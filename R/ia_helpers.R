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
      temperature = 0,
      max_completion_tokens = 8192,
      reasoning_effort = "low",
      messages = list(list(role = "user", content = prompt))
    )) |>
    req_perform()

  corpo <- resp_body_json(resposta)
  escolha <- corpo$choices[[1]]
  texto <- escolha$message$content
  if (is.null(texto) || !nzchar(trimws(texto))) {
    stop("A IA devolveu resposta vazia (finish_reason = ", escolha$finish_reason,
        "). Aumente max_completion_tokens ou reduza reasoning_effort.")
  }
  texto
}

#' Monta o prompt que ensina a IA a escrever no formato do R/Exams
montar_prompt_questao <- function(descricao, disciplina, tema) {
  regras <- r"---(
Você NÃO cria questões. Você apenas CONVERTE uma questão já existente para o formato R/Exams (.Rmd) e a PARAMETRIZA, para que o R sorteie números diferentes em cada prova.

=== REGRAS (siga todas) ===
1. FIDELIDADE: mantenha o texto do enunciado exatamente como foi dado. Não reescreva, não resuma, não acrescente contexto, não mude a ordem. A única alteração permitida no texto é trocar números por código R inline.
2. PARAMETRIZAÇÃO: troque por variáveis todo número que, se mudasse, mudaria a resposta (dados, quantidades, medidas, taxas, preços). Declare o sorteio no chunk R do topo, com sample().
   - O valor original DEVE ser um dos valores possíveis do sorteio.
   - Varie pouco: use uma faixa próxima do valor original (cerca de 50% a 150% dele, ou no máximo ±30% em física e química), sempre na mesma ordem de grandeza e na mesma unidade.
   - Mantenha o "formato" do número original: se era inteiro, sorteie inteiros; se tinha 1 casa decimal, sorteie com 1 casa; se era "redondo" (50, 100, 2,5), sorteie valores redondos (use sample(seq(...)) com passo adequado).
   - Em contextos reais (preços, idades, massas, velocidades, temperaturas, tempos), os valores sorteados devem continuar plausíveis. Nada de carro a 900 km/h, pessoa com 300 kg ou preço de caderno a R$ 500.
3. NÃO parametrize números que fazem parte do enunciado e não mudam a resposta: rótulos de itens (a, b, c), "2º grau", expoentes fixos da fórmula, datas históricas, nomes. NÃO parametrize constantes físicas ou químicas (massa atômica, aceleração da gravidade, número de Avogadro, pi, etc.): elas são fatos e não podem ser sorteadas.
4. GABARITO CALCULADO: nunca escreva o resultado como número fixo. Calcule em R no chunk do topo (ex.: media <- mean(dados)) e use a variável na Solution e no exsolution.
5. RESULTADO COERENTE: o resultado final deve ficar na mesma ordem de grandeza do original (entre ~0,5x e ~2x), com o mesmo sinal, e sem divisão por zero, sem raiz de número negativo e sem empates ambíguos (moda, máximo). Quando houver uma restrição, sorteie dentro de um laço até satisfazê-la:
   repeat { a <- sample(...); b <- sample(...); if (condição_válida) break }
6. Se a questão não tem números a parametrizar (ex.: textos de humanas, ou questões que só usam constantes), apenas converta para .Rmd sem chunk de sorteio.
7. Tipo: use 'schoice' se o enunciado já traz alternativas; 'num' se pede um único valor numérico; 'cloze' (extype: cloze, exclozetype: num|num|...) se há vários itens numéricos (a, b, c...); 'string' se a resposta é um texto.
8. Em schoice, escreva a alternativa CORRETA em primeiro lugar, calcule as erradas a partir das variáveis (todas diferentes entre si e diferentes da correta) e use exshuffle: TRUE. O exsolution é binário, com exatamente um dígito por alternativa (a correta é 1 e vem primeiro, ex.: 10000). Se as alternativas forem textos, mantenha-as fixas, também com a correta primeiro.
9. Em schoice, a Answerlist da Solution deve ter EXATAMENTE o mesmo número de itens da Answerlist da Question (um "Correto." e os demais "Incorreto.").
10. Em num e cloze, nunca crie Answerlist de alternativas; no cloze a Answerlist da Question só descreve cada item.
11. MATEMÁTICA: toda fórmula usa cifrão: $x^2$ no texto e $$ ... $$ em bloco. NUNCA use \( \) nem \[ \]. Para média, use $\bar{x}$; para letras gregas e símbolos, use LaTeX ($\mu$, $\sigma$, $\leq$).
12. DINHEIRO: escreva o cifrão de moeda escapado, como R\$ 10,00, para não ser confundido com fórmula.
13. Devolva SOMENTE o conteúdo do .Rmd, sem ``` envolvendo a resposta e sem comentário. Não coloque linhas de ==== no final.

=== EXEMPLO NUM (convertido de: "Calcule a soma de 12 e 7.") ===
```{r, echo = FALSE, results = "hide"}
a <- sample(5:30, 1)
b <- sample(5:30, 1)
resultado <- a + b
```

Question
========
Calcule a soma de `r a` e `r b`.

Solution
========
`r a` + `r b` = `r resultado`.

Meta-information
================
exname: soma
extype: num
exsolution: `r resultado`
extol: 0.01

=== EXEMPLO SCHOICE (convertido de: "Um carro percorre 240 km em 4 horas. Qual é a velocidade média? A) 40 B) 50 C) 60 D) 70 E) 80") ===
```{r, echo = FALSE, results = "hide"}
v <- sample(c(40, 50, 60, 70, 80), 1)
t <- sample(2:5, 1)
d <- v * t
alternativas <- v + c(0, -10, 10, 20, -20)
```

Question
========
Um carro percorre `r d` km em `r t` horas, em velocidade constante. Qual é a velocidade média, em km/h?

Answerlist
----------
* `r alternativas[1]`
* `r alternativas[2]`
* `r alternativas[3]`
* `r alternativas[4]`
* `r alternativas[5]`

Solution
========
A velocidade média é `r d` / `r t` = `r v` km/h.

Answerlist
----------
* Correto.
* Incorreto.
* Incorreto.
* Incorreto.
* Incorreto.

Meta-information
================
exname: velocidade_media
extype: schoice
exsolution: 10000
exshuffle: TRUE

=== EXEMPLO CLOZE (convertido de uma questão com média e mediana de uma lista) ===
```{r, echo = FALSE, results = "hide"}
dados <- sample(1:6, 10, replace = TRUE)
media <- mean(dados)
mediana <- median(dados)
```

Question
========
Foram registradas as horas diárias de uso da internet: `r paste(dados, collapse = ", ")`.

Answerlist
----------
* Qual é a média?
* Qual é a mediana?

Solution
========
Média = `r media`; mediana = `r mediana`.

Meta-information
================
exname: horas_internet
extype: cloze
exclozetype: num|num
exsolution: `r paste(media, mediana, sep = "|")`
extol: 0.01
)---"


  paste0(
    "Converta e parametrize a questão abaixo para o formato R/Exams (.Rmd).\n",
    regras, "\n\n",
    "Questão original:\n\"\"\"\n", descricao, "\n\"\"\"\n\n",
    "Inclua no Meta-information: exsection: ", disciplina, "/", tema, "\n"
  )
}


validar_fidelidade <- function(original, rmd, minimo = 0.85) {
  palavras <- function(x) {
    x <- gsub("`r[^`]*`", " ", x)          # tira código inline
    x <- gsub("[0-9]+([.,][0-9]+)?", " ", x) # tira números
    x <- tolower(gsub("[[:punct:]]", " ", x))
    p <- unlist(strsplit(x, "\\s+"))
    unique(p[nchar(p) > 2])
  }
  po <- palavras(original)
  if (length(po) == 0) return(invisible(TRUE))
  frac <- mean(po %in% palavras(rmd))
  if (frac < minimo) {
    stop(sprintf("A IA alterou o enunciado (só %.0f%% das palavras originais foram mantidas). Tente novamente.", frac * 100))
  }
  invisible(TRUE)
}

#' Corrige padrões que quebram a compilação do PDF.
#' (Os caracteres Unicode, como ₂ e μ, são tratados no template LaTeX; ver
#' template_pdf() em R/helpers.R.)
normalizar_rmd <- function(texto) {
  # \( ... \)  ->  $ ... $   (o pandoc não reconhece \( \) como matemática)
  texto <- gsub("(?s)\\\\\\((.*?)\\\\\\)", "$\\1$", texto, perl = TRUE)
  # \[ ... \]  ->  $$ ... $$
  texto <- gsub("(?s)\\\\\\[(.*?)\\\\\\]", "$$\\1$$", texto, perl = TRUE)
  texto
}

limpar_resposta_ia <- function(texto) {
  texto <- gsub("^```(text|r|rmd|markdown|md)?\\n", "", texto, ignore.case = TRUE)
  texto <- gsub("```\\s*$", "", texto)
  normalizar_rmd(trimws(texto))
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