# WSL + dsh 故障树

Agent 在 WSL、浏览器在 Windows 时，问题常出在「跨系统网络」而不是 dsh 本身。按症状选工具，不要盲重启。

## 快速对照

| 症状 | 先跑什么 | 插件 |
|------|----------|------|
| DeepSeek Search / `TypeError: fetch failed` | `net_doctor`（确认 **dsh 进程** `NODE_USE_ENV_PROXY=1` + 代理端口 OPEN）→ `check-dsh-health.sh` / `restart-dsh-web.sh` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| GPU / 显存 / 推理端口互斥 | `gpu_doctor` | [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) |
| Ollama / 本地模型 API 404、连不上、ctx 报错 | `host_reach`（看 `ctxReports` / `ctxMatch`） | [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) |
| settings `contextWindow` > Ollama 真实 `num_ctx` | `host_reach` → 降 settings 或抬 `OLLAMA_NUM_CTX` | dsh-wsl-hostsvc |
| DeepSeek API / npm install 超时 | `net_doctor` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| ModelScope / Hugging Face 拉模型失败 | `net_doctor` target=`registry` | dsh-wsl-net |
| git push / GitHub API 401 | `github_app_hint` + `cred_doctor` | github + cred |
| DNS 解析怪、证书像被劫持 | `dns_doctor` | [dsh-wsl-dns](https://github.com/173787247/dsh-wsl-dns) |
| WSL 与 Windows 对同一主机 A 记录不一致 | `dns_doctor`（对比两侧；再 `net_doctor` / `wslconfig_hint`） | dsh-wsl-dns |
| TLS / 证书时间错误；休眠后 skew；GitHub App JWT 异常 | `clock_doctor`（必要时 `wsl --shutdown`） | [dsh-wsl-clock](https://github.com/173787247/dsh-wsl-clock) |
| 仓库 / 工作区开在 Desktop、Downloads（`/mnt/c/...`） | `wsl_workspace` + `mnt_doctor` | [dsh-wsl-workspace](https://github.com/173787247/dsh-wsl-workspace) |
| 浏览器打不开 WSL 里的 dsh web | 见下方 §0；再 `wsl_expose` | [dsh-wsl-expose](https://github.com/173787247/dsh-wsl-expose) |
| Agent 乱用 Windows 路径 | （自动） | [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) |
| `CONTEXT_WINDOW_EXCEEDED` / prompt 过大 | settings `contextWindow` 与 Ollama `num_ctx` 对齐（插件多时建议 ≥32768） | hostsvc + settings |
| 工具行为像旧版 / 列表缺插件 | `bash scripts/check-plugin-versions.sh` → `dsh plugin add` + `restart-dsh-web.sh` | [dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit) |

---

## 0. Windows 浏览器 ↔ WSL 里的 dsh（必读）

dsh **禁止** `--host 0.0.0.0`，只绑 `127.0.0.1:3080`。Windows 侧请用中继：

```text
ERR_CONNECTION_REFUSED / 空白
  → 是否开了 :3000（GenericAgent）或只开了 :3080？
  → bash scripts/restart-dsh-web.sh
  → 浏览器打开 http://127.0.0.1:3081/

ERR_CONNECTION_RESET（中继在、dsh 挂）
  → 同上重启；确认 ss 里 3080 与 3081 都在听

/api 403（曾改写 Host → Origin 不一致）
  → 不要改写 Host；中继保持 Host: 127.0.0.1:3081 + --trusted-host
```

---

## 1. 本地 LLM（Ollama / LM Studio / vLLM / Unsloth）

```text
host_reach (profile=all)
  ├─ 全 closed → Windows 上服务没开 / 只绑 127.0.0.1 且 NAT 模式
  │     → OLLAMA_HOST=0.0.0.0:11434 或 LM Studio「局域网」
  │     → 或 .wslconfig 开 networkingMode=mirrored
  ├─ 只有 Windows host IP 通 → 把 settings.yaml baseURL 改成 suggestedBaseURL
  ├─ providerSnippets → 粘贴到 ~/.dsh/settings.yaml
  └─ ctx 400 / CONTEXT_WINDOW_EXCEEDED
        → settings contextWindow 必须 ≤ Ollama 实际 n_ctx，且建议两者一起抬到 ≥32768
        → 改 Modelfile PARAMETER num_ctx 后 recreate；再改 settings.yaml
```

**推荐安装：** `KIT_SET=llm`（见 [install.sh](./install.sh)）

---

## 2. HTTPS / 代理 / npm

```text
net_doctor (target=all)
  ├─ HTTP_PROXY 有值但 NODE_USE_ENV_PROXY 不是 1
  │     → export NODE_USE_ENV_PROXY=1 后重启 dsh web
  ├─ 无代理且 probe FAIL
  │     → Windows Clash/V2Ray mixed port → http://127.0.0.1:7890
  └─ npm OK 但 deepseek FAIL → 代理规则未放行 api.deepseek.com
```

Node 24 的 fetch **默认忽略**代理；`dsh-wsl-net` 会给子进程注入 `NODE_USE_ENV_PROXY=1`，但 **dsh 主进程**仍需你手动 export。

---

## 3. GitHub / git push

1. `KIT_SET=github` 装 github + cred
2. 按 [dsh-wsl-github README](https://github.com/173787247/dsh-wsl-github) 配 GitHub App
3. `source ~/.dsh/dsh-wsl-github.env` 后再开 `dsh web`
4. 仍失败 → `cred_doctor`，**不要**把 PEM/PAT 贴进聊天

---

## 4. 连通性 playbook（推荐顺序）

1. **host_reach** — 本地推理端口
2. **net_doctor** — 外网 HTTPS + registry
3. **dns_doctor** — 解析异常 / WSL↔Windows A 记录不一致
4. **clock_doctor** — 时间漂移（TLS / App JWT）
5. **wsl_workspace** — 工作区是否误开在 Desktop/`/mnt`
6. **wsl_expose** — 仅当 Windows 浏览器访问不到 WSL 内 web

`host_reach` 返回的 `connectivityPlaybook` 字段与上表一致。

---

## 5. 一键套件

| KIT_SET | 用途 |
|---------|------|
| `daily` | 日常 WSL+浏览器 |
| `github` | daily + GitHub App |
| `llm` | 本地模型 + 网络诊断 + 托盘/暴露 |
| `full` | 全部 30 插件 |

```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=llm bash
```

装完后 **重启 dsh web** 并 **新开一个会话**。
