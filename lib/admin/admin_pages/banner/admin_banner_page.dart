import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../services/banner_service.dart';
import 'edit_banner_page.dart';
import 'add_banner_page.dart';
import 'package:handabatamae/admin/admin_pages/banner/banner_deletion_dialog.dart';

class AdminBannerPage extends StatefulWidget {
  const AdminBannerPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminBannerPageState createState() => _AdminBannerPageState();
}

class AdminBannerState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> banners;
  final Set<int> processingIds; // Track banners being edited/deleted

  const AdminBannerState({
    this.isLoading = false,
    this.error,
    this.banners = const [],
    this.processingIds = const {},
  });

  AdminBannerState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? banners,
    Set<int>? processingIds,
  }) {
    return AdminBannerState(
      isLoading: isLoading ?? this.isLoading,
      error: error,  // Note: Passing null clears error
      banners: banners ?? this.banners,
      processingIds: processingIds ?? this.processingIds,
    );
  }
}

class _AdminBannerPageState extends State<AdminBannerPage> {
  final BannerService _bannerService = BannerService();
  late AdminBannerState _state;
  StreamSubscription? _bannerSubscription;
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _state = const AdminBannerState();
    _setupSubscriptions();
    _fetchBanners();
  }

  void _setupSubscriptions() {
    // Listen for banner updates
    _bannerSubscription = _bannerService.bannerUpdates.listen(
      (banners) {
        if (mounted) {
          setState(() => _state = _state.copyWith(
            banners: banners,
            isLoading: false,
            error: null,
          ));
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _state = _state.copyWith(
            error: error.toString(),
            isLoading: false,
          ));
        }
      },
    );

    // Listen for sync status
    _syncSubscription = _bannerService.syncStatus.listen(
      (isSyncing) {
        if (mounted) {
          setState(() => _state = _state.copyWith(
            isLoading: isSyncing,
          ));
        }
      },
    );
  }

  Future<void> _fetchBanners() async {
    try {
      setState(() => _state = _state.copyWith(
        isLoading: true,
        error: null,
      ));

      final banners = await _bannerService.fetchBanners();
      
      if (mounted) {
        setState(() => _state = _state.copyWith(
          banners: banners,
          isLoading: false,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = _state.copyWith(
          error: e.toString(),
          isLoading: false,
        ));
      }
    }
  }

  void _showAddBannerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddBannerDialog();
      },
    ).then((_) {
      _fetchBanners();
    });
  }

  void _navigateToEditBanner(Map<String, dynamic> banner) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return EditBannerDialog(banner: banner);
      },
    );

    if (result == true) {
      _fetchBanners(); // Refresh the list after successful update
    }
  }

  Future<void> _deleteBanner(int id) async {
    try {
      bool confirm = await BannerDeletionDialog(
        bannerId: id, 
        context: context
      ).show();

      if (!confirm) return;

      // Add to processing set
      setState(() => _state = _state.copyWith(
        processingIds: {..._state.processingIds, id},
      ));

      // Optimistic update
      final updatedBanners = _state.banners
          .where((b) => b['id'] != id)
          .toList();
      
      setState(() => _state = _state.copyWith(
        banners: updatedBanners,
      ));

      // Perform delete
      await _bannerService.deleteBanner(id);

      // Remove from processing
      setState(() => _state = _state.copyWith(
        processingIds: _state.processingIds.difference({id}),
      ));

    } catch (e) {
      // Revert on error
      _fetchBanners();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting banner: $e')),
        );
      }
    }
  }

  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.vt323TextTheme()
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Manage Banners', 
              style: GoogleFonts.vt323(color: Colors.white, fontSize: 30)),
          backgroundColor: const Color(0xFF381c64),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Keep the refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _state.isLoading ? null : _fetchBanners,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF381c64),
        body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Stack(
            children: [
              // Background
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                ),
              ),
              
              // Content
              if (_state.error != null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: ${_state.error}',
                          style: GoogleFonts.vt323(color: Colors.red)),
                      ElevatedButton(
                        onPressed: _fetchBanners,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _state.isLoading ? null : _showAddBannerDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF381c64),
                          shadowColor: Colors.transparent,
                        ),
                        child: Text('Add Banner',
                            style: GoogleFonts.vt323(
                                color: Colors.white, fontSize: 20)),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: BannerDataTable(
                          banners: _state.banners,
                          processingIds: _state.processingIds,
                          onEditBanner: _navigateToEditBanner,
                          onDeleteBanner: _deleteBanner,
                        ),
                      ),
                    ],
                  ),
                ),

              // Loading Indicator
              if (_state.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bannerSubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }
}

class BannerDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> banners;
  final Set<int> processingIds;
  final ValueChanged<Map<String, dynamic>> onEditBanner;
  final ValueChanged<int> onDeleteBanner;

  const BannerDataTable({
    super.key,
    required this.banners,
    required this.processingIds,
    required this.onEditBanner,
    required this.onDeleteBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // Set card background to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0), // Square corners
        side: const BorderSide(color: Colors.black, width: 2.0), // Black border
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Add padding inside the card
        child: DataTable(
          columns: [
            DataColumn(label: Text('ID', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Title', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Image URL', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Description', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Actions', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
          ],
          rows: banners.map((banner) {
            int id = banner['id'] ?? 0;
            String title = banner['title'] ?? '';
            String imageUrl = banner['img'] ?? '';
            String description = banner['description'] ?? '';
            return DataRow(cells: [
              DataCell(Text(id.toString(), style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(title, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(imageUrl, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(description, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => onEditBanner(banner),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF381c64),
                      ),
                      child: Text('Edit', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => onDeleteBanner(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text('Delete', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}