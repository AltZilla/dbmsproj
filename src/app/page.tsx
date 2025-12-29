import Link from 'next/link';
// import styles from './page.module.css';

/**
 * Landing Page
 * =============
 * Main entry point with links to Student and Admin portals.
 */
export default function Home() {
  return (
    <div className="min-h-[calc(100vh-144px)] bg-gradient-to-br from-slate-50 via-indigo-50 to-purple-50 py-16 px-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-5xl font-extrabold text-indigo-950 text-center mb-6 leading-tight">
          Smart Hostel Management
          <span className="text-transparent bg-clip-text bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500"> & Analytics</span>
        </h1>
        <p className="text-xl text-gray-500 text-center max-w-3xl mx-auto mb-12 leading-relaxed">
          A comprehensive system for managing hostel operations, room allocations,
          fee payments, and maintenance complaints with powerful analytics.
        </p>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16 max-w-6xl mx-auto">
          <Link href="/student" className="bg-white rounded-2xl p-8 hover:-translate-y-1 hover:shadow-2xl hover:shadow-indigo-500/15 hover:border-indigo-200 transition-all border border-transparent group flex flex-col items-start">
            <div className="text-4xl mb-4">🎓</div>
            <h2 className="text-xl font-semibold text-indigo-950 mb-3">Student Portal</h2>
            <p className="text-gray-500 text-sm leading-relaxed mb-4">View room details, check payment status, and raise maintenance complaints.</p>
            <span className="text-sm font-semibold text-indigo-500 group-hover:text-indigo-600 transition-colors mt-auto">Enter Portal →</span>
          </Link>

          <Link href="/admin" className="bg-white rounded-2xl p-8 hover:-translate-y-1 hover:shadow-2xl hover:shadow-indigo-500/15 hover:border-indigo-200 transition-all border border-transparent group flex flex-col items-start">
            <div className="text-4xl mb-4">⚙️</div>
            <h2 className="text-xl font-semibold text-indigo-950 mb-3">Admin Portal</h2>
            <p className="text-gray-500 text-sm leading-relaxed mb-4">Manage students, rooms, allocations, and track maintenance requests.</p>
            <span className="text-sm font-semibold text-indigo-500 group-hover:text-indigo-600 transition-colors mt-auto">Enter Portal →</span>
          </Link>

          <Link href="/admin/analytics" className="bg-white rounded-2xl p-8 hover:-translate-y-1 hover:shadow-2xl hover:shadow-indigo-500/15 hover:border-indigo-200 transition-all border border-transparent group flex flex-col items-start">
            <div className="text-4xl mb-4">📊</div>
            <h2 className="text-xl font-semibold text-indigo-950 mb-3">Analytics Dashboard</h2>
            <p className="text-gray-500 text-sm leading-relaxed mb-4">View complaint statistics, resolution times, and maintenance trends.</p>
            <span className="text-sm font-semibold text-indigo-500 group-hover:text-indigo-600 transition-colors mt-auto">View Analytics →</span>
          </Link>
        </div>

        <div className="bg-white rounded-3xl p-12 mb-12 shadow-sm border border-slate-100 max-w-6xl mx-auto">
          <h3 className="text-2xl font-bold text-indigo-950 text-center mb-8">Key Features</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            <div className="flex gap-4 items-start">
              <span className="text-2xl shrink-0">🏠</span>
              <div>
                <h4 className="text-base font-semibold text-slate-700 mb-1">Room Management</h4>
                <p className="text-sm text-gray-500 leading-relaxed">Manage rooms with capacity constraints and automatic occupancy tracking</p>
              </div>
            </div>
            <div className="flex gap-4 items-start">
              <span className="text-2xl shrink-0">👥</span>
              <div>
                <h4 className="text-base font-semibold text-slate-700 mb-1">Student Allocation</h4>
                <p className="text-sm text-gray-500 leading-relaxed">Smart allocation system with gender validation and overflow prevention</p>
              </div>
            </div>
            <div className="flex gap-4 items-start">
              <span className="text-2xl shrink-0">💳</span>
              <div>
                <h4 className="text-base font-semibold text-slate-700 mb-1">Payment Tracking</h4>
                <p className="text-sm text-gray-500 leading-relaxed">Track fees, due dates, and payment statuses for all students</p>
              </div>
            </div>
            <div className="flex gap-4 items-start">
              <span className="text-2xl shrink-0">🔧</span>
              <div>
                <h4 className="text-base font-semibold text-slate-700 mb-1">Maintenance System</h4>
                <p className="text-sm text-gray-500 leading-relaxed">Complete complaint workflow with staff assignment and status tracking</p>
              </div>
            </div>
            <div className="flex gap-4 items-start">
              <span className="text-2xl shrink-0">📈</span>
              <div>
                <h4 className="text-base font-semibold text-slate-700 mb-1">Analytics & Reports</h4>
                <p className="text-sm text-gray-500 leading-relaxed">Visual charts showing complaint patterns, resolution times, and trends</p>
              </div>
            </div>
            <div className="flex gap-4 items-start">
              <span className="text-2xl shrink-0">🔒</span>
              <div>
                <h4 className="text-base font-semibold text-slate-700 mb-1">Database Triggers</h4>
                <p className="text-sm text-gray-500 leading-relaxed">Automatic capacity control and audit logging at database level</p>
              </div>
            </div>
          </div>
        </div>

        <div className="text-center">
          <h3 className="text-xl font-semibold text-slate-700 mb-6">DBMS Concepts Demonstrated</h3>
          <div className="flex flex-wrap justify-center gap-3">
            {['Normalized Schema', 'Foreign Keys', 'Triggers', 'SQL Views', 'JOINs', 'GROUP BY', 'Aggregate Functions', 'Transactions', 'Connection Pooling', 'Parameterized Queries'].map((tag) => (
              <span key={tag} className="px-4 py-2 bg-indigo-50 text-indigo-700 text-sm font-medium rounded-full border border-indigo-200">
                {tag}
              </span>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

