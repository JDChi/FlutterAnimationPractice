import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ExplodeParticleWidget extends StatefulWidget {
  final Image image;

  ExplodeParticleWidget(this.image);

  @override
  _ExplodeParticleWidgetState createState() => _ExplodeParticleWidgetState();
}

class _ExplodeParticleWidgetState extends State<ExplodeParticleWidget> {
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
    ui.Image image = await _getUIImageFromImageProvider(widget.image.image);
    return await image.toByteData();
  }

  Future<img.Image> decodeImage() async {
    ByteData byteData = await _getImageByteData();
    return img.decodeImage(byteData.buffer.asUint8List());
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.image,
    );
  }
}
