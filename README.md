# Coreio

iOS 端 AI 客户端 · Bundle ID `ai.Coreio.app` · 最低 iOS 16.0

## 功能

| 模块 | 说明 |
| --- | --- |
| 初始化 | API 地址 / API Key / 模型 ID，点「继续」自动发测试请求，模型回复里含 `1` 才进主界面 |
| 主界面 | 系统风 UI，左上角三条杠打开会话抽屉 |
| 会话 | 新建 / 删除（左滑）/ 归档（左滑 + 长按菜单）/ 已归档可恢复 |
| 聊天 | 流式输出、自动滚到底、可选文字 |
| 设置（底部） | 改地址 / Key / 模型（6 个常用服务商一键填）、深浅色（跟随系统 / 浅色 / 深色）、清空数据 |
| 设备工具（底部） | **只在 rootless 越狱且装了 OpenSSH 时出现**，AI 可调 SSH 改设备 |

## 目录

```
Coreio/
├─ Coreio.xcodeproj/project.pbxproj   # Xcode 16 同步文件夹工程，新增 Swift 文件自动进 target
├─ Coreio/
│  ├─ CoreioApp.swift                 # 入口
│  ├─ AppStore.swift                  # 状态 / 持久化 / 流式请求 / 工具执行
│  ├─ Models.swift                    # 数据模型 + 常用模型预设
│  ├─ LLMClient.swift                 # OpenAI 兼容接口（流式 + 非流式）
│  ├─ SSHClient.swift                 # rootless ssh 调用（posix_spawn）+ 风险评估
│  ├─ JailbreakEnv.swift              # 环境探测
│  ├─ Assets.xcassets/AppIcon         # 图标（你给的那张，已转 1024 去 alpha）
│  └─ Views/                          # Setup / Main / Drawer / Settings / DeviceTools
├─ Coreio.entitlements                # TrollStore 用越狱权限
├─ build.sh                           # 一键出 ipa
└─ .github/workflows/build-ipa.yml    # 没 Mac 可以云端打包
```

## 编译

**有 Mac：** 用 Xcode 16 打开 `Coreio.xcodeproj`，选真机 Run。或命令行：

```bash
cd Coreio
./build.sh            # 出 build/Coreio.ipa（未签名，TrollStore 直接装）
./build.sh --sign     # 额外 ldid -S Coreio.entitlements（需要 ldid）
```

**没 Mac：** 推到这个仓库，跑 GitHub Actions 的 `Build Coreio IPA`，下载 artifact 里的 `Coreio.ipa`。

## 安装

- **TrollStore**：直接把 `Coreio.ipa` 丢进去（会自动签名并带 platform 权限，`posix_spawn` 调 ssh 才有效）
- **正常自签 / AltStore / Sideloadly**：能装能用 AI 功能，但沙盒没解除 → 底部不会出现「设备工具」（代码里按 `/var/jb` + `/var/jb/usr/bin/ssh` 双重判断，本来就该隐藏）

## 初始化流程

1. 首屏填三项：地址（写到版本号即可，App 自动补 `/chat/completions`）、Key、模型 ID
2. 点「继续」→ 发送 `请只回复一个数字 1`
3. 回复里出现 `1` → 存配置、进主界面；否则报错并显示模型原始回复，可改模型重试

## 设备工具

- 检测条件：`/var/jb` 存在且能找到 `/var/jb/usr/bin/ssh`（rootless 越狱 + OpenSSH）
- 连接默认 `root@127.0.0.1:22`，密码一般 `alpine`；也支持填私钥路径走公钥登录
- 三种权限模式：
  - **按需确认**：每条命令都弹窗
  - **风险确认**：`ls/cat/ps/df/id` 这类只读命令直接跑；含重定向、`rm/mv/kill/reboot/chmod/apt` 等才弹窗
  - **全部允许**：不弹窗，直接执行
- 模型把命令写在 ` ```ssh ` 代码块里（一行一条），App 执行后把 stdout/stderr + exit code 作为工具输出回传，自动再请求一轮（最多 3 轮）

## 注意

- 工程用了 Xcode 16 的「文件系统同步组」，**Xcode 15 及以下打不开这个 pbxproj**；新版 Xcode 加文件不用改工程文件
- 所有配置和会话存在 UserDefaults，卸载会一起清掉
- 密码用 askpass 脚本喂给 ssh，不写死在二进制里；但仍建议改成私钥登录
