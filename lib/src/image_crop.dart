part of image_crop;

class ImageOptions {
  final int width;
  final int height;

  ImageOptions({this.width, this.height})
      : assert(width != null),
        assert(height != null);

  @override
  int get hashCode => hashValues(width, height);

  @override
  bool operator ==(other) {
    return other is ImageOptions &&
        other.width == width &&
        other.height == height;
  }

  @override
  String toString() {
    return '$runtimeType(width: $width, height: $height)';
  }
}

class ImageCrop {
  static const _channel =
      const MethodChannel('plugins.lykhonis.com/image_crop');

  static Future<bool> requestPermissions() {
    return _channel
        .invokeMethod('requestPermissions')
        .then<bool>((result) => result);
  }

  static Future<ImageOptions> getImageOptions({File file}) async {
    assert(file != null);
    final result =
        await _channel.invokeMethod('getImageOptions', {'path': file.path});
    return ImageOptions(
      width: result['width'],
      height: result['height'],
    );
  }

  static Future<File> cropImage({
    File file,
    Rect area,
    double scale,
    bool portrait
  }) async {
    assert(file != null);
    assert(area != null);
    if(Io.Platform.isAndroid){

      Img.Image image= Img.decodeImage(file.readAsBytesSync());
      image = Img.copyCrop(image, 0,0, image.width, image.height);

      int topOffset = (image.height*area.top).round();
      int bottomOffset = (image.height*area.bottom).round();
      int leftOffset = (image.width*area.left).toInt();
      int delta = image.height - bottomOffset;
      int width =(image.width *area.width).toInt();
      int height = (image.height*area.height).toInt();
      if(portrait){
        image = Img.copyCrop(image, leftOffset, topOffset, width, height);
      }else{
        image = Img.copyCrop(image, height, 0, height, width);
      }
      var directory = await getApplicationDocumentsDirectory();
      var newFile = new File('${directory.path}/cropp${DateTime.now().toString()}.jpg');
      return newFile..writeAsBytesSync(Img.encodeJpg(image));
    }else{
      return _channel.invokeMethod('cropImage', {
        'path': file.path,
        'left': area.left,
        'top': area.top,
        'right': area.right,
        'bottom': area.bottom,
        'scale': scale ?? 1.0,
        'portrait': portrait
      }).then<File>((result) => File(result));
    }
  }

  static Future<File> sampleImage({
    File file,
    int preferredSize,
    int preferredWidth,
    int preferredHeight,
  }) async {
    assert(file != null);
    assert(() {
      if (preferredSize == null &&
          (preferredWidth == null || preferredHeight == null)) {
        throw ArgumentError(
            'Preferred size or both width and height of a resampled image must be specified.');
      }
      return true;
    }());
    final String path = await _channel.invokeMethod('sampleImage', {
      'path': file.path,
      'maximumWidth': preferredSize ?? preferredWidth,
      'maximumHeight': preferredSize ?? preferredHeight,
    });
    return File(path);
  }
}
