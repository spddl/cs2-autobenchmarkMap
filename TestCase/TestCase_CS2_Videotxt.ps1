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
for ($i = 0; $i -lt 3; $i++) {
 # number of runs
	$TestCases += @{ Value = 1; Name = 'Default' } # The value that will be changed
	$TestCases += @{ Value = 2; Name = 'Sample_1' }
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
	if ($TestCases[$id].Value -eq 1) {
		Set-Content -Path 'C:\Program Files (x86)\Steam\userdata\66889288\730\local\cfg\cs2_video.txt' -Force -Value @'
"video.cfg"
{
	"setting.defaultres"		"1024"
	"setting.defaultresheight"		"768"
	"setting.refreshrate_numerator"		"0"
	"setting.refreshrate_denominator"		"0"
	"setting.fullscreen"		"1"
	"setting.mat_vsync"		"0"
	"Version"		"13"
	"VendorID"		"4318"
	"DeviceID"		"7943"
	"setting.cpu_level"		"3"
	"setting.gpu_mem_level"		"3"
	"setting.gpu_level"		"3"
	"setting.knowndevice"		"1"
	"setting.nowindowborder"		"0"
	"setting.fullscreen_min_on_focus_loss"		"1"
	"setting.high_dpi"		"0"
	"setting.coop_fullscreen"		"0"
	"Autoconfig"		"2"
	"setting.shaderquality"		"0"
	"setting.r_aoproxy_enable"		"0"
	"setting.r_aoproxy_min_dist"		"3"
	"setting.r_ssao"		"0"
	"setting.r_csgo_lowend_objects"		"0"
	"setting.r_texturefilteringquality"		"0"
	"setting.r_character_decal_resolution"		"256"
	"setting.r_texture_stream_max_resolution"		"1024"
	"setting.msaa_samples"		"0"
	"setting.r_csgo_cmaa_enable"		"0"
	"setting.csm_max_num_cascades_override"		"2"
	"setting.csm_viewmodel_shadows"		"0"
	"setting.csm_max_shadow_dist_override"		"240"
	"setting.lb_csm_override_staticgeo_cascades"		"1"
	"setting.lb_csm_override_staticgeo_cascades_value"		"-1"
	"setting.lb_sun_csm_size_cull_threshold_texels"		"30.000000"
	"setting.lb_shadow_texture_width_override"		"1280"
	"setting.lb_shadow_texture_height_override"		"1280"
	"setting.lb_csm_cascade_size_override"		"640"
	"setting.lb_barnlight_shadowmap_scale"		"0.250000"
	"setting.lb_csm_draw_alpha_tested"		"1"
	"setting.lb_csm_draw_translucent"		"0"
	"setting.r_particle_cables_cast_shadows"		"0"
	"setting.lb_enable_shadow_casting"		"0"
	"setting.lb_csm_cross_fade_override"		"0.100000"
	"setting.lb_csm_distance_fade_override"		"0.050000"
	"setting.r_particle_shadows"		"0"
	"setting.cl_particle_fallback_base"		"5"
	"setting.cl_particle_fallback_multiplier"		"1.500000"
	"setting.r_particle_max_detail_level"		"0"
	"setting.r_csgo_mboit_force_mixed_resolution"		"1"
	"setting.r_csgo_fsr_upsample"		"0"
	"setting.mat_viewportscale"		"1.000000"
	"setting.sc_hdr_enabled_override"		"3"
	"setting.r_low_latency"		"0"
	"setting.aspectratiomode"		"0"
}
'@
	} else {
		Set-Content -Path 'C:\Program Files (x86)\Steam\userdata\66889288\730\local\cfg\cs2_video.txt' -Force -Value @'
"video.cfg"
{
	"setting.defaultres"		"1024"
	"setting.defaultresheight"		"768"
	"setting.refreshrate_numerator"		"0"
	"setting.refreshrate_denominator"		"0"
	"setting.fullscreen"		"1"
	"setting.mat_vsync"		"0"
	"Version"		"13"
	"VendorID"		"4318"
	"DeviceID"		"7943"
	"setting.cpu_level"		"3"
	"setting.gpu_mem_level"		"3"
	"setting.gpu_level"		"3"
	"setting.knowndevice"		"1"
	"setting.nowindowborder"		"0"
	"setting.fullscreen_min_on_focus_loss"		"1"
	"setting.high_dpi"		"0"
	"setting.coop_fullscreen"		"0"
	"Autoconfig"		"2"
	"setting.shaderquality"		"0"
	"setting.r_aoproxy_enable"		"0"
	"setting.r_aoproxy_min_dist"		"3"
	"setting.r_ssao"		"0"
	"setting.r_csgo_lowend_objects"		"0"
	"setting.r_texturefilteringquality"		"0"
	"setting.r_character_decal_resolution"		"256"
	"setting.r_texture_stream_max_resolution"		"1024"
	"setting.msaa_samples"		"0"
	"setting.r_csgo_cmaa_enable"		"0"
	"setting.csm_max_num_cascades_override"		"2"
	"setting.csm_viewmodel_shadows"		"0"
	"setting.csm_max_shadow_dist_override"		"240"
	"setting.lb_csm_override_staticgeo_cascades"		"1"
	"setting.lb_csm_override_staticgeo_cascades_value"		"-1"
	"setting.lb_sun_csm_size_cull_threshold_texels"		"30.000000"
	"setting.lb_shadow_texture_width_override"		"1280"
	"setting.lb_shadow_texture_height_override"		"1280"
	"setting.lb_csm_cascade_size_override"		"640"
	"setting.lb_barnlight_shadowmap_scale"		"0.250000"
	"setting.lb_csm_draw_alpha_tested"		"1"
	"setting.lb_csm_draw_translucent"		"0"
	"setting.r_particle_cables_cast_shadows"		"0"
	"setting.lb_enable_shadow_casting"		"0"
	"setting.lb_csm_cross_fade_override"		"0.100000"
	"setting.lb_csm_distance_fade_override"		"0.050000"
	"setting.r_particle_shadows"		"0"
	"setting.cl_particle_fallback_base"		"5"
	"setting.cl_particle_fallback_multiplier"		"1.500000"
	"setting.r_particle_max_detail_level"		"0"
	"setting.r_csgo_mboit_force_mixed_resolution"		"1"
	"setting.r_csgo_fsr_upsample"		"0"
	"setting.mat_viewportscale"		"1.000000"
	"setting.sc_hdr_enabled_override"		"3"
	"setting.r_low_latency"		"0"
	"setting.aspectratiomode"		"0"
}
'@
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