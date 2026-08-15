# =====================================================================
# INSTALADOR del puente Soft Restaurant -> Panel La Ola
# Se corre UNA vez en la máquina servidor del POS (PowerShell como admin):
#   [Net.ServicePointManager]::SecurityProtocol=3072; irm <url-del-gist> | iex
# Detecta el SQL Server del POS, prueba credenciales conocidas, deja el
# agente en C:\LaOla y registra la tarea programada cada 15 minutos.
# =====================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$GIST_RAW = 'https://gist.githubusercontent.com/AdministracionSolu/84236740eb504a987bff762b15c376c0/raw/agente-pos.ps1'
$SUPABASE_URL = 'https://ctoeckcgrqihsxjefmwg.supabase.co'
$ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0b2Vja2NncnFpaHN4amVmbXdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4Mjk3NzgsImV4cCI6MjA4MzQwNTc3OH0.N9FZwtUHlx_jax3YyndymaMIkt73oi6ztXROVONyYb0'

Write-Host ''
Write-Host '=== Puente Soft Restaurant -> Panel La Ola ===' -ForegroundColor Cyan
Write-Host ''

# --- 1. Sucursal -----------------------------------------------------
$sucursales = @{
  '1' = @{ origen = 'cerveceria'; nombre = 'Cervecería';  secret = 'a5fa9d2ad6970e06e3f86319ddf359a655cf53ab248d6c13' }
  '2' = @{ origen = 'valle';      nombre = 'Del Valle';   secret = 'e7a9b9135ceee53e809b04fff24969e148ff34d552ba1183' }
  '3' = @{ origen = 'brisas';     nombre = 'Las Brisas';  secret = 'd2dab4014e6f3a54268d67d589aa3c0791721e4ea5e68659' }
  '4' = @{ origen = 'solares';    nombre = 'Solares';     secret = 'd03c4438138538698cebf968b62424674e35ba9417205658' }
}
Write-Host '  1) Cervecería   2) Del Valle   3) Las Brisas   4) Solares'
$sel = Read-Host 'En qué sucursal estás (1-4)'
$suc = $sucursales[$sel.Trim()]
if (-not $suc) { throw 'Selección inválida, corre el instalador de nuevo.' }
Write-Host ("Sucursal: {0}" -f $suc.nombre) -ForegroundColor Green

# --- 2. Encontrar el SQL Server del POS ------------------------------
$servidores = New-Object System.Collections.ArrayList
$reg = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' -ErrorAction SilentlyContinue
if ($reg) {
  foreach ($p in $reg.PSObject.Properties) {
    if ($p.Name -notlike 'PS*') {
      if ($p.Name -eq 'MSSQLSERVER') { [void]$servidores.Add('.') }
      else { [void]$servidores.Add(".\$($p.Name)") }
    }
  }
}
foreach ($s in @('.\NATIONALSOFT', '.\SQLEXPRESS', '.')) {
  if ($servidores -notcontains $s) { [void]$servidores.Add($s) }
}

$credenciales = @(
  @{ u = '';   p = '' },              # autenticación de Windows
  @{ u = 'sa'; p = 'National09' },
  @{ u = 'sa'; p = 'national09' },
  @{ u = 'sa'; p = 'Nationalsoft' }
)

function Probar-Conexion($server, $user, $pass) {
  if ($user) { $cs = "Server=$server;Database=master;User ID=$user;Password=$pass;Connect Timeout=5" }
  else { $cs = "Server=$server;Database=master;Integrated Security=True;Connect Timeout=5" }
  $cn = New-Object System.Data.SqlClient.SqlConnection $cs
  $cn.Open()
  return $cn
}

function Buscar-BaseSR($cn) {
  $cmd = $cn.CreateCommand()
  $cmd.CommandText = "SELECT name FROM sys.databases WHERE LOWER(name) LIKE '%restaurant%' ORDER BY create_date DESC"
  $rd = $cmd.ExecuteReader()
  $bases = @()
  while ($rd.Read()) { $bases += $rd.GetString(0) }
  $rd.Close()
  return ,$bases
}

