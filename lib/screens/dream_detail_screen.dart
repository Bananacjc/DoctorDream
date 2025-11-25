import 'dart:developer';

import 'package:doctor_dream/view_models/dream_detail_view_model.dart';
import 'package:doctor_dream/widgets/custom_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color_constant.dart';
import '../data/models/dream_entry.dart';
import '../widgets/custom_button.dart';
import 'dream_edit_screen.dart';

class DreamDetailScreen extends StatefulWidget {
  final DreamEntry dreamEntry;

  const DreamDetailScreen({super.key, required this.dreamEntry});

  @override
  State<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends State<DreamDetailScreen> {
  final _viewModel = DreamDetailViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<bool> _showDeleteConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomPromptDialog(
        title: 'Delete this Dream?',
        isClosable: true,
        description:
            "Once deleted, you won't be able to "
            "get it back.",
        actions: [
          CustomTextButton(
            buttonText: 'Cancel',
            type: ButtonType.cancel,
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          CustomTextButton(
            buttonText: "Delete",
            type: ButtonType.warning,
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    DreamEntry thisEntry = widget.dreamEntry;
    return Scaffold(
      appBar: AppBar(scrolledUnderElevation: 0),
      body: Container(
        margin: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(color: ColorConstant.primary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thisEntry.dreamTitle,
                    style: GoogleFonts.robotoFlex(
                      color: ColorConstant.onPrimary.withAlpha(150),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat(
                      "hh:mm MMMM dd, yyyy",
                    ).format(thisEntry.updatedAt),
                    style: GoogleFonts.robotoFlex(
                      color: ColorConstant.onPrimary.withAlpha(150),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: ColorConstant.onPrimary.withAlpha(150)),
            SizedBox(height: 8),
            Expanded(
              child: RawScrollbar(
                thumbColor: ColorConstant.secondaryContainer,
                radius: Radius.circular(16),
                thumbVisibility: true,
                padding: EdgeInsets.only(left: 4),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    thisEntry.dreamContent,
                    textAlign: TextAlign.justify,
                    style: GoogleFonts.robotoFlex(
                      fontSize: 18,
                      color: ColorConstant.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DreamEditScreen(
                                dreamEntry: thisEntry,
                              ),
                            ),
                          );

                          if (result == true && context.mounted) {
                            Navigator.pop(context, true);
                          }
                          log("Edit dream");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstant.primaryContainer,
                          foregroundColor: ColorConstant.onPrimaryContainer,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Icon(Icons.edit, size: 24),
                      ),
                    ),
                    SizedBox(width: 16),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _viewModel.isDeleting
                            ? null
                            : () async {
                                final confirm =
                                    await _showDeleteConfirmDialog();
                                if (!confirm) return;

                                final success = await _viewModel.deleteDream(
                                  thisEntry.dreamID,
                                );
                                if (success && context.mounted) {
                                  Navigator.pop(context, true);
                                }

                                log("Delete dream");
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstant.primaryContainer,
                          foregroundColor: ColorConstant.onPrimaryContainer,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Icon(Icons.delete, size: 24),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      //TODO: add function
                      log("Analysis");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.primaryContainer,
                      foregroundColor: ColorConstant.onPrimaryContainer,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Icon(Icons.analytics, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
