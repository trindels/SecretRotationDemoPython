# Identity Name Variables
$tenantId = "73043c5d-205c-4462-beb9-13bebde5ec9e"
$spName = "trr-secretrotationdemo-sp02"

# Create Azure Identity / Service Principal
$scopes = @(
    "Application.ReadWrite.All"
    "AppRoleAssignment.ReadWrite.All"
)
Connect-MgGraph -TenantId $tenantId -Scopes $scopes
$mgCtx = Get-MgContext

# Get Owners
$userId = (Get-MgUser -UserId $mgCtx.Account).Id # Self
$rotFuncId = $rotFunc.IdentityPrincipalId # Function App
$userDirObj = (Get-MgDirectoryObjectById -Ids $userId)[0]
$funcDirObj = (Get-MgDirectoryObjectById -Ids $rotFuncId)[0]

# Application
$adApp = Get-MgApplication -Filter "DisplayName eq '$spName'"
if ( $null -eq $adApp ) {
    $adApp = New-MgApplication -DisplayName $spName
    New-MgApplicationOwnerByRef -ApplicationId $adApp.Id -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
    New-MgApplicationOwnerByRef -ApplicationId $adApp.Id -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$rotFuncId"
    $adApp = Get-MgApplication -Filter "DisplayName eq '$spName'"
}

# Application Owners
New-MgApplicationOwnerByRef -ApplicationId $adApp.Id -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
New-MgApplicationOwnerByRef -ApplicationId $adApp.Id -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$rotFuncId"

# Service Principal
$adSp = Get-MgServicePrincipal -Filter "DisplayName eq '$spName'"
if ( $null -eq $adSp ) {
    $adSp = New-MgServicePrincipal -AppId $adApp.AppId -DisplayName $spName
}

# Service Principal Owners
New-MgServicePrincipalOwnerByRef -ServicePrincipalId $adSp.Id -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$userId"
New-MgServicePrincipalOwnerByRef -ServicePrincipalId $adSp.Id -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$rotFuncId"

# Create Secret
$curUtcTime = (Get-Date).AddHours( -1 * (Get-TimeZone).BaseUtcOffset.Hours )
$adAppSecret = Add-MgApplicationPassword -ApplicationId $adApp.Id -PasswordCredential @{
    displayName = "SecretRotationDemo"
    startDateTime = $curUtcTime
    endDateTime = $curUtcTime.AddDays( 7 )
}
$spSecret = ConvertTo-SecureString -String $adAppSecret.SecretText -AsPlainText -Force

# Store Secret in Key Vault
$curUtcTime = (Get-Date).AddHours( -1 * (Get-TimeZone).BaseUtcOffset.Hours )
$expTime = $curUtcTime.AddHours( 4 )
Set-AzKeyVaultSecret -VaultName $demoKvName -Name "appObjId-$($adApp.Id)" -SecretValue $spSecret -Expires $expTime
Set-AzKeyVaultSecret -VaultName $demoKvName -Name "spObjId-$($adSp.Id)" -SecretValue $spSecret -Expires $expTime
Set-AzKeyVaultSecret -VaultName $demoKvName -Name "spAppId-$($adSp.AppId)" -SecretValue $spSecret -Expires $expTime

Connect-MgGraph -Scopes AppRoleAssignment.ReadWrite