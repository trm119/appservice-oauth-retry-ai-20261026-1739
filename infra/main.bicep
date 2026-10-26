// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name used to generate resource names.')
param name string

@minLength(1)
@description('Primary location for the deployment.')
param location string

@description('Object ID of the user who runs the deployment.')
param principalId string = ''

@description('Assign the current user access to a newly created or reused Azure OpenAI resource.')
param createRoleForUser bool = true

param appServiceName string = ''
param appServicePlanName string = ''
param appServicePlanSkuName string = 'B1'

param openAiResourceName string = ''
param openAiResourceGroupName string = ''

@minLength(1)
@description('Location for a new Azure OpenAI resource.')
param openAiResourceLocation string

param openAiSkuName string = ''
param disableKeyBasedAuth bool = true
param openAiDeploymentName string
param openAiModelName string
param openAiModelVersion string
param openAiDeploymentCapacity int
param openAiDeploymentSkuName string

@description('Create an Azure OpenAI resource. Set false to reuse an existing resource.')
param createAzureOpenAi bool

@description('Endpoint of an existing Azure OpenAI resource.')
param openAiEndpoint string = ''

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var tags = {
  'azd-env-name': name
}
var prefix = '${name}-${resourceToken}'
var effectiveOpenAiResourceGroupName = !empty(openAiResourceGroupName) ? openAiResourceGroupName : rg.name
var effectiveOpenAiResourceName = createAzureOpenAi ? openAi!.outputs.name : openAiResourceName
var effectiveOpenAiEndpoint = createAzureOpenAi ? openAi!.outputs.endpoint : openAiEndpoint

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${name}-rg'
  location: location
  tags: tags
}

module openAi 'core/ai/cognitiveservices.bicep' = if (createAzureOpenAi) {
  name: 'openai'
  scope: rg
  params: {
    name: !empty(openAiResourceName) ? openAiResourceName : '${resourceToken}-cog'
    location: !empty(openAiResourceLocation) ? openAiResourceLocation : location
    tags: tags
    disableLocalAuth: disableKeyBasedAuth
    sku: {
      name: !empty(openAiSkuName) ? openAiSkuName : 'S0'
    }
    deployments: [
      {
        name: openAiDeploymentName
        model: {
          format: 'OpenAI'
          name: openAiModelName
          version: openAiModelVersion
        }
        sku: {
          name: openAiDeploymentSkuName
          capacity: openAiDeploymentCapacity
        }
      }
    ]
  }
}

module appServicePlan 'core/host/appserviceplan.bicep' = {
  name: 'app-service-plan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${take(prefix, 35)}-plan'
    location: location
    tags: tags
    sku: {
      name: appServicePlanSkuName
    }
  }
}

module web 'core/host/appservice.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: !empty(appServiceName) ? appServiceName : '${take(prefix, 54)}-web'
    location: location
    appServicePlanId: appServicePlan.outputs.id
    tags: union(tags, {
      'azd-service-name': 'web'
    })
    appSettings: {
      AZURE_OPENAI_ENDPOINT: effectiveOpenAiEndpoint
      AZURE_OPENAI_CHAT_DEPLOYMENT: openAiDeploymentName
      RUNNING_IN_PRODUCTION: 'true'
    }
  }
}

module openAiRoleBackend 'core/security/role.bicep' = {
  name: 'openai-role-backend'
  scope: resourceGroup(effectiveOpenAiResourceGroupName)
  params: {
    accountName: effectiveOpenAiResourceName
    principalId: web.outputs.identityPrincipalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'ServicePrincipal'
  }
}

module openAiRoleUser 'core/security/role.bicep' = if (createRoleForUser && !empty(principalId)) {
  name: 'openai-role-user'
  scope: resourceGroup(effectiveOpenAiResourceGroupName)
  params: {
    accountName: effectiveOpenAiResourceName
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'User'
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_OPENAI_RESOURCE_GROUP string = effectiveOpenAiResourceGroupName
output AZURE_OPENAI_RESOURCE_NAME string = effectiveOpenAiResourceName
output AZURE_OPENAI_CHAT_DEPLOYMENT string = openAiDeploymentName
output AZURE_OPENAI_ENDPOINT string = effectiveOpenAiEndpoint
output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = web.outputs.identityPrincipalId
output SERVICE_WEB_NAME string = web.outputs.name
output SERVICE_WEB_URI string = web.outputs.uri
