"use client";

import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import type { Session, User } from "@supabase/supabase-js";
import { supabase } from "./supabase";

export type Role = "admin" | "customer";

interface AuthState {
  session: Session | null;
  user: User | null;
  role: Role | null;
  loading: boolean; // true until the initial session check completes
  signIn: (email: string, password: string) => Promise<{ error: string | null }>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthState | undefined>(undefined);

// ---------------------------------------------------------------------------
// ROLE RESOLUTION — SCHEMA ASSUMPTION.
//
// The role can live in several places depending on how you provisioned it.
// This resolves in priority order and returns the first match. Edit this ONE
// function to match your setup; the rest of the app just reads `role`.
//
//   1. JWT app_metadata.role  (set via the admin API / a signup trigger — the
//      most robust option because RLS policies can read it directly)
//   2. JWT user_metadata.role (set at signup; user-editable, less secure)
//   3. A `profiles` table row: profiles.id = auth.uid(), column `role`
//
// If you use a different table/column, change the query in branch 3.
// ---------------------------------------------------------------------------
async function resolveRole(user: User): Promise<Role> {
  const appRole = user.app_metadata?.role;
  if (appRole === "admin" || appRole === "customer") return appRole;

  const metaRole = user.user_metadata?.role;
  if (metaRole === "admin" || metaRole === "customer") return metaRole;

  const { data, error } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();

  if (!error && (data?.role === "admin" || data?.role === "customer")) {
    return data.role;
  }

  // Safe default: least privilege. A customer only ever sees their own sites
  // via RLS, so defaulting here never leaks data even if role lookup fails.
  return "customer";
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [role, setRole] = useState<Role | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;

    async function applySession(s: Session | null) {
      if (!active) return;
      setSession(s);
      setUser(s?.user ?? null);
      if (s?.user) {
        const r = await resolveRole(s.user);
        if (active) setRole(r);
      } else {
        setRole(null);
      }
      if (active) setLoading(false);
    }

    supabase.auth.getSession().then(({ data }) => applySession(data.session));

    const { data: sub } = supabase.auth.onAuthStateChange((_event, s) => {
      applySession(s);
    });

    return () => {
      active = false;
      sub.subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    return { error: error ? error.message : null };
  };

  const signOut = async () => {
    await supabase.auth.signOut();
  };

  return (
    <AuthContext.Provider
      value={{ session, user, role, loading, signIn, signOut }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within <AuthProvider>");
  return ctx;
}
