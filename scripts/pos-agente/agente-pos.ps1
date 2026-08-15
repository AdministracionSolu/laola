# =====================================================================
# AGENTE POS LA OLA — lee Soft Restaurant (SQL Server local) y sube las
# ventas al panel (Supabase) vía el RPC pos_ingest.
# Corre como tarea programada cada 15 min. Config en C:\LaOla\config.json
# Compatible con PowerShell 5.1 (el que trae Windows).
# =====================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$dir = 'C:\LaOla'
$cfg = Get-Content (Join-Path $dir 'config.json') -Raw | ConvertFrom-Json
$log = Join-Path $dir 'agente.log'
$marca = Join-Path $dir 'ultima-corrida.txt'

if ((Test-Path $log) -and ((Get-Item $log).Length -gt 2MB)) { Remove-Item $log -Force }

function Escribir-Log($msg) {
  $linea = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
  Add-Content -Path $log -Value $linea
  Write-Host $linea
}

function Nueva-Conexion {
  if ($cfg.sql_user) {
    $cs = "Server=$($cfg.sql_server);Database=$($cfg.sql_db);User ID=$($cfg.sql_user);Password=$($cfg.sql_pass)"
  } else {
    $cs = "Server=$($cfg.sql_server);Database=$($cfg.sql_db);Integrated Security=True"
  }
  $cn = New-Object System.Data.SqlClient.SqlConnection $cs
  $cn.Open()
  return $cn
}

function Consultar($cn, $sql) {
  $cmd = $cn.CreateCommand()
  $cmd.CommandText = $sql
  $cmd.CommandTimeout = 600
  $dt = New-Object System.Data.DataTable
  (New-Object System.Data.SqlClient.SqlDataAdapter $cmd).Fill($dt) | Out-Null
  return ,$dt
}

function Convertir-Filas($dt) {
  # DataTable -> lista de objetos planos con llaves en minúsculas.
  # Fechas a texto (el ConvertTo-Json de PS 5.1 arruina los DateTime) y
  # se limpian bytes de control (rompen el jsonb de Postgres).
  $filas = New-Object System.Collections.ArrayList
  foreach ($row in $dt.Rows) {
    $o = [ordered]@{}
    foreach ($col in $dt.Columns) {
      $v = $row[$col]
      if ($v -is [System.DBNull]) { $v = $null }
      elseif ($v -is [datetime]) { $v = $v.ToString('yyyy-MM-dd HH:mm:ss') }
      elseif ($v -is [byte[]]) { $v = $null }
      elseif ($v -is [string]) { $v = $v -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', '' }
      $o[$col.ColumnName.ToLower()] = $v
    }
    [void]$filas.Add([pscustomobject]$o)
  }
  return ,$filas
}

function Enviar($tabla, $filas) {
  $total = $filas.Count
  $enviadas = 0
  for ($i = 0; $i -lt $total; $i += 200) {
    $fin = [Math]::Min($i + 199, $total - 1)
    $lote = @($filas[$i..$fin])
    $body = @{ p_secret = $cfg.secret; p_origen = $cfg.origen; p_tabla = $tabla; p_filas = $lote } | ConvertTo-Json -Depth 5 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($body)
    Invoke-RestMethod -Method Post -Uri "$($cfg.supabase_url)/rest/v1/rpc/pos_ingest" `
      -Headers @{ apikey = $cfg.anon_key; Authorization = "Bearer $($cfg.anon_key)" } `
      -ContentType 'application/json; charset=utf-8' -Body $bytes | Out-Null
    $enviadas += $lote.Count
    if ($total -gt 400) { Write-Host ("  {0}: {1} de {2}" -f $tabla, $enviadas, $total) }
  }
  Escribir-Log ("{0}: {1} filas subidas" -f $tabla, $enviadas)
}

try {
  # Primera corrida = backfill largo; después, ventana rodante de pocos días
  # (upsert idempotente: las cuentas reabiertas se corrigen solas).
  if (Test-Path $marca) { $dias = [int]$cfg.dias_ventana } else { $dias = [int]$cfg.dias_backfill }
  Escribir-Log ("inicio ({0}, ventana {1} dias)" -f $cfg.origen, $dias)

  $cn = Nueva-Conexion

  $cheques = Consultar $cn "SELECT * FROM cheques WHERE fecha >= DATEADD(day, -$dias, GETDATE())"
  if ($cheques.Rows.Count -gt 0) { Enviar 'cheques' (Convertir-Filas $cheques) }

  $det = Consultar $cn "SELECT d.* FROM cheqdet d WHERE d.foliodet IN (SELECT folio FROM cheques WHERE fecha >= DATEADD(day, -$dias, GETDATE()))"
  if ($det.Rows.Count -gt 0) { Enviar 'cheqdet' (Convertir-Filas $det) }

  $turnos = Consultar $cn "SELECT * FROM turnos WHERE apertura >= DATEADD(day, -$dias, GETDATE())"
  if ($turnos.Rows.Count -gt 0) { Enviar 'turnos' (Convertir-Filas $turnos) }

  # Catálogo de productos: en el backfill y una vez al día (5:00-5:15)
  $ahora = Get-Date
  if (-not (Test-Path $marca) -or ($ahora.Hour -eq 5 -and $ahora.Minute -lt 15)) {
    try {
      $prod = Consultar $cn "SELECT p.*, g.descripcion AS grupo FROM productos p LEFT JOIN grupos g ON g.idgrupo = p.idgrupo"
    } catch {
      $prod = Consultar $cn "SELECT * FROM productos"
    }
    if ($prod.Rows.Count -gt 0) { Enviar 'productos' (Convertir-Filas $prod) }
  }

  $cn.Close()
  Set-Content -Path $marca -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  Escribir-Log 'OK'
} catch {
  Escribir-Log ('ERROR: ' + $_.Exception.Message)
  exit 1
}
