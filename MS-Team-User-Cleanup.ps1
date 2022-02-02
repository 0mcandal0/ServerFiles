# Hide powershell prompt
Add-Type -Name win -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);' -Namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle,0)

$TeamsUpdateExePath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams', 'Update.exe')
$TeamsAppData = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft', 'Teams')
$TeamsAppData2 = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft Teams')
$TeamsLocalAppData = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams')
$SquirrelTemp = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'SquirrelTemp ')
$TeamsStartMenuShortcut = “c:\users\$env:USERNAME.$env:USERDOMAIN\Start Menu\Programs\Microsoft Corporation”
$TeamsDesktopShortcut = “c:\users\$env:USERNAME.$env:USERDOMAIN\Desktop\Microsoft Teams.lnk"


try
{
    If (Test-Path -Path $TeamsUpdateExePath) {
        Write-Host "Uninstalling Microsoft Teams..."

        # Kill teams.exe
        If (Get-Process -Name Teams -ErrorAction SilentlyContinue) {
            Stop-Process -Name Teams -Force
        }

        # Uninstall app
        $proc = Start-Process -FilePath $TeamsUpdateExePath -ArgumentList "-uninstall -s" -PassThru -ErrorAction SilentlyContinue
        $proc.WaitForExit()

        # Delete Microsoft Teams AppData directory
        If (Test-Path -Path $TeamsAppData) {
            Write-Host "Deleting Microsoft Teams AppData directory..."
            Remove-Item -Path $TeamsAppData -Recurse
        }

        If (Test-Path -Path $TeamsAppData2) {
            Write-Host "Deleting Microsoft Teams AppData directory..."
            Remove-Item -Path $TeamsAppData2 -Recurse
        }

        # Delete Microsoft Teams LocalAppData directory
        If (Test-Path -Path $TeamsLocalAppData) {
            Write-Host "Deleting Microsoft Teams LocalAppData directory..."
            Remove-Item -Path $TeamsLocalAppData -Recurse
        }

        # Delete Microsoft Teams SquirrelTemp directory
        If (Test-Path -Path $SquirrelTemp) {
            Write-Host "Deleting Microsoft Teams SquirrelTemp directory..."
            Remove-Item -Path $SquirrelTemp -Recurse
        }

        # Delete Microsoft Teams start menu shortcut
        If (Test-Path -Path $TeamsStartMenuShortcut) {
            Write-Host "Deleting Microsoft Teams start menu shortcut..."
            Remove-Item -Path $TeamsStartMenuShortcut -Recurse
        }

        # Delete Microsoft Teams desktop shortcut
        If (Test-Path -Path $TeamsDesktopShortcut) {
            Write-Host "Deleting Microsoft Teams desktop shortcut"
            Remove-Item -Path $TeamsDesktopShortcut -Recurse
        }

    }

}
catch
{
    Write-Error -ErrorRecord $_
    Exit 1
}