// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

metadata description = 'Updates app settings for an Azure App Service app.'

@description('Name of the App Service app in the current resource group.')
param name string

@secure()
@description('App settings to apply to the App Service app.')
param appSettings object

resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: name
}

resource settings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: appService
  properties: appSettings
}
