# Identity Name Variables
$tenantId = "73043c5d-205c-4462-beb9-13bebde5ec9e"
$spName = "trr-secretrotationdemo-sp01"

# Environment Variables
$rgName = "trr-secretrotationdemo-rg"
$location = "eastus2"

# Variables
$demoKvName = "trrsecretrotationdemokv"
$demoSaName = "trrsecretrotationdemosa"
$demoLawName = "trr-secretrotationdemo-rotation-law"
$demoAiName = "trr-secretrotationdemo-rotation-appinsights"
$demoAspName = "trr-secretrotationdemo-rotation-asp"
$demoFuncName = "trr-secretrotationdemo-rotation-func1"
$demoEgName = "trr-secretrotationdemo-rotation-evtgrid"

# Azure Environment:  Create Azure Resource Group
$rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
if ( $null -eq $rg ) {
    New-AzResourceGroup -Name $rgName -Location $location -Tag @{ "BusinessUnit" = "Microsoft"; "CostCenter" = "Self" }
}

# Key Vault
$rotKv = Get-AzKeyVault -VaultName $demoKvName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if ( $null -eq $rotKv ) {
    $rotKv = New-AzKeyVault -Name $demoKvName -ResourceGroupName $rgName -Location $location
}

# Log Analytics
$rotLaw = Get-AzOperationalInsightsWorkspace -Name $demoLawName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if ( $null -eq $rotLaw ) {
    $rotLaw = New-AzOperationalInsightsWorkspace -Name $demoLawName -ResourceGroupName $rgName -Location $location -Sku pergb2018
}

# Application Insights
$rotAppInsights = Get-AzApplicationInsights -Name $demoAiName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if ( $null -eq $rotAppInsights ) {
    $rotAppInsights = New-AzApplicationInsights -Name $demoAiName -ResourceGroupName $rgName -Location $location `
        -WorkspaceResourceId $rotLaw.ResourceId
}

# Storage Account
$rotStorage = Get-AzStorageAccount -Name $demoSaName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if ( $null -eq $rotStorage ) {
    $rotStorage = New-AzStorageAccount -Name $demoSaName -ResourceGroupName $rgName -Location $location -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot
}

# App Service Plan
$rotAsp = Get-AzAppServicePlan -Name $demoAspName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if ( $null -eq $rotAsp ) {
    $rotAsp = New-AzAppServicePlan -Name $demoAspName -ResourceGroupName $rgName -Location $location -Tier Y1 -Linux
}

# Function App
$rotFunc = Get-AzFunctionApp -Name $demoFuncName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if ( $null -eq $rotFunc ) {
    $rotFunc = New-AzFunctionApp -Name $demoFuncName -ResourceGroupName $rgName -Location $location `
        -FunctionsVersion 4 `
        -OSType Linux `
        -Runtime Python -RuntimeVersion 3.11 `
        -StorageAccountName $demoSaName `
        -ApplicationInsightsName $demoAiName `
        -ApplicationInsightsKey $rotAppInsights.InstrumentationKey `
        -IdentityType SystemAssigned
}

# Event Grid System Topic
$rotEgst = Get-AzEventGridSystemTopic -Name $demoEgName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
if ( $null -eq $rotEgst ) {
    $rotEgst = New-AzEventGridSystemTopic -Name $demoEgName -ResourceGroupName $rgName -Location $location `
        -IdentityType SystemAssigned `
        -TopicType "Microsoft.KeyVault.vaults" `
        -Source $rotKv.ResourceId
}

# Give Rotation App Permissions to Key Vault
$rotFuncId = $rotFunc.IdentityPrincipalId
$rotKv | Set-AzKeyVaultAccessPolicy -ObjectId $rotFuncId -PermissionsToSecrets set,list

# Deploy Code to Rotation Function App


