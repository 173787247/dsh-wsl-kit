#!/usr/bin/env node
import { execute, format } from "../../dsh-wsl-hostsvc/lib/hostsvc.js";

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
