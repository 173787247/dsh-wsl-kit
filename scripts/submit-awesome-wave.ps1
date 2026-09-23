# Submit one awesome wave from kit drafts. Usage: .\submit-awesome-wave.ps1 B
param(
  [Parameter(Mandatory = $true)][string]$Wave,
  [string]$Work = "C:\Users\rchua\AppData\Local\Temp\awesome-dsh-plugin-submit",
  [string]$KitQ = "c:\Users\rchua\Desktop\AIFullStackDevelopment\dsh-wsl-kit\docs\awesome-queue"
)
$ErrorActionPreference = "Continue"
$hooks = Join-Path $env:USERPROFILE ".cursor\git-hooks"
$waveDir = Join-Path $KitQ ("wave-" + $Wave)
if (-not (Test-Path $waveDir)) { throw "missing $waveDir" }
$files = Get-ChildItem $waveDir -Filter "*.yml"
if (-not $files) { throw "no yml in $waveDir" }

if (-not (Test-Path $Work)) {
  git clone --depth 1 https://github.com/173787247/awesome-dsh-plugin.git $Work
}
Set-Location $Work
git remote add upstream https://github.com/awesome-dsh-plugin/awesome-dsh-plugin.git 2>$null
git fetch upstream main
git checkout -B main upstream/main
git push origin main --force 2>$null | Out-Null

$branch = "add-173787247-wave-$Wave"
git checkout -B $branch
Copy-Item (Join-Path $waveDir "*.yml") "data\plugins\" -Force
$names = @()
foreach ($f in $files) {
  git add ("data/plugins/" + $f.Name)
  $names += ($f.BaseName -replace '^173787247__','')
}
$title = "Add 173787247 " + ($names -join " / ")
$msg = "$title`n`nWave $Wave optional WSL plugins for awesome-dsh-plugin.`n"
$tmp = Join-Path $env:TEMP "awesome-wave-$Wave.txt"
[IO.File]::WriteAllText($tmp, $msg, [Text.UTF8Encoding]::new($false))
if (Test-Path $hooks) { git -c "core.hooksPath=$hooks" commit -F $tmp } else { git commit -F $tmp }
$b = git log -1 --format=%B
if ($b -match '(?i)Co-authored-by:\s*Cursor|cursoragent@cursor\.com|Made-with:\s*Cursor') {
  $clean = ($b -split "`n" | Where-Object { $_ -notmatch '(?i)Co-authored-by:\s*Cursor|cursoragent@cursor\.com|Made-with:\s*Cursor' }) -join "`n"
  [IO.File]::WriteAllText($tmp, $clean.TrimEnd() + "`n", [Text.UTF8Encoding]::new($false))
  git -c core.hooksPath=/dev/null commit --amend -F $tmp
}
git push -u origin $branch --force

$body = @"
## Summary
$(($names | ForEach-Object { "- Add ``$_``" }) -join "`n")

Category: ``wsl``. YAML only.

Wave **$Wave** from dsh-wsl-kit awesome queue.
"@
$bodyFile = Join-Path $env:TEMP "awesome-body-$Wave.md"
[IO.File]::WriteAllText($bodyFile, $body, [Text.UTF8Encoding]::new($false))
$url = gh pr create --repo awesome-dsh-plugin/awesome-dsh-plugin --head "173787247:$branch" --title $title --body-file $bodyFile
Write-Output $url
