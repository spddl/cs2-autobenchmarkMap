Param(
	[int]$id = -1
)
Set-StrictMode -Version 3.0
$VerbosePreference = 'Continue'

If (!([Security.Principal.WindowsPrincipal][Security.Principal.Windowsidentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
	# Is not an admin, is restarted as admin
	Start-Process powershell.exe -ArgumentList "-NoProfile -NoExit -Command &{cd '$PSScriptRoot'; &'$PSCommandPath' -id $id}" -Verb RunAs
	Exit 1
}

Start-Transcript -Path "$PSScriptRoot\TestCase.log" -Append | Out-Null
Set-Location "$PSScriptRoot"

$RestartNeeded = $true

$TestCases = @()
for ($i = 0; $i -lt 2; $i++) {
 # number of runs
	$TestCases += @{ Value = 'a1841308-3541-4fab-bc81-f71556f20b4a'; Name = 'Power Saver' }
	$TestCases += @{ Value = '381b4222-f694-41f0-9685-ff5bb260df2e'; Name = 'Balanced' }
	$TestCases += @{ Value = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'; Name = 'High Performance' }
	$TestCases += @{ Value = 'ad32feb9-d019-4831-ac93-f0f9acf9bec8'; Name = 'Ultimative Leistung' }
}

if ($id -ne -1) {
	Write-Host "$id/$($TestCases.Count) => $($TestCases[$id].Name)"

	if ($id -eq 0) {
		Set-Content -Path .\_starttime.txt -Value (Get-Date -Format HHmmss) -Force
	} else {
		if (Test-Path .\_starttime.txt -PathType Leaf) {
			$now = [datetime]::ParseExact((Get-Content -Path .\_starttime.txt), 'HHmmss', $null)
			[int32]$completeTime = ($(Get-Date) - $now).TotalSeconds
			[int32]$oneRun = ($completeTime / ($id + 1))
			if ($oneRun -is [int32]) {
				Write-Host 'total estimated time:' (New-TimeSpan -Seconds ($oneRun * $TestCases.Count)).ToString()
				Write-Host 'estimated remaining time:' (New-TimeSpan -Seconds ($oneRun * ($TestCases.Count - $id)))
				Write-Host 'estimated end:' ((Get-Date) + (New-TimeSpan -Seconds ($oneRun * ($TestCases.Count - $id))))
			}
		}
	}

	if ($RestartNeeded) {
		Write-Host 'Sleep 45s'
		Start-Sleep -Seconds 45
	} else {
		Write-Host 'Sleep 5s'
		Start-Sleep -Seconds 5
	}

	Write-Verbose 'Start benchmark'
	Start-Process -FilePath '../benchmark.exe' -ArgumentList "-name `"$($TestCases[$id].Name)_$id`"" -Wait -NoNewWindow
} else {
	if ($RestartNeeded) {
		Write-Verbose 'Autorun'
		New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'TestCase' -Value "Powershell -ExecutionPolicy Bypass -File `"$PSScriptRoot\$($MyInvocation.MyCommand.Name)`" -id 0"

		Write-Verbose 'Reboot'
		Start-Process -FilePath shutdown -ArgumentList '/r', '/t 0'
	}
}

$Id += 1 # check if there is a test case next to it

if ($id -ne $TestCases.Count) {
	Write-Verbose 'new test environment is being prepared'

	# Where the test value will be changed
	Start-Process -FilePath powercfg -ArgumentList '/SETACTIVE', "$($TestCases[$id].Value)" -Wait -NoNewWindow

	Stop-Transcript | Out-Null
	if ($RestartNeeded) {
		# Autorun
		New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'TestCase' -Value "Powershell -ExecutionPolicy Bypass -File `"$PSScriptRoot\$($MyInvocation.MyCommand.Name)`" -Id $Id"

		# Reboot
		Start-Process -FilePath shutdown -ArgumentList '/r', '/t 0' -Wait
	} else {
		. $MyInvocation.MyCommand.Path -Id $Id # next run
	}
}

Remove-Item -Path .\_starttime.txt -ErrorAction SilentlyContinue

Write-Host 'Finish' -ForegroundColor Green
# Shutdown on finish
# Start-Process -FilePath shutdown -ArgumentList "/s", "/t 0" -Wait
Pause