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

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewViewModel _viewModel = ReviewViewModel();
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
          body: _viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _viewModel.dreams.isEmpty
              ? CustomPromptDialog(
                title: "Nothing here...",
                description:
                    "You haven't record any dream, how about try one now?",
                actions: [
                  CustomTextButton(
                    buttonText: "Add one now!",
                    type: ButtonType.confirm,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                        const DreamEditScreen())
                      );

                      if (result == true) {
                        _viewModel.loadDreams();
                      }
                    },
                  ),
                ],
              )
              : SingleChildScrollView(
                  physics: _viewModel.dreams.isEmpty
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    height: size.height,
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
                              Expanded(flex: 7, child: CustomSearchBar()),
                              Expanded(flex: 1, child: SizedBox()),
                              Expanded(flex: 2, child: CustomFilter()),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        // Dream entries
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
                    ),
                  ),
                ),
        );
      },
    );
  }
}
