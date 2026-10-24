import '../../../../libraries/core/localization/language_keys.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final int sortOrder;
  final bool isDefault;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.sortOrder,
    this.isDefault = false,
  });

  static const defaults = [
    ExpenseCategory(
      id: LanguageKeys.housing,
      name: 'Housing',
      iconKey: 'home',
      colorValue: 0xFF7B47B4,
      sortOrder: 0,
      isDefault: true,
    ),
    ExpenseCategory(
      id: LanguageKeys.needs,
      name: 'Essentials',
      iconKey: 'shopping',
      colorValue: 0xFFD05D67,
      sortOrder: 1,
      isDefault: true,
    ),
    ExpenseCategory(
      id: LanguageKeys.transportation,
      name: 'Transportation',
      iconKey: 'transport',
      colorValue: 0xFF31A4B5,
      sortOrder: 2,
      isDefault: true,
    ),
    ExpenseCategory(
      id: LanguageKeys.bills,
      name: 'Bills',
      iconKey: 'receipt',
      colorValue: 0xFFB69A36,
      sortOrder: 3,
      isDefault: true,
    ),
    ExpenseCategory(
      id: LanguageKeys.other,
      name: 'Other',
      iconKey: 'category',
      colorValue: 0xFF607D8B,
      sortOrder: 4,
      isDefault: true,
    ),
  ];
}
