'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import {
    LayoutDashboard,
    Wallet,
    ArrowLeftRight,
    HandCoins,
    TrendingUp,
    Menu,
    X,
    DollarSign,
    Settings,
    LogOut,
    UserCircle,
} from 'lucide-react';
import { useAuth } from '@/context/AuthContext';

const navItems = [
    { href: '/', label: 'Dashboard', icon: LayoutDashboard },
    { href: '/accounts', label: 'Accounts', icon: Wallet },
    { href: '/transactions', label: 'Transactions', icon: ArrowLeftRight },
    { href: '/credits', label: 'Credits', icon: HandCoins },
    { href: '/insights', label: 'Insights', icon: TrendingUp },
    { href: '/settings', label: 'Settings', icon: Settings },
];

export default function Sidebar() {
    const pathname = usePathname();
    const [mobileOpen, setMobileOpen] = useState(false);
    const { user, logout } = useAuth();

    // Helper to get initials from name
    const getInitials = (name: string) => {
        if (!name) return 'U';
        return name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
    };

    const navContent = (
        <nav className="flex flex-col gap-3 mt-10 px-1">
            {navItems.map((item) => {
                const isActive = pathname === item.href;
                const Icon = item.icon;
                return (
                    <Link
                        key={item.href}
                        href={item.href}
                        onClick={() => setMobileOpen(false)}
                        style={{ padding: '14px 20px' }}
                        className={`relative overflow-hidden flex items-center gap-3 rounded-xl text-sm font-medium transition-all duration-200 ${isActive
                            ? 'bg-violet-500/15 text-violet-400 shadow-sm'
                            : 'text-slate-400 hover:text-slate-200 hover:bg-white/5'
                            }`}
                    >
                        {isActive && (
                            <motion.div
                                layoutId="activeTab"
                                className="absolute left-0 inset-y-0 w-1 bg-violet-400 rounded-l-xl rounded-r-none z-10"
                            />
                        )}
                        <Icon size={20} />
                        <span>{item.label}</span>
                    </Link>
                );
            })}
        </nav>
    );

    return (
        <>
            {/* Desktop Sidebar */}
            <aside className="hidden lg:flex flex-col w-64 min-h-screen border-r border-border bg-[#0c1322] p-6 fixed top-0 left-0 z-40">
                <div className="flex items-center gap-3 px-4 py-4">
                    <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-violet-500 to-indigo-600 flex items-center justify-center">
                        <DollarSign size={20} className="text-white" />
                    </div>
                    <div>
                        <h1 className="text-base font-bold text-white">FinanceApp</h1>
                        <p className="text-xs text-muted">Personal Finance</p>
                    </div>
                </div>
                <div className="mt-2 border-b border-border/50" />
                <div className="flex-1 overflow-y-auto">
                    {navContent}
                </div>

                {/* User Profile Section (Desktop) */}
                <div className="mt-auto pt-4 border-t border-border/50 space-y-2">
                    {user && (
                        <Link
                            href="/profile"
                            className="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-white/5 transition-all text-left"
                        >
                            {user.profilePicture ? (
                                <img src={user.profilePicture} alt="Profile" className="w-10 h-10 rounded-full object-cover border border-white/10 shrink-0" />
                            ) : (
                                <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center border border-white/10 shrink-0 text-slate-300 font-medium text-sm tracking-wide">
                                    {getInitials(user.name)}
                                </div>
                            )}
                            <div className="overflow-hidden">
                                <p className="text-sm font-medium text-white truncate">{user.name}</p>
                                <p className="text-xs text-muted truncate">View Profile</p>
                            </div>
                        </Link>
                    )}
                    <button
                        onClick={logout}
                        className="flex items-center gap-3 px-5 py-3.5 text-rose-400 font-medium hover:bg-rose-500/10 rounded-xl transition-all w-full text-sm"
                    >
                        <LogOut size={18} />
                        <span>Sign Out</span>
                    </button>
                </div>
            </aside>

            {/* Mobile Header */}
            <header className="lg:hidden fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-5 h-[60px] bg-[#0c1322] border-b border-border">
                <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-violet-500 to-indigo-600 flex items-center justify-center">
                        <DollarSign size={16} className="text-white" />
                    </div>
                    <h1 className="text-sm font-bold text-white">FinanceApp</h1>
                </div>
                <button
                    onClick={() => setMobileOpen(!mobileOpen)}
                    className="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-white/10 transition-colors"
                >
                    {mobileOpen ? <X size={22} /> : <Menu size={22} />}
                </button>
            </header>

            {/* Mobile Overlay */}
            <AnimatePresence>
                {mobileOpen && (
                    <>
                        <motion.div
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            onClick={() => setMobileOpen(false)}
                            className="lg:hidden fixed inset-0 z-50 bg-black/60 backdrop-blur-sm"
                        />
                        <motion.aside
                            initial={{ x: -280 }}
                            animate={{ x: 0 }}
                            exit={{ x: -280 }}
                            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
                            className="lg:hidden fixed top-0 left-0 bottom-0 z-[60] w-[280px] bg-[#0c1322] border-r border-border p-5 overflow-y-auto"
                        >
                            <div className="flex items-center justify-between px-4 py-3">
                                <div className="flex items-center gap-3">
                                    <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-violet-500 to-indigo-600 flex items-center justify-center">
                                        <DollarSign size={20} className="text-white" />
                                    </div>
                                    <h1 className="text-base font-bold text-white">FinanceApp</h1>
                                </div>
                                <button
                                    onClick={() => setMobileOpen(false)}
                                    className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-white/10"
                                >
                                    <X size={20} />
                                </button>
                            </div>
                            {navContent}

                            {/* User Profile Section (Mobile) */}
                            <div className="mt-8 pt-4 border-t border-border/50 space-y-2">
                                {user && (
                                    <Link
                                        href="/profile"
                                        onClick={() => setMobileOpen(false)}
                                        className="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-white/5 transition-all text-left"
                                    >
                                        {user.profilePicture ? (
                                            <img src={user.profilePicture} alt="Profile" className="w-8 h-8 rounded-full object-cover border border-white/10 shrink-0" />
                                        ) : (
                                            <div className="w-8 h-8 rounded-full bg-slate-800 flex items-center justify-center border border-white/10 shrink-0 text-slate-300 font-medium text-sm tracking-wide">
                                                {getInitials(user.name)}
                                            </div>
                                        )}
                                        <div className="overflow-hidden">
                                            <p className="text-sm font-medium text-white truncate">{user.name}</p>
                                            <p className="text-xs text-muted truncate">View Profile</p>
                                        </div>
                                    </Link>
                                )}
                                <button
                                    onClick={logout}
                                    className="flex items-center gap-3 px-5 py-3.5 text-rose-400 font-medium hover:bg-rose-500/10 rounded-xl transition-all w-full text-sm"
                                >
                                    <LogOut size={18} />
                                    <span>Sign Out</span>
                                </button>
                            </div>
                        </motion.aside>
                    </>
                )}
            </AnimatePresence>
        </>
    );
}
