import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:image/image.dart' as img;

const noOfParticles = 64;

class ExplodeView extends StatelessWidget {
  final String imagePath;
  final double imagePosFromLeft;
  final double imagePosFromTop;

  const ExplodeView(
      {this.imagePath, this.imagePosFromLeft, this.imagePosFromTop});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return ExplodeViewBody(
      imagePath: imagePath,
      imagePosFromLeft: imagePosFromLeft,
      imagePosFromTop: imagePosFromTop,
      screenSize: screenSize,
    );
  }
}

class ExplodeViewBody extends StatefulWidget {
  final String imagePath;
  final double imagePosFromLeft;
  final double imagePosFromTop;
  final Size screenSize;

  const ExplodeViewBody(
      {this.imagePath,
      this.imagePosFromLeft,
      this.imagePosFromTop,
      this.screenSize});

  @override
  _ExplodeViewBodyState createState() => _ExplodeViewBodyState();
}

class _ExplodeViewBodyState extends State<ExplodeViewBody>
    with TickerProviderStateMixin {
  GlobalKey currentKey;
  GlobalKey imageKey = GlobalKey();
  GlobalKey paintKey = GlobalKey();

  bool useSnapshot = true;
  bool isImage = true;

  AnimationController imageAnimationController;

  double imageSize = 50.0;
  double distFromLeft = 10.0, distFromTop = 0.0;
  Random random;

  img.Image photo;

  final StreamController<Color> _stateController =
      StreamController<Color>.broadcast();
  final List<Particle> particles = List();

  @override
  void initState() {
    super.initState();
    currentKey = useSnapshot ? paintKey : imageKey;
    random = Random();

    imageAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    imageAnimationController.addListener(() {
      if (imageAnimationController.isCompleted) {
        imageAnimationController.repeat();
      }
    });
  }

  @override
  void dispose() {
    imageAnimationController.dispose();
    super.dispose();
  }

  Future<Color> getPixel(Offset position, double size) async {
    if (photo == null) {
      await (useSnapshot ? loadSnapshotBytes() : loadImageBundleBytes());
    }

    Color newColor = calculatePixel(position, size);
    return newColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isImage
          ? StreamBuilder(
              initialData: Colors.green[500],
              stream: _stateController.stream,
              builder: (context, snapshot) {
                return Stack(
                  children: <Widget>[
                    RepaintBoundary(
                      key: paintKey,
                      child: GestureDetector(
                        onLongPress: () {
                          imageAnimationController.forward();
                          doParticleAnimation();
                        },
                        child: Container(
                            alignment: FractionalOffset(
                                (widget.imagePosFromLeft /
                                    widget.screenSize.width),
                                (widget.imagePosFromTop /
                                    widget.screenSize.height)),
                            child: AnimatedBuilder(
                              builder: (BuildContext context, Widget child) {
                                return Transform.translate(
                                  offset: Offset(
                                      20 *
                                          shake(imageAnimationController.value),
                                      0),
                                  child: Image.asset(widget.imagePath,
                                      key: imageKey,
                                      width: imageSize,
                                      height: imageSize),
                                );
                              },
                              animation: imageAnimationController,
                            )),
                      ),
                    )
                  ],
                );
              },
            )
          : Container(
              child: Stack(
                children: <Widget>[
                  for (Particle particle in particles)
                    particle.startParticleAnimation()
                ],
              ),
            ),
    );
  }

  double shake(double value) =>
      2 * (0.5 - (0.5 - Curves.linear.transform(value)).abs());

  Future<void> loadImageBundleBytes() async {
    ByteData imageBytes = await rootBundle.load(widget.imagePath);
    setImageBytes(imageBytes);
  }

  Future<void> loadSnapshotBytes() async {
    RenderRepaintBoundary boxPaint = paintKey.currentContext.findRenderObject();
    ui.Image capture = await boxPaint.toImage();
    ByteData imageBytes =
        await capture.toByteData(format: ui.ImageByteFormat.png);
    setImageBytes(imageBytes);
    capture.dispose();
  }

  Color calculatePixel(Offset position, double size) {
    double px = position.dx;
    double py = position.dy;

    if (!useSnapshot) {
      double widgetScale = size / photo.width;
      px = (px / widgetScale);
      py = (py / widgetScale);
    }

    int pixel32 = photo.getPixelSafe(px.toInt() + 1, py.toInt());
    int hex = abgrToArgb(pixel32);

    _stateController.add(Color(hex));

    Color returnColor = Color(hex);
    return returnColor;
  }

  /// abgr转成argb
  /// image.dart库里使用KML格式abgr来表示颜色，这里转成常用的argb
  int abgrToArgb(int argbColor) {
    int r = (argbColor >> 16) & 0xFF;
    int b = argbColor & 0xFF;
    return (argbColor & 0xFF00FF00) | (b << 16) | r;
  }

  void setImageBytes(ByteData imageBytes) {
    List<int> values = imageBytes.buffer.asUint8List();
    photo = img.decodeImage(values);
  }

  Future<List<Color>> collectColors(RenderBox box) async {
    Offset imagePosition = box.localToGlobal(Offset.zero);
    double imagePositionOffsetX = imagePosition.dx;
    double imagePositionOffsetY = imagePosition.dy;

    List<Color> colors = List();

    for (int i = 0; i < noOfParticles; i++) {
      if (i < 21) {
        await getPixel(
                Offset(imagePositionOffsetX + (i * 0.7),
                    imagePositionOffsetY - 60),
                box.size.width)
            .then((value) {
          colors.add(value);
        });
      } else if (i >= 21 && i < 42) {
        await getPixel(
                Offset(imagePositionOffsetX + (1 * 0.7),
                    imagePositionOffsetY - 52),
                box.size.width)
            .then((value) {
          colors.add(value);
        });
      } else {
        await getPixel(
                Offset(imagePositionOffsetX + (i * 0.7),
                    imagePositionOffsetY - 68),
                box.size.width)
            .then((value) {
          colors.add(value);
        });
      }
    }

    return colors;
  }

  Future doParticleAnimation() async {
    RenderBox box = imageKey.currentContext.findRenderObject();

    List<Color> colors = await collectColors(box);

    Future.delayed(Duration(milliseconds: 4000)).then((value) {
      addParticles(box, colors);
    });
  }

  void addParticles(RenderBox box, List<Color> colors) {
    Offset imagePosition = box.localToGlobal(Offset.zero);
    double imagePositionOffsetX = imagePosition.dx;
    double imagePositionOffsetY = imagePosition.dy;

    double imageCenterPositionX = imagePositionOffsetX + (imageSize / 2);
    double imageCenterPositionY = imagePositionOffsetY + (imageSize / 2);
    for (int i = 0; i < noOfParticles; i++) {
      if (i < 21) {
        particles.add(Particle(
            id: i,
            screenSize: widget.screenSize,
            colors: colors[i].withOpacity(1.0),
            offsetX:
                (imageCenterPositionX - imagePositionOffsetX + (i * 0.7)) * 0.1,
            offsetY: (imageCenterPositionY - (imagePositionOffsetY - 60)) * 0.1,
            newOffsetX: imagePositionOffsetX + (i * 0.7),
            newOffsetY: imagePositionOffsetY - 60));
      } else if (i >= 21 && i < 42) {
        particles.add(Particle(
            id: i,
            screenSize: widget.screenSize,
            colors: colors[i].withOpacity(1.0),
            offsetX:
                (imageCenterPositionX - imagePositionOffsetX + (i * 0.5)) * 0.1,
            offsetY: (imageCenterPositionY - (imagePositionOffsetY - 52)) * 0.1,
            newOffsetX: imagePositionOffsetX + (i * 0.7),
            newOffsetY: imagePositionOffsetY - 52));
      } else {
        particles.add(Particle(
            id: i,
            screenSize: widget.screenSize,
            colors: colors[i].withOpacity(1.0),
            offsetX:
                (imageCenterPositionX - imagePositionOffsetX + (i * 0.9)) * 0.1,
            offsetY: (imageCenterPositionY - (imagePositionOffsetY - 68)) * 0.1,
            newOffsetX: imagePositionOffsetX + (i * 0.7),
            newOffsetY: imagePositionOffsetY - 68));
      }
    }
    setState(() {
      isImage = false;
    });
  }
}

