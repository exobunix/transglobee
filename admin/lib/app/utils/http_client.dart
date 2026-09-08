import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as original_http;

export 'package:http/http.dart' hide get, post, put, delete;

final _loggingClient = LoggingClient();

Future<original_http.Response> get(Uri url, {Map<String, String>? headers}) =>
    _loggingClient.get(url, headers: headers);

Future<original_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _loggingClient.post(url, headers: headers, body: body, encoding: encoding);

Future<original_http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _loggingClient.put(url, headers: headers, body: body, encoding: encoding);

Future<original_http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _loggingClient.delete(url, headers: headers, body: body, encoding: encoding);

class LoggingClient extends original_http.BaseClient {
  final original_http.Client _inner = original_http.Client();

  @override
  Future<original_http.StreamedResponse> send(original_http.BaseRequest request) async {
    final reqId = DateTime.now().millisecondsSinceEpoch;
    
    // Print Request logs
    debugPrint("-------------------- HTTP REQUEST --------------------");
    debugPrint("--> [Req ID: $reqId] ${request.method} ${request.url}");
    debugPrint("Headers: ${request.headers}");
    
    if (request is original_http.Request) {
      if (request.body.isNotEmpty) {
        debugPrint("Body: ${request.body}");
      }
    } else if (request is original_http.MultipartRequest) {
      debugPrint("Multipart Fields: ${request.fields}");
      final fileNames = request.files.map((f) => "${f.field} (${f.filename}, ${f.length} bytes)").join(", ");
      debugPrint("Multipart Files: [$fileNames]");
    }
    debugPrint("-----------------------------------------------------");

    final startTime = DateTime.now();
    final response = await _inner.send(request);
    final duration = DateTime.now().difference(startTime).inMilliseconds;

    // Buffer response body bytes so we can print them without consuming the stream
    final bytes = await response.stream.toBytes();
    final bodyString = utf8.decode(bytes, allowMalformed: true);

    // Print Response logs
    debugPrint("-------------------- HTTP RESPONSE --------------------");
    debugPrint("<-- [Req ID: $reqId] Status: ${response.statusCode} | Duration: ${duration}ms | ${request.url}");
    debugPrint("Response Headers: ${response.headers}");
    debugPrint("Response Body: $bodyString");
    debugPrint("------------------------------------------------------");

    return original_http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
