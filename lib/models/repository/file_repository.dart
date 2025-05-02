import 'package:verigor_module_flutter/data/service/file_service.dart';
import 'package:verigor_module_flutter/models/file_entity.dart';

/// Repository layer: converts service DTOs into domain entities.
class FileRepository {
  final FileService _service;

  FileRepository({required FileService service}) : _service = service;

  /// Returns either a list of FileEntity or throws on failure.
  Future<List<FileEntity>> getFiles(String xToken) async {
    final response = await _service.fetchFiles(xToken);
    if (response.data != null) {
      return response.data!.map((dto) => FileEntity(id: dto.id, name: dto.name)).toList();
    } else {
      // handle error based on response.message or status
      throw Exception('Failed to load files: ${response.message}');
    }
  }
}
