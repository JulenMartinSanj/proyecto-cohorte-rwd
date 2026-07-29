# _targets.R
library(targets)
library(tarchetypes) # <-- AÑADIDO: paquete para funciones avanzadas como Quarto

source("R/funciones_datos.R")
source("R/funciones_analisis.R")

tar_option_set(packages = c("tidyverse", "lubridate", "gtsummary"))

list(
  tar_target(archivo_pacientes, "data/raw/patients.csv", format = "file"),
  tar_target(archivo_condiciones, "data/raw/conditions.csv", format = "file"),
  tar_target(archivo_observaciones, "data/raw/observations.csv", format = "file"),
  
  tar_target(pacientes_limpios, limpiar_pacientes(archivo_pacientes)),
  tar_target(cohorte_diabeticos, definir_cohorte_diabetes(pacientes_limpios, archivo_condiciones)),
  tar_target(cohorte_final, anadir_variables_basales(cohorte_diabeticos, archivo_observaciones)),
  
  tar_target(tabla_uno, crear_tabla_uno(cohorte_final)),
  
  # EL INFORME AUTOMÁTICO
  # tar_render detecta qué objetos de targets se usan dentro del .rmd y crea las conexiones
  tar_render(informe_html, "reports/informe.Rmd")
)