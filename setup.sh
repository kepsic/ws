#!/usr/bin/env bash

REALPATH=$(which realpath)
if [ -z $REALPATH ]; then
  realpath() {
    [[ $1 == /* ]] && echo "$1" || echo "$PWD/${1#./}"
  }
fi
# Set up constants
SCRIPT_PATH=$(realpath $(dirname "$0"))
TERRAFORM=$(which terraform)
AZ=$(which az)
JQ=$(which jq)

# Load .env file source is exist
if [ -f ./.env ]; then
  source ./.env
else
  echo ".env file is missing. Cant continue"
  echo "To bootstrap make copy from .env_example"
  exit 200
fi

# Hardcoded variable
TERRAFORM_VERSION=0.14
TF_PROVIDER=${TF_PROVIDER:-az}
AZ_IMAGE_OFFER=${AZ_IMAGE_OFFER:-"0001-com-ubuntu-server-focal"}
AZ_IMAGE_SKU=${AZ_IMAGE_SKU:-"20_04-lts"}
AZ_IMAGE_PUBLISHER=${AZ_IMAGE_PUBLISHER:-"Canonical"}
AZ_LOCATION=${AZ_LOCATION:-"northeurope"}
AZ_VM_NAME=${AZ_VM_NAME:-"monitoring"}
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-not-set}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-not-set}
AWS_DEFAULT_REGION=${AWS_REGION:-eu-west-3}
EMON_ADMIN_USER=${EMON_ADMIN_USER:-emon-user}
AZ_IMAGE_VERSION=${AZ_IMAGE_VERSION:-"20.04.202110260"}
TERRAFORM_CURRENT_VERSION=$(${TERRAFORM} version)
TERRAFORM_VERSION_CHECK=$(echo ${TERRAFORM_CURRENT_VERSION}|grep ${TERRAFORM_VERSION})
SITE_DOMAIN="tallinn.emon.ee"
SITE_PATH="ansible/roles/emon/files/emon"
SITE_ENV_FILE=$SITE_PATH/.env
IAC_HOME=/srv/data/ws/iac
IAC=$(echo $SCRIPT_PATH|sed -e's/\/\.//')
SITE_INSTALLER_FILE=$SCRIPT_PATH/ansible/ansible_site_installer.sh

# Load env variables
export LOOKUP_AZ_IMAGE=${LOOKUP_AZ_IMAGE:-false}
export SCRIPT_COMMIT=${SCRIPT_COMMIT:-false}
export SCRIPT_INIT=${SCRIPT_INIT:-false}
export SCRIPT_PLAN=${SCRIPT_PLAN:-false}
export SCRIPT_DESTROY=${SCRIPT_DESTROY:-false}
export SCRIPT_VERBOSE=${SCRIPT_VERBOSE:-false}
export TF_VAR_az_location=$AZ_LOCATION
export TF_VAR_image_offer=$AZ_IMAGE_OFFER
export TF_VAR_image_sku=$AZ_IMAGE_SKU
export TF_VAR_image_version=$AZ_IMAGE_VERSION
export TF_VAR_image_publisher=$AZ_IMAGE_PUBLISHER
export TF_VAR_admin_user=$EMON_ADMIN_USER
export TF_VAR_site_installer_file=$SITE_INSTALLER_FILE
export TF_VAR_aws_access_key=$AWS_ACCESS_KEY_ID
export TF_VAR_aws_secret_key=$AWS_SECRET_ACCESS_KEY
export TR_VAR_aws_region=$AWS_DEFAULT_REGION

echo $TF_VAR_aws_access_key $TF_VAR_aws_secret_key $TR_VAR_aws_region

# Enable xtrace if the DEBUG environment variable is set
if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
  set -o xtrace # Trace the execution of the script (debug)
fi

# A better class of script...
set -o errexit  # Exit on most errors (see the manual)
set -o errtrace # Make sure any error trap is inherited
set -o nounset  # Disallow expansion of unset variables
set -o pipefail # Use last non-zero exit code in a pipeline

# DESC: Validates required parameters
# ARGS: null
# OUTS: null
function validate_requiments() {
  # Sanity checks
  if [ -z "$TERRAFORM" ]; then
    echo "Missing terraform binary; I'm sorry, we cant continue!"
    exit 200
  fi

#  if [ -z "$TERRAFORM_VERSION_CHECK"  ] || [[ $TF_PROVIDER == aws ]]; then
#    echo "I'm sorry! This code is intended to use with $TERRAFORM_VERSION"
#    echo $TERRAFORM_CURRENT_VERSION
#    exit 201
#  fi

  if [ -z "$AZ" ] && [ "$TF_PROVIDER" == "az" ]; then
    echo "Missing Azure CLI binary; I'm sorry, we cant continue!"
    exit 202
  fi

  if  [ "$TF_PROVIDER" == "az" ]; then
    # Try to login if not
    az account show > /dev/null
    if [ $? -eq 1  ]; then
        az login
    fi
  fi

  if [ -z "$JQ" ]; then
    echo "Missing jq binary; I'm sorry, we cant continue!"
    exit 203
  fi
}

# DESC: Prints out verbose message if verbose is set
# ARGS: Message
# OUTS: null
function verbose_msg() {
    local message=$1
    if [ "${SCRIPT_VERBOSE}" == "true" ]; then
      echo $message
    fi
}

# DESC: Lookup latest VM offer, sku, publisher and version
# ARGS: null
# OUTS: null
function lookup_az_latest_vm_image() {
  verbose_msg "Identifying latest vm image from $AZ_LOCATION"
  # ref. https://discourse.ubuntu.com/t/find-ubuntu-images-on-microsoft-azure/18918
  json_data=$($AZ vm image list --all --publisher $AZ_IMAGE_PUBLISHER --location $AZ_LOCATION | jq '[.[] | select(.sku=="'${AZ_IMAGE_SKU}'")]| max_by(.version)')
  export TF_VAR_image_offer=$(echo ${json_data}|jq .offer)|tr -d "\""
  export TF_VAR_image_sku=$(echo ${json_data}|jq .sku)|tr -d "\""
  export TF_VAR_image_publisher=$(echo ${json_data}|jq .publisher)|tr -d "\""
  export TF_VAR_image_version=$(echo ${json_data}|jq .version)|tr -d "\""
  verbose_msg "offer=$TF_VAR_image_offer"
  verbose_msg "sku=$TF_VAR_image_sku"
  verbose_msg "publisher=$TF_VAR_image_publisher"
  verbose_msg "version=$TF_VAR_image_version"
}

# DESC: Usage help
# ARGS: None
# OUTS: None
function script_usage() {
  cat <<EOF
Usage:
     --init                     Init terrafrom code
     --plan                     Plan terrafrom code
     --apply                    Plan and apply terrafrom code
     --destroy                  Destroy all resources
     --aws-provider             Execute code against aws
     -h|--help                  Displays this help
     -v|--verbose               Displays verbose output
EOF
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parse_params() {
  local param
  while [[ $# -gt 0 ]]; do
    param="$1"
    shift
    case $param in
    --apply)
      export SCRIPT_COMMIT=true
      ;;
    --init)
      export SCRIPT_INIT=true
      ;;
    --plan)
      export SCRIPT_PLAN=true
      ;;
    --destroy)
      export SCRIPT_DESTROY=true
      ;;
    --lookup-az-image)
      export LOOKUP_AZ_IMAGE=true
      ;;

    --aws-provider)
      export TF_PROVIDER=aws
      ;;


    -h | --help)
      script_usage
      exit 0
      ;;
    -v | --verbose)
      export SCRIPT_VERBOSE=true
      ;;
    *)
      echo "Invalid parameter was provided: $param"
      exit 1
      ;;
    esac
  done
}

# DESC: Plan terrafrom resources
# ARGS: None
# OUTS: None
function terraform_plan() {

  # Format code
  ${TERRAFORM} fmt

  ## Initialize terraform
  ${TERRAFORM} plan

}

# DESC: Prepares setting file after completion
# ARGS: None
# OUTS: None
function prepare_settings() {

    if [ ! -d "${SETTINGS_DIR}" ]; then
      mkdir -p "${SETTINGS_DIR}"
    fi

    if [ ! -d "${RSA_DIR}" ]; then
      mkdir -p "${RSA_DIR}"
    fi

    if [ ! -f "${RSA_FILE}" ]; then
      ${TERRAFORM} output -raw tls_private_key > ${RSA_FILE}
      ${TERRAFORM} output -raw ssh_public_key > ${RSA_FILE}.pub
      chmod 600 "${RSA_FILE}"
      chmod 600 "${RSA_FILE}".pub
    fi

    if [ ! -f "${SETTINGS_FILE}" ]; then
          _dst_host=$(${TERRAFORM} output -raw public_ip)
          _ssh_connection_params="-oStrictHostKeyChecking=no -oIdentitiesOnly=yes -oUserKnownHostsFile=/dev/null -i $RSA_FILE"
          _ssh_connection_string=" ${EMON_ADMIN_USER}@$_dst_host $_ssh_connection_params"
          cat  > "${SETTINGS_DIR}"/vars.sh << SETTINGS
#!/usr/bin/env bash
export ssh="ssh ${_ssh_connection_string}"
SETTINGS
          cat  > "${SETTINGS_FILE}" << SETTINGS
#!/usr/bin/env bash
REALPATH=\$(which realpath)
if [ -z \$REALPATH ]; then
  realpath() {
    [[ \$1 == /* ]] && echo "\$1" || echo "\$PWD/\${1#./}"
  }
fi
# Set up constants
SCRIPT_PATH=\$(realpath \$(dirname "\$0"))
cd $SCRIPT_PATH

if [ -f ${SETTINGS_DIR}/vars.sh ]; then
  source ${SETTINGS_DIR}/vars.sh
else
  echo "vars.sh file is mandatory. exiting"
  exit 200
fi

if [ -f $SCRIPT_PATH/$SITE_ENV_FILE ]; then
  rsync -avz -e "ssh $_ssh_connection_params"  \
  --exclude '$IAC/venv' \
  --exclude '$IAC/terraform/$TF_PROVIDER/.terraform/*' \
  --progress \
  $IAC/* ${EMON_ADMIN_USER}@$_dst_host:$IAC_HOME
 \$ssh "cd $IAC_HOME/$SITE_PATH && echo '$IAC_HOME/ansible/ansible_site_installer.sh && yes|./init-letsencrypt.sh' > init-site.sh"
 \$ssh "cd $IAC_HOME/$SITE_PATH && sudo bash ./init-site.sh && rm -rf ./init-site.sh"
else
  echo Without $SCRIPT_PATH/$SITE_ENV_FILE file this site is depricated!
  exit 200
fi

SETTINGS
          chmod 750 "${SETTINGS_FILE}"
          ${SETTINGS_FILE}
    fi

}
# DESC: Commit terrafrom resources
# ARGS: None
# OUTS: None
function terraform_commit() {

  if  [ "${LOOKUP_AZ_IMAGE}" == "true" ]; then
    lookup_az_latest_vm_image
  fi

  terraform_plan

  sleep 15
  ## Create the resource
  ${TERRAFORM} apply -auto-approve

  sleep 10
  ${TERRAFORM} refresh

  if [ -d ${SETTINGS_DIR} ]; then
    rm -rf ${SETTINGS_DIR}
  fi

  ## View state file
  ${TERRAFORM} show



}

# DESC: Init terrafrom resources
# ARGS: None
# OUTS: None
function terraform_init() {

  verbose_msg "Init EMON Tallinn stack"
  if [[ ${TF_PROVIDER} == aws ]] && [[ ${SCRIPT_INIT} == true ]]; then

    if [ ! -d $TERRAFORM_CODE/terraform_init/S3/.terraform ] || [[ ${SCRIPT_INIT} == true ]]; then
      echo "Init S3"
      cd $TERRAFORM_CODE/terraform_init/S3
      if [ ! -d $TERRAFORM_CODE/terraform_init/S3/.terraform ]; then
        $TERRAFORM init
        sleep 5
        $TERRAFORM plan
        sleep 30
        $TERRAFORM apply -auto-approve
      fi
    fi

    if [ -d $TERRAFORM_CODE/terraform_init/DynamoDB/.terraform ] || [[ ${SCRIPT_INIT} == true ]]; then
      echo "Init DynamoDB"
      cd $TERRAFORM_CODE/terraform_init/DynamoDB
      if [ ! -d $TERRAFORM_CODE/terraform_init/DynamoDB/.terraform ]; then
        $TERRAFORM init
        sleep 5
        $TERRAFORM plan
        sleep 30
        $TERRAFORM apply -auto-approve
      fi
    fi

  fi

  ## Initialize terraform
  cd $TERRAFORM_CODE
  ${TERRAFORM} init

}

# DESC: Destroy terrafrom resources
# ARGS: None
# OUTS: None
function terraform_destroy() {

  cd $TERRAFORM_CODE
  # Format code
  ${TERRAFORM} fmt

  # Destroy the resources
  ${TERRAFORM} destroy

  if [ -f "${RSA_FILE}" ]; then
    rm -rf "${RSA_FILE}"*
  fi

  if [ -f "${SETTINGS_FILE}" ]; then
    rm -rf "${SETTINGS_FILE}"
  fi

  if [ -d "${SETTINGS_DIR}" ]; then
    rm -rf "${SETTINGS_DIR}"
  fi

}

# DESC: Main script function
# ARGS: command line params
# OUTS: None
function main() {

  parse_params "$@"

  export TERRAFORM_CODE=${SCRIPT_PATH}/terraform/${TF_PROVIDER}
  export SETTINGS_DIR=${SCRIPT_PATH}/ansible/settings.d/${TF_PROVIDER}
  export SETTINGS_FILE=${SETTINGS_DIR}/post-settings.sh
  export RSA_DIR=${SETTINGS_DIR}/ssh_keys
  export RSA_FILE=${RSA_DIR}/id_rsa_emon


  validate_requiments

  cd  "${TERRAFORM_CODE}"

  if [ ! -d "${TERRAFORM_CODE}"/.terraform ]; then
    verbose_msg "Terrafrom is not initialized!"
    terraform_init
  fi

  if [ "${SCRIPT_INIT}" == "true" ]; then
    terraform_init
    exit 0
  fi

  if [ "${SCRIPT_COMMIT}" == "true" ]; then
    cd $TERRAFORM_CODE
    terraform_commit
    # Perpare settings
    prepare_settings
    exit 0
  fi

  if [ "${SCRIPT_PLAN}" == "true" ]; then
    cd $TERRAFORM_CODE
    terraform_plan
    exit 0
  fi

  if [ "${SCRIPT_DESTROY}" == "true" ]; then
    cd $TERRAFORM_CODE
    terraform_destroy
    exit 0
  fi

}

main "$@"
