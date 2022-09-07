Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table –AutoSize

Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | ? { $_ -match "Chrome" } | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table –AutoSize

# Get chrome version from mulple machines remotely

$servers = @('vdd98098', 'vss9839', 'kjf00009')

ForEach($server in $servers){
$version = gmi win32_product -ComputerName $server -Filter "Name='Google Chrome'" | Select -Expend Version "$server - $version"
}
