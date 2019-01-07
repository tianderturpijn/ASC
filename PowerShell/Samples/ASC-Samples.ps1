#region List all ASC PowerShell commands
Get-Command -Module Az.Security
#endregion

#region Azure Microsoft.Security ResourceProvider registration
#Verify registration
Get-AzResourceProvider -ProviderNamespace Microsoft.Security | Select-Object ProviderNamespace, Locations, RegistrationState

#Register the Microsoft.Security resource provider
Register-AzResourceProvider -ProviderNamespace Microsoft.Security
#endregion

#region Assign ASC Azure Policy
#Assign the ASC Azure Policies to a subscription
$mySub = Get-AzSubscription -SubscriptionName "<mySubscriptionName>"
$subscription = "/subscriptions/$mySub"
$policySetDefinition = Get-AzPolicySetDefinition | Where-Object {$_.Properties.DisplayName -eq "[Preview]: Enable Monitoring in Azure Security Center"}
New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -Name "<YourAssignmentName>" -Scope $subscription -PolicyParameter "{}"

#Assign the ASC Azure Policies to a resource group
$resourceGroup = Get-AzResourceGroup -Name "<myResourceGroupName>"
$policySetDefinition = Get-AzPolicySetDefinition | Where-Object {$_.Properties.DisplayName -eq "[Preview]: Enable Monitoring in Azure Security Center"}
New-AzPolicyAssignment -PolicySetDefinition $policySetDefinition -Name "<YourAssignmentName>" -Scope $resourceGroup.ResourceId -PolicyParameter "{}"
#endregion

#region GET Autoprovision settings for subscriptions
#Get Autoprovision setting for the current scope
Get-AzSecurityAutoProvisioningSetting

#Get the Autoprovision setting for all Azure subscriptions 
Get-AzContext -ListAvailable -PipelineVariable myAzureSubs | Set-AzContext | ForEach-Object{
    Write-Output $myAzureSubs
    Get-AzSecurityAutoProvisioningSetting | Select-Object AutoProvision
    "-"*100
}

#Get the AutoProvision settings based on an input file
#Get subscriptions from Azure
$subscriptions = Get-AzSubscription

#Create an output file with all the subscriptions names
$subscriptions.Name | Out-File "C:\Temp\Subscriptions.txt"

$subscriptionFile = Get-Content -Path "C:\Temp\Subscriptions.txt"
foreach($subNameFromFile in $subscriptionFile){
    Select-AzSubscription $subNameFromFile | Out-Null
    $autoSettings = Get-AzSecurityAutoProvisioningSetting
    Write-Output ("SubscriptionName: " + $subNameFromFile + " - AutoProvisionSetting: " + $autoSettings.AutoProvision)
}
#endregion

#region SET AutoProvision settings
#Set AutoProvision to ON for the current scope
Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision

#Set AutoProvision to OFF for the current scope
Set-AzSecurityAutoProvisioningSetting -Name "default"

#Set AutoProvision to ON for all subscriptions
Get-AzContext -ListAvailable -PipelineVariable myAzureSubs | Set-AzContext | ForEach-Object{
    Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision
}

#SET Autoprovision setting to ON, using an input file
$subscriptionFile = Get-Content -Path "C:\temp\Subscriptions.txt"
foreach($subNameFromFile in $subscriptionFile){
    Select-AzSubscription $subNameFromFile | Out-Null
    Write-Output "Enabling Autoprovision for subscription $subNameFromFile"
    Set-AzSecurityAutoProvisioningSetting -Name "default" -EnableAutoProvision
}

#SET Autoprovision setting to OFF, using an input file
$subscriptionFile = Get-Content -Path "C:\temp\Subscriptions.txt"
foreach($subNameFromFile in $subscriptionFile){
    Select-AzSubscription $subNameFromFile | Out-Null
    Write-Output "Disabling Autoprovision for subscription $subNameFromFile"
    Set-AzSecurityAutoProvisioningSetting -Name "default"
}
#endregion

#region Azure Security Pricing
#Get current pricing tier
Get-AzSecurityPricing | Select-Object Name, PricingTier

#Set Azure Security Center pricing tier for the default scope, use either "Standard" or "Free"
Set-AzSecurityPricing -Name default -PricingTier "Standard"

#region Security Alerts
#Tip: you can filter out fields of interest by using Select-Object
Get-AzSecurityAlert
Get-AzSecurityAlert | Select-Object AlertDisplayName, CompromisedEntity, Description
#endregion

#region Security Contact information
#Get the security contact in the current scope
Get-AzSecurityContact

#Get all the security contacts
Get-AzContext -ListAvailable -PipelineVariable myAzureSubs | Set-AzContext | ForEach-Object{
    Get-AzSecurityContact}

#Set a security contact for the current scope. For the parameter "-Name", you need to use "default1", "default2", etc.
Set-AzSecurityContact  -Name "default1" -Email "john@johndoe.com" -Phone "12345" -AlertAdmin -NotifyOnAlert

#SET security contacts for all subscriptions (assuming you have the appropriete permissions)
Get-AzContext -ListAvailable -PipelineVariable myAzureSubs | Set-AzContext | ForEach-Object{
    Set-AzSecurityContact -Email "john@doe.com" `
    -NotifyOnAlert -phone "12345" `
    -Name 'default1' -AlertAdmin }
#endregion

#region Security Compliance
$compliance = Get-AzSecurityCompliance   

#example, get the compliance percentage for your subscription
$compliance[0].AssessmentResult
#endregion

#region workspace settings
#Get the configured workspace for the current scope
$workspace = Get-AzSecurityWorkspaceSetting

#display the configured workspaceID and workspaceName
$workspace.WorkspaceId

#Set the workspace
#get the workspaceName and workspaceID - this requires the module Az.OperationalInsights
$workspaceID = Get-AzOperationalInsightsWorkspace -Name "<workspaceName>" -ResourceGroupName "<workspaceResourceGroupName"
Set-AzSecurityWorkspaceSetting -Name default -WorkspaceId "<workspaceID"
#endregion





