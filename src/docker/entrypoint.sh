#!/usr/bin/env ash
set -x -euf -o pipefail

: "${PROJECT_ROOT:=/tmp/project-root}"
: "${TERRAFORM_OPTIONS:=}"

cd ${PROJECT_ROOT}/terraform

terraform init
terraform apply -auto-approve=true ${TERRAFORM_OPTIONS} || JOB_STATUS=$?
terraform destroy -auto-approve=true ${TERRAFORM_OPTIONS}
exit ${JOB_STATUS:-0}
