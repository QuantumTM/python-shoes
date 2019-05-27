#!/usr/bin/env bash

function make_folders() {
	mkdir "bin"
	mkdir "common"
	mkdir "scripts"
	mkdir "deploy"
}

function make_files() {
	touch "bin/run_python.sh"
	touch "bin/make_config.sh"
	touch ".gitignore"
	touch "run"
	touch "requirements.txt"
	touch "main.py"
	touch "common/logging.py"
	touch "config.py"
	touch "scripts/make_config.py"
	touch "deploy/config_enviroment.py"
}

function inject_files() {
	echo "${PY_RUNNER}" > "bin/run_python.sh"
	echo "${MAKE_CONFIG}" > "bin/make_config.sh"
	echo "${ENV_CONFIG}" > "deploy/config_enviroment.py"
	echo "${GITIGNORE}" > ".gitignore"
	echo "${RUN_FILE}" > "run"
	echo "${REQUIREMENTS}" > "requirements.txt"
	echo "${MAINPY}" > "main.py"
	echo "${LOGGINGPY}" > "common/logging.py"
	echo "${CONFIGPY}" > "config.py"
	echo "${MAKE_CONFIGPY}" > "scripts/make_config.py"
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
	chmod 755 bin/*
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

MAINPY='import click
from common import logging

log = logging.get_logger("main")

@click.group(help="This is an app")
def app():
	log.info("Bootstrap successfully!")

@app.command(help="successive entries as a list")
@click.argument("messages", nargs=-1)
def print(messages):
	log.info(",".join(("{}",)*len(messages)), *messages)

@app.command(help="first and last names")
@click.option("--first", "-f", required=True)
@click.option("--second", "-s", default="_blank_")
@click.option("--caps", is_flag=True)
def name(first, second, caps):
	log.info(
		"{} {}",
		first.capitalize() if caps else first,
		second.capitalize() if caps else second
	)

@app.command(help="click context infomation")
@click.pass_context
def show_context(ctx):
	log.info(
		"info_name: {}, params: {}, parent.info_name: {}",
		ctx.info_name,
		ctx.command.params,
		ctx.parent.info_name,
	)

if __name__ == "__main__":
	with logging.init("app").applicationbound():
		app()
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

from deploy.config_enviroment import CONFIG_NAME

def create(config_dict):
	path = os.path.join(os.path.dirname(os.path.abspath(__file__)), CONFIG_NAME)
	print("Creating config: {}".format(path))
	cfg = ConfigParser()

	for section, kv in config_dict.items():
		cfg[section] = {}
		for k, v in kv.items():
			cfg[section][k] = v

	with open(path, "w") as configfile:
		cfg.write(configfile)

def load():
	cfg = ConfigParser()
	path = os.path.join(os.path.dirname(os.path.abspath(__file__)), CONFIG_NAME)
	with open(path) as f:
		cfg.read_file(f)
	cfg.config_path = path
	print("Found config file {}".format(path))
	return cfg
'

MAKE_CONFIGPY='import click

import config
from deploy.config_enviroment import CONFIG, CONFIG_NAME
from common import logging

log = logging.get_logger("script")

@click.command(help="Setup application config")
def build_config(env):
	config.create(CONFIG["env"])

if __name__ == "__main__":
	with logging.init("script").applicationbound():
		build_config()
'

ENV_CONFIG='CONFIG = {
	"local": {
		"app": [
			("env", "local"),
		],
	},
	"dev": {
		"app": [
			("env", "dev"),
		],
	},
	"prod": {
		"app": [
			("env", "prod"),
		],
	},
}

CONFIG_NAME = "app.conf"
'

PY_RUNNER='#!/usr/bin/env bash
source "${PROJECT_ROOT}/venv/bin/activate"
PYTHONPATH="${PROJECT_ROOT}" python "$@"
deactivate
'

MAKE_CONFIG='#!/usr/bin/env bash
# TODO: not sure this is the correct approach
# resolve to dir above `bin`
PROJECT_ROOT=$(readlink -f "$(dirname "$(readlink -f "$0")")/../")
${PROJECT_ROOT}/run ${PROJECT_ROOT}/scripts/make_config.py "$@"
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
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

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
click>=7.0

# cutom requirements
'

main
