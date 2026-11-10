# Coreio

iOS AI 客户端，Bundle ID：`ai.Coreio.app`，App 名称：**Coreio**。

## 工程内容

```
Coreio/
├── project.yml                  # XcodeGen 工程描述（推荐用它生成 .xcodeproj）
├── README.md
└── Coreio/
    ├── CoreioApp.swift          # App 入口 / 根视图
    ├── Info.plist
    ├── Assets.xcassets/         # 应用图标（驴头黑白图标，1024）
    ├── Models/
    │   ├── Conversation.swift    # 消息 / 会话模型
    │   └── AppSettings.swift     # API 配置、外观、终端权限模式持久化
    ├── Networking/
    │   ├── APIClient.swift        # OpenAI 兼容 Chat Completions 请求
    │   ├── ToolRegistry.swift     # 工具（Function Calling）注册中心
    │   └── TimeTool.swift         # 示例工具，演示接入方法
    ├── Store/
    │   └── ConversationStore.swift# 会话增删改查 / 归档
    └── Views/
        ├── Onboarding/APIConfigView.swift   # 首屏：API 地址 / Key / 模型 ID + 测试请求
        ├── Main/MainChatView.swift          # 主聊天界面 + 侧边抽屉
        ├── Main/SidebarView.swift           # 新对话 / 删除 / 归档 / 底部入口
        ├── Settings/SettingsView.swift      # 更换 API 模型、深浅色、工具列表、关于
        └── Tools/
            ├── DeviceToolsView.swift         # 设备工具：越狱检测 + 终端
            └── ShellExecutor.swift           # 越狱环境 Shell 执行与三档权限
```

## 重要说明：IPA 需要在 Mac 上编译导出

当前交付的是**完整 Xcode 源码工程**。IPA 必须用 macOS 上的 Xcode 工具链编译并签名，
Linux / 云端环境没有 Xcode，无法直接产出可安装的签名 `.ipa`。拿到源码后按下面步骤在 Mac 上打包。

## 一、生成 Xcode 工程（推荐）

前置：Mac 安装 Xcode 15 或更高、Homebrew。

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 进入工程根目录（包含 project.yml 的目录）
cd Coreio

# 3. 生成 .xcodeproj
xcodegen

# 4. 用 Xcode 打开
open Coreio.xcodeproj
```

### 兜底：不用 XcodeGen，手动建工程

1. Xcode → New → Project → iOS → App；
2. Product Name 填 `Coreio`，Bundle Identifier 填 `ai.Coreio.app`，Interface 选 SwiftUI，Language 选 Swift，最低版本 iOS 16；
3. 把本目录 `Coreio/` 下除 `Info.plist`、`Assets.xcassets` 外的所有 `.swift` 文件拖进工程（保持勾选 Copy items 按需）；
4. 用本工程的 `Assets.xcassets` 与 `Info.plist` 覆盖新建工程中的对应文件；
5. Target → General → App Icon 选择 `AppIcon`。

## 二、编译并导出 IPA

1. 连上真机（终端工具依赖越狱环境，模拟器无法验证 Shell 执行）；
2. Xcode 顶部设备选 **Any iOS Device (arm64)** 或你的真机；
3. 菜单 **Product → Archive**；
4. Archive 完成后在 Organizer 里点 **Distribute App**：
   - 开发签名：选 Development → 导出 IPA，用 Sideloadly / AltStore 侧载；
   - 越狱设备：导出后可用 TrollStore 安装（需对应 iOS 版本的 TrollStore 支持）；
5. 若只需在自己设备调试：直接 Xcode 点运行（⌘R）安装到真机。

## 三、GitHub Actions 云端打包（不用自己的 Mac）

工程已内置 `.github/workflows/build-ipa.yml`，跑在 GitHub 的 macOS runner 上：
自动安装 XcodeGen → 生成工程 → 编译（关闭签名）→ 打包未签名 IPA → 作为 workflow artifact 上传。

### 推送仓库

```bash
git init
git add .
git commit -m "Coreio initial"
git branch -M main
git remote add origin https://github.com/<你的账号>/<仓库名>.git
git push -u origin main
```

### 触发与下载

1. 推到 `main` 后 Action 自动跑；也可在仓库 **Actions** 页手动 **Run workflow**；
2. 跑完进入该次运行 → 下拉到 **Artifacts** → 下载 `Coreio-ipa`；
3. 解压得到 `Coreio-unsigned.ipa`，用 Sideloadly / AltStore 侧载，或 TrollStore 安装（越狱设备）。

### 关于签名

默认 workflow 产出的是**未签名 IPA**（`CODE_SIGNING_ALLOWED=NO`），用于侧载重签名。
要在 Actions 里直接出签名 IPA，需要在仓库 **Settings → Secrets and variables → Actions** 配置：

| Secret | 内容 |
| --- | --- |
| `CERT_P12_BASE64` | 开发者证书 `.p12` 的 Base64 |
| `CERT_PASSWORD` | p12 导出密码 |
| `PROFILE_BASE64` | 对应描述文件 `.mobileprovision` 的 Base64 |

配好后把打包步骤改为 `xcodebuild -exportArchive`，并用 `exportOptions.plist` 指定 `method = development`。
免费 Apple ID 签名有效期 7 天；Actions 环境无法走交互式 Apple ID 登录，自动签名需手动证书 + 描述文件。

## 功能对照

- **首屏接入**：API 地址、ApiKey、模型 ID；点「继续」自动发一条最小测试请求，HTTP 2xx 即进入主界面。
- **主界面**：SwiftUI 系统风格；左上角三条杠打开侧边栏。
- **侧边栏**：开启新对话、删除对话、归档 / 取消归档；底部入口为「设置」「设备工具」。
- **设置**：更换 API 地址 / Key / 模型 ID；浅色 / 深色 / 跟随系统；已注册工具列表；Bundle ID 信息。
- **设备工具**：自动检测 Rootless / Roothide / 未越狱；终端权限三档：
  - 按需确认（ask）：每条命令执行前弹窗确认；
  - 风险确认（risk）：仅高危命令（rm、sudo、dd、kill、launchctl、chmod 等）弹窗；
  - 全部允许（allow）：不弹窗直接执行，**有风险，请谨慎使用**。

## 新增一个工具（Skill / Function Calling）

1. 实现 `Tool` 协议：

```swift
struct MyTool: Tool {
    let schema = ToolSchema(
        name: "my_tool",
        description: "工具用途说明",
        parameters: [
            "arg1": ToolParameter(type: "string", description: "参数说明")
        ]
    )

    func run(arguments: [String: Any]) async throws -> String {
        // 在这里实现工具逻辑，返回纯文本结果回传给模型
        return "结果"
    }
}
```

2. 在 `CoreioApp.swift` 的 `onAppear` 里注册：

```swift
registry.register(MyTool())
```

注册后聊天请求会自动带上 `tools` 字段。预设模型名不在工程内写死，由你在 API 配置里填写。

## 安全与风险提示

- 终端命令在越狱环境下以设备权限执行，误操作（删除、改权限、改挂载）可能导致系统或数据异常；
- 「全部允许」模式不会再弹窗确认，建议日常保持「按需确认」；
- ApiKey 仅保存在本机 UserDefaults，不会上传到除你填写的 API 地址以外的地方。
