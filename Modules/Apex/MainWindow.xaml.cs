using System.IO;
using System.Text.Json;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Threading;
using Apex.Core;

namespace Apex;

public partial class MainWindow : Window
{
    private record CardEntry(Border Card, StackPanel? ParentGroup, WindowItem? Item, string? BlockedProc);
    private readonly List<CardEntry> _cardCache = new();
    private uint _summonMsgId;
    private bool _isBlocklistView = false;
    private readonly DispatcherTimer _inactivityTimer = new();
    private int _secondsRemaining = 60;

    private static readonly string ConfigDir = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Apex");
    private static readonly string ConfigPath = Path.Combine(ConfigDir, "window_config.json");

    private class WindowConfig
    {
        public double Width { get; set; } = 780;
        public double Height { get; set; } = 650;
        public double? Left { get; set; }
        public double? Top { get; set; }
    }

    public MainWindow()
    {
        InitializeComponent();
        LoadWindowConfig();
        InitializeInactivityWatchdog();

        Loaded += MainWindow_Loaded;
        KeyDown += MainWindow_KeyDown;
        Closing += (s, e) => { _inactivityTimer.Stop(); SaveWindowConfig(); };
        Deactivated += (s, e) => SaveWindowConfig();
        LocationChanged += (s, e) => { if (IsLoaded) SaveWindowConfig(); };
        SizeChanged += (s, e) => { if (IsLoaded) SaveWindowConfig(); };
    }

    protected override void OnSourceInitialized(EventArgs e)
    {
        base.OnSourceInitialized(e);
        var handle = new WindowInteropHelper(this).Handle;
        var source = HwndSource.FromHwnd(handle);
        source?.AddHook(WndProc);

        _summonMsgId = App.RegisterWindowMessage(App.SummonMessageName);
    }

