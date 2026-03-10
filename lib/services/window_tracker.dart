import 'dart:ffi';
import 'dart:io' show Platform, Process;
import 'package:ffi/ffi.dart';

class WindowInfo {
  final String appName;
  final String executableName;
  final String? windowTitle;
  final String? executablePath;
  final int processId;

  WindowInfo({
    required this.appName,
    required this.executableName,
    this.windowTitle,
    this.executablePath,
    required this.processId,
  });
}

abstract class WindowTracker {
  WindowInfo? getActiveWindow();
  int getIdleTimeMs();
}

// ---------------------------------------------------------------------------
// Win32 FFI struct for GetLastInputInfo
// ---------------------------------------------------------------------------
final class _LastInputInfo extends Struct {
  @Uint32()
  external int cbSize;

  @Uint32()
  external int dwTime;
}

// ---------------------------------------------------------------------------
// Known process‑name → friendly display‑name map
// ---------------------------------------------------------------------------
const _processDisplayNames = <String, String>{
  // Browsers
  'chrome': 'Google Chrome',
  'firefox': 'Firefox',
  'msedge': 'Microsoft Edge',
  'opera': 'Opera',
  'brave': 'Brave Browser',
  'vivaldi': 'Vivaldi',
  'iexplore': 'Internet Explorer',
  // Communication
  'Telegram': 'Telegram',
  'Discord': 'Discord',
  'Slack': 'Slack',
  'Teams': 'Microsoft Teams',
  'ms-teams': 'Microsoft Teams',
  'Zoom': 'Zoom',
  'Skype': 'Skype',
  'Signal': 'Signal',
  'WhatsApp': 'WhatsApp',
  'thunderbird': 'Thunderbird',
  'OUTLOOK': 'Microsoft Outlook',
  // Development
  'Code': 'Visual Studio Code',
  'devenv': 'Visual Studio',
  'idea64': 'IntelliJ IDEA',
  'idea': 'IntelliJ IDEA',
  'pycharm64': 'PyCharm',
  'pycharm': 'PyCharm',
  'webstorm64': 'WebStorm',
  'rider64': 'JetBrains Rider',
  'clion64': 'CLion',
  'goland64': 'GoLand',
  'datagrip64': 'DataGrip',
  'studio64': 'Android Studio',
  'sublime_text': 'Sublime Text',
  'notepad++': 'Notepad++',
  'WindowsTerminal': 'Windows Terminal',
  'cmd': 'Command Prompt',
  'powershell': 'PowerShell',
  'pwsh': 'PowerShell',
  'mintty': 'Git Bash',
  'GitHubDesktop': 'GitHub Desktop',
  // Office / Productivity
  'EXCEL': 'Microsoft Excel',
  'WINWORD': 'Microsoft Word',
  'POWERPNT': 'Microsoft PowerPoint',
  'ONENOTE': 'OneNote',
  'MSACCESS': 'Microsoft Access',
  'Notion': 'Notion',
  'Obsidian': 'Obsidian',
  'Todoist': 'Todoist',
  // File management
  'explorer': 'File Explorer',
  // Media
  'Spotify': 'Spotify',
  'vlc': 'VLC Media Player',
  'wmplayer': 'Windows Media Player',
  'foobar2000': 'foobar2000',
  // Design
  'Figma': 'Figma',
  'Photoshop': 'Adobe Photoshop',
  'Illustrator': 'Adobe Illustrator',
  'AfterFX': 'Adobe After Effects',
  'PremierePro': 'Adobe Premiere Pro',
  'GIMP': 'GIMP',
  'inkscape': 'Inkscape',
  'Blender': 'Blender',
  // Gaming
  'steam': 'Steam',
  'EpicGamesLauncher': 'Epic Games',
  'GalaxyClient': 'GOG Galaxy',
  // System
  'notepad': 'Notepad',
  'mspaint': 'Paint',
  'SnippingTool': 'Snipping Tool',
  'calc': 'Calculator',
  'mstsc': 'Remote Desktop',
  'taskmgr': 'Task Manager',
  'SystemSettings': 'Settings',
  // Other popular apps
  'Postman': 'Postman',
  'docker': 'Docker Desktop',
  'filezilla': 'FileZilla',
  'PuTTY': 'PuTTY',
  'WinSCP': 'WinSCP',
  '7zFM': '7-Zip',
  'Bitwarden': 'Bitwarden',
  '1Password': '1Password',
};

/// Processes whose own name is meaningless – use the window title instead.
const _genericProcesses = <String>{
  'applicationframehost', // UWP / Store apps
  'electron',
  'java',
  'javaw',
  'python',
  'pythonw',
  'node',
  'wscript',
  'cscript',
  'shellexperiencehost',
  'searchhost',
};

