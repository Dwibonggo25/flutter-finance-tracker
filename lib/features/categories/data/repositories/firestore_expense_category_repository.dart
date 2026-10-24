import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_category_repository.dart';

class FirestoreExpenseCategoryRepository implements ExpenseCategoryRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreExpenseCategoryRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    final user = _auth.currentUser;
    if (user == null) throw StateError('A signed-in user is required.');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenseCategories');
  }

  @override
  Stream<List<ExpenseCategory>> watchCategories() => _collection
      .orderBy('sortOrder')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((document) => _fromDocument(document.id, document.data()))
            .toList(growable: false),
      );

  @override
  Future<void> ensureDefaultCategories() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;
    final batch = _firestore.batch();
    for (final category in ExpenseCategory.defaults) {
      batch.set(_collection.doc(category.id), {
        ..._data(category),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> addCategory(String name) async {
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Category name is required.');
    final baseId = _idFor(value);
    var id = baseId;
    var suffix = 2;
    while ((await _collection.doc(id).get()).exists) {
      id = '$baseId-$suffix';
      suffix++;
    }
    final count = (await _collection.count().get()).count ?? 0;
    final category = ExpenseCategory(
      id: id,
      name: value,
      iconKey: 'category',
      colorValue: _customColors[count % _customColors.length],
      sortOrder: count,
    );
    await _collection.doc(id).set({
      ..._data(category),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> renameCategory(ExpenseCategory category, String newName) async {
    final value = newName.trim();
    if (value.isEmpty) throw ArgumentError('Category name is required.');
    await _collection.doc(category.id).update({
      'name': value,
      'isDefault': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteCategory(String categoryId) =>
      _collection.doc(categoryId).delete();

  Map<String, dynamic> _data(ExpenseCategory category) => {
    'name': category.name,
    'iconKey': category.iconKey,
    'colorValue': category.colorValue,
    'sortOrder': category.sortOrder,
    'isDefault': category.isDefault,
  };

  ExpenseCategory _fromDocument(String id, Map<String, dynamic> data) =>
      ExpenseCategory(
        id: id,
        name: data['name'] as String? ?? id,
        iconKey: data['iconKey'] as String? ?? 'category',
        colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF607D8B,
        sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
        isDefault: data['isDefault'] as bool? ?? false,
      );

  String _idFor(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty
        ? 'category-${DateTime.now().millisecondsSinceEpoch}'
        : normalized;
  }
}

const _customColors = [
  0xFF8E5AAE,
  0xFF2B8A78,
  0xFFE07A5F,
  0xFF457B9D,
  0xFFC28B2C,
];
