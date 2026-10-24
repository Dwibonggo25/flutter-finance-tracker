import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/monthly_budget.dart';
import '../../domain/repositories/budget_repository.dart';

class FirestoreBudgetRepository implements BudgetRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreBudgetRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to access budgets.');
    }
    return _firestore.collection('users').doc(user.uid).collection('budgets');
  }

  @override
  Stream<MonthlyBudget> watchMonthlyBudget(DateTime month) {
    final emptyBudget = MonthlyBudget(year: month.year, month: month.month);
    return _collection.doc(emptyBudget.id).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return emptyBudget;

      final rawLimits = data['categoryLimits'];
      final limits = <String, double>{};
      if (rawLimits is Map) {
        for (final entry in rawLimits.entries) {
          final value = entry.value;
          if (entry.key is String && value is num) {
            limits[entry.key as String] = value.toDouble();
          }
        }
      }

      return MonthlyBudget(
        year: data['year'] as int? ?? month.year,
        month: data['month'] as int? ?? month.month,
        categoryLimits: limits,
      );
    });
  }

  @override
  Future<void> saveMonthlyBudget(MonthlyBudget budget) {
    return _collection.doc(budget.id).set({
      'year': budget.year,
      'month': budget.month,
      'categoryLimits': budget.categoryLimits,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
