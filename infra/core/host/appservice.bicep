// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

metadata description = 'Creates a Linux Azure App Service app in an existing App Service plan.'

param name string
param location string = resourceGroup().location
param tags object = {}
param appServicePlanId string
param linuxFxVersion string = 'PYTHON|3.12'
param appCommandLine string = 'gunicorn --config gunicorn.conf.py app:app'

@secure()
param appSettings object = {}

resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      appCommandLine: appCommandLine
      healthCheckPath: '/'
    }
  }

  resource ftpPolicy 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }

  resource scmPolicy 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }
}

module configAppSettings 'appservice-appsettings.bicep' = {
  name: '${name}-app-settings'
  params: {
    name: appService.name
    appSettings: union(appSettings, {
      SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
      ENABLE_ORYX_BUILD: 'true'
    })
  }
}

resource configLogs 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'logs'
  parent: appService
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    detailedErrorMessages: {
      enabled: false
    }
    failedRequestsTracing: {
      enabled: true
    }
    httpLogs: {
      fileSystem: {
        enabled: true
        retentionInDays: 1
        retentionInMb: 35
      }
    }
  }
  dependsOn: [
    configAppSettings
  ]
}

output identityPrincipalId string = appService.identity.principalId
output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
