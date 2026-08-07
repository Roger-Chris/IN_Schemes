import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/models/user_profile.dart';
import 'package:frontend/services/assistant_session_controller.dart';
import 'package:frontend/services/livekit_voice_agent_controller.dart';
import 'package:frontend/services/scheme_understanding_engine.dart';
import 'package:frontend/services/voice_agent_controller.dart';

void main() {
  test('cloud scheme result state parses only valid compact records', () {
    final results = parseCloudSchemeResultsAttribute(
      '{"schema":"in-schemes-results-v1","results":['
      '{"id":"SCH000001","code":"TN001","name":"Capital Subsidy",'
      '"match_confidence":88,"is_verified":true,"source_confidence":"high"},'
      '{"id":"","code":"","name":""},'
      '"invalid"]}',
    );

    expect(results, hasLength(1));
    expect(results.single.id, 'SCH000001');
    expect(results.single.code, 'TN001');
    expect(results.single.name, 'Capital Subsidy');
    expect(results.single.matchConfidence, 88);
    expect(results.single.isVerified, isTrue);
    expect(results.single.sourceConfidence, 'high');
  });

  test('cloud scheme result state rejects unknown schemas', () {
    expect(
      parseCloudSchemeResultsAttribute(
        '{"schema":"unknown","results":[{"name":"Fake"}]}',
      ),
      isEmpty,
    );
  });

  test('cloud results resolve to bundled schemes by code or exact name', () {
    const catalog = [
      Scheme(id: 'IN001', schemeCode: 'IN001', name: 'Capital Subsidy'),
      Scheme(id: 'IN002', schemeCode: 'IN002', name: 'Cleaner Technology'),
    ];
    const results = [
      CloudSchemeResult(id: 'SCH1', code: 'TN001', name: 'Capital Subsidy'),
      CloudSchemeResult(id: 'SCH2', code: 'IN002', name: 'Different Name'),
    ];

    expect(
      matchCloudSchemeResultsToCatalog(results, catalog).map((item) => item.id),
      ['IN001', 'IN002'],
    );
  });

  test('cloud profile context includes eligibility facts but excludes PII', () {
    final metadata = buildCloudProfileMetadata(
      UserProfile(
        name: 'Anto Merary',
        dob: DateTime(2000, 8, 6),
        gender: 'Female',
        state: 'Tamil Nadu',
        district: 'Tiruvallur',
        community: 'General',
        qualification: 'Undergraduate',
        employmentStatus: 'Student',
        annualIncome: 150000,
        disability: 'None',
        veteran: false,
        email: 'private@example.com',
        mobile: '9999999999',
        pinCode: '600001',
      ),
      now: DateTime.utc(2026, 8, 5),
    );

    expect(metadata['schema'], 'in-schemes-profile-v1');
    expect(metadata['profile'], {
      'name': 'Anto Merary',
      'age': 25,
      'gender': 'Female',
      'state': 'Tamil Nadu',
      'district': 'Tiruvallur',
      'community': 'General',
      'education': 'Undergraduate',
      'employment': 'Student',
      'annualIncome': 150000.0,
      'disability': 'None',
      'veteran': false,
    });
    expect(metadata.toString(), isNot(contains('private@example.com')));
    expect(metadata.toString(), isNot(contains('9999999999')));
    expect(metadata.toString(), isNot(contains('600001')));
    expect(metadata.toString(), isNot(contains('2000-08-06')));
  });

  test('cloud voice listens while pre-connect audio is buffering', () {
    expect(cloudVoicePreConnectAudio, isTrue);
    expect(
      shouldReportCloudListening(
        agentCanListen: true,
        isMuted: false,
        isSpeaking: false,
      ),
      isTrue,
    );
    expect(
      shouldReportCloudListening(
        agentCanListen: true,
        isMuted: true,
        isSpeaking: false,
      ),
      isFalse,
    );
    expect(
      shouldReportCloudListening(
        agentCanListen: true,
        isMuted: false,
        isSpeaking: true,
      ),
      isFalse,
    );
    expect(
      shouldReportCloudListening(
        agentCanListen: true,
        isMuted: false,
        isSpeaking: false,
        isThinking: true,
      ),
      isFalse,
    );
  });

  test('local controller never enters a cloud session', () async {
    final session = AssistantSessionController(
      engine: const LocalSchemeUnderstandingEngine(),
      schemes: const [],
      profile: UserProfile(),
    );
    final controller = LocalVoiceAgentController(session: session);

    await controller.initialize();
    await controller.connect();

    expect(controller.state.usingCloud, isFalse);
    expect(controller.state.phase, VoiceAgentConnectionPhase.fallback);
    expect(controller.state.message, contains('on-device'));
    await controller.dispose();
    session.dispose();
  });

  test('typed text uses the same private assistant session', () async {
    final session = AssistantSessionController(
      engine: const LocalSchemeUnderstandingEngine(),
      schemes: const [],
      profile: UserProfile(),
    );
    final controller = LocalVoiceAgentController(session: session);

    await controller.sendText('I need a scholarship');

    expect(controller.state.inputTranscript, 'I need a scholarship');
    expect(controller.state.outputTranscript, isNotEmpty);
    expect(session.state.statement, 'I need a scholarship');
    expect(controller.state.usingCloud, isFalse);
    await controller.dispose();
    session.dispose();
  });
}
