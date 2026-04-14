#' Banque de niveaux certifiés
#' @export
charger_niveau <- function(id = 1) {
  niveaux <- list(
    # Niveau 1 : Sujet original
    matrix(c(2, 2, NA, NA, NA, NA, NA, NA, 3, 2, NA, NA, NA, NA, 1, 3, 0, NA, NA, 2, NA, 3, 2, 2, NA), nrow=5, byrow=T),
    # Niveau 2 : Ton image (10 indices)
    matrix(c(NA, 2, 2, NA, NA, 3, NA, NA, 3, NA, NA, NA, 0, NA, NA, NA, 2, NA, 2, NA, NA, NA, 3, 2, NA), nrow=5, byrow=T),
    # Niveau 3 : Ton image (9 indices)
    matrix(c(NA, 0, NA, 2, NA, 3, NA, NA, NA, 3, NA, NA, 1, NA, NA, 2, NA, NA, NA, 3, NA, 3, NA, 0, NA), nrow=5, byrow=T)
  )
  return(niveaux[[as.numeric(id)]])
}
