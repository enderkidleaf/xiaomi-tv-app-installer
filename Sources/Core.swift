import Foundation
import Darwin

enum ToolError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}

struct Endpoint: Equatable {
    let host: String
    let port: Int
    var address: String { "\(host):\(port)" }

    init(_ input: String, defaultPort: Int = 5555) throws {
        let pieces = input.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":", omittingEmptySubsequences: false)
        guard pieces.count == 1 || pieces.count == 2 else { throw ToolError.message("请输入 IPv4 地址，例如 192.168.1.73:5555。") }
        let parts = pieces[0].split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4, parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) && Int($0).map { (0...255).contains($0) } == true }) else {
            throw ToolError.message("IP 地址格式不正确，例如 192.168.1.73。")
        }
        let host = parts.map { String(Int($0)!) }.joined(separator: ".")
        guard let port = pieces.count == 2 ? Int(pieces[1]) : defaultPort, (1...65535).contains(port) else {
            throw ToolError.message("端口应在 1 到 65535 之间。")
        }
        guard !host.hasPrefix("127."), host != "0.0.0.0", !host.hasPrefix("255.") else {
            throw ToolError.message("请输入设备的局域网 IP 地址。")
        }
        self.host = host
        self.port = port
    }
}

struct Device: Identifiable, Equatable {
    let serial: String
    var state: String
    var model: String
    var manufacturer = ""
    var android = ""
    var architecture = ""
    var id: String { serial }
    var ready: Bool { state == "device" }
    var status: String {
        switch state {
        case "device": return "已连接"
        case "unauthorized": return "等待设备授权"
        case "offline": return "设备离线"
        default: return state
        }
    }
    var title: String { model.isEmpty ? "Android 设备" : model.replacingOccurrences(of: "_", with: " ") }
}

enum ADBParser {
    static func devices(_ output: String) -> [Device] {
        output.components(separatedBy: .newlines).compactMap { line in
            let words = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard words.count >= 2, ["device", "offline", "unauthorized"].contains(words[1]) else { return nil }
            // This app only installs through network ADB. Leave USB devices/emulators out of selection.
            guard words[0].contains(":") || words[0].hasPrefix("adb-") || words[0].contains("._adb-tls-connect.") else { return nil }
            let model = words.first(where: { $0.hasPrefix("model:") }).map { String($0.dropFirst(6)) } ?? ""
            return Device(serial: words[0], state: words[1], model: model)
        }
    }

    static func services(_ output: String, pairing: Bool = false) -> [Endpoint] {
        let service = pairing ? "_adb-tls-pairing._tcp" : "_adb-tls-connect._tcp"
        var seen = Set<String>()
        return output.components(separatedBy: .newlines).compactMap { line in
            let words = line.split(whereSeparator: \.isWhitespace)
            guard words.count >= 3, line.contains(service), let endpoint = try? Endpoint(String(words.last!)), seen.insert(endpoint.address).inserted else { return nil }
            return endpoint
        }
    }

    static func installArguments(serial: String, files: [URL], split: Bool) throws -> [String] {
        guard !serial.isEmpty, !files.isEmpty else { throw ToolError.message("请先选择设备和 APK 文件。") }
        try files.forEach(validateAPK)
        return ["-s", serial, split ? "install-multiple" : "install", "-r"] + files.map(\.path)
    }

