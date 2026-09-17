# =========================================================
# helpers.R
# Funções auxiliares: leitura do banco de questões e geração
# das provas via pacote exams.
# =========================================================

library(exams)
library(tools)

EXERCISES_DIR <- "exercises"

#' Lista as disciplinas disponíveis (subpastas de exercises/)
list_disciplinas <- function(base = EXERCISES_DIR) {
  dirs <- list.dirs(base, recursive = FALSE, full.names = FALSE)
  sort(dirs)
}

#' Lista as dificuldades disponíveis para uma disciplina
#' (subpastas dentro de exercises/<disciplina>/)
list_dificuldades <- function(disciplina, base = EXERCISES_DIR) {
  path <- file.path(base, disciplina)
  if (!dir.exists(path)) return(character(0))
  dirs <- list.dirs(path, recursive = FALSE, full.names = FALSE)
  sort(dirs)
}

#' Lista os arquivos de questão (.Rmd/.Rnw) para disciplina + dificuldades
list_questoes <- function(disciplina, dificuldades, base = EXERCISES_DIR) {
  arquivos <- c()
  for (dif in dificuldades) {
    path <- file.path(base, disciplina, dif)
    if (dir.exists(path)) {
      f <- list.files(path, pattern = "\\.(Rmd|Rnw)$", full.names = TRUE)
      arquivos <- c(arquivos, f)
    }
  }
  arquivos
}

#' Gera a prova (e gabarito) usando o pacote exams
#'
#' @param arquivos vetor de caminhos para os arquivos de questão selecionados
#' @param n_questoes número de questões a sortear por versão
#' @param n_versoes número de versões (A, B, C, ...) a gerar
#' @param formato "pdf", "html" ou "moodle"
#' @param com_solucao se TRUE, inclui a solução/gabarito na saída gerada
#' @param dir_saida pasta onde salvar os arquivos gerados
generate_exam <- function(arquivos, n_questoes, n_versoes, formato = "pdf",
                          com_solucao = FALSE,
                          dir_saida = tempfile("prova_")) {
  
  dir.create(dir_saida, showWarnings = FALSE, recursive = TRUE)
  
  if (length(arquivos) < n_questoes) {
    stop("O número de questões pedido é maior do que o banco disponível para os filtros escolhidos.")
  }
  
  # Sorteia quais arquivos entram na prova (mesmo conjunto-base para
  # todas as versões; os VALORES dentro de cada questão são
  # re-sorteados automaticamente pelo exams a cada versão)
  selecionados <- sample(arquivos, n_questoes)
  
  resultado <- list(dir = dir_saida, arquivos_gerados = c())
  
  # nome do arquivo reflete se a solução está incluída, evitando que uma
  # chamada sobrescreva a outra quando ambas gravam na mesma pasta
  nome_saida <- if (com_solucao) "prova_gabarito" else "prova"
  
  if (formato == "pdf") {
    exams2pdf(
      selecionados,
      n        = n_versoes,
      dir      = dir_saida,
      name     = nome_saida,
      encoding = "UTF-8",
      control  = list(solution = com_solucao)
    )
    
  } else if (formato == "html") {
    exams2html(
      selecionados,
      n        = n_versoes,
      dir      = dir_saida,
      name     = nome_saida,
      encoding = "UTF-8",
      control  = list(solution = com_solucao)
    )
    
  } else if (formato == "moodle") {
    # o XML do Moodle carrega a resposta correta internamente (necessária
    # para a correção automática), então a opção com/sem solução não se
    # aplica a este formato
    exams2moodle(
      selecionados,
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
