import type { Metadata } from "next";
import "./globals.css";
import Navbar from "@/components/layout/Navbar";

export const metadata: Metadata = {
  title: "Smart Hostel Management System",
  description: "A comprehensive hostel management and maintenance analytics system",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet" />
      </head>
      <body>
        <div className="page-wrapper">
          <Navbar />
          <main className="main-content">
            {children}
          </main>
          <footer style={{
            textAlign: 'center',
            padding: '2rem',
            color: '#6b7280',
            fontSize: '0.875rem',
            borderTop: '1px solid #e5e7eb'
          }}>
            <p style={{ margin: 0 }}>
              Smart Hostel Management System © {new Date().getFullYear()} |
              Built with Next.js, React, and PostgreSQL
            </p>
          </footer>
        </div>
      </body>
    </html>
  );
}
