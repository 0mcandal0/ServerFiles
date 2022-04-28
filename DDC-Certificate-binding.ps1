###SCRIPT BEGINS HERE - run as administrator to bind the certificate with DDC###


Write-Host "This script should be run on the delivery controller to bind your imported SSL Certificate to the Citrix Broker Service"
Write-Host "Please make sure that you've imported a valid server SSL certificate on your Controller/Broker server.
Write-Host "You should only have two certificates in your personal store.  The new one and the one you want to replace (due to expire)"
Write-Host "If there is already a bound SSL certificate, it must be expiring within the next 60 days or expired for this to work"
""
netsh http show sslcert
""
$continue = Read-Host "Would you like to Continue? Y/N"
""

If ($continue -eq "y" -or $continue -eq "Y") {
""
Write-Host "Getting the AppID for the Citrix Broker Service"

Write-Host "--------------------------------------------------"
$appID = Get-ChildItem HKLM:\software\Classes\Installer\Products | Get-ItemProperty | where {$_.ProductName -match "Citrix Broker Service"} | foreach {$_.PSPath.ToString().Split("\")[6]}
if ($appID) {
$appID = $appID.Insert(20,"-")
$appID = $appID.Insert(16,"-")
$appID = $appID.Insert(12,"-")
$appID = $appID.Insert(8,"-")
$appID = "{$appID}"
} else {Write-Host "Error: Unable to find Citrix Broker Service"

break
}

Write-Host "Citrix Broker Service AppID = $appID"

""
Write-Host "Getting the current SSL Cert expiring withing the next 60 days"

$expiringCert = ls Cert:\LocalMachine\My -ExpiringInDays 60

If (-not $expiringCert) {
Write-Host "Unable to find an expiring certificate within the next 60 days"
Write-Host "Looking for expired certificate"
$expiredCert = ls Cert:\LocalMachine\My -ExpiringInDays 0
If ($expiredCert) {
""
Write-Host ">>> YOUR CERTIFICATE HAS ALREADY EXPIRED !!! <<<"
$expiringCert = $expiredCert
$expiredCert
} else {""
Write-Host ">>> No server certificates expiring in the next 60 days found! <<<"}


}

""
Write-Host "Finding a valid Server SSL Cert that is not currently bound to the Citrix Broker Service"
$computername = $env:computername

$certs = ls Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -notmatch $expiringCert.Thumbprint -and $_.Subject -match $computername}
if (-not $certs) {
$certs = ls Cert:\LocalMachine\My | Where-Object {$_.Subject -match $computername}
}

$myCert = $certs | Select-Object -ExpandProperty Thumbprint | foreach {$_}

If ($certs) {
Write-Host "Found a valid Server SSL CertHash: $myCert"
$bind = Read-Host "Would you like to Bind the certificate to the Citrix Broker Service? Y/N"
If ($bind -eq "y") {
Write-Host "Binding new cert hash to the Citrix Broker Service"
Remove-NetIPHttpsCertBinding
Add-NetIPHttpsCertBinding -IpPort "0.0.0.0:443" -CertificateHash $myCert -CertificateStoreName "My" -ApplicationId $appID -NullEncryption $false
netsh http show sslcert
}else {Write-Host "Cancelled binding!" }

}else {Write-Host "Could not find a new valid certificate"}


}
pause
