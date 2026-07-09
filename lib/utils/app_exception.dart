import 'dart:async';
import 'dart:io';

class AppException implements Exception {
  const AppException(this.message);

  factory AppException.fromObject(Object error, {required String fallback}) {
    if (error is AppException) return error;
    if (isNetworkError(error)) return const AppException(offlineMessage);
    return AppException(fallback);
  }

  static const offlineMessage = 'Tidak ada koneksi internet';

  final String message;

  bool get isOffline => message == offlineMessage;

  static bool isOfflineMessage(String? message) {
    return message?.trim() == offlineMessage;
  }

  static bool isNetworkError(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        error is HandshakeException) {
      return true;
    }

    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('timeoutexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('no address associated with hostname') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused') ||
        text.contains('connection timed out') ||
        text.contains('failed to fetch') ||
        text.contains('xmlhttprequest error') ||
        text.contains('handshakeexception');
  }

  @override
  String toString() => message;
}
