@description('The name of the resource group containing the APIM service instance')
param resourceGroupName string = 'bicepDemo${uniqueString(resourceGroup().id)}'

@description('The name of the API Management service instance')
param apiManagementServiceName string = 'apiservice${uniqueString(resourceGroup().id)}'

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string = 'abishek87365@duck.com'

@description('The name of the owner of the service')
@minLength(1)
param publisherName string = 'TDWorkShop'

@description('The pricing tier of this API Management service')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Basicv2'
  'Standard'
  'Standardv2'
  'Premium'
])
param sku string = 'Developer'

@description('The instance size of this API Management service.')
@allowed([
  0
  1
  2
])
param skuCount int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

/*resource apiManagementService 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}*/

var scriptContent = '''
$apiManagement = Get-AzApiManagement -ResourceGroupName ${resourceGroupName} -Name ${apiManagementServiceName} -ErrorAction SilentlyContinue
if ($null -eq $apiManagement) {
    return @{exists = $false}
} else {
    return @{exists = $true}
}
'''

resource apiManagementCheck 'Microsoft.Resources/deploymentScripts@2021-01-01' = {
  name: 'apiManagementCheck'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    azPowerShellVersion: '3.0'
    cleanupPreference: 'OnSuccess'
    scriptContent: scriptContent
    arguments: '-resourceGroupName ${resourceGroupName} -apiManagementName ${apiManagementServiceName}'
    retentionInterval: 'P1D'
  }
}

resource apiManagement 'Microsoft.ApiManagement/service@2020-06-01-preview' = if(apiManagementCheck.outputs['exists'].value == false) {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}
