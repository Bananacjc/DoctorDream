import 'package:flutter/material.dart';

import 'package:doctor_dream/widgets/custom_prompt_dialog.dart';
import 'package:doctor_dream/widgets/custom_button.dart';

class ValidationHelper {
  static Future<bool> isValidDreamEntry({
    required BuildContext context,
    required String dreamTitle,
    required String dreamContent,
  }) async {
    if (dreamTitle.isNotEmpty && dreamContent.isNotEmpty) {
      return true;
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => CustomPromptDialog(
          title: 'Missing Info',
          description: 'Your dream title or content is empty.',
          isClosable: true,
          actions: [
            CustomTextButton(
              buttonText: 'OK',
              type: ButtonType.confirm,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      );
      return confirm == true;
    }
  }
}
