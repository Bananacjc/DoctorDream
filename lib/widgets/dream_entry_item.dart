import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants/color_constant.dart';
import '../data/models/dream_entry.dart';
import '../screens/dream_detail_screen.dart';

class DreamEntryItem extends StatelessWidget {
  final DreamEntry dreamEntry;
  final VoidCallback? onRefresh;

  const DreamEntryItem({super.key, required this.dreamEntry, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DreamDetailScreen(dreamEntry: dreamEntry),
          ),
        );

        if (result == true && onRefresh != null) {
          onRefresh!();
        }
      },
      child: Container(
        padding: EdgeInsets.all(20),
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        decoration: BoxDecoration(
          color: ColorConstant.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ColorConstant.primary, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              dreamEntry.dreamTitle,
              style: GoogleFonts.robotoFlex(
                color: ColorConstant.onPrimaryContainer,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              maxLines: 1,
            ),

            // Date
            Text(
              DateFormat(
                "MMM dd, yyyy \u00B7 hh:mm a",
              ).format(dreamEntry.updatedAt),
              style: GoogleFonts.robotoFlex(
                color: ColorConstant.onSurfaceVariant.withAlpha(153),
                fontSize: 14,
              ),
              textAlign: TextAlign.start,
            ),

            Divider(
              height: 16,
              color: ColorConstant.outlineVariant.withAlpha(77),
            ),
            SizedBox(
              child: Text(
                dreamEntry.dreamContent,
                style: GoogleFonts.robotoFlex(
                  color: ColorConstant.onPrimaryContainer,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.justify,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
