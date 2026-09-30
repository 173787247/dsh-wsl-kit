# dsh-wsl-env.ps1 —— Windows 侧的环境发现，被其它 PS1 source
#
# ★ 为什么需要它
#   tray 的那几个 PS1 每份都写死了 `$distro = 'Ubuntu-24.04'` 和
#   `$HOME/src/dsh-wsl-kit/...`。在写它们的那台机器上没问题，别人 clone
#   下来就全是硬的。这里把「这台机器上 WSL 叫什么、用户是谁、kit 在哪」集中发现一次。
#
# ★ 这个文件必须是 UTF-8 **带 BOM**。
#   PowerShell 5.1 靠 BOM 判断编码；没有 BOM 就按系统代码页（简体中文是 GBK）读，
#   中文注释被读碎之后解析器会报「意外的标记 }」—— 看起来像语法错，其实是编码。
#   改这个文件之后请确认 BOM 还在：head -c3 file.ps1 | od -An -tx1 应为 ef bb bf
#
# ★ 两个踩过的坑，都在下面处理了：
#   1. `$home` / `$user` 是 PowerShell 的只读自动变量，不能赋值。用 $wslHome 之类。
#   2. `wsl.exe -l -q` 的输出是 UTF-16，PowerShell 按 UTF-8 读会得到
#      "U<NUL>b<NUL>u<NUL>..."。所以凡是从 wsl.exe 拿字符串，都过 Get-CleanWslText。
#
# 用法（在别的 PS1 里）：
#   . "$PSScriptRoot\dsh-wsl-env.ps1"
#   Invoke-WslBash 'echo $HOME'
#
# 覆盖：设环境变量 DSH_WSL_DISTRO / DSH_WSL_USER / DSH_WSL_KIT 即可。
#
# 生成者: dsh-wsl-kit 维护者

$ErrorActionPreference = 'Continue'

# wsl.exe 的文字输出可能是 UTF-16；去掉 NUL 与首尾空白
function Get-CleanWslText([object]$Raw) {
  if ($null -eq $Raw) { return '' }
  $s = ($Raw | Out-String)
  $s = $s -replace "`0", ''
  return $s.Trim()
}

function Get-DshWslInfo {
  # distro：显式覆盖 > 默认 distro > 列表里第一个 > 兜底
  $wslDistro = $env:DSH_WSL_DISTRO
  if (-not $wslDistro) {
    try {
      $list = Get-CleanWslText (& wsl.exe -l -q 2>$null)
      $first = ($list -split "`r?`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -First 1)
      if ($first) { $wslDistro = $first.Trim() }
    } catch { }
  }
  if (-not $wslDistro) { $wslDistro = 'Ubuntu-24.04' }

  # 用户名与家目录：从 WSL 侧问，而不是猜
  $wslUser = $env:DSH_WSL_USER
  $wslHome = ''
  try {
    if (-not $wslUser) { $wslUser = Get-CleanWslText (& wsl.exe -d $wslDistro -- bash -lc 'id -un' 2>$null) }
    $wslHome = Get-CleanWslText (& wsl.exe -d $wslDistro -- bash -lc 'printf %s "$HOME"' 2>$null)
  } catch { }
  if (-not $wslHome -and $wslUser) { $wslHome = "/home/$wslUser" }

  # kit 路径：显式覆盖 > 常见位置里第一个存在的
  $wslKit = $env:DSH_WSL_KIT
  if (-not $wslKit -and $wslHome) {
    foreach ($cand in @(
      "$wslHome/src/dsh-wsl-kit",
      "$wslHome/dsh-wsl-kit",
      "$wslHome/.local/share/dsh-wsl-kit"
    )) {
      $probe = Get-CleanWslText (& wsl.exe -d $wslDistro -- bash -lc "test -d '$cand' && printf ok" 2>$null)
      if ($probe -eq 'ok') { $wslKit = $cand; break }
    }
  }

  [pscustomobject]@{
    Distro = $wslDistro
    User   = $wslUser
    Home   = $wslHome
    Kit    = $wslKit
    Unc    = "\\wsl.localhost\$wslDistro"
  }
}

$DshWsl = Get-DshWslInfo

function Invoke-WslBash([string]$Command) {
  Get-CleanWslText (& wsl.exe -d $DshWsl.Distro -- bash -lc $Command 2>$null)
}
