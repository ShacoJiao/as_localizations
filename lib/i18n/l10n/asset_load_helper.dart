import 'package:flutter/services.dart' show rootBundle;
// import 'package:path_provider/path_provider.dart';

abstract class AssetLoadHelper {
  static Future<String> _initialLoadAsset(String fileName, [bool formSupport = false]) async {
    // TODO 读取缓存
    // try {
    //   final packageInfo = await PackageInfo.fromPlatform();
    //   final directory = '${packageInfo.version}+${packageInfo.buildNumber}';
    //   final support = await getApplicationSupportDirectory();
    //   final targetDir = Directory('${support.path}/$directory');
    //   if (!await targetDir.exists()) {
    //     throw Exception('目录不存在，已创建新目录');
    //   }
    //   final file = File('${targetDir.path}/$fileName');
    //   if (!await file.exists()) {
    //     throw Exception('文件不存在: $fileName');
    //   }
    //
    //   return await file.readAsString();
    // } catch (_) {}
    final assetKey = 'assets/translations/$fileName';
    return rootBundle.loadString(assetKey);
  }

  static Future<String> Function(String fileName, [bool formSupport]) loadAssetFun = _initialLoadAsset;

  static Future<String> loadAsset(String fileName, [bool formSupport = false]) {
    return loadAssetFun(fileName);
  }

  static void resetLoadAsset() {
    loadAssetFun = _initialLoadAsset;
  }
}
