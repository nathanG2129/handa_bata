import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/resource_service.dart';
import 'edit_resource_dialog.dart';
import 'add_resource_dialog.dart';
import 'resource_deletion_dialog.dart';

class AdminResourcePage extends StatefulWidget {
  const AdminResourcePage({super.key});

  @override
  _AdminResourcePageState createState() => _AdminResourcePageState();
}

class AdminResourceState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> resources;
  final Set<int> processingIds;

  const AdminResourceState({
    this.isLoading = false,
    this.error,
    this.resources = const [],
    this.processingIds = const {},
  });

  AdminResourceState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? resources,
    Set<int>? processingIds,
  }) {
    return AdminResourceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      resources: resources ?? this.resources,
      processingIds: processingIds ?? this.processingIds,
    );
  }
}

class _AdminResourcePageState extends State<AdminResourcePage> {
  final ResourceService _resourceService = ResourceService();
  late AdminResourceState _state;
  StreamSubscription? _resourceSubscription;
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _state = const AdminResourceState();
    _setupSubscriptions();
    _fetchResources();
  }

  void _setupSubscriptions() {
    _resourceSubscription = _resourceService.resourceUpdates.listen(
      (resources) {
        if (mounted) {
          setState(() => _state = _state.copyWith(
            resources: resources,
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

    _syncSubscription = _resourceService.syncStatus.listen(
      (isSyncing) {
        if (mounted) {
          setState(() => _state = _state.copyWith(
            isLoading: isSyncing,
          ));
        }
      },
    );
  }

  Future<void> _fetchResources() async {
    try {
      setState(() => _state = _state.copyWith(
        isLoading: true,
        error: null,
      ));

      final resources = await _resourceService.fetchResources(isAdmin: true);
      
      if (mounted) {
        setState(() => _state = _state.copyWith(
          resources: resources,
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

  void _showAddResourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddResourceDialog();
      },
    ).then((_) {
      _fetchResources();
    });
  }

  void _navigateToEditResource(Map<String, dynamic> resource) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return EditResourceDialog(resource: resource);
      },
    );

    if (result == true) {
      _fetchResources();
    }
  }

  Future<void> _deleteResource(int id) async {
    try {
      bool confirm = await ResourceDeletionDialog(
        resourceId: id, 
        context: context
      ).show();

      if (!confirm) return;

      setState(() => _state = _state.copyWith(
        processingIds: {..._state.processingIds, id},
      ));

      final updatedResources = _state.resources
          .where((r) => r['id'] != id)
          .toList();
      
      setState(() => _state = _state.copyWith(
        resources: updatedResources,
      ));

      await _resourceService.deleteResource(id);

      setState(() => _state = _state.copyWith(
        processingIds: _state.processingIds.difference({id}),
      ));

    } catch (e) {
      _fetchResources();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting resource: $e')),
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
          title: Text('Manage Resources', 
              style: GoogleFonts.vt323(color: Colors.white, fontSize: 30)),
          backgroundColor: const Color(0xFF381c64),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _state.isLoading ? null : _fetchResources,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF381c64),
        body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                ),
              ),
              
              if (_state.error != null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: ${_state.error}',
                          style: GoogleFonts.vt323(color: Colors.red)),
                      ElevatedButton(
                        onPressed: _fetchResources,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ResourceDataTable(
                              resources: _state.resources,
                              onEditResource: _navigateToEditResource,
                              onDeleteResource: _deleteResource,
                              processingIds: _state.processingIds,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _state.isLoading ? null : _showAddResourceDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF381c64),
                          shadowColor: Colors.transparent,
                        ),
                        child: Text('Add Resource',
                            style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

              if (_state.isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _resourceSubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }
}

class ResourceDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> resources;
  final Set<int> processingIds;
  final ValueChanged<Map<String, dynamic>> onEditResource;
  final ValueChanged<int> onDeleteResource;

  const ResourceDataTable({
    super.key,
    required this.resources,
    required this.processingIds,
    required this.onEditResource,
    required this.onDeleteResource,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0),
        side: const BorderSide(color: Colors.black, width: 2.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DataTable(
          columns: [
            DataColumn(label: Text('ID', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Type', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Title', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Source', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Reference', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Actions', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
          ],
          rows: resources.map((resource) {
            int id = resource['id'] ?? 0;
            String type = resource['type'] ?? '';
            String title = resource['title'] ?? '';
            String src = resource['src'] ?? '';
            String reference = resource['reference'] ?? '';
            return DataRow(cells: [
              DataCell(Text(id.toString(), style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(type, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(title, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(src, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(reference, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => onEditResource(resource),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF381c64),
                      ),
                      child: Text('Edit', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => onDeleteResource(id),
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