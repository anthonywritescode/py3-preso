all: run-build

venv: requirements.txt
	rm -rf venv
	virtualenv venv -ppython3
	venv/bin/pip install -rrequirements.txt
	venv/bin/pre-commit install

.PHONY: run-build
run-build: venv
	venv/bin/markdown-to-presentation run-build

.PHONY: push
push: venv
	venv/bin/markdown-to-presentation push index.htm build

clean:
	rm -rf .mtp venv build index.htm
