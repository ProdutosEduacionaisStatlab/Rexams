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

  banco <- banco[banco$disciplina == disciplina_alvo & banco$tema %in% temas_alvo, ]

  # Ignora registros sem conteúdo (ex.: tentativas antigas que salvaram texto vazio)
  banco[!is.na(banco$conteudo_rmd) & nzchar(trimws(banco$conteudo_rmd)), ]
}


# =========================================================
# Caracteres Unicode no PDF
# O pdflatex não aceita caracteres como ₂, ², μ, ≤, →. Em vez de
# alterar o texto das questões, declaramos esses caracteres no
# preâmbulo do template LaTeX (formato: CODIGO_HEX|COMANDO_LATEX).
# =========================================================
.UNICODE_LATEX <- r"---(
2080|\ensuremath{{}_0}
2081|\ensuremath{{}_1}
2082|\ensuremath{{}_2}
2083|\ensuremath{{}_3}
2084|\ensuremath{{}_4}
2085|\ensuremath{{}_5}
2086|\ensuremath{{}_6}
2087|\ensuremath{{}_7}
2088|\ensuremath{{}_8}
2089|\ensuremath{{}_9}
208A|\ensuremath{{}_+}
208B|\ensuremath{{}_-}
2070|\ensuremath{{}^0}
2074|\ensuremath{{}^4}
2075|\ensuremath{{}^5}
2076|\ensuremath{{}^6}
2077|\ensuremath{{}^7}
2078|\ensuremath{{}^8}
2079|\ensuremath{{}^9}
207A|\ensuremath{{}^+}
207B|\ensuremath{{}^-}
2190|\ensuremath{\leftarrow}
2192|\ensuremath{\rightarrow}
21CC|\ensuremath{\rightleftharpoons}
21D2|\ensuremath{\Rightarrow}
2264|\ensuremath{\leq}
2265|\ensuremath{\geq}
2260|\ensuremath{\neq}
2248|\ensuremath{\approx}
221E|\ensuremath{\infty}
221A|\ensuremath{\surd}
2211|\ensuremath{\sum}
222B|\ensuremath{\int}
2208|\ensuremath{\in}
2229|\ensuremath{\cap}
222A|\ensuremath{\cup}
2202|\ensuremath{\partial}
2212|\ensuremath{-}
2011|\mbox{-}
202F|\,
2009|\,
200B|\relax
03B1|\ensuremath{\alpha}
03B2|\ensuremath{\beta}
03B3|\ensuremath{\gamma}
03B4|\ensuremath{\delta}
03B5|\ensuremath{\varepsilon}
03B8|\ensuremath{\theta}
03BB|\ensuremath{\lambda}
03BC|\ensuremath{\mu}
03C0|\ensuremath{\pi}
03C1|\ensuremath{\rho}
03C3|\ensuremath{\sigma}
03C4|\ensuremath{\tau}
03C6|\ensuremath{\varphi}
03C7|\ensuremath{\chi}
03C9|\ensuremath{\omega}
0394|\ensuremath{\Delta}
03A3|\ensuremath{\Sigma}
03A9|\ensuremath{\Omega}
03A0|\ensuremath{\Pi}
03A6|\ensuremath{\Phi}
0398|\ensuremath{\Theta}
039B|\ensuremath{\Lambda}
)---"

#' Linhas \DeclareUnicodeCharacter{...}{...} montadas a partir da tabela acima
preambulo_unicode <- function() {
  linhas <- trimws(strsplit(.UNICODE_LATEX, "\n", fixed = TRUE)[[1]])
  linhas <- linhas[nzchar(linhas)]
  partes <- strsplit(linhas, "|", fixed = TRUE)
  vapply(partes, function(p) {
    sprintf("\\DeclareUnicodeCharacter{%s}{%s}", p[1], p[2])
  }, character(1))
}

#' Devolve o caminho de uma cópia do template do exams ("exam" ou "solution")
#' com os caracteres Unicode declarados. Se algo falhar, devolve o nome
#' original do template (comportamento antigo).
template_pdf <- function(nome = "exam") {
  origem <- system.file("tex", paste0(nome, ".tex"), package = "exams")
  if (!nzchar(origem) || !file.exists(origem)) return(nome)

  linhas <- readLines(origem, warn = FALSE)
  pos <- grep("^\\s*\\\\begin\\{document\\}", linhas)[1]
  if (is.na(pos)) return(nome)

  destino <- file.path(tempdir(), paste0("rexams_", nome, ".tex"))
  writeLines(
    c(linhas[seq_len(pos - 1)],
      "% --- caracteres Unicode (Rexams) ---",
      preambulo_unicode(),
      linhas[pos:length(linhas)]),
    destino
  )
  destino
}

#' Trecho do log do LaTeX com a primeira linha de erro (para mostrar no status)
trecho_log_latex <- function(pastas) {
  logs <- list.files(pastas, pattern = "\\.log$", recursive = TRUE, full.names = TRUE)
  if (length(logs) == 0) return("")
  ultimo <- logs[which.max(file.mtime(logs))]
  linhas <- readLines(ultimo, warn = FALSE)
  erros <- grep("^!", linhas)
  if (length(erros) == 0) return("")
  ini <- erros[1]
  paste(linhas[ini:min(ini + 4, length(linhas))], collapse = "\n")
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
  estaticas <- selecionados$id[!grepl("sample\\(", selecionados$conteudo_rmd)]

  # =================================================================
  # O "Fatiador Temporário": transforma o texto do JSON em arquivos .Rmd
  # =================================================================
  dir_rmd_temp <- tempfile("rmd_temp_")
  dir.create(dir_rmd_temp, showWarnings = FALSE)

  arquivos_temp <- c()
  for (i in seq_len(nrow(selecionados))) {
    nome_arquivo <- file.path(dir_rmd_temp, paste0("questao_", i, ".Rmd"))
    writeLines(normalizar_rmd(selecionados$conteudo_rmd[i]), nome_arquivo)
    arquivos_temp <- c(arquivos_temp, nome_arquivo)
  }
  resultado <- list(dir = dir_saida, arquivos_gerados = c(), estaticas = estaticas)
  nome_saida <- if (com_solucao) "prova_gabarito" else "prova"

  # O resto continua igual, mas agora usando os `arquivos_temp`
  if (formato == "pdf") {
    tryCatch(
      exams2pdf(
        arquivos_temp,
        n        = n_versoes,
        dir      = dir_saida,
        name     = nome_saida,
        encoding = "UTF-8",
        template = template_pdf(if (com_solucao) "solution" else "exam")
      ),
      error = function(e) {
        detalhe <- trecho_log_latex(c(dir_saida, tempdir()))
        stop(conditionMessage(e),
             if (nzchar(detalhe)) paste0("\n\nTrecho do log do LaTeX:\n", detalhe) else "",
             call. = FALSE)
      }
    )

  } else if (formato == "html") {
    exams2html(
      arquivos_temp,
      n        = n_versoes,
      dir      = dir_saida,
      name     = nome_saida,
      encoding = "UTF-8",
      solution = com_solucao
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
