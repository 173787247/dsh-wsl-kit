#!/usr/bin/env node
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

// Resolve the hostsvc module from an installed profile first: the sibling
// checkout is optional, and dsh profiles already carry the package.
const here = dirname(fileURLToPath(import.meta.url));
const profile = process.env.DSH_PROFILE || "web";
const candidates = [
  process.env.DSH_HOSTSVC,
  join(homedir(), ".dsh", "profiles", profile, "node_modules", "dsh-wsl-hostsvc", "lib", "hostsvc.js"),
  join(here, "..", "..", "dsh-wsl-hostsvc", "lib", "hostsvc.js"),
].filter(Boolean);
const found = candidates.find((p) => existsSync(p));
if (!found) {
  console.error(`hostsvc not found; looked in:\n  ${candidates.join("\n  ")}`);
  process.exit(1);
}
const { execute, format } = await import(pathToFileURL(found).href);

const result = await execute({ profile: "all", includeProviders: true });
console.log(format(result));
console.log("\n--- summary ---");
console.log(
  JSON.stringify(
    {
      ok: result.ok,
      windowsHostIp: result.windowsHostIp,
      suggestedBaseURL: result.suggestedBaseURL,
      openServices: (result.services || []).filter((s) => s.open).map((s) => s.id),
      ollamaModels: result.ollamaModels,
      hasProviderYaml: Boolean(result.providerSnippets?.yaml),
    },
    null,
    2,
  ),
);
