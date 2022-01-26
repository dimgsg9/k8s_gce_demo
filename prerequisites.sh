#!/usr/bin/env bash

# Author: Dmitry G
# NO WORRANTY. USE THIS SCRIPT AT YOUR OWN RISK

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
YELLOW='\033[1;33m'

# Prefix for output messages
MSG_ERROR=${RED}[ERROR]${NC}
MSG_OK=${GREEN}[OK]${NC}

# Define a friendly name for current OS. Will be use it to general google help link. Example https://www.google.com/search?q=Installing+cfssl+on+linux
case $OSTYPE in
  "linux-gnu")
    os_name="Linux"
    ;;
  "darwin"*)
    os_name="OSX"
    ;;
  "cygwin")
    os_name="Cygwin"
    echo "Detected using cygwin. That's going to be fun."
    ;;
  "freebsd"*)
    os_name="FreeBSD"
    echo "That's hardcore mate. I'm not sure it will work in FreeBSD."
    exit 126
esac

if [[ -z $1 ]]; then
  echo -e "${MSG_ERROR} Please specify your GCP Project ID as first parameter."
  exit 0
fi

GCP_PROJECT_ID=$1

function gce_api_setup() {
  # Login to G Cloud
  gcloud auth login

  if [[ $? -eq 0 ]]; then
    # Authenticate to call GCE management API
    gcloud auth application-default login
    if [[ $? -eq 0 ]]; then
      # Enable GCE instance group manager API
      gcloud config set project $GCP_PROJECT_ID
      gcloud services enable replicapool.googleapis.com
      if [[ $? -eq 0 ]]; then
        echo -e "\n\n===================== ${GREEN}All set. You're good to go! ${NC}=====================\n\n"
      else
        exit $?
      fi
    else
      echo -e "${MSG_ERROR} Something went wrong whilte trying to authenticate to GCE API."
      exit $?
    fi
  else
    echo -e "${MSG_ERROR} Something went wrong while trying to authenticate you in Google Cloud Platform."
    exit $?
  fi
}

# Check if bash is >= 4.x. There are known issues running kubernetes script in older versions of bash.
bash_major_version=$(echo $BASH_VERSION | awk -F "." '{print $1}')

if [[ bash_major_version -lt 4 ]]; then
  echo -e "${MSG_ERROR} Your bash is too old. You need at least bash v4.x to run this installation."
  echo "Your bash version is ${BASH_VERSION}."
  echo ">> Try to search Google for the instructions to upgrade your bash: https://www.google.com/search?q=Upgrading+bash+to+latest+version+on+${os_name}"
else
  echo -e "${MSG_OK} Bash version."
fi

# Check if cfssl is installed and PATH is set.
cfssl_path=$(which cfssl)

if [[ -z $cfssl_path ]]; then
  echo -e "${MSG_ERROR} The required golang-cfssl library is not present or PATH is not configured on your machine."
  echo ">> Try to search Google for the instructions how to setup cfssl: https://www.google.com/search?q=Installing+cfssl+in+${os_name}"
else
  echo -e "${MSG_OK} CFSSL library."
fi

# Check if python 2 is installed and version. Min required is 2.7 for G Cloud SDK CLI to work.
python_path=$(which python)

if [[ -z $python_path ]]; then
  echo -e "${MSG_ERROR} Python 2 is not present or PATH is not configured on your machine."
else
  python_version=$(python --version 2>&1)
  python_minor_version=$(echo $python_version | awk '{print $2}' | awk -F "." '{print $2}')
  if [[ $python_minor_version -lt 7 ]]; then
    echo -e "${MSG_ERROR} Python version 2.7.x required to proceed with installation."
  else
    echo -e "${MSG_OK} Python v2.7"
  fi
fi

# Check if gcloud CLI is installed.
gcloud_cli_path=$(which gcloud)

if [[ -z $gcloud_cli_path ]]; then
  echo -e "${MSG_ERROR} Google Cloud SDK & CLI is not installed or PATH not configured."
  echo ">> Please see the following page for the instructions: https://cloud.google.com/sdk/docs/quickstarts"
else 
  echo -e "${MSG_OK} Google Cloud SDK & CLI."
  # Check if gcloud alpha and beta components are installed
  gcloud_alpha="$(gcloud components list | grep "Not Installed" | grep alpha | awk -F "|" '{print$4}' | awk '{print$1}')"
  gcloud_beta="$(gcloud components list | grep "Not Installed" | grep beta | awk -F "|" '{print$4}' | awk '{print$1}')"

  if [[ $gcloud_alpha == "alpha" ]]; then
    echo -e "${MSG_ERROR} Google Cloud SDK Alpha component is required."
    echo -e ">> Please install it with the following command: ${YELLOW}gcloud components install ${gcloud_alpha}"
  else
    echo -e "${MSG_OK} Google Cloud SDK Alpha component."
  fi
  if [[ $gcloud_beta == "beta" ]]; then
    echo -e "${MSG_ERROR} Google Cloud SDK Beta component is required."
    echo -e ">> Please install it with the following command: ${YELLOW}gcloud components install ${gcloud_beta}"
  else
    echo -e "${MSG_OK} Google Cloud SDK Beta component."
  fi
  
  if [[ $gcloud_alpha != "alpha" ]] && [[ $gcloud_beta != "beta" ]]; then
    gce_api_setup
    if [[ $? -eq 0 ]]; then
      echo "Would you like to proceed further and download Kubernetes setup tools? [Y]/n"
      read -r confirm
      if [[ "${confirm}" =~ ^[nN]$ ]]; then
        echo "Aborting."
        exit 0
      fi
      KUBERNETES_RELEASE="v1.17.5" KUBERNETES_SKIP_CONFIRM=true KUBERNETES_SKIP_CREATE_CLUSTER=true ./getk8s.sh
    else
      echo -e "${MSG_ERROR} An error occured while preparing your GCP Project for Kubernetes installation."
    fi
  fi
fi
