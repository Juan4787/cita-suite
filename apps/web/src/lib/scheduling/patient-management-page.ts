import type { RescheduleFinancialTerms } from './reschedule-terms';

export type PatientManagementPanelData = {
 url: string; revision: string; operationId: string; mode: 'overview' | 'cancel' | 'reschedule';
 startsAt: string; timezone: string; now: string; canCancel: boolean; canReschedule: boolean; canConfirm: boolean;
 date: string; slots: { starts_at: string; ends_at: string }[]; selectedStart: string | null;
 availabilityRevision: number | null; integrationRevision: number | null; durationMinutes: number | null; financialTerms: RescheduleFinancialTerms | null;
 unavailableMessage: string | null; financialSummary: { appliedAmount: string; forfeitedAmount: string; unresolvedAmount: string };
};
export type PatientManagementFeedback = {
 success?: boolean; message?: string; action?: 'confirm' | 'cancel' | 'reschedule';
 retrySameOperation?: boolean; submitted?: Record<string, string>;
};
