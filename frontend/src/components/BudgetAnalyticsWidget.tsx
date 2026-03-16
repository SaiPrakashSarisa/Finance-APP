'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Target, Calendar, CheckCircle, AlertTriangle } from 'lucide-react';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, Legend, ReferenceLine } from 'recharts';
import { getBudgetAnalytics } from '@/lib/api';
import { formatCurrency } from '@/lib/utils';
import { Select } from './Select';

export default function BudgetAnalyticsWidget() {
    const now = new Date();
    const [rangeType, setRangeType] = useState('current_year');
    const [customFrom, setCustomFrom] = useState(`${now.getFullYear()}-01`);
    const [customTo, setCustomTo] = useState(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`);
    
    const [data, setData] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchAnalytics() {
            setLoading(true);
            try {
                let fMonth = now.getMonth() + 1;
                let fYear = now.getFullYear();
                let tMonth = now.getMonth() + 1;
                let tYear = now.getFullYear();

                if (rangeType === 'current_year') {
                    fMonth = 1;
                    fYear = now.getFullYear();
                    tMonth = 12; // Or current month
                    tYear = now.getFullYear();
                } else if (rangeType === 'custom') {
                    if (customFrom) {
                        const [y, m] = customFrom.split('-');
                        fYear = parseInt(y);
                        fMonth = parseInt(m);
                    }
                    if (customTo) {
                        const [y, m] = customTo.split('-');
                        tYear = parseInt(y);
                        tMonth = parseInt(m);
                    }
                }

                const res = await getBudgetAnalytics(fMonth, fYear, tMonth, tYear);
                setData(res.data);
            } catch (err) {
                console.error('Failed to load budget analytics', err);
            } finally {
                setLoading(false);
            }
        }
        
        // Only fetch if dates are valid
        if (rangeType !== 'custom' || (customFrom && customTo)) {
            fetchAnalytics();
        }
    }, [rangeType, customFrom, customTo]);

    const CustomTooltip = ({ active, payload, label }: any) => {
        if (active && payload && payload.length) {
            return (
                <div className="glass-card p-3 text-sm">
                    <p className="text-white font-medium mb-2">{label}</p>
                    {payload.map((p: any, i: number) => (
                        <p key={i} style={{ color: p.color || p.fill }}>
                            {p.name}: {formatCurrency(p.value)}
                        </p>
                    ))}
                </div>
            );
        }
        return null;
    };

    return (
        <div className="mt-8">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                <h3 className="text-xl font-bold text-white flex items-center gap-2">
                    <Target className="text-violet-400 w-6 h-6" /> Budget Tracing & Analytics
                </h3>
                
                <div className="flex flex-col sm:flex-row items-center gap-3">
                    <div className="w-full sm:w-48">
                        <Select
                            options={[
                                { label: 'Current Month', value: 'current_month' },
                                { label: 'Current Year', value: 'current_year' },
                                { label: 'Custom Range', value: 'custom' }
                            ]}
                            value={rangeType}
                            onChange={(val) => setRangeType(val)}
                            position="bottom"
                        />
                    </div>
                    {rangeType === 'custom' && (
                        <div className="flex items-center gap-2 w-full sm:w-auto">
                            <input
                                type="month"
                                className="input-dark py-2 px-3 text-sm w-full"
                                value={customFrom}
                                onChange={(e) => setCustomFrom(e.target.value)}
                            />
                            <span className="text-muted text-sm">to</span>
                            <input
                                type="month"
                                className="input-dark py-2 px-3 text-sm w-full"
                                value={customTo}
                                onChange={(e) => setCustomTo(e.target.value)}
                            />
                        </div>
                    )}
                </div>
            </div>

            {loading ? (
                <div className="glass-card p-10 flex justify-center items-center h-[300px]">
                    <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
                </div>
            ) : !data || data.trends.length === 0 ? (
                <div className="glass-card p-10 text-center text-muted">
                    <Calendar className="mx-auto mb-3 opacity-50 w-8 h-8" />
                    <p>No budget data found for the selected range.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 lg:grid-cols-4 gap-4 md:gap-6">
                    {/* Summary Cards */}
                    <div className="lg:col-span-1 flex flex-col gap-4">
                        <div className="glass-card p-5 border-l-4 border-emerald-400">
                            <div className="flex items-center gap-3 mb-2">
                                <CheckCircle className="text-emerald-400 w-5 h-5" />
                                <h4 className="font-semibold text-white">Within Limits</h4>
                            </div>
                            <p className="text-3xl font-bold text-emerald-400">{data.successMonths} <span className="text-sm font-normal text-muted">months</span></p>
                            <p className="text-xs text-muted mt-1">Successfully stayed under total budget</p>
                        </div>
                        <div className="glass-card p-5 border-l-4 border-rose-400">
                            <div className="flex items-center gap-3 mb-2">
                                <AlertTriangle className="text-rose-400 w-5 h-5" />
                                <h4 className="font-semibold text-white">Exceeded Limits</h4>
                            </div>
                            <p className="text-3xl font-bold text-rose-400">{data.exceededMonths} <span className="text-sm font-normal text-muted">months</span></p>
                            <p className="text-xs text-muted mt-1">Months where expenses outpaced budget</p>
                        </div>
                    </div>

                    {/* Chart */}
                    <div className="glass-card p-4 md:p-6 lg:col-span-3 h-[300px] md:h-auto min-h-[300px]">
                        <h4 className="text-sm font-semibold text-white mb-4">Total Spending vs Target Budget</h4>
                        <ResponsiveContainer width="100%" height="85%">
                            <BarChart data={data.trends.filter((t: any) => t.hasBudgets)} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" vertical={false} />
                                <XAxis dataKey="label" tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} />
                                <YAxis tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickLine={false} tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}k`} />
                                <Tooltip content={<CustomTooltip />} cursor={{ fill: '#ffffff0a' }} />
                                <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '10px' }} />
                                {/* Render Budget as a lighter background bar, and actual as the primary bar */}
                                <Bar dataKey="totalBudget" name="Budget Limit" fill="#334155" radius={[4, 4, 0, 0]} />
                                <Bar dataKey="totalSpent" name="Actual Spent" fill="#8b5cf6" radius={[4, 4, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            )}
        </div>
    );
}
