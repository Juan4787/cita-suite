<script lang="ts">
	import { enhance } from '$app/forms';
	import { onDestroy, tick, untrack } from 'svelte';
	import type { SubmitFunction } from '@sveltejs/kit';
	import type {
		PatientDetailViewData,
		PatientFormState,
		PatientPermissions
	} from '$lib/patients/contracts';
	import Modal from '$lib/components/Modal.svelte';
	import DatePartsInput from '$lib/components/DatePartsInput.svelte';
	let {
		open = $bindable(false),
		patient,
		permissions,
		scope,
		form,
		focusEmail = false,
		onCommitted
	}: {
		open: boolean;
		patient: PatientDetailViewData['patient'];
		permissions: PatientPermissions;
		scope: string;
		form?: PatientFormState | null;
		focusEmail?: boolean;
		onCommitted: () => void;
	} = $props();
	let editorPatient = $state(untrack(() => ({ ...patient })));
	let showEditErrors = $state(false),
		savingPatient = $state(false),
		patientUpdateError = $state('');
	let seeded = false;
	let activePatient = untrack(() => patient.id),
		activeScope = untrack(() => scope);
	let destroyed = false;
	const currentYear = new Date().getFullYear();
	function focusEmailField(node: HTMLInputElement) {
		if (focusEmail) void tick().then(() => { if (node.isConnected) node.focus(); });
	}
	const revisionConflict = $derived(
		Boolean(
			form &&
			(form.currentPatientUpdatedAt !== undefined ||
				form.currentClinicalProfileUpdatedAt !== undefined)
		)
	);
	$effect(() => {
		const patientId = patient.id,
			nextScope = scope;
		if (activePatient !== patientId || activeScope !== nextScope) {
			activePatient = patientId;
			activeScope = nextScope;
			open = false;
			seeded = false;
			editorPatient = { ...patient };
			patientUpdateError = '';
			savingPatient = false;
			return;
		}
		if (!open) {
			seeded = false;
			return;
		}
		if (seeded) return;
		// Keep the opening revision and fields together. A conflict response cannot
		// acknowledge a newer revision and overwrite unseen concurrent changes.
		editorPatient = { ...patient };
		seeded = true;
		showEditErrors = false;
		patientUpdateError = '';
	});
	onDestroy(() => {
		destroyed = true;
	});
	function close() {
		if (!savingPatient) open = false;
	}
	function preventEnterSubmit(event: KeyboardEvent) {
		if (event.key !== 'Enter') return;
		const target = event.target;
		if (
			!(target instanceof HTMLElement) ||
			target.tagName === 'TEXTAREA' ||
			target.tagName === 'BUTTON'
		)
			return;
		event.preventDefault();
	}
	function handleEditSubmit(event: SubmitEvent) {
		showEditErrors = true;
		const element = event.currentTarget;
		if (!(element instanceof HTMLFormElement)) return;
		const birth = element.querySelector<HTMLInputElement>('[name="birth_date"]');
		if (revisionConflict || birth?.value === '__invalid__') event.preventDefault();
	}
	const enhancePatientUpdate: SubmitFunction<Record<string, never>, PatientFormState> = ({
		cancel,
		formElement
	}) => {
		showEditErrors = true;
		patientUpdateError = '';
		const birth = formElement.querySelector<HTMLInputElement>('[name="birth_date"]');
		if (savingPatient || revisionConflict || birth?.value === '__invalid__') {
			cancel();
			return;
		}
		const requestedPatient = patient.id,
			requestedScope = scope;
		const isCurrent = () => !destroyed && requestedPatient === patient.id && requestedScope === scope;
		savingPatient = true;
		return async ({ result, update }) => {
			if (!isCurrent()) return;
			try {
				if (result.type === 'error') {
					patientUpdateError =
						'No pudimos guardar los cambios. Revisá tu conexión y volvé a intentar; tus datos siguen en el formulario.';
					return;
				}
				if (result.type === 'success' || result.type === 'redirect') {
					onCommitted();
					open = false;
					showEditErrors = false;
					patientUpdateError = '';
					await update();
					return;
				}
				await update({ reset: false });
			} finally {
				if (isCurrent()) savingPatient = false;
			}
		};
	};
</script>

