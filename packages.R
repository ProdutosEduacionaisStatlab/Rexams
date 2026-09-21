# Execute este script uma vez para instalar as dependências do projeto
pacotes <- c("shiny", "exams", "rmarkdown", "knitr", "tools", "httr2", "pdftools", "officer")

instalar_se_faltando <- function(p) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
}

invisible(lapply(pacotes, instalar_se_faltando))

# Para gerar PDF é necessário uma distribuição LaTeX.
# Se não tiver LaTeX instalado no sistema, use o tinytex:
if (!requireNamespace("tinytex", quietly = TRUE)) install.packages("tinytex")
if (!nzchar(Sys.which("pdflatex")) && !tinytex::is_tinytex()) {
  tinytex::install_tinytex()
}