    static func validateAPK(_ file: URL) throws {
        guard file.pathExtension.lowercased() == "apk" else { throw ToolError.message("请选择 .apk 文件；XAPK、APKM 和 AAB 不能直接安装。") }
        var directory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: file.path, isDirectory: &directory), !directory.boolValue,
              FileManager.default.isReadableFile(atPath: file.path) else { throw ToolError.message("无法读取文件：\(file.lastPathComponent)") }
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        guard try handle.read(upToCount: 4) == Data([0x50, 0x4b, 0x03, 0x04]) else {
            throw ToolError.message("\(file.lastPathComponent) 不是有效的 APK / ZIP 文件。")
        }
    }

    static func friendlyError(_ raw: String) -> String {
        if raw.contains("INSTALL_FAILED_UPDATE_INCOMPATIBLE") { return "签名与已安装版本不同。请使用同一来源的 APK；卸载旧版本会删除应用数据。" }
        if raw.contains("INSTALL_FAILED_VERSION_DOWNGRADE") { return "APK 版本低于设备上的已安装版本，请选择更新版本。" }
        if raw.contains("INSTALL_FAILED_NO_MATCHING_ABIS") { return "APK 的处理器架构不兼容，请选择与设备处理器架构匹配的版本。" }
        if raw.contains("INSTALL_FAILED_OLDER_SDK") { return "APK 要求更高的 Android 版本，请选择兼容版本。" }
        if raw.contains("INSTALL_FAILED_INSUFFICIENT_STORAGE") { return "设备存储空间不足，请先清理空间。" }
        if raw.contains("INSTALL_FAILED_USER_RESTRICTED") { return "设备限制了安装。请检查未知来源安装设置，并确认设备上的提示。" }
        if raw.contains("INSTALL_FAILED_MISSING_SPLIT") { return "这是拆分 APK。请选齐同一应用的 base 和 split 文件，并开启拆分 APK 模式。" }
        if raw.localizedCaseInsensitiveContains("unauthorized") || raw.contains("authenticate") { return "请在设备弹出的调试授权窗口选择「允许」，然后点击刷新状态。" }
        if raw.localizedCaseInsensitiveContains("refused") { return "设备未开放此 ADB 端口。请检查 ADB 调试开关，或使用无线调试页面显示的连接端口。" }
        if raw.localizedCaseInsensitiveContains("timed out") || raw.contains("Host is down") || raw.contains("No route") { return "无法访问设备。请确认设备已开机、IP 正确，电脑和设备在同一局域网，且没有访客网络或客户端隔离。" }
        if raw.contains("offline") || raw.contains("not found") || raw.contains("no devices") { return "设备离线，请重新连接设备。" }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct CommandResult {
    let code: Int32
    let output: String
    let timedOut: Bool
    var success: Bool { code == 0 && !timedOut }
}

/// Run without a shell: IP, pairing code and filenames are always separate arguments.
struct ADBClient {
    let executable: URL

    func run(_ arguments: [String], timeout: TimeInterval = 15, input: String? = nil) throws -> CommandResult {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        // A disk-backed output handle cannot deadlock on a full stdout pipe during an install.
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("tv-adb-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        let output = try FileHandle(forWritingTo: outputURL)
        defer { try? output.close(); try? FileManager.default.removeItem(at: outputURL) }
        process.standardOutput = output
        process.standardError = output
        let stdin = Pipe()
        process.standardInput = stdin
        let finished = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in finished.signal() }
        try process.run()
        if let input { try stdin.fileHandleForWriting.write(contentsOf: Data((input + "\n").utf8)) }
        try? stdin.fileHandleForWriting.close()
        let timedOut = finished.wait(timeout: .now() + timeout) == .timedOut
        if timedOut {
            process.terminate()
            if finished.wait(timeout: .now() + 2) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                _ = finished.wait(timeout: .now() + 2)
            }
        }
        let data = (try? Data(contentsOf: outputURL)) ?? Data()
        let text = String(decoding: data, as: UTF8.self)
        return CommandResult(code: process.isRunning ? -1 : process.terminationStatus,
                             output: text + (timedOut ? "\n连接或操作超时 (timed out)。" : ""), timedOut: timedOut)
    }

    func enrichedDevices() throws -> [Device] {
        let result = try run(["devices", "-l"])
        guard result.success else { throw ToolError.message(ADBParser.friendlyError(result.output)) }
        return ADBParser.devices(result.output).map { device in
            guard device.ready else { return device }
            var detail = device
            // Fixed commands; no interpolated user content is executed on the television.
            if let properties = try? run(["-s", device.serial, "shell", "getprop ro.product.model; getprop ro.product.manufacturer; getprop ro.build.version.release; getprop ro.product.cpu.abilist"], timeout: 6), properties.success {
                let values = properties.output.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                if values.count >= 4 {
                    detail.model = values[0]; detail.manufacturer = values[1]
                    detail.android = values[2]; detail.architecture = values[3]
                }
            }
            return detail
        }
    }
}

