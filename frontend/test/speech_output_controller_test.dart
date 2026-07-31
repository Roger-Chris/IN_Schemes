import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/speech_output_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/speech_output');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('session disposal leaves the activity-owned bridge available', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'capabilities' => <String, dynamic>{
          'available': true,
          'english': true,
          'tamil': true,
        },
        'stop' => null,
        _ => throw PlatformException(code: 'unexpected'),
      };
    });

    final first = NativeSpeechOutputController(channel: channel);
    expect((await first.initialize()).available, isTrue);
    await first.dispose();

    final second = NativeSpeechOutputController(channel: channel);
    expect((await second.initialize()).tamil, isTrue);
    await second.dispose();

    expect(calls.where((method) => method == 'capabilities'), hasLength(2));
    expect(calls, isNot(contains('dispose')));
  });

  test(
    'missing native bridge degrades to visible text without throwing',
    () async {
      final controller = NativeSpeechOutputController(channel: channel);

      final capabilities = await controller.initialize();

      expect(capabilities.available, isFalse);
      expect(await controller.speak('Question', languageTag: 'en-IN'), isFalse);
      await controller.stop();
      await controller.dispose();
    },
  );

  test('uses the chosen natural voice style for English and Tamil', () async {
    final spokenCalls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'capabilities') {
        return <String, dynamic>{
          'available': true,
          'english': true,
          'tamil': true,
          'englishVoice': 'en-in-natural',
          'tamilVoice': 'ta-in-natural',
        };
      }
      if (call.method == 'speak') {
        spokenCalls.add(call);
        final utteranceId = 'utterance-${spokenCalls.length}';
        await messenger.handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            MethodCall('speechEvent', <String, dynamic>{
              'event': 'completed',
              'utteranceId': utteranceId,
            }),
          ),
          (_) {},
        );
        return utteranceId;
      }
      return null;
    });
    final controller = NativeSpeechOutputController(
      channel: channel,
      preferredVoice: 'clear',
    );

    final capabilities = await controller.initialize();
    expect(capabilities.englishVoice, 'en-in-natural');
    expect(capabilities.tamilVoice, 'ta-in-natural');
    expect(await controller.speak('Welcome', languageTag: 'en-IN'), isTrue);
    expect(await controller.speak('வணக்கம்', languageTag: 'ta-IN'), isTrue);
    expect(spokenCalls.map((call) => call.arguments['languageTag']), [
      'en-IN',
      'ta-IN',
    ]);
    expect(spokenCalls.map((call) => call.arguments['voiceStyle']).toSet(), {
      'clear',
    });
    await controller.dispose();
  });
}
