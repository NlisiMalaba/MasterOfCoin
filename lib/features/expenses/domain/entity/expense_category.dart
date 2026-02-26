import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Expense category (groceries, transport, etc.).
class ExpenseCategory extends Equatable {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    this.iconName,
    this.colorHex,
    this.isSystem = true,
  });

  final String id;
  final String name;
  final int createdAt;
  final String? iconName;
  final int? colorHex;
  final bool isSystem;

  Color get color => colorHex != null ? Color(colorHex!) : Colors.grey;

  @override
  List<Object?> get props => [id, name, createdAt, iconName, colorHex, isSystem];

  ExpenseCategory copyWith({
    String? id,
    String? name,
    int? createdAt,
    String? iconName,
    int? colorHex,
    bool? isSystem,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}
