'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Target, ArrowLeft, Plus, Pencil, Trash2 } from 'lucide-react';
import Link from 'next/link';
import { getBudgets, getCategories, upsertBudget, deleteBudget } from '@/lib/api';
import Modal from '@/components/Modal';
import ConfirmDialog from '@/components/ConfirmDialog';
import { Select } from '@/components/Select';
import { formatCurrency } from '@/lib/utils';

export default function BudgetSettingsPage() {
    const [budgets, setBudgets] = useState<any[]>([]);
    const [categories, setCategories] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [modalOpen, setModalOpen] = useState(false);
    const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);
    const [editingBudget, setEditingBudget] = useState<any>(null);

    const [form, setForm] = useState({
        categoryId: '',
        amount: ''
    });

    const loadData = async () => {
        try {
            const [bRes, cRes] = await Promise.all([
                getBudgets(),
                getCategories()
            ]);
            setBudgets(bRes.data || []);
            // Only expense categories make sense for budgets right now
            setCategories((cRes.data || []).filter((c: any) => c.type === 'expense'));
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { loadData(); }, []);

    const openEdit = (budget: any) => {
        setEditingBudget(budget);
        setForm({
            categoryId: budget.categoryId._id || budget.categoryId,
            amount: String(budget.amount)
        });
        setModalOpen(true);
    };

    const handleOpenAdd = () => {
        setEditingBudget(null);
        setForm({ categoryId: '', amount: '' });
        setModalOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (submitting) return;
        setSubmitting(true);
        try {
            await upsertBudget({
                categoryId: form.categoryId,
                amount: parseFloat(form.amount),
                yearMonth: 'default' // standard repeating monthly budget
            });
            setModalOpen(false);
            setForm({ categoryId: '', amount: '' });
            loadData();
        } catch (err: any) {
            alert(err.message);
        } finally {
            setSubmitting(false);
        }
    };

    const handleDelete = async () => {
        if (!deleteTarget) return;
        try {
            await deleteBudget(deleteTarget);
            setDeleteTarget(null);
            loadData();
        } catch (err: any) {
            alert(err.message);
            setDeleteTarget(null);
        }
    };

    const unbudgetedCategories = categories.filter(c => !budgets.find(b => b.categoryId._id === c._id));
    // If editing, they can keep their existing category or choose from unbudgeted.
    const availableCategoriesForForm = editingBudget 
        ? [categories.find(c => c._id === editingBudget.categoryId._id), ...unbudgetedCategories].filter(Boolean)
        : unbudgetedCategories;

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <div className="w-8 h-8 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    return (
        <div className="max-w-4xl mx-auto pb-20">
            <header className="mb-6 md:mb-10">
                <Link href="/settings" className="inline-flex items-center text-sm text-muted hover:text-white transition-colors mb-4">
                    <ArrowLeft size={16} className="mr-1" /> Back to Settings
                </Link>
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div>
                        <motion.h1
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            className="text-xl md:text-2xl lg:text-3xl font-bold text-white flex items-center gap-2"
                        >
                            <Target className="text-emerald-400 w-6 h-6 md:w-8 md:h-8" /> Budgets
                        </motion.h1>
                        <p className="text-xs md:text-sm text-muted mt-1">Set monthly spending limits for expense categories.</p>
                    </div>
                    <button onClick={handleOpenAdd} className="btn-primary flex items-center justify-center gap-2 self-start sm:self-auto bg-emerald-500 hover:bg-emerald-600 shadow-[0_0_15px_rgba(16,185,129,0.3)]">
                        <Plus size={18} /> Add Budget
                    </button>
                </div>
            </header>

            {budgets.length === 0 ? (
                <div className="text-center py-20 text-muted glass-card">
                    <Target size={48} className="mx-auto mb-4 opacity-50 text-emerald-400" />
                    <p>No budgets configured.</p>
                    <p className="text-sm mt-2">Take control of your spending by setting limits.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {budgets.map((budget: any, i: number) => (
                        <motion.div
                            key={budget._id}
                            initial={{ opacity: 0, scale: 0.95 }}
                            animate={{ opacity: 1, scale: 1 }}
                            transition={{ delay: i * 0.05 }}
                            className="glass-card p-5 relative overflow-hidden group"
                        >
                            <div className="flex items-center justify-between mb-2 w-full">
                                <div className="flex items-center gap-3">
                                    <div className={`w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500/20 to-emerald-600/10 flex items-center justify-center text-xl shadow-inner border border-emerald-500/20`}>
                                        {budget.categoryId.icon || '📦'}
                                    </div>
                                    <div>
                                        <h3 className="font-semibold text-white">{budget.categoryId.name}</h3>
                                        <p className="text-xs text-muted">Monthly Limit</p>
                                    </div>
                                </div>
                                
                                <div className="text-right">
                                    <p className="text-lg font-bold text-emerald-400">{formatCurrency(budget.amount)}</p>
                                </div>
                            </div>
                            
                            <div className="absolute top-3 right-3 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                <button onClick={() => openEdit(budget)} className="p-1.5 rounded-lg bg-black/40 text-slate-300 hover:text-white hover:bg-white/10 transition-colors backdrop-blur-md">
                                    <Pencil size={14} />
                                </button>
                                <button onClick={() => setDeleteTarget(budget._id)} className="p-1.5 rounded-lg bg-black/40 text-slate-300 hover:text-rose-400 hover:bg-rose-500/20 transition-colors backdrop-blur-md">
                                    <Trash2 size={14} />
                                </button>
                            </div>
                        </motion.div>
                    ))}
                </div>
            )}

            <Modal isOpen={modalOpen} onClose={() => { setModalOpen(false); setEditingBudget(null); }} title={editingBudget ? 'Edit Budget' : 'New Budget'}>
                <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Category</label>
                        <Select
                            options={availableCategoriesForForm.map((c: any) => ({
                                label: c.name,
                                value: c._id
                            }))}
                            value={form.categoryId}
                            onChange={(val) => setForm({ ...form, categoryId: val })}
                            placeholder="Select an expense category"
                            disabled={!!editingBudget} // Don't allow changing category during edit for now
                        />
                        {availableCategoriesForForm.length === 0 && !editingBudget && (
                            <p className="text-xs text-rose-400 mt-1">All expense categories already have budgets.</p>
                        )}
                    </div>

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Monthly Limit Amount</label>
                        <input
                            className="input-dark"
                            type="number"
                            step="0.01"
                            min="0.01"
                            placeholder="0.00"
                            value={form.amount}
                            onChange={(e) => setForm({ ...form, amount: e.target.value })}
                            required
                        />
                    </div>

                    <div className="flex gap-3 mt-4">
                        <button type="submit" disabled={submitting || (!editingBudget && availableCategoriesForForm.length === 0)} className="btn-primary bg-emerald-500 hover:bg-emerald-600 flex-1">
                            {submitting ? 'Saving...' : editingBudget ? 'Update Budget' : 'Create Budget'}
                        </button>
                        <button type="button" onClick={() => { setModalOpen(false); setEditingBudget(null); }} className="btn-ghost flex-1">
                            Cancel
                        </button>
                    </div>
                </form>
            </Modal>

            <ConfirmDialog
                isOpen={!!deleteTarget}
                title="Delete Budget?"
                message="This will remove the monthly spending limit for this category. Past tracking metrics will not be affected."
                confirmLabel="Delete"
                onConfirm={handleDelete}
                onCancel={() => setDeleteTarget(null)}
            />
        </div>
    );
}
