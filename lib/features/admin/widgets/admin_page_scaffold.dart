import 'package:flutter/material.dart';

import '../../../core/widgets/drawer_menu_leading.dart';
import 'admin_drawer.dart';

/// Standard admin layout with side navigation.
class AdminPageScaffold extends StatelessWidget {
  const AdminPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: Text(title),
        leadingWidth: DrawerMenuLeading.widthFor(context),
        leading: const DrawerMenuLeading(),
        automaticallyImplyLeading: false,
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
