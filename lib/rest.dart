// import 'package:alica/alice.dart';
import 'package:dio/dio.dart';
import 'package:firebase/constants.dart';
import 'package:flutter/foundation.dart';

enum Method { post, get, put, delete }

const String _baseUrl = Constants.BASE_URL;

class Rest {
  final Dio _dio = Dio(BaseOptions(
      receiveTimeout: const Duration(seconds: 60),
      connectTimeout: const Duration(seconds: 60)))
    ..interceptors.add(LogInterceptor(
        responseBody: true, requestBody: true, requestHeader: true));

  Future<Response?> request(
      {required String path,
      Method? method,
      Map<String, dynamic>? header,
      Map<String, dynamic>? params,
      Object? data}) async {
    method ??= Method.get;
    try {
      final _result = await _dio.fetch(
          Options(method: method.name, headers: header)
              .compose(_dio.options, path, data: data, queryParameters: params)
              .copyWith(baseUrl: _baseUrl));

      // Alice(
      //     result: _result,
      //     showNotification: true,
      //     navigatorKey: NavigationService.navigatorKey);
      return _result;
    } on DioError catch (_) {
      if (kDebugMode) {
        print("error: ${_.type.name}");
      }
    }
    return null;
  }
}
