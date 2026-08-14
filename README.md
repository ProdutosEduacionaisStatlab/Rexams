# Gerador de Provas Automáticas — R/Exams + Shiny

Interface web para professores criarem provas com questões e valores
aleatórios **sem precisar programar**, usando o pacote R/Exams por trás.

## Estrutura do projeto

```
rexams-web/
├── app.R                  # Interface Shiny (o "site")
├── R/
│   └── helpers.R          # Lógica: lê o banco de questões e chama o exams
├── exercises/              # BANCO DE QUESTÕES
│   ├── matematica/
│   │   ├── facil/
│   │   └── dificil/
│   └── estatistica/
│       └── facil/
├── packages.R              # Instala dependências R (rodar uma vez)
├── deploy/
│   └── Dockerfile          # Empacota R + LaTeX + Shiny
└── .gitignore
```

Cada disciplina é uma pasta em `exercises/`, e cada nível de dificuldade é
uma subpasta. Para adicionar uma nova disciplina ou dificuldade, basta criar
a pasta correspondente — a interface detecta automaticamente.

## 1. Rodar localmente

**Pré-requisitos:**
- R (>= 4.2) — https://cran.r-project.org
- Uma distribuição LaTeX (para gerar PDF): TinyTeX é a mais simples
- Pandoc (para gerar HTML) — normalmente já vem com o RStudio

```r
# 1. instalar dependências (uma vez só)
source("packages.R")

# 2. rodar o app
shiny::runApp()
```

O navegador vai abrir com a interface: escolher disciplina, dificuldade,
número de questões, número de versões e formato, clicar em **Gerar Prova**
e depois **Baixar Prova + Gabarito** (um `.zip`).

## 2. Adicionar novas questões

Cada questão é um arquivo `.Rmd` no formato do R/Exams (veja os exemplos em
`exercises/matematica/facil/soma.Rmd`). Estrutura básica:

```
```{r, echo=FALSE, results="hide"}
# código R que sorteia os valores aleatórios
```

Question
========
Enunciado usando os valores sorteados, ex: `r a`

Solution
========
Explicação da resposta

Meta-information
================
exname: nome_da_questao
extype: schoice | mchoice | num | string | cloze
exsolution: gabarito
exsection: Disciplina/Dificuldade
```

Tipos de questão suportados pelo exams: múltipla escolha (`schoice`/`mchoice`),
numérica (`num`), texto curto (`string`) e cloze (mista). Documentação oficial:
https://www.r-exams.org/

## 3. Publicar o site (deploy)

**Opção A — shinyapps.io (mais simples, gratuito para uso leve)**
```r
install.packages("rsconnect")
rsconnect::setAccountInfo(name="SEU_NOME", token="...", secret="...")
rsconnect::deployApp()
```
⚠️ shinyapps.io não tem LaTeX instalado por padrão — configure o TinyTeX
como pacote R (`tinytex::install_tinytex()`) antes do deploy, ou use apenas
saída HTML/Moodle nesse plano.

**Opção B — Docker (recomendado para produção, já vem com LaTeX)**
```bash
docker build -t rexams-web -f deploy/Dockerfile .
docker run -p 3838:3838 rexams-web
```
Acesse em `http://localhost:3838/rexams-web`. Pode subir essa imagem em
qualquer serviço que rode containers (Posit Connect, servidor próprio,
Render, Fly.io, etc.).

## 4. Roadmap sugerido

**Fase 1 — MVP (este projeto)**
- [x] Estrutura de pastas por disciplina/dificuldade
- [x] Interface Shiny com seleção de parâmetros
- [x] Geração de PDF/HTML/Moodle + gabarito
- [x] Exemplo de banco de questões

**Fase 2 — Usabilidade**
- [ ] Preview da prova antes de gerar (render de 1 versão em tela)
- [ ] Upload de novas questões `.Rmd` direto pela interface
- [ ] Tags além de disciplina/dificuldade (ex: assunto, ano, autor)
- [ ] Cabeçalho/logo customizável (template LaTeX próprio da escola)

**Fase 3 — Escala**
- [ ] Trocar pastas por banco de dados (SQLite/Postgres) com metadados das questões
- [ ] Autenticação de professores (login)
- [ ] Histórico de provas geradas por usuário
- [ ] Exportação direta para Moodle via API (em vez de XML manual)
- [ ] Correção automática de respostas de alunos (exams2nops / scanner de folha óptica)

## Ferramentas usadas / necessárias

| Ferramenta | Função |
|---|---|
| R | linguagem base |
| pacote `exams` | motor de geração/aleatorização/correção |
| Shiny | framework da interface web |
| LaTeX (TinyTeX) | renderização de PDF |
| Pandoc | renderização de HTML/Moodle |
| Git/GitHub | versionamento e colaboração |
| Docker (opcional) | empacotar ambiente completo para deploy |
| shinyapps.io / Posit Connect (opcional) | hospedagem do site |
