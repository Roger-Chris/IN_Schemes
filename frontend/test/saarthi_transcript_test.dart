import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/companion_mode/saarthi_home_screen.dart';

SaarthiMessage message(String role, {String? status}) => SaarthiMessage(
  id: role,
  role: role,
  text: role,
  timestamp: DateTime(2026),
  status: status,
);

void main() {
  test('a user turn starts a new assistant transcript bubble', () {
    final messages = [message('assistant'), message('user')];
    expect(cloudAssistantMessageTargetIndex(messages), -1);
  });

  test('streaming chunks update only the current assistant bubble', () {
    final messages = [message('user'), message('assistant')];
    expect(cloudAssistantMessageTargetIndex(messages), 1);
  });

  test('transcribing state can be cleared when a turn completes', () {
    final transcribing = message('user', status: 'transcribing');
    expect(transcribing.copyWith(clearStatus: true).status, isNull);
  });

  test('stale output is not copied into the next assistant bubble', () {
    expect(
      shouldApplyCloudOutput(
        output: 'Previous answer',
        previousOutput: 'Previous answer',
      ),
      isFalse,
    );
    expect(
      shouldApplyCloudOutput(
        output: 'New answer',
        previousOutput: 'Previous answer',
      ),
      isTrue,
    );
  });
}
