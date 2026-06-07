/** @type {import('next').NextConfig} */
const nextConfig = {
  async headers() {
    return [
      {
        // Apply CORS headers to all API routes
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,POST,PUT,PATCH,DELETE,OPTIONS' },
          // x-session is the custom header Flutter sends for auth (Cookie is blocked by browsers)
          { key: 'Access-Control-Allow-Headers', value: 'Content-Type, Authorization, Cookie, x-session' },
        ],
      },
    ];
  },
};

export default nextConfig;
