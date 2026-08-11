"use client";

import { useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/lib/auth";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { session, role, loading, user, signOut } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  // Client-side guard. Note: RLS on the database is the real security boundary;
  // this only controls what the UI renders. Unauthenticated users are bounced
  // to /login before any data component mounts.
  useEffect(() => {
    if (!loading && !session) router.replace("/login");
  }, [session, loading, router]);

  if (loading || !session) {
    return (
      <div className="login-wrap">
        <span className="spinner" />
      </div>
    );
  }

  const isActive = (href: string) =>
    href === "/dashboard"
      ? pathname === "/dashboard" || pathname === "/dashboard/"
      : pathname.startsWith(href);

  return (
    <div className="app">
      <div className="header">
        <div>
          <h1>DR Data Platform</h1>
          <p>Entergy New Orleans · Demand Response Pilot</p>
        </div>
        <div className="user-chip">
          <nav className="nav">
            <Link href="/dashboard" className={isActive("/dashboard") ? "active" : ""}>
              Load Data
            </Link>
            <Link
              href="/dashboard/baselines"
              className={isActive("/dashboard/baselines") ? "active" : ""}
            >
              Baselines
            </Link>
          </nav>
          <span>{user?.email}</span>
          <span className={`badge ${role === "admin" ? "admin" : ""}`}>{role}</span>
          <button
            className="btn"
            style={{ padding: "6px 12px" }}
            onClick={async () => {
              await signOut();
              router.replace("/login");
            }}
          >
            Sign out
          </button>
        </div>
      </div>
      {children}
    </div>
  );
}
