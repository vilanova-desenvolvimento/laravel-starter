# Leitura das variáveis do arquivo .env
include .env
export

# Converter a variável APP_NAME para minúsculas e concatenar com '-app'
APP_CONTAINER = $(addsuffix -app,$(shell echo $(APP_NAME) | tr '[:upper:]' '[:lower:]'))

.PHONY: help install

help: ## Print help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Inicia a aplicação.
	@docker compose up -d && \
		docker compose exec $(APP_CONTAINER) composer install && \
		docker compose exec $(APP_CONTAINER) php artisan key:generate
	






