# Create GitHub repos and push five new dsh-wsl plugins + kit docs.
$ErrorActionPreference = "Continue"
$base = "c:\Users\rchua\Desktop\AIFullStackDevelopment"
$hooks = Join-Path $env:USERPROFILE ".cursor\git-hooks"
$plugins = @("dsh-wsl-ollama","dsh-wsl-media","dsh-wsl-search","dsh-wsl-vecmem","dsh-wsl-k8s")
$ident = @("-c","user.name=grandocean","-c","user.email=173787247@qq.com")

foreach ($p in $plugins) {
  Write-Host "======== $p ========"
  Set-Location "$base\$p"
  npm test
  if ($LASTEXITCODE -ne 0) { throw "tests failed: $p" }
  if (-not (Test-Path .git)) { git init -b master | Out-Null }
  git add -A
  git diff --cached --quiet 2>$null
  if ($LASTEXITCODE -ne 0) {
    $tmp = Join-Path $PWD ".git\COMMIT_EDITMSG_TMP"
    [System.IO.File]::WriteAllText($tmp, "feat: initial $p 0.1.0`n")
    & git @ident -c "core.hooksPath=$hooks" commit -F $tmp
    Remove-Item $tmp -ErrorAction SilentlyContinue
  } else {
    Write-Host "nothing to commit"
  }
  $hasOrigin = $false
  git remote get-url origin 1>$null 2>$null
  if ($LASTEXITCODE -eq 0) { $hasOrigin = $true }
  if (-not $hasOrigin) {
    gh repo create "173787247/$p" --public --source=. --remote=origin --description "DeepSeek Harness WSL plugin ($p)" --push
    if ($LASTEXITCODE -ne 0) { throw "gh repo create failed: $p" }
  } else {
    git push -u origin HEAD
    if ($LASTEXITCODE -ne 0) { throw "git push failed: $p" }
  }
  gh repo edit "173787247/$p" --add-topic dsh-plugin --add-topic wsl --add-topic deepseek-harness 2>$null | Out-Null
}

Set-Location "$base\dsh-wsl-kit"
git add README.md README.zh.md
git diff --cached --quiet 2>$null
if ($LASTEXITCODE -ne 0) {
  $tmp = Join-Path $PWD ".git\COMMIT_EDITMSG_TMP"
  [System.IO.File]::WriteAllText($tmp, "docs: register ollama/media/search/vecmem/k8s optional plugins`n")
  & git @ident -c "core.hooksPath=$hooks" commit -F $tmp
  Remove-Item $tmp -ErrorAction SilentlyContinue
  git push origin master
}
Write-Host DONE
