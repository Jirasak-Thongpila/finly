/// Actions emitted by [AppDrawer] to the parent screen.
enum DrawerAction { home, transactions, statistics, settings }

/// Transaction types that can be started from the drawer.
class DrawerAddAction {
  DrawerAddAction._();

  static const String income = 'income';
  static const String expense = 'expense';
}