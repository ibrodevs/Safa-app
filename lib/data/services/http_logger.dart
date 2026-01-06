import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    final msg = _fmtRequest(o);
    dev.log(msg, name: tag);
    if (alsoPrint) print('[$tag]\n$msg');
    h.next(o);
  }

  @override
  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    final full = _pretty(r.data);
    dev.log(
      '← ${r.statusCode} ${r.requestOptions.uri}\n$full',
      name: tag,
    );

    if (alsoPrint) {
      print('[$tag] body: ${_short(full)}');
    }

    h.next(r);
  }


  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    final msg = _fmtError(e);
    dev.log(msg, name: tag, error: e.error, stackTrace: e.stackTrace);
    if (alsoPrint) print('[$tag]\n$msg');
    h.next(e);
  }

  String _fmtRequest(RequestOptions o) {
    final b = StringBuffer()
      ..writeln('→ ${o.method} ${o.uri}')
      ..writeln('headers: ${_short(_pretty(o.headers))}');
    if (o.queryParameters.isNotEmpty) b.writeln('query: ${_short(_pretty(o.queryParameters))}');
    if (o.data != null) b.writeln('body: ${_short(_pretty(o.data))}');
    return b.toString().trimRight();
  }

  String _fmtResponse(Response r) {
    final b = StringBuffer()
      ..writeln('← ${r.statusCode} ${r.requestOptions.method} ${r.requestOptions.uri}')
      ..writeln('headers: ${_short(_pretty(r.headers.map))}');
    if (r.data != null) b.writeln('body: ${_short(_pretty(r.data))}');
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
  void _logLong(String text) {
    const chunkSize = 800;
    for (var i = 0; i < text.length; i += chunkSize) {
      dev.log(
        text.substring(
          i,
          i + chunkSize > text.length ? text.length : i + chunkSize,
        ),
        name: tag,
      );
    }
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
