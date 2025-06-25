// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Only if direct navigation needed, otherwise rely on router
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/models/topic_model.dart';
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/theme/app_theme.dart'; // For themeModeProvider
import 'package:myapp/providers/topic_provider.dart';
import 'package:myapp/widgets/topic_card.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
// import 'package:myapp/navigation/app_router.dart'; // For AppRoute enum if needed for direct navigation

// Enum for settings actions
enum SettingsAction { toggleTheme, logout }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Helper to show logout confirmation dialog
  Future<bool?> _showLogoutConfirmationDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizations.logoutDialogTitle),
          content: Text(localizations.logoutDialogContent),
          actions: <Widget>[
            TextButton(
              child: Text(localizations.cancelButtonLabel),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // User canceled
              },
            ),
            TextButton(
              child: Text(localizations.logoutButtonLabel),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // User confirmed
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final topicsAsyncValue = ref.watch(topicsStreamProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    // Listen to AuthNotifier for sign-out errors (if any)
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.homePageTitle,
        ), // Use homePageTitle instead of appTitle for screen context
        leading: IconButton(
          icon: const Icon(Icons.language_outlined),
          tooltip: localizations.languageMenuTooltip,
          onPressed: () {
            // TODO: Implement language change or side menu
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: const Text('Language/Menu action placeholder'),
              ), // Make child Text const
            );
          },
        ),
        actions: [
          // Settings PopupMenuButton
          PopupMenuButton<SettingsAction>(
            icon: const Icon(Icons.settings),
            tooltip: localizations.settingsMenuTooltip,
            onSelected: (SettingsAction action) async {
              switch (action) {
                case SettingsAction.toggleTheme:
                  ref
                      .read(themeModeProvider.notifier)
                      .state = currentThemeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                  break;
                case SettingsAction.logout:
                  final confirmed = await _showLogoutConfirmationDialog(
                    context,
                    localizations,
                  );
                  if (confirmed == true) {
                    await authNotifier.signOut();
                    // Navigation handled by GoRouter redirect
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<SettingsAction>>[
                  PopupMenuItem<SettingsAction>(
                    value: SettingsAction.toggleTheme,
                    child: Row(
                      children: [
                        Icon(
                          currentThemeMode == ThemeMode.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentThemeMode == ThemeMode.dark
                              ? localizations.switchToLightModeLabel
                              : localizations.switchToDarkModeLabel,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<SettingsAction>(
                    value: SettingsAction.logout,
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          localizations.logoutButtonLabel,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: topicsAsyncValue.when(
        data: (topics) {
          if (topics.isEmpty) {
            return Center(child: Text(localizations.noTopicsAvailableMessage));
          }
          // Using GridView.builder for a responsive grid of TopicCards
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: MediaQuery.of(context).size.width > 600
                  ? 1.2
                  : 0.9,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return TopicCard(
                topic: topic,
                onTap: () {
                  // TODO: Implement navigation to topic detail screen or action
                  print('Tapped on topic: ${topic.id}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tapped on: ${_getLocalizedTitle(context, topic)}',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: const CircularProgressIndicator(),
        ), // Make child const
        error: (err, stack) {
          if (kDebugMode) {
            print('Error loading topics: $err');
            print(stack);
          }
          return Center(child: Text(localizations.errorLoadingTopicsMessage));
        },
      ),
    );
  }

  // Helper to get localized title (copied from TopicCard for temporary use in SnackBar)
  String _getLocalizedTitle(BuildContext context, Topic topic) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'de':
        return topic.titleDe;
      case 'es':
        return topic.titleEs;
      case 'en':
      default:
        return topic.titleEn;
    }
  }
}
