import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/family_service.dart';

class InviteAcceptScreen extends ConsumerStatefulWidget {
  final String token;
  const InviteAcceptScreen({super.key, required this.token});

  @override
  ConsumerState<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends ConsumerState<InviteAcceptScreen> {
  final FamilyService _familyService = FamilyService();
  bool _loading = true;
  bool _accepting = false;
  String? _error;
  Map<String, dynamic>? _inviteInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInviteInfo());
  }

  Future<void> _loadInviteInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await _familyService.getInviteInfo(widget.token);
      if (!mounted) return;
      setState(() {
        _inviteInfo = info;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Invalid or expired invite link';
        _loading = false;
      });
    }
  }

  Future<void> _acceptInvite() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first to accept invite'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      context.go('/login');
      return;
    }

    setState(() => _accepting = true);
    try {
      await _familyService.acceptInvite(widget.token);
      await ref.read(authProvider.notifier).checkAuth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have joined the family successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept invite: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyName = (_inviteInfo?['family']?['name'] ?? 'Family').toString();
    final familyAddress = (_inviteInfo?['family']?['address'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Family Invite')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const CircularProgressIndicator()
              : _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.dangerColor, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadInviteInfo,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'You are invited to join',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          familyName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (familyAddress.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            familyAddress,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _accepting ? null : _acceptInvite,
                            child: _accepting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Accept & Join Family'),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

