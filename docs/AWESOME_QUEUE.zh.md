# awesome-dsh-plugin 收录队列

对照：[awesome-dsh-plugin/awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)  
门槛（2026-09 起）：**仓龄 ≥ 1 天**；每 PR **最多 3** 条；需 `dsh.bundle` + 话题 `dsh-plugin`。**已无提交数下限。**

不收录：`dsh-wsl-kit`、`dsh-wsl-common`。

YAML 草稿目录：[`awesome-queue/`](./awesome-queue/)。提 PR 只新增 `data/plugins/<owner>__<repo>.yml`，勿手改 README。

## 时间表（UTC+8）

按 `created_at + 24h` 换算。当前（约 09-23 00:30）都还不到点。

| Wave | 最早可提（UTC+8） | 插件 | 状态 |
|------|-------------------|------|------|
| **A** | **09-24 03:42** | jev · obsidian | 待提（先 2 条也行） |
| **B** | **09-24 06:40** | secret · ollama · media | 待提 |
| **C** | **09-24 06:37** | search · vecmem · k8s | 待提（可与 B 同日连开） |
| **D** | **09-24 07:34** | llamacpp · vllm · struct | 待提 |
| **E** | **09-24 07:34** | git · tmux · compose | 待提 |
| **F** | **09-24 07:40** | systemd · helm · terraform | 待提 |
| **G** | **09-24 07:48** | rclone · db · glab | 待提 |
| **H** | **09-24 07:49** | playwright · mail · cal | 待提 |
| **I** | **09-24 07:50** | pkg | 待提（可并入 H 若仓龄已够） |

建议节奏：24 日凌晨先合 **A**；上午连开 **B→C**；下午扫完 **D→I**（每 PR 间隔几分钟即可，避免同作者刷屏观感）。

## 已收录

约 33 个 `173787247__dsh-*`（Daily / 工具向）。本队列只管缺口。

## 提 PR

1. Fork / 同步 `awesome-dsh-plugin/awesome-dsh-plugin`
2. 从 `docs/awesome-queue/wave-X/` 拷贝对应 yml → `data/plugins/`
3. PR 标题示例：`Add 173787247 jev + obsidian`
4. 若 CI 只报仓龄未到：留着等自动复跑，不必关重开
