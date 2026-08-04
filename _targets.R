library(targets)
library(tarchetypes)

source("R/funciones_datos.R")
source("R/funciones_analisis.R")
source("R/funciones_imputacion.R") 
source("R/funciones_modelo.R") 

# <-- NUEVO: Añadimos naniar y mice a la lista de paquetes
tar_option_set(packages = c("tidyverse", "lubridate", "gtsummary", "naniar", "mice")) 

list(
  tar_target(archivo_pacientes, "data/raw/patients.csv", format = "file"),
  tar_target(archivo_condiciones, "data/raw/conditions.csv", format = "file"),
  tar_target(archivo_observaciones, "data/raw/observations.csv", format = "file"),
  
  tar_target(pacientes_limpios, limpiar_pacientes(archivo_pacientes)),
  tar_target(cohorte_diabeticos, definir_cohorte_diabetes(pacientes_limpios, archivo_condiciones)),
  tar_target(cohorte_final, anadir_variables_basales(cohorte_diabeticos, archivo_observaciones)),
  
  tar_target(tabla_uno, crear_tabla_uno(cohorte_final)),
  
  tar_target(grafico_nas, explorar_datos_faltantes(cohorte_final)),
  tar_target(cohorte_imputada, imputar_datos(cohorte_final)),
  
  # <-- NUEVO TARGET: El modelo predictivo usa la cohorte imputada, no la original
  tar_target(modelo_riesgo, entrenar_modelo_logistico(cohorte_imputada)),
  
  tar_render(informe_html, "reports/informe.Rmd")
)