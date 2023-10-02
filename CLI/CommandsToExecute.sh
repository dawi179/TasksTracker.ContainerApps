RESOURCE_GROUP="tst-aca-workshop-rg"
LOCATION="westeurope"
ENVIRONMENT="tst-aca-workshop-cae"
WORKSPACE_NAME="tst-aca-workshop-log"
APPINSIGHTS_NAME="tst-aca-workshop-ai"
BACKEND_API_NAME="tasksmanager-backend-api"
ACR_NAME="tstacaworkshopacr"
VNET_NAME="tst-aca-workshop-vnet"
VNET_ADDRESS_SPACE="10.20.0.0/16"
SNET_NAME="infra-subnet"
SNET_ADDRESS_SPACE="10.20.0.0/24"

# Resource Group
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Container Registry
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true

# Log Analytics Workspace
# create the log analytics workspace
az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $WORKSPACE_NAME

# retrieve workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show --query customerId \
    -g $RESOURCE_GROUP \
    -n $WORKSPACE_NAME -o tsv)

# retrieve workspace secret
WORKSPACE_SECRET=$(az monitor log-analytics workspace get-shared-keys --query primarySharedKey \
    -g $RESOURCE_GROUP \
    -n $WORKSPACE_NAME -o tsv)

# Application Insights
# Create application-insights instance

az monitor app-insights component create \
    -g $RESOURCE_GROUP \
    -l $LOCATION \
    --app $APPINSIGHTS_NAME \
    --workspace $WORKSPACE_NAME

# Get Application Insights Instrumentation Key
APPINSIGHTS_INSTRUMENTATIONKEY=$(az monitor app-insights component show \
    --app $APPINSIGHTS_NAME \
    -g $RESOURCE_GROUP --query instrumentationKey -o tsv)

# Virtual Network and subnet
# Create vnet
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --location $LOCATION \
  --address-prefix $VNET_ADDRESS_SPACE

# Create subnet
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $SNET_NAME \
  --address-prefixes $SNET_ADDRESS_SPACE \
  --delegations 'Microsoft.App/environments'

# Retrieve subnet ID
INFRASTRUCTURE_SUBNET=`az network vnet subnet show \
    --resource-group ${RESOURCE_GROUP} \
    --vnet-name $VNET_NAME \
    --name $SNET_NAME \
    --query "id" -o tsv | tr -d '[:space:]'`

# Azure Container Apps Environment
az containerapp env create \
    --name $ENVIRONMENT \
    --resource-group $RESOURCE_GROUP \
    --logs-workspace-id $WORKSPACE_ID \
    --logs-workspace-key $WORKSPACE_SECRET \
    --dapr-instrumentation-key $APPINSIGHTS_INSTRUMENTATIONKEY \
    --enable-workload-profiles true \
    --infrastructure-subnet-resource-id $INFRASTRUCTURE_SUBNET \
    --location $LOCATION


# Build the container image and push to ACR
cd ~\TasksTracker.ContainerApps
az acr build --registry $ACR_NAME --image "tasksmanager/$BACKEND_API_NAME" --file 'TasksTracker.TasksManager.Backend.Api/Dockerfile' .


# Deploy the WEB API container
az containerapp create \
--name $BACKEND_API_NAME  \
--resource-group $RESOURCE_GROUP \
--environment $ENVIRONMENT \
--image "$ACR_NAME.azurecr.io/tasksmanager/$BACKEND_API_NAME" \
--registry-server "$ACR_NAME.azurecr.io" \
--target-port 5062 \
--ingress 'external' \
--min-replicas 1 \
--max-replicas 1 \
--cpu 0.25 --memory 0.5Gi \
--query configuration.ingress.fqdn