// ---------------------------------------------------------------------------
// Resolve a human-readable app name from exe name + window title
// ---------------------------------------------------------------------------
String _resolveAppName(String executableName, String? windowTitle) {
  final lowerExe = executableName.toLowerCase();

  // 1. Known display name
  for (final entry in _processDisplayNames.entries) {
    if (entry.key.toLowerCase() == lowerExe) return entry.value;
  }

  // 2. Generic host processes → parse window title
  if (_genericProcesses.contains(lowerExe) &&
      windowTitle != null &&
      windowTitle.isNotEmpty) {
    final parsed = _extractAppNameFromTitle(windowTitle);
    if (parsed != null) return parsed;
  }

  // 3. Prettify the raw exe name
  if (executableName.isNotEmpty && executableName != 'Unknown') {
    return _prettifyName(executableName);
  }

  // 4. Last resort – window title
  if (windowTitle != null && windowTitle.isNotEmpty) {
    return _extractAppNameFromTitle(windowTitle) ?? windowTitle;
  }

  return 'Unknown';
}

String? _extractAppNameFromTitle(String title) {
  // Many apps use "Document - AppName" or "Page | AppName"
  final dashIdx = title.lastIndexOf(' - ');
  final pipeIdx = title.lastIndexOf(' | ');
  final idx = dashIdx > pipeIdx ? dashIdx : pipeIdx;
  if (idx != -1 && idx + 3 < title.length) {
    return title.substring(idx + 3).trim();
  }
  return null;
}

String _prettifyName(String name) {
  // Remove common suffixes like "64", "_x64"
  var n = name
      .replaceAll(RegExp(r'[_\-]?x?64$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\.exe$', caseSensitive: false), '');
  if (n.isEmpty) return name;
  // Title‑case first letter
  return n[0].toUpperCase() + n.substring(1);
}

// ---------------------------------------------------------------------------
// Windows implementation using raw dart:ffi
// ---------------------------------------------------------------------------
class WindowTrackerImpl implements WindowTracker {
  // -- DLL handles (lazily initialised, only on Windows) --------------------
  static final _user32 = Platform.isWindows
      ? DynamicLibrary.open('user32.dll')
      : null;
  static final _kernel32 = Platform.isWindows
      ? DynamicLibrary.open('kernel32.dll')
      : null;

  // -- Win32 function look‑ups ----------------------------------------------
  static final _getForegroundWindow = _user32
      ?.lookupFunction<IntPtr Function(), int Function()>(
        'GetForegroundWindow',
      );

  static final _getWindowText = _user32
      ?.lookupFunction<
        Int32 Function(IntPtr, Pointer<Uint16>, Int32),
        int Function(int, Pointer<Uint16>, int)
      >('GetWindowTextW');

  static final _getWindowThreadProcessId = _user32
      ?.lookupFunction<
        Uint32 Function(IntPtr, Pointer<Uint32>),
        int Function(int, Pointer<Uint32>)
      >('GetWindowThreadProcessId');

  static final _openProcess = _kernel32
      ?.lookupFunction<
        IntPtr Function(Uint32, Int32, Uint32),
        int Function(int, int, int)
      >('OpenProcess');

  static final _queryFullProcessImageName = _kernel32
      ?.lookupFunction<
        Int32 Function(IntPtr, Uint32, Pointer<Uint16>, Pointer<Uint32>),
        int Function(int, int, Pointer<Uint16>, Pointer<Uint32>)
      >('QueryFullProcessImageNameW');

