<script lang="ts">
  import ProfessionalBookingFormEditor from '$lib/booking/ProfessionalBookingFormEditor.svelte';
  import { enhance } from '$app/forms';
  import { page } from '$app/stores';
  import type { BookingIntakeField, BookingModalityWindow } from '@turnos-saas/shared/booking-integration';
  let { data, form } = $props();
  const profile = $derived(data.profiles.find((item: any) => item.id === data.selectedId));
  let fields = $state<BookingIntakeField[]>([]);
  let windows = $state<BookingModalityWindow[]>([]);
  let copying = $state('');
  $effect(() => { fields = structuredClone(profile?.intake_schema ?? []); windows = structuredClone(profile?.modality_windows ?? []); });
  async function copyLink() {
    try { await navigator.clipboard.writeText(`${data.baseURL}/embed/v1/${profile.public_key}`); copying = 'Enlace copiado'; }
    catch { copying = 'Seleccioná el enlace para copiarlo.'; }
  }
</script>

<section class="space-y-6">
  <div><h1 class="ux-title">Reserva online</h1>{#if data.canManage}<a class="ux-btn-secondary mt-4 inline-flex" href="/odonto/configuracion/consultorio-publico">Configurar documentos, indicaciones y contacto</a>{/if}<div class="mt-4 flex flex-wrap gap-3">{#each data.professionals as professional}<a class="ux-btn-secondary" href={`/odonto/profesionales/${professional.id}/aranceles`}>Aranceles de {professional.name}</a>{/each}</div><p class="mt-2 text-white/65">Elegí qué puede reservar cada paciente y qué información puede compartir antes de la consulta.</p></div>
  {#if !data.enabled}
    <div class="ux-soft-card p-6"><p>Este módulo todavía no está habilitado. Las reservas actuales conservan su funcionamiento.</p></div>
  {:else}
    <ProfessionalBookingFormEditor professionals={data.professionals} configurations={data.forms} />
    {#if form?.message}<p role={form.formSaved ? 'status' : 'alert'} class={form.formSaved ? 'ux-success' : 'ux-error'}>{form.message}</p>{/if}
    {#if data.canManage}
    <nav class="flex flex-wrap gap-3" aria-label="Enlaces de reserva">
      <a class="ux-btn-secondary" href="?nuevo=1">Crear enlace</a>
      {#each data.profiles as item (item.id)}<a class={item.id === profile?.id ? 'ux-btn-primary' : 'ux-btn-secondary'} href={`?perfil=${item.id}`}>{item.name}{item.is_active ? '' : ' · Borrador'}</a>{/each}
    </nav>
    {#if $page.url.searchParams.get('guardado') === '1'}<p role="status" class="ux-success">La configuración quedó guardada.</p>{/if}
    {#if profile}
      <div class="ux-soft-card p-5"><label class="block"><span class="ux-label">Enlace individual</span><input class="ux-input" readonly value={`${data.baseURL}/embed/v1/${profile.public_key}`} /></label><button type="button" class="ux-btn-secondary mt-3" onclick={copyLink}>Copiar enlace</button><span role="status" class="ml-3 text-sm">{copying}</span></div>
    {/if}
    {#key profile?.id ?? 'new'}
    <form method="POST" action="?/save" use:enhance class="ux-soft-card space-y-6 p-6">
      <input type="hidden" name="id" value={profile?.id ?? ''} /><input type="hidden" name="revision" value={profile?.revision ?? ''} />
      <input type="hidden" name="intake_schema" value={JSON.stringify(fields)} />
      <input type="hidden" name="modality_windows" value={JSON.stringify(windows)} />
      <div class="grid gap-4 sm:grid-cols-2">
        <label><span class="ux-label">Nombre del enlace</span><input name="name" required maxlength="120" class="ux-input" value={profile?.name ?? ''} placeholder="Ejemplo: Agenda de una profesional" /></label>
        <label><span class="ux-label">Apariencia</span><select name="theme" class="ux-select" value={profile?.theme ?? 'cita-suite'}><option value="cita-suite">Cita Suite</option><option value="natalia">Web Natalia</option></select></label>
      </div>
      <fieldset><legend class="ux-section-title">Profesionales de este enlace</legend><p class="mt-2 text-sm text-white/60">Seleccioná una profesional para su enlace individual. Los horarios se administran desde su perfil.</p><div class="mt-3 grid gap-2 sm:grid-cols-2">{#each data.professionals as person (person.id)}<label class="flex items-center gap-3"><input type="checkbox" name="professional_ids" value={person.id} checked={profile?.allowed_professional_ids?.includes(person.id)} />{person.name}{!person.is_active || !person.is_public ? ' · No disponible públicamente' : ''}</label>{/each}</div></fieldset>
      <fieldset><legend class="ux-section-title">Prestaciones disponibles</legend><div class="mt-3 grid gap-2 sm:grid-cols-2">{#each data.services as service (service.id)}<label class="flex items-center gap-3"><input type="checkbox" name="service_ids" value={service.id} checked={profile?.allowed_service_ids?.includes(service.id)} /><span>{service.name} · {service.duration_minutes} minutos{service.price_label ? ` · ${service.price_label}` : ''}{!service.is_active || !service.is_public ? ' · No disponible públicamente' : ''}</span></label>{/each}</div></fieldset>
      <label class="block"><span class="ux-label">Sitios que pueden mostrar este turnero</span><textarea name="origins" class="ux-textarea" rows="3" placeholder="Un dominio completo por línea, por ejemplo https://mi-consultorio.com" value={profile?.allowed_origins?.join('\n') ?? ''}></textarea></label>
      <fieldset class="space-y-3"><legend class="ux-section-title">Modalidad</legend><p>La atención presencial está disponible en este perfil.</p><label class="flex items-center gap-3"><input type="checkbox" name="video" value="true" checked={profile?.allowed_modalities?.includes('video')} />Ofrecer también atención virtual</label><label class="block"><span class="ux-label">Indicaciones de acceso para la consulta virtual</span><textarea name="video_instructions" rows="2" maxlength="1000" class="ux-textarea" value={profile?.video_instructions ?? ''}></textarea></label></fieldset>
      <fieldset class="space-y-3"><legend class="ux-section-title">Franjas por modalidad (opcional)</legend><p class="text-sm text-white/60">Limitan los horarios existentes; no reemplazan la agenda de cada profesional.</p>
        {#each windows as window, index}
          <div class="grid gap-2 sm:grid-cols-5"><label><span class="ux-label">Modalidad</span><select class="ux-select" bind:value={window.modality}><option value="in_person">Presencial</option><option value="video">Virtual</option></select></label><label><span class="ux-label">Día</span><select class="ux-select" bind:value={window.weekday}>{#each ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'] as day, n}<option value={n}>{day}</option>{/each}</select></label><label><span class="ux-label">Desde</span><input type="time" class="ux-input" bind:value={window.startTime} /></label><label><span class="ux-label">Hasta</span><input type="time" class="ux-input" bind:value={window.endTime} /></label><button type="button" class="ux-btn-secondary self-end" onclick={() => windows = windows.filter((_, n) => n !== index)}>Quitar franja</button></div>
        {/each}
        <button type="button" class="ux-btn-secondary" onclick={() => windows = [...windows, { modality: 'in_person', weekday: 1, startTime: '09:00', endTime: '12:00' }]}>Agregar franja</button>
      </fieldset>
      {#if fields.length}<section class="space-y-3"><h2 class="ux-section-title">Preguntas existentes de este enlace</h2><p class="text-sm text-white/60">Se conservan por compatibilidad. Configurá los nuevos datos y su guardado en el perfil en “Datos que pedís al reservar”, arriba.</p><ul class="space-y-2">{#each fields as field}<li>{field.label}{field.required ? ' · Obligatoria' : ' · Opcional'}</li>{/each}</ul></section>{/if}
      <div class="space-y-3"><label class="flex items-center gap-3"><input type="checkbox" name="default" value="true" checked={profile?.is_default} />Usar estas opciones también en el enlace general del consultorio</label><p class="text-sm text-white/60">Sólo un perfil puede ser el general. Para dos agendas individuales, conservá un alcance general que incluya a ambas profesionales.</p><label class="flex items-center gap-3"><input type="checkbox" name="active" value="true" checked={profile?.is_active} />Habilitar nuevas reservas desde este enlace</label></div>
      <button class="ux-btn-primary" type="submit">Guardar configuración</button>
    </form>
    {/key}
    {/if}
  {/if}
</section>
