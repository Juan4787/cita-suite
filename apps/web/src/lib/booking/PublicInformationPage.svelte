<script lang="ts">
	import type { PublicInformationPageData, PublicInformationFeedback } from '$lib/patients/public-booking-information';

  import PatientDocumentUpload from "$lib/booking/PatientDocumentUpload.svelte";
  import BookingAppearance from "$lib/booking/BookingAppearance.svelte";
  import { enhance } from "$app/forms";
  let { data, form }: { data: PublicInformationPageData; form?: PublicInformationFeedback | null } = $props();
  let busy = $state(false);
  const initialAnswers = () =>
    Object.fromEntries(
      data.info.schema.map((field: { id: string }) => [
        field.id,
        String((form?.submitted?.answers ?? data.info.answers)[field.id] ?? ""),
      ]),
    );
  let answers = $state<Record<string, string>>(initialAnswers());
  const initialComment = () => form?.submitted?.comment ?? data.info.comment;
  let comment = $state(initialComment());
  const infoKey = () =>
    data.token + ":" + data.info.version + ":" + data.info.schema_hash;
  let appliedInfoKey = $state(infoKey());
  $effect(() => {
    const nextKey = infoKey();
    if (nextKey !== appliedInfoKey) {
      answers = Object.fromEntries(
        data.info.schema.map((field: { id: string }) => [
          field.id,
          String((form?.submitted?.answers ?? data.info.answers)[field.id] ?? ""),
        ]),
      );
      comment = initialComment();
      appliedInfoKey = nextKey;
    }
  });
</script>

<BookingAppearance theme={data.info.theme}>
<main class="mx-auto max-w-2xl space-y-6 px-5 py-8">
  <a class="ux-btn-secondary" href={data.managementUrl}>Volver a mi turno</a>
  <div><h1 class="ux-title">Información para tu consulta</h1><p class="mt-3 text-fg-65 bk-muted">Tu turno ya está reservado. Podés ampliar los datos para la profesional. Los campos configurados se guardan automáticamente en tu perfil y los envíos anteriores se conservan.</p></div>
  {#if form?.message}<p class={form.saved ? 'ux-success' : 'ux-error'} role={form.saved ? 'status' : 'alert'}>{form.message}</p>{/if}
  <form method="POST" action="?/save" use:enhance={() => { busy = true; return async ({ update,result }) => { try{await update({ reset: false,invalidateAll:result.type==='success' });}finally{busy = false;} }; }} class="ux-soft-card space-y-4 p-5">
    <fieldset disabled={busy} class="space-y-4">
    <input type="hidden" name="request_key" value={form?.submitted?.requestKey ?? data.requestKey} /><input type="hidden" name="schema_hash" value={form?.submitted?.schemaHash ?? data.info.schema_hash} /><input type="hidden" name="version" value={form?.submitted?.version ?? data.info.version} />
    {#each data.info.schema as field (field.id)}
      <label class="block"><span class="ux-label">{field.label}{field.required ? ' *' : ' (opcional)'}</span>
        {#if field.kind === 'textarea'}<textarea class="ux-textarea" name={'intake_' + field.id} required={field.required} maxlength={field.maxLength} rows="3" bind:value={answers[field.id]}></textarea>
        {:else if field.kind === 'text'}<input type={field.patientField === 'birth_date' ? 'date' : field.patientField === 'age' ? 'number' : 'text'} min={field.patientField === 'age' ? 0 : undefined} max={field.patientField === 'age' ? 130 : undefined} class="ux-input" name={'intake_' + field.id} required={field.required} maxlength={field.maxLength} bind:value={answers[field.id]} />
        {:else}<select class="ux-select" required={field.required} name={'intake_' + field.id} bind:value={answers[field.id]}><option value="">Sin responder</option>{#if field.kind === 'boolean'}<option value="true">Sí</option><option value="false">No</option>{:else}{#each field.options ?? [] as option}<option value={option}>{option}</option>{/each}{/if}</select>{/if}
        {#if field.help}<span class="mt-1 block text-sm text-fg-60 bk-muted">{field.help}</span>{/if}
      </label>
    {/each}
    <label class="block"><span class="ux-label">Comentario adicional (opcional)</span><textarea class="ux-textarea" name="comment" maxlength="2000" rows="3" bind:value={comment}></textarea></label>
    <p class="text-sm text-fg-60 bk-muted">Los datos quedan privados para el equipo clínico. Tu reserva se conserva si un envío falla.</p>
    <button class="ux-btn-primary" disabled={busy} type="submit">{busy ? 'Guardando…' : 'Guardar información'}</button>
    </fieldset>
  </form>
  {#if data.info.documents_enabled}<PatientDocumentUpload endpoint={data.documentsUrl}/>{/if}
</main>
</BookingAppearance>
