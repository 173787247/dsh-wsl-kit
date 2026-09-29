# bootstrap —— 三步把 dsh-wsl-kit 装到这台 WSL 上

> **这是给新机器的入口。** 已经装好的机器要看维护，读
> [`../docs/MAINTENANCE.zh.md`](../docs/MAINTENANCE.zh.md)。

## 为什么需要它

DSH 官方假设 **dsh 和浏览器在同一台机器上**。WSL 不是这样：

```
浏览器   在 Windows
dsh      在 Linux（WSL2）
```

好处是真实的（实测）：

| | WSL `/home` | Windows `/mnt/c` |
|---|---|---|
| 300 个小文件 | **0.01 s** | 0.62 s |
| 100 MB 顺序写 | **0.09 s** | 0.58 s |

外加 CUDA 直通（`/dev/dxg` + `libcuda.so`，RTX 5080 · compute_cap 12.0），
以及一整套 Windows 上没有的 Linux 工具（`systemctl` `journalctl` `pass` `rclone`
`tmux` `helm` `terraform` …）—— 42 个 `dsh-wsl-*` 插件就建在这上面。

**代价不是性能，是复杂度**：每一样好东西都要跨一次操作系统边界。
所以这个套件把每条边界封在一个地方，而不是让每个新用户重新踩一遍。

## 三步

```sh
# 1 拿到 kit
git clone https://github.com/173787247/dsh-wsl-kit ~/src/dsh-wsl-kit

# 2 先看它打算做什么，不改任何东西
bash ~/src/dsh-wsl-kit/bootstrap/boot.sh --check

# 3 装
bash ~/src/dsh-wsl-kit/bootstrap/boot.sh
```

`boot.sh` 做五步，**每步都断言**：

| | 做什么 | 失败时会说 |
|---|---|---|
| 1 | 查环境 | WSL？dsh 装了吗？端口？`.wslconfig` 是 mirrored 吗？代理？三个 PS1 在吗？ |
| 2 | 装插件集 | 调 `install.sh`（`KIT_SET=daily\|github\|llm\|full`） |
| 3 | 装本地定制 | undici 7.18.2 + 三个 cordis 补丁，**逐条验证** |
| 4 | 装 Windows 常驻者 | `dsh-ui-watcher` —— 重启后浏览器自己回来靠它 |
| 5 | 自检 | 端口 · token URL · watcher 心跳 |

**★ 为什么每步都断言**：这一套里最容易出的错是**静默失败** —— 命令退出码 0 但什么
都没做。比如从 systemd 单元里 `Start-Process` 开浏览器：退出码 0，浏览器不出现。
所以每一步之后都验结果，而不是信任退出码。

## 那些 PS1 为什么必须有 BOM

`windows/` 下的 `.ps1` 是 **UTF-8 带 BOM** 存的。这不是风格问题：

**PowerShell 5.1 靠 BOM 判断编码。没有 BOM 就按系统代码页（简体中文是 GBK）读，
中文注释被读碎之后，解析器报的是「意外的标记 }」—— 看起来像语法错，其实是编码。**

改完请确认：

```sh
head -c3 bootstrap/windows/dsh-wsl-env.ps1 | od -An -tx1   # 应为 ef bb bf
```

另外两个坑也写在文件注释里：

- `$home` / `$user` 是 PowerShell 的**只读自动变量**，不能赋值 → 用 `$wslHome`。
- `wsl.exe -l -q` 的输出是 **UTF-16**，按 UTF-8 读会得到 `U<NUL>b<NUL>u<NUL>…`
  → 所有从 `wsl.exe` 拿的字符串都过 `Get-CleanWslText`。

## 目录

```
bootstrap/
  boot.sh                 五步一键入口（--check 只查不改）
  README.zh.md            这一页

  windows/
    dsh-wsl-env.ps1       环境发现：distro · user · home · kit 路径（零硬编码）
    dsh-ui-watcher.ps1    常驻者：token 一变就开浏览器
    install-watcher.ps1   把它装成开机自启（幂等 · 不需要管理员）
```

**★ 三个 PS1 都零硬编码**：distro 从 `wsl -l -q` 问，用户与家目录从 WSL 里问，
kit 路径在常见位置里找。要覆盖就设 `DSH_WSL_DISTRO` / `DSH_WSL_USER` / `DSH_WSL_KIT`。

## 装完之后

```sh
# 升级 dsh（粘 release URL 就行）
systemd-run --user --collect --unit=dsh-upgrade-$(date +%H%M%S) \
  --property=KillMode=process \
  /bin/bash ~/src/dsh-wsl-kit/scripts/upgrade-dsh-full.sh \
  https://github.com/deepseek-ai/deepseek-harness/releases/tag/dsh-v0.2.0-rc.2

# 重启（浏览器会自己回来）
bash ~/src/dsh-wsl-kit/scripts/restart-dsh-web.sh
```

**★ 保底**：桌面的 `DSH WSL` 快捷方式永远可用 —— 它起的是 `PATH` 里的 `dsh`，
无论 watcher 在不在都能进。
