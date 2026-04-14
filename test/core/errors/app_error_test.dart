// ABOUTME: Tests for typed error classification used across the app.
// ABOUTME: Verifies factory correctly maps exceptions to error variants.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:udahni/core/errors/app_error.dart';

void main() {
  group('AppError.fromException', () {
    test('classifies SocketException as noInternet', () {
      final error = AppError.fromException(
        const SocketException('No route to host'),
      );
      expect(error, isA<NoInternetError>());
      expect(error.userMessage, contains('internet'));
    });

    test('classifies TimeoutException as noInternet', () {
      final error = AppError.fromException(
        TimeoutException('Request timed out'),
      );
      expect(error, isA<NoInternetError>());
    });

    test('classifies ClientException as noInternet', () {
      final error = AppError.fromException(
        http.ClientException('Connection reset'),
      );
      expect(error, isA<NoInternetError>());
    });

    test('classifies generic Exception as unexpected', () {
      final error = AppError.fromException(Exception('something broke'));
      expect(error, isA<UnexpectedError>());
      expect(error.userMessage, contains('greške'));
    });
  });

  group('AppError.fromHttpStatus', () {
    test('classifies 500 as serverError', () {
      final error = AppError.fromHttpStatus(500);
      expect(error, isA<ServerError>());
      expect(error.userMessage, contains('dostupni'));
    });

    test('classifies 503 as serverError', () {
      final error = AppError.fromHttpStatus(503);
      expect(error, isA<ServerError>());
    });

    test('classifies 404 as notFound', () {
      final error = AppError.fromHttpStatus(404);
      expect(error, isA<NotFoundError>());
    });

    test('classifies 400 as unexpected', () {
      final error = AppError.fromHttpStatus(400);
      expect(error, isA<UnexpectedError>());
    });
  });
}
