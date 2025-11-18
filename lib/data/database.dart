// import 'dart:io';
// import 'package:drift/drift.dart';
// import 'package:drift/native.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;

// // part 'database.g.dart';  // Temporarily disabled

// // ============================================================================
// // USERS
// // ============================================================================

// /// Users table - stores user profile information
// class Users extends Table {
//   TextColumn get id => text()(); // Firebase UID
//   TextColumn get displayName => text()();
//   TextColumn get email => text()();
//   IntColumn get createdAt => integer()(); // milliseconds since epoch
//   IntColumn get updatedAt => integer()();

//   @override
//   Set<Column> get primaryKey => {id};
// }

// // ============================================================================
// // DHOBIS
// // ============================================================================

// /// Dhobis table - stores laundry service provider information
// class Dhobis extends Table {
//   TextColumn get id => text()(); // UUID
//   TextColumn get userId => text()(); // FK to Users
//   TextColumn get name => text()();
//   TextColumn get phone => text().nullable()();
//   TextColumn get notes => text().nullable()();
//   IntColumn get createdAt => integer()();
//   IntColumn get updatedAt => integer()();
//   BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

//   @override
//   Set<Column> get primaryKey => {id};
// }

// // ============================================================================
// // CATEGORIES
// // ============================================================================

// /// Categories table - cloth types (Shirts, T-shirts, Pants, etc.)
// class Categories extends Table {
//   TextColumn get id => text()(); // UUID
//   TextColumn get userId => text()();
//   TextColumn get name => text()(); // "Shirts"
//   TextColumn get slug => text()(); // "shirt"
//   TextColumn get group => text()(); // "upper", "lower", "others"
//   BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();
//   BoolColumn get isActive => boolean().withDefault(const Constant(true))();
//   IntColumn get sortOrder => integer()();
//   TextColumn get icon => text()(); // icon name
//   TextColumn get color => text()(); // hex color
//   IntColumn get createdAt => integer()();
//   IntColumn get updatedAt => integer()();

//   @override
//   Set<Column> get primaryKey => {id};
// }

// // ============================================================================
// // WASHES
// // ============================================================================

// /// Washes table - each laundry session
// class Washes extends Table {
//   TextColumn get id => text()(); // UUID
//   TextColumn get userId => text()();
//   TextColumn get dhobiId => text()(); // FK to Dhobis
//   TextColumn get status => text()(); // "given", "partial_return", "returned"
//   IntColumn get givenAt => integer()();
//   IntColumn get expectedReturnAt => integer().nullable()();
//   IntColumn get returnedAt => integer().nullable()();
//   TextColumn get notes => text().nullable()();
//   IntColumn get totalItemsGiven => integer()();
//   IntColumn get totalItemsReturned => integer()();
//   IntColumn get totalMissing => integer()();
//   IntColumn get totalExtra => integer()();
//   TextColumn get riskLevel => text().nullable()(); // "low", "medium", "high"
//   IntColumn get createdAt => integer()();
//   IntColumn get updatedAt => integer()();

//   // Sync metadata
//   TextColumn get remoteId => text().nullable()(); // Firestore doc ID
//   TextColumn get syncStatus =>
//       text()(); // "pending_create", "pending_update", "synced", "pending_delete"

//   @override
//   Set<Column> get primaryKey => {id};
// }

// // ============================================================================
// // WASH ITEMS
// // ============================================================================

// /// WashItems table - individual cloth items in each wash
// class WashItems extends Table {
//   TextColumn get id => text()(); // UUID
//   TextColumn get washId => text()(); // FK to Washes
//   TextColumn get categoryId => text()(); // FK to Categories
//   IntColumn get sequence => integer()(); // for checklist: Shirt 1, Shirt 2
//   TextColumn get color => text().nullable()(); // "blue", "red", etc.
//   TextColumn get pattern => text().nullable()(); // "checks", "plain", "stripes"
//   BoolColumn get logo => boolean().withDefault(const Constant(false))();
//   TextColumn get collarType =>
//       text().nullable()(); // "none", "round", "polo", "shirt_collar"
//   TextColumn get status => text()(); // "given", "returned", "missing", "extra"
//   IntColumn get givenCount => integer()(); // usually 1
//   IntColumn get returnedCount => integer()();
//   TextColumn get imageLocalPath => text().nullable()(); // cropped patch
//   TextColumn get imageRemoteUrl => text().nullable()(); // Storage URL
//   IntColumn get createdAt => integer()();
//   IntColumn get updatedAt => integer()();

