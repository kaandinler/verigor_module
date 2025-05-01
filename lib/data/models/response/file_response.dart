/// Data transfer object for file metadata from the API.
class FileData {
  final String id;
  final String name;

  FileData({required this.id, required this.name});

  factory FileData.fromJson(Map<String, dynamic> json) {
    return FileData(id: json['id'] as String, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
