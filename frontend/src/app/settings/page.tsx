'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Settings, Tag, ChevronRight, User, Bell, Palette, Shield, LayoutDashboard } from 'lucide-react';
import Link from 'next/link';
import { Select } from '@/components/Select';
import { Switch } from '@/components/Switch';
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

    const handleUpdateSetting = async (key: string, val: any) => {
        setUpdating(true);
        try {
            const res = await updateUserSettings({ [key]: val });
            setSettings(res.data);
        } catch (err) {
            console.error('Failed to update setting:', err);
            alert('Failed to update setting');
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
            <header className="mb-6 md:mb-10">
                <motion.h1
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="text-xl md:text-2xl lg:text-3xl font-bold text-white flex items-center gap-2 md:gap-3"
                >
                    <Settings className="text-violet-400 w-6 h-6 md:w-8 md:h-8" /> Settings
                </motion.h1>
                <p className="text-xs md:text-sm text-muted mt-1">Configure your application preferences and manage data.</p>
            </header>

            <div className="space-y-12">
                {/* Dashboard Settings Section */}
                <section>
                    <h2 className="text-xs md:text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3 md:mb-4 ml-1">
                        Dashboard Settings
                    </h2>
                    <div className="glass-card p-4 md:p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 md:gap-6">
                        <div className="flex items-start gap-3 md:gap-4">
                            <div className="w-10 h-10 md:w-12 md:h-12 rounded-xl flex items-center justify-center shrink-0 bg-violet-400/10 text-violet-400">
                                <LayoutDashboard className="w-5 h-5 md:w-6 md:h-6" />
                            </div>
                            <div>
                                <h3 className="text-sm md:text-base font-semibold text-white">Data Display Range</h3>
                                <p className="text-xs md:text-sm text-muted mt-0.5 md:mt-1 max-w-sm leading-relaxed">
                                    Choose the default time period for transactions and charts on your dashboard.
                                </p>
                            </div>
                        </div>
                        <div className="w-full md:w-64">
                            <Select
                                options={RANGE_OPTIONS}
                                value={settings?.dashboardRange || '1m'}
                                onChange={(val) => handleUpdateSetting('dashboardRange', val)}
                                disabled={updating}
                            />
                            {updating && <p className="text-[10px] text-violet-400 mt-2 animate-pulse text-right px-1">Saving changes...</p>}
                        </div>
                    </div>
                </section>

                {/* Feature Toggles Section */}
                <section>
                    <h2 className="text-xs md:text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3 md:mb-4 ml-1">
                        Feature Toggles
                    </h2>
                    <div className="glass-card p-4 md:p-6">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-4">
                                <div className="w-10 h-10 rounded-xl flex items-center justify-center bg-emerald-400/10 text-emerald-400">
                                    <Shield className="w-5 h-5" />
                                </div>
                                <div>
                                    <h3 className="text-sm font-semibold text-white">Budgeting Feature</h3>
                                    <p className="text-xs text-muted mt-1">Enable or disable monthly budget tracking and limits.</p>
                                </div>
                            </div>
                            <Switch 
                                checked={settings?.budgetEnabled !== false} 
                                onChange={(val) => handleUpdateSetting('budgetEnabled', val)}
                                disabled={updating}
                            />
                        </div>
                    </div>
                </section>

                {/* Application Settings Section */}
                <section>
                    <h2 className="text-xs md:text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3 md:mb-4 ml-1">
                        Application Settings
                    </h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4">
                        <Link
                            href="/settings/categories"
                            className="glass-card p-4 md:p-5 group flex items-start gap-3 md:gap-4 transition-all hover:border-violet-500/30 hover:bg-white/[0.04]"
                        >
                            <div className="w-10 h-10 md:w-12 md:h-12 rounded-xl flex items-center justify-center shrink-0 bg-violet-400/10 text-violet-400">
                                <Tag className="w-5 h-5 md:w-6 md:h-6" />
                            </div>
                            <div className="flex-1">
                                <div className="flex items-center justify-between">
                                    <h3 className="text-sm md:text-base font-semibold text-white group-hover:text-violet-400 transition-colors">
                                        Categories
                                    </h3>
                                    <ChevronRight size={18} className="text-slate-600 group-hover:text-violet-400 transform group-hover:translate-x-1 transition-all" />
                                </div>
                                <p className="text-xs md:text-sm text-muted mt-0.5 md:mt-1 leading-relaxed">
                                    Manage your income and expense categories
                                </p>
                            </div>
                        </Link>

                        <div className="glass-card p-4 md:p-5 group flex items-start gap-3 md:gap-4 transition-all opacity-60 cursor-not-allowed">
                            <div className="w-10 h-10 md:w-12 md:h-12 rounded-xl flex items-center justify-center shrink-0 bg-blue-400/10 text-blue-400">
                                <Palette className="w-5 h-5 md:w-6 md:h-6" />
                            </div>
                            <div className="flex-1">
                                <h3 className="text-sm md:text-base font-semibold text-white">Display & Theme</h3>
                                <p className="text-xs md:text-sm text-muted mt-0.5 md:mt-1 leading-relaxed">
                                    Customize app appearance and colors
                                </p>
                                <span className="inline-block mt-1.5 md:mt-2 text-[10px] uppercase font-bold tracking-widest text-slate-500 bg-slate-800 px-1.5 py-0.5 rounded">
                                    Coming Soon
                                </span>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Personalization Section */}
                <section>
                    <h2 className="text-xs md:text-sm font-semibold text-slate-400 uppercase tracking-wider mb-3 md:mb-4 ml-1">
                        Personalization
                    </h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4">

                        <div className="glass-card p-4 md:p-5 group flex items-start gap-3 md:gap-4 transition-all opacity-60 cursor-not-allowed">
                            <div className="w-10 h-10 md:w-12 md:h-12 rounded-xl flex items-center justify-center shrink-0 bg-amber-400/10 text-amber-400">
                                <Bell className="w-5 h-5 md:w-6 md:h-6" />
                            </div>
                            <div className="flex-1">
                                <h3 className="text-sm md:text-base font-semibold text-white">Notifications</h3>
                                <p className="text-xs md:text-sm text-muted mt-0.5 md:mt-1 leading-relaxed">
                                    Manage app alerts and reminders
                                </p>
                                <span className="inline-block mt-1.5 md:mt-2 text-[10px] uppercase font-bold tracking-widest text-slate-500 bg-slate-800 px-1.5 py-0.5 rounded">
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
