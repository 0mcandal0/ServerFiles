
# get the last 10 event id 4624 
function Get-RdpLogonEvent
{
    [CmdletBinding()]
    param(
        [Int32] $Last = 10
    )

    $RdpInteractiveLogons = Get-WinEvent -FilterHashtable @{
        LogName='Security'
        ProviderName='Microsoft-Windows-Security-Auditing'
        ID='4624'
        LogonType='10' # RemoteInteractive
    } | Select-Object -First $Last

    $RdpNetworkLogons = @()
    foreach ($RdpInteractiveLogon in $RdpInteractiveLogons) {
        $RdpNetworkLogon = Get-WinEvent -FilterHashtable @{
            LogName='Security'
            ProviderName='Microsoft-Windows-Security-Auditing'
            ID='4624'
            LogonType='3' # Network
        } | Where-Object {
            ($_.TimeCreated -lt $RdpInteractiveLogon.TimeCreated) -and
            ($_.Properties[5].Value -eq $RdpInteractiveLogon.Properties[5].Value)
        } | Select-Object -First 1
        $RdpNetworkLogons += $RdpNetworkLogon
    }

    $RdpNetworkLogons | ForEach-Object {
        [PSCustomObject] @{
            EventTime = $_.TimeCreated
            UserName = $_.Properties[5].Value
            DomainName = $_.Properties[6].Value
            AuthPackage = $_.Properties[10].Value
            SourceAddress = $_.Properties[18].Value
        }
    }
}

# Get-RdpLogonEvent -Last 10 | Format-Table
