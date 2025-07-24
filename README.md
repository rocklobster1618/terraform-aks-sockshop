# terraform-aks-sockshop


###########################################
# PRE-REQUISITES
###########################################

# Authenticate to Azure
az login

# Register Azure Resource Providers for Subscription (Powershell)
$Providers = @(
    'Microsoft.ApiManagement',
    'Microsoft.AVS',
    'Microsoft.DBforPostgreSQL',
    'Microsoft.Compute',
    'Microsoft.Network',
    'Microsoft.Accounts'
)
$Providers | Foreach-Object {
    az provider register --namespace $_
}

# Register Azure Resource Providers for Subscription (Bash)
providers=(
    Microsoft.ApiManagement
    Microsoft.AVS
    Microsoft.DBforPostgreSQL
    Microsoft.Compute
    Microsoft.Network
    Microsoft.Account
)
for provider in "${providers[@]}"; do
  echo "Registering $provider..."
  az provider register --namespace "$provider"
done