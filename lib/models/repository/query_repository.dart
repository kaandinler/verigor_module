import 'package:verigor_module_flutter/data/service/query_service.dart';
import 'package:verigor_module_flutter/models/query_entity.dart';

/// Repository layer: uses the service to perform queries and map to domain.
class QueryRepository {
  final QueryService _service;

  QueryRepository({required QueryService service}) : _service = service;

  /// Creates a new query and returns its `requestId` wrapped in a `QueryEntity`.
  Future<QueryEntity> createQuery({required String xToken, required String query, required String threadId, required String fileName}) async {
    final response = await _service.sendQuery(xToken: xToken, query: query, threadId: threadId, fileName: fileName);
    if (response.data != null) {
      return QueryEntity(requestId: response.data!.requestId);
    }
    throw Exception('Failed to create query: ${response.message}');
  }
}
