import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Main shell with bottom navigation
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.notes)) return 1;
    if (location.startsWith(AppRoutes.files)) return 2;
    if (location.startsWith(AppRoutes.convert)) return 3;
    if (location.startsWith(AppRoutes.jobs)) return 4;
    if (location.startsWith(AppRoutes.settings)) return 5;

    return 0;
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.notes);
        break;
      case 2:
        context.go(AppRoutes.files);
        break;
      case 3:
        context.go(AppRoutes.convert);
        break;
      case 4:
        context.go(AppRoutes.jobs);
        break;
      case 5:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    if (isWideScreen) {
      // Tablet/Desktop layout with NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              extended: screenWidth > 900,
              minWidth: 72,
              minExtendedWidth: 200,
              backgroundColor: theme.scaffoldBackgroundColor,
              indicatorColor: theme.colorScheme.primary.withOpacity(0.1),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.note_outlined),
                  selectedIcon: Icon(Icons.note),
                  label: Text('Notes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: Text('Files'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.transform_outlined),
                  selectedIcon: Icon(Icons.transform),
                  label: Text('Convert'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Mobile layout with BottomNavigationBar
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    onTap: () => _onDestinationSelected(0),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.note_outlined,
                    selectedIcon: Icons.note,
                    label: 'Notes',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onDestinationSelected(1),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.folder_outlined,
                    selectedIcon: Icons.folder,
                    label: 'Files',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onDestinationSelected(2),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.transform_outlined,
                    selectedIcon: Icons.transform,
                    label: 'Convert',
                    isSelected: selectedIndex == 3,
                    onTap: () => _onDestinationSelected(3),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history,
                    label: 'History',
                    isSelected: selectedIndex == 4,
                    onTap: () => _onDestinationSelected(4),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: 'Settings',
                    isSelected: selectedIndex == 5,
                    onTap: () => _onDestinationSelected(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom navigation bar item with animation
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Ensure icons and text are always visible - use solid colors
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final color = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 22,
              color: color,
            ).animate(target: isSelected ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 150.ms,
                ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
