import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color_constant.dart';
import '../data/models/dream_entry.dart';

class DreamDetailScreen extends StatefulWidget {
  final DreamEntry dreamEntry;

  const DreamDetailScreen({super.key, required this.dreamEntry});

  @override
  State<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends State<DreamDetailScreen> {
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        onPressed: () {
                          //TODO: add function
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
                        onPressed: () {
                          //TODO: add function
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
