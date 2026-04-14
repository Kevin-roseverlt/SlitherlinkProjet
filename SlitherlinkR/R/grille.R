#' Dessiner la grille avec points agrandis
#' @export
dessiner_grille <- function(niveau, segments_h, segments_v, afficher_erreurs = FALSE) {
  library(ggplot2)
  n_l <- nrow(niveau); n_c <- ncol(niveau)
  points <- expand.grid(x = 1:(n_c + 1), y = 1:(n_l + 1))
  chiffres <- expand.grid(x = 1:n_c, y = 1:n_l)
  chiffres$valeur <- as.vector(t(niveau))
  chiffres$x_centre <- chiffres$x + 0.5
  chiffres$y_centre <- (n_l + 1) - chiffres$y + 0.5

  chiffres$couleur <- "black"
  if (afficher_erreurs) {
    mat_err <- verifier_chiffres(niveau, segments_h, segments_v)
    chiffres$couleur <- ifelse(as.vector(t(mat_err)), "red", "darkgreen")
  }

  df_h <- data.frame(); df_v <- data.frame()
  if(any(segments_h)) {
    idx <- which(segments_h, arr.ind = TRUE)
    df_h <- data.frame(x = idx[,2], xend = idx[,2]+1, y = idx[,1], yend = idx[,1])
  }
  if(any(segments_v)) {
    idx <- which(segments_v, arr.ind = TRUE)
    df_v <- data.frame(x = idx[,2], xend = idx[,2], y = idx[,1], yend = idx[,1]+1)
  }

  ggplot() +
    {if(nrow(df_h) > 0) geom_segment(data = df_h, aes(x=x, y=y, xend=xend, yend=yend), size=2, lineend="round")}+
    {if(nrow(df_v) > 0) geom_segment(data = df_v, aes(x=x, y=y, xend=xend, yend=yend), size=2, lineend="round")}+
    geom_point(data = points, aes(x = x, y = y), size = 8, color = "black") +
    geom_text(data = subset(chiffres, !is.na(valeur)),
              aes(x = x_centre, y = y_centre, label = valeur, color = couleur),
              size = 10, fontface = "bold") +
    scale_color_identity() + theme_void() + coord_fixed()
}

#' Vérifier les chiffres des cases
#' @export
verifier_chiffres <- function(niveau, segments_h, segments_v) {
  n_l <- nrow(niveau); n_c <- ncol(niveau)
  erreurs <- matrix(FALSE, nrow = n_l, ncol = n_c)
  for (i in 1:n_l) {
    for (j in 1:n_c) {
      valeur <- niveau[i, j]
      if (!is.na(valeur)) {
        y_t <- (n_l + 1) - i + 1; y_b <- (n_l + 1) - i
        count <- segments_h[y_t, j] + segments_h[y_b, j] + segments_v[y_b, j] + segments_v[y_b, j+1]
        if (count != valeur) erreurs[i, j] <- TRUE
      }
    }
  }
  return(erreurs)
}

#' Vérifier la règle des points (0 ou 2)
#' @export
verifier_points <- function(segments_h, segments_v) {
  n_lp <- nrow(segments_h); n_cp <- ncol(segments_v)
  for (i in 1:n_lp) {
    for (j in 1:n_cp) {
      h_g <- if(j > 1) segments_h[i, j-1] else 0
      h_d <- if(j < n_cp) segments_h[i, j] else 0
      v_b <- if(i > 1) segments_v[i-1, j] else 0
      v_h <- if(i < n_lp) segments_v[i, j] else 0
      somme <- h_g + h_d + v_b + v_h
      if (somme > 0 && somme != 2) return(FALSE)
    }
  }
  return(TRUE)
}

#' Vérifier s'il n'y a qu'une seule boucle (BFS)
#' @export
verifier_boucle_unique <- function(segments_h, segments_v) {
  edges <- list()
  if(any(segments_h)) {
    idx <- which(segments_h, arr.ind = TRUE)
    for(i in 1:nrow(idx)) edges[[length(edges)+1]] <- c(paste(idx[i,1], idx[i,2]), paste(idx[i,1], idx[i,2]+1))
  }
  if(any(segments_v)) {
    idx <- which(segments_v, arr.ind = TRUE)
    for(i in 1:nrow(idx)) edges[[length(edges)+1]] <- c(paste(idx[i,1], idx[i,2]), paste(idx[i,1]+1, idx[i,2]))
  }
  if (length(edges) == 0) return(FALSE)
  visites <- rep(FALSE, length(edges)); pile <- c(1); visites[1] <- TRUE; count <- 0
  while(length(pile) > 0) {
    curr_idx <- pile[1]; pile <- pile[-1]; count <- count + 1
    curr_edge <- edges[[curr_idx]]
    for(i in 1:length(edges)) {
      if(!visites[i] && any(edges[[i]] %in% curr_edge)) { visites[i] <- TRUE; pile <- c(pile, i) }
    }
  }
  return(count == length(edges))
}
