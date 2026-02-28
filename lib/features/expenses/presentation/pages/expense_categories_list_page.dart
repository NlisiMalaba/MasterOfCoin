import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/expense_category_dao.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../domain/entity/expense_category.dart';

const _iconNames = [
  'shopping_cart',
  'directions_car',
  'checkroom',
  'bolt',
  'phone_android',
  'restaurant',
  'local_hospital',
  'school',
  'movie',
  'more_horiz',
  'home',
  'flight',
  'attach_money',
  'savings',
  'category',
];

const _iconMap = {
  'shopping_cart': Icons.shopping_cart,
  'directions_car': Icons.directions_car,
  'checkroom': Icons.checkroom,
  'bolt': Icons.bolt,
  'phone_android': Icons.phone_android,
  'restaurant': Icons.restaurant,
  'local_hospital': Icons.local_hospital,
  'school': Icons.school,
  'movie': Icons.movie,
  'more_horiz': Icons.more_horiz,
  'home': Icons.home,
  'flight': Icons.flight,
  'attach_money': Icons.attach_money,
  'savings': Icons.savings,
  'category': Icons.category,
};

const _categoryColors = [
  0xFF4CAF50,
  0xFF2196F3,
  0xFF9C27B0,
  0xFFFF9800,
  0xFF00BCD4,
  0xFFE91E63,
  0xFFF44336,
  0xFF673AB7,
  0xFF795548,
  0xFF607D8B,
  0xFF00897B,
  0xFF5C6BC0,
];

class ExpenseCategoriesListPage extends StatefulWidget {
  const ExpenseCategoriesListPage({super.key});

  @override
  State<ExpenseCategoriesListPage> createState() =>
      _ExpenseCategoriesListPageState();
}

class _ExpenseCategoriesListPageState extends State<ExpenseCategoriesListPage> {
  late ExpenseCategoryDao _dao;
  List<ExpenseCategory> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _dao = getIt<ExpenseCategoryDao>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _dao.getAll();
    if (mounted) {
      setState(() {
        _categories = list;
        _loading = false;
      });
    }
  }

  IconData _iconForName(String name) => _iconMap[name] ?? Icons.category;

  Future<void> _showForm({ExpenseCategory? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String iconName = existing?.iconName ?? 'category';
    int colorHex = existing?.colorHex ?? 0xFF4CAF50;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(colorHex).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _iconForName(iconName),
                        size: 28,
                        color: Color(colorHex),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        existing != null ? 'Edit Category' : 'New Category',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Groceries, Transport',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                Text(
                  'Icon',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconNames.map((name) {
                    final selected = iconName == name;
                    return GestureDetector(
                      onTap: () => setModalState(() => iconName = name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? Color(colorHex).withValues(alpha: 0.3)
                              : Theme.of(ctx)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? Color(colorHex)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _iconForName(name),
                          color: selected ? Color(colorHex) : Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Color',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoryColors.map((hex) {
                    final selected = colorHex == hex;
                    return GestureDetector(
                      onTap: () => setModalState(() => colorHex = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Theme.of(ctx).colorScheme.onSurface : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(hex).withValues(alpha: 0.5),
                              blurRadius: selected ? 8 : 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Enter a name')),
                            );
                            return;
                          }
                          Navigator.pop(ctx, {
                            'name': name,
                            'iconName': iconName,
                            'colorHex': colorHex,
                          });
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final category = ExpenseCategory(
        id: existing?.id ?? 'cat_${const Uuid().v4()}',
        name: result['name'] as String,
        createdAt: existing?.createdAt ?? now,
        iconName: result['iconName'] as String,
        colorHex: result['colorHex'] as int,
        isSystem: false,
      );
      await _dao.insert(category);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing != null ? 'Updated' : 'Added')),
        );
      }
    }
  }

  Future<void> _confirmDelete(ExpenseCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.name}"? Transactions using this category will keep the reference.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _dao.delete(category.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? _EmptyState(onAdd: () => _showForm())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final c = _categories[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: c.color,
                            child: Icon(
                              _iconForName(c.iconName ?? 'category'),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: c.isSystem
                              ? Text(
                                  'Default category',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                )
                              : null,
                          trailing: c.isSystem
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _showForm(existing: c),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                      onPressed: () => _confirmDelete(c),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.label_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No categories yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add expense categories to organize your spending',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}
