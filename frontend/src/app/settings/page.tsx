'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Settings, Tag, ChevronRight, User, Bell, Palette, Shield, LayoutDashboard } from 'lucide-react';
import Link from 'next/link';
import { Select } from '@/components/Select';
import { getUserSettings, updateUserSettings } from '@/lib/api';

const RANGE_OPTIONS = [
    { label: 'Last 1 Month', value: '1m' },
    { label: 'Last 3 Months', value: '3m' },
    { label: 'Last 6 Months', value: '6m' },
    { label: 'Last 1 Year', value: '1y' },
    { label: 'All Time', value: 'all' },
];

const SETTINGS_GROUPS = [
    // ... items stay similar but I'll add the dashboard one manually below or restructure
];

export default function SettingsHubPage() {
    const [settings, setSettings] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [updating, setUpdating] = useState(false);

    useEffect(() => {
        async function load() {
            try {
                const res = await getUserSettings();
                setSettings(res.data);
            } catch (err) {
                console.error('Failed to load settings:', err);
            } finally {
                setLoading(false);
            }
        }
        load();
    }, []);

    const handleRangeChange = async (val: string) => {
        setUpdating(true);
        try {
            const res = await updateUserSettings({ dashboardRange: val });
            setSettings(res.data);
        } catch (err) {
            console.error('Failed to update settings:', err);
            alert('Failed to update settings');
        } finally {
            setUpdating(false);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    return (
        <div className="max-w-4xl mx-auto pb-20">
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
                {/* Dashboard Settings Section */}
                <section>
                    <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4 ml-1">
                        Dashboard Settings
                    </h2>
                    <div className="glass-card p-6 flex flex-col md:flex-row md:items-center justify-between gap-6">
                        <div className="flex items-start gap-4">
                            <div className="w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-violet-400/10 text-violet-400">
                                <LayoutDashboard size={24} />
                            </div>
                            <div>
                                <h3 className="font-semibold text-white">Data Display Range</h3>
                                <p className="text-sm text-muted mt-1 max-w-sm">
                                    Choose the default time period for transactions and charts on your dashboard.
                                </p>
                            </div>
                        </div>
                        <div className="w-full md:w-64">
                            <Select
                                options={RANGE_OPTIONS}
                                value={settings?.dashboardRange || '1m'}
                                onChange={handleRangeChange}
                                disabled={updating}
                            />
                            {updating && <p className="text-[10px] text-violet-400 mt-2 animate-pulse text-right px-1">Saving changes...</p>}
                        </div>
                    </div>
                </section>

                {/* Application Settings Section */}
                <section>
                    <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4 ml-1">
                        Application Settings
                    </h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <Link
                            href="/settings/categories"
                            className="glass-card p-5 group flex items-start gap-4 transition-all hover:border-violet-500/30 hover:bg-white/[0.04]"
                        >
                            <div className="w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-violet-400/10 text-violet-400">
                                <Tag size={24} />
                            </div>
                            <div className="flex-1">
                                <div className="flex items-center justify-between">
                                    <h3 className="font-semibold text-white group-hover:text-violet-400 transition-colors">
                                        Categories
                                    </h3>
                                    <ChevronRight size={18} className="text-slate-600 group-hover:text-violet-400 transform group-hover:translate-x-1 transition-all" />
                                </div>
                                <p className="text-sm text-muted mt-1 leading-relaxed">
                                    Manage your income and expense categories
                                </p>
                            </div>
                        </Link>

                        <div className="glass-card p-5 group flex items-start gap-4 transition-all opacity-60 cursor-not-allowed">
                            <div className="w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-blue-400/10 text-blue-400">
                                <Palette size={24} />
                            </div>
                            <div className="flex-1">
                                <h3 className="font-semibold text-white">Display & Theme</h3>
                                <p className="text-sm text-muted mt-1 leading-relaxed">
                                    Customize app appearance and colors
                                </p>
                                <span className="inline-block mt-2 text-[10px] uppercase font-bold tracking-widest text-slate-500 bg-slate-800 px-1.5 py-0.5 rounded">
                                    Coming Soon
                                </span>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Personalization Section */}
                <section>
                    <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-wider mb-4 ml-1">
                        Personalization
                    </h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">

                        <div className="glass-card p-5 group flex items-start gap-4 transition-all opacity-60 cursor-not-allowed">
                            <div className="w-12 h-12 rounded-xl flex items-center justify-center shrink-0 bg-amber-400/10 text-amber-400">
                                <Bell size={24} />
                            </div>
                            <div className="flex-1">
                                <h3 className="font-semibold text-white">Notifications</h3>
                                <p className="text-sm text-muted mt-1 leading-relaxed">
                                    Manage app alerts and reminders
                                </p>
                                <span className="inline-block mt-2 text-[10px] uppercase font-bold tracking-widest text-slate-500 bg-slate-800 px-1.5 py-0.5 rounded">
                                    Coming Soon
                                </span>
                            </div>
                        </div>
                    </div>
                </section>
            </div>
        </div>
    );
}
