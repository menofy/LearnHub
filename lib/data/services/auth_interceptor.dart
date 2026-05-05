import 'package:http/http.dart' as http;

import '../../core/auth_constants.dart';
import 'auth_exceptions.dart';

/// HTTP Interceptor for adding auth tokens and handling auth errors
class AuthInterceptor extends http.BaseClient {
  final http.Client _inner;
  final String? Function() getToken;
  final Future<bool> Function() refreshToken;

  AuthInterceptor({
    required http.Client inner,
    required this.getToken,
    required this.refreshToken,
  }) : _inner = inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add auth token to request headers
    final token = getToken();
    if (token != null && token.isNotEmpty) {
      request.headers[AuthConstants.authorizationHeader] =
          '${AuthConstants.bearerPrefix} $token';
    }

    // Send request
    try {
      var response = await _inner.send(request);

      // Handle 401 Unauthorized - token expired
      if (response.statusCode == 401) {
        // Try to refresh token
        final refreshed = await refreshToken();

        if (refreshed) {
          // Retry request with new token
          final newToken = getToken();
          if (newToken != null && newToken.isNotEmpty) {
            final retryRequest = _copyRequest(request);
            retryRequest.headers[AuthConstants.authorizationHeader] =
                '${AuthConstants.bearerPrefix} $newToken';
            response = await _inner.send(retryRequest);
          }
        } else {
          // Token refresh failed
          throw TokenExpiredException();
        }
      }

      // Handle other errors
      _handleResponseError(response.statusCode);

      return response;
    } on http.ClientException {
      throw NetworkException();
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw NetworkException();
    }
  }

  /// Copy request to retry with new headers
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;

    if (request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw NetworkException(message: 'Cannot retry a StreamedRequest');
    } else {
      throw NetworkException(message: 'Unknown request type');
    }

    requestCopy
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return requestCopy;
  }

  /// Handle response error codes
  void _handleResponseError(int statusCode) {
    switch (statusCode) {
      case 400:
        throw ServerException(message: 'Bad request');
      case 401:
        throw TokenExpiredException();
      case 403:
        throw OperationNotSupportedException(message: 'Access forbidden');
      case 404:
        throw UserNotFoundException();
      case 409:
        throw UserAlreadyExistsException();
      case 500:
      case 502:
      case 503:
        throw ServerException(message: 'Server error');
      default:
        if (statusCode >= 400 && statusCode < 500) {
          throw GenericAuthException(message: 'Client error: $statusCode');
        } else if (statusCode >= 500) {
          throw ServerException();
        }
    }
  }
}
