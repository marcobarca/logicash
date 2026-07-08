import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String changelog;
  final String downloadUrl;
  const UpdateInfo({
    required this.version,
    required this.changelog,
    required this.downloadUrl,
  });
}

class UpdateService {
  static const _owner = 'marcobarca';
  static const _repo = 'logicash';
  static const _apiBase = 'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;

      final dio = Dio();
      final res = await dio.get<Map<String, dynamic>>(
        _apiBase,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.statusCode != 200 || res.data == null) return null;
      final data = res.data!;

      final tag = (data['tag_name'] as String? ?? '').trim();
      final latest = tag.startsWith('v') ? tag.substring(1) : tag;
      if (latest.isEmpty || !_isNewer(latest, current)) return null;

      final assets = (data['assets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final apk = assets.where((a) => (a['name'] as String).endsWith('.apk')).firstOrNull;
      if (apk == null) return null;

      return UpdateInfo(
        version: latest,
        changelog: data['body'] as String? ?? '',
        downloadUrl: apk['browser_download_url'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> downloadApk(
    String url,
    void Function(double progress) onProgress,
  ) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/logicash_update.apk';
    final dio = Dio();
    await dio.download(
      url,
      path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );
    return path;
  }

  static bool _isNewer(String latest, String current) {
    List<int> parse(String v) =>
        v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final l = parse(latest);
    final c = parse(current);
    for (int i = 0; i < 3; i++) {
      final li = i < l.length ? l[i] : 0;
      final ci = i < c.length ? c[i] : 0;
      if (li > ci) return true;
      if (li < ci) return false;
    }
    return false;
  }
}
