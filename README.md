# 电视安装助手

在 macOS 上通过局域网 ADB 给小米、Redmi 和其他支持网络 ADB 的 Android 电视安装 APK。

## 下载

在 [GitHub Releases](https://github.com/enderkidleaf/xiaomi-tv-app-installer/releases) 下载 `电视安装助手-macOS.zip`，解压后双击应用。无需另外安装 ADB。

## 使用

1. 双击 `dist/电视安装助手.app`。支持 macOS 13 及以上，Apple Silicon 和 Intel Mac。
2. 电视开启 ADB 调试，电脑和电视接入同一局域网。macOS 提示本地网络权限时选择允许。
3. 点击「发现电视」，或输入电视 IP（默认端口 5555），点击连接。在电视上确认调试授权。
4. 选择目标电视，拖入 APK 或点击选择文件，然后点击「开始安装」。
5. 安装成功后在电视的应用列表打开。操作日志可以导出。

配对方式：如果电视有「无线调试 → 使用配对码配对」，点击「无线配对」，填入配对地址、6 位配对码和连接地址。配对端口和连接端口通常不同，以电视显示为准。

默认多个 APK 按独立应用依次安装。若选择同一应用的 base 和 split APK，勾选「拆分 APK」，所有文件会作为一次安装提交。XAPK、APKM、AAB 不支持直接安装。

更新使用 `-r` 保留已有应用数据。工具不自动卸载、不降级、不绕过电视安装限制。停止后续安装会等待当前安装结束。

## 查找与连接

- 扫描所选 IPv4 网卡的真实子网，最多扫描本机所在的 /24（不超过 253 个其他地址），仅检测 TCP 5555。
- 同时通过官方 ADB 的 mDNS 查询无线连接服务，以支持动态端口。
- 大网络的其他地址、自定义端口或未广播的设备可使用手动 `IP:端口`。
- 仅列出网络 ADB 设备，显示设备返回的真实型号、Android 版本和架构。无法保证所有 ADB 设备都是小米电视，请确认安装目标。
- 开启 ADB 调试不一定开放网络端口；此工具不能远程开启被固件关闭的服务。某些型号需要电视端额外设置或初始 USB 调试。
- 电视重启后端口或 IP 可能变化，重新发现或查看电视网络设置。
- 超时或不可达时，确认 IP、电视电源、访客网络和客户端隔离设置。

## 数据与分发

所有 APK 通过本机 ADB 直接发往所选电视，不上传云端，无遥测。日志保存在当前内存会话，只有点击导出才会写出文件。配对码不保存；官方 ADB 会在用户目录管理调试信任密钥。使用已运行的本机 ADB 服务，不会全局断开其他设备或停止 ADB 服务。

应用为本地构建并使用 ad-hoc 签名，未经过 Apple 公证。分发到其他 Mac 时，系统可能要求通过系统设置 → 隐私与安全性 → 仍要打开确认来源。本机可直接运行。通用指 macOS 上支持不同局域网和电视型号，不包含 Windows/Linux 客户端。

## 构建与验证

需要 Xcode Command Line Tools（Swift 6 / macOS SDK）。

```bash
bash Scripts/build.sh
bash Scripts/test.sh
```

构建脚本在 `Resources/adb` 缺失时从 Google 官方下载 Platform Tools；正式应用内置 ADB，不需要用户另行安装 Python、Node、Homebrew 或 Android Studio。

连接诊断：

```bash
bash Scripts/prepare-build.sh
swiftc -vfsoverlay .build/swift-overlay.json -swift-version 5 -module-cache-path .build/module-cache Sources/Core.swift Scripts/diagnose.swift -o .build/diagnose
.build/diagnose --scan
```

构建时会下载官方 ADB 及其第三方声明，并生成应用图标；这些生成文件不提交到源码仓库。发布包中的第三方声明见 `电视安装助手.app/Contents/Resources/ADB-NOTICE.txt`。官方参考：[ADB 文档](https://developer.android.com/tools/adb)、[Platform Tools](https://developer.android.com/tools/releases/platform-tools)、[小米电视调试设置](https://www.mi.com/tw/support/article/KA-17750/)。
