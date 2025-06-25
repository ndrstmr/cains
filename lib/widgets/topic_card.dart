// lib/widgets/topic_card.dart
import 'package:flutter/material.dart';
import 'package:myapp/models/topic_model.dart';
// import 'package:myapp/l10n/app_localizations.dart'; // For localization (currently unused directly)

class TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback? onTap; // Optional: for tap interaction

  const TopicCard({super.key, required this.topic, this.onTap});

  // Helper function to map iconName string to IconData
  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'business':
        return Icons
            .business_center; // Using business_center as business is generic
      case 'science':
        return Icons.science_outlined;
      case 'palette':
        return Icons.palette_outlined;
      case 'people':
        return Icons.people_alt_outlined;
      case 'eco':
      case 'nature':
        return Icons.eco_outlined;
      // Add more cases as needed
      default:
        return Icons.help_outline; // Default icon if no match
    }
  }

  // Helper to get localized title
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

  // Helper to get localized description
  String _getLocalizedDescription(BuildContext context, Topic topic) {
    final locale = Localizations.localeOf(context).languageCode;
    switch (locale) {
      case 'de':
        return topic.descriptionDe;
      case 'es':
        return topic.descriptionEs;
      case 'en':
      default:
        return topic.descriptionEn;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final localizations = AppLocalizations.of(context)!; // For any fixed text if needed
    final iconData = _getIconData(topic.iconName);
    final localizedTitle = _getLocalizedTitle(context, topic);
    final localizedDescription = _getLocalizedDescription(context, topic);

    // Using Card for Material Design 3 look and feel
    return Card(
      elevation: 2.0, // Subtle shadow
      margin: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ), // Margin for spacing in a list/grid
      shape: const RoundedRectangleBorder(
        // Made const
        borderRadius: BorderRadius.all(Radius.circular(12.0)), // Already const
      ),
      clipBehavior: Clip.antiAlias, // Ensures content respects border radius
      child: InkWell(
        onTap:
            onTap ??
            () {
              // Default tap action: print to console or navigate if needed in future
              if (onTap == null) {
                print('TopicCard tapped: ${topic.id} - $localizedTitle');
              }
            },
        splashColor: Theme.of(
          context,
        ).colorScheme.primary.withAlpha((255 * 0.12).round()),
        highlightColor: Theme.of(
          context,
        ).colorScheme.primary.withAlpha((255 * 0.1).round()),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize
                .min, // Important for GridView to size cards properly
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    iconData,
                    size: 36.0, // Slightly larger icon
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          localizedTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (localizedDescription.isNotEmpty) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            localizedDescription,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 3, // Adjust as needed
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Optional: Add more elements like progress indicators or quick actions later
            ],
          ),
        ),
      ),
    );
  }
}
