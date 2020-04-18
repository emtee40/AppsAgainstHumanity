import 'dart:async';

import 'package:appsagainsthumanity/data/features/game/game_repository.dart';
import 'package:appsagainsthumanity/internal.dart';
import 'package:appsagainsthumanity/ui/game/bloc/bloc.dart';
import 'package:appsagainsthumanity/ui/game/screens/gameplay/widget/judge/judging_pager.dart';
import 'package:appsagainsthumanity/ui/game/screens/gameplay/widget/judge/player_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class JudgeDredd extends StatefulWidget {
  final GameViewState state;

  JudgeDredd(this.state);

  @override
  _JudgeDreddState createState() => _JudgeDreddState();
}

class _JudgeDreddState extends State<JudgeDredd> {
  final JudgementController controller = JudgementController();

  @override
  void initState() {
    super.initState();
    controller.totalPageCount = widget.state.game.turn?.responses?.length ?? 0;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        JudgingPager(
          state: widget.state,
          controller: controller,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 48),
            child: StreamBuilder<int>(
                stream: controller.observePageChanges(),
                builder: (context, snapshot) {
                  var currentPage = snapshot.data ?? 0;
                  var showLeft = currentPage > 0;
                  var showRight = currentPage < controller.totalPageCount - 1;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _buildPageButton(context: context, iconData: Icons.keyboard_arrow_left, isVisible: showLeft),
                      _buildPickWinnerButton(context),
                      _buildPageButton(
                          context: context, iconData: Icons.keyboard_arrow_right, isLeft: false, isVisible: showRight),
                    ],
                  );
                }),
          ),
        )
      ],
    );
  }

  Widget _buildPickWinnerButton(BuildContext context) {
    return RaisedButton.icon(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: StadiumBorder(),
      color: AppColors.secondary,
      onPressed: () async {
        var currentPlayerResponse = controller.currentPlayerResponse;
        if (currentPlayerResponse != null) {
          print("Winner selected! ${currentPlayerResponse.playerId}");
          await context.repository<GameRepository>()
              .pickWinner(currentPlayerResponse.playerId);
        }
      },
      icon: Icon(
        MdiIcons.crown,
        color: Colors.black87,
      ),
      label: Container(
        margin: const EdgeInsets.only(left: 16, right: 40),
        child: Text(
          "WINNER",
          style: context.theme.textTheme.button.copyWith(
            color: Colors.black87,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    @required BuildContext context,
    @required IconData iconData,
    isVisible = true,
    isLeft = true,
  }) {
    return AnimatedOpacity(
      opacity: isVisible ? 1 : 0,
      duration: Duration(milliseconds: 150),
      child: Container(
        height: 48,
        width: 56,
        child: Material(
          color: AppColors.secondary,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: isLeft
                ? BorderRadius.only(
                    topRight: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  )
                : BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
          ),
          child: InkWell(
            onTap: isVisible
                ? () {
                    if (isLeft) {
                      controller.prevPage();
                    } else {
                      controller.nextPage();
                    }
                  }
                : null,
            child: Container(
              alignment: Alignment.center,
              child: Icon(
                iconData,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JudgementController {
  static const double VIEWPORT_FRACTION = 0.945;

  final PageController pageController = PageController(viewportFraction: VIEWPORT_FRACTION);
  final StreamController<int> _pageChanges = StreamController.broadcast();

  PlayerResponse _currentPlayerResponse;

  PlayerResponse get currentPlayerResponse => _currentPlayerResponse;

  int _index = 0;
  int totalPageCount = 0;

  JudgementController() {
    _pageChanges.onListen = () => _pageChanges.add(_index);
  }

  void dispose() {
    pageController.dispose();
    _pageChanges.close();
  }

  void setCurrentResponse(PlayerResponse playerResponse, int index, int count) {
    _currentPlayerResponse = playerResponse;
    _index = index;
    totalPageCount = count;
    _pageChanges.add(_index);
  }

  void nextPage() {
    if (_index < totalPageCount - 1) {
      pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void prevPage() {
    if (_index > 0) {
      pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Stream<int> observePageChanges() => _pageChanges.stream;
}