  static final _closeHandle = _kernel32
      ?.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'CloseHandle',
      );

  static final _getLastInputInfo = _user32
      ?.lookupFunction<
        Int32 Function(Pointer<_LastInputInfo>),
        int Function(Pointer<_LastInputInfo>)
      >('GetLastInputInfo');

  static final _getTickCount = _kernel32
      ?.lookupFunction<Uint32 Function(), int Function()>('GetTickCount');

  // -- Public API -----------------------------------------------------------
  @override
  WindowInfo? getActiveWindow() {
    if (Platform.isWindows) return _getActiveWindowWindows();
    if (Platform.isLinux) return _getActiveWindowLinux();
    if (Platform.isMacOS) return _getActiveWindowMacOS();
    return null;
  }

  @override
  int getIdleTimeMs() {
    if (Platform.isWindows) return _getIdleTimeWindows();
    if (Platform.isLinux) return _getIdleTimeLinux();
    return 0;
  }

  // -- Windows --------------------------------------------------------------
  WindowInfo? _getActiveWindowWindows() {
    try {
      final hwnd = _getForegroundWindow!();
      if (hwnd == 0) return null;

      // Window title
      final titleBuf = calloc<Uint16>(512);
      String? windowTitle;
      try {
        final len = _getWindowText!(hwnd, titleBuf, 512);
        windowTitle = len > 0
            ? String.fromCharCodes(titleBuf.asTypedList(len))
            : null;
      } finally {
        calloc.free(titleBuf);
      }
      if (windowTitle == null || windowTitle.isEmpty) return null;

      // Process ID
      final pidPtr = calloc<Uint32>();
      int pid;
      try {
        _getWindowThreadProcessId!(hwnd, pidPtr);
        pid = pidPtr.value;
      } finally {
        calloc.free(pidPtr);
      }
      if (pid == 0) return null;

      // Executable path
      String executableName = 'Unknown';
      String? executablePath;

      const processQueryLimitedInfo =
          0x1000; // PROCESS_QUERY_LIMITED_INFORMATION
      final hProcess = _openProcess!(processQueryLimitedInfo, 0, pid);
      if (hProcess != 0) {
        final exeBuf = calloc<Uint16>(1024);
        final sizePtr = calloc<Uint32>();
        try {
          sizePtr.value = 1024;
          if (_queryFullProcessImageName!(hProcess, 0, exeBuf, sizePtr) != 0) {
            final pathLen = sizePtr.value;
            executablePath = String.fromCharCodes(exeBuf.asTypedList(pathLen));
            final fileName = executablePath.split(RegExp(r'[/\\]')).last;
            executableName = fileName.replaceAll(
              RegExp(r'\.exe$', caseSensitive: false),
              '',
            );
          }
        } finally {
          calloc.free(exeBuf);
          calloc.free(sizePtr);
          _closeHandle!(hProcess);
        }
      }

      final displayName = _resolveAppName(executableName, windowTitle);

      return WindowInfo(
        appName: displayName,
        executableName: executableName,
        windowTitle: windowTitle,
        executablePath: executablePath,
        processId: pid,
      );
    } catch (_) {
      return null;
    }
  }

  int _getIdleTimeWindows() {
    try {
      final info = calloc<_LastInputInfo>();
      try {
        info.ref.cbSize = sizeOf<_LastInputInfo>();
        if (_getLastInputInfo!(info) != 0) {
          final now = _getTickCount!();
          // Unsigned 32-bit subtraction (handles wrap‑around)
          return (now - info.ref.dwTime) & 0xFFFFFFFF;
        }
      } finally {
        calloc.free(info);
      }
    } catch (_) {}
    return 0;
  }

  // -- Linux ----------------------------------------------------------------
  WindowInfo? _getActiveWindowLinux() {
    try {
      // Use xdotool (widely available on X11)
      final pidResult = Process.runSync('xdotool', [
        'getactivewindow',
        'getwindowpid',
      ]);
      final nameResult = Process.runSync('xdotool', [
        'getactivewindow',
        'getwindowname',
      ]);

      final pid = int.tryParse(pidResult.stdout.toString().trim()) ?? 0;
      final windowTitle = nameResult.stdout.toString().trim();

      String exeName = 'Unknown';
      if (pid > 0) {
        final ps = Process.runSync('ps', ['-p', '$pid', '-o', 'comm=']);
        exeName = ps.stdout.toString().trim();
      }

      final displayName = _resolveAppName(exeName, windowTitle);

      return WindowInfo(
        appName: displayName,
        executableName: exeName,
        windowTitle: windowTitle,
        processId: pid,
      );
    } catch (_) {
      return null;
    }
  }

  int _getIdleTimeLinux() {
    try {
      final result = Process.runSync('xprintidle', []);
      return int.tryParse(result.stdout.toString().trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // -- macOS ----------------------------------------------------------------
  WindowInfo? _getActiveWindowMacOS() {
    try {
      final result = Process.runSync('osascript', [
        '-e',
        'tell application "System Events" to get {name, unix id} of first '
            'application process whose frontmost is true',
      ]);
      final output = result.stdout.toString().trim(); // "AppName, 12345"
      final parts = output.split(', ');
      if (parts.length < 2) return null;

      final exeName = parts[0];
      final pid = int.tryParse(parts[1]) ?? 0;

      // Window title
      final titleResult = Process.runSync('osascript', [
        '-e',
        'tell application "System Events" to get title of front window of '
            'first application process whose frontmost is true',
      ]);
      final windowTitle = titleResult.stdout.toString().trim();

      final displayName = _resolveAppName(exeName, windowTitle);

      return WindowInfo(
        appName: displayName,
        executableName: exeName,
        windowTitle: windowTitle,
        processId: pid,
      );
    } catch (_) {
      return null;
    }
  }
}
