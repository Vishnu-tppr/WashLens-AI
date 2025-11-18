// import 'dart:convert';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_auth/firebase_auth.dart' as auth;
// import 'package:uuid/uuid.dart';
// import 'package:drift/drift.dart';
// import '../data/database.dart';

// /// Sync service for offline-first synchronization with Firestore
// class SyncService {
//   final AppDatabase _db;
//   final FirebaseFirestore _firestore;
//   final FirebaseStorage _storage;
//   final auth.FirebaseAuth _auth;

//   SyncService({
//     required AppDatabase database,
//     FirebaseFirestore? firestore,
//     FirebaseStorage? storage,
//     auth.FirebaseAuth? firebaseAuth,
//   })  : _db = database,
//         _firestore = firestore ?? FirebaseFirestore.instance,
//         _storage = storage ?? FirebaseStorage.instance,
//         _auth = firebaseAuth ?? auth.FirebaseAuth.instance;

//   String? get _currentUserId => _auth.currentUser?.uid;

//   /// Process all pending sync operations
//   Future<void> syncAll() async {
//     if (_currentUserId == null) {
//       print('SyncService: No user logged in, skipping sync');
//       return;
//     }

//     try {
//       final operations = await _db.getPendingSyncOperations();
//       print('SyncService: Processing ${operations.length} pending operations');

//       for (final operation in operations) {
//         try {
//           await _processSyncOperation(operation);
//           await _db.deleteSyncOperation(operation.id);
//         } catch (e) {
//           print('SyncService: Error processing operation ${operation.id}: $e');
//           // Update retry count
//           await _db.updateSyncOperation(
//             operation.copyWith(
//               retryCount: operation.retryCount + 1,
//               lastError: Value(e.toString()),
//             ),
//           );
//         }
//       }

//       print('SyncService: Sync completed');
//     } catch (e) {
//       print('SyncService: Error during sync: $e');
//     }
//   }

//   /// Process a single sync operation
//   Future<void> _processSyncOperation(SyncQueueData operation) async {
//     final payload = jsonDecode(operation.payload) as Map<String, dynamic>;

//     switch (operation.entityType) {
//       case 'wash':
//         await _syncWash(operation.operation, operation.entityId, payload);
//         break;
//       case 'wash_item':
//         await _syncWashItem(operation.operation, operation.entityId, payload);
//         break;
//       case 'dhobi':
//         await _syncDhobi(operation.operation, operation.entityId, payload);
//         break;
//       case 'category':
//         await _syncCategory(operation.operation, operation.entityId, payload);
//         break;
//       default:
//         print('SyncService: Unknown entity type: ${operation.entityType}');
//     }
//   }

//   /// Sync wash to Firestore
//   Future<void> _syncWash(
//     String operation,
//     String entityId,
//     Map<String, dynamic> payload,
//   ) async {
//     final docRef = _firestore
//         .collection('users')
//         .doc(_currentUserId)
//         .collection('washes')
//         .doc(payload['remoteId'] ?? entityId);

//     switch (operation) {
//       case 'create':
//       case 'update':
//         await docRef.set(payload, SetOptions(merge: true));
//         // Update local remoteId and sync status
//         final wash = await _db.getWashById(entityId);
//         if (wash != null) {
//           await _db.updateWash(
//             wash.copyWith(remoteId: Value(docRef.id), syncStatus: 'synced'),
//           );
//         }
//         break;
//       case 'delete':
//         await docRef.delete();
//         break;
//     }
//   }

//   /// Sync wash item to Firestore
//   Future<void> _syncWashItem(
//     String operation,
//     String entityId,
//     Map<String, dynamic> payload,
//   ) async {
//     final washId = payload['washId'] as String;
//     final wash = await _db.getWashById(washId);
//     if (wash?.remoteId == null) {
//       throw Exception('Parent wash not synced yet');
//     }

//     final docRef = _firestore
//         .collection('users')
//         .doc(_currentUserId)
//         .collection('washes')
//         .doc(wash!.remoteId)
//         .collection('items')
//         .doc(entityId);

//     switch (operation) {
//       case 'create':
//       case 'update':
//         await docRef.set(payload, SetOptions(merge: true));
//         break;
//       case 'delete':
//         await docRef.delete();
//         break;
//     }
//   }

//   /// Sync dhobi to Firestore
//   Future<void> _syncDhobi(
//     String operation,
//     String entityId,
//     Map<String, dynamic> payload,
//   ) async {
//     final docRef = _firestore
//         .collection('users')
//         .doc(_currentUserId)
//         .collection('dhobis')
//         .doc(entityId);

