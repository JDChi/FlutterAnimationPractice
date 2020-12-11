import 'dart:math';

import 'package:flutter/cupertino.dart';

class Particle extends StatefulWidget {
  final AnimationController animationController;
  final Color color;
  final int id;
  final Offset position;
  final Offset newPosition;

  Particle(
      {Key key,
      this.color,
      @required this.animationController,
      this.id,
      this.position,
      this.newPosition})
      : assert(animationController != null);

  @override
  _ParticleState createState() => _ParticleState();
}

class _ParticleState extends State<Particle> with TickerProviderStateMixin {
  Animation fadingAnimation;
  Animation particleSize;
  Size screenSize;
  Animation translateXAnimation, negateTranslateXAnimation;
  Animation translateYAnimation, negateTranslateYAnimation;
  double lastXOffset, lastYOffset;

  @override
  void initState() {
    Random random = Random();
    fadingAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(widget.animationController);
    particleSize = Tween(begin: 5.0, end: random.nextDouble() * 20)
        .animate(widget.animationController);

    translateXAnimation = Tween(begin: widget.position.dx, end: lastXOffset)
        .animate(widget.animationController);
    translateYAnimation = Tween(begin: widget.position.dy, end: lastYOffset)
        .animate(widget.animationController);

    negateTranslateXAnimation =
        Tween(begin: -1 * widget.position.dx, end: -1 * lastXOffset)
            .animate(widget.animationController);
    negateTranslateYAnimation =
        Tween(begin: -1 * widget.position.dy, end: -1 * lastYOffset)
            .animate(widget.animationController);
    super.initState();
  }

  Widget _particle() {
    return FadeTransition(
      opacity: fadingAnimation,
      child: Container(
        width: particleSize.value > 5 ? particleSize.value : 5,
        height: particleSize.value > 5 ? particleSize.value : 5,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    return Container(
      alignment: FractionalOffset((widget.newPosition.dx / screenSize.width),
          (widget.newPosition.dy / screenSize.height)),
      child: AnimatedBuilder(
        builder: (BuildContext context, Widget child) {
          if (widget.id % 4 == 0) {
            return Transform.translate(
              offset:
                  Offset(translateXAnimation.value, translateYAnimation.value),
              child: _particle(),
            );
          } else if (widget.id % 4 == 1) {
            return Transform.translate(
              offset: Offset(
                  negateTranslateXAnimation.value, translateYAnimation.value),
              child: _particle(),
            );
          } else if (widget.id % 4 == 2) {
            return Transform.translate(
                offset: Offset(
                    translateXAnimation.value, negateTranslateYAnimation.value),
                child: _particle());
          } else {
            return Transform.translate(
                offset: Offset(negateTranslateXAnimation.value,
                    negateTranslateYAnimation.value),
                child: _particle());
          }
        },
        animation: widget.animationController,
      ),
    );
  }
}
