import 'package:doctor_dream/widgets/custom_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
import '../data/models/dream_entry.dart';
import '../view_models/dream_edit_view_model.dart';
import '../util/validation_helper.dart';
import '../widgets/custom_button.dart';

class DreamEditScreen extends StatefulWidget {
  final DreamEntry? dreamEntry;

  const DreamEditScreen({super.key, this.dreamEntry});

  @override
  State<DreamEditScreen> createState() => _DreamEntryScreenState();
}

class _DreamEntryScreenState extends State<DreamEditScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _viewModel = DreamEditViewModel();

  Future<bool> _showSaveConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomPromptDialog(
        title: 'Save This Dream?',
        description: 'Are you sure you want to save this dream?',
        isClosable: true,
        actions: [
          CustomTextButton(
            buttonText: 'Cancel',
            type: ButtonType.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          CustomTextButton(
            buttonText: 'Save',
            type: ButtonType.confirm,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.dreamEntry != null) {
      _titleController.text = widget.dreamEntry!.dreamTitle;
      _contentController.text = widget.dreamEntry!.dreamContent;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            title: Text(widget.dreamEntry == null ? 'New Dream' : 'Edit Dream'),
          ),
          body: Container(
            margin: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(color: ColorConstant.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title TextField
                TextField(
                  controller: _titleController,
                  cursorColor: ColorConstant.onPrimary,
                  cursorWidth: 1,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(bottom: 0),
                    labelText: 'Title',
                    labelStyle: GoogleFonts.robotoFlex(
                      color: ColorConstant.onPrimary.withAlpha(150),
                      fontSize: 20,
                    ),
                    floatingLabelStyle: TextStyle(
                      color: ColorConstant.onPrimary.withAlpha(150),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: ColorConstant.onPrimary,
                        width: 1,
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: ColorConstant.onPrimary),
                    ),
                  ),
                  style: GoogleFonts.robotoFlex(
                    color: ColorConstant.onPrimary,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                // Content TextField
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    cursorColor: ColorConstant.onPrimary,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: GoogleFonts.robotoFlex(
                        color: ColorConstant.onPrimary.withAlpha(150),
                        fontSize: 16,
                      ),
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                      contentPadding: EdgeInsets.only(top: 4, left: 4),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: ColorConstant.onPrimary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: ColorConstant.onPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _viewModel.isSaving
                              ? null
                              : () async {
                                  final dreamTitle = _titleController.text
                                      .trim();
                                  final dreamContent = _contentController.text
                                      .trim();

                                  final valid =
                                      await ValidationHelper.isValidDreamEntry(
                                        context: context,
                                        dreamTitle: dreamTitle,
                                        dreamContent: dreamContent,
                                      );

                                  if (!valid) return;

                                  final confirm = await
                                  _showSaveConfirmDialog();
                                  if (!confirm) return;

                                  final success = await _viewModel.saveDream(
                                    originalEntry: widget.dreamEntry,
                                    dreamTitle: _titleController.text,
                                    dreamContent: _contentController.text,
                                  );

                                  if (success && context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstant.primaryContainer,
                            foregroundColor: ColorConstant.onPrimaryContainer,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Icon(Icons.save, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
