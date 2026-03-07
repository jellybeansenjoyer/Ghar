import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visitor.dart';
import '../services/visitor_service.dart';

class VisitorState {
  final List<Visitor> visitors;
  final Visitor? currentVisitor; // Currently ringing visitor
  final bool isLoading;
  final String? error;
  final int totalPages;
  final int currentPage;

  VisitorState({
    this.visitors = const [],
    this.currentVisitor,
    this.isLoading = false,
    this.error,
    this.totalPages = 1,
    this.currentPage = 1,
  });

  VisitorState copyWith({
    List<Visitor>? visitors,
    Visitor? currentVisitor,
    bool? isLoading,
    String? error,
    int? totalPages,
    int? currentPage,
    bool clearCurrentVisitor = false,
  }) {
    return VisitorState(
      visitors: visitors ?? this.visitors,
      currentVisitor:
          clearCurrentVisitor ? null : (currentVisitor ?? this.currentVisitor),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class VisitorNotifier extends StateNotifier<VisitorState> {
  final VisitorService _visitorService = VisitorService();

  VisitorNotifier() : super(VisitorState());

  Future<void> loadHistory(String familyId, {int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _visitorService.getHistory(familyId, page: page);
      state = VisitorState(
        visitors: result.visitors,
        totalPages: result.pages,
        currentPage: page,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load visitor history',
      );
    }
  }

  void setCurrentVisitor(Map<String, dynamic> data) {
    final visitor = Visitor(
      id: data['visitorId'] ?? '',
      familyId: data['familyId'] ?? '',
      name: data['visitorName'] ?? data['name'] ?? 'Visitor',
      photoUrl: data['photoUrl'],
      status: 'pending',
      arrivedAt: data['arrivedAt'] != null
          ? DateTime.parse(data['arrivedAt'])
          : DateTime.now(),
    );
    state = state.copyWith(currentVisitor: visitor);
  }

  Future<void> respondToVisitor(String visitorId, String action) async {
    try {
      await _visitorService.respondToVisitor(visitorId, action);
      state = state.copyWith(clearCurrentVisitor: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to respond');
    }
  }

  void clearCurrentVisitor() {
    state = state.copyWith(clearCurrentVisitor: true);
  }

  void clear() {
    state = VisitorState();
  }
}

final visitorProvider =
    StateNotifierProvider<VisitorNotifier, VisitorState>((ref) {
  return VisitorNotifier();
});
