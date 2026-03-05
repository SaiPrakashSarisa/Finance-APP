'use client';

import { motion } from 'framer-motion';
import { Settings, Tag, ChevronRight, User, Bell, Palette, Shield } from 'lucide-react';
import Link from 'next/link';

const SETTINGS_GROUPS = [
    {
        title: 'Application Settings',
        items: [
            {
                id: 'categories',
                name: 'Categories',
                description: 'Manage your income and expense categories',
                icon: Tag,
                href: '/settings/categories',
                color: 'text-violet-400',
                bgColor: 'bg-violet-400/10'
            },
            {
                id: 'display',
                name: 'Display & Theme',
                description: 'Customize app appearance and colors',
                icon: Palette,
                href: '#',
                color: 'text-blue-400',
                bgColor: 'bg-blue-400/10',
                disabled: true
            },
        ]
    },
    {
        title: 'Personalization',
        items: [
            {
                id: 'profile',
                name: 'Profile Settings',
                description: 'Update your personal info and preferences',
                icon: User,
                href: '#',
                color: 'text-emerald-400',
                bgColor: 'bg-emerald-400/10',
                disabled: true
            },
            {
                id: 'notifications',
                name: 'Notifications',
                description: 'Manage app alerts and reminders',
                icon: Bell,
                href: '#',
                color: 'text-amber-400',
                bgColor: 'bg-amber-400/10',
                disabled: true
            },
            {
                id: 'security',
                name: 'Security',
                description: 'Password, PIN, and account security',
                icon: Shield,
                href: '#',
                color: 'text-rose-400',
                bgColor: 'bg-rose-400/10',
                disabled: true
            },
        ]
    }
];

export default function SettingsHubPage() {
    return (
        <div className="max-w-4xl mx-auto">
            <header className="mb-10">
                <motion.h1
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="text-2xl sm:text-3xl font-bold text-white flex items-center gap-3"
                >
                    <Settings className="text-violet-400" /> Settings
                </motion.h1>
                <p className="text-muted mt-1">Configure your application preferences and manage data.</p>
            </header>

            <div className="space-y-12">
                {SETTINGS_GROUPS.map((group, groupIdx) => (
                    <section key={groupIdx}>
                        <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4 ml-1">
                            {group.title}
                        </h2>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {group.items.map((item, i) => (
                                <Link
                                    key={item.id}
                                    href={item.disabled ? '#' : item.href}
                                    className={`glass-card p-5 group flex items-start gap-4 transition-all ${item.disabled
                                            ? 'opacity-60 cursor-not-allowed'
                                            : 'hover:border-violet-500/30 hover:bg-white/[0.04]'
                                        }`}
                                >
                                    <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${item.bgColor} ${item.color}`}>
                                        <item.icon size={24} />
                                    </div>
                                    <div className="flex-1">
                                        <div className="flex items-center justify-between">
                                            <h3 className="font-semibold text-white group-hover:text-violet-400 transition-colors">
                                                {item.name}
                                            </h3>
                                            {!item.disabled && (
                                                <ChevronRight size={18} className="text-slate-600 group-hover:text-violet-400 transform group-hover:translate-x-1 transition-all" />
                                            )}
                                        </div>
                                        <p className="text-sm text-muted mt-1 leading-relaxed">
                                            {item.description}
                                        </p>
                                        {item.disabled && (
                                            <span className="inline-block mt-2 text-[10px] uppercase font-bold tracking-widest text-slate-500 bg-slate-800 px-1.5 py-0.5 rounded">
                                                Coming Soon
                                            </span>
                                        )}
                                    </div>
                                </Link>
                            ))}
                        </div>
                    </section>
                ))}
            </div>
        </div>
    );
}
