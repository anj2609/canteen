import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage the selected tab index in MainScreen
final selectedTabProvider = StateProvider<int>((ref) => 0);
