<script lang="ts">
	import { enhance } from '$app/forms';
	import type { SubmitFunction } from '@sveltejs/kit';
	import type { AppointmentDepositView } from '$lib/scheduling/deposits';
	import { formatDepositAmount } from '$lib/scheduling/deposits';

	// Says what is about to happen before it happens (plan, P1). Nothing here promises a delivery:
	// whether the receipt really left is what «Correos de este turno» shows afterwards.
	let {
		patientName,
		when,
		patientHasEmail,
		deposit,
		operationId,
		revision,
		disabled,
		onsubmit
	}: {
		patientName: string;
		when: string;
		patientHasEmail: boolean;
		deposit: AppointmentDepositView | null;
		operationId: string;
		revision: string;
		disabled: boolean;
		onsubmit: SubmitFunction;
	} = $props();
</script>

<details class="ux-disclosure ux-disclosure-danger" data-cancel-panel>
	<summary>Cancelar turno</summary>
	<form method="POST" action="?/update_status" use:enhance={onsubmit} class="ux-disclosure-body flex flex-col gap-4">
		<input type="hidden" name="status" value="cancelled" />
		<input type="hidden" name="operation_id" value={operationId} />
		<input type="hidden" name="expected_revision" value={revision} />
		<div>
			<p class="text-base text-fg">Vas a cancelar el turno de <strong>{patientName}</strong>, {when}.</p>
			<ul class="mt-2 grid gap-1 text-sm text-fg-65">
				<li>El horario queda libre para otra reserva.</li>
				{#if deposit?.status === 'paid'}
					<li>La seña de {formatDepositAmount(deposit.amount)} queda por resolver con el paciente. Cancelar no registra una devolución.</li>
				{:else if deposit?.status === 'pending'}
					<li>La seña pendiente deja de pedirse.</li>
				{/if}
				<li>
					{patientHasEmail
						? 'Si el consultorio tiene los correos activos, el paciente recibe el comprobante de cancelación.'
						: 'El paciente no tiene correo cargado: avisale por otro medio.'}
				</li>
			</ul>
		</div>
		<label>
			<span class="ux-label">Motivo (opcional)</span>
			<textarea name="reason" maxlength="500" rows="2" {disabled} class="ux-textarea"></textarea>
		</label>
		<label class="flex items-start gap-3 text-sm font-bold text-fg">
			<input type="checkbox" name="confirm_cancel" value="true" required {disabled} class="mt-0.5" />
			<span>Confirmo que quiero cancelar este turno.</span>
		</label>
		<button {disabled} class="ux-btn-danger w-full sm:w-auto sm:self-start">Cancelar turno</button>
	</form>
</details>
