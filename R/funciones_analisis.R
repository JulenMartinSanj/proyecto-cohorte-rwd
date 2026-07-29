# R/funciones_analisis.R
library(gtsummary)
library(tidyverse)

crear_tabla_uno <- function(cohorte) {
  cohorte %>%
    # Seleccionamos solo las variables que queremos en la tabla
    select(sexo, raza, edad_diagnostico, hba1c, imc, pas) %>%
    # tbl_summary genera automáticamente estadísticas descriptivas
    tbl_summary(
      by = sexo, # Estratificamos (dividimos columnas) por sexo
      missing = "ifany", # Muestra cuántos NA (valores perdidos) hay
      missing_text = "Valores perdidos",
      label = list(
        edad_diagnostico ~ "Edad al diagnóstico (años)",
        raza ~ "Raza",
        hba1c ~ "HbA1c (%)",
        imc ~ "Índice de Masa Corporal",
        pas ~ "Presión Arterial Sistólica (mmHg)"
      ),
      # Configuramos cómo se muestran los números (Media (Desviación Típica))
      statistic = list(
        all_continuous() ~ "{mean} ({sd})",
        all_categorical() ~ "{n} ({p}%)"
      )
    ) %>%
    add_overall() %>% # Añade una columna con el total de la cohorte
    add_p() %>%       # Calcula el p-valor para ver si hay diferencias significativas entre sexos
    modify_header(label = "**Característica Basal**") %>%
    bold_labels()
}