import 'package:flutter/material.dart';

/// When a route can pop, [AppBar] replaces the drawer menu with a back icon only.
/// This widget keeps both actions so admin/student shells stay navigable.
class DrawerMenuLeading extends StatelessWidget {
  const DrawerMenuLeading({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canPop)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ],
    );
  }

  static double widthFor(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return canPop ? 112 : 56;
  }
}
