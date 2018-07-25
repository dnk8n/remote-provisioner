#!/usr/bin/env sh
set -x -euf

: "${PROJECT_ROOT:=$(pwd)}"
: "${TERRAFORM_DIR:=terraform}"
: "${TERRAFORM_OPTIONS:=}"

cd ${PROJECT_ROOT}/${TERRAFORM_DIR}
terraform init
terraform apply -auto-approve=true ${TERRAFORM_OPTIONS} || JOB_STATUS=$?
terraform destroy -auto-approve=true ${TERRAFORM_OPTIONS}
exit ${JOB_STATUS:-0}
