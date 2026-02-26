import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/transaction_mappers.dart';
import '../../../../core/widgets/currency_display.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/domain/transaction_type.dart';
import '../../domain/entity/transaction.dart';
import 'transaction_form_page.dart';

class TransactionsListPage extends StatefulWidget {
  const TransactionsListPage({super.key});

  @override
  State<TransactionsListPage> createState() => _TransactionsListPageState();
}

class _TransactionsListPageState extends State<TransactionsListPage> {
  late TransactionDao _dao;
  List<TransactionRow> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _dao = getIt<TransactionDao>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _dao.getAll(limit: 100);
    setState(() {
      _transactions = list;
      _loading = false;
    });
  }

  Future<void> _deleteTransaction(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _dao.delete(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/transactions/add'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => context.push('/transactions/add'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Transaction'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final row = _transactions[index];
                      final tx = TransactionMappers.toEntity(row);
                      return Dismissible(
                        key: ValueKey(row.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteTransaction(row.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _colorForType(tx.type),
                            child: Icon(_iconForType(tx.type), color: Colors.white),
                          ),
                          title: Text(_titleForTransaction(tx)),
                          subtitle: Text(
                            _formatDate(tx.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Text(
                            '${tx.currency.symbol} ${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: tx.type == TransactionType.expense
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          onTap: () =>
                              context.push('/transactions/edit/${row.id}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _colorForType(TransactionType type) {
    return switch (type) {
      TransactionType.income => Colors.green,
      TransactionType.expense => Colors.red,
      TransactionType.transfer => Colors.blue,
    };
  }

  IconData _iconForType(TransactionType type) {
    return switch (type) {
      TransactionType.income => Icons.arrow_downward,
      TransactionType.expense => Icons.arrow_upward,
      TransactionType.transfer => Icons.swap_horiz,
    };
  }

  String _titleForTransaction(Transaction tx) {
    if (tx.note != null && tx.note!.isNotEmpty) return tx.note!;
    return tx.type.name[0].toUpperCase() + tx.type.name.substring(1);
  }

  String _formatDate(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
