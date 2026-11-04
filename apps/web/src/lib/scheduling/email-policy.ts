export const EMAIL_POLICY_BOOLEAN_KEYS = ['email_enabled', 'require_email', 'show_cancel', 'show_reschedule', 'require_deposit_on_reschedule'] as const;
export type AppointmentEmailPreferences = Record<(typeof EMAIL_POLICY_BOOLEAN_KEYS)[number], boolean> & {
 previous_deposit_disposition: 'credit' | 'forfeit';
};
export const DEFAULT_APPOINTMENT_EMAIL_PREFERENCES: AppointmentEmailPreferences = {
 email_enabled: true, require_email: true, show_cancel: true, show_reschedule: true,
 require_deposit_on_reschedule: true, previous_deposit_disposition: 'forfeit'
};
