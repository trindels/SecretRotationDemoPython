# Variables
$tenantId = "73043c5d-205c-4462-beb9-13bebde5ec9e"
$scopes = @(
    "Application.ReadWrite.All"
    "AppRoleAssignment.ReadWrite.All"
)
$functionAppSpId = "23aaddab-94a5-4d97-b833-069718a0846c"  # $rotFunc.IdentityPrincipalId

# Connect to MS Grpah
Connect-MgGraph -TenantId $tenantId -Scopes $scopes

# Grant Function App with Graph API Access
$graphSp = Get-MgServicePrincipal -Filter "AppId eq ''00000003-0000-0000-c000-000000000000''"  # Get Graph SP
$graphAppRoles = $graphSp.AppRoles | Where-Object -Property Value -In @( "Application.ReadWrite.OwnedBy" ) # Get Graph Application Role
New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $graphSp.Id `
    -PrincipalId $functionAppSpId `
    -ResourceId $graphSp.Id `
    -AppRoleId $graphAppRoles.Id