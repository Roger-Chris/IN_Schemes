import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/gradient_scaffold.dart';
import '../providers/app_state_provider.dart';
import '../utils/constants.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final list = provider.notifications;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.primaryText),
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: AppConstants.secondaryText.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No notifications yet', style: TextStyle(color: AppConstants.secondaryText, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final isRead = item['read'] as bool;
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: isRead ? AppConstants.surfaceColor : AppConstants.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isRead ? AppConstants.cardBorderColor : AppConstants.accentColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isRead ? AppConstants.cardBorderColor : AppConstants.accentColor.withValues(alpha: 0.15),
                      child: Icon(
                        isRead ? Icons.notifications_none : Icons.notifications_active,
                        color: isRead ? AppConstants.secondaryText : AppConstants.accentColor,
                      ),
                    ),
                    title: Text(
                      item['title'] ?? '',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        color: AppConstants.primaryText,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          item['body'] ?? '',
                          style: const TextStyle(color: AppConstants.secondaryText, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['time'] ?? '',
                          style: const TextStyle(color: AppConstants.secondaryText, fontSize: 10),
                        ),
                      ],
                    ),
                    onTap: () {
                      provider.markNotificationRead(item['id']);
                    },
                  ),
                );
              },
            ),
    );
  }
}
