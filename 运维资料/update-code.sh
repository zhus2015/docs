#!/bin/bash
DIR="$( cd "$( dirname "$0"  )" && pwd  )"
cd $DIR
git pull && source /usr/local/py3/bin/activate && mkdocs build
