library(httr2)

GROQ_MODEL <- "openai/gpt-oss-20b"

#' Envia um prompt para a Groq e devolve o texto de resposta
chamar_groq <- function(prompt) {
  chave <- Sys.getenv("GROQ_API_KEY")
  if (!nzchar(chave)) {
    stop("GROQ_API_KEY não encontrada. Configure no arquivo .Renviron e reinicie o R.")
  }

  resposta <- request("https://api.groq.com/openai/v1/chat/completions") |>
    req_headers(Authorization = paste("Bearer", chave)) |>
    req_body_json(list(
      model = GROQ_MODEL,
      temperature = 0.3,
      max_tokens = 2048,
      messages = list(list(role = "user", content = prompt))
    )) |>
    req_perform()

  corpo <- resp_body_json(resposta)
  corpo$choices[[1]]$message$content
}

#' Monta o prompt que ensina a IA a escrever no formato do R/Exams
montar_prompt_questao <- function(descricao, disciplina, tema) {
  paste0(
    "Voce e um especialista em criar questoes no formato R/Exams (arquivo .Rmd).\n",
    "Transforme a descricao abaixo em UMA questao completa, seguindo EXATAMENTE este modelo:\n\n",
    "```{r, echo=FALSE, results=\"hide\"}\n",
    "# codigo R que sorteia valores aleatorios usados no enunciado (use sample() ou runif())\n",
    "```\n\n",
    "Question\n========\n",
    "Enunciado da questao, usando os valores sorteados com `r nome_variavel`.\n\n",
    "Answerlist\n----------\n",
    "* alternativa 1\n* alternativa 2\n* alternativa 3\n* alternativa 4\n\n",
    "Solution\n========\n",
    "Explicacao de como resolver.\n\n",
    "Answerlist\n----------\n",
    "* Correto! ou Incorreto. para cada alternativa, na MESMA ordem da Question\n\n",
    "Meta-information\n================\n",
    "exname: nome_curto_sem_acento_sem_espaco\n",
    "extype: schoice, mchoice, num ou string (escolha o mais adequado)\n",
    "exsolution: sequencia de 0 e 1 (um digito por alternativa) se for schoice/mchoice, OU o valor numerico correto se for num\n",
    "exshuffle: TRUE\n",
    "exsection: ", disciplina, "/", tema, "\n\n",
    "Regras obrigatorias:\n",
    "- Se for multipla escolha, a Answerlist da Question e a da Solution devem ter a MESMA quantidade de itens.\n",
    "- O exsolution deve ter exatamente um digito por alternativa (ex: 4 alternativas -> 4 digitos, tipo 0100).\n",
    "- Se for questao numerica (extype: num), nao use Answerlist; use exsolution com o valor certo e acrescente a linha extol: 0.05.\n",
    "- Escreva formulas e simbolos matematicos entre $...$ (LaTeX).\n",
    "- O codigo R deve realmente sortear valores diferentes a cada vez, nao pode repetir sempre os mesmos numeros.\n\n",
    "Descricao da questao fornecida pelo professor:\n\"\"\"\n", descricao, "\n\"\"\"\n\n",
    "Disciplina: ", disciplina, "\n",
    "Tema: ", tema, "\n\n",
    "Devolva SOMENTE o conteudo do arquivo .Rmd, sem nenhum texto explicativo antes ou depois, e sem blocos de markdown (sem ``` no inicio ou no fim)."
  )
}

limpar_resposta_ia <- function(texto) {
  texto <- gsub("^```(text|r|rmd)?\\n", "", texto)
  texto <- gsub("```\\s*$", "", texto)
  trimws(texto)
}

extrair_texto_arquivo <- function(caminho, extensao) {
  extensao <- tolower(extensao)
  if (extensao == "pdf") {
    paginas <- pdftools::pdf_text(caminho)
    paste(paginas, collapse = "\n")
  } else if (extensao == "docx") {
    doc <- officer::read_docx(caminho)
    conteudo <- officer::docx_summary(doc)
    paste(conteudo$text, collapse = "\n")
  } else {
    stop("Formato de arquivo nao suportado: ", extensao, " (use .pdf ou .docx)")
  }
}