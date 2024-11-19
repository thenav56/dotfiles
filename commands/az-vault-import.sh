#!/bin/bash

# Ensure Azure CLI is logged in
if ! az account show > /dev/null 2>&1; then
    echo "Please login to Azure using 'az login'."
    exit 1
fi

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "yq is not installed. Please install it to continue."
    exit 1
fi

# Define the Azure Key Vault name and input YAML file
VAULT_NAME=${VAULT_NAME?error}
INPUT_FILE=${INPUT_FILE?error}

# Check if the input YAML file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Input file '$INPUT_FILE' not found!"
    exit 1
fi

if ! [[ "$UPDATE_VALUES" = "true" ]] ; then
    echo "UPDATE_VALUES is not true. So just showing what will be done"
    echo "-------------------------------------------------"
fi

# Loop through each secret in the YAML file
yq e -o=j -I=0 '.secrets[]' "$INPUT_FILE" | while IFS= read -r secret; do
    # Extract the name and value of the secret
    secret_name=$(echo "$secret" | yq eval '.name' -)
    secret_value=$(echo "$secret" | yq eval '.value' -)
    # echo "secret_name: $secret_name"
    # echo "secret_value: $secret_value"
    # continue

    if [[ -z "$secret_name" || -z "$secret_value" ]]; then
        echo "Invalid secret entry. Skipping..."
        continue
    fi

    # Upload the secret to Azure Key Vault
    echo "Uploading secret: $secret_name"
    if ! [[ "$UPDATE_VALUES" = "true" ]] ; then
        echo "az keyvault secret set --vault-name \"$VAULT_NAME\" --name \"$secret_name\" --value \"$secret_value\""
        continue
    fi

    az keyvault secret set --vault-name "$VAULT_NAME" --name "$secret_name" --value "$secret_value"

    if [[ $? -eq 0 ]]; then
        echo "Successfully uploaded secret: $secret_name"
    else
        echo "Failed to upload secret: $secret_name"
    fi
done

