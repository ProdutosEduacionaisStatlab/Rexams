library(shiny)
source("R/helpers.R")

ui <- fluidPage(
  titlePanel("Gerador de Provas Automáticas — R/Exams"),

  sidebarLayout(
    sidebarPanel(
      selectInput("disciplina", "1. Disciplina:",
                  choices = list_disciplinas()),

      uiOutput("dificuldade_ui"),

      numericInput("n_questoes", "2. Número de questões na prova:",
                   value = 2, min = 1, step = 1),

      numericInput("n_versoes", "3. Número de versões (A, B, C...):",
                   value = 1, min = 1, max = 20, step = 1),

      selectInput("formato", "4. Formato de saída:",
                  choices = c("PDF (impressão)" = "pdf",
                              "HTML (online)"    = "html",
                              "Moodle (XML)"     = "moodle")),

      actionButton("gerar", "Gerar Prova", class = "btn-primary"),

      br(), br(),
      downloadButton("baixar", "Baixar Prova + Gabarito")
    ),

    mainPanel(
      h4("Status"),
      verbatimTextOutput("status"),
      h4("Questões disponíveis com os filtros escolhidos"),
      tableOutput("preview_questoes")
    )
  )
)

server <- function(input, output, session) {

  output$dificuldade_ui <- renderUI({
    req(input$disciplina)
    difs <- list_dificuldades(input$disciplina)
    checkboxGroupInput("dificuldade", "1b. Dificuldade:",
                        choices = difs, selected = difs)
  })

  questoes_filtradas <- reactive({
    req(input$disciplina, input$dificuldade)
    list_questoes(input$disciplina, input$dificuldade)
  })

  output$preview_questoes <- renderTable({
    arquivos <- questoes_filtradas()
    data.frame(arquivo = basename(arquivos))
  })

  resultado_geracao <- eventReactive(input$gerar, {
    arquivos <- questoes_filtradas()
    withProgress(message = "Gerando prova(s)...", value = 0.3, {
      res <- tryCatch({
        generate_exam(
          arquivos    = arquivos,
          n_questoes  = input$n_questoes,
          n_versoes   = input$n_versoes,
          formato     = input$formato
        )
      }, error = function(e) {
        list(erro = conditionMessage(e))
      })
      incProgress(0.7)
      res
    })
  })

  output$status <- renderPrint({
    res <- resultado_geracao()
    if (!is.null(res$erro)) {
      cat("Erro:", res$erro)
    } else {
      cat("Prova gerada com sucesso!\n")
      cat("Arquivos:\n")
      print(basename(res$arquivos_gerados))
    }
  })

  output$baixar <- downloadHandler(
    filename = function() paste0("prova_", Sys.Date(), ".zip"),
    content = function(file) {
      res <- resultado_geracao()
      req(is.null(res$erro))
      zip_path <- zip_exam_output(res$dir)
      file.copy(zip_path, file)
    }
  )
}

shinyApp(ui, server)
