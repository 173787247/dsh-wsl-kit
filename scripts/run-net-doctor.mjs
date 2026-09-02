#!/usr/bin/env node
import { readEnv, buildAdvice, formatReport, registryProbeList } from "../../dsh-wsl-net/lib/net.js";

// Quick net_doctor-style probe (same logic as plugin, without dsh host)
async function probe(name, url, timeoutMs = 5000) {
  const started = Date.now();
  try {
    const res = await fetch(url, { method: "GET", redirect: "manual", signal: AbortSignal.timeout(timeoutMs) });
    return { name, url, ok: res.status > 0 && res.status < 500, status: res.status, ms: Date.now() - started };
  } catch (err) {
    return { name, url, ok: false, error: err instanceof Error ? `${err.name}: ${err.message}` : String(err), ms: Date.now() - started };
  }
}

const env = readEnv();
const probes = [
  await probe("deepseek", "https://api.deepseek.com/"),
  ...await Promise.all(registryProbeList(env, "registry").map((s) => probe(s.name, s.url))),
];
const value = {
  advice: buildAdvice(env, probes, "registry", true),
  fix: { steps: ["(script run — see net_doctor in chat for full fix)"], scripts: [] },
  env,
  probes,
};
console.log(formatReport(value));
