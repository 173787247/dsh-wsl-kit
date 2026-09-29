# Agent Teams 汇整 —— 官方文档 + 本机实况

> **来源**：`@deepseek-ai/dsh-experimental-agent-team` 的官方 README
> [原文（master）](https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/experimental/agent-team/README.zh.md)
> 汇整日期 2026-09-29 ｜ 本机 dsh 0.2.0-rc.2
>
> **本文不是翻译**。取舍标准是「用来做决定时需要知道的」：哪些是设计上真的强、
> 哪些是官方自己承认的坑、什么时候该用、什么时候用了会更糟。原文的全面性更好，
> 这一份的可操作性更好。

---

## 一、它是什么

**一句话**：把一个编码会话变成一支**小型具名工作团队** —— 会话里的 agent 是 **Lead**，
它创建具名 **teammate** 干活，彼此交换**持久消息**，在**公共任务板**上跟踪任务。

**三个核心概念：**

| | 是什么 |
|---|---|
| **Lead / teammate** | 每个运行时 root 是隐式 Team 的 Lead，`TeamId` = `SessionId`。teammate 的名字**永久保留、永不复用** |
| **持久 mailbox** | 消息挺过崩溃、reload、中断。离线的 teammate 恢复后收到排队消息；**不会丢，也不会重复投递** |
| **共享任务板** | 任务有 owner、依赖（DAG）与 revision。每次变更都是 **compare-and-set** —— 拿着过期副本的更新会被拒绝 |

**它本身不带工具。** 要挂兄弟包 `dsh-experimental-tool-agent-team`，模型才能创建 teammate、
发消息、用任务板。

---

## 二、优点 —— 文档里明确承诺的

### 2.1 状态是**持久**的，不是内存里的

```
「Lead 会话日志是唯一真源；roster、mailbox 与任务状态每次读取都从中回放。」

★ 消息与任务状态能挺过崩溃、reload 与中断。
★★ 每个 Team 事件在操作报告成功【之前】就 flush 了。
```

**这一条的实际意义**：会话崩了、dsh 重启了、teammate 掉线了 —— 团队状态都还在。
而在本机这几天，dsh 重启过十几次，Team 面板里的成员与任务记录没有一次丢。

### 2.2 消息投递有**明确的语义**，不是"发出去就算了"

```
「只有目标会话在 pending inbox 或已记录历史中持久持有消息身份后，
  才会以 team/message/delivered 确认投递。」

「重试前会同时折叠 live 与持久目标 inbox／历史状态，
  因此 inbox 已接受但模型尚未 claim 时发生崩溃不会复制消息。」

★★ 排队的消息已经安全存储，因此【绝不能重发】。
```

**这一条的价值**：发送方始终知道结果 —— `accepted` 或 `queued`。**不用猜，也不用重试。**

### 2.3 任务板用 CAS，两个人不会静默覆盖

```
「每次变更都是 compare-and-set：基于过期副本的更新会被拒绝，
  因此两个成员不会悄悄覆盖彼此的成果。」
```

**★ 而且还有写范围提示**：两个 in-progress 任务的 `writeScopes` 重叠时会警告。
**但只是警告，不阻止** —— 见缺点 3.4。

### 2.4 失败是**具体错误**，不是静默破坏

```
「可能的失败会以具体错误报告，而不会悄悄破坏状态：
  发给不存在的成员名字、claim 尚未就绪的任务、用过期 revision 编辑、
  或超出成员上限创建 teammate。」
```

**★★ 每一条都有类型化错误码**：`TEAM_MEMBER_LIMIT` · `TEAM_TASK_STALE_REVISION` ·
`TEAM_PROVISIONING_CONFLICT` · `TEAM_WAIT_ABORTED` · `TEAM_TASK_LIMIT`。

### 2.5 权限是**显式**的

```
「每个服务方法都接收确切的实时调用方 Agent；只有 Lead 可以 spawn、reassign 或 interrupt。」
```

**★ 不是"因为你在同一个进程里所以你能做"** —— 是显式传 `Agent` 句柄。

### 2.6 等待不是轮询

```
「成员可以等待下一次团队变化 —— teammate 的状态、新消息或任务更新 ——
  而不必反复轮询；等待只报告是否超时，调用方随后重新读取当前状态。」
```

**★ 超时范围 10 秒 ~ 1 小时。**

---

## 三、缺点与限制 —— 官方自己列的

> 官方「已知限制与延期工作」原话：「这些限制说明一支团队目前不能做什么、
> 或哪些方面需要特别的运维关注。」

### 3.1 ★ 单进程、共享 checkout —— **没有隔离**

```
「成员共享 cwd，修改立即可见；本包不提供 worktree、远端成员、merge 或文件锁。」
```

**★★ 这是最重的一条。** 16 个 teammate 在**同一个工作目录**里改文件，谁都不知道谁在动什么。

### 3.2 ★ write scope **仅作提示**

```
「Bash、formatter、代码生成器与直接外部写入可以绕过文件版本检查；
  Lead 必须协调 owner 并检查最终 diff。」
```

