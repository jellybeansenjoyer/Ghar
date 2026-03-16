import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family.dart' as models;
import '../models/user.dart';
import '../services/family_service.dart';
import '../core/storage/secure_storage.dart';

class FamilyState {
  final models.Family? family;
  final List<AppUser> members;
  final String? qrCodeData;
  final bool isLoading;
  final String? error;

  FamilyState({
    this.family,
    this.members = const [],
    this.qrCodeData,
    this.isLoading = false,
    this.error,
  });

  FamilyState copyWith({
    models.Family? family,
    List<AppUser>? members,
    String? qrCodeData,
    bool? isLoading,
    String? error,
  }) {
    return FamilyState(
      family: family ?? this.family,
      members: members ?? this.members,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  final FamilyService _familyService = FamilyService();

  FamilyNotifier() : super(FamilyState());

  Future<String?> createFamily(String name, String? address) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _familyService.createFamily(name, address);

      // Update stored tokens
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken != null) {
        await SecureStorageService.saveTokens(
          accessToken: result.accessToken,
          refreshToken: refreshToken,
        );
      }

      state = FamilyState(
        family: result.family,
        qrCodeData: result.family.qrCodeData,
        isLoading: false,
      );

      return result.family.id;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create family',
      );
      return null;
    }
  }

  Future<void> loadFamily(String familyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      debugPrint('[FamilyProvider] Loading family: $familyId');
      final family = await _familyService.getFamily(familyId);
      debugPrint('[FamilyProvider] Family loaded: ${family.name} (id: ${family.id})');
      final members = await _familyService.getMembers(familyId);
      debugPrint('[FamilyProvider] Members loaded: ${members.length}');
      final qrData = await _familyService.getQrCodeData(familyId);
      debugPrint('[FamilyProvider] QR data loaded: $qrData (length: ${qrData.length})');

      state = FamilyState(
        family: family,
        members: members,
        qrCodeData: qrData,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint('[FamilyProvider] Failed to load family: $e\n$stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load family: $e',
      );
    }
  }

  Future<void> loadMembers() async {
    if (state.family == null) return;
    try {
      final members = await _familyService.getMembers(state.family!.id);
      state = state.copyWith(members: members);
    } catch (_) {}
  }

  Future<bool> addMember({
    String? phone,
    String? email,
    String? inviteToken,
  }) async {
    if (state.family == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _familyService.addMember(
        state.family!.id,
        phone: phone,
        email: email,
        inviteToken: inviteToken,
      );
      await loadMembers();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>?> createInvite({int expiresInDays = 7}) async {
    if (state.family == null) {
      debugPrint('[FamilyProvider] Cannot create invite: no family');
      return null;
    }
    try {
      debugPrint('[FamilyProvider] Creating invite for family: ${state.family!.id}');
      final invite = await _familyService.createInvite(
        state.family!.id,
        expiresInDays: expiresInDays,
      );
      debugPrint('[FamilyProvider] Invite created: ${invite['inviteUrl']}');
      return invite;
    } catch (e) {
      debugPrint('[FamilyProvider] Error creating invite: $e');
      state = state.copyWith(error: _extractError(e));
      return null;
    }
  }

  Future<bool> removeMember(String userId) async {
    if (state.family == null) return false;
    try {
      await _familyService.removeMember(state.family!.id, userId);
      await loadMembers();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove member');
      return false;
    }
  }

  void clear() {
    state = FamilyState();
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('message')) {
        final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(msg);
        if (match != null) return match.group(1)!;
      }
    }
    return 'Something went wrong';
  }
}

final familyProvider =
    StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  return FamilyNotifier();
});
