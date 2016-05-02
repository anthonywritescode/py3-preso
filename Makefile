all: build-files

venv: requirements.txt
	rm -rf venv
	virtualenv venv
	venv/bin/pip install -rrequirements.txt
	venv/bin/pre-commit install -f --install-hooks

nenv: | venv
	rm -rf nenv
	venv/bin/nodeenv --prebuilt nenv
	. nenv/bin/activate && npm install -g bower

bower_components: bower.json | nenv
	. nenv/bin/activate && bower install

build:
	mkdir $@

build/%.css: assets/%.scss build bower_components | venv
	venv/bin/sassc $< $@

build/reveal.min.css: build bower_components
	cp bower_components/reveal.js/css/reveal.min.css $@

build/reveal.min.js: build bower_components
	cp bower_components/reveal.js/js/reveal.min.js $@

build/idea.css: build bower_components
	cp bower_components/highlightjs/styles/idea.css $@

build/highlight.pack.js: build bower_components
	cp bower_components/highlightjs/highlight.pack.js $@

build/jquery.min.js: build bower_components
	cp bower_components/jquery/jquery.min.js $@

build/python-logo.png: build
	cp assets/python-logo.png $@

.PHONY: build-files
build-files: build/reveal.css build/presentation.css
build-files: build/reveal.min.css build/reveal.min.js
build-files: build/idea.css build/highlight.pack.js
build-files: build/jquery.min.js
build-files: build/python-logo.png

clean:
	rm -rf venv nenv bower_components assets/*.css
	find -name '*.pyc' -delete
