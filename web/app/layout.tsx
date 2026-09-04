import type { Metadata, Viewport } from 'next';
import './globals.css';
export const metadata: Metadata = {
  title: { default:'RETRACE — Device Recovery & Tracking', template:'%s · RETRACE' },
  description:'A complete device recovery ecosystem. Find and secure lost devices across online, offline, and limited-connectivity scenarios. Platform-honest, offline-first, anti-stalking.',
  applicationName:'RETRACE',
  keywords:['device recovery','find my device','lost phone','tracking','security','android'],
  robots:{ index:true, follow:true }
};
export const viewport: Viewport = {
  themeColor:[{media:'(prefers-color-scheme: dark)',color:'#0b0f14'},{media:'(prefers-color-scheme: light)',color:'#f7fafc'}],
  width:'device-width', initialScale:1
};
export default function RootLayout({children}:{children:React.ReactNode}){
  return <html lang="en" className="dark antialiased"><body>{children}</body></html>;
}
