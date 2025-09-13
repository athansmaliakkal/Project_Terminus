import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storage_space/storage_space.dart';
import 'package:terminus/services/background_service.dart';
import 'package:terminus/services/permission_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PermissionService _permissionService = PermissionService();
  double _totalSpace = 0.0;
  double _usedSpace = 0.0;
  bool _isLoadingStorage = true;

  @override
  void initState() {
    super.initState();
    _initializeAppServices();
    _getStorageInfo();
  }

  Future<void> _initializeAppServices() async {
    final hasPermissions = await _permissionService.requestCorePermissions();
    if (!hasPermissions || !mounted) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Terminus Service Notifications',
      description: 'This channel is used for the main Terminus background service.',
      importance: Importance.low,
    );
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await BackgroundService.initializeService();
    
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    }
  }
  
  Future<void> _getStorageInfo() async {
    StorageSpace storage = await getStorageSpace(lowOnSpaceThreshold: 0, fractionDigits: 1);
    if (mounted) {
      setState(() {
        _totalSpace = storage.total / 1073741824;
        _usedSpace = (_totalSpace * 1073741824 - storage.free) / 1073741824;
        _isLoadingStorage = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 30;
    const double verticalPadding = 25;
    final double usedPercentage = _totalSpace > 0 ? _usedSpace / _totalSpace : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - (verticalPadding * 2)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: IconButton(
                              tooltip: 'Sync with Cloud',
                              icon: const Icon(Icons.cloud_sync, color: Colors.black, size: 30),
                              onPressed: () => Navigator.pushNamed(context, '/sync'),
                            ),
                          ),
                          Container(
                            height: 50,
                            width: 50,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: IconButton(
                              tooltip: 'Settings',
                              icon: const Icon(Icons.settings_input_component, color: Colors.black, size: 30),
                              onPressed: () => Navigator.pushNamed(context, '/settings'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.poppins(fontSize: 24, color: Colors.white),
                      ),
                      Text(
                        'ATHAN',
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                      GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1 / 1,
                        shrinkWrap: true,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          TerminusPanel(
                            title: "AUDIO",
                            icon: Icons.multitrack_audio,
                            onTap: () => Navigator.pushNamed(context, '/audio'),
                          ),
                          TerminusPanel(
                            title: "VIDEO",
                            icon: Icons.video_collection_outlined,
                            onTap: () => Navigator.pushNamed(context, '/video'),
                          ),
                          TerminusPanel(
                            title: "LOCATION",
                            icon: Icons.share_location,
                            onTap: () => Navigator.pushNamed(context, '/location'),
                          ),
                          TerminusPanel(
                            title: "STORAGE",
                            icon: Icons.folder_outlined,
                            onTap: () => Navigator.pushNamed(context, '/storage'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _isLoadingStorage
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Device Storage',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: usedPercentage,
                                  minHeight: 10,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${_usedSpace.toStringAsFixed(1)} GB / ${_totalSpace.toStringAsFixed(1)} GB used',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TerminusPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const TerminusPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: Colors.black),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

