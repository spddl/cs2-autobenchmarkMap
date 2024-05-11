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
 # https://developer.valvesoftware.com/wiki/Command_line_options#Command-Line_Parameters_3
 # https://github.com/bigfinfrank/cs2/tree/30571f8120dbf03fd3d977a5bf1d1deda1cdaaa4?tab=readme-ov-file#launch-options
	$TestCases += @{ Value = '-nojoy'; Name = 'nojoy' } # The value that will be changed
	$TestCases += @{ Value = '-high' ; Name = 'high' }
	$TestCases += @{ Value = '-realtime'; Name = 'realtime' }
	$TestCases += @{ Value = '-d3d9ex'; Name = 'd3d9ex' }
	$TestCases += @{ Value = '-limitvsconst'; Name = 'limitvsconst' }
	$TestCases += @{ Value = '-nopreload'; Name = 'nopreload' }
	$TestCases += @{ Value = '-nostyle'; Name = 'nostyle' }
	$TestCases += @{ Value = '-softparticledefaultoff'; Name = 'softparticledefaultoff' }
	$TestCases += @{ Value = '-softparticlesdefaultoff'; Name = 'softparticlesdefaultoff' }
	$TestCases += @{ Value = '+r_dynamic 0'; Name = 'r_dynamic' }
	$TestCases += @{ Value = '+r_drawparticles 0'; Name = 'r_drawparticles' }
	$TestCases += @{ Value = '-threads 8'; Name = 'threads 8' }
	$TestCases += @{ Value = '+mat_disable_fancy_blending 1'; Name = 'mat_disable_fancy_blending' }
	$TestCases += @{ Value = '-mainthreadpriority 2' ; Name = 'mainthreadpriority 2' }
	$TestCases += @{ Value = '-set_power_qos_disable' ; Name = 'set_power_qos_disable' }
	$TestCases += @{ Value = '-sse4' ; Name = 'sse4' }
	$TestCases += @{ Value = '-vulkan'; Name = 'vulkan' }
	$TestCases += @{ Value = '-gpuraytracing'; Name = 'gpuraytracing' }
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
	Start-Process -FilePath '../benchmark.exe' -ArgumentList "-name `"$($id)_$($TestCases[$id].Name)`" -parameter `"$($TestCases[$id].Value)`"" -Wait -NoNewWindow
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