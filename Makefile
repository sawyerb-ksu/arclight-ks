SHELL = /bin/bash

# Define variables
BUILD_TAG ?= ksul-arclight:latest
DOCKER_COMPOSE = docker compose -f .docker/docker-compose.yml
APP_SERVICE = app
SOLR_SERVICE = solr
DATA_DIR = ./solr/arclight/data
EAD_DIR = ./my-ead/atom-export-ead

# Docker run helper
run_command = docker run --rm -v "$(shell pwd):/opt/app-root" $(BUILD_TAG)

# Rebuild Docker images without cache.
.PHONY: build 
build:
	$(DOCKER_COMPOSE) build --no-cache

#
.PHONY : clean
clean:
	rm -rf ./tmp/*
	rm -f ./log/*.log

.PHONY : test
test:
	./test.sh

.PHONY : accessibility
accessibility:
	./test-a11y.sh

# To start all the containers
.PHONY: start
start:
	$(DOCKER_COMPOSE) up -d

# To stop all the containers
.PHONY: stop
stop:
	$(DOCKER_COMPOSE) down

#To restart services without rebuilding
.PHONY: restart
restart:
	$(DOCKER_COMPOSE) down && $(DOCKER_COMPOSE) up -d

#To intialize db during intial set up
.PHONY: db-setup
db-setup:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) bundle exec rails db:schema:load
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) bundle exec rails db:prepare
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) bundle exec rails db:migrate

#to index the ead files in to solr
.PHONY: index-solr
index-solr:
	$(DOCKER_COMPOSE) exec $(APP_SERVICE) rake dul_arclight:index_dir DIR=/opt/app-root/finding-aid-data

#to fix solr permissions issue
.PHONY: solr-permissions
solr-permissions:
	sudo chown -R 8983:8983 $(DATA_DIR)
	sudo chmod -R 755 $(DATA_DIR)

# to check code style
.PHONY: rubocop
rubocop:
	$(run_command) bundle exec rubocop $(args)

# to fix code issues automatically like sytle issues
.PHONY: autocorrect
autocorrect:
	$(run_command) bundle exec rubocop -a

#freezes the dependencies before deploying
.PHONY: lock
lock:
	$(run_command) bundle lock


.PHONY: bundle-update
bundle-update:
	$(run_command) bundle update $(gems)
.PHONY: audit
audit:
	$(run_command) ./audit.sh

# For kubernetes
# .PHONY: update-chart
# update-chart:
# 	helm dependency update chart

# .PHONY: lint-chart
# lint-chart:
# 	helm lint chart --with-subcharts

# .PHONY: chart
# chart: update-chart lint-chart

# one command for intial set up
.PHONY: full-setup
full-setup: solr-permissions build start db-setup index-solr

