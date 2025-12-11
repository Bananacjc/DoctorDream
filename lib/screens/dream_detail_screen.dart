import 'dart:developer';

import 'package:doctor_dream/view_models/dream_detail_view_model.dart';
import 'package:doctor_dream/widgets/custom_progress_indicator.dart';
import 'package:doctor_dream/widgets/custom_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../constants/color_constant.dart';
import '../data/models/dream_entry.dart';
import '../data/models/user_info.dart';
import '../widgets/custom_button.dart';
import 'chat_screen.dart';
import 'dream_edit_screen.dart';

class DreamDetailScreen extends StatefulWidget {
  final DreamEntry dreamEntry;

  const DreamDetailScreen({super.key, required this.dreamEntry});

  @override
  State<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends State<DreamDetailScreen> {
  final _viewModel = DreamDetailViewModel();
  bool _isChatStarting = false;

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

  Future<void> _navigateToDreamEditScreen(DreamEntry dreamEntry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DreamEditScreen(dreamEntry: dreamEntry),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteDreamEntry(DreamEntry dreamEntry) async {
    final confirm = await _showDeleteConfirmDialog();
    if (!confirm) return;

    final success = await _viewModel.deleteDream(dreamEntry.dreamID);

    if (!mounted) return;

    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<bool> _showDeleteConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomPromptDialog(
        title: 'Delete Dream?',
        icon: Icons.delete_forever_rounded,
        isClosable: true,
        description:
            "Once deleted, your dream will be gone forever. Are you sure you "
            "want to let it go?",
        actions: [
          CustomTextButton(
            buttonText: 'Wait, Cancel',
            type: ButtonType.cancel,
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          CustomTextButton(
            buttonText: "Yes, Delete It",
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

  Future<bool> _analyzeDream(DreamEntry dreamEntry) async {
    if (_viewModel.existingAnalysis != null) {
      _buildAnalysisWindow(_viewModel.existingAnalysis!);
      return true;
    }

    final confirm = await _showAnalysisConfirmDialog();
    if (!confirm) return false;

    final analysis = await _viewModel.analyzeDream(
      dreamEntry.dreamTitle,
      dreamEntry.dreamContent,
    );

    if (analysis != null) {
      await _viewModel.saveDreamAnalysis(dreamEntry.dreamID, analysis);
      await _viewModel.loadDreamAnalysis(dreamEntry.dreamID);
      _buildAnalysisWindow(analysis);
      return true;
    }

    return false;
  }

  Future<bool> _showAnalysisConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CustomPromptDialog(
        title: 'Ready for Insight?',
        icon: Icons.psychology_alt_rounded,
        isClosable: true,
        description:
            "Let me help you uncover the hidden meaning and "
            "emotional patterns in this dream.",
        actions: [
          CustomTextButton(
            buttonText: 'Not Yet',
            type: ButtonType.cancel,
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          CustomTextButton(
            buttonText: "Analyze Now",
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

  Future<void> _startChatDiscussion(
    BuildContext modalContext,
    String analysis,
  ) async {
    Navigator.pop(modalContext);

    setState(() {
      _isChatStarting = true;
    });

    final dummyUserInfo = UserInfo.defaultValues();
    String initialMessage;

    try {
      initialMessage = await _viewModel.startDreamChat(
        userInfo: dummyUserInfo,
        title: widget.dreamEntry.dreamTitle,
        analysis: analysis,
      );
    } catch (e) {
      initialMessage =
          "I'm having trouble connecting to your subconscious right now. Please try again.";
    }

    if (!mounted) {
      if (_isChatStarting) {
        setState(() {
          _isChatStarting = false;
        });
      }
      return;
    }

    setState(() {
      _isChatStarting = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(initialMessage: initialMessage,
          isAiInitiated: true,),
      ),
    );
  }

  Future<dynamic> _buildAnalysisWindow(String result) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: ColorConstant.surfaceContainerHigh,
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
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: ColorConstant.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Your Dream Insight",
                      style: GoogleFonts.robotoFlex(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorConstant.onSurface,
                      ),
                    ),
                    // Buttons (talk about it)
                    SizedBox(
                      height: 48,
                      child: CustomPillButton(
                        onPressed: () => _startChatDiscussion(context, result),
                        labelText: "Let's Chat",
                        icon: Icons.forum_rounded,
                      ),
                    ),
                  ],
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
                          color: ColorConstant.onSurface,
                        ),
                        h1: GoogleFonts.robotoFlex(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.primary,
                        ),
                        h2: GoogleFonts.robotoFlex(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.primary,
                        ),
                        h3: GoogleFonts.robotoFlex(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.primary,
                        ),
                        strong: GoogleFonts.robotoFlex(
                          fontWeight: FontWeight.bold,
                          color: ColorConstant.primary,
                        ),
                        listBullet: GoogleFonts.robotoFlex(
                          color: ColorConstant.onSurface,
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
    DreamEntry thisEntry = widget.dreamEntry;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        //TODO: add layout builder for fetching process
        final bool isAnyLoading =
            _isChatStarting ||
            _viewModel.isFetchingAnalysis ||
            _viewModel.isAnalyzing;
        return Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: ColorConstant.surface,
          ),
          body: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and date
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thisEntry.dreamTitle,
                            style: GoogleFonts.robotoFlex(
                              color: ColorConstant.onSurface,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat(
                              "EEE, MMM dd, yyyy 'at' hh:mm a",
                            ).format(thisEntry.updatedAt),
                            style: GoogleFonts.robotoFlex(
                              color: ColorConstant.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    Divider(color: ColorConstant.outlineVariant),
                    // Content
                    Expanded(
                      child: RawScrollbar(
                        thumbColor: ColorConstant.onSurfaceVariant,
                        radius: Radius.circular(8),
                        thumbVisibility: true,
                        padding: EdgeInsets.only(left: 4),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            thisEntry.dreamContent,
                            textAlign: TextAlign.justify,
                            style: GoogleFonts.robotoFlex(
                              fontSize: 17,
                              height: 1.5,
                              color: ColorConstant.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Buttons (edit, delete, analyze)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CustomIconActionButton(
                                icon: Icons.edit_note_rounded,
                                onPressed: () =>
                                    _navigateToDreamEditScreen(thisEntry),
                              ),
                              SizedBox(width: 16),
                              CustomIconActionButton(
                                icon: Icons.delete_forever_rounded,
                                onPressed: () => _deleteDreamEntry(thisEntry),
                                backgroundColor: ColorConstant.errorContainer,
                                foregroundColor: ColorConstant.onErrorContainer,
                              ),
                            ],
                          ),
                          CustomPillButton(
                            icon: _viewModel.existingAnalysis != null
                                ? Icons.visibility_rounded
                                : Icons.psychology_alt_rounded,
                            labelText: _viewModel.existingAnalysis != null
                                ? "View Insight"
                                : "Get Insight",
                            onPressed: () =>
                                (_viewModel.isAnalyzing ||
                                    _viewModel.isDeleting)
                                ? null
                                : _analyzeDream(thisEntry),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isAnyLoading)
                Positioned.fill(
                  child: CustomProgressIndicator(
                    icon: Icon(
                      _isChatStarting
                          ? Icons.chat_bubble_rounded
                          : _viewModel.isFetchingAnalysis
                          ? Icons.monitor_heart_rounded
                          : _viewModel.isAnalyzing
                          ? Icons.lightbulb_rounded
                          : Icons.delete_forever_rounded,
                      size: 18,
                      color: ColorConstant.onSurface,
                    ),
                    indicatorText: Text(
                      _isChatStarting
                          ? "Connecting with the Subconscious..."
                          : _viewModel.isFetchingAnalysis
                          ? "Checking for past insights..."
                          : _viewModel.isAnalyzing
                          ? "What could this dream mean..."
                          : "Removing this dream...",
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
        );
      },
    );
  }
}
