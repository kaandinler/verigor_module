class BaseResponse<T> {
  final bool status;
  final String message;
  final T? data;

  BaseResponse({required this.status, required this.message, this.data});

  /// Parse a JSON map into `BaseResponse<T>` by providing a converter for `data`.
  factory BaseResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    return BaseResponse<T>(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  /// Serialize `BaseResponse<T>` to JSON by providing a converter for `data`.
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {'status': status, 'message': message, 'data': data != null ? toJsonT(data as T) : null};
  }
}
