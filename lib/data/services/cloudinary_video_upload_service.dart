import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

typedef VideoUploadProgressCallback =
    void Function(int sentBytes, int totalBytes);

class CloudinaryVideoUploadService {
  CloudinaryVideoUploadService({
    Dio? dio,
    String cloudName = _defaultCloudName,
    String uploadPreset = _defaultUploadPreset,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: 'https://api.cloudinary.com/v1_1/$cloudName',
               connectTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(minutes: 10),
               receiveTimeout: const Duration(seconds: 45),
               responseType: ResponseType.json,
             ),
           ),
       _uploadPreset = uploadPreset;

  static const String _defaultCloudName = 'dt10vnoqb';
  static const String _defaultUploadPreset = 'edu_course_upload';

  static final CloudinaryVideoUploadService instance =
      CloudinaryVideoUploadService();

  final Dio _dio;
  final String _uploadPreset;

  Future<String> uploadVideo(
    File file, {
    VideoUploadProgressCallback? onProgress,
  }) async {
    final filePath = file.path.trim();
    if (filePath.isEmpty) {
      throw const CloudinaryVideoUploadException(
        'Selected video file is missing a valid path.',
      );
    }
    if (!await file.exists()) {
      throw const CloudinaryVideoUploadException(
        'Selected video file could not be found on this device.',
      );
    }
    if (await file.length() <= 0) {
      throw const CloudinaryVideoUploadException(
        'Selected video file is empty and cannot be uploaded.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/video/upload',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(
            filePath,
            filename: p.basename(filePath),
          ),
          'upload_preset': _uploadPreset,
          'resource_type': 'video',
        }),
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onProgress,
      );

      final secureUrl = (response.data?['secure_url'] ?? '').toString().trim();
      if (secureUrl.isEmpty || !_isHttpsUrl(secureUrl)) {
        throw const CloudinaryVideoUploadException(
          'Cloudinary did not return a secure video URL.',
        );
      }
      return secureUrl;
    } on DioException catch (error) {
      throw CloudinaryVideoUploadException(_dioErrorMessage(error));
    } on FileSystemException {
      throw const CloudinaryVideoUploadException(
        'The selected video file could not be read during upload.',
      );
    }
  }

  bool _isHttpsUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme.toLowerCase() == 'https';
  }

  String _dioErrorMessage(DioException error) {
    final responseMessage = _cloudinaryErrorMessage(error.response?.data);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Video upload timed out. Please try again on a stronger connection.';
      case DioExceptionType.badResponse:
        if (responseMessage != null) {
          return 'Cloudinary upload failed: $responseMessage';
        }
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          return 'Cloudinary upload failed with status $statusCode.';
        }
        return 'Cloudinary upload failed. Please try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach Cloudinary. Check your internet connection and try again.';
      case DioExceptionType.cancel:
        return 'Video upload was cancelled before completion.';
      case DioExceptionType.badCertificate:
        return 'A secure connection to Cloudinary could not be established.';
      case DioExceptionType.unknown:
        if (responseMessage != null) {
          return responseMessage;
        }
        final message = error.message?.trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
        return 'Video upload failed unexpectedly. Please try again.';
    }
  }

  String? _cloudinaryErrorMessage(Object? data) {
    if (data is Map) {
      final map = Map<Object?, Object?>.from(data);
      final nestedError = map['error'];
      if (nestedError is Map) {
        final nestedMap = Map<Object?, Object?>.from(nestedError);
        final nestedMessage = nestedMap['message']?.toString().trim();
        if (nestedMessage != null && nestedMessage.isNotEmpty) {
          return nestedMessage;
        }
      }
      final message = map['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }
}

class CloudinaryVideoUploadException implements Exception {
  const CloudinaryVideoUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
