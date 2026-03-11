enum AppCategory {
  work,
  development,
  communication,
  entertainment,
  social,
  gaming,
  design,
  productivity,
  browser,
  system,
  other,
}

extension AppCategoryExtension on AppCategory {
  String get displayName {
    switch (this) {
      case AppCategory.work:
        return 'Work';
      case AppCategory.development:
        return 'Development';
      case AppCategory.communication:
        return 'Communication';
      case AppCategory.entertainment:
        return 'Entertainment';
      case AppCategory.social:
        return 'Social';
      case AppCategory.gaming:
        return 'Gaming';
      case AppCategory.design:
        return 'Design';
      case AppCategory.productivity:
        return 'Productivity';
      case AppCategory.browser:
        return 'Browser';
      case AppCategory.system:
        return 'System';
      case AppCategory.other:
        return 'Other';
    }
  }

  static AppCategory fromAppName(String appName) {
    final name = appName.toLowerCase();

    // Development
    if (name.contains('visual studio') ||
        name.contains('code') ||
        name.contains('terminal') ||
        name.contains('git') ||
        name.contains('android studio') ||
        name.contains('intellij') ||
        name.contains('pycharm') ||
        name.contains('webstorm') ||
        name.contains('rider') ||
        name.contains('clion') ||
        name.contains('goland') ||
        name.contains('datagrip') ||
        name.contains('sublime') ||
        name.contains('notepad++') ||
        name.contains('powershell') ||
        name.contains('command prompt') ||
        name.contains('postman')) {
      return AppCategory.development;
    }

    // Communication
    if (name.contains('telegram') ||
        name.contains('slack') ||
        name.contains('discord') ||
        name.contains('teams') ||
        name.contains('zoom') ||
        name.contains('meet') ||
        name.contains('skype') ||
        name.contains('signal') ||
        name.contains('whatsapp') ||
        name.contains('thunderbird') ||
        name.contains('outlook')) {
      return AppCategory.communication;
    }

    // Entertainment
    if (name.contains('spotify') ||
        name.contains('music') ||
        name.contains('video') ||
        name.contains('vlc') ||
        name.contains('media player') ||
        name.contains('foobar') ||
        name.contains('netflix') ||
        name.contains('youtube') ||
        name.contains('twitch') ||
        name.contains('plex')) {
      return AppCategory.entertainment;
    }

    // Social
    if (name.contains('twitter') ||
        name.contains('facebook') ||
        name.contains('instagram') ||
        name.contains('reddit') ||
        name.contains('social') ||
        name.contains('tiktok')) {
      return AppCategory.social;
    }

    // Gaming
    if (name.contains('steam') ||
        name.contains('game') ||
        name.contains('epic games') ||
        name.contains('gog') ||
        name.contains('battle.net') ||
        name.contains('blizzard')) {
      return AppCategory.gaming;
    }

    // Design
    if (name.contains('figma') ||
        name.contains('photoshop') ||
        name.contains('illustrator') ||
        name.contains('after effects') ||
        name.contains('premiere') ||
        name.contains('gimp') ||
        name.contains('inkscape') ||
        name.contains('blender') ||
        name.contains('canva')) {
      return AppCategory.design;
    }

    // Productivity
    if (name.contains('notion') ||
        name.contains('trello') ||
        name.contains('todoist') ||
        name.contains('asana') ||
        name.contains('clickup') ||
        name.contains('jira') ||
        name.contains('calendar') ||
        name.contains('keep') ||
        name.contains('drive') ||
        name.contains('onenote') ||
        name.contains('evernote') ||
        name.contains('planner')) {
      return AppCategory.productivity;
    }

    // Browsers
    if (name.contains('chrome') ||
        name.contains('firefox') ||
        name.contains('safari') ||
        name.contains('edge') ||
        name.contains('opera') ||
        name.contains('brave') ||
        name.contains('vivaldi') ||
        name.contains('browser')) {
      return AppCategory.browser;
    }

    // System
    if (name.contains('file explorer') ||
        name.contains('task manager') ||
        name.contains('settings') ||
        name.contains('notepad') ||
        name.contains('paint') ||
        name.contains('calculator') ||
        name.contains('registry') ||
        name.contains('remote desktop') ||
        name.contains('snipping')) {
      return AppCategory.system;
    }

    // Work
    if (name.contains('office') ||
        name.contains('excel') ||
        name.contains('word') ||
        name.contains('powerpoint') ||
        name.contains('sheets') ||
        name.contains('docs')) {
      return AppCategory.work;
    }

    return AppCategory.other;
  }
}

class AppStats {
  final String appName;
  final int totalTimeMs;
  final int sessionCount;
  final AppCategory category;
  final DateTime? lastUsed;

  AppStats({
    required this.appName,
    required this.totalTimeMs,
    required this.sessionCount,
    required this.category,
    this.lastUsed,
  });

  String get formattedTime {
    final hours = totalTimeMs ~/ (1000 * 60 * 60);
    final minutes = (totalTimeMs % (1000 * 60 * 60)) ~/ (1000 * 60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  double get hours => totalTimeMs / (1000 * 60 * 60);
}
