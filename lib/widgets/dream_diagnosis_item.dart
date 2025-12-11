import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/color_constant.dart';
import '../data/models/dream_diagnosis.dart';
import '../screens/dream_diagnosis_detail_screen.dart';

class DreamDiagnosisItem extends StatelessWidget {
  final DreamDiagnosis dreamDiagnosis;
  final VoidCallback? onRefresh;

  const DreamDiagnosisItem({
    super.key,
    required this.dreamDiagnosis,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DreamDiagnosisDetailScreen(dreamDiagnosis: dreamDiagnosis),
          ),
        );

        if (result == true && onRefresh != null) {
          onRefresh!();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorConstant.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ColorConstant.tertiary.withAlpha(50),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorConstant.shadow.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Icon
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorConstant.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: ColorConstant.onTertiaryContainer,
                    size: 14,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Latest Insight",
                        style: GoogleFonts.robotoFlex(
                          color: ColorConstant.tertiary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat(
                          "MMMM dd, yyyy",
                        ).format(dreamDiagnosis.createdAt),
                        style: GoogleFonts.robotoFlex(
                          color: ColorConstant.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              dreamDiagnosis.diagnosisContent,
              style: GoogleFonts.robotoFlex(
                color: ColorConstant.onSurface,
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Read Full Analysis",
                  style: GoogleFonts.robotoFlex(
                    color: ColorConstant.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: ColorConstant.primary,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
