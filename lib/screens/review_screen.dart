import 'dart:developer';

import 'package:doctor_dream/constants/color_constant.dart';
import 'package:doctor_dream/screens/dream_detail_screen.dart';
import 'package:doctor_dream/widgets/custom_prompt_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/custom_filter.dart';
import '../data/models/dream_entry.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ScrollController _dreamEntryScroll = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _dreamEntryScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    DreamEntry dreamEntryOne = DreamEntry(
      dreamID: "dreamID1",
      dreamTitle: "I have a nightmare that I can't sleep",
      dreamContent:
          "The nightmare is the brain’s private theatre of terror, a sudden, vivid descent into personalized horror that leaves the sleeper gasping for breath and questioning the boundary between the subconscious and reality. Far exceeding the typical strangeness of a common bad dream, a true nightmare is defined by its intensity, its capacity to elicit genuine fear and anxiety, and the resulting sudden awakening. These nocturnal dramas are not random; they are often the subconscious mind's most critical, albeit brutal, attempt to process deep-seated anxieties, unresolved emotional conflicts, and external trauma."
          "\n\n"
          "Psychologically, nightmares serve a complex, protective function within the context of REM (Rapid Eye Movement) sleep, the phase of dreaming characterized by heightened brain activity. While the logical centers of the brain are quieted, the emotional centers—particularly the amygdala, which governs fear—are highly active. This environment allows the mind to simulate threatening scenarios without the body being in actual danger. Through this mechanism, nightmares act as an emotional regulation tool, attempting to desensitize the sleeper to past or anticipated stress. However, when the emotional load is too great, as is often the case with Post-Traumatic Stress Disorder (PTSD), the nightmare becomes a repetitive loop, constantly re-traumatizing the individual rather than offering catharsis. The recurring chase, the feeling of being trapped, or the paralyzing inability to scream are universal expressions of helplessness, reflecting real-world stresses related to work, relationships, or existential fears."
          "\n\n"
          "The power of the nightmare is perhaps best understood through its enduring cultural significance. For centuries, before the advent of modern sleep science, nightmares were interpreted as external, supernatural forces. The word 'nightmare' itself derives from the Old English mare, referring to a female demon or spirit that sat upon the chests of sleepers, suffocating them and causing terrifying visions. This belief speaks to the visceral, physical nature of the experience—the sensation of weight, pressure, and the struggle for air. While science has replaced demons with cortisol (the stress hormone) and spiritual attacks with dysfunctional REM cycles, the emotional impact remains potent. The shift from a religious or supernatural understanding to a scientific one validates the experience not as a fault of the spirit, but as a critical communication from the psyche."
          "\n\n"
          "Ultimately, the nightmare is a signal. It is a harsh, immediate indicator that the waking life is imposing a stress too great for routine mental housekeeping. Recognizing the nightmare not as a mere inconvenience but as a crucial message allows us to engage with our subconscious fears directly. By understanding that these nocturnal terrors are generated internally—tools for processing stress—we can begin to address the root causes during the day, thereby calming the anxious mind and reclaiming the peace of the night.",

      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final items = [
      DreamEntryItem(dreamEntry: dreamEntryOne),
      DreamEntryItem(dreamEntry: dreamEntryOne),
      DreamEntryItem(dreamEntry: dreamEntryOne),
      DreamEntryItem(dreamEntry: dreamEntryOne),
      DreamEntryItem(dreamEntry: dreamEntryOne),
      DreamEntryItem(dreamEntry: dreamEntryOne),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Text("Dreams", style: Theme.of(context).textTheme.titleLarge),
            Text(
              "Some description on this page",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(8),
          height: size.height,
          width: size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: items.isNotEmpty
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              if (items.isNotEmpty) ...[
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
                    controller: _dreamEntryScroll,
                    thumbVisibility: true,
                    radius: Radius.circular(16),
                    crossAxisMargin: 4,
                    thumbColor: ColorConstant.secondaryContainer,
                    child: ListView.builder(
                      controller: _dreamEntryScroll,
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        return items[i];
                      },
                    ),
                  ),
                ),
              ] else
                Center(
                  child: CustomPromptDialog(
                    title: "Nothing here...",
                    description:
                        "You haven't record any dream, how about try one now?",
                    actions: [
                      CustomTextButton(
                        buttonText: "Add one now!",
                        type: ButtonType.navigate,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      //TODO: add dream entry
                      log("Add dream");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstant.primaryContainer,
                      foregroundColor: ColorConstant.onPrimaryContainer,
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
  }
}

class DreamEntryItem extends StatelessWidget {
  final DreamEntry dreamEntry;

  const DreamEntryItem({super.key, required this.dreamEntry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DreamDetailScreen(dreamEntry: dreamEntry),
          ),
        );
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
              height: 32,
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
              "${dreamEntry.createdAt.day}/${dreamEntry.createdAt.month}/${dreamEntry.createdAt.year}",
              style: GoogleFonts.robotoFlex(
                color: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer.withAlpha(150),
                fontSize: 16,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }
}
