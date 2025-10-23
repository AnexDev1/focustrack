enum AppCategory {
  work,
  development,
  communication,
  entertainment,
  social,
  gaming,
  design,
  productivity,
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
      case AppCategory.other:
        return 'Other';
    }
  }

  static AppCategory fromAppName(String appName) {
    final name = appName.toLowerCase();

    // Development
    if (name.contains('code') ||
        name.contains('terminal') ||
        name.contains('git') ||
        name.contains('studio')) {
      return AppCategory.development;
    }

    // Communication
    if (name.contains('telegram') ||
        name.contains('slack') ||
        name.contains('discord') ||
        name.contains('teams') ||
        name.contains('zoom') ||
        name.contains('meet')) {
      return AppCategory.communication;
    }

    // Entertainment
    if (name.contains('spotify') ||
        name.contains('music') ||
        name.contains('video') ||
        name.contains('player') ||
        name.contains('netflix') ||
        name.contains('youtube')) {
      return AppCategory.entertainment;
    }

    // Social
    if (name.contains('twitter') ||
        name.contains('facebook') ||
        name.contains('instagram') ||
        name.contains('social')) {
      return AppCategory.social;
    }

    // Gaming
    if (name.contains('steam') ||
        name.contains('game') ||
        name.contains('epic')) {
      return AppCategory.gaming;
    }

    // Design
    if (name.contains('figma') ||
        name.contains('photoshop') ||
        name.contains('illustrator') ||
        name.contains('gimp') ||
        name.contains('inkscape')) {
      return AppCategory.design;
    }

    // Browsers and productivity
    if (name.contains('chrome') ||
        name.contains('firefox') ||
        name.contains('safari') ||
        name.contains('edge') ||
        name.contains('browser')) {
      return AppCategory.productivity;
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
