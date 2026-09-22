# dsh-wsl-kit

**涓€鍙ヨ瘽锛?* Agent 鍦?WSL 閲岃窇 DeepSeek Harness锛岃亰澶╁湪 Windows 娴忚鍣ㄢ€斺€旇矾寰勩€佷唬鐞嗐€佸壀璐存澘銆佹墦寮€鏂囦欢閮借璺ㄧ郴缁熸椂锛岃杩欎釜濂椾欢銆?
鏈粨鏄?*鍏冧粨**锛堟枃妗?+ 瀹夎鑴氭湰 + [`cordis.patch.yml`](./cordis.patch.yml)锛夛紝涓嶅惈鎻掍欢杩愯鏃朵唬鐮併€傚悇瀛愭彃浠朵粨搴撳彟闄勮嫳鏂?`README.md` 涓庝腑鏂?`README.zh.md`銆?
[English 鈫?README.md](./README.md)

---

## 杩欎簺涓滆タ鎬庝箞鎷煎湪涓€璧?
鏈粨涓嶆槸杩愯鏃躲€俙install.sh` 鎶婃彃浠惰杩?dsh 鐨?`web` profile銆傝亰澶╁湪 Windows锛宎gent 鍜屽伐鍏峰湪 WSL銆傚彲閫夌殑 [dsh-wsl-im](https://github.com/173787247/dsh-wsl-im)銆乕dsh-wsl-obsidian](https://github.com/173787247/dsh-wsl-obsidian) 涓?[dsh-wsl-jev](https://github.com/173787247/dsh-wsl-jev) **涓嶅湪** `install.sh` 閲屻€?
```mermaid
flowchart TB
  subgraph win [Windows]
    browser["娴忚鍣?:3081/?token="]
    host["鍓创鏉?/ 璧勬簮绠＄悊鍣?/ 榛樿娴忚鍣?]
  end
  subgraph wslbox [WSL]
    relay["绔彛涓户"]
    dsh["dsh web :3080"]
    subgraph plugins [鏈?kit 鐨勬彃浠禲
      daily["鏃ュ父锛歟nv net fetch open clipboard path browser launch"]
      guards["repeat-stop + tool-budget"]
      more["鍙€夛細github cred notify + 璇婃柇"]
    end
    im["dsh-wsl-im 鈥?鍙€?]
    obsidian["dsh-wsl-obsidian 鈥?鍙€?]
    jev["dsh-wsl-jev 鈥?鍙€?]
  end
  llm["DeepSeek API 鎴栨湰鏈?Ollama"]
  chats["椋炰功 / 浼佸井 / 閽夐拤 / QQ / Slack / Discord / Telegram"]
  vault["Windows Obsidian vault锛圢TFS锛?]

  browser --> relay --> dsh
  dsh --> plugins
  dsh --> llm
  plugins --> host
  chats --> im --> dsh
  obsidian --> vault
  dsh --> obsidian
```

| 杈圭晫 | 璋佽礋璐?|
|------|--------|
| Windows 鐣岄潰 | 娴忚鍣ㄥ紑 `:3081`锛孶RL 甯︿竴娆℃€?`?token=`锛堣８ `:3081` 鏄?401锛沗:3080` 鍙粰 WSL锛?|
| Agent | WSL 閲岀殑 `dsh web`锛屽伐鍏疯蛋鎻掍欢 `ctx` |
| 璺ㄧ郴缁?| 鏃ュ父鎻掍欢锛坄path`銆乣open`銆乣clipboard`銆乣browser`銆乣launch`銆乣net`銆乣fetch`锛?|
| IM | `dsh-wsl-im` 鍑虹珯 WS/Stream/Gateway 鈫?`ctx.agents`銆傛瘡涓?IM 涓€涓伐浣滃尯锛屾瘡涓亰澶╀竴鏉′細璇?|
| Obsidian | `dsh-wsl-obsidian`锛歐SL agent 鈫?Windows NTFS vault + `obsidian://`銆備笉杩?`install.sh` |
| Jev | `dsh-wsl-jev`锛歋ystem One 鍐崇瓥锛坄jev_ask` / `check` / `rank`锛夛紝OpenRouter 鎴?TypeSafe銆備笉杩?`install.sh` |

## 鎻掍欢鐗堟湰

涓嬮潰鏄?**2026-09-18** 鏈満鍏勫紵浠撶殑 `package.json`銆俒`scripts/check-plugin-versions.sh`](./scripts/check-plugin-versions.sh) 閲岀殑鍦版澘鏄笅闄愶紝涓嶆槸杩欎唤蹇収銆?
褰撳ぉ鏈満 dsh 鏄?**`0.1.6-alpha.1`**锛坄alpha` 鏍囩锛夈€傛湰鏂囦笅闈㈠吋瀹硅〃閲岃緝鏃╄涓嬬殑 npm `latest` 浠嶆槸 **`0.1.5-rc.1`**銆傝剼鏈粛鎸?dsh **鈮?.1.2** 缂栧啓銆?
### 鏃ュ父

| 鎻掍欢 | 鐗堟湰 | 妗ｄ綅 |
|------|------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | 0.3.0 | daily |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | 0.5.2 | daily |
| [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) | 0.1.2 | daily |
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | 0.2.0 | daily |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | 0.1.2 | daily |
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | 0.1.2 | daily |
| [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) | 0.1.0 | daily |
| [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) | 0.2.0 | daily |
| [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | 0.1.0 | daily |
| [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) | 0.1.0 | daily |

### GitHub 闄勫姞涓庡彲閫?
| 鎻掍欢 | 鐗堟湰 | 妗ｄ綅 |
|------|------|------|
| [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | 0.2.0 | github |
| [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | 0.2.0 | github |
| [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) | 0.1.0 | github |
| [dsh-wsl-im](https://github.com/173787247/dsh-wsl-im) | 0.3.2 | 涓嶅湪 `install.sh` |
| [dsh-wsl-obscura](https://github.com/173787247/dsh-wsl-obscura) | 0.1.0 | 涓嶅湪鏃ュ父濂椾欢 |
| [dsh-wsl-obsidian](https://github.com/173787247/dsh-wsl-obsidian) | 0.1.0 | 涓嶅湪 `install.sh`锛堝彲閫夛級 |
| [dsh-wsl-jev](https://github.com/173787247/dsh-wsl-jev) | 0.1.0 | 涓嶅湪 `install.sh`锛堝彲閫夛級 |
| [dsh-wsl-ollama](https://github.com/173787247/dsh-wsl-ollama) | 0.1.0 | 涓嶅湪 `install.sh`锛堝彲閫夛級 |
| [dsh-wsl-media](https://github.com/173787247/dsh-wsl-media) | 0.1.0 | 涓嶅湪 `install.sh`锛堝彲閫夛級 |
| [dsh-wsl-search](https://github.com/173787247/dsh-wsl-search) | 0.1.0 | 涓嶅湪 `install.sh`锛堝彲閫夛級 |
| [dsh-wsl-vecmem](https://github.com/173787247/dsh-wsl-vecmem) | 0.1.0 | 涓嶅湪 `install.sh`锛堝彲閫夛級 |
| [dsh-wsl-k8s](https://github.com/173787247/dsh-wsl-k8s) | 0.1.0 | 涓嶅湪 `install.sh`锛堝彲閫夛級 |
| [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) | 0.1.0 | 涓嶅湪 `install.sh`锛堝彲閫夛級 |

### 瀹屾暣濂椾欢鍏朵綑鎻掍欢

| 鎻掍欢 | 鐗堟湰 | 鎻掍欢 | 鐗堟湰 |
|------|------|------|------|
| [gpu](https://github.com/173787247/dsh-wsl-gpu) | 0.2.2 | [port](https://github.com/173787247/dsh-wsl-port) | 0.2.2 |
| [distro](https://github.com/173787247/dsh-wsl-distro) | 0.2.0 | [workspace](https://github.com/173787247/dsh-wsl-workspace) | 0.2.0 |
| [picker](https://github.com/173787247/dsh-wsl-picker) | 0.1.0 | [tray](https://github.com/173787247/dsh-wsl-tray) | 0.2.4 |
| [expose](https://github.com/173787247/dsh-wsl-expose) | 0.2.2 | [hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) | 0.4.3 |
| [clock](https://github.com/173787247/dsh-wsl-clock) | 0.2.0 | [dns](https://github.com/173787247/dsh-wsl-dns) | 0.2.0 |
| [mnt](https://github.com/173787247/dsh-wsl-mnt) | 0.2.0 | [editor](https://github.com/173787247/dsh-wsl-editor) | 0.1.0 |
| [shot](https://github.com/173787247/dsh-wsl-shot) | 0.1.0 | [docker](https://github.com/173787247/dsh-wsl-docker) | 0.2.2 |
| [ssh-agent](https://github.com/173787247/dsh-wsl-ssh-agent) | 0.2.0 | [encoding](https://github.com/173787247/dsh-wsl-encoding) | 0.2.0 |
| [wslconfig](https://github.com/173787247/dsh-wsl-wslconfig) | 0.2.0 | [download](https://github.com/173787247/dsh-wsl-download) | 0.2.0 |

鍏辩敤搴?[dsh-wsl-common](https://github.com/173787247/dsh-wsl-common) `0.1.0` 涓嶆槸 `KIT_SET` 鐨勪竴椤广€?
---

## 鍏煎鎬э紙2026-09锛?
| 椤?| 鐜扮姸 |
|----|------|
| **dsh** | 濂椾欢绾у凡鍦?**`0.1.5-rc.1`** 楠岃瘉锛?026-09-10 鏃?npm `latest`锛涘皻鏃犻潪 rc 鐨?`0.1.5`锛夈€傛湰鏈?2026-09-16 鍐掔儫鐢ㄧ殑鏄?**`0.1.6-alpha.1`**锛坄alpha` 鏍囩锛涘崌绾ф椂 `latest` 浠嶆槸 `0.1.5-rc.1`锛夈€傝剼鏈寜 dsh **鈮?.1.2** 鐨?UI 涓€娆℃€?`?token=`锛坄:3081`锛夌紪鍐欍€?|
| **DeepSeek V4.1 Flash** | 瀹樻柟 API 妯″瀷 id 涓?**`deepseek-flash`**銆傛棫鍚?`deepseek-v4-flash` / `deepseek-v4-flash-vision-exp` 鏆傛椂浼氳矾鐢卞埌 V4.1 Flash銆?*鏈?kit 涓嶅啓姝绘ā鍨?*鈥斺€斿湪 `~/.dsh/settings.yaml` 鐨?`llm-deepseek` / 榛樿妯″瀷閲屾敼銆?|
| **Agent Teams** | 鍙€夊疄楠屽寘锛坄@deepseek-ai/dsh-experimental-agent-team-profile`锛屼笌 dsh 鍚岀増鏈嚎锛夈€?*涓嶅湪** `install.sh` 閲屻€傚紑浜?Teams 浼氬嚭鐜版洿闀跨殑 鈥淒eep diving鈥濓紱娴嬫ā鍨嬭鍏堢敤鏅€氭柊浼氳瘽銆?|
| **鎻掍欢** | 蹇収瑙佷笂鏂?[鎻掍欢鐗堟湰](#鎻掍欢鐗堟湰)锛?026-09-16 鍏勫紵浠擄級銆傚湴鏉胯 [`scripts/check-plugin-versions.sh`](./scripts/check-plugin-versions.sh)銆傛棩甯稿浠跺惈 [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) **鈮?.1.1**銆?|

### 瀛愭彃浠?README 绾﹀畾

- **鏈吋瀹硅〃鏄浠剁煩闃靛敮涓€鐪熸簮銆?* 鍚勫瓙鎻掍欢 README锛堜腑鑻憋級閮芥湁瀵瑰簲鐨?**鍏煎鎬?* 琛細鏈€浣?dsh **鈮?.1.2**銆侀摼鍥炴澶勭湅**鏈€鏂伴獙璇?*銆佸浠舵。浣嶏紝骞惰鏄庝簯绔?Flash / Agent Teams 涓嶅綊 WSL 鎻掍欢绠°€?- 姣忓綋 dsh 鍙戞柊绾匡紙濡?`0.1.5` 姝ｅ紡鐗堟垨 `0.1.6`锛夛紝**鍏堟敼鏈?kit 琛?*锛屽啀鍒锋柊鍚勬彃浠躲€屽綋鍓?鈥︺€嶈锛堟垨璺戞枃妗ｅ悓姝ワ級銆傛病鏈夊啋鐑熼€氳繃灏变笉瑕佽櫄鏋勩€屽凡楠岃瘉銆嶆棩鏈熴€?- API 鏁忔劅鎻掍欢锛坄net` / `fetch` / `port` / `expose` / `tray` / `hostsvc`锛夊彟鏈?**鑼冨洿** 娈碉紱钖?Daily 宸ュ叿鍙繚鐣欏叡鐢ㄨ〃鍗冲彲銆?
浠呮崲鍒?V4.1 Flash **涓嶅繀**鏀?kit 瀹夎閫昏緫锛涜嫢榛樿妯″瀷浠嶆槸宸查€€褰?id锛屾敼 settings 鍗冲彲銆?
---

## 60 绉掍笂鎵嬶紙鎺ㄨ崘锛氭棩甯稿浠讹級

**鍓嶆彁锛?* WSL 閲屽凡鑳借繍琛?`dsh`锛堥€氬父 profile = `web`锛夈€傚缓璁?`0.1.5-rc.1` 鎴栧悓绯诲垪鏇存柊銆?
```sh
curl -fsSL https://raw.githubusercontent.com/173787247/dsh-wsl-kit/master/install.sh \
  | KIT_SET=daily bash
```

鐒跺悗锛?
1. 鐢?[`scripts/restart-dsh-web.sh`](./scripts/restart-dsh-web.sh) 閲嶅惎锛坄:3080` dsh + `:3081` Windows 涓户锛?2. Windows 娴忚鍣ㄦ墦寮€ **`restart-dsh-web.sh` 鎵撳嵃鐨?URL**锛坉sh 鈮?.1.2 甯?`?token=`锛涜８ `:3081` 鏄?401銆備笉瑕佺敤 `:3080`锛夈€俆oken 涔熷啓鍦?WSL `/tmp/dsh-ui-url`銆?3. 寮€涓€涓?*鏂颁細璇?*锛堟棫浼氳瘽浠嶆槸鏃у伐鍏烽泦锛?4. 鍙€夛細鎶?[`cordis.patch.yml`](./cordis.patch.yml) 鍚堝苟杩?profile锛堝悗鍐欑殑鎻掍欢 `config` 浼?*鏁存鏇挎崲**锛岄敭瑕佸啓鍏級

| 鎯宠浠€涔?| 鍛戒护 |
|----------|------|
| **鏃ュ父锛堥粯璁ゆ帹鑽愶級** | `KIT_SET=daily bash install.sh` |
| 鏃ュ父 + GitHub App / 鍑嵁 | `KIT_SET=github bash install.sh` |
| **鏈湴 LLM + 缃戠粶璇婃柇** | `KIT_SET=llm bash install.sh` |
| 鍏ㄥ妗?| `KIT_SET=full bash install.sh`锛堟垨涓嶈 `KIT_SET`锛屽吋瀹规棫琛屼负锛?|

鏈湴鍏嬮殕鍚庯細`KIT_SET=daily bash install.sh`

### `restart-dsh-web.sh` 浼氬姞杞戒粈涔?
- `NODE_USE_ENV_PROXY=1`锛宍OLLAMA_API_KEY` 榛樿 `ollama`
- `NO_PROXY` **浠?* `127.0.0.1,localhost`锛堜笉瑕佺户鎵?Clash 鐨?RFC1918 `NO_PROXY` 閫氶厤锛屽惁鍒?Node 缁曡繃浠ｇ悊锛岃闂?`api.deepseek.com` 浼?TRANSPORT 瓒呮椂锛?- GitHub App锛氬惎鍔ㄥ墠鑷 `source "$HOME/.dsh/dsh-wsl-github.env"`

---

## 浣犻┈涓婅兘鐢ㄧ殑鑳藉姏

| 鐥涚偣 | 宸ュ叿 | 鎻掍欢 |
|------|------|------|
| 浠ｇ悊 / Node 24 鎵撲笉閫?DeepSeek 鎴?npm | `net_doctor` | [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) |
| `web_fetch` 鎶?`TypeError: fetch failed`锛圓PI 鍗撮€氾級 | 瑁?[dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) 鈮?.1.1 + `restart-dsh-web.sh` | [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) |
| 鑱婂ぉ閲岀殑 Linux 璺緞瑕佸湪 Windows 鎵撳紑 | 锛堝彲鐐瑰嚮璺緞锛?| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) |
| 璺緞浜掕浆銆乣/mnt/c` 鎱?| `path_convert` | [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) |
| 璇诲啓 Windows 鍓创鏉?| `wsl_clipboard` | [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) |
| 鍦?Windows 娴忚鍣ㄦ墦寮€ PR / 鏂囨。閾炬帴 | `win_open_url` | [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) |
| Agent 涓嶇煡閬撹嚜宸卞湪 WSL | 锛堟敞鍏?system prompt锛?| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) |

**鏃ュ父濂椾欢** = 涓婅〃 + `win_launch` + `dsh-repeat-stop` + `dsh-tool-budget` + **`dsh-wsl-fetch`**銆?
鍐掔儫锛氬鏂颁細璇濊銆岃窇涓€涓?`net_doctor`銆嶃€屾妸褰撳墠璺緞鎷峰埌 Windows 鍓创鏉裤€嶃€備簯绔紭鍏堥€?**`deepseek-flash`**锛涚涓€娆″啋鐑熷厛鍏虫帀 Agent Teams銆?
---

## 瀹夎缁勫悎锛堢煭鍚嶅崟锛?
| 缁勫悎 | 鍖呭惈 | 閫傚悎璋?|
|------|------|--------|
| **鏃ュ父** | env銆乶et銆?*fetch**銆乷pen銆乺epeat-stop銆乼ool-budget銆乧lipboard銆乸ath銆乥rowser銆乴aunch | 缁濆ぇ澶氭暟 WSL + Windows 娴忚鍣ㄧ敤鎴?|
| **GitHub 鏃ュ父** | 鏃ュ父 + [github](https://github.com/173787247/dsh-wsl-github) + [cred](https://github.com/173787247/dsh-wsl-cred) + notify | 杩樿鏌?PR/Actions銆佷慨 `git push` 鍑嵁 |
| **鏈湴 LLM** | env銆乶et銆?*fetch**銆乭ostsvc銆乨ocker銆乨ns銆乧lock銆乬pu銆乸ort銆乪xpose銆乼ray銆乷pen銆乸ath銆乥rowser | Ollama / vLLM / Unsloth + 杩為€氭€?|
| **瀹屾暣** | [`install.sh`](./install.sh) 鍏ㄩ儴 | 璇婃柇 GPU/Docker/鏃堕挓銆佹墭鐩樺惎鍔ㄣ€乸ortproxy 绛?|

**涓嶈**涓€涓婃潵瑁呭畬鏁村鈥斺€斿厛鏃ュ父璺戦€氾紝鍐嶆寜鐥涚偣鍔犳彃浠躲€?
### GitHub 鏃ュ父锛堝彲閫夛級

WSL 閲岀 GitHub = 鍑嵁 + API + 娴忚鍣ㄦ墦寮€ + 浠ｇ悊锛屼笉鏄竴涓ぇ鎻掍欢鑳界硦寮勭殑銆傝 `KIT_SET=github` 鍚庯細

1. 鎸?[dsh-wsl-github](https://github.com/173787247/dsh-wsl-github/blob/master/README.zh.md) 鍒涘缓 GitHub App锛堝彧璇?Metadata / PR / Actions锛屽叧 webhook锛?2. 鍚姩鍓嶏細`source "$HOME/.dsh/dsh-wsl-github.env"`
3. 鏂颁細璇濋噷璺?`github_app_hint` / `github_repo_status`锛?*涓嶈**鎶?PEM / PAT 璐磋繘鑱婂ぉ

---

## Node 24 + Windows 浠ｇ悊

Clash / V2Ray 鍦?Windows銆乄SL 瑕佽蛋浠ｇ悊鏃讹細

```sh
export HTTP_PROXY=http://127.0.0.1:7890   # 鎴?Clash mixed锛屽 16006
export HTTPS_PROXY=http://127.0.0.1:7890
export NODE_USE_ENV_PROXY=1
# 鎺ㄨ崘鐢?restart-dsh-web.sh锛屼繚璇?NO_PROXY 鍙湁鍥炵幆
```

浠嶄笉閫?鈫?璁?Agent 璺?`net_doctor`銆?
- **API 閫氥€乣web_fetch` 澶辫触** 鈫?[dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch)锛堟棩甯稿浠跺凡瑁咃級銆?- **绗笁鏂?Workers / Cloudflare 缁?Clash 杩斿洖 403锛?010锛?* 鈫?瀵硅鍩熷悕鍔?Clash **DIRECT**锛堟彃浠舵敼涓嶄簡绔欑偣 WAF锛夈€?
鏈湴 Ollama / LM Studio 绛夊湪 Windows 涓婏細鍔?[dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc)锛岃窇 `host_reach`锛屽啀鍚堝苟 [`examples/local-llm-providers.settings.yaml`](./examples/local-llm-providers.settings.yaml)銆?
---

## 鏁呴殰鏍?
杩炰笉涓?Ollama銆丄PI銆乬it push銆乣web_fetch` 鏃跺厛鐪?**[docs/TROUBLESHOOTING.zh.md](./docs/TROUBLESHOOTING.zh.md)**锛堣嫳鏂囷細[TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)锛夈€?
鎺ㄨ崘椤哄簭锛歚host_reach` 鈫?`net_doctor` 鈫?`dns_doctor` 鈫?`clock_doctor` 鈫?workspace/mnt 鈫?expose锛堜粎 LAN锛夈€?
---

## 瀹屾暣鎻掍欢鐩綍锛堟寜闇€鏌ラ槄锛?
<details>
<summary>鐐瑰嚮灞曞紑鍏ㄩ儴鎻掍欢琛?/summary>

### 鏃ュ父锛圞IT_SET=daily锛?
| 鎻掍欢 | 浣滅敤 |
|------|------|
| [dsh-wsl-env](https://github.com/173787247/dsh-wsl-env) | 鍚?system prompt 娉ㄥ叆 WSL/Windows 浜嬪疄 |
| [dsh-wsl-net](https://github.com/173787247/dsh-wsl-net) | `net_doctor` |
| [dsh-wsl-fetch](https://github.com/173787247/dsh-wsl-fetch) | 璁?`web_fetch` 璧?Windows 浠ｇ悊锛坲ndici `ProxyAgent`锛?|
| [dsh-wsl-open](https://github.com/173787247/dsh-wsl-open) | 鑱婂ぉ璺緞鍦?Windows 鎵撳紑 |
| [dsh-repeat-stop](https://github.com/173787247/dsh-repeat-stop) | 杩炵画鐩稿悓宸ュ叿璋冪敤纭嫤鎴?|
| [dsh-tool-budget](https://github.com/173787247/dsh-tool-budget) | 浼氳瘽绾у伐鍏锋鏁颁笂闄?|
| [dsh-wsl-clipboard](https://github.com/173787247/dsh-wsl-clipboard) | `wsl_clipboard` |
| [dsh-wsl-path](https://github.com/173787247/dsh-wsl-path) | `path_convert` |
| [dsh-wsl-browser](https://github.com/173787247/dsh-wsl-browser) | `win_open_url` |
| [dsh-wsl-launch](https://github.com/173787247/dsh-wsl-launch) | `win_launch`锛堢櫧鍚嶅崟锛?|

### GitHub 闄勫姞

| 鎻掍欢 | 浣滅敤 |
|------|------|
| [dsh-wsl-github](https://github.com/173787247/dsh-wsl-github) | `github_app_hint` / `github_repo_status` |
| [dsh-wsl-cred](https://github.com/173787247/dsh-wsl-cred) | `cred_hint`锛堜笉杈撳嚭瀵嗛挜锛?|
| [dsh-wsl-notify](https://github.com/173787247/dsh-wsl-notify) | `win_notify` |

### 璇婃柇 / UI / 浜屾闃?
| 鎻掍欢 | 浣滅敤 |
|------|------|
| [dsh-wsl-gpu](https://github.com/173787247/dsh-wsl-gpu) | `gpu_doctor` |
| [dsh-wsl-port](https://github.com/173787247/dsh-wsl-port) | `port_doctor` |
| [dsh-wsl-distro](https://github.com/173787247/dsh-wsl-distro) | `distro_info` |
| [dsh-wsl-workspace](https://github.com/173787247/dsh-wsl-workspace) | `wsl_workspace` |
| [dsh-wsl-picker](https://github.com/173787247/dsh-wsl-picker) | `wsl_picker` |
| [dsh-wsl-tray](https://github.com/173787247/dsh-wsl-tray) | `wsl_tray` |
| [dsh-wsl-expose](https://github.com/173787247/dsh-wsl-expose) | `wsl_expose` |
| [dsh-wsl-hostsvc](https://github.com/173787247/dsh-wsl-hostsvc) | `host_reach` |
| [dsh-wsl-clock](https://github.com/173787247/dsh-wsl-clock) | `clock_doctor` |
| [dsh-wsl-dns](https://github.com/173787247/dsh-wsl-dns) | `dns_doctor` |
| [dsh-wsl-mnt](https://github.com/173787247/dsh-wsl-mnt) | `mnt_doctor` |
| [dsh-wsl-editor](https://github.com/173787247/dsh-wsl-editor) | `win_editor` |
| [dsh-wsl-shot](https://github.com/173787247/dsh-wsl-shot) | `win_shot` |
| [dsh-wsl-docker](https://github.com/173787247/dsh-wsl-docker) | `docker_doctor` |
| [dsh-wsl-ssh-agent](https://github.com/173787247/dsh-wsl-ssh-agent) | `ssh_agent_hint` |
| [dsh-wsl-encoding](https://github.com/173787247/dsh-wsl-encoding) | `encoding_doctor` |
| [dsh-wsl-wslconfig](https://github.com/173787247/dsh-wsl-wslconfig) | `wslconfig_hint` |
| [dsh-wsl-download](https://github.com/173787247/dsh-wsl-download) | `win_download` |

鍙€夌浉鍏筹細[session-contract](https://github.com/173787247/session-contract)銆俛wesome 鐗囨锛歔`awesome-wsl-kit.md`](./awesome-wsl-kit.md)銆?
**Awesome 鐜扮姸锛?026-09锛夛細** `173787247` 涓嬪凡鏀跺綍 **32** 涓彃浠讹紙鍚?[fetch](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/blob/main/data/plugins/173787247__dsh-wsl-fetch.yml) [#4736](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/4736)銆乕obscura](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/blob/main/data/plugins/173787247__dsh-wsl-obscura.yml) [#4903](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/4903)锛夈€?*鏈?kit 鍏冧粨涓嶈繘 awesome** 鈥?鐢ㄦ湰浠?/ `install.sh` 瀹夎銆?
</details>

---

## kit 涔嬪鎬庝箞闀?
宸茬粡钀藉湴鐨勪笉瑕佸啀褰撴柊鏂瑰悜閲嶅紑锛坄fetch` 0.1.2銆乣obscura`銆佺増鏈湴鏉裤€?01 鍋ュ悍妫€鏌ャ€乣hostsvc` `apiReady`銆乣:3081` token 涓户锛夈€傚彧鏈夋柊浜у搧鎵嶅紑鏂颁粨銆傞拤閽夋病鏈夎嚜宸辩殑浠撱€?
| 鏂瑰悜 | 瑙勫垝 | 鐜扮姸锛?026-09-17锛?|
|------|------|-------------------|
| 椋炰功 / 浼佸井 / 閽夐拤 / QQ / Slack / Discord / Telegram | 宸叉槸 [dsh-wsl-im](https://github.com/173787247/dsh-wsl-im)銆傜户缁湪閭ｄ釜浠撳仛娣憋紝**涓嶈**鏀捐繘 `install.sh`銆傞暱杩炴帴瑕佸嚟璇佸拰 `HTTPS_PROXY`锛學SL 鐩磋繛杩欏嚑瀹朵細瓒呮椂銆?| **0.3.2** 鍚?Slack Socket Mode銆丏iscord Gateway銆乀elegram `getUpdates`锛堝榻?OryxOS 鍑虹珯鍨嬶紱涓嶅仛 webhook 娓犻亾锛夈€俛wesome 宸插悎 [#5222](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/pull/5222)銆?|
| Obsidian | [dsh-wsl-obsidian](https://github.com/173787247/dsh-wsl-obsidian) 0.1.0锛歷ault 鏀?NTFS锛坄/mnt/c|d/...`锛夛紝宸ュ叿 `obsidian_*` + `obsidian://` 鎵撳紑銆?*涓嶈**鏀捐繘 `install.sh`銆?| 鍙€夈€傚崟鐙?`dsh plugin --profile web add github:173787247/dsh-wsl-obsidian`銆傚噯澶?awesome 鏀跺綍銆?|
| Jev / System One | [dsh-wsl-jev](https://github.com/173787247/dsh-wsl-jev) 0.1.0锛氳嚜寤哄伐鍏风洿杩?OpenRouter/TypeSafe System One锛坄noul`/`choice`/`score`锛夛紝涓嶄緷璧栫涓夋柟 Jev 鎻掍欢銆?*涓嶈**鏀捐繘 `install.sh`銆?| 鍙€夈€傞渶瑕?`OPENROUTER_API_KEY` 鎴?`TYPESAFE_API_KEY` + `HTTPS_PROXY`銆?|
| 鏈湴 Ollama | [dsh-wsl-ollama](https://github.com/173787247/dsh-wsl-ollama) 0.1.0锛歚ollama_status/list/chat/embed`銆?| 鍙€夈€?|
| 濯掍綋 CLI | [dsh-wsl-media](https://github.com/173787247/dsh-wsl-media) 0.1.0锛歠fprobe / pdftotext / whisper銆?| 鍙€夈€?|
| 娌欑妫€绱?| [dsh-wsl-search](https://github.com/173787247/dsh-wsl-search) 0.1.0锛歳g + fd銆?| 鍙€夈€?|
| 鍚戦噺灏忚 | [dsh-wsl-vecmem](https://github.com/173787247/dsh-wsl-vecmem) 0.1.0锛歄llama embedding + `~/.dsh/vecmem`銆?| 鍙€夈€?|
| kubectl 鍙 | [dsh-wsl-k8s](https://github.com/173787247/dsh-wsl-k8s) 0.1.0锛歡et/describe/logs銆?| 鍙€夈€?|
| 瀵嗛挜鍙 | [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) 0.1.0锛歱ass/age + allowPrefixes銆?| 鍙€夈€?|
| [dsh-wsl-secret](https://github.com/173787247/dsh-wsl-secret) | 0.1.0 | 涓嶅湪 `install.sh`锛堝彲閫夛級 |
| MCP | 鐢ㄤ笂娓?[`@deepseek-ai/dsh-mcp-client`](https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/mcp/mcp-client/README.md)锛屽啓鍦?`cordis.patch.yml`锛屼竴鍙版湇鍔″櫒涓€涓疄渚嬨€備笉鏄?WSL 鎻掍欢銆?| 涓嶈繘 kit |
| OpenClaw | 鐙珛杩愯鏃躲€備笉瑕佹妸瀹冪殑娓犻亾鎼繘鏈?kit銆傚悓涓€涓?Bot 鍙兘涓€鏉￠暱杩炴帴锛屼笉瑕佸拰 `dsh-wsl-im` 鍚屾椂鎸傚悓涓€涓?Bot銆?| 涓嶈繘 kit |
| Agent Teams | 涓婃父瀹為獙鍖咃紝涓嶈繘 `install.sh`銆?| 涓嶈繘 kit |
| 钖?UX | editor / shot / notify / picker | 鏆傜紦 |

---

## 瀹夊叏

- 鎻掍欢涓?Harness 鍚屾潈锛堣鏂囦欢銆佽仈缃戙€佺粡 PowerShell 璋?Windows锛夈€?- `win_launch` 鏈夌櫧鍚嶅崟锛沗cred_hint` / GitHub App **涓?*鎶婂瘑閽ヨ创杩涘璇濄€?- `win_notify` 浼氶樆濉炲脊绐楋紝鏂囨鍕垮惈瀵嗛挜銆?- `~/.dsh/*.env` 淇濇寔 `chmod 600`锛屽嬁鎶?API Key 鎻愪氦杩涗粨搴撱€?
## Topics

`deepseek-harness` 路 `dsh-plugin` 路 `wsl` 路 `windows` 路 `github-app`

## 璁稿彲

MIT锛堜笌鍚勫瓙鎻掍欢鐩稿悓锛夈€?