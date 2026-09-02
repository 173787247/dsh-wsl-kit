# WSL + dsh 故障树

Agent 在 WSL、浏览器在 Windows 时，问题常出在「跨系统网络」而不是 dsh 本身。按症状选工具，不要盲重启。

## 快速对照

| 症状 | 先跑什么 | 插件 |
|------|----------|------|
| Ollama / 本地模型 API 404、连不上、ctx 报错 | `host_reach` | [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) |
| DeepSeek API / npm install 超时 | `net_doctor` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| ModelScope / Hugging Face 拉模型失败 | `net_doctor` target=`registry` | dsh-wsl-net |
| git push / GitHub API 401 | `github_app_hint` + `cred_doctor` | github + cred |
| DNS 解析怪、证书像被劫持 | `wsl_dns` | [dsh-wsl-dns](https://github.com/173787247/dsh-wsl-dns) |
| TLS / 证书时间错误 | `wsl_clock` | [dsh-wsl-clock](https://github.com/173787247/dsh-wsl-clock) |
| 浏览器打不开 WSL 里的 dsh web | `wsl_expose` advise | [dsh-wsl-expose](https://github.com/173787247/dsh-wsl-expose) |
| Agent 乱用 Windows 路径 | （自动） | [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) |

---

## 1. 本地 LLM（Ollama / LM Studio / vLLM / Unsloth）

```text
host_reach (profile=all)
  ├─ 全 closed → Windows 上服务没开 / 只绑 127.0.0.1 且 NAT 模式
  │     → OLLAMA_HOST=0.0.0.0:11434 或 LM Studio「局域网」
  │     → 或 .wslconfig 开 networkingMode=mirrored
  ├─ 只有 Windows host IP 通 → 把 settings.yaml baseURL 改成 suggestedBaseURL
  ├─ providerSnippets → 粘贴到 ~/.dsh/settings.yaml
  └─ ctx 400 错误 → settings contextWindow 大于 Ollama 实际 n_ctx
        → OLLAMA_NUM_CTX 或降低 settings 里的 contextWindow
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
3. **wsl_dns** — 解析异常
4. **wsl_clock** — 时间漂移
5. **wsl_expose** — 仅当 Windows 浏览器访问不到 WSL 内 web

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
