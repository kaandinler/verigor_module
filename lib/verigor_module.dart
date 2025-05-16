// DTOs & helpers
export '/data/base/base_response.dart';
export '/data/models/request/file_request.dart';
export '/data/models/response/file_response.dart';
export '/data/models/response/query_response.dart';

// Services
export '/data/service/file_service.dart';
export '/data/service/query_service.dart';

// Repositories
export '/models/repository/file_repository.dart';
export '/models/repository/query_repository.dart';

// Domain models
export 'models/file_entity.dart';
export 'models/message_type.dart';
export 'models/query_entity.dart';

// Core widgets
export 'src/verigor_screen.dart';
export 'src/widgets/resizable_answer_widget.dart';

/// A typedef for token providers
typedef TokenProvider = String Function();
