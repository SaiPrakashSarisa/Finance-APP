'use client';

import { motion } from 'framer-motion';
import { LucideIcon } from 'lucide-react';

interface SummaryCardProps {
    label: string;
    value: string;
    icon: LucideIcon;
    color: 'emerald' | 'rose' | 'violet' | 'amber' | 'blue';
    delay?: number;
}

const colorMap = {
    emerald: { gradient: 'gradient-emerald', text: 'text-emerald-400', iconBg: 'bg-emerald-500/20' },
    rose: { gradient: 'gradient-rose', text: 'text-rose-400', iconBg: 'bg-rose-500/20' },
    violet: { gradient: 'gradient-violet', text: 'text-violet-400', iconBg: 'bg-violet-500/20' },
    amber: { gradient: 'gradient-amber', text: 'text-amber-400', iconBg: 'bg-amber-500/20' },
    blue: { gradient: 'gradient-blue', text: 'text-blue-400', iconBg: 'bg-blue-500/20' },
};

export default function SummaryCard({ label, value, icon: Icon, color, delay = 0 }: SummaryCardProps) {
    const c = colorMap[color];
    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay }}
            className={`glass-card p-6 ${c.gradient}`}
        >
            <div className="flex items-center justify-between">
                <div>
                    <p className="text-xs font-medium text-muted uppercase tracking-wider mb-1">{label}</p>
                    <p className={`text-xl sm:text-2xl font-bold ${c.text}`}>{value}</p>
                </div>
                <div className={`w-11 h-11 rounded-xl ${c.iconBg} flex items-center justify-center`}>
                    <Icon size={22} className={c.text} />
                </div>
            </div>
        </motion.div>
    );
}
