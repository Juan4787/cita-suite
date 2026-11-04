import {
	businessId,
	patientId,
	userId,
	patientContext as context
} from '../__fixtures__/patient-context';
import { describe, expect, it, vi } from 'vitest';
import { createClient } from '@supabase/supabase-js';
import type { CitaDatabase } from '$lib/types/database';
import { readPatientDetail, PatientDetailReadError } from './patient-detail';

describe('authorized patient detail projection with typed SDK and simulated HTTP', () => {
	it.each([
		'patient_clinical_profiles',
		'clinical_entries',
		'appointments',
		'professional_patient_links',
		'professional_users'
	])(
		'rejects an unavailable %s read instead of presenting missing data as empty',
		async (tableWithError) => {
			const selectedContext = context();
			if (tableWithError.startsWith('professional_')) {
				selectedContext.role = 'professional';
				selectedContext.canManage = false;
			}
			const log = vi.spyOn(console, 'error').mockImplementation(() => {});
			const client = createClient<CitaDatabase>('https://supabase.example.test', 'synthetic-key', {
				auth: { persistSession: false, autoRefreshToken: false },
				global: {
					fetch: async (input) => {
						const url = new URL(input instanceof Request ? input.url : String(input));
						const table = url.pathname.split('/').at(-1);
						// A non-retryable technical failure isolates the application projection;
						// the SDK's automatic retry of 503 must not turn this into a timer test.
						if (table === tableWithError)
							return Response.json(
								{ code: 'XX000', message: 'Synthetic read failure' },
								{ status: 400 }
							);
						if (table === 'patients')
							return Response.json({ id: patientId, full_name: 'Synthetic patient' });
						if (table === 'professional_users')
							return Response.json({
								professional_id: userId,
								professionals: { name: 'Synthetic professional' }
							});
						if (table === 'patient_clinical_profiles' || table === 'professional_patient_links')
							return Response.json(null);
						if (table === 'clinical_entries' || table === 'appointments') return Response.json([]);
						throw new Error('Unexpected patient projection request');
					}
				}
			});
			try {
				await expect(
					readPatientDetail({
						patientId,
						supabase: client,
						admin: client,
						context: selectedContext,
						currentUserId: userId
					})
				).rejects.toBeInstanceOf(PatientDetailReadError);
			} finally {
				log.mockRestore();
			}
		}
	);
	it.each([
		{ phone: null, phone_raw: null, phone_e164: null, expectedPhone: null },
		{ phone: null, phone_raw: '342 504 8209', phone_e164: '+5493425048209', expectedPhone: '342 504 8209' },
		{ phone: '', phone_raw: '', phone_e164: '+5493425048209', expectedPhone: '+5493425048209' },
		{ phone: '3425048209', phone_raw: '342 504 8209', phone_e164: '+5493425048209', expectedPhone: '3425048209' }
	])('retains the effective contact in the editable projection and defers documents ($expectedPhone)', async (contact) => {
		const requests: URL[] = [];
		const client = createClient<CitaDatabase>('https://supabase.example.test', 'synthetic-key', {
			auth: { persistSession: false, autoRefreshToken: false },
			global: {
				fetch: async (input) => {
					const url = new URL(input instanceof Request ? input.url : String(input));
					requests.push(url);
					const table = url.pathname.split('/').at(-1);
					if (table === 'patients')
						return Response.json({
							id: patientId,
							full_name: 'Synthetic patient',
							dni: null,
							phone: contact.phone,
							...(url.searchParams.get('select')?.split(',').includes('phone_raw')
								? { phone_raw: contact.phone_raw, phone_e164: contact.phone_e164 } : {}),
							email: null,
							birth_date: null,
							address: null,
							insurance: null,
							insurance_plan: null,
							archived_at: null,
							created_at: '2026-01-01T00:00:00Z',
							updated_at: '2026-01-01T00:00:00Z'
						});
					if (table === 'patient_clinical_profiles') return Response.json(null);
					if (table === 'clinical_entries' || table === 'appointments') return Response.json([]);
					throw new Error('Unexpected patient projection request');
				}
			}
		});
		const result = await readPatientDetail({
			patientId,
			supabase: client,
			admin: client,
			context: context(),
			currentUserId: userId
		});
		expect(result.patient.id).toBe(patientId);
		expect(result.patient.phone).toBe(contact.expectedPhone);
		expect(result.patient).not.toHaveProperty('phone_raw');
		expect(result.patient).not.toHaveProperty('phone_e164');
		expect(result.entries).toEqual([]);
		expect(result.hasMoreEntries).toBe(false);
		expect(result.radiographs).toEqual([]);
		expect(result.permissions.canViewRadiographs).toBe(true);
		expect(result.documentUploads).toBe('not_permitted');
		expect(requests.map((url) => url.pathname.split('/').at(-1)).sort()).toEqual([
			'appointments',
			'clinical_entries',
			'patient_clinical_profiles',
			'patients'
		]);
		expect(
			requests.every((url) => url.searchParams.get('business_id') === 'eq.' + businessId)
		).toBe(true);
	});
});
