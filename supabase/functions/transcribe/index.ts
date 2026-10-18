import { createClient } from "npm:@supabase/supabase-js@2.118.0";
import { createHandler } from "./handler.ts";

const client = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false },
});
Deno.serve(createHandler({
  authenticate: async (token) => {
    const { data, error } = await client.auth.getUser(token);
    return !error && !!data.user && !data.user.is_anonymous;
  },
  key: Deno.env.get("AZURE_SPEECH_KEY"),
  region: Deno.env.get("AZURE_SPEECH_REGION"),
  fetch,
}));
