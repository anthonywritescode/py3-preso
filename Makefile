all: scss

.PHONY: scss
scss: assets/reveal.css assets/presentation.css

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

%.css: %.scss bower_components | venv
	venv/bin/sassc $< $@

clean:
	rm -rf venv nenv bower_components assets/*.css
	find -name '*.pyc' -delete
