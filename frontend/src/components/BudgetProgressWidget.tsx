'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Target, AlertTriangle, ArrowRight } from 'lucide-react';
import Link from 'next/link';
import { formatCurrency } from '@/lib/utils';
import Badge from './Badge';

interface BudgetProgressProps {
    budgets: any[];
    loading?: boolean;
}

export default function BudgetProgressWidget({ budgets, loading = false }: BudgetProgressProps) {
    if (loading) {
        return (
            <div className="glass-card p-5 animate-pulse">
                <div className="h-6 w-1/3 bg-white/10 rounded mb-4" />
                <div className="space-y-4">
                    <div className="h-10 w-full bg-white/5 rounded" />
                    <div className="h-10 w-full bg-white/5 rounded" />
                </div>
            </div>
        );
    }

    return (
        <div className="glass-card p-5 md:p-6 flex flex-col h-full">
            <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-2">
                    <Target className="text-emerald-400 w-5 h-5" />
                    <h3 className="text-lg font-semibold text-white">Monthly Budgets</h3>
                </div>
                <Link href="/settings/budgets" className="text-xs text-muted hover:text-white flex items-center gap-1 transition-colors">
                    Manage <ArrowRight size={14} />
                </Link>
            </div>

            {budgets.length === 0 ? (
                <div className="flex-1 flex flex-col items-center justify-center text-center py-6">
                    <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center mb-3">
                        <Target className="w-6 h-6 text-slate-500" />
                    </div>
                    <p className="text-sm text-slate-300 font-medium">No budgets set</p>
                    <p className="text-xs text-muted mt-1 max-w-[200px]">Set category limits to track your spending pace.</p>
                    <Link href="/settings/budgets" className="mt-4 px-4 py-1.5 rounded-lg bg-emerald-500/20 text-emerald-400 text-xs font-semibold hover:bg-emerald-500/30 transition-colors">
                        Create Budget
                    </Link>
                </div>
            ) : (
                <div className="space-y-5 flex-1 max-h-[300px] overflow-y-auto custom-scrollbar pr-2">
                    {budgets.map((budget, i) => {
                        const isOver = budget.exceeded;
                        const isWarning = budget.percentageUsed >= 80 && !isOver;
                        
                        let barColor = 'bg-emerald-400';
                        if (isOver) barColor = 'bg-rose-400';
                        else if (isWarning) barColor = 'bg-amber-400';

                        return (
                            <motion.div
                                key={budget.budgetId}
                                initial={{ opacity: 0, x: -10 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: i * 0.1 }}
                            >
                                <div className="flex items-center justify-between mb-2">
                                    <div className="flex items-center gap-2">
                                        <span className="text-lg">{budget.category?.icon || '📦'}</span>
                                        <span className="text-sm font-medium text-slate-200">{budget.category?.name || 'Unknown'}</span>
                                        {isOver && <AlertTriangle size={12} className="text-rose-400" />}
                                    </div>
                                    <div className="text-right flex flex-col items-end">
                                        <div className="flex items-baseline gap-1">
                                            <span className={`text-sm font-bold ${isOver ? 'text-rose-400' : 'text-white'}`}>
                                                {formatCurrency(budget.spent)}
                                            </span>
                                            <span className="text-xs text-muted">/ {formatCurrency(budget.amount)}</span>
                                        </div>
                                    </div>
                                </div>
                                
                                <div className="h-2 w-full bg-white/5 rounded-full overflow-hidden flex">
                                    <motion.div
                                        initial={{ width: 0 }}
                                        animate={{ width: `${Math.min(budget.percentageUsed, 100)}%` }}
                                        transition={{ duration: 1, ease: 'easeOut' }}
                                        className={`h-full ${barColor} rounded-full`}
                                    />
                                    {isOver && (
                                        <div className="h-full bg-rose-500/50 flex-1" />
                                    )}
                                </div>
                                <div className="flex justify-between mt-1 text-[10px] sm:text-xs">
                                    <span className={isWarning ? 'text-amber-400' : isOver ? 'text-rose-400' : 'text-muted'}>
                                        {budget.percentageUsed}% used
                                    </span>
                                    {isOver ? (
                                        <span className="text-rose-400 font-medium">Over by {formatCurrency(Math.abs(budget.remaining))}</span>
                                    ) : (
                                        <span className="text-emerald-400">{formatCurrency(budget.remaining)} left</span>
                                    )}
                                </div>
                            </motion.div>
                        );
                    })}
                </div>
            )}
        </div>
    );
}
