import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animation_practice/animation/explode/own/explode_particle_controller.dart';
import 'package:image/image.dart' as img;

class ExplodeParticleWidget extends StatefulWidget {
  final Image image;
  final ExplodeParticleController controller;

  ExplodeParticleWidget(this.image, {this.controller});

  @override
  _ExplodeParticleWidgetState createState() => _ExplodeParticleWidgetState();
}

class _ExplodeParticleWidgetState extends State<ExplodeParticleWidget> {
  img.Image image;
  ui.Image uiImage;
  Offset imageContainerPosition;
  final GlobalKey imageContainerKey = GlobalKey();

  /// 从ImageProvider从获取ui.Image
  Future<ui.Image> _getUIImageFromImageProvider(
    ImageProvider provider, {
    ImageConfiguration config = ImageConfiguration.empty,
  }) async {
    Completer<ui.Image> completer = Completer<ui.Image>(); //完成的回调
    ImageStreamListener listener;
    ImageStream stream = provider.resolve(config); //获取图片流
    //监听
    listener = ImageStreamListener((ImageInfo frame, bool sync) {
      final ui.Image image = frame.image;
      completer.complete(image); //完成
      stream.removeListener(listener); //移除监听
    });
    stream.addListener(listener); //添加监听
    return completer.future; //返回
  }

  Future<ByteData> _getImageByteData() async {
    uiImage = await _getUIImageFromImageProvider(widget.image.image);
    return await uiImage.toByteData();
  }

  Future<img.Image> _decodeImage() async {
    ByteData byteData = await _getImageByteData();
    return img.decodeImage(byteData.buffer.asUint8List());
  }

  Color _extractColorFromPosition(Offset position) {
    int pixel32 =
        image.getPixelSafe(position.dx.toInt() + 1, position.dy.toInt());
    int hex = _abgrToArgb(pixel32);
    return Color(hex);
  }

  int _abgrToArgb(int abgrColor) {
    int r = (abgrColor >> 16) & 0xFF;
    int b = abgrColor & 0xFF;
    return (abgrColor & 0xFF00FF00) | (b << 16) | r;
  }

  Future _prepareData() async {
    image = await _decodeImage();
    _collectColors();
    _initParticles();
  }

  List<Color> _collectColors() {
    List colors = List();
    Color color;
    for (int i = 0; i < 64; i++) {
      if (i < 21) {
        color = _extractColorFromPosition(Offset(
            imageContainerPosition.dx + (1 * 0.7),
            imageContainerPosition.dy - 52));
      } else if (i >= 21 && i < 42) {
        color = _extractColorFromPosition(Offset(
            imageContainerPosition.dx + (i * 0.7),
            imageContainerPosition.dy - 60));
      } else {
        color = _extractColorFromPosition(Offset(
            imageContainerPosition.dx + (i * 0.7),
            imageContainerPosition.dy - 68));
      }
      colors.add(color);
    }
    return colors;
  }

  getImageContainerPosition() {
    RenderBox imageContainerRenderBox =
        imageContainerKey.currentContext.findRenderObject();
    imageContainerPosition = imageContainerRenderBox.localToGlobal(Offset.zero);
  }

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(() async {});
  }

  @override
  void deactivate() {
    widget.controller.removeListener(() {});
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: imageContainerKey,
      child: widget.image,
    );
  }

  void _initParticles() {
    
  }
}
