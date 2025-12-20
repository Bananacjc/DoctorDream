import 'dart:developer';
import 'package:doctor_dream/screens/dream_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
import '../widgets/custom_prompt_dialog.dart';
import '../widgets/dream_entry_item.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_filter.dart';
import '../view_models/dream_review_view_model.dart';

class DreamReviewScreen extends StatefulWidget {
  const DreamReviewScreen({super.key});

  @override
  State<DreamReviewScreen> createState() => _DreamReviewScreenState();
}

class _DreamReviewScreenState extends State<DreamReviewScreen> {
  final DreamReviewViewModel _viewModel = DreamReviewViewModel();
  final ScrollController _dreamEntriesController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel.loadDreams();
  }

  @override
  void dispose() {
    _dreamEntriesController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Widget _buildCustomFilter() {
    return SizedBox(
      height: 40,
      child: CustomFilter<DreamFilterOption>(
        onFilterSelected: (DreamFilterOption selected) async {
          switch (selected) {
            case DreamFilterOption.newest:
              _viewModel.setSortOrder(SortOrder.newest);
              break;
            case DreamFilterOption.oldest:
              _viewModel.setSortOrder(SortOrder.oldest);
              break;
            case DreamFilterOption.dateRange:
              DateTimeRange<DateTime>? pickedRange = await _showDatePicker();
              if (pickedRange != null) {
                _viewModel.filterByDateRange(
                  pickedRange.start,
                  pickedRange.end,
                );
              }
              break;
            case DreamFilterOption.clear:
              _viewModel.clearFilters();
              break;
          }
        },
        filterOptions: [
          PopupMenuItem(
            enabled: false,
            child: Text(
              'Organize Your Thoughts',
              style: GoogleFonts.robotoFlex(
                color: ColorConstant.onInverseSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuItem(
            value: DreamFilterOption.newest,
            child: Row(
              children: [
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: ColorConstant.onInverseSurface,
                ),
                SizedBox(width: 8),
                Text(
                  'The Latest Dreams',
                  style: GoogleFonts.robotoFlex(
                    color: ColorConstant.onInverseSurface,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: DreamFilterOption.oldest,
            child: Row(
              children: [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 18,
                  color: ColorConstant.onInverseSurface,
                ),
                SizedBox(width: 8),
                Text(
                  'Way Back When',
                  style: GoogleFonts.robotoFlex(
                    color: ColorConstant.onInverseSurface,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            value: DreamFilterOption.dateRange,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: ColorConstant.onInverseSurface,
                ),
                SizedBox(width: 8),
                Text(
                  'Pick a Date Range',
                  style: GoogleFonts.robotoFlex(
                    color: ColorConstant.onInverseSurface,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            value: DreamFilterOption.clear,
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt_off_rounded,
                  size: 18,
                  color: ColorConstant.errorContainer,
                ),
                SizedBox(width: 8),
                Text(
                  'See Everything!',
                  style: GoogleFonts.robotoFlex(
                    color: ColorConstant.errorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<DateTimeRange<DateTime>?> _showDatePicker() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstant.primaryContainer,
              onPrimary: ColorConstant.onPrimaryContainer,
              onSurface: ColorConstant.onPrimary,
              secondary: ColorConstant.primaryContainer.withAlpha(100),
            ),
          ),
          child: child!,
        );
      },
    );
    return pickedRange;
  }

  Widget _showNoDreamEntriesDialog() {
    return CustomPromptDialog(
      title: "Your Page is Blank!",
      icon: Icons.lightbulb_outline_rounded,
      description: "It's empty! Let's capture your first sleep story.",
      actions: [
        CustomTextButton(
          buttonText: "Start Writing!",
          type: ButtonType.confirm,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DreamEditScreen()),
            );

            if (result == true) {
              _viewModel.loadDreams();
            }
          },
        ),
      ],
    );
  }

  Future<void> _navigateToDreamEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DreamEditScreen()),
    );
    if (result == true) {
      _viewModel.loadDreams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_rounded,
                      color: ColorConstant.primary,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Your Dream Journal",
                      style: GoogleFonts.robotoFlex(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorConstant.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Discover the secrets in your sleep.",
                  style: GoogleFonts.robotoFlex(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: ColorConstant.onSurfaceVariant.withAlpha(205),
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorConstant.surfaceContainer,
                  ColorConstant.surfaceContainerHigh,
                  ColorConstant.surfaceContainerHighest
                ]
              )
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Search bar and filter
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 12,
                          child: CustomSearchBar(
                            onSearch: (query) {
                              _viewModel.searchDreams(query);
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildCustomFilter()),
                      ],
                    ),
                  ),
                  if (_viewModel.isLoading)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: ColorConstant.primary,
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.hourglass_empty_rounded,
                                  color: ColorConstant.onSurface,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Brewing up your memories...",
                                  style: GoogleFonts.robotoFlex(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstant.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_viewModel.hasNoDreams)
                    Expanded(child: Center(child: _showNoDreamEntriesDialog()))
                  // Dream entries
                  else if (_viewModel.dreams.isEmpty) ...[
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sentiment_dissatisfied_outlined,
                            size: 64,
                            color: ColorConstant.onPrimary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Hmm, those dreams are hiding!",
                            style: GoogleFonts.robotoFlex(
                              color: ColorConstant.onPrimary,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Try a different filter or tap 'See Everything' to "
                                "reset.",
                            style: GoogleFonts.robotoFlex(
                              color: ColorConstant.onPrimary.withAlpha(180),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Expanded(
                      child: RawScrollbar(
                        controller: _dreamEntriesController,
                        thumbColor: ColorConstant.onSurface,
                        radius: Radius.circular(8),
                        child: ListView.builder(
                          controller: _dreamEntriesController,
                          padding: EdgeInsets.zero,
                          itemCount: _viewModel.dreams.length,
                          itemBuilder: (context, i) {
                            return DreamEntryItem(
                              dreamEntry: _viewModel.dreams[i],
                              onRefresh: () => _viewModel.loadDreams(),
                            );
                          },
                        ),
                      ),
                    ),
                  // Add dream button
                  SizedBox(
                    child: Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.center,
                        child: CustomPillButton(
                          onPressed: _navigateToDreamEditScreen,
                          labelText: "Record Your Dream Now",
                          icon: Icons.cloud_queue_rounded,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
