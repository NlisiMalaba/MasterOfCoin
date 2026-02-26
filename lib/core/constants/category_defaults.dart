import 'package:flutter/material.dart';

/// Default expense categories for Zimbabwe context.
const List<ExpenseCategoryDefaults> kDefaultExpenseCategories = [
  ExpenseCategoryDefaults(
    id: 'groceries',
    name: 'Groceries',
    iconName: 'shopping_cart',
    colorHex: 0xFF4CAF50,
  ),
  ExpenseCategoryDefaults(
    id: 'transport',
    name: 'Transport',
    iconName: 'directions_car',
    colorHex: 0xFF2196F3,
  ),
  ExpenseCategoryDefaults(
    id: 'clothing',
    name: 'Clothing',
    iconName: 'checkroom',
    colorHex: 0xFF9C27B0,
  ),
  ExpenseCategoryDefaults(
    id: 'utilities',
    name: 'Utilities',
    iconName: 'bolt',
    colorHex: 0xFFFF9800,
  ),
  ExpenseCategoryDefaults(
    id: 'airtime_data',
    name: 'Airtime & Data',
    iconName: 'phone_android',
    colorHex: 0xFF00BCD4,
  ),
  ExpenseCategoryDefaults(
    id: 'eating_out',
    name: 'Eating Out',
    iconName: 'restaurant',
    colorHex: 0xFFE91E63,
  ),
  ExpenseCategoryDefaults(
    id: 'healthcare',
    name: 'Healthcare',
    iconName: 'local_hospital',
    colorHex: 0xFFF44336,
  ),
  ExpenseCategoryDefaults(
    id: 'education',
    name: 'Education',
    iconName: 'school',
    colorHex: 0xFF673AB7,
  ),
  ExpenseCategoryDefaults(
    id: 'entertainment',
    name: 'Entertainment',
    iconName: 'movie',
    colorHex: 0xFF795548,
  ),
  ExpenseCategoryDefaults(
    id: 'other',
    name: 'Other',
    iconName: 'more_horiz',
    colorHex: 0xFF607D8B,
  ),
];

/// Default income sources (seeded for both USD and ZWG).
const List<IncomeSourceDefaults> kDefaultIncomeSources = [
  IncomeSourceDefaults(id: 'job_usd', name: 'Job', currency: 'USD'),
  IncomeSourceDefaults(id: 'side_hustle_usd', name: 'Side Hustle', currency: 'USD'),
  IncomeSourceDefaults(id: 'investments_usd', name: 'Investments', currency: 'USD'),
  IncomeSourceDefaults(id: 'other_usd', name: 'Other', currency: 'USD'),
  IncomeSourceDefaults(id: 'job_zwg', name: 'Job', currency: 'ZWG'),
  IncomeSourceDefaults(id: 'side_hustle_zwg', name: 'Side Hustle', currency: 'ZWG'),
  IncomeSourceDefaults(id: 'investments_zwg', name: 'Investments', currency: 'ZWG'),
  IncomeSourceDefaults(id: 'other_zwg', name: 'Other', currency: 'ZWG'),
];

class ExpenseCategoryDefaults {
  const ExpenseCategoryDefaults({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
  });

  final String id;
  final String name;
  final String iconName;
  final int colorHex;

  Color get color => Color(colorHex);
}

class IncomeSourceDefaults {
  const IncomeSourceDefaults({
    required this.id,
    required this.name,
    required this.currency,
  });

  final String id;
  final String name;
  final String currency;
}
