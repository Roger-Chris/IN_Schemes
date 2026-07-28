import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String category; // 'important', 'update', 'reminder'
  final DateTime timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    required this.isRead,
  });
}

class CompanionNotificationsScreen extends StatefulWidget {
  const CompanionNotificationsScreen({super.key});

  @override
  State<CompanionNotificationsScreen> createState() => _CompanionNotificationsScreenState();
}

class _CompanionNotificationsScreenState extends State<CompanionNotificationsScreen> {
  String _activeFilter = 'All'; // 'All', 'Important', 'Updates', 'Reminders'
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'New Scheme Matched! 🚀',
        description: 'Prime Minister Employment Generation Programme (PMEGP) matches 92% of your profile. Apply now to get up to 35% subsidy.',
        category: 'important',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        title: 'Application Approved! 🎉',
        description: 'Your subsidy application for the Udyam registration support scheme has been successfully approved.',
        category: 'update',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: '3',
        title: 'Udyam Renewal Reminder ⏳',
        description: 'Your Udyam Certificate renewal is due in 5 days. Click to auto-renew with Saarthi assistant.',
        category: 'reminder',
        timestamp: now.subtract(const Duration(hours: 4)),
        isRead: false,
      ),
      NotificationModel(
        id: '4',
        title: 'Saved Scheme Updated',
        description: 'SIDBI Make in India Soft Loan Fund (SMILE) interest rate reduced to 5.8% for Micro enterprises.',
        category: 'update',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        title: 'Upload Pending Documents',
        description: 'GST identification certificate is missing for verification in CGTMSE loan scheme.',
        category: 'important',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: '6',
        title: 'Security System Notification',
        description: 'New login detected from a Chrome browser on Windows 11 device.',
        category: 'reminder',
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          title: n.title,
          description: n.description,
          category: n.category,
          timestamp: n.timestamp,
          isRead: true,
        );
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read.')),
    );
  }

  List<NotificationModel> _getFilteredNotifications() {
    if (_activeFilter == 'All') return _notifications;
    final catLower = _activeFilter.substring(0, _activeFilter.length - 1).toLowerCase().trim();
    // 'important' -> 'important', 'updates' -> 'update', 'reminders' -> 'reminder'
    String targetCat = 'important';
    if (catLower.startsWith('update')) {
      targetCat = 'update';
    } else if (catLower.startsWith('reminder')) {
      targetCat = 'reminder';
    }
    return _notifications.where((n) => n.category == targetCat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final rogerName = provider.profile.name.isNotEmpty 
        ? provider.profile.name.split(' ').first 
        : 'Roger';

    final filteredList = _getFilteredNotifications();
    final now = DateTime.now();

    // Grouping
    final todayList = filteredList.where((n) {
      final diff = now.difference(n.timestamp).inDays;
      return diff == 0 && n.timestamp.day == now.day;
    }).toList();

    final earlierList = filteredList.where((n) {
      final diff = now.difference(n.timestamp).inDays;
      return diff > 0 || n.timestamp.day != now.day;
    }).toList();

    // Count categories
    final importantCount = _notifications.where((n) => n.category == 'important').length;
    final updatesCount = _notifications.where((n) => n.category == 'update').length;
    final remindersCount = _notifications.where((n) => n.category == 'reminder').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 18),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                icon: const Icon(Icons.settings, color: Color(0xFF0F172A), size: 18),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Saarthi Greeting Banner (Top)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/saarthi_expressions/01_happy.png',
                            width: 50,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.support_agent,
                              size: 40,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hi $rogerName! ✨",
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "Here are the latest updates and important information for you.",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Soundwave graphic mimic
                          Row(
                            children: List.generate(4, (index) {
                              final double height = [6, 16, 12, 4][index].toDouble();
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 2,
                                height: height,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEA580C),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    // Filter Pills Horizontal Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildFilterPill("All (${_notifications.length})", null),
                          const SizedBox(width: 8),
                          _buildFilterPill("Important ($importantCount)", const Color(0xFFF97316)),
                          const SizedBox(width: 8),
                          _buildFilterPill("Updates ($updatesCount)", const Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          _buildFilterPill("Reminders ($remindersCount)", const Color(0xFF8B5CF6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Today Section List
                    if (todayList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFEA580C),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _markAllAsRead,
                              icon: const Icon(Icons.check, size: 14),
                              label: Text(
                                "Mark all as read",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: todayList.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) => NotificationTile(model: todayList[index]),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Earlier Section List
                    if (earlierList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Earlier",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: earlierList.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) => NotificationTile(model: earlierList[index]),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Saarthi Footer Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/saarthi_expressions/01_happy.png',
                            width: 44,
                            height: 52,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.support_agent,
                              size: 34,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "I'll keep you updated with important alerts and recommendations!",
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF7C2D12),
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Soundwave graphic mimic
                          Row(
                            children: List.generate(4, (index) {
                              final double height = [4, 12, 16, 6][index].toDouble();
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 2,
                                height: height,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEA580C),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, Color? dotColor) {
    final bool isSelected = (label.startsWith("All") && _activeFilter == 'All') ||
        (label.startsWith("Important") && _activeFilter == 'Important') ||
        (label.startsWith("Updates") && _activeFilter == 'Updates') ||
        (label.startsWith("Reminders") && _activeFilter == 'Reminders');

    final String cleanFilter = label.split(' ').first;

    return GestureDetector(
      onTap: () => setState(() => _activeFilter = cleanFilter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEA580C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (dotColor != null) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Reusable stateless NotificationTile Widget
class NotificationTile extends StatelessWidget {
  final NotificationModel model;

  const NotificationTile({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    Color categoryColor = const Color(0xFFEA580C);
    Color categoryBg = const Color(0xFFFFF7ED);
    IconData categoryIcon = Icons.notifications_none;

    if (model.category == 'update') {
      categoryColor = const Color(0xFF3B82F6);
      categoryBg = const Color(0xFFEFF6FF);
      categoryIcon = Icons.update;
    } else if (model.category == 'reminder') {
      categoryColor = const Color(0xFF8B5CF6);
      categoryBg = const Color(0xFFF5F3FF);
      categoryIcon = Icons.hourglass_empty;
    } else if (model.category == 'important') {
      categoryColor = const Color(0xFFEA580C);
      categoryBg = const Color(0xFFFFF7ED);
      categoryIcon = Icons.warning_amber_rounded;
    }

    final String timeStr = model.timestamp.difference(DateTime.now()).inDays.abs() > 0
        ? "Yesterday"
        : "${model.timestamp.hour.toString().padLeft(2, '0')}:${model.timestamp.minute.toString().padLeft(2, '0')} ${model.timestamp.hour >= 12 ? 'PM' : 'AM'}";

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unread indicator dot
          if (!model.isRead) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14.0, right: 8.0),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 14),
          ],

          // Leading pastel icon container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: categoryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  model.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Trailing time / chevron block
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Icon(Icons.chevron_right, color: Color(0xFFEA580C), size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
