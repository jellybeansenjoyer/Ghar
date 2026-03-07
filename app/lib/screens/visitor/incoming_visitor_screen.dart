import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../providers/visitor_provider.dart';
import '../../core/network/socket_service.dart';
import '../../services/notification_service.dart';
import '../../config/theme.dart';

class IncomingVisitorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> visitorData;

  const IncomingVisitorScreen({super.key, required this.visitorData});

  @override
  ConsumerState<IncomingVisitorScreen> createState() =>
      _IncomingVisitorScreenState();
}

class _IncomingVisitorScreenState extends ConsumerState<IncomingVisitorScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bellController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _vibrationTimer;
  bool _responded = false;

  String get visitorName {
    final name = widget.visitorData['visitorName'] ?? widget.visitorData['name'];
    return (name is String && name.isNotEmpty) ? name : 'Visitor';
  }
  String get visitorId => (widget.visitorData['visitorId'] as String?) ?? '';
  String? get photoUrl => widget.visitorData['photoUrl'] as String?;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _startRinging();
    _listenForResponse();
  }

  void _startRinging() {
    // Start vibration pattern
    _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if ((await Vibration.hasVibrator()) == true) {
        Vibration.vibrate(duration: 500, amplitude: 255);
      }
    });

    // Play ringtone (using system default or bundled sound)
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.play(AssetSource('sounds/doorbell.mp3')).catchError((_) {
      // If no custom sound, that's okay
    });
  }

  void _stopRinging() {
    _vibrationTimer?.cancel();
    Vibration.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    NotificationService.cancelNotification(visitorId);
  }

  void _listenForResponse() {
    SocketService.instance.onVisitorResponded((data) {
      if (data['visitorId'] == visitorId && mounted && !_responded) {
        _responded = true;
        _stopRinging();
        context.pop();
      }
    });
  }

  Future<void> _respond(String action) async {
    if (_responded) return;
    _responded = true;
    _stopRinging();

    await ref.read(visitorProvider.notifier).respondToVisitor(visitorId, action);

    if (!mounted) return;
    if (action == 'accept') {
      context.pop();
      context.push('/chat/$visitorId', extra: visitorName);
    } else {
      context.pop();
    }
  }

  @override
  void dispose() {
    _stopRinging();
    _pulseController.dispose();
    _bellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Pulsating ring animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse rings
                      for (int i = 0; i < 3; i++)
                        Transform.scale(
                          scale: 1 +
                              (_pulseController.value + i * 0.33) % 1.0 * 0.5,
                          child: Opacity(
                            opacity:
                                1 - ((_pulseController.value + i * 0.33) % 1.0),
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Visitor photo
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: photoUrl != null && photoUrl!.isNotEmpty
                              ? Image.network(
                                  photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _defaultAvatar(),
                                )
                              : _defaultAvatar(),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Bell animation
              AnimatedBuilder(
                animation: _bellController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: (_bellController.value - 0.5) * 0.5,
                    child: const Text(
                      '🔔',
                      style: TextStyle(fontSize: 40),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Visitor name
              Text(
                visitorName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'is at your door',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),

              const Spacer(),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject
                  _ActionButton(
                    icon: Icons.close,
                    label: 'Reject',
                    color: AppTheme.dangerColor,
                    onTap: () => _respond('reject'),
                  ),
                  // Chat
                  _ActionButton(
                    icon: Icons.chat,
                    label: 'Chat',
                    color: AppTheme.warningColor,
                    onTap: () {
                      _stopRinging();
                      context.pop();
                      context.push('/chat/$visitorId', extra: visitorName);
                    },
                  ),
                  // Accept
                  _ActionButton(
                    icon: Icons.check,
                    label: 'Accept',
                    color: AppTheme.successColor,
                    onTap: () => _respond('accept'),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppTheme.primaryLight,
      child: Center(
        child: Text(
          visitorName.isNotEmpty ? visitorName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