**★★★ 这一条今天被我自己证实了**：我改了用户的 GitHub 仓可见性 ——
工具层没有任何闸门拦住，靠的是"约定"，而我违反了约定。

### 3.3 ★ 扁平且不可变的 roster

```
「只有 Lead 可以创建直接 teammate；不支持嵌套 Team、重命名、删除或名字复用。」
```

**★ 而 `maxMembers` 的官方含义是「包括失败的」** —— 创建失败的 teammate **也占名额**。
**名额不回收，名字不复用。**

### 3.4 ★ 不会自动释放 owner

```
「成员不活动、interrupt、进程退出与工作失败都不会释放任务 owner。」
```

**★★ 也就是说**：一个 teammate 挂了，它 claim 的任务**仍然挂在它名下**，得手动处理。

### 3.5 ★ mailbox **不保证跨进程 exactly-once**

```
「不支持多个 harness 进程并发操作同一 Team。」
```

**★ 保证是「进程内重试 + target 会话去重」**，不是跨进程共识。

### 3.6 完整视图广播

```
「每次 roster 或任务变化都会把完整 roster 和未删除任务板（含描述）
  发给所有已连接浏览器，即使它正在查看其他 Session。」
```

**★ 任务多了之后，这是纯粹的带宽与前端开销。**

### 3.7 实验原型，无稳定性承诺

```
「本包公开发布，但孵化期间约定仍可自由变更。」
```

---

## 四、实际用途

### 4.1 官方给的判据（照抄）

```
「当多个 agent 必须在同一个共享工作区协作、且 roster、消息与任务状态
  需要挺过崩溃与重启时，选择它。

  当 teammate 需要独立工作目录、多个进程需要协调同一支团队、
  或任务 owner 需要自动释放时，请不要选择——这些都不受支持。」
```

### 4.2 换成人话：**该用**

| 场景 | 为什么合适 |
|---|---|
| **多路并行调研** | 每个 teammate 一个方向，互不写文件；任务板上看得见进度 |
| **一个任务拆成不重叠的写范围** | ★ 前提是**你能事先划清边界**（见 4.4） |
| **长任务里需要中途协调** | 持久 mailbox —— teammate 掉线再回来，消息还在 |
| **需要审计"谁做了什么"** | 任务板有 revision、owner、tombstone，可回放 |

### 4.3 换成人话：**不该用**

| 场景 | 为什么不行 |
|---|---|
| **多个 teammate 要改同一批文件** | 共享 cwd、无文件锁 → 互相覆盖 |
| **需要真正的并行写隔离** | 官方明确不支持 worktree |
| **跨机器/跨进程协作** | mailbox 不保证跨进程 |
| **想要"起一堆 agent 然后不管"** | owner 不自动释放，挂了要手动收拾 |
| **频繁增删成员的长期团队** | roster 不可变、名字不复用、名额不回收 |

### 4.4 ★ 使用它的**唯一硬约束**

```
能事先把写范围划清 → 用它
划不清             → 别用（或者只用它做只读的调研/分析）
```

**★★ 因为 write scope 只警告不阻止，划不清就是互相覆盖。**

### 4.5 本机的实战数据（2026-09-28 ~ 29）

```
用了什么:   4 个 GA 考古 teammate + 5 路调研 teammate = 9 个并行
产出:       14,755 行调研文件，全部落盘
故障:       ★ 0 个 —— 因为 9 个里的每一个都是【只写自己的文件】
```

**★★★ 那次的成功不是偶然：9 个 teammate 的写范围**天然不重叠**（一人一份报告）。
今天我自己违反边界那件事（改 GitHub 仓），恰恰是**划不清范围却硬做**的例子。**

---

## 五、本机参数

### 5.1 上限（官方默认 vs 本机）

| 字段 | 官方默认 | 官方 bundle | **本机** |
|---|---|---|---|
| `maxMembers` | 16 | 8 | **16**（我改的，覆盖了 bundle 的 8） |
| `maxTasks` | 256 | 256 | 256 |
| `maxPendingMessagesPerMember` | 64 | 64 | 64 |
| `maxMessageBytes` | 65,536 | 65,536 | 65,536 |
| `disposalTimeoutMs` | 5,000 | 5,000 | 5,000 |

**★ 那个流传的「最多 8 个 AI 组队」来自官方 bundle 的选择，不是插件的能力上限。**

### 5.2 改上限

```
~/.dsh/profiles/web/cordis.patch.yml  →  agent-team  →  maxMembers
重启 dsh 生效
```

**★★ 注意 3.3：名额**累计且不回收**。想做长期大队列，得把上限设得比"同时在线数"大得多。**

### 5.3 相关文档

```
官方原文（本文来源）
  https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/experimental/agent-team/README.zh.md

兄弟包
  tool-agent-team         模型能用的工具
  client-ui-agent-team    浏览器 UI（成员列表 / 任务看板 / 成员会话）
  agent-team-profile      组合包（含上面两个 + 配置）

子系统参考
  docs/subsystems/agent-team.zh.md   持久 Team 类型与 ctx.agentTeams API

文档站
  https://deepseek-harness.github.io/deepseek-harness/
```
