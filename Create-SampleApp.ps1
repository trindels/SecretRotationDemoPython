# Environment Variables
$rgName = "trr-secretrotationdemo-rg"
$location = "eastus2"

# Application Variables
$appAspName = "trr-sampleapp-asp"
$appWebName = "trr-sampleapp-web"
$appSaName = "trrssampleappsa"

# Resource Group
$rg = Get-AzResourceGroup -Name $rgName
if ( $null -eq $rg ) {
    New-AzResourceGroup -Name $rgName -Location $location
}

# App Service Plan
$asp = Get-AzAppServicePlan -Name $appAspName -ResourceGroupName $rgName
if ( $null -eq $asp ) {
    $asp = New-AzAppServicePlan -Name $appAspName -ResourceGroupName $rgName -Location $location -Tier Free
}

# Web App
$wa = Get-AzWebApp -Name $appWebName -ResourceGroupName $rgName
if ( $null -eq $wa ) {
    $wa = New-AzWebApp -Name $appWebName -ResourceGroupName $rgName -Location $location -AppServicePlan $appAspName -AssignIdentity $true
}

# Storage Account
$storage = Get-AzStorageAccount -Name $appSaName -ResourceGroupName $rgName
if ( $null -eq $storage ) {
    $storage = New-AzStorageAccount -Name $appSaName -ResourceGroupName $rgName -Location $location -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot
}

