
# Add SP Secret To Key Vault
if ( $null -ne $spSecureSecret ) {
    Set-AzKeyVaultSecret -VaultName $kvName -Name $spId -SecretValue $spSecureSecret
}


# Give Rotation App Permissions to Service Principal
$spOwners = Get-AzureADServicePrincipalOwner -ObjectId $spId
if ( $rotFuncId -notin $spOwners.ObjectId ) {
    Add-AzureADServicePrincipalOwner -ObjectId $spId -RefObjectId $rotFuncId
}
