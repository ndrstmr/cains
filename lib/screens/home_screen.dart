// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/models/topic_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/challenge_model.dart'; // Added ChallengeModel
import 'package:myapp/providers/auth_provider.dart';
import 'package:myapp/providers/user_progress_provider.dart';
import 'package:myapp/providers/daily_challenge_provider.dart'; // Added DailyChallengeProvider
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/providers/topic_provider.dart';
import 'package:myapp/widgets/topic_card.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/navigation/app_router.dart';

// Enum for settings actions
enum SettingsAction { toggleTheme, logout }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<bool?> _showLogoutConfirmationDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    // ... (dialog logic remains the same)
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
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: Text(localizations.logoutButtonLabel),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
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
    final userProgressAsyncValue = ref.watch(userProgressProvider);
    final currentChallenge = ref.watch(currentDayChallengeProvider); // Get today's challenge from stream
    final todayChallengeFuture = ref.watch(todayDailyChallengeProvider); // For explicit fetch/generate status

    // Automatically try to fetch/generate challenge if none is loaded and user is logged in
    // This effect runs once when the HomeScreen is built or when user logs in.
    // It checks if a challenge is already available via currentChallenge. If not, it triggers a fetch.
    final userId = ref.watch(currentUserIdProvider);
    if (userId != null && currentChallenge == null && !todayChallengeFuture.isLoading) {
      // Check if we haven't tried fetching recently or if the last attempt failed and we want to retry.
      // For simplicity, we'll just invalidate if no current challenge.
      // A more sophisticated approach might check timestamps or error states.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (kDebugMode) {
          print("HomeScreen: No current day challenge found, attempting to fetch/generate.");
        }
        ref.invalidate(todayDailyChallengeProvider);
      });
    }


    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      // ... (error listening remains the same)
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

    final int totalPoints = userProgressAsyncValue.when(
      data: (UserModel? userModel) => userModel?.totalPoints ?? 0,
      loading: () => 0,
      error: (e, st) => 0,
    );

    final double overallProgress = userProgressAsyncValue.when(
      data: (UserModel? userModel) {
        if (userModel == null || userModel.totalPoints == 0) return 0.0;
        const double maxPoints = 10000.0;
        return (userModel.totalPoints / maxPoints).clamp(0.0, 1.0);
      },
      loading: () => 0.0,
      error: (e, st) => 0.0,
    );

    return Scaffold(
      appBar: AppBar(
        // ... (appBar title and actions remain mostly the same)
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(localizations.homePageTitle),
            Chip(
              avatar: Icon(Icons.star, color: Theme.of(context).colorScheme.secondary),
              label: Text(
                localizations.pointsLabel(totalPoints),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.language_outlined),
          tooltip: localizations.languageMenuTooltip,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Language/Menu action placeholder')),
            );
          },
        ),
        actions: [
          PopupMenuButton<SettingsAction>(
            icon: const Icon(Icons.settings),
            tooltip: localizations.settingsMenuTooltip,
            onSelected: (SettingsAction action) async {
              switch (action) {
                case SettingsAction.toggleTheme:
                  ref.read(themeModeProvider.notifier).state =
                      currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                  break;
                case SettingsAction.logout:
                  final confirmed = await _showLogoutConfirmationDialog(context, localizations);
                  if (confirmed == true) {
                    await authNotifier.signOut();
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SettingsAction>>[
              PopupMenuItem<SettingsAction>(
                value: SettingsAction.toggleTheme,
                child: Row(
                  children: [
                    Icon(
                      currentThemeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
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
                    Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      localizations.logoutButtonLabel,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Overall Progress Bar
          if (userProgressAsyncValue.hasValue && userProgressAsyncValue.value != null)
            Padding(
              // ... (progress bar remains the same)
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.overallProgressLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(overallProgress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

          // Daily Challenge Section
          _DailyChallengeSection(currentChallenge: currentChallenge, todayChallengeFuture: todayChallengeFuture),

          // Topics Grid
          Expanded(
            child: topicsAsyncValue.when(
              // ... (topics grid remains the same)
              data: (topics) {
                if (topics.isEmpty) {
                  return Center(child: Text(localizations.noTopicsAvailableMessage));
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0), // Adjust padding if challenge section is present
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.2 : 0.9,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return TopicCard(
                      topic: topic,
                      onTap: () {
                        GoRouter.of(context).go(AppRoute.wordgrid.path, extra: topic);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                if (kDebugMode) {
                  print('Error loading topics: $err');
                  print(stack);
                }
                return Center(child: Text(localizations.errorLoadingTopicsMessage));
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle(BuildContext context, Topic topic) {
    // ... (helper remains the same)
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

// Internal widget for displaying the daily challenge
class _DailyChallengeSection extends ConsumerWidget {
  final ChallengeModel? currentChallenge;
  final AsyncValue<ChallengeModel?> todayChallengeFuture;

  const _DailyChallengeSection({
    required this.currentChallenge,
    required this.todayChallengeFuture,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    if (currentChallenge != null) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentChallenge!.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(currentChallenge!.description),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      currentChallenge!.status == ChallengeStatus.open
                          ? localizations.challengeStatusOpen // "Open"
                          : localizations.challengeStatusCompleted, // "Completed"
                    ),
                    backgroundColor: currentChallenge!.status == ChallengeStatus.open
                        ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7)
                        : Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.7),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(localizations.startChallengeButtonLabel), // "Start Challenge"
                    onPressed: currentChallenge!.status == ChallengeStatus.open
                        ? () {
                            // TODO: Implement navigation to the challenge (e.g., specific WordGridScreen)
                            if (kDebugMode) {
                              print("Start challenge: ${currentChallenge!.id} - ${currentChallenge!.targetWord}");
                            }
                            // Example: Navigate to word grid for the target topic
                            // This requires fetching the TopicModel for currentChallenge.targetTopicId
                            // For now, just print.
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Starting challenge: ${currentChallenge!.targetWord}")),
                            );
                          }
                        : null, // Disable if completed or failed
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (todayChallengeFuture.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (todayChallengeFuture.hasError) {
       if (kDebugMode) {
          print("Error loading today's challenge: ${todayChallengeFuture.error}");
        }
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localizations.errorLoadingChallengeMessage), // "Error loading challenge."
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(todayDailyChallengeProvider),
                child: Text(localizations.retryButtonLabel), // "Retry"
              ),
            ],
          ),
        ),
      );
    } else {
      // No challenge loaded, and not currently loading/error - show button to fetch
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(localizations.getTodaysChallengeButtonLabel), // "Get Today's Challenge"
            onPressed: () {
              ref.invalidate(todayDailyChallengeProvider);
            },
          ),
        ),
      );
    }
  }
}

// Add to lib/l10n/app_localizations.dart or equivalent:
// String get challengeStatusOpen => 'Open';
// String get challengeStatusCompleted => 'Completed';
// String get startChallengeButtonLabel => 'Start Challenge';
// String get errorLoadingChallengeMessage => 'Could not load today\'s challenge.';
// String get retryButtonLabel => 'Retry';
// String get getTodaysChallengeButtonLabel => 'Get Today\'s Challenge';
// String get dailyChallengeSectionTitle => 'Daily Challenge'; // Optional title for the section
