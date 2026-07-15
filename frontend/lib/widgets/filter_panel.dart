import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state_provider.dart';

class FilterPanel extends StatefulWidget {
  const FilterPanel({super.key});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  // State variables for all filters in the mockup
  late String _state;
  late String _district;
  late String _ministry;
  late String _department;
  late String _category;
  
  late String _income;
  late String _gender;
  late String _age;
  late String _community;
  late String _occupation;
  late String _education;
  late bool _firstGen;
  late String _disability;
  
  late String _schemeStatus;
  late String _onlineOffline;
  late String _schemeType;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // Initialize state from existing provider filters or defaults
    _state = provider.filters['state'] ?? 'All';
    _district = provider.filters['district'] ?? 'All';
    _ministry = provider.filters['ministry'] ?? 'All';
    _department = provider.filters['department'] ?? 'All';
    _category = provider.filters['category'] ?? 'All';
    
    _income = provider.filters['income'] ?? 'All';
    _gender = provider.filters['gender'] ?? 'All';
    _age = provider.filters['age'] ?? 'All';
    _community = provider.filters['community'] ?? 'All';
    _occupation = provider.filters['occupation'] ?? 'All';
    _education = provider.filters['education'] ?? 'All';
    _firstGen = provider.filters['firstGen'] == true;
    _disability = provider.filters['disability'] ?? 'All';
    
