#!/usr/bin/env bash

function make_folders() {
	mkdir "bin"
}

function make_files() {
	touch "bin/activate"
	touch "bin/run_python"
	touch "run"
	touch "requirements.txt"
	touch "main.py"
}

function inject_files() {
	echo "${ACTIVATE}" > "bin/activate"
	echo "${PY_RUNNER}" > "bin/run_python"
	echo "${RUN_FILE}" > "run"
	echo "${REQUIREMENTS}" > "requirements.txt"
	echo "${PYTHON_FILE}" > "main.py"
}

function with_venv() {
    source venv/bin/activate
    "$@"
    deactivate
}

function make_venv() {
	python3 -m venv venv
	with_venv pip install -Ur requirements.txt
}

function set_permissions() {
	chmod 755 "bin/activate"
	chmod 755 "bin/run_python"
	chmod 755 "run"
}

function main() {
    echo 'Creating project structure...'
	make_folders
	make_files
	inject_files
	set_permissions
	echo 'Creating virtual enviroment...'
	make_venv
}

LOCATION="$(dirname "$(readlink -f "$0")")"

PYTHON_FILE='
def run():
	print("Created-successfully")

def main():
	run()

if __name__ == "__main__":
	main()
'

ACTIVATE='#!/usr/bin/env bash
source "'${LOCATION}'/venv/bin/activate"
# add any other env configuration settings here
'

PY_RUNNER='#!/usr/bin/env bash
source "${PROJECT_ROOT}/bin/activate"
python "$@"
deactivate
'

RUN_FILE='#!/usr/bin/env bash
PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
echo "Using project root at: $PROJECT_ROOT"
PROJECT_ROOT=${PROJECT_ROOT} ${PROJECT_ROOT}/bin/run_python "$@"
'

REQUIREMENTS='# basic requirements
pip
setuptools
wheel

# cutom requirements
'

main
