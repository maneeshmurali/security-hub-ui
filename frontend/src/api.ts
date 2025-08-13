import type { Control, Stats } from './App';

export async function fetchJSON<T>(url: string): Promise<T> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
}

export function fetchStats(): Promise<Stats> {
  return fetchJSON('/api/stats');
}

export function fetchControls(params: { severity?: string } = {}): Promise<{ controls: Control[]; total_controls: number; total_affected_resources: number; }> {
  const search = new URLSearchParams();
  if (params.severity) search.set('severity', params.severity);
  const qs = search.toString();
  return fetchJSON(`/api/controls${qs ? `?${qs}` : ''}`);
}

export function fetchControlDetails(controlId: string) {
  return fetchJSON(`/api/controls/${encodeURIComponent(controlId)}`);
}