//     switch (operation) {
//       case 'create':
//       case 'update':
//         await docRef.set(payload, SetOptions(merge: true));
//         break;
//       case 'delete':
//         await docRef.delete();
//         break;
//     }
//   }

//   /// Sync category to Firestore
//   Future<void> _syncCategory(
//     String operation,
//     String entityId,
//     Map<String, dynamic> payload,
//   ) async {
//     final docRef = _firestore
//         .collection('users')
//         .doc(_currentUserId)
//         .collection('categories')
//         .doc(entityId);

//     switch (operation) {
//       case 'create':
//       case 'update':
//         await docRef.set(payload, SetOptions(merge: true));
//         break;
//       case 'delete':
//         await docRef.delete();
//         break;
//     }
//   }

//   /// Upload image to Firebase Storage
//   Future<String> uploadImage({
//     required File imageFile,
//     required String washId,
//     required String role, // 'given' or 'returned'
//   }) async {
//     if (_currentUserId == null) {
//       throw Exception('No user logged in');
//     }

//     final imageId = const Uuid().v4();
//     final extension = imageFile.path.split('.').last;
//     final path =
//         'users/$_currentUserId/washes/$washId/$role/$imageId.$extension';

//     final ref = _storage.ref().child(path);
//     await ref.putFile(imageFile);
//     final downloadUrl = await ref.getDownloadURL();

//     return downloadUrl;
//   }

//   /// Download all data from Firestore (for restore)
//   Future<void> pullFromCloud() async {
//     if (_currentUserId == null) {
//       throw Exception('No user logged in');
//     }

//     print('SyncService: Pulling data from cloud...');

//     // Pull dhobis
//     final dhobisSnapshot = await _firestore
//         .collection('users')
//         .doc(_currentUserId)
//         .collection('dhobis')
//         .get();

//     for (final doc in dhobisSnapshot.docs) {
//       final data = doc.data();
//       await _db.insertDhobi(
//         DhobisCompanion.insert(
//           id: doc.id,
//           userId: _currentUserId!,
//           name: data['name'] as String,
//           phone: Value(data['phone'] as String?),
//           notes: Value(data['notes'] as String?),
//           createdAt: data['createdAt'] as int,
//           updatedAt: data['updatedAt'] as int,
//         ),
//       );
//     }

//     // Pull categories
//     final categoriesSnapshot = await _firestore
//         .collection('users')
//         .doc(_currentUserId)
//         .collection('categories')
//         .get();

//     for (final doc in categoriesSnapshot.docs) {
//       final data = doc.data();
//       await _db.insertCategory(
//         CategoriesCompanion.insert(
//           id: doc.id,
//           userId: _currentUserId!,
//           name: data['name'] as String,
//           slug: data['slug'] as String,
//           group: data['group'] as String,
//           sortOrder: data['sortOrder'] as int,
//           icon: data['icon'] as String,
//           color: data['color'] as String,
//           createdAt: data['createdAt'] as int,
//           updatedAt: data['updatedAt'] as int,
//         ),
//       );
//     }

//     // Pull washes
//     final washesSnapshot = await _firestore
//         .collection('users')
//         .doc(_currentUserId)
//         .collection('washes')
//         .get();

//     for (final doc in washesSnapshot.docs) {
//       final data = doc.data();
//       await _db.insertWash(
//         WashesCompanion.insert(
//           id: data['id'] as String,
//           userId: _currentUserId!,
//           dhobiId: data['dhobiId'] as String,
//           status: data['status'] as String,
//           givenAt: data['givenAt'] as int,
//           totalItemsGiven: data['totalItemsGiven'] as int,
//           totalItemsReturned: data['totalItemsReturned'] as int,
//           totalMissing: data['totalMissing'] as int,
//           totalExtra: data['totalExtra'] as int,
//           createdAt: data['createdAt'] as int,
//           updatedAt: data['updatedAt'] as int,
//           syncStatus: 'synced',
//           remoteId: Value(doc.id),
//         ),
//       );
//     }

//     print('SyncService: Pull completed');
//   }

//   /// Queue an operation for sync
//   Future<void> queueSync({
//     required String entityType,
//     required String entityId,
//     required String operation,
//     required Map<String, dynamic> payload,
//   }) async {
//     await _db.insertSyncOperation(
//       SyncQueueCompanion.insert(
//         id: const Uuid().v4(),
//         entityType: entityType,
//         entityId: entityId,
//         operation: operation,
//         payload: jsonEncode(payload),
//         createdAt: DateTime.now().millisecondsSinceEpoch,
//       ),
//     );
//   }
// }
