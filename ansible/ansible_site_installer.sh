#! /bin/bash
# Author: Andres Kepler <andres@kepler.ee>
# Date: 11.12.2021
# Description: Ansible remote wrapper/helper script for terraform to prepare tallinn.emon.ee site.
# Set up constants
SCRIPT_PATH=$(realpath $(dirname "$0"))
REPO_URL="https://github.com/emon-tallinn/ws"
DATA=/srv/data
IAC_HOME=$DATA/ws
IAC_FILES=$IAC_HOME/iac
VENV=$IAC_HOME/venv
ADMIN_USER=${admin_user}
ADMIN_SSH_PUBLIC_KEY="${ssh_public_key}"
IAC_UPDATE=$1

if [[ $ADMIN_USER ]]; then

  id $ADMIN_USER > /dev/null
  if [ $? -gt 0 ]; then
    groupadd "$ADMIN_USER"
    useradd -c "EMON Admin User" -g "$ADMIN_USER" "$ADMIN_USER"
  fi

  if [ ! -f /etc/sudoers.d/"$ADMIN_USER" ]; then
    cat > /etc/sudoers.d/"$ADMIN_USER" << EOF
$ADMIN_USER     ALL=(ALL) NOPASSWD:ALL
EOF
  chmod 600 /etc/sudoers.d/"$ADMIN_USER"
  fi

  ADMIN_USER_HOME=/home/$ADMIN_USER
  if [ ! -d "$ADMIN_USER_HOME"/.ssh ]; then
    mkdir -p "$ADMIN_USER_HOME"/.ssh && \
    echo "$ADMIN_SSH_PUBLIC_KEY" > "$ADMIN_USER_HOME"/.ssh/authorized_keys && \
    chmod 600 "$ADMIN_USER_HOME"/.ssh/authorized_keys && \
    chown "$ADMIN_USER":"$ADMIN_USER" -R "$ADMIN_USER_HOME"/.ssh && \
    chown "$ADMIN_USER":"$ADMIN_USER" -R "$ADMIN_USER_HOME" && \
    chmod 750 "$ADMIN_USER_HOME"/.ssh
  fi

  # Create data dir if not exist
  if [ ! -d $DATA ]; then
    mkdir -p $DATA
  fi

  chown -R "$ADMIN_USER":root $DATA

fi


# A better class of script...
set -o errexit  # Exit on most errors (see the manual)
set -o errtrace # Make sure any error trap is inherited
set -o nounset  # Disallow expansion of unset variables
set -o pipefail # Use last non-zero exit code in a pipeline


# Install system dependencies
sudo apt update
sudo apt install -y git python3 python3.8-venv python3-venv python3-wheel virtualenv sudo


# Install virtual env
if [ ! -d $VENV ]; then
  python3 -m venv $VENV
  chown -R "$ADMIN_USER":root $DATA
fi

# Activate virtual env
if [ -f $VENV/bin/activate ]; then
  source $VENV/bin/activate
else
  echo "Unable to find virtual env activate file"
  exit 200
fi

if [[ $IAC_UPDATE == true ]]; then
  # Clone IAAC repository
  if [ ! -d $IAC_FILES ]; then
    git clone $REPO_URL $IAC_FILES
    chmod 700 $IAC_FILES
  else
    cd $IAC_FILES
    git stash
    git pull
  fi
fi

if [ -f $IAC_FILES/ansible/requirements.txt ]; then
  $VENV/bin/pip install -r "$IAC_FILES"/ansible/requirements.txt
else
  echo "Unable to locate "$IAC_FILES"/ansible/requirements.txt file"
  exit 200
fi

# Run ansible code
cd "$IAC_FILES"/ansible
ANSIBLE_CONFIG=$IAC_FILES/ansible/ansible.cfg ansible-playbook --inventory $IAC_FILES/ansible/inventories/hosts site.yaml