/** @type {import('next').NextConfig} */
const nextConfig = {
  // Static export -> writes plain HTML/CSS/JS to ./out, served directly by
  // Cloudflare Pages' CDN. No Node runtime at request time. All auth + data
  // access happens client-side against Supabase (RLS is the security boundary).
  output: "export",

  // next/image's default loader needs a server; disable optimization for export.
  images: { unoptimized: true },

  // Emit /dashboard/index.html instead of /dashboard.html so Cloudflare Pages
  // serves clean URLs without extra redirect rules.
  trailingSlash: true,

  reactStrictMode: true,
};

export default nextConfig;
