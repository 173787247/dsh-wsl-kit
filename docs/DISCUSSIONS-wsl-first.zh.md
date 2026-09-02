# WSL-first DeepSeek Harness（讨论帖草稿）

> 发帖位置建议：DeepSeek Harness / dsh 相关 Discussions 或社区帖。可直接复制。  
> 配套仓：[dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit)（元仓，不进 awesome）

---

## 标题

WSL-first：Agent 在 Linux、聊天在 Windows 浏览器时怎么装 dsh 插件

## 正文

### 场景

很多同学是：

- `dsh web` 跑在 **WSL Ubuntu**
- 浏览器在 **Windows**
- 本地推理（Ollama / LM Studio / vLLM / Unsloth）也在 Windows 或 Docker 里

这时痛点不是「缺一个大插件」，而是 **跨系统边界**：路径、`NODE_USE_ENV_PROXY`、本机 `127.0.0.1` 到底是谁、git 凭据、GitHub API。

### 推荐装法（套件，不是单体大包）

元仓：**[dsh-wsl-kit](https://github.com/173787247/dsh-wsl-kit)**

```sh
# 日常（路径 / 代理 / 剪贴板 / 浏览器打开链接）
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=daily bash

# 本地 LLM（host_reach + 网络诊断 + 托盘等）
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=llm bash

# GitHub App 查 PR/Actions + 凭据提示
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=github bash
```

子插件进 [awesome-dsh-plugins](https://github.com/deepseek-ai/awesome-dsh-plugins)；**kit 本身不进 awesome**（约定：元仓 / 安装脚本）。

### 60 秒连通性顺序

1. 本地模型连不上 → `host_reach`（粘贴 `providerSnippets`）
2. DeepSeek / npm 超时 → `net_doctor`（`NODE_USE_ENV_PROXY=1`）
3. DNS / 证书时间怪 → `wsl_dns` / `wsl_clock`
4. 浏览器打不开 WSL 里的 UI → 见 kit `scripts/restart-dsh-web.sh`，Windows 打开 **http://127.0.0.1:3081/**（dsh 只绑 3080，需中继）

完整故障树：[TROUBLESHOOTING.zh.md](https://github.com/173787247/dsh-wsl-kit/blob/master/docs/TROUBLESHOOTING.zh.md)

### Ollama 上下文踩坑

插件一多，系统提示 + 工具 schema 很容易 >8k。请让 Ollama `num_ctx` 与 settings `contextWindow` **一致**（例如都 32768），且 `maxTokens` 小于窗口。

### 不做的事

- 不合成「一个巨大 WSL 插件」
- 不把钉钉 / OpenClaw / MCP 硬塞进 WSL 分类（那是另一条产品线）
- Unsloth Studio ≠ Unsloth Desktop；Flash-Next 多分片优先 Desktop / 补丁版 llama.cpp

### 相关链接

- Kit：https://github.com/173787247/dsh-wsl-kit  
- 本地 LLM：https://github.com/173787247/dsh-wsl-hostsvc  
- 网络：https://github.com/173787247/dsh-wsl-net  
- GitHub App：https://github.com/173787247/dsh-wsl-github  

欢迎反馈：你的 distro、是否 mirrored networking、Ollama 实际 `n_ctx`。
