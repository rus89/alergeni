// ABOUTME: Typed error representations for user-facing error states.
// ABOUTME: Classifies network, server, and data errors with Serbian user messages.

import 'dart:async';
import 'dart:io';

sealed class AppError {
  const AppError();

  String get userMessage;
  String get iconName;

  factory AppError.fromException(Object exception) {
    if (exception is SocketException || exception is TimeoutException) {
      return const NoInternetError();
    }
    return UnexpectedError(debugMessage: exception.toString());
  }

  factory AppError.fromHttpStatus(int statusCode) {
    if (statusCode >= 500) {
      return const ServerError();
    }
    if (statusCode == 404) {
      return const NotFoundError();
    }
    return UnexpectedError(debugMessage: 'HTTP $statusCode');
  }
}

class NoInternetError extends AppError {
  const NoInternetError();

  @override
  String get userMessage =>
      'Nema internet konekcije. Proverite vezu i pokušajte ponovo.';

  @override
  String get iconName => 'wifi_off';
}

class ServerError extends AppError {
  const ServerError();

  @override
  String get userMessage =>
      'Podaci trenutno nisu dostupni. Pokušajte ponovo malo kasnije.';

  @override
  String get iconName => 'cloud_off';
}

class NotFoundError extends AppError {
  const NotFoundError();

  @override
  String get userMessage => 'Podaci za ovu lokaciju nisu pronađeni.';

  @override
  String get iconName => 'search_off';
}

class UnexpectedError extends AppError {
  final String? debugMessage;

  const UnexpectedError({this.debugMessage});

  @override
  String get userMessage => 'Došlo je do greške. Pokušajte ponovo.';

  @override
  String get iconName => 'error_outline';
}
