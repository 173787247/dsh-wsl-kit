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
| 01 | `01-undici-7.18.2.sh.disabled-for-signin` | 已停用：不再把 undici 打回 7.18.2 | dsh 0.2.2-alpha.3 的登录线需要 undici **8.11.2**；Node 24 内置 7.18.2，不能再拿「与 Node 内置一致」当判据。实测 alpha.3 + 8.11.2 的 `web_search` 正常 |
| 02 | `02-cordis-backports.sh` | 四个 cordis 补丁（含按 1.0.7 重新适配的 loader 卸载等待） | 线上 cordis 的真实缺陷：插件在 update 时抛异常会逃逸成 unhandled rejection 打死进程；loader 的 `remove()` 不等待 teardown。**2026-09-28 差分验证，2026-11-03 适配 alpha.3** |
| 03 | `03-wsl-powershell-script-path.sh` | `dsh-native-command` 里交给 `powershell.exe -File` 的脚本路径改成 `wslpath -w` 的结果 | 从 `/mnt/<盘>` 下的 cwd 启动时，Windows 子进程把 Linux 路径解析到自己盘符下 ⇒ 脚本没跑、`powershell` 只打印横幅并退出 0 ⇒ 调用方 `JSON.parse` 炸 ⇒ 文件卡片「用应用打开」永远 `Could not load applications`。配套：`scripts/restart-dsh-web.sh` 里的 `cd "${DSH_WEB_CWD:-$HOME}"` |

## 2026-11-03 alpha.3 适配

- **01 undici 补丁停用**：改名为 `01-undici-7.18.2.sh.disabled-for-signin`，不再参与重打。alpha.3 的登录线需要 **undici 8.11.2**；Node 24 内置 7.18.2，继续按「与 Node 内置一致」检查会把正确的 8.11.2 判成失败。
- **02 loader 补丁重新适配**：按 `cordis-plugin-loader@1.0.7-alpha.2` 新增 `cordis-plugin-loader-1.0.7-teardown.patch`，让 `EntryGroup.remove()` 把 dispose task 交给 `EntryTree.trackDetached()`，并让 `update()` await 它。旧的 `cordis-plugin-loader-1.0.6-teardown.patch` 与 `cordis-4.0.4.patch` 已移入 `~/src/cordis-dsh-audit/backport/archive/`。
- **检查覆盖**：`apply-local-patches.sh --check` 现在验 undici 8.11.2、cordis、loader、native-command 四处；alpha.3 上全绿。

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