$encontrado = $null
Write-Host 'Buscando el SQL Server de Soft Restaurant...'
foreach ($srv in $servidores) {
  foreach ($cred in $credenciales) {
    try {
      $cn = Probar-Conexion $srv $cred.u $cred.p
      $bases = Buscar-BaseSR $cn
      foreach ($db in $bases) {
        try {
          $cmd = $cn.CreateCommand()
          $cmd.CommandText = "SELECT TOP 1 folio FROM [$db].dbo.cheques"
          $cmd.ExecuteScalar() | Out-Null
          $encontrado = @{ server = $srv; user = $cred.u; pass = $cred.p; db = $db }
          break
        } catch { }
      }
      $cn.Close()
    } catch { }
    if ($encontrado) { break }
  }
  if ($encontrado) { break }
}

if (-not $encontrado) {
  Write-Host 'No encontré la base automáticamente. Vamos a mano:' -ForegroundColor Yellow
  $srv = Read-Host 'Servidor SQL (ej. .\NATIONALSOFT)'
  $usr = Read-Host 'Usuario (vacío = autenticación de Windows)'
  $pwd2 = ''
  if ($usr) { $pwd2 = Read-Host 'Contraseña' }
  $db = Read-Host 'Nombre de la base (ej. softrestaurant11)'
  $cn = Probar-Conexion $srv $usr $pwd2
  $cmd = $cn.CreateCommand()
  $cmd.CommandText = "SELECT TOP 1 folio FROM [$db].dbo.cheques"
  $cmd.ExecuteScalar() | Out-Null
  $cn.Close()
  $encontrado = @{ server = $srv; user = $usr; pass = $pwd2; db = $db }
}
Write-Host ("SQL encontrado: {0} / base {1} / usuario {2}" -f $encontrado.server, $encontrado.db, $(if ($encontrado.user) { $encontrado.user } else { 'Windows' })) -ForegroundColor Green

# Si el acceso fue por autenticación de Windows, la tarea (que corre como
# SYSTEM) podría no entrar. Avisar para vigilar el log en ese caso.
if (-not $encontrado.user) {
  Write-Host 'OJO: acceso por autenticación de Windows; si el log marca error de acceso, avísale a Claude.' -ForegroundColor Yellow
}

# --- 3. Instalar -----------------------------------------------------
$dir = 'C:\LaOla'
New-Item -ItemType Directory -Path $dir -Force | Out-Null

@{
  origen        = $suc.origen
  secret        = $suc.secret
  supabase_url  = $SUPABASE_URL
  anon_key      = $ANON_KEY
  sql_server    = $encontrado.server
  sql_db        = $encontrado.db
  sql_user      = $encontrado.user
  sql_pass      = $encontrado.pass
  dias_ventana  = 3
  dias_backfill = 400
} | ConvertTo-Json | Set-Content -Path (Join-Path $dir 'config.json') -Encoding UTF8

Invoke-WebRequest -Uri $GIST_RAW -OutFile (Join-Path $dir 'agente-pos.ps1') -UseBasicParsing
Write-Host 'Agente descargado en C:\LaOla' -ForegroundColor Green

$tr = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\LaOla\agente-pos.ps1'
schtasks /create /tn 'LaOlaPOS' /tr $tr /sc minute /mo 15 /ru SYSTEM /rl HIGHEST /f | Out-Null
Write-Host 'Tarea programada "LaOlaPOS" registrada (cada 15 minutos).' -ForegroundColor Green

# --- 4. Primera corrida (backfill) -----------------------------------
Write-Host ''
Write-Host 'Arrancando la primera sincronización (histórico completo, puede tardar varios minutos)...' -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir 'agente-pos.ps1')
if ($LASTEXITCODE -eq 0) {
  Write-Host ''
  Write-Host 'LISTO. El puente quedó instalado y sincronizando cada 15 minutos.' -ForegroundColor Green
  Write-Host 'Log: C:\LaOla\agente.log'
} else {
  Write-Host ''
  Write-Host 'La primera corrida marcó error. Manda a Claude lo que dice C:\LaOla\agente.log' -ForegroundColor Yellow
}
