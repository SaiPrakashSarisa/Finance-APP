'use client';

import { usePathname, useRouter } from 'next/navigation';
import Sidebar from "@/components/Sidebar";
import { useAuth } from "@/context/AuthContext";
import { useEffect } from 'react';

export default function MainLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { loading, user } = useAuth();
  
  const isAuthPage = pathname === '/login' || pathname === '/register';

  useEffect(() => {
    if (!loading && !user && !isAuthPage) {
      router.push('/login');
    }
    // Automatically redirect authenticated users away from auth pages
    if (!loading && user && isAuthPage) {
      router.push('/');
    }
  }, [loading, user, isAuthPage, router]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-[#08090a]">
        <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  // Prevent flashing of protected content while redirecting
  if (!user && !isAuthPage) {
    return null;
  }

  // Prevent rendering auth pages if already logged in
  if (user && isAuthPage) {
    return null;
  }

  return (
    <>
      {!isAuthPage && <Sidebar />}
      <main className={!isAuthPage ? "main-content" : ""}>
        <div className={!isAuthPage ? "content-inner" : ""}>
          {children}
        </div>
      </main>
    </>
  );
}
