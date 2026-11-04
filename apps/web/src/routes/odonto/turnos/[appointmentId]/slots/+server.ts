import { logServerFailure } from '$lib/server/platform/logging';
import { env } from '$env/dynamic/private';
import { isAvailabilityDate } from '$lib/availability/windows';
import { getOdontoContext } from '$lib/server/access/public/odonto-context';
import { listStaffManagementSlots, loadStaffManagementSelection } from '$lib/server/scheduling/public/staff-management';
import { json, redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async event => {
 if (!event.locals.auth) throw redirect(303, '/login');
 if (env.DEMO_MODE === 'true') return json({ slots: [], availabilityRevision: null, durationMinutes: null });
 const { supabase, business } = await getOdontoContext(event);
 if (!business.canOperate) return json({ message: 'Tu rol no permite reprogramar turnos.', slots: [] }, { status: 403 });
 const date = event.url.searchParams.get('date') ?? '';
 const revision = event.url.searchParams.get('expected_revision') ?? '';
 if (!isAvailabilityDate(date) || !/^[a-f0-9]{64}$/.test(revision))
  return json({ message: 'Recargá el detalle del turno y elegí una fecha válida.', slots: [] }, { status: 400 });
 try {
  const appointment = await loadStaffManagementSelection(supabase, business.business.id, event.params.appointmentId);
  if (appointment.revision !== revision) return json({ message: 'El turno cambió. Recargá su detalle antes de elegir otro horario.', slots: [] }, { status: 409 });
  const selected = await listStaffManagementSlots(supabase, business.business, appointment, date, event.url.searchParams.get('ignore_break') === 'true');
  return json({ slots: selected.slots, availabilityRevision: selected.availabilityRevision, durationMinutes: selected.durationMinutes });
 } catch (error) {
  logServerFailure('Error consultando horarios de reprogramación', error);
  return json({ message: 'No pudimos consultar los horarios. Recargá el detalle y volvé a intentar.', slots: [] }, { status: 503 });
 }
};
