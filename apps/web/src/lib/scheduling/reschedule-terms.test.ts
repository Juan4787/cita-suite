import { describe, expect, it } from 'vitest';
import { formatDepositMoney, parseRescheduleFinancialTerms } from './reschedule-terms';

const terms = () => ({
 kind: 'new_requirement', unavailable_reason: null, required: true, amount: '40000', base_amount: '40000', currency: 'ARS',
 previous_applicable_payment_amount: '40000', previous_payment_disposition: 'credit', forfeit_amount: '0', credit_amount: '40000',
 quote_amount: '115000', quote_remainder: '75000', request_from: '2026-11-10T03:00:00.001234Z', due_at: '2026-11-15T13:00:00.001234Z',
 auto_cancel: true, last_minute: false, terms_informed: true, current_deposit_status: 'paid', current_deposit_amount: '40000',
 current_payment_allocation: 'applied', request_days: 7, deadline_hours: 48, min_payment_hours: 24
});

describe('patient reschedule financial boundary', () => {
 it('retains the complete SQL conditions, including microseconds, without recalculating money or dates', () => {
  expect(parseRescheduleFinancialTerms(terms())).toEqual(terms());
 });
 it('does not silently drop a newly introduced or injected financial condition', () => {
  expect(() => parseRescheduleFinancialTerms({ ...terms(), extra_payment: true })).toThrow();
 });
 it.each([0, '01', '-1', '1.5', '4e4', 'NaN', ' 40000', '1000000000001', null])('rejects a noncanonical or invalid new advance: %s', amount => {
  expect(() => parseRescheduleFinancialTerms({ ...terms(), amount })).toThrow();
 });
 it('preserves large accumulated credit and formats it without Number precision loss', () => {
  const amount = '9007199254740993';
  const parsed = parseRescheduleFinancialTerms({ ...terms(), credit_amount: amount });
  expect(parsed.credit_amount).toBe(amount);
  expect(formatDepositMoney(parsed.credit_amount)).toContain('9.007.199.254.740.993');
 });
 it.each(['2026-02-30T13:00:00.001234Z', '2026-11-15T13:00:00Z', '2026-11-15T13:00:00.001234-03:00', 'not a date'])('does not normalize invalid or noncanonical dates: %s', due_at => {
  expect(() => parseRescheduleFinancialTerms({ ...terms(), due_at })).toThrow();
 });
 it('does not interpret an absent quote as a zero balance', () => {
  expect(parseRescheduleFinancialTerms({ ...terms(), quote_amount: null, quote_remainder: null }).quote_amount).toBeNull();
  expect(() => parseRescheduleFinancialTerms({ ...terms(), quote_amount: null, quote_remainder: '0' })).toThrow();
 });
 it('accepts a coherent no-new-obligation outcome without inventing a waiver or payment', () => {
  const none = { ...terms(), kind: 'none', required: false, amount: null, request_from: null, due_at: null,
   request_days: null, deadline_hours: null, min_payment_hours: null, auto_cancel: false };
  expect(parseRescheduleFinancialTerms(none)).toEqual(none);
  expect(() => parseRescheduleFinancialTerms({ ...none, amount: '40000' })).toThrow();
 });
 it('retains an unavailable reason on the initial unchanged interval, and requires a reason for an unavailable target', () => {
  const blocked = { ...terms(), kind: 'unchanged', unavailable_reason: 'deposit_automation_paused', required: false, amount: null,
   request_from: null, due_at: null, request_days: null, deadline_hours: null, min_payment_hours: null, auto_cancel: false,
   previous_applicable_payment_amount: '0', previous_payment_disposition: 'none', credit_amount: '40000' };
  expect(parseRescheduleFinancialTerms(blocked).unavailable_reason).toBe('deposit_automation_paused');
  expect(() => parseRescheduleFinancialTerms({ ...blocked, kind: 'unavailable', unavailable_reason: null })).toThrow();
 });
 it('does not turn a waived obligation into received money or allow an uninformed penalty', () => {
  expect(() => parseRescheduleFinancialTerms({ ...terms(), current_deposit_status: 'waived' })).toThrow();
  expect(() => parseRescheduleFinancialTerms({ ...terms(), terms_informed: false, previous_payment_disposition: 'forfeit', forfeit_amount: '40000' })).toThrow();
 });
});
