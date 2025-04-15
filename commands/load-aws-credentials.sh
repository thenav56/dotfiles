#!/bin/bash -e

# Use it with
# source load-aws-credentials.sh "Work/<ref-id>"

VAULT_REF=$1

export AWS_ACCESS_KEY_ID=$(op read "op://$VAULT_REF/access key id")
export AWS_SECRET_ACCESS_KEY=$(op read "op://$VAULT_REF/secret access key")

aws sts get-caller-identity
