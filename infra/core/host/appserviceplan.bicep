// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

metadata description = 'Creates a Linux Azure App Service plan.'

param name string
param location string = resourceGroup().location
param tags object = {}
param sku object = {
  name: 'B1'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  tags: tags
  sku: sku
  properties: {
    reserved: true
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
