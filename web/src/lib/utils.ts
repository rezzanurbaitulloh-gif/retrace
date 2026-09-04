import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
export function cn(...inputs: ClassValue[]) { return twMerge(clsx(inputs)); }
export function formatTimestamp(value: string | number | Date | null | undefined): string {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleString(undefined, { month:'short', day:'numeric', hour:'2-digit', minute:'2-digit' });
}
export function timeAgo(value: string | number | Date | null | undefined): string {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  const diff = Date.now() - d.getTime();
  const s = Math.round(diff/1000);
  if (s<60) return `${s}s ago`;
  const m = Math.round(s/60);
  if (m<60) return `${m}m ago`;
  const h = Math.round(m/60);
  if (h<24) return `${h}h ago`;
  return `${Math.round(h/24)}d ago`;
}
export type BatteryStatus = 'HIGH'|'MEDIUM'|'LOW'|'CRITICAL'|'UNKNOWN';
export function batteryStatus(level: number | null | undefined): BatteryStatus {
  if (level==null) return 'UNKNOWN';
  if (level<10) return 'CRITICAL';
  if (level<20) return 'LOW';
  if (level<50) return 'MEDIUM';
  return 'HIGH';
}
export function accuracyLabel(accuracy: number | null | undefined): string {
  if (accuracy==null) return '±?';
  return `±${Math.round(accuracy)}m`;
}
export function confidenceFromAccuracy(accuracy: number | null | undefined): 'HIGH'|'MEDIUM'|'LOW' {
  if (accuracy==null) return 'LOW';
  if (accuracy<=50) return 'HIGH';
  if (accuracy<=200) return 'MEDIUM';
  return 'LOW';
}
export function truncate(text: string | null | undefined, max=24): string {
  if (!text) return '';
  return text.length>max ? `${text.slice(0,max-1)}…` : text;
}
