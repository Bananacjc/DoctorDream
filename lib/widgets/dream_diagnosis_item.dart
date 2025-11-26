import 'package:doctor_dream/data/models/dream_diagnosis.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/models/dream_diagnosis.dart';
import '../screens/dream_diagnosis_detail_screen.dart';
import '../screens/dream_diagnosis_screen.dart';

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
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dream Diagnosis",
              style: GoogleFonts.robotoFlex(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              maxLines: 1,
            ),
            Divider(),
            SizedBox(
              child: Text(
                dreamDiagnosis.diagnosisContent,
                style: GoogleFonts.robotoFlex(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.justify,
                maxLines: 2,
              ),
            ),
            Text(
              DateFormat(
                "hh:mm MMMM dd, yyyy",
              ).format(dreamDiagnosis.createdAt),
              style: GoogleFonts.robotoFlex(
                color: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer.withAlpha(150),
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }
}
