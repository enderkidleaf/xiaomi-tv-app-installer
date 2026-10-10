import SwiftUI

private struct PreparationContent: Decodable {
    struct Section: Decodable { let device: String; let mode: String; let title: String; let body: String }
    struct Source: Decodable { let title: String; let url: String }
    let title: String; let intro: String; let sections: [Section]; let sources: [Source]
    static func load() -> PreparationContent? {
        guard let url = Bundle.main.url(forResource: "PreparationGuide", withExtension: "json"), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

struct PreparationGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var device = "phone"
    @State private var mode = "tcp"
    private let guide = PreparationContent.load()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("连接前准备教程", systemImage: "book.closed").font(.system(size: 22, weight: .bold))
                Spacer()
                Button("关闭") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            if let guide = guide {
                Text(guide.intro).font(.system(size: 12)).foregroundStyle(.secondary)
                Picker("目标设备", selection: $device) {
                    Text("手机 / 平板").tag("phone")
                    Text("电视 / 机顶盒").tag("tv")
                }.pickerStyle(.segmented)
                Picker("连接方式", selection: $mode) {
                    Text("普通网络 ADB").tag("tcp")
                    Text("无线调试配对").tag("pair")
                    Text("先用 USB 开启").tag("usb")
                }.pickerStyle(.segmented)
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        let sections = guide.sections.filter { ($0.device == "all" || $0.device == device) && ($0.mode == "all" || $0.mode == mode) }
                        ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(index + 1). \(section.title)").font(.system(size: 14, weight: .semibold))
                                Text(section.body).font(.system(size: 13)).lineSpacing(4).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                        Text("官方参考 · 步骤随设备型号和系统变化").font(.system(size: 12, weight: .semibold))
                        ForEach(guide.sources, id: \.url) { source in
                            if let url = URL(string: source.url) { Link(source.title, destination: url).font(.system(size: 12)) }
                        }
                    }.padding(.trailing, 12).padding(.bottom, 12)
                }.id(device + mode)
            } else {
                Text("未找到内置教程，请重新安装完整应用包。").foregroundStyle(.secondary)
                Spacer()
            }
        }.padding(28).frame(width: 720, height: 700).background(Color(red: 0.97, green: 0.97, blue: 0.95))
    }
}
