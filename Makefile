# Licensed to Big Data Genomics (BDG) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The BDG licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

define help

Supported targets: 'prepare', 'develop', 'sdist', 'clean', 'test', or 'pypi'.

The 'prepare' target installs toil-lib's build requirements into the current virtualenv.

The 'develop' target creates an editable install (aka develop mode).

	make develop

The 'clean' target undoes the effect of 'develop', 'docs', and 'sdist'.

The 'test' target runs Toil-script's unit tests.

The 'pypi' target publishes the current commit of Toil to PyPI after enforcing that the working
copy and the index are clean, and tagging it as an unstable .dev build.

endef
export help
help:
	@echo "$$help"


python=python
pip=pip
tests=src
extras=

green=\033[0;32m
normal=\033[0m
red=\033[0;31m

prepare: check_venv
	$(pip) install pytest==2.8.3 toil[aws]==3.7.0a1.dev392
clean_prepare: check_venv
	- $(pip) uninstall -y pytest toil


develop: check_venv
	$(pip) install -e .$(extras)
clean_develop: check_venv
	- rm -rf src/*.egg-info
	- rm -f bdgenomics/workflows/version.py


sdist: check_venv
	$(python) setup.py sdist
clean_sdist:
	- rm -rf dist


test: check_venv
	$(python) setup.py test --pytest-args "-vv $(tests) --junitxml=test-report.xml"


pypi: check_venv check_clean_working_copy
	$(python) setup.py egg_info sdist bdist_egg upload
clean_pypi:
	- rm -rf build/


clean: clean_develop clean_sdist clean_pypi


check_venv:
	@$(python) -c 'import sys; sys.exit( int( not hasattr(sys, "real_prefix") ) )' \
		|| ( echo "$(red)A virtualenv must be active.$(normal)" ; true )


check_clean_working_copy:
	@echo "$(green)Checking if your working copy is clean ...$(normal)"
	@git diff --exit-code > /dev/null \
		|| ( echo "$(red)Your working copy looks dirty.$(normal)" ; false )
	@git diff --cached --exit-code > /dev/null \
		|| ( echo "$(red)Your index looks dirty.$(normal)" ; false )
	@test -z "$$(git ls-files --other --exclude-standard --directory)" \
		|| ( echo "$(red)You have are untracked files:$(normal)" \
			; git ls-files --other --exclude-standard --directory \
			; false )


check_running_on_jenkins:
	@echo "$(green)Checking if running on Jenkins ...$(normal)"
	@test -n "$$BUILD_NUMBER" \
		|| ( echo "$(red)This target should only be invoked on Jenkins.$(normal)" ; false )


.PHONY: help develop clean_develop sdist clean_sdist test \
		pypi pypi_stable clean_pypi docs clean_docs clean \
		check_venv check_clean_working_copy check_running_on_jenkins
