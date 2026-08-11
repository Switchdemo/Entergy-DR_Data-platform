"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth";

export default function LoginPage() {
  const { session, loading, signIn } = useAuth();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Already signed in -> bounce to the dashboard.
  useEffect(() => {
    if (!loading && session) router.replace("/dashboard");
  }, [session, loading, router]);

  const onSubmit = async () => {
    setError(null);
    setSubmitting(true);
    const { error } = await signIn(email.trim(), password);
    setSubmitting(false);
    if (error) setError(error);
    // On success, onAuthStateChange fires and the effect above redirects.
  };

  return (
    <div className="login-wrap">
      <div className="login-card">
        <h1>DR Data Platform</h1>
        <p className="sub">Entergy New Orleans · Demand Response Pilot</p>

        {error && <div className="error-box">{error}</div>}

        <div className="field">
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && onSubmit()}
          />
        </div>
        <div className="field">
          <label htmlFor="password">Password</label>
          <input
            id="password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && onSubmit()}
          />
        </div>

        <button
          className="btn btn-primary login-btn"
          onClick={onSubmit}
          disabled={submitting || !email || !password}
        >
          {submitting ? "Signing in…" : "Sign in"}
        </button>
      </div>
    </div>
  );
}
