# Gerador de Provas Automáticas — R/Exams + Shiny

Interface web para professores criarem provas com questões e valores
aleatórios **sem precisar programar**, usando o pacote R/Exams por trás.

## Estrutura do projeto

```text
rexams-web/
├── app.R                  # Interface Shiny (o "site")
├── R/
│   └── helpers.R          # Lógica: lê o banco de questões e chama o exams
├── exercises/             # BANCO DE QUESTÕES
│   ├── matematica/
│   │   ├── facil/
│   │   └── dificil/
│   └── estatistica/
│       └── facil/
├── packages.R             # Instala dependências R (rodar uma vez)
├── docker-compose.yml     # Orquestrador do Docker (sincroniza as questões)
├── deploy/
│   └── Dockerfile         # Empacota R + LaTeX + Pandoc + Zip + Shiny
└── .gitignore
```

Cada disciplina é uma pasta em `exercises/`, e cada nível de dificuldade é
uma subpasta. Para adicionar uma nova disciplina ou dificuldade, basta criar
a pasta correspondente — a interface detecta automaticamente.

## 1. Rodar localmente

**Pré-requisitos:**

* R (>= 4.2) — https://cran.r-project.org
* Uma distribuição LaTeX (para gerar PDF): TinyTeX é a mais simples
* Pandoc (para gerar HTML) — normalmente já vem com o RStudio
* Um utilitário `zip` disponível no PATH do sistema (necessário para o
  botão "Baixar Prova + Gabarito", que compacta o PDF e o gabarito). No
  Linux/macOS geralmente já vem instalado; no Windows, garanta que o
  Git Bash/Rtools (ou outro `zip.exe`) esteja no PATH.

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

~~~text
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
~~~

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

**Opção B — Docker Compose (Recomendado)**

Esta opção prepara todo o ambiente automaticamente, já com R, LaTeX, Pandoc
e as permissões corrigidas. O arquivo `docker-compose.yml` mapeia a pasta
local `exercises/` para dentro do container.

Nem toda mudança em `exercises/` aparece sem reiniciar o app:

* **Novas questões (`.Rmd`)** e **novos níveis de dificuldade** dentro de
  uma disciplina que já existe → aparecem imediatamente, sem precisar
  reiniciar nada (a lista é recarregada a cada interação na interface).
* **Novas disciplinas** (uma pasta nova direto em `exercises/`) → só
  aparecem depois de reiniciar o container, porque a lista de disciplinas
  é carregada uma única vez quando o app sobe:

```bash
docker compose restart
```

```bash
# Para iniciar o servidor (baixa as dependências e roda em segundo plano):
docker compose up -d --build

# Para parar o servidor quando terminar:
docker compose down
```

Acesse o sistema em `http://localhost:3838/rexams-web`.

## 4. Roadmap sugerido

**Fase 1 — MVP (este projeto)**

* [x] Estrutura de pastas por disciplina/dificuldade
* [x] Interface Shiny com seleção de parâmetros
* [x] Geração de PDF/HTML/Moodle + gabarito
* [x] Exemplo de banco de questões

**Fase 2 — Usabilidade**

* [ ] Preview da prova antes de gerar (render de 1 versão em tela)
* [ ] Upload de novas questões `.Rmd` direto pela interface
* [ ] Tags além de disciplina/dificuldade (ex: assunto, ano, autor)
* [ ] Cabeçalho/logo customizável (template LaTeX próprio da escola)
* [ ] Tornar a lista de disciplinas reativa, para que novas disciplinas
      apareçam sem precisar reiniciar o container

**Fase 3 — Escala**

* [ ] Trocar pastas por banco de dados (SQLite/Postgres) com metadados das questões
* [ ] Autenticação de professores (login)
* [ ] Histórico de provas geradas por usuário
* [ ] Exportação direta para Moodle via API (em vez de XML manual)
* [ ] Correção automática de respostas de alunos (exams2nops / scanner de folha óptica)

## Ferramentas usadas / necessárias

| Ferramenta | Função |
| --- | --- |
| R | linguagem base |
| pacote `exams` | motor de geração/aleatorização/correção |
| Shiny | framework da interface web |
| LaTeX | renderização de PDF (instalado nativamente no Docker via apt-get) |
| Pandoc | renderização de HTML/Moodle |
| zip | compacta prova + gabarito para download |
| Docker Compose | empacotar e orquestrar ambiente completo para deploy |
| shinyapps.io / Posit Connect (opcional) | hospedagem do site |