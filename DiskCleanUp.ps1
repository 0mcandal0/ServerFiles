Function Check-if-empty-folder {
[cmdletbinding()]
Param (
[parameter(Mandatory=$true)]
[string]$folderName
  
)
$directoryInfo = Get-ChildItem $folderName | Measure-Object
$count = $directoryInfo.count
if($count -eq 0){
  return 0
}
else{
  return 1
 }
}
  
  
  
$Daysback = "-60"
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)
$systemDrive = Get-ChildItem -Path Env:\SystemDrive | select -ExpandProperty Value
$iisPath = "$systemDrive\inetpub\logs\LogFiles\"
$foldersToCheck = @("$systemDrive\Windows\ccmcache", "$systemDrive\Windows\SoftwareDistribution\Download", "$systemDrive\Windows\Temp", "$systemDrive\Users\*\AppData\Local\Temp\*")
  
# Delete IIS logs older than 60 days
  
if(Test-Path $iisPath){
  $iisLogs = Get-ChildItem -Recurse $iisPath | Where-Object { (! $_.PSIsContainer) -and ($_.LastWriteTime -lt $DatetoDelete) }
  foreach ($iisLog in $iisLogs){
     Try{
        Remove-Item $iisLog.FullName -Force -ErrorAction Stop
        Write-Host "Deleted: " $iisLog.FullName -ForegroundColor Yellow
     }
     Catch{
        Write-Host "Error deleting: $iisLog.FullName; Error Message: $($_.Exception.Message)" -ForegroundColor Cyan
     }
    }
}
  
  
# Delete content of C:\Windows\SoftwareDistribution\Download, C:\Windows\Temp,C:\Windows\ccmcache and user temp folders
  
  
 foreach ($folderToCheck in $foldersToCheck){
     If (Test-Path -Path $folderToCheck){
     if([bool](Check-if-empty-folder -folderName $folderToCheck) -eq 1 ){
         $folderList = Get-ChildItem -Path $folderToCheck
         foreach($folder in $folderList){
         Try{
            Remove-Item $folder.FullName -Recurse -Force  -ErrorAction Stop
            Write-Host "Deleted: " $folder.FullName -ForegroundColor Yellow
         }
         Catch{
           Write-Host "Error deleting: $folder.FullName; Error Message: $($_.Exception.Message)" -ForegroundColor Cyan
      }
     }
   }
 }
}
   
# Delete unknown user profiles
  
Get-CimInstance win32_userprofile | foreach {
    ""
    $u = $_          # save our user to delete later
    try {
        $objSID = New-Object System.Security.Principal.SecurityIdentifier($U.sid) -ErrorAction stop
        $objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
        "User={0}" -f $objUser.Value
        "Path={0}" -f $u.LocalPath
        "SID={0}" -f $u.SID
    }
    catch {
        "!!!!!Account Unknown!!!!!"
        "Path={0}" -f $u.LocalPath
        "SID={0}" -f $u.SID
        Remove-CimInstance -inputobject $u -Verbose
    }
}
  
# Running disk Cleanup
cleanmgr /sagerun:1 | out-Null
