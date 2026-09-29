#!/usr/bin/env bash
# 证伪 check-recovery.sh：拿已知坏输入去试它，看它会不会报错。
#
# 为什么需要这个：README 里曾写着「9 项，每项都被坏输入证伪过」，而实际上只证伪过
# 一项（pkill）。另外那些从没拿坏输入试过。**一条没被证伪过的检查，不算检查。**
#
# ★ 判据是反的：这个脚本【期望】check-recovery.sh 失败。
#   如果某个检查在坏输入下仍然通过，那才是本脚本要报的错。
#
# 用法：
#   bash scripts/falsify-recovery.sh
# 退出码：0 每个探针都被证伪了 · 1 有探针在坏输入下仍然通过（即那条检查是空的）
set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX=$(mktemp -d /tmp/falsify-recovery-XXXXXX)
trap 'rm -rf "$SANDBOX"' EXIT

pass=0; fail=0
probe() {
  local name="$1" expect="$2"   # expect = bad 表示"这个检查应该失败"
  shift 2
  local out rc
  out=$("$@" 2>&1); rc=$?
  # check-recovery.sh 的退出码：有 FAIL 时非零
  local saw_fail=0
  grep -q '^  FAIL' <<<"$out" && saw_fail=1
  if [ "$saw_fail" = "1" ]; then
    printf '  ✓ %-46s 坏输入被抓到\n' "$name"
    pass=$((pass+1))
  else
    printf '  ★ %-46s 坏输入【没】被抓到 —— 这条检查是空的\n' "$name"
    fail=$((fail+1))
  fi
}

printf '════ 证伪 check-recovery.sh ════\n'
printf '  沙箱 %s\n\n' "$SANDBOX"

# ── 探针 1：~/.dsh/.env 里有 DSH_ 前缀的变量 ────────────────────────────────
# 那条检查读的是 $HOME/.dsh/.env。用一个假的 HOME 造坏输入。
mk_home() {
  local h="$1"; mkdir -p "$h/.dsh/tray"
  # 把线上 tray 复制进去，免得别的检查全挂（那会掩盖这一条）
  cp -r "$HOME/.dsh/tray/." "$h/.dsh/tray/" 2>/dev/null || true
}
H1="$SANDBOX/home1"; mk_home "$H1"
printf 'DSH_SECRET_TEST=1\n' > "$H1/.dsh/.env"
probe ".env 里有 DSH_ 前缀变量" bad env HOME="$H1" DSH_WSL_KIT="$KIT" bash "$KIT/scripts/check-recovery.sh"

# ── 探针 2：托盘 PS1 不能解析 ──────────────────────────────────────────────
H2="$SANDBOX/home2"; mk_home "$H2"
# ★ 不看线上有没有 PS1 —— 自己造一个。检查本来就是要读它，造不出来就说明探针写错了。
mkdir -p "$H2/.dsh/tray"
# ★ 必须用检查真正会看的那个文件名 —— 第一版我用了 dsh-tray.ps1，
#   而检查只看三个固定的名字，于是探针形同虚设（它自己也会 SKIP）。
printf 'function Broken { \n' > "$H2/.dsh/tray/start-dsh-web.ps1"    # 少一个 }
# ★ 必须注入 TRAY_UNC：那条检查原本把路径写死成 $USER 的位置，
  #   任何沙箱坏输入都碰不到它。加 TRAY_UNC 之后它才可被证伪。
_unc="\\\\wsl.localhost\\$(wslpath -w / 2>/dev/null | awk -F'\\\\' '{print $4}')\\home\\$USER\\.dsh\\tray"
# 上面是真实路径；探针要的是沙箱的 —— 用 Windows 能看到的 /tmp 路径
_unc_tmp="$(wslpath -w "$H2/.dsh/tray" 2>/dev/null | tr -d '\r')"
probe "托盘 PS1 语法坏" bad env HOME="$H2" TRAY_UNC="$_unc_tmp" DSH_WSL_KIT="$KIT" bash "$KIT/scripts/check-recovery.sh"

# ── 探针 3：重启脚本缺 interop PATH ────────────────────────────────────────
H3="$SANDBOX/home3"; mk_home "$H3"
K3="$SANDBOX/kit3"; mkdir -p "$K3/scripts"
# 复制重启脚本，但把恢复 /mnt/c PATH 那段删掉
if [ -f "$KIT/scripts/restart-dsh-web.sh" ]; then
  grep -v '/mnt/c/WINDOWS' "$KIT/scripts/restart-dsh-web.sh" > "$K3/scripts/restart-dsh-web.sh"
  cp "$KIT/scripts/"*.inc.sh "$K3/scripts/" 2>/dev/null || true
  probe "重启脚本缺 interop PATH" bad env HOME="$H3" DSH_WSL_KIT="$K3" bash "$KIT/scripts/check-recovery.sh"
fi

# ── 探针 4：vecmem 的 items 与字节数脱钩 ───────────────────────────────────
# 那条检查读 $HOME/.dsh/vecmem/store.json + .f32。造一个 dims 缺失的。
H4="$SANDBOX/home4"; mk_home "$H4"; mkdir -p "$H4/.dsh/vecmem"
printf '{"version":1,"items":[{"text":"x"}]}' > "$H4/.dsh/vecmem/store.json"   # ★ 没有 dims
: > "$H4/.dsh/vecmem/store.vectors.f32"
probe "vecmem 的 store.json 没有 dims" bad env HOME="$H4" DSH_WSL_KIT="$KIT" bash "$KIT/scripts/check-recovery.sh"

# ── 探针 5：vecmem 的字节数对不上 ─────────────────────────────────────────
H5="$SANDBOX/home5"; mk_home "$H5"; mkdir -p "$H5/.dsh/vecmem"
printf '{"version":2,"dims":4,"items":[{"text":"a"},{"text":"b"}]}' > "$H5/.dsh/vecmem/store.json"
head -c 16 /dev/zero > "$H5/.dsh/vecmem/store.vectors.f32"    # 2*4*4=32 字节，只给 16
probe "vecmem 的 f32 字节数不足" bad env HOME="$H5" DSH_WSL_KIT="$KIT" bash "$KIT/scripts/check-recovery.sh"

printf '\n════ %s 个探针被抓到 · %s 个没被抓到 ════\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
  printf '★ 有检查在坏输入下仍然通过。那条检查是空的 —— 这正是它存在的理由。\n'
  exit 1
fi
printf '每个探针都被证伪了 —— 这些检查不是空的。\n'
