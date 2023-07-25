# Verifica se o arquivo .env existe antes de incluí-lo
ifneq ($(wildcard .env),)
    include .env
    export
endif

# Converter a variável APP_NAME para minúsculas, substituir espaços em branco por hífens e remover caracteres não alfanuméricos
APP_CONTAINER = $(addsuffix -app, $(shell echo $(APP_NAME) | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed -E 's/[^a-zA-Z0-9-]//g'))

# Ler o conteúdo da variável APP_ENV
APP_ENV_CONTENT := $(APP_ENV)

.PHONY: help install uninstall

help: ## Print help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Cria os arquivos de configuração de aplicação, sobe os containers e instala as suas dependencias
	@sh ./entrypoint.sh

## Impede que estes comandos sejam executados por em produção
ifeq ($(strip $(APP_ENV_CONTENT)),local)

uninstall: ## Derruba os container da aplicação e limpa arquivos relacionados.	
	@rm -rf docker-compose
	@rm -f composer.lock
	@rm -f .env
	@docker compose down --remove-orphans
	@rm -f docker-compose.yml

endif
