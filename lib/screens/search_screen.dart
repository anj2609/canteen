import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  List<String> _recentSearches = [
    'Burger',
    'Chole samose',
    'Chole bhature',
    'Chole samose',
    'Noodles',
    'Pizza',
  ];

  @override
  void initState() {
    super.initState();
    // Listen to focus changes to update the UI (show/hide overlay)
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearHistory() {
    setState(() => _recentSearches.clear());
  }

  @override
  Widget build(BuildContext context) {
    final canteenState = ref.watch(canteenProvider);
    bool isSearching = _focusNode.hasFocus;

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // --- 1. BACKGROUND LAYER (Tabs & Results) ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gap for the floating search bar (adjust height based on search bar size)
                const SizedBox(height: 85),

                _buildCategoryTabs(),

                const SizedBox(height: 16),

                Expanded(
                  child: Stack(
                    children: [
                      _buildResultsGrid(filteredMenu, canteenState),

                      // --- 2. DIM OVERLAY LAYER ---
                      if (isSearching)
                        GestureDetector(
                          onTap: () => _focusNode.unfocus(),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // --- 3. FLOATING SEARCH SECTION (White Header) ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  top: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  boxShadow: isSearching
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // Allows container to grow with Wrap content
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios_new, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSearchBar()),
                      ],
                    ),
                    if (isSearching && _recentSearches.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildRecentSearchesHeader(),
                      const SizedBox(height: 12),
                      _buildRecentSearchesWrap(), // Using Wrap instead of ListView
                    ],
                  ],
                ),
              ),
            ),
          ],
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
