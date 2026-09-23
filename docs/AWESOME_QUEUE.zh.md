# awesome-dsh-plugin 收录队列

对照：[awesome-dsh-plugin/awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)  
门槛（2026-09 起）：**仓龄 ≥ 1 天**；每 PR **最多 3** 条；需 `dsh.bundle` + 话题 `dsh-plugin`。**已无提交数下限。**

不收录：`dsh-wsl-kit`、`dsh-wsl-common`。

YAML 草稿：[`awesome-queue/`](./awesome-queue/)。提 PR 只新增 `data/plugins/<owner>__<repo>.yml`，勿手改 README。

更新于 **2026-09-23 18:00（UTC+8）**。已收录对照 upstream：`173787247__*` **33** 个（Daily/工具向）；本队列 **24** 个缺口。

## 时间表（UTC+8）

| Wave | 最早可提 | 插件 | 状态 |
|------|----------|------|------|
| **A** | 09-23 19:42（jev；obsidian 已满龄） | jev · obsidian | **PR 已开** → [#5755](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5755)（jev 约 2h 内过仓龄门） |
| **B** | 09-23 **22:40** | secret · ollama · media | 待提 |
| **C** | 09-23 **22:37** | search · vecmem · k8s | 待提 |
| **D** | 09-23 **23:34** | llamacpp · vllm · struct | 待提 |
| **E** | 09-23 **23:34** | git · tmux · compose | 待提 |
| **F** | 09-23 **23:40** | systemd · helm · terraform | 待提 |
| **G** | 09-23 **23:48** | rclone · db · glab | 待提 |
| **H** | 09-23 **23:49** | playwright · mail · cal | 待提 |
| **I** | 09-23 **23:50** | pkg | 待提（可并入 H） |

## 已收录（无需再提）

上游 `data/plugins/173787247__*.yml` 约 33 个（env / net / repeat-stop / Daily 医生与 Windows 桥等）。

## 提 PR

1. 同步 fork `173787247/awesome-dsh-plugin` ← upstream `main`
2. 从 `docs/awesome-queue/wave-X/` 拷贝 yml → `data/plugins/`
3. PR 标题示例：`Add 173787247 …`
4. 若 CI 只报仓龄未到：留着等自动复跑，不必关重开
