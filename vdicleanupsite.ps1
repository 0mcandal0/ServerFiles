#VDI CleanUp Script - Author Chatrughan Prasad
[cmdletBinding()]
Param(
    $Tag = "VDI_CLEANUP",
    $DesktopGroupNameList = "deliver group names, second dellivery group name",
    $CreatedDaysAgo = "60", # when computer object created in AD
    $CreatedDaysAgo2 = "60", # used for  shutdown of VDI s wher e user objec is disabled in AD
    $NotUsedDays = "60", #Days that users hasnot lgged in to the VDI using Citrix

    # 3 output Fils
    $OutputFile = "VDI-CLEANUP-TASK1-DCD3-" + (Get-Date -Format yyyy_dd_MM-HH_mm_ss) + ".csv",
    $ResultFile = "ACTIONS_" + $OutputFile,
    $Logfile = "log_" + $OutputFile.replace(".csv", ".log"),
    $OutputLocation = "C:\Test",

    $module = "Active Directory",
    $snapin = "Citrix.Broker.Admin",
    $FullList = "",
    $SplitName = "",
    $OutPutList = (New-Object System.Collections.ArrayList),
    $dateA = (get-date).Adddays(-$NotUsedDays),
    $dateB = (get-date).Adddays(-$CreatedDaysAgo),
    $dateC = (get-date).Adddays(-$CreatedDaysAgo2), # Used for shutdown the vDi when user is disabled
    $LogPath = $OutputLocation + "\" + $Logfile,
    $OutputPath = $OutputLocation + "\" + $ResultFile,
    $domainprefix = "rise\*", # rise.com
    $ProcessList = @(),
    $OutPutList_reduced = @(),
    [int]$i = "0",
    $DCD2 = "DKCPHV000023",
    #$DCD3 = "DKCPHV000023",
    $DCD = "",
    [int]$max = "1000"
)

#######################################functon Start ########################################################################

Function Log {
    param([string]$InfoTXT, [string]$Type = "INFO")
    $DataLog = Get-Date -Format "dd.MM.yyy HH:mm:ss"

    switch ($Type.ToUpper()) {
        "INFO" { Write-Host($DataLog + ' - ' + $InfoTXT) }
        "Warning" { Write-Host($DataLog + ' - ' + $InfoTXT) -ForgroundColor Yellow }
        "Error" { Write-Host($DataLog + ' - ' + $InfoTXT) -ForgroundColor Red }
        "VEBOSE" { Write-Host($DataLog + ' - ' + $InfoTXT) }
        default { Write-Host($DataLog + ' - ' + $InfoTXT) }
    }
}

function IsVDIOlderThanXDays {
    param($VDI)
    Try {
        $ADcomputer = Get-ADcomputer -Identiry $VDI -Properties created
        If ($ADcomputer) {
            $VDIcreated = $ADcomputer.created
            if ($VDIcreated -lt $datec) { $VMolderThanXDays = $true } else { $VMolderThanXDays = $false }
        }
    }
    Catch {
        #write-host 
        $VMolderThanXDays = "error"
    }
    $VMolderThanXDays
}

function FilterUserInfo {
    param ($User)
    if ($User) {
        $UserCount = $User.Cound
        if ($UserCount -gt 1) {
            # assigned VDIs Withe Several users
            if ($User[0] -match "QAONE") { $1Username = $User[0] }
            else {
                if ($Use[0] -match "ONEADR") {
                    $1Username = $User[0].Substring(7)
                }
            }
            [string]$AllUserNames = $User
        }
        else {
            if ($user -match "QAOne") { $1Username = $User[0] }
            else {
                if ($User -match "ONEADR") {
                    $1Username = $User.Substring(7)
                }
                else { $1Username = "No Users Found" }
            }
        }
    }
    else {
        #no Users Fonund
        $1Username = " No users fond"
    }
    $1Username
}

