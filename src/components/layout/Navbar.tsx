'use client';

/**
 * Navbar Component
 * =================
 * Main navigation component with role-based links.
 */

import Link from 'next/link';
import { usePathname } from 'next/navigation';

export default function Navbar() {
    const pathname = usePathname();

    const isActive = (path: string) => {
        return pathname?.startsWith(path);
    };

    return (
        <nav className="bg-gradient-to-br from-indigo-950 to-indigo-900 sticky top-0 z-50 shadow-lg px-6">
            <div className="max-w-7xl mx-auto flex items-center justify-between h-16">
                <Link href="/" className="flex items-center gap-3 decoration-0 group">
                    <span className="text-2xl group-hover:scale-110 transition-transform">🏠</span>
                    <span className="text-xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-violet-300 to-fuchsia-300">HostelMS</span>
                </Link>

                <div className="hidden md:flex items-center gap-2">
                    <Link
                        href="/admin"
                        className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${isActive('/admin')
                                ? 'bg-white/15 text-white'
                                : 'text-white/70 hover:text-white hover:bg-white/10'
                            }`}
                    >
                        Admin Portal
                    </Link>
                    <Link
                        href="/student"
                        className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${isActive('/student')
                                ? 'bg-white/15 text-white'
                                : 'text-white/70 hover:text-white hover:bg-white/10'
                            }`}
                    >
                        Student Portal
                    </Link>
                    <Link
                        href="/admin/analytics"
                        className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${isActive('/admin/analytics')
                                ? 'bg-white/15 text-white'
                                : 'text-white/70 hover:text-white hover:bg-white/10'
                            }`}
                    >
                        Analytics
                    </Link>
                </div>

                <div className="flex items-center gap-4">
                    <span className="px-3 py-1 bg-amber-500/20 text-amber-400 text-xs font-semibold rounded-full border border-amber-500/30">Demo Mode</span>
                </div>
            </div>
        </nav>
    );
}


