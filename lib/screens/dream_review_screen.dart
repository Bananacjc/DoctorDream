import 'dart:developer';

import 'package:doctor_dream/screens/dream_detail_screen.dart';
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

  Widget _buildCustomFilter() {
    return CustomFilter<DreamFilterOption>(
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
              _viewModel.filterByDateRange(pickedRange.start, pickedRange.end);
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
            'Sort By',
            style: GoogleFonts.robotoFlex(
              color: ColorConstant.onSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        PopupMenuItem(
          value: DreamFilterOption.newest,
          child: Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 18,
                color: ColorConstant.onSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Most Recent',
                style: GoogleFonts.robotoFlex(color: ColorConstant.onSecondary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: DreamFilterOption.oldest,
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 18,
                color: ColorConstant.onSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Most Oldest',
                style: GoogleFonts.robotoFlex(color: ColorConstant.onSecondary),
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
                Icons.calendar_today,
                size: 18,
                color: ColorConstant.onSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Select Date Range',
                style: GoogleFonts.robotoFlex(color: ColorConstant.onSecondary),
              ),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: DreamFilterOption.clear,
          child: Row(
            children: [
              Icon(Icons.filter_alt_off,
              size: 18,
              color: ColorConstant.error,),
              SizedBox(width: 8),
              Text(
                'Clear Filters',
                style: GoogleFonts.robotoFlex(color: ColorConstant.error,
                    fontWeight: FontWeight.bold),
              )
            ],
          )),
      ],
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
      title: "Nothing here...",
      description: "You haven't record any dream, how about try one now?",
      actions: [
        CustomTextButton(
          buttonText: "Add one now!",
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

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Column(
              children: [
                Text("Dreams", style: Theme.of(context).textTheme.titleLarge),
                Text(
                  "Your subconscious journal",
                  style: GoogleFonts.robotoFlex(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraint) {
              if (_viewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_viewModel.hasNoDreams) {
                return _showNoDreamEntriesDialog();
              }

              return SingleChildScrollView(
                physics: _viewModel.dreams.isEmpty
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                child: Container(
                  padding: EdgeInsets.all(8),
                  height: constraint.maxHeight,
                  width: size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Search bar and filter
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 7,
                              child: CustomSearchBar(
                                onSearch: (query) {
                                  _viewModel.searchDreams(query);
                                },
                              ),
                            ),
                            Expanded(flex: 1, child: SizedBox()),
                            Expanded(flex: 2, child: _buildCustomFilter()),
                          ],
                        ),
                      ),
                      // Dream entries
                      if (_viewModel.dreams.isEmpty) ...[
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: ColorConstant.onPrimary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "No dreams found matching your search "
                                "criteria",
                                style: GoogleFonts.robotoFlex(
                                  color: ColorConstant.onPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        SizedBox(height: 16),
                        Container(
                          margin: EdgeInsets.only(top: 0),
                          width: size.width,
                          height: size.height * 0.60,
                          decoration: BoxDecoration(
                            color: ColorConstant.primaryContainer,
                          ),
                          child: RawScrollbar(
                            controller: _dreamEntriesController,
                            crossAxisMargin: 4,
                            thumbColor: ColorConstant.secondaryContainer,
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
                        SizedBox(height: 16),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () async {
                                log("Add dream");
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DreamEditScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _viewModel.loadDreams();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstant.primaryContainer,
                                foregroundColor:
                                    ColorConstant.onPrimaryContainer,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Icon(Icons.add, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
