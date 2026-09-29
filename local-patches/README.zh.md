# local-patches —— 我们对 dsh 的本地定制

> **为什么有这一层**：`npm install -g` 升级 dsh 会覆盖整个 `node_modules`，
> 我们改过的东西全没了。每次升级都「重头再来」不是进化，是原地打转。
>
> 所以把定制做成**幂等的脚本**，升级后一条命令重打，并逐条验证。

## 用法

```sh
bash ~/src/dsh-wsl-kit/scripts/apply-local-patches.sh          # 全部重打
bash ~/src/dsh-wsl-kit/scripts/apply-local-patches.sh --check  # 只检查，不改
```

**★ 幂等**：已打过就跳过，不会重复改。
**★ 逐条验证**：每项都有 `verify`，打完立刻验，验不过就报错。

## 清单

| # | 脚本 | 改什么 | 为什么 |
|---|---|---|---|
| 01 | `01-undici-7.18.2.sh` | dsh 内嵌的 undici `8.11.0` → `7.18.2` | Node 24 内置 fetch 是 undici 7.x；跨大版本的 ProxyAgent 作全局 dispatcher 会丢响应头 → `web_search` 的 brotli 响应不解压 → JSON.parse 失败。**Cursor 于 2026-09-26 修复** |
| 02 | `02-cordis-backports.sh` | 三个 cordis 补丁 | 线上 cordis 的真实缺陷：插件在 update 时抛异常会逃逸成 unhandled rejection 打死进程。**2026-09-28 差分验证过** |

## 不受升级影响的东西（不用重打）

```
~/.dsh/profiles/web/cordis.patch.yml     profile 配置，在 ~/.dsh 下
~/.dsh/settings.yaml                     同上
dsh-wsl-kit/scripts/*.sh                 脚本仓，不在 node_modules
22 个插件的 link: 安装                    指向 Windows 侧检出，不随 npm 升级
```

## 加一条新定制

在 `scripts/apply-local-patches.sh` 的 `PATCHES` 数组里加一行：
```sh
"NN-名字.sh|一句话说明|验证命令"
```
验证命令退出 0 表示生效。
