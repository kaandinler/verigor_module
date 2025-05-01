import 'package:dio/dio.dart';

class FileRequest {
  final Dio _dio = Dio();

  Future<Response> sendRequest(String xToken) async {
    const String url = 'https://dev-verigor-be.twoq.dev/api/file';

    try {
      final response = await _dio.get(url, options: Options(headers: {'x-token': xToken}));
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
