using System.Text;
using System.Text.Json;

namespace TVAppInstaller;

sealed class PreparationForm : Form
{
    readonly JsonDocument guide;
    readonly ComboBox device = new() { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Fill };
    readonly ComboBox mode = new() { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Fill };
    readonly RichTextBox content = new() { Dock = DockStyle.Fill, ReadOnly = true, BorderStyle = BorderStyle.None, BackColor = Color.White, DetectUrls = true, ScrollBars = RichTextBoxScrollBars.Vertical, WordWrap = true };
    public PreparationForm()
    {
        using var stream = typeof(PreparationForm).Assembly.GetManifestResourceStream("PreparationGuide.json") ?? throw new IOException("未找到内置准备教程，请重新安装完整应用包。");
        guide = JsonDocument.Parse(stream);
        Text = "连接前准备教程"; Size = new Size(800, 780); MinimumSize = new Size(650, 580);
        StartPosition = FormStartPosition.CenterParent; Font = new Font("Microsoft YaHei UI", 10); BackColor = Color.FromArgb(247, 247, 242); AutoScaleMode = AutoScaleMode.Dpi;
        var root = new TableLayoutPanel { Dock = DockStyle.Fill, Padding = new Padding(22), RowCount = 6, ColumnCount = 1 };
        root.RowStyles.Add(new RowStyle(SizeType.Absolute, 40)); root.RowStyles.Add(new RowStyle(SizeType.Absolute, 55));
        root.RowStyles.Add(new RowStyle(SizeType.Absolute, 42)); root.RowStyles.Add(new RowStyle(SizeType.Absolute, 42));
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); root.RowStyles.Add(new RowStyle(SizeType.Absolute, 44)); Controls.Add(root);
        root.Controls.Add(new Label { Text = Text, AutoSize = true, Font = new Font(Font.FontFamily, 18, FontStyle.Bold) }, 0, 0);
        root.Controls.Add(new Label { Text = guide.RootElement.GetProperty("intro").GetString(), Dock = DockStyle.Fill }, 0, 1);
        device.Items.AddRange(["手机 / 平板", "电视 / 机顶盒"]); mode.Items.AddRange(["普通网络 ADB", "无线调试配对", "先用 USB 开启"]);
        root.Controls.Add(Choice("目标设备", device), 0, 2); root.Controls.Add(Choice("连接方式", mode), 0, 3);
        root.Controls.Add(content, 0, 4);
        var close = new Button { Text = "关闭", AutoSize = true, Anchor = AnchorStyles.Right, DialogResult = DialogResult.Cancel }; root.Controls.Add(close, 0, 5); CancelButton = close;
        content.LinkClicked += (_, e) => { if (e.LinkText is string url && Uri.TryCreate(url, UriKind.Absolute, out var parsed) && parsed.Scheme == "https") System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(url) { UseShellExecute = true }); };
        device.SelectedIndexChanged += (_, _) => Render(); mode.SelectedIndexChanged += (_, _) => Render(); device.SelectedIndex = 0; mode.SelectedIndex = 0;
    }
    static Control Choice(string title, Control control)
    {
        var row = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2 };
        row.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 90)); row.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        row.Controls.Add(new Label { Text = title, AutoSize = true, Anchor = AnchorStyles.Left }); row.Controls.Add(control); return row;
    }
    void Render()
    {
        if (device.SelectedIndex < 0 || mode.SelectedIndex < 0) return;
        string type = device.SelectedIndex == 0 ? "phone" : "tv", method = new[] { "tcp", "pair", "usb" }[mode.SelectedIndex];
        var result = new StringBuilder(); int step = 0;
        foreach (var section in guide.RootElement.GetProperty("sections").EnumerateArray())
        {
            string? d = section.GetProperty("device").GetString(), m = section.GetProperty("mode").GetString();
            if ((d == "all" || d == type) && (m == "all" || m == method)) result.AppendLine($"{++step}. {section.GetProperty("title").GetString()}").AppendLine().AppendLine(section.GetProperty("body").GetString()?.Replace("\n", "\r\n")).AppendLine();
        }
        result.AppendLine("官方参考 · 步骤随设备型号和系统变化");
        foreach (var source in guide.RootElement.GetProperty("sources").EnumerateArray()) result.AppendLine(source.GetProperty("title").GetString()).AppendLine(source.GetProperty("url").GetString()).AppendLine();
        content.Text = result.ToString(); content.SelectionStart = 0; content.ScrollToCaret();
    }
    protected override void Dispose(bool disposing) { if (disposing) guide.Dispose(); base.Dispose(disposing); }
}
