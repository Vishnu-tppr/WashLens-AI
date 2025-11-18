# WashLens AI - Database Schema

## Overview

WashLens AI uses a dual-database architecture:
- **SQLite (Drift)** for local, offline-first storage
- **Cloud Firestore** for cloud sync and backup

Both databases maintain parallel schemas with sync metadata in SQLite.

---

## SQLite Schema (Drift)

### Table: `users`

Stores user profile information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | Firebase UID |
| `display_name` | TEXT | NOT NULL | User's display name |
| `email` | TEXT | NOT NULL | User's email address |
| `created_at` | INTEGER | NOT NULL | Timestamp (milliseconds since epoch) |
| `updated_at` | INTEGER | NOT NULL | Timestamp (milliseconds since epoch) |

**Indexes:**
- PRIMARY KEY on `id`

---

### Table: `dhobis`

Stores laundry service provider information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID |
| `user_id` | TEXT | NOT NULL, FK → users.id | Owner user |
| `name` | TEXT | NOT NULL | Dhobi/service name |
| `phone` | TEXT | NULL | Contact phone number |
| `notes` | TEXT | NULL | Additional notes |
| `created_at` | INTEGER | NOT NULL | Timestamp |
| `updated_at` | INTEGER | NOT NULL | Timestamp |
| `is_archived` | BOOLEAN | NOT NULL, DEFAULT FALSE | Soft delete flag |

**Indexes:**
- PRIMARY KEY on `id`
- INDEX on `user_id`
- INDEX on `(user_id, is_archived)`

---

### Table: `categories`

Stores cloth categories (both built-in and custom).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID or slug (e.g., "shirt") |
| `user_id` | TEXT | NOT NULL | Owner user |
| `name` | TEXT | NOT NULL | Display name (e.g., "Shirts") |
| `slug` | TEXT | NOT NULL | URL-safe identifier (e.g., "shirt") |
| `group` | TEXT | NOT NULL | "upper", "lower", "others" |
| `is_builtin` | BOOLEAN | NOT NULL, DEFAULT FALSE | System category flag |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | Visibility toggle |
| `sort_order` | INTEGER | NOT NULL | Display order |
| `icon` | TEXT | NOT NULL | Icon name (MaterialIcons) |
| `color` | TEXT | NOT NULL | Hex color code (e.g., "#5B9BF3") |
| `created_at` | INTEGER | NOT NULL | Timestamp |
| `updated_at` | INTEGER | NOT NULL | Timestamp |

**Indexes:**
- PRIMARY KEY on `id`
- INDEX on `(user_id, is_active, sort_order)`

**Built-in Categories:**
| ID | Name | Slug | Group | Icon | Color |
|----|------|------|-------|------|-------|
| shirt | Shirts | shirt | upper | checkroom | #5B9BF3 |
| tshirt | T-Shirts | tshirt | upper | checkroom_outlined | #6FCF97 |
| pants | Pants | pants | lower | man | #9B59B6 |
| shorts | Shorts | shorts | lower | man_outlined | #F39C12 |
| track_pant | Track Pants | track_pant | lower | directions_run | #3498DB |
| towel | Towels | towel | others | dry_cleaning | #E67E22 |
| socks | Socks (Pairs) | socks | others | accessibility | #E74C3C |
| bedsheet | Bedsheets | bedsheet | others | bed | #1ABC9C |

---

### Table: `washes`

Stores each laundry session.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID |
| `user_id` | TEXT | NOT NULL | Owner user |
| `dhobi_id` | TEXT | NOT NULL, FK → dhobis.id | Service provider |
| `status` | TEXT | NOT NULL | "given", "partial_return", "returned" |
| `given_at` | INTEGER | NOT NULL | When clothes were given |
| `expected_return_at` | INTEGER | NULL | Expected return timestamp |
| `returned_at` | INTEGER | NULL | When clothes were returned |
| `notes` | TEXT | NULL | User notes |
| `total_items_given` | INTEGER | NOT NULL | Total count given |
| `total_items_returned` | INTEGER | NOT NULL | Total count returned |
| `total_missing` | INTEGER | NOT NULL | Missing count |
| `total_extra` | INTEGER | NOT NULL | Extra items count |
| `risk_level` | TEXT | NULL | "low", "medium", "high" (pro feature) |
| `created_at` | INTEGER | NOT NULL | Timestamp |
| `updated_at` | INTEGER | NOT NULL | Timestamp |
| `remote_id` | TEXT | NULL | Firestore document ID |
| `sync_status` | TEXT | NOT NULL | "pending_create", "pending_update", "synced", "pending_delete" |

**Indexes:**
- PRIMARY KEY on `id`
- INDEX on `(user_id, status, given_at DESC)`
- INDEX on `(user_id, dhobi_id)`
- INDEX on `sync_status`

---

### Table: `wash_items`

