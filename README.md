# Instruções para executar a aplicação

Para executar a aplicação, siga os seguintes passos:

1. Preencher as variáveis de ambiente no arquivo `.env.example`:

APP_NAME="Laravel microservico" # Nome da aplicação, será base dos containers
APP_PORT=8002 # Porta em que a aplicação será executada
APP_IMAGE="devsidnei/php8.2-fpm-dev:latest" # Imagem PHP utilizada na criação dos containers

2. Utilize o comando `make` para listar as opções disponíveis:

Targets:
help Print help.
install Cria os arquivos de configuração de aplicação, sobe os containers e instala as suas dependências.
uninstall Comando destrutivo. Destroi os containers da aplicação e apaga arquivos relacionados.


3. Execute o comando `make install` para subir a aplicação usando o Docker pela primeira vez.

Em caso de erro ou necessidade de remoção:

4. Utilize o comando `make uninstall` para remover arquivos e desfazer a configuração.

Após a configuração inicial, você pode usar os comandos padrão do Docker Compose para gerenciar a aplicação.

```bash
docker-compose up -d    # Inicia os containers em modo background
docker-compose down     # Derruba os containers
docker-compose logs     # Exibe os logs dos containers
```

Lembre-se de verificar a documentação do Docker Compose para mais detalhes sobre o gerenciamento dos containers da aplicação.