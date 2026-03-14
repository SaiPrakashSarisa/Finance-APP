'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import {
    PiggyBank, TrendingDown, Flame, Award,
    ShieldAlert, HeartPulse,
} from 'lucide-react';
import { getInsights, getUserSettings } from '@/lib/api';
import { formatCurrency } from '@/lib/utils';

interface InsightCard {
    label: string;
    value: string;
    subtitle?: string;
    icon: any;
    color: string;
    bgClass: string;
}

const RANGE_LABELS: Record<string, string> = {
    '1m': 'this month',
    '3m': 'the last 3 months',
    '6m': 'the last 6 months',
    '1y': 'the last year',
    'all': 'all time'
};

export default function InsightsPage() {
    const [data, setData] = useState<any>(null);
    const [settings, setSettings] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function load() {
            try {
                const [insRes, setRes] = await Promise.all([
                    getInsights(),
                    getUserSettings()
                ]);
                setData(insRes.data);
                setSettings(setRes.data);
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

    const range = settings?.dashboardRange || '1m';
    const rangeLabel = RANGE_LABELS[range] || 'this month';

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
            subtitle: `Daily average for ${rangeLabel}`,
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
            subtitle: data.highestSpendingCategory ? formatCurrency(data.highestSpendingCategory.total) + ` for ${rangeLabel}` : `No expenses for ${rangeLabel}`,
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
            <motion.h1 initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="text-xl md:text-2xl lg:text-3xl font-bold text-white mb-2">
                Smart Insights
            </motion.h1>
            <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.1 }} className="text-muted mb-8">
                AI-powered analysis of your financial health for {rangeLabel}.
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
                                className={`glass-card p-4 md:p-6 ${card.bgClass}`}
                            >
                                <div className="flex items-center gap-3 mb-4">
                                    <div className={`w-9 h-9 md:w-11 md:h-11 rounded-xl bg-white/5 flex items-center justify-center shrink-0`}>
                                        <Icon className={`w-5 h-5 md:w-[22px] md:h-[22px] ${card.color}`} />
                                    </div>
                                    <p className="text-[10px] md:text-xs font-medium text-muted uppercase tracking-wider truncate">{card.label}</p>
                                </div>
                                <p className={`text-2xl md:text-3xl font-bold mb-1 md:mb-2 truncate ${card.color}`}>{card.value}</p>
                                {card.subtitle && <p className="text-xs md:text-sm text-slate-400">{card.subtitle}</p>}
                            </motion.div>
                    );
                })}
            </div>

            {/* Quick Stats Bar */}
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                className="glass-card p-4 md:p-6 mt-4 md:mt-6"
            >
                <h3 className="text-sm md:text-base font-semibold text-white mb-4">Total Overview ({rangeLabel})</h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3 md:gap-4">
                    {[
                        { label: 'Income', value: formatCurrency(data.income), color: 'text-emerald-400' },
                        { label: 'Expenses', value: formatCurrency(data.expense), color: 'text-rose-400' },
                        { label: 'Balance', value: formatCurrency(data.totalBalance), color: 'text-blue-400' },
                        { label: 'Receivables', value: formatCurrency(data.totalReceivables), color: 'text-amber-400' },
                        { label: 'Liabilities', value: formatCurrency(data.totalLiabilities), color: 'text-rose-400' },
                    ].map((item) => (
                        <div key={item.label} className="text-center">
                            <p className="text-[10px] md:text-xs text-muted mb-1">{item.label}</p>
                            <p className={`text-base md:text-lg font-bold truncate ${item.color}`}>{item.value}</p>
                        </div>
                    ))}
                </div>
            </motion.div>
        </div>
    );
}
