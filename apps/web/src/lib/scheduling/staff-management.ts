export type StaffManagementFeedback = {
 success?: boolean; message?: string;
 retry?: { action: 'update_status' | 'reschedule'; fields: Record<string, string> };
};
