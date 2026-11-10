# Mihomo 系统级透明代理 (通用版)

基于 **Mihomo (Clash.Meta)** 的 Android 系统级通用透明代理 Magisk / KernelSU / APatch 模块。

无需运行客户端 App，手机状态栏**绝无 VPN 钥匙图标**，原生接管全局 TCP/UDP 与 DNS 流量，毫秒级直连，全链路防 DNS 泄漏与运营商穿透。

---

## ✨ 核心特性

- **纯内核级网络接管**：
  - 基于 Linux Netfilter / iptables 协议栈进行全局透明劫持，国内流量原生直连，海外流量无感代理；
  - 手机状态栏不占 VPN 插槽、无 VPN 钥匙标识，彻底避开应用层 VPN 检测。
- **全链路防 DNS 泄漏**：
  - 本地 53 端口精准重定向到 Mihomo 1053 Fake-IP 解析引擎；
  - 内置 **IPv6 漏网全面阻断** 机制，彻底阻断运营商 IPv6 DNS 穿透泄漏；
  - 强制屏蔽 QUIC（UDP 443）与 Android Private DNS（DoT 853），驱动流量走高优先级代理链路。
- **三重自适应订阅输入机制**：
  - **WebUI X / KernelSU WebUI**：已安装 WebUI X 组件的设备，点击【操作】直接弹出交互式管理窗口；
  - **手机浏览器自动唤起**：未安装任何 WebUI 组件的设备，点击【操作】会自动唤起系统默认浏览器（Chrome / Edge 等）打开本地轻量级控制台 (`http://127.0.0.1:9092`)，软键盘即点即出；
  - **`/sdcard/sub.txt` 免开网页法**：在手机存储根目录新建 `sub.txt` 粘贴链接，开机或点击【操作】自动静默读取导入。
- **开机自检与安全看门狗**：
  - 启动前自动探活网络网关与 DHCP 就绪状态；
  - 启动后若发生物理网络死锁或路由异常，5 秒内自动安全回滚至系统直连，**确保手机开机无论如何绝不断网**。
- **内置 MetacubexD 网页控制面板**：
  - 开箱即用，访问 `http://127.0.0.1:9091/ui` 即可切换节点、测速、查看连接与实时流量。

---

## 📱 兼容性支持

- **Root 环境**：Magisk (v20.4+) / KernelSU / APatch
- **CPU 架构**：`arm64-v8a` (aarch64)
- **Android 版本**：Android 10 - 15+

---

## 🚀 安装与使用

### 1. 刷入模块
1. 前往本仓库的 [Releases 页面](https://github.com/Aero-stack-max/Mihomo-TProxy/releases) 下载最新的 `Mihomo_TProxy_Universal_v1.2.zip`；
2. 打开 Magisk / KernelSU / APatch 应用，进入 **【模块】** -> **【从本地安装】** 并选中安装包；
3. 安装成功后**重启手机**。

### 2. 导入您的机场订阅链接
*重启开机后，模块默认处于直连安全状态（绝不影响初次使用断网）。选择以下任意一种方式导入订阅：*

- **方式 A（点击 Magisk 操作按钮，最推荐）**：
  1. 打开 Magisk，进入【模块】列表，找到 **【Mihomo 系统级透明代理 (通用版)】**；
  2. 点击右侧的 **`【操作】`（Action）** 按钮；
  3. 系统会自动唤起图形控制台（或直接自动调起手机浏览器打开 `http://127.0.0.1:9092`）；
  4. 点击输入框，长按屏幕粘贴您的订阅链接（支持 Clash YAML 与 Base64 格式），点击 **【⚡ 立即导入并生效节点】** 即可。

- **方式 B（免网页文件导入）**：
  1. 使用文件管理器在内部存储根目录（`/storage/emulated/0/` 或 `/sdcard/`）新建名为 **`sub.txt`** 的文本文件；
  2. 粘贴机场订阅链接并保存；
  3. 在 Magisk 中点击一下 **【操作】**（或重启手机），核心将自动提取导入。

- **方式 C（终端命令行）**：
  ```bash
  su -c "sh /data/adb/modules/mihomo_tproxy/update_sub.sh 'https://your-subscription-url'"
  ```

---

## 🌐 日常管理与控制台

* **节点切换面板 (MetacubexD)**：
  在手机浏览器中打开：
  ```text
  http://127.0.0.1:9091/ui
  ```
  可自由点选节点、切换自动测速策略组或查看分流规则。

* **订阅与服务控制页面**：
  在手机浏览器中打开：
  ```text
  http://127.0.0.1:9092
  ```

---

## 🛠 命令行快速管理

```bash
# 启动透明代理
su -c "sh /data/adb/modules/mihomo_tproxy/start.sh"

# 停止透明代理 (恢复直连)
su -c "sh /data/adb/modules/mihomo_tproxy/stop.sh"

# 刷新当前已存订阅
su -c "sh /data/adb/modules/mihomo_tproxy/update_sub.sh"

# 查看开机日志
su -c "cat /data/adb/modules/mihomo_tproxy/service.log"
```

---

## ⚖ 许可证

本项目基于 GPL-3.0 协议开源，核心组件基于 [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) 与 [MetaCubeX/metacubexd](https://github.com/MetaCubeX/metacubexd)。
