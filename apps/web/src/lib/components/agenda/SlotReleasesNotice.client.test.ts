/** @vitest-environment jsdom */
import { cleanup, render, screen } from '@testing-library/svelte';
import '@testing-library/jest-dom/vitest';
import { afterEach, describe, expect, it } from 'vitest';
import SlotReleasesNotice from './SlotReleasesNotice.svelte';
import { buildSlotReleaseNotice, type SlotRelease } from '$lib/scheduling/slot-releases';

const release = (id: string): SlotRelease => ({ id, appointmentId: 'a1000000-0000-4000-8000-000000000001',
	professionalId: 'a2000000-0000-4000-8000-000000000001', serviceId: 'a3000000-0000-4000-8000-000000000001',
	professionalName: 'Dra. Ramírez', startsAt: '2026-12-01T12:00:00.000Z', endsAt: '2026-12-01T12:30:00.000Z',
	releasedAt: '2026-11-20T12:00:00.000Z', reason: 'patient_cancelled' });
const props = (items: SlotRelease[], truncated = false) => ({ notice: buildSlotReleaseNotice(items, truncated),
	timezone: 'America/Argentina/Cordoba', storageKeyPrefix: 'cita-suite:notice:v1:persona:consultorio' });

afterEach(() => { cleanup(); window.localStorage.clear(); });

describe('aviso interno de horarios liberados', () => {
	it('con uno solo dice cuál es y permite darlo sin pasar por la lista', async () => {
		render(SlotReleasesNotice, props([release('r1')]));
		expect(await screen.findByText('Se liberó un horario')).toBeInTheDocument();
		expect(screen.getByText(/Dra\. Ramírez/)).toHaveTextContent('Canceló la persona');
		const action = screen.getByRole('link', { name: 'Dar este horario' });
		expect(action.getAttribute('href')).toContain('/odonto/agenda?date=2026-12-01');
		expect(action.getAttribute('href')).toContain('hora=09%3A00');
		expect(screen.getByRole('link', { name: 'Ver en la agenda' })).toHaveAttribute('href', '/odonto/agenda#horarios-liberados');
	});

	it('con varios lleva a la lista de la agenda, y sin ninguno no muestra nada', async () => {
		const { unmount } = render(SlotReleasesNotice, props([release('r1'), release('r2')]));
		expect(await screen.findByText('Se liberaron 2 horarios')).toBeInTheDocument();
		expect(screen.getByRole('link', { name: 'Ver horarios' })).toHaveAttribute('href', '/odonto/agenda#horarios-liberados');
		unmount();
		const { container } = render(SlotReleasesNotice, props([]));
		expect(container.textContent?.trim()).toBe('');
	});

	it('no promete un total exacto cuando la lista está cortada', async () => {
		render(SlotReleasesNotice, props(Array.from({ length: 50 }, (_, index) => release(`r${index}`)), true));
		expect(await screen.findByText('Se liberaron más de 50 horarios')).toBeInTheDocument();
	});

	it('cerrado queda cerrado para ese conjunto y vuelve si se libera otro horario', () => {
		const first = buildSlotReleaseNotice([release('r1')], false);
		expect(buildSlotReleaseNotice([release('r1')], false).dismissalKey).toBe(first.dismissalKey);
		expect(buildSlotReleaseNotice([release('r1'), release('r2')], false).dismissalKey).not.toBe(first.dismissalKey);
		expect(buildSlotReleaseNotice([release('r2')], false).dismissalKey).not.toBe(first.dismissalKey);
	});
});
