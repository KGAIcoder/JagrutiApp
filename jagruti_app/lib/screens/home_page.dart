import 'package:flutter/material.dart';

import '../db/database_helper.dart';

enum MemberListMode { all, birthdays, anniversaries }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _bg = Color(0xFFFFF4E6);
  static const Color _surface = Colors.white;
  static const Color _line = Color(0xFFEFDCC8);
  static const Color _text = Color(0xFF2B160F);
  static const Color _muted = Color(0xFF7A5A47);
  static const Color _brand = Color(0xFFA52A2A);

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  List<String> _cities = ['All'];

  bool _isLoading = true;
  bool _isGridView = false;
  String _selectedCity = 'All';
  String _memberListTitle = 'Members';
  MemberListMode _memberListMode = MemberListMode.all;
  int _selectedMenuIndex = 0; // 0 dashboard, 1 members, 2 reports, 3 manual

  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _compareMembersByName(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aName = _normalize(_fullName(a));
    final bName = _normalize(_fullName(b));
    final byName = aName.compareTo(bName);
    if (byName != 0) return byName;
    final aId = _normalize((a['member_id'] ?? '').toString());
    final bId = _normalize((b['member_id'] ?? '').toString());
    return aId.compareTo(bId);
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final data = await DatabaseHelper().getMembers();
      final sortedData = [...data]..sort(_compareMembersByName);
      if (!mounted) return;

      final citySet = <String>{
        ...sortedData
            .map((member) => (member['city'] ?? '').toString().trim())
            .where((city) => city.isNotEmpty),
      };

      setState(() {
        _members = sortedData;
        _cities = ['All', ...citySet.toList()..sort()];
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load members: $e')),
      );
    }
  }

  void _applyFilters() {
    final query = _normalize(_searchController.text);
    final baseMembers = switch (_memberListMode) {
      MemberListMode.all => _members,
      MemberListMode.birthdays => _membersForMonth('date_of_birth'),
      MemberListMode.anniversaries => _membersForMonth('date_of_marriage'),
    };

    final queryTokens = query.isEmpty ? const <String>[] : query.split(' ');

    setState(() {
      _filteredMembers = baseMembers.where((member) {
        final memberId = _normalize((member['member_id'] ?? '').toString());
        final city = _normalize((member['city'] ?? '').toString());
        final mobile = _normalize((member['mobile'] ?? '').toString());
        final fullName = _normalize(_fullName(member));
        final searchHaystack = '$fullName $memberId $city $mobile';

        final matchesSearch = queryTokens.isEmpty ||
            queryTokens.every((token) => searchHaystack.contains(token));

        final matchesCity =
            _selectedCity == 'All' || city == _normalize(_selectedCity);
        return matchesSearch && matchesCity;
      }).toList()
        ..sort(_compareMembersByName);
    });
  }

  int get _totalMembers => _members.length;

  int get _totalFamilies {
    final families = _members
        .map((member) => (member['last_name'] ?? '').toString().trim().toLowerCase())
        .where((lastName) => lastName.isNotEmpty)
        .toSet();
    return families.length;
  }

  DateTime? _tryParseDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;

    // Handle dd-mm-yyyy (old format) while preserving yyyy-mm-dd.
    final parts = raw.split('-');
    if (parts.length == 3 && parts[0].length != 4) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime.tryParse(
          '${year.toString().padLeft(4, '0')}-'
          '${month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}',
        );
      }
    }

    return DateTime.tryParse(raw);
  }

  int _countByMonth(String dateField) {
    final now = DateTime.now();
    int count = 0;
    for (final member in _members) {
      final raw = (member[dateField] ?? '').toString();
      final parsed = _tryParseDate(raw);
      if (parsed != null && parsed.month == now.month) {
        count++;
      }
    }
    return count;
  }

  List<Map<String, dynamic>> _membersForMonth(String dateField) {
    final now = DateTime.now();
    return _members.where((member) {
      final raw = (member[dateField] ?? '').toString();
      final parsed = _tryParseDate(raw);
      return parsed != null && parsed.month == now.month;
    }).toList();
  }

  String _fullName(Map<String, dynamic> member) {
    final title = (member['title'] ?? '').toString().trim();
    final first = (member['first_name'] ?? '').toString().trim();
    final middle = (member['middle_name'] ?? '').toString().trim();
    final last = (member['last_name'] ?? '').toString().trim();

    final parts = [title, first, middle, last].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Unknown Member' : parts.join(' ').toUpperCase();
  }

  void _selectMenu(int index) {
    setState(() {
      _selectedMenuIndex = index;
      if (index == 1) {
        _memberListMode = MemberListMode.all;
        _memberListTitle = 'Members';
      }
    });
    _applyFilters();
    Navigator.of(context).maybePop();
  }

  List<Map<String, dynamic>> _todayBirthdays() {
    final now = DateTime.now();
    return _members.where((member) {
      final parsed = _tryParseDate((member['date_of_birth'] ?? '').toString());
      return parsed != null && parsed.month == now.month && parsed.day == now.day;
    }).toList();
  }

  List<Map<String, dynamic>> _todayAnniversaries() {
    final now = DateTime.now();
    return _members.where((member) {
      final parsed = _tryParseDate((member['date_of_marriage'] ?? '').toString());
      return parsed != null && parsed.month == now.month && parsed.day == now.day;
    }).toList();
  }

  int? _ageFromDob(Map<String, dynamic> member) {
    final dob = _tryParseDate((member['date_of_birth'] ?? '').toString());
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    final hadBirthday =
        (now.month > dob.month) || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age--;
    return age < 0 ? null : age;
  }

  Map<String, int> _ageDistribution() {
    final buckets = <String, int>{
      '0-5  Infant': 0,
      '6-18  Child': 0,
      '19-35  Youth': 0,
      '36-50  Adult': 0,
      '51-65  Senior': 0,
      '66+  Elder': 0,
    };

    for (final member in _members) {
      final age = _ageFromDob(member);
      if (age == null) continue;
      if (age <= 5) {
        buckets['0-5  Infant'] = buckets['0-5  Infant']! + 1;
      } else if (age <= 18) {
        buckets['6-18  Child'] = buckets['6-18  Child']! + 1;
      } else if (age <= 35) {
        buckets['19-35  Youth'] = buckets['19-35  Youth']! + 1;
      } else if (age <= 50) {
        buckets['36-50  Adult'] = buckets['36-50  Adult']! + 1;
      } else if (age <= 65) {
        buckets['51-65  Senior'] = buckets['51-65  Senior']! + 1;
      } else {
        buckets['66+  Elder'] = buckets['66+  Elder']! + 1;
      }
    }

    return buckets;
  }

  List<MapEntry<String, int>> _topCountsByField(String field, {int top = 10}) {
    final counts = <String, int>{};
    for (final member in _members) {
      var key = (member[field] ?? '').toString().trim().toUpperCase();
      if (key.isEmpty) key = 'NOT KNOWN';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(top).toList();
  }

  void _openMembersView(MemberListMode mode, String title) {
    setState(() {
      _selectedMenuIndex = 1;
      _memberListMode = mode;
      _memberListTitle = title;
      _selectedCity = 'All';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _showCityFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _cities
                .map(
                  (city) => ListTile(
                    title: Text(city),
                    trailing: _selectedCity == city
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCity = city;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? const Color(0xFFF8DEBF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: _text),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _text,
                      fontSize: 21,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Navigation',
                style: TextStyle(color: _muted, fontSize: 28, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _menuItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                active: _selectedMenuIndex == 0,
                onTap: () => _selectMenu(0),
              ),
              _menuItem(
                icon: Icons.groups_2_outlined,
                label: 'Members',
                active: _selectedMenuIndex == 1,
                onTap: () => _selectMenu(1),
              ),
              _menuItem(
                icon: Icons.bar_chart_outlined,
                label: 'Reports',
                active: _selectedMenuIndex == 2,
                onTap: () => _selectMenu(2),
              ),
              _menuItem(
                icon: Icons.menu_book_outlined,
                label: 'User Manual',
                active: _selectedMenuIndex == 3,
                onTap: () => _selectMenu(3),
              ),
              _menuItem(
                icon: Icons.temple_hindu_outlined,
                label: 'Temple & GuestHouse',
                active: false,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Temple & GuestHouse coming next.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(color: _muted, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(icon, color: iconColor),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                value,
                style: TextStyle(
                  color: _text,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final birthdaysThisMonth = _countByMonth('date_of_birth');
    final anniversariesThisMonth = _countByMonth('date_of_marriage');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(color: _text, fontSize: 46, fontWeight: FontWeight.w800, height: 1),
          ),
          const SizedBox(height: 8),
          Text(
            'Overview of your Community directory',
            style: TextStyle(color: _muted, fontSize: 18),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.06,
            children: [
              _buildStatCard(
                label: 'Total Members',
                value: '$_totalMembers',
                icon: Icons.groups_2_outlined,
                iconColor: const Color(0xFF8C2727),
                onTap: () => _openMembersView(MemberListMode.all, 'Members'),
              ),
              _buildStatCard(
                label: 'Total Families',
                value: '$_totalFamilies',
                icon: Icons.hub_outlined,
                iconColor: const Color(0xFF0F8C57),
                onTap: () => _openMembersView(MemberListMode.birthdays, 'Birthdays This Month'),
              ),
              _buildStatCard(
                label: 'Birthdays this month',
                value: '$birthdaysThisMonth',
                icon: Icons.cake_outlined,
                iconColor: const Color(0xFFFF2F92),
                onTap: () => _openMembersView(MemberListMode.birthdays, 'Birthdays This Month'),
              ),
              _buildStatCard(
                label: 'Anniversaries this month',
                value: '$anniversariesThisMonth',
                icon: Icons.favorite_border,
                iconColor: const Color(0xFF1C6CFF),
                onTap: () => _openMembersView(MemberListMode.anniversaries, 'Anniversaries This Month'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF8DEBF) : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Icon(icon, color: _text),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final memberId = (member['member_id'] ?? 'N/A').toString();
    final gotra = (member['gotra'] ?? 'Unknown').toString();
    final city = (member['city'] ?? '').toString();
    final state = (member['state'] ?? '').toString();
    final mobile = (member['mobile'] ?? '').toString();
    final fullName = _fullName(member);
    final photoUrl = (member['photo_url'] ?? '').toString().trim();

    final location = [city, state].where((part) => part.isNotEmpty).join(', ').toUpperCase();
    final initials = fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MemberProfileScreen(member: member, fullName: fullName),
              ),
            );
          },
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFF9DFC9),
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                            color: Color(0xFF6B331A),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memberId,
                        style: TextStyle(color: _muted, fontSize: 22, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        fullName,
                        style: TextStyle(
                          color: _text,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Gotra: ${gotra.toUpperCase()}',
                        style: TextStyle(color: _muted, fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      if (mobile.isNotEmpty)
                        Text('Mobile: $mobile', style: TextStyle(color: _muted, fontSize: 22)),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Location: $location', style: TextStyle(color: _muted, fontSize: 22)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberGridCard(Map<String, dynamic> member) {
    final memberId = (member['member_id'] ?? 'N/A').toString();
    final fullName = _fullName(member);
    final gotra = (member['gotra'] ?? 'Unknown').toString().toUpperCase();
    final city = (member['city'] ?? '').toString().toUpperCase();
    final photoUrl = (member['photo_url'] ?? '').toString().trim();
    final initials = fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MemberProfileScreen(member: member, fullName: fullName),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF9DFC9),
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            initials.isEmpty ? '?' : initials,
                            style: const TextStyle(
                              color: Color(0xFF6B331A),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      memberId,
                      style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Gotra: $gotra',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'City: $city',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembers() {
    final membersToShow = _filteredMembers;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          child: Row(
            children: [
              Text(
                _memberListTitle,
                style: TextStyle(color: _text, fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${membersToShow.length} records',
                style: TextStyle(color: _muted, fontSize: 14),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  style: TextStyle(color: _text, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: 'Search by Member ID, Name, City...',
                    hintStyle: TextStyle(color: _muted),
                    filled: true,
                    fillColor: const Color(0xFFFFF1E1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: const Color(0xFFEFCBA8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: const Color(0xFFEFCBA8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _brand, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _showCityFilterSheet,
                child: Ink(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _line),
                  ),
                  child: const Icon(Icons.filter_list, color: _text),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    _buildToggleButton(
                      icon: Icons.view_list_outlined,
                      active: !_isGridView,
                      onTap: () => setState(() => _isGridView = false),
                    ),
                    const SizedBox(width: 4),
                    _buildToggleButton(
                      icon: Icons.grid_view_outlined,
                      active: _isGridView,
                      onTap: () => setState(() => _isGridView = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: membersToShow.isEmpty
              ? Center(
                  child: Text(
                    'No members found',
                    style: TextStyle(color: _muted, fontSize: 22),
                  ),
                )
              : _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.05,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: membersToShow.length,
                      itemBuilder: (context, index) => _buildMemberGridCard(membersToShow[index]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: membersToShow.length,
                      itemBuilder: (context, index) => _buildMemberCard(membersToShow[index]),
                    ),
        ),
      ],
    );
  }

  Widget _distributionBar(double ratio) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 12,
        color: const Color(0xFFBEEFD9),
        child: FractionallySizedBox(
          widthFactor: ratio.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(color: const Color(0xFF0F9D69)),
        ),
      ),
    );
  }

  Widget _buildAgeDistributionCard() {
    final data = _ageDistribution();
    final total = data.values.fold<int>(0, (sum, n) => sum + n);
    final maxValue = data.values.fold<int>(0, (max, n) => n > max ? n : max);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Age Distribution',
                  style: TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              Text('By Current Age', style: TextStyle(color: _muted, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...data.entries.map((entry) {
            final count = entry.value;
            final percent = total == 0 ? 0 : ((count * 100) / total).round();
            final ratio = maxValue == 0 ? 0.0 : count / maxValue;
            final split = entry.key.split('  ');
            final range = split.first;
            final label = split.length > 1 ? split[1] : entry.key;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(width: 72, child: Text(range, style: TextStyle(color: _muted, fontSize: 15))),
                  SizedBox(width: 84, child: Text(label, style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600))),
                  Expanded(child: _distributionBar(ratio)),
                  const SizedBox(width: 10),
                  Text('$count ($percent%)', style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
          const Divider(height: 20, color: _line),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Total $total', style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTenCard({
    required String title,
    required List<MapEntry<String, int>> data,
  }) {
    final total = data.fold<int>(0, (sum, e) => sum + e.value);
    final maxValue = data.fold<int>(0, (max, e) => e.value > max ? e.value : max);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              Text('Top 10', style: TextStyle(color: _muted, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...data.asMap().entries.map((indexed) {
            final index = indexed.key;
            final entry = indexed.value;
            final percent = total == 0 ? 0 : ((entry.value * 100) / total).round();
            final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${index + 1}.', style: TextStyle(color: _muted, fontSize: 15)),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      entry.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _distributionBar(ratio)),
                  const SizedBox(width: 10),
                  Text(
                    '${entry.value} ($percent%)',
                    style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 22, color: _line),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total $total',
              style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReports() {
    final byLocation = _topCountsByField('city');
    final byVillage = _topCountsByField('origin_village');
    final bySurname = _topCountsByField('last_name');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demographics',
            style: TextStyle(color: _text, fontSize: 36, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('Community distribution insights', style: TextStyle(color: _muted, fontSize: 16)),
          const SizedBox(height: 14),
          _buildTopTenCard(title: 'People by Current Location', data: byLocation),
          _buildAgeDistributionCard(),
          _buildTopTenCard(title: 'Members by Origin Village', data: byVillage),
          _buildTopTenCard(title: 'Members by Surname', data: bySurname),
        ],
      ),
    );
  }

  Widget _buildUserManual() {
    const sections = [
      {
        'title': '1. Unlock App',
        'body':
            'Enter your 4-digit PIN on the unlock screen. On correct PIN, you enter the dashboard.'
      },
      {
        'title': '2. Dashboard',
        'body':
            'View totals for Members, Families, Birthdays this month, and Anniversaries this month. Tap cards to open related member lists.'
      },
      {
        'title': '3. Members',
        'body':
            'Use search to find members by ID or name. Use location filter to narrow results. Switch between list and grid views using the view toggle.'
      },
      {
        'title': '4. Member Profile',
        'body':
            'Tap any member card to open full details including contact, personal info, village, and address.'
      },
      {
        'title': '5. Notifications',
        'body':
            'Tap the bell icon to see today\'s birthdays and anniversaries. Names are grouped by event type.'
      },
      {
        'title': '6. Reports',
        'body':
            'Open Reports from the left menu to view demographics: top current locations, age distribution, top origin villages, and top surnames.'
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Manual', style: TextStyle(color: _text, fontSize: 36, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('How to use Jagruti App', style: TextStyle(color: _muted, fontSize: 16)),
          const SizedBox(height: 14),
          ...sections.map(
            (section) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section['title']!,
                    style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    section['body']!,
                    style: TextStyle(color: _muted, fontSize: 16, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE3CC),
              ),
              child: const Icon(Icons.self_improvement, color: _brand, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Jagruti App',
              style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w800, height: 1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: _text),
            onPressed: () {
              final birthdayNames = _todayBirthdays().map(_fullName).toList();
              final anniversaryNames = _todayAnniversaries().map(_fullName).toList();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                    birthdayNames: birthdayNames,
                    anniversaryNames: anniversaryNames,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : switch (_selectedMenuIndex) {
              0 => _buildDashboard(),
              1 => _buildMembers(),
              2 => _buildReports(),
              3 => _buildUserManual(),
              _ => _buildDashboard(),
            },
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  static const Color _bg = Color(0xFFFFF4E6);
  static const Color _surface = Colors.white;
  static const Color _line = Color(0xFFEFDCC8);
  static const Color _text = Color(0xFF2B160F);
  static const Color _muted = Color(0xFF7A5A47);

  const NotificationsScreen({
    super.key,
    required this.birthdayNames,
    required this.anniversaryNames,
  });

  final List<String> birthdayNames;
  final List<String> anniversaryNames;

  Widget _groupCard(String title, IconData icon, List<String> names) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFA52A2A)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          if (names.isEmpty)
            Text('No notifications for today.', style: TextStyle(color: _muted, fontSize: 16))
          else
            ...names.map(
              (name) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('• $name', style: TextStyle(color: _muted, fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Notifications', style: TextStyle(color: _text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _groupCard('Birthdays Today', Icons.cake_outlined, birthdayNames),
            _groupCard('Anniversaries Today', Icons.favorite_border, anniversaryNames),
          ],
        ),
      ),
    );
  }
}

class MemberProfileScreen extends StatelessWidget {
  static const Color _bg = Color(0xFFFFF4E6);
  static const Color _surface = Colors.white;
  static const Color _line = Color(0xFFEFDCC8);
  static const Color _text = Color(0xFF2B160F);
  static const Color _muted = Color(0xFF7A5A47);

  const MemberProfileScreen({super.key, required this.member, required this.fullName});

  final Map<String, dynamic> member;
  final String fullName;

  String _value(String key, {String fallback = '-'}) {
    final value = (member[key] ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(color: _muted, fontSize: 18)),
          ),
          Expanded(
            flex: 7,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _value('photo_url', fallback: '');
    final memberId = _value('member_id');
    final initials = fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Member Profile', style: TextStyle(color: _text)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFF9DFC9),
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          initials.isEmpty ? '?' : initials,
                          style: const TextStyle(
                            color: Color(0xFF6B331A),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(memberId, style: const TextStyle(color: _muted, fontSize: 20)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Column(
                children: [
                  _detailRow('Title', _value('title')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Gotra', _value('gotra')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Origin Village', _value('origin_village')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Gender', _value('gender')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Marital Status', _value('marital_status')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Date of Birth', _value('date_of_birth')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Date of Marriage', _value('date_of_marriage')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Mobile', _value('mobile')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Email', _value('email')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Education', _value('education')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Occupation', _value('occupation')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Address', _value('address')),
                  const Divider(height: 1, color: _line),
                  _detailRow('City', _value('city')),
                  const Divider(height: 1, color: _line),
                  _detailRow('State', _value('state')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Country', _value('country')),
                  const Divider(height: 1, color: _line),
                  _detailRow('Zip Code', _value('zip_code')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
