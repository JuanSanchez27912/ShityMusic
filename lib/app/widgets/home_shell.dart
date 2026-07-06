import 'package:flutter/material.dart';

import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/player/presentation/screens/player_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../theme/app_theme.dart';
import 'now_playing_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _openPlayer() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.backdropGradient(theme.brightness),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              LibraryScreen(onOpenPlayer: _openPlayer),
              const SettingsScreen(),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NowPlayingBar(onTap: _openPlayer),
              NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music),
                    label: 'Biblioteca',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune),
                    label: 'Ajustes',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
