import 'dart:developer';
import 'package:verigor_module_flutter/data/service/file_service.dart';
import 'package:verigor_module_flutter/data/service/query_service.dart';
import 'package:verigor_module_flutter/models/repository/file_repository.dart';
import 'package:verigor_module_flutter/models/repository/query_repository.dart';
import 'package:verigor_module_flutter/models/message_type.dart';

class VeriGorViewModel {
  final QueryRepository _queryRepository = QueryRepository(service: QueryService());
  final FileRepository _fileRepository = FileRepository(service: FileService());

  Future<List<String>> getFiles(String token) async {
    final response = await _fileRepository.getFiles(token);
    log('Files: $response');
    return response.map((file) => file.name).toList();
  }

  Future<Message> sendQuestion({
    required String token,
    required String question,
    required String threadId,
    required String fileName,
  }) async {
    try {
      final entity = await _queryRepository.createQuery(
        xToken: token,
        query: question,
        threadId: threadId,
        fileName: fileName,
      );

      return Message.webView(entity.requestId);
    } catch (e) {
      // Handle error
      log('Error sending question: $e');
      return Message.text('Soru gönderilirken bir hata oluştu. Lütfen Token ve diğer bilgileri kontrol edin.');
    }
  }
}
