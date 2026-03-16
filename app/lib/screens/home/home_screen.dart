import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/visitor_provider.dart';
import '../../core/network/socket_service.dart';
import '../../services/notification_service.dart';
import '../../config/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _setupRealtime();
    });
  }

  Future<void> _loadData() async {
    final user = ref.read(authProvider).user;
    debugPrint('[HomeScreen] _loadData called. user=${user?.name}, familyId=${user?.familyId}');
    
    // Ensure push token is registered (in case it wasn't set during login)
    try {
      final playerId = await NotificationService.getPlayerId();
      if (playerId != null) {
        debugPrint('[HomeScreen] Registering push token: $playerId');
        await ref.read(authProvider.notifier).updatePushToken(playerId);
      } else {
        debugPrint('[HomeScreen] WARNING: OneSignal player ID not available yet');
      }
    } catch (e) {
      debugPrint('[HomeScreen] Error registering push token: $e');
    }
    
    if (user?.familyId != null) {
      await ref.read(familyProvider.notifier).loadFamily(user!.familyId!);
      await ref
          .read(visitorProvider.notifier)
          .loadHistory(user.familyId!);
      debugPrint('[HomeScreen] Data loaded successfully');
    } else {
      debugPrint('[HomeScreen] No familyId, skipping load');
    }
  }

  void _setupRealtime() {
    final user = ref.read(authProvider).user;
    if (user?.familyId == null) return;

    // Connect Socket.IO
    final socket = SocketService.instance;
    socket.connect();
    socket.joinFamilyRoom(user!.familyId!);

    // Listen for new visitors
    socket.onVisitorNew((data) {
      ref.read(visitorProvider.notifier).setCurrentVisitor(data);

      // Show notification and navigate to ringing screen
      NotificationService.showVisitorNotification(
        visitorName: data['name'] ?? 'Visitor',
        visitorId: data['visitorId'] ?? '',
      );

      if (mounted) {
        context.push('/incoming-visitor', extra: data);
      }
    });

    // Listen for visitor responses (stop ringing)
    socket.onVisitorResponded((data) {
      ref.read(visitorProvider.notifier).clearCurrentVisitor();
      NotificationService.cancelNotification(data['visitorId'] ?? '');
    });

    // Setup push notification handler
    NotificationService.onVisitorArrived = (data) {
      ref.read(visitorProvider.notifier).setCurrentVisitor(data);
      if (mounted) {
        context.push('/incoming-visitor', extra: data);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);
    final user = authState.user;
    final family = familyState.family;

    return Scaffold(
      appBar: AppBar(
        title: Text(family?.name ?? 'Ghar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.name ?? "there"}! 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.isAdmin == true
                            ? 'You are the admin of this family'
                            : 'Family member',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Actions Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _ActionCard(
                    icon: Icons.qr_code,
                    title: 'QR Code',
                    subtitle: 'Show & share',
                    color: AppTheme.primaryColor,
                    onTap: () => context.push('/qr-code'),
                  ),
                  _ActionCard(
                    icon: Icons.group,
                    title: 'Members',
                    subtitle:
                        '${familyState.members.length} member${familyState.members.length != 1 ? "s" : ""}',
                    color: AppTheme.successColor,
                    onTap: () => context.push('/members'),
                  ),
                  _ActionCard(
                    icon: Icons.history,
                    title: 'Visitors',
                    subtitle: 'View history',
                    color: AppTheme.warningColor,
                    onTap: () => context.push('/visitor-history'),
                  ),
                  _ActionCard(
                    icon: Icons.settings,
                    title: 'Profile',
                    subtitle: 'Settings',
                    color: AppTheme.textSecondary,
                    onTap: () => context.push('/profile'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Visitors
              const Text(
                'Recent Visitors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Consumer(builder: (context, ref, child) {
                final visitorState = ref.watch(visitorProvider);

                if (visitorState.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (visitorState.visitors.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.door_front_door_outlined,
                              size: 48, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No visitors yet',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share your QR code to get started',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: visitorState.visitors.take(5).map((visitor) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _statusColor(visitor.status).withValues(alpha: 0.1),
                          child: Icon(
                            _statusIcon(visitor.status),
                            color: _statusColor(visitor.status),
                          ),
                        ),
                        title: Text(visitor.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          _formatTime(visitor.arrivedAt),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _statusColor(visitor.status).withValues(alpha: 0.1),
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
                        onTap: () =>
                            context.push('/visitor/${visitor.id}'),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.notifications_active;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
