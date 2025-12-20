import 'dart:developer';
import 'dart:convert';
import 'package:doctor_dream/screens/chat_screen.dart';
import 'package:doctor_dream/view_models/dream_diagnosis_detail_view_model.dart';
import 'package:doctor_dream/widgets/custom_button.dart';
import 'package:doctor_dream/widgets/custom_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../data/local/local_database.dart';

import '../constants/color_constant.dart';
import '../data/models/dream_diagnosis.dart';
import '../data/models/user_info.dart';

class DreamDiagnosisDetailScreen extends StatefulWidget {
  final DreamDiagnosis dreamDiagnosis;

  const DreamDiagnosisDetailScreen({super.key, required this.dreamDiagnosis});

  @override
  State<DreamDiagnosisDetailScreen> createState() =>
      _DreamDiagnosisDetailScreenState();
}

class _DreamDiagnosisDetailScreenState
    extends State<DreamDiagnosisDetailScreen> {
  final _viewModel = DreamDiagnosisDetailViewModel();
  bool _isChatStarting = false;

  String _getDetailContent(String rawContent) {
    try {
      final Map<String, dynamic> json = jsonDecode(rawContent);
      return json['content'] ?? rawContent;
    } catch (e) {
      return rawContent;
    }
  }

  String _getSummary(String rawContent) {
    try {
      final Map<String, dynamic> json = jsonDecode(rawContent);
      return json['summary'] ?? "";
    } catch (e) {
      return "";
    }
  }

  Future<void> _startChatDiscussion(String rawDiagnosis) async {
    setState(() {
      _isChatStarting = true;
    });

    final profile = await LocalDatabase.instance.fetchUserProfile();
    final dummyUserInfo = UserInfo.fromUserProfile(profile);
    String initialMessage;

    final detailContent = _getDetailContent(rawDiagnosis);

    try {
      initialMessage = await _viewModel.startDiagnosisChat(
        userInfo: dummyUserInfo,
        diagnosis: detailContent,
      );
    } catch (e) {
      initialMessage =
          "I'm having trouble connecting to your subconscious right now. Please try again.";
    }

    if (!mounted) return;

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

  MarkdownBody _showResultInMarkdown(String result) {
    return MarkdownBody(
      data: result,
      selectable: true,
      onTapLink: (text, href, title) async {
        if (href != null) {
          final Uri url = Uri.parse(href);
          try {
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              // TODO: Snack bar
              log("Cannot launch link");
          }
            } catch (e) {
            log("Error launching url: $e");
          }
        }
      },
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.robotoFlex(
          fontSize: 16,
          height: 1.6,
          color: ColorConstant.onSurface.withAlpha(225),
        ),
        h1: GoogleFonts.robotoFlex(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ColorConstant.tertiary,
        ),
        h2: GoogleFonts.robotoFlex(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ColorConstant.tertiary,
        ),
        h3: GoogleFonts.robotoFlex(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ColorConstant.tertiary,
        ),
        strong: GoogleFonts.robotoFlex(
          fontWeight: FontWeight.bold,
          color: ColorConstant.onPrimaryContainer,
        ),
        listBullet: GoogleFonts.robotoFlex(
          fontSize: 16,
          color: ColorConstant.tertiary,
        ),
        blockquote: GoogleFonts.robotoFlex(
          color: ColorConstant.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: ColorConstant.tertiary, width: 4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DreamDiagnosis thisDiagnosis = widget.dreamDiagnosis;
    final displayContent = _getDetailContent(thisDiagnosis.diagnosisContent);

    return Scaffold(
      backgroundColor: ColorConstant.surface,
      appBar: AppBar(
        backgroundColor: ColorConstant.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ColorConstant.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Insight Details",
          style: GoogleFonts.robotoFlex(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorConstant.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: RawScrollbar(
                  thumbColor: ColorConstant.onSurfaceVariant,
                  radius: Radius.circular(8),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ColorConstant.tertiary.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: ColorConstant.tertiary,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Deep Dive Analysis",
                                  style: GoogleFonts.robotoFlex(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstant.onSurface,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    "MMMM dd, yyyy 'at' hh:mm a",
                                  ).format(thisDiagnosis.createdAt),
                                  style: GoogleFonts.robotoFlex(
                                    color: ColorConstant.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(color: ColorConstant.outlineVariant),
                        SizedBox(height: 8),

                        _showResultInMarkdown(displayContent),

                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ColorConstant.surface,
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstant.shadow.withAlpha(50),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomPillButton(
                    labelText: "Explore This Further",
                    icon: Icons.forum_rounded,
                    onPressed: _isChatStarting
                        ? null
                        : () => _startChatDiscussion(
                            thisDiagnosis.diagnosisContent,
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (_isChatStarting)
            Positioned.fill(
              child: CustomProgressIndicator(
                icon: Icon(
                  Icons.chat_bubble_rounded,
                  size: 18,
                  color: ColorConstant.onSurface,
                ),
                indicatorText: Text(
                  "Connecting with the Subconscious...",
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
  }
}
