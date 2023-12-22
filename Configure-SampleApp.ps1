# Environment Variables
$rgName = "trr-secretrotationdemo-rg"
$location = "eastus2"

# Application Variables
$aspName = "trr-sampleapp-asp"
$appName = "trr-sampleapp-web"
$storageName = "trrssampleappsa"


# Add Properties to App Service
$waSettings = @{}
foreach ( $setting in $wa.SiteConfig.AppSettings ) {
    $waSettings.Add( $setting.Name, $setting.Value )
}
$waSettings.Add( "StorageAccountBlob", $storage.PrimaryEndpoints.Blob )
$waSettings.Add( "KeyVaultUri", $kv.VaultUri )
$waSettings.Add( "StorageServicePrincipalId", $spId )
Set-AzWebApp -Name $appName -ResourceGroupName $rgName -AppSettings $waSettings
$wa = Get-AzWebApp -Name $appName -ResourceGroupName $rgName




# Add Service Principal Access to Storage Account
$storageId = $storage.Id
$roleassignment = Get-AzRoleAssignment -ObjectId $spId -RoleDefinitionName "Storage Blob Data Contributor" -Scope $storageId
if ( $null -eq $roleassignment ) {
    New-AzRoleAssignment -ObjectId $spId -RoleDefinitionName "Storage Blob Data Contributor" -Scope $storageId
}



# Add Key Vault Access Policy
$waId = ( $wa | Select-Object -ExpandProperty Identity ).PrincipalId
$kv | Set-AzKeyVaultAccessPolicy -ObjectId $waId -PermissionsToSecrets get
