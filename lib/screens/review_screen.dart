import 'package:doctor_dream/constants/size_constant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_filter.dart';
import '../data/models/dream_entry.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  final items = const [
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
    DreamEntryItem(),
  ];

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(8),
        height: size.height,
        width: size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Container(
              margin: EdgeInsets.only(top: size.height * 0.05),
              child: Column(
                children: [
                  Text("Dreams", style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    "Some description on this page",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
            ),
            // Search bar and filter
            Container(
              margin: EdgeInsets.only(top: 40),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 7, child: CustomSearchBar()),
                    Expanded(flex: 1, child: SizedBox()),
                    Expanded(flex: 2, child: CustomFilter()),
                  ],
                ),
              ),
            ),
            // Dream entries
            Container(
              margin: EdgeInsets.only(top: 16),
              width: size.width,
              height: (size.height * 0.65) - SizeConstants.bottomNavBarHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24)
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder: (context, i) {
                  return items[i];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DreamEntryItem extends StatelessWidget {
  //final DreamEntry dreamEntry;

  const DreamEntryItem({super.key /*required this.dreamEntry*/});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Dream Entry Title",
                style: GoogleFonts.robotoFlex(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 16,
                ),
              ),
              Text(
                "dd/mm/yy",
                style: GoogleFonts.robotoFlex(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Divider(),
          Text(
            "Description..",
            style: GoogleFonts.robotoFlex(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
