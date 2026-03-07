import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../config/theme.dart';

class ManageMembersScreen extends ConsumerWidget {
  const ManageMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => context.push('/add-member'),
            ),
        ],
      ),
      body: familyState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : familyState.members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined,
                          size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'No members yet',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 18,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/add-member'),
                          child: const Text('Add a member'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: familyState.members.length,
                  itemBuilder: (context, index) {
                    final member = familyState.members[index];
                    final isMe = member.id == authState.user?.id;
                    final isMemberAdmin = member.role == 'admin';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          backgroundImage: member.avatarUrl != null
                              ? NetworkImage(member.avatarUrl!)
                              : null,
                          child: member.avatarUrl == null
                              ? Text(
                                  member.name.isNotEmpty
                                      ? member.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name
                                    : member.phone ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (isMe)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          isMemberAdmin ? '👑 Admin' : '👤 Member',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: isAdmin && !isMe && !isMemberAdmin
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: AppTheme.dangerColor),
                                onPressed: () =>
                                    _confirmRemove(context, ref, member.id, member.name),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmRemove(
      BuildContext context, WidgetRef ref, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
            'Are you sure you want to remove ${name.isNotEmpty ? name : "this member"} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(familyProvider.notifier).removeMember(userId);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
