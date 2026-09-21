# Gerador de Provas Automáticas — R/Exams + Shiny

Interface web (R + Shiny) para professores gerarem provas em **PDF, HTML ou Moodle XML** a partir de um banco de questões em [R/Exams](https://www.r-exams.org/), com **valores sorteados a cada versão** (A, B, C…) e gabarito, **sem precisar programar**. As questões ficam em arquivos `.Rmd` organizados por disciplina e tema; a interface lista o que existe, sorteia as questões e devolve os arquivos prontos.

<!-- Adicione aqui uma captura de tela da interface, por exemplo: ![Interface do app](docs/interface.png) -->

## Sumário

1. [Problema que resolve e para quem é](#problema-que-resolve-e-para-quem-é)
2. [Como funciona](#como-funciona)
3. [Tecnologias usadas e necessárias](#tecnologias-usadas-e-necessárias)
4. [Estrutura do projeto](#estrutura-do-projeto)
5. [Rodar localmente](#1-rodar-localmente)
6. [Usando a interface](#2-usando-a-interface)
7. [Adicionar novas questões](#3-adicionar-novas-questões)
8. [Rodar com Docker](#4-rodar-com-docker)
9. [Solução de problemas](#solução-de-problemas)
10. [Limitações conhecidas](#limitações-conhecidas)
11. [Roadmap](#roadmap-sugerido)
12. [Licença e autoria](#licença-e-autoria)

---

## Problema que resolve e para quem é

Montar várias versões de uma prova exige trocar valores, reordenar alternativas e refazer o gabarito de cada versão à mão. Este projeto automatiza esse trabalho: o professor escolhe a disciplina, os temas, o número de questões e de versões, e o sistema entrega os arquivos prontos para imprimir, publicar online ou importar no Moodle.

**Para quem é:** professores que querem provas com questões e valores aleatórios sem escrever código. Quem mantém o banco de questões precisa conhecer o formato `.Rmd` do R/Exams (veja a seção [Adicionar novas questões](#3-adicionar-novas-questões)); quem só gera provas não precisa.

## Como funciona

1. As questões são arquivos `.Rmd` (ou `.Rnw`) guardados em `exercises/<disciplina>/<tema>/`. Cada arquivo contém um trecho de código R que sorteia os valores, o enunciado, a solução e metadados.
2. Na interface, o professor escolhe a disciplina e os temas. A lista de questões disponíveis com esses filtros é exibida na tela.
3. Ao clicar em **Gerar Prova**, o sistema sorteia, entre as questões filtradas, a quantidade pedida. Esse conjunto de questões é o mesmo para todas as versões; o pacote `exams` re-sorteia os **valores** dentro de cada questão a cada versão.
4. A saída é gerada no formato escolhido (PDF, HTML ou Moodle XML), com ou sem solução, e pode ser baixada em um `.zip`.

Detalhes que valem saber:

* Se o número de questões pedido for maior que o total de questões filtradas, a geração é interrompida com uma mensagem de erro.
* Os arquivos gerados levam o prefixo `prova` (sem solução) ou `prova_gabarito` (com solução).
* No formato Moodle, o XML já carrega a resposta correta (necessária para a correção automática); por isso a opção com/sem solução não se aplica a ele.

## Tecnologias usadas e necessárias

### O que o projeto usa

| Tecnologia | Função |
| --- | --- |
| [R](https://cran.r-project.org) | Linguagem base do projeto |
| [`exams`](https://www.r-exams.org/) | Motor de geração, aleatorização e correção das provas |
| [Shiny](https://shiny.posit.co/) | Framework da interface web |
| `rmarkdown` e `knitr` | Processam os arquivos `.Rmd` das questões |
| LaTeX | Renderização do PDF |
| Pandoc | Renderização de HTML e Moodle |
| `zip` | Compacta os arquivos gerados para download |
| Docker e Docker Compose | Empacotam e orquestram o ambiente completo para deploy |
| `rocker/shiny` (Shiny Server) | Imagem base do container; serve o app localmente na porta 3838 |

### O que precisa estar instalado

**Para rodar localmente:**

| Requisito | Detalhes |
| --- | --- |
| R (>= 4.2) | <https://cran.r-project.org> |
| Pacotes R | `shiny`, `exams`, `rmarkdown`, `knitr` (o `packages.R` instala tudo, inclusive o `tinytex`; o pacote `tools` já vem com o R) |
| LaTeX | Necessário só para gerar PDF. O TinyTeX é o mais simples (o `packages.R` instala se não houver LaTeX no sistema) |
| Pandoc | Necessário para HTML e Moodle. Normalmente já vem com o RStudio |
| `zip` no PATH | Necessário para o botão de download. No Linux/macOS geralmente já vem instalado; no Windows, garanta que o Git Bash/Rtools (ou outro `zip.exe`) esteja no PATH |

**Para rodar com Docker (recomendado):** só é preciso ter **Docker** e **Docker Compose**. Todo o resto já vem na imagem (`rocker/shiny:4.4.1`, `texlive-latex-base`, `texlive-latex-extra`, `texlive-fonts-recommended`, `pandoc`, `zip` e os pacotes R `exams`, `rmarkdown` e `knitr`).

**O que cada formato de saída exige:**

| Formato | Depende de |
| --- | --- |
| PDF | LaTeX |
| HTML | Pandoc |
| Moodle (XML) | Pandoc |
| Download em `.zip` (qualquer formato) | `zip` |

## Estrutura do projeto

```text
Rexams/
├── app.R                          # Interface Shiny (a interface web)
├── R/
│   └── helpers.R                  # Lógica: lê o banco de questões, gera as provas e compacta o .zip
├── exercises/                     # BANCO DE QUESTÕES (disciplina/tema/arquivo.Rmd)
│   ├── estatistica/
│   │   ├── analise_exploratoria/  # assimetria_distribuicao.Rmd, colesterol_desviopadrao.Rmd
│   │   ├── facil/                 # media.Rmd
│   │   ├── inferencia/            # ic_media_imc.Rmd, interpretacao_pvalor.Rmd
│   │   └── regressao/             # coeficiente_dose_resposta.Rmd, interpretacao_r2.Rmd
│   └── matematica/
│       ├── dificil/               # equacao.Rmd
│       └── facil/                 # soma.Rmd
├── packages.R                     # Instala as dependências R (rodar uma vez)
├── docker-compose.yml             # Orquestrador do Docker (sincroniza as questões)
├── deploy/
│   └── Dockerfile                 # Empacota R + LaTeX + Pandoc + Zip + Shiny
├── .gitignore
└── README.md
```

Cada **disciplina** é uma pasta em `exercises/`, e cada **tema** (um assunto ou um nível de dificuldade) é uma subpasta dela. Para adicionar uma disciplina ou um tema, basta criar a pasta correspondente: a interface detecta automaticamente (veja as observações sobre reinício na seção [Rodar com Docker](#4-rodar-com-docker)).

## 1. Rodar localmente

```r
# 1. instalar dependências (uma vez só)
source("packages.R")

# 2. rodar o app
shiny::runApp()
```

O navegador abre com a interface do app. Os pré-requisitos estão na seção [Tecnologias usadas e necessárias](#tecnologias-usadas-e-necessárias).

## 2. Usando a interface

1. **Disciplina:** escolha a disciplina (uma pasta de `exercises/`).
2. **Tema:** marque os temas que podem entrar na prova (por padrão, todos vêm marcados).
3. **Número de questões:** quantas questões a prova terá.
4. **Número de versões:** de 1 a 20 versões (A, B, C…), cada uma com valores sorteados de novo.
5. **Formato de saída:** PDF (impressão), HTML (online) ou Moodle (XML).
6. **Com solução?** "Sem solução (prova)" ou "Com solução (gabarito)".
7. Clique em **Gerar Prova**. O painel **Status** mostra os arquivos gerados ou a mensagem de erro, e a tabela ao lado lista as questões disponíveis com os filtros escolhidos.
8. Clique em **Baixar Prova + Gabarito** para baixar um `.zip` com os arquivos da última geração.

## 3. Adicionar novas questões

Cada questão é um arquivo `.Rmd` (o app também reconhece `.Rnw`) no formato do R/Exams. **Quem define a disciplina e o tema é a pasta onde o arquivo está**, então salve o arquivo em `exercises/<disciplina>/<tema>/`. Exemplos prontos: `exercises/matematica/facil/soma.Rmd` (múltipla escolha), `exercises/estatistica/facil/media.Rmd` (resposta numérica) e `exercises/estatistica/regressao/interpretacao_r2.Rmd` (interpretação de resultado).

**Exemplo de múltipla escolha (`schoice`):**

~~~text
```{r, echo=FALSE, results="hide"}
# código R que sorteia os valores aleatórios
a <- sample(2:20, 1)
b <- sample(2:20, 1)
resultado <- a + b
```

Question
========
Enunciado usando os valores sorteados, ex: `r a` e `r b`.

Answerlist
----------
* `r resultado - 2`
* `r resultado`
* `r resultado + 3`
* `r resultado + 5`

Solution
========
Explicação da resposta.

Answerlist
----------
* Incorreto.
* Correto!
* Incorreto.
* Incorreto.

Meta-information
================
exname: nome_da_questao
extype: schoice
exsolution: 0100
exshuffle: TRUE
exsection: Disciplina/Tema
~~~

**Exemplo de resposta numérica (`num`):**

~~~text
```{r, echo=FALSE, results="hide"}
vals <- sample(1:30, 4)
media <- round(mean(vals), 2)
```

Question
========
Considere os valores `r paste(vals, collapse = ", ")`. Qual é a média aritmética?

Solution
========
A média é a soma dos valores dividida pela quantidade: `r media`.

Meta-information
================
exname: media_aritmetica
extype: num
exsolution: `r media`
extol: 0.05
exsection: Estatistica/Facil
~~~

Pontos de atenção:

* Em `schoice` e `mchoice`, a `Answerlist` da pergunta e a da solução precisam ter o mesmo número de itens. O `exsolution` é uma sequência de 0 e 1 com uma posição por alternativa (`0100` significa que a segunda é a correta).
* Em `num`, o `exsolution` é o valor correto e o `extol` é a tolerância aceita.
* O campo `exsection` é um metadado do R/Exams; o app **não** o usa para filtrar, quem filtra é a estrutura de pastas.

Tipos de questão suportados pelo exams: múltipla escolha (`schoice`/`mchoice`), numérica (`num`), texto curto (`string`) e cloze (mista). Documentação oficial: <https://www.r-exams.org/>.

## 4. Rodar com Docker

Alternativa ao passo 1 que evita instalar R, LaTeX e Pandoc na máquina: o Docker prepara o ambiente completo automaticamente, já com as permissões corrigidas. O `docker-compose.yml` mapeia a pasta local `exercises/` para dentro do container, então o banco de questões pode ser editado sem reconstruir a imagem.

```bash
# Para subir o app localmente via Docker (constrói a imagem e roda em segundo plano):
docker compose up -d --build

# Para parar quando terminar:
docker compose down
```

Acesse o sistema em `http://localhost:3838/rexams-web`.

Nem toda mudança em `exercises/` aparece sem reiniciar o app:

* **Novas questões (`.Rmd`)** e **novos temas** dentro de uma disciplina que já existe aparecem imediatamente, sem reiniciar nada (a lista é recarregada a cada interação na interface).
* **Novas disciplinas** (uma pasta nova direto em `exercises/`) só aparecem depois de reiniciar o container, porque a lista de disciplinas é carregada uma única vez quando o app sobe:

```bash
docker compose restart
```

## Solução de problemas

| Sintoma | O que verificar |
| --- | --- |
| Erro ao gerar PDF | Se o LaTeX está instalado e acessível: no R, rode `Sys.which("pdflatex")`; se vier vazio, instale o TinyTeX (`tinytex::install_tinytex()`) |
| Erro ao gerar HTML ou Moodle | Se o Pandoc está instalado (`rmarkdown::pandoc_available()`) |
| O botão de download falha | Se o utilitário `zip` está no PATH (no Windows, veja a seção de tecnologias) |
| "O número de questões pedido é maior do que o banco disponível…" | Marque mais temas ou reduza o número de questões |
| Nova disciplina não aparece (Docker) | Rode `docker compose restart` |

## Limitações conhecidas

* **Prova e gabarito são gerados separadamente.** Cada clique em **Gerar Prova** sorteia questões e valores novos, e o `.zip` traz apenas os arquivos da última geração (com ou sem solução, conforme a escolha). Por isso, uma prova gerada em um clique e um gabarito gerado em outro **não correspondem entre si**.
* A lista de disciplinas só é atualizada ao reiniciar o app.
* A tela mostra apenas a lista de arquivos de questão; não há pré-visualização renderizada da prova.
* Os arquivos gerados ficam em pastas temporárias; não há histórico nem login de usuários.

## Roadmap sugerido

**Fase 1 — MVP (este projeto)**

* [x] Estrutura de pastas por disciplina/tema
* [x] Interface Shiny com seleção de parâmetros
* [x] Geração de PDF/HTML/Moodle + gabarito
* [x] Exemplo de banco de questões

**Fase 2 — Usabilidade**

* [ ] Preview da prova antes de gerar (render de 1 versão em tela)
* [ ] Upload de novas questões `.Rmd` direto pela interface
* [ ] Campo de texto livre + IA generativa simples para transformar a descrição da questão em um arquivo `.Rmd` (no formato R/Exams) pronto para revisão do professor
* [ ] Tags além de disciplina/tema (ex: assunto, ano, autor)
* [ ] Cabeçalho/logo customizável (template LaTeX próprio da escola)
* [ ] Tornar a lista de disciplinas reativa, para que novas disciplinas apareçam sem precisar reiniciar o container

**Fase 3 — Escala**

* [ ] Trocar pastas por banco de dados (SQLite/Postgres) com metadados das questões
* [ ] Autenticação de professores (login)
* [ ] Histórico de provas geradas por usuário
* [ ] Exportação direta para Moodle via API (em vez de XML manual)
* [ ] Correção automática de respostas de alunos (exams2nops / scanner de folha óptica)
* [ ] Publicar o app em um servidor (shinyapps.io, Posit Connect ou Docker em VPS) para acesso fora da máquina local
