import '../models/system_model.dart';
import 'api_client.dart';

class SystemEvent {
  final int id;
  final String systemId;
  final String type;
  final String message;
  final DateTime timestamp;

  SystemEvent({
    required this.id,
    required this.systemId,
    required this.type,
    required this.message,
    required this.timestamp,
  });

  factory SystemEvent.fromJson(Map<String, dynamic> json) => SystemEvent(
        id: json['id'] as int,
        systemId: json['system_id'] as String,
        type: json['type'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class SystemService {
  final ApiClient _api = ApiClient();

  Future<List<SystemModel>> fetchSystems() async {
    final data = await _api.get('/systems') as List;
    return data
        .map((e) => SystemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SystemModel> getSystem(String id) async {
    final data = await _api.get('/systems/$id') as Map<String, dynamic>;
    return SystemModel.fromJson(data);
  }

  Future<SystemModel> powerAction(String id, String action) async {
    final data = await _api.post('/systems/$id/power', {'action': action})
        as Map<String, dynamic>;
    return SystemModel.fromJson(data);
  }

  Future<List<SystemEvent>> getEvents(String id) async {
    final data = await _api.get('/systems/$id/events') as List;
    return data
        .map((e) => SystemEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
