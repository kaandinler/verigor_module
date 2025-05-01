import 'package:dio/dio.dart';
import 'package:verigor_module/data/base/base_response.dart';
import 'package:verigor_module/data/models/response/file_response.dart';

/// Responsible solely for making HTTP requests to fetch file data.
class FileService {
  final Dio _dio;

  FileService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches the raw API response and returns a parsed BaseResponse of List<FileData>.
  Future<BaseResponse<List<FileData>>> fetchFiles(String xToken) async {
    const url = 'https://dev-verigor-be.twoq.dev/api/file';
    try {
      final response = await _dio.get<Map<String, dynamic>>(url, options: Options(headers: {'x-token': xToken}));

      return BaseResponse.fromJson(response.data!, (jsonData) {
        final list = jsonData as List;
        return list.map((item) => FileData.fromJson(item as Map<String, dynamic>)).toList();
      });
    } on DioException catch (dioErr) {
      return BaseResponse<List<FileData>>(status: false, message: dioErr.message ?? 'Exception', data: null);
    } catch (e) {
      return BaseResponse<List<FileData>>(status: false, message: 'Unexpected error: $e', data: null);
    }
  }
}
