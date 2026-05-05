import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/firebase_options.dart';

void main() {
  test('Android Firebase config matches the app package and Dart options', () {
    final googleServices = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final projectInfo = googleServices['project_info'] as Map<String, dynamic>;
    final clients = googleServices['client'] as List<dynamic>;
    final androidClient = clients.cast<Map<String, dynamic>>().singleWhere((
      client,
    ) {
      final info = client['client_info'] as Map<String, dynamic>;
      final androidInfo = info['android_client_info'] as Map<String, dynamic>;
      return androidInfo['package_name'] == 'com.example.edu_pro';
    });
    final clientInfo = androidClient['client_info'] as Map<String, dynamic>;
    final oauthClients = androidClient['oauth_client'] as List<dynamic>;
    final packageOauthClient = oauthClients.cast<Map<String, dynamic>>()
        .singleWhere((client) => client['client_type'] == 1);
    final androidInfo =
        packageOauthClient['android_info'] as Map<String, dynamic>;

    expect(projectInfo['project_id'], DefaultFirebaseOptions.android.projectId);
    expect(
      clientInfo['mobilesdk_app_id'],
      DefaultFirebaseOptions.android.appId,
    );
    expect(
      projectInfo['project_number'],
      DefaultFirebaseOptions.android.messagingSenderId,
    );
    expect(androidInfo['package_name'], 'com.example.edu_pro');
    expect(
      androidInfo['certificate_hash'],
      '129fa3c55af3387fb148611b8e21c74cbee08642',
    );
  });

  test('Firebase CLI config points to the active project and rules files', () {
    final firebaseConfig = jsonDecode(
      File('firebase.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final firebaseRc = jsonDecode(
      File('.firebaserc').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(firebaseRc['projects']['default'], 'edu-pro-8e259');
    expect(firebaseConfig['firestore']['rules'], 'firestore.rules');
    expect(firebaseConfig['firestore']['indexes'], 'firestore.indexes.json');
    expect(File('firestore.rules').existsSync(), isTrue);
    expect(File('firestore.indexes.json').existsSync(), isTrue);
  });
}
