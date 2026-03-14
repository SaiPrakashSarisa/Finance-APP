'use client';

import { useEffect, useState, useCallback } from 'react';
import { motion } from 'framer-motion';
import { Plus, Pencil, Trash2, ArrowLeftRight, Filter, X } from 'lucide-react';
import { getTransactions, createTransaction, updateTransaction, deleteTransaction, getAccounts, getCategories, getCredits } from '@/lib/api';
import { formatCurrency, formatDate, TRANSACTION_TYPE_COLORS } from '@/lib/utils';
import Modal from '@/components/Modal';
import ConfirmDialog from '@/components/ConfirmDialog';
import Badge from '@/components/Badge';
import { Select } from '@/components/Select';

const TYPE_TABS = ['all', 'income', 'expense', 'transfer', 'credit_repay'] as const;
const TYPE_LABELS: Record<string, string> = { all: 'All', income: 'Income', expense: 'Expense', transfer: 'Transfer', credit_repay: 'Repayment' };

export default function TransactionsPage() {
    const [transactions, setTransactions] = useState<any[]>([]);
    const [accounts, setAccounts] = useState<any[]>([]);
    const [categories, setCategories] = useState<any[]>([]);
    const [credits, setCredits] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [modalOpen, setModalOpen] = useState(false);
    const [filterOpen, setFilterOpen] = useState(false);
    const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);
    const [editingTransaction, setEditingTransaction] = useState<any>(null);

    // Filters
    const [typeFilter, setTypeFilter] = useState<string>('all');
    const [accountFilter, setAccountFilter] = useState<string>('');
    const [categoryFilter, setCategoryFilter] = useState<string>('');
    const [creditFilter, setCreditFilter] = useState<string>('');
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');

    // Form
    const emptyForm = {
        type: 'expense',
        amount: '',
        accountId: '',
        toAccountId: '',
        categoryId: '',
        creditId: '',
        note: '',
        date: new Date().toISOString().split('T')[0],
    };
    const [form, setForm] = useState(emptyForm);

    const loadData = useCallback(async () => {
        try {
            const params: Record<string, string> = {};
            if (typeFilter !== 'all') params.type = typeFilter;
            if (accountFilter) params.accountId = accountFilter;
            if (categoryFilter) params.categoryId = categoryFilter;
            if (creditFilter) params.creditId = creditFilter;
            if (startDate) params.startDate = startDate;
            if (endDate) params.endDate = endDate;

            const [txRes, accRes, catRes, credRes] = await Promise.all([
                getTransactions(Object.keys(params).length > 0 ? params : undefined),
                getAccounts(),
                getCategories(),
                getCredits(),
            ]);
            setTransactions(txRes.transactions || []);
            setAccounts(accRes.data);
            setCategories(catRes.data);
            setCredits(credRes.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    }, [typeFilter, accountFilter, categoryFilter, creditFilter, startDate, endDate]);

    useEffect(() => { loadData(); }, [loadData]);

    const openEdit = (tx: any) => {
        setEditingTransaction(tx);
        const getId = (field: any) => typeof field === 'object' && field?._id ? field._id : (field || '');
        setForm({
            type: tx.type,
            amount: String(tx.amount),
            accountId: getId(tx.accountId),
            toAccountId: getId(tx.toAccountId),
            categoryId: getId(tx.categoryId),
            creditId: getId(tx.creditId),
            note: tx.note || '',
            date: tx.date ? new Date(tx.date).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
        });
        setModalOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (submitting) return;
        setSubmitting(true);
        try {
            const data: any = {
                type: form.type,
                amount: parseFloat(form.amount),
                accountId: form.accountId,
                note: form.note,
                date: form.date,
            };
            if (form.type !== 'transfer' && form.type !== 'credit_repay' && form.categoryId) {
                data.categoryId = form.categoryId;
            }
            if (form.type === 'transfer') {
                data.toAccountId = form.toAccountId;
            }
            if (form.type === 'credit_repay' && form.creditId) {
                data.creditId = form.creditId;
            }
            if (editingTransaction) {
                await updateTransaction(editingTransaction._id, data);
            } else {
                await createTransaction(data);
            }
            setModalOpen(false);
            setEditingTransaction(null);
            setForm(emptyForm);
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
            await deleteTransaction(deleteTarget);
            setDeleteTarget(null);
            loadData();
        } catch (err: any) {
            alert(err.message);
            setDeleteTarget(null);
        }
    };

    const clearFilters = () => {
        setTypeFilter('all');
        setAccountFilter('');
        setCategoryFilter('');
        setCreditFilter('');
        setStartDate('');
        setEndDate('');
    };

    const hasActiveFilters = typeFilter !== 'all' || accountFilter || categoryFilter || creditFilter || startDate || endDate;

    const getCreditLabel = (creditObj: any) => {
        if (!creditObj) return '—';
        if (typeof creditObj === 'object' && creditObj.personName) {
            return `${creditObj.personName} (${creditObj.type})`;
        }
        const c = credits.find(cr => cr._id === creditObj);
        return c ? `${c.personName} (${c.type})` : '—';
    };

    const getAccountName = (idOrObj: any) => {
        if (!idOrObj) return '—';
        if (typeof idOrObj === 'object' && idOrObj.name) return idOrObj.name;
        return accounts.find((a) => a._id === idOrObj)?.name || '—';
    };
    const getCategoryName = (idOrObj: any) => {
        if (!idOrObj) return '—';
        if (typeof idOrObj === 'object' && idOrObj.name) return idOrObj.name;
        return categories.find((c) => c._id === idOrObj)?.name || '—';
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    return (
        <div>
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                <motion.h1
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="text-xl md:text-2xl lg:text-3xl font-bold text-white"
                >
                    Transactions
                </motion.h1>
                <div className="flex gap-2 self-start sm:self-auto">
                    <button
                        onClick={() => setFilterOpen(!filterOpen)}
                        className={`btn-ghost flex items-center gap-2 ${hasActiveFilters ? 'border-violet-500 text-violet-400' : ''}`}
                    >
                        <Filter size={16} /> Filters {hasActiveFilters && '•'}
                    </button>
                    <button onClick={() => { setEditingTransaction(null); setForm(emptyForm); setModalOpen(true); }} className="btn-primary flex items-center gap-2">
                        <Plus size={18} /> Add
                    </button>
                </div>
            </div>

            {/* Type Tabs */}
            <div className="flex gap-1 mb-4 bg-surface rounded-xl p-1 overflow-x-auto">
                {TYPE_TABS.map((tab) => (
                    <button
                        key={tab}
                        onClick={() => setTypeFilter(tab)}
                        className={`px-4 py-2 rounded-lg text-sm font-medium transition-all capitalize whitespace-nowrap ${typeFilter === tab
                            ? 'bg-violet-500/20 text-violet-400'
                            : 'text-slate-400 hover:text-white hover:bg-white/5'
                            }`}
                    >
                        {TYPE_LABELS[tab] || tab}
                    </button>
                ))}
            </div>

            {/* Filter Panel */}
            {filterOpen && (
                <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    className="glass-card p-4 md:p-6 mb-4 md:mb-6"
                >
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                        <div>
                            <label className="block text-xs text-muted mb-1">Account</label>
                            <Select
                                options={[
                                    { label: 'All Accounts', value: '' },
                                    ...accounts.map((a) => ({ label: a.name, value: a._id })),
                                ]}
                                value={accountFilter}
                                onChange={setAccountFilter}
                            />
                        </div>
                        <div>
                            <label className="block text-xs text-muted mb-1">Category</label>
                            <Select
                                options={[
                                    { label: 'All Categories', value: '' },
                                    ...categories.map((c) => ({ label: c.name, value: c._id })),
                                ]}
                                value={categoryFilter}
                                onChange={setCategoryFilter}
                            />
                        </div>
                        <div>
                            <label className="block text-xs text-muted mb-1">Credit</label>
                            <Select
                                options={[
                                    { label: 'All Credits', value: '' },
                                    ...credits.filter(c => c.status !== 'settled').map((c) => ({ label: `${c.personName} (${c.type})`, value: c._id })),
                                ]}
                                value={creditFilter}
                                onChange={setCreditFilter}
                            />
                        </div>
                        <div>
                            <label className="block text-xs text-muted mb-1">From Date</label>
                            <input type="date" className="input-dark" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
                        </div>
                        <div>
                            <label className="block text-xs text-muted mb-1">To Date</label>
                            <input type="date" className="input-dark" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
                        </div>
                    </div>
                    {hasActiveFilters && (
                        <button onClick={clearFilters} className="mt-3 text-xs text-rose-400 hover:text-rose-300 flex items-center gap-1">
                            <X size={14} /> Clear all filters
                        </button>
                    )}
                </motion.div>
            )}

            {/* Transactions List — Card layout (responsive) */}
            {transactions.length === 0 ? (
                <div className="text-center py-20 text-muted">
                    <ArrowLeftRight size={48} className="mx-auto mb-4 opacity-50" />
                    <p>No transactions found. Add your first transaction or adjust filters.</p>
                </div>
            ) : (
                <>
                    {/* Desktop Table */}
                    <div className="hidden md:block glass-card overflow-hidden">
                        <table className="w-full text-sm">
                            <thead>
                                <tr className="border-b border-border">
                                    <th className="text-left px-4 py-3 text-xs font-semibold text-muted uppercase">Date</th>
                                    <th className="text-left px-4 py-3 text-xs font-semibold text-muted uppercase">Type</th>
                                    <th className="text-left px-4 py-3 text-xs font-semibold text-muted uppercase">Account</th>
                                    <th className="text-left px-4 py-3 text-xs font-semibold text-muted uppercase">Category</th>
                                    <th className="text-right px-4 py-3 text-xs font-semibold text-muted uppercase">Amount</th>
                                    <th className="text-left px-4 py-3 text-xs font-semibold text-muted uppercase">Note</th>
                                    <th className="px-4 py-3"></th>
                                </tr>
                            </thead>
                            <tbody>
                                {transactions.map((tx: any) => (
                                    <tr key={tx._id} className="border-b border-border/50 hover:bg-white/[0.02] transition-colors">
                                        <td className="px-4 py-3 text-slate-300 whitespace-nowrap">{formatDate(tx.date)}</td>
                                        <td className="px-4 py-3">
                                            <Badge label={tx.type} className={TRANSACTION_TYPE_COLORS[tx.type]} />
                                        </td>
                                        <td className="px-4 py-3 text-white">
                                            {getAccountName(tx.accountId)}
                                            {tx.type === 'transfer' && tx.toAccountId && (
                                                <span className="text-muted"> → {getAccountName(tx.toAccountId)}</span>
                                            )}
                                        </td>
                                        <td className="px-4 py-3 text-slate-300">{tx.type === 'credit_repay' ? getCreditLabel(tx.creditId) : tx.categoryId ? getCategoryName(tx.categoryId) : '—'}</td>
                                        <td className={`px-4 py-3 text-right font-semibold ${tx.type === 'income' ? 'text-emerald-400' : tx.type === 'expense' ? 'text-rose-400' : tx.type === 'credit_repay' ? 'text-cyan-400' : 'text-violet-400'
                                            }`}>
                                            {tx.type === 'income' || (tx.type === 'credit_repay' && tx.creditId?.type === 'given') ? '+' : tx.type === 'expense' || tx.type === 'credit_repay' ? '-' : ''}
                                            {formatCurrency(tx.amount)}
                                        </td>
                                        <td className="px-4 py-3 text-slate-400 max-w-[150px] truncate">{tx.note || ''}</td>
                                        <td className="px-4 py-3">
                                            <div className="flex gap-1">
                                                <button onClick={() => openEdit(tx)} className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-white/10 transition-colors">
                                                    <Pencil size={15} />
                                                </button>
                                                <button onClick={() => setDeleteTarget(tx._id)} className="p-1.5 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 transition-colors">
                                                    <Trash2 size={15} />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>

                    {/* Mobile Card List */}
                    <div className="md:hidden flex flex-col gap-3">
                        {transactions.map((tx: any, i: number) => (
                            <motion.div
                                key={tx._id}
                                initial={{ opacity: 0, y: 10 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ delay: i * 0.03 }}
                                className="glass-card p-4"
                            >
                                <div className="flex items-start justify-between mb-2">
                                    <div>
                                        <div className="flex items-center gap-2 mb-1">
                                            <Badge label={tx.type} className={TRANSACTION_TYPE_COLORS[tx.type]} />
                                            <span className="text-[10px] sm:text-xs text-muted">{formatDate(tx.date)}</span>
                                        </div>
                                        <p className="text-sm text-white">
                                            {getAccountName(tx.accountId)}
                                            {tx.type === 'transfer' && tx.toAccountId && (
                                                <span className="text-muted"> → {getAccountName(tx.toAccountId)}</span>
                                            )}
                                        </p>
                                        {tx.type === 'credit_repay' && tx.creditId && <p className="text-xs text-cyan-400 mt-0.5">{getCreditLabel(tx.creditId)}</p>}
                                        {tx.type !== 'credit_repay' && tx.categoryId && <p className="text-xs text-slate-400 mt-0.5">{getCategoryName(tx.categoryId)}</p>}
                                        {tx.note && <p className="text-xs text-slate-500 mt-1">{tx.note}</p>}
                                    </div>
                                    <div className="text-right">
                                        <p className={`text-base sm:text-lg font-bold ${tx.type === 'income' ? 'text-emerald-400' : tx.type === 'expense' ? 'text-rose-400' : tx.type === 'credit_repay' ? 'text-cyan-400' : 'text-violet-400'
                                            }`}>
                                            {tx.type === 'income' || (tx.type === 'credit_repay' && tx.creditId?.type === 'given') ? '+' : tx.type === 'expense' || tx.type === 'credit_repay' ? '-' : ''}
                                            {formatCurrency(tx.amount)}
                                        </p>
                                        <div className="flex gap-1 mt-1 justify-end">
                                            <button onClick={() => openEdit(tx)} className="p-1 rounded text-slate-500 hover:text-white transition-colors">
                                                <Pencil size={14} />
                                            </button>
                                            <button onClick={() => setDeleteTarget(tx._id)} className="p-1 rounded text-slate-500 hover:text-rose-400 transition-colors">
                                                <Trash2 size={14} />
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </motion.div>
                        ))}
                    </div>
                </>
            )}

            {/* Add Transaction Modal */}
            <Modal isOpen={modalOpen} onClose={() => { setModalOpen(false); setEditingTransaction(null); }} title={editingTransaction ? 'Edit Transaction' : 'New Transaction'}>
                <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                    {/* Type Selector */}
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Type</label>
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                            {(['income', 'expense', 'transfer', 'credit_repay'] as const).map((t) => (
                                <button
                                    key={t}
                                    type="button"
                                    onClick={() => setForm({ ...form, type: t, creditId: '', categoryId: '', toAccountId: '' })}
                                    className={`py-2 rounded-lg text-sm font-medium transition-all ${form.type === t
                                        ? t === 'income' ? 'bg-emerald-500/20 text-emerald-400 ring-1 ring-emerald-500/40'
                                            : t === 'expense' ? 'bg-rose-500/20 text-rose-400 ring-1 ring-rose-500/40'
                                                : t === 'credit_repay' ? 'bg-cyan-500/20 text-cyan-400 ring-1 ring-cyan-500/40'
                                                    : 'bg-violet-500/20 text-violet-400 ring-1 ring-violet-500/40'
                                        : 'bg-white/5 text-slate-400 hover:bg-white/10'
                                        }`}
                                >
                                    {TYPE_LABELS[t]}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Amount</label>
                        <input className="input-dark" type="number" step="0.01" min="0.01" placeholder="0.00" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} required />
                    </div>

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">{form.type === 'transfer' ? 'From Account' : form.type === 'credit_repay' ? 'Through Account' : 'Account'}</label>
                        <Select
                            options={accounts.map((a) => ({
                                label: `${a.name} (${formatCurrency(a.balance)})`,
                                value: a._id
                            }))}
                            value={form.accountId}
                            onChange={(val) => setForm({ ...form, accountId: val })}
                            placeholder="Select account"
                        />
                    </div>

                    {form.type === 'transfer' && (
                        <div>
                            <label className="block text-xs font-medium text-muted mb-1.5">To Account</label>
                            <Select
                                options={accounts.filter(a => a._id !== form.accountId).map((a) => ({
                                    label: a.name,
                                    value: a._id
                                }))}
                                value={form.toAccountId}
                                onChange={(val) => setForm({ ...form, toAccountId: val })}
                                placeholder="Select destination"
                            />
                        </div>
                    )}

                    {form.type === 'credit_repay' && (
                        <div>
                            <label className="block text-xs font-medium text-muted mb-1.5">Credit Entry</label>
                            <Select
                                options={credits.filter(c => c.status !== 'settled').map((c) => ({
                                    label: `${c.personName} — ${formatCurrency(c.remainingAmount)} (${c.type})`,
                                    value: c._id
                                }))}
                                value={form.creditId}
                                onChange={(val) => setForm({ ...form, creditId: val })}
                                placeholder="Select credit"
                            />
                        </div>
                    )}

                    {form.type !== 'transfer' && form.type !== 'credit_repay' && (
                        <div>
                            <label className="block text-xs font-medium text-muted mb-1.5">Category</label>
                            <Select
                                options={categories.filter(c => c.type === form.type).map((c) => ({
                                    label: c.name,
                                    value: c._id
                                }))}
                                value={form.categoryId}
                                onChange={(val) => setForm({ ...form, categoryId: val })}
                                placeholder="Select category"
                            />
                        </div>
                    )}

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Date</label>
                        <input className="input-dark" type="date" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} required />
                    </div>

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Note (optional)</label>
                        <input className="input-dark" placeholder="Add a note..." value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })} />
                    </div>

                    <div className="flex gap-3 mt-2">
                        <button type="submit" disabled={submitting} className="btn-primary flex-1 disabled:opacity-50 disabled:cursor-not-allowed">{submitting ? 'Saving...' : editingTransaction ? 'Update Transaction' : 'Add Transaction'}</button>
                        <button type="button" onClick={() => { setModalOpen(false); setEditingTransaction(null); }} disabled={submitting} className="btn-ghost flex-1">Cancel</button>
                    </div>
                </form>
            </Modal>

            <ConfirmDialog
                isOpen={!!deleteTarget}
                title="Delete Transaction?"
                message="This will permanently delete the transaction and reverse the balance update on the linked account."
                confirmLabel="Delete"
                onConfirm={handleDelete}
                onCancel={() => setDeleteTarget(null)}
            />
        </div>
    );
}