//   @override
//   Set<Column> get primaryKey => {id};
// }

// // ============================================================================
// // WASH IMAGES
// // ============================================================================

// /// WashImages table - multiple photos per wash (given/returned)
// class WashImages extends Table {
//   TextColumn get id => text()(); // UUID
//   TextColumn get washId => text()(); // FK to Washes
//   TextColumn get role => text()(); // "given", "returned"
//   TextColumn get localPath => text()(); // app sandbox path
//   TextColumn get remotePath => text().nullable()(); // Storage path
//   TextColumn get remoteUrl => text().nullable()(); // download URL
//   IntColumn get width => integer().nullable()();
//   IntColumn get height => integer().nullable()();
//   IntColumn get createdAt => integer()();

//   @override
//   Set<Column> get primaryKey => {id};
// }

// // ============================================================================
// // SETTINGS
// // ============================================================================

// /// Settings table - user preferences (single row per user)
// class Settings extends Table {
//   IntColumn get id => integer().autoIncrement()();
//   TextColumn get userId => text()();
//   IntColumn get reminderDays => integer().withDefault(const Constant(3))();
//   IntColumn get dryingBaseHours => integer().withDefault(const Constant(24))();
//   BoolColumn get useCloudBackup =>
//       boolean().withDefault(const Constant(true))();
//   BoolColumn get proEnabled => boolean().withDefault(const Constant(false))();
//   IntColumn get lastSeenAt => integer().nullable()();
//   IntColumn get widgetLastUpdateAt => integer().nullable()();
//   IntColumn get createdAt => integer()();
//   IntColumn get updatedAt => integer()();
// }

// // ============================================================================
// // SYNC QUEUE
// // ============================================================================

// /// SyncQueue table - offline operation queue
// class SyncQueue extends Table {
//   TextColumn get id => text()(); // UUID
//   TextColumn get entityType =>
//       text()(); // "wash", "wash_item", "category", etc.
//   TextColumn get entityId => text()();
//   TextColumn get operation => text()(); // "create", "update", "delete"
//   TextColumn get payload => text()(); // JSON
//   IntColumn get createdAt => integer()();
//   IntColumn get retryCount => integer().withDefault(const Constant(0))();
//   TextColumn get lastError => text().nullable()();

//   @override
//   Set<Column> get primaryKey => {id};
// }

// // ============================================================================
// // DATABASE
// // ============================================================================

// @DriftDatabase(
//   tables: [
//     Users,
//     Dhobis,
//     Categories,
//     Washes,
//     WashItems,
//     WashImages,
//     Settings,
//     SyncQueue,
//   ],
// )
// class AppDatabase {
//   // Temporarily simplified database for demo mode
//   AppDatabase();

//   @override
//   int get schemaVersion => 1;

//   @override
//   MigrationStrategy get migration => MigrationStrategy(
//         onCreate: (Migrator m) async {
//           await m.createAll();
//         },
//         onUpgrade: (Migrator m, int from, int to) async {
//           // Handle future schema migrations here
//         },
//       );

//   // ============================================================================
//   // USERS QUERIES
//   // ============================================================================

//   Future<User?> getUserById(String id) =>
//       (select(users)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

//   Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

//   Future<bool> updateUser(User user) => update(users).replace(user);

//   // ============================================================================
//   // DHOBIS QUERIES
//   // ============================================================================

//   Future<List<Dhobi>> getDhobisByUser(String userId) => (select(dhobis)
//         ..where(
//           (tbl) => tbl.userId.equals(userId) & tbl.isArchived.equals(false),
//         )
//         ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
//       .get();

//   Future<Dhobi?> getDhobiById(String id) =>
//       (select(dhobis)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

//   Future<int> insertDhobi(DhobisCompanion dhobi) => into(dhobis).insert(dhobi);

//   Future<bool> updateDhobi(Dhobi dhobi) => update(dhobis).replace(dhobi);

