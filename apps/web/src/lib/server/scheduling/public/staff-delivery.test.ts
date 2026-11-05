import { describe, expect, it, vi } from 'vitest';
import { parseStaffDelivery, prepareStaffDelivery, markStaffReminderSent } from './staff-delivery';
import { ManagementResultUncertainError } from '../internal/management-contract';
import type { CitaSupabaseClient } from '$lib/types/database';

const businessId = 'b1000000-0000-4000-8000-000000000001';
const appointmentId = 'b2000000-0000-4000-8000-000000000001';
const token = 'a'.repeat(64), revision = 'b'.repeat(64);
const phone = '+5493425048209';
const snapshot = () => ({ appointment_id: appointmentId, token, patient_name: 'Paciente sintético', phone_e164: phone,
 service_name_snapshot: 'Synthetic clinical information',
 starts_at: '2026-12-05T13:00:00+00:00', status: 'reserved', modality: 'in_person',
 business: { name: 'Consultorio sintético', timezone: 'America/Argentina/Cordoba', address: 'Dirección sintética', maps_url: 'https://maps.example.test' },
 deposit: { appointment_id: appointmentId, status: 'pending', amount: 40000, currency: 'ARS', request_from: '2026-11-28T03:00:00Z', due_at: '2026-12-03T13:00:00Z',
  auto_cancel: true, waived_reason: null, recorded_at: null, reminder_opened_at: '2026-11-05T13:00:00Z', expired_at: null, revision: 2 },
 transfer_details: 'Alias sintético', deposit_auto_cancel_enabled: true });
const clientWith = (response: { data: unknown; error: unknown }) => {
 const rpc = vi.fn(async () => response);
 return { rpc, client: { rpc } as unknown as CitaSupabaseClient };
};

describe('explicit staff delivery', () => {
 it.each(['activation','rescheduled','reminder','deposit'] as const)('uses only the fresh management link for %s', kind => {
  const result = parseStaffDelivery(snapshot(), appointmentId, kind);
  expect(new URL(result.publicUrl).pathname).toBe(`/gestion/${token}${kind === 'rescheduled' ? '/reprogramado' : ''}`);
  expect(result.message).toContain(result.publicUrl);
  expect(result.message).not.toContain('/turno/');
  expect(result.whatsappUrl).toBeTruthy();
  expect(new URL(result.whatsappUrl!).searchParams.get('text')).toBe(result.message);
  expect(result.message).not.toContain('Synthetic clinical information');
 });

 it('keeps virtual reminders separate from the physical address', () => {
  const result = parseStaffDelivery({ ...snapshot(), modality: 'video' }, appointmentId, 'reminder');
  expect(result.message).toContain('Modalidad: Virtual');
  expect(result.message).not.toContain('Dirección sintética');
  expect(result.message).not.toContain('maps.example.test');
 });

 it('does not announce automatic cancellation when its practice switch is off', () => {
  const result = parseStaffDelivery({ ...snapshot(), deposit_auto_cancel_enabled: false }, appointmentId, 'deposit');
  expect(result.message).toContain('40.000');
  expect(result.message).not.toContain('se libera automáticamente');
  expect(result.message).toContain('Alias sintético');
 });

 it.each(['activation','rescheduled'] as const)('allows a viewable %s link without inventing a WhatsApp recipient', kind => {
  const result = parseStaffDelivery({ ...snapshot(), phone_e164: null }, appointmentId, kind);
  expect(result.publicUrl).toContain(`/gestion/${token}`);
  expect(result.whatsappUrl).toBeNull(); expect(result.whatsappWebUrl).toBeNull();
 });

 it('rejects a foreign appointment, malformed credential or incomplete prepared purpose', () => {
  for (const payload of [{ ...snapshot(), appointment_id: businessId }, { ...snapshot(), token: 'broken' },
   { ...snapshot(), deposit: null }, { ...snapshot(), phone_e164: null },
   { ...snapshot(), deposit_auto_cancel_enabled: 'unknown', deposit: { ...snapshot().deposit, auto_cancel: false } }]) {
   expect(() => parseStaffDelivery(payload, appointmentId, 'deposit')).toThrow();
  }
 });

 it('passes tenant, displayed revision and the exact checked stored phone, without a browser actor', async () => {
  const { rpc, client } = clientWith({ data: snapshot(), error: null });
  await prepareStaffDelivery(client, { businessId, appointmentId, expectedRevision: revision, kind: 'reminder', expectedPhone: phone });
  expect(rpc).toHaveBeenCalledExactlyOnceWith('prepare_staff_appointment_delivery', { p_business_id: businessId,
   p_appointment_id: appointmentId, p_expected_revision: revision, p_kind: 'reminder', p_reopen: false, p_expected_phone: phone });
 });

 it('does not dispatch without a valid checked recipient or displayed revision', async () => {
  const { rpc, client } = clientWith({ data: snapshot(), error: null });
  await expect(prepareStaffDelivery(client, { businessId, appointmentId, expectedRevision: revision, kind: 'deposit' })).rejects.toThrow('APPOINTMENT_DELIVERY_CONTACT_CHANGED');
  await expect(prepareStaffDelivery(client, { businessId, appointmentId, expectedRevision: '', kind: 'activation' })).rejects.toThrow();
  expect(rpc).not.toHaveBeenCalled();
 });

 it('keeps an unreadable committed preparation uncertain instead of claiming rollback', async () => {
  const { client } = clientWith({ data: { token }, error: null });
  await expect(prepareStaffDelivery(client, { businessId, appointmentId, expectedRevision: revision, kind: 'activation' })).rejects.toBeInstanceOf(ManagementResultUncertainError);
 });

 it('preserves a known SQL refusal and never turns it into a delivery success', async () => {
  const error = { message: 'APPOINTMENT_MANAGEMENT_FORBIDDEN', code: 'P0001' };
  const { client } = clientWith({ data: null, error });
  await expect(prepareStaffDelivery(client, { businessId, appointmentId, expectedRevision: revision, kind: 'activation' })).rejects.toBe(error);
 });

 it.each([true,false])('accepts a manual sent fact or its already recorded result (%s)', async data => {
  const { rpc, client } = clientWith({ data, error: null });
  await expect(markStaffReminderSent(client, { businessId, appointmentId, expectedRevision: revision })).resolves.toBe(data);
  expect(rpc).toHaveBeenCalledExactlyOnceWith('mark_appointment_whatsapp_reminder_sent', { p_business_id: businessId,
   p_appointment_id: appointmentId, p_expected_revision: revision });
 });

 it('keeps an unreadable manual sent result uncertain', async () => {
  const { client } = clientWith({ data: null, error: null });
  await expect(markStaffReminderSent(client, { businessId, appointmentId, expectedRevision: revision })).rejects.toBeInstanceOf(ManagementResultUncertainError);
 });
});
