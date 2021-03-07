Function Get-PendingRebootStatus {

 
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0
        )]
 
    [string[]]  $ComputerName = $env:COMPUTERNAME
    )
 
 
    BEGIN {}
 
    PROCESS {
        Foreach ($Computer in $ComputerName) {
            Try {
                $PendingReboot = $false
 
                $HKLM = [UInt32] "0x80000002"
                $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
 
                if ($WMI_Reg) {
                    if (($WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")).sNames -contains 'RebootPending') {$PendingReboot = $true}
                    if (($WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")).sNames -contains 'RebootRequired') {$PendingReboot = $true}
 
                    #Checking for SCCM namespace
                    $SCCM_Namespace = Get-WmiObject -Namespace ROOT\CCM\ClientSDK -List -ComputerName $Computer -ErrorAction Ignore
                    if ($SCCM_Namespace) {
                        if (([WmiClass]"\\$Computer\ROOT\CCM\ClientSDK:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending -eq $true) {$PendingReboot = $true}
                    }
 
                    if ($PendingReboot -eq $true) {
                        [PSCustomObject]@{
                            ComputerName   = $Computer.ToUpper()
                            PendingReboot  = $true
                        }
                      } else {
                        [PSCustomObject]@{
                            ComputerName   = $Computer.ToUpper()
                            PendingReboot  = $false
                        }
                    }
                }
            } catch {
                Write-Error $_.Exception.Message
 
            } finally {
                #Clearing Variables
                $WMI_Reg        = $null
                $SCCM_Namespace = $null
            }
        }
    }
 
    END {}
}
