'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { UserPlus, Mail, Lock, User, AlertCircle, CheckCircle2 } from 'lucide-react';
import { register as apiRegister } from '@/lib/api';
import { useAuth } from '@/context/AuthContext';
import Link from 'next/link';

export default function RegisterPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      setLoading(false);
      return;
    }
    
    try {
      const res = await apiRegister({ name, email, password });
      login(res.user);
    } catch (err: any) {
      setError(err.message || 'Registration failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden bg-[#08090a]">
      {/* Dynamic Background Elements */}
      <div className="absolute top-[-10%] right-[-10%] w-[45%] h-[45%] bg-indigo-600/20 blur-[130px] rounded-full" />
      <div className="absolute bottom-[-10%] left-[-10%] w-[45%] h-[45%] bg-violet-600/15 blur-[130px] rounded-full" />
      
      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="w-full max-w-md p-8 glass-card relative z-10 mx-4 border border-white/10 my-8"
      >
        <div className="flex flex-col items-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-indigo-600 to-violet-600 flex items-center justify-center shadow-lg shadow-indigo-600/20 mb-4">
            <UserPlus size={32} className="text-white" />
          </div>
          <h1 className="text-3xl font-bold text-white tracking-tight text-center">Create Account</h1>
          <p className="text-slate-400 mt-2 text-center text-sm px-4">Join us to start your journey towards financial freedom</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <motion.div 
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              className="bg-rose-500/10 border border-rose-500/20 p-3 rounded-xl flex items-center gap-3 text-rose-400 text-sm"
            >
              <AlertCircle size={18} />
              <span>{error}</span>
            </motion.div>
          )}

          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">Full Name</label>
            <div className="relative group">
              <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none text-slate-500 group-focus-within:text-indigo-400 transition-colors">
                <User size={18} />
              </div>
              <input 
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500/50 transition-all placeholder:text-slate-600 text-sm"
                placeholder="John Doe"
              />
            </div>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">Email Address</label>
            <div className="relative group">
              <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none text-slate-500 group-focus-within:text-indigo-400 transition-colors">
                <Mail size={18} />
              </div>
              <input 
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500/50 transition-all placeholder:text-slate-600 text-sm"
                placeholder="you@example.com"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4">
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">Password</label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none text-slate-500 group-focus-within:text-violet-400 transition-colors">
                  <Lock size={18} />
                </div>
                <input 
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all placeholder:text-slate-600 text-sm"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">Confirm Password</label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none text-slate-500 group-focus-within:text-violet-400 transition-colors">
                  <Lock size={18} />
                </div>
                <input 
                  type="password"
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all placeholder:text-slate-600 text-sm"
                  placeholder="••••••••"
                />
              </div>
            </div>
          </div>

          <div className="flex items-start gap-2 ml-1 pb-2">
            <div className="mt-1 h-4 w-4 rounded border border-white/20 bg-white/5 flex items-center justify-center">
              <CheckCircle2 size={12} className="text-indigo-400" />
            </div>
            <p className="text-[11px] text-slate-500 leading-tight">
              I agree to the <span className="text-slate-300">Terms of Service</span> and <span className="text-slate-300">Privacy Policy</span>.
            </p>
          </div>

          <button 
            type="submit"
            disabled={loading}
            className="w-full py-3.5 px-4 bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-500 hover:to-violet-500 disabled:opacity-50 text-white font-semibold rounded-xl shadow-lg shadow-indigo-600/20 transition-all active:scale-[0.98] flex items-center justify-center gap-2"
          >
            {loading ? (
              <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <span>Create Account</span>
                <UserPlus size={18} />
              </>
            )}
          </button>
        </form>

        <p className="text-center text-slate-500 text-sm mt-8">
          Already have an account?{' '}
          <Link href="/login" className="text-indigo-400 font-medium hover:text-indigo-300 transition-colors underline-offset-4 hover:underline">
            Sign In
          </Link>
        </p>
      </motion.div>
    </div>
  );
}
