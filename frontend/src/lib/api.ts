const API_BASE = "http://localhost:5000/api";
// const API_BASE = "https://finance-app-axlj.onrender.com/api";

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

// ── User Settings & Profile ──
export const getUserSettings = () => request<any>('/user/settings');
export const updateUserSettings = (data: any) =>
  request<any>('/user/settings', { method: 'PATCH', body: JSON.stringify(data) });

export const getUserProfile = () => request<any>('/user/profile');
export const updateUserProfile = (data: any) =>
  request<any>('/user/profile', { method: 'PUT', body: JSON.stringify(data) });
export const changePassword = (data: any) =>
  request<any>('/user/change-password', { method: 'PUT', body: JSON.stringify(data) });

// ── Budgets ──
export const getBudgets = () => request<any>('/budgets');
export const upsertBudget = (data: any) =>
  request<any>('/budgets/upsert', { method: 'POST', body: JSON.stringify(data) });
export const deleteBudget = (id: string) =>
  request<any>(`/budgets/${id}`, { method: 'DELETE' });
export const getBudgetProgress = (month?: number, year?: number) => {
  const params = new URLSearchParams();
  if (month) params.set('month', String(month));
  if (year) params.set('year', String(year));
  const query = params.toString() ? `?${params}` : '';
  return request<any>(`/budgets/progress${query}`);
};

export const getBudgetAnalytics = (
  fromMonth?: number, fromYear?: number,
  toMonth?: number, toYear?: number
) => {
  const params = new URLSearchParams();
  if (fromMonth) params.set('fromMonth', String(fromMonth));
  if (fromYear) params.set('fromYear', String(fromYear));
  if (toMonth) params.set('toMonth', String(toMonth));
  if (toYear) params.set('toYear', String(toYear));
  const query = params.toString() ? `?${params}` : '';
  return request<any>(`/budgets/analytics${query}`);
};