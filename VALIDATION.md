# 验证记录

验证日期：2026-10-10（Asia/Shanghai）。

## 已完成

- `Scripts/test.sh`：35 项检查全部通过。覆盖 IP 与端口校验、设备与 mDNS 解析、真实子网与扫描范围、指定目标安装、特殊字符文件名、拆分 APK 参数、错误退出码和超时终止。安装成功与失败输出使用临时模拟 ADB 验证。
- 使用与应用共用的 `PortProbe`、`LAN`、`ADBClient` 扫描一个家庭 /24 局域网，自动发现小米电视的 5555 端口。
- 正确读取真实设备型号 `MiTV-MFFU0`、Android 14、`arm64-v8a,armeabi-v7a,armeabi`。
- Apple Silicon Mac 上启动正式 `.app`，检查连接状态、布局、文件队列和完成结果。
- 在打开的应用中选择并安装两个独立 APK，界面最终显示成功 2 项、失败 0 项。未额外向电视安装模拟 APK。
- 应用构建包含 arm64 与 x86_64 两个架构；`codesign --verify --deep --strict` 通过。
- `Info.plist` 格式校验通过；ZIP 分发包已生成。

## 验证范围

本次真实设备验证覆盖常规 5555 网络连接和两个独立 APK 的顺序安装。尚未在真实设备上验证无线配对、拆分 APK、不同小米固件或 Intel Mac 运行。应用的「安装成功」来自 ADB 返回结果；未验证第三方应用的内容服务或遥控器适配。

## 输出

- `dist/电视安装助手.app`
- `dist/电视安装助手-macOS.zip`

为本地 ad-hoc 签名，未 Apple 公证。
