import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  reactCompiler: true,

  // Allow CORS for Flutter app
  async headers() {
    return [];
  },
};

export default nextConfig;

