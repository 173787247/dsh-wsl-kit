#!/usr/bin/env node
import { execute, format } from "../../dsh-wsl-docker/lib/docker.js";

const result = await execute({ focus: "all" });
console.log(format(result));
console.log("\n--- summary ---");
console.log(
  JSON.stringify(
    {
      ok: result.ok,
      serverVersion: result.serverVersion,
      gpuHint: result.gpuHint,
      containers: (result.containers || []).length,
      vllmHints: result.vllmHints?.length ?? 0,
    },
    null,
    2,
  ),
);
