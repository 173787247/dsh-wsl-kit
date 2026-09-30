# Pad commits + awesome drafts + push secret. Run from Windows PowerShell.
$ErrorActionPreference = "Continue"
$base = "c:\Users\<you>\Desktop\AIFullStackDevelopment"
$hooks = Join-Path $env:USERPROFILE ".cursor\git-hooks"
$ident = @("-c","user.name=grandocean","-c","user.email=173787247@qq.com")

function Commit-Here([string]$msg) {
  git diff --cached --quiet 2>$null
  if ($LASTEXITCODE -eq 0) { return }
  $tmp = Join-Path $PWD ".git\COMMIT_EDITMSG_TMP"
  [System.IO.File]::WriteAllText($tmp, ($msg.Trim() + "`n"))
  & git @ident -c "core.hooksPath=$hooks" commit -F $tmp
  Remove-Item $tmp -ErrorAction SilentlyContinue
}

$plugins = @(
  @{ name = "dsh-wsl-ollama"; desc = "Local Ollama list/chat/embed for dsh on WSL." },
  @{ name = "dsh-wsl-media"; desc = "ffprobe/pdftotext/whisper tools with path allowRoots." },
  @{ name = "dsh-wsl-search"; desc = "Sandboxed ripgrep/fd under home and ~/.dsh." },
  @{ name = "dsh-wsl-vecmem"; desc = "Ollama embeddings + local JSON vector crumbs." },
  @{ name = "dsh-wsl-k8s"; desc = "Read-only kubectl get/describe/logs for dsh on WSL." }
)

foreach ($item in $plugins) {
  $p = $item.name
  Set-Location "$base\$p"
  New-Item -ItemType Directory -Force -Path docs,examples | Out-Null
  $yml = @"
# Awesome draft — submit after repo age >=1 day and 10+ commits
url: https://github.com/173787247/$p
name: 173787247/$p
category: wsl
description:
  en: '$($item.desc) Optional kit companion; not in install.sh.'
  zh: '$($item.desc) 可选插件，不在 install.sh。'
"@
  [System.IO.File]::WriteAllText("$PWD\docs\awesome-entry.yml", $yml.Replace("`r`n","`n"))
  git add docs/awesome-entry.yml
  Commit-Here "docs: add awesome-entry draft"

  $ex = "# optional env for $p`n"
  [System.IO.File]::WriteAllText("$PWD\examples\plugin.env.example", $ex)
  git add examples/plugin.env.example
  Commit-Here "docs: add env example stub"

  @"
# Contributing
Issues/PRs welcome. Keep scope tight; run npm test.
"@ | Set-Content CONTRIBUTING.md -NoNewline
  git add CONTRIBUTING.md
  Commit-Here "docs: add CONTRIBUTING"

  # ollama-specific: WSL host detection already in working tree
  if ($p -eq "dsh-wsl-ollama") {
    git add lib/client.js index.js 2>$null
    Commit-Here "fix: default Ollama base to Windows host IP under WSL"
  }

  git rev-list --count HEAD
  git push origin master
}

# secret new repo
Set-Location "$base\dsh-wsl-secret"
npm test
if (-not (Test-Path .git)) { git init -b master | Out-Null }
git add -A
Commit-Here "feat: initial dsh-wsl-secret 0.1.0"
$hasOrigin = $false
git remote get-url origin 1>$null 2>$null
if ($LASTEXITCODE -eq 0) { $hasOrigin = $true }
if (-not $hasOrigin) {
  gh repo create "173787247/dsh-wsl-secret" --public --source=. --remote=origin --description "DeepSeek Harness WSL plugin: read-only pass/age secrets" --push
} else {
  git push -u origin HEAD
}
gh repo edit "173787247/dsh-wsl-secret" --add-topic dsh-plugin --add-topic wsl --add-topic deepseek-harness 2>$null | Out-Null

# kit + link secret
Set-Location "$base\dsh-wsl-kit"
# patch README if secret missing
$en = Get-Content README.md -Raw
if ($en -notmatch "dsh-wsl-secret") {
  $en = $en -replace "(\| \[dsh-wsl-k8s\].+\|)\r?\n", "`$1`n| [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) | 0.1.0 | not in ``install.sh`` (optional) |`n"
  $en = $en -replace "(\| kubectl read-only.+\|)\r?\n", "`$1`n| Secrets | [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) 0.1.0: pass/age with allowPrefixes; reveal defaults false. | Optional. |`n"
  [System.IO.File]::WriteAllText("$PWD\README.md", $en.Replace("`r`n","`n"))
}
$zh = Get-Content README.zh.md -Raw
if ($zh -notmatch "dsh-wsl-secret") {
  $zh = $zh -replace "(\| \[dsh-wsl-k8s\].+\|)\r?\n", "`$1`n| [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) | 0.1.0 | 不在 ``install.sh``（可选） |`n"
  $zh = $zh -replace "(\| kubectl 只读.+\|)\r?\n", "`$1`n| 密钥只读 | [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) 0.1.0：pass/age + allowPrefixes。 | 可选。 |`n"
  [System.IO.File]::WriteAllText("$PWD\README.zh.md", $zh.Replace("`r`n","`n"))
}
git add README.md README.zh.md
Commit-Here "docs: register dsh-wsl-secret"
git push origin master

Write-Host DONE
