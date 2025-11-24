import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_navigation_safety/src/core/theme/app_theme.dart';
import 'package:cooperative_navigation_safety/src/providers/app_providers.dart';
import 'package:cooperative_navigation_safety/src/ui/widgets/radar_widget.dart';
import 'package:cooperative_navigation_safety/src/ui/widgets/developer_panel.dart';
import 'package:cooperative_navigation_safety/src/ui/widgets/alert_banner.dart';
import 'package:cooperative_navigation_safety/src/ui/widgets/status_card.dart';
import 'package:cooperative_navigation_safety/src/ui/widgets/control_panel.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _initialized = false;
  bool _showDevPanel = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final systemCoordinator = ref.read(systemCoordinatorProvider);
      
      // Add timeout to prevent infinite waiting
      await systemCoordinator.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Initialization timeout - continuing anyway');
        },
      );
      
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      print('Initialization error: $e');
      // Still mark as initialized so app can show - permissions can be requested later
      setState(() {
        _initialized = true;
      });
      ref.read(appStateProvider.notifier).setError('Initialization failed: $e. Please grant permissions manually.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Cooperative Navigation Safety'),
        actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  _showSettingsDialog(context);
                },
              ),
              IconButton(
                icon: Icon(Icons.developer_mode,
                    color: _showDevPanel ? AppTheme.accentTeal : Colors.grey),
                onPressed: () {
                  setState(() => _showDevPanel = !_showDevPanel);
                },
              ),
        ],
      ),
      body: _initialized 
          ? _buildMainContent(context, appState)
          : _buildLoadingScreen(),
    );
  }

  Widget _buildMainContent(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Alert Banner
          const AlertBanner(),
          const SizedBox(height: 16),
          
          // Radar Visualization
          const RadarWidget(),
          const SizedBox(height: 16),
          if (_showDevPanel) const DeveloperPanel(),
          if (_showDevPanel) const SizedBox(height: 16),
          
          // Status and Controls Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              const Expanded(
                flex: 2,
                child: StatusCard(),
              ),
              const SizedBox(width: 16),
              
              // Control Panel
              const Expanded(
                flex: 3,
                child: ControlPanel(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Error Display
          if (appState.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.alertRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.alertRed),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: AppTheme.alertRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appState.error!,
                      style: const TextStyle(color: AppTheme.alertRed),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.alertRed),
                    onPressed: () {
                      ref.read(appStateProvider.notifier).clearError();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.accentTeal,
          ),
          SizedBox(height: 16),
          Text(
            'Initializing Cooperative Navigation Safety...',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Beacon Interval: 300ms'),
              Text('Radar Update: 60 FPS'),
              Text('Max Range: 50m'),
              Text('Collision Threshold: 2s TTC'),
              SizedBox(height: 16),
              Text('App Version: 1.0.0'),
              Text('Android 14 Compatible'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}