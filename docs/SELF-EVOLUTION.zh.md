# 自进化迭代系统 —— 设计草案

> 写于 2026-09-28。全部结论来自**本机当天的实证**，不是推演。
> 当天发生了七个 bug，五个是用户推出来的。这份设计要解决的就是那五个。

---

## 一、为什么现在谈这个：当天的证据

### 1.1 七个 bug 及其发现者

| # | bug | 发现者 | 若无人推，后果 |
|---|---|---|---|
| ① | `~/.dsh/.env` 里有 12 个 `DSH_*` | 用户（"测试重启"） | 下次重启 dsh 永久起不来 |
| ② | `Start-Process -ArgumentList` 拆散命令 | 用户（"换端口测试"） | 恢复路径失效 |
| ③ | `export PATH` 未加引号 → bash 语法错 | 我（顺 ② 查出） | 同上 |
| ④ | 快捷方式传 Linux 路径 | 我（查 `.lnk` 时） | 同上 |
| ⑤ | `WSL_DISTRO_NAME` 丢失 → `"WSL"` | 用户（"点了没反应"） | 同上 |
| ⑥ | PS1 无 BOM → GBK 错位吞引号 | 用户（"我还没点"） | 同上 |
| ⑦ | `vecmem` 被旧格式覆盖，检索静默返回 0 | 用户（"天花板要不要加"） | 检索死了无人知 |

**七个里五个靠人推。这是我能力之外的结构性缺口，不是态度问题。**

### 1.2 共同的失败形状

前七条都是同一句话：

> **我验证了「我刚做的那个动作」，没验证「它可能弄坏的那个东西」。**

- 改完 `.env`，我验证了文件格式对不对 —— 没验证 dsh 还能不能启动
- 改完快捷方式，我验证了「我拼出来的路径」能不能解析 —— 没验证「它实际写的那个路径」
- 改完写库格式，我验证了脚本没报错 —— 没验证 items 和 rows 还对不对得上

第八条更狠：**我写的 `check-recovery.sh` 有一项永远返回 OK**（`grep` 扫了整个文件而不是那一行），直到我拿坏输入去试才发现。

---

## 二、闭环的十个步骤

| # | 步骤 | 在哪跑 | 当天状态 |
|---|---|---|---|
| 1 | **OBSERVE** 状态快照 | **systemd 外** | ★ 没有 → ⑦ 无人知 |
| 2 | **DETECT** 触发器 | **systemd 外** | ★ 没有 → 五个靠人推 |
| 3 | **DIAGNOSE** 诊断 | agent 内 | ✓ 有，且是强项 |
| 4 | **PROPOSE** 提改动 | agent 内 | ✓ 有 |
| 5 | **BASELINE** 改动前跑一遍 | agent 内 | ★ **整天没做过一次** |
| 6 | **APPLY** 应用 | agent 内 | ✓ 有（改代码 + 重启） |
| 7 | **RE-VERIFY** 改动后跑 | **systemd 外** | ★ 只有 cordis 审计有 |
| 8 | **COMPARE** 差分 | **systemd 外** | ★ 只有 cordis 审计有 |
| 9 | **RECORD** 写回记忆 | agent 内 | ~ 库在，但我没查 |
| 10 | **ROLLBACK** 回滚 | **systemd 外** | ★ 完全没接（git 可做） |

### 2.1 为什么 1、2、7、8、10 必须在外面

**dsh 自己要死的时候，只有进程外的东西看得见。**

当天两次重启都是 systemd 完成的 —— 它不在 dsh 的进程树里，所以 dsh 死了它还在。

**反之 3–6 必须在里面**，因为那需要读代码、理解上下文、写修复 —— 那是 agent 的活。

---

## 三、Agent Team 的位置：职责分离，不是并行加速

### 3.1 单 agent 环路的结构性缺陷

```
我改  →  我验  →  我宣布成功
```

**六个 bug 全部通过这个环路 —— 因为写的人、验的人、判的人共享同一个盲区。**

### 3.2 四个角色

| 角色 | 职责 | 当天谁在做 |
|---|---|---|
| **PROPOSER** | 提出改动 + 自己的验证方案 | 我 |
| **VERIFIER** | 独立写验证，**不看** PROPOSER 的验证代码 | ★ 没人 |
| **ADVERSARY** | 拿已知坏输入攻击 VERIFIER 的检查，证明它不会永远返回 OK | ★ 没人 |
| **SUPERVISOR** | 进程外；拿不准时叫醒人 | ★ 没人（systemd 今天临时担任） |

### 3.3 每个角色的价值都有当天实证

**VERIFIER** —— 写检查和写修复的不是同一个人，就不共享盲区。

**ADVERSARY** —— `check-recovery.sh` 的 pkill 那项，我写完就"通过"了，直到拿坏输入试才发现它 `grep` 整个文件。**这个角色专职做「证伪检查」。**

**SUPERVISOR** —— 两次实证：① dsh 起不来时只有外面能救；② 我判断不了时得有人叫醒（当天五次都是用户主动推）。

---

## 四、验证的三个层次（从弱到强）

### 4.1 测试：绑在实现上

```
"这个修复在不在？"
```
**换了实现就失效 —— 自进化最需要它的时候它最先坏。**

### 4.2 不变量：绑在性质上

来自 `cordis-dsh-audit/invariants`，源码注释：

> *"A scenario here never asserts that a particular fix is present — it asserts that a property holds, which makes the same file meaningful on both lines."*

