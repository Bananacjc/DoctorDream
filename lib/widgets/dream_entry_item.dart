import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/models/dream_entry.dart';
import '../screens/dream_detail_screen.dart';

class DreamEntryItem extends StatelessWidget {
  final DreamEntry dreamEntry;
  final VoidCallback? onRefresh;

  const DreamEntryItem({super.key, required this.dreamEntry, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
              dreamEntry.dreamTitle,
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
                dreamEntry.dreamContent,
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
              DateFormat("hh:mm MMMM dd, yyyy").format(dreamEntry.updatedAt),
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
