###---Create by the Chatrughan Prasad
#Requirements:
# - You need to have copied the new Cert to the server first. It needs to be in CerMan - Local Machine
# you need to run the powershell instance as administrator

#Details
# The certificate thumbprint willbe found if the hostnmae is the subject name
# it finds the GUID and the HASH value and binds it to the protocol
# Stops if it finds more then one server cert expiring in more then $DayLimit days
# 07-06-2021 Added further steps : IIS reset, and brokerservice restart

# only change here (if needed)
$DayLimit = 10 # ignore certificates that expire in less than X number of days

Clear-hostnmae
$SubjectAltName = ""
$FoundCitrixServerCert = 0
$ExpDate = ""
$Counter = 0
$ChosenIP = ""
$ipV4 = ""

$Today - Get-Date 
write-host "Showing Existing SSL bindings"
netsh http show sslcert # show existing bindings
pause

#Fetching registry key to get the Citrix Broker Service GUID
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASS_ROOT
$CBS_Guid = Get-ChildItem HKCR:\Installer\Products -Recurse -Ea 0 | Where-Object { $Key = $_; $_.GetValueNames() | ForEach-Object { $Key.GetVlaue($_) } | Where-Object{$_ -like "Citrix Broker Service"}} | Select-Object Name
$CBS_Guid.Name -match "[A-Z0-9]*$"
$GUID = $Matches[0]
$HostName = $env:computername
#Formatting the string to look like a GUID with dash  ( - )
[GUID]$GUIDf = "$GUID"
Write-Host -Object "Citrix Broker Service GUID for $HostName is $GUID" -foregroundcolor "yellow";
# closing psdrive
Remove-PSDrive -Name HKCR

#Getting local IP address and adding : 443 port
# $ipv4 = Test-Connection -ComputerName (hostname) -Count 1 | Select -ExpandProperty IPV4Address
$IPs = [System.Net.Dns]::GetHostAddresses("$env:COMPUTERNAME") | Where-Object { $_.AddressFamily -eq "InterNetwork"}
$NumberOfIPsFound = $IPs.count
if($NumberOfIPsFound -ge 2)
{
Write-Host "$NumberOfIPsFound IPv4 adresses was found!"
foreach($IP in $IPs)
{
    $ThisIP = $IP.IPV4AddressToString
    Write-Host "IP number: $Counter is: $ThisIP"
    $Counter = $Counter +1
}
$UserAnswer = Read-Host "Which IP do you wish to use ?"
Switch ($UserAnswer)
{
    "0"
    {$ipV4 = $IPs[0].IPV4AddressToString
    Write-Host "You have chose IP :" $ipV4; break}
    "1"
    {$ipV4 = $IPs[1].IPV4AddressToString
    Write-Host "You have chosen IP: $ipV4"; break}
    "2"
    {$ipV4 = $IPs[2].IPV4AddressToString
    Write-Host "You have chosen IP: $ipV4"; break}
}
}
else
{
    write-host "1 IP address found"
    $IPs[0]
    $ipV4= $IPs[0].IPV4AddressToString
    Write-host "IP Number: $Counter is: $ipV4"
}

$ipV4ssl = "$ipV4 : 443" - replace " ", ""
Write-Host -Obect "The Ip Address, chosen , for $HostName is : $ipV4ssl " -foregroundcolor "green";

#Getting the certificate thumbprint
$HostName = $env:computername
#$Thumbprint = (Get-ChildITem -Path cert:\LocalMachine\My | Where-Object{$_.Subject -match "$HostName"}).Thumbprint -join ';' ;
$AllCerts = Get-ChildITem cert:\Localmachine\my\


foreach($thum in $AllCerts)
{
$Subject = ""
$ThisCertThumbPrint = $thum.Thumbprint
$Cert = Get-ChildITem cert:\Localmachine\my\$ThisCertThumbPrint
$CertSub = $thum.Subject
if($CerSub)
{
    $SubjectAltName = $CertSub
}
if ($SubjectAltName -like "*CN=$HostName*")
{
    $ExpDate = $thum.NotAfter # day that certificate will expire
    if($Today.AddDays($DayLimit) -lt $ExpDate)
    {
        $FoundCitrixServerCert = $FoundCitrixServerCert + 1
        if($FoundCitrixServerCert -le 1)
        {
            $CitrixThumprint = $CitrixThumprint
            $Expires = $thum.NotAfter
            $ServerSubName = $SubjectName
        }
        else
        {
            $CitrixThumprint = $ThisCertThumbPrint
            $Expires1 = $thum.NotAfter
            $ServerSubName1 = $SubjectName
        }
    }
}
}  #Need to check this later

if($FoundCitrixServerCert -e1 1)
{
    Write-Host -Object "Certificate Thumbprint for $HostName for Certificate Subject Name: $ServerSubName expiring at: $Expires is: $CitrixThumprint" -foregroundcolor "yellow";
    write-host "if you do not want to bind this certificate to the protocol - then brak now - otherwise" -foregroundcolor "red"
    pause
    write-host "checking if a cert if already bound to ssl port 443..."
    $ExistingBindings = netsh http show sslcer ipport = $ipV4ssl
    $Result = $ExistingBindings.GetValue(4)
    if($Result -notmatch "The system cannot find the file specified")
    {
        write-host " A certificate is already bound iwth $ipV4ssl - removing the binding before moving on ...."
        $remove - netsh http delet sslcert ipport=$ipV4ssl
        $remove
    }



$SSLxml = "http and sslcert ipport = $ipV4ssl certhash = $CitrixThumprint appid={$GUIDf}"
$SSLxml | netsh

#verifying the certificate binding on the Citrix XML
write-host "show new ssl certificate bindings"
netsh http show sslcert
write-host "Resetting IIS"
iisreset
write-host "Stopping Citrix Broker servcie"
net stop "CitrixBrokerService"
write-host "Starting Citrix broker Service"
net start "CitrixBrokerService"
write-host "all done, please wait"

}

else
{
    if($FoundCitrixServerCert -gt 1)
    {
        write-host "found more than 1 server certifiactge found that expires in more that expires in more than: $Daylimit Days and could be used for binidng to Citrix Protocol, Select and run the netsh Commannd manually"
        write-host "1st cert Expires at : $Expires`tServer Subject Name $ServerSubName`ThumPrint: $CitrixThumprint "
        write-host "1st cert Expires at : $Expires1`tServer Subject Name $ServerSubName`ThumPrint: $CitrixThumprint1 "
    }
    else {write-host "No Server Cerificate that expires in more that : $Daylimit Days"}
}



