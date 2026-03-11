import 'package:home_widget/home_widget.dart';

/// Names of all home screen widget providers.
const widgetProviders = [
  'ScreenTimeWidgetProvider',
  'FocusScoreWidgetProvider',
  'TopAppsWidgetProvider',
  'QuickStatsWidgetProvider',
];

/// Trigger an update for all home screen widgets.
Future<void> updateAllHomeWidgets() async {
  for (final name in widgetProviders) {
    await HomeWidget.updateWidget(androidName: name);
  }
}
