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
}
