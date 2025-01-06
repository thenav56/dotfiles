#!/bin/bash -e

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


# Define the Azure Key Vault name
if [ "$1" = "" ]
then
  echo "Usage: $0 <vaultname>"
  exit
fi
VAULT_NAME=$1

# Fetch all secret names from the Azure Key Vault
echo "# Fetching secrets from Key Vault: $VAULT_NAME"

# Initialize the YAML file
echo "secrets:"

# Loop through each secret in the Key Vault
secrets=$(az keyvault secret list --vault-name "$VAULT_NAME" --query "[].id" -o tsv)

for secret_id in $secrets; do
    secret_name=$(basename "$secret_id")

    # Fetch the secret value
    secret_value=$(az keyvault secret show --vault-name "$VAULT_NAME" --name "$secret_name" --query "value" -o tsv)

    # Append secret information to the YAML file
    echo "  - name: $secret_name"
    echo "    value: \"$secret_value\""
done
