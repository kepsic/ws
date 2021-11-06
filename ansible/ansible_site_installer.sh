#! /bin/bash
# Author: Andres Kepler <andres@kepler.ee>
# Date: 07.11.2021
# Description: Ansible remote wrapper/helper script for terraform to prepare tallinn.emon.ee site.

REALPATH=$(which realpath)
if [ -z $REALPATH ]; then
  realpath() {
    [[ $1 == /* ]] && echo "$1" || echo "$PWD/${1#./}"
  }
fi
# Set up constants
SCRIPT_PATH=$(realpath $(dirname "$0"))
REPO_URL="https://github.com/emon-tallinn/ws"
DATA=/srv/data
IAAC_HOME=$DATA/ws
IAAC_FILES=$IAAC_HOME/iaac
VENV=$IAAC_HOME/venv
ADMIN_USER=az-user


# A better class of script...
set -o errexit  # Exit on most errors (see the manual)
set -o errtrace # Make sure any error trap is inherited
set -o nounset  # Disallow expansion of unset variables
set -o pipefail # Use last non-zero exit code in a pipeline

# Create data dir if not exist
if [ ! -d $DATA ]; then
  mkdir -p $DATA
fi
# Install system dependencies
sudo apt update
sudo apt install -y git python3 python3.8-venv python3-venv virtualenv


# Install virtual env
if [ ! -d ${VENV} ]; then
  python3 -m venv ${VENV}
fi

# Activate virtual env
if [ -f ${VENV}/bin/activate ]; then
  source ${VENV}/bin/activate
else
  echo "Unable to find virtual env activate file"
  exit 200
fi

# Clone IAAC repository
if [ ! -d ${IAAC_FILES} ]; then
  git clone $REPO_URL ${IAAC_FILES}
  chmod 700 ${IAAC_FILES}
  chown -R $ADMIN_USER:root ${IAAC_HOME}
  if [ -f ${IAAC_FILES}/ansible/requirements.txt ]; then
    ${VENV}/bin/pip install -r ${IAAC_FILES}/ansible/requirements.txt
  else
    echo "Unable to locate ${IAAC_FILES}/ansible/requirements.txt file"
    exit 200
  fi
else
  cd ${IAAC_FILES}
  git stash
  git pull
fi

# Run ansible code
cd ${IAAC_FILES}/ansible
ANSIBLE_CONFIG=${IAAC_FILES}/ansible/ansible.cfg ansible-playbook --inventory ${IAAC_FILES}/ansible/inventories/hosts site.yaml