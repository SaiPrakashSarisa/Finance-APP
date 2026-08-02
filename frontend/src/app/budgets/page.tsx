'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { PieChart, Plus, Calendar, ChevronLeft, ChevronRight, TrendingUp, AlertCircle, CheckCircle2 } from 'lucide-react';
import { getBudgets, getCategories, upsertBudget, deleteBudget } from '@/lib/api';
import Modal from '@/components/Modal';
import { Select } from '@/components/Select';
import { formatCurrency } from '@/lib/utils';
import SummaryCard from '@/components/SummaryCard';

export default function BudgetsPage() {
    const [budgets, setBudgets] = useState<any[]>([]);
    const [categories, setCategories] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [modalOpen, setModalOpen] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    
    const [currentDate, setCurrentDate] = useState(new Date());
    const [form, setForm] = useState({ categoryId: '', amount: '', month: 0, year: 0 });
    const [expandedBudgets, setExpandedBudgets] = useState<string[]>([]);

    const toggleSubcategoryExpand = (e: React.MouseEvent, budgetId: string) => {
        e.stopPropagation();
        setExpandedBudgets(prev =>
            prev.includes(budgetId) ? prev.filter(id => id !== budgetId) : [...prev, budgetId]
        );
    };

    const month = currentDate.getMonth() + 1;
    const year = currentDate.getFullYear();

    const monthName = currentDate.toLocaleString('default', { month: 'long' });

    const load = async () => {
        setLoading(true);
        try {
            const [budgetRes, catRes] = await Promise.all([
                getBudgets({ month: String(month), year: String(year) }),
                getCategories({ tree: 'true' })
            ]);
            setBudgets(budgetRes.data);
            setCategories(catRes.data);
        } catch (err) {
            console.error('Failed to load budgets:', err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { load(); }, [month, year]);

    const changeMonth = (offset: number) => {
        const next = new Date(currentDate);
        next.setMonth(next.getMonth() + offset);
        setCurrentDate(next);
    };

    const openUpsert = (budget?: any) => {
        setForm({
            categoryId: budget?.category?._id || '',
            amount: budget?.amount || '',
            month,
            year
        });
        setModalOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            await upsertBudget({ ...form, amount: parseFloat(form.amount) });
            setModalOpen(false);
            load();
        } catch (err: any) {
            alert(err.message);
        } finally {
            setSubmitting(false);
        }
    };

    const totalBudget = budgets.reduce((sum, b) => sum + b.amount, 0);
    const totalSpent = budgets.reduce((sum, b) => sum + b.spent, 0);
    const remaining = totalBudget - totalSpent;
    const overallProgress = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

    if (loading && budgets.length === 0) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    return (
        <div className="max-w-5xl mx-auto pb-20">
            <header className="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
                <div>
                    <motion.h1
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="text-xl md:text-2xl lg:text-3xl font-bold text-white flex items-center gap-3"
                    >
                        <PieChart className="text-violet-400 w-8 h-8" /> Monthly Budgets
                    </motion.h1>
                    <div className="flex items-center gap-4 mt-2">
                        <div className="flex items-center bg-white/5 border border-white/10 rounded-lg p-1">
                            <button onClick={() => changeMonth(-1)} className="p-1.5 hover:bg-white/10 rounded-md transition-colors text-slate-400 hover:text-white">
                                <ChevronLeft size={18} />
                            </button>
                            <div className="px-4 py-1.5 flex items-center gap-2 min-w-[140px] justify-center">
                                <Calendar size={16} className="text-violet-400" />
                                <span className="text-sm font-semibold text-white">{monthName} {year}</span>
                            </div>
                            <button onClick={() => changeMonth(1)} className="p-1.5 hover:bg-white/10 rounded-md transition-colors text-slate-400 hover:text-white">
                                <ChevronRight size={18} />
                            </button>
                        </div>
                    </div>
                </div>

                <div className="flex gap-3">
                    <button onClick={() => openUpsert()} className="btn-primary flex items-center gap-2">
                        <Plus size={18} /> Add Budget
                    </button>
                </div>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
                <SummaryCard
                    label="Total Budget"
                    value={formatCurrency(totalBudget)}
                    icon={TrendingUp}
                    color="violet"
                />
                <SummaryCard
                    label="Total Spent"
                    value={formatCurrency(totalSpent)}
                    icon={TrendingUp}
                    color="rose"
                />
                <SummaryCard
                    label="Remaining"
                    value={formatCurrency(remaining)}
                    icon={TrendingUp}
                    color="emerald"
                />
            </div>

            {/* Overall Progress */}
            <div className="glass-card p-6 mb-10 overflow-hidden relative">
                <div className="absolute top-0 right-0 p-8 opacity-10">
                    <PieChart size={120} className="text-violet-400" />
                </div>
                <div className="flex justify-between items-end mb-4">
                    <div>
                        <h2 className="text-lg font-bold text-white uppercase tracking-wider text-xs text-slate-400 mb-1">Monthly Progress</h2>
                        <p className="text-2xl font-bold text-white">{overallProgress.toFixed(1)}% <span className="text-sm font-normal text-slate-500 ml-1">of budget utilized</span></p>
                    </div>
                    <div className="text-right">
                         <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider ${remaining >= 0 ? 'bg-emerald-500/10 text-emerald-400' : 'bg-rose-500/10 text-rose-400'}`}>
                            {remaining >= 0 ? <CheckCircle2 size={12} /> : <AlertCircle size={12} />}
                            {remaining >= 0 ? 'On Track' : 'Over Budget'}
                         </span>
                    </div>
                </div>
                <div className="h-3 w-full bg-slate-800 rounded-full overflow-hidden flex">
                    <motion.div 
                        initial={{ width: 0 }}
                        animate={{ width: `${Math.min(overallProgress, 100)}%` }}
                        className={`h-full transition-all duration-1000 ${overallProgress > 100 ? 'bg-rose-500' : overallProgress > 80 ? 'bg-amber-500' : 'bg-violet-500'}`}
                    />
                </div>
            </div>

            <div className="space-y-6">
                <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-widest ml-1">Category Breakdown</h2>
                {budgets.length === 0 && !loading && (
                    <div className="glass-card p-12 text-center">
                        <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center mx-auto mb-4 text-slate-600">
                            <PieChart size={32} />
                        </div>
                        <h3 className="text-white font-semibold mb-1">No Budgets Set</h3>
                        <p className="text-sm text-slate-500 max-w-xs mx-auto">Start by setting monthly limits for your primary expense categories.</p>
                        <button onClick={() => openUpsert()} className="btn-primary mt-6 inline-flex items-center gap-2">
                             <Plus size={18} /> Set Your First Budget
                        </button>
                    </div>
                )}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {budgets.map((budget) => (
                        <motion.div 
                            key={budget._id}
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            layout
                            className="glass-card p-5 group cursor-pointer hover:border-violet-500/30 transition-all border border-transparent shadow-md bg-white/[0.02]"
                            onClick={() => openUpsert(budget)}
                        >
                            <div className="flex items-center justify-between mb-4">
                                <div className="flex items-center gap-4">
                                    <div 
                                        className="w-12 h-12 rounded-xl flex items-center justify-center text-xl shadow-inner"
                                        style={{ backgroundColor: `${budget.category?.color}20`, color: budget.category?.color }}
                                    >
                                        {budget.category?.icon || '📁'}
                                    </div>
                                    <div>
                                        <h3 className="font-bold text-white text-lg">{budget.category?.name}</h3>
                                        <div className="flex items-center gap-2 text-xs text-muted font-medium uppercase tracking-tight">
                                             <span className="text-white">{formatCurrency(budget.spent)}</span> / {formatCurrency(budget.amount)}
                                        </div>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <span className={`text-sm font-bold ${budget.percentage > 100 ? 'text-rose-400' : 'text-slate-300'}`}>
                                        {budget.percentage.toFixed(0)}%
                                    </span>
                                </div>
                            </div>
                            
                            <div className="h-2 w-full bg-slate-800 rounded-full overflow-hidden">
                                <motion.div 
                                    initial={{ width: 0 }}
                                    animate={{ width: `${Math.min(budget.percentage, 100)}%` }}
                                    className={`h-full ${budget.percentage > 100 ? 'bg-rose-500' : budget.percentage > 85 ? 'bg-amber-500' : 'bg-emerald-500'}`}
                                />
                            </div>
                            
                            <div className="mt-4 flex justify-between items-center text-xs">
                                <p className="text-[10px] text-muted uppercase tracking-widest font-bold">
                                    {budget.remaining >= 0 
                                        ? `${formatCurrency(budget.remaining)} left` 
                                        : `${formatCurrency(Math.abs(budget.remaining))} over`}
                                </p>
                                
                                {budget.subcategories && budget.subcategories.length > 0 && (
                                    <button
                                        type="button"
                                        onClick={(e) => toggleSubcategoryExpand(e, budget._id)}
                                        className="text-[11px] font-semibold text-violet-400 hover:text-violet-300 flex items-center gap-1 bg-violet-500/10 px-2 py-1 rounded-lg border border-violet-500/20"
                                    >
                                        {expandedBudgets.includes(budget._id) ? 'Hide Breakdown ▲' : 'Subcategories Breakdown ▼'}
                                    </button>
                                )}
                            </div>

                            {/* Expandable Subcategories Progress Breakdown */}
                            <AnimatePresence>
                                {expandedBudgets.includes(budget._id) && budget.subcategories?.length > 0 && (
                                    <motion.div
                                        initial={{ height: 0, opacity: 0 }}
                                        animate={{ height: 'auto', opacity: 1 }}
                                        exit={{ height: 0, opacity: 0 }}
                                        className="overflow-hidden mt-3 pt-3 border-t border-white/10 space-y-2.5"
                                        onClick={(e) => e.stopPropagation()}
                                    >
                                        <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Subcategory Progress Breakdown</p>
                                        {budget.subcategories.map((sub: any) => (
                                            <div key={sub._id} className="space-y-1">
                                                <div className="flex justify-between items-center text-xs">
                                                    <span className="text-slate-300 flex items-center gap-1.5 font-medium">
                                                        <span>{sub.icon || '🏷️'}</span> {sub.name}
                                                    </span>
                                                    <span className="text-white font-semibold">
                                                        {formatCurrency(sub.spent)} <span className="text-[10px] text-slate-400 font-normal">({sub.percentage}%)</span>
                                                    </span>
                                                </div>
                                                <div className="h-1.5 w-full bg-slate-800 rounded-full overflow-hidden">
                                                    <div 
                                                        className="h-full bg-violet-400/80 rounded-full"
                                                        style={{ width: `${Math.min(sub.percentage, 100)}%` }}
                                                    />
                                                </div>
                                            </div>
                                        ))}
                                    </motion.div>
                                )}
                            </AnimatePresence>
                        </motion.div>
                    ))}
                </div>
            </div>

            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Set Category Budget">
                <form onSubmit={handleSubmit} className="flex flex-col gap-6 p-1">
                    <div>
                        <label className="block text-xs font-bold text-slate-400 uppercase tracking-widest mb-2">Primary Category</label>
                        <Select
                            options={categories.filter(c => !c.parentCategoryId).map(c => ({
                                label: `${c.icon} ${c.name}`,
                                value: c._id
                            }))}
                            value={form.categoryId}
                            onChange={(val) => setForm({ ...form, categoryId: val })}
                            placeholder="Select category..."
                        />
                         <p className="text-[10px] text-slate-500 mt-2 leading-relaxed italic">
                            Spending from all sub-categories will be automatically included in this budget.
                         </p>
                    </div>
                    <div>
                        <label className="block text-xs font-bold text-slate-400 uppercase tracking-widest mb-2">Monthly Limit</label>
                        <div className="relative">
                            <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 font-medium">$</span>
                            <input
                                type="number"
                                step="0.01"
                                className="input-dark pl-9 py-4 text-xl font-bold"
                                placeholder="0.00"
                                value={form.amount}
                                onChange={(e) => setForm({ ...form, amount: e.target.value })}
                                required
                            />
                        </div>
                    </div>
                    
                    <div className="bg-slate-800/50 rounded-xl p-4 flex items-center gap-3">
                         <div className="w-8 h-8 rounded-full bg-violet-500/10 flex items-center justify-center text-violet-400">
                            <Calendar size={16} />
                         </div>
                         <div>
                            <p className="text-xs font-bold text-white uppercase tracking-tight">Active Period</p>
                            <p className="text-sm text-slate-400">{monthName} {year}</p>
                         </div>
                    </div>

                    <div className="flex gap-4 mt-2">
                        <button type="submit" disabled={submitting || !form.categoryId} className="btn-primary flex-1 py-4 text-lg font-bold disabled:opacity-30">
                            {submitting ? 'Saving...' : 'Set Budget'}
                        </button>
                    </div>
                </form>
            </Modal>
        </div>
    );
}
