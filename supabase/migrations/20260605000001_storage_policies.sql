-- ============================================================
-- Storage Bucket RLS Policies
-- Run this in the Supabase SQL Editor or via: supabase db push
-- ============================================================
-- Root cause: all 4 storage buckets were created with RLS
-- enabled but zero policies defined, blocking every upload
-- and signed-URL generation for authenticated users.
-- ============================================================

-- books (private) — teacher upload + student signed-URL download
CREATE POLICY "books_allow_all_authenticated"
ON storage.objects
FOR ALL
TO authenticated
USING  (bucket_id = 'books')
WITH CHECK (bucket_id = 'books');

-- recordings (private) — teacher upload + signed-URL playback
CREATE POLICY "recordings_allow_all_authenticated"
ON storage.objects
FOR ALL
TO authenticated
USING  (bucket_id = 'recordings')
WITH CHECK (bucket_id = 'recordings');

-- avatars (public) — profile picture uploads
CREATE POLICY "avatars_allow_all_authenticated"
ON storage.objects
FOR ALL
TO authenticated
USING  (bucket_id = 'avatars')
WITH CHECK (bucket_id = 'avatars');

-- course-thumbnails (public) — course thumbnail uploads
CREATE POLICY "thumbnails_allow_all_authenticated"
ON storage.objects
FOR ALL
TO authenticated
USING  (bucket_id = 'course-thumbnails')
WITH CHECK (bucket_id = 'course-thumbnails');
