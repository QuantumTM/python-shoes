#!/bin/bash
LOCATION="${PWD}"

function make_folders() {
	mkdir "bin"
}

function make_files() {
	touch "run"
	touch "main.py"
	touch "bin/activate"
	# touch ".project_aliases"
}

function inject_files() {
	echo "$PYTHON_FILE" > "main.py"
	echo "$RUN_FILE" > "run"
	echo "$ACTIVATE" > "bin/activate"
}

function make_venv() {
	python3 -m virtualenv --python=/usr/bin/python3.5 venv
}

function set_permissions() {
	chmod 755 "bin/activate"
	chmod 755 "run"
}

function main() {
	make_folders
	make_files
	inject_files
	set_permissions
	make_venv
}

PYTHON_FILE="
def run():
	print('Created-successfully')

def main():
	run()

if __name__ == '__main__':
	main()
"

ACTIVATE="#!/bin/bash
SRC_DIR=\"$LOCATION\"
source \"\$SRC_DIR/venv/bin/activate\"
export PYTHONPATH=\"\$SRC_DIR\"
"

RUN_FILE="#!/bin/bash
source \"$LOCATION/bin/activate\"
python \"\$@\"
"

main