function CheckOnline { param([string]$HostName) }
$Result = Test-Connection $HostName -Quiet
try {
    $Tmp = Get-AdUser $User -Properties Enabled -ErrorAction SilentlyContinue
}
catch {
    Log "Use not found" -Type Error
    Log $Error[0] - Type Error\
    $myObject2 | Add-Member -type NoteProperty -Name UserExit -value $false

}
if ($tmp) {
    $myObject2 | Add-member -type NoteProperty -Name UserAccountEnabled -Value $tmp.Enabled
    #$myObject2 | Add-member -type NoteProperty -Name UsersDepartment -Value $tmp.Enabled
    #$myObject2 | Add-member -type NoteProperty -Name UsersMail -Value $tmp.Enabled
    $DisName = $Tmp.DistinguishedName
    $UserAccountIsEnabled = $tmp.Enabled
    if ($UserAccountIsEnabled -eq $false) {
        if ($DisName -like "*$Global:DisabledUsersOU") { $found = $true } #Defined as Global, beacase
        if ($Found)
        { $UserIsInDisabledUsersOU = $true }else { $UserIsInDisabledUsersOU = $false }
    }
    $myObject2 | Add-member -type NoteProperty - Name UserObjectInDisabledOU - Value $UserIsInDisabledUsersOU
}
$myObject2

function shutdown {
    param[string]$VDI, [string]$DCD
    $Check = Get-BrokerDesktop -AdminAddress $DCD2 -MachineName $item.FullMachinename
    New-BrokerHostingPowerAction -AdminAddress $DCD -Action Shutdown -MachineName $VDI
    #$result = $result.PowerActionPending
    #if($result){$result = "Shutdown pending"}
    $resutl
}

####Loading Citrix Snap-ins
Try {
    Get-PsSnapin -Registered -Nam $$snapin | Add-PSSnapin -ErrorAction stop
}
Catch {
    Log "Unable to load snapin $snapin" -Type Error
    Log $Error[0] -Type Error
    Exit 1
}

#####loading AD mdule
Try {
    Get-module $module | Import-Module $module -ErrorAction stop
}
catch {
    Log "Unable to load snapin $module" -Type Error
    Log $Error[0] -Type Error
    Exit 2

}

#############Main Script Start ###################
#Checking if location ofr the output is found
if (Test-Path $OutputLocation) {}
Else {
    Log "Unable to find output location $OutputLocation" -Type Error
    Exit 3
}
## Check if tag is found, if not tag will be created

$CheckTag = Get-BrokerTag $tag -ErrorAction SilentlyContinue
if ($CheckTag = Get-BrokerTag $tag -ErrorAction SilentlyContinue) {
    log "Tag: $tag, is not existing" -Type Type
    New-BrokerTag -eq | Out-Null
    Log "Created new tag: $tag" -Type Type
   
}
Else {
    Log "Tag: $tag, was found" -Typye Type
}

#$error.clear()
Start-Transcript -Path $LogPath

$DesktopGroupNameList = $DesktopGroupNameList.Split(",")

