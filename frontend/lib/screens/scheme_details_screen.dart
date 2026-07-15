import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/custom_button.dart';
import '../providers/app_state_provider.dart';
import '../models/scheme_model.dart';
import '../utils/constants.dart';
import '../engine/recommendation_engine.dart';

class SchemeDetailsScreen extends StatefulWidget {
  final Scheme scheme;

  const SchemeDetailsScreen({
    super.key,
    required this.scheme,
  });

  @override
  State<SchemeDetailsScreen> createState() => _SchemeDetailsScreenState();
}

class _SchemeDetailsScreenState extends State<SchemeDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDocumentHelpDialog(BuildContext context, String docName, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppConstants.cardBorderColor)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: AppConstants.accentColor),
              SizedBox(width: 10),
              Text('Document Assistance', style: TextStyle(color: AppConstants.primaryText, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to be redirected to the official government portal to apply for your $docName.',
                style: const TextStyle(color: AppConstants.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  url,
                  style: const TextStyle(color: AppConstants.secondaryColor, fontSize: 12, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppConstants.secondaryText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                // In a simulated or actual environment, we notify that redirect has occurred.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Redirecting to official portal for $docName...'),
                    backgroundColor: AppConstants.successColor,
                  ),
                );
              },
              child: const Text('Open Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final evaluation = provider.recommendedSchemes.firstWhere((e) => e.key.id == widget.scheme.id).value;
    final isBookmarked = provider.bookmarkedIds.contains(widget.scheme.id);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Scheme Details', style: TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.primaryText),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppConstants.accentColor : AppConstants.primaryText,
            ),
            onPressed: () => provider.toggleBookmark(widget.scheme.id),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppConstants.primaryText),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scheme link copied to clipboard!'),
                  backgroundColor: AppConstants.successColor,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scheme Header Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.cardBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.scheme.category.toUpperCase(),
                      style: const TextStyle(color: AppConstants.accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: evaluation.percentage >= 80 ? AppConstants.successColor.withValues(alpha: 0.15) : AppConstants.warningColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${evaluation.percentage}% Match',
                        style: TextStyle(
                          color: evaluation.percentage >= 80 ? AppConstants.successColor : AppConstants.warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.scheme.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.primaryText),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.scheme.sponsoringBody,
                  style: const TextStyle(color: AppConstants.secondaryText, fontSize: 13),
                ),
              ],
            ),
          ),
          
          // Tab bar headers
          TabBar(
            controller: _tabController,
            indicatorColor: AppConstants.primaryColor,
            labelColor: AppConstants.primaryColor,
            unselectedLabelColor: AppConstants.secondaryText,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Eligibility'),
              Tab(text: 'How to Apply'),
            ],
          ),
          
          // Tab bar content views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(evaluation),
                _buildEligibilityTab(evaluation, context),
                _buildApplyTab(),
              ],
            ),
          ),
          
          // Apply Button Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppConstants.surfaceColor,
              border: Border(top: BorderSide(color: AppConstants.cardBorderColor)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Apply Now',
                icon: Icons.launch,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening official portal: ${widget.scheme.officialWebsite}'),
                      backgroundColor: AppConstants.primaryColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // OVERVIEW TAB
  Widget _buildOverviewTab(RecommendationResult evaluation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match explanation box
          if (evaluation.matchingReasons.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.secondaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.secondaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.thumb_up_alt_outlined, color: AppConstants.secondaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Why you are a match:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryText, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...evaluation.matchingReasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppConstants.secondaryColor, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(reason, style: const TextStyle(color: AppConstants.primaryText, fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          const Text('Scheme Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryText)),
          const SizedBox(height: 8),
          Text(widget.scheme.overview, style: const TextStyle(color: AppConstants.secondaryText, fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          
          const Text('Benefits & Financial Subsidies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryText)),
          const SizedBox(height: 8),
          Card(
            color: AppConstants.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppConstants.cardBorderColor)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.currency_rupee, color: AppConstants.accentColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.scheme.benefits,
                      style: const TextStyle(color: AppConstants.primaryText, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ELIGIBILITY TAB
  Widget _buildEligibilityTab(RecommendationResult evaluation, BuildContext context) {
    // Separate documents
    final requiredDocs = widget.scheme.requiredDocuments;
    final missingDocs = evaluation.missingDocuments;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Eligibility Criteria list
          const Text('Eligibility Criteria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryText)),
          const SizedBox(height: 10),
          Column(
            children: widget.scheme.eligibilityCriteria.map((criterion) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, color: AppConstants.successColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        criterion,
                        style: const TextStyle(color: AppConstants.secondaryText, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // 2. Required Documents and checklists
          const Text('Required Documents Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryText)),
          const SizedBox(height: 10),
          
          Column(
            children: requiredDocs.map((doc) {
              final isMissing = missingDocs.contains(doc);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMissing ? AppConstants.warningColor.withValues(alpha: 0.15) : AppConstants.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isMissing ? AppConstants.warningColor.withValues(alpha: 0.3) : AppConstants.successColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isMissing ? Icons.warning_amber_rounded : Icons.check_circle,
                      color: isMissing ? AppConstants.warningColor : AppConstants.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc,
                            style: const TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            isMissing ? 'Missing from profile' : 'Available',
                            style: TextStyle(
                              color: isMissing ? AppConstants.warningColor : AppConstants.successColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Missing document assistance helper button
                    if (isMissing)
                      TextButton(
                        onPressed: () {
                          final url = AppConstants.documentLinks[doc] ?? 'https://www.india.gov.in/';
                          _showDocumentHelpDialog(context, doc, url);
                        },
                        child: const Text(
                          'Get Document',
                          style: TextStyle(color: AppConstants.secondaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // HOW TO APPLY TAB
  Widget _buildApplyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Application Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryText)),
          const SizedBox(height: 12),
          
          // Timeline list of steps
          Column(
            children: List.generate(widget.scheme.applicationProcess.length, (index) {
              final step = widget.scheme.applicationProcess[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step number circle
                    CircleAvatar(
                      backgroundColor: AppConstants.accentColor,
                      radius: 12,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Step ${index + 1}',
                            style: const TextStyle(color: AppConstants.secondaryText, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step,
                            style: const TextStyle(color: AppConstants.primaryText, fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          
          const Divider(color: AppConstants.cardBorderColor),
          const SizedBox(height: 12),
          
          // FAQs Section
          if (widget.scheme.faqs.isNotEmpty) ...[
            const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryText)),
            const SizedBox(height: 12),
            ...widget.scheme.faqs.map((faq) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.cardBorderColor),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      faq['question'] ?? '',
                      style: const TextStyle(color: AppConstants.primaryText, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    shape: const Border(),
                    iconColor: AppConstants.accentColor,
                    collapsedIconColor: AppConstants.secondaryText,
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Text(
                        faq['answer'] ?? '',
                        style: const TextStyle(color: AppConstants.secondaryText, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
