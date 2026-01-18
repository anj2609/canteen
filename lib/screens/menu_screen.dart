import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/canteen_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/menu_item_card.dart';
import 'cart_sheet.dart';
import 'search_screen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Meals', 'Snacks', 'Drinks'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(canteenProvider.notifier).fetchCanteens();
    });
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canteenState = ref.watch(canteenProvider);
    final cartState = ref.watch(cartProvider);

    // Filter menu based on category only
    final filteredMenu = canteenState.menu.where((item) {
      // Category filter (basic implementation - you may need to add category field to MenuItem)
      if (_selectedCategory != 'All') {
        // This is a simple categorization based on item names
        // You should ideally have a category field in your MenuItem model
        final itemName = item.name.toLowerCase();
        switch (_selectedCategory) {
          case 'Meals':
            if (!itemName.contains('burger') &&
                !itemName.contains('rice') &&
                !itemName.contains('noodles') &&
                !itemName.contains('samose'))
              return false;
            break;
          case 'Snacks':
            if (!itemName.contains('samosa') &&
                !itemName.contains('pakora') &&
                !itemName.contains('fries'))
              return false;
            break;
          case 'Drinks':
            if (!itemName.contains('tea') &&
                !itemName.contains('coffee') &&
                !itemName.contains('juice') &&
                !itemName.contains('shake'))
              return false;
            break;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: Color(0xFF0B7D3B),
            ),
            const SizedBox(width: 4),
            if (canteenState.selectedCanteen != null)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.black26,
                      builder: (context) => Stack(
                        children: [
                          // Dismiss on tap outside
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                          // Dropdown menu
                          Positioned(
                            top:
                                kToolbarHeight +
                                MediaQuery.of(context).padding.top,
                            left: 0,
                            right: 0,
                            child: Material(
                              elevation: 8,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: canteenState.canteens.map((
                                    canteen,
                                  ) {
                                    return InkWell(
                                      onTap: () {
                                        ref
                                            .read(canteenProvider.notifier)
                                            .selectCanteen(canteen);
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                canteen.name,
                                                style: GoogleFonts.urbanist(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            if (!canteen.isCurrentlyOpen)
                                              Text(
                                                'Closed',
                                                style: GoogleFonts.urbanist(
                                                  fontSize: 12,
                                                  color: Colors.pink[300],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          canteenState.selectedCanteen!.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 20),
                    ],
                  ),
                ),
              )
            else
              Text(
                'Select Canteen',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black,
                ),
                onPressed: () => _showCart(context),
              ),
              if (cartState.totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B7D3B),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartState.totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(canteenProvider.notifier).fetchCanteens();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Hungry?',
                    style: GoogleFonts.urbanist(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Beat the rush.',
                    style: GoogleFonts.urbanist(
                      fontSize: 24,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 22,
                            ),
                          ),
                          Text(
                            'Search for food...',
                            style: GoogleFonts.urbanist(
                              color: Colors.grey[500],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Tabs
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Menu Grid
            Expanded(
              child: canteenState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : canteenState.canteens.isEmpty
                  ? const Center(child: Text("No Canteens Available"))
                  : filteredMenu.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No menu items available",
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: filteredMenu.length,
                      itemBuilder: (context, index) {
                        final item = filteredMenu[index];
                        final isOpen =
                            canteenState.selectedCanteen?.isCurrentlyOpen ??
                            true;

                        return Opacity(
                          opacity: isOpen ? 1.0 : 0.6,
                          child: AbsorbPointer(
                            absorbing: !isOpen,
                            child: MenuItemCard(
                              item: item,
                              canteenId: canteenState.selectedCanteen!.id,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