Stores individual cloth items in each wash.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID |
| `wash_id` | TEXT | NOT NULL, FK → washes.id | Parent wash |
| `category_id` | TEXT | NOT NULL, FK → categories.id | Cloth category |
| `sequence` | INTEGER | NOT NULL | Item number (for checklist: Shirt 1, Shirt 2...) |
| `color` | TEXT | NULL | Detected/user-entered color (e.g., "blue") |
| `pattern` | TEXT | NULL | "checks", "plain", "stripes", "dots", "logo" |
| `logo` | BOOLEAN | NOT NULL, DEFAULT FALSE | Has visible logo/print |
| `collar_type` | TEXT | NULL | "none", "round", "polo", "shirt_collar" |
| `status` | TEXT | NOT NULL | "given", "returned", "missing", "extra" |
| `given_count` | INTEGER | NOT NULL | Usually 1 |
| `returned_count` | INTEGER | NOT NULL | 0 or 1 (or more for bulk items like socks) |
| `image_local_path` | TEXT | NULL | Path to cropped image patch |
| `image_remote_url` | TEXT | NULL | Firebase Storage URL |
| `created_at` | INTEGER | NOT NULL | Timestamp |
| `updated_at` | INTEGER | NOT NULL | Timestamp |

**Indexes:**
- PRIMARY KEY on `id`
- INDEX on `(wash_id, sequence)`
- INDEX on `(wash_id, status)`

---

### Table: `wash_images`

Stores multiple photos per wash (given/returned).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID |
| `wash_id` | TEXT | NOT NULL, FK → washes.id | Parent wash |
| `role` | TEXT | NOT NULL | "given", "returned" |
| `local_path` | TEXT | NOT NULL | App sandbox file path |
| `remote_path` | TEXT | NULL | Firebase Storage path |
| `remote_url` | TEXT | NULL | Public download URL |
| `width` | INTEGER | NULL | Image width in pixels |
| `height` | INTEGER | NULL | Image height in pixels |
| `created_at` | INTEGER | NOT NULL | Timestamp |

**Indexes:**
- PRIMARY KEY on `id`
- INDEX on `(wash_id, role)`

---

### Table: `settings`

Stores user preferences (single row per user).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Row ID |
| `user_id` | TEXT | NOT NULL, UNIQUE | Owner user |
| `reminder_days` | INTEGER | NOT NULL, DEFAULT 3 | Days before reminder |
| `drying_base_hours` | INTEGER | NOT NULL, DEFAULT 24 | Base drying time |
| `use_cloud_backup` | BOOLEAN | NOT NULL, DEFAULT TRUE | Enable Firebase sync |
| `pro_enabled` | BOOLEAN | NOT NULL, DEFAULT FALSE | Pro features enabled |
| `last_seen_at` | INTEGER | NULL | Last app open timestamp |
| `widget_last_update_at` | INTEGER | NULL | Last widget update timestamp |
| `created_at` | INTEGER | NOT NULL | Timestamp |
| `updated_at` | INTEGER | NOT NULL | Timestamp |

**Indexes:**
- PRIMARY KEY on `id`
- UNIQUE INDEX on `user_id`

---

### Table: `sync_queue`

Queues offline operations for later sync.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID |
| `entity_type` | TEXT | NOT NULL | "wash", "wash_item", "dhobi", "category" |
| `entity_id` | TEXT | NOT NULL | Entity UUID |
| `operation` | TEXT | NOT NULL | "create", "update", "delete" |
| `payload` | TEXT | NOT NULL | JSON serialized entity data |
| `created_at` | INTEGER | NOT NULL | Timestamp |
| `retry_count` | INTEGER | NOT NULL, DEFAULT 0 | Retry attempts |
| `last_error` | TEXT | NULL | Last error message |

**Indexes:**
- PRIMARY KEY on `id`
- INDEX on `(created_at ASC)` (FIFO processing)

---

## Firestore Schema

### Collection: `users/{uid}`

**Document Fields:**
```json
{
  "displayName": "John Doe",
  "email": "john.doe@university.com",
  "createdAt": 1700000000000,
  "updatedAt": 1700100000000,
  "proEnabled": false,
  "lastSeenAt": 1700200000000
}
```

---

### Subcollection: `users/{uid}/dhobis/{dhobiId}`

**Document Fields:**
```json
{
  "id": "uuid-1234",
  "name": "Raju Dhobi",
  "phone": "+91-9876543210",
  "notes": "Near hostel gate",
  "isArchived": false,
  "createdAt": 1700000000000,
  "updatedAt": 1700100000000
}
```

---

### Subcollection: `users/{uid}/categories/{categoryId}`

**Document Fields:**
```json
{
  "id": "shirt",
  "name": "Shirts",
  "slug": "shirt",
  "group": "upper",
  "isBuiltin": true,
  "isActive": true,
  "sortOrder": 1,
  "icon": "checkroom",
  "color": "#5B9BF3",
  "createdAt": 1700000000000,
  "updatedAt": 1700100000000
}
```

---

### Subcollection: `users/{uid}/washes/{washId}`

