'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { getMe, logout as apiLogout } from '@/lib/api';
import { useRouter, usePathname } from 'next/navigation';

interface AuthContextType {
  user: any;
  loading: boolean;
  login: (userData: any) => void;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    async function checkAuth() {
      try {
        const res = await getMe();
        if (res.success) {
          setUser(res.user);
        }
      } catch (err) {
        // Not logged in or token expired
        setUser(null);
        if (pathname !== '/login' && pathname !== '/register') {
          router.push('/login');
        }
      } finally {
        setLoading(false);
      }
    }
    checkAuth();
  }, [pathname, router]);

  const loginUser = (userData: any) => {
    setUser(userData);
    router.push('/');
  };

  const logoutUser = async () => {
    try {
      await apiLogout();
      setUser(null);
      router.push('/login');
    } catch (err) {
      console.error('Logout failed:', err);
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, login: loginUser, logout: logoutUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