<Modal {open} title="Editar datos" on:close={close}>
	<!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
	<form
		method="post"
		action="?/update_patient"
		class="space-y-3"
		onkeydown={preventEnterSubmit}
		onsubmit={handleEditSubmit}
		use:enhance={enhancePatientUpdate}
		aria-busy={savingPatient}
	>
		<input
			type="hidden"
			name="expected_patient_updated_at"
			value={editorPatient.updated_at ?? ''}
		/>
		<input
			type="hidden"
			name="expected_clinical_profile_updated_at"
			value={editorPatient.clinical_profile_updated_at ?? ''}
		/>
		<div class="grid grid-cols-1 gap-3 md:grid-cols-2">
			<div class="space-y-1">
				<label class="text-sm font-semibold text-fg" for="full_name">Nombre del paciente *</label>
				<input
					id="full_name"
					name="full_name"
					required
					class="ux-input"
					value={editorPatient.full_name ?? ''}
				/>
			</div>
			<div class="space-y-1">
				<label class="text-sm font-semibold text-fg" for="email">Correo electrónico (opcional)</label>
				<input
					id="email"
					name="email"
					use:focusEmailField
					type="email"
					class="ux-input"
					value={editorPatient.email ?? ''}
				/>
			</div>
		</div>
		<div class="grid grid-cols-1 gap-3 md:grid-cols-2">
			<div class="space-y-1">
				<label class="text-sm font-semibold text-fg" for="phone">Teléfono (opcional)</label>
				<input
					id="phone"
					name="phone"
					class="ux-input"
					value={editorPatient.phone ?? ''}
				/>
			</div>
			<div class="space-y-1">
				<label class="text-sm font-semibold text-fg" for="dni">DNI (opcional)</label>
				<input
					id="dni"
					name="dni"
					inputmode="numeric"
					class="ux-input"
					value={editorPatient.dni ?? ''}
				/>
			</div>
		</div>
		<div class="grid grid-cols-1 gap-3 md:grid-cols-2">
			<div class="space-y-1">
				<label class="text-sm font-semibold text-fg" for="birth_date-year">Fecha de nacimiento (opcional)</label>
				<DatePartsInput
					name="birth_date"
					initialValue={editorPatient.birth_date ?? null}
					minYear={1900}
					maxYear={currentYear}
					showErrors={showEditErrors}
				/>
			</div>
			<div class="space-y-1">
				<label class="text-sm font-semibold text-fg" for="address">Dirección (opcional)</label>
				<input
					id="address"
					name="address"
					class="ux-input"
					value={editorPatient.address ?? ''}
				/>
			</div>
		</div>
		<div class="grid grid-cols-1 gap-3 md:grid-cols-2">
			<div class="space-y-3">
				<div class="space-y-1">
					<label class="text-sm font-semibold text-fg" for="insurance">Obra social (opcional)</label>
					<input
						id="insurance"
						name="insurance"
						class="ux-input"
						value={editorPatient.insurance ?? ''}
					/>
				</div>
				<div class="space-y-1">
					<label class="text-sm font-semibold text-fg" for="insurance_plan">
						Plan de la obra social (opcional)
					</label>
					<input
						id="insurance_plan"
						name="insurance_plan"
						class="ux-input"
						value={editorPatient.insurance_plan ?? ''}
					/>
				</div>
			</div>
			{#if permissions.canEditClinicalProfile}
				<div class="space-y-1">
					<label class="text-sm font-semibold text-fg" for="allergies">Alergias (opcional)</label>
					<input
						id="allergies"
						name="allergies"
						class="ux-input"
						value={editorPatient.allergies ?? ''}
					/>
				</div>
			{/if}
		</div>
		{#if permissions.canEditClinicalProfile}
			<div class="grid grid-cols-1 gap-3 md:grid-cols-2">
				<div class="space-y-1">
					<label class="text-sm font-semibold text-fg" for="medication">Medicación (opcional)</label>
					<textarea
						id="medication"
						name="medication"
						rows="2"
						class="ux-textarea"
					>{editorPatient.medication ?? ''}</textarea>
				</div>
				<div class="space-y-1">
					<label class="text-sm font-semibold text-fg" for="background">Antecedentes (opcional)</label>
					<textarea
						id="background"
						name="background"
						rows="2"
						class="ux-textarea"
					>{editorPatient.background ?? ''}</textarea>
				</div>
			</div>
		{/if}
		{#if form?.message}
			<div class="rounded-xl border px-4 py-3 text-sm font-semibold border-danger-400-50 bg-danger-500-15 text-danger-100">
				<p>{form.message}</p>
				{#if form.duplicate && form.existingId}
					<a
						class="mt-3 inline-flex rounded-xl bg-chip-amber-500 px-4 py-2 text-sm font-bold text-ink-s950 transition hover:bg-chip-amber-400"
						href={`/odonto/pacientes/${form.existingId}`}
						data-sveltekit-preload-data="tap"
					>
						Abrir paciente existente
					</a>
				{/if}
			</div>
		{/if}
		{#if patientUpdateError}
			<div
				class="rounded-xl border px-4 py-3 text-sm font-semibold border-danger-400-50 bg-danger-500-15 text-danger-100"
				role="alert"
			>
				{patientUpdateError}
			</div>
		{/if}
		{#if revisionConflict}<a href={`/odonto/pacientes/${patient.id}?tab=datos`} data-sveltekit-reload class="inline-flex rounded-xl border px-4 py-2 text-sm font-semibold border-line-strong text-fg-n100">Recargar ficha</a>{/if}
		<div class="flex flex-col-reverse gap-2 sm:flex-row sm:items-center sm:justify-end">
			<button
				type="button"
				class="ux-btn-secondary w-full sm:w-auto"
				onclick={close}
				disabled={savingPatient}
			>
				Cancelar
			</button>
			<button
				type="submit"
				disabled={savingPatient || revisionConflict}
				class="ux-btn-primary w-full sm:w-auto"
			>
				{savingPatient ? 'Guardando…' : 'Guardar cambios'}
			</button>
		</div>
	</form>
</Modal>
