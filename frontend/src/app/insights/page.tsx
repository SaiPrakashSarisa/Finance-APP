'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import {
    PiggyBank, TrendingDown, Flame, Award,
    ShieldAlert, HeartPulse, Store, Repeat, ShoppingBag
} from 'lucide-react';
import { getInsights, getUserSettings, getInflationTracker, getMerchantAnalytics, getMerchantItemComparison, getSubscriptions } from '@/lib/api';
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
    const [inflationData, setInflationData] = useState<any>(null);
    const [merchantsData, setMerchantsData] = useState<any[]>([]);
    const [merchantCompareData, setMerchantCompareData] = useState<any[]>([]);
    const [subscriptionsData, setSubscriptionsData] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function load() {
            try {
                const [insRes, setRes, infRes, merchRes, compRes, subRes] = await Promise.all([
                    getInsights(),
                    getUserSettings(),
                    getInflationTracker(),
                    getMerchantAnalytics(),
                    getMerchantItemComparison(),
                    getSubscriptions()
                ]);
                setData(insRes.data);
                setSettings(setRes.data);
                setInflationData(infRes.data);
                setMerchantsData(merchRes.data || []);
                setMerchantCompareData(compRes.data || []);
                setSubscriptionsData(subRes.data || []);
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
                Smart Insights & Item Inflation
            </motion.h1>
            <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.1 }} className="text-muted mb-8">
                AI-powered financial analytics, burn rate, and product-level price inflation tracker.
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

            {/* Item-Level Personal Inflation Tracker */}
            {inflationData && (
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.4 }}
                    className="glass-card p-4 md:p-6 mt-6 border-violet-500/30"
                >
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-4 border-b border-border/50 pb-3">
                        <div>
                            <h3 className="text-base md:text-lg font-bold text-white flex items-center gap-2">
                                🛒 Personal Household Inflation Tracker
                            </h3>
                            <p className="text-xs text-muted">Tracking individual product unit price increases across shopping trips (e.g. D-Mart)</p>
                        </div>
                        <div className="self-start sm:self-auto bg-violet-500/10 border border-violet-500/30 px-3 py-1.5 rounded-xl text-right">
                            <span className="text-[10px] text-muted block uppercase">Overall Personal Inflation</span>
                            <span className={`text-lg font-extrabold ${inflationData.overallInflation > 0 ? 'text-rose-400' : 'text-emerald-400'}`}>
                                {inflationData.overallInflation > 0 ? '+' : ''}{inflationData.overallInflation}%
                            </span>
                        </div>
                    </div>

                    {inflationData.items && inflationData.items.length > 0 ? (
                        <div className="overflow-x-auto">
                            <table className="w-full text-xs">
                                <thead>
                                    <tr className="border-b border-border/50 text-muted uppercase text-left">
                                        <th className="py-2.5 px-3">Item Name</th>
                                        <th className="py-2.5 px-3 text-center">Unit</th>
                                        <th className="py-2.5 px-3 text-right">Baseline Price</th>
                                        <th className="py-2.5 px-3 text-right">Latest Price</th>
                                        <th className="py-2.5 px-3 text-right">Price Variance</th>
                                        <th className="py-2.5 px-3 text-right">Inflation %</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {inflationData.items.map((item: any, idx: number) => (
                                        <tr key={idx} className="border-b border-white/5 hover:bg-white/[0.02]">
                                            <td className="py-2.5 px-3 font-semibold text-white">{item.name}</td>
                                            <td className="py-2.5 px-3 text-center text-slate-400">{item.unit}</td>
                                            <td className="py-2.5 px-3 text-right text-slate-300">{formatCurrency(item.firstPrice)}</td>
                                            <td className="py-2.5 px-3 text-right font-semibold text-white">{formatCurrency(item.lastPrice)}</td>
                                            <td className={`py-2.5 px-3 text-right font-medium ${item.priceDiff > 0 ? 'text-rose-400' : item.priceDiff < 0 ? 'text-emerald-400' : 'text-slate-400'}`}>
                                                {item.priceDiff > 0 ? '+' : ''}{formatCurrency(item.priceDiff)}
                                            </td>
                                            <td className="py-2.5 px-3 text-right">
                                                <span className={`inline-block px-2 py-0.5 rounded text-[11px] font-bold ${item.inflationPercent > 0 ? 'bg-rose-500/20 text-rose-400 border border-rose-500/30' : item.inflationPercent < 0 ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' : 'bg-slate-500/20 text-slate-400'}`}>
                                                    {item.inflationPercent > 0 ? '+' : ''}{item.inflationPercent}%
                                                </span>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    ) : (
                        <p className="text-xs text-muted text-center py-4">No recurring itemized purchases found yet. Start itemizing your store receipts to track inflation!</p>
                    )}
                </motion.div>
            )}

            {/* Subscriptions & Recurring Bills Section */}
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="glass-card p-4 md:p-6 mt-4 md:mt-6"
            >
                <div className="flex items-center gap-2 mb-4">
                    <div className="p-2 rounded-xl bg-cyan-500/10 text-cyan-400">
                        <Repeat className="w-5 h-5" />
                    </div>
                    <div>
                        <h3 className="text-sm md:text-base font-bold text-white">Detected Subscriptions & Recurring Bills</h3>
                        <p className="text-xs text-muted">Automatically detected recurring monthly expenses & obligations</p>
                    </div>
                </div>

                {subscriptionsData.length > 0 ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
                        {subscriptionsData.map((sub, i) => (
                            <div key={i} className="p-3.5 rounded-xl bg-white/[0.03] border border-white/10 flex items-center justify-between">
                                <div>
                                    <p className="text-sm font-semibold text-white capitalize">{sub.name}</p>
                                    <p className="text-xs text-slate-400 mt-0.5">{sub.frequency} • {sub.occurrences} payments detected</p>
                                </div>
                                <div className="text-right">
                                    <p className="text-sm font-bold text-cyan-400">{formatCurrency(sub.amount)}</p>
                                    <span className="inline-block mt-1 px-1.5 py-0.5 text-[10px] font-medium bg-cyan-500/20 text-cyan-300 rounded">Active</span>
                                </div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <p className="text-xs text-muted text-center py-4">No recurring bills detected yet.</p>
                )}
            </motion.div>

            {/* Merchant Spending & Store Analytics */}
            <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.45 }}
                className="glass-card p-4 md:p-6 mt-4 md:mt-6"
            >
                <div className="flex items-center gap-2 mb-4">
                    <div className="p-2 rounded-xl bg-amber-500/10 text-amber-400">
                        <Store className="w-5 h-5" />
                    </div>
                    <div>
                        <h3 className="text-sm md:text-base font-bold text-white">Top Merchants & Store Spending</h3>
                        <p className="text-xs text-muted">Total spending breakdown across your favorite stores & supermarkets</p>
                    </div>
                </div>

                {merchantsData.length > 0 ? (
                    <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                        {merchantsData.map((merch, i) => (
                            <div key={i} className="p-3.5 rounded-xl bg-white/[0.03] border border-white/10 text-center">
                                <div className="w-10 h-10 mx-auto rounded-full bg-amber-500/10 text-amber-400 flex items-center justify-center mb-2 font-bold">
                                    🏪
                                </div>
                                <h4 className="text-sm font-bold text-white truncate">{merch._id}</h4>
                                <p className="text-xs text-slate-400 mt-0.5">{merch.transactionCount} visit{merch.transactionCount > 1 ? 's' : ''}</p>
                                <p className="text-sm font-bold text-amber-400 mt-1">{formatCurrency(merch.totalSpent)}</p>
                            </div>
                        ))}
                    </div>
                ) : (
                    <p className="text-xs text-muted text-center py-4">No merchant transactions recorded yet.</p>
                )}
            </motion.div>

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
