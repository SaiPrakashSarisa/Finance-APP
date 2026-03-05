'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import {
    PiggyBank, TrendingDown, Flame, Award,
    ShieldAlert, HeartPulse,
} from 'lucide-react';
import { getInsights } from '@/lib/api';
import { formatCurrency } from '@/lib/utils';

interface InsightCard {
    label: string;
    value: string;
    subtitle?: string;
    icon: any;
    color: string;
    bgClass: string;
}

export default function InsightsPage() {
    const [data, setData] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function load() {
            try {
                const res = await getInsights();
                setData(res.data);
            } catch (err) { console.error(err); }
            finally { setLoading(false); }
        }
        load();
    }, []);

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    if (!data) {
        return (
            <div className="text-center py-20 text-muted">
                <p>Unable to load insights. Make sure the backend is running and seeded.</p>
            </div>
        );
    }

    const cards: InsightCard[] = [
        {
            label: 'Savings Rate',
            value: `${data.savingsRate}%`,
            subtitle: data.savingsRate >= 20 ? 'Great! You\'re saving well.' : data.savingsRate >= 0 ? 'Consider cutting expenses.' : 'You\'re spending more than you earn!',
            icon: PiggyBank,
            color: 'text-emerald-400',
            bgClass: 'gradient-emerald',
        },
        {
            label: 'Avg Daily Expense',
            value: formatCurrency(data.avgDailyExpense),
            subtitle: 'This month\'s daily average',
            icon: TrendingDown,
            color: 'text-rose-400',
            bgClass: 'gradient-rose',
        },
        {
            label: 'Burn Rate',
            value: `${data.burnRate} days`,
            subtitle: data.burnRate > 90 ? 'Healthy runway!' : data.burnRate > 30 ? 'Moderate runway.' : 'Low runway — save more!',
            icon: Flame,
            color: 'text-amber-400',
            bgClass: 'gradient-amber',
        },
        {
            label: 'Top Spending Category',
            value: data.highestSpendingCategory?.name || 'N/A',
            subtitle: data.highestSpendingCategory ? formatCurrency(data.highestSpendingCategory.total) + ' this month' : 'No expenses this month',
            icon: Award,
            color: 'text-violet-400',
            bgClass: 'gradient-violet',
        },
        {
            label: 'Emergency Fund',
            value: `${data.emergencyFundMonths} months`,
            subtitle: data.emergencyFundMonths >= 6 ? 'Solid emergency fund!' : data.emergencyFundMonths >= 3 ? 'Building up — keep going.' : 'Build your safety net!',
            icon: HeartPulse,
            color: 'text-blue-400',
            bgClass: 'gradient-blue',
        },
        {
            label: 'Credit Exposure',
            value: `${data.creditExposureRatio}%`,
            subtitle: data.creditExposureRatio < 10 ? 'Low exposure — great!' : data.creditExposureRatio < 30 ? 'Moderate exposure.' : 'High exposure — be cautious!',
            icon: ShieldAlert,
            color: 'text-rose-400',
            bgClass: 'gradient-rose',
        },
    ];

    return (
        <div>
            <motion.h1 initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="text-2xl sm:text-3xl font-bold text-white mb-2">
                Smart Insights
            </motion.h1>
            <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.1 }} className="text-muted mb-8">
                AI-powered analysis of your financial health this month.
            </motion.p>

            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
                {cards.map((card, i) => {
                    const Icon = card.icon;
                    return (
                        <motion.div
                            key={card.label}
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            transition={{ delay: i * 0.08 }}
                            className={`glass-card p-6 ${card.bgClass}`}
                        >
                            <div className="flex items-center gap-3 mb-4">
                                <div className={`w-11 h-11 rounded-xl bg-white/5 flex items-center justify-center`}>
                                    <Icon size={22} className={card.color} />
                                </div>
                                <p className="text-xs font-medium text-muted uppercase tracking-wider">{card.label}</p>
                            </div>
                            <p className={`text-3xl font-bold mb-2 ${card.color}`}>{card.value}</p>
                            {card.subtitle && <p className="text-sm text-slate-400">{card.subtitle}</p>}
                        </motion.div>
                    );
                })}
            </div>

            {/* Quick Stats Bar */}
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                className="glass-card p-5 mt-6"
            >
                <h3 className="text-sm font-semibold text-white mb-4">Monthly Overview</h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
                    {[
                        { label: 'Income', value: formatCurrency(data.monthlyIncome), color: 'text-emerald-400' },
                        { label: 'Expenses', value: formatCurrency(data.monthlyExpense), color: 'text-rose-400' },
                        { label: 'Balance', value: formatCurrency(data.totalBalance), color: 'text-blue-400' },
                        { label: 'Receivables', value: formatCurrency(data.totalReceivables), color: 'text-amber-400' },
                        { label: 'Liabilities', value: formatCurrency(data.totalLiabilities), color: 'text-rose-400' },
                    ].map((item) => (
                        <div key={item.label} className="text-center">
                            <p className="text-xs text-muted mb-1">{item.label}</p>
                            <p className={`text-lg font-bold ${item.color}`}>{item.value}</p>
                        </div>
                    ))}
                </div>
            </motion.div>
        </div>
    );
}
