import type { Metadata } from "next";
import "./globals.css";
import Sidebar from "@/components/Sidebar";

export const metadata: Metadata = {
  title: "FinanceApp — Personal Finance Dashboard",
  description: "Track income, expenses, transfers, credits, and net worth with smart insights.",
};

import { AuthProvider } from "@/context/AuthContext";
import MainLayout from "@/components/MainLayout";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className="antialiased">
        <AuthProvider>
          <MainLayout>{children}</MainLayout>
        </AuthProvider>
      </body>
    </html>
  );
}
