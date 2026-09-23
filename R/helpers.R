# =========================================================
# helpers.R
# Funções auxiliares: leitura do banco de questões e geração
# das provas via pacote exams.
# =========================================================

library(exams)
library(tools)
library(jsonlite)


ARQUIVO_BANCO <- "banco_questoes.json"

ler_banco <- function() {
  if (!file.exists(ARQUIVO_BANCO)) {
    return(data.frame(id = character(), disciplina = character(), tema = character(), conteudo_rmd = character()))
  }
  dados <- fromJSON(ARQUIVO_BANCO)
  
  if (length(dados) == 0) {
    return(data.frame(id = character(), disciplina = character(), tema = character(), conteudo_rmd = character()))
  }
  return(dados)
}


#' Lista as disciplinas disponíveis (subpastas de exercises/)
list_disciplinas <- function() {
  banco <- ler_banco()
  if (nrow(banco) == 0) return(character(0))
  sort(unique(banco$disciplina))
}

list_dificuldades <- function(disciplina_alvo) {
  banco <- ler_banco()
  if (nrow(banco) == 0) return(character(0))

  temas <- banco$tema[banco$disciplina == disciplina_alvo]
  sort(unique(temas))
}

#' Lista os arquivos de questão (.Rmd/.Rnw) para disciplina + dificuldades
filtrar_questoes <- function(disciplina_alvo, temas_alvo) {
  banco <- ler_banco()
  if (nrow(banco) == 0) return(data.frame())

  banco[banco$disciplina == disciplina_alvo & banco$tema %in% temas_alvo, ]
}

#' Gera a prova (e gabarito) usando o pacote exams
#'
#' @param arquivos vetor de caminhos para os arquivos de questão selecionados
#' @param n_questoes número de questões a sortear por versão
#' @param n_versoes número de versões (A, B, C, ...) a gerar
#' @param formato "pdf", "html" ou "moodle"
#' @param com_solucao se TRUE, inclui a solução/gabarito na saída gerada
#' @param dir_saida pasta onde salvar os arquivos gerados

#' Gera a prova (e gabarito) usando o pacote exams e o banco JSON
generate_exam <- function(df_questoes, n_questoes, n_versoes, formato = "pdf",
                          com_solucao = FALSE,
                          dir_saida = tempfile("prova_")) {

  dir.create(dir_saida, showWarnings = FALSE, recursive = TRUE)

  if (nrow(df_questoes) < n_questoes) {
    stop("O número de questões pedido é maior do que o banco disponível para os filtros escolhidos.")
  }

  # Sorteia as questões (linhas do dataframe)
  indices_sorteados <- sample(seq_len(nrow(df_questoes)), n_questoes)
  selecionados <- df_questoes[indices_sorteados, ]

  # =================================================================
  # O "Fatiador Temporário": transforma o texto do JSON em arquivos .Rmd
  # =================================================================
  dir_rmd_temp <- tempfile("rmd_temp_")
  dir.create(dir_rmd_temp, showWarnings = FALSE)

  arquivos_temp <- c()
  for (i in seq_len(nrow(selecionados))) {
    nome_arquivo <- file.path(dir_rmd_temp, paste0("questao_", i, ".Rmd"))
    writeLines(selecionados$conteudo_rmd[i], nome_arquivo)
    arquivos_temp <- c(arquivos_temp, nome_arquivo)
  }

  resultado <- list(dir = dir_saida, arquivos_gerados = c())
  nome_saida <- if (com_solucao) "prova_gabarito" else "prova"

  # O resto continua igual, mas agora usando os `arquivos_temp`
  if (formato == "pdf") {
    exams2pdf(
      arquivos_temp,
      n        = n_versoes,
      dir      = dir_saida,
      name     = nome_saida,
      encoding = "UTF-8",
      control  = list(solution = com_solucao)
    )

  } else if (formato == "html") {
    exams2html(
      arquivos_temp,
      n        = n_versoes,
      dir      = dir_saida,
      name     = nome_saida,
      encoding = "UTF-8",
      control  = list(solution = com_solucao)
    )

  } else if (formato == "moodle") {
    exams2moodle(
      arquivos_temp,
      n    = n_versoes,
      dir  = dir_saida,
      name = "prova",
      encoding = "UTF-8"
    )

  } else {
    stop("Formato não suportado: ", formato)
  }

  resultado$arquivos_gerados <- list.files(dir_saida, full.names = TRUE)
  resultado
}

#' Compacta todos os arquivos gerados em um único .zip para download
zip_exam_output <- function(dir_saida, zip_path = tempfile(fileext = ".zip")) {
  arquivos <- list.files(dir_saida, full.names = TRUE)
  old_wd <- getwd()
  on.exit(setwd(old_wd))
  setwd(dir_saida)
  utils::zip(zipfile = zip_path, files = list.files("."))
  zip_path
}
