'use client';

import { usePathname } from 'next/navigation';
import Sidebar from "@/components/Sidebar";
import { useAuth } from "@/context/AuthContext";

export default function MainLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { loading, user } = useAuth();
  
  const isAuthPage = pathname === '/login' || pathname === '/register';

  if (loading && !isAuthPage) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-[#08090a]">
        <div className="w-8 h-8 border-2 border-violet-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
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
