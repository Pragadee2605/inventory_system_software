import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory_system_software/core/database/database.dart';
import 'package:inventory_system_software/features/auth/domain/models/auth_user.dart';
import 'package:inventory_system_software/features/auth/presentation/providers/auth_provider.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  String _selectedRoleFilter = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage staff accounts, assign roles, and control access permissions.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showAddUserDialog(context),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add New User'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Filter & Search Controls Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search by name, username, or email...',
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedRoleFilter,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(10),
                      items: const [
                        DropdownMenuItem(value: 'ALL', child: Text('All Roles')),
                        DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                        DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                        DropdownMenuItem(value: 'STAFF', child: Text('Staff')),
                        DropdownMenuItem(value: 'VIEWER', child: Text('Viewer')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRoleFilter = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Users Data List
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  final filtered = users.where((u) {
                    final query = _searchController.text.trim().toLowerCase();
                    final matchesSearch = query.isEmpty ||
                        u.fullName.toLowerCase().contains(query) ||
                        u.username.toLowerCase().contains(query) ||
                        (u.email ?? '').toLowerCase().contains(query);

                    final matchesRole = _selectedRoleFilter == 'ALL' ||
                        u.roleName.toUpperCase() == _selectedRoleFilter;

                    return matchesSearch && matchesRole;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Card(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_rounded, size: 48, color: theme.dividerColor),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching user accounts found.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        final isActive = user.status == UserStatus.active;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? const Color(0xFFEEF2FF)
                                : const Color(0xFFF1F5F9),
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '@${user.username}',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              _buildRoleChip(user.roleName),
                              const SizedBox(width: 8),
                              _buildStatusChip(user.status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Email: ${user.email ?? 'N/A'} | Phone: ${user.phone ?? 'N/A'}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit User',
                                onPressed: () => _showEditUserDialog(context, user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.lock_reset_rounded, size: 20),
                                tooltip: 'Reset Password',
                                onPressed: () => _showResetPasswordDialog(context, user),
                              ),
                              IconButton(
                                icon: Icon(
                                  isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                  size: 20,
                                  color: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                ),
                                tooltip: isActive ? 'Disable Account' : 'Enable Account',
                                onPressed: () => _toggleUserStatus(user),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading users: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toUpperCase()) {
      case 'ADMIN':
        color = const Color(0xFF4F46E5);
        break;
      case 'MANAGER':
        color = const Color(0xFF0284C7);
        break;
      case 'STAFF':
        color = const Color(0xFFD97706);
        break;
      default:
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildStatusChip(UserStatus status) {
    final isActive = status == UserStatus.active;
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'DISABLED',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'STAFF';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Staff User Account'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Initial Password *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Access Role'),
                  items: const [
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrator')),
                    DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                    DropdownMenuItem(value: 'STAFF', child: Text('Staff')),
                    DropdownMenuItem(value: 'VIEWER', child: Text('Viewer')),
                  ],
                  onChanged: (val) {
                    if (val != null) role = val;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  usernameCtrl.text.trim().isEmpty ||
                  passwordCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              try {
                await ref.read(userListProvider.notifier).createUser(
                      username: usernameCtrl.text.trim(),
                      fullName: nameCtrl.text.trim(),
                      password: passwordCtrl.text,
                      roleName: role,
                      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create user: $e')),
                  );
                }
              }
            },
            child: const Text('Create User'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, AuthUser user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    String role = user.roleName.toUpperCase();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User: @${user.username}'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: ['ADMIN', 'MANAGER', 'STAFF', 'VIEWER'].contains(role) ? role : 'STAFF',
                decoration: const InputDecoration(labelText: 'Access Role'),
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Administrator')),
                  DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                  DropdownMenuItem(value: 'STAFF', child: Text('Staff')),
                  DropdownMenuItem(value: 'VIEWER', child: Text('Viewer')),
                ],
                onChanged: (val) {
                  if (val != null) role = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref.read(userListProvider.notifier).updateUser(
                      id: user.id,
                      fullName: nameCtrl.text.trim(),
                      roleName: role,
                      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update user: $e')),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AuthUser user) {
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for @${user.username}'),
        content: TextField(
          controller: passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password (min 6 characters)'),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (passwordCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }

              try {
                await ref.read(userListProvider.notifier).changePassword(user.id, passwordCtrl.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to reset password: $e')),
                  );
                }
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(AuthUser user) async {
    final isActive = user.status == UserStatus.active;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isActive ? "Disable" : "Enable"} Account'),
        content: Text(
          'Are you sure you want to ${isActive ? "disable" : "enable"} access for @${user.username}?',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            ),
            child: Text(isActive ? 'Disable' : 'Enable'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(userListProvider.notifier).toggleUserStatus(user.id, user.status);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $e')),
          );
        }
      }
    }
  }
}
