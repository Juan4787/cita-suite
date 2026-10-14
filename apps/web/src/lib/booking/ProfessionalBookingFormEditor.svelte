<script lang="ts">
  import { onMount } from 'svelte';
  import { enhance } from '$app/forms';
  import type { BookingIntakeField } from '@turnos-saas/shared/booking-integration';
  let { professionals, configurations } = $props<{
    professionals: Array<{ id: string; name: string }>;
    configurations: Array<{ professional_id: string; revision: number; fields: BookingIntakeField[] }>;
  }>();
  let selected = $state('');
  let fields = $state<BookingIntakeField[]>([]);
  let saving = $state(false);
  let ready = $state(false);
  onMount(() => { ready = true; });
  const person = $derived(professionals.find((item: {id: string; name: string}) => item.id === selected) ?? professionals[0]);
  const configuration = $derived(configurations.find((item: {professional_id: string; revision: number; fields: BookingIntakeField[]}) => item.professional_id === person?.id));
  $effect(() => { person?.id; fields = structuredClone(configuration?.fields ?? []); });
  const targets: Array<{ value: NonNullable<BookingIntakeField['patientField']>; label: string }> = [
    { value: 'insurance', label: 'Obra social' }, { value: 'insurance_plan', label: 'Plan de cobertura' },
    { value: 'age', label: 'Edad declarada' }, { value: 'birth_date', label: 'Fecha de nacimiento' },
    { value: 'medication', label: 'Medicación' }, { value: 'background', label: 'Antecedentes' },
    { value: 'allergies', label: 'Alergias' }, { value: 'dni', label: 'DNI' },
    { value: 'address', label: 'Domicilio' }, { value: 'custom', label: 'Otro dato del perfil' }
  ];
  function add() { fields = [...fields, { id: 'q_' + crypto.randomUUID().replaceAll('-', ''), label: '', kind: 'text', maxLength: 500, required: false, patientField: 'custom' }]; }
  function changeKind(index: number, kind: BookingIntakeField['kind']) {
    const previous = fields[index];
    fields[index] = { id: previous.id, label: previous.label, patientField: previous.patientField, required: previous.required, kind,
      ...(kind === 'text' || kind === 'textarea' ? { maxLength: 1000 } : kind === 'choice' ? { options: [] } : {}) };
  }
</script>

<section class="ux-soft-card space-y-5 p-6" aria-labelledby="patient-form-title">
  <div><h2 id="patient-form-title" class="ux-section-title">Datos que pedís al reservar</h2><p class="mt-2 text-sm text-white/65">Se aplican a todos tus enlaces de reserva. Elegí dónde se guarda cada respuesta y cuáles son obligatorias. Los cambios se aplican a nuevas reservas; cada turno conserva sus preguntas originales.</p></div>
  {#if person}
    <label class="block"><span class="ux-label">Profesional del formulario</span><select class="ux-select" value={person.id} onchange={event => selected = event.currentTarget.value}>{#each professionals as professional}<option value={professional.id}>{professional.name}</option>{/each}</select></label>
    <form method="POST" action="?/save_form" use:enhance={() => { saving = true; return async ({ update }) => { try { await update({ reset: false }); } finally { saving = false; } }; }} class="space-y-5">
      <input type="hidden" name="professional_id" value={person.id} /><input type="hidden" name="revision" value={configuration?.revision ?? 0} /><input type="hidden" name="fields" value={JSON.stringify(fields)} />
      {#each fields as field, index (field.id)}
        <fieldset class="rounded-xl border border-white/15 p-4 space-y-3"><legend class="px-2 text-sm">Pregunta {index + 1}</legend>
          <label class="block"><span class="ux-label">Pregunta para el paciente</span><input class="ux-input" required maxlength="120" bind:value={field.label} /></label>
          <div class="grid gap-3 sm:grid-cols-2">
            <label><span class="ux-label">Guardar en el perfil como</span><select class="ux-select" value={field.patientField} onchange={event => { field.patientField = event.currentTarget.value as BookingIntakeField['patientField']; if (field.patientField === 'age' || field.patientField === 'birth_date' || (field.patientField !== 'custom' && field.kind === 'boolean')) changeKind(index, 'text'); }}>{#each targets as target}<option value={target.value} disabled={target.value !== 'custom' && fields.some((other, n) => n !== index && other.patientField === target.value)}>{target.label}</option>{/each}</select></label>
            <label><span class="ux-label">Tipo de respuesta</span><select class="ux-select" value={field.kind} onchange={event => changeKind(index, event.currentTarget.value as BookingIntakeField['kind'])} disabled={field.patientField === 'age' || field.patientField === 'birth_date'}><option value="text">Respuesta corta</option><option value="textarea">Respuesta extensa</option><option value="choice">Lista de opciones</option>{#if field.patientField === 'custom'}<option value="boolean">Sí / No</option>{/if}</select></label>
          </div>
          {#if field.kind === 'choice'}<label class="block"><span class="ux-label">Opciones, una por línea</span><textarea class="ux-textarea" rows="3" required value={field.options?.join('\n') ?? ''} oninput={event => field.options = event.currentTarget.value.split('\n').map(value => value.trim()).filter(Boolean)}></textarea></label>{:else if field.kind === 'text' || field.kind === 'textarea'}<label class="block"><span class="ux-label">Máximo de caracteres</span><input class="ux-input" type="number" min="1" max="2000" required bind:value={field.maxLength} /></label>{/if}
          <label class="flex items-center gap-3"><input type="checkbox" bind:checked={field.required} />Exigir esta respuesta para reservar</label>
          <div class="flex flex-wrap gap-3"><button class="ux-btn-secondary" type="button" disabled={index === 0} onclick={() => { const previous = fields[index - 1]; fields[index - 1] = fields[index]; fields[index] = previous; }}>Subir pregunta</button><button class="ux-btn-secondary" type="button" onclick={() => fields = fields.filter((_, n) => n !== index)}>Quitar pregunta</button></div>
        </fieldset>
      {/each}
      {#if !fields.length}<p class="text-sm text-white/65">Todavía no pedís datos adicionales al reservar.</p>{/if}
      <div class="flex flex-wrap gap-3"><button class="ux-btn-secondary" type="button" disabled={!ready || fields.length >= 24} onclick={add}>Agregar dato</button><button class="ux-btn-primary" type="submit" disabled={!ready || saving}>{saving ? 'Guardando…' : 'Guardar preguntas'}</button></div>
    </form>
  {:else}<p>Primero configurá un perfil profesional en el consultorio.</p>{/if}
</section>
