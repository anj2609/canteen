import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/owner_provider.dart';
import '../../launch_screen.dart';
import '../settings/owner_canteen_settings_view.dart';
import '../tabs/analytics_view.dart';

class OwnerProfileView extends ConsumerStatefulWidget {
  const OwnerProfileView({super.key});

  @override
  ConsumerState<OwnerProfileView> createState() => _OwnerProfileViewState();
}

class _OwnerProfileViewState extends ConsumerState<OwnerProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ownerState = ref.read(ownerProvider);
      if (ownerState.myCanteens.isEmpty && !ownerState.isLoading) {
        ref.read(ownerProvider.notifier).fetchMyCanteens();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final ownerState = ref.watch(ownerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(
                        color: const Color(0xFFF62F56),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?.name ?? 'Owner',
                    style: GoogleFonts.urbanist(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? 'admin@bunkbite.com',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1AF62F56),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ADMIN',
                      style: GoogleFonts.urbanist(
                        color: const Color(0xFFF62F56),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Menu Options
            _buildMenuOption(
              context,
              icon: Icons.store,
              title: 'Canteen Settings',
              onTap: () {
                final selectedCanteen = ownerState.selectedCanteen;
                if (selectedCanteen != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OwnerCanteenSettingsView(canteen: selectedCanteen),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a canteen first'),
                    ),
                  );
                }
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.bar_chart,
              title: 'Analytics',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsView()),
                );
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.people_outline,
              title: 'Manage Staff',
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Coming Soon')));
              },
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            _buildMenuOption(
              context,
              icon: Icons.logout,
              title: 'Logout',
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LaunchScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black,
    Color iconColor = Colors.black,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
