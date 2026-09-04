#!/usr/bin/env bash
# Offline smoke for deepened verticals.
# Import + pure-function / unit self-check only — no live network, Windows, or GitHub App e2e.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT="${DSH_WSL_ROOT:-$(cd "${KIT_DIR}/.." && pwd)}"

need_dir() {
  local name="$1"
  local path="${ROOT}/${name}"
  if [[ ! -d "${path}" ]]; then
    echo "SKIP ${name}: not found at ${path} (set DSH_WSL_ROOT to sibling checkout root)"
    return 1
  fi
  echo "OK dir ${name}"
  return 0
}

run_tests() {
  local name="$1"
  local path="${ROOT}/${name}"
  echo "=== ${name} npm test ==="
  (cd "${path}" && npm test)
}

echo "smoke-verticals: ROOT=${ROOT}"

failed=0
for repo in \
  dsh-wsl-dns dsh-wsl-clock dsh-wsl-workspace dsh-wsl-distro dsh-wsl-github \
  dsh-wsl-net dsh-wsl-hostsvc dsh-wsl-docker dsh-wsl-tray \
  dsh-wsl-path dsh-wsl-cred dsh-wsl-port dsh-wsl-expose
do
  if need_dir "${repo}"; then
    if ! run_tests "${repo}"; then
      echo "FAIL ${repo}"
      failed=1
    fi
  else
    failed=1
  fi
done

echo "=== pure import self-check (node) ==="
export DSH_SMOKE_ROOT="${ROOT}"
node --input-type=module <<'EOF'
import { pathToFileURL } from "node:url";
import { join } from "node:path";

const root = process.env.DSH_SMOKE_ROOT;
const checks = [];

async function load(rel) {
  return import(pathToFileURL(join(root, rel)).href);
}

const dns = await load("dsh-wsl-dns/lib/dns.js");
const annotated = dns.annotateResults([
  { host: "github.com", wsl: ["1.1.1.1"], windows: ["1.0.0.1"] },
]);
if (!annotated[0]?.mismatch) throw new Error("dns annotateResults expected mismatch");
checks.push("dns");

const clock = await load("dsh-wsl-clock/lib/clock.js");
const skew = clock.computeSkew(0, 60_000, 30);
if (skew.level !== "fail") throw new Error("clock computeSkew expected fail");
checks.push("clock");

const ws = await load("dsh-wsl-workspace/lib/workspace.js");
const classified = ws.classifyWorkspacePath("/mnt/c/Users/u/Desktop/proj", {
  home: "/home/u",
  exists: () => false,
});
if (classified.kind !== "windows_user_folder") {
  throw new Error(`workspace kind expected windows_user_folder, got ${classified.kind}`);
}
checks.push("workspace");

const distro = await load("dsh-wsl-distro/lib/distro.js");
const parsed = distro.parseWslListVerbose(
  "  NAME            STATE           VERSION\n* Ubuntu          Running         2\n  Debian          Stopped         2\n",
);
if (!parsed.distros?.some((d) => d.name === "Ubuntu" && d.isDefault)) {
  throw new Error("distro parseWslListVerbose failed");
}
checks.push("distro");

const gh = await load("dsh-wsl-github/lib/github.js");
const env = gh.detectGithubEnvFile({ home: "/tmp/x", exists: () => false });
const advice = gh.buildAppHint(
  { mode: "missing", appIdSet: false, privateKeySet: false },
  { envFile: env },
);
if (!advice.some((t) => /cred_hint/i.test(t))) throw new Error("github advice missing role split");
checks.push("github");

const net = await load("dsh-wsl-net/lib/net.js");
const raw = Buffer.from("NODE_USE_ENV_PROXY=\0HTTP_PROXY=http://127.0.0.1:9\0");
const got = net.readProcEnv(1, { readFileSyncFn: () => raw });
if (!got.env || got.env.HTTP_PROXY !== "http://127.0.0.1:9") throw new Error("net readProcEnv failed");
checks.push("net");

const host = await load("dsh-wsl-hostsvc/lib/providers.js");
if (host.compareCtx(131072, 8192).ctxMatch !== "mismatch") throw new Error("hostsvc compareCtx failed");
const models404 = await host.fetchOpenAiModels("http://127.0.0.1:8000/v1", {
  fetchFn: async () => ({ ok: false, status: 404, json: async () => ({}) }),
});
if (models404.apiReady !== false || models404.tcpOpen !== true) {
  throw new Error("hostsvc fetchOpenAiModels 404 apiReady failed");
}
checks.push("hostsvc");

const dock = await load("dsh-wsl-docker/lib/docker.js");
if (!dock.containerHasGpuRuntime({ HostConfig: { Runtime: "nvidia" } })) {
  throw new Error("docker containerHasGpuRuntime failed");
}
const hints404 = dock.buildVllmHints([], {
  daemonOk: true,
  portHealth: { ok: false, status: 404, url: "http://127.0.0.1:8000/v1/models", error: "" },
});
if (!hints404.some((h) => /404/.test(h))) throw new Error("docker 404 hint failed");
checks.push("docker");

const port = await load("dsh-wsl-port/lib/port.js");
if (!port.buildUiPlaybook(3081).some((s) => /check-dsh-health/i.test(s))) {
  throw new Error("port buildUiPlaybook failed");
}
checks.push("port");

const tray = await load("dsh-wsl-tray/lib/tray.js");
const kit = tray.resolveKitPath({
  kitPath: "/kit",
  exists: (p) => String(p).includes("/kit/scripts/restart-dsh-web.sh"),
  candidates: [],
});
if (!kit.ok) throw new Error("tray resolveKitPath failed");
checks.push("tray");

console.log("pure-check ok:", checks.join(", "));
EOF

if [[ "${failed}" -ne 0 ]]; then
  echo "smoke-verticals: some sibling repos missing or tests failed"
  exit 1
fi
echo "smoke-verticals: all green"