```
"这个性质还成立吗？"
```
**能活过修改。这是自进化可用的验证单元。**

### 4.3 差分：不靠"我知道正确答案"

`cordis-dsh-audit/invariants/run.mjs` 跑两条线，报三种结果：

```
AGREE     两边都成立，或两边都违反
DIVERGE   一边成立一边不成立   ← the finding
```

**★ 源码里最诚实的一句：**
> *"A divergence is not automatically a bug on the line that failed: it is a question about which behaviour the property demands."*

**它不假装知道哪条线对 —— 这是个**问题生成器**，不是判决器。人（或 agent）还得判断。**

---

## 五、本机已有的零件（不需要造新的）

| 零件 | 现状 | 在环路里的位置 |
|---|---|---|
| **systemd 255** | timer / service / `Restart=on-failure` / journal | 步骤 1-2、7-8、10 的宿主 |
| **`check-recovery.sh`** | 9 项，全部用坏输入反向验证过 | 步骤 2 的触发器 |
| **cordis `invariants/` + `run.mjs`** | 9 个不变量，差分跑两条线 | 步骤 7-8 的引擎 |
| **`vecmem`** | 5000 条 / 4096 维 / 二进制边车 | 步骤 9 的记忆 |
| **git** | kit 90 提交、audit 46 提交，均干净 | 步骤 10 的回滚机制 |
| **DSH 编排原语** | `subagent` / `workflow` / `spawn_teammate` / `team_task_create` | 步骤 3-6 的队形 |
| **`dsh-wsl-notify`** | 已有跨 Windows 通知实现 | SUPERVISOR 叫醒人的通道 |
| **21 个 `link:` 插件** | 源码可写，重启后生效 | 自进化的作用面 |
| **RTX 5080 / 16GB** | 已用 4.2GB | 本地模型全在 |

---

## 六、硬约束（违反任何一条，系统会自我毁灭）

### 6.1 第一约束：检查必须被坏输入证伪过

```
任何「检查」在没有被已知坏输入证伪之前，不算检查。
```

**当天实证：`check-recovery.sh` 的 pkill 项通过了一个坏文件，因为它 `grep` 了整个文件而不是那一行。**

### 6.2 第二约束：改动前必须有基线

```
没有基线 → 改完不知道是变好还是变坏，只能说"看起来对"。
```

### 6.3 第三约束：进程外的东西只报告，初期不动手

```
SUPERVISOR 在检查本身还没被验证够之前，不该有重启权限。
```

**理由：一个有洞的检查 + 自动重启 = 带着洞去重启。当天那个 pkill 的洞证明了检查不是一次能写对的。**

### 6.4 第四约束：能写的是那 21 个 link 插件，不是 82 个官方 copy 包

```
改了 copy 包 → 下次安装被覆盖 → 修改静默消失
```

---

## 七、分阶段落地

### 阶段一：只观察，只报告（无写入权限）

```
systemd timer (每 15 分钟)
  → check-recovery.sh
  → 失败则 Windows 通知 + journal
  → 不动任何东西
```

**目的：先让检查在真实环境里跑够，看它有没有误报/漏报。**

### 阶段二：加基线采集

```
每次 agent 改动前，自动快照：
  · git 状态（commit hash）
  · check-recovery 结果
  · invariants 跑一遍（如果适用）
→ 存入 vecmem，带时间戳和 commit
```

**目的：让「改完之后」有东西可比。**

### 阶段三：接差分与回滚

```
改动 → 重跑同一组检查 → COMPARE
  AGREE    → 记录，继续
  DIVERGE  → 标为"待判断"，通知人，**不自动回滚**
```

**目的：把 `cordis-dsh-audit` 那套差分机制从"一次性审计"变成"常驻能力"。**

### 阶段四：Agent Team 常态化

```
PROPOSER (agent)  →  VERIFIER (独立 subagent，不共享上下文)
                  →  ADVERSARY (subagent，专职证伪检查)
                  →  SUPERVISOR (systemd，进程外)
```

**目的：让「写的人」和「验的人」在结构上分开。**

---

## 八、第一件该做的事（不是搭框架）

**`backport/` 里那三个补丁，是这套设计的第一个真实用例：**

```
cordis-4.0.4.patch                493 行 / 25 hunks
cordis-plugin-loader-1.0.5.patch  279 行 / 21 hunks
cordis-plugin-timer-1.1.6.patch   102 行 /  5 hunks
```

**它们修的是 DSH 自己那份 cordis 里真实存在的缺陷，probe-before / probe-after 都验过。**

**★ 而且 `invariants/run.mjs` 已经能跑 —— 那九个不变量就是完美的基线。**

**流程：**
1. 跑九个不变量，记录基线（改动前的 AGREE/DIVERGE）
2. 打补丁
3. 再跑同一组不变量
4. COMPARE
5. git 提交（可回滚点）

**这是「自进化」第一个真实动作，而且验证机制已经现成。**

---

## 九、还没有答案的问题

1. **检查的频率与代价**：15 分钟一次，每次跑 PowerShell parse + wslpath + vecmem 校验，值不值得？
2. **SUPERVISOR 什么条件下才该有重启权限**：需要一个量化的"检查可信度"，现在没有
3. **Agent Team 的成本**：VERIFIER + ADVERSARY 每次都要跑，对本机算力是什么负担
4. **记忆的写入策略**：什么该进 vecmem、什么不该 —— 今天试过 8 条"已确立事实"，但那是手写的
5. **回滚的粒度**：git 能回代码，回不了"配置改坏了但代码没动"那种
