# Imagem base com R + Shiny Server já configurados
FROM rocker/shiny:4.4.1

# LaTeX (necessário para exams2pdf) e Pandoc (necessário para exams2html)
RUN apt-get update && apt-get install -y \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Pacotes R do projeto
COPY packages.R /tmp/packages.R
RUN Rscript /tmp/packages.R

# Copia o app para a pasta padrão do Shiny Server
COPY . /srv/shiny-server/rexams-web

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
