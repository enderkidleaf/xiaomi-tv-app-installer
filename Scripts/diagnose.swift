import Foundation

@main struct Diagnostics {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let client = ADBClient(executable: root.appendingPathComponent("Resources/adb"))
        let networks = LAN.current()
        for network in networks { print("LAN: \(network.description), hosts: \(network.hosts.count)") }
        if CommandLine.arguments.contains("--scan"), let network = networks.first {
            let hosts = PortProbe.scan(network) { _, _ in }
            print("TCP 5555: \(hosts)")
            for host in hosts { print(try client.run(["connect", "\(host):5555"]).output) }
        }
        for device in try client.enrichedDevices() {
            print("DEVICE: \(device.serial) | \(device.title) | \(device.state) | Android \(device.android) | \(device.architecture)")
        }
    }
}
