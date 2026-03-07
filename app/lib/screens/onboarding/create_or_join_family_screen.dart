import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../config/theme.dart';

class CreateOrJoinFamilyScreen extends ConsumerStatefulWidget {
  const CreateOrJoinFamilyScreen({super.key});

  @override
  ConsumerState<CreateOrJoinFamilyScreen> createState() =>
      _CreateOrJoinFamilyScreenState();
}

class _CreateOrJoinFamilyScreenState
    extends ConsumerState<CreateOrJoinFamilyScreen> {
  final _nameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _showCreateForm = false;

  @override
  void dispose() {
    _nameController.dispose();
    _familyNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) return;
    await ref
        .read(authProvider.notifier)
        .updateProfile(name: _nameController.text.trim());
  }

  Future<void> _createFamily() async {
    if (_familyNameController.text.trim().isEmpty) return;

    // Update name first if needed
    final user = ref.read(authProvider).user;
    if (user != null && user.name.isEmpty && _nameController.text.isNotEmpty) {
      await _updateName();
    }

    final familyId = await ref.read(familyProvider.notifier).createFamily(
          _familyNameController.text.trim(),
          _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
        );

    if (!mounted) return;
    if (familyId != null) {
      // Refresh auth state
      await ref.read(authProvider.notifier).checkAuth();
      if (!mounted) return;
      context.go('/home');
    } else {
      final error = ref.read(familyProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error), backgroundColor: AppTheme.dangerColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);
    final user = authState.user;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Text('🏠', style: TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Set Up Your Home',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Create a family or wait for an invite',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Name input if needed
              if (user != null && user.name.isEmpty) ...[
                const Text('Your Name',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(hintText: 'Enter your name'),
                ),
                const SizedBox(height: 24),
              ],

              if (!_showCreateForm) ...[
                // Create Family Button
                Card(
                  child: InkWell(
                    onTap: () => setState(() => _showCreateForm = true),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.add_home,
                              size: 48, color: AppTheme.primaryColor),
                          const SizedBox(height: 12),
                          const Text(
                            'Create a Family',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set up your home and invite members',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Wait for invite
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.hourglass_top,
                            size: 48, color: AppTheme.warningColor),
                        const SizedBox(height: 12),
                        const Text(
                          'Wait for Invite',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ask your family admin to add your phone number',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (user?.phone != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user!.phone!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Create Family Form
              if (_showCreateForm) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Create Your Family',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Family Name',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _familyNameController,
                          decoration: const InputDecoration(
                              hintText: 'e.g., The Sharma Family'),
                        ),
                        const SizedBox(height: 16),
                        const Text('Address (optional)',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                              hintText: 'Your home address'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                familyState.isLoading ? null : _createFamily,
                            child: familyState.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Create Family'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showCreateForm = false),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
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
