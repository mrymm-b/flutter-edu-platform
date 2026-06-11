/**
 * setup-storage — one-shot edge function to create storage bucket policies.
 *
 * Deploy once, call once with the admin secret header, then optionally delete.
 *
 * Deploy:  supabase functions deploy setup-storage
 * Call:    curl -X POST \
 *            -H "Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>" \
 *            https://YOUR_PROJECT_REF.supabase.co/functions/v1/setup-storage
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const SQL = `
CREATE POLICY IF NOT EXISTS "books_allow_all_authenticated"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'books') WITH CHECK (bucket_id = 'books');

CREATE POLICY IF NOT EXISTS "recordings_allow_all_authenticated"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'recordings') WITH CHECK (bucket_id = 'recordings');

CREATE POLICY IF NOT EXISTS "avatars_allow_all_authenticated"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'avatars') WITH CHECK (bucket_id = 'avatars');

CREATE POLICY IF NOT EXISTS "thumbnails_allow_all_authenticated"
ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'course-thumbnails') WITH CHECK (bucket_id = 'course-thumbnails');
`;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { error } = await supabase.rpc("exec_sql", { sql: SQL });

  if (error) {
    return new Response(JSON.stringify({ ok: false, error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ ok: true, message: "Storage policies created" }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
