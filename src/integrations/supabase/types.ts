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
      insumo_sucursal: {
        Row: {
          activo: boolean
          costo: number | null
          created_at: string
          id: string
          insumo_id: string
          nivel_par: number | null
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
          nivel_par?: number | null
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
          nivel_par?: number | null
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
          id: string
          nombre: string
          unidad: string | null
        }
        Insert: {
          activo?: boolean
          categoria_id: string
          created_at?: string
          id?: string
          nombre: string
          unidad?: string | null
        }
        Update: {
          activo?: boolean
          categoria_id?: string
          created_at?: string
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
          id: string
          insumo_id: string
          pedido_id: string
        }
        Insert: {
          cantidad_pedida?: number
          cantidad_sugerida?: number | null
          created_at?: string
          existencia?: number | null
          id?: string
          insumo_id: string
          pedido_id: string
        }
        Update: {
          cantidad_pedida?: number
          cantidad_sugerida?: number | null
          created_at?: string
          existencia?: number | null
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
      proveedor_precios: {
        Row: {
          created_at: string
          id: string
          precio: number
          proveedor_producto_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          precio: number
          proveedor_producto_id: string
        }
        Update: {
          created_at?: string
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
          proveedor_id: string
          unidad: string | null
        }
        Insert: {
          activo?: boolean
          created_at?: string
          id?: string
          insumo_id?: string | null
          nombre: string
          proveedor_id: string
          unidad?: string | null
        }
        Update: {
          activo?: boolean
          created_at?: string
          id?: string
          insumo_id?: string | null
          nombre?: string
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
          registrado_por: string | null
          sucursal_id: string
        }
        Insert: {
          created_at?: string
          fecha?: string
          id?: string
          notas?: string | null
          proveedor: string
          registrado_por?: string | null
          sucursal_id: string
        }
        Update: {
          created_at?: string
          fecha?: string
          id?: string
          notas?: string | null
          proveedor?: string
          registrado_por?: string | null
          sucursal_id?: string
        }
        Relationships: [
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
          nombre: string
          pin: string | null
        }
        Insert: {
          created_at?: string
          direccion?: string | null
          id?: string
          nombre: string
          pin?: string | null
        }
        Update: {
          created_at?: string
          direccion?: string | null
          id?: string
          nombre?: string
          pin?: string | null
        }
        Relationships: []
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
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      prov_add_producto: {
        Args: { p_nombre: string; p_token: string; p_unidad: string }
        Returns: string
      }
      prov_catalogo: { Args: { p_token: string }; Returns: Json }
      prov_set_precio: {
        Args: { p_precio: number; p_producto_id: string; p_token: string }
        Returns: boolean
      }
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
