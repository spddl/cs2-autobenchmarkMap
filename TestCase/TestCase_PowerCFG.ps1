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

$RestartNeeded = $false

&powercfg /setactive 77777777-7777-7777-7777-777777777777
&powercfg /DELETE 88888888-8888-8888-8888-888888888888
&powercfg /import 'C:\ProgramData\KirbyOS\Power Plans\Kirby Powerplan v1.2.pow' 88888888-8888-8888-8888-888888888888
&powercfg /setactive 88888888-8888-8888-8888-888888888888

<#
https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/configuration-for-hetero-power-scheduling-heterodecreasethreshold
powercfg /setacvalueindex scheme_current sub_processor HETEROPOLICY 0
	HeteroDecreaseThreshold is a four-byte unsigned integer where each byte represents a threshold in percentage. See HeteroIncreaseThreshold for configuring the thresholds.
	https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/configuration-for-hetero-power-scheduling-heteroincreasethreshold

https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/configuration-for-hetero-power-scheduling-schedulingpolicy
powercfg /setacvalueindex scheme_current sub_processor SCHEDPOLICY 1
	0 All processors
	1 Performant processors
	2 Prefer performant processors
	3 Efficient processors
	4 Prefer efficient processors
	5 Automatic

https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/configuration-for-hetero-power-scheduling-shortschedulingpolicy
powercfg /setacvalueindex scheme_current sub_processor SHORTSCHEDPOLICY 3
	bae08b81-2d5e-4688-ad6a-13243356654b
	0 All processors
	1 Performant processors
	2 Prefer performant processors
	3 Efficient processors
	4 Prefer efficient processors
	5 Automatic
#>

$TestCases = @()
for ($i = 0; $i -lt 2; $i++) {
 # number of runs
	$TestCases += @{ Value = @('HETEROPOLICY 4', 'SCHEDPOLICY 5', 'SHORTSCHEDPOLICY 5'); Name = '4,5,5' } # Default
	$TestCases += @{ Value = @('HETEROPOLICY 0', 'SCHEDPOLICY 1', 'SHORTSCHEDPOLICY 3'); Name = '0,1,3' }

	$TestCases += @{ Value = @('HETEROPOLICY 1', 'SCHEDPOLICY 5', 'SHORTSCHEDPOLICY 2'); Name = '1,5,2' }
	$TestCases += @{ Value = @('HETEROPOLICY 1', 'SCHEDPOLICY 2', 'SHORTSCHEDPOLICY 5'); Name = '1,2,5' }

	$TestCases += @{ Value = @('HETEROPOLICY 4', 'SCHEDPOLICY 3', 'SHORTSCHEDPOLICY 2'); Name = '4,3,2' }
	$TestCases += @{ Value = @('HETEROPOLICY 4', 'SCHEDPOLICY 2', 'SHORTSCHEDPOLICY 3'); Name = '4,2,3' }

	$TestCases += @{ Value = @('HETEROPOLICY 3', 'SCHEDPOLICY 4', 'SHORTSCHEDPOLICY 1'); Name = '3,4,1' }
}

if ($id -ne -1) {
	Write-Host "$id/$($TestCases.Count) => $($TestCases[$id].Name)"

	if ($id -eq 0) {
		Set-Content -Path .\_starttime.txt -Value (Get-Date -Format HHmmss)
	} else {
		$now = [datetime]::ParseExact((Get-Content -Path .\_starttime.txt), 'HHmmss', $null)
		[int32]$completeTime = ($(Get-Date) - $now).TotalSeconds
		[int32]$oneRun = ($completeTime / ($id + 1))
		if ($oneRun -is [int32]) {
			Write-Host 'total estimated time:' (New-TimeSpan -Seconds ($oneRun * $TestCases.Count)).ToString()
			Write-Host 'estimated remaining time:' (New-TimeSpan -Seconds ($oneRun * ($TestCases.Count - $id)))
			Write-Host 'estimated end:' ((Get-Date) + (New-TimeSpan -Seconds ($oneRun * ($TestCases.Count - $id))))
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
		# Autorun
		New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'TestCase' -Value "Powershell -ExecutionPolicy Bypass -File `"$PSScriptRoot\$($MyInvocation.MyCommand.Name)`" -id 0"

		# Reboot
		Start-Process -FilePath shutdown -ArgumentList '/r', '/t 0' -Wait
	}
}

$id += 1 # check if there is a test case next to it

if ($null -ne $TestCases[$id]) {
	# new test environment is being prepared

	# Where the test value will be changed
	foreach ($Value in $TestCases[$id].Value) {
		Start-Process -FilePath powercfg -ArgumentList "/setacvalueindex scheme_current sub_processor $Value" -Wait -NoNewWindow
	}

	Stop-Transcript | Out-Null
	if ($RestartNeeded) {
		# Autorun
		New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'TestCase' -Value "Powershell -ExecutionPolicy Bypass -File `"$PSScriptRoot\$($MyInvocation.MyCommand.Name)`" -id $id"

		# Reboot
		Start-Process -FilePath shutdown -ArgumentList '/r', '/t 0' -Wait
	} else {
		. $MyInvocation.MyCommand.Path -id $id # next run
	}
}

Remove-Item -Path .\_starttime.txt -ErrorAction SilentlyContinue

Write-Host 'Finish' -ForegroundColor Green
# Shutdown on finish
# Start-Process -FilePath shutdown -ArgumentList "/s", "/t 0" -Wait
Pause