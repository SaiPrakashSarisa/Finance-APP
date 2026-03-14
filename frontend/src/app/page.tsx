'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import {
  PieChart, Pie, Cell, ResponsiveContainer, BarChart, Bar, XAxis, YAxis,
  Tooltip, CartesianGrid, Legend,
} from 'recharts';
import {
  TrendingUp, TrendingDown, PiggyBank, ArrowUpRight,
  ArrowDownLeft, Landmark,
} from 'lucide-react';
import SummaryCard from '@/components/SummaryCard';
import { getDashboard, getCategoryBreakdown, getMonthlyTrend, getUserSettings } from '@/lib/api';
import { formatCurrency } from '@/lib/utils';

const PIE_COLORS = ['#f43f5e', '#8b5cf6', '#f59e0b', '#10b981', '#3b82f6', '#ec4899', '#14b8a6', '#f97316'];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export default function DashboardPage() {
  const [dashboard, setDashboard] = useState<any>(null);
  const [categories, setCategories] = useState<any[]>([]);
  const [trend, setTrend] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [range, setRange] = useState('1m');

  useEffect(() => {
    async function load() {
      try {
        const [settingsRes, d, c, t] = await Promise.all([
          getUserSettings(),
          getDashboard(),
          getCategoryBreakdown(),
          getMonthlyTrend(),
        ]);
        setRange(settingsRes.data.dashboardRange || '1m');
        setDashboard(d.data);
        setCategories(c.data);

        // Transform trend data for Recharts
        const trendMap: Record<string, any> = {};
        t.data.forEach((item: any) => {
          const key = `${item._id.year}-${item._id.month}`;
          if (!trendMap[key]) {
            trendMap[key] = {
              month: MONTHS[item._id.month - 1],
              income: 0,
              expense: 0,
            };
          }
          trendMap[key][item._id.type] = item.total;
        });
        setTrend(Object.values(trendMap));
      } catch (err) {
        console.error('Dashboard load error:', err);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!dashboard) {
    return (
      <div className="text-center py-20 text-muted">
        <p>Unable to load dashboard data. Make sure the backend is running and seeded.</p>
      </div>
    );
  }

  const rangeLabels: Record<string, string> = {
    '1m': 'This Month',
    '3m': 'Last 3 Months',
    '6m': 'Last 6 Months',
    '1y': 'Last 1 Year',
    'all': 'All Time'
  };

  const accountDonut = dashboard.accounts?.map((a: any, i: number) => ({
    name: a.name,
    value: Math.abs(a.balance),
    color: PIE_COLORS[i % PIE_COLORS.length],
  })) || [];

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="glass-card p-3 text-sm">
          <p className="text-white font-medium">{payload[0].name || payload[0].payload.month}</p>
          {payload.map((p: any, i: number) => (
            <p key={i} style={{ color: p.color || p.fill }}>
              {p.name || p.dataKey}: {formatCurrency(p.value)}
            </p>
          ))}
        </div>
      );
    }
    return null;
  };

  return (
    <div>
      <div className="mb-6">
        <motion.h1
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-xl md:text-2xl lg:text-3xl font-bold text-white mb-1"
        >
          Dashboard
        </motion.h1>
        <p className="text-xs sm:text-sm text-muted flex items-center gap-2">
          Showing data for <span className="text-violet-400 font-medium">{rangeLabels[range]}</span>
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-3 md:gap-6 mb-8 md:mb-10">
        <SummaryCard label="Total Income" value={formatCurrency(dashboard.income)} icon={TrendingUp} color="emerald" delay={0} />
        <SummaryCard label="Total Expenses" value={formatCurrency(dashboard.expense)} icon={TrendingDown} color="rose" delay={0.05} />
        <SummaryCard label="Net Savings" value={formatCurrency(dashboard.netSavings)} icon={PiggyBank} color="violet" delay={0.1} />
        <SummaryCard label="Receivables" value={formatCurrency(dashboard.totalReceivables)} icon={ArrowUpRight} color="amber" delay={0.15} />
        <SummaryCard label="Liabilities" value={formatCurrency(dashboard.totalLiabilities)} icon={ArrowDownLeft} color="rose" delay={0.2} />
        <SummaryCard label="Net Worth" value={formatCurrency(dashboard.netWorth)} icon={Landmark} color="blue" delay={0.25} />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 md:gap-8">
        {/* Expense Category Pie */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="glass-card p-4 md:p-6"
        >
          <h3 className="text-sm md:text-base font-semibold text-white mb-3 md:mb-4">Expense Breakdown</h3>
          {categories.length === 0 ? (
            <p className="text-muted text-sm text-center py-10">No expense data for this month</p>
          ) : (
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={categories.map((c, i) => ({ name: c.name, value: c.total, color: PIE_COLORS[i % PIE_COLORS.length] }))}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={3}
                  dataKey="value"
                >
                  {categories.map((_, i) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip content={<CustomTooltip />} />
                <Legend
                  formatter={(value: string) => <span className="text-xs text-slate-300">{value}</span>}
                />
              </PieChart>
          </ResponsiveContainer>
          )}
        </motion.div>

        {/* Monthly Trend Bar */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.35 }}
          className="glass-card p-4 md:p-6"
        >
          <h3 className="text-sm md:text-base font-semibold text-white mb-3 md:mb-4">Income vs Expenses (Trends)</h3>
          {trend.length === 0 ? (
            <p className="text-muted text-sm text-center py-10">No trend data available</p>
          ) : (
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={trend} barGap={4}>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                <XAxis dataKey="month" tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} />
                <YAxis tick={{ fill: '#94a3b8', fontSize: 12 }} axisLine={false} tickFormatter={(v) => `₹${(v / 1000).toFixed(0)}k`} />
                <Tooltip content={<CustomTooltip />} />
                <Legend formatter={(value: string) => <span className="text-xs text-slate-300 capitalize">{value}</span>} />
                <Bar dataKey="income" fill="#10b981" radius={[4, 4, 0, 0]} />
                <Bar dataKey="expense" fill="#f43f5e" radius={[4, 4, 0, 0]} />
              </BarChart>
          </ResponsiveContainer>
          )}
        </motion.div>

        {/* Account Balance Donut */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="glass-card p-4 md:p-6 lg:col-span-2"
        >
          <h3 className="text-sm md:text-base font-semibold text-white mb-3 md:mb-4">Account Balances</h3>
          {accountDonut.length === 0 ? (
            <p className="text-muted text-sm text-center py-10">No accounts found</p>
          ) : (
            <div className="flex flex-col sm:flex-row items-center gap-6">
              <ResponsiveContainer width="100%" height={240} className="max-w-[300px]">
                <PieChart>
                  <Pie
                    data={accountDonut}
                    cx="50%"
                    cy="50%"
                    innerRadius={50}
                    outerRadius={90}
                    paddingAngle={3}
                    dataKey="value"
                  >
                    {accountDonut.map((entry: any, i: number) => (
                      <Cell key={i} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip content={<CustomTooltip />} />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex flex-wrap gap-3 justify-center sm:justify-start">
                {dashboard.accounts.map((acc: any, i: number) => (
                  <div key={i} className="flex items-center gap-2 bg-white/5 rounded-lg px-3 py-2">
                    <div className="w-3 h-3 rounded-full" style={{ background: PIE_COLORS[i % PIE_COLORS.length] }} />
                    <div>
                      <p className="text-xs text-slate-300">{acc.name}</p>
                      <p className="text-sm font-semibold text-white">{formatCurrency(acc.balance)}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </motion.div>
      </div>
    </div>
  );
}
