/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: { optimizePackageImports: ['lucide-react'] },
  images: { domains: ['umxiqgauhfsbzlqiyelm.supabase.co'], formats: ['image/avif','image/webp'] },
  async headers() {
    return [{ source:'/:path*', headers:[
      {key:'X-Content-Type-Options',value:'nosniff'},
      {key:'X-Frame-Options',value:'DENY'},
      {key:'X-XSS-Protection',value:'1; mode=block'},
      {key:'Referrer-Policy',value:'strict-origin-when-cross-origin'},
      {key:'Permissions-Policy',value:'camera=(), microphone=(), geolocation=(self)'}
    ]}]
  }
};
module.exports = nextConfig;
