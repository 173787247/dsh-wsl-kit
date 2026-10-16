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
| 03 | `03-wsl-powershell-script-path.sh` | `dsh-native-command` 里交给 `powershell.exe -File` 的脚本路径改成 `wslpath -w` 的结果 | 从 `/mnt/<盘>` 下的 cwd 启动时，Windows 子进程把 Linux 路径解析到自己盘符下 ⇒ 脚本没跑、`powershell` 只打印横幅并退出 0 ⇒ 调用方 `JSON.parse` 炸 ⇒ 文件卡片「用应用打开」永远 `Could not load applications`。配套：`scripts/restart-dsh-web.sh` 里的 `cd "${DSH_WEB_CWD:-$HOME}"` |

## ⚠️ 一个已知打不上的补丁（2026-10-16）

`02-cordis-backports.sh` 会遍历 `~/src/cordis-dsh-audit/backport/*.patch` 里的三个补丁。
其中：

```
cordis-4.0.4.patch                 ✓ 仍能重打
cordis-plugin-timer-1.1.6.patch    ✓ 仍能重打
cordis-plugin-loader-1.0.5.patch   ★ 打不上 —— 但它【仍然需要】，见下
```

**而 `apply-local-patches.sh --check` 照样报「全部本地定制都已生效」** ✗ ——
因为它验的是 `cordis` 那一处（`name: 'cordis 补丁'`），**不是 loader 这一处**。

⇒ **这是"检查没覆盖那件事"的又一个实例**：升级日志里两次点名这个补丁失败，
而检查说没事。**看检查的绿灯，不等于每一处都被验过。**

### 为什么打不上：版本漂移，不是上游修好了

```
补丁针对: cordis-plugin-loader【1.0.5】
实际装的: cordis-plugin-loader【1.0.6】     ← 差一个小版本 ⇒ 上下文行对不上
```

**而缺陷在 1.0.6 里依然存在**（2026-10-16 实测装的这一份）：

```
grep -c 'Promise.all(ids.map('                    lib/index.js  ⇒ 1 处   ← 补丁要删掉的旧写法还在
grep -c 'for (const id of ids) if (!newMap[id])'  lib/index.js  ⇒ 0 处   ← 补丁要加的新写法没有
grep -c 'async _patchContext'                     lib/index.js  ⇒ 0 处
grep -c '_initTask?: Promise<void> | undefined'   lib/index.js  ⇒ 0 处
```

真实代码（`lib/index.js` 88-92 行）仍是：

```js
if (newMap[id]) await this.create(newMap[id]).catch((error) => {
    this.ctx.logger.error(error);
});
else this.remove(id);
}));                       // ← Promise.all(ids.map(…)) 并发跑，一处抛出即整体 reject
```

⇒ **不要把补丁移走** —— 它要修的东西还在。

★ **一个还没有证据的联想**：那个缺陷的形状是"异常逃逸成 unhandled rejection"，
而 2026-10-16 晚观察到的现象是"dsh 每隔几分钟就不应答一次"。
**形状相同，但没有证明是它造成的** —— 查这件事要有它自己的判据（例如抓那个 rejection 的现场）。

### 该怎么办

1. ★ **已经确认：仍然需要**（上面那四条 grep 就是判据）。所以不是"移走"，是**重新适配**。
2. **按 1.0.6 的代码重新做适配** —— 改动只有几处（见补丁的 hunk），把上下文行对上即可。
3. 适配完把补丁名改成对应版本（`…-1.0.6.patch`），旧的删掉 —— 免得下次又对不上。

★ 在那之前：**升级日志里出现这一行是预期的，不代表升级失败。**

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
