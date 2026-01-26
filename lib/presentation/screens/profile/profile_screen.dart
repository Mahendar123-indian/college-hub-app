import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Core Project Imports
import '../../../config/routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
// ✅ FIXED: Security Elevation Import
import '../../../core/security/admin_guard.dart';
// ✅ ADDED: Notification Triggers Import
import '../../../core/utils/notification_triggers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper method to get count stream from a subcollection
  Stream<int> _getCountStream(String userId, String collectionName) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 🛡️ FEATURE: Master PIN Dialog (Restored Logic)
  void _showAppPinDialog(BuildContext context) {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key_rounded, size: 40, color: Color(0xFFf5576c)),
            SizedBox(height: 10),
            Text('Master Security PIN'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your 4-digit Master PIN to unlock the Admin Dashboard.'),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 15, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "••••",
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (AdminGuard.verifyAppPin(pinController.text)) {
                Navigator.pop(context); // Close dialog
                Navigator.pushNamed(context, AppRoutes.adminDashboard);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect PIN. Please try again.'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf5576c),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text('Unlock', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.currentUser;
    final isDark = themeProvider.isDarkMode;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
                      ),
                    ),
                  ),
                  Positioned.fill(child: CustomPaint(painter: _ProfileBackgroundPainter())),
                  SafeArea(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildProfileImage(user),
                              const SizedBox(height: 16),
                              _buildProfileHeaderInfo(user),
                              const SizedBox(height: 12),
                              _buildRoleBadge(user),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            actions: [_buildAppBarSettingsAction(context)],
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildDynamicStatsRow(user, isDark),
                  const SizedBox(height: 32),

                  // 🔐 ADMIN SECTION
                  if (user.isAdmin == true) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Administration', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
                          const SizedBox(height: 12),
                          _buildPremiumCard(
                            context,
                            icon: Icons.admin_panel_settings_rounded,
                            title: 'Admin Dashboard',
                            subtitle: 'Manage app content and users',
                            gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
                            onTap: () async {
                              try {
                                // 🛡️ Step 1: Device Security (Fingerprint or Phone PIN)
                                bool isAuthenticated = await AdminGuard.authenticateAdmin();

                                if (isAuthenticated && context.mounted) {
                                  // 🛡️ Step 2: Custom App Master PIN for Double-Layer Protection
                                  _showAppPinDialog(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Verification Failed. Please use your phone PIN.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint("Admin Access Error: $e");
                              }
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  _buildAccountSection(context, isDark),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(context, themeProvider, isDark),
                  const SizedBox(height: 24),
                  _buildSupportSection(context, isDark),
                  const SizedBox(height: 24),
                  _buildLogoutSection(context, authProvider, isDark),
                  const SizedBox(height: 120), // ✅ FIXED: Added 120px bottom padding for clear visibility
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UI HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileImage(dynamic user) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 130, height: 130,
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 30, spreadRadius: 10)]),
        ),
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) ? NetworkImage(user.photoUrl!) : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? Text(user.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF667eea)))
                : null,
          ),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeaderInfo(dynamic user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5, shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)]), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, letterSpacing: 0.3), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(user.isAdmin == true ? Icons.admin_panel_settings : Icons.school, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(user.role.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildAppBarSettingsAction(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.settings_outlined, color: Colors.white)),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),
    );
  }

  Widget _buildDynamicStatsRow(dynamic user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: StreamBuilder<int>(stream: _getCountStream(user.id, 'bookmarks'), builder: (context, snapshot) {
            return _buildStatCard(context, icon: Icons.bookmark_rounded, count: snapshot.hasData ? snapshot.data.toString() : '...', label: 'Bookmarks', gradient: const [Color(0xFFfa709a), Color(0xFFfee140)], isDark: isDark);
          })),
          const SizedBox(width: 12),
          Expanded(child: StreamBuilder<int>(stream: _getCountStream(user.id, 'downloads'), builder: (context, snapshot) {
            return _buildStatCard(context, icon: Icons.download_rounded, count: snapshot.hasData ? snapshot.data.toString() : '...', label: 'Downloads', gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)], isDark: isDark);
          })),
          const SizedBox(width: 12),
          Expanded(child: StreamBuilder<int>(stream: _getCountStream(user.id, 'favorites'), builder: (context, snapshot) {
            return _buildStatCard(context, icon: Icons.favorite_rounded, count: snapshot.hasData ? snapshot.data.toString() : '...', label: 'Favorites', gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)], isDark: isDark);
          })),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          _buildModernMenuItem(context, icon: Icons.person_outline_rounded, title: 'Edit Profile', subtitle: 'Update info', iconColor: const Color(0xFF667eea), onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile), isDark: isDark),
          const SizedBox(height: 10),
          _buildModernMenuItem(context, icon: Icons.download_outlined, title: 'My Downloads', subtitle: 'View files', iconColor: const Color(0xFF4facfe), onTap: () => Navigator.pushNamed(context, AppRoutes.downloads), isDark: isDark),
          const SizedBox(height: 10),
          _buildModernMenuItem(context, icon: Icons.bookmark_border_rounded, title: 'Saved Items', subtitle: 'Bookmarks', iconColor: const Color(0xFFfa709a), onTap: () => Navigator.pushNamed(context, AppRoutes.bookmarks), isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, ThemeProvider themeProvider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferences', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          _buildToggleCard(context, icon: themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, title: 'Dark Mode', subtitle: themeProvider.isDarkMode ? 'Enabled' : 'Disabled', iconColor: const Color(0xFFFFB74D), value: themeProvider.isDarkMode, onChanged: (value) => themeProvider.toggleTheme(), isDark: isDark),
          const SizedBox(height: 10),
          _buildModernMenuItem(context, icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Configure alerts', iconColor: const Color(0xFF26C6DA), onTap: () {}, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Support', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          _buildModernMenuItem(context, icon: Icons.help_outline_rounded, title: 'Help & FAQs', subtitle: 'Get support', iconColor: const Color(0xFF7E57C2), onTap: () {}, isDark: isDark),
          const SizedBox(height: 10),
          _buildModernMenuItem(context, icon: Icons.info_outline_rounded, title: 'About App', subtitle: 'Version 1.0.0', iconColor: const Color(0xFF5C6BC0), onTap: () => _showAboutDialog(context), isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context, AuthProvider authProvider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildLogoutCard(context, onTap: () async {
        final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Logout'), content: const Text('Are you sure?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Logout'))]));
        if (confirm == true && context.mounted) {
          await authProvider.signOut();
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        }
      }, isDark: isDark),
    );
  }

  Widget _buildStatCard(BuildContext context, {required IconData icon, required String count, required String label, required List<Color> gradient, required bool isDark}) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]), child: Column(children: [Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 8), Text(count, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)]));
  }

  Widget _buildPremiumCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required List<Color> gradient, required VoidCallback onTap, required bool isDark}) {
    return Material(elevation: 4, borderRadius: BorderRadius.circular(20), shadowColor: gradient[0].withOpacity(0.3), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient), borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 28)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13))])), const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18)]))));
  }

  Widget _buildModernMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color iconColor, required VoidCallback onTap, required bool isDark}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!, width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 2))]), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]))])), Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400])]))));
  }

  Widget _buildToggleCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color iconColor, required bool value, required ValueChanged<bool> onChanged, required bool isDark}) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!, width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 2))]), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]))])), Switch(value: value, onChanged: onChanged, activeColor: iconColor)]));
  }

  Widget _buildLogoutCard(BuildContext context, {required VoidCallback onTap, required bool isDark}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.logout, color: Colors.red, size: 22), const SizedBox(width: 12), const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 17, fontWeight: FontWeight.bold))]))));
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(context: context, applicationName: 'College Hub', applicationVersion: '1.0.0', applicationIcon: const FlutterLogo());
  }
}

// Custom Painter for Background Pattern
class _ProfileBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.85), 70, paint);

    final arcPaint = Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 3;
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width * 0.1, size.height * 0.5), radius: 50), 0, 3.14, false, arcPaint);
    canvas.drawArc(Rect.fromCircle(center: Offset(size.width * 0.9, size.height * 0.7), radius: 40), 0, 3.14, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}