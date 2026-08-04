# R/funciones_imputacion.R
library(tidyverse)
library(naniar)
library(mice)

# 1. Función para visualizar el patrón de NAs
explorar_datos_faltantes <- function(cohorte) {
  
  # Seleccionamos solo las variables clínicas que pueden tener NAs
  datos_clinicos <- cohorte %>%
    select(edad_diagnostico, hba1c, imc, pas)
  
  # Generamos un gráfico de diagnóstico de NAs
  grafico_nas <- gg_miss_upset(datos_clinicos)
  
  return(grafico_nas)
}

# 2. Función para realizar la imputación múltiple
imputar_datos <- function(cohorte) {
  
  # Seleccionamos las columnas que MICE usará para buscar patrones
  # (Quitamos identificadores y fechas para no confundir al algoritmo)
  datos_modelo <- cohorte %>%
    select(patient_id, edad_diagnostico, sexo, raza, hba1c, imc, pas)
  
  # Ejecutamos MICE
  # m = 5: Crea 5 versiones distintas de los datos rellenados
  # method = "pmm" (Predictive Mean Matching): Es el estándar oro para datos clínicos 
  # porque asegura que los datos imputados son realistas (ej. no te pondrá un IMC negativo).
  imputacion <- mice(
    data = datos_modelo, 
    m = 5, 
    maxit = 5, 
    method = "pmm", 
    seed = 123, # Fijamos la semilla para que sea 100% reproducible
    printFlag = FALSE # Silenciamos el texto para que targets no se ensucie
  )
  
  # Extraemos el primer dataset completo (versión 1 de 5) para nuestro pipeline general
  # En investigación muy avanzada se usan los 5, pero para este nivel, 
  # extraer uno derivado del modelo predictivo PMM ya es un estándar altísimo.
  datos_completos <- complete(imputacion, action = 1)
  
  # Volvemos a unir estos datos limpios y completos con la cohorte original
  cohorte_imputada <- cohorte %>%
    select(-hba1c, -imc, -pas, -sexo, -raza, -edad_diagnostico) %>% 
    left_join(datos_completos, by = "patient_id")
  
  return(cohorte_imputada)
}