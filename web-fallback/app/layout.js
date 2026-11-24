import './globals.css';

export const metadata = { title: 'VibeDrop', description: 'Your digital identity, one QR.' };

export default function RootLayout({ children }) {
  return <html lang="en"><body>{children}</body></html>;
}
