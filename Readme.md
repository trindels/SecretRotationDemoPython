# Automated Secret Rotation Demo

## Deployment

### (1) Create Secret Rotation Infrastructure
Requirements:
- Az Powershell Modules

Steps:
1. Run Create-SecretRotationDemo.ps1
    - Resource Group
    - Key Vault
    - Log Analytics
    - Application Insights
    - Storage Account
    - App Service Plan
    - Function App
    - Event Grid System Topic
    - Function App Managed Identity Permissions to Key Vault

### (2) Deploy Function App Code (VSCode)
Requirements:
- VS Code
- VS Code Extensions:
    - Azure Account
    - Azure Resources
    - Azure Functions

Steps:
1. Launch VSCode
2. Edit "function_app.py" with your appropriate Key Vault Permissions
3. Deploy Function App

### (3) Configure Function App MS Graph API Access
Requirements:
- MS Graph Powershell Modules

Steps:
1. Run Configure-FunctionAppIdentity.ps1
    - Function App Managed Identity MS Graph API Permssions (Application.ReadWrite.OwnedBy)

### (4) Configure Event Grid Subscription
Requirements:
- Az Powershell Modules

Steps:
1. Run Configure-SecretRotationDemo.ps1
    - Event Grid System Topic Event Subscription

### (5) Create Service Principal Account
Requirements:
- MS Graph Powershell Modules

Steps:
1. Run Create-ServicePrincipal.ps1
    - Create Service Principal
    - Grant Function App Managed Identity as Owner to Service Principal

### (6) Configure Sample App
Requirements:
- Az Powershell Modules

Steps:
1. Run Create-SampleApp.ps1
    - Resource Group
    - App Service Plan
    - Web App
    - Storage Account
2. Run Configure-SampleApp.ps1
    - Set App Settings Configuration values:
        - Storage Blob Uri
        - Key Vault Uri
        - Service Principal Id
    - Grant Service Principal to Storage Permissions
    - Grant Web App Managed Identity GET access to Key Vault

## Post-Demo Cleanup Activities
Requirements:
- Az Powershell Modules
- MS Graph Powershell Modules

Steps:
1. Run Delete-SampleApp.ps1
2. Run Delete-ServicePrincipal.ps1
3. Run Delete-SecretRotationDemo.ps1