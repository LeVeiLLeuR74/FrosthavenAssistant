import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Layout/modifier_deck_widget.dart';
import 'package:frosthaven_assistant/Layout/section_list.dart';
import 'package:frosthaven_assistant/Layout/top_bar.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/main.dart';

import '../Model/campaign.dart';
import '../Resource/game_data.dart';
import '../Resource/scaling.dart';
import '../Resource/settings.dart';
import '../Resource/ui_utils.dart';
import '../services/service_locator.dart';
import 'bottom_bar.dart';
import 'loot_deck_widget.dart';
import 'main_list.dart';
import 'menus/main_menu.dart';

class ToastNotifier extends StatelessWidget {
  const ToastNotifier({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
        valueListenable: getIt<GameState>().toastMessage,
        builder: (context, value, child) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (getIt<GameState>().toastMessage.value != "") {
              if (context.mounted) {
                showToastSticky(context, getIt<GameState>().toastMessage.value);
              }
            }
          });

          return const SizedBox(
            width: 0.0000,
            height: 0.0000,
          );
        });
  }
}

class MainScaffoldBody extends StatelessWidget {
  const MainScaffoldBody({super.key});

  double getSectionWidth(BuildContext context) {
    bool modFitsOnBar = modifiersFitOnBar(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double barScale = getIt<Settings>().userScalingBars.value;

    bool hasLootDeck = GameMethods.hasLootDeck();
    double sectionWidth = screenWidth;
    if (hasLootDeck) {
      sectionWidth -= 94 *
          barScale; //width of loot deck todo: add the 5 * barScale margin here?
    }
    if ((!modFitsOnBar || GameMethods.shouldShowAlliesDeck()) &&
        getIt<Settings>().showAmdDeck.value) {
      sectionWidth -= 153 * barScale; //width of amd
    }
    return sectionWidth;
  }

  int? getNrOfSections() {
    final GameData gameData = getIt<GameData>();
    final GameState gameState = getIt<GameState>();
    int? nrOfSections = gameData
        .modelData
        .value[gameState.currentCampaign.value]
        ?.scenarios[gameState.scenario.value]
        ?.sections
        .length;
    if (nrOfSections != null &&
        gameState.scenarioSectionsAdded.length == nrOfSections) {
      nrOfSections = null;
    }
    if (getIt<Settings>().showSectionsInMainView.value == false) {
      nrOfSections = null;
    }
    return nrOfSections;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        const MainList(),
        const ToastNotifier(),
        ValueListenableBuilder<Map<String, CampaignModel>>(
            valueListenable: getIt<GameData>().modelData,
            builder: (context, value, child) {
              return ValueListenableBuilder<int>(
                  valueListenable: getIt<GameState>().commandIndex,
                  builder: (context, value, child) {
                    return ValueListenableBuilder<double>(
                        valueListenable: getIt<Settings>().userScalingBars,
                        builder: (context, value, child) {
                          GameState gameState = getIt<GameState>();
                          double barScale =
                              getIt<Settings>().userScalingBars.value;
                          bool hasLootDeck = GameMethods.hasLootDeck();
                          bool modFitsOnBar = modifiersFitOnBar(context);
                          var sectionWidth = getSectionWidth(context);

                          //move to separate row if it doesn't fit
                          bool sectionsOnSeparateRow = false;
                          int? nrOfSections = getNrOfSections();
                          if ((nrOfSections != null &&
                                  nrOfSections > 0 &&
                                  sectionWidth < 58 * barScale) ||
                              (nrOfSections != null &&
                                  nrOfSections > 2 &&
                                  sectionWidth < 58 * barScale * 2)) {
                            //in case doesn't fit
                            sectionsOnSeparateRow = true;
                            sectionWidth = MediaQuery.of(context).size.width;
                          }

                          return Positioned(
                              width: screenWidth,
                              bottom: 4 * barScale,
                              left: 5 * barScale,
                              child: Column(children: [
                                Row(
                                    mainAxisAlignment:
                                        ((!sectionsOnSeparateRow &&
                                                    nrOfSections != null) ||
                                                hasLootDeck)
                                            ? MainAxisAlignment.spaceBetween
                                            : MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      if (hasLootDeck) const LootDeckWidget(),
                                      if (!sectionsOnSeparateRow &&
                                          nrOfSections != null)
                                        SizedBox(
                                          width: sectionWidth,
                                          child: const SectionList(),
                                        ),
                                      Column(children: [
                                        if (GameMethods.shouldShowAlliesDeck())
                                          const ModifierDeckWidget(
                                              name: "allies"),
                                        if (!modFitsOnBar &&
                                            gameState.currentCampaign.value !=
                                                "Buttons and Bugs" && //hide amd deck for buttons and bugs
                                            getIt<Settings>().showAmdDeck.value)
                                          Container(
                                              margin: EdgeInsets.only(
                                                top: 4 * barScale,
                                              ),
                                              child: const ModifierDeckWidget(
                                                name: '',
                                              ))
                                      ])
                                    ]),
                                if (sectionsOnSeparateRow &&
                                    nrOfSections != null)
                                  SizedBox(
                                    width: sectionWidth,
                                    child: const SectionList(),
                                  ),
                              ]));
                        });
                  });
            }),
        if (loading.value && kDebugMode)
          Positioned(
              left: screenWidth * 0.45,
              top: MediaQuery.of(context).size.height * 0.4,
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              child: const CircularProgressIndicator(
                strokeWidth: 10,
              ))
      ],
    );
  }
}

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    setupMoreGetIt(context);
    return ValueListenableBuilder<double>(
        valueListenable: getIt<Settings>().userScalingBars,
        builder: (context, value, child) {
          return SafeArea(
              left: false,
              right: false,
              maintainBottomViewPadding: true,
              child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  bottomNavigationBar: createBottomBar(context),
                  appBar: createTopBar(),
                  drawer: createMainMenu(context),
                  body: const MainScaffoldBody()));
        });
  }
}
