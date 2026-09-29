# dsh-ui-watcher.ps1 —— Windows 侧的常驻者：dsh 一重启，就自动把浏览器接上
#
# ★ 为什么必须有它
#   dsh 的会话 token 每个进程一变。重启后旧标签的 URL 就失效了，而【开浏览器这件事
#   只能由 Windows 侧做】—— 从 WSL 的 systemd 单元里 Start-Process 是开不出来的
#   （非交互式会话，到不了桌面），而它还会退出码 0 骗过调用者。
#
#   结果：agent 重启完自己，回不来，只能等人点桌面。这个脚本补的就是那一环。
#
# ★ 这个文件必须是 UTF-8 **带 BOM**（PowerShell 5.1 靠 BOM 判断编码）。
#   改完确认：head -c3 dsh-ui-watcher.ps1 | od -An -tx1 应为 ef bb bf
#
# ★ 它做什么
#   每 2 秒读一次 WSL 里的 /tmp/dsh-ui-url。内容变了（= dsh 重启了，token 换了）
#   就用 Start-Process 打开。
#
# ★ 它怎么保证不死
#   每一步都 try/catch，任何异常都不退出；每分钟写一次心跳到日志 ——
#   所以万一它死了，日志最后一行就是线索（v1 死过一次，什么都没留下）。
#
# 用法
#   手动:  powershell -NoProfile -ExecutionPolicy Bypass -File <这个文件>
#   常驻:  用同目录的 install-watcher.ps1 装到 Startup（不需要管理员）
#
# 生成者: dsh-wsl-kit 维护者

$ErrorActionPreference = 'Continue'

# 环境发现与它放一起；找不到就退回默认值（这个脚本要能独立跑）
$envFile = Join-Path $PSScriptRoot 'dsh-wsl-env.ps1'
if (Test-Path $envFile) {
  . $envFile
  $distro  = $DshWsl.Distro
  $logFile = Join-Path $env:USERPROFILE 'dsh-ui-watcher.log'
} else {
  $distro  = if ($env:DSH_WSL_DISTRO) { $env:DSH_WSL_DISTRO } else { 'Ubuntu-24.04' }
  $logFile = Join-Path $env:USERPROFILE 'dsh-ui-watcher.log'
}

$urlFile  = '/tmp/dsh-ui-url'
$interval = 2

function Write-Log([string]$msg) {
  try {
    Add-Content -Path $logFile -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $msg) -ErrorAction SilentlyContinue
  } catch { }
}

function Get-DshUrl {
  try {
    $raw = (& wsl.exe -d $distro -- bash -lc "cat $urlFile 2>/dev/null" 2>$null | Out-String)
    $raw = ($raw -replace "`0", '').Trim()
    if ($raw -match 'token=') { return $raw }
  } catch { }
  return ''
}

Write-Log "==== watcher start (pid $PID, distro $distro) ===="

$last = Get-DshUrl
Write-Log ("initial: " + $(if ($last) { $last } else { '(none)' }))
if ($last) {
  try { Start-Process $last; Write-Log 'opened initial' } catch { Write-Log "initial open failed: $_" }
}

$beat = Get-Date
while ($true) {
  try {
    Start-Sleep -Seconds $interval
    $url = Get-DshUrl
    if ($url -and $url -ne $last) {
      $last = $url
      Write-Log "restart detected -> $url"
      try {
        Set-Clipboard -Value $url
        Start-Process $url
        Write-Log 'opened ok'
      } catch { Write-Log "open failed: $_" }
    }
    if (((Get-Date) - $beat).TotalSeconds -ge 60) {
      $beat = Get-Date
      $short = if ($last) { $last.Substring(0, [Math]::Min(40, $last.Length)) } else { '(none)' }
      Write-Log "alive; last=$short"
    }
  } catch {
    Write-Log "loop error (continuing): $_"
    Start-Sleep -Seconds 5
  }
}
