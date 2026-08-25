export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  public: {
    Tables: {
      asistencias: {
        Row: {
          created_at: string
          empleado_id: string
          entrada_at: string
          fecha_negocio: string
          id: string
          minutos_retardo: number | null
          nota: string | null
          salida_at: string | null
          sucursal_id: string
          turno_entrada: string | null
        }
        Insert: {
          created_at?: string
          empleado_id: string
          entrada_at?: string
          fecha_negocio: string
          id?: string
          minutos_retardo?: number | null
          nota?: string | null
          salida_at?: string | null
          sucursal_id: string
          turno_entrada?: string | null
        }
        Update: {
          created_at?: string
          empleado_id?: string
          entrada_at?: string
          fecha_negocio?: string
          id?: string
          minutos_retardo?: number | null
          nota?: string | null
          salida_at?: string | null
          sucursal_id?: string
          turno_entrada?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "asistencias_empleado_id_fkey"
            columns: ["empleado_id"]
            isOneToOne: false
            referencedRelation: "empleados"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "asistencias_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      catalogo_turnos: {
        Row: {
          activo: boolean
          color: string
          created_at: string
          hora_entrada: string
          hora_salida: string
          id: string
          nombre: string
          orden: number
          sucursal_id: string | null
        }
        Insert: {
          activo?: boolean
          color?: string
          created_at?: string
          hora_entrada: string
          hora_salida: string
          id?: string
          nombre: string
          orden?: number
          sucursal_id?: string | null
        }
        Update: {
          activo?: boolean
          color?: string
          created_at?: string
          hora_entrada?: string
          hora_salida?: string
          id?: string
          nombre?: string
          orden?: number
          sucursal_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "catalogo_turnos_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      categorias_insumos: {
        Row: {
          created_at: string
          id: string
          nombre: string
          orden: number
        }
        Insert: {
          created_at?: string
          id?: string
          nombre: string
          orden?: number
        }
        Update: {
          created_at?: string
          id?: string
          nombre?: string
          orden?: number
        }
        Relationships: []
      }
      config_app: {
        Row: {
          clave: string
          valor: string | null
        }
        Insert: {
          clave: string
          valor?: string | null
        }
        Update: {
          clave?: string
          valor?: string | null
        }
        Relationships: []
      }
      config_depuracion: {
        Row: {
          id: number
          token: string
        }
        Insert: {
          id?: number
          token?: string
        }
        Update: {
          id?: number
          token?: string
        }
        Relationships: []
      }
      cortes_alertas_config: {
        Row: {
          activo: boolean
          hora_limite: string
          hora_limite_finde: string | null
          sucursal_id: string
          updated_at: string
        }
        Insert: {
          activo?: boolean
          hora_limite?: string
          hora_limite_finde?: string | null
          sucursal_id: string
          updated_at?: string
        }
        Update: {
          activo?: boolean
          hora_limite?: string
          hora_limite_finde?: string | null
          sucursal_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "cortes_alertas_config_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: true
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      cortes_alertas_enviadas: {
        Row: {
          created_at: string
          fecha_negocio: string
          id: string
          sucursal_id: string
        }
        Insert: {
          created_at?: string
          fecha_negocio: string
          id?: string
          sucursal_id: string
        }
        Update: {
          created_at?: string
          fecha_negocio?: string
          id?: string
          sucursal_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "cortes_alertas_enviadas_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      cortes_audit: {
        Row: {
          accion: string
          antes: Json
          corte_id: string
          created_at: string
          despues: Json | null
          id: string
          quien: string | null
          sucursal_id: string | null
        }
        Insert: {
          accion: string
          antes: Json
          corte_id: string
          created_at?: string
          despues?: Json | null
          id?: string
          quien?: string | null
          sucursal_id?: string | null
        }
        Update: {
          accion?: string
          antes?: Json
          corte_id?: string
          created_at?: string
          despues?: Json | null
          id?: string
          quien?: string | null
          sucursal_id?: string | null
        }
        Relationships: []
      }
      cortes_caja: {
        Row: {
          cobradas: number
          compras: number | null
          corte_x: number
          created_at: string
          efectivo: number
          fecha_venta: string
          id: string
          pago_proveedores: number | null
          pago_servicios: number | null
          por_cobrar: number
          propinas: number | null
          rappi: number | null
          salarios: number | null
          sucursal_id: string
          tarjetas: number
          tarjetas_banregio: number | null
          tarjetas_espiral: number | null
          tarjetas_haycash: number | null
          tarjetas_mercadopago: number | null
          tipo_corte: Database["public"]["Enums"]["tipo_corte"]
          total: number
          uber: number | null
        }
        Insert: {
          cobradas?: number
          compras?: number | null
          corte_x?: number
          created_at?: string
          efectivo?: number
          fecha_venta: string
          id?: string
          pago_proveedores?: number | null
          pago_servicios?: number | null
          por_cobrar?: number
          propinas?: number | null
          rappi?: number | null
          salarios?: number | null
          sucursal_id: string
          tarjetas?: number
          tarjetas_banregio?: number | null
          tarjetas_espiral?: number | null
          tarjetas_haycash?: number | null
          tarjetas_mercadopago?: number | null
          tipo_corte: Database["public"]["Enums"]["tipo_corte"]
          total?: number
          uber?: number | null
        }
        Update: {
          cobradas?: number
          compras?: number | null
          corte_x?: number
          created_at?: string
          efectivo?: number
          fecha_venta?: string
          id?: string
          pago_proveedores?: number | null
          pago_servicios?: number | null
          por_cobrar?: number
          propinas?: number | null
          rappi?: number | null
          salarios?: number | null
          sucursal_id?: string
          tarjetas?: number
          tarjetas_banregio?: number | null
          tarjetas_espiral?: number | null
          tarjetas_haycash?: number | null
          tarjetas_mercadopago?: number | null
          tipo_corte?: Database["public"]["Enums"]["tipo_corte"]
          total?: number
          uber?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "cortes_caja_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      empleados: {
        Row: {
          activo: boolean
          area: string
          created_at: string
          id: string
          nombre: string
          orden: number
          pin: string | null
          sucursal_principal_id: string | null
          telefono: string | null
          updated_at: string
        }
        Insert: {
          activo?: boolean
          area: string
          created_at?: string
          id?: string
          nombre: string
          orden?: number
          pin?: string | null
          sucursal_principal_id?: string | null
          telefono?: string | null
          updated_at?: string
        }
        Update: {
          activo?: boolean
          area?: string
          created_at?: string
          id?: string
          nombre?: string
          orden?: number
          pin?: string | null
          sucursal_principal_id?: string | null
          telefono?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "empleados_sucursal_principal_id_fkey"
            columns: ["sucursal_principal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      factura_folios: {
        Row: {
          fecha: string
          sucursal_codigo: string
          ultimo: number
        }
        Insert: {
          fecha: string
          sucursal_codigo: string
          ultimo?: number
        }
        Update: {
          fecha?: string
          sucursal_codigo?: string
          ultimo?: number
        }
        Relationships: []
      }
      factura_solicitudes: {
        Row: {
          cfdi_uuid: string | null
          codigo_postal: string
          created_at: string
          email: string
          estado: string
          folio_solicitud: string
          forma_pago: string | null
          id: string
          notas: string | null
          razon_social: string
          regimen_fiscal: string
          rfc: string
          sucursal_codigo: string | null
          sucursal_id: string | null
          telefono: string | null
          ticket_fecha: string | null
          ticket_folio: string | null
          ticket_folio_norm: string | null
          ticket_foto_path: string | null
          ticket_total: number | null
          timbrada_at: string | null
          updated_at: string
          uso_cfdi: string
        }
        Insert: {
          cfdi_uuid?: string | null
          codigo_postal: string
          created_at?: string
          email: string
          estado?: string
          folio_solicitud: string
          forma_pago?: string | null
          id?: string
          notas?: string | null
          razon_social: string
          regimen_fiscal: string
          rfc: string
          sucursal_codigo?: string | null
          sucursal_id?: string | null
          telefono?: string | null
          ticket_fecha?: string | null
          ticket_folio?: string | null
          ticket_folio_norm?: string | null
          ticket_foto_path?: string | null
          ticket_total?: number | null
          timbrada_at?: string | null
          updated_at?: string
          uso_cfdi: string
        }
        Update: {
          cfdi_uuid?: string | null
          codigo_postal?: string
          created_at?: string
          email?: string
          estado?: string
          folio_solicitud?: string
          forma_pago?: string | null
          id?: string
          notas?: string | null
          razon_social?: string
          regimen_fiscal?: string
          rfc?: string
          sucursal_codigo?: string | null
          sucursal_id?: string | null
          telefono?: string | null
          ticket_fecha?: string | null
          ticket_folio?: string | null
          ticket_folio_norm?: string | null
          ticket_foto_path?: string | null
          ticket_total?: number | null
          timbrada_at?: string | null
          updated_at?: string
          uso_cfdi?: string
        }
        Relationships: [
          {
            foreignKeyName: "factura_solicitudes_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      folios_secuencia: {
        Row: {
          fecha: string
          sucursal_id: string
          ultimo: number
        }
        Insert: {
          fecha: string
          sucursal_id: string
          ultimo?: number
        }
        Update: {
          fecha?: string
          sucursal_id?: string
          ultimo?: number
        }
        Relationships: [
          {
            foreignKeyName: "folios_secuencia_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      horarios_ligas: {
        Row: {
          activo: boolean
          area: string
          created_at: string
          id: string
          sucursal_id: string
          token: string
        }
        Insert: {
          activo?: boolean
          area: string
          created_at?: string
          id?: string
          sucursal_id: string
          token: string
        }
        Update: {
          activo?: boolean
          area?: string
          created_at?: string
          id?: string
          sucursal_id?: string
          token?: string
        }
        Relationships: [
          {
            foreignKeyName: "horarios_ligas_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      horarios_roles_def: {
        Row: {
          activo: boolean
          area: string
          hora_entrada: string | null
          hora_salida: string | null
          id: string
          rol: string
          sucursal_id: string | null
          updated_at: string
        }
        Insert: {
          activo?: boolean
          area: string
          hora_entrada?: string | null
          hora_salida?: string | null
          id?: string
          rol: string
          sucursal_id?: string | null
          updated_at?: string
        }
        Update: {
          activo?: boolean
          area?: string
          hora_entrada?: string | null
          hora_salida?: string | null
          id?: string
          rol?: string
          sucursal_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "horarios_roles_def_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      horarios_sucursal: {
        Row: {
          activo: boolean
          created_at: string
          dia_semana: number
          hora_apertura: string
          hora_cierre: string
          id: string
          sucursal_id: string
        }
        Insert: {
          activo?: boolean
          created_at?: string
          dia_semana: number
          hora_apertura: string
          hora_cierre: string
          id?: string
          sucursal_id: string
        }
        Update: {
          activo?: boolean
          created_at?: string
          dia_semana?: number
          hora_apertura?: string
          hora_cierre?: string
          id?: string
          sucursal_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "horarios_sucursal_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      impl_pendientes: {
        Row: {
          area: string | null
          created_at: string
          estado: string
          id: string
          notas: string | null
          responsable: string | null
          semana_objetivo: string | null
          sucursal_id: string | null
          titulo: string
          updated_at: string
        }
        Insert: {
          area?: string | null
          created_at?: string
          estado?: string
          id?: string
          notas?: string | null
          responsable?: string | null
          semana_objetivo?: string | null
          sucursal_id?: string | null
          titulo: string
          updated_at?: string
        }
        Update: {
          area?: string | null
          created_at?: string
          estado?: string
          id?: string
          notas?: string | null
          responsable?: string | null
          semana_objetivo?: string | null
          sucursal_id?: string | null
          titulo?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "impl_pendientes_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      impl_responsables: {
        Row: {
          activo: boolean
          id: string
          notas: string | null
          persona: string
          proceso: string
          puesto: string | null
          sucursal_id: string | null
          telefono: string | null
          updated_at: string
        }
        Insert: {
          activo?: boolean
          id?: string
          notas?: string | null
          persona: string
          proceso: string
          puesto?: string | null
          sucursal_id?: string | null
          telefono?: string | null
          updated_at?: string
        }
        Update: {
          activo?: boolean
          id?: string
          notas?: string | null
          persona?: string
          proceso?: string
          puesto?: string | null
          sucursal_id?: string | null
          telefono?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "impl_responsables_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      insumo_sucursal: {
        Row: {
          activo: boolean
          costo: number | null
          created_at: string
          id: string
          insumo_id: string
          orden: number
          sucursal_id: string
          unidad: string | null
          updated_at: string
        }
        Insert: {
          activo?: boolean
          costo?: number | null
          created_at?: string
          id?: string
          insumo_id: string
          orden?: number
          sucursal_id: string
          unidad?: string | null
          updated_at?: string
        }
        Update: {
          activo?: boolean
          costo?: number | null
          created_at?: string
          id?: string
          insumo_id?: string
          orden?: number
          sucursal_id?: string
          unidad?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "insumo_sucursal_insumo_id_fkey"
            columns: ["insumo_id"]
            isOneToOne: false
            referencedRelation: "insumos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "insumo_sucursal_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      insumos: {
        Row: {
          activo: boolean
          categoria_id: string
          created_at: string
          desglosa_procesado: boolean
          id: string
          nombre: string
          unidad: string | null
        }
        Insert: {
          activo?: boolean
          categoria_id: string
          created_at?: string
          desglosa_procesado?: boolean
          id?: string
          nombre: string
          unidad?: string | null
        }
        Update: {
          activo?: boolean
          categoria_id?: string
          created_at?: string
          desglosa_procesado?: boolean
          id?: string
          nombre?: string
          unidad?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "insumos_categoria_id_fkey"
            columns: ["categoria_id"]
            isOneToOne: false
            referencedRelation: "categorias_insumos"
            referencedColumns: ["id"]
          },
        ]
      }
      integracion_makatea: {
        Row: {
          activo: boolean
          base_url: string
          id: number
          secreto: string
          updated_at: string
        }
        Insert: {
          activo?: boolean
          base_url: string
          id?: number
          secreto: string
          updated_at?: string
        }
        Update: {
          activo?: boolean
          base_url?: string
          id?: number
          secreto?: string
          updated_at?: string
        }
        Relationships: []
      }
      lealtad_canjes: {
        Row: {
          cliente_id: string
          created_at: string
          fecha_negocio: string
          id: string
          origen: string
          posicion: number
          sucursal_id: string | null
          titulo: string
        }
        Insert: {
          cliente_id: string
          created_at?: string
          fecha_negocio: string
          id?: string
          origen?: string
          posicion: number
          sucursal_id?: string | null
          titulo: string
        }
        Update: {
          cliente_id?: string
          created_at?: string
          fecha_negocio?: string
          id?: string
          origen?: string
          posicion?: number
          sucursal_id?: string | null
          titulo?: string
        }
        Relationships: [
          {
            foreignKeyName: "lealtad_canjes_cliente_id_fkey"
            columns: ["cliente_id"]
            isOneToOne: false
            referencedRelation: "lealtad_clientes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "lealtad_canjes_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      lealtad_clientes: {
        Row: {
          activo: boolean
          apellido_materno: string | null
          apellido_paterno: string | null
          bienvenida_canjeada_at: string | null
          consentimiento_at: string | null
          consentimiento_marketing: boolean
          created_at: string
          cumpleanos: string | null
          id: string
          nombre: string
          primer_nombre: string | null
          recompensas_usadas: number
          segundo_nombre: string | null
          sucursal_captacion_codigo: string | null
          sucursal_captacion_id: string | null
          telefono: string
          ultima_visita: string | null
          updated_at: string
          visitas_total: number
        }
        Insert: {
          activo?: boolean
          apellido_materno?: string | null
          apellido_paterno?: string | null
          bienvenida_canjeada_at?: string | null
          consentimiento_at?: string | null
          consentimiento_marketing?: boolean
          created_at?: string
          cumpleanos?: string | null
          id?: string
          nombre: string
          primer_nombre?: string | null
          recompensas_usadas?: number
          segundo_nombre?: string | null
          sucursal_captacion_codigo?: string | null
          sucursal_captacion_id?: string | null
          telefono: string
          ultima_visita?: string | null
          updated_at?: string
          visitas_total?: number
        }
        Update: {
          activo?: boolean
          apellido_materno?: string | null
          apellido_paterno?: string | null
          bienvenida_canjeada_at?: string | null
          consentimiento_at?: string | null
          consentimiento_marketing?: boolean
          created_at?: string
          cumpleanos?: string | null
          id?: string
          nombre?: string
          primer_nombre?: string | null
          recompensas_usadas?: number
          segundo_nombre?: string | null
          sucursal_captacion_codigo?: string | null
          sucursal_captacion_id?: string | null
          telefono?: string
          ultima_visita?: string | null
          updated_at?: string
          visitas_total?: number
        }
        Relationships: [
          {
            foreignKeyName: "lealtad_clientes_sucursal_captacion_id_fkey"
            columns: ["sucursal_captacion_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      lealtad_colaboradores: {
        Row: {
          activo: boolean
          admin_grupo: boolean
          agregado_at: string
          nombre_wa: string | null
          notas: string | null
          origen: string
          telefono: string
          telefono_wa: string | null
        }
        Insert: {
          activo?: boolean
          admin_grupo?: boolean
          agregado_at?: string
          nombre_wa?: string | null
          notas?: string | null
          origen?: string
          telefono: string
          telefono_wa?: string | null
        }
        Update: {
          activo?: boolean
          admin_grupo?: boolean
          agregado_at?: string
          nombre_wa?: string | null
          notas?: string | null
          origen?: string
          telefono?: string
          telefono_wa?: string | null
        }
        Relationships: []
      }
      lealtad_config: {
        Row: {
          id: number
          meta_visitas: number
          recompensa_texto: string
          tope_visitas_dia: number
          updated_at: string
        }
        Insert: {
          id?: number
          meta_visitas?: number
          recompensa_texto?: string
          tope_visitas_dia?: number
          updated_at?: string
        }
        Update: {
          id?: number
          meta_visitas?: number
          recompensa_texto?: string
          tope_visitas_dia?: number
          updated_at?: string
        }
        Relationships: []
      }
      lealtad_intentos: {
        Row: {
          created_at: string
          fecha_negocio: string
          folio_norm: string | null
          id: string
          motivo: string
          sucursal_id: string | null
          telefono: string
        }
        Insert: {
          created_at?: string
          fecha_negocio: string
          folio_norm?: string | null
          id?: string
          motivo: string
          sucursal_id?: string | null
          telefono: string
        }
        Update: {
          created_at?: string
          fecha_negocio?: string
          folio_norm?: string | null
          id?: string
          motivo?: string
          sucursal_id?: string | null
          telefono?: string
        }
        Relationships: [
          {
            foreignKeyName: "lealtad_intentos_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      lealtad_niveles: {
        Row: {
          activo: boolean
          beneficio: string | null
          color: string
          id: string
          min_visitas: number
          nombre: string
          orden: number
          posicion: number | null
        }
        Insert: {
          activo?: boolean
          beneficio?: string | null
          color?: string
          id?: string
          min_visitas: number
          nombre: string
          orden?: number
          posicion?: number | null
        }
        Update: {
          activo?: boolean
          beneficio?: string | null
          color?: string
          id?: string
          min_visitas?: number
          nombre?: string
          orden?: number
          posicion?: number | null
        }
        Relationships: []
      }
      lealtad_recompensas: {
        Row: {
          activo: boolean
          posicion: number
          titulo: string
          updated_at: string
        }
        Insert: {
          activo?: boolean
          posicion: number
          titulo: string
          updated_at?: string
        }
        Update: {
          activo?: boolean
          posicion?: number
          titulo?: string
          updated_at?: string
        }
        Relationships: []
      }
      lealtad_visitas: {
        Row: {
          cliente_id: string
          created_at: string
          fecha_negocio: string
          folio: string | null
          folio_norm: string | null
          id: string
          origen: string
          sucursal_id: string | null
        }
        Insert: {
          cliente_id: string
          created_at?: string
          fecha_negocio: string
          folio?: string | null
          folio_norm?: string | null
          id?: string
          origen?: string
          sucursal_id?: string | null
        }
        Update: {
          cliente_id?: string
          created_at?: string
          fecha_negocio?: string
          folio?: string | null
          folio_norm?: string | null
          id?: string
          origen?: string
          sucursal_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "lealtad_visitas_cliente_id_fkey"
            columns: ["cliente_id"]
            isOneToOne: false
            referencedRelation: "lealtad_clientes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "lealtad_visitas_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_categorias: {
        Row: {
          activa: boolean
          created_at: string
          id: string
          nombre: string
          orden: number
        }
        Insert: {
          activa?: boolean
          created_at?: string
          id?: string
          nombre: string
          orden?: number
        }
        Update: {
          activa?: boolean
          created_at?: string
          id?: string
          nombre?: string
          orden?: number
        }
        Relationships: []
      }
      menu_items: {
        Row: {
          categoria_id: string
          created_at: string
          descripcion: string | null
          es_alcohol: boolean
          id: string
          nombre: string
          opciones: Json | null
          orden: number
        }
        Insert: {
          categoria_id: string
          created_at?: string
          descripcion?: string | null
          es_alcohol?: boolean
          id?: string
          nombre: string
          opciones?: Json | null
          orden?: number
        }
        Update: {
          categoria_id?: string
          created_at?: string
          descripcion?: string | null
          es_alcohol?: boolean
          id?: string
          nombre?: string
          opciones?: Json | null
          orden?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_items_categoria_id_fkey"
            columns: ["categoria_id"]
            isOneToOne: false
            referencedRelation: "menu_categorias"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_variante_sucursal: {
        Row: {
          disponible: boolean
          precio: number
          sucursal_id: string
          variante_id: string
        }
        Insert: {
          disponible?: boolean
          precio: number
          sucursal_id: string
          variante_id: string
        }
        Update: {
          disponible?: boolean
          precio?: number
          sucursal_id?: string
          variante_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_variante_sucursal_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_variante_sucursal_variante_id_fkey"
            columns: ["variante_id"]
            isOneToOne: false
            referencedRelation: "menu_variantes"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_variantes: {
        Row: {
          created_at: string
          id: string
          item_id: string
          nombre: string
          orden: number
        }
        Insert: {
          created_at?: string
          id?: string
          item_id: string
          nombre: string
          orden?: number
        }
        Update: {
          created_at?: string
          id?: string
          item_id?: string
          nombre?: string
          orden?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_variantes_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      notificaciones_pedido: {
        Row: {
          created_at: string
          estado: string
          id: string
          payload: Json | null
          pedido_id: string
          telefono: string
          tipo: string
        }
        Insert: {
          created_at?: string
          estado?: string
          id?: string
          payload?: Json | null
          pedido_id: string
          telefono: string
          tipo: string
        }
        Update: {
          created_at?: string
          estado?: string
          id?: string
          payload?: Json | null
          pedido_id?: string
          telefono?: string
          tipo?: string
        }
        Relationships: [
          {
            foreignKeyName: "notificaciones_pedido_pedido_id_fkey"
            columns: ["pedido_id"]
            isOneToOne: false
            referencedRelation: "pedidos_en_linea"
            referencedColumns: ["id"]
          },
        ]
      }
      pedidos: {
        Row: {
          created_at: string
          enviado_at: string | null
          estado: string
          fecha: string
          id: string
          notas: string | null
          registrado_por: string | null
          sucursal_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          enviado_at?: string | null
          estado?: string
          fecha?: string
          id?: string
          notas?: string | null
          registrado_por?: string | null
          sucursal_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          enviado_at?: string | null
          estado?: string
          fecha?: string
          id?: string
          notas?: string | null
          registrado_por?: string | null
          sucursal_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "pedidos_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      pedidos_detalle: {
        Row: {
          cantidad_pedida: number
          cantidad_sugerida: number | null
          created_at: string
          existencia: number | null
          existencia_no_procesado: number | null
          existencia_procesado: number | null
          id: string
          insumo_id: string
          pedido_id: string
        }
        Insert: {
          cantidad_pedida?: number
          cantidad_sugerida?: number | null
          created_at?: string
          existencia?: number | null
          existencia_no_procesado?: number | null
          existencia_procesado?: number | null
          id?: string
          insumo_id: string
          pedido_id: string
        }
        Update: {
          cantidad_pedida?: number
          cantidad_sugerida?: number | null
          created_at?: string
          existencia?: number | null
          existencia_no_procesado?: number | null
          existencia_procesado?: number | null
          id?: string
          insumo_id?: string
          pedido_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "pedidos_detalle_insumo_id_fkey"
            columns: ["insumo_id"]
            isOneToOne: false
            referencedRelation: "insumos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pedidos_detalle_pedido_id_fkey"
            columns: ["pedido_id"]
            isOneToOne: false
            referencedRelation: "pedidos"
            referencedColumns: ["id"]
          },
        ]
      }
      pedidos_en_linea: {
        Row: {
          confirmado_at: string | null
          costo_envio: number
          created_at: string
          direccion: string | null
          entregado_at: string | null
          estado: string
          folio: string
          id: string
          listo_at: string | null
          metodo_pago: string
          motivo_cancelacion: string | null
          nombre_cliente: string
          notas_generales: string | null
          referencias: string | null
          subtotal: number
          sucursal_id: string
          telefono: string
          tipo: string
          token: string
          total: number
          updated_at: string
          zona_id: string | null
        }
        Insert: {
          confirmado_at?: string | null
          costo_envio?: number
          created_at?: string
          direccion?: string | null
          entregado_at?: string | null
          estado?: string
          folio: string
          id?: string
          listo_at?: string | null
          metodo_pago?: string
          motivo_cancelacion?: string | null
          nombre_cliente: string
          notas_generales?: string | null
          referencias?: string | null
          subtotal?: number
          sucursal_id: string
          telefono: string
          tipo: string
          token?: string
          total?: number
          updated_at?: string
          zona_id?: string | null
        }
        Update: {
          confirmado_at?: string | null
          costo_envio?: number
          created_at?: string
          direccion?: string | null
          entregado_at?: string | null
          estado?: string
          folio?: string
          id?: string
          listo_at?: string | null
          metodo_pago?: string
          motivo_cancelacion?: string | null
          nombre_cliente?: string
          notas_generales?: string | null
          referencias?: string | null
          subtotal?: number
          sucursal_id?: string
          telefono?: string
          tipo?: string
          token?: string
          total?: number
          updated_at?: string
          zona_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "pedidos_en_linea_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pedidos_en_linea_zona_id_fkey"
            columns: ["zona_id"]
            isOneToOne: false
            referencedRelation: "zonas_reparto"
            referencedColumns: ["id"]
          },
        ]
      }
      pedidos_en_linea_items: {
        Row: {
          cantidad: number
          created_at: string
          id: string
          nombre_item: string
          nombre_variante: string
          notas: string | null
          opciones_elegidas: Json | null
          pedido_id: string
          precio_unitario: number
          variante_id: string | null
        }
        Insert: {
          cantidad: number
          created_at?: string
          id?: string
          nombre_item: string
          nombre_variante: string
          notas?: string | null
          opciones_elegidas?: Json | null
          pedido_id: string
          precio_unitario: number
          variante_id?: string | null
        }
        Update: {
          cantidad?: number
          created_at?: string
          id?: string
          nombre_item?: string
          nombre_variante?: string
          notas?: string | null
          opciones_elegidas?: Json | null
          pedido_id?: string
          precio_unitario?: number
          variante_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "pedidos_en_linea_items_pedido_id_fkey"
            columns: ["pedido_id"]
            isOneToOne: false
            referencedRelation: "pedidos_en_linea"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pedidos_en_linea_items_variante_id_fkey"
            columns: ["variante_id"]
            isOneToOne: false
            referencedRelation: "menu_variantes"
            referencedColumns: ["id"]
          },
        ]
      }
      prov_gracias_enviados: {
        Row: {
          created_at: string
          fecha: string
          proveedor_id: string
          request_id: number | null
        }
        Insert: {
          created_at?: string
          fecha: string
          proveedor_id: string
          request_id?: number | null
        }
        Update: {
          created_at?: string
          fecha?: string
          proveedor_id?: string
          request_id?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "prov_gracias_enviados_proveedor_id_fkey"
            columns: ["proveedor_id"]
            isOneToOne: false
            referencedRelation: "proveedores"
            referencedColumns: ["id"]
          },
        ]
      }
      proveedor_alias: {
        Row: {
          alias: string
          alias_norm: string | null
          created_at: string
          id: string
          proveedor_id: string
        }
        Insert: {
          alias: string
          alias_norm?: string | null
          created_at?: string
          id?: string
          proveedor_id: string
        }
        Update: {
          alias?: string
          alias_norm?: string | null
          created_at?: string
          id?: string
          proveedor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "proveedor_alias_proveedor_id_fkey"
            columns: ["proveedor_id"]
            isOneToOne: false
            referencedRelation: "proveedores"
            referencedColumns: ["id"]
          },
        ]
      }
      proveedor_envios: {
        Row: {
          created_at: string
          fuente: string
          id: string
          payload: Json
          proveedor_id: string | null
          resultado: Json | null
        }
        Insert: {
          created_at?: string
          fuente: string
          id?: string
          payload: Json
          proveedor_id?: string | null
          resultado?: Json | null
        }
        Update: {
          created_at?: string
          fuente?: string
          id?: string
          payload?: Json
          proveedor_id?: string | null
          resultado?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "proveedor_envios_proveedor_id_fkey"
            columns: ["proveedor_id"]
            isOneToOne: false
            referencedRelation: "proveedores"
            referencedColumns: ["id"]
          },
        ]
      }
      proveedor_precios: {
        Row: {
          created_at: string
          gramaje: string | null
          id: string
          precio: number
          proveedor_producto_id: string
        }
        Insert: {
          created_at?: string
          gramaje?: string | null
          id?: string
          precio: number
          proveedor_producto_id: string
        }
        Update: {
          created_at?: string
          gramaje?: string | null
          id?: string
          precio?: number
          proveedor_producto_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "proveedor_precios_proveedor_producto_id_fkey"
            columns: ["proveedor_producto_id"]
            isOneToOne: false
            referencedRelation: "proveedor_productos"
            referencedColumns: ["id"]
          },
        ]
      }
      proveedor_productos: {
        Row: {
          activo: boolean
          created_at: string
          id: string
          insumo_id: string | null
          nombre: string
          por_gramaje: boolean
          proveedor_id: string
          unidad: string | null
        }
        Insert: {
          activo?: boolean
          created_at?: string
          id?: string
          insumo_id?: string | null
          nombre: string
          por_gramaje?: boolean
          proveedor_id: string
          unidad?: string | null
        }
        Update: {
          activo?: boolean
          created_at?: string
          id?: string
          insumo_id?: string | null
          nombre?: string
          por_gramaje?: boolean
          proveedor_id?: string
          unidad?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "proveedor_productos_insumo_id_fkey"
            columns: ["insumo_id"]
            isOneToOne: false
            referencedRelation: "insumos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "proveedor_productos_proveedor_id_fkey"
            columns: ["proveedor_id"]
            isOneToOne: false
            referencedRelation: "proveedores"
            referencedColumns: ["id"]
          },
        ]
      }
      proveedores: {
        Row: {
          activo: boolean
          categoria: string | null
          contacto: string | null
          created_at: string
          depurado: boolean
          id: string
          nombre: string
          telefono: string | null
          token: string
        }
        Insert: {
          activo?: boolean
          categoria?: string | null
          contacto?: string | null
          created_at?: string
          depurado?: boolean
          id?: string
          nombre: string
          telefono?: string | null
          token?: string
        }
        Update: {
          activo?: boolean
          categoria?: string | null
          contacto?: string | null
          created_at?: string
          depurado?: boolean
          id?: string
          nombre?: string
          telefono?: string | null
          token?: string
        }
        Relationships: []
      }
      recepciones: {
        Row: {
          created_at: string
          fecha: string
          id: string
          notas: string | null
          proveedor: string
          proveedor_id: string | null
          registrado_por: string | null
          sucursal_id: string
        }
        Insert: {
          created_at?: string
          fecha?: string
          id?: string
          notas?: string | null
          proveedor: string
          proveedor_id?: string | null
          registrado_por?: string | null
          sucursal_id: string
        }
        Update: {
          created_at?: string
          fecha?: string
          id?: string
          notas?: string | null
          proveedor?: string
          proveedor_id?: string | null
          registrado_por?: string | null
          sucursal_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recepciones_proveedor_id_fkey"
            columns: ["proveedor_id"]
            isOneToOne: false
            referencedRelation: "proveedores"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recepciones_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      recepciones_detalle: {
        Row: {
          cantidad_recibida: number
          created_at: string
          id: string
          insumo_id: string
          pedido_detalle_id: string | null
          recepcion_id: string
        }
        Insert: {
          cantidad_recibida?: number
          created_at?: string
          id?: string
          insumo_id: string
          pedido_detalle_id?: string | null
          recepcion_id: string
        }
        Update: {
          cantidad_recibida?: number
          created_at?: string
          id?: string
          insumo_id?: string
          pedido_detalle_id?: string | null
          recepcion_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "recepciones_detalle_insumo_id_fkey"
            columns: ["insumo_id"]
            isOneToOne: false
            referencedRelation: "insumos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recepciones_detalle_pedido_detalle_id_fkey"
            columns: ["pedido_detalle_id"]
            isOneToOne: false
            referencedRelation: "pedidos_detalle"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "recepciones_detalle_recepcion_id_fkey"
            columns: ["recepcion_id"]
            isOneToOne: false
            referencedRelation: "recepciones"
            referencedColumns: ["id"]
          },
        ]
      }
      reservaciones: {
        Row: {
          created_at: string
          estado: string
          fecha: string
          hora: string
          id: string
          nombre_cliente: string
          notas: string | null
          num_personas: number
          registrado_por: string | null
          sucursal_id: string
          telefono: string | null
          updated_at: string
          zona_id: string
        }
        Insert: {
          created_at?: string
          estado?: string
          fecha: string
          hora: string
          id?: string
          nombre_cliente: string
          notas?: string | null
          num_personas?: number
          registrado_por?: string | null
          sucursal_id: string
          telefono?: string | null
          updated_at?: string
          zona_id: string
        }
        Update: {
          created_at?: string
          estado?: string
          fecha?: string
          hora?: string
          id?: string
          nombre_cliente?: string
          notas?: string | null
          num_personas?: number
          registrado_por?: string | null
          sucursal_id?: string
          telefono?: string | null
          updated_at?: string
          zona_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "reservaciones_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reservaciones_zona_id_fkey"
            columns: ["zona_id"]
            isOneToOne: false
            referencedRelation: "zonas_sucursal"
            referencedColumns: ["id"]
          },
        ]
      }
      sucursales: {
        Row: {
          created_at: string
          direccion: string | null
          id: string
          menu_url: string | null
          nombre: string
          pedidos_en_linea_activos: boolean
          pedidos_pausados_hasta: string | null
          pin: string | null
          prefijo_folio: string | null
          slug: string | null
          telefono_contacto: string | null
          tiempo_estimado_min: number
          venta_alcohol_en_linea: boolean
          zona_horaria: string
        }
        Insert: {
          created_at?: string
          direccion?: string | null
          id?: string
          menu_url?: string | null
          nombre: string
          pedidos_en_linea_activos?: boolean
          pedidos_pausados_hasta?: string | null
          pin?: string | null
          prefijo_folio?: string | null
          slug?: string | null
          telefono_contacto?: string | null
          tiempo_estimado_min?: number
          venta_alcohol_en_linea?: boolean
          zona_horaria?: string
        }
        Update: {
          created_at?: string
          direccion?: string | null
          id?: string
          menu_url?: string | null
          nombre?: string
          pedidos_en_linea_activos?: boolean
          pedidos_pausados_hasta?: string | null
          pin?: string | null
          prefijo_folio?: string | null
          slug?: string | null
          telefono_contacto?: string | null
          tiempo_estimado_min?: number
          venta_alcohol_en_linea?: boolean
          zona_horaria?: string
        }
        Relationships: []
      }
      terminales: {
        Row: {
          activa: boolean
          created_at: string
          id: string
          nombre: string
          orden: number
        }
        Insert: {
          activa?: boolean
          created_at?: string
          id?: string
          nombre: string
          orden?: number
        }
        Update: {
          activa?: boolean
          created_at?: string
          id?: string
          nombre?: string
          orden?: number
        }
        Relationships: []
      }
      terminales_asignacion: {
        Row: {
          created_at: string
          fecha: string
          sucursal_id: string
          terminal_id: string
        }
        Insert: {
          created_at?: string
          fecha: string
          sucursal_id: string
          terminal_id: string
        }
        Update: {
          created_at?: string
          fecha?: string
          sucursal_id?: string
          terminal_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "terminales_asignacion_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "terminales_asignacion_terminal_id_fkey"
            columns: ["terminal_id"]
            isOneToOne: false
            referencedRelation: "terminales"
            referencedColumns: ["id"]
          },
        ]
      }
      terminales_aviso_config: {
        Row: {
          activo: boolean
          hora: string
          id: number
          updated_at: string
          zona: string
        }
        Insert: {
          activo?: boolean
          hora?: string
          id?: number
          updated_at?: string
          zona?: string
        }
        Update: {
          activo?: boolean
          hora?: string
          id?: number
          updated_at?: string
          zona?: string
        }
        Relationships: []
      }
      terminales_aviso_enviado: {
        Row: {
          created_at: string
          fecha: string
          mensaje: string | null
        }
        Insert: {
          created_at?: string
          fecha: string
          mensaje?: string | null
        }
        Update: {
          created_at?: string
          fecha?: string
          mensaje?: string | null
        }
        Relationships: []
      }
      terminales_sucursal: {
        Row: {
          sucursal_id: string
          terminal_id: string
        }
        Insert: {
          sucursal_id: string
          terminal_id: string
        }
        Update: {
          sucursal_id?: string
          terminal_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "terminales_sucursal_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "terminales_sucursal_terminal_id_fkey"
            columns: ["terminal_id"]
            isOneToOne: false
            referencedRelation: "terminales"
            referencedColumns: ["id"]
          },
        ]
      }
      turno_excepciones: {
        Row: {
          created_at: string
          empleado_id: string | null
          fecha: string
          hora_entrada: string | null
          hora_salida: string | null
          id: string
          nota: string | null
          sucursal_id: string
          tipo: string
        }
        Insert: {
          created_at?: string
          empleado_id?: string | null
          fecha: string
          hora_entrada?: string | null
          hora_salida?: string | null
          id?: string
          nota?: string | null
          sucursal_id: string
          tipo: string
        }
        Update: {
          created_at?: string
          empleado_id?: string | null
          fecha?: string
          hora_entrada?: string | null
          hora_salida?: string | null
          id?: string
          nota?: string | null
          sucursal_id?: string
          tipo?: string
        }
        Relationships: [
          {
            foreignKeyName: "turno_excepciones_empleado_id_fkey"
            columns: ["empleado_id"]
            isOneToOne: false
            referencedRelation: "empleados"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "turno_excepciones_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      turnos: {
        Row: {
          activo: boolean
          area: string | null
          catalogo_turno_id: string | null
          created_at: string
          dia_semana: number
          empleado_id: string
          hora_entrada: string | null
          hora_salida: string | null
          id: string
          rol: string | null
          sucursal_id: string
        }
        Insert: {
          activo?: boolean
          area?: string | null
          catalogo_turno_id?: string | null
          created_at?: string
          dia_semana: number
          empleado_id: string
          hora_entrada?: string | null
          hora_salida?: string | null
          id?: string
          rol?: string | null
          sucursal_id: string
        }
        Update: {
          activo?: boolean
          area?: string | null
          catalogo_turno_id?: string | null
          created_at?: string
          dia_semana?: number
          empleado_id?: string
          hora_entrada?: string | null
          hora_salida?: string | null
          id?: string
          rol?: string | null
          sucursal_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "turnos_catalogo_turno_id_fkey"
            columns: ["catalogo_turno_id"]
            isOneToOne: false
            referencedRelation: "catalogo_turnos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "turnos_empleado_id_fkey"
            columns: ["empleado_id"]
            isOneToOne: false
            referencedRelation: "empleados"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "turnos_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
      verificaciones_plataforma: {
        Row: {
          cantidad_reportada: number
          cantidad_sistema: number
          created_at: string
          diferencia: number
          fecha_fin: string
          fecha_inicio: string
          id: string
          plataforma: string
          registrado_por: string | null
          sucursal_id: string
          tiene_discrepancia: boolean
        }
        Insert: {
          cantidad_reportada?: number
          cantidad_sistema?: number
          created_at?: string
          diferencia?: number
          fecha_fin: string
          fecha_inicio: string
          id?: string
          plataforma?: string
          registrado_por?: string | null
          sucursal_id: string
          tiene_discrepancia?: boolean
        }
        Update: {
          cantidad_reportada?: number
          cantidad_sistema?: number
          created_at?: string
          diferencia?: number
          fecha_fin?: string
          fecha_inicio?: string
          id?: string
          plataforma?: string
          registrado_por?: string | null
          sucursal_id?: string
          tiene_discrepancia?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "verificaciones_plataforma_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      zonas_reparto: {
        Row: {
          activa: boolean
          costo_envio: number
          created_at: string
          id: string
          nombre: string
          pedido_minimo: number
          sucursal_id: string
        }
        Insert: {
          activa?: boolean
          costo_envio?: number
          created_at?: string
          id?: string
          nombre: string
          pedido_minimo?: number
          sucursal_id: string
        }
        Update: {
          activa?: boolean
          costo_envio?: number
          created_at?: string
          id?: string
          nombre?: string
          pedido_minimo?: number
          sucursal_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "zonas_reparto_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
      zonas_sucursal: {
        Row: {
          capacidad: number | null
          created_at: string
          id: string
          nombre: string
          sucursal_id: string
        }
        Insert: {
          capacidad?: number | null
          created_at?: string
          id?: string
          nombre: string
          sucursal_id: string
        }
        Update: {
          capacidad?: number | null
          created_at?: string
          id?: string
          nombre?: string
          sucursal_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "zonas_sucursal_sucursal_id_fkey"
            columns: ["sucursal_id"]
            isOneToOne: false
            referencedRelation: "sucursales"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      avisar_terminales_dia: { Args: { p_forzar?: boolean }; Returns: string }
      checador_estado: {
        Args: { p_sucursal_id: string }
        Returns: {
          area: string
          entrada_at: string
          nombre: string
        }[]
      }
      checador_listar: {
        Args: { p_sucursal_id: string }
        Returns: {
          area: string
          empleado_id: string
          entrada_at: string
          estado: string
          nombre: string
          orden: number
        }[]
      }
      checar: {
        Args: { p_empleado_id: string; p_pin: string; p_sucursal_id: string }
        Returns: Json
      }
      checar_pin: {
        Args: { p_pin: string; p_sucursal_id: string }
        Returns: Json
      }
      compras_precios: { Args: { p_pin: string }; Returns: Json }
      compras_validar_pin: { Args: { p_pin: string }; Returns: boolean }
      crear_pedido_en_linea: {
        Args: {
          p_direccion?: string
          p_items: Json
          p_nombre_cliente: string
          p_notas_generales?: string
          p_referencias?: string
          p_sucursal_id: string
          p_telefono: string
          p_tipo: string
          p_zona_id?: string
        }
        Returns: Json
      }
      depurar_eliminar: {
        Args: { p_ids: Json; p_token: string }
        Returns: number
      }
      depurar_listar: { Args: { p_token: string }; Returns: Json }
      depurar_marcar: {
        Args: { p_depurado: boolean; p_proveedor_id: string; p_token: string }
        Returns: boolean
      }
      factura_solicitar: {
        Args: {
          p_codigo_postal: string
          p_email: string
          p_forma_pago: string
          p_razon_social: string
          p_regimen_fiscal: string
          p_rfc: string
          p_sucursal_codigo?: string
          p_telefono: string
          p_ticket_fecha?: string
          p_ticket_folio?: string
          p_ticket_foto_path: string
          p_ticket_total?: number
          p_uso_cfdi: string
        }
        Returns: Json
      }
      factura_ticket_disponible: {
        Args: { p_sucursal_codigo: string; p_ticket_folio: string }
        Returns: boolean
      }
      factura_ticket_norm: { Args: { p_folio: string }; Returns: string }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      horarios_captura_info: { Args: { p_token: string }; Returns: Json }
      horarios_captura_set: {
        Args: {
          p_dia: number
          p_empleado_id?: string
          p_rol: string
          p_token: string
        }
        Returns: Json
      }
      impl_pendiente_guardar: {
        Args: {
          p_area?: string
          p_borrar?: boolean
          p_estado?: string
          p_id?: string
          p_notas?: string
          p_pin: string
          p_responsable?: string
          p_semana?: string
          p_sucursal_id?: string
          p_titulo?: string
        }
        Returns: Json
      }
      impl_responsable_guardar: {
        Args: {
          p_borrar?: boolean
          p_id?: string
          p_notas?: string
          p_persona?: string
          p_pin: string
          p_proceso?: string
          p_puesto?: string
          p_sucursal_id?: string
          p_telefono?: string
        }
        Returns: Json
      }
      impl_validar_pin: { Args: { p_pin: string }; Returns: boolean }
      laola_fecha_negocio: { Args: { p_ts?: string }; Returns: string }
      lealtad_canjear: { Args: { p_telefono: string }; Returns: Json }
      lealtad_canjear_bienvenida: {
        Args: { p_sucursal_codigo?: string; p_telefono: string }
        Returns: Json
      }
      lealtad_canjear_cliente: {
        Args: { p_sucursal_codigo?: string; p_telefono: string }
        Returns: Json
      }
      lealtad_consultar: { Args: { p_telefono: string }; Returns: Json }
      lealtad_perfil_json: {
        Args: {
          p_cliente: Database["public"]["Tables"]["lealtad_clientes"]["Row"]
        }
        Returns: Json
      }
      lealtad_registrar: {
        Args: {
          p_apellido_materno: string
          p_apellido_paterno: string
          p_consentimiento?: boolean
          p_cumpleanos: string
          p_primer_nombre: string
          p_segundo_nombre?: string
          p_sucursal_codigo?: string
          p_telefono: string
        }
        Returns: Json
      }
      lealtad_visita: {
        Args: {
          p_apellido_materno?: string
          p_apellido_paterno?: string
          p_consentimiento?: boolean
          p_cumpleanos?: string
          p_folio?: string
          p_primer_nombre?: string
          p_segundo_nombre?: string
          p_sucursal_codigo?: string
          p_telefono: string
        }
        Returns: Json
      }
      makatea_push_clientes: {
        Args: { p_cliente_ids: string[] }
        Returns: undefined
      }
      makatea_reconciliar: { Args: never; Returns: undefined }
      norm_proveedor: { Args: { txt: string }; Returns: string }
      obtener_pedido_por_token: { Args: { p_token: string }; Returns: Json }
      panel_implementacion: {
        Args: { p_desde?: string; p_hasta?: string; p_pin: string }
        Returns: Json
      }
      panel_implementacion_lealtad: {
        Args: { p_desde?: string; p_hasta?: string; p_pin: string }
        Returns: Json
      }
      prov_catalogo: { Args: { p_token: string }; Returns: Json }
      prov_gracias_diagnostico: {
        Args: { p_dias?: number }
        Returns: {
          error: string
          fecha: string
          proveedor: string
          respuesta: string
          status: number
          telefono: string
        }[]
      }
      prov_guardar_precios: {
        Args: { p_gramajes?: Json; p_normales?: Json; p_token: string }
        Returns: Json
      }
      prov_set_camaron: {
        Args: { p_items: Json; p_producto_id: string; p_token: string }
        Returns: boolean
      }
      prov_set_precio: {
        Args: { p_precio: number; p_producto_id: string; p_token: string }
        Returns: boolean
      }
      sucursal_en_horario: { Args: { p_sucursal_id: string }; Returns: boolean }
      sucursal_set_menu: {
        Args: { p_menu_url: string; p_sucursal_id: string }
        Returns: undefined
      }
      terminales_mensaje_dia: { Args: { p_fecha?: string }; Returns: string }
      vigilar_cortes: { Args: never; Returns: undefined }
    }
    Enums: {
      app_role: "admin" | "user"
      tipo_corte: "momento" | "cierre"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "user"],
      tipo_corte: ["momento", "cierre"],
    },
  },
} as const
