#' Lancer l'application Slitherlink
#' @export
lancer_jeu <- function() {
  library(shiny); library(ggplot2)
  ui <- fluidPage(
    tags$head(
      tags$script(src = "https://cdn.jsdelivr.net/npm/canvas-confetti@1.5.1/dist/confetti.browser.min.js"),
      tags$script("Shiny.addCustomMessageHandler('fete', function(m) {
        confetti({particleCount:150, spread:70, origin:{y:0.6}});
        document.getElementById('audio_applaudissements').play();
      });")
    ),
    titlePanel("Slitherlink"),
    sidebarLayout(
      sidebarPanel(
        selectInput("id_niveau", "Choisir un niveau :", choices = list("Niveau 1"=1, "Niveau 2"=2, "Niveau 3"=3)),
        hr(),
        conditionalPanel(condition = "input.mode_aide == true",
                         div(style = "text-align:center; font-size: 24px; color: red; font-weight: bold;", textOutput("affichage_chrono"))
        ),
        checkboxInput("mode_aide", "Mode aide (Chronomètre 1min + Couleurs)", value = FALSE),
        hr(),
        actionButton("reset", "Réinitialiser la grille", class = "btn-danger", style="width:100%"),
        br(), br(),
        actionButton("verifier", "Vérifier la solution finale", class = "btn-primary", style="width:100%"),
        hr(),
        strong("Progression :"),
        htmlOutput("message_statut"),
        tags$audio(id = "audio_applaudissements", src = "https://www.myinstants.com/media/sounds/applaudissements.mp3")
      ),
      mainPanel(plotOutput("grille_plot", click = "plot_click", height = "700px"))
    )
  )

  server <- function(input, output, session) {
    niveau <- reactive({ charger_niveau(input$id_niveau) })
    jeu <- reactiveValues(h = matrix(F, 6, 5), v = matrix(F, 5, 6), temps = 60, victoire = F, attente = 20, modal = F)

    observeEvent(input$id_niveau, { reinitialiser() })
    observeEvent(input$reset, { reinitialiser() })
    observeEvent(input$confirm_reset, { reinitialiser(); removeModal() })

    reinitialiser <- function() {
      jeu$h[,] <- F; jeu$v[,] <- F; jeu$temps <- 60; jeu$attente <- 20; jeu$victoire <- F; jeu$modal <- F
      updateCheckboxInput(session, "mode_aide", value = FALSE)
    }

    observe({
      if (input$mode_aide && !jeu$victoire) {
        invalidateLater(1000, session)
        isolate({
          jeu$temps <- jeu$temps - 1
          if (jeu$temps <= 0) { showModal(modalDialog(title="TEMPS ÉCOULÉ", "La grille a été réinitialisée.")); reinitialiser() }
        })
      }
    })

    observe({
      if (jeu$victoire && !jeu$modal) {
        invalidateLater(1000, session)
        isolate({
          jeu$attente <- jeu$attente - 1
          if (jeu$attente <= 0) {
            jeu$modal <- T
            showModal(modalDialog(title="PARTIE TERMINÉE", div(style="text-align:center;", h4("Félicitations !"), p("Voulez-vous recommencer ?")),
                                  footer = tagList(actionButton("confirm_reset", "Oui", class="btn-success"), modalButton("Non"))))
          }
        })
      }
    })

    output$affichage_chrono <- renderText({ sprintf("%02d:%02d", jeu$temps %/% 60, jeu$temps %% 60) })

    output$message_statut <- renderUI({
      if (jeu$victoire) {
        msg <- if (input$mode_aide) paste0("✅ RÉSOLU en ", 60-jeu$temps, "s ! 🎉") else "✅ RÉSOLU ! 🎉"
        info <- if(!jeu$modal) paste0("<br><small>(Fenêtre de reset dans ", jeu$attente, "s)</small>") else ""
        return(HTML(paste0("<span style='color:green; font-weight:bold;'>", msg, "</span>", info)))
      }
      mat_err <- verifier_chiffres(niveau(), jeu$h, jeu$v)
      nb_ok <- sum(!is.na(niveau())) - sum(mat_err)
      color <- if(nb_ok == sum(!is.na(niveau()))) "green" else "orange"
      HTML(paste0("<span style='color:", color, "; font-weight:bold;'>Cases respectées : ", nb_ok, " / ", sum(!is.na(niveau())), "</span>"))
    })

    observeEvent(input$verifier, {
      if (jeu$victoire) return()
      err_c <- verifier_chiffres(niveau(), jeu$h, jeu$v)
      pts_ok <- verifier_points(jeu$h, jeu$v)
      if (!any(err_c) && pts_ok && verifier_boucle_unique(jeu$h, jeu$v)) {
        jeu$victoire <- T; session$sendCustomMessage("fete", list())
      } else {
        showNotification("La solution est incomplète, se croise, ou contient plusieurs boucles.", type="error")
      }
    })

    observeEvent(input$plot_click, {
      if (jeu$victoire) return()
      px <- input$plot_click$x; py <- input$plot_click$y
      if(is.null(px)) return()
      dist_h <- abs(px - (col(jeu$h) + 0.5)) + abs(py - row(jeu$h))
      dist_v <- abs(px - col(jeu$v)) + abs(py - (row(jeu$v) + 0.5))
      if (min(dist_h) < min(dist_v) && min(dist_h) < 0.4) {
        idx <- which(dist_h == min(dist_h), arr.ind = TRUE)[1,]; jeu$h[idx[1], idx[2]] <- !jeu$h[idx[1], idx[2]]
      } else if (min(dist_v) < 0.4) {
        idx <- which(dist_v == min(dist_v), arr.ind = TRUE)[1,]; jeu$v[idx[1], idx[2]] <- !jeu$v[idx[1], idx[2]]
      }
    })
    output$grille_plot <- renderPlot({ dessiner_grille(niveau(), jeu$h, jeu$v, input$mode_aide) })
  }
  shinyApp(ui, server)
}
