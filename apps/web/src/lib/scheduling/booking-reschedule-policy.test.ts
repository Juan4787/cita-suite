import { describe, expect, it } from 'vitest';
import { bookingReschedulePolicyNotice, parseBookingReschedulePolicy } from './email-policy';

const policy = { schema_version: 1, policy_revision: 7, require_deposit_on_reschedule: true, previous_deposit_disposition: 'forfeit' };
describe('initial rescheduling policy disclosure', () => {
 it.each([
  { required: true, previous: 'forfeit', allocation: 'no se aplicará', requirement: 'se pedirá una nueva' },
  { required: true, previous: 'credit', allocation: 'seguirá a cuenta', requirement: 'se pedirá una nueva' },
  { required: false, previous: 'credit', allocation: 'seguirá a cuenta', requirement: 'no se pedirá una nueva' },
  { required: false, previous: 'forfeit', allocation: 'no se aplicará', requirement: 'no se pedirá una nueva' }
 ])('explains the paid and unpaid branches: $required / $previous', ({ required, previous, allocation, requirement }) => {
  const parsed = parseBookingReschedulePolicy({ ...policy, require_deposit_on_reschedule: required, previous_deposit_disposition: previous });
  const notice = bookingReschedulePolicyNotice(parsed);
  expect(notice).toContain('después de pagar'); expect(notice).toContain(allocation); expect(notice).toContain(requirement);
  expect(notice).toContain('una sola seña pendiente');
  if (required) expect(notice).toContain('salvo que las señas a cuenta ya cubran el arancel conocido');
 });
 it.each([null, { ...policy, schema_version: 2 }, { ...policy, policy_revision: 0 }, { ...policy, policy_revision: Number.MAX_SAFE_INTEGER + 1 },
  { ...policy, require_deposit_on_reschedule: 'true' }, { ...policy, previous_deposit_disposition: null }, { ...policy, sender_verified: true }])(
  'rejects invalid or expanded disclosure contracts', input => expect(() => parseBookingReschedulePolicy(input)).toThrow()
 );
});
