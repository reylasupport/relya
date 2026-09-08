import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

export interface Caller {
  userId: string;
  /** Acts as the user: every query is still subject to Row Level Security. */
  db: SupabaseClient;
  /** Bypasses RLS. Only for writes the user must not be able to forge, such
   *  as usage accounting, and never for reads of another user data. */
  admin: SupabaseClient;
}

/**
 * Resolves the caller from the Authorization header.
 *
 * Anonymous access is never allowed on these functions: they all touch
 * personal data or spend money.
 */
export async function requireCaller(req: Request): Promise<Caller> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) throw new Response("Missing authorization", { status: 401 });

  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const db = createClient(url, anon, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  const { data, error } = await db.auth.getUser();
  if (error || !data.user) {
    throw new Response("Invalid session", { status: 401 });
  }

  const admin = createClient(url, service, { auth: { persistSession: false } });

  return { userId: data.user.id, db, admin };
}
