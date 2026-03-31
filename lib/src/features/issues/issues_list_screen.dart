import 'package:flutter/material.dart';

import '../../mock/mock_data.dart';
import '../../theme/app_theme.dart';
import 'widgets/issue_card.dart';

class IssuesListScreen extends StatefulWidget {
  const IssuesListScreen({super.key});

  @override
  State<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends State<IssuesListScreen> {
  int _activeTab = 0; // 0=All, 1=Mine, 2=Open
  String _activeFilter = 'All'; // 'All', 'Chore', 'Grocery', 'Repair', 'Other'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _tabs = ['All', 'Mine', 'Open'];
  static const List<String> _filters = ['All', 'Chore', 'Grocery', 'Repair', 'Other'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MockIssue> get _filteredIssues {
    var issues = MockData.issues;

    // Tab filter
    if (_activeTab == 1) {
      issues = issues
          .where((i) => i.assigneeId == MockData.currentUser.id)
          .toList();
    } else if (_activeTab == 2) {
      issues = issues.where((i) => i.status == 'open').toList();
    }

    // Type filter chip
    if (_activeFilter != 'All') {
      issues = issues
          .where((i) => i.type.toLowerCase() == _activeFilter.toLowerCase())
          .toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      issues = issues.where((i) => i.title.toLowerCase().contains(q)).toList();
    }

    return issues;
  }

  @override
  Widget build(BuildContext context) {
    final filteredIssues = _filteredIssues;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Sticky header
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: const Color(0x0A000000),
            elevation: 1,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: AppColors.surface),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(160),
              child: _StickyHeader(
                searchController: _searchController,
                activeTab: _activeTab,
                activeFilter: _activeFilter,
                onTabChanged: (i) => setState(() => _activeTab = i),
                onFilterChanged: (f) => setState(() => _activeFilter = f),
                tabs: _tabs,
                filters: _filters,
              ),
            ),
          ),

          // Issue list or empty state
          if (filteredIssues.isEmpty)
            const SliverFillRemaining(
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IssueCard(issue: filteredIssues[index]),
                  ),
                  childCount: filteredIssues.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky Header
// ---------------------------------------------------------------------------
class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.searchController,
    required this.activeTab,
    required this.activeFilter,
    required this.onTabChanged,
    required this.onFilterChanged,
    required this.tabs,
    required this.filters,
  });

  final TextEditingController searchController;
  final int activeTab;
  final String activeFilter;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onFilterChanged;
  final List<String> tabs;
  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Issues',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),

          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: searchController,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Search issues...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tabs
          Row(
            children: List.generate(tabs.length, (i) {
              final isActive = activeTab == i;
              return GestureDetector(
                onTap: () => onTabChanged(i),
                child: Padding(
                  padding: EdgeInsets.only(right: i < tabs.length - 1 ? 20 : 0),
                  child: Column(
                    children: [
                      Text(
                        tabs[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppColors.slate800
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        width: 20,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.emerald
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Filter chips — horizontal scroll
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = filters[i];
                final isActive = activeFilter == filter;
                return GestureDetector(
                  onTap: () => onFilterChanged(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.slate800
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? AppColors.slate800
                            : AppColors.borderMedium,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.emerald100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.emerald,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All clear!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No issues match your current filters',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
