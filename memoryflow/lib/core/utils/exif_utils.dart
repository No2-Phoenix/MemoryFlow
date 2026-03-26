import 'dart:convert';
import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ExifUtils {
  static const MethodChannel _exifChannel = MethodChannel('memoryflow/exif');

  static Future<Map<String, dynamic>> extractExif(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File does not exist', filePath);
      }

      final tags = await readExifFromBytes(await file.readAsBytes());
      if (tags.isEmpty) {
        return {'error': 'No EXIF data found'};
      }

      final result = <String, dynamic>{};

      _putTag(result, 'Make', _tagValue(tags, const ['Image Make']));
      _putTag(result, 'Model', _tagValue(tags, const ['Image Model']));
      _putTag(result, 'DateTime', _tagValue(tags, const ['Image DateTime']));
      _putTag(
        result,
        'DateTimeOriginal',
        _tagValue(tags, const ['EXIF DateTimeOriginal']),
      );
      _putTag(
        result,
        'GPSLatitudeRef',
        _tagValue(tags, const ['GPS GPSLatitudeRef']),
      );
      _putTag(
        result,
        'GPSLongitudeRef',
        _tagValue(tags, const ['GPS GPSLongitudeRef']),
      );
      _putTag(
        result,
        'GPSAreaInformation',
        _tagValue(tags, const ['GPS GPSAreaInformation']),
      );
      _putTag(
        result,
        'ImageDescription',
        _tagValue(tags, const ['Image ImageDescription']),
      );
      _putTag(
        result,
        'UserComment',
        _tagValue(tags, const ['EXIF UserComment']),
      );
      _putTag(
        result,
        'XPComment',
        _tagValue(tags, const ['Image XPComment', 'EXIF XPComment']),
      );
      _putTag(
        result,
        'XPSubject',
        _tagValue(tags, const ['Image XPSubject', 'EXIF XPSubject']),
      );
      _putTag(
        result,
        'XPTitle',
        _tagValue(tags, const ['Image XPTitle', 'EXIF XPTitle']),
      );

      final latitude = _parseGpsCoordinate(
        _tagValue(tags, const ['GPS GPSLatitude']),
      );
      final longitude = _parseGpsCoordinate(
        _tagValue(tags, const ['GPS GPSLongitude']),
      );

      if (latitude != null) {
        result['GPSLatitude'] = latitude;
      }
      if (longitude != null) {
        result['GPSLongitude'] = longitude;
      }

      return result;
    } catch (error) {
      return {'error': 'Failed to extract EXIF: $error'};
    }
  }

  static Future<DateTime?> getPhotoDate(String filePath) async {
    try {
      final exifData = await extractExif(filePath);
      final original = exifData['DateTimeOriginal'] as String?;
      final captured = exifData['DateTime'] as String?;
      final parsed = _parseDateTime(original) ?? _parseDateTime(captured);
      if (parsed != null) {
        return parsed;
      }

      final file = File(filePath);
      if (await file.exists()) {
        return await file.lastModified();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<String?> getCameraModel(String filePath) async {
    try {
      final exifData = await extractExif(filePath);
      final make = _normalizeText(exifData['Make'] as String?);
      final model = _normalizeText(exifData['Model'] as String?);

      if (make != null && model != null) {
        if (model.toLowerCase().startsWith(make.toLowerCase())) {
          return model;
        }
        return '$make $model';
      }

      return model ?? make;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, double>?> getGpsCoordinates(String filePath) async {
    try {
      final exifData = await extractExif(filePath);
      final latitude = exifData['GPSLatitude'] as double?;
      final longitude = exifData['GPSLongitude'] as double?;

      if (latitude == null || longitude == null) {
        return await _readGpsFromPlatform(filePath);
      }

      final latitudeRef = (exifData['GPSLatitudeRef'] as String?)
          ?.trim()
          .toUpperCase();
      final longitudeRef = (exifData['GPSLongitudeRef'] as String?)
          ?.trim()
          .toUpperCase();

      var normalizedLatitude = latitude;
      var normalizedLongitude = longitude;

      if (latitudeRef == 'S') {
        normalizedLatitude = -normalizedLatitude;
      }
      if (longitudeRef == 'W') {
        normalizedLongitude = -normalizedLongitude;
      }
      if (normalizedLatitude.abs() < 0.000001 &&
          normalizedLongitude.abs() < 0.000001) {
        return await _readGpsFromPlatform(filePath);
      }

      return {'latitude': normalizedLatitude, 'longitude': normalizedLongitude};
    } catch (_) {
      return await _readGpsFromPlatform(filePath);
    }
  }

  static Future<String?> getPhotoLocationName(String filePath) async {
    try {
      final exifData = await extractExif(filePath);
      final exifLocation = _extractLocationNameFromExif(exifData);
      if (exifLocation != null) {
        return exifLocation;
      }

      final locationFromPlatform = await _readLocationNameFromPlatform(
        filePath,
      );
      if (locationFromPlatform != null) {
        return locationFromPlatform;
      }

      final gps = await getGpsCoordinates(filePath);
      final latitude = gps?['latitude'];
      final longitude = gps?['longitude'];
      if (latitude == null || longitude == null) {
        return null;
      }
      return await _reverseGeocode(latitude: latitude, longitude: longitude);
    } catch (_) {
      return null;
    }
  }

  static Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    try {
      await _ensurePhotoMetadataPermissions();
    } catch (error, stackTrace) {
      debugPrint('Photo permission request failed, fallback to picker: $error');
      debugPrint('$stackTrace');
    }

    try {
      return await picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: true,
      );
    } catch (error, stackTrace) {
      debugPrint('Image picker failed: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  static Future<List<XFile>?> pickMultipleImages() async {
    final picker = ImagePicker();
    try {
      await _ensurePhotoMetadataPermissions();
    } catch (error, stackTrace) {
      debugPrint(
        'Photo permissions request failed for multi-picker, fallback: $error',
      );
      debugPrint('$stackTrace');
    }

    try {
      return await picker.pickMultiImage(requestFullMetadata: true);
    } catch (error, stackTrace) {
      debugPrint('Multiple image picker failed: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  static void _putTag(Map<String, dynamic> result, String key, String? value) {
    final normalized = _normalizeText(value);
    if (normalized != null) {
      result[key] = normalized;
    }
  }

  static String? _tagValue(Map<String, IfdTag> tags, List<String> keys) {
    for (final key in keys) {
      final value = _normalizeText(tags[key]?.printable);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static String? _normalizeText(String? value) {
    final normalized = value?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        normalized == '[]' ||
        normalized == 'null') {
      return null;
    }
    return normalized;
  }

  static DateTime? _parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) {
      return null;
    }

    try {
      final parts = dateTimeStr.split(' ');
      if (parts.length != 2) {
        return null;
      }

      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');
      if (dateParts.length != 3 || timeParts.length != 3) {
        return null;
      }

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  static double? _parseGpsCoordinate(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    final direct = _parseExifNumber(rawValue);
    if (direct != null) {
      return direct;
    }

    final cleaned = rawValue
        .replaceAll('°', ' ')
        .replaceAll("'", ' ')
        .replaceAll('"', ' ')
        .replaceAll(';', ',')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('deg', ' ')
        .trim();
    final parts = cleaned
        .split(RegExp(r'[, ]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return null;
    }
    if (parts.length == 1) {
      return _parseExifNumber(parts[0]);
    }
    if (parts.length == 2) {
      final degrees = _parseExifNumber(parts[0]);
      final minutes = _parseExifNumber(parts[1]);
      if (degrees == null || minutes == null) {
        return null;
      }
      return degrees + minutes / 60;
    }

    final degrees = _parseExifNumber(parts[0]);
    final minutes = _parseExifNumber(parts[1]);
    final seconds = _parseExifNumber(parts[2]);
    if (degrees == null || minutes == null || seconds == null) {
      return null;
    }

    return degrees + minutes / 60 + seconds / 3600;
  }

  static double? _parseExifNumber(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.contains('/')) {
      final parts = normalized.split('/');
      if (parts.length != 2) {
        return null;
      }
      final numerator = double.tryParse(parts[0]);
      final denominator = double.tryParse(parts[1]);
      if (numerator == null || denominator == null || denominator == 0) {
        return null;
      }
      return numerator / denominator;
    }

    return double.tryParse(normalized);
  }

  static String? _extractLocationNameFromExif(Map<String, dynamic> exifData) {
    final candidates = <String?>[
      exifData['GPSAreaInformation'] as String?,
      exifData['ImageDescription'] as String?,
      exifData['UserComment'] as String?,
      exifData['XPComment'] as String?,
      exifData['XPSubject'] as String?,
      exifData['XPTitle'] as String?,
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeLocationLabel(candidate);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  static String? _normalizeLocationLabel(String? value) {
    final normalized = _normalizeText(value);
    if (normalized == null) {
      return null;
    }

    final compact = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length < 2) {
      return null;
    }
    if (RegExp(r'^[-+0-9.,/ ]+$').hasMatch(compact)) {
      return null;
    }
    if (compact.toLowerCase().contains('dcim')) {
      return null;
    }
    if (_looksLikeCameraDebugMetadata(compact)) {
      return null;
    }
    return compact;
  }

  static bool _looksLikeCameraDebugMetadata(String value) {
    final lower = value.toLowerCase();
    final keywordPattern = RegExp(
      r'(fileterintensity|filtermask|captureorientation|algolist|multi-frame|'
      r'brp_mask|brp_del|scenemode|aec_lux|module:|module=|bokeh|'
      r'weatherinfo|motionlevel|zeisscolor|ai_scene|touch:|cct_value|'
      r'runfunc|hw-remosaic|filter:)',
    );
    if (keywordPattern.hasMatch(lower)) {
      return true;
    }

    final semicolons = ';'.allMatches(lower).length;
    final colons = ':'.allMatches(lower).length;
    final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(lower);
    final hasAsciiLetters = RegExp(r'[a-z]').hasMatch(lower);

    if (semicolons >= 4 && colons >= 4 && hasAsciiLetters && !hasChinese) {
      return true;
    }

    if (lower.length > 96 && semicolons >= 2 && lower.contains('=')) {
      return true;
    }

    return false;
  }

  static Future<String?> _reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    if (kIsWeb) {
      return null;
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': latitude.toStringAsFixed(7),
        'lon': longitude.toStringAsFixed(7),
        'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8',
      });
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'MemoryFlow/1.0 (mobile-photo-story)');

      final response = await request.close().timeout(
        const Duration(seconds: 4),
      );
      if (response.statusCode != 200) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final payload = jsonDecode(body);
      if (payload is! Map<String, dynamic>) {
        return null;
      }

      final address = payload['address'];
      if (address is Map<String, dynamic>) {
        final level1 =
            _normalizeText(address['city'] as String?) ??
            _normalizeText(address['town'] as String?) ??
            _normalizeText(address['village'] as String?) ??
            _normalizeText(address['county'] as String?);
        final level2 =
            _normalizeText(address['suburb'] as String?) ??
            _normalizeText(address['neighbourhood'] as String?) ??
            _normalizeText(address['district'] as String?);
        final road =
            _normalizeText(address['road'] as String?) ??
            _normalizeText(address['pedestrian'] as String?) ??
            _normalizeText(address['hamlet'] as String?);
        final segments = [
          level1,
          level2,
          road,
        ].whereType<String>().where((item) => item.trim().isNotEmpty).toList();
        if (segments.isNotEmpty) {
          return segments.join(' · ');
        }
      }

      final displayName = _normalizeLocationLabel(
        payload['display_name'] as String?,
      );
      if (displayName == null) {
        return null;
      }
      final parts = displayName
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      if (parts.isEmpty) {
        return null;
      }
      return parts.take(3).join(' · ');
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _ensurePhotoMetadataPermissions() async {
    if (kIsWeb) {
      return;
    }
    if (Platform.isAndroid) {
      await Permission.photos.request();
      await Permission.storage.request();
      await Permission.accessMediaLocation.request();
      return;
    }
    if (Platform.isIOS) {
      await Permission.photos.request();
    }
  }

  static Future<Map<String, double>?> _readGpsFromPlatform(
    String filePath,
  ) async {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }

    try {
      final raw = await _exifChannel.invokeMethod<dynamic>('readGpsFromPath', {
        'path': filePath,
      });
      if (raw is! Map) {
        return null;
      }
      final latitude = _asDouble(raw['latitude']);
      final longitude = _asDouble(raw['longitude']);
      if (latitude == null || longitude == null) {
        return null;
      }
      if (latitude.abs() < 0.000001 && longitude.abs() < 0.000001) {
        return null;
      }
      return {'latitude': latitude, 'longitude': longitude};
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _readLocationNameFromPlatform(String filePath) async {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }

    try {
      final raw = await _exifChannel.invokeMethod<String>(
        'readLocationNameFromPath',
        {'path': filePath},
      );
      return _normalizeLocationLabel(raw);
    } catch (_) {
      return null;
    }
  }

  static double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
