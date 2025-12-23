import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/owner_provider.dart';
import '../../../providers/canteen_provider.dart';
import '../../../models/canteen_model.dart';
import 'package:intl/intl.dart';

class OwnerCanteenSettingsView extends ConsumerStatefulWidget {
  final Canteen canteen;
  const OwnerCanteenSettingsView({super.key, required this.canteen});

  @override
  ConsumerState<OwnerCanteenSettingsView> createState() =>
      _OwnerCanteenSettingsViewState();
}

class _OwnerCanteenSettingsViewState
    extends ConsumerState<OwnerCanteenSettingsView> {
  late TimeOfDay _openingTime;
  late TimeOfDay _closingTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _openingTime = _parseTime(widget.canteen.openingTime);
    _closingTime = _parseTime(widget.canteen.closingTime);
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      // Assuming format "HH:mm" or "hh:mm AM/PM"
      // If simple "09:00", split.
      // If "9:00 AM", parse.
      // Let's assume standard format or try best effort.
      if (timeStr.contains("AM") || timeStr.contains("PM")) {
        final dt = DateFormat.jm().parse(timeStr);
        return TimeOfDay.fromDateTime(dt);
      }
      final parts = timeStr.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    // Return appropriate string for API backend format
    // Assuming backend takes "09:00" or similar.
    // Let's use 24h format "HH:mm" usually safe, or match expected.
    // existing seems to play loose, let's use standard.
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _pickTime(bool isOpening) async {
    // Get current canteen times from provider
    final ownerState = ref.read(ownerProvider);
    final currentCanteen = ownerState.myCanteens.firstWhere(
      (c) => c.id == widget.canteen.id,
      orElse: () => widget.canteen,
    );

    final currentOpeningTime = _parseTime(currentCanteen.openingTime);
    final currentClosingTime = _parseTime(currentCanteen.closingTime);

    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? currentOpeningTime : currentClosingTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  Future<void> _saveHours() async {
    setState(() => _isLoading = true);
    final openStr = _formatTime(_openingTime);
    final closeStr = _formatTime(_closingTime);

    // Get the current canteen from provider (not from stale widget)
    final ownerState = ref.read(ownerProvider);
    final currentCanteen = ownerState.myCanteens.firstWhere(
      (c) => c.id == widget.canteen.id,
      orElse: () => widget.canteen,
    );

    final success = await ref
        .read(canteenProvider.notifier)
        .updateCanteenHours(currentCanteen.id, openStr, closeStr);

    // Refresh parent
    ref.read(ownerProvider.notifier).fetchMyCanteens();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hours updated successfully')),
        );
        Navigator.pop(context);
      } else {
        // Show the actual error message
        final canteenState = ref.read(canteenProvider);
        final errorMsg = canteenState.error != null
            ? 'Error: ${canteenState.error}'
            : 'Failed to update hours';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus() async {
    // Optimistic update handled by provider or refresher
    final success = await ref
        .read(canteenProvider.notifier)
        .toggleCanteenStatus(widget.canteen.id);
    ref.read(ownerProvider.notifier).fetchMyCanteens();

    if (success) {
      // The view will update beautifully because we are watching the provider in build()
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Canteen status updated'),
          duration: const Duration(seconds: 1),
        ),
      );
      // Do NOT pop, let them see the change.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerState = ref.watch(ownerProvider);
    // Find the latest version of this canteen from the provider
    final canteen = ownerState.myCanteens.firstWhere(
      (c) => c.id == widget.canteen.id,
      orElse: () => widget.canteen,
    );
    final isOpen = canteen.isCurrentlyOpen;

    // Use times from the latest canteen data
    final currentOpeningTime = _parseTime(canteen.openingTime);
    final currentClosingTime = _parseTime(canteen.closingTime);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Canteen Settings',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isOpen
                    ? const Color(0x1A4CAF50)
                    : const Color(0x1AF44336),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isOpen ? Colors.green : Colors.red),
              ),
              child: Row(
                children: [
                  Icon(
                    isOpen ? Icons.store : Icons.store_mall_directory_outlined,
                    size: 40,
                    color: isOpen ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOpen ? 'CURRENTLY OPEN' : 'CURRENTLY CLOSED',
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isOpen ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          isOpen
                              ? 'Accepting new orders'
                              : 'Not accepting orders',
                          style: GoogleFonts.urbanist(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.2,
                    child: Switch(
                      value: isOpen,
                      onChanged: (val) => _toggleStatus(),
                      activeThumbColor: Colors.green,
                      inactiveTrackColor: const Color(0x4DF44336),
                      inactiveThumbColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Operating Hours',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _buildTimeRow(
              'Opening Time',
              currentOpeningTime,
              () => _pickTime(true),
            ),
            const SizedBox(height: 15),
            _buildTimeRow(
              'Closing Time',
              currentClosingTime,
              () => _pickTime(false),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveHours,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF62F56),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Delete Canteen Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: _deleteCanteen,
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  'Delete Canteen',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, TimeOfDay time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            Row(
              children: [
                Text(
                  time.format(context),
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.access_time, color: Color(0xFFF62F56)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCanteen() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Canteen?'),
        content: Text(
          'Are you sure you want to delete "${widget.canteen.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(ownerProvider.notifier)
          .deleteCanteen(widget.canteen.id);

      if (success && mounted) {
        Navigator.pop(context); // Go back after deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canteen deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete canteen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
