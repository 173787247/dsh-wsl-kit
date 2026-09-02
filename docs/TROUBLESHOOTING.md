# WSL + dsh troubleshooting

When the agent runs in WSL and the browser is on Windows, failures are often cross-system networking—not dsh itself. Match symptoms to tools; avoid blind restarts.

## Quick map

| Symptom | Tool first | Plugin |
|---------|------------|--------|
| Local LLM unreachable / ctx errors | `host_reach` | [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) |
| DeepSeek API / npm timeout | `net_doctor` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| ModelScope / Hugging Face | `net_doctor` target=`registry` | dsh-wsl-net |
| git push / GitHub 401 | `github_app_hint` + `cred_doctor` | github + cred |
| DNS weirdness | `wsl_dns` | dsh-wsl-dns |
| TLS clock skew | `wsl_clock` | dsh-wsl-clock |
| Browser cannot open WSL dsh web | `wsl_expose` advise | dsh-wsl-expose |

See [TROUBLESHOOTING.zh.md](./TROUBLESHOOTING.zh.md) for the full fault tree (中文).

## Recommended install for local LLM

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=llm bash
```

Restart `dsh web` and open a **new session** after install.
