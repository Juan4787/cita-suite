/** @vitest-environment jsdom */
import { cleanup, render, screen } from '@testing-library/svelte';
import '@testing-library/jest-dom/vitest';
import { afterEach, describe, expect, it, vi } from 'vitest';
import Panel from './PatientManagementPanel.svelte';
import type { PatientManagementPanelData } from '$lib/scheduling/patient-management-page';
import type { ComponentProps } from 'svelte';
const renderPanel = (props: ComponentProps<typeof Panel>) => render(Panel, { props });
vi.mock('$app/forms', () => ({ enhance: () => ({ destroy() {} }) }));
afterEach(cleanup);
const context = (overrides: Partial<PatientManagementPanelData> = {}): PatientManagementPanelData => ({
 url: '/gestion/personal-token', revision: 'observed-revision', operationId: 'original-operation', mode: 'overview',
 startsAt: '2026-12-01T12:00:00Z', timezone: 'America/Argentina/Cordoba', now: '2026-11-03T14:00:00Z',
 canCancel: true, canReschedule: true, canConfirm: true, date: '2026-12-02', slots: [], selectedStart: null,
 availabilityRevision: 9, integrationRevision: null, durationMinutes: 45, financialTerms: null, unavailableMessage: null,
 financialSummary: { appliedAmount: '0', forfeitedAmount: '0', unresolvedAmount: '0' }, ...overrides
});
describe('contextual patient management panel', () => {
 it('offers both independent available paths from a current appointment', () => {
  renderPanel({ context: context() });
  expect(screen.getByRole('link', { name: 'Cancelar turno' })).toHaveAttribute('href', '/gestion/personal-token?accion=cancelar');
  expect(screen.getByRole('link', { name: 'Reprogramar turno' })).toHaveAttribute('href', '/gestion/personal-token?accion=reprogramar');
 });
 it('asks cancellation explicitly, preserves the observed operation and offers the other allowed path', () => {
  const { container } = renderPanel({ context: context({ mode: 'cancel' }) });
  expect(screen.getByRole('heading', { name: '¿Querés cancelar este turno?' })).toBeVisible();
  expect(screen.getByRole('button', { name: 'Sí, cancelar turno' })).toBeVisible();
  expect(screen.getByRole('link', { name: 'Prefiero reprogramar' })).toBeVisible();
  expect(container.querySelector('input[name="expected_revision"]')).toHaveValue('observed-revision');
  expect(container.querySelector('input[name="operation_id"]')).toHaveValue('original-operation');
 });
 it('shows no cancel/reschedule action for a cancelled/past appointment even with a stale query mode', () => {
  renderPanel({ context: context({ mode: 'cancel', canCancel: false, canReschedule: false, canConfirm: false,
   financialSummary: { appliedAmount: '0', forfeitedAmount: '0', unresolvedAmount: '40000' } }) });
  expect(screen.queryByRole('button', { name: /cancelar|reprogramar/i })).not.toBeInTheDocument();
  expect(screen.queryByRole('link', { name: /cancelar|reprogramar/i })).not.toBeInTheDocument();
  expect(screen.getByText(/dinero.*resolver/i)).toBeVisible();
 });
 it('offers the cancellation alternative on the selection screen, with no mutation button before a choice', () => {
  renderPanel({ context: context({ mode: 'reschedule' }) });
  expect(screen.getByRole('heading', { name: '¿Querés reprogramar este turno?' })).toBeVisible();
  expect(screen.getByRole('link', { name: 'Prefiero cancelar sin reprogramar' })).toBeVisible();
  expect(screen.queryByRole('button', { name: 'Confirmar reprogramación' })).not.toBeInTheDocument();
 });
 it('does not offer a hidden/denied alternative and keeps the no-change exit', () => {
  renderPanel({ context: context({ mode: 'cancel', canReschedule: false }) });
  expect(screen.queryByRole('link', { name: 'Prefiero reprogramar' })).not.toBeInTheDocument();
  expect(screen.getByRole('link', { name: 'Conservar mi turno' })).toHaveAttribute('href', '/gestion/personal-token');
 });
 it('does not claim an unverified transport failure rolled back; retries only the original submitted operation', () => {
  const { container } = renderPanel({ context: context(), feedback: { message: 'No pudimos comprobar el resultado.', action: 'reschedule', retrySameOperation: true,
   submitted: { operation_id: 'lost-operation', expected_revision: 'old-revision', starts_at: '2026-12-02T12:00:00Z' } } });
  expect(screen.getByRole('button', { name: 'Volver a comprobar la misma acción' })).toBeVisible();
  expect(container.querySelector('input[name="operation_id"]')).toHaveValue('lost-operation');
  expect(container.querySelector('input[name="expected_revision"]')).toHaveValue('old-revision');
  expect(screen.queryByRole('link', { name: 'Cancelar turno' })).not.toBeInTheDocument();
 });
});
