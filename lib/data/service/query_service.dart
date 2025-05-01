import 'package:dio/dio.dart';
import 'package:verigor_module/data/base/base_response.dart';
import 'package:verigor_module/data/models/response/query_response.dart';

/// Responsible for calling the query API endpoint.
class QueryService {
  final Dio _dio;

  QueryService({Dio? dio}) : _dio = dio ?? Dio();

  /// Sends the query payload and returns a parsed BaseResponse<QueryData>.
  Future<BaseResponse<QueryData>> sendQuery({
    required String xToken,
    required String query,
    required String threadId,
    required String fileName,
  }) async {
    const url = 'https://dev-verigor-be.twoq.dev/api/query';
    final payload = {'query': query, 'thread_id': threadId, 'file_name': fileName};
    try {
      final response = await _dio.post<Map<String, dynamic>>(url, data: payload, options: Options(headers: {'x-token': xToken}));

      return BaseResponse.fromJson(response.data!, (dataJson) => QueryData.fromJson(dataJson as Map<String, dynamic>));
    } on DioException catch (dioErr) {
      return BaseResponse<QueryData>(status: false, message: dioErr.message ?? 'Exception', data: null);
    } catch (e) {
      return BaseResponse<QueryData>(status: false, message: 'Unexpected error: \$e', data: null);
    }
  }
}
