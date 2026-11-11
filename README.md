# PayDemo · 支付流程演示（iOS / SwiftUI）

一个按“扫码 → 付款 → 成功 → 回首页”流程做的 iOS 演示工程。

> **这是演示应用**：没有网络代码、不接支付 SDK、不会产生任何真实扣款；付款页和成功页常驻“演示 / 非真实交易”标记，不可关闭。它使用自有品牌 PayDemo，不是对任何真实支付应用的克隆。

---

## 1. 当前状态（请先看这里）

这台 Mac 只装了 Command Line Tools，**没有 Xcode 和 iOS SDK**，所以工程**没有实际编译过**。已经完成的验证：

- `PayFlowDemo.xcodeproj/project.pbxproj` 结构校验（`plutil -lint` 通过），文件引用与磁盘一一对应；
- 21 个 Swift 文件的语法检查（`swiftc -parse` 全部通过）；
- 模型层（`ChatItem` / `ChatStore` / `PayTarget`）在 macOS SDK 上完整类型检查通过；
- 付款页、键盘、成功页、会话行、横幅在 macOS SDK 上带桩类型检查通过。

剩下的风险集中在 iOS 专属 API（`navigationBarDrawer`、`fullScreenCover`、`PhotosPicker`、`AVCaptureMetadataOutput` 等），都用的是标准写法。用 Xcode 15 / 16 打开后若有报错，把报错贴给我即可。

## 2. 运行

1. 双击 `PayFlowDemo.xcodeproj`；
2. 选中 target `PayFlowDemo` → **Signing & Capabilities** → 选择你自己的 Team；
   - Bundle Identifier 现在是 `com.example.paydemo`，建议改成你自己的（例如 `com.你的名字.paydemo`）；
3. 选一台 **iPhone 真机**（相机必须在真机上测）→ Run；
4. 首次启动会请求相机权限。

**模拟器**没有摄像头：用扫码页的「手动输入内容」，或者直接点首页的会话来进入付款页。

## 3. 功能

### 首页（会话列表）
- 右上角 `+`：扫一扫（演示）、新增会话、生成演示二维码、关于此演示、恢复示例数据；
- **长按会话**：编辑名称 / 图片或表情头像 / 头像颜色 / 最后一条消息 / 最后消息时间 / 消息免打扰、发起模拟支付、新增会话、删除会话；
- 左滑：删除 / 编辑；
- 点会话：直接对这个人发起一次模拟支付（不经过相机，方便模拟器演示）；
- 搜索框按名称或消息过滤。

### 扫码
- `AVFoundation` 相机预览 + `AVCaptureMetadataOutput` 二维码识别；
- 扫描框、手电筒、关闭、手动输入；
- 识别到内容后自动进入付款页。

### 付款页
- 显示演示对象名称（来自二维码文本或会话）；
- 数字键盘输入金额（最多 6 位整数 + 2 位小数）；
- 黄色提示卡「这是演示页面，不会扣款」+ 二维码原文片段；
- 「演示钱包（模拟）」；
- 点「模拟支付」进入成功页。

### 成功页
- 「模拟支付成功」+ 满屏斜向 `DEMO · 非真实交易` 水印；
- 点「完成」回到首页。

### 数据
- 会话列表保存为 `Application Support/PayFlowDemo/chats.json`；
- 图片头像压缩到 320pt 后保存为 `Application Support/PayFlowDemo/Avatars/*.jpg`；
- 全部在本机，卸载即清除。

## 4. 二维码里的“名字”是怎么读的

- `paydemo://pay?name=张三&amount=0.01` → 名称「张三」，金额 0.01（见「生成演示二维码」）；
- 任意 URL 里的 `name` / `title` / `nick` / `nickname`（以及中文 `名称` / `商户`）参数；
- 不超过 24 字、单行、不是 URL 的纯文本 → 直接作为名称；
- 其他内容（例如真实的 `wxp://...` 收款码）→ **不尝试解码**，界面显示「演示对象」，并展示原文片段。

最后一条是有意为之：把真实收款码里的真实姓名解出来、再配一个“支付成功”页，正是假付款工具的用法，所以这个工程不做。演示二维码用的是自己的 `paydemo://` 协议，足够走通整条流程。

## 5. 目录结构

```
PayFlowDemo.xcodeproj/          # 工程文件 + 共享 scheme
PayFlowDemo/
  App/PayFlowApp.swift          # @main，注入 ChatStore
  Models/
    ChatItem.swift              # 会话模型 + 示例数据
    ChatStore.swift             # JSON 持久化
    PayTarget.swift             # 演示对象 + 二维码文本解析
  Views/
    HomeView.swift              # 首页 / 长按菜单 / 入口
    ChatRow.swift               # 会话行
    ChatEditorView.swift        # 编辑 / 新增（含相册选头像）
    AvatarView.swift            # 图片或表情头像
    ScannerView.swift           # 相机扫码页
    CameraPreview.swift         # AVCaptureVideoPreviewLayer 包装
    PaymentFlowView.swift       # 付款页
    PaymentKeypad.swift         # 数字键盘
    SuccessCard.swift           # 成功页 + 水印
    DemoQRCodeView.swift        # 生成演示二维码
    DemoBanner.swift            # 顶部演示提示
    AboutDemoView.swift         # 边界说明
  Support/
    QRScannerController.swift   # AVFoundation 封装
    AvatarStore.swift           # 图片头像存储
    QRCodeImage.swift           # CoreImage 生成二维码
    Color+Hex.swift
    DemoTheme.swift
  Info.plist                    # 相机权限文案等
  Assets.xcassets               # AppIcon（¥ / DEMO）、颜色
Tools/
  make_pbxproj.py               # 从磁盘重新生成工程文件
  build-unsigned-ipa.sh         # 导出未签名 ipa
```

## 6. 新增/删除源文件后

Xcode 工程是脚本生成的。加删文件后执行：

```bash
python3 Tools/make_pbxproj.py
```

## 7. 导出未签名 IPA

```bash
./Tools/build-unsigned-ipa.sh
# 产出 PayFlowDemo-unsigned.ipa
```

然后用 Sideloadly / AltStore / TrollStore 自签安装。注意：未签名 ipa 不能直接双击安装。

## 8. 已知边界

- 只用 SwiftUI + AVFoundation + CoreImage，无第三方依赖，无网络；
- 未做 iPad 适配（`TARGETED_DEVICE_FAMILY = 1`），仅竖屏；
- 最低 iOS 16.0；
- 演示应用在任何页面都保留“演示 / 非真实交易”标识，不做移除开关。
