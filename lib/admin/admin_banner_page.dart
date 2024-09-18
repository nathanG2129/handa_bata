import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../services/banner_service.dart';
import 'edit_banner_page.dart';
import 'add_banner_page.dart';
import 'package:handabatamae/admin/banner_deletion_dialog.dart';

class AdminBannerPage extends StatefulWidget {
  const AdminBannerPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminBannerPageState createState() => _AdminBannerPageState();
}

class _AdminBannerPageState extends State<AdminBannerPage> {
  final BannerService _bannerService = BannerService();
  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  void _fetchBanners() async {
    List<Map<String, dynamic>> banners = await _bannerService.fetchBanners();
    print('Fetched banners: $banners');
    setState(() {
      _banners = banners;
    });
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditBannerDialog(banner: banner);
      },
    ).then((_) {
      _fetchBanners();
    });
  }

  void _deleteBanner(int id) async {
    bool confirm = await BannerDeletionDialog(bannerId: id, context: context).show();
    if (confirm) {
      await _bannerService.deleteBanner(id);
      _fetchBanners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.vt323TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Manage Banners', style: GoogleFonts.vt323(color: Colors.white, fontSize: 30)),
          backgroundColor: const Color(0xFF381c64),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: const Color(0xFF381c64),
        body: Container(
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
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showAddBannerDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF381c64),
                        shadowColor: Colors.transparent,
                      ),
                      child: Text('Add Banner', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: BannerDataTable(
                        banners: _banners,
                        onEditBanner: _navigateToEditBanner,
                        onDeleteBanner: _deleteBanner,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BannerDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> banners;
  final ValueChanged<Map<String, dynamic>> onEditBanner;
  final ValueChanged<int> onDeleteBanner;

  const BannerDataTable({
    super.key,
    required this.banners,
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
                      onPressed: id != 0 ? () => onEditBanner(banner) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF381c64),
                      ),
                      child: Text('Edit', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: id != 0 ? () => onDeleteBanner(id) : null,
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