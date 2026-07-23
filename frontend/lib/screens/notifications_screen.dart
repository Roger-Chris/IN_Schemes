import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';
import 'profile_setup_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _activeFilter = 'All';

  final List<Map<String, dynamic>> _categories = [
    {'key': 'All', 'label': 'All', 'icon': Icons.notifications_none},
    {'key': 'new_schemes', 'label': 'New Schemes', 'icon': Icons.shopping_bag_outlined},
    {'key': 'reminders', 'label': 'Reminders', 'icon': Icons.calendar_today_outlined},
    {'key': 'updates', 'label': 'Updates', 'icon': Icons.campaign_outlined},
    {'key': 'profile', 'label': 'Profile', 'icon': Icons.person_outline},
  ];

  // Helper widget to build tags
  Widget _buildTag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          color: textCol,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Filter Chips Row Builder
  Widget _buildFilterChips() {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _activeFilter == cat['key'];
          final activeBgColor = const Color(0xFFEFF6FF);
          final activeTextColor = const Color(0xFF2563EB);
          final inactiveBgColor = Colors.white;
          final inactiveTextColor = const Color(0xFF64748B);

          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = cat['key'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeBgColor : inactiveBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: GoogleFonts.inter(
                      color: isSelected ? activeTextColor : const Color(0xFF1E293B),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Section Builder Helper
  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData headerIcon,
    required Color headerIconBg,
    required Color headerIconColor,
    required List<Widget> cards,
    required VoidCallback onViewAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: headerIconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(headerIcon, color: headerIconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, size: 14, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...cards,
        const SizedBox(height: 12),
      ],
    );
  }

  // 1. New Scheme Alerts Card Widget
  Widget _buildNewSchemeCard(BuildContext context, Map<String, dynamic> item, AppProvider provider) {
    final isRead = item['read'] as bool;
    final isEducation = item['tag'] == 'Education';
    final Color iconBg = isEducation ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final Color iconCol = isEducation ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    final IconData icon = isEducation ? Icons.school : Icons.store_mall_directory_outlined;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => provider.markNotificationRead(item['id']),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconCol, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] ?? '',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['body'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTag(item['tag'] ?? '', iconBg, iconCol),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item['time'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Deadline Reminders Card Widget
  Widget _buildDeadlineCard(BuildContext context, Map<String, dynamic> item, AppProvider provider) {
    final isRead = item['read'] as bool;
    final isPostMatric = item['title'] == 'Post Matric Scholarship Scheme';
    final IconData icon = isPostMatric ? Icons.calendar_today_outlined : Icons.access_time;
    final Color iconBg = isPostMatric ? const Color(0xFFFFEBEE) : const Color(0xFFF3E5F5);
    final Color iconCol = isPostMatric ? const Color(0xFFD32F2F) : const Color(0xFF7B1FA2);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => provider.markNotificationRead(item['id']),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconCol, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['body'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Color(0xFFE11D48)),
                        const SizedBox(width: 2),
                        Text(
                          item['deadline'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFFE11D48),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '•',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10),
                        ),
                        Text(
                          item['daysLeft'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFFE11D48),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item['time'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Government Updates Card Widget
  Widget _buildGovtUpdateCard(BuildContext context, Map<String, dynamic> item, AppProvider provider) {
    final isRead = item['read'] as bool;
    final IconData icon = item['iconType'] == 'emblem' ? Icons.gavel_outlined : Icons.account_balance_outlined;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => provider.markNotificationRead(item['id']),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: const Color(0xFF0D47A1), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['body'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['time'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Profile Completion Card Widget
  Widget _buildProfileReminderCard(BuildContext context, Map<String, dynamic> item, AppProvider provider) {
    final isRead = item['read'] as bool;
    final completion = item['progress'] ?? 70;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          provider.markNotificationRead(item['id']);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E5F5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.edit_note_outlined, color: Color(0xFF7B1FA2), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['body'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Profile Completion',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: completion / 100.0,
                              backgroundColor: const Color(0xFFF3E8FF),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$completion%',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['time'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final list = provider.notifications;

    // Filtered lists for each section
    final newSchemes = list.where((n) => n['category'] == 'new_schemes').toList();
    final reminders = list.where((n) => n['category'] == 'reminders').toList();
    final updates = list.where((n) => n['category'] == 'updates').toList();
    final profileAlerts = list.where((n) => n['category'] == 'profile').toList();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: AppConstants.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.primaryText),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: AppConstants.primaryText, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter options opened'), duration: Duration(milliseconds: 500)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppConstants.primaryText, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More options opened'), duration: Duration(milliseconds: 500)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Horizontal list
          _buildFilterChips(),

          // Notifications List
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 1. New Scheme Alerts Section
                  if ((_activeFilter == 'All' || _activeFilter == 'new_schemes') && newSchemes.isNotEmpty)
                    _buildSection(
                      title: 'New Scheme Alerts',
                      subtitle: 'Stay informed about newly launched schemes',
                      headerIcon: Icons.notifications_active_outlined,
                      headerIconBg: const Color(0xFFE8F5E9),
                      headerIconColor: const Color(0xFF16A34A),
                      cards: newSchemes.map((item) => _buildNewSchemeCard(context, item, provider)).toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'new_schemes';
                        });
                      },
                    ),

                  // 2. Deadline Reminders Section
                  if ((_activeFilter == 'All' || _activeFilter == 'reminders') && reminders.isNotEmpty)
                    _buildSection(
                      title: 'Deadline Reminders',
                      subtitle: "Don't miss important application deadlines",
                      headerIcon: Icons.calendar_today_outlined,
                      headerIconBg: const Color(0xFFFFEBEE),
                      headerIconColor: const Color(0xFFD32F2F),
                      cards: reminders.map((item) => _buildDeadlineCard(context, item, provider)).toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'reminders';
                        });
                      },
                    ),

                  // 3. Government Updates Section
                  if ((_activeFilter == 'All' || _activeFilter == 'updates') && updates.isNotEmpty)
                    _buildSection(
                      title: 'Government Updates',
                      subtitle: 'Important announcements and updates',
                      headerIcon: Icons.campaign_outlined,
                      headerIconBg: const Color(0xFFEFF6FF),
                      headerIconColor: const Color(0xFF0D47A1),
                      cards: updates.map((item) => _buildGovtUpdateCard(context, item, provider)).toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'updates';
                        });
                      },
                    ),

                  // 4. Profile Completion Reminders Section
                  if ((_activeFilter == 'All' || _activeFilter == 'profile') && profileAlerts.isNotEmpty)
                    _buildSection(
                      title: 'Profile Completion Reminders',
                      subtitle: 'Complete your profile to get better recommendations',
                      headerIcon: Icons.person_outline,
                      headerIconBg: const Color(0xFFF3E5F5),
                      headerIconColor: const Color(0xFF7B1FA2),
                      cards: profileAlerts.map((item) => _buildProfileReminderCard(context, item, provider)).toList(),
                      onViewAll: () {
                        setState(() {
                          _activeFilter = 'profile';
                        });
                      },
                    ),

                  // Empty State if no notifications match filter
                  if ((_activeFilter == 'new_schemes' && newSchemes.isEmpty) ||
                      (_activeFilter == 'reminders' && reminders.isEmpty) ||
                      (_activeFilter == 'updates' && updates.isEmpty) ||
                      (_activeFilter == 'profile' && profileAlerts.isEmpty) ||
                      list.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_off_outlined, size: 60, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 16),
                            Text(
                              'No matching alerts',
                              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
