import 'package:flutter_test/flutter_test.dart';
import 'package:ghar/providers/visitor_provider.dart';
import 'package:ghar/models/visitor.dart';

void main() {
  group('VisitorState', () {
    test('should have default values', () {
      final state = VisitorState();

      expect(state.visitors, isEmpty);
      expect(state.currentVisitor, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.totalPages, 1);
      expect(state.currentPage, 1);
    });

    test('copyWith should update specified fields', () {
      final visitors = [
        Visitor(
          id: 'v1',
          familyId: 'f1',
          name: 'Visitor 1',
          arrivedAt: DateTime.now(),
        ),
      ];

      final state = VisitorState();
      final updated = state.copyWith(
        visitors: visitors,
        totalPages: 5,
        currentPage: 2,
      );

      expect(updated.visitors.length, 1);
      expect(updated.totalPages, 5);
      expect(updated.currentPage, 2);
    });

    test('copyWith clearCurrentVisitor should set currentVisitor to null', () {
      final visitor = Visitor(
        id: 'v1',
        familyId: 'f1',
        name: 'V',
        arrivedAt: DateTime.now(),
      );
      final state = VisitorState(currentVisitor: visitor);

      final updated = state.copyWith(clearCurrentVisitor: true);

      expect(updated.currentVisitor, isNull);
    });

    test('copyWith should preserve currentVisitor when not clearing', () {
      final visitor = Visitor(
        id: 'v1',
        familyId: 'f1',
        name: 'V',
        arrivedAt: DateTime.now(),
      );
      final state = VisitorState(currentVisitor: visitor);

      final updated = state.copyWith(isLoading: true);

      expect(updated.currentVisitor, isNotNull);
      expect(updated.currentVisitor?.id, 'v1');
    });
  });

  group('VisitorNotifier', () {
    late VisitorNotifier notifier;

    setUp(() {
      notifier = VisitorNotifier();
    });

    test('initial state should have no visitors', () {
      expect(notifier.state.visitors, isEmpty);
      expect(notifier.state.currentVisitor, isNull);
    });

    test('setCurrentVisitor should set visitor from map data', () {
      notifier.setCurrentVisitor({
        'visitorId': 'v-1',
        'familyId': 'f-1',
        'visitorName': 'John',
        'photoUrl': 'https://img.com/john.jpg',
        'arrivedAt': '2025-06-15T10:00:00Z',
      });

      expect(notifier.state.currentVisitor, isNotNull);
      expect(notifier.state.currentVisitor?.id, 'v-1');
      expect(notifier.state.currentVisitor?.name, 'John');
      expect(notifier.state.currentVisitor?.photoUrl, 'https://img.com/john.jpg');
      expect(notifier.state.currentVisitor?.status, 'pending');
    });

    test('setCurrentVisitor should use name fallback', () {
      notifier.setCurrentVisitor({
        'visitorId': 'v-2',
        'name': 'Jane',
      });

      expect(notifier.state.currentVisitor?.name, 'Jane');
    });

    test('setCurrentVisitor should default name to Visitor', () {
      notifier.setCurrentVisitor({
        'visitorId': 'v-3',
      });

      expect(notifier.state.currentVisitor?.name, 'Visitor');
    });

    test('clearCurrentVisitor should clear current visitor', () {
      notifier.setCurrentVisitor({
        'visitorId': 'v-1',
        'name': 'Test',
      });
      expect(notifier.state.currentVisitor, isNotNull);

      notifier.clearCurrentVisitor();

      expect(notifier.state.currentVisitor, isNull);
    });

    test('clear should reset all state', () {
      notifier.setCurrentVisitor({
        'visitorId': 'v-1',
        'name': 'Test',
      });

      notifier.clear();

      expect(notifier.state.visitors, isEmpty);
      expect(notifier.state.currentVisitor, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });
  });
}
