import 'package:flutter/material.dart';

import '../data/models/user_info.dart';
import '../data/services/gemini_service.dart';

class DreamDiagnosisDetailViewModel extends ChangeNotifier {
  Future<String> startDiagnosisChat({
    required UserInfo userInfo,
    required String diagnosis,
  }) async {
    return GeminiService.instance.startDreamDiagnosisChat(
      userInfo: userInfo,
      diagnosis: diagnosis,
    );
  }
}
