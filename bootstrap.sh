#!/usr/bin/env bash

function make_folders() {
	mkdir "bin"
	mkdir "common"
}

function make_files() {
	touch "bin/run_python.sh"
	touch ".gitignore"
	touch "run"
	touch "requirements.txt"
	touch "main.py"
	touch "common/logging.py"
	touch "config.py"
}

function inject_files() {
	echo "${PY_RUNNER}" > "bin/run_python.sh"
	echo "${GITIGNORE}" > ".gitignore"
	echo "${RUN_FILE}" > "run"
	echo "${REQUIREMENTS}" > "requirements.txt"
	echo "${PYTHON_FILE}" > "main.py"
	echo "${LOGGINGPY}" > "common/logging.py"
	echo "${CONFIGPY}" > "config.py"
}

function with_venv() {
    source venv/bin/activate
    "$@"
    deactivate
}

function make_venv() {
	python3 -m venv venv
	with_venv pip install -U pip
	with_venv pip install -Ur requirements.txt
}

function set_permissions() {
	chmod 755 "bin/run_python.sh"
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
from common import logging

logger = logging.get_logger("main")

def run():
	logger.info("Bootstrap successfully!")

def main():
	run()

if __name__ == "__main__":
	with logging.init("app").applicationbound():
		main()
'

LOGGINGPY='import sys
import logbook

def init(app_name):
	handlers = [
		logbook.StreamHandler(sys.stdout, level=0, bubble=True)
	]
	return logbook.NestedSetup(handlers)

def get_logger(logger_name):
	return logbook.Logger(logger_name)
'

CONFIGPY='import os
from configparser import ConfigParser

CONFIG_NAME = "app.conf"

def load():
	cfg = ConfigParser()
	loc = os.path.join(os.path.dirname(os.path.abspath(__file__)), CONFIG_NAME)
	with open(loc) as f:
		cfg.read_file(f)
	cfg.config_path = loc
	print("Found config file {}".format(loc))
	return cfg

def create(config_dict):
	path = os.path.join(os.path.dirname(os.path.abspath(__file__)), CONFIG_NAME)
	print("Creating config: {}".format(path))
	cfg = ConfigParser()

	for section, kv in config_dict.items():
		cfg[section] = {}
		for k, v in kv.items():
			cfg[section][k] = v

	with open(path, 'w') as configfile:
		cfg.write(configfile)
'

PY_RUNNER='#!/usr/bin/env bash
source "${PROJECT_ROOT}/venv/bin/activate"
python "$@"
deactivate
'

RUN_FILE='#!/usr/bin/env bash
PROJECT_ROOT=$(dirname "$(readlink -f "$0")")
echo "Using project root at: $PROJECT_ROOT"
PROJECT_ROOT=${PROJECT_ROOT} ${PROJECT_ROOT}/bin/run_python.sh "$@"
'

GITIGNORE='# Python Files
__pycache__/
*.py[cod]
*$py.class

# Enviroment
venv/

# IDE Settings
.idea/

# Application Config
app.conf

# Sphinx documentation
docs/_build/

# IPython
profile_default/
ipython_config.py
'

REQUIREMENTS='# basic
pip
setuptools
wheel

# advanced
logbook

# cutom requirements
'

main
