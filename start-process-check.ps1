[CmdletBinding()]

Param
(
    [string[]]$processes ,
    [switch]$launch ,
    [switch]$auto ,
    [switch]$ignoreFirst ,
    [switch]$install ,
    [switch]$uninstall ,
    [switch]$allUsers ,
    [switch]$silent ,
    [int]$checkPeriod = 300 ,
    [int]$startDelay = 0 ,
    [string]$delimiter = ';' ,
    [string]$valueName = 'Guy''s Process Checker'
)

if( $install -and $uninstall )
{
    Throw 'Can''t install and uninstall in the same invocation'
}

[string]$runKey = $( if( $allUsers ) { 'HKLM' } else { 'HKCU' } ) + ':\Software\Microsoft\Windows\CurrentVersion\Run'

if( $install )
{
    [string]$valueData = ("powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"{0}`" -processes `"{1}`" -checkPeriod {2} -startDelay {3} -delimiter `"{4}`"" -f (& { $myInvocation.ScriptName }) , ($processes -join '","') ,  $checkPeriod , $startDelay , $delimiter )
    if( $launch )
    {
        $valueData += ' -launch'
    }
    if( $auto )
    {
        $valueData += ' -auto'
    }
    if( $ignoreFirst )
    {
        $valueData += ' -ignoreFirst'
    }
    if( $silent )
    {
        $valueData += ' -silent'
    }
    Set-ItemProperty -Path $runKey -Name $valueName -Value $valueData -ErrorAction Stop
    Exit $?
}
elseif( $uninstall )
{
    Remove-ItemProperty -Path $runKey -Name $valueName -ErrorAction Stop
    Exit $?
}

## Workaround for array passed as single element which happens when script not invoked from within PowerShell
if( $processes[0].IndexOf( ',' ) -ge 0 )
{
    $processes = $processes[0] -split ','
}

if( ! $processes -or ! $processes.Count )
{
    Throw "Must specify one or more processes via -processes"
}

[int]$thisSessionId = (Get-Process -Id $pid -ErrorAction Stop).SessionId
[string]$scriptName = Split-Path -Path (& { $myInvocation.ScriptName }) -Leaf
[bool]$first = $true

## in case launched at logon before the monitored processes are launched
Write-Verbose ( "{0} : sleeping for {1} seconds" -f (Get-Date -Format G) , $startDelay )
Start-Sleep -Seconds $startDelay

[void](Add-type -assembly 'Microsoft.VisualBasic')

Write-Verbose ( "{0} : started monitoring {1} processes" -f (Get-Date -Format G) , $processes.Count )

do
{
    ForEach( $process in $processes )
    {
        ## Process may have full path and/or arguments so must strip out for Get-Process
        if( ! ( Get-Process -Name ([io.path]::GetFileNameWithoutExtension( ($process -split $delimiter)[0] )) -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $thisSessionId } ) )
        {
            if( ! $ignoreFirst -or ! $first )
            {
                [string]$theProcess,[string]$arguments = $process -split $delimiter
                [string]$message = ( "{0} : {1} is not running" -f (Get-Date -Format G) , $theProcess )
                Write-Verbose $message
                if( $launch -or $auto )
                {
                    [string]$answer = 'No'
                    if( ! $auto )
                    {
                        $message += '. Start it?'
                        $answer = [Microsoft.VisualBasic.Interaction]::MsgBox( $message , 'YesNo,SystemModal,Exclamation' , $scriptName )
                    }
                    if( $auto -or $answer -eq 'Yes' )
                    {
                        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                        $pinfo.FileName = $theProcess
                        $pinfo.Arguments = $arguments
                        $pinfo.RedirectStandardError = $false
                        $pinfo.RedirectStandardOutput = $false
                        $pinfo.UseShellExecute = $true
                        $pinfo.WindowStyle = 'Normal'
                        $pinfo.CreateNoWindow = $false
                        $newProcess = New-Object System.Diagnostics.Process
                        $newProcess.StartInfo = $pinfo
                        $launched = $null
                        try
                        {
                            $launched = $newProcess.Start()
                        }
                        catch
                        {
                            $launched = $null
                            Write-Verbose $_
                        }
                        if( ! $launched )
                        {
                            if( ! $silent )
                            {
                                [void][Microsoft.VisualBasic.Interaction]::MsgBox( "Failed to launch $($pinfo.FileName) $($pinfo.Arguments) - $($Error[0].Exception.Message)" , 'OKOnly,SystemModal,Exclamation' , $scriptName )
                            }
                        }
                        else
                        {
                            Write-Verbose "`"$($pinfo.FileName)`" launched ok"
                        }
                    }
                }
                elseif( ! $silent )
                {
                    [void][Microsoft.VisualBasic.Interaction]::MsgBox( $message , 'OKOnly,SystemModal,Exclamation' , $scriptName )
                }
            }
        }
    }
    Start-Sleep -Seconds $checkPeriod
    $first = $false
} While( $checkPeriod -gt 0 )