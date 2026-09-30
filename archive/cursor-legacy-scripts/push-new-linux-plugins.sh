#!/usr/bin/env bash
# Create GitHub repos and push five new dsh-wsl plugins + kit docs.
set -euo pipefail
BASE="/mnt/c/Users/<you>/Desktop/AIFullStackDevelopment"
HOOKS="${HOME}/.cursor/git-hooks"
plugins=(dsh-wsl-ollama dsh-wsl-media dsh-wsl-search dsh-wsl-vecmem dsh-wsl-k8s)

for p in "${plugins[@]}"; do
  dir="${BASE}/${p}"
  echo "======== ${p} ========"
  cd "$dir"
  npm test
  if [[ ! -d .git ]]; then
    git init -b master
  fi
  git add -A
  git status -sb
  if git diff --cached --quiet; then
    echo "nothing to commit"
  else
    git -c "core.hooksPath=${HOOKS}" commit -m "feat: initial ${p} 0.1.0"
  fi
  if ! git remote get-url origin >/dev/null 2>&1; then
    gh repo create "173787247/${p}" --public --source=. --remote=origin \
      --description "DeepSeek Harness WSL plugin (${p})" --push
  else
    git push -u origin master
  fi
  gh repo edit "173787247/${p}" --add-topic dsh-plugin --add-topic wsl --add-topic deepseek-harness || true
done

cd "${BASE}/dsh-wsl-kit"
git add README.md README.zh.md
if ! git diff --cached --quiet; then
  git -c "core.hooksPath=${HOOKS}" commit -m "docs: register ollama/media/search/vecmem/k8s optional plugins"
  git push origin master
fi
echo DONE
