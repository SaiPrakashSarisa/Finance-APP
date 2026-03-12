const API_BASE = "http://localhost:5000/api";

async function request<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${endpoint}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  const json = await res.json();
  if (!json.success) throw new Error(json.error || 'API error');
  return json;
}

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
export const getCategories = () => request<any>('/categories');
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

// ── User Settings ──
export const getUserSettings = () => request<any>('/user/settings');
export const updateUserSettings = (data: any) =>
  request<any>('/user/settings', { method: 'PATCH', body: JSON.stringify(data) });
