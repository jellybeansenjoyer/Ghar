import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../config/theme.dart';
import 'package:intl/intl.dart';

class VisitorHistoryScreen extends ConsumerStatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  ConsumerState<VisitorHistoryScreen> createState() =>
      _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends ConsumerState<VisitorHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    final user = ref.read(authProvider).user;
    if (user?.familyId != null) {
      await ref
          .read(visitorProvider.notifier)
          .loadHistory(user!.familyId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitorState = ref.watch(visitorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Visitor History')),
      body: visitorState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : visitorState.visitors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'No visitors yet',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: visitorState.visitors.length,
                    itemBuilder: (context, index) {
                      final visitor = visitorState.visitors[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                _statusColor(visitor.status).withValues(alpha: 0.1),
                            backgroundImage: visitor.photoUrl != null
                                ? NetworkImage(visitor.photoUrl!)
                                : null,
                            child: visitor.photoUrl == null
                                ? Text(
                                    visitor.name.isNotEmpty
                                        ? visitor.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(visitor.status),
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            visitor.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy • h:mm a')
                                .format(visitor.arrivedAt.toLocal()),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(visitor.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              visitor.status.toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(visitor.status),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          onTap: () => context.push('/visitor/${visitor.id}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.dangerColor;
      case 'expired':
        return AppTheme.textSecondary;
      default:
        return AppTheme.warningColor;
    }
  }
}