    _schemeStatus = provider.filters['schemeStatus'] ?? 'All';
    _onlineOffline = provider.filters['onlineOffline'] ?? 'All';
    _schemeType = provider.filters['schemeType'] ?? 'All';
  }

  void _applyFilters() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.updateFilter('state', _state);
    provider.updateFilter('district', _district);
    provider.updateFilter('ministry', _ministry);
    provider.updateFilter('department', _department);
    provider.updateFilter('category', _category);
    
    provider.updateFilter('income', _income);
    provider.updateFilter('gender', _gender);
    provider.updateFilter('age', _age);
    provider.updateFilter('community', _community);
    provider.updateFilter('occupation', _occupation);
    provider.updateFilter('education', _education);
    provider.updateFilter('firstGen', _firstGen);
    provider.updateFilter('disability', _disability);
    
    provider.updateFilter('schemeStatus', _schemeStatus);
    provider.updateFilter('onlineOffline', _onlineOffline);
    provider.updateFilter('schemeType', _schemeType);
    
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _state = 'All';
      _district = 'All';
      _ministry = 'All';
      _department = 'All';
      _category = 'All';
      
      _income = 'All';
      _gender = 'All';
      _age = 'All';
      _community = 'All';
      _occupation = 'All';
      _education = 'All';
      _firstGen = false;
      _disability = 'All';
      
      _schemeStatus = 'All';
      _onlineOffline = 'All';
      _schemeType = 'All';
    });
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_state != 'All') count++;
    if (_district != 'All') count++;
    if (_ministry != 'All') count++;
    if (_department != 'All') count++;
    if (_category != 'All') count++;
    
    if (_income != 'All') count++;
    if (_gender != 'All') count++;
    if (_age != 'All') count++;
    if (_community != 'All') count++;
    if (_occupation != 'All') count++;
    if (_education != 'All') count++;
    if (_firstGen) count++;
    if (_disability != 'All') count++;
    
    if (_schemeStatus != 'All') count++;
    if (_onlineOffline != 'All') count++;
    if (_schemeType != 'All') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _getActiveFilterCount();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Off-white/slate 50 background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Schemes',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: _resetFilters,
                  child: Row(
                    children: [
                      Text(
                        'Clear All',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.refresh,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Filter Form Fields
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Location Section
                  _buildSectionHeader('Location'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFF2563EB),
                          iconBgColor: const Color(0xFFEFF6FF),
                          label: 'State',
                          value: _state,
                          items: ['All', 'Tamil Nadu', 'Karnataka', 'Kerala', 'Maharashtra', 'Delhi'],
                          onChanged: (val) => setState(() => _state = val ?? 'All'),
                        ),
                        const SizedBox(width: 10),
                        _buildDropdownCell(
                          icon: Icons.apartment_outlined,
                          iconColor: const Color(0xFF2563EB),
                          iconBgColor: const Color(0xFFEFF6FF),
                          label: 'District',
                          value: _district,
                          items: ['All', 'Chennai', 'Bangalore', 'Cochin', 'Mumbai', 'New Delhi'],
                          onChanged: (val) => setState(() => _district = val ?? 'All'),
                        ),
                      ],
                    ),
                  ),

                  // 2. Organization Section
                  _buildSectionHeader('Organization'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.account_balance_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          iconBgColor: const Color(0xFFF5F3FF),
                          label: 'Ministry',
                          value: _ministry,
                          items: ['All', 'Ministry of MSME', 'Ministry of Agriculture', 'Ministry of Finance', 'Ministry of Education'],
                          onChanged: (val) => setState(() => _ministry = val ?? 'All'),
                        ),
                        const SizedBox(width: 10),
                        _buildDropdownCell(
                          icon: Icons.folder_open_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          iconBgColor: const Color(0xFFF5F3FF),
                          label: 'Department',
                          value: _department,
                          items: ['All', 'Dept of MSME Development', 'Dept of Agriculture Cooperation', 'Dept of Higher Education'],
                          onChanged: (val) => setState(() => _department = val ?? 'All'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.grid_view_outlined,
                          iconColor: const Color(0xFF16A34A),
                          iconBgColor: const Color(0xFFF0FDF4),
                          label: 'Category',
                          value: _category,
                          items: ['All', 'Business & MSME', 'Startup', 'Finance', 'Women & Child Welfare', 'Artisan'],
                          onChanged: (val) => setState(() => _category = val ?? 'All'),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: SizedBox()), // Push to left, take exactly half width
                      ],
                    ),
                  ),

                  // 3. Personal Details Section
                  _buildSectionHeader('Personal Details'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.wallet_outlined,
                          iconColor: const Color(0xFFEA580C),
                          iconBgColor: const Color(0xFFFFF7ED),
                          label: 'Annual Income',
                          value: _income,
                          items: ['All', 'Under ₹1 Lakh', 'Under ₹5 Lakhs', 'Under ₹10 Lakhs', 'Under ₹50 Lakhs'],
                          onChanged: (val) => setState(() => _income = val ?? 'All'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFDB2777),
                          iconBgColor: const Color(0xFFFDF2F8),
                          label: 'Gender',
                          value: _gender,
                          items: ['All', 'Female', 'Male', 'Transgender'],
                          onChanged: (val) => setState(() => _gender = val ?? 'All'),
                        ),
                        const SizedBox(width: 10),
                        _buildDropdownCell(
                          icon: Icons.calendar_month_outlined,
                          iconColor: const Color(0xFF0D9488),
                          iconBgColor: const Color(0xFFF0FDFA),
                          label: 'Age',
                          value: _age,
                          items: ['All', 'Under 18', '18 - 35', '36 - 60', 'Above 60'],
                          onChanged: (val) => setState(() => _age = val ?? 'All'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.people_outline,
                          iconColor: const Color(0xFF7C3AED),
                          iconBgColor: const Color(0xFFF5F3FF),
                          label: 'Community',
                          value: _community,
                          items: ['All', 'General', 'OBC', 'EWS', 'SC', 'ST'],
                          onChanged: (val) => setState(() => _community = val ?? 'All'),
                        ),
                        const SizedBox(width: 10),
                        _buildDropdownCell(
                          icon: Icons.business_center_outlined,
                          iconColor: const Color(0xFF2563EB),
                          iconBgColor: const Color(0xFFEFF6FF),
                          label: 'Occupation',
                          value: _occupation,
                          items: ['All', 'Unemployed', 'Student', 'Farmer', 'Self Employed', 'Salaried'],
                          onChanged: (val) => setState(() => _occupation = val ?? 'All'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.school_outlined,
                          iconColor: const Color(0xFF16A34A),
                          iconBgColor: const Color(0xFFF0FDF4),
                          label: 'Education',
                          value: _education,
                          items: ['All', 'Under 10th', '12th Pass', 'Graduate', 'Post Graduate'],
                          onChanged: (val) => setState(() => _education = val ?? 'All'),
                        ),
                        const SizedBox(width: 10),
                        _buildSwitchCell(
                          icon: Icons.workspace_premium_outlined,
                          iconColor: const Color(0xFFEA580C),
                          iconBgColor: const Color(0xFFFFF7ED),
                          label: 'First Generation Graduate',
                          value: _firstGen,
                          onChanged: (val) => setState(() => _firstGen = val),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.accessible_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          iconBgColor: const Color(0xFFF5F3FF),
                          label: 'Disability',
                          value: _disability,
                          items: ['All', 'None', 'Locomotor', 'Visual', 'Hearing', 'Other'],
                          onChanged: (val) => setState(() => _disability = val ?? 'All'),
                        ),
                      ],
                    ),
                  ),
                  // 4. Scheme Preferences Section
                  _buildSectionHeader('Scheme Preferences'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.check_circle_outline,
                          iconColor: const Color(0xFF2563EB),
                          iconBgColor: const Color(0xFFEFF6FF),
                          label: 'Scheme Status',
                          value: _schemeStatus,
                          items: ['All', 'Active', 'Closed'],
                          onChanged: (val) => setState(() => _schemeStatus = val ?? 'All'),
                        ),
                        const SizedBox(width: 10),
                        _buildDropdownCell(
                          icon: Icons.language_outlined,
                          iconColor: const Color(0xFF16A34A),
                          iconBgColor: const Color(0xFFF0FDF4),
                          label: 'Online / Offline',
                          value: _onlineOffline,
                          items: ['All', 'Online Application', 'Offline Application'],
                          onChanged: (val) => setState(() => _onlineOffline = val ?? 'All'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildDropdownCell(
                          icon: Icons.account_balance_outlined,
                          iconColor: const Color(0xFF7C3AED),
                          iconBgColor: const Color(0xFFF5F3FF),
                          label: 'Central / State Scheme',
                          value: _schemeType,
                          items: ['All', 'Central Government', 'State Government'],
                          onChanged: (val) => setState(() => _schemeType = val ?? 'All'),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Fixed Action Footer
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _resetFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF), // Light blue 50
                        foregroundColor: const Color(0xFF2563EB), // Blue 600
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1), // Royal Blue
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Apply Filters ($activeCount)',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E3A8A), // Deep Royal Navy
        ),
      ),
    );
  }

  Widget _buildDropdownCell({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value == 'All' ? 'Select $label' : value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.0,
                child: DropdownButton<String>(
                  value: items.contains(value) ? value : items.first,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: items.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCell({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ? 'Yes' : 'Select Option',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.7,
              alignment: Alignment.centerRight,
              child: Switch(
                value: value,
                activeThumbColor: const Color(0xFF0D47A1),
                activeTrackColor: const Color(0xFF0D47A1).withAlpha(76),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
