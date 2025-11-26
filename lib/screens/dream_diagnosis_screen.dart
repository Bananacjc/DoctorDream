import 'dart:developer';

import 'package:doctor_dream/widgets/dream_diagnosis_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constant.dart';
import '../view_models/dream_diagnosis_view_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_prompt_dialog.dart';
import 'dream_edit_screen.dart';

class DreamDiagnosisScreen extends StatefulWidget {
  const DreamDiagnosisScreen({super.key});

  @override
  State<DreamDiagnosisScreen> createState() => _DreamDiagnosisScreenState();
}

class _DreamDiagnosisScreenState extends State<DreamDiagnosisScreen> {
  final DreamDiagnosisViewModel _viewModel = DreamDiagnosisViewModel();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel.loadDiagnosis();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _showNoDiagnosisDialog() {
    return CustomPromptDialog(
      title: "Nothing here...",
      description: "You haven't do any diagnosis, how about try one now?",
      actions: [
        CustomTextButton(
          buttonText: "Do one now!",
          type: ButtonType.confirm,
          onPressed: () async {
            final result = await _viewModel.diagnose();

            if (result != null) {
              await _viewModel.saveDreamDiagnosis(result);
              await _viewModel.loadDiagnosis();
            }

            _viewModel.loadDiagnosis();
          },
        ),
      ],
    );
  }

  Widget _showNotEnoughDreamDialog() {
    return CustomPromptDialog(
      title: "I need to know more...",
      description:
          "You don't have enough dreams to do diagnosis, how about add more now?",
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
              _viewModel.loadDiagnosis();
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  "Diagnosis",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  "Your mental health helper",
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
                return const Center(
                  child: CircularProgressIndicator(
                    color: ColorConstant.onPrimary,
                  ),
                );
              }

              if (_viewModel.hasNoDiagnosis && _viewModel.hasEnoughDreams) {
                return _showNoDiagnosisDialog();
              }

              if (!_viewModel.hasEnoughDreams) {
                return _showNotEnoughDreamDialog();
              }

              return SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(8),
                  height: constraint.maxHeight,
                  width: size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 0),
                        width: size.width,
                        height: size.height * 0.6,
                        decoration: BoxDecoration(
                          color: ColorConstant.primaryContainer,
                        ),
                        child: RawScrollbar(
                          controller: _scrollController,
                          crossAxisMargin: 4,
                          thumbColor: ColorConstant.secondaryContainer,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            itemCount: _viewModel.diagnosis.length,
                            itemBuilder: (context, i) {
                              return DreamDiagnosisItem(
                                dreamDiagnosis: _viewModel.diagnosis[i],
                                onRefresh: () => _viewModel.loadDiagnosis(),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _viewModel.isDiagnosing
                                ? null
                                : () async {
                                    final result = await _viewModel.diagnose();

                                    if (result != null) {
                                      await _viewModel.saveDreamDiagnosis(
                                        result,
                                      );
                                      await _viewModel.loadDiagnosis();
                                    }

                                    _viewModel.loadDiagnosis();
                                  },
                            icon: _viewModel.isDiagnosing
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    padding: EdgeInsets.all(2),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ColorConstant.onPrimary,
                                    ),
                                  )
                                : Icon(Icons.favorite_outline, size: 24),
                            label: Text(
                              _viewModel.isDiagnosing
                                  ? "Diagnosing..."
                                  : "Diagnose My Dream",
                              style: GoogleFonts.robotoFlex(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.onPrimary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstant.primaryContainer,
                              foregroundColor: ColorConstant.onPrimaryContainer,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
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
