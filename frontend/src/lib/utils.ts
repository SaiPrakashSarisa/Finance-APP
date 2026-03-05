export function formatCurrency(amount: number, currency = 'INR'): string {
    return new Intl.NumberFormat('en-IN', {
        style: 'currency',
        currency,
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
    }).format(amount);
}

export function formatDate(dateStr: string): string {
    return new Date(dateStr).toLocaleDateString('en-IN', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
    });
}

export function cn(...classes: (string | false | undefined | null)[]): string {
    return classes.filter(Boolean).join(' ');
}

export const ACCOUNT_TYPE_LABELS: Record<string, string> = {
    bank: 'Bank',
    cash: 'Cash',
    credit_card: 'Credit Card',
    wallet: 'Wallet',
    investment: 'Investment',
};

export const ACCOUNT_TYPE_COLORS: Record<string, string> = {
    bank: 'bg-blue-500/20 text-blue-400',
    cash: 'bg-emerald-500/20 text-emerald-400',
    credit_card: 'bg-rose-500/20 text-rose-400',
    wallet: 'bg-amber-500/20 text-amber-400',
    investment: 'bg-violet-500/20 text-violet-400',
};

export const TRANSACTION_TYPE_COLORS: Record<string, string> = {
    income: 'bg-emerald-500/20 text-emerald-400',
    expense: 'bg-rose-500/20 text-rose-400',
    transfer: 'bg-violet-500/20 text-violet-400',
    credit_repay: 'bg-cyan-500/20 text-cyan-400',
};

export const CREDIT_STATUS_COLORS: Record<string, string> = {
    active: 'bg-amber-500/20 text-amber-400',
    partial: 'bg-blue-500/20 text-blue-400',
    settled: 'bg-emerald-500/20 text-emerald-400',
};

export const CATEGORY_TYPE_LABELS: Record<string, string> = {
    income: 'Income',
    expense: 'Expense',
};

