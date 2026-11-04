<script lang="ts">
 import { enhance } from '$app/forms';
 import BackLink from '$lib/components/BackLink.svelte';
 import type { ActionData, PageData } from './$types';
 let { data, form }: { data: PageData; form: ActionData } = $props();
 let saving = $state(false);
 const values = $derived(form && 'values' in form && form.values ? form.values : data.policy);
 const expectedRevision = $derived(form && 'expectedRevision' in form && form.expectedRevision ? form.expectedRevision : data.policy.revision);
 const changed = $derived(Boolean(form && 'changed' in form && form.changed));
</script>

<svelte:head><title>Correo y autogestión · Cita Suite</title></svelte:head>
<section class="ux-page email-settings">
 <header class="ux-hero">
  <BackLink href="/odonto/configuracion" label="Volver" class="mb-5" />
  <h1 class="ux-title">Correo y autogestión</h1>
  <p class="ux-subtitle">Comprobantes, recordatorios y condiciones para cambiar un turno.</p>
 </header>
 {#if !data.policy.sender_verified}
  <p class="ux-alert" role="status">Falta completar el remitente del consultorio. Mientras tanto, no se enviarán correos.</p>
 {/if}
 {#if form?.message}
  <div class={'success' in form && form.success ? 'ux-alert ux-alert-success' : 'ux-alert'} role="status">
   <p>{form.message}</p>
   {#if changed}<a class="underline" href="/odonto/configuracion/correo">Recargar configuración</a>{/if}
  </div>
 {/if}
 <form method="post" action="?/save" class="ux-card grid gap-8" use:enhance={() => {
  saving = true;
  return async ({ update }) => { try { await update({ reset: false }); } finally { saving = false; } };
 }}>
  <input type="hidden" name="expected_revision" value={expectedRevision} />
  <fieldset class="grid gap-4" disabled={saving || data.demo}>
   <legend class="ux-section-title mb-3">Correo del paciente</legend>
   <label class="ux-choice flex items-start gap-3 px-4 py-3">
    <input class="accent-check-accent-600 mt-1" type="checkbox" name="email_enabled" value="true" checked={values.email_enabled} />
    <span><strong>Enviar comprobantes y recordatorios por email</strong><span class="mt-1 block text-sm text-copy-subtle">Los recordatorios se envían 72 y 24 horas antes del turno, cuando corresponde.</span></span>
   </label>
   <label class="ux-choice flex items-start gap-3 px-4 py-3">
    <input class="accent-check-accent-600 mt-1" type="checkbox" name="require_email" value="true" checked={values.require_email} />
    <span><strong>Pedir email obligatorio al reservar online</strong><span class="mt-1 block text-sm text-copy-subtle">Esta opción funciona aunque apagues los envíos. Recepción puede continuar sin email después de confirmar el aviso.</span></span>
   </label>
  </fieldset>
  <fieldset class="grid gap-4" disabled={saving || data.demo}>
   <legend class="ux-section-title mb-3">Botones en los correos</legend>
   <p class="text-sm text-copy-subtle">Se muestran cuando el turno permite esa acción. El comprobante de cancelación no incluye ninguno de estos botones.</p>
   <label class="ux-choice flex items-center gap-3 px-4 py-3"><input class="accent-check-accent-600" type="checkbox" name="show_cancel" value="true" checked={values.show_cancel} /><span>Mostrar Cancelar</span></label>
   <label class="ux-choice flex items-center gap-3 px-4 py-3"><input class="accent-check-accent-600" type="checkbox" name="show_reschedule" value="true" checked={values.show_reschedule} /><span>Mostrar Reprogramar</span></label>
  </fieldset>
  <fieldset class="grid gap-4" disabled={saving || data.demo}>
   <legend class="ux-section-title mb-3">Seña al reprogramar</legend>
   <p class="text-sm text-copy-subtle">Estas condiciones se informan en las nuevas reservas. Cada turno conserva las que aceptó. Los cambios de horario hechos por el consultorio conservan el dinero aplicable.</p>
   <label class="ux-choice flex items-start gap-3 px-4 py-3">
    <input class="accent-check-accent-600 mt-1" type="checkbox" name="require_deposit_on_reschedule" value="true" checked={values.require_deposit_on_reschedule} />
    <span>Pedir una nueva seña si el paciente cambia el horario de un turno que exige seña</span>
   </label>
   <fieldset class="grid gap-3">
    <legend class="ux-label mb-2">¿Qué pasa con la seña anterior?</legend>
    <label class="ux-choice flex items-start gap-3 px-4 py-3">
     <input class="accent-check-accent-600 mt-1" type="radio" name="previous_deposit_disposition" value="forfeit" checked={values.previous_deposit_disposition === 'forfeit'} required />
     <span>Deja de aplicarse al precio de la consulta cuando el paciente confirma el cambio</span>
    </label>
    <label class="ux-choice flex items-start gap-3 px-4 py-3">
     <input class="accent-check-accent-600 mt-1" type="radio" name="previous_deposit_disposition" value="credit" checked={values.previous_deposit_disposition === 'credit'} />
     <span>Se conserva a cuenta del precio de la consulta</span>
    </label>
   </fieldset>
  </fieldset>
  <div><button class="ux-btn ux-btn-primary" disabled={saving || data.demo || changed}>{saving ? 'Guardando…' : 'Guardar preferencias'}</button></div>
 </form>
</section>
<style>
 .email-settings { max-width: 52rem; margin-inline: auto; }
 .email-settings :global(.ux-choice span) { min-width: 0; overflow-wrap: anywhere; }
</style>
