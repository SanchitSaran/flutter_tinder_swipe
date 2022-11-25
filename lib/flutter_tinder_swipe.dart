library flutter_tinder_swipe;

import 'package:flutter/material.dart';
import 'dart:math';

///making enum for button click funcion just like triggering event
enum SwipeDirection { none, right, left }

List<Size> swipeSize = [];
List<Alignment> swipeAligns = [];

// ignore: must_be_immutable
class SwipeCard extends StatefulWidget {
  CardBuilder _cardBuilder;
  int _totalNum;
  int _stackNum;
  int _animDuration;
  double _swipeEdge;
  bool _allowVerticalMovement;
  CardSwipeCompleteCallback swipeCompleteCallback;
  CardDragUpdateCallback swipeUpdateCallback;
  CardController cardController;
  Function swipeLeft;
  Function swipeRight;

  @override
  _SwipeCardState createState() => _SwipeCardState();

  /// Constructor requires Card Widget Builder [cardBuilder] & your card count [totalNum]
  /// , option includes: stack orientation [orientation], number of card display in same time [stackNum]
  /// , [swipeEdge] is the edge to determine action(recover or swipe) when you release your swiping card
  /// it is the value of alignment, 0.0 means middle, so it need bigger than zero.
  /// , and size control params;

  SwipeCard({required CardBuilder cardBuilder, required int totalNum, AmassOrientation orientation = AmassOrientation.LEFT, int stackNum = 3, int animDuration = 800, double swipeEdge = 3.0, double swipeEdgeVertical = 8.0, double? maxWidth, double? maxHeight, double? minWidth, double? minHeight, bool allowVerticalMovement = true, required this.cardController, required this.swipeCompleteCallback, required this.swipeUpdateCallback, required this.swipeLeft, required this.swipeRight})
      : this._cardBuilder = cardBuilder,
        this._totalNum = totalNum,
        assert(stackNum > 1),
        this._stackNum = stackNum,
        this._animDuration = animDuration,
        assert(swipeEdge > 0),
        this._swipeEdge = swipeEdge,
        assert(swipeEdgeVertical > 0),
        assert(maxWidth! > minWidth! && maxHeight! > minHeight!),
        this._allowVerticalMovement = allowVerticalMovement {
    double widthGap = maxWidth! - minWidth!;
    double heightGap = maxHeight! - minHeight!;

    swipeAligns = [];
    swipeSize = [];

    for (int i = 0; i < _stackNum; i++) {
      swipeSize.add(new Size(minWidth + (widthGap / _stackNum) * i, minHeight + (heightGap / _stackNum) * i));

      switch (orientation) {
        case AmassOrientation.LEFT:
          if (_stackNum == 1) {
            swipeAligns.add(new Alignment(-0.5 * (stackNum - i), 0.0));
          } else {
            swipeAligns.add(new Alignment((-0.5 / _stackNum - 1) * (stackNum - i), 0.0));
          }
          break;
        case AmassOrientation.RIGHT:
          if (_stackNum == 1) {
            swipeAligns.add(new Alignment(-0.5 * (stackNum - i), 0.0));
          } else {
            swipeAligns.add(new Alignment((0.5 / _stackNum - 1) * (stackNum - i), 0.0));
          }
          break;
      }
    }
  }
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late Alignment frontAlign;

  ///alignment
  late AnimationController _animationController;

  ///animation controller
  late int _currentFront;
  static SwipeDirection? swipeable;

  Widget _buildCard(BuildContext context, int realIndex) {
    if (realIndex < 0) {
      return Container();
    }
    int index = realIndex - _currentFront;

    if (index == widget._stackNum - 1) {
      return Align(
        alignment: _animationController.status == AnimationStatus.forward
            ? frontAlign = CardAnimation.frontAlign(
                _animationController,
                frontAlign,
                swipeAligns[widget._stackNum - 1],
                widget._swipeEdge,
              ).value
            : frontAlign,
        child: Transform.rotate(
            angle: (pi / 180.0) * (_animationController.status == AnimationStatus.forward ? CardAnimation.frontRotation(_animationController, frontAlign.x).value : frontAlign.x),
            child: new SizedBox.fromSize(
              size: swipeSize[index],
              child: widget._cardBuilder(context, widget._totalNum - realIndex - 1),
            )),
      );
    }

    ///align
    return Align(
      alignment: _animationController.status == AnimationStatus.forward && (frontAlign.x > 3.0 || frontAlign.x < -3.0 || frontAlign.y > 3 || frontAlign.y < -3) ? CardAnimation.backAlign(_animationController, swipeAligns[index], swipeAligns[index + 1]).value : swipeAligns[index],
      child: new SizedBox.fromSize(
        size: _animationController.status == AnimationStatus.forward && (frontAlign.x > 3.0 || frontAlign.x < -3.0 || frontAlign.y > 3 || frontAlign.y < -3) ? CardAnimation.backSize(_animationController, swipeSize[index], swipeSize[index + 1]).value : swipeSize[index],
        child: widget._cardBuilder(context, widget._totalNum - realIndex - 1),
      ),
    );
  }

