namespace TVAppInstaller;

static class Program
{
    [STAThread]
    static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();
        Application.Run(new MainForm(args.Where(x => x.EndsWith(".apk", StringComparison.OrdinalIgnoreCase)).ToArray()));
    }
}
