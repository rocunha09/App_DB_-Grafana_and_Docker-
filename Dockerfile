FROM php:7.4-apache

# Instalar pacotes necessários
RUN apt-get update && apt-get install -y \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ativar o módulo headers do Apache
RUN a2enmod headers

# Copiar a configuração personalizada do Apache
#COPY apache.conf /etc/apache2/sites-available/000-default.conf

# Definir o diretório de trabalho
WORKDIR /var/www/html

# Copiar os arquivos do projeto
COPY ./html /var/www/html
