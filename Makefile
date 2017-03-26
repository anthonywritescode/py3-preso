all: build-files

venv: requirements.txt
	rm -rf venv
	virtualenv venv -ppython3.6
	venv/bin/pip install -rrequirements.txt
	venv/bin/pre-commit install -f --install-hooks

node_modules: package.json
	npm install

build:
	mkdir $@

build/%.css: assets/%.scss $(wildcard assets/*.scss) build node_modules | venv
	venv/bin/sassc -t compressed $< $@

build/%.png: assets/%.png build
	cp $< $@

build/reveal.min.js: build node_modules
	cp node_modules/reveal.js/js/reveal.min.js $@

build/highlight.pack.min.js: build node_modules
	cp node_modules/highlightjs/highlight.pack.min.js $@

.PHONY: build-files
build-files: build/presentation.css
build-files: build/reveal.min.js
build-files: build/highlight.pack.min.js
build-files: build/python-logo.png

clean:
	rm -rf venv node_modules build
	find -name '*.pyc' -delete
