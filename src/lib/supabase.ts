import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!url || !anonKey) {
  // Surfaced at build time and in the browser console if env vars are missing.
  throw new Error(
    "Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_SUPABASE_ANON_KEY. " +
      "Copy .env.local.example to .env.local (local) or set them in the " +
      "Cloudflare Pages project settings (production)."
  );
}

// Single browser client for the whole app. Session persists in localStorage and
// is auto-refreshed. Because this is a static export there is no server, so all
// requests carry the logged-in user's JWT and RLS filters the results.
export const supabase: SupabaseClient = createClient(url, anonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
});
