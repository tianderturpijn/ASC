<#
*******************************************************************************************************************************************
* PowerShell sample script to leverage the Azure Security Center Rest API for SIEM integration scenarios
* Pre-reqs: Azure SPN
* References: https://msdn.microsoft.com/en-us/library/mt704034.aspx
*             Data provider source types: https://msdn.microsoft.com/en-us/library/mt704039.aspx
*             Azure SPN setup: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal
* tiandert@microsoft.com                                                                                 
*******************************************************************************************************************************************
#>


#region Params
param (
    [Parameter(Mandatory=$true)][string]$resourceGroup,
    [Parameter(Mandatory=$true)][string]$sourceType = "alerts"

)
#endregion

<#

#>

#region variables
$tenantID=""
$clientID=""
$clientSecret=""
$subscriptionID=""
$alerts = $null
$alert = $null
$entry = $null
#endregion

#region Connect to the Security Rest API
#Create Access Token
$Token = Invoke-RestMethod -Uri https://login.microsoftonline.com/$tenantID/oauth2/token?api-version=1.0 -Method Post -Body @{"grant_type" = "client_credentials"; "resource" = "https://management.core.windows.net/"; "client_id" = $clientID; "client_secret" = $clientSecret}
 
#Define RestAPI Endpoint (change the provider for your specific usage, like alerts, securitystatuses, tasks, etc.)
#Provider reference: https://msdn.microsoft.com/en-us/library/mt704039.aspx
$SubscriptionURI="https://management.azure.com/subscriptions/$SubscriptionID/providers/microsoft.Security/$sourceType" +'?api-version=2015-06-01-preview'

$Headers = @{
    'authorization'="Bearer $($Token.access_token)"
    }

#Construct the request 
"`nGetting data..."
try
{$Request = Invoke-RestMethod -Method GET -Headers $Headers -ContentType "application/x-www-form-urlencoded" -Uri $SubscriptionURI}
catch
{
Write-Output "Error while executing Invoke-RestMethod!"
break
}
#endregion

#region Output Rest API results
#all
#$Request.value

#one entry
#$Request.value[0].properties
#endregion

#region Parsing Alerts
#foreach ($alert in $Request.value.properties){
#Write-Output ($alert.compromisedEntity + " - "+ $alert.alertDisplayName + " - " + $alert.reportedTimeUtc)
#}
#endregion

#region filter entries based on params

#uncomment to see all information:
#$Request.value.properties
foreach($entry in $Request.value.properties){
if ($entry.associatedResource | Select-String -Pattern "/resourceGroups/$resourceGroup"){
    foreach ($alert in $entry){
    $alerts = ($alert.compromisedEntity + " - "+ $alert.alertDisplayName + " - " + $alert.reportedTimeUtc)
    $alerts
        }
    }
}
if ($alerts -eq $null){
    Write-Output "`nNothing found!"
        }
#endregion


