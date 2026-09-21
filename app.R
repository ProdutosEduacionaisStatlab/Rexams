library(shiny)
source("R/helpers.R")
source("R/ia_helpers.R")

ui <- fluidPage(
  titlePanel("Gerador de Provas Automáticas — R/Exams"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("disciplina", "1. Disciplina:",
                  choices = list_disciplinas()),
      
      uiOutput("tema_ui"),
      
      numericInput("n_questoes", "2. Número de questões na prova:",
                   value = 2, min = 1, step = 1),
      
      numericInput("n_versoes", "3. Número de versões (A, B, C...):",
                   value = 1, min = 1, max = 20, step = 1),
      
      selectInput("formato", "4. Formato de saída:",
                  choices = c("PDF (impressão)" = "pdf",
                              "HTML (online)"    = "html",
                              "Moodle (XML)"     = "moodle")),
      
      radioButtons("com_solucao", "5. Gerar com solução?",
                   choices = c("Sem solução (prova)"   = "sem",
                               "Com solução (gabarito)" = "com"),
                   selected = "sem", inline = TRUE),
      
      actionButton("gerar", "Gerar Prova", class = "btn-primary"),
      
      br(), br(),
      downloadButton("baixar", "Baixar Prova + Gabarito"),
      hr(),
      h4("Gerar nova questão com IA"),

      selectInput("ia_disciplina", "Disciplina desta questão:",
                  choices = list_disciplinas()),

      uiOutput("ia_tema_ui"),

      radioButtons("ia_fonte", "Fonte da questão:",
                   choices = c("Colar texto" = "texto",
                               "Enviar arquivo (PDF ou Word)" = "arquivo"),
                   selected = "texto", inline = TRUE),

      conditionalPanel(
        condition = "input.ia_fonte == 'texto'",
        textAreaInput("ia_texto", "Descreva ou cole a questão:",
                      rows = 6, width = "100%")
      ),

      conditionalPanel(
        condition = "input.ia_fonte == 'arquivo'",
        fileInput("ia_arquivo", "Arquivo (.pdf ou .docx):",
                 accept = c(".pdf", ".docx"))
      ),

      actionButton("ia_gerar", "Gerar questão com IA", class = "btn-info")
    ),
    
    mainPanel(
      h4("Status"),
      verbatimTextOutput("status"),
      h4("Questões disponíveis com os filtros escolhidos"),
      tableOutput("preview_questoes"),
      hr(),
      h4("Prévia da questão gerada"),
      verbatimTextOutput("ia_preview"),
      uiOutput("ia_salvar_ui")
    )
  )
)

server <- function(input, output, session) {
  
  output$tema_ui <- renderUI({
    req(input$disciplina)
    temas <- list_dificuldades(input$disciplina)
    
    checkboxGroupInput(
      "tema",
      "1b. Tema:",
      choices = temas,
      selected = temas
    )
  })
  
  questoes_filtradas <- reactive({
    req(input$disciplina, input$tema)
    list_questoes(input$disciplina, input$tema)
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
          formato     = input$formato,
          com_solucao = input$com_solucao == "com"
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
    output$ia_tema_ui <- renderUI({
    req(input$ia_disciplina)
    temas <- list_dificuldades(input$ia_disciplina)
    selectInput("ia_tema", "Tema:", choices = temas)
  })

  questao_gerada <- eventReactive(input$ia_gerar, {
    req(input$ia_disciplina, input$ia_tema)

    texto_base <- if (input$ia_fonte == "texto") {
      req(input$ia_texto)
      input$ia_texto
    } else {
      req(input$ia_arquivo)
      extensao <- tools::file_ext(input$ia_arquivo$name)
      extrair_texto_arquivo(input$ia_arquivo$datapath, extensao)
    }

    withProgress(message = "Gerando questão com a IA...", value = 0.3, {
      res <- tryCatch({
        prompt <- montar_prompt_questao(texto_base, input$ia_disciplina, input$ia_tema)
        bruto  <- chamar_groq(prompt)
        rmd    <- limpar_resposta_ia(bruto)

        # valida se o .Rmd realmente compila antes de oferecer para salvar
        arquivo_temp <- tempfile(fileext = ".Rmd")
        writeLines(rmd, arquivo_temp)
        dir_teste <- tempfile("teste_ia_")
        dir.create(dir_teste)
        exams::exams2html(arquivo_temp, dir = dir_teste, n = 1)

        list(rmd = rmd, ok = TRUE)
      }, error = function(e) {
        list(erro = conditionMessage(e), ok = FALSE)
      })
      incProgress(0.7)
      res
    })
  })

  output$ia_preview <- renderPrint({
    res <- questao_gerada()
    if (isTRUE(res$ok)) {
      cat(res$rmd)
    } else {
      cat("Erro ao gerar/validar a questão:\n", res$erro)
    }
  })

  output$ia_salvar_ui <- renderUI({
    res <- questao_gerada()
    if (isTRUE(res$ok)) {
      tagList(
        textInput("ia_nome_arquivo", "Nome do arquivo (sem .Rmd):", value = "nova_questao"),
        actionButton("ia_salvar", "Salvar no banco de questões", class = "btn-success")
      )
    }
  })

  observeEvent(input$ia_salvar, {
    res <- questao_gerada()
    req(isTRUE(res$ok), input$ia_nome_arquivo)

    pasta_destino <- file.path(EXERCISES_DIR, input$ia_disciplina, input$ia_tema)
    dir.create(pasta_destino, showWarnings = FALSE, recursive = TRUE)
    caminho <- file.path(pasta_destino, paste0(input$ia_nome_arquivo, ".Rmd"))
    writeLines(res$rmd, caminho)

    showNotification(paste("Questão salva em", caminho), type = "message")
  })
}

shinyApp(ui, server)
