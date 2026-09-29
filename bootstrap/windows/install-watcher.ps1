# install-watcher.ps1 —— 把 dsh-ui-watcher 装成开机自启
#
# ★ 为什么不用计划任务
#   Register-ScheduledTask 需要管理员权限，普通用户下报「拒绝访问」。
#   放 Startup 文件夹不需要任何权限，效果一样（登录即起）。
#
# ★ 幂等
#   重复跑会覆盖同一个快捷方式，不会装出两份。
#
# ★ 这个文件必须是 UTF-8 **带 BOM**（PowerShell 5.1 靠 BOM 判断编码）。
#
# 用法
#   powershell -NoProfile -ExecutionPolicy Bypass -File install-watcher.ps1
#   powershell ... -File install-watcher.ps1 -Uninstall     # 卸载
#
# 生成者: dsh-wsl-kit 维护者

param(
  [switch]$Uninstall,
  [switch]$Start
)

$ErrorActionPreference = 'Continue'

$here    = $PSScriptRoot
$watcher = Join-Path $here 'dsh-ui-watcher.ps1'
$startup = [Environment]::GetFolderPath('Startup')
$lnk     = Join-Path $startup 'DSH UI Watcher.lnk'

function Find-WatcherProcesses {
  Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object {
      $_.CommandLine -like '*dsh-ui-watcher.ps1*' -and
      $_.CommandLine -notlike '*Get-CimInstance*' -and
      $_.CommandLine -notlike '*-like*'
    }
}

if ($Uninstall) {
  if (Test-Path $lnk) { Remove-Item $lnk -Force; Write-Output "  removed $lnk" }
  Find-WatcherProcesses | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Output ("  stopped pid " + $_.ProcessId)
  }
  Write-Output '  uninstalled'
  exit 0
}

if (-not (Test-Path $watcher)) {
  Write-Output "  FAIL: watcher not found at $watcher"
  exit 1
}

# ── 1 装快捷方式
$sh = New-Object -ComObject WScript.Shell
$s  = $sh.CreateShortcut($lnk)
$s.TargetPath  = 'powershell.exe'
$s.Arguments   = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $watcher + '"'
$s.Description = 'Watch /tmp/dsh-ui-url and open the browser when dsh restarts'
$s.Save()
Write-Output "  autostart: $lnk"

# ── 2 先收掉已有的，避免装出两份（两份会开两次浏览器）
$existing = Find-WatcherProcesses
if ($existing) {
  $existing | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    Write-Output ("  stopped old pid " + $_.ProcessId)
  }
  Start-Sleep -Seconds 2
}

# ── 3 起一份
if ($Start -or $true) {
  Start-Process powershell.exe -ArgumentList @(
    '-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File', $watcher
  )
  Start-Sleep -Seconds 5
  $now = Find-WatcherProcesses
  if ($now) {
    $now | ForEach-Object { Write-Output ("  running pid " + $_.ProcessId) }
  } else {
    Write-Output '  FAIL: started but no process found -- run the watcher by hand to see the error'
    exit 1
  }
}

# ── 4 日志确认
$log = Join-Path $env:USERPROFILE 'dsh-ui-watcher.log'
if (Test-Path $log) {
  Write-Output "  log tail:"
  Get-Content $log -Tail 3 | ForEach-Object { Write-Output ("    " + $_) }
} else {
  Write-Output "  note: $log not written yet (give it a few seconds)"
}
