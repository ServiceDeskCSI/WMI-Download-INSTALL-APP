# ============================
# Configuration (edit these)
# ============================
[string]$RemoteHost      = "TARGET-PC"                                    # remote host name or IP
[string]$DownloadUrl     = "https://site.com/file.exe"
[string]$FileName      = "file.exe"
[string]$InstallerArgs      = "/S"
[string]$RemoteTempPath  = "C:\Temp"

# -------------------------------------------------------------------
# Get the WMI process class on the remote computer once
# -------------------------------------------------------------------
$procClass = [WmiClass]"\\$RemoteHost\root\cimv2:Win32_Process"

# -------------------------------------------------------------------
# 1) Create remote folders
# -------------------------------------------------------------------
$dirsCmd = "cmd.exe /c mkdir `"$RemoteTempPath`""
$createDirs = $procClass.Create($dirsCmd)
if ($createDirs.ReturnValue -ne 0) {
    Write-Error "❌ Failed to create folders on $RemoteHost (WMI RC=$($createDirs.ReturnValue))"; exit 1
}

# -------------------------------------------------------------------
# 2) Download installer via PowerShell on the remote machine
# -------------------------------------------------------------------
$remoteExePath = "$RemoteTempPath\$FileName"
$downloadCmd = "cmd.exe /c powershell -NoProfile -ExecutionPolicy Bypass -Command `"Invoke-WebRequest -Uri '$DownloadUrl' -OutFile '$remoteExePath'`""

$doDownload = $procClass.Create($downloadCmd)
if ($doDownload.ReturnValue -ne 0) {
    Write-Error "❌ Remote download failed on $RemoteHost (WMI RC=$($doDownload.ReturnValue))"; exit 1
} else {
    Write-Host "✅ Downloaded installer to $remoteExePath on $RemoteHost."
}

# -------------------------------------------------------------------
# 3) Build and launch the installer
# -------------------------------------------------------------------

$installCmd = "cmd.exe /c `"$remoteExePath`" $InstallerArgs

$doInstall = $procClass.Create($installCmd)
if ($doInstall.ReturnValue -eq 0) {
    Write-Host "✅ Installer launched on $RemoteHost (PID: $($doInstall.ProcessId))."
    Write-Host "   Logs: $stdoutLog  |  $stderrLog"
} else {
    Write-Error "❌ Failed to launch installer on $RemoteHost (WMI RC=$($doInstall.ReturnValue))"; exit 1
}