class Particle extends _ExplodeViewBodyState {
  int id;
  Size screenSize;
  Color colors;
  double offsetX = 0.0, offsetY = 0.0;
  double newOffsetX = 0.0, newOffsetY = 0.0;

  Offset position;
  Paint singleParticle;

  static final randomValue = Random();
  AnimationController animationController;

  Animation translateXAnimation, negateTranslateXAnimation;
  Animation translateYAnimation, negateTranslateYAnimation;

  Animation fadingAnimation;
  Animation particleSize;

  double lastXOffset, lastYOffset;

  /// 粒子
  Particle(
      {@required this.id,
      @required this.screenSize,
      this.colors,
      this.offsetX,
      this.offsetY,
      this.newOffsetX,
      this.newOffsetY}) {
    position = Offset(this.offsetX, this.offsetY);

    Random random = Random();
    this.lastXOffset = random.nextDouble() * 100;
    this.lastYOffset = random.nextDouble() * 100;

    animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1500));

    translateXAnimation = Tween(begin: position.dx, end: lastXOffset)
        .animate(animationController);
    translateYAnimation = Tween(begin: position.dy, end: lastYOffset)
        .animate(animationController);

    negateTranslateXAnimation =
        Tween(begin: -1 * position.dx, end: -1 * lastXOffset)
            .animate(animationController);
    negateTranslateYAnimation =
        Tween(begin: -1 * position.dy, end: -1 * lastYOffset)
            .animate(animationController);

    fadingAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(animationController);

    particleSize = Tween(begin: 5.0, end: random.nextDouble() * 20)
        .animate(animationController);
  }

  Widget startParticleAnimation() {
    animationController.forward();

    return Container(
      alignment: FractionalOffset(
          (newOffsetX / screenSize.width), (newOffsetY / screenSize.height)),
      child: AnimatedBuilder(
        builder: (BuildContext context, Widget child) {
          if (id % 4 == 0) {
            return Transform.translate(
              offset:
                  Offset(translateXAnimation.value, translateYAnimation.value),
              child: FadeTransition(
                opacity: fadingAnimation,
                child: Container(
                  width: particleSize.value > 5 ? particleSize.value : 5,
                  height: particleSize.value > 5 ? particleSize.value : 5,
                  decoration:
                      BoxDecoration(color: colors, shape: BoxShape.circle),
                ),
              ),
            );
          } else if (id % 4 == 1) {
            return Transform.translate(
              offset: Offset(
                  negateTranslateXAnimation.value, translateYAnimation.value),
              child: FadeTransition(
                opacity: fadingAnimation,
                child: Container(
                  width: particleSize.value > 5 ? particleSize.value : 5,
                  height: particleSize.value > 5 ? particleSize.value : 5,
                  decoration:
                      BoxDecoration(color: colors, shape: BoxShape.circle),
                ),
              ),
            );
          } else if (id % 4 == 2) {
            return Transform.translate(
                offset: Offset(
                    translateXAnimation.value, negateTranslateYAnimation.value),
                child: FadeTransition(
                  opacity: fadingAnimation,
                  child: Container(
                    width: particleSize.value > 5 ? particleSize.value : 5,
                    height: particleSize.value > 5 ? particleSize.value : 5,
                    decoration:
                        BoxDecoration(color: colors, shape: BoxShape.circle),
                  ),
                ));
          } else {
            return Transform.translate(
                offset: Offset(negateTranslateXAnimation.value,
                    negateTranslateYAnimation.value),
                child: FadeTransition(
                  opacity: fadingAnimation,
                  child: Container(
                    width: particleSize.value > 5 ? particleSize.value : 5,
                    height: particleSize.value > 5 ? particleSize.value : 5,
                    decoration:
                        BoxDecoration(color: colors, shape: BoxShape.circle),
                  ),
                ));
          }
        },
        animation: animationController,
      ),
    );
  }
}
