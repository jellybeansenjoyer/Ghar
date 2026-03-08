import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/visitor.dart';
import '../../services/visitor_service.dart';
import '../../config/theme.dart';

class VisitorDetailScreen extends ConsumerStatefulWidget {
  final String visitorId;

  const VisitorDetailScreen({super.key, required this.visitorId});

  @override
  ConsumerState<VisitorDetailScreen> createState() =>
      _VisitorDetailScreenState();
}

class _VisitorDetailScreenState extends ConsumerState<VisitorDetailScreen> {
  Visitor? _visitor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVisitor();
    });
  }

  Future<void> _loadVisitor() async {
    try {
      final visitor = await VisitorService().getVisitor(widget.visitorId);
      if (mounted) setState(() { _visitor = visitor; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visitor == null
              ? const Center(child: Text('Visitor not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Photo
                      CircleAvatar(
                        radius: 60,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        backgroundImage: _visitor!.photoUrl != null
                            ? NetworkImage(_visitor!.photoUrl!)
                            : null,
                        child: _visitor!.photoUrl == null
                            ? Text(
                                _visitor!.name.isNotEmpty
                                    ? _visitor!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _visitor!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(_visitor!.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _visitor!.status.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(_visitor!.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Details
                      _detailRow(
                        Icons.access_time,
                        'Arrived',
                        DateFormat('MMM d, yyyy • h:mm a')
                            .format(_visitor!.arrivedAt.toLocal()),
                      ),
                      if (_visitor!.respondedAt != null)
                        _detailRow(
                          Icons.check_circle,
                          'Responded',
                          DateFormat('h:mm a')
                              .format(_visitor!.respondedAt!.toLocal()),
                        ),
                      if (_visitor!.respondedByName != null)
                        _detailRow(
                          Icons.person,
                          'Responded by',
                          _visitor!.respondedByName!,
                        ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/chat/${_visitor!.id}',
                            extra: _visitor!.name,
                          ),
                          icon: const Icon(Icons.chat),
                          label: const Text('View Chat'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
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
