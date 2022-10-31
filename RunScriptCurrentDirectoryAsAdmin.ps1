param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

# Restart Process using PowerShell 64-bit 
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
   Try {
       &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
   }
 Catch {
     Throw "Failed to start $PSCOMMANDPATH"
 }
    Exit
}

# Save the current location and switch to this script's directory.
# Note: This shouldn't fail; if it did, it would indicate a
# serious system-wide problem.

$prevPwd = $PWD; Set-Location -ErrorAction Stop -LiteralPath $PSScriptRoot

try {
 # Your script's body here.
 # Install FortiClient VPN
  Start-Process Msiexec.exe -Wait -ArgumentList '/i FortiClientVPN.msi REBOOT=ReallySuppress /qn'
 # ... 
 $PWD  # output the current location 
}
finally {
  # Restore the previous location.
  $prevPwd | Set-Location
}
