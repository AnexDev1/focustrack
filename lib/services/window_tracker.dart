import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show File, Link, Platform, Process;
import 'package:ffi/ffi.dart';

class WindowInfo {
  final String appName;
  final String executableName;
  final String? windowTitle;
  final String? executablePath;
  final String? windowClass;
  final String? windowInstance;
  final int processId;

  WindowInfo({
    required this.appName,
    required this.executableName,
    this.windowTitle,
    this.executablePath,
    this.windowClass,
    this.windowInstance,
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
  'googlechrome': 'Google Chrome',
  'chromium': 'Chromium',
  'firefox': 'Firefox',
  'firefoxbin': 'Firefox',
  'mozillafirefox': 'Firefox',
  'firefoxdeveloperedition': 'Firefox Developer Edition',
  'navigator': 'Firefox',
  'librewolf': 'LibreWolf',
  'zenbrowser': 'Zen Browser',
  'zen': 'Zen Browser',
  'msedge': 'Microsoft Edge',
  'microsoftedge': 'Microsoft Edge',
  'opera': 'Opera',
  'brave': 'Brave Browser',
  'bravebrowser': 'Brave Browser',
  'vivaldi': 'Vivaldi',
  'iexplore': 'Internet Explorer',
  // Communication
  'telegram': 'Telegram',
  'telegramdesktop': 'Telegram',
  'orgtelegramdesktop': 'Telegram',
  'telegramdesktopdesktop': 'Telegram',
  'telegrambeta': 'Telegram',
  'ayugram': 'AyuGram',
  'ayugramdesktop': 'AyuGram',
  'orgayugramdesktop': 'AyuGram',
  'ayugramtelegramdesktop': 'AyuGram',
  '64gram': '64Gram',
  'discord': 'Discord',
  'Discord': 'Discord',
  'Slack': 'Slack',
  'slack': 'Slack',
  'Teams': 'Microsoft Teams',
  'ms-teams': 'Microsoft Teams',
  'msteams': 'Microsoft Teams',
  'Zoom': 'Zoom',
  'zoom': 'Zoom',
  'Skype': 'Skype',
  'skype': 'Skype',
  'Signal': 'Signal',
  'signal': 'Signal',
  'WhatsApp': 'WhatsApp',
  'whatsapp': 'WhatsApp',
  'thunderbird': 'Thunderbird',
  'outlook': 'Microsoft Outlook',
  // Development
  'Code': 'Visual Studio Code',
  'code': 'Visual Studio Code',
  'codeoss': 'Visual Studio Code',
  'codium': 'VSCodium',
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
  'githubdesktop': 'GitHub Desktop',
  // Office / Productivity
  'excel': 'Microsoft Excel',
  'winword': 'Microsoft Word',
  'powerpnt': 'Microsoft PowerPoint',
  'onenote': 'OneNote',
  'msaccess': 'Microsoft Access',
  'Notion': 'Notion',
  'notion': 'Notion',
  'Obsidian': 'Obsidian',
  'obsidian': 'Obsidian',
  'Todoist': 'Todoist',
  'todoist': 'Todoist',
  // File management
  'explorer': 'File Explorer',
  'nautilus': 'Files',
  'orggnomenautilus': 'Files',
  'dolphin': 'Dolphin',
  'thunar': 'Thunar',
  // Media
  'Spotify': 'Spotify',
  'spotify': 'Spotify',
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
  'blender': 'Blender',
  // Gaming
  'steam': 'Steam',
  'EpicGamesLauncher': 'Epic Games',
  'epicgameslauncher': 'Epic Games',
  'GalaxyClient': 'GOG Galaxy',
  'galaxyclient': 'GOG Galaxy',
  // System
  'notepad': 'Notepad',
  'mspaint': 'Paint',
  'SnippingTool': 'Snipping Tool',
  'calc': 'Calculator',
  'mstsc': 'Remote Desktop',
  'taskmgr': 'Task Manager',
  'SystemSettings': 'Settings',
  'orggnomeSettings': 'Settings',
  'orggnomecontrolcenter': 'Settings',
  // Other popular apps
  'Postman': 'Postman',
  'postman': 'Postman',
  'docker': 'Docker Desktop',
  'filezilla': 'FileZilla',
  'PuTTY': 'PuTTY',
  'WinSCP': 'WinSCP',
  '7zFM': '7-Zip',
  'Bitwarden': 'Bitwarden',
  'bitwarden': 'Bitwarden',
  '1Password': '1Password',
  'obs': 'OBS Studio',
  'obsstudio': 'OBS Studio',
  'orggimpGIMP': 'GIMP',
  'orginkscapeInkscape': 'Inkscape',
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
  'flatpak',
  'bwrap',
  'snap',
  'gtk-launch',
};

const _titleFragmentDisplayNames = <String, String>{
  'mozillafirefox': 'Firefox',
  'firefox': 'Firefox',
  'ayugram': 'AyuGram',
  'telegram': 'Telegram',
  'telegramdesktop': 'Telegram',
  '64gram': '64Gram',
  'librewolf': 'LibreWolf',
  'zenbrowser': 'Zen Browser',
  'vivaldi': 'Vivaldi',
  'brave': 'Brave Browser',
  'chromium': 'Chromium',
  'googlechrome': 'Google Chrome',
};

// ---------------------------------------------------------------------------
// Resolve a human-readable app name from exe name + window title
// ---------------------------------------------------------------------------
String _resolveAppName(
  String executableName,
  String? windowTitle, {
  String? executablePath,
  String? windowClass,
  String? windowInstance,
  String? trackerAppName,
}) {
  final knownName = _lookupKnownDisplayName([
    executableName,
    _basenameWithoutExtension(executablePath),
    windowClass,
    windowInstance,
    trackerAppName,
    ..._extractTitleCandidates(windowTitle),
  ]);
  if (knownName != null) return knownName;

  final titleKnownName = _lookupTitleFragmentDisplayName(windowTitle);
  if (titleKnownName != null) return titleKnownName;

  final normalizedExe = _normalizeAppIdentifier(executableName);

  if (_genericProcesses.any(
        (processName) => _normalizeAppIdentifier(processName) == normalizedExe,
      ) &&
      windowTitle != null &&
      windowTitle.isNotEmpty) {
    final parsed = _extractAppNameFromTitle(windowTitle);
    final parsedKnown = _lookupKnownDisplayName([parsed]);
    if (parsedKnown != null) return parsedKnown;
    if (parsed != null) return parsed;
  }

  if (executableName.isNotEmpty && executableName != 'Unknown') {
    return _prettifyName(executableName);
  }

  if (windowClass != null && windowClass.isNotEmpty) {
    return _prettifyName(windowClass);
  }

  if (trackerAppName != null &&
      trackerAppName.isNotEmpty &&
      trackerAppName != 'Unknown') {
    return _prettifyName(trackerAppName);
  }

  if (windowTitle != null && windowTitle.isNotEmpty) {
    return _extractAppNameFromTitle(windowTitle) ?? windowTitle;
  }

  return 'Unknown';
}

String _normalizeAppIdentifier(String? value) {
  if (value == null) return '';
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String? _lookupKnownDisplayName(Iterable<String?> candidates) {
  for (final candidate in candidates) {
    final normalized = _normalizeAppIdentifier(candidate);
    if (normalized.isEmpty) continue;
    for (final entry in _processDisplayNames.entries) {
      if (_normalizeAppIdentifier(entry.key) == normalized) {
        return entry.value;
      }
    }
  }
  return null;
}

String? _basenameWithoutExtension(String? path) {
  if (path == null || path.isEmpty) return null;
  final fileName = path.split('/').last;
  return fileName.replaceAll(
    RegExp(r'\.(exe|desktop)$', caseSensitive: false),
    '',
  );
}

String? _extractAppNameFromTitle(String title) {
  final candidates = _extractTitleCandidates(title);
  for (final candidate in candidates) {
    if (candidate != title && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
  }
  return null;
}

List<String> _extractTitleCandidates(String? title) {
  if (title == null) return const [];
  final trimmed = title.trim();
  if (trimmed.isEmpty) return const [];

  final candidates = <String>[trimmed];
  final separators = [
    ' - ',
    ' | ',
    ' — ',
    ' – ',
    ' • ',
    ' · ',
    ' :: ',
    ' —',
    ' –',
  ];

  for (final separator in separators) {
    if (!trimmed.contains(separator)) continue;
    final parts = trimmed
        .split(separator)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    candidates.addAll(parts);
    if (parts.isNotEmpty) {
      candidates.add(parts.last);
    }
  }

  return candidates.toSet().toList();
}

String? _lookupTitleFragmentDisplayName(String? title) {
  final normalizedTitle = _normalizeAppIdentifier(title);
  if (normalizedTitle.isEmpty) return null;

  for (final entry in _titleFragmentDisplayNames.entries) {
    final normalizedKey = _normalizeAppIdentifier(entry.key);
    if (normalizedKey.isNotEmpty && normalizedTitle.contains(normalizedKey)) {
      return entry.value;
    }
  }

  return null;
}

String _prettifyName(String name) {
  // Remove common suffixes like "64", "_x64"
  var n = name
      .replaceAll(RegExp(r'\.desktop$', caseSensitive: false), '')
      .replaceAll(RegExp(r'[_\-]?x?64$', caseSensitive: false), '')
      .replaceAll(RegExp(r'\.exe$', caseSensitive: false), '')
      .replaceAll('.', ' ')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .trim();
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

      final displayName = _resolveAppName(
        executableName,
        windowTitle,
        executablePath: executablePath,
      );

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
      String exeName = 'Unknown';
      String windowTitle = '';
      String? executablePath;
      String? windowClass;
      String? windowInstance;
      String? trackerAppName;
      int pid = 0;

      final gnomeWindowInfo = _getActiveWindowFromGnomeShellExtension();
      if (gnomeWindowInfo != null) {
        trackerAppName = gnomeWindowInfo['appName'];
        windowTitle = gnomeWindowInfo['title'] ?? '';
        windowClass = gnomeWindowInfo['wmClass'];
        windowInstance = gnomeWindowInfo['wmClassInstance'];
        exeName =
            gnomeWindowInfo['appId'] ?? gnomeWindowInfo['appName'] ?? 'Unknown';
        pid = int.tryParse(gnomeWindowInfo['pid'] ?? '') ?? 0;
      }

      if (trackerAppName == null || trackerAppName.isEmpty) {
        try {
          final trackerDir = Platform.resolvedExecutable;
          final trackerPath =
              '${trackerDir.substring(0, trackerDir.lastIndexOf('/'))}/active_window_linux';
          final result = Process.runSync(trackerPath, []);
          final data = _parseLinuxTrackerOutput(result.stdout.toString());
          if (data.isNotEmpty) {
            trackerAppName = data['app'];
            windowTitle = data['title'] ?? '';
            windowClass = data['class'];
            windowInstance = data['instance'];
            pid = int.tryParse(data['pid'] ?? '') ?? 0;
          } else {
            throw Exception('Invalid output');
          }
        } catch (_) {
          // Fallback to xdotool
          final pidResult = Process.runSync('xdotool', [
            'getactivewindow',
            'getwindowpid',
          ]);
          final nameResult = Process.runSync('xdotool', [
            'getactivewindow',
            'getwindowname',
          ]);

          pid = int.tryParse(pidResult.stdout.toString().trim()) ?? 0;
          windowTitle = nameResult.stdout.toString().trim();

          if (pid > 0) {
            final ps = Process.runSync('ps', ['-p', '$pid', '-o', 'comm=']);
            exeName = ps.stdout.toString().trim();
          }
        }
      }

      if (pid > 0) {
        executablePath = _readLinuxExecutablePath(pid);
        final procExeName = _readLinuxExecutableName(pid);
        if (procExeName != null && procExeName.isNotEmpty) {
          exeName = procExeName;
        }
      }

      if ((exeName.isEmpty || exeName == 'Unknown') &&
          trackerAppName != null &&
          trackerAppName.isNotEmpty) {
        exeName = trackerAppName;
      }

      final displayName = _resolveAppName(
        exeName,
        windowTitle,
        executablePath: executablePath,
        windowClass: windowClass,
        windowInstance: windowInstance,
        trackerAppName: trackerAppName,
      );

      return WindowInfo(
        appName: displayName,
        executableName: exeName,
        windowTitle: windowTitle,
        executablePath: executablePath,
        windowClass: windowClass,
        windowInstance: windowInstance,
        processId: pid,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, String>? _getActiveWindowFromGnomeShellExtension() {
    try {
      if (!Platform.isLinux) return null;
      final desktop = Platform.environment['XDG_CURRENT_DESKTOP'] ?? '';
      if (!desktop.toLowerCase().contains('gnome')) return null;

      final result = Process.runSync('gdbus', [
        'call',
        '--session',
        '--dest',
        'com.focustrack.WindowTracker',
        '--object-path',
        '/com/focustrack/WindowTracker',
        '--method',
        'com.focustrack.WindowTracker.GetActiveWindowJson',
      ]);

      if (result.exitCode != 0) return null;
      final stdout = result.stdout.toString().trim();
      final start = stdout.indexOf("'");
      final end = stdout.lastIndexOf("'");
      if (start == -1 || end <= start) return null;

      final jsonString = stdout
          .substring(start + 1, end)
          .replaceAll("\\'", "'")
          .replaceAll(r'\\', r'\');
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return null;

      return decoded.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _parseLinuxTrackerOutput(String output) {
    final data = <String, String>{};
    for (final line in output.split('\n')) {
      final separatorIndex = line.indexOf(':');
      if (separatorIndex == -1) continue;
      final key = line.substring(0, separatorIndex).trim().toLowerCase();
      final value = line.substring(separatorIndex + 1).trim();
      if (value.isNotEmpty) {
        data[key] = value;
      }
    }
    return data;
  }

  String? _readLinuxExecutableName(int pid) {
    try {
      final comm = File('/proc/$pid/comm').readAsStringSync().trim();
      if (comm.isNotEmpty) return comm;
    } catch (_) {}

    final executablePath = _readLinuxExecutablePath(pid);
    return _basenameWithoutExtension(executablePath);
  }

  String? _readLinuxExecutablePath(int pid) {
    try {
      return Link('/proc/$pid/exe').targetSync();
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
