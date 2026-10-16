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
# ★ 2026-10-16: 2 秒一次 ⇒ 每次都要起一个 job 进程（见 Invoke-WslCat），太费。
#   token 只在 dsh 重启时变一次，等 6 秒完全够；心跳仍是每 60 秒一行。
$interval = 6

function Write-Log([string]$msg) {
  try {
    Add-Content -Path $logFile -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $msg) -ErrorAction SilentlyContinue
  } catch { }
}

# ★★★ 2026-10-16: 给 wsl.exe 加超时 —— 它是这个脚本唯一的对外调用，而原来没有超时。
#
# 实测（2026-10-16）：心跳在 13:09:29 停写，而日志里【一行错误都没有】。
#   WSL 那一刻停摆，`& wsl.exe ...` 就永远挂住 ⇒ while($true) 卡死在那一行，
#   连 catch 都进不去（根本没抛异常）⇒ WSL 13:15:18 回来之后它也不会自己醒
#   ⇒ 浏览器永不自动重开 ⇒ 人等了 54 分钟，只能手点桌面按钮。
#
# 判据：改成子进程 + WaitForExit(超时)，超时就 Kill 并记一行 TIMEOUT。
#   之后循环一定能继续 ⇒ 心跳一定继续 ⇒ 停摆会【看得见】，而不是变成沉默。
function Invoke-WslCat([string]$path, [int]$timeoutSec = 15) {
  # ★★★ 为什么必须是 Start-Job（2026-10-16 实测三种写法，只有这一种能用）
  #
  #   A  & wsl.exe ... | Out-String
  #      ⇒ 能拿到内容（HAS_TOKEN），但**没有超时**：WSL 停摆时它永远挂住，
  #        while($true) 卡死在这一行，连 catch 都进不去（不抛异常）
  #        ⇒ 实测 13:09:29 心跳停写、日志一行错误都没有；WSL 13:15:18 回来它也没醒
  #        ⇒ 浏览器永不自动重开（人等了 54 分钟只能手点桌面）
  #
  #   B  Start-Process -RedirectStandardOutput + WaitForExit(ms)
  #      ⇒ ★ 拿不到内容：非交互 + 重定向下 wsl.exe 没有控制台，直接把中文错误
  #        写进 stdout（实测 first16 = 0d 4e 58 5b … = UTF-16LE「不存在…」），
  #        116 字节全部不是 URL
  #
  #   C  System.Diagnostics.Process + RedirectStandardOutput + WaitForExit(ms)
  #      ⇒ 同样拿不到（同样没有控制台），实测 NO_TOKEN(len=108)
  #
  #   D  Start-Job + Wait-Job -Timeout + Stop-Job   ← 只有这个同时满足两点
  #      ⇒ 子进程里的 & wsl.exe 照旧能拿到内容（HAS_TOKEN）
  #      ⇒ 而主循环不会被它挂住；超时就 Stop-Job 扔掉，循环继续
  #
  # 代价：每次轮询起一个短命 PowerShell。所以把轮询间隔放宽（见 $interval）。
  $job = $null
  try {
    $job = Start-Job -ScriptBlock {
      param($d, $f)
      (& wsl.exe -d $d -- bash -lc "cat $f 2>/dev/null" 2>$null | Out-String).Trim()
    } -ArgumentList $distro, $path

    if (Wait-Job $job -Timeout $timeoutSec) {
      return [string](Receive-Job $job)
    }
    Write-Log "wsl.exe TIMEOUT ${timeoutSec}s -> job stopped (WSL 停摆?)"
    return ''
  } catch {
    Write-Log "wsl.exe call failed: $_"
    return ''
  } finally {
    if ($job) { Stop-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job -Force -ErrorAction SilentlyContinue }
  }
}

function Get-DshUrl {
  try {
    $raw = (Invoke-WslCat $urlFile | Out-String)
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
