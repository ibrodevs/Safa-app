import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// ignore_for_file: avoid_print

class HttpLoggerInterceptor extends Interceptor {
  HttpLoggerInterceptor({
    this.tag = 'HTTP',
    this.maxBody = 400000,
    this.alsoPrint = true,
  });

  final String tag;
  final int maxBody;
  final bool alsoPrint;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final msg = _fmtRequest(options);
    dev.log(msg, name: tag);
    if (alsoPrint) debugPrint('[$tag]\n$msg');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final full = _pretty(response.data);
    dev.log(
      '← ${response.statusCode} ${response.requestOptions.uri}\n$full',
      name: tag,
    );

    if (alsoPrint) {
      debugPrint('[$tag] body: ${_short(full)}');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final msg = _fmtError(err);
    dev.log(msg, name: tag, error: err.error, stackTrace: err.stackTrace);
    if (alsoPrint) debugPrint('[$tag]\n$msg');
    handler.next(err);
  }

  String _fmtRequest(RequestOptions o) {
    final b = StringBuffer()
      ..writeln('→ ${o.method} ${o.uri}')
      ..writeln('headers: ${_short(_pretty(o.headers))}');
    if (o.queryParameters.isNotEmpty) b.writeln('query: ${_short(_pretty(o.queryParameters))}');
    if (o.data != null) b.writeln('body: ${_short(_pretty(o.data))}');
    return b.toString().trimRight();
  }

  String _fmtError(DioException e) {
    final ro = e.requestOptions;
    final b = StringBuffer()
      ..writeln('⨯ ERROR ${ro.method} ${ro.uri}')
      ..writeln('type: ${e.type}')
      ..writeln('message: ${e.message}');
    if (e.response != null) {
      b.writeln('status: ${e.response?.statusCode}');
      b.writeln('body: ${_short(_pretty(e.response?.data))}');
    }
    return b.toString().trimRight();
  }

  String _short(String s) {
    if (kReleaseMode) {
      if (s.length <= maxBody) return s;
      return '${s.substring(0, maxBody)}…(truncated ${s.length - maxBody})';
    }
    return s;
  }

  String _pretty(dynamic v) {
    if (v == null) return 'null';
    try {
      if (v is String) return v;
      return const JsonEncoder.withIndent('  ').convert(v);
    } catch (_) {
      return v.toString();
    }
  }
}