    private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (_summonMsgId != 0 && msg == _summonMsgId)
        {
            SummonToCurrentDesktopAndForeground();
            handled = true;
        }
        return IntPtr.Zero;
    }

    public void SummonToCurrentDesktopAndForeground()
    {
        var handle = new WindowInteropHelper(this).Handle;

        // 1. Teleport Apex directly to user's active virtual desktop
        Guid currentDesktop = VirtualDesktopHelper.GetCurrentDesktopId();
        if (currentDesktop != Guid.Empty)
        {
            VirtualDesktopHelper.MoveWindowToDesktop(handle, currentDesktop);
        }

        // 2. Restore if minimized
        if (WindowState == WindowState.Minimized)
        {
            WindowState = WindowState.Normal;
        }

        // 3. Bring to foreground & focus
        WindowManager.ShowWindow(handle, WindowManager.SW_RESTORE);
        WindowManager.SetForegroundWindow(handle);
        Activate();
        Topmost = true;

        // 4. Return to main windows view, reset filter and refresh
        _isBlocklistView = false;
        UpdateViewModeUI();
        txtFilter.Text = string.Empty;
        UpdateWindowTree();
        txtFilter.Focus();

        // 5. Reset 1-minute inactivity self-destruct watchdog on summon
        ResetInactivityTimer();
    }

    #region Inactivity Self-Destruct Watchdog
    private void InitializeInactivityWatchdog()
    {
        _secondsRemaining = 60;
        _inactivityTimer.Interval = TimeSpan.FromSeconds(1);
        _inactivityTimer.Tick += InactivityTimer_Tick;
        _inactivityTimer.Start();

        // Strictly consider only keyboard keystrokes and mouse button clicks (ignoring mouse moves & wheel scrolls)
        InputManager.Current.PostProcessInput += (s, e) =>
        {
            if (e.StagingItem.Input is KeyEventArgs or MouseButtonEventArgs or TextCompositionEventArgs)
            {
                ResetInactivityTimer();
            }
        };
    }

    private void ResetInactivityTimer()
    {
        _secondsRemaining = 60;
        if (txtAutoKillTimer != null)
        {
            txtAutoKillTimer.Text = "⏱️ 60s";
        }

        if (_inactivityTimer.IsEnabled)
        {
            _inactivityTimer.Stop();
            _inactivityTimer.Start();
        }
    }

    private void InactivityTimer_Tick(object? sender, EventArgs e)
    {
        _secondsRemaining--;
        if (_secondsRemaining > 0)
        {
            if (txtAutoKillTimer != null)
            {
                txtAutoKillTimer.Text = $"⏱️ {_secondsRemaining}s";
            }
        }
        else
        {
            if (txtAutoKillTimer != null)
            {
                txtAutoKillTimer.Text = "⏱️ 0s";
            }
            _inactivityTimer.Stop();
            SaveWindowConfig();
            Application.Current.Shutdown();
        }
    }
    #endregion

    private void LoadWindowConfig()
    {
        try
        {
            if (File.Exists(ConfigPath))
            {
                var json = File.ReadAllText(ConfigPath);
                var cfg = JsonSerializer.Deserialize<WindowConfig>(json);
                if (cfg != null)
                {
                    if (cfg.Width >= MinWidth) Width = cfg.Width;
                    if (cfg.Height >= MinHeight) Height = cfg.Height;

                    if (cfg.Left.HasValue && cfg.Top.HasValue)
                    {
                        double left = cfg.Left.Value;
                        double top = cfg.Top.Value;

                        // Ensure coordinates are within virtual desktop visible bounds
                        double minX = SystemParameters.VirtualScreenLeft - 40;
                        double maxX = SystemParameters.VirtualScreenLeft + SystemParameters.VirtualScreenWidth - 100;
                        double minY = SystemParameters.VirtualScreenTop - 40;
                        double maxY = SystemParameters.VirtualScreenTop + SystemParameters.VirtualScreenHeight - 100;

                        if (left >= minX && left < maxX && top >= minY && top < maxY)
                        {
                            WindowStartupLocation = WindowStartupLocation.Manual;
                            Left = left;
                            Top = top;
                            return;
                        }
                    }
                }
            }
        }
        catch { }

        // Fallback: If no config exists or coordinates were out of bounds, center on screen
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
    }

    private void SaveWindowConfig()
    {
        try
        {
            if (!IsLoaded || WindowState != WindowState.Normal) return;

            double w = ActualWidth >= MinWidth ? ActualWidth : Width;
            double h = ActualHeight >= MinHeight ? ActualHeight : Height;
            double l = Left;
            double t = Top;

            if (double.IsNaN(w) || double.IsNaN(h) || double.IsNaN(l) || double.IsNaN(t)) return;

            var cfg = new WindowConfig
            {
                Width = Math.Round(w, 1),
                Height = Math.Round(h, 1),
                Left = Math.Round(l, 1),
                Top = Math.Round(t, 1)
            };

            Directory.CreateDirectory(ConfigDir);
            File.WriteAllText(ConfigPath, JsonSerializer.Serialize(cfg));
        }
        catch { }
    }

    private void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        var handle = new WindowInteropHelper(this).Handle;
        WindowManager.SetRoundedCorners(handle);
        UpdateViewModeUI();
        UpdateWindowTree();
        txtFilter.Focus();
    }

    private void MainWindow_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            if (_isBlocklistView)
            {
                _isBlocklistView = false;
                UpdateViewModeUI();
                UpdateWindowTree();
            }
            else
            {
                Close();
            }
        }
        else if (e.Key == Key.F5)
        {
            UpdateWindowTree();
        }
    }

    private void PnlHeader_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed)
        {
            DragMove();
        }
    }

    private void BtnClose_Click(object sender, RoutedEventArgs e) => Close();

    private void BtnRefresh_Click(object sender, RoutedEventArgs e) => UpdateWindowTree();

    private void BtnBlocklistToggle_Click(object sender, RoutedEventArgs e)
    {
        // If blocklist is empty, do not open an empty window
        if (!_isBlocklistView && BlacklistManager.Count == 0)
        {
            txtStatus.Text = "ℹ️ Blocklist is empty. Click 🚫 next to any window to blacklist it.";
            return;
        }

        _isBlocklistView = !_isBlocklistView;
        UpdateViewModeUI();
        txtFilter.Text = string.Empty;
        UpdateWindowTree();
    }

    private void UpdateViewModeUI()
    {
        if (_isBlocklistView)
        {
            btnBlocklistToggle.Content = "← Windows";
            btnBlocklistToggle.BorderBrush = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF));
            btnBlocklistToggle.Foreground = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF));
            btnBlocklistToggle.Opacity = 1.0;
            txtFilterPlaceholder.Text = "🔍 Search blacklisted applications... (Esc to return)";
            btnUnpinAll.Visibility = Visibility.Collapsed;
        }
        else
        {
            int count = BlacklistManager.Count;
            btnBlocklistToggle.Content = $"🚫 Blocklist ({count})";
            btnBlocklistToggle.BorderBrush = new SolidColorBrush(Color.FromRgb(0x28, 0x28, 0x28));
            btnBlocklistToggle.Foreground = new SolidColorBrush(Color.FromRgb(0xCC, 0xCC, 0xCC));
            btnBlocklistToggle.Opacity = count > 0 ? 1.0 : 0.6;
            txtFilterPlaceholder.Text = "🔍 Type to filter windows across all desktops... (Esc to exit)";
            btnUnpinAll.Visibility = Visibility.Visible;
        }
    }

    private void BtnUnpinAll_Click(object sender, RoutedEventArgs e)
    {
        var windows = WindowManager.ScanWindows();
        int unpinned = 0;
        foreach (var w in windows)
        {
            if (w.IsTopmost && !w.IsLocked && !w.IsBlacklisted)
            {
                WindowManager.SetTopmost(w.Hwnd, false);
                unpinned++;
            }
        }

        if (unpinned > 0)
        {
            PlayAudioChime(false);
            txtStatus.Text = $"✨ Unpinned {unpinned} window(s) successfully.";
            UpdateWindowTree();
        }
        else
        {
            txtStatus.Text = "No user windows are currently pinned.";
        }
    }

    private void TxtFilter_TextChanged(object sender, TextChangedEventArgs e)
    {
        string query = txtFilter.Text.Trim().ToLowerInvariant();
        txtFilterPlaceholder.Visibility = string.IsNullOrEmpty(query) ? Visibility.Visible : Visibility.Collapsed;

        if (string.IsNullOrEmpty(query))
        {
            foreach (var entry in _cardCache)
            {
                entry.Card.Visibility = Visibility.Visible;
                if (entry.ParentGroup != null) entry.ParentGroup.Visibility = Visibility.Visible;
            }
            return;
        }

        if (_isBlocklistView)
        {
            foreach (var entry in _cardCache)
            {
                bool match = entry.BlockedProc != null && entry.BlockedProc.ToLowerInvariant().Contains(query);
                entry.Card.Visibility = match ? Visibility.Visible : Visibility.Collapsed;
            }
            return;
        }

        foreach (var group in pnlWindows.Children.OfType<StackPanel>())
        {
            bool hasVisible = false;
            foreach (var card in group.Children.OfType<Border>())
            {
                if (card.Tag is WindowItem item)
                {
                    bool match = item.Title.ToLowerInvariant().Contains(query) ||
                                 item.ProcessName.ToLowerInvariant().Contains(query) ||
                                 item.DesktopName.ToLowerInvariant().Contains(query);

                    card.Visibility = match ? Visibility.Visible : Visibility.Collapsed;
                    if (match) hasVisible = true;
                }
            }
            group.Visibility = hasVisible ? Visibility.Visible : Visibility.Collapsed;
        }
    }

    private void UpdateWindowTree()
    {
        pnlWindows.Children.Clear();
        _cardCache.Clear();

        if (_isBlocklistView)
        {
            RenderBlocklistView();
            return;
        }

        txtStatus.Text = "Scanning virtual desktops and windows...";

        var allWindows = WindowManager.ScanWindows();
        var windows = allWindows.Where(w => !w.IsBlacklisted).ToList();

        if (windows.Count == 0)
        {
            pnlWindows.Children.Add(new TextBlock
            {
                Text = "No active user windows found.",
                Foreground = new SolidColorBrush(Color.FromRgb(0x55, 0x55, 0x55)),
                HorizontalAlignment = HorizontalAlignment.Center,
                Margin = new Thickness(0, 40, 0, 0),
                FontSize = 13
            });
            txtStatus.Text = "Ready • 0 windows active";
            UpdatePinnedBadge(allWindows);
            return;
        }

        var groups = windows
            .GroupBy(w => new { w.DesktopName, w.DesktopOrder, IsCurrent = w.IsCurrentDesktop })
            .OrderBy(g => g.Key.DesktopOrder)
            .ThenBy(g => g.Key.DesktopName);
        int totalGroups = 0;

        foreach (var group in groups)
        {
            totalGroups++;
            var deskGroup = new StackPanel { Margin = new Thickness(0, 6, 0, 16) };

            string activeBadge = group.Key.IsCurrent ? "  •  ACTIVE" : "";
            string icon = group.Key.DesktopName.Contains("Pinned", StringComparison.OrdinalIgnoreCase) ? "📌" : "🖥️";

            // Desktop Header
            var hdrText = new TextBlock
            {
                Text = $"{icon}  {group.Key.DesktopName}{activeBadge} ({group.Count()})",
                FontSize = 14,
                FontWeight = FontWeights.Bold,
                Foreground = group.Key.IsCurrent 
                    ? new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF)) 
                    : new SolidColorBrush(Color.FromRgb(0x9E, 0x9E, 0x9E)),
                Margin = new Thickness(4, 0, 0, 10)
            };
            deskGroup.Children.Add(hdrText);

            foreach (var item in group)
            {
                var card = CreateWindowCard(item, deskGroup);
                _cardCache.Add(new CardEntry(card, deskGroup, item, null));
                deskGroup.Children.Add(card);
            }

            pnlWindows.Children.Add(deskGroup);
        }

        UpdatePinnedBadge(allWindows);
        txtStatus.Text = $"Ready • {windows.Count} windows active across {totalGroups} desktop spaces";
    }

    private void RenderBlocklistView()
    {
        txtStatus.Text = "Viewing Blacklisted Applications";
        var blockedList = BlacklistManager.GetAll().OrderBy(x => x).ToList();

        if (blockedList.Count == 0)
        {
            _isBlocklistView = false;
            UpdateViewModeUI();
            UpdateWindowTree();
            return;
        }

        var header = new TextBlock
        {
            Text = $"🚫  Blacklisted Processes ({blockedList.Count})",
            FontSize = 14,
            FontWeight = FontWeights.Bold,
            Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0x52, 0x52)),
            Margin = new Thickness(4, 0, 0, 12)
        };
        pnlWindows.Children.Add(header);

        foreach (var proc in blockedList)
        {
            var card = CreateBlacklistCard(proc);
            _cardCache.Add(new CardEntry(card, null, null, proc));
            pnlWindows.Children.Add(card);
        }
    }

    private void UpdatePinnedBadge(List<WindowItem>? scannedWindows = null)
    {
        UpdateViewModeUI();

        var list = scannedWindows ?? WindowManager.ScanWindows();
        int pinnedCount = list.Count(w => w.IsTopmost && !w.IsLocked && !w.IsBlacklisted);
        int lockedCount = list.Count(w => w.IsLocked && !w.IsBlacklisted);
        int totalPinned = pinnedCount + lockedCount;

        txtPinnedCount.Text = $"📌 {totalPinned} Pinned";

        if (totalPinned > 0)
        {
            badgePinnedCount.Background = new SolidColorBrush(Color.FromRgb(0x1F, 0x1A, 0x05));
            badgePinnedCount.BorderBrush = new SolidColorBrush(Color.FromRgb(0xFF, 0xB3, 0x00));
            txtPinnedCount.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0xD5, 0x4F));
            btnUnpinAll.IsEnabled = pinnedCount > 0;
            btnUnpinAll.Opacity = pinnedCount > 0 ? 1.0 : 0.4;
        }
        else
        {
            badgePinnedCount.Background = new SolidColorBrush(Color.FromRgb(0x14, 0x14, 0x14));
            badgePinnedCount.BorderBrush = new SolidColorBrush(Color.FromRgb(0x28, 0x28, 0x28));
            txtPinnedCount.Foreground = new SolidColorBrush(Color.FromRgb(0x88, 0x88, 0x88));
            btnUnpinAll.IsEnabled = false;
            btnUnpinAll.Opacity = 0.4;
        }
    }

    private static ControlTemplate CreateCurvedCapsuleTemplate()
    {
        var template = new ControlTemplate(typeof(Button));
        var borderFactory = new FrameworkElementFactory(typeof(Border));
        borderFactory.SetValue(Border.CornerRadiusProperty, new CornerRadius(16));
        borderFactory.SetBinding(Border.BackgroundProperty, new System.Windows.Data.Binding("Background") { RelativeSource = new System.Windows.Data.RelativeSource(System.Windows.Data.RelativeSourceMode.TemplatedParent) });
        borderFactory.SetBinding(Border.BorderBrushProperty, new System.Windows.Data.Binding("BorderBrush") { RelativeSource = new System.Windows.Data.RelativeSource(System.Windows.Data.RelativeSourceMode.TemplatedParent) });
        borderFactory.SetBinding(Border.BorderThicknessProperty, new System.Windows.Data.Binding("BorderThickness") { RelativeSource = new System.Windows.Data.RelativeSource(System.Windows.Data.RelativeSourceMode.TemplatedParent) });
        borderFactory.SetBinding(Border.PaddingProperty, new System.Windows.Data.Binding("Padding") { RelativeSource = new System.Windows.Data.RelativeSource(System.Windows.Data.RelativeSourceMode.TemplatedParent) });

        var contentFactory = new FrameworkElementFactory(typeof(ContentPresenter));
        contentFactory.SetValue(ContentPresenter.HorizontalAlignmentProperty, HorizontalAlignment.Center);
        contentFactory.SetValue(ContentPresenter.VerticalAlignmentProperty, VerticalAlignment.Center);
        borderFactory.AppendChild(contentFactory);
        template.VisualTree = borderFactory;
        return template;
    }

    private Border CreateWindowCard(WindowItem item, StackPanel parentGroup)
    {
        var border = new Border
        {
            Background = new SolidColorBrush(Color.FromRgb(0x0D, 0x0D, 0x0D)),
            BorderBrush = new SolidColorBrush(Color.FromRgb(0x1F, 0x1F, 0x1F)),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
            Margin = new Thickness(0, 0, 0, 8),
            Padding = new Thickness(16, 12, 16, 12),
            Tag = item
        };

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        // Left Info Stack (Clickable Teleport Target)
        var infoStack = new StackPanel 
        { 
            VerticalAlignment = VerticalAlignment.Center,
            Cursor = Cursors.Hand,
            Background = Brushes.Transparent // Ensure entire hit area is testable
        };
        Grid.SetColumn(infoStack, 0);

        var txtTitle = new TextBlock
        {
            Text = item.Title,
            Foreground = new SolidColorBrush(Color.FromRgb(0xF5, 0xF5, 0xF5)),
            FontSize = 14,
            FontWeight = FontWeights.Bold,
            TextTrimming = TextTrimming.CharacterEllipsis,
            ToolTip = $"Click to teleport to '{item.Title}' across desktops",
            Margin = new Thickness(0, 0, 0, 4)
        };
        infoStack.Children.Add(txtTitle);

        var txtMeta = new TextBlock
        {
            Text = $"{item.ProcessName}  •  PID: {item.Pid}  •  {item.DesktopName}",
            Foreground = new SolidColorBrush(Color.FromRgb(0x88, 0x88, 0x88)),
            FontSize = 12,
            FontWeight = FontWeights.Medium
        };
        infoStack.Children.Add(txtMeta);

        // Hover & Click Teleportation: Left-click jumps to window and dismisses Apex
        infoStack.MouseEnter += (s, e) =>
        {
            border.Background = new SolidColorBrush(Color.FromRgb(0x16, 0x16, 0x16));
            border.BorderBrush = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF));
            txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF));
        };

        infoStack.MouseLeave += (s, e) =>
        {
            border.Background = new SolidColorBrush(Color.FromRgb(0x0D, 0x0D, 0x0D));
            border.BorderBrush = new SolidColorBrush(Color.FromRgb(0x1F, 0x1F, 0x1F));
            txtTitle.Foreground = new SolidColorBrush(Color.FromRgb(0xF5, 0xF5, 0xF5));
        };

        infoStack.MouseLeftButtonDown += (s, e) =>
        {
            WindowManager.TeleportToWindow(item.Hwnd);
            Close();
        };

        // Right Actions Stack
        var actionStack = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            VerticalAlignment = VerticalAlignment.Center
        };
        Grid.SetColumn(actionStack, 1);

        // 1. Main Pin/Unpin Action Button (Curved rounded capsule, uniform #141414 bg, border-only highlight)
        var btnPin = new Button
        {
            Height = 32,
            Padding = new Thickness(16, 0, 16, 0),
            MinWidth = 98,
            FontSize = 12,
            FontWeight = FontWeights.Bold,
            Cursor = Cursors.Hand,
            BorderThickness = new Thickness(1),
            Background = new SolidColorBrush(Color.FromRgb(0x14, 0x14, 0x14)),
            Template = CreateCurvedCapsuleTemplate()
        };

        Action applyState = () =>
        {
            btnPin.Background = new SolidColorBrush(Color.FromRgb(0x14, 0x14, 0x14));

            if (item.IsLocked)
            {
                btnPin.Content = "🔒 LOCKED";
                btnPin.BorderBrush = new SolidColorBrush(Color.FromRgb(0xFF, 0xB3, 0x00));
                btnPin.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0xB3, 0x00));
                btnPin.IsEnabled = false;
                btnPin.ToolTip = "System Inviolability Shield: Protected Overlay";
            }
            else if (item.IsTopmost)
            {
                btnPin.Content = "📌 TOPMOST";
                btnPin.BorderBrush = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF));
                btnPin.Foreground = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF));
                btnPin.ToolTip = "Window is Always On Top. Click to Unpin.";
            }
            else
            {
                btnPin.Content = "○ PIN";
                btnPin.BorderBrush = new SolidColorBrush(Color.FromRgb(0x2C, 0x2C, 0x2C));
                btnPin.Foreground = new SolidColorBrush(Color.FromRgb(0x88, 0x88, 0x88));
                btnPin.ToolTip = "Click to Pin Window Always On Top.";
            }
        };

        applyState();

        btnPin.MouseEnter += (s, e) =>
        {
            if (item.IsLocked) return;
            // Never change background to custom color! Only highlight border and text!
            btnPin.Background = new SolidColorBrush(Color.FromRgb(0x14, 0x14, 0x14));
            if (item.IsTopmost)
            {
                btnPin.BorderBrush = new SolidColorBrush(Color.FromRgb(0x33, 0xEB, 0xFF));
                btnPin.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0xFF, 0xFF));
            }
            else
            {
                btnPin.BorderBrush = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF));
                btnPin.Foreground = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF));
            }
        };

        btnPin.MouseLeave += (s, e) =>
        {
            applyState();
        };

        btnPin.Click += (s, e) =>
        {
            if (item.IsLocked) return;

            bool newState = !item.IsTopmost;
            WindowManager.SetTopmost(item.Hwnd, newState);

            if (item.IsCurrentDesktop)
            {
                WindowManager.Flash(item.Hwnd);
            }
            PlayAudioChime(newState);

            item.IsTopmost = newState;
            applyState();
            UpdatePinnedBadge();

            txtStatus.Text = newState ? $"📌 Window pinned to top: {item.Title}" : $"○ Window unpinned: {item.Title}";
        };

        // Streamlined default card surface: only the Pin button
        actionStack.Children.Add(btnPin);

        grid.Children.Add(infoStack);
        grid.Children.Add(actionStack);
        border.Child = grid;

        // Right-Click AMOLED Context Menu
        var contextMenu = new ContextMenu();

        // 0. Switch to Window (Teleport)
        var miTeleport = new MenuItem
        {
            Header = "Switch to Window (Teleport)",
            Icon = new TextBlock 
            { 
                Text = "⚡", 
                FontSize = 13, 
                Foreground = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF)) 
            }
        };
        miTeleport.Click += (s, e) =>
        {
            WindowManager.TeleportToWindow(item.Hwnd);
            Close();
        };

        // 1. Toggle Pin / Topmost
        var miToggleTop = new MenuItem
        {
            Header = item.IsTopmost ? "Unpin Window" : "Pin Always On Top",
            Icon = new TextBlock 
            { 
                Text = item.IsTopmost ? "○" : "📌", 
                FontSize = 13, 
                Foreground = new SolidColorBrush(Color.FromRgb(0x00, 0xE5, 0xFF)) 
            },
            IsEnabled = !item.IsLocked
        };
        miToggleTop.Click += (s, e) =>
        {
            if (item.IsLocked) return;
            btnPin.RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
        };

        // 2. Blacklist Application
        var miBlacklist = new MenuItem
        {
            Header = $"Blacklist '{item.ProcessName}'",
            Icon = new TextBlock { Text = "🚫", FontSize = 13 },
            IsEnabled = !item.IsLocked
        };
        miBlacklist.Click += (s, e) =>
        {
            if (item.IsLocked) return;
            BlacklistManager.Add(item.ProcessName);
            txtStatus.Text = $"🚫 Added '{item.ProcessName}' to blocklist.";
            UpdateWindowTree();
        };

        // 3. Graceful Close Window (WM_CLOSE)
        var miClose = new MenuItem
        {
            Header = "Close Window",
            Icon = new TextBlock 
            { 
                Text = "✕", 
                FontSize = 13, 
                Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0x8A, 0x80)) 
            },
            IsEnabled = !item.IsLocked
        };
        miClose.Click += (s, e) =>
        {
            if (item.IsLocked) return;
            WindowManager.CloseWindow(item.Hwnd);
            txtStatus.Text = $"✕ Sent close request to '{item.Title}'.";
            RemoveCardFromView(border, parentGroup, item);
        };

        // 4. Force Kill Process (PID)
        var miKill = new MenuItem
        {
            Header = $"Force Kill Process ({item.ProcessName}:{item.Pid})",
            Icon = new TextBlock 
            { 
                Text = "⚡", 
                FontSize = 13, 
                Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0x52, 0x52)) 
            },
            IsEnabled = !item.IsLocked,
            Style = (Style)FindResource("DangerMenuItemStyle")
        };
        miKill.Click += (s, e) =>
        {
            if (item.IsLocked) return;

            if (item.ProcessName.Equals("explorer", StringComparison.OrdinalIgnoreCase))
            {
                var confirm = MessageBox.Show(
                    "Killing explorer.exe will terminate your Windows Desktop and Taskbar.\n\nAre you sure you want to force kill it?",
                    "Apex • Desktop Shell Warning",
                    MessageBoxButton.YesNo,
                    MessageBoxImage.Warning);
                if (confirm != MessageBoxResult.Yes) return;
            }

            bool killed = WindowManager.KillProcess(item.Pid);
            if (killed)
            {
                txtStatus.Text = $"⚡ Terminated process '{item.ProcessName}' (PID: {item.Pid}).";
                RemoveProcessCardsFromView(item.Pid);
            }
            else
            {
                txtStatus.Text = $"⚠️ Failed to terminate '{item.ProcessName}' (Access Denied / Already Exited).";
            }
        };

        contextMenu.Opened += (s, e) =>
        {
            miToggleTop.Header = item.IsTopmost ? "Unpin Window" : "Pin Always On Top";
            if (miToggleTop.Icon is TextBlock tb)
            {
                tb.Text = item.IsTopmost ? "○" : "📌";
            }
        };

        contextMenu.Items.Add(miTeleport);
        contextMenu.Items.Add(miToggleTop);
        contextMenu.Items.Add(new Separator());
        contextMenu.Items.Add(miClose);
        contextMenu.Items.Add(miKill);
        contextMenu.Items.Add(new Separator());
        contextMenu.Items.Add(miBlacklist);

        border.ContextMenu = contextMenu;

        return border;
    }

    private void RemoveCardFromView(Border card, StackPanel parentGroup, WindowItem item)
    {
        _cardCache.RemoveAll(c => c.Card == card);
        parentGroup.Children.Remove(card);

        if (!parentGroup.Children.OfType<Border>().Any())
        {
            pnlWindows.Children.Remove(parentGroup);
        }

        var remainingWindows = _cardCache.Where(c => c.Item != null).Select(c => c.Item!).ToList();
        UpdatePinnedBadge(remainingWindows);
    }

    private void RemoveProcessCardsFromView(uint pid)
    {
        var toRemove = _cardCache.Where(c => c.Item != null && c.Item.Pid == pid).ToList();
        foreach (var entry in toRemove)
        {
            if (entry.ParentGroup != null)
            {
                entry.ParentGroup.Children.Remove(entry.Card);
                if (!entry.ParentGroup.Children.OfType<Border>().Any())
                {
                    pnlWindows.Children.Remove(entry.ParentGroup);
                }
            }
            _cardCache.Remove(entry);
        }

        var remainingWindows = _cardCache.Where(c => c.Item != null).Select(c => c.Item!).ToList();
        UpdatePinnedBadge(remainingWindows);
    }

    private Border CreateBlacklistCard(string processName)
    {
        var border = new Border
        {
            Background = new SolidColorBrush(Color.FromRgb(0x0D, 0x0D, 0x0D)),
            BorderBrush = new SolidColorBrush(Color.FromRgb(0x1F, 0x1F, 0x1F)),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(8),
            Margin = new Thickness(0, 0, 0, 8),
            Padding = new Thickness(16, 12, 16, 12),
            Tag = processName
        };

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

        var infoStack = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        Grid.SetColumn(infoStack, 0);

        var txtTitle = new TextBlock
        {
            Text = processName,
            Foreground = new SolidColorBrush(Color.FromRgb(0xF5, 0xF5, 0xF5)),
            FontSize = 14,
            FontWeight = FontWeights.Bold,
            Margin = new Thickness(0, 0, 0, 4)
        };
        infoStack.Children.Add(txtTitle);

        var txtMeta = new TextBlock
        {
            Text = "Blacklisted Application  •  Hidden from main switchboard",
            Foreground = new SolidColorBrush(Color.FromRgb(0x88, 0x88, 0x88)),
            FontSize = 12,
            FontWeight = FontWeights.Medium
        };
        infoStack.Children.Add(txtMeta);

        // Unblock Action Button (Curved capsule, border-only highlight, NO pin/unpin button)
        var btnUnblock = new Button
        {
            Content = "Unblock ↩",
            Height = 32,
            Padding = new Thickness(16, 0, 16, 0),
            MinWidth = 98,
            FontSize = 12,
            FontWeight = FontWeights.Bold,
            Cursor = Cursors.Hand,
            Background = new SolidColorBrush(Color.FromRgb(0x14, 0x14, 0x14)),
            BorderBrush = new SolidColorBrush(Color.FromRgb(0xFF, 0x52, 0x52)),
            Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0x52, 0x52)),
            BorderThickness = new Thickness(1),
            Template = CreateCurvedCapsuleTemplate(),
            ToolTip = $"Remove '{processName}' from blocklist"
        };
        btnUnblock.MouseEnter += (s, e) =>
        {
            btnUnblock.Background = new SolidColorBrush(Color.FromRgb(0x14, 0x14, 0x14));
            btnUnblock.BorderBrush = new SolidColorBrush(Color.FromRgb(0xFF, 0x8A, 0x80));
            btnUnblock.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0xFF, 0xFF));
        };
        btnUnblock.MouseLeave += (s, e) =>
        {
            btnUnblock.Background = new SolidColorBrush(Color.FromRgb(0x14, 0x14, 0x14));
            btnUnblock.BorderBrush = new SolidColorBrush(Color.FromRgb(0xFF, 0x52, 0x52));
            btnUnblock.Foreground = new SolidColorBrush(Color.FromRgb(0xFF, 0x52, 0x52));
        };
        btnUnblock.Click += (s, e) =>
        {
            BlacklistManager.Remove(processName);
            txtStatus.Text = $"✨ Unblocked '{processName}'.";
            if (BlacklistManager.Count == 0)
            {
                _isBlocklistView = false;
            }
            UpdateViewModeUI();
            UpdateWindowTree();
        };

        Grid.SetColumn(btnUnblock, 1);
        grid.Children.Add(infoStack);
        grid.Children.Add(btnUnblock);
        border.Child = grid;

        return border;
    }

    private static void PlayAudioChime(bool isPinned)
    {
        Task.Run(() =>
        {
            try
            {
                if (isPinned)
                {
                    Console.Beep(1400, 60);
                    Console.Beep(2200, 80);
                }
                else
                {
                    Console.Beep(1800, 60);
                    Console.Beep(1000, 80);
                }
            }
            catch { }
        });
    }

    // Window Resizing via Native Win32 Handles
    private void ResizeGrip_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.LeftButton == MouseButtonState.Pressed)
        {
            var handle = new WindowInteropHelper(this).Handle;
            WindowManager.SendMessage(handle, WindowManager.WM_NCLBUTTONDOWN, (IntPtr)WindowManager.HTBOTTOMRIGHT, IntPtr.Zero);
        }
    }

    private void ResizeRight_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.LeftButton == MouseButtonState.Pressed)
        {
            var handle = new WindowInteropHelper(this).Handle;
            WindowManager.SendMessage(handle, WindowManager.WM_NCLBUTTONDOWN, (IntPtr)WindowManager.HTRIGHT, IntPtr.Zero);
        }
    }

    private void ResizeBottom_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.LeftButton == MouseButtonState.Pressed)
        {
            var handle = new WindowInteropHelper(this).Handle;
            WindowManager.SendMessage(handle, WindowManager.WM_NCLBUTTONDOWN, (IntPtr)WindowManager.HTBOTTOM, IntPtr.Zero);
        }
    }
}
