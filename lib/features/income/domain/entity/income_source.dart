import 'package:equatable/equatable.dart';

import '../../../../shared/domain/currency.dart';

/// Source of income (job, side hustle, etc.).
class IncomeSource extends Equatable {
  const IncomeSource({
    required this.id,
    required this.name,
    required this.currency,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final String name;
  final Currency currency;
  final int createdAt;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, currency, createdAt, isActive];

  IncomeSource copyWith({
    String? id,
    String? name,
    Currency? currency,
    int? createdAt,
    bool? isActive,
  }) {
    return IncomeSource(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
