using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace Apex.Core;

public class WindowItem : INotifyPropertyChanged
{
    public IntPtr Hwnd { get; init; }
    public uint Pid { get; init; }
    public string ProcessName { get; init; } = string.Empty;
    public string Title { get; init; } = string.Empty;
    public Guid DesktopId { get; init; }
    public string DesktopName { get; set; } = "All Desktops";
    public int DesktopOrder { get; init; } = 999;
    public bool IsCurrentDesktop { get; init; }
    public bool IsLocked { get; init; }
    public bool IsBlacklisted { get; init; }

    private bool _isTopmost;
    public bool IsTopmost
    {
        get => _isTopmost;
        set
        {
            if (_isTopmost != value)
            {
                _isTopmost = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(ButtonText));
                OnPropertyChanged(nameof(StatusTooltip));
            }
        }
    }

    public string ButtonText => IsLocked ? "🔒 LOCKED" : (IsTopmost ? "📌 TOPMOST" : "○ PIN");
    public string StatusTooltip => IsLocked 
        ? "System Inviolability Shield: Protected Overlay" 
        : (IsTopmost ? "Window is Always On Top. Click to Unpin." : "Click to Pin Window Always On Top.");

    public event PropertyChangedEventHandler? PropertyChanged;
    protected void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}
