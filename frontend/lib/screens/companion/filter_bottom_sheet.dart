import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> initialFilters;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedMatchScore;
  late String _selectedSchemeType;
  late String _selectedBusinessStage;
  late String _selectedSector;
  late String _selectedLocation;
  late String _selectedBeneficiary;
  late bool _womenEntrepreneursOnly;
  late bool _newlyAddedOnly;

  @override
  void initState() {
    super.initState();
    _selectedMatchScore = widget.initialFilters['matchScore'] ?? 'All';
    _selectedSchemeType = widget.initialFilters['schemeType'] ?? 'All Types';
    _selectedBusinessStage = widget.initialFilters['businessStage'] ?? 'All Stages';
    _selectedSector = widget.initialFilters['sector'] ?? 'All Sectors';
    _selectedLocation = widget.initialFilters['location'] ?? 'All Locations';
    _selectedBeneficiary = widget.initialFilters['beneficiary'] ?? 'All Beneficiaries';
    _womenEntrepreneursOnly = widget.initialFilters['womenOnly'] ?? false;
    _newlyAddedOnly = widget.initialFilters['newlyAdded'] ?? false;
  }

  void _clearAll() {
    setState(() {
      _selectedMatchScore = 'All';
      _selectedSchemeType = 'All Types';
      _selectedBusinessStage = 'All Stages';
      _selectedSector = 'All Sectors';
      _selectedLocation = 'All Locations';
      _selectedBeneficiary = 'All Beneficiaries';
      _womenEntrepreneursOnly = false;
      _newlyAddedOnly = false;
    });
  }

  void _applyFilters() {
    Navigator.of(context).pop({
      'matchScore': _selectedMatchScore,
      'schemeType': _selectedSchemeType,
      'businessStage': _selectedBusinessStage,
      'sector': _selectedSector,
      'location': _selectedLocation,
      'beneficiary': _selectedBeneficiary,
      'womenOnly': _womenEntrepreneursOnly,
      'newlyAdded': _newlyAddedOnly,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Column(
          children: [
            // 1. Header (Fixed at top)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Text(
                        "Filters",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        "Clear All",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Group 1: Match Score
                    _buildGroupTitle("Match Score"),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SelectableTextPill(
                          label: "All",
                          isSelected: _selectedMatchScore == 'All',
                          onTap: () => setState(() => _selectedMatchScore = 'All'),
                        ),
                        SelectableTextPill(
                          label: "High (75% and above)",
                          isSelected: _selectedMatchScore == 'High',
                          onTap: () => setState(() => _selectedMatchScore = 'High'),
                        ),
                        SelectableTextPill(
                          label: "Medium (50% - 74%)",
                          isSelected: _selectedMatchScore == 'Medium',
                          onTap: () => setState(() => _selectedMatchScore = 'Medium'),
                        ),
                        SelectableTextPill(
                          label: "Low (Below 50%)",
                          isSelected: _selectedMatchScore == 'Low',
                          onTap: () => setState(() => _selectedMatchScore = 'Low'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Group 2: Scheme Type
                    _buildGroupTitle("Scheme Type"),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          SelectableIconCard(
                            label: "All Types",
                            icon: Icons.all_inclusive,
                            isSelected: _selectedSchemeType == 'All Types',
                            onTap: () => setState(() => _selectedSchemeType = 'All Types'),
                          ),
                          const SizedBox(width: 8),
                          SelectableIconCard(
                            label: "Grant",
                            icon: Icons.calendar_today,
                            isSelected: _selectedSchemeType == 'Grant',
                            onTap: () => setState(() => _selectedSchemeType = 'Grant'),
                          ),
                          const SizedBox(width: 8),
                          SelectableIconCard(
                            label: "Reimbursement",
                            icon: Icons.assignment_turned_in,
                            isSelected: _selectedSchemeType == 'Reimbursement',
                            onTap: () => setState(() => _selectedSchemeType = 'Reimbursement'),
                          ),
                          const SizedBox(width: 8),
                          SelectableIconCard(
                            label: "Loan",
                            icon: Icons.monetization_on,
                            isSelected: _selectedSchemeType == 'Loan',
                            onTap: () => setState(() => _selectedSchemeType = 'Loan'),
                          ),
                          const SizedBox(width: 8),
                          SelectableIconCard(
                            label: "Equity",
                            icon: Icons.pie_chart,
                            isSelected: _selectedSchemeType == 'Equity',
                            onTap: () => setState(() => _selectedSchemeType = 'Equity'),
                          ),
                          const SizedBox(width: 8),
                          SelectableIconCard(
                            label: "Other",
                            icon: Icons.auto_awesome,
                            isSelected: _selectedSchemeType == 'Other',
                            onTap: () => setState(() => _selectedSchemeType = 'Other'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Group 3: Business Stage
                    _buildGroupTitle("Business Stage"),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SelectableTextPill(
                          label: "All Stages",
                          isSelected: _selectedBusinessStage == 'All Stages',
                          onTap: () => setState(() => _selectedBusinessStage = 'All Stages'),
                        ),
                        SelectableTextPill(
                          label: "Idea Stage",
                          isSelected: _selectedBusinessStage == 'Idea Stage',
                          onTap: () => setState(() => _selectedBusinessStage = 'Idea Stage'),
                        ),
                        SelectableTextPill(
                          label: "Early Stage",
                          isSelected: _selectedBusinessStage == 'Early Stage',
                          onTap: () => setState(() => _selectedBusinessStage = 'Early Stage'),
                        ),
                        SelectableTextPill(
                          label: "Growth Stage",
                          isSelected: _selectedBusinessStage == 'Growth Stage',
                          onTap: () => setState(() => _selectedBusinessStage = 'Growth Stage'),
                        ),
                        SelectableTextPill(
                          label: "Mature Stage",
                          isSelected: _selectedBusinessStage == 'Mature Stage',
                          onTap: () => setState(() => _selectedBusinessStage = 'Mature Stage'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Group 4, 5, 6: Dropdowns
                    _buildGroupTitle("Sector"),
                    FilterDropdownContainer(
                      value: _selectedSector,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSector = val);
                      },
                      items: const ["All Sectors", "Manufacturing", "Services", "Technology", "Agriculture", "Textile"],
                    ),
                    const SizedBox(height: 24),

                    _buildGroupTitle("Location"),
                    FilterDropdownContainer(
                      value: _selectedLocation,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLocation = val);
                      },
                      items: const ["All Locations", "Tamil Nadu", "Delhi", "Maharashtra", "Karnataka", "Uttar Pradesh"],
                    ),
                    const SizedBox(height: 24),

                    _buildGroupTitle("Target Beneficiary"),
                    FilterDropdownContainer(
                      value: _selectedBeneficiary,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBeneficiary = val);
                      },
                      items: const ["All Beneficiaries", "Women Entrepreneurs", "SC/ST", "Minorities", "General", "Ex-Servicemen"],
                    ),
                    const SizedBox(height: 24),

                    // Group 7: Other Preferences
                    _buildGroupTitle("Other Preferences"),
                    CheckboxListTile(
                      activeColor: const Color(0xFFEA580C),
                      title: Text(
                        "Schemes for Women Entrepreneurs",
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A)),
                      ),
                      value: _womenEntrepreneursOnly,
                      onChanged: (val) => setState(() => _womenEntrepreneursOnly = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      activeColor: const Color(0xFFEA580C),
                      title: Text(
                        "Newly Added Schemes Only",
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A)),
                      ),
                      value: _newlyAddedOnly,
                      onChanged: (val) => setState(() => _newlyAddedOnly = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // 3. Bottom Action Area (Fixed at bottom)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _applyFilters,
                      child: Text(
                        "Apply Filters",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

// Reusable SelectableTextPill private widget
class SelectableTextPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableTextPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

// Reusable SelectableIconCard private widget
class SelectableIconCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableIconCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable FilterDropdownContainer widget
class FilterDropdownContainer extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final List<String> items;

  const FilterDropdownContainer({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF0F172A),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
