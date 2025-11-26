import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/color_constant.dart';
import '../data/models/dream_diagnosis.dart';

class DreamDiagnosisDetailScreen extends StatefulWidget {
  final DreamDiagnosis dreamDiagnosis;

  const DreamDiagnosisDetailScreen({super.key, required this.dreamDiagnosis});

  @override
  State<DreamDiagnosisDetailScreen> createState() =>
      _DreamDiagnosisDetailScreenState();
}

class _DreamDiagnosisDetailScreenState
    extends State<DreamDiagnosisDetailScreen> {
  MarkdownBody _showResultInMarkdown(String result) {
    return MarkdownBody(
      data: result,
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.robotoFlex(fontSize: 16, color: ColorConstant.onPrimary),
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
        listBullet: GoogleFonts.robotoFlex(color: ColorConstant.onPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    DreamDiagnosis thisDiagnosis = widget.dreamDiagnosis;

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
                    "Dream Diagnosis",
                    style: GoogleFonts.robotoFlex(
                      color: ColorConstant.onPrimary.withAlpha(150),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat(
                      "hh:mm MMMM dd, yyyy",
                    ).format(thisDiagnosis.createdAt),
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
                  child: _showResultInMarkdown(thisDiagnosis.diagnosisContent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
