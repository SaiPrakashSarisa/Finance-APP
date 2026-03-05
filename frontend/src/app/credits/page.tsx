'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Plus, Pencil, HandCoins } from 'lucide-react';
import { getCredits, createCredit, updateCredit, getAccounts } from '@/lib/api';
import { formatCurrency, formatDate, CREDIT_STATUS_COLORS } from '@/lib/utils';
import Modal from '@/components/Modal';
import Badge from '@/components/Badge';
import { Select } from '@/components/Select';

export default function CreditsPage() {
    const [credits, setCredits] = useState<any[]>([]);
    const [accounts, setAccounts] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState<'given' | 'taken'>('given');
    const [modalOpen, setModalOpen] = useState(false);
    const [editingCredit, setEditingCredit] = useState<any>(null);
    const [submitting, setSubmitting] = useState(false);

    const emptyForm = { type: 'given', subType: 'account_credit', personName: '', amount: '', linkedAccountId: '', dueDate: '', notes: '', interestRate: '' };
    const [form, setForm] = useState(emptyForm);

    const load = async () => {
        try {
            const [credRes, accRes] = await Promise.all([getCredits(), getAccounts()]);
            setCredits(credRes.data);
            setAccounts(accRes.data);
        } catch (err) { console.error(err); }
        finally { setLoading(false); }
    };

    useEffect(() => { load(); }, []);

    const filteredCredits = credits.filter((c) => c.type === activeTab);

    const openCreate = () => {
        setEditingCredit(null);
        setForm({ ...emptyForm, type: activeTab });
        setModalOpen(true);
    };

    const openEdit = (credit: any) => {
        setEditingCredit(credit);
        const accId = typeof credit.linkedAccountId === 'object' && credit.linkedAccountId?._id
            ? credit.linkedAccountId._id : (credit.linkedAccountId || '');
        setForm({
            type: credit.type,
            subType: credit.subType || 'account_credit',
            personName: credit.personName,
            amount: String(credit.amount),
            linkedAccountId: accId,
            dueDate: credit.dueDate ? new Date(credit.dueDate).toISOString().split('T')[0] : '',
            notes: credit.notes || '',
            interestRate: credit.interestRate ? String(credit.interestRate) : '',
        });
        setModalOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (submitting) return;
        setSubmitting(true);
        try {
            if (editingCredit) {
                // Only send editable fields
                await updateCredit(editingCredit._id, {
                    personName: form.personName,
                    dueDate: form.dueDate || null,
                    notes: form.notes,
                    interestRate: parseFloat(form.interestRate) || 0,
                });
            } else {
                const data: any = {
                    type: form.type,
                    personName: form.personName,
                    amount: parseFloat(form.amount),
                    dueDate: form.dueDate || null,
                    notes: form.notes,
                    interestRate: parseFloat(form.interestRate) || 0,
                };
                if (form.type === 'given') {
                    data.linkedAccountId = form.linkedAccountId;
                } else {
                    data.subType = form.subType;
                    if (form.subType === 'account_credit') {
                        data.linkedAccountId = form.linkedAccountId;
                    }
                    // emi_loan: no linkedAccountId
                }
                await createCredit(data);
            }
            setModalOpen(false);
            setEditingCredit(null);
            setForm(emptyForm);
            load();
        } catch (err: any) { alert(err.message); }
        finally { setSubmitting(false); }
    };

    const getAccountName = (id: any) => {
        if (typeof id === 'object' && id?.name) return id.name;
        return accounts.find((a) => a._id === id)?.name || '—';
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    // Whether to show account dropdown
    const showAccountSelect = form.type === 'given' || (form.type === 'taken' && form.subType === 'account_credit');

    return (
        <div>
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                <motion.h1 initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="text-2xl sm:text-3xl font-bold text-white">
                    Credits
                </motion.h1>
                <button onClick={openCreate} className="btn-primary flex items-center gap-2 self-start sm:self-auto">
                    <Plus size={18} /> Add Credit
                </button>
            </div>

            {/* Tabs */}
            <div className="flex gap-1 mb-6 bg-surface rounded-xl p-1 w-fit">
                {(['given', 'taken'] as const).map((tab) => (
                    <button
                        key={tab}
                        onClick={() => setActiveTab(tab)}
                        className={`px-5 py-2 rounded-lg text-sm font-medium capitalize transition-all ${activeTab === tab
                            ? tab === 'given' ? 'bg-amber-500/20 text-amber-400' : 'bg-rose-500/20 text-rose-400'
                            : 'text-slate-400 hover:text-white hover:bg-white/5'
                            }`}
                    >
                        {tab === 'given' ? '↗ Given (Receivables)' : '↙ Taken (Liabilities)'}
                    </button>
                ))}
            </div>

            {/* Credits List */}
            {filteredCredits.length === 0 ? (
                <div className="text-center py-20 text-muted">
                    <HandCoins size={48} className="mx-auto mb-4 opacity-50" />
                    <p>No {activeTab} credits found.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-6">
                    {filteredCredits.map((credit, i) => {
                        const progress = credit.amount > 0 ? ((credit.amount - credit.remainingAmount) / credit.amount) * 100 : 0;
                        return (
                            <motion.div
                                key={credit._id}
                                initial={{ opacity: 0, y: 20 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ delay: i * 0.05 }}
                                className="glass-card p-6"
                            >
                                <div className="flex items-start justify-between mb-3">
                                    <div>
                                        <h3 className="text-base font-semibold text-white">{credit.personName}</h3>
                                        <p className="text-xs text-muted mt-0.5">
                                            {credit.linkedAccountId ? getAccountName(credit.linkedAccountId) : credit.subType === 'emi_loan' ? '🏦 EMI / Loan' : '—'}
                                        </p>
                                    </div>
                                    <div className="flex items-center gap-2">
                                        <button onClick={() => openEdit(credit)} className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-white/10 transition-colors">
                                            <Pencil size={15} />
                                        </button>
                                        <Badge label={credit.status} className={CREDIT_STATUS_COLORS[credit.status]} />
                                    </div>
                                </div>

                                <div className="mb-3">
                                    <div className="flex justify-between text-sm mb-1">
                                        <span className="text-slate-400">Remaining</span>
                                        <span className={`font-semibold ${credit.type === 'given' ? 'text-amber-400' : 'text-rose-400'}`}>
                                            {formatCurrency(credit.remainingAmount)}
                                        </span>
                                    </div>
                                    <div className="w-full h-2 rounded-full bg-white/10 overflow-hidden">
                                        <motion.div
                                            initial={{ width: 0 }}
                                            animate={{ width: `${progress}%` }}
                                            transition={{ duration: 0.8, delay: i * 0.05 }}
                                            className={`h-full rounded-full ${credit.type === 'given' ? 'bg-amber-500' : 'bg-rose-500'}`}
                                        />
                                    </div>
                                    <div className="flex justify-between text-xs text-muted mt-1">
                                        <span>Paid: {formatCurrency(credit.amount - credit.remainingAmount)}</span>
                                        <span>Total: {formatCurrency(credit.amount)}</span>
                                    </div>
                                </div>

                                {(credit.interestRate > 0 || credit.dueDate) && (
                                    <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-400 mb-2">
                                        {credit.interestRate > 0 && <span>@ {credit.interestRate}% p.a.</span>}
                                        {credit.dueDate && <span>Due: {formatDate(credit.dueDate)}</span>}
                                    </div>
                                )}
                                {credit.notes && (
                                    <p className="text-xs text-slate-500">{credit.notes}</p>
                                )}
                            </motion.div>
                        );
                    })}
                </div>
            )}

            {/* Create / Edit Credit Modal */}
            <Modal isOpen={modalOpen} onClose={() => { setModalOpen(false); setEditingCredit(null); }} title={editingCredit ? 'Edit Credit' : 'New Credit'}>
                <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                    {/* Type - only shown when creating */}
                    {!editingCredit && (
                        <div>
                            <label className="block text-xs font-medium text-muted mb-1.5">Type</label>
                            <div className="grid grid-cols-2 gap-2">
                                {(['given', 'taken'] as const).map((t) => (
                                    <button key={t} type="button" onClick={() => setForm({ ...form, type: t, subType: 'account_credit', linkedAccountId: '' })} className={`py-2 rounded-lg text-sm font-medium capitalize transition-all ${form.type === t
                                        ? t === 'given' ? 'bg-amber-500/20 text-amber-400 ring-1 ring-amber-500/40' : 'bg-rose-500/20 text-rose-400 ring-1 ring-rose-500/40'
                                        : 'bg-white/5 text-slate-400 hover:bg-white/10'
                                        }`}>
                                        {t === 'given' ? '↗ Given' : '↙ Taken'}
                                    </button>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Sub-type for Taken - only shown when creating */}
                    {!editingCredit && form.type === 'taken' && (
                        <div>
                            <label className="block text-xs font-medium text-muted mb-1.5">Credit Type</label>
                            <div className="grid grid-cols-2 gap-2">
                                <button type="button" onClick={() => setForm({ ...form, subType: 'account_credit', linkedAccountId: '' })}
                                    className={`py-2 rounded-lg text-sm font-medium transition-all ${form.subType === 'account_credit'
                                        ? 'bg-blue-500/20 text-blue-400 ring-1 ring-blue-500/40'
                                        : 'bg-white/5 text-slate-400 hover:bg-white/10'}`}>
                                    💳 To Account
                                </button>
                                <button type="button" onClick={() => setForm({ ...form, subType: 'emi_loan', linkedAccountId: '' })}
                                    className={`py-2 rounded-lg text-sm font-medium transition-all ${form.subType === 'emi_loan'
                                        ? 'bg-blue-500/20 text-blue-400 ring-1 ring-blue-500/40'
                                        : 'bg-white/5 text-slate-400 hover:bg-white/10'}`}>
                                    🏦 EMI / Loan
                                </button>
                            </div>
                        </div>
                    )}

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Person Name</label>
                        <input className="input-dark" placeholder="Who?" value={form.personName} onChange={(e) => setForm({ ...form, personName: e.target.value })} required />
                    </div>

                    {/* Amount - only shown when creating */}
                    {!editingCredit && (
                        <div>
                            <label className="block text-xs font-medium text-muted mb-1.5">Amount</label>
                            <input className="input-dark" type="number" step="0.01" min="0.01" placeholder="0.00" value={form.amount} onChange={(e) => setForm({ ...form, amount: e.target.value })} required />
                        </div>
                    )}

                    {/* Account selector - conditional */}
                    {!editingCredit && showAccountSelect && (
                        <div>
                            <label className="block text-xs font-medium text-muted mb-1.5">
                                {form.type === 'given' ? 'Given from Account' : 'Credited to Account'}
                            </label>
                            <Select
                                options={accounts.map((a) => ({ label: a.name, value: a._id }))}
                                value={form.linkedAccountId}
                                onChange={(val) => setForm({ ...form, linkedAccountId: val })}
                                placeholder="Select account"
                            />
                        </div>
                    )}

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Interest Rate % (optional)</label>
                        <input className="input-dark" type="number" step="0.01" min="0" max="100" placeholder="e.g. 12" value={form.interestRate} onChange={(e) => setForm({ ...form, interestRate: e.target.value })} />
                    </div>

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Due Date (optional)</label>
                        <input className="input-dark" type="date" value={form.dueDate} onChange={(e) => setForm({ ...form, dueDate: e.target.value })} />
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Notes (optional)</label>
                        <input className="input-dark" placeholder="Add notes..." value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />
                    </div>
                    <div className="flex gap-3 mt-2">
                        <button type="submit" disabled={submitting} className="btn-primary flex-1 disabled:opacity-50 disabled:cursor-not-allowed">{submitting ? 'Saving...' : editingCredit ? 'Update' : 'Create'}</button>
                        <button type="button" onClick={() => { setModalOpen(false); setEditingCredit(null); }} disabled={submitting} className="btn-ghost flex-1">Cancel</button>
                    </div>
                </form>
            </Modal>
        </div>
    );
}
