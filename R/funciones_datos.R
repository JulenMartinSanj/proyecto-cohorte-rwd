# R/funciones_datos.R
library(tidyverse)
library(lubridate)

# 1. Función para limpiar la tabla de pacientes
limpiar_pacientes <- function(ruta_archivo) {
  read_csv(ruta_archivo, show_col_types = FALSE) %>%
    # Seleccionamos solo las columnas que nos interesan
    select(Id, BIRTHDATE, GENDER, RACE) %>%
    # Las renombramos al español y a minúsculas para trabajar más fácil
    rename(
      patient_id = Id, 
      fecha_nacimiento = BIRTHDATE, 
      sexo = GENDER, 
      raza = RACE
    ) %>%
    # Convertimos la fecha de nacimiento a formato fecha de R
    mutate(fecha_nacimiento = ymd(fecha_nacimiento))
}

# 2. Función para definir la cohorte de diabéticos
definir_cohorte_diabetes <- function(datos_pacientes, ruta_conditions) {
  
  # Cargamos y limpiamos diagnósticos
  diagnosticos <- read_csv(ruta_conditions, show_col_types = FALSE) %>%
    select(PATIENT, START, DESCRIPTION) %>%
    rename(
      patient_id = PATIENT, 
      fecha_diagnostico = START, 
      diagnostico = DESCRIPTION
    )
  
  # Filtramos solo la diabetes
  diabetes_filtrado <- diagnosticos %>%
    # str_detect busca la palabra "diabetes" (pasando todo a minúsculas antes)
    filter(str_detect(tolower(diagnostico), "diabetes")) %>%
    # Si un paciente fue diagnosticado varias veces, nos quedamos con la primera fecha
    group_by(patient_id) %>%
    slice_min(fecha_diagnostico, n = 1) %>%
    ungroup() %>%
    # Convertimos la fecha
    mutate(fecha_diagnostico = ymd(fecha_diagnostico))
  
  # EL CRUCE MÁGICO: Unimos pacientes con sus diagnósticos. 
  # Al usar inner_join, los pacientes sin diabetes desaparecerán de la tabla automáticamente.
  cohorte_final <- inner_join(datos_pacientes, diabetes_filtrado, by = "patient_id") %>%
    # Calculamos la edad en el momento del diagnóstico
    mutate(
      edad_diagnostico = as.numeric(difftime(fecha_diagnostico, fecha_nacimiento, units = "days")) / 365.25
    ) %>%
    # Filtramos a mayores de 18 años (típico criterio de inclusión)
    filter(edad_diagnostico >= 18)
  
  return(cohorte_final)
}

# 3. Función para extraer variables clínicas basales (VERSIÓN ROBUSTA)
anadir_variables_basales <- function(cohorte_base, ruta_observations) {
  
  observaciones <- read_csv(ruta_observations, show_col_types = FALSE) %>%
    select(PATIENT, DATE, DESCRIPTION, VALUE) %>%
    rename(
      patient_id = PATIENT,
      fecha_observacion = DATE,
      variable = DESCRIPTION,
      valor = VALUE
    ) %>%
    filter(str_detect(tolower(variable), "hemoglobin a1c|body mass index|systolic blood pressure")) %>%
    mutate(
      fecha_observacion = as_date(fecha_observacion), 
      valor = as.numeric(valor)
    )
  
  datos_basales <- cohorte_base %>%
    select(patient_id, fecha_diagnostico) %>%
    left_join(observaciones, by = "patient_id") %>%
    filter(fecha_observacion <= fecha_diagnostico) %>%
    mutate(
      variable = case_when(
        str_detect(tolower(variable), "hemoglobin") ~ "hba1c",
        str_detect(tolower(variable), "body mass") ~ "imc",
        str_detect(tolower(variable), "systolic") ~ "pas"
      )
    ) %>%
    drop_na(variable) %>%
    group_by(patient_id, variable) %>%
    slice_max(fecha_observacion, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    select(patient_id, variable, valor) %>%
    # AQUÍ ESTÁ LA MAGIA:
    pivot_wider(
      names_from = variable, 
      values_from = valor,
      values_fn = mean # Si hay duplicados el mismo día, toma la media para forzar que sea numérico
    )
  
  cohorte_completa <- left_join(cohorte_base, datos_basales, by = "patient_id")
  
  return(cohorte_completa)
}