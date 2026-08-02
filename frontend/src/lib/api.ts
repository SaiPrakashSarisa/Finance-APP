const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5000/api";

async function request<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers
    },
    credentials: 'include', // Ensure cookies are sent
  });
  const json = await res.json();
  if (!json.success) throw new Error(json.error || 'API error');
  return json;
}

// ── Auth ──
export const register = (data: any) =>
  request<any>('/auth/register', { method: 'POST', body: JSON.stringify(data) });
export const login = (data: any) =>
  request<any>('/auth/login', { method: 'POST', body: JSON.stringify(data) });
export const logout = () => request<any>('/auth/logout');
export const getMe = () => request<any>('/auth/me');

// ── Accounts ──
export const getAccounts = () => request<any>('/accounts');
export const createAccount = (data: any) =>
  request<any>('/accounts', { method: 'POST', body: JSON.stringify(data) });
export const updateAccount = (id: string, data: any) =>
  request<any>(`/accounts/${id}`, { method: 'PUT', body: JSON.stringify(data) });
export const deleteAccount = (id: string) =>
  request<any>(`/accounts/${id}`, { method: 'DELETE' });

// ── Transactions ──
export const getTransactions = (params?: Record<string, string>) => {
  const query = params ? '?' + new URLSearchParams(params).toString() : '';
  return request<any>(`/transactions${query}`);
};
export const createTransaction = (data: any) =>
  request<any>('/transactions', { method: 'POST', body: JSON.stringify(data) });
export const updateTransaction = (id: string, data: any) =>
  request<any>(`/transactions/${id}`, { method: 'PUT', body: JSON.stringify(data) });
export const deleteTransaction = (id: string) =>
  request<any>(`/transactions/${id}`, { method: 'DELETE' });

// ── Categories ──
export const getCategories = (params?: Record<string, string>) => {
  const query = params ? '?' + new URLSearchParams(params).toString() : '';
  return request<any>(`/categories${query}`);
};
export const createCategory = (data: any) =>
  request<any>('/categories', { method: 'POST', body: JSON.stringify(data) });
export const updateCategory = (id: string, data: any) =>
  request<any>(`/categories/${id}`, { method: 'PUT', body: JSON.stringify(data) });
export const deleteCategory = (id: string) =>
  request<any>(`/categories/${id}`, { method: 'DELETE' });

// ── Credits ──
export const getCredits = (params?: Record<string, string>) => {
  const query = params ? '?' + new URLSearchParams(params).toString() : '';
  return request<any>(`/credits${query}`);
};
export const createCredit = (data: any) =>
  request<any>('/credits', { method: 'POST', body: JSON.stringify(data) });
export const updateCredit = (id: string, data: any) =>
  request<any>(`/credits/${id}`, { method: 'PUT', body: JSON.stringify(data) });

// ── Budgets ──
export const getBudgets = (params?: Record<string, string>) => {
  const query = params ? '?' + new URLSearchParams(params).toString() : '';
  return request<any>(`/budgets${query}`);
};
export const upsertBudget = (data: any) =>
  request<any>('/budgets', { method: 'POST', body: JSON.stringify(data) });
export const deleteBudget = (id: string) =>
  request<any>(`/budgets/${id}`, { method: 'DELETE' });

// ── Analytics ──
export const getDashboard = (month?: number, year?: number) => {
  const params = new URLSearchParams();
  if (month) params.set('month', String(month));
  if (year) params.set('year', String(year));
  const query = params.toString() ? `?${params}` : '';
  return request<any>(`/analytics/dashboard${query}`);
};
export const getCategoryBreakdown = (month?: number, year?: number) => {
  const params = new URLSearchParams();
  if (month) params.set('month', String(month));
  if (year) params.set('year', String(year));
  const query = params.toString() ? `?${params}` : '';
  return request<any>(`/analytics/categories${query}`);
};
export const getMonthlyTrend = () => request<any>('/analytics/monthly-trend');
export const getInsights = () => request<any>('/analytics/insights');
export const getItemTrends = (itemName: string) =>
  request<any>(`/analytics/items/trends?name=${encodeURIComponent(itemName)}`);
export const getInflationTracker = () => request<any>('/analytics/inflation');
export const getMerchantAnalytics = () => request<any>('/analytics/merchants');
export const getMerchantItemComparison = () => request<any>('/analytics/merchants/compare');
export const getSubscriptions = () => request<any>('/analytics/subscriptions');
export const lookupMasterItem = (name: string) =>
  request<any>(`/master-items/lookup?name=${encodeURIComponent(name)}`);

// ── User Settings & Profile ──
export const getUserSettings = () => request<any>('/user/settings');
export const updateUserSettings = (data: any) =>
  request<any>('/user/settings', { method: 'PATCH', body: JSON.stringify(data) });

export const getUserProfile = () => request<any>('/user/profile');
export const updateUserProfile = (data: any) =>
  request<any>('/user/profile', { method: 'PUT', body: JSON.stringify(data) });
export const changePassword = (data: any) =>
  request<any>('/user/change-password', { method: 'PUT', body: JSON.stringify(data) });

