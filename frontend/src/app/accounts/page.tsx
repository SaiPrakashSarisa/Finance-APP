'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Pencil, Trash2, Wallet } from 'lucide-react';
import { getAccounts, createAccount, updateAccount, deleteAccount } from '@/lib/api';
import { formatCurrency, ACCOUNT_TYPE_LABELS, ACCOUNT_TYPE_COLORS } from '@/lib/utils';
import Modal from '@/components/Modal';
import ConfirmDialog from '@/components/ConfirmDialog';
import Badge from '@/components/Badge';
import { Select } from '@/components/Select';

const ACCOUNT_TYPES = ['bank', 'cash', 'credit_card', 'wallet', 'investment'];

export default function AccountsPage() {
    const [accounts, setAccounts] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [modalOpen, setModalOpen] = useState(false);
    const [editingAccount, setEditingAccount] = useState<any>(null);
    const [form, setForm] = useState({ name: '', type: 'bank', balance: '', currency: 'INR' });
    const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);

    const load = async () => {
        try {
            const res = await getAccounts();
            setAccounts(res.data);
            console.log(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { load(); }, []);

    const openCreate = () => {
        setEditingAccount(null);
        setForm({ name: '', type: 'bank', balance: '', currency: 'INR' });
        setModalOpen(true);
    };

    const openEdit = (acc: any) => {
        setEditingAccount(acc);
        setForm({ name: acc.name, type: acc.type, balance: String(acc.balance), currency: acc.currency });
        setModalOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (submitting) return;
        setSubmitting(true);
        try {
            const data = { ...form, balance: parseFloat(form.balance) || 0 };
            if (editingAccount) {
                await updateAccount(editingAccount._id, data);
            } else {
                await createAccount(data);
            }
            setModalOpen(false);
            load();
        } catch (err: any) {
            alert(err.message);
        } finally {
            setSubmitting(false);
        }
    };

    const handleDelete = async () => {
        if (!deleteTarget) return;
        try {
            await deleteAccount(deleteTarget);
            setDeleteTarget(null);
            load();
        } catch (err: any) {
            alert(err.message);
            setDeleteTarget(null);
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
        <div>
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                <motion.h1
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="text-2xl sm:text-3xl font-bold text-white"
                >
                    Accounts
                </motion.h1>
                <button onClick={openCreate} className="btn-primary flex items-center gap-2 self-start sm:self-auto">
                    <Plus size={18} /> Add Account
                </button>
            </div>

            {accounts.length === 0 ? (
                <div className="text-center py-20 text-muted">
                    <Wallet size={48} className="mx-auto mb-4 opacity-50" />
                    <p>No accounts yet. Create your first account to get started.</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-6">
                    <AnimatePresence>
                        {accounts.map((acc, i) => (
                            <motion.div
                                key={acc._id}
                                initial={{ opacity: 0, y: 20 }}
                                animate={{ opacity: 1, y: 0 }}
                                exit={{ opacity: 0, scale: 0.95 }}
                                transition={{ delay: i * 0.05 }}
                                className="glass-card p-6"
                            >
                                <div className="flex items-start justify-between mb-3">
                                    <div>
                                        <h3 className="text-base font-semibold text-white">{acc.name}</h3>
                                        <Badge label={ACCOUNT_TYPE_LABELS[acc.type] || acc.type} className={ACCOUNT_TYPE_COLORS[acc.type]} />
                                    </div>
                                    <div className="flex gap-1">
                                        <button onClick={() => openEdit(acc)} className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-white/10 transition-colors">
                                            <Pencil size={15} />
                                        </button>
                                        <button onClick={() => setDeleteTarget(acc._id)} className="p-1.5 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 transition-colors">
                                            <Trash2 size={15} />
                                        </button>
                                    </div>
                                </div>
                                <p className={`text-2xl font-bold ${acc.balance >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                                    {formatCurrency(acc.balance, acc.currency)}
                                </p>
                                <p className="text-xs text-muted mt-1">{acc.currency}</p>
                            </motion.div>
                        ))}
                    </AnimatePresence>
                </div>
            )}

            {/* Create / Edit Modal */}
            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editingAccount ? 'Edit Account' : 'New Account'}>
                <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Account Name</label>
                        <input
                            className="input-dark"
                            placeholder="e.g. HDFC Salary"
                            value={form.name}
                            onChange={(e) => setForm({ ...form, name: e.target.value })}
                            required
                        />
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Type</label>
                        <Select
                            options={ACCOUNT_TYPES.map((t) => ({
                                label: ACCOUNT_TYPE_LABELS[t],
                                value: t
                            }))}
                            value={form.type}
                            onChange={(val) => setForm({ ...form, type: val })}
                        />
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Initial Balance</label>
                        <input
                            className="input-dark"
                            type="number"
                            step="0.01"
                            placeholder="0"
                            value={form.balance}
                            onChange={(e) => setForm({ ...form, balance: e.target.value })}
                        />
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Currency</label>
                        <input
                            className="input-dark"
                            placeholder="INR"
                            value={form.currency}
                            onChange={(e) => setForm({ ...form, currency: e.target.value })}
                        />
                    </div>
                    <div className="flex gap-3 mt-2">
                        <button type="submit" disabled={submitting} className="btn-primary flex-1 disabled:opacity-50 disabled:cursor-not-allowed">{submitting ? 'Saving...' : editingAccount ? 'Update' : 'Create'}</button>
                        <button type="button" onClick={() => setModalOpen(false)} disabled={submitting} className="btn-ghost flex-1">Cancel</button>
                    </div>
                </form>
            </Modal>

            <ConfirmDialog
                isOpen={!!deleteTarget}
                title="Delete Account?"
                message="This will deactivate the account. Existing transactions linked to it will remain."
                confirmLabel="Delete"
                onConfirm={handleDelete}
                onCancel={() => setDeleteTarget(null)}
            />
        </div>
    );
}
