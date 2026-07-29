import 'dart:async';

import 'realtime_voice_agent_transport.dart';
import 'voice_agent_controller.dart';

class VoiceAgentPreviewService {
  static Future<void> preview(String voice) async {
    if (!openAiRealtimeEnabled) {
      throw StateError(
        'Cloud voice previews are available after Realtime is enabled.',
      );
    }
    final transport = RealtimeVoiceAgentTransport();
    final completed = Completer<void>();
    final subscription = transport.events.listen((event) {
      if (event['type'] == 'response.done' && !completed.isCompleted) {
        completed.complete();
      }
    });
    try {
      await transport.connect(
        VoiceAgentTransportConfig(
          surface: VoiceAgentSurface.companion,
          voice: voice,
        ),
      );
      await transport.send({
        'type': 'conversation.item.create',
        'item': {
          'type': 'message',
          'role': 'user',
          'content': [
            {
              'type': 'input_text',
              'text':
                  'Voice preview only. Say: Hello, I am Saarthi. I can help you find the right government scheme.',
            },
          ],
        },
      });
      await transport.send({'type': 'response.create'});
      await completed.future.timeout(const Duration(seconds: 12));
    } finally {
      await subscription.cancel();
      await transport.dispose();
    }
  }
}
