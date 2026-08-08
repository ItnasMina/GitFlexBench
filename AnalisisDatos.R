# ==============================================================================
# SCRIPT DE ANÁLISIS PARA SENSORES PIEZORESISTIVOS (TPU / ELASTÓMEROS)
# FASE 1: Ingesta Masiva, Limpieza y Feature Engineering Base
# ==============================================================================

# 1. CARGA DE LIBRERÍAS
# Si no las tienes, instala con: install.packages(c("tidyverse", "readxl", "fs"))
library(tidyverse)
library(readxl)
library(fs) # Para manejar directorios y buscar archivos fácilmente

# 2. CONFIGURACIÓN DEL DIRECTORIO
# IMPORTANTE: Cambia esta ruta a la carpeta donde tengas todos los archivos Excel.
# Usa barras normales (/) o dobles invertidas (\\).
ruta_excels <- "C:/ruta/a/tus/excels" 

# Obtenemos la lista de todos los archivos .xlsx en la carpeta
lista_archivos <- dir_ls(ruta_excels, glob = "*.xlsx")

# 3. FUNCIÓN DE EXTRACCIÓN (Lee 1 archivo y extrae datos y metadatos)
extraer_datos_ensayo <- function(archivo_path) {
  
  # A. Leer Metadatos (Pestaña 'Specimen_Info')
  info_raw <- read_excel(archivo_path, sheet = "Specimen_Info")
  
  # Convertimos la tabla vertical a una fila horizontal limpia
  info_limpia <- info_raw %>%
    pivot_wider(names_from = Attribute, values_from = Value) %>%
    # Renombramos columnas para evitar problemas con espacios o símbolos
    # Asegúrate de que los nombres de las columnas coincidan con los de tu Excel
    rename(
      Longitud_cm = `Length`,
      Ancho_cm = `Width (cm)`,
      Grosor_mm = `Thickness (mm)`,
      Nombre_Probeta = `Specimen Name`,
      Infill = `Infill` # Asumo que has añadido esta fila en el excel
    )
  
  # B. Leer Datos del Ensayo (Pestaña 'Test_Data')
  datos_raw <- read_excel(archivo_path, sheet = "Test_Data")
  
  # Unimos los metadatos a cada fila del ensayo
  datos_completos <- datos_raw %>%
    bind_cols(info_limpia) %>%
    mutate(
      Archivo_Origen = basename(archivo_path) # Trazabilidad
    )
  
  return(datos_completos)
}

# 4. INGESTA MASIVA
print("Iniciando lectura de archivos... Esto puede tardar unos segundos.")
df_master <- map_df(lista_archivos, extraer_datos_ensayo)
print("¡Lectura finalizada!")

# 5. LIMPIEZA INICIAL Y CÁLCULO DE MÉTRICAS BÁSICAS POR CICLO
# Limpiamos valores erróneos (como los -1 de los contactos fallidos)
df_clean <- df_master %>%
  filter(Resistance != -1 & Average_Resistance != -1)

if(nrow(df_clean) == 0) {
  warning("ALERTA: Tras eliminar las filas con Resistance == -1, el conjunto de datos está vacío. Comprueba los Excels.")
} else {
  
  # Agrupamos por Archivo, Probeta y Ciclo para calcular las métricas iniciales
  resumen_ciclos <- df_clean %>%
    group_by(Archivo_Origen, Nombre_Probeta, Infill, Grosor_mm, Longitud_cm, Cycle) %>%
    summarise(
      # RESOLUCIÓN: Sensibilidad máxima en el ciclo
      GF_Maximo = max(Gauge_Factor, na.rm = TRUE),
      Strain_Maximo = max(Strain, na.rm = TRUE),
      
      # ESTABILIDAD: Variación de la resistencia base (Drift)
      # Tomamos la resistencia cuando el motor está en Posición 0
      Posicion_Min = min(Position, na.rm = TRUE),
      Resistencia_Base = mean(Resistance[Position == min(Position)], na.rm = TRUE),
      
      .groups = 'drop'
    )
  
  print("Métricas básicas por ciclo calculadas con éxito.")
  head(resumen_ciclos)
}

