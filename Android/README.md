# 安卓客户端

适用于 Android 8.0（API 26）及以上。APK 安装到手机后，手机通过 Wi-Fi / 局域网直接给电视安装应用，不需要 root，也不需要电脑。

本地构建产物：`dist/xiaomi-tv-app-installer-Android.apk`。应用不包含 native 库，不限 ARM / x86 CPU 架构。

## 操作

1. 电视开启普通网络 ADB，手机与电视接入同一局域网。
2. 发现电视，或手动输入电视 IP。默认端口为 5555。
3. 首次连接需要在电视上授权此手机。手机会保存自己的 ADB 信任密钥，和电脑端的授权分开管理。
4. 从系统文件选择器选取手机中的 APK，确认电视地址后开始安装。
5. 多个独立 APK 会顺序安装；同一应用的 base 与 split 文件需选齐并勾选拆分 APK。

安卓端实现普通 TCP ADB（RSA 授权、shell、SYNC），当前不支持 Android 配对式 TLS 无线调试。如果电视只有配对码端口，可使用桌面客户端。扫描最多覆盖本机所在 /24，仅检查 5555；其他普通 ADB 端口可手动输入。

仅需要 `INTERNET` 和 `ACCESS_NETWORK_STATE` 普通权限。文件选择使用系统 SAF，不申请所有文件权限，不申请在手机上安装其他应用的权限。APK 经手机缓存直接发往电视，不上传云端。正常退出或清空文件时删除本次缓存；原始 APK 不会被删除。系统强制终止后遗留的缓存可通过应用存储设置清理。

应用目标 SDK 为 36。按照 [Android 官方说明](https://developer.android.com/privacy-and-security/local-network-permission)，目标 SDK 36 或以下仍通过 `INTERNET` 权限访问局域网。

## 构建

提供标准 Android Gradle 项目，使用 AGP 8.13.2、JDK 17+、compile/target SDK 36、min SDK 26。也可以使用 `Scripts/build-android.sh` 直接调用官方 AAPT2、javac、D8、zipalign 和 apksigner，避免依赖 Gradle 下载。

在常规 SDK 环境中执行：

```bash
TV_INSTALLER_JAVA_HOME="$JAVA_HOME" \
TV_INSTALLER_ANDROID_JAR="$ANDROID_HOME/platforms/android-36/android.jar" \
TV_INSTALLER_ANDROID_TOOLS="$ANDROID_HOME/build-tools/36.0.0" \
bash Scripts/build-android.sh
```

Gradle 构建也可使用 `gradle :app:assembleDebug`；debug 签名用于开发，不能直接替换已经安装的 release 版本。

release 签名密钥与随机密码保存于项目的 `.signing/`，已被 Git 忽略，不包含在 APK 中。**请保留并备份 `.signing/`，后续 APK 更新必须使用同一密钥。**

## 验证

安卓协议核心使用标准 Java 编写，同一份代码可在电脑上测试。已完成 45 项协议检查（包含首次授权公钥交换），以及对真实小米电视的 RSA 认证、shell、SYNC 上传与读取回验。真实电视测试复用已有的电脑授权密钥，仅在测试进程使用，不包含在 APK 中。

已通过 APK v2 / v3 签名校验。尚未完成安卓手机 / 模拟器上的界面与文件选择器实测，也未在真实电视上验证本安卓客户端的拆分安装流程。