//   // ============================================================================
//   // CATEGORIES QUERIES
//   // ============================================================================

//   Future<List<Category>> getCategoriesByUser(String userId) =>
//       (select(categories)
//             ..where(
//               (tbl) => tbl.userId.equals(userId) & tbl.isActive.equals(true),
//             )
//             ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
//           .get();

//   Future<Category?> getCategoryById(String id) =>
//       (select(categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

//   Future<int> insertCategory(CategoriesCompanion category) =>
//       into(categories).insert(category);

//   Future<bool> updateCategory(Category category) =>
//       update(categories).replace(category);

//   // ============================================================================
//   // WASHES QUERIES
//   // ============================================================================

//   Future<List<Washe>> getWashesByUser(String userId) => (select(washes)
//         ..where((tbl) => tbl.userId.equals(userId))
//         ..orderBy([(tbl) => OrderingTerm.desc(tbl.givenAt)]))
//       .get();

//   Future<List<Washe>> getPendingWashes(String userId) => (select(washes)
//         ..where(
//           (tbl) =>
//               tbl.userId.equals(userId) & tbl.status.isNotValue('returned'),
//         )
//         ..orderBy([(tbl) => OrderingTerm.asc(tbl.givenAt)]))
//       .get();

//   Future<Washe?> getWashById(String id) =>
//       (select(washes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

//   Future<int> insertWash(WashesCompanion wash) => into(washes).insert(wash);

//   Future<bool> updateWash(Washe wash) => update(washes).replace(wash);

//   Future<int> deleteWash(String id) =>
//       (delete(washes)..where((tbl) => tbl.id.equals(id))).go();

//   // ============================================================================
//   // WASH ITEMS QUERIES
//   // ============================================================================

//   Future<List<WashItem>> getWashItemsByWash(String washId) => (select(washItems)
//         ..where((tbl) => tbl.washId.equals(washId))
//         ..orderBy([(tbl) => OrderingTerm.asc(tbl.sequence)]))
//       .get();

//   Future<int> insertWashItem(WashItemsCompanion item) =>
//       into(washItems).insert(item);

//   Future<bool> updateWashItem(WashItem item) => update(washItems).replace(item);

//   Future<int> deleteWashItemsByWash(String washId) =>
//       (delete(washItems)..where((tbl) => tbl.washId.equals(washId))).go();

//   // ============================================================================
//   // WASH IMAGES QUERIES
//   // ============================================================================

//   Future<List<WashImage>> getWashImagesByWash(String washId) =>
//       (select(washImages)
//             ..where((tbl) => tbl.washId.equals(washId))
//             ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
//           .get();

//   Future<int> insertWashImage(WashImagesCompanion image) =>
//       into(washImages).insert(image);

//   Future<int> deleteWashImagesByWash(String washId) =>
//       (delete(washImages)..where((tbl) => tbl.washId.equals(washId))).go();

//   // ============================================================================
//   // SETTINGS QUERIES
//   // ============================================================================

//   Future<Setting?> getSettingsByUser(String userId) => (select(
//         settings,
//       )..where((tbl) => tbl.userId.equals(userId)))
//           .getSingleOrNull();

//   Future<int> insertSettings(SettingsCompanion setting) =>
//       into(settings).insert(setting);

//   Future<bool> updateSettings(Setting setting) =>
//       update(settings).replace(setting);

//   // ============================================================================
//   // SYNC QUEUE QUERIES
//   // ============================================================================

//   Future<List<SyncQueueData>> getPendingSyncOperations() => (select(
//         syncQueue,
//       )..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
//           .get();

//   Future<int> insertSyncOperation(SyncQueueCompanion operation) =>
//       into(syncQueue).insert(operation);

//   Future<int> deleteSyncOperation(String id) =>
//       (delete(syncQueue)..where((tbl) => tbl.id.equals(id))).go();

//   Future<bool> updateSyncOperation(SyncQueueData operation) =>
//       update(syncQueue).replace(operation);
// }

// LazyDatabase _openConnection() {
//   return LazyDatabase(() async {
//     final dbFolder = await getApplicationDocumentsDirectory();
//     final file = File(p.join(dbFolder.path, 'washlens.db'));
//     return NativeDatabase.createInBackground(file);
//   });
// }
