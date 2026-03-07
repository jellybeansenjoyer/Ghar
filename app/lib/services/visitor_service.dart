import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/visitor.dart';

class VisitorService {
  final Dio _dio = ApiClient.instance.dio;

  Future<({List<Visitor> visitors, int total, int pages})> getHistory(
    String familyId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/families/$familyId/visitors',
      queryParameters: {'page': page, 'limit': limit},
    );

    final data = response.data['data'];
    final list = data['visitors'] as List;
    final pagination = data['pagination'];

    return (
      visitors: list.map((v) => Visitor.fromJson(v)).toList(),
      total: pagination['total'] as int,
      pages: pagination['pages'] as int,
    );
  }

  Future<Visitor> getVisitor(String visitorId) async {
    final response = await _dio.get('/visitors/$visitorId');
    return Visitor.fromJson(response.data['data']);
  }

  Future<void> respondToVisitor(String visitorId, String action) async {
    await _dio.post('/visitors/$visitorId/respond', data: {
      'action': action,
    });
  }
}