struct LAN: Identifiable, Equatable {
    let name: String
    let ip: String
    let mask: UInt32
    var id: String { name + ip }
    var prefix: Int { mask.nonzeroBitCount }
    var description: String { "\(name) · \(ip)/\(prefix)" }
    var scanDescription: String { prefix < 24 ? "网络较大，仅扫描本机所在的 /24；其他地址可手动连接" : "仅扫描此局域网的 ADB 端口 5555" }
    var hosts: [String] {
        guard let own = LAN.number(ip) else { return [] }
        let effectiveMask: UInt32 = mask < 0xffffff00 ? 0xffffff00 : mask
        let base = own & effectiveMask
        let end = base | ~effectiveMask
        guard end > base + 1 else { return [] }
        return ((base + 1)..<end).filter { $0 != own }.map(LAN.string)
    }
    static func number(_ ip: String) -> UInt32? {
        let parts = ip.split(separator: ".").compactMap { UInt32($0) }
        guard parts.count == 4, parts.allSatisfy({ $0 < 256 }) else { return nil }
        return parts.reduce(0) { ($0 << 8) | $1 }
    }
    static func string(_ ip: UInt32) -> String { [24,16,8,0].map { String((ip >> $0) & 255) }.joined(separator: ".") }

    static func current() -> [LAN] {
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0 else { return [] }
        defer { freeifaddrs(pointer) }
        var current = pointer
        var networks: [LAN] = []
        while let item = current {
            defer { current = item.pointee.ifa_next }
            let entry = item.pointee
            guard (entry.ifa_flags & UInt32(IFF_UP)) != 0, (entry.ifa_flags & UInt32(IFF_LOOPBACK)) == 0,
                  let address = entry.ifa_addr, Int32(address.pointee.sa_family) == AF_INET, let netmask = entry.ifa_netmask else { continue }
            let name = String(cString: entry.ifa_name)
            guard !name.hasPrefix("utun"), !name.hasPrefix("ipsec"), !name.hasPrefix("bridge"), !name.hasPrefix("awdl") else { continue }
            let addr = UnsafeRawPointer(address).assumingMemoryBound(to: sockaddr_in.self).pointee
            let mask = UnsafeRawPointer(netmask).assumingMemoryBound(to: sockaddr_in.self).pointee
            let ip = UInt32(bigEndian: addr.sin_addr.s_addr)
            guard ip >> 24 != 169, ip >> 24 != 127, mask.sin_addr.s_addr != 0 else { continue }
            networks.append(LAN(name: name, ip: string(ip), mask: UInt32(bigEndian: mask.sin_addr.s_addr)))
        }
        return networks.sorted { $0.name < $1.name }
    }
}

enum PortProbe {
    static func open(_ host: String, port: Int = 5555, timeoutMS: Int32 = 650) -> Bool {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        let flags = fcntl(fd, F_GETFL, 0)
        guard flags >= 0, fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0 else { return false }
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(port).bigEndian
        guard inet_pton(AF_INET, host, &addr.sin_addr) == 1 else { return false }
        let result = withUnsafePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.connect(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        if result == 0 { return true }
        guard errno == EINPROGRESS else { return false }
        var pollFD = pollfd(fd: fd, events: Int16(POLLOUT), revents: 0)
        guard poll(&pollFD, 1, timeoutMS) > 0 else { return false }
        var error: Int32 = 0
        var length = socklen_t(MemoryLayout<Int32>.size)
        return getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &length) == 0 && error == 0
    }

    static func scan(_ lan: LAN, progress: @escaping (Int, Int) -> Void) -> [String] {
        let hosts = lan.hosts
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 24
        let lock = NSLock()
        var found: [String] = []
        var count = 0
        for host in hosts {
            queue.addOperation {
                let reachable = open(host)
                lock.lock()
                if reachable { found.append(host) }
                count += 1
                progress(count, hosts.count)
                lock.unlock()
            }
        }
        queue.waitUntilAllOperationsAreFinished()
        return found.sorted()
    }
}
