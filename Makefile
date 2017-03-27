all: run-build

venv: requirements.txt
	rm -rf venv
	virtualenv venv -ppython3.6
	venv/bin/pip install -rrequirements.txt
	venv/bin/pre-commit install -f --install-hooks

MTP := run-build push
.PHONY: $(MTP)
$(MTP): venv
	venv/bin/markdown-to-presentation $@

clean:
	rm -rf .mtp venv build index.htm
