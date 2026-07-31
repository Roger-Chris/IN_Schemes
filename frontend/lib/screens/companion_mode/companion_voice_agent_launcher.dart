import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../services/scheme_repository.dart';
import '../../services/voice_agent_controller.dart';
import '../../widgets/voice_assistant_overlay.dart';
import '../regular_mode/scheme_details_screen.dart';
import '../regular_mode/search_results_screen.dart';

Future<void> openCompanionVoiceAgent(
  BuildContext context, {
  bool autoStart = true,
  String? initialText,
}) async {
  final provider = Provider.of<AppProvider>(context, listen: false);
  final schemes = provider.allSchemes.isNotEmpty
      ? provider.allSchemes
      : await SchemeRepository.instance.getAllSchemes();
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Talk to Saarthi',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (overlayContext, animation, secondaryAnimation) {
      return VoiceAssistantOverlay(
        surface: VoiceAgentSurface.companion,
        autoStart: autoStart,
        initialText: initialText,
        schemes: schemes,
        profile: provider.profile,
        onProfileConfirmed: provider.updateProfile,
        onClose: () => Navigator.of(overlayContext, rootNavigator: true).pop(),
        onSubmit: (query) {
          Navigator.of(overlayContext, rootNavigator: true).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SearchResultsScreen(title: query),
            ),
          );
        },
        onSchemeSelected: (scheme) {
          Navigator.of(overlayContext, rootNavigator: true).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SchemeDetailsScreen(scheme: scheme),
            ),
          );
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          alignment: Alignment.bottomCenter,
          scale: Tween<double>(begin: 0.90, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}
