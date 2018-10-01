# Azure Automation sample script to put a specific VM in quarantine, based on a VM name and resource group
# Author: Tiander Turpijn, Microsoft
# Make sure that you leverage the by default created AzureRunAsConnection, management scope is your Azure subscription
# This script can be easily modified to add NSG rules as well, please note that I'm using a priority rule of 100 and I'm not checking conflicts (todo)
# Please test before using in production!

Param (
[Parameter(Mandatory = $true)]
[string]$VMname,
[Parameter(Mandatory = $true)]
[string]$ResourceGroupName
)
$ErrorActionPreference = "Stop"

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

# Variables - in case you want to add a new NetworkSecurityRule, ** PLease update **
$ScriptAction = "Add"
$Priority = 100
$Port = '*'
$Protocol = 'Tcp'
$Source = '*'
$Destination = '*'
$Action = 'Deny'
$Direction = 'Inbound'
$RuleName = "Deny-All-Inbound-Traffic"
$Description = "Rule added by Azure Security Center"

# Getting the AzureRm VM
Write-Output ("Retrieving VM $VMname from Resource Group $ResourceGroupName")
$VM = Get-AzureRmVm -Name $VMname -ResourceGroupName $ResourceGroupName

# We need to query the Network Profile to get the NetworkInterfaceID
Write-Output "Getting NetworkProfile...."
$NetworkInterfaceIDs = $VM.NetworkProfile.NetworkInterfaces.Id

# Now we find the NetworkInterface ID and put it in an array ($NicIDs), in case the VM has multiple NIC's
$NicIDs = @()
Write-Output "Getting NetworkInterfaceID's...."
#We need to loop through the found NetworkInterfaceID's in case we have more than one
foreach($NicID in $NetworkInterfaceIDs){
    $NIC = Get-AzureRmNetworkInterface | Where-Object {$_.id -eq $NICid}
    $NicIDs = $NicIDs += $NIC
}
#$NIC = Get-AzureRmNetworkInterface | Where-Object {$_.id -eq $NetworkInterfaceIDs}

# Since we now have the NetworkInterfaceID, we can find the NetworkSecurityGroup ID
$NsgIDs = @()
Write-Output "Getting NetworkSecurityGroup...."
foreach($NsgID in $NicIDs.NetworkSecurityGroup.Id){
    $NsgIDs = $NsgIDs += $NsgID
}
#$NSGid = $NIC.NetworkSecurityGroup.Id

# Based on the $NsgIDs we can find it the NSG properties
$NsgGroupIDs = @()
Write-Output "Getting NetworkSecurityGroupIDs...."
foreach($NsgGroupID in $NsgIDs){
    $NsgGroupID = Get-AzureRmNetworkSecurityGroup | Where-Object {$_.ID -eq $NsgGroupID }
    $NsgGroupIDs = $NsgGroupIDs += $NsgGroupID
}
#$NSG = Get-AzureRmNetworkSecurityGroup | Where-Object {$_.ID -eq $NSGid }

# Uncomment to see all network rule names
#$NSG.SecurityRules.Name

# Look at (Get) a specific NetworkSecurityRule
#Get-AzureRmNetworkSecurityRuleConfig -Name "Port_135" -NetworkSecurityGroup $NSG

foreach($NsgAction in $NsgGroupIDs)
{
    if($ScriptAction -eq "Delete")
    {
        Write-Output ("Trying to delete rulename " + $RuleName)
        try {Remove-AzureRmNetworkSecurityRuleConfig -Name $RuleName -NetworkSecurityGroup $NSG}
        catch
        {
            Write-Output "Something went wrong..."
            Write-Output ("Error Message: " + $ErrorMessage)
            break
        }
    }
    else{
        if($ScriptAction -eq "Add")
        {
            Write-Output ("Trying to add rulename " + $RuleName)
            try {
                $a = Get-AzureRmNetworkSecurityGroup -Name $Nsgaction.Name -ResourceGroupName $NsgAction.ResourceGroupName
                Add-AzureRmNetworkSecurityRuleConfig -Name $RuleName -Priority $Priority -DestinationPortRange $Port `
                -Protocol $Protocol -SourcePortRange $Source -DestinationAddressPrefix $Destination `
                -Access $Action -Direction $Direction -SourceAddressPrefix $Source `
                -Description $Description -NetworkSecurityGroup $a
                Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $a
            }
            catch
            {
                $ErrorMessage = $_.Exception.Message
                Write-Output ("*** Something went wrong *** " + $ErrorMessage)
                break
            }
        }
    }
}