**Document Fields:**
```json
{
  "id": "uuid-5678",
  "dhobiId": "uuid-1234",
  "status": "given",
  "givenAt": 1731619200000,
  "expectedReturnAt": 1731878400000,
  "returnedAt": null,
  "notes": "Please use gentle detergent for blue shirt",
  "totalItemsGiven": 15,
  "totalItemsReturned": 0,
  "totalMissing": 0,
  "totalExtra": 0,
  "riskLevel": null,
  "createdAt": 1731619200000,
  "updatedAt": 1731619200000
}
```

---

### Subcollection: `users/{uid}/washes/{washId}/items/{itemId}`

**Document Fields:**
```json
{
  "id": "uuid-item-1",
  "categoryId": "shirt",
  "sequence": 1,
  "color": "blue",
  "pattern": "checks",
  "logo": false,
  "collarType": "shirt_collar",
  "status": "given",
  "givenCount": 1,
  "returnedCount": 0,
  "imageRemoteUrl": "https://storage.googleapis.com/...",
  "createdAt": 1731619200000,
  "updatedAt": 1731619200000
}
```

---

### Subcollection: `users/{uid}/washes/{washId}/images/{imageId}`

**Document Fields:**
```json
{
  "id": "uuid-img-1",
  "role": "given",
  "remotePath": "users/uid123/washes/wash456/given/img789.jpg",
  "remoteUrl": "https://storage.googleapis.com/...",
  "width": 1920,
  "height": 1080,
  "createdAt": 1731619200000
}
```

---

### Subcollection: `users/{uid}/stats/monthly/{yyyyMM}`

**Document Fields (aggregated):**
```json
{
  "month": "2024-11",
  "totalItemsGiven": 120,
  "totalItemsReturned": 115,
  "totalMissing": 5,
  "totalExtra": 0,
  "mostMissingCategory": "socks",
  "mostMissingCount": 3,
  "dhobiStats": {
    "uuid-1234": {
      "name": "Raju Dhobi",
      "totalWashes": 4,
      "totalMissing": 3,
      "averageDelay": 0.5  // days
    }
  },
  "updatedAt": 1731619200000
}
```

---

### Subcollection: `users/{uid}/riskProfiles/{dhobiId}`

**Document Fields (pro feature):**
```json
{
  "dhobiId": "uuid-1234",
  "dhobiName": "Raju Dhobi",
  "riskLevel": "high",
  "riskScore": 0.78,
  "totalWashes": 15,
  "totalMissing": 8,
  "averageDelay": 1.2,
  "likelyMissingCategory": "tshirt",
  "recommendation": "Avoid giving t-shirts. Consider marking with permanent marker.",
  "lastAnalyzedAt": 1731619200000
}
```

---

## Sync Strategy

### Offline → Online Sync

1. **Queue Operations:** All local changes (create/update/delete) added to `sync_queue`
2. **Batch Processing:** On connectivity, `SyncService` processes queue in FIFO order
3. **Conflict Resolution:** Last-write-wins based on `updatedAt` timestamp
4. **Retry Logic:** Failed operations retry with exponential backoff (max 3 attempts)
5. **Image Uploads:** Images uploaded first; then document with `remoteUrl`

### Online → Offline Pull

- On fresh install or explicit restore: Pull all Firestore data into SQLite
- Incremental sync not implemented in MVP (full pull only)

---

## Indexes for Performance

### SQLite

```sql
CREATE INDEX idx_washes_user_status ON washes(user_id, status, given_at DESC);
CREATE INDEX idx_wash_items_wash ON wash_items(wash_id, sequence);
CREATE INDEX idx_sync_queue_created ON sync_queue(created_at ASC);
```

### Firestore

Composite indexes (auto-created via Firebase console):
- `washes`: `status` ASC, `givenAt` DESC
- `wash_items`: `status` ASC, `sequence` ASC

---

## Sample Data

### Sample Wash Entry (JSON)

```json
{
  "wash": {
    "id": "w-001",
    "userId": "user-123",
    "dhobiId": "dhobi-raju",
    "status": "partial_return",
    "givenAt": 1731532800000,
    "expectedReturnAt": 1731792000000,
    "returnedAt": null,
    "notes": "Handle with care",
    "totalItemsGiven": 10,
    "totalItemsReturned": 8,
    "totalMissing": 2,
    "totalExtra": 0,
    "riskLevel": "medium",
    "createdAt": 1731532800000,
    "updatedAt": 1731619200000
  },
  "items": [
    {
      "id": "item-001",
      "washId": "w-001",
      "categoryId": "shirt",
      "sequence": 1,
      "color": "blue",
      "pattern": "plain",
      "status": "returned",
      "givenCount": 1,
      "returnedCount": 1
    },
    {
      "id": "item-002",
      "washId": "w-001",
      "categoryId": "tshirt",
      "sequence": 2,
      "color": "white",
      "pattern": "logo",
      "status": "missing",
      "givenCount": 1,
      "returnedCount": 0
    }
  ],
  "images": [
    {
      "id": "img-001",
      "washId": "w-001",
      "role": "given",
      "localPath": "/data/user/0/.../image_001.jpg",
      "remoteUrl": "https://storage.googleapis.com/.../image_001.jpg"
    }
  ]
}
```

---

**Document Version:** 1.0  
**Last Updated:** November 15, 2025
