library(shiny)
library(bslib)
source("R/helpers.R")
source("R/ia_helpers.R")

tema <- bs_theme(
  version = 5,
  bootswatch = "darkly",
  bg = "#101827",
  fg = "#E8EEF5",
  primary = "#38BDF8",
  secondary = "#94A3B8",
  success = "#2DD4BF",
  base_font = font_google("Source Sans 3"),
  heading_font = font_google("Source Sans 3")
)

ui <- fluidPage(
  theme = tema,
  
  tags$head(
    tags$meta(name = "viewport",
              content = "width=device-width, initial-scale=1"),
    tags$style(HTML("
      body {
        background: #101827;
        font-size: 15px;
        line-height: 1.6;
      }

      .container-fluid {
        max-width: 1500px;
        padding: 24px 30px;
      }

      .app-header {
        padding: 22px 26px;
        margin-bottom: 24px;
        background: #192538;
        border: 1px solid #2B3A4F;
        border-radius: 14px;
        border-left: 4px solid #38BDF8;
      }

      .app-header h2 {
        margin-top: 0;
        font-weight: 650;
        letter-spacing: -0.5px;
      }

      .app-subtitle {
        color: #A9B8CC;
        margin-bottom: 0;
      }

      .nav-tabs {
        border-bottom: 1px solid #334155;
        margin-bottom: 22px;
      }

      .nav-tabs > li > a {
        color: #A9B8CC;
        border-radius: 8px 8px 0 0;
      }

      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:hover,
      .nav-tabs > li.active > a:focus {
        color: #38BDF8;
        background: #192538;
        border-color: #334155;
        border-bottom-color: #192538;
      }

      .well, .panel, .card {
        background: #192538;
        border: 1px solid #2B3A4F;
        border-radius: 12px;
        box-shadow: none;
      }

      .well {
        padding: 22px;
      }

      h3, h4 {
        font-weight: 600;
        color: #F1F5F9;
      }

      .section-heading {
        margin-top: 0;
        padding-bottom: 12px;
        border-bottom: 1px solid #334155;
        margin-bottom: 18px;
      }

      .form-control, .selectize-input {
        border-radius: 7px !important;
        min-height: 40px;
      }

      .btn {
        border-radius: 8px;
        font-weight: 600;
        padding: 9px 15px;
      }

      .btn-primary {
        background: #0284C7;
        border-color: #0284C7;
      }

      .btn-primary:hover {
        background: #0369A1;
        border-color: #0369A1;
      }

      .btn-info {
        background: #0F766E;
        border-color: #0F766E;
      }

      .btn-info:hover {
        background: #115E59;
        border-color: #115E59;
      }

      .form-group {
        margin-bottom: 19px;
      }

      .table {
        background: #192538;
        border-radius: 8px;
      }

      pre {
        background: #111C2D;
        color: #DCE6F2;
        border: 1px solid #2B3A4F;
        border-radius: 8px;
        padding: 15px;
        white-space: pre-wrap;
        overflow-wrap: anywhere;
      }

      hr {
        border-color: #334155;
      }

      .help-text {
        color: #A9B8CC;
        font-size: 13px;
      }

      @media (max-width: 768px) {
        .container-fluid {
          padding: 14px;
        }

        .app-header {
          padding: 18px;
        }
      }
    "))
  ),
  
  # Cabeçalho institucional
  div(
    class = "app-header",
    h2(
      icon("graduation-cap"),
      "STATLAB"
    ),
    p(
      class = "app-subtitle",
      "Gerador de avaliações acadêmicas",
      span("  |  R / exams")
    )
  ),
  
  # Navegação principal
  tabsetPanel(
    id = "navegacao",
    type = "tabs",
    
    # ABA 1 — GERAÇÃO DA PROVA
    tabPanel(
      title = tagList(icon("file-text"), " Gerar prova"),
      
      br(),
      
      sidebarLayout(
        sidebarPanel(
          width = 4,
          
          h4(
            class = "section-heading",
            icon("sliders-horizontal"),
            " Configuração da avaliação"
          ),
          
          p(
            class = "help-text",
            "Defina o conteúdo, a quantidade de questões e o formato."
          ),
          
          selectInput(
            "disciplina",
            "1. Disciplina",
            choices = list_disciplinas()
          ),
          
          uiOutput("tema_ui"),
          
          numericInput(
            "n_questoes",
            "2. Número de questões",
            value = 2,
            min = 1,
            step = 1
          ),
          
          numericInput(
            "n_versoes",
            "3. Número de versões",
            value = 1,
            min = 1,
            max = 20,
            step = 1
          ),
          
          selectInput(
            "formato",
            "4. Formato de saída",
            choices = c(
              "PDF — impressão" = "pdf",
              "HTML — online" = "html",
              "Moodle — XML" = "moodle"
            )
          ),
          
          radioButtons(
            "com_solucao",
            "5. Incluir soluções?",
            choices = c(
              "Somente prova" = "sem",
              "Com gabarito" = "com"
            ),
            selected = "sem",
            inline = FALSE
          ),
          
          hr(),
          
          actionButton(
            "gerar",
            "Gerar avaliação",
            icon = icon("file-circle-check"),
            class = "btn-primary",
            width = "100%"
          ),
          
          br(),
          br(),
          
          downloadButton(
            "baixar",
            "Baixar prova + gabarito",
            class = "btn-default",
            width = "100%"
          )
        ),
        
        mainPanel(
          width = 8,
          
          h4(
            class = "section-heading",
            icon("activity"),
            " Acompanhamento"
          ),
          
          div(
            class = "well",
            h4("Status da geração"),
            verbatimTextOutput("status")
          ),
          
          br(),
          
          div(
            class = "well",
            h4("Banco de questões"),
            p(
              class = "help-text",
              "Questões disponíveis conforme os filtros selecionados."
            ),
            tableOutput("preview_questoes")
          )
        )
      )
    ),
    
    # ABA 2 — BANCO DE QUESTÕES
    tabPanel(
      title = tagList(icon("database"), " Banco de questões"),
      
      br(),
      
      div(
        class = "well",
        h4("Acervo de questões"),
        p(
          "Consulte as questões disponíveis para compor suas avaliações."
        ),
        p(
          class = "help-text",
          paste(
            "A tabela de questões filtradas continua disponível",
            "na aba Gerar prova. Esta área pode receber futuramente",
            "a consulta completa, edição e exclusão do banco."
          )
        )
      )
    ),
    
    # ABA 3 — IMPORTAÇÃO COM IA
    tabPanel(
      title = tagList(icon("brain"), " Importar com IA"),
      
      br(),
      
      sidebarLayout(
        sidebarPanel(
          width = 5,
          
          h4(
            class = "section-heading",
            icon("file-import"),
            " Parametrização da questão"
          ),
          
          p(
            class = "help-text",
            "Importe uma questão para organizá-la no banco de dados."
          ),
          
          selectizeInput(
            "ia_disciplina",
            "Disciplina",
            choices = list_disciplinas(),
            options = list(create = TRUE)
          ),
          
          uiOutput("ia_tema_ui"),
          
          radioButtons(
            "ia_fonte",
            "Origem da questão",
            choices = c(
              "Texto colado" = "texto",
              "Arquivo PDF ou Word" = "arquivo"
            ),
            selected = "texto",
            inline = FALSE
          ),
          
          conditionalPanel(
            condition = "input.ia_fonte == 'texto'",
            
            textAreaInput(
              "ia_texto",
              "Enunciado e conteúdo da questão",
              rows = 8,
              width = "100%",
              placeholder = "Cole ou descreva a questão aqui..."
            )
          ),
          
          conditionalPanel(
            condition = "input.ia_fonte == 'arquivo'",
            
            fileInput(
              "ia_arquivo",
              "Selecionar arquivo",
              accept = c(".pdf", ".docx")
            )
          ),
          
          actionButton(
            "ia_gerar",
            "Converter e parametrizar",
            icon = icon("wand-magic-sparkles"),
            class = "btn-info",
            width = "100%"
          )
        ),
        
        mainPanel(
          width = 7,
          
          div(
            class = "well",
            h4(
              class = "section-heading",
              icon("eye"),
              " Pré-visualização"
            ),
            
            p(
              class = "help-text",
              "Confira o conteúdo convertido antes de salvá-lo."
            ),
            
            verbatimTextOutput("ia_preview"),
            
            uiOutput("ia_salvar_ui")
          )
        )
      )
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

  output$ia_tema_ui <- renderUI({
    req(input$ia_disciplina)
    temas <- list_dificuldades(input$ia_disciplina)
    selectizeInput("ia_tema", "Tema:", choices = temas, options = list(create = TRUE))
  })

  questoes_filtradas <- reactive({
    req(input$disciplina, input$tema)
    filtrar_questoes(input$disciplina, input$tema)
  })

  output$preview_questoes <- renderTable({
    df <- questoes_filtradas()
    if (nrow(df) == 0) return(data.frame(Status = "Nenhuma questão encontrada."))
    data.frame(Questao = df$id)
      })

  resultado_geracao <- eventReactive(input$gerar, {
    df_questoes <- questoes_filtradas()
    withProgress(message = "Gerando prova(s)...", value = 0.3, {
      res <- tryCatch({
        generate_exam(
          df_questoes = df_questoes,
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
      texto_ia <- NULL  # último texto devolvido pela IA (mostrado se der erro)
      res <- tryCatch({
        prompt <- montar_prompt_questao(texto_base, input$ia_disciplina, input$ia_tema)
        bruto  <- chamar_groq(prompt)
        texto_ia <- bruto
        rmd    <- limpar_resposta_ia(bruto)
        texto_ia <- rmd
        if (!nzchar(rmd)) stop("A IA devolveu um .Rmd vazio.")
        validar_fidelidade(texto_base, rmd)

        # valida se o .Rmd compila nos DOIS formatos antes de oferecer para salvar:
        # HTML e PDF (o PDF é mais rígido e é o formato usado nas provas)
        arquivo_temp <- tempfile(fileext = ".Rmd")
        writeLines(rmd, arquivo_temp)
        dir_teste <- tempfile("teste_ia_")
        dir.create(dir_teste)
        exams::exams2html(arquivo_temp, dir = dir_teste, n = 1)
        exams::exams2pdf(arquivo_temp, dir = dir_teste, n = 1, name = "teste_pdf",
                         encoding = "UTF-8", template = template_pdf("exam"))

        list(rmd = rmd, ok = TRUE)
      }, error = function(e) {
        list(erro = conditionMessage(e), ok = FALSE, bruto = texto_ia)
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
      if (!is.null(res$bruto) && nzchar(res$bruto)) {
        cat("\n\n--- Texto devolvido pela IA ---\n", res$bruto)
      }
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
    req(nzchar(trimws(res$rmd)))  # nunca salva questão vazia

    # 1. Cria o registro da nova questão no formato do JSON
    novo_registro <- data.frame(
      id = input$ia_nome_arquivo,
      disciplina = input$ia_disciplina,
      tema = input$ia_tema,
      conteudo_rmd = res$rmd,
      stringsAsFactors = FALSE
    )

    # 2. Lê o banco atual
    banco_atual <- ler_banco()

    # 3. Anexa a nova questão ao final do banco
    banco_atualizado <- rbind(banco_atual, novo_registro)

    # 4. Sobrescreve o arquivo JSON com os dados atualizados
    jsonlite::write_json(banco_atualizado, ARQUIVO_BANCO, pretty = TRUE, auto_unbox = TRUE)

    showNotification(paste("Questão", input$ia_nome_arquivo, "adicionada ao JSON!"), type = "message")
  })
}

shinyApp(ui, server)
