# Supabase Setup for WashLens AI

## Required Database Tables

Create the following tables in your Supabase database:

### 1. `wash_entries`
```sql
CREATE TABLE wash_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  dhobi_name TEXT NOT NULL,
  total_items INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  given_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  returned_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE wash_entries ENABLE ROW LEVEL SECURITY;

-- Allow users to manage their own data
CREATE POLICY "Users can view own wash entries" ON wash_entries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wash entries" ON wash_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wash entries" ON wash_entries
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own wash entries" ON wash_entries
  FOR DELETE USING (auth.uid() = user_id);
```

### 2. `dhobis`
```sql
CREATE TABLE dhobis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE dhobis ENABLE ROW LEVEL SECURITY;

-- Allow users to manage their own data
CREATE POLICY "Users can view own dhobis" ON dhobis
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own dhobis" ON dhobis
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own dhobis" ON dhobis
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own dhobis" ON dhobis
  FOR DELETE USING (auth.uid() = user_id);
```

### 3. `categories`
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  group TEXT NOT NULL,
  is_builtin BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  icon TEXT NOT NULL,
  color TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Allow users to manage their own data
CREATE POLICY "Users can view own categories" ON categories
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own categories" ON categories
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories" ON categories
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories" ON categories
  FOR DELETE USING (auth.uid() = user_id);
```

## Required Storage Bucket

### 1. Create Storage Bucket
1. Go to Supabase Dashboard → Storage
2. Create a new bucket named `profile-photos`
3. Set it to **Public** (so profile photos can be accessed)

### 2. Storage Policies
Create the following storage policy for the `profile-photos` bucket:

```sql
-- Allow users to upload their own profile photos
CREATE POLICY "Users can upload own profile photos" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow anyone to view profile photos
CREATE POLICY "Anyone can view profile photos" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile-photos');

-- Allow users to update their own profile photos
CREATE POLICY "Users can update own profile photos" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow users to delete their own profile photos
CREATE POLICY "Users can delete own profile photos" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

## Authentication Settings

### 1. Enable Email Confirmation (Optional)
In Supabase Dashboard → Authentication → Settings:
- Enable "Enable email confirmations" if you want email verification
- Configure email templates if needed

### 2. Enabled Providers
Make sure at least "Email" provider is enabled in Authentication → Providers.

## Environment Variables

Make sure your `.env` file contains:
```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

## Testing Setup

1. Run the app with a test user
2. Verify data export works (should create JSON with user data)
3. Test profile photo upload (requires storage bucket to be created)
4. Test account deletion (deletes user data but keeps auth account)

## Troubleshooting

### Common Issues:

1. **Profile photo upload fails**: Make sure `profile-photos` bucket exists and is public
2. **Data export returns empty**: Check that tables exist and have correct RLS policies
3. **Email update fails**: May require email confirmation setup in Supabase
4. **Delete account incomplete**: Admin.deleteUser requires service role key, currently just deletes data

### Debug Commands:
```bash
# Check table existence
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

# Check storage buckets
SELECT name, public FROM storage.buckets;
