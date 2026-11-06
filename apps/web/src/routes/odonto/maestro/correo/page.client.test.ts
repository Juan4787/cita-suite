/** @vitest-environment jsdom */

import { cleanup, render, screen } from '@testing-library/svelte';
import '@testing-library/jest-dom/vitest';
import { afterEach, describe, expect, it } from 'vitest';
import type { ComponentProps } from 'svelte';
import Page from './+page.svelte';

type Data = ComponentProps<typeof Page>['data'];
const ops = {
	revision: 7, producerEnabled: true, producerEnabledAt: '2026-11-06T10:00:00Z', pausedUntil: null as string | null, pauseReason: null as string | null,
	dailyLimit: 100, dailyReserve: 10, used24h: 12,
	credit: { messages: 10000, startedAt: '2026-11-05T03:00:00Z', expiresAt: '2026-12-04T02:59:59Z', used: 9000 } as Data['ops']['credit'],
	uncertain: 1, failed7d: 2,
	senders: [{ businessId: 'b1', businessName: 'Consultorio de prueba', domain: 'prueba-correo.cita-suite.com.ar', state: 'verified' as const, ready: true }]
};
const page = (changes: Partial<typeof ops> = {}, warnings: Data['warnings'] = []) =>
	render(Page, { data: { ops: { ...ops, ...changes }, warnings } as Data, form: null, params: {} });

afterEach(() => cleanup());

describe('correo de los turnos', () => {
	it('muestra el crédito, lo que queda y el uso del día sin datos de pacientes', () => {
		const { container } = page();
		expect(screen.getByText(/10\.000 correos desde el 5 de noviembre de 2026, con vencimiento el 3 de diciembre de 2026\./)).toBeInTheDocument();
		expect(screen.getByText(/Quedan aproximadamente 1\.000\./)).toBeInTheDocument();
		expect(screen.getByText('Enviados en las últimas 24 horas: 12 de 100, con 10 reservados para pruebas y reenvíos.')).toBeInTheDocument();
		expect(screen.getByText('prueba-correo.cita-suite.com.ar · Verificado · listo para enviar')).toBeInTheDocument();
		expect(container.textContent).not.toMatch(/@example|@gmail/);
	});

	it('los avisos urgentes se anuncian y la pausa sólo se levanta si existe', () => {
		const { container, unmount } = page({}, [{ level: 'critical', message: 'El crédito venció.' }, { level: 'info', message: 'El envío automático está apagado.' }]);
		expect(screen.getByRole('alert')).toHaveTextContent('El crédito venció.');
		expect(screen.getByText('El envío automático está apagado.')).toHaveAttribute('role', 'status');
		expect(container.querySelector('input[name="lift_pause"]')).toBeNull();
		unmount();
		const paused = page({ pausedUntil: '2026-11-06T15:15:00Z', pauseReason: 'SERR_157' });
		expect(paused.container.querySelector('input[name="lift_pause"]')).not.toBeNull();
	});

	it('cada formulario envía su propia revisión y sus campos', () => {
		const { container } = page();
		const sending = container.querySelector<HTMLFormElement>('form[action="?/sending"]')!;
		const credit = container.querySelector<HTMLFormElement>('form[action="?/credit"]')!;
		expect(Object.fromEntries(new FormData(sending))).toEqual({ expected_revision: '7', producer_enabled: 'true', daily_limit: '100' });
		expect(new FormData(credit).get('expected_revision')).toBe('7');
		expect(screen.getByLabelText('Correos incluidos')).toBeRequired();
		expect(document.querySelector('[name="credit_expires_on"]')).toHaveAttribute('type', 'date');
	});

	it('sin crédito registrado lo dice en lugar de mostrar un saldo', () => {
		page({ credit: null });
		expect(screen.getByText('Todavía no hay un crédito registrado.')).toBeInTheDocument();
		expect(screen.queryByText(/Quedan aproximadamente/)).not.toBeInTheDocument();
	});
});
