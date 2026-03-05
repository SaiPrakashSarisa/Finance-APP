'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Pencil, Trash2, Settings, Tag, ArrowLeft } from 'lucide-react';
import { getCategories, createCategory, updateCategory, deleteCategory } from '@/lib/api';
import { CATEGORY_TYPE_LABELS } from '@/lib/utils';
import Modal from '@/components/Modal';
import ConfirmDialog from '@/components/ConfirmDialog';
import { Select } from '@/components/Select';
import Link from 'next/link';

const CATEGORY_TYPES = ['income', 'expense'];

export default function CategoriesPage() {
    const [categories, setCategories] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [modalOpen, setModalOpen] = useState(false);
    const [editingCategory, setEditingCategory] = useState<any>(null);
    const [form, setForm] = useState({ name: '', type: 'expense', color: '#6366f1', icon: 'Tag' });
    const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);

    const load = async () => {
        try {
            const res = await getCategories();
            setCategories(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { load(); }, []);

    const openCreate = () => {
        setEditingCategory(null);
        setForm({ name: '', type: 'expense', color: '#6366f1', icon: 'Tag' });
        setModalOpen(true);
    };

    const openEdit = (cat: any) => {
        setEditingCategory(cat);
        setForm({ name: cat.name, type: cat.type, color: cat.color || '#6366f1', icon: cat.icon || 'Tag' });
        setModalOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (submitting) return;
        setSubmitting(true);
        try {
            if (editingCategory) {
                await updateCategory(editingCategory._id, form);
            } else {
                await createCategory(form);
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
            await deleteCategory(deleteTarget);
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

    const groupedCategories = {
        income: categories.filter(c => c.type === 'income'),
        expense: categories.filter(c => c.type === 'expense'),
    };

    return (
        <div className="max-w-4xl mx-auto">
            <div className="mb-6">
                <Link href="/settings" className="text-muted hover:text-white flex items-center gap-2 text-sm transition-colors">
                    <ArrowLeft size={16} /> Back to Settings
                </Link>
            </div>

            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
                <div>
                    <motion.h1
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="text-2xl sm:text-3xl font-bold text-white flex items-center gap-3"
                    >
                        <Tag className="text-violet-400" /> Categories
                    </motion.h1>
                    <p className="text-muted mt-1">Manage your transaction categories for better tracking.</p>
                </div>
                <button onClick={openCreate} className="btn-primary flex items-center gap-2 self-start sm:self-auto">
                    <Plus size={18} /> Add Category
                </button>
            </div>

            <div className="space-y-10">
                {CATEGORY_TYPES.map(type => (
                    <section key={type}>
                        <div className="flex items-center gap-3 mb-4">
                            <h2 className="text-lg font-semibold text-white capitalize">{type} Categories</h2>
                            <span className="text-xs text-muted bg-white/5 px-2 py-0.5 rounded-full">
                                {groupedCategories[type as keyof typeof groupedCategories].length}
                            </span>
                        </div>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <AnimatePresence mode="popLayout">
                                {groupedCategories[type as keyof typeof groupedCategories].map((cat, i) => (
                                    <motion.div
                                        key={cat._id}
                                        initial={{ opacity: 0, scale: 0.95 }}
                                        animate={{ opacity: 1, scale: 1 }}
                                        exit={{ opacity: 0, scale: 0.95 }}
                                        transition={{ delay: i * 0.03 }}
                                        className="glass-card p-4 flex items-center justify-between group"
                                    >
                                        <div className="flex items-center gap-3">
                                            <div
                                                className="w-10 h-10 rounded-xl flex items-center justify-center text-lg"
                                                style={{ backgroundColor: `${cat.color}20`, color: cat.color }}
                                            >
                                                <Tag size={20} />
                                            </div>
                                            <div>
                                                <h3 className="font-medium text-white">{cat.name}</h3>
                                                <p className="text-xs text-muted uppercase tracking-wider">{cat.type}</p>
                                            </div>
                                        </div>
                                        <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                            <button
                                                onClick={() => openEdit(cat)}
                                                className="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-white/10"
                                            >
                                                <Pencil size={14} />
                                            </button>
                                            <button
                                                onClick={() => setDeleteTarget(cat._id)}
                                                className="p-2 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-rose-500/10"
                                            >
                                                <Trash2 size={14} />
                                            </button>
                                        </div>
                                    </motion.div>
                                ))}
                            </AnimatePresence>
                        </div>
                    </section>
                ))}
            </div>

            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editingCategory ? 'Edit Category' : 'New Category'}>
                <form onSubmit={handleSubmit} className="flex flex-col gap-4">
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Category Name</label>
                        <input
                            className="input-dark"
                            placeholder="e.g. Shopping"
                            value={form.name}
                            onChange={(e) => setForm({ ...form, name: e.target.value })}
                            required
                        />
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Type</label>
                        <Select
                            options={CATEGORY_TYPES.map((t) => ({
                                label: CATEGORY_TYPE_LABELS[t],
                                value: t
                            }))}
                            value={form.type}
                            onChange={(val) => setForm({ ...form, type: val })}
                        />
                    </div>
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5">Color</label>
                        <div className="flex gap-3 items-center">
                            <input
                                type="color"
                                className="w-12 h-10 rounded-lg bg-transparent border-none cursor-pointer"
                                value={form.color}
                                onChange={(e) => setForm({ ...form, color: e.target.value })}
                            />
                            <input
                                className="input-dark flex-1 font-mono uppercase"
                                value={form.color}
                                onChange={(e) => setForm({ ...form, color: e.target.value })}
                                placeholder="#000000"
                            />
                        </div>
                    </div>

                    <div className="flex gap-3 mt-4">
                        <button type="submit" disabled={submitting} className="btn-primary flex-1 disabled:opacity-50 disabled:cursor-not-allowed">
                            {submitting ? 'Saving...' : editingCategory ? 'Update Category' : 'Create Category'}
                        </button>
                        <button type="button" onClick={() => setModalOpen(false)} disabled={submitting} className="btn-ghost flex-1">
                            Cancel
                        </button>
                    </div>
                </form>
            </Modal>

            <ConfirmDialog
                isOpen={!!deleteTarget}
                title="Delete Category?"
                message="Are you sure you want to delete this category? This will not affect existing transactions, but they will no longer have a valid category reference."
                confirmLabel="Delete"
                onConfirm={handleDelete}
                onCancel={() => setDeleteTarget(null)}
            />
        </div>
    );
}
