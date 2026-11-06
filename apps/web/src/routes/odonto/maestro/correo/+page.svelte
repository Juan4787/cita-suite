<script lang="ts">
	import type { PageProps } from './$types';
	import { enhance } from '$app/forms';
	import BackLink from '$lib/components/BackLink.svelte';
	import type { SubmitFunction } from '@sveltejs/kit';

	let { data, form }: PageProps = $props();
	let pending = $state<'sending' | 'credit' | null>(null);
	const ops = $derived(data.ops);
	const number = (value: number) => new Intl.NumberFormat('es-AR').format(value);
	const day = (iso: string) => new Intl.DateTimeFormat('es-AR', { timeZone: 'America/Argentina/Buenos_Aires', day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(iso));
	const today = new Intl.DateTimeFormat('sv-SE', { timeZone: 'America/Argentina/Buenos_Aires' }).format(new Date());
	const remaining = $derived(ops.credit ? Math.max(0, ops.credit.messages - ops.credit.used) : null);
	const stateLabels: Record<string, string> = { unprovisioned: 'Sin preparar', dns_pending: 'Registros pendientes', verified: 'Verificado', failed: 'Rechazado', disabled: 'Desactivado' };
	const submit = (target: 'sending' | 'credit'): SubmitFunction => () => {
		pending = target;
		return async ({ update }) => {
			try { await update({ reset: false }); }
			finally { pending = null; }
		};
	};
</script>

<svelte:head><title>Correo de los turnos · Cita Suite</title></svelte:head>
<section class="ux-page mx-auto max-w-4xl">
	<header>
		<BackLink href="/odonto/maestro" label="Panel maestro" class="mb-5" />
		<h1 class="ux-title">Correo de los turnos</h1>
		<p class="mt-3 text-[var(--text-muted)]">Enviados en las últimas 24 horas: {number(ops.used24h)} de {number(ops.dailyLimit)}, con {number(ops.dailyReserve)} reservados para pruebas y reenvíos.</p>
	</header>

	{#if data.warnings.length}
		<ul class="grid gap-3" aria-label="Avisos del correo" data-email-warnings>
			{#each data.warnings as warning (warning.message)}
				<li class={warning.level === 'info' ? 'ux-alert' : 'ux-alert ux-alert-warning'} role={warning.level === 'critical' ? 'alert' : 'status'}>{warning.message}</li>
			{/each}
		</ul>
	{/if}

	<form method="POST" action="?/sending" class="ux-card" use:enhance={submit('sending')} aria-busy={pending === 'sending'}>
		<h2 class="ux-section-title">Envío</h2>
		<input type="hidden" name="expected_revision" value={ops.revision} />
		<label class="mt-4 flex min-h-11 items-center gap-3">
			<input class="accent-check-accent-600" type="checkbox" name="producer_enabled" value="true" checked={ops.producerEnabled} disabled={pending !== null} />
			<span>Envío automático encendido</span>
		</label>
		<p class="mt-1 text-sm text-[var(--text-muted)]">Apagarlo detiene todo lo nuevo. Al volver a encenderlo no salen los avisos de mientras estuvo apagado.</p>
		<label class="mt-5 grid max-w-sm gap-2">
			<span class="font-semibold">Límite diario de correos</span>
			<input class="ux-input" name="daily_limit" inputmode="numeric" pattern="[0-9]*" required maxlength="7" value={ops.dailyLimit} disabled={pending !== null} />
		</label>
		<p class="mt-1 text-sm text-[var(--text-muted)]">Compartido por todos los consultorios. Ponelo en lo que el plan de Zoho permite por día.</p>
		{#if ops.pausedUntil}
			<label class="mt-4 flex min-h-11 items-center gap-3">
				<input class="accent-check-accent-600" type="checkbox" name="lift_pause" value="true" disabled={pending !== null} />
				<span>Levantar la pausa ahora: ya revisé la cuenta de Zoho</span>
			</label>
		{/if}
		{#if form?.form === 'sending' && form.message}
			<p class={form.saved ? 'ux-alert ux-alert-success mt-4' : 'ux-alert mt-4'} role={form.saved ? 'status' : 'alert'}>{form.message}</p>
		{/if}
		<button class="ux-btn-primary mt-5" disabled={pending !== null}>{pending === 'sending' ? 'Guardando…' : 'Guardar envío'}</button>
	</form>

	<form method="POST" action="?/credit" class="ux-card" use:enhance={submit('credit')} aria-busy={pending === 'credit'}>
		<h2 class="ux-section-title">Crédito comprado</h2>
		{#if ops.credit && remaining !== null}
			<p class="mt-2 text-sm">
				{number(ops.credit.messages)} correos desde el {day(ops.credit.startedAt)}, con vencimiento el {day(ops.credit.expiresAt)}.
				Quedan aproximadamente {number(remaining)}.
			</p>
		{:else}
			<p class="mt-2 text-sm">Todavía no hay un crédito registrado.</p>
		{/if}
		<p class="mt-2 text-sm text-[var(--text-muted)]">Zoho no informa el saldo: registrá acá cada crédito que compres. La cuenta incluye todo lo que pudo haber salido, así que es prudente.</p>
		<input type="hidden" name="expected_revision" value={ops.revision} />
		<div class="mt-5 grid gap-4 sm:grid-cols-3">
			<label class="grid min-w-0 gap-2">
				<span class="font-semibold">Correos incluidos</span>
				<input class="ux-input" name="credit_messages" inputmode="numeric" required maxlength="11" placeholder="10000" disabled={pending !== null} />
			</label>
			<label class="grid min-w-0 gap-2">
				<span class="font-semibold">Fecha de compra</span>
				<input class="ux-input" type="date" name="credit_started_on" required value={today} disabled={pending !== null} />
			</label>
			<label class="grid min-w-0 gap-2">
				<span class="font-semibold">Vence el</span>
				<input class="ux-input" type="date" name="credit_expires_on" required disabled={pending !== null} />
			</label>
		</div>
		{#if form?.form === 'credit' && form.message}
			<p class={form.saved ? 'ux-alert ux-alert-success mt-4' : 'ux-alert mt-4'} role={form.saved ? 'status' : 'alert'}>{form.message}</p>
		{/if}
		<button class="ux-btn-primary mt-5" disabled={pending !== null}>{pending === 'credit' ? 'Registrando…' : 'Registrar crédito'}</button>
	</form>

	<section class="ux-card" aria-labelledby="senders-title">
		<h2 id="senders-title" class="ux-section-title">Remitentes por consultorio</h2>
		<p class="mt-2 text-sm text-[var(--text-muted)]">En comprobación: {number(ops.uncertain)} · Sin entregar en 7 días: {number(ops.failed7d)}</p>
		{#if !ops.senders.length}<p class="ux-empty mt-4">Ningún consultorio tiene un remitente preparado.</p>{/if}
		<ul class="mt-4 divide-y divide-line">
			{#each ops.senders as sender (sender.businessId)}
				<li class="py-3">
					<p class="break-words font-semibold">{sender.businessName}</p>
					<p class="mt-1 break-words text-sm text-[var(--text-muted)]">{sender.domain ?? 'Sin dominio'} · {stateLabels[sender.state]}{sender.ready ? ' · listo para enviar' : ''}</p>
				</li>
			{/each}
		</ul>
	</section>
</section>
