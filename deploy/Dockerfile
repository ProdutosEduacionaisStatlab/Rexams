# 1. Imagem base oficial com R e Shiny Server
FROM rocker/shiny:4.4.1

# 2. Instalação de ferramentas do sistema (LaTeX, Pandoc e Zip)
RUN apt-get update && apt-get install -y \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-recommended \
    pandoc \
    zip \
    libpoppler-cpp-dev \
    libxml2-dev \
    libicu-dev \
    libssl-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Instalação dos pacotes do R diretamente
RUN R -e "install.packages(c('exams', 'rmarkdown', 'knitr', 'httr2', 'pdftools', 'officer'), repos='https://cloud.r-project.org/')"

# 4. Limpa o aplicativo padrão da imagem
RUN rm -rf /srv/shiny-server/*

# 5. Copia os arquivos do projeto para a subpasta rexams-web
COPY ./ /srv/shiny-server/rexams-web

# 6. Ajusta as permissões para o servidor conseguir gerar os PDFs
RUN chown -R shiny:shiny /srv/shiny-server

EXPOSE 3838
CMD ["/usr/bin/shiny-server"]