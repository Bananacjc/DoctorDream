import 'package:doctor_dream/widgets/custom_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
import '../data/models/dream_entry.dart';
import '../view_models/dream_edit_view_model.dart';
import '../util/validation_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_progress_indicator.dart';

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

  bool get _hasChanges {
    final originalTitle = widget.dreamEntry?.dreamTitle ?? '';
    final originalContent = widget.dreamEntry?.dreamContent ?? '';

    final currentTitle = _titleController.text;
    final currentContent = _contentController.text;

    return originalTitle != currentTitle || originalContent != currentContent;
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomPromptDialog(
        title: "Discard Changes?",
        description:
            "You have unsaved changes. Are you sure you want to go"
            " back and lose them?",
        isClosable: true,
        icon: Icons.edit_off_rounded,
        actions: [
          CustomTextButton(
            buttonText: "Keep Editing",
            type: ButtonType.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          CustomTextButton(
            buttonText: "Discard",
            type: ButtonType.warning,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<bool> _showSaveConfirmDialog() async {
    final isEditing = widget.dreamEntry != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomPromptDialog(
        title: isEditing ? 'Update This Dream?' : 'Save This New Dream?',
        description: isEditing
            ? "Are you ready to finalize the changes to this dream entry?"
            : "Are you sure you want to capture and save this dream?",
        isClosable: true,
        actions: [
          CustomTextButton(
            buttonText: 'Wait, Cancel',
            type: ButtonType.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          CustomTextButton(
            buttonText: isEditing ? 'Update It!' : 'Save It!',
            type: ButtonType.confirm,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _saveDreamEntry() async {
    final dreamTitle = _titleController.text.trim();
    final dreamContent = _contentController.text.trim();

    final valid = await ValidationHelper.isValidDreamEntry(
      context: context,
      dreamTitle: dreamTitle,
      dreamContent: dreamContent,
    );

    if (!valid) return;

    final confirm = await _showSaveConfirmDialog();
    if (!confirm) return;

    final success = await _viewModel.saveDream(
      originalEntry: widget.dreamEntry,
      dreamTitle: dreamTitle,
      dreamContent: dreamContent,
    );

    if (success && mounted) {
      Navigator.pop(context, true);
    }
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

  InputDecoration _buildInputDecoration({
    required String labelText,
    required bool isContentField,
  }) {
    final focusedBorder = isContentField
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ColorConstant.primary, width: 2),
          )
        : UnderlineInputBorder(
            borderSide: BorderSide(color: ColorConstant.primary, width: 2),
          );

    final enabledBorder = isContentField
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ColorConstant.outlineVariant),
          )
        : UnderlineInputBorder(
            borderSide: BorderSide(color: ColorConstant.onSurfaceVariant),
          );

    return InputDecoration(
      contentPadding: isContentField
          ? EdgeInsets.all(12)
          : EdgeInsets.only(bottom: 4),
      labelText: labelText,
      labelStyle: GoogleFonts.robotoFlex(
        color: ColorConstant.onSurfaceVariant,
        fontSize: isContentField ? 16 : 20,
      ),
      floatingLabelAlignment: FloatingLabelAlignment.start,
      floatingLabelStyle: TextStyle(color: ColorConstant.primary),
      alignLabelWithHint: isContentField,
      fillColor: isContentField ? ColorConstant.surfaceContainerHigh : null,
      filled: isContentField,
      focusedBorder: focusedBorder,
      enabledBorder: enabledBorder,
      border: enabledBorder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.dreamEntry != null;
    final String pageTitle = isEditing
        ? "Editing This Dream"
        : "Creating New Dream";

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;

            if (!_hasChanges || _viewModel.isSaving) {
              Navigator.of(context).pop();
              return;
            }

            final shouldDiscard = await _showDiscardDialog();

            if (shouldDiscard && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              scrolledUnderElevation: 0,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.create_rounded,
                    color: ColorConstant.primary,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    pageTitle,
                    style: GoogleFonts.robotoFlex(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorConstant.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title TextField
                        TextField(
                          controller: _titleController,
                          cursorColor: ColorConstant.primary,
                          cursorWidth: 2,
                          decoration: _buildInputDecoration(
                            labelText: 'Dream Title',
                            isContentField: false,
                          ),
                          style: GoogleFonts.robotoFlex(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Content TextField
                        Expanded(
                          child: TextField(
                            controller: _contentController,
                            cursorColor: ColorConstant.primary,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: _buildInputDecoration(
                              labelText: 'Capture the Details',
                              isContentField: true,
                            ),
                            style: GoogleFonts.robotoFlex(
                              fontSize: 16,
                              color: ColorConstant.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: CustomPillButton(
                            labelText: _viewModel.isSaving
                                ? "Saving..."
                                : isEditing
                                ? "Finalize Update"
                                : "Save Dream",
                            icon: _viewModel.isSaving
                                ? Icons.hourglass_empty_rounded
                                : isEditing
                                ? Icons.save_as_rounded
                                : Icons.cloud_done_rounded,
                            onPressed: _viewModel.isSaving
                                ? null
                                : () => _saveDreamEntry(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_viewModel.isSaving)
                  Positioned.fill(
                    child: CustomProgressIndicator(
                      icon: Icon(Icons.cloud_upload_rounded, size: 18),
                      indicatorText: Text(
                        "Saving Your Memory...",
                        style: GoogleFonts.robotoFlex(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.onSurface,
                        ),
                      ),
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
