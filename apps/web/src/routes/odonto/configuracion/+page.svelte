<script lang="ts">
	import { page } from '$app/stores';
	import BackLink from '$lib/components/BackLink.svelte';

	let { data } = $props<{
		data: { demo: boolean; isMaster?: boolean; canExportPatientData?: boolean };
	}>();

	const returnTarget = $derived.by(() => {
		const raw = $page.url.searchParams.get('return') ?? '';
		try {
			const decoded = decodeURIComponent(raw);
			return decoded.startsWith('/odonto/') ? decoded : '';
		} catch {
			return '';
		}
	});
</script>

<section class="ux-page">
	<div class="ux-hero">
		<BackLink href={returnTarget || '/odonto/pacientes'} label="Volver" class="mb-5" />
		<p class="ux-badge">Configuración</p>
		<h1 class="ux-title mt-4">Ajustes del consultorio</h1>
		<p class="ux-subtitle">Datos, equipo y acceso.</p>
	</div>

	<div class="grid gap-4 lg:grid-cols-2">
		<a href="/odonto/configuracion/reserva-online" class="ux-choice p-6"><h2 class="ux-section-title">Reserva online</h2><p class="mt-2 text-sm text-white/55">Enlaces individuales, prestaciones y datos solicitados por profesional.</p></a>
		<a href="/odonto/configuracion/negocio" class="ux-choice p-6">
			<span class="ux-badge">Consultorio</span>
			<h2 class="mt-4 text-2xl font-bold text-white">Datos y reserva online</h2>
			<p class="mt-2 text-sm text-white/55">Nombre, contacto y reglas de reserva.</p>
		</a>
		<a href="/odonto/configuracion/usuarios" class="ux-choice p-6">
			<span class="ux-badge">Permisos</span>
			<h2 class="mt-4 text-2xl font-bold text-white">Equipo</h2>
			<p class="mt-2 text-sm text-white/55">Quién puede entrar al consultorio y qué rol cumple.</p>
		</a>
		<a href="/odonto/configuracion/suscripcion" class="ux-choice p-6">
			<span class="ux-badge">Acceso</span>
			<h2 class="mt-4 text-2xl font-bold text-white">Suscripción</h2>
			<p class="mt-2 text-sm text-white/55">Estado comercial, vencimiento e historial de acceso.</p>
		</a>
		<a href="/odonto/configuracion/comunicacion" class="ux-choice p-6">
			<span class="ux-badge">Reservas</span>
			<h2 class="mt-4 text-2xl font-bold text-white">Link de reserva</h2>
			<p class="mt-2 text-sm text-white/55">Copiá o abrí el enlace que compartís con tus pacientes.</p>
		</a>
		<a href="/odonto/configuracion/resena-google" class="ux-choice p-6">
			<span class="ux-badge">Opinión</span>
			<h2 class="mt-4 text-2xl font-bold text-white">Reseña de Google</h2>
			<p class="mt-2 text-sm text-white/55">Configurá el enlace y el mensaje automático.</p>
		</a>
		{#if data.canExportPatientData}
			<a href="/odonto/exportar-datos" class="ux-choice p-6">
				<span class="ux-badge">Excel</span>
				<h2 class="mt-4 text-2xl font-bold text-white">Exportar datos</h2>
				<p class="mt-2 text-sm text-white/55">Prepará un Excel con pacientes, historial, turnos y seguimientos.</p>
			</a>
		{/if}
		{#if !data.isMaster}
			<a href="/odonto/configuracion/ayuda" class="ux-choice p-6">
				<span class="ux-badge">Ayuda</span>
				<h2 class="mt-4 text-2xl font-bold text-white">Ayuda para configurar</h2>
				<p class="mt-2 text-sm text-white/55">Pedí ayuda por 1 hora para completar la configuración inicial.</p>
			</a>
		{/if}
	</div>
</section>
