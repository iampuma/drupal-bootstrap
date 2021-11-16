##
## Drupal Bootstrap
##

# This is a clever trick to mimick help functionality
# Execute `make` or `make help` to see all command comments that are commented with a double # symbol
# Example: `up: ## Initialize, install and serve the Drupal instance`
help: ## Show available commands (default)
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS="([a-z|:]) ## "} {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

up: ## Initialize, install and serve the Drupal instance
	make init
	make install
	make start

init: ## Download and install latest Drupal and composer requirements
	php -d memory_limit=-1 /usr/local/bin/composer create-project drupal-composer/drupal-project:9.x-dev drupal --no-interaction
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer require drush/drush

install: ## Install 'Custom demo' profile instance
	cd drupal/web && php -d memory_limit=-1 ./core/scripts/drupal install standard --site-name="Demo"
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer require drupal/admin_toolbar
	cd drupal && ./vendor/bin/drush en -y admin_toolbar admin_toolbar_tools admin_toolbar_links_access_filter

install-minimal: ## Install 'Minimal' profile instance
	cd drupal/web && php -d memory_limit=-1 ./core/scripts/drupal install minimal

install-standard: ## Install 'Standard' profile instance
	cd drupal/web && php -d memory_limit=-1 ./core/scripts/drupal install standard

install-umami: ## Install 'Umami Demo' profile instance
	cd drupal/web && php -d memory_limit=-1 ./core/scripts/drupal install demo_umami

start: ## Run local webserver and serve current Drupal instance
	cd drupal/web && php -d memory_limit=-1 ./core/scripts/drupal server

down: ## Remove the current project (codebase+db!)
	sudo rm -rf drupal

clean: ## Cleanup the current project for a fresh install (db+settings.php, keeps the codebase)
	cd drupal/web && sudo rm -f ./sites/default/settings.php
	cd drupal/web && sudo rm -f ./sites/default/files/.sqlite
	cd drupal/web && sudo chmod +w ./sites/default