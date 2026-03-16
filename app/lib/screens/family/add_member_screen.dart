import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/family_provider.dart';
import '../../config/theme.dart';

enum AddMethod { phone, email, invite }

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  AddMethod _selectedMethod = AddMethod.phone;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _inviteData;
  bool _isGeneratingInvite = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (_selectedMethod == AddMethod.invite) {
      // Invite flow is handled separately
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    bool success = false;
    if (_selectedMethod == AddMethod.phone) {
      String phone = _phoneController.text.trim();
      if (!phone.startsWith('+')) {
        phone = '+91$phone';
      }
      success = await ref.read(familyProvider.notifier).addMember(phone: phone);
    } else if (_selectedMethod == AddMethod.email) {
      final email = _emailController.text.trim();
      success = await ref.read(familyProvider.notifier).addMember(email: email);
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member added successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    } else {
      final error = ref.read(familyProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _generateInvite() async {
    setState(() => _isGeneratingInvite = true);
    debugPrint('[AddMemberScreen] Generating invite...');
    try {
      final invite = await ref.read(familyProvider.notifier).createInvite();
      if (invite != null) {
        debugPrint('[AddMemberScreen] Invite generated: ${invite['inviteUrl']}');
        setState(() {
          _inviteData = invite;
          _isGeneratingInvite = false;
        });
      } else {
        debugPrint('[AddMemberScreen] Failed to generate invite');
        final error = ref.read(familyProvider).error;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to generate invite'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
        setState(() => _isGeneratingInvite = false);
      }
    } catch (e) {
      debugPrint('[AddMemberScreen] Error generating invite: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      setState(() => _isGeneratingInvite = false);
    }
  }

  Future<void> _copyInviteLink() async {
    if (_inviteData?['inviteUrl'] != null) {
      await Clipboard.setData(ClipboardData(text: _inviteData!['inviteUrl']));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite link copied to clipboard!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _shareInviteLink() async {
    if (_inviteData?['inviteUrl'] != null) {
      try {
        debugPrint('[AddMemberScreen] Sharing invite link: ${_inviteData!['inviteUrl']}');
        await Share.share(
          'Join my family on Ghar! Use this link: ${_inviteData!['inviteUrl']}',
          subject: 'Family Invite - Ghar',
        );
        debugPrint('[AddMemberScreen] Share completed');
      } catch (e) {
        debugPrint('[AddMemberScreen] Error sharing: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Family Member',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to add a member to your family.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Method selector
              SegmentedButton<AddMethod>(
                segments: const [
                  ButtonSegment(
                    value: AddMethod.phone,
                    label: Text('Phone'),
                    icon: Icon(Icons.phone, size: 18),
                  ),
                  ButtonSegment(
                    value: AddMethod.email,
                    label: Text('Email'),
                    icon: Icon(Icons.email, size: 18),
                  ),
                  ButtonSegment(
                    value: AddMethod.invite,
                    label: Text('Invite'),
                    icon: Icon(Icons.link, size: 18),
                  ),
                ],
                selected: {_selectedMethod},
                onSelectionChanged: (Set<AddMethod> newSelection) {
                  setState(() {
                    _selectedMethod = newSelection.first;
                    _inviteData = null;
                  });
                },
              ),
              const SizedBox(height: 24),
              // Phone input
              if (_selectedMethod == AddMethod.phone) ...[
                const Text(
                  'Phone Number',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Enter phone number',
                    prefixText: '+91  ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a phone number';
                    }
                    if (value.trim().length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'They must have the Ghar app installed.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              // Email input
              if (_selectedMethod == AddMethod.email) ...[
                const Text(
                  'Email Address',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter email address',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an email address';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'They must have the Ghar app installed and signed in with this email.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              // Invite link/QR
              if (_selectedMethod == AddMethod.invite) ...[
                if (_inviteData == null) ...[
                  Text(
                    'Generate an invite link or QR code that can be shared with anyone. They can use it to join your family.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingInvite ? null : _generateInvite,
                      icon: _isGeneratingInvite
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_link),
                      label: const Text('Generate Invite'),
                    ),
                  ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Invite Link',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: _inviteData!['inviteUrl'] ?? '',
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              _inviteData!['inviteUrl'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _copyInviteLink,
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _shareInviteLink,
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Share'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() => _inviteData = null);
                                  },
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('New'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expires: ${_inviteData!['expiresAt'] != null ? DateTime.parse(_inviteData!['expiresAt']).toString().substring(0, 10) : 'N/A'}',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              // Add button (for phone/email)
              if (_selectedMethod != AddMethod.invite) ...[
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: familyState.isLoading ? null : _addMember,
                    child: familyState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add Member'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
