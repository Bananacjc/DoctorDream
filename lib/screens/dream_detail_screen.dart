import 'dart:developer';

import 'package:doctor_dream/view_models/dream_detail_view_model.dart';
import 'package:doctor_dream/widgets/custom_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
  void initState() {
    super.initState();
    _viewModel.loadDreamAnalysis(widget.dreamEntry.dreamID);
  }

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

  Future<bool> _showAnalysisConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomPromptDialog(
        title: 'Analyze this dream?',
        isClosable: true,
        description: "You can analyze this dream to know what it means to you.",
        actions: [
          CustomTextButton(
            buttonText: 'Cancel',
            type: ButtonType.cancel,
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          CustomTextButton(
            buttonText: "Analyze",
            type: ButtonType.confirm,
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<dynamic> _buildAnalysisWindow(String result) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: ColorConstant.primary,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: ColorConstant.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Dream Analysis",
                  style: GoogleFonts.robotoFlex(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConstant.onPrimary,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: MarkdownBody(
                      data: result,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.robotoFlex(
                          fontSize: 16,
                          color: ColorConstant.onPrimary,
                        ),
                        h1: GoogleFonts.robotoFlex(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.onPrimary,
                        ),
                        h2: GoogleFonts.robotoFlex(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.onPrimary,
                        ),
                        h3: GoogleFonts.robotoFlex(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.onPrimary,
                        ),
                        strong: GoogleFonts.robotoFlex(
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.primaryContainer,
                        ),
                        listBullet: GoogleFonts.robotoFlex(
                          color: ColorConstant.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    DreamEntry thisEntry = widget.dreamEntry;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        //TODO: add layout builder for fetching process
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
                                  builder: (context) =>
                                      DreamEditScreen(dreamEntry: thisEntry),
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

                                    final success = await _viewModel
                                        .deleteDream(thisEntry.dreamID);

                                    if (!context.mounted) return;

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
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _viewModel.isAnalyzing
                            ? null
                            : () async {
                                if (_viewModel.existingAnalysis != null) {
                                  _buildAnalysisWindow(
                                    _viewModel.existingAnalysis!,
                                  );
                                  return;
                                }

                                final confirm =
                                    await _showAnalysisConfirmDialog();

                                if (!confirm) return;

                                final result = await _viewModel.analyzeDream(
                                  thisEntry.dreamTitle,
                                  thisEntry.dreamContent,
                                );

                                if (result != null) {
                                  await _viewModel.saveDreamAnalysis(
                                    widget.dreamEntry.dreamID,
                                    result,
                                  );
                                  await _viewModel.loadDreamAnalysis(
                                    widget.dreamEntry.dreamID,
                                  );
                                  _buildAnalysisWindow(result);
                                  log("Analysis saved and loaded");
                                }
                              },
                        icon: _viewModel.isAnalyzing
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: EdgeInsets.all(2),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ColorConstant.onPrimary,
                                ),
                              )
                            : Icon(_viewModel.existingAnalysis != null ?
                        Icons.visibility_outlined : Icons.analytics_outlined,
                            size: 24),
                        label: Text(
                          _viewModel.isAnalyzing
                              ? "Analyzing..."
                              : (_viewModel.existingAnalysis != null)
                              ? "View Analysis"
                              : "Analyze Dream",
                          style: GoogleFonts.robotoFlex(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstant.primaryContainer,
                          foregroundColor: ColorConstant.onPrimaryContainer,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
