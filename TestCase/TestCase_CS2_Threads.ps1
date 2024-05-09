Param(
	[int]$id = -1
)
Set-StrictMode -Version 3.0
# $VerbosePreference = 'Continue'

If (!([Security.Principal.WindowsPrincipal][Security.Principal.Windowsidentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
	# Is not an admin, is restarted as admin
	Start-Process powershell.exe -ArgumentList "-NoProfile -NoExit -Command &{cd '$PSScriptRoot'; &'$PSCommandPath' -id $id}" -Verb RunAs
	Exit 1
}

Start-Transcript -Path "$PSScriptRoot\TestCase.log" -Append | Out-Null
Set-Location "$PSScriptRoot"

$RestartNeeded = $false

$TestCases = @()
for ($i = 0; $i -lt 2; $i++) {
 # number of runs
	$TestCases += @{ Value = -1; Name = 'without' } # The value that will be changed
	$TestCases += @{ Value = 1; Name = '1' }
	#$TestCases += @{ Value = 2; Name = '2' }
	$TestCases += @{ Value = 4; Name = '4' }
	$TestCases += @{ Value = 7; Name = '7' }
	$TestCases += @{ Value = 8; Name = '8' }
	#$TestCases += @{ Value = 9; Name = '9' }
	$TestCases += @{ Value = 16; Name = '16' }
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
	if ($TestCases[$id].Value -eq -1) {
		Start-Process -FilePath '../benchmark.exe' -ArgumentList "-name `"$($TestCases[$id].Name)_$id`"" -Wait -NoNewWindow
	} else {
		Start-Process -FilePath '../benchmark.exe' -ArgumentList "-name `"$($TestCases[$id].Name)_$id`" -parameter `"-threads $($TestCases[$id].Value) -fps_max 130`"" -Wait -NoNewWindow
	}
} else {
	if ($RestartNeeded) {
		Write-Verbose 'Autorun'
		New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'TestCase' -Value "Powershell -ExecutionPolicy Bypass -File `"$PSScriptRoot\$($MyInvocation.MyCommand.Name)`" -id 0"

		Write-Verbose 'Reboot'
		Start-Process -FilePath shutdown -ArgumentList '/r', '/t 0' -Wait
	}
}

$id += 1 # check if there is a test case next to it

if ($id -ne $TestCases.Count) {
	Write-Verbose 'new test environment is being prepared'

	# Where the test value will be changed

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