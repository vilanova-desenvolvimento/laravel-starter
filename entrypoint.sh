#!/bin/bash

# Arquivo de variaveis da aplicação
env_example=".env.example"
env_file=".env"

# Obter o valor da variável APP_IMAGE do arquivo .env
app_image=$(grep -E "^APP_IMAGE=" "$env_example" | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
# Obter o valor da variável APP_PORT do arquivo .env e remover quaisquer caracteres não numéricos
app_port=$(grep -E "^APP_PORT=" "$env_example" | cut -d '=' -f2 | tr -cd '[:digit:]')

# Verificar se a variável APP_NAME existe no arquivo .env
app_name=$(grep -E "^APP_NAME=" "$env_example" | cut -d '=' -f2 | sed -e 's/^"//' -e 's/"$//')
# Converter o valor da variável APP_NAME para minúsculas
app_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')
# Substituir espaços em branco por hífens e remover caracteres não alfanuméricos
app_name=$(echo "$app_name" | tr ' ' '-' | sed -E 's/[^a-zA-Z0-9-]//g')

# Verificar se a variável APP_NAME existe e tem pelo menos 3 caracteres
if [ -z "$app_name" ] || [ ${#app_name} -lt 3 ]; then
    echo "\e[31mA variável APP_NAME não está definida no arquivo .env.example ou possui menos de 3 caracteres. Encerrando o script.\e[0m"
fi

# Verificar se existe um container com o mesmo nome da aplicação
if docker ps --format "{{.Names}}" | grep -q "^${app_name}-app"; then
    echo "\e[31mJá existe um container com o nome '${app_name}-app' em execução. \nSe estiver tentando subir uma nova aplicaçação, altere o valor de APP_NAME. \nEncerrando o script.\e[0m"
    exit 1
fi

# Copiar o arquivo .env.example para .env, se o arquivo .env não existir
if [ ! -f "$env_file" ]; then
    cp "$env_example" "$env_file"
    echo "\e[32mArquivo $env_file copiado do $env_example.\e[0m"

    # Substituir o valor da variável REDIS_HOST no arquivo .env pelo valor ${app_name}-redis
    sed -i "s/^REDIS_HOST=.*/REDIS_HOST=${app_name}-redis/" "$env_file"

    echo "\e[32mValor da variável REDIS_HOST substituído por ${app_name}-redis no arquivo $env_file.\e[0m"
else
    echo "\e[33mO arquivo $env_file já existe. Não será copiado novamente. Encerrando o script. \e[0m"
    exit 1
fi

# Verificar se o arquivo docker-compose.yml já existe
docker_compose_file="docker-compose.yml"
if [ -f "$docker_compose_file" ]; then
    echo "\e[31mO arquivo $docker_compose_file já existe. Encerrando o script.\e[0m"
fi

# Verificar se o diretório docker-compose/nginx existe, se não, criá-lo
nginx_dir="docker-compose/nginx/"
if [ ! -d "$nginx_dir" ]; then
    mkdir -p "$nginx_dir"
    echo "\e[32mDiretório $nginx_dir criado com sucesso.\e[0m"
else
    echo "\e[33mO diretório $nginx_dir já existe. Não será criado novamente.\e[0m"
fi

# Verificar se o arquivo nginx.conf já existe
nginx_conf="docker-compose/nginx/nginx.conf"
if [ -f "$nginx_conf" ]; then
    echo "\e[31mO arquivo $nginx_conf já existe. Encerrando o script.\e[0m"
    exit 1
fi

# Criar o conteúdo do arquivo nginx.conf substituindo a variável
echo "server {
    listen 80;   
    index index.php;
    root /var/www/public;

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass ${app_name}-app:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
        gzip_static on;
    }

    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}" > "$nginx_conf"

echo "\e[32mArquivo $nginx_conf criado com sucesso!\e[0m"

# Criar o arquivo docker-compose.yml
echo "version: \"3.8\"

services:
  # application
  ${app_name}-app:
    container_name: ${app_name}-app
    image: ${app_image}
    working_dir: /var/www/
    volumes:
      - ./:/var/www/
    restart: unless-stopped
    extra_hosts:
      - host.docker.internal:host-gateway
    depends_on:
      - ${app_name}-redis
    networks:
      - ${app_name}

  #queue  
  ${app_name}-queue:
    container_name: ${app_name}-queue
    image: ${app_image}
    working_dir: /var/www/
    volumes:
      - ./:/var/www/
    restart: unless-stopped
    extra_hosts:
      - host.docker.internal:host-gateway
    depends_on:
      - ${app_name}-redis          
    networks:
      - ${app_name}

  #nginx  
  ${app_name}-nginx:
    container_name: ${app_name}-nginx
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - \${APP_PORT}:80
    volumes:
      - ./docker-compose/nginx/:/etc/nginx/conf.d/
      - ./:/var/www
    networks:
      - ${app_name}

  # redis  
  ${app_name}-redis:
    container_name: ${app_name}-redis
    image: redis:latest
    restart: unless-stopped
    networks:
      - ${app_name}

networks:
  ${app_name}:
    name: ${app_name}" > "$docker_compose_file"

echo "\e[32mArquivo $docker_compose_file criado com sucesso!\e[0m"

echo "\e[32mInstalando as dependencias da aplicação \e[0m"

# Instala as dependencias da aplicação
docker compose up -d && \
		docker compose exec ${app_name}-app composer install --quiet && \
		docker compose exec ${app_name}-app php artisan key:generate

echo "\e[37m\e[44mAplicação acessível em: http://localhost:${app_port} \e[0m"








