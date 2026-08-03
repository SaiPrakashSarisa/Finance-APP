'use client';

import React, { useEffect, useState, useCallback, useRef } from 'react';
import { motion } from 'framer-motion';
import { Plus, Pencil, Trash2, ArrowLeftRight, Filter, X, Download, Upload, RefreshCw } from 'lucide-react';
import { getTransactions, createTransaction, updateTransaction, deleteTransaction, getAccounts, getCategories, getCredits, lookupMasterItem, exportTransactionsCSV, importTransactionsCSV } from '@/lib/api';
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
    const [importModalOpen, setImportModalOpen] = useState(false);
    const [filterOpen, setFilterOpen] = useState(false);
    const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);
    const [importing, setImporting] = useState(false);
    const [importMode, setImportMode] = useState<'replace' | 'append'>('replace');
    const [csvFileText, setCsvFileText] = useState('');
    const [editingTransaction, setEditingTransaction] = useState<any>(null);

    // Filters
    const [typeFilter, setTypeFilter] = useState<string>('all');
    const [accountFilter, setAccountFilter] = useState<string>('');
    const [mainCategoryFilter, setMainCategoryFilter] = useState<string>('');
    const [subCategoryFilter, setSubCategoryFilter] = useState<string>('');
    const [creditFilter, setCreditFilter] = useState<string>('');
    const [startDate, setStartDate] = useState('');
    const [endDate, setEndDate] = useState('');

    // Pagination
    const [page, setPage] = useState(1);
    const [limit, setLimit] = useState(20);
    const [totalPages, setTotalPages] = useState(1);
    const [totalItems, setTotalItems] = useState(0);
    const [isMobile, setIsMobile] = useState(false);
    const [loadingMore, setLoadingMore] = useState(false);
    const observerTarget = useRef<HTMLDivElement>(null);

    const [expandedReceipts, setExpandedReceipts] = useState<Record<string, boolean>>({});

    // Form
    const emptyForm = {
        type: 'expense',
        amount: '',
        accountId: '',
        toAccountId: '',
        mainCategoryId: '',
        categoryId: '',
        creditId: '',
        merchantName: '',
        isItemized: false,
        useItemCategories: false,
        items: [] as Array<{ name: string; mainCategoryId?: string; categoryId?: string; quantity: number; unit: string; unitPrice: number; totalPrice: number }>,
        note: '',
        date: new Date().toISOString().split('T')[0],
    };
    const [form, setForm] = useState(emptyForm);
    const [showCustomCategories, setShowCustomCategories] = useState(false);

    const categoriesRef = useRef(categories);
    categoriesRef.current = categories;

    const loadMetadata = useCallback(async () => {
        try {
            const [accRes, catRes, credRes] = await Promise.all([
                getAccounts(),
                getCategories(),
                getCredits(),
            ]);
            setAccounts(accRes.data || []);
            setCategories(catRes.data || []);
            setCredits(credRes.data || []);
        } catch (err) {
            console.error(err);
        }
    }, []);

    const loadTransactions = useCallback(async () => {
        try {
            const isAppending = isMobile && page > 1;
            if (isAppending) {
                setLoadingMore(true);
            }

            const params: Record<string, string> = {};
            if (typeFilter !== 'all') params.type = typeFilter;
            if (accountFilter) params.accountId = accountFilter;
            
            if (subCategoryFilter) {
                params.categoryId = subCategoryFilter;
            } else if (mainCategoryFilter) {
                const childIds = categoriesRef.current
                    .filter(c => c.parentCategoryId === mainCategoryFilter)
                    .map(c => c._id);
                params.categoryId = [mainCategoryFilter, ...childIds].join(',');
            }

            if (creditFilter) params.creditId = creditFilter;
            if (startDate) params.startDate = startDate;
            if (endDate) params.endDate = endDate;
            params.page = String(page);
            params.limit = String(isMobile ? Math.max(limit, 50) : limit);

            const txRes = await getTransactions(Object.keys(params).length > 0 ? params : undefined);

            setTransactions(prev => isAppending ? [...prev, ...(txRes.transactions || [])] : (txRes.transactions || []));
            setTotalPages(txRes.pages || 1);
            setTotalItems(txRes.total || 0);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
            setLoadingMore(false);
        }
    }, [typeFilter, accountFilter, mainCategoryFilter, subCategoryFilter, creditFilter, startDate, endDate, page, limit, isMobile]);

    const loadData = useCallback(async () => {
        await Promise.all([loadMetadata(), loadTransactions()]);
    }, [loadMetadata, loadTransactions]);

    useEffect(() => {
        loadMetadata();
    }, [loadMetadata]);

    useEffect(() => {
        loadTransactions();
    }, [loadTransactions]);

    useEffect(() => {
        const checkMobile = () => {
            const mobile = window.innerWidth < 768;
            setIsMobile(mobile);
        };
        checkMobile();
        window.addEventListener('resize', checkMobile);
        return () => window.removeEventListener('resize', checkMobile);
    }, []);

    useEffect(() => {
        if (isMobile && limit < 50) {
            setLimit(50);
            setPage(1);
        }
    }, [isMobile, limit]);

    useEffect(() => {
        if (!isMobile || loading || loadingMore || page >= totalPages) return;

        const observer = new IntersectionObserver(
            (entries) => {
                if (entries[0].isIntersecting) {
                    setPage((p) => p + 1);
                }
            },
            { threshold: 0.1 }
        );

        if (observerTarget.current) {
            observer.observe(observerTarget.current);
        }

        return () => observer.disconnect();
    }, [isMobile, loading, loadingMore, page, totalPages]);

    const openEdit = (tx: any) => {
        setEditingTransaction(tx);
        const getId = (field: any) => typeof field === 'object' && field?._id ? field._id : (field || '');
        
        const catId = getId(tx.categoryId);
        const category = categories.find(c => c._id === catId);
        
        let mainCategoryId = '';
        let subCategoryId = '';
        
        if (category) {
            if (category.parentCategoryId) {
                mainCategoryId = category.parentCategoryId;
                subCategoryId = catId;
            } else {
                mainCategoryId = catId;
                subCategoryId = '';
            }
        }

        setShowCustomCategories(!!(tx.items && tx.items.some((i: any) => !!i.categoryId)));
        setForm({
            type: tx.type,
            amount: String(tx.amount),
            accountId: getId(tx.accountId),
            toAccountId: getId(tx.toAccountId),
            mainCategoryId: mainCategoryId,
            categoryId: subCategoryId,
            creditId: getId(tx.creditId),
            merchantName: tx.merchantName || (tx.merchantId?.name || ''),
            isItemized: !!tx.isItemized,
            useItemCategories: !!(tx.items && tx.items.some((i: any) => !!i.categoryId)),
            items: tx.items && tx.items.length > 0 ? tx.items.map((i: any) => {
                const itemCatId = getId(i.categoryId);
                const itemCat = categories.find(c => c._id === itemCatId);
                let itemMainCat = '';
                let itemSubCat = '';
                if (itemCat) {
                    if (itemCat.parentCategoryId) {
                        itemMainCat = itemCat.parentCategoryId;
                        itemSubCat = itemCatId;
                    } else {
                        itemMainCat = itemCatId;
                        itemSubCat = '';
                    }
                }
                return {
                    name: i.name || '',
                    mainCategoryId: itemMainCat,
                    categoryId: itemSubCat,
                    quantity: i.quantity || 1,
                    unit: i.unit || 'unit',
                    unitPrice: i.unitPrice || 0,
                    totalPrice: i.totalPrice || ((i.quantity || 1) * (i.unitPrice || 0))
                };
            }) : [],
            note: tx.note || '',
            date: tx.date ? new Date(tx.date).toISOString().split('T')[0] : new Date().toISOString().split('T')[0],
        });
        setModalOpen(true);
    };

    const addItemRow = () => {
        setForm(prev => ({
            ...prev,
            isItemized: true,
            items: [...prev.items, { name: '', quantity: 1, unit: 'kg', unitPrice: 0, totalPrice: 0 }]
        }));
    };

    const updateItemRow = (index: number, field: string, value: any) => {
        setForm(prev => {
            const updatedItems = [...prev.items];
            const item = { ...updatedItems[index], [field]: value };
            if (field === 'quantity' || field === 'unitPrice') {
                const q = field === 'quantity' ? parseFloat(value) || 0 : item.quantity;
                const p = field === 'unitPrice' ? parseFloat(value) || 0 : item.unitPrice;
                item.totalPrice = Math.round(q * p * 100) / 100;
            }
            updatedItems[index] = item;
            
            // Recalculate total amount if itemized
            const totalSum = updatedItems.reduce((sum, i) => sum + (i.totalPrice || 0), 0);
            return {
                ...prev,
                items: updatedItems,
                amount: totalSum > 0 ? String(totalSum) : prev.amount
            };
        });
    };

    const handleItemNameLookup = async (index: number, name: string) => {
        if (!name || name.trim().length < 2) return;
        try {
            const res = await lookupMasterItem(name.trim());
            if (res.data) {
                setForm(prev => {
                    const updatedItems = [...prev.items];
                    const item = { ...updatedItems[index] };
                    if (res.data.defaultCategoryId?._id) {
                        const defCat = res.data.defaultCategoryId;
                        if (defCat.parentCategoryId) {
                            item.mainCategoryId = defCat.parentCategoryId;
                            item.categoryId = defCat._id;
                        } else {
                            item.mainCategoryId = defCat._id;
                            item.categoryId = '';
                        }
                    }
                    if (res.data.lastUnitPrice && (!item.unitPrice || item.unitPrice === 0)) {
                        item.unitPrice = res.data.lastUnitPrice;
                        item.totalPrice = Math.round((item.quantity || 1) * res.data.lastUnitPrice * 100) / 100;
                    }
                    if (res.data.defaultUnit) {
                        item.unit = res.data.defaultUnit;
                    }
                    updatedItems[index] = item;
                    const totalSum = updatedItems.reduce((sum, i) => sum + (i.totalPrice || 0), 0);
                    return {
                        ...prev,
                        items: updatedItems,
                        amount: totalSum > 0 ? String(totalSum) : prev.amount
                    };
                });
            }
        } catch (e) {}
    };

    const removeItemRow = (index: number) => {
        setForm(prev => {
            const updatedItems = prev.items.filter((_, i) => i !== index);
            const totalSum = updatedItems.reduce((sum, i) => sum + (i.totalPrice || 0), 0);
            return {
                ...prev,
                items: updatedItems,
                amount: totalSum > 0 ? String(totalSum) : prev.amount
            };
        });
    };

    const toggleReceipt = (id: string) => {
        setExpandedReceipts(prev => ({ ...prev, [id]: !prev[id] }));
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

            if (form.type === 'expense' && form.merchantName.trim()) {
                data.merchantName = form.merchantName.trim();
            }

            if (form.type === 'expense' && form.isItemized && form.items.length > 0) {
                data.isItemized = true;
                data.items = form.items.filter(i => i.name.trim()).map(i => ({
                    name: i.name.trim(),
                    categoryId: i.categoryId || i.mainCategoryId || null,
                    quantity: Number(i.quantity) || 1,
                    unit: i.unit || 'unit',
                    unitPrice: Number(i.unitPrice) || 0,
                    totalPrice: Number(i.totalPrice) || ((Number(i.quantity) || 1) * (Number(i.unitPrice) || 0))
                }));
                const sum = data.items.reduce((acc: number, item: any) => acc + item.totalPrice, 0);
                if (sum > 0) data.amount = sum;

                const firstCat = data.items.find((i: any) => i.categoryId)?.categoryId;
                if (firstCat) data.categoryId = firstCat;
            } else {
                data.isItemized = false;
                data.items = [];
            }

            if (form.type !== 'transfer' && form.type !== 'credit_repay' && !data.categoryId) {
                const finalCategoryId = form.categoryId || form.mainCategoryId;
                if (finalCategoryId) data.categoryId = finalCategoryId;
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
        setMainCategoryFilter('');
        setSubCategoryFilter('');
        setCreditFilter('');
        setStartDate('');
        setEndDate('');
        setPage(1);
    };

    const hasActiveFilters = typeFilter !== 'all' || accountFilter || mainCategoryFilter || subCategoryFilter || creditFilter || startDate || endDate;

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

    const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = (event) => {
            const text = event.target?.result as string;
            setCsvFileText(text);
        };
        reader.readAsText(file);
    };

    const handleRunImport = async () => {
        if (!csvFileText || !csvFileText.trim()) {
            alert('Please select a valid CSV backup file.');
            return;
        }
        setImporting(true);
        try {
            const res = await importTransactionsCSV({ csvText: csvFileText, mode: importMode });
            alert(res.message);
            setImportModalOpen(false);
            setCsvFileText('');
            loadData();
        } catch (err: any) {
            alert(err.message || 'Import failed');
        } finally {
            setImporting(false);
        }
    };

    if (loading && !isMobile && page === 1) {
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
                <div className="flex flex-wrap gap-2 self-start sm:self-auto">
                    <button onClick={exportTransactionsCSV} className="btn-ghost flex items-center gap-1.5 text-xs">
                        <Download size={14} /> Export CSV
                    </button>
                    <button onClick={() => setImportModalOpen(true)} className="px-3 py-2 rounded-xl text-xs font-semibold bg-violet-600/20 hover:bg-violet-600/30 text-violet-300 border border-violet-500/30 flex items-center gap-1.5 transition-all">
                        <Upload size={14} /> Import & Restore CSV
                    </button>
                    <button
                        onClick={() => setFilterOpen(!filterOpen)}
                        className={`btn-ghost flex items-center gap-2 text-xs ${hasActiveFilters ? 'border-violet-500 text-violet-400' : ''}`}
                    >
                        <Filter size={14} /> Filters {hasActiveFilters && '•'}
                    </button>
                    <button onClick={() => { setEditingTransaction(null); setForm(emptyForm); setModalOpen(true); }} className="btn-primary flex items-center gap-2 text-xs">
                        <Plus size={16} /> Add
                    </button>
                </div>
            </div>

            {/* Type Tabs */}
            <div className="flex gap-1 mb-4 bg-surface rounded-xl p-1 overflow-x-auto">
                {TYPE_TABS.map((tab) => (
                    <button
                        key={tab}
                        onClick={() => {
                            const newType = tab;
                            setTypeFilter(newType);
                            setPage(1);

                            if (mainCategoryFilter && (newType === 'income' || newType === 'expense')) {
                                const currentMain = categories.find(c => c._id === mainCategoryFilter);
                                if (currentMain && currentMain.type !== newType) {
                                    setMainCategoryFilter('');
                                    setSubCategoryFilter('');
                                }
                            }
                        }}
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
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                        <div>
                            <label className="block text-xs text-muted mb-1">Account</label>
                            <Select
                                options={[
                                    { label: 'All Accounts', value: '' },
                                    ...accounts.map((a) => ({ label: a.name, value: a._id })),
                                ]}
                                value={accountFilter}
                                onChange={(val) => { setAccountFilter(val); setPage(1); }}
                            />
                        </div>
                        <div>
                            <label className="block text-xs text-muted mb-1">Main Category</label>
                            <Select
                                options={[
                                    { label: 'All Main Categories', value: '' },
                                    ...categories
                                        .filter(c => !c.parentCategoryId && (typeFilter === 'all' || typeFilter === 'transfer' || typeFilter === 'credit_repay' || c.type === typeFilter))
                                        .map((c) => ({ label: c.name, value: c._id })),
                                ]}
                                value={mainCategoryFilter}
                                onChange={(val) => {
                                    setMainCategoryFilter(val);
                                    setSubCategoryFilter('');
                                    setPage(1);
                                }}
                            />
                        </div>
                        <div>
                            <label className="block text-xs text-muted mb-1">Sub Category</label>
                            <Select
                                options={[
                                    { label: mainCategoryFilter ? 'All Sub Categories' : 'Select Main Category first', value: '' },
                                    ...categories
                                        .filter(c => c.parentCategoryId === mainCategoryFilter)
                                        .map((c) => ({ label: c.name, value: c._id })),
                                ]}
                                value={subCategoryFilter}
                                onChange={(val) => { setSubCategoryFilter(val); setPage(1); }}
                                disabled={!mainCategoryFilter}
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
                                onChange={(val) => { setCreditFilter(val); setPage(1); }}
                            />
                        </div>
                        <div>
                            <label className="block text-xs text-muted mb-1">From Date</label>
                            <input type="date" className="input-dark" value={startDate} onChange={(e) => { setStartDate(e.target.value); setPage(1); }} />
                        </div>
                        <div>
                            <label className="block text-xs text-muted mb-1">To Date</label>
                            <input type="date" className="input-dark" value={endDate} onChange={(e) => { setEndDate(e.target.value); setPage(1); }} />
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
                                    <React.Fragment key={tx._id}>
                                        <tr className="border-b border-border/50 hover:bg-white/[0.02] transition-colors">
                                            <td className="px-4 py-3 text-slate-300 whitespace-nowrap">{formatDate(tx.date)}</td>
                                            <td className="px-4 py-3">
                                                <Badge label={tx.type} className={TRANSACTION_TYPE_COLORS[tx.type]} />
                                            </td>
                                            <td className="px-4 py-3 text-white">
                                                {getAccountName(tx.accountId)}
                                                {tx.type === 'transfer' && tx.toAccountId && (
                                                    <span className="text-muted"> → {getAccountName(tx.toAccountId)}</span>
                                                )}
                                                {tx.merchantName && (
                                                    <div className="text-xs text-amber-400 font-medium flex items-center gap-1 mt-0.5">
                                                        <span>🏪 {tx.merchantName}</span>
                                                    </div>
                                                )}
                                            </td>
                                            <td className="px-4 py-3 text-slate-300">
                                                {tx.type === 'credit_repay' ? getCreditLabel(tx.creditId) : tx.categoryId ? getCategoryName(tx.categoryId) : '—'}
                                                {tx.isItemized && tx.items?.length > 0 && (
                                                    <button 
                                                        onClick={() => toggleReceipt(tx._id)}
                                                        className="mt-1 text-xs text-violet-400 hover:text-violet-300 underline block"
                                                    >
                                                        {expandedReceipts[tx._id] ? 'Hide Receipt Items ▲' : `🛒 ${tx.items.length} Items (Receipt) ▼`}
                                                    </button>
                                                )}
                                            </td>
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
                                        {/* Expanded Itemized Receipt Sub-row */}
                                        {tx.isItemized && expandedReceipts[tx._id] && tx.items?.length > 0 && (
                                            <tr className="bg-white/[0.01] border-b border-border/40">
                                                <td colSpan={7} className="px-6 py-3">
                                                    <div className="bg-surface/90 border border-violet-500/30 rounded-xl p-3 max-w-xl">
                                                        <p className="text-xs font-semibold text-violet-400 mb-2">
                                                            🧾 {tx.merchantName ? `${tx.merchantName} Receipt Items` : 'Itemized Receipt Breakdown'}
                                                        </p>
                                                        <div className="grid grid-cols-12 gap-2 text-xs text-slate-400 border-b border-border/50 pb-1 mb-1 font-semibold">
                                                            <div className="col-span-5">Item</div>
                                                            <div className="col-span-3 text-center">Qty & Unit</div>
                                                            <div className="col-span-2 text-right">Unit ₹</div>
                                                            <div className="col-span-2 text-right">Total ₹</div>
                                                        </div>
                                                        {tx.items.map((item: any, idx: number) => (
                                                            <div key={idx} className="grid grid-cols-12 gap-2 text-xs py-1 border-b border-white/5 text-slate-200">
                                                                <div className="col-span-5 font-medium text-white">{item.name}</div>
                                                                <div className="col-span-3 text-center text-slate-400">{item.quantity} {item.unit}</div>
                                                                <div className="col-span-2 text-right text-slate-400">{formatCurrency(item.unitPrice)}</div>
                                                                <div className="col-span-2 text-right font-semibold text-emerald-400">{formatCurrency(item.totalPrice)}</div>
                                                            </div>
                                                        ))}
                                                    </div>
                                                </td>
                                            </tr>
                                        )}
                                    </React.Fragment>
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
                                        {tx.merchantName && (
                                            <p className="text-xs text-amber-400 font-medium mt-0.5">🏪 {tx.merchantName}</p>
                                        )}
                                        {tx.type === 'credit_repay' && tx.creditId && <p className="text-xs text-cyan-400 mt-0.5">{getCreditLabel(tx.creditId)}</p>}
                                        {tx.type !== 'credit_repay' && tx.categoryId && <p className="text-xs text-slate-400 mt-0.5">{getCategoryName(tx.categoryId)}</p>}
                                        {tx.note && <p className="text-xs text-slate-500 mt-1">{tx.note}</p>}
                                        {tx.isItemized && tx.items?.length > 0 && (
                                            <button 
                                                onClick={() => toggleReceipt(tx._id)}
                                                className="mt-1 text-xs text-violet-400 underline block"
                                            >
                                                {expandedReceipts[tx._id] ? 'Hide Receipt ▲' : `🛒 ${tx.items.length} Items ▼`}
                                            </button>
                                        )}
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
                                {tx.isItemized && expandedReceipts[tx._id] && tx.items?.length > 0 && (
                                    <div className="mt-3 pt-2 border-t border-border/50 bg-black/20 p-2 rounded-lg">
                                        <p className="text-[11px] font-semibold text-violet-400 mb-1">Receipt Items:</p>
                                        {tx.items.map((item: any, idx: number) => (
                                            <div key={idx} className="flex justify-between text-xs py-0.5 text-slate-300">
                                                <span>{item.name} ({item.quantity} {item.unit})</span>
                                                <span className="font-semibold text-emerald-400">{formatCurrency(item.totalPrice)}</span>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </motion.div>
                        ))}

                        {/* Infinite Scroll Target */}
                        {isMobile && page < totalPages && (
                            <div ref={observerTarget} className="py-4 flex justify-center">
                                {loadingMore ? (
                                    <div className="w-6 h-6 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
                                ) : (
                                    <span className="text-sm text-muted">Scroll for more...</span>
                                )}
                            </div>
                        )}
                    </div>

                    {/* Pagination Controls (Desktop Only) */}
                    {!isMobile && totalItems > 0 && (
                        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mt-6 print:hidden">
                            <div className="flex items-center gap-2 text-sm text-slate-400">
                                <span>Showing</span>
                                <Select
                                    options={[
                                        { label: '20', value: '20' },
                                        { label: '50', value: '50' },
                                        { label: '100', value: '100' },
                                        { label: '200', value: '200' },
                                    ]}
                                    value={String(limit)}
                                    onChange={(val) => { setLimit(Number(val)); setPage(1); }}
                                    position="top"
                                />
                                <span>per page ({totalItems} total)</span>
                            </div>

                            <div className="flex items-center gap-2">
                                <button
                                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                                    disabled={page === 1}
                                    className="px-3 py-1.5 rounded-lg text-sm text-slate-300 hover:text-white hover:bg-white/10 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                >
                                    Previous
                                </button>
                                <span className="text-sm font-medium text-slate-300">
                                    Page {page} of {totalPages}
                                </span>
                                <button
                                    onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                                    disabled={page >= totalPages}
                                    className="px-3 py-1.5 rounded-lg text-sm text-slate-300 hover:text-white hover:bg-white/10 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                >
                                    Next
                                </button>
                            </div>
                        </div>
                    )}
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
                                    onClick={() => setForm({ ...form, type: t, creditId: '', mainCategoryId: '', categoryId: '', toAccountId: '' })}
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

                    {form.type !== 'transfer' && form.type !== 'credit_repay' && !form.isItemized && (
                        <div className="grid grid-cols-2 gap-3">
                            <div>
                                <label className="block text-xs font-medium text-muted mb-1.5">Category</label>
                                <Select
                                    options={categories.filter(c => !c.parentCategoryId && c.type === form.type).map((c) => ({
                                        label: c.name,
                                        value: c._id
                                    }))}
                                    value={form.mainCategoryId}
                                    onChange={(val) => setForm({ ...form, mainCategoryId: val, categoryId: '' })}
                                    placeholder="Select main"
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-medium text-muted mb-1.5">Sub Category</label>
                                <Select
                                    options={categories.filter(c => c.parentCategoryId === form.mainCategoryId).map((c) => ({
                                        label: c.name,
                                        value: c._id
                                    }))}
                                    value={form.categoryId}
                                    onChange={(val) => setForm({ ...form, categoryId: val })}
                                    placeholder="Optional"
                                    disabled={!form.mainCategoryId}
                                />
                            </div>
                        </div>
                    )}

                    {form.type === 'expense' && (
                        <div className="border border-border/60 rounded-xl p-3 bg-white/[0.02]">
                            <div className="flex items-center justify-between mb-2">
                                <label className="block text-xs font-semibold text-violet-400">Store / Merchant (Optional)</label>
                                <label className="flex items-center gap-2 cursor-pointer text-xs text-slate-300">
                                    <input 
                                        type="checkbox" 
                                        checked={form.isItemized} 
                                        onChange={(e) => {
                                            const checked = e.target.checked;
                                            setForm(prev => ({
                                                ...prev,
                                                isItemized: checked,
                                                items: checked && prev.items.length === 0 ? [{ name: '', quantity: 1, unit: 'kg', unitPrice: 0, totalPrice: 0 }] : prev.items
                                            }));
                                        }}
                                        className="rounded border-slate-700 text-violet-600 focus:ring-violet-500"
                                    />
                                    <span>Itemize Receipt Products</span>
                                </label>
                            </div>
                            <input 
                                className="input-dark mb-2" 
                                placeholder="Store name (e.g. D-Mart, Reliance)" 
                                value={form.merchantName} 
                                onChange={(e) => setForm({ ...form, merchantName: e.target.value })} 
                            />

                            {form.isItemized && (
                                <div className="mt-3 pt-3 border-t border-border/40 space-y-3">
                                    <div className="flex items-center justify-between">
                                        <span className="text-xs font-semibold text-slate-300">Purchased Receipt Items</span>
                                        <button 
                                            type="button" 
                                            onClick={addItemRow}
                                            className="text-xs text-violet-400 hover:text-violet-300 font-medium"
                                        >
                                            + Add Product
                                        </button>
                                    </div>

                                    <div className="flex flex-col gap-3 max-h-64 overflow-y-auto pr-1">
                                        {form.items.map((item, idx) => (
                                            <div key={idx} className="bg-white/[0.03] p-3 rounded-xl border border-white/10 space-y-2.5">
                                                {/* Line 1: Item Name & Delete Button */}
                                                <div className="flex items-center justify-between gap-2">
                                                    <input 
                                                        className="input-dark text-xs flex-1 py-1.5 px-2.5 font-semibold text-white" 
                                                        placeholder="Item name (e.g. Basmati Rice, Dove Soap)" 
                                                        value={item.name}
                                                        onChange={(e) => updateItemRow(idx, 'name', e.target.value)}
                                                        onBlur={() => handleItemNameLookup(idx, item.name)}
                                                    />
                                                    <button 
                                                        type="button" 
                                                        onClick={() => removeItemRow(idx)}
                                                        className="text-rose-400 hover:text-rose-300 text-xs px-2 py-1 font-bold rounded-lg hover:bg-rose-500/10"
                                                    >
                                                        ✕ Remove
                                                    </button>
                                                </div>

                                                {/* Line 2: Cascading Parent & Sub Category Selector */}
                                                <div className="grid grid-cols-2 gap-2 bg-surface/40 p-2 rounded-lg border border-white/5">
                                                    <div>
                                                        <label className="block text-[10px] font-medium text-slate-400 mb-1">Main Category</label>
                                                        <select
                                                            className="input-dark text-xs py-1 px-2 w-full"
                                                            value={item.mainCategoryId || ''}
                                                            onChange={(e) => {
                                                                updateItemRow(idx, 'mainCategoryId', e.target.value);
                                                                updateItemRow(idx, 'categoryId', '');
                                                            }}
                                                        >
                                                            <option value="">Select Main Category</option>
                                                            {categories.filter(c => !c.parentCategoryId && c.type === form.type).map(c => (
                                                                <option key={c._id} value={c._id}>{c.name}</option>
                                                            ))}
                                                        </select>
                                                    </div>
                                                    <div>
                                                        <label className="block text-[10px] font-medium text-slate-400 mb-1">Sub Category</label>
                                                        <select
                                                            className="input-dark text-xs py-1 px-2 w-full disabled:opacity-40"
                                                            value={item.categoryId || ''}
                                                            onChange={(e) => updateItemRow(idx, 'categoryId', e.target.value)}
                                                            disabled={!item.mainCategoryId}
                                                        >
                                                            <option value="">Optional Sub Category</option>
                                                            {categories.filter(c => c.parentCategoryId === item.mainCategoryId).map(c => (
                                                                <option key={c._id} value={c._id}>{c.name}</option>
                                                            ))}
                                                        </select>
                                                    </div>
                                                </div>

                                                {/* Line 3: Qty, Unit, Unit Price, Subtotal */}
                                                <div className="grid grid-cols-12 gap-2 items-center text-xs pt-1">
                                                    <div className="col-span-3 flex items-center gap-1">
                                                        <span className="text-slate-400 text-[10px]">Qty:</span>
                                                        <input 
                                                            className="input-dark text-xs py-1 px-1 text-center w-full" 
                                                            type="number" step="0.01" min="0.01" 
                                                            value={item.quantity}
                                                            onChange={(e) => updateItemRow(idx, 'quantity', e.target.value)}
                                                        />
                                                    </div>
                                                    <div className="col-span-3 flex items-center gap-1">
                                                        <span className="text-slate-400 text-[10px]">Unit:</span>
                                                        <select 
                                                            className="input-dark text-xs py-1 px-0.5 text-center w-full"
                                                            value={item.unit}
                                                            onChange={(e) => updateItemRow(idx, 'unit', e.target.value)}
                                                        >
                                                            <option value="kg">kg</option>
                                                            <option value="L">L</option>
                                                            <option value="pc">pc</option>
                                                            <option value="g">g</option>
                                                            <option value="ml">ml</option>
                                                            <option value="unit">unit</option>
                                                        </select>
                                                    </div>
                                                    <div className="col-span-3 flex items-center gap-1">
                                                        <span className="text-slate-400 text-[10px]">Unit ₹:</span>
                                                        <input 
                                                            className="input-dark text-xs py-1 px-1.5 text-right w-full font-mono" 
                                                            type="number" step="0.01" min="0" 
                                                            placeholder="0.00" 
                                                            value={item.unitPrice || ''}
                                                            onChange={(e) => updateItemRow(idx, 'unitPrice', e.target.value)}
                                                        />
                                                    </div>
                                                    <div className="col-span-3 text-right font-semibold text-emerald-400 text-xs">
                                                        ₹{item.totalPrice ? item.totalPrice.toFixed(2) : '0.00'}
                                                    </div>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                    {form.items.length > 0 && (
                                        <div className="mt-2 text-right text-xs text-slate-400 font-medium">
                                            Receipt Subtotal: <span className="text-white font-bold">{formatCurrency(form.items.reduce((s, i) => s + (i.totalPrice || 0), 0))}</span>
                                        </div>
                                    )}
                                </div>
                            )}
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

            {/* Import CSV & Data Restore Modal */}
            <Modal isOpen={importModalOpen} onClose={() => setImportModalOpen(false)} title="Import & Restore CSV Backup">
                <div className="space-y-4">
                    <div className="p-3 bg-violet-500/10 border border-violet-500/20 rounded-xl text-xs text-violet-300">
                        <p className="font-bold flex items-center gap-1.5 mb-1 text-violet-200">
                            <Upload className="w-4 h-4 text-violet-400" /> Restore Transactions & Account Balances
                        </p>
                        Upload your exported CSV file backup. The system will parse your transactions, match categories and accounts, and recalculate your exact account balances.
                    </div>

                    <div>
                        <label className="block text-xs font-semibold text-slate-300 mb-1.5">Select CSV Backup File</label>
                        <input 
                            type="file" 
                            accept=".csv"
                            onChange={handleFileUpload}
                            className="block w-full text-xs text-slate-300 file:mr-3 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-violet-600 file:text-white hover:file:bg-violet-500 cursor-pointer bg-white/5 p-2 rounded-xl border border-white/10"
                        />
                    </div>

                    {csvFileText && (
                        <div className="text-xs text-emerald-400 font-medium flex items-center gap-1.5">
                            ✓ CSV Loaded ({csvFileText.split('\n').length - 1} rows detected)
                        </div>
                    )}

                    <div className="space-y-2 pt-2 border-t border-white/10">
                        <label className="block text-xs font-semibold text-slate-300">Restore Mode</label>
                        <div className="space-y-2 text-xs">
                            <label className="flex items-start gap-2.5 p-2.5 rounded-xl bg-white/[0.03] border border-white/10 cursor-pointer">
                                <input 
                                    type="radio" 
                                    name="importMode" 
                                    value="replace" 
                                    checked={importMode === 'replace'} 
                                    onChange={() => setImportMode('replace')}
                                    className="mt-0.5 text-violet-600 focus:ring-violet-500"
                                />
                                <div>
                                    <span className="font-semibold text-white">Clean Restore from Backup (Recommended)</span>
                                    <p className="text-slate-400 text-[11px] mt-0.5">Cleans out corrupted/duplicate transactions and re-creates clean history & exact account balances from CSV.</p>
                                </div>
                            </label>
                            <label className="flex items-start gap-2.5 p-2.5 rounded-xl bg-white/[0.03] border border-white/10 cursor-pointer">
                                <input 
                                    type="radio" 
                                    name="importMode" 
                                    value="append" 
                                    checked={importMode === 'append'} 
                                    onChange={() => setImportMode('append')}
                                    className="mt-0.5 text-violet-600 focus:ring-violet-500"
                                />
                                <div>
                                    <span className="font-semibold text-white">Append to Existing Transactions</span>
                                    <p className="text-slate-400 text-[11px] mt-0.5">Imports CSV rows into your current database without deleting existing records.</p>
                                </div>
                            </label>
                        </div>
                    </div>

                    <div className="flex gap-3 mt-4">
                        <button
                            type="button"
                            onClick={handleRunImport}
                            disabled={importing || !csvFileText}
                            className="btn-primary flex-1 disabled:opacity-50 flex items-center justify-center gap-2"
                        >
                            {importing ? (
                                <>
                                    <RefreshCw className="w-4 h-4 animate-spin" /> Restoring Transactions...
                                </>
                            ) : (
                                'Restore Transactions'
                            )}
                        </button>
                        <button
                            type="button"
                            onClick={() => setImportModalOpen(false)}
                            disabled={importing}
                            className="btn-ghost flex-1"
                        >
                            Cancel
                        </button>
                    </div>
                </div>
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
