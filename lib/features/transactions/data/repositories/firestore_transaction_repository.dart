import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/finance_transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class FirestoreTransactionRepository implements TransactionRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreTransactionRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to access transactions.');
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  @override
  Stream<List<FinanceTransaction>> watchTransactions() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(_transactionFromDocument)
              .toList(growable: false),
        );
  }

  @override
  Future<void> createTransaction(FinanceTransaction transaction) {
    return _collection.add({
      ..._transactionData(transaction),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateTransaction(FinanceTransaction transaction) {
    if (transaction.id.isEmpty) {
      throw ArgumentError.value(
        transaction.id,
        'transaction.id',
        'An existing transaction ID is required.',
      );
    }
    return _collection.doc(transaction.id).update({
      ..._transactionData(transaction),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteTransaction(String transactionId) {
    if (transactionId.isEmpty) {
      throw ArgumentError.value(
        transactionId,
        'transactionId',
        'A transaction ID is required.',
      );
    }
    return _collection.doc(transactionId).delete();
  }

  Map<String, dynamic> _transactionData(FinanceTransaction transaction) {
    return {
      'title': transaction.title,
      'category': transaction.categoryKey,
      'amount': transaction.amount,
      'date': Timestamp.fromDate(transaction.date),
      'type': transaction.type.name,
      'note': transaction.note,
    };
  }

  FinanceTransaction _transactionFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawAmount = data['amount'];
    final rawDate = data['date'];
    final rawType = data['type'];

    return FinanceTransaction(
      id: document.id,
      title: data['title'] as String? ?? '',
      categoryKey: data['category'] as String? ?? 'other',
      amount: rawAmount is num ? rawAmount.toDouble() : 0,
      date: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      type: rawType == FinanceTransactionType.income.name
          ? FinanceTransactionType.income
          : FinanceTransactionType.expense,
      note: data['note'] as String? ?? '',
    );
  }
}
