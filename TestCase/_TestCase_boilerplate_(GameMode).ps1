Param(
	[int]$id = -1
)
Set-StrictMode -Version 3.0
$VerbosePreference = 'Continue'

# Check if the current user is an administrator, if not, restart script as admin
If (!([Security.Principal.WindowsPrincipal][Security.Principal.Windowsidentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
	Start-Process powershell.exe -ArgumentList "-NoProfile -NoExit -Command &{cd '$PSScriptRoot'; &'$PSCommandPath' -id $id}" -Verb RunAs
	Exit 1
}
# Start logging transcript
Start-Transcript -Path "$PSScriptRoot\TestCase.log" -Append | Out-Null

# Set current location to script root directory
Set-Location "$PSScriptRoot"

# Variable to indicate if restart is needed
$RestartNeeded = $false

# Array to store test cases
$TestCases = @()
for ($i = 0; $i -lt 3; $i++) {
 # 3 Trails
	$TestCases += @{ Value = 1; Name = 'GameMode_On' } # The value that will be changed
	$TestCases += @{ Value = 0; Name = 'GameMode_Off' }
}

if ($id -ne -1) {
	Write-Host "$id/$($TestCases.Count) => $($TestCases[$id].Name)"

	if ($id -eq 0) {
		# Store start time for the first test case
		Set-Content -Path .\_starttime.txt -Value (Get-Date -Format HHmmss)
	} else {
		# Calculate estimated completion time for each test case
		$now = [datetime]::ParseExact((Get-Content -Path .\_starttime.txt), 'HHmmss', $null)
		[int32]$completeTime = ($(Get-Date) - $now).TotalSeconds
		[int32]$oneRun = ($completeTime / ($id + 1))
		if ($oneRun -is [int32]) {
			Write-Host 'total estimated time:' (New-TimeSpan -Seconds ($oneRun * $TestCases.Count)).ToString()
			Write-Host 'estimated remaining time:' (New-TimeSpan -Seconds ($oneRun * ($TestCases.Count - $id)))
			Write-Host 'estimated end:' ((Get-Date) + (New-TimeSpan -Seconds ($oneRun * ($TestCases.Count - $id))))
		}
	}

	# Delay before starting benchmark
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
		Write-Verbose 'Autorun next time'
		# Add script to run once on user login
		New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'TestCase' -Value "Powershell -ExecutionPolicy Bypass -File `"$PSScriptRoot\$($MyInvocation.MyCommand.Name)`" -id 0"

		Write-Verbose 'Restart system'
		Start-Process -FilePath shutdown -ArgumentList '/r', '/t 0' -Wait
	}
}

# Increment test case ID
$id += 1

if ($id -ne $TestCases.Count) {
	Write-Verbose 'new test environment is being prepared'

	# Change test value in registry
	Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value $TestCases[$id].Value -Type DWord
 
	# Stop logging transcript
	Stop-Transcript | Out-Null
	if ($RestartNeeded) {
		# Add script to run once on user login
		New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'TestCase' -Value "Powershell -ExecutionPolicy Bypass -File `"$PSScriptRoot\$($MyInvocation.MyCommand.Name)`" -id $id"

		# Restart system
		Start-Process -FilePath shutdown -ArgumentList '/r', '/t 0' -Wait
	} else {
		. $MyInvocation.MyCommand.Path -id $id # next run
	}
}

# Clean up
Remove-Item -Path .\_starttime.txt -ErrorAction SilentlyContinue

Write-Host 'Finish' -ForegroundColor Green

# Shutdown on finish
# Start-Process -FilePath shutdown -ArgumentList "/s", "/t 0" -Wait

# Pause script execution
Pause