  ///builder swipe card
  List<Widget> _buildCards(BuildContext context) {
    List<Widget> cards = [];
    for (int i = _currentFront; i < _currentFront + widget._stackNum; i++) {
      cards.add(_buildCard(context, i));
    }

    cards.add(new SizedBox.expand(
      child: new GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            if (widget._allowVerticalMovement == true) {
              frontAlign = new Alignment(frontAlign.x + details.delta.dx * 20 / MediaQuery.of(context).size.width, frontAlign.y + details.delta.dy * 30 / MediaQuery.of(context).size.height);
            } else {
              frontAlign = new Alignment(frontAlign.x + details.delta.dx * 20 / MediaQuery.of(context).size.width, 0);

              widget.swipeUpdateCallback(details, frontAlign);
            }

            widget.swipeUpdateCallback(details, frontAlign);
          });
        },
        onPanEnd: (DragEndDetails details) {
          animateCards(SwipeDirection.none);
        },
      ),
    ));
    return cards;
  }

  ///animation for swipe cards and here we initializing our swipeable
  animateCards(SwipeDirection swipes) {
    if (_animationController.isAnimating || _currentFront + widget._stackNum == 0) {
      return;
    }
    swipeable = swipes;
    _animationController.stop();
    _animationController.value = 0.0;
    _animationController.forward();
  }

  void swipesSwap(SwipeDirection swipes) {
    animateCards(swipes);
  }

  /// support for asynchronous data events
  @override
  void didUpdateWidget(covariant SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._totalNum != oldWidget._totalNum) {
      getInitialize();
    }
  }

  ///disposing controller
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getInitialize();
  }

  ///here we initialize some and giving value to some
  void getInitialize() {
    _currentFront = widget._totalNum - widget._stackNum;

    frontAlign = swipeAligns[swipeAligns.length - 1];
    _animationController = new AnimationController(vsync: this, duration: Duration(milliseconds: widget._animDuration));
    _animationController.addListener(() => setState(() {}));
    _animationController.addStatusListener((AnimationStatus status) {
      int index = widget._totalNum - widget._stackNum - _currentFront;
      if (status == AnimationStatus.completed) {
        CardSwipeOrientation orientation;
        if (frontAlign.x < -widget._swipeEdge) {
          orientation = CardSwipeOrientation.LEFT;
          widget.swipeLeft();
        } else if (frontAlign.x > widget._swipeEdge) {
          orientation = CardSwipeOrientation.RIGHT;
          widget.swipeRight();
        } else {
          frontAlign = swipeAligns[widget._stackNum - 1];
          orientation = CardSwipeOrientation.RECOVER;
        }
        widget.swipeCompleteCallback(orientation, index);
        if (orientation != CardSwipeOrientation.RECOVER) changeCardOrder();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.cardController.addListener((swipes) => swipesSwap(swipes));

    return Stack(children: _buildCards(context));
  }

  ///change ordering of card
  changeCardOrder() {
    setState(() {
      _currentFront--;
      frontAlign = swipeAligns[widget._stackNum - 1];
    });
  }
}

typedef Widget CardBuilder(BuildContext context, int index);

///card swipe enum declare for orientaion left and right
enum CardSwipeOrientation { LEFT, RIGHT, RECOVER }

/// swipe card to [CardSwipeOrientation.LEFT] or [CardSwipeOrientation.RIGHT]
/// , [CardSwipeOrientation.RECOVER] means back to start.
typedef CardSwipeCompleteCallback = void Function(CardSwipeOrientation orientation, int index);

/// [DragUpdateDetails] of swiping card.
typedef CardDragUpdateCallback = void Function(DragUpdateDetails details, Alignment align);

///declaring enum for action performing
enum AmassOrientation { LEFT, RIGHT }

class CardAnimation {
  static Animation<Alignment> frontAlign(
    AnimationController controller,
    Alignment beginAlign,
    Alignment baseAlign,
    double swipeEdge,
  ) {
    double endX, endY;

    ///condition for swipe none ,left,right
    if (_SwipeCardState.swipeable == SwipeDirection.none) {
      endX = beginAlign.x > 0 ? (beginAlign.x > swipeEdge ? beginAlign.x + 10.0 : baseAlign.x) : (beginAlign.x < -swipeEdge ? beginAlign.x - 10.0 : baseAlign.x);
      endY = beginAlign.x > 3.0 || beginAlign.x < -swipeEdge ? beginAlign.y : baseAlign.y;
    } else if (_SwipeCardState.swipeable == SwipeDirection.left) {
      endX = beginAlign.x - swipeEdge;
      endY = beginAlign.y + 0.5;
    } else {
      endX = beginAlign.x + swipeEdge;
      endY = beginAlign.y + 0.5;
    }

    ///applying tween animation
    return new AlignmentTween(begin: beginAlign, end: new Alignment(endX, endY)).animate(new CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  ///card animation front
  static Animation<double> frontRotation(AnimationController controller, double beginRot) {
    return new Tween(begin: beginRot, end: 0.0).animate(new CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  ///Card animation Size
  static Animation backSize(AnimationController controller, Size beginSize, Size endSize) {
    return new SizeTween(begin: beginSize, end: endSize).animate(new CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  ///Card aniamtion Align
  static Animation<Alignment> backAlign(AnimationController controller, Alignment beginAlign, Alignment endAlign) {
    return new AlignmentTween(begin: beginAlign, end: endAlign).animate(new CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }
}

///swipe listen
typedef SwipeListen = void Function(SwipeDirection swipes);

///making class called as Card Controller
class CardController {
  SwipeListen? _listener;

  ///for action performed by clicking tap for left swipe
  void swipeLeft() {
    if (_listener != null) {
      _listener!(SwipeDirection.left);
    }
  }

  ///for action performed by clicking tap for right swipe
  void swipeRight() {
    if (_listener != null) {
      _listener!(SwipeDirection.right);
    }
  }

  ///adding listener to listen
  void addListener(listener) {
    _listener = listener;
  }
}
