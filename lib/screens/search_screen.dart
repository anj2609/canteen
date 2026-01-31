import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/canteen_provider.dart';
import '../widgets/menu_item_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Meals', 'Snacks', 'Drinks'];

  List<String> _recentSearches = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Listen to focus changes to update the UI (show/hide overlay)
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
      _isLoadingHistory = false;
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('recent_searches') ?? [];

    // Remove if exists to move to top
    history.remove(query);
    // Add to start
    history.insert(0, query);
    // Limit to 5
    if (history.length > 5) {
      history = history.sublist(0, 5);
    }

    await prefs.setStringList('recent_searches', history);
    if (mounted) {
      setState(() {
        _recentSearches = history;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    setState(() => _recentSearches.clear());
  }

  @override
  Widget build(BuildContext context) {
    final canteenState = ref.watch(canteenProvider);

    // Filtering Logic
    final filteredMenu = canteenState.menu.where((item) {
      if (_searchQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCategory != 'All') {
        final itemName = item.name.toLowerCase();
        switch (_selectedCategory) {
          case 'Meals':
            if (!itemName.contains('burger') && !itemName.contains('rice'))
              return false;
            break;
          case 'Snacks':
            if (!itemName.contains('samosa') && !itemName.contains('fries'))
              return false;
            break;
          case 'Drinks':
            if (!itemName.contains('tea') && !itemName.contains('coffee'))
              return false;
            break;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.translucent, // Hit empty space
        child: Align(
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside the sheet
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height *
                    0.85, // Limit height to keep sheet feel
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Wrap content height
                  children: [
                    // Search Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: _buildSearchBar(),
                    ),

                    // Content (History or Results)
                    Flexible(
                      child: _searchQuery.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_recentSearches.isEmpty &&
                                      !_isLoadingHistory) ...[
                                    Text(
                                      'Suggestions',
                                      style: GoogleFonts.urbanist(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildSuggestionsWrap(),
                                  ] else if (_recentSearches.isNotEmpty) ...[
                                    _buildRecentSearchesHeader(),
                                    const SizedBox(height: 12),
                                    _buildRecentSearchesWrap(),
                                  ],
                                ],
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildCategoryTabs(),
                                const SizedBox(height: 10),
                                Flexible(
                                  child: _buildResultsGrid(
                                    filteredMenu,
                                    canteenState,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    // Bottom padding for aesthetics
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI SUB-WIDGETS ---

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        autofocus: true, // Auto-focus to show keyboard and history immediately
        onSubmitted: (val) => _addToHistory(val), // Add on Submit
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.urbanist(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search for food...',
          hintStyle: GoogleFonts.urbanist(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Colors.black87),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSuggestionsWrap() {
    final suggestions = ['Pizza', 'Burger', 'Sandwich'];
    return Wrap(
      spacing: 8.0,
      runSpacing: 10.0,
      children: suggestions.map((search) {
        return GestureDetector(
          onTap: () {
            _addToHistory(search);
            setState(() {
              _searchQuery = search;
              _searchController.text = search;
              _focusNode.unfocus();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  search,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentSearchesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Searches',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: _clearHistory,
          child: Text(
            'Clear History',
            style: GoogleFonts.urbanist(
              color: const Color(0xFF0B7D3B),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchesWrap() {
    return Wrap(
      spacing: 8.0, // Horizontal space between chips
      runSpacing: 10.0, // Vertical space between lines
      children: _recentSearches.map((search) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _searchQuery = search;
              _searchController.text = search;
              _focusNode.unfocus(); // Optional: close search UI on selection
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  search,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == _categories[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = _categories[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              child: Text(
                _categories[index],
                style: GoogleFonts.urbanist(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsGrid(List filteredMenu, dynamic canteenState) {
    if (filteredMenu.isEmpty) {
      return Center(
        child: Text(
          "No items match your search",
          style: GoogleFonts.urbanist(color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: filteredMenu.length,
      itemBuilder: (context, index) {
        final item = filteredMenu[index];
        return MenuItemCard(
          item: item,
          canteenId: canteenState.selectedCanteen?.id ?? '',
        );
      },
    );
  }
}
