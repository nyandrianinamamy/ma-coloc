import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/issue.dart';
import '../../providers/house_provider.dart';
import '../../providers/issue_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/issue_card.dart';

class IssuesListScreen extends ConsumerStatefulWidget {
  const IssuesListScreen({super.key});

  @override
  ConsumerState<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends ConsumerState<IssuesListScreen> {
  int _activeTab = 0; // 0=All, 1=Mine, 2=Open
  IssueType? _activeTypeFilter; // null means "All"
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _tabs = ['All', 'Mine', 'Open'];
  static const List<String> _filterLabels = [
    'All',
    'Chore',
    'Grocery',
    'Repair',
    'Other'
  ];
  static const List<IssueType?> _filterTypes = [
    null,
    IssueType.chore,
    IssueType.grocery,
    IssueType.repair,
    IssueType.other,
  ];

  IssueTab get _issueTab => IssueTab.values[_activeTab];

  String get _activeFilterLabel =>
      _filterLabels[_filterTypes.indexOf(_activeTypeFilter)];

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

  @override
  Widget build(BuildContext context) {
    final houseId = ref.watch(currentHouseIdProvider).valueOrNull;

    if (houseId == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final issuesAsync = ref.watch(
      issuesStreamProvider(IssueQueryParams(houseId: houseId, tab: _issueTab)),
    );

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
                activeFilter: _activeFilterLabel,
                onTabChanged: (i) => setState(() => _activeTab = i),
                onFilterChanged: (f) => setState(
                  () => _activeTypeFilter =
                      _filterTypes[_filterLabels.indexOf(f)],
                ),
                tabs: _tabs,
                filters: _filterLabels,
              ),
            ),
          ),

          // Issue list or loading/error/empty state
          ...issuesAsync.when(
            loading: () => [
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Error loading issues',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
            data: (issues) {
              final filtered = filterBySearch(
                filterByType(issues, _activeTypeFilter),
                _searchQuery,
              );

              if (filtered.isEmpty) {
                return [
                  const SliverFillRemaining(child: _EmptyState()),
                ];
              }

              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IssueCard(
                          issue: filtered[index],
                          houseId: houseId,
                        ),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
              ];
            },
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
