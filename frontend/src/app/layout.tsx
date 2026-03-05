import type { Metadata } from "next";
import "./globals.css";
import Sidebar from "@/components/Sidebar";

export const metadata: Metadata = {
  title: "FinanceApp — Personal Finance Dashboard",
  description: "Track income, expenses, transfers, credits, and net worth with smart insights.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className="antialiased">
        <Sidebar />
        {/* Main content area — uses CSS class for responsive offset */}
        <main className="main-content">
          <div className="content-inner">
            {children}
          </div>
        </main>
      </body>
    </html>
  );
}
