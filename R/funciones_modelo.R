# R/funciones_modelo.R
library(tidyverse)
library(gtsummary)

entrenar_modelo_logistico <- function(cohorte) {
  
  # 1. Crear la variable dependiente (Binaria: 1 = Sí, 0 = No)
  # Definimos "Mal control glucémico" clínico como una HbA1c mayor o igual a 8.0
  datos_modelo <- cohorte %>%
    mutate(mal_control = ifelse(hba1c >= 6.5, 1, 0))
  
  # 2. Entrenar el modelo
  # Predecimos el mal control usando edad, sexo, IMC y presión arterial
  modelo <- glm(
    mal_control ~ edad_diagnostico + sexo + imc + pas,
    data = datos_modelo,
    family = binomial(link = "logit") # Esto le dice a R que es regresión logística
  )
  
  # 3. Formatear los resultados para publicación
  # exponentiate = TRUE transforma los coeficientes en Odds Ratios (OR)
  tabla_resultados <- tbl_regression(modelo, exponentiate = TRUE) %>%
    bold_p() %>% # Pone en negrita los p-valores significativos (< 0.05)
    bold_labels() %>%
    modify_header(label = "**Predictor**") %>%
    modify_caption("**Análisis Multivariante: Predictores de HbA1c ≥ 6.5**")
  
  return(tabla_resultados)
}