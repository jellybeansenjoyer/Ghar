import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/family.dart';
import '../models/user.dart';

class FamilyService {
  final Dio _dio = ApiClient.instance.dio;

  Future<({Family family, String accessToken})> createFamily(
      String name, String? address) async {
    final response = await _dio.post('/families', data: {
      'name': name,
      'address': ?address,
    });

    final data = response.data['data'];
    return (
      family: Family.fromJson(data['family']),
      accessToken: data['accessToken'] as String,
    );
  }

  Future<Family> getFamily(String familyId) async {
    final response = await _dio.get('/families/$familyId');
    return Family.fromJson(response.data['data']);
  }

  Future<List<AppUser>> getMembers(String familyId) async {
    final response = await _dio.get('/families/$familyId/members');
    final list = response.data['data'] as List;
    return list.map((m) => AppUser.fromJson(m)).toList();
  }

  Future<AppUser> addMember(String familyId, String phone) async {
    final response = await _dio.post('/families/$familyId/members', data: {
      'phone': phone,
    });
    return AppUser.fromJson(response.data['data']);
  }

  Future<void> removeMember(String familyId, String userId) async {
    await _dio.delete('/families/$familyId/members/$userId');
  }

  Future<String> getQrCodeData(String familyId) async {
    final response = await _dio.get('/families/$familyId/qr');
    return response.data['data']['qrData'] as String;
  }
}
