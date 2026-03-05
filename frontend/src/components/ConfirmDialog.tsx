'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { AlertTriangle } from 'lucide-react';

interface ConfirmDialogProps {
    isOpen: boolean;
    title?: string;
    message: string;
    confirmLabel?: string;
    cancelLabel?: string;
    variant?: 'danger' | 'warning';
    onConfirm: () => void;
    onCancel: () => void;
}

export default function ConfirmDialog({
    isOpen,
    title = 'Are you sure?',
    message,
    confirmLabel = 'Delete',
    cancelLabel = 'Cancel',
    variant = 'danger',
    onConfirm,
    onCancel,
}: ConfirmDialogProps) {
    const colors = variant === 'danger'
        ? { btn: 'bg-rose-600 hover:bg-rose-700', icon: 'text-rose-400', ring: 'ring-rose-500/30', glow: 'bg-rose-500/10' }
        : { btn: 'bg-amber-600 hover:bg-amber-700', icon: 'text-amber-400', ring: 'ring-amber-500/30', glow: 'bg-amber-500/10' };

    return (
        <AnimatePresence>
            {isOpen && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    className="fixed inset-0 z-[200] flex items-center justify-center p-4"
                    onClick={onCancel}
                >
                    {/* Backdrop */}
                    <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />

                    {/* Dialog */}
                    <motion.div
                        initial={{ opacity: 0, scale: 0.9, y: 20 }}
                        animate={{ opacity: 1, scale: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.9, y: 20 }}
                        transition={{ type: 'spring', damping: 25, stiffness: 300 }}
                        className="relative glass-card p-6 max-w-sm w-full text-center"
                        onClick={(e) => e.stopPropagation()}
                    >
                        {/* Icon */}
                        <div className={`w-14 h-14 rounded-full ${colors.glow} flex items-center justify-center mx-auto mb-4 ring-2 ${colors.ring}`}>
                            <AlertTriangle size={28} className={colors.icon} />
                        </div>

                        <h3 className="text-lg font-semibold text-white mb-2">{title}</h3>
                        <p className="text-sm text-slate-400 mb-6 leading-relaxed">{message}</p>

                        <div className="flex gap-3">
                            <button
                                onClick={onCancel}
                                className="btn-ghost flex-1"
                            >
                                {cancelLabel}
                            </button>
                            <button
                                onClick={onConfirm}
                                className={`flex-1 px-4 py-2.5 rounded-xl text-sm font-medium text-white transition-all ${colors.btn}`}
                            >
                                {confirmLabel}
                            </button>
                        </div>
                    </motion.div>
                </motion.div>
            )}
        </AnimatePresence>
    );
}
