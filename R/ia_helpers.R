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
    "Você é um programador especialista em criar questões no formato R/Exams (arquivo .Rmd).\n",
    "Gere o conteúdo exato do arquivo .Rmd. Escolha o formato: 'schoice', 'num' ou 'string'.\n\n",

    "=== REGRAS ===\n",
    "1. A tag 'exsolution' no Meta-information é OBRIGATÓRIA PARA TODOS OS TIPOS.\n",
    "2. Múltipla escolha (schoice): Use a seção 'Answerlist' (com traços ---------). O 'exsolution' deve ser binário (ex: 1000) com o mesmo número de itens da lista.\n",
    "3. Numérica (num) e Aberta (string): NUNCA crie 'Answerlist'. Para num, o exsolution é o número exato e adicione extol. Para string, o exsolution é nil.\n",
    "4. NUNCA adicione linhas de sinais de igual (====) no final do arquivo. Retorne APENAS o código puro.\n\n",

    "Regras vitais:\n",
    "1. A tag 'exsolution' é OBRIGATÓRIA SEMPRE.\n",
    "2. Para 'schoice' e 'mchoice', exsolution DEVE ser uma sequência de 0s e 1s com o número EXATO de dígitos igual ao número de itens na Answerlist (ex: 10100 para 5 alternativas, onde 1 indica as alternativas corretas).\n",
    "3. Se escolher 'num' ou 'string', NÃO crie a seção 'Answerlist'.\n",
    "4. Devolva SOMENTE o conteúdo do arquivo .Rmd, sem markdown (```) e sem texto extra.\n\n",
    
    "--- EXEMPLO SCHOICE ---\n",
    "Question\n========\nQual a capital da França?\n\nAnswerlist\n----------\n* Paris\n* Londres\n\nSolution\n========\nÉ Paris.\n\nAnswerlist\n----------\n* Correto\n* Incorreto\n\nMeta-information\n================\n",
    "exname: questao_ia\nextype: schoice\nexsolution: 10\nexshuffle: TRUE\n\n",

    "--- EXEMPLO NUM ---\n",
    "Question\n========\nCalcule 7 x 8.\n\nSolution\n========\nO resultado é 56.\n\nMeta-information\n================\n",
    "exname: questao_ia\nextype: num\nexsolution: 56\nextol: 0.01\n\n",

    "--- EXEMPLO STRING ---\n",
    "Question\n========\nO que é fotossíntese?\n\nSolution\n========\nÉ o processo das plantas.\n\nMeta-information\n================\n",
    "exname: questao_ia\nextype: string\nexsolution: nil\n\n",

    "Gere a questão abaixo:\n\"\"\"\n", descricao, "\n\"\"\"\n\n",
    "Inclua no Meta-information:\n",
    "exname: questao_gerada_ia\n",
    "exsection: ", disciplina, "/", tema, "\n"
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