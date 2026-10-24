import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../transactions/domain/entities/finance_transaction.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';

class FirestoreRecurringTransactionRepository
    implements RecurringTransactionRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreRecurringTransactionRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required.');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recurringTransactions');
  }

  @override
  Stream<List<RecurringTransaction>> watchRecurringTransactions() {
    return _collection.snapshots().map((snapshot) {
      final items = snapshot.docs.map(_fromDocument).toList(growable: false);
      return [...items]..sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));
    });
  }

  @override
  Future<String> createRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final document = await _collection.add({
      ..._data(transaction),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  @override
  Future<void> updateRecurringTransaction(RecurringTransaction transaction) {
    if (transaction.id.isEmpty) {
      throw ArgumentError('An existing recurring transaction ID is required.');
    }
    return _collection.doc(transaction.id).update({
      ..._data(transaction),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteRecurringTransaction(String transactionId) {
    if (transactionId.isEmpty) {
      throw ArgumentError('A recurring transaction ID is required.');
    }
    return _collection.doc(transactionId).delete();
  }

  Map<String, dynamic> _data(RecurringTransaction transaction) => {
    'title': transaction.title,
    'amount': transaction.amount,
    'type': transaction.type.name,
    'category': transaction.categoryKey,
    'dayOfMonth': transaction.dayOfMonth,
    'reminderDaysBefore': transaction.reminderDaysBefore,
    'isActive': transaction.isActive,
    'note': transaction.note,
  };

  RecurringTransaction _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return RecurringTransaction(
      id: document.id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: data['type'] == FinanceTransactionType.income.name
          ? FinanceTransactionType.income
          : FinanceTransactionType.expense,
      categoryKey: data['category'] as String? ?? 'other',
      dayOfMonth: (data['dayOfMonth'] as num?)?.toInt() ?? 1,
      reminderDaysBefore: (data['reminderDaysBefore'] as num?)?.toInt() ?? 1,
      isActive: data['isActive'] as bool? ?? true,
      note: data['note'] as String? ?? '',
    );
  }
}
