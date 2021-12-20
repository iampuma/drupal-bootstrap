##
## Drupal Bootstrap Pro
##

# Split all arguments for easier use in commands.
# You can now use the variables: ${ARGS} ${ARG_1} ${ARG_2} ${ARG_3} ${ARG_REST}
# @see https://stackoverflow.com/questions/2214575/passing-arguments-to-make-run#answer-45003119
ARGS = $(filter-out $@,$(MAKECMDGOALS))
ARG_1 = $(word 1, ${ARGS})
ARG_2 = $(word 2, ${ARGS})
ARG_3 = $(word 3, ${ARGS})
ARG_REST = $(wordlist 2, 100, ${ARGS})
## We use the following rule/recipe to prevent errors messages when passing arguments in make commands
## @see https://stackoverflow.com/a/6273809/1826109
%:
	@:

# This is a clever trick to mimick help functionality
# Execute `make` or `make help` to see all command comments that are commented with a double # symbol
# Example: `up: ## Initialize, install and serve the Drupal instance`
help: ## Show available commands (default)
	@grep -E '^([a-zA-Z_-]| )+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS="([a-z|:]) ## "} {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

init: ## Initialize, download, install custom profile and serve the Drupal instance
	make build
	make profile-install-custom
	make start

build: ## Download and install latest Drupal and composer requirements + configuration
	php -d memory_limit=-1 /usr/local/bin/composer create-project drupal-composer/drupal-project:9.x-dev drupal --no-interaction
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer require dealerdirect/phpcodesniffer-composer-installer --dev
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer require phpspec/prophecy-phpunit:^2 --dev
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer require drupal/console:~1.0 --dev --prefer-dist --optimize-autoloader
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer require drupal/drupal-extension --dev
	make configure-phpunit
	make configure-behat

profile-install-custom: ## Install `Standard` profile instance + admin_toolbar (default)
	make profile-install standard
	make module admin_toolbar
	make module-install admin_toolbar_tools admin_toolbar_links_access_filter

profile-install: ## Install a <profile> instance (minimal, standard or umami) `make profile-install umami`
	cd drupal/web && php -d memory_limit=-1 ./core/scripts/drupal install ${ARG_1}

start: ## Run local webserver and serve current Drupal instance
	cd drupal && ./vendor/bin/drush uli --uri localhost:8888
	cd drupal/web && php -d memory_limit=-1 -S localhost:8888 .ht.router.php

remove: ## Remove the current project (codebase+db!)
	sudo rm -rf drupal

clean: ## Cleanup the current project for a fresh install (db+settings.php, keeps the codebase)
	cd drupal/web && sudo rm -f ./sites/default/settings.php
	cd drupal/web && sudo rm -f ./sites/default/files/.sqlite
	cd drupal/web && sudo chmod +w ./sites/default

cr: # Drupal cache rebuild
	cd drupal && ./vendor/bin/drush cr

console: ## Run drupal console
	cd drupal && ./vendor/bin/drupal ${ARGS}

drush: ## Run drush
	cd drupal && ./vendor/bin/drush ${ARGS}

phpcs: ## Run phpcs on a <module> `make phpcs admin_toolbar`
	cd drupal && ./vendor/bin/phpcs --standard=Drupal web/modules/*/${ARG_1}

phpcbf: ## Run phpcbf on a <module> `make phpcbf admin_toolbar`
	cd drupal && ./vendor/bin/phpcbf --standard=Drupal web/modules/*/${ARG_1}

phpunit: ## Run PHPUnit
	cd drupal && ./vendor/bin/phpunit ${ARGS}

behat: ## Run behat
	cd drupal && ./vendor/bin/behat ${ARGS}

module-install: ## Download and enable a <module> `make module-install admin_toolbar`
	make module-download ${ARG_1}
	make module-enable ${ARG_1}

module-source: ## Download and install a <module> from source `make module-source styled_google_map`
	cd drupal/web && rm -rf modules/contrib/${ARG_1}
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer require drupal/${ARG_1} --prefer-source
	make module-install ${ARG_1}
	make phpcs ${ARG_1}

module-download: ## Downloads a <module> `make module-download styled_google_map`
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer require drupal/${ARG_1}

module-enable: ## Installs a <module> `make module-enable styled_google_map`
	cd drupal && ./vendor/bin/drush pm:enable -y ${ARGS}

module-uninstall: ## Uninstalls a <module> `make module-uninstall styled_google_map`
	cd drupal && ./vendor/bin/drush pm:uninstall -y ${ARGS}

module-remove: ## Removes a <module> `make module-remove styled_google_map`
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer remove drupal/${ARG_1}

patch-test: ## Test out <patch> in the patches folder for <module> `make patch-test patches/mymodule.patch styled_google_map`
	#cd drupal && php -d memory_limit=-1 composer config extra.enable-patching true
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer config --json --merge extra.patches '{"drupal/${ARG_2}": {"patch-test": "${ARG_1}"}}'
	cd drupal && php -d memory_limit=-1 /usr/local/bin/composer install
	make cr

patch-create: ## Create a patch of a <module> in the drupal patches folder `make patch-create styled_google_map`
	echo '[project_name]-[short-description]-[issue-number]-[comment-number].patch'
	mkdir -p drupal/patches && cd drupal/web/modules/contrib/${ARG_1} && git diff > ../../../../patches/${ARG_1}.patch

site-mode: ## Set the Drupal site mode (dev or prod) `make site-mode dev`
	cd drupal/web && sudo chmod +w ./sites/default
	cd drupal && ./vendor/bin/drupal site:mode ${ARG_1}

configure-phpunit: ## Configure phpunit settings
	cd drupal/web && mkdir -p sites/simpletest/browser_output
	cd drupal/web && chmod -R 777 sites/simpletest
	cd drupal/web/core && cp phpunit.xml.dist ../../phpunit.xml
	cd drupal && sed -i '' 's%name="SIMPLETEST_BASE_URL" value=""%name="SIMPLETEST_BASE_URL" value="http://localhost:8888"%g' phpunit.xml
	cd drupal && sed -i '' 's|name="SIMPLETEST_DB" value=""|name="SIMPLETEST_DB" value="sqlite://localhost/sites/default/files/.sqlite"|g' phpunit.xml
	cd drupal && sed -i '' 's|name="BROWSERTEST_OUTPUT_DIRECTORY" value=""|name="BROWSERTEST_OUTPUT_DIRECTORY" value="web/sites/simpletest/browser_output"|g' phpunit.xml
	cd drupal && sed -i '' 's|tests/bootstrap.php|web/core/tests/bootstrap.php|g' phpunit.xml
	cd drupal && sed -i '' 's|<file>./tests/TestSuites|<file>web/core/tests/TestSuites|g' phpunit.xml
	cd drupal && sed -i '' 's|<directory>../|<directory>web/core/|g' phpunit.xml
	cd drupal && sed -i '' 's|<directory>./|<directory>web/core/|g' phpunit.xml

configure-behat: ## Configure behat settings
	cp behat.yml.dist drupal/behat.yml
	cd drupal && mkdir -p features
