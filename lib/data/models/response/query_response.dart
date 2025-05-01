/// DTO for the `data` object of the query endpoint.
class QueryData {
  final String requestId;

  QueryData({required this.requestId});

  factory QueryData.fromJson(Map<String, dynamic> json) {
    return QueryData(requestId: json['request_id'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'request_id': requestId};
  }
}
