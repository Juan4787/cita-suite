export type StaffManagementFeedback = {
 success?: boolean; message?: string;
 retry?: { action: 'update_status' | 'reschedule' | 'late_deposit'; fields: Record<string, string> };
 lateDepositDraft?: { amount: string; note: string };
};
