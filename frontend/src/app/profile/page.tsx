'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { User, Mail, Phone, Shield, Camera, Lock, CheckCircle2, AlertCircle, Save } from 'lucide-react';
import { getUserProfile, updateUserProfile, changePassword } from '@/lib/api';
import { useAuth } from '@/context/AuthContext';
import { Select } from '@/components/Select';

const COUNTRY_CODES = [
    { label: '+1 (US/CA)', value: '+1' },
    { label: '+44 (UK)', value: '+44' },
    { label: '+91 (IN)', value: '+91' },
    { label: '+61 (AU)', value: '+61' },
    { label: '+49 (DE)', value: '+49' },
    { label: '+81 (JP)', value: '+81' },
    { label: '+971 (AE)', value: '+971' },
];

export default function ProfilePage() {
    const { user, updateUser } = useAuth();
    
    // Profile State
    const [name, setName] = useState('');
    const [phone, setPhone] = useState('');
    const [countryCode, setCountryCode] = useState('+1');
    const [profilePicture, setProfilePicture] = useState<string | null>(null);
    const [email, setEmail] = useState('');
    
    // Password State
    const [currentPassword, setCurrentPassword] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    
    // UI State
    const [loadingProfile, setLoadingProfile] = useState(true);
    const [savingProfile, setSavingProfile] = useState(false);
    const [savingPassword, setSavingPassword] = useState(false);
    
    const [profileSuccess, setProfileSuccess] = useState('');
    const [profileError, setProfileError] = useState('');
    const [passwordSuccess, setPasswordSuccess] = useState('');
    const [passwordError, setPasswordError] = useState('');

    const fileInputRef = useRef<HTMLInputElement>(null);

    // Initial Load
    useEffect(() => {
        const loadProfile = async () => {
            try {
                const res = await getUserProfile();
                const data = res.data;
                setName(data.name || '');
                setEmail(data.email || '');
                setPhone(data.phone || '');
                setCountryCode(data.countryCode || '+1');
                setProfilePicture(data.profilePicture || null);
            } catch (err) {
                setProfileError('Failed to load profile data.');
            } finally {
                setLoadingProfile(false);
            }
        };
        loadProfile();
    }, []);

    // Helper: Convert image to base64 and resize
    const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        // Check size (limit to 2MB)
        if (file.size > 2 * 1024 * 1024) {
            setProfileError('Image must be less than 2MB');
            return;
        }

        const reader = new FileReader();
        reader.onload = (event) => {
            const img = new Image();
            img.onload = () => {
                // Resize image logic. Max width/height = 500px to save DB space
                const canvas = document.createElement('canvas');
                let width = img.width;
                let height = img.height;
                const MAX_SIZE = 500;

                if (width > height) {
                    if (width > MAX_SIZE) {
                        height *= MAX_SIZE / width;
                        width = MAX_SIZE;
                    }
                } else {
                    if (height > MAX_SIZE) {
                        width *= MAX_SIZE / height;
                        height = MAX_SIZE;
                    }
                }

                canvas.width = width;
                canvas.height = height;
                const ctx = canvas.getContext('2d');
                ctx?.drawImage(img, 0, 0, width, height);
                // Convert to compressed jpeg base64
                const base64Str = canvas.toDataURL('image/jpeg', 0.8);
                setProfilePicture(base64Str);
                setProfileError(''); // Clear errors
            };
            img.src = event.target?.result as string;
        };
        reader.readAsDataURL(file);
    };

    const handleSaveProfile = async (e: React.FormEvent) => {
        e.preventDefault();
        setSavingProfile(true);
        setProfileError('');
        setProfileSuccess('');

        try {
            const res = await updateUserProfile({
                name,
                phone,
                countryCode,
                profilePicture
            });
            setProfileSuccess('Profile updated successfully!');
            
            // Update AuthContext user so sidebar updates instantly
            if (user) {
                 updateUser({ ...user, name: res.data.name, profilePicture: res.data.profilePicture, phone: res.data.phone, countryCode: res.data.countryCode });
            }
        } catch (err: any) {
            setProfileError(err.message || 'Failed to update profile');
        } finally {
            setSavingProfile(false);
            setTimeout(() => setProfileSuccess(''), 3000);
        }
    };

    const handleUpdatePassword = async (e: React.FormEvent) => {
        e.preventDefault();
        setSavingPassword(true);
        setPasswordError('');
        setPasswordSuccess('');

        if (newPassword !== confirmPassword) {
            setPasswordError('New passwords do not match');
            setSavingPassword(false);
            return;
        }

        if (newPassword.length < 6) {
            setPasswordError('New password must be at least 6 characters');
            setSavingPassword(false);
            return;
        }

        try {
            await changePassword({ currentPassword, newPassword });
            setPasswordSuccess('Password changed securely!');
            setCurrentPassword('');
            setNewPassword('');
            setConfirmPassword('');
        } catch (err: any) {
            setPasswordError(err.message || 'Failed to change password');
        } finally {
            setSavingPassword(false);
            setTimeout(() => setPasswordSuccess(''), 3000);
        }
    };

    if (loadingProfile) {
        return (
            <div className="flex items-center justify-center min-h-[60vh]">
                <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
            </div>
        );
    }

    return (
        <div className="max-w-4xl mx-auto pb-20">
            <header className="mb-6 md:mb-8">
                <motion.h1
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="text-xl md:text-2xl lg:text-3xl font-bold text-white flex items-center gap-2 md:gap-3"
                >
                    <User className="text-violet-400 w-6 h-6 md:w-8 md:h-8" /> Profile Settings
                </motion.h1>
                <p className="text-xs md:text-sm text-muted mt-1">Manage your personal information and application security.</p>
            </header>

            <div className="space-y-6 md:space-y-8">
                {/* Personal Information */}
                <motion.section 
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="glass-card p-4 md:p-6 border border-white/10 relative overflow-hidden"
                >
                    <div className="absolute top-0 right-0 w-64 h-64 bg-violet-500/10 blur-[100px] rounded-full pointer-events-none" />
                    
                    <h2 className="text-base md:text-lg font-semibold text-white mb-4 md:mb-6 flex items-center gap-2">
                        <User className="text-violet-400 w-5 h-5 md:w-[20px] md:h-[20px]" />
                        Personal Information
                    </h2>

                    <form onSubmit={handleSaveProfile} className="relative z-10 flex flex-col md:flex-row gap-6 md:gap-8">
                        {/* Avatar Column */}
                        <div className="flex flex-col items-center gap-3 md:gap-4 shrink-0">
                            <div className="relative group cursor-pointer" onClick={() => fileInputRef.current?.click()}>
                                <div className="w-24 h-24 sm:w-32 sm:h-32 rounded-full overflow-hidden border-2 border-white/10 bg-slate-800 relative shadow-xl shadow-black/20 group-hover:border-violet-500/50 transition-colors">
                                    {profilePicture ? (
                                        <img src={profilePicture} alt="Profile" className="w-full h-full object-cover" />
                                    ) : (
                                        <div className="w-full h-full flex items-center justify-center text-3xl sm:text-4xl font-bold text-slate-600">
                                            {name ? name.charAt(0).toUpperCase() : 'U'}
                                        </div>
                                    )}
                                    {/* Overlay */}
                                    <div className="absolute inset-0 bg-black/50 flex flex-col items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                        <Camera className="text-white mb-1" size={24} />
                                        <span className="text-xs text-white font-medium">Change</span>
                                    </div>
                                </div>
                            </div>
                            <input 
                                type="file" 
                                ref={fileInputRef} 
                                onChange={handleImageUpload} 
                                accept="image/jpeg, image/png, image/webp" 
                                className="hidden" 
                            />
                            <p className="text-xs text-muted text-center max-w-[120px]">
                                JPG, PNG or WebP. Max size 2MB.
                            </p>
                        </div>

                        {/* Fields Column */}
                        <div className="flex-1 space-y-5 content-inner p-0">
                            {/* Feedback Messages */}
                            <AnimatePresence>
                                {profileError && (
                                    <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-rose-500/10 border border-rose-500/20 text-rose-400 p-3 rounded-lg text-sm flex items-center gap-2">
                                        <AlertCircle size={16} /> {profileError}
                                    </motion.div>
                                )}
                                {profileSuccess && (
                                    <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 p-3 rounded-lg text-sm flex items-center gap-2">
                                        <CheckCircle2 size={16} /> {profileSuccess}
                                    </motion.div>
                                )}
                            </AnimatePresence>

                            <div className="space-y-1.5 flex-1">
                                <label className="text-[10px] md:text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">Full Name</label>
                                <div className="relative group">
                                    <div className="absolute inset-y-0 left-3 md:left-4 flex items-center pointer-events-none text-slate-500 group-focus-within:text-violet-400 transition-colors">
                                        <User size={18} />
                                    </div>
                                    <input 
                                        type="text" required value={name} onChange={(e) => setName(e.target.value)}
                                        className="w-full bg-slate-900 border border-white/10 rounded-xl py-2.5 md:py-3 pl-10 md:pl-12 pr-4 text-sm md:text-base text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-sans"
                                    />
                                </div>
                            </div>

                            <div className="space-y-1.5 flex-1 opacity-70 cursor-not-allowed">
                                <label className="text-[10px] md:text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">Email Address</label>
                                <div className="relative group">
                                    <div className="absolute inset-y-0 left-3 md:left-4 flex items-center pointer-events-none text-slate-500">
                                        <Mail size={18} />
                                    </div>
                                    <input 
                                        type="email" disabled value={email}
                                        className="w-full bg-slate-900/50 border border-white/10 rounded-xl py-2.5 md:py-3 pl-10 md:pl-12 pr-4 text-sm md:text-base text-slate-400 cursor-not-allowed"
                                    />
                                </div>
                                <p className="text-[10px] text-muted ml-1 leading-none">Email address cannot be changed</p>
                            </div>

                            <div className="space-y-1.5 flex-1">
                                <label className="text-[10px] md:text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">Phone Number</label>
                                <div className="flex flex-col sm:flex-row gap-3 relative group">
                                    <div className="w-full sm:w-36 overflow-visible shrink-0 z-20" >
                                        <Select 
                                            options={COUNTRY_CODES}
                                            value={countryCode}
                                            onChange={setCountryCode}
                                        />
                                    </div>
                                    <div className="relative flex-1 group">
                                        <div className="absolute inset-y-0 left-3 md:left-4 flex items-center pointer-events-none text-slate-500 group-focus-within:text-violet-400 transition-colors">
                                            <Phone size={18} />
                                        </div>
                                        <input 
                                            type="tel" value={phone} onChange={(e) => setPhone(e.target.value)}
                                            className="w-full bg-slate-900 border border-white/10 rounded-xl py-[9px] md:py-[11px] pl-10 md:pl-12 pr-4 text-sm md:text-base text-white focus:outline-none focus:ring-2 focus:ring-violet-500/50 focus:border-violet-500/50 transition-all font-sans"
                                            placeholder="555-0123"
                                        />
                                    </div>
                                </div>
                            </div>

                            <div className="flex justify-end pt-2">
                                <button
                                    type="submit" disabled={savingProfile}
                                    className="px-4 py-2 sm:px-6 sm:py-2.5 bg-violet-600 hover:bg-violet-500 disabled:opacity-50 text-white text-sm md:text-base font-medium rounded-xl shadow-lg shadow-violet-600/20 transition-all active:scale-[0.98] flex items-center justify-center gap-2 w-full md:w-auto"
                                >
                                    {savingProfile ? (
                                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                    ) : (
                                        <Save size={18} />
                                    )}
                                    <span>Save Profile</span>
                                </button>
                            </div>
                        </div>
                    </form>
                </motion.section>

                {/* Password & Security */}
                <motion.section 
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.1 }}
                    className="glass-card p-4 md:p-6 border border-white/10"
                >
                    <h2 className="text-base md:text-lg font-semibold text-white mb-4 md:mb-6 flex items-center gap-2">
                        <Shield className="text-indigo-400 w-5 h-5 md:w-[20px] md:h-[20px]" />
                        Password & Security
                    </h2>

                    <form onSubmit={handleUpdatePassword} className="space-y-4 md:space-y-5 max-w-xl">
                        {/* Feedback Messages */}
                        <AnimatePresence>
                            {passwordError && (
                                <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-rose-500/10 border border-rose-500/20 text-rose-400 p-3 rounded-lg text-sm flex items-center gap-2">
                                    <AlertCircle size={16} /> {passwordError}
                                </motion.div>
                            )}
                            {passwordSuccess && (
                                <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 p-3 rounded-lg text-sm flex items-center gap-2">
                                    <CheckCircle2 size={16} /> {passwordSuccess}
                                </motion.div>
                            )}
                        </AnimatePresence>

                        <div className="space-y-1.5 flex-1">
                            <label className="text-[10px] md:text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">Current Password</label>
                            <div className="relative group">
                                <div className="absolute inset-y-0 left-3 md:left-4 flex items-center pointer-events-none text-slate-500 group-focus-within:text-indigo-400 transition-colors">
                                    <Lock size={18} />
                                </div>
                                <input 
                                    type="password" required value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)}
                                    className="w-full bg-slate-900 border border-white/10 rounded-xl py-2.5 md:py-3 pl-10 md:pl-12 pr-4 text-sm md:text-base text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500/50 transition-all font-sans"
                                    placeholder="••••••••"
                                />
                            </div>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-5">
                            <div className="space-y-1.5 flex-1">
                                <label className="text-[10px] md:text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">New Password</label>
                                <div className="relative group">
                                    <div className="absolute inset-y-0 left-3 md:left-4 flex items-center pointer-events-none text-slate-500 group-focus-within:text-indigo-400 transition-colors">
                                        <Lock size={18} />
                                    </div>
                                    <input 
                                        type="password" required value={newPassword} onChange={(e) => setNewPassword(e.target.value)}
                                        className="w-full bg-slate-900 border border-white/10 rounded-xl py-2.5 md:py-3 pl-10 md:pl-12 pr-4 text-sm md:text-base text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500/50 transition-all font-sans"
                                        placeholder="••••••••"
                                    />
                                </div>
                            </div>
                            <div className="space-y-1.5 flex-1">
                                <label className="text-[10px] md:text-xs font-semibold text-slate-400 ml-1 uppercase tracking-wider">Confirm New</label>
                                <div className="relative group">
                                    <div className="absolute inset-y-0 left-3 md:left-4 flex items-center pointer-events-none text-slate-500 group-focus-within:text-indigo-400 transition-colors">
                                        <Lock size={18} />
                                    </div>
                                    <input 
                                        type="password" required value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)}
                                        className="w-full bg-slate-900 border border-white/10 rounded-xl py-2.5 md:py-3 pl-10 md:pl-12 pr-4 text-sm md:text-base text-white focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500/50 transition-all font-sans"
                                        placeholder="••••••••"
                                    />
                                </div>
                            </div>
                        </div>

                        <div className="flex justify-start pt-2">
                            <button
                                type="submit" disabled={savingPassword}
                                className="px-4 py-2 sm:px-6 sm:py-2.5 bg-slate-800 hover:bg-slate-700 disabled:opacity-50 text-white text-sm md:text-base font-medium rounded-xl border border-white/10 transition-all active:scale-[0.98] flex items-center justify-center gap-2 w-full md:w-auto"
                            >
                                {savingPassword ? (
                                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                ) : (
                                    <Shield size={18} />
                                )}
                                <span>Change Password</span>
                            </button>
                        </div>
                    </form>
                </motion.section>
            </div>
        </div>
    );
}
