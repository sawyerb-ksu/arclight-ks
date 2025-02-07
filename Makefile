SHELL = /bin/bash

build_tag ?= dul-arclight:latest

run_command = docker run --rm -v "$(shell pwd):/opt/app-root" $(build_tag)

.PHONY : build
build:
	./build.sh

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

.PHONY : rubocop
rubocop:
	$(run_command) bundle exec rubocop $(args)

.PHONY : autocorrect
autocorrect:
	$(run_command) bundle exec rubocop -a

.PHONY: lock
lock:
	$(run_command) bundle lock

.PHONY: update
update:
	$(run_command) bundle update $(gems)

.PHONY: audit
audit:
	$(run_command) ./audit.sh

.PHONY: update-chart
update-chart:
	helm dependency update chart

.PHONY: lint-chart
lint-chart:
	helm lint chart --with-subcharts

.PHONY: chart
chart: update-chart lint-chart
