'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Pencil, Trash2, Tag, ArrowLeft, ChevronDown, ChevronRight } from 'lucide-react';
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
    const [expandedParents, setExpandedParents] = useState<string[]>([]);
    const [form, setForm] = useState({ name: '', type: 'expense', color: '#6366f1', icon: 'Tag', parentCategoryId: '' });
    const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);

    const load = async () => {
        try {
            const res = await getCategories({ tree: 'true' });
            setCategories(res.data);
            setExpandedParents(res.data.map((c: any) => c._id));
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { load(); }, []);

    const toggleExpand = (id: string) => {
        setExpandedParents(prev => 
            prev.includes(id) ? prev.filter(p => p !== id) : [...prev, id]
        );
    };

    const openCreate = (parentId: string = '') => {
        setEditingCategory(null);
        let type = 'expense';
        let color = '#6366f1';
        
        if (parentId) {
            const parent = categories.find(c => c._id === parentId);
            if (parent) {
                type = parent.type;
                color = parent.color;
            }
        }
        
        setForm({ name: '', type, color, icon: 'Tag', parentCategoryId: parentId });
        setModalOpen(true);
    };

    const openEdit = (cat: any) => {
        setEditingCategory(cat);
        setForm({ 
            name: cat.name, 
            type: cat.type, 
            color: cat.color || '#6366f1', 
            icon: cat.icon || 'Tag',
            parentCategoryId: cat.parentCategoryId || ''
        });
        setModalOpen(true);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (submitting) return;
        setSubmitting(true);
        try {
            const payload = { ...form };
            if (!payload.parentCategoryId) delete (payload as any).parentCategoryId;
            
            if (editingCategory) {
                await updateCategory(editingCategory._id, payload);
            } else {
                await createCategory(payload);
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
        }
    };

    const incomeCategories = categories.filter(c => c.type === 'income');
    const expenseCategories = categories.filter(c => c.type === 'expense');

    if (loading && categories.length === 0) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    return (
        <div className="max-w-4xl mx-auto pb-20">
            <div className="mb-6">
                <Link href="/settings" className="text-muted hover:text-white flex items-center gap-2 text-sm transition-colors">
                    <ArrowLeft size={16} /> Back to Settings
                </Link>
            </div>

            <div className="flex items-center justify-between gap-4 mb-8">
                <div>
                    <motion.h1
                        initial={{ opacity: 0, y: -10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="text-xl md:text-2xl lg:text-3xl font-bold text-white flex items-center gap-2 md:gap-3"
                    >
                        <Tag className="text-violet-400 w-6 h-6 md:w-8 md:h-8" /> Categories
                    </motion.h1>
                    <p className="text-xs md:text-sm text-muted mt-1">Manage your primary and sub-categories.</p>
                </div>
                <button onClick={() => openCreate()} className="btn-primary flex items-center gap-2">
                    <Plus size={16} /> Add Primary Category
                </button>
            </div>

            <div className="space-y-12">
                {[{ type: 'expense', list: expenseCategories }, { type: 'income', list: incomeCategories }].map(({ type, list }) => (
                    <section key={type}>
                        <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-widest mb-6 ml-1 flex items-center gap-2">
                             <div className={`w-2 h-2 rounded-full ${type === 'income' ? 'bg-emerald-500' : 'bg-rose-500'}`} />
                             {type} Categories
                        </h2>
                        <div className="space-y-4">
                            {list.length === 0 && <p className="text-sm text-slate-600 italic ml-1">No {type} categories yet.</p>}
                            {list.map((cat) => (
                                <div key={cat._id} className="space-y-2">
                                    <div className="glass-card p-4 flex items-center justify-between group">
                                        <div className="flex items-center gap-4">
                                            <button 
                                                onClick={() => toggleExpand(cat._id)}
                                                className="text-slate-500 hover:text-white transition-colors p-1"
                                            >
                                                {expandedParents.includes(cat._id) ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
                                            </button>
                                            <div
                                                className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 shadow-lg"
                                                style={{ backgroundColor: `${cat.color}20`, color: cat.color }}
                                            >
                                                <Tag className="w-5 h-5" />
                                            </div>
                                            <div>
                                                <h3 className="text-base font-semibold text-white">{cat.name}</h3>
                                                <p className="text-xs text-muted">Primary Category</p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2">
                                            <button
                                                onClick={() => openCreate(cat._id)}
                                                className="hidden md:flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-violet-500/10 text-violet-400 hover:bg-violet-500/20 transition-all border border-violet-500/20"
                                            >
                                                <Plus size={14} /> Sub
                                            </button>
                                            <button
                                                onClick={() => openEdit(cat)}
                                                className="p-2 rounded-lg text-muted hover:text-white hover:bg-white/5 transition-colors"
                                            >
                                                <Pencil size={16} />
                                            </button>
                                            <button
                                                onClick={() => setDeleteTarget(cat._id)}
                                                className="p-2 rounded-lg text-muted hover:text-rose-400 hover:bg-rose-500/10 transition-colors"
                                            >
                                                <Trash2 size={16} />
                                            </button>
                                        </div>
                                    </div>

                                    {/* Sub-categories */}
                                    <AnimatePresence>
                                        {expandedParents.includes(cat._id) && cat.subcategories?.length > 0 && (
                                            <motion.div
                                                initial={{ height: 0, opacity: 0 }}
                                                animate={{ height: 'auto', opacity: 1 }}
                                                exit={{ height: 0, opacity: 0 }}
                                                className="pl-6 md:pl-12 space-y-2 overflow-hidden"
                                            >
                                                {cat.subcategories.map((sub: any) => (
                                                    <div key={sub._id} className="glass-card p-3 flex items-center justify-between bg-white/[0.01]">
                                                        <div className="flex items-center gap-3">
                                                            <div className="w-1.5 h-1.5 rounded-full bg-violet-400" />
                                                            <span className="text-sm text-slate-200">{sub.name}</span>
                                                        </div>
                                                        <div className="flex items-center gap-1">
                                                            <button
                                                                onClick={() => openEdit(sub)}
                                                                className="p-1.5 rounded-lg text-muted hover:text-white hover:bg-white/5 transition-colors"
                                                            >
                                                                <Pencil size={14} />
                                                            </button>
                                                            <button
                                                                onClick={() => setDeleteTarget(sub._id)}
                                                                className="p-1.5 rounded-lg text-muted hover:text-rose-400 hover:bg-rose-500/10 transition-colors"
                                                            >
                                                                <Trash2 size={14} />
                                                            </button>
                                                        </div>
                                                    </div>
                                                ))}
                                            </motion.div>
                                        )}
                                    </AnimatePresence>
                                </div>
                            ))}
                        </div>
                    </section>
                ))}
            </div>

            <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editingCategory ? 'Edit Category' : 'Create Category'}>
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5 uppercase tracking-widest">Category Type</label>
                        <div className="grid grid-cols-2 gap-2">
                            {CATEGORY_TYPES.map((t) => (
                                <button
                                    key={t}
                                    type="button"
                                    onClick={() => setForm({ ...form, type: t })}
                                    className={`py-2 rounded-xl text-xs font-semibold uppercase tracking-wider border transition-all ${
                                        form.type === t
                                            ? 'bg-violet-600 border-violet-500 text-white shadow-lg'
                                            : 'bg-white/5 border-white/10 text-slate-400 hover:bg-white/10'
                                    }`}
                                >
                                    {t}
                                </button>
                            ))}
                        </div>
                    </div>

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5 uppercase tracking-widest">Name</label>
                        <input
                            className="input-dark"
                            value={form.name}
                            onChange={(e) => setForm({ ...form, name: e.target.value })}
                            placeholder="Category Name"
                            required
                        />
                    </div>

                    <div>
                        <label className="block text-xs font-medium text-muted mb-1.5 uppercase tracking-widest">Parent Category (Optional)</label>
                        <Select
                            options={categories.filter(c => !c.parentCategoryId && c.type === form.type && c._id !== editingCategory?._id).map((c) => ({
                                label: c.name,
                                value: c._id
                            }))}
                            value={form.parentCategoryId}
                            onChange={(val) => setForm({ ...form, parentCategoryId: val })}
                            placeholder="None (Make it a Primary Category)"
                        />
                    </div>

                    {!form.parentCategoryId && (
                        <>
                            <div>
                                <label className="block text-xs font-medium text-muted mb-1.5 uppercase tracking-widest">Color</label>
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
                        </>
                    )}

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
                message="Are you sure you want to delete this category? If it's a primary category, all its sub-categories and associated budgets will also be deleted."
                confirmLabel="Delete"
                onConfirm={handleDelete}
                onCancel={() => setDeleteTarget(null)}
            />
        </div>
    );
}
