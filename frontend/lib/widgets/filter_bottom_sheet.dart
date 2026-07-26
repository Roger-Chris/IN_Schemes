import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Store selected sub-options for each filter category
  final Map<String, List<String>> _selectedFilters = {
    "Location": ["Central"], // Pre-selected defaults
    "Applicant": [],
    "Stage": [],
    "Benefits": [],
    "Sector": [],
    "Authority": [],
  };

  final List<Map<String, dynamic>> _filterCategories = [
    {
      "name": "Location",
      "icon": Icons.location_on_outlined,
      "iconColor": const Color(0xFF1D4ED8),
      "iconBg": const Color(0xFFEFF6FF),
      "options": ["All India", "Central", "State"],
    },
    {
      "name": "Applicant",
      "icon": Icons.person_outline,
      "iconColor": const Color(0xFFE11D48),
      "iconBg": const Color(0xFFFFE4E6),
      "options": ["Student", "Entrepreneur", "Business", "Farmer", "Women", "SHG"],
    },
    {
      "name": "Stage",
      "icon": Icons.business_center_outlined,
      "iconColor": const Color(0xFFD97706),
      "iconBg": const Color(0xFFFEF3C7),
      "options": ["Idea", "Startup", "Existing"],
    },
    {
      "name": "Benefits",
      "icon": Icons.card_giftcard_outlined,
      "iconColor": const Color(0xFF047857),
      "iconBg": const Color(0xFFECFDF5),
      "options": ["Loan", "Subsidy", "Grant", "Training"],
    },
    {
      "name": "Sector",
      "icon": Icons.bar_chart_outlined,
      "iconColor": const Color(0xFF6D28D9),
      "iconBg": const Color(0xFFF5F3FF),
      "options": ["Manufacturing", "Services", "Agriculture", "Technology", "Retail", "Others"],
    },
    {
      "name": "Authority",
      "icon": Icons.account_balance_outlined,
      "iconColor": const Color(0xFFEA580C),
      "iconBg": const Color(0xFFFFEDD5),
      "options": ["Central", "State", "SIDBI", "NABARD", "MSME"],
    },
  ];

  void _clearAll() {
    setState(() {
      for (var key in _selectedFilters.keys) {
        _selectedFilters[key]!.clear();
      }
    });
  }

  void _toggleOption(String category, String option) {
    setState(() {
      if (_selectedFilters[category]!.contains(option)) {
        _selectedFilters[category]!.remove(option);
      } else {
        _selectedFilters[category]!.add(option);
      }
    });
  }

  String _getPreviewText(String category, List<String> selections) {
    if (selections.isEmpty) {
      return "All";
    }
    return selections.join(", ");
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // 2. Drag Handle & Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter Schemes",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: _clearAll,
                  child: Text(
                    "Clear All",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Scrollable Filter Categories
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filterCategories.length,
              itemBuilder: (context, index) {
                final category = _filterCategories[index];
                final String name = category["name"];
                final List<String> selections = _selectedFilters[name]!;
                return _FilterCategoryCard(
                  name: name,
                  icon: category["icon"],
                  iconColor: category["iconColor"],
                  iconBg: category["iconBg"],
                  options: List<String>.from(category["options"]),
                  selectedOptions: selections,
                  previewText: _getPreviewText(name, selections),
                  onOptionToggled: (opt) => _toggleOption(name, opt),
                );
              },
            ),
          ),

          // 5. Bottom Action Bar
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46, // Reduced height to prevent overflows
                        child: OutlinedButton(
                          onPressed: _clearAll,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Reset",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 46, // Reduced height to prevent overflows
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, _selectedFilters);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Apply Filters",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 6. Extracted Expandable Category Card Helper
class _FilterCategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<String> options;
  final List<String> selectedOptions;
  final String previewText;
  final ValueChanged<String> onOptionToggled;

  const _FilterCategoryCard({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.options,
    required this.selectedOptions,
    required this.previewText,
    required this.onOptionToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            previewText,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF64748B),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((opt) {
                    final bool isSelected = selectedOptions.contains(opt);
                    return ChoiceChip(
                      label: Text(
                        opt,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => onOptionToggled(opt),
                      selectedColor: const Color(0xFFEFF6FF),
                      backgroundColor: Colors.white,
                      checkmarkColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
