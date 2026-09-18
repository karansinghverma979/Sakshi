using System.IO;
using System.Text.Json;

namespace Apex.Core;

public static class BlacklistManager
{
    private static readonly string BlacklistDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Apex");
    private static readonly string BlacklistPath = Path.Combine(BlacklistDir, "blacklist.json");
    private static readonly HashSet<string> _blacklisted = new(StringComparer.OrdinalIgnoreCase);

    static BlacklistManager()
    {
        Load();
    }

    public static void Load()
    {
        try
        {
            if (File.Exists(BlacklistPath))
            {
                var json = File.ReadAllText(BlacklistPath);
                var items = JsonSerializer.Deserialize<List<string>>(json);
                if (items != null)
                {
                    _blacklisted.Clear();
                    foreach (var item in items)
                    {
                        if (!string.IsNullOrWhiteSpace(item))
                        {
                            _blacklisted.Add(item.Trim());
                        }
                    }
                }
            }
        }
        catch { }
    }

    public static void Save()
    {
        try
        {
            Directory.CreateDirectory(BlacklistDir);
            var json = JsonSerializer.Serialize(_blacklisted.OrderBy(x => x).ToList(), new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(BlacklistPath, json);
        }
        catch { }
    }

    public static bool IsBlacklisted(string processName)
    {
        if (string.IsNullOrWhiteSpace(processName)) return false;
        return _blacklisted.Contains(processName.Trim());
    }

    public static void Add(string processName)
    {
        if (string.IsNullOrWhiteSpace(processName)) return;
        if (_blacklisted.Add(processName.Trim()))
        {
            Save();
        }
    }

    public static void Remove(string processName)
    {
        if (string.IsNullOrWhiteSpace(processName)) return;
        if (_blacklisted.Remove(processName.Trim()))
        {
            Save();
        }
    }

    public static IReadOnlySet<string> GetAll() => _blacklisted;

    public static int Count => _blacklisted.Count;
}