##Get list of machines not used in wated date
Log "Getting Full List of VDIs in Domain: $domainprefix from Citrix Site...." -Type INFO
Try {
    $FullList = Get-BrokerDesktop -MaxRecordCount 100000 -Filter { MachinesName -like $domainprefix } | Select `
    @{name = 'FullMachinename'; expression = { $_.MachinesName } }, `
    @{name = 'CitrixLastLogon'; expression = { $_.LastConnectionTime } }, `
    @{name = 'VDI'; expression = { $_.HostedMachineName } }, `
    @{name = 'AssignedUsers'; expression = { $_.AssociatedUsernames } }, `
    @{name = 'GroupName'; expression = { $_.DesktopGroupname } }, `
    @{name = 'Session'; expression = { $_.SessionState } }, `
    @{name = 'Tags'; expression = { $_.Tags } }, `
    @{name = 'DCD'; expression = { $_.HyperVisiorConnetionName } }`
        -ErrorAction Stop

}
Catch {
    Log "Unable to get VDI list" -Type Error
    Log $Error[0] -Type Error
    Exit 4
}
#Add fields to the list
$FullList | Add-Member -MemberType NoteProperty -name "MachineName" -value ""
$FullList | Add-Member -MemberType NoteProperty -name "Created" -value ""
$FullList | Add-Member -MemberType NoteProperty -name "UserIDDisabledOU" -value ""
$FullList | Add-Member -MemberType NoteProperty -name "NotMemberOfAnySMSpasscodeGroups" -value ""
$FullList | Add-Member -MemberType NoteProperty -name "EDCWin10TrustedVendorWin10" -value ""

##Removing VDIs from the list that have an active session
$FullList = $FullList | where { $_.session -eq $null }
##Start Powering off VDIs older than X days, where user object is disabled in AD, and usercound =1.
$count = 0
$found = 0
Foreach ($item in $FullList) {
    $count = $count + 1
    $total = $FullList.$count
    loG "Searching for VDIs with disabled users....Processing: $count of: $total" - Type info
    $VDI = $item.VDI
    if (!($VDI)) {
        $TmpName = $item.FullMachineName.Split("\")
        $VDI = $TmpName[1]
    }
    $UserCount = $item.AssignedUsers.$count
    $User = $item.AssignedUsers
    if (item.DCD -eq "DC02") { $DCD = $DCD2 } else { $DCD = $DCD3 }
    if (($UserCount -eq 1) -and ($VDI -notlike "RBN")) {
        #ignore Robotoc VDIs i.e. machine name "RBN"
        $VMolderThanXDays = IsVDIOlderThanXDays $VDI # VDI Should be older than X (30) days
        if ($VMolderThanXDays -eq $True) {
            $UserInfo = FilterUserInfo $User
            if ($UserInfo -ne "No Users Found") {
                $UserADinfo = CheckUserInAD $UserInfo -ErrorAction SilentlyContinue
                if ($UserADinfo.UserExit -ne $false) {
                    $UserAccountIsEnabled = $UserADinfo.UserAccountEnabled #check user is disabled 
                    if ($UserAccountIsEnabled -eq $false) {
                        #check that user is disabled
                        $Online = CheckOnline $VDI # Check if VDI is Powered on
                        if ($Online) {
                            $PwrState = ShutdownVDI $VDI $DCD # Shutdown if online
                            if (($PwerState[0].Action -eq "Shutdown") -and ($pwrState[0].State -eq "Pending" )) {
                                Log "User: $User is Disabled in AD - VDI is older than: $CreatedDaysAgo2 days -shutting down VDI: $VDI "
                                $found = $found + 1
                            }
                        }

                    }
                }
            }
            
        }
    }
}
Log "$fond VDIs, with disabled users were shutdown in total"

#####End ##### Powering Off VDIs older than x days, where user object is disabled in AD, and usercount = 1.

##Removing unwanted desktopgroup from the list
$FullList - $FullList | where { $DesktopGroupNameList -contains $_.GroupName }

#Removing VDI that have no Citrix Logon Date
$FullList = $FullList | where { $_.CitrixLastLogon -ne $null } # Removing according to  Dcom Rule 2
#Removing VDI that have been already tagged from the list and tagged for Robotic VDI or Decom Exclusive
$FullList = $FullList | where { ($_.tags -notcontains "Exclude from Decom") }
$FullList = $FullList | where { ($_.tags -notcontains "Robotics VDI") }

# Start - Adding two ekstra criteria for EDC user Groups "User object is in Disabled Ou and "User
$EDCGroupNameList = "VDI Delivery group name" # Deliver Group name
$Global:DisabledUsersOU = "ou=disabled-accounts,ou=rise,ou=com" # ou of disaled users
$count = 0
$found = 0
$FullList1 = @()
$FullList2 = @()
$FullList3 = @()
ForEach ($item in $FullList) {
    $UserAccountEnabled = ""
    $UserObjectInDisabledOU = ""
    $Found = ""
    if ($EDCGroupNameList -match $item.GroupName) {
        $item.EDCWin10TrustedVendorWin10 = $true
        $count = $count + 1
        $total = $FullList.$count
        Log "Searching for  VDIs whose users are in Disabled OU and User has  No SMS Passcode membership .....Processing $count of: $total" -Type INFO
        $VDI = $item.VDI
        if (!($VDI)) {
            $TmpName = $item.FullMachineName.Split("\")
            $VDI = $TmpName

        } 
        $UserCount = $item.AssignedUsers.$count
        $User = $item.AssignedUsers
        if ($item.DCD -eq "DCD02") { $DCD = $DCD2 } else { $DCD = $DCD3 }
        if (($UserCount -eq 1) -and ($VDI -notlike "*RBN*")) {
            #ignore robotics VDI
            $UserInfo = FilterUserInfo $User
            if ($UserInfo -ne "No users found") {

                $UserADinfo = CheckUserInAD $UserInfo -ErrorAction SilentlyContinue
                if ($UserADinfo.UserExit -ne $false) {
                    $UserAccountEnabled = $UserADinfo.UserAccountEnabled
                    $UserObjectInDisabledOU = $UserADinfo.UserObjectInDisabledOU
                    
                }
                if ($UserAccountEnabled -eq $false) {
                    if ($UserObjectInDisabledOU -eq $true) {
                        $item.UserObjectInDisabledOU = $true
                        {
                            $UsersADgroups = (Get-ADUser $UserInfo -Properties MemberOf).MemberOf
                            $Found = $UsersADgroups | Where-Object { $_ -match "Sec-vdc-vendor Access" }
                            If (!($Found))
                            { $item.NotMemberOfAnySMSpasscodeGroups = $true }
                            else
                            { $item.NotMemberOfAnySMSpasscodeGroups - $false }  
                        }
                        else { $Item.UserObjectInDisabledOU = $false }

                    }
                }
            }
        }
        else { item.EDCWin10TrustedVendorWin10 = $false }
    }
}


#$fullList = $FullList | where{($_.EDCWin10TrustedVendorWin10 -eq "$true" -and $_.UseresInDisabledOU -eq "$true" -and $_.NotMemberOfAnySMSpasscodeGroups -eq "$true")} -or ($_.EDCWin10TrustedVendorWin10 = $false)
$fullList1 = $FullList | where { ($_.EDCWin10TrustedVendorWin10 -eq $true -and $_.UseresInDisabledOU -eq $true -and $_.NotMemberOfAnySMSpasscodeGroups -eq "$true") }
$FullList2 = $FullList | where { ($_.EDCWin10TrustedVendorWin10 -eq $false) }
$FullList3 = $FullList1 + $FullList2
$FullList = $FullList3

#checking the logon dates and filter out VDI;s that ar ein use. Contineing to do further filtering on the 
Log "filtering out VDI's that do not maching to the cleanup criteria; Last Logon and VDI Creted DAte" -Type INFO
Try{
    Foreach($item in $FullList){
        If($item.CitrixLastLogon -lt $dateA){
            $SplitName = $item.FullMachineName.Split("\")
            Try{
                $b = Get-ADcomputer -Identiry $SplitName[1] - Properties created
            }
            Catch{
                Log "Unable get Ad data of: $SplitName[1]" - Type Error
                Log $Error[0] - Type Error
                Exit 5
            }
            If($b.create -lt $dataB){
                $item.MachineName+=$SplitName[1]
                $item.Created+=$b.Created
                $OutputFile+=$item
                Clear-Variable b
            }
        }
    }
    Clear-Variable FullList
    Clear-Variable item
}
Catch{
    Log "Error when creting array to output" -Type Error
    Log $Error[0] -Type Error
    Exit 6
}

#Check if output has more machines than is allowed
$nro = $OutputFile.FullMachineName.$count
If($nro -gt $max){
    Log("Number of machines found is $nro this more that allowed") -Type Warning
    foreach($item in $OutPutList){
        If($i -lt $max){
            $i++
            $OutPutList_reduced+=$item
        }
    }

    Clear-Variable OutPutList
    $OutPutList = $OutPutList_reduced
    $nro = $OutPutList.FullMachineName.$count
    Log("Number of machines for cleanuup is now reduced to = $nro") -Type info

}
Else{
    Log("Number of machines for cleanup = $nro ") -Type Info
}


# Print machine names for log
Write-host ""
$OutPutList | ft MachinesName,Created,CitrixLastLogon
Write-host ""
#Stop - Transcript

#Exporting output to
Log "Outputting results" -Type INFO
Try{
    $OutputFile | Export-Csv -Path $OutputPath -NoTypeInformation -Encokding UTF8 -ErrorAction Stop

}
Catch{
    Log "Unable to output to: $OutputPath" - Type Error
    Log $Error[0] -Type error
    Exit 7
}

#Tag VDI's set set maintenance mode ON and PowerOFF VDI's

Foreach($item in $OutPutList){
    $VDI = $item.MachineName
    Try{
        if($item.session -eq $null){
            Get-BrokerDesktop -MachineName $item.FullMachinename | Add-BrokerTag $tag
            $Check_machine = Get-BrokerDesktop -MachineName $item.FullMachineName | select MachineName,tags
            $Check_machine | add-member -membertype NoteProperty -nam "Tagged" -value ""
            $Check_machine | add-member -membertype NoteProperty -nam "MaintenanceMode_ON" -value ""
            $Check_machine | add-member -membertype NoteProperty -nam "Powered_OFF" -value ""
            If($Check_machine.Tags -notcontains $tag){
                Log "$VDI | ACTION:Tag | Failed" - Type Warning
                $Check_machine.Tagged += "NO"
            }
            Else{
                Log "$VDI | ACTION:Tag | Successfull !" - Type Info
                $Check_machine.Tagged += "YES"
            }
            Clear-Variable Check
            #PowerOff the VDI
            Sleep 2

            $Check = Get-BrokerDesktop -MachineName $item.FullMachineName
                If(($Check.tags -contains $Tag -and $Check.InMaintenaneMode -eq $True)){
                    New-BrokerHostingPowerAction -Action Shutdown -MachineName $item.FullMachineName | Out-null
                    Log "$VDI | ACTION:PowerOFF | Successfully !" -Type Info
                    $Check_machine.Powered_OFF += "YES"
                }
                Else{
                    Log "$VDI | ACTION:PowerOFF | Failed" - Type Warning
                    Log $Error[0] -Type Error
                    $Check_machine.Powered_OFF += "NO"
                }
        }
        Else{
            Log "$item.Machinename has active logon session, skipped" -Type Info
            $Check_machine.Tagged +="NO"
        }

    }Catch{
        Log "Error when reading list of the machine"  -Type Error
        Log $Error[0] -Type Error
        Exit 8
    }
    $ProcessList += $Check_machine
    Clear-Variable Check_machine
    Write-Host ""

}

#Exporting output of actions
Log "Outputting results" -Type INFO
Try{
    $ProcessList | select MachineName,Tagged,MaintenanceMode_ON,Powered_OFF | Export-Csv -Path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    Log "See list of VDI's in $ResultOutputPath" -Type INFO
    Write-host "##LOG_FILE_1 $OutputPath"
    Write-host "##LOG_FILE_2 $ResultOutputPath"
}
Catch{
    Log "Unable to output to: $ResultOutputPath" -Type Error
    Log $Error[0] -Type Error
    Exit 9
}

Log "Script Ended" -Type INFO
Stop-Transcript
