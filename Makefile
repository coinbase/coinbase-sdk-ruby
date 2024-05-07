.PHONY: format
format:
	bundle exec rubocop -A

.PHONY: lint
lint:
	bundle exec rubocop

.PHONY: test
test:
	bundle exec rake test

.PHONY: repl
repl:
	bundle exec bin/repl

.PHONY: docs
docs:
	bundle exec yardoc --output-dir ./docs --quiet --template-path ./docs/templates
