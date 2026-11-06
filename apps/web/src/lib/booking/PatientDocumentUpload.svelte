<script lang="ts">
  import {
    validateClinicalImageFile,
    sha256File,
    uploadClinicalFileWithProgress,
  } from "$lib/client/clinical-files";
  let { endpoint }: { endpoint: string } = $props();
  let files = $state<FileList | null>(null);
  let selected = $derived(files?.[0] ?? null);
  let note = $state("");
  let busy = $state(false);
  let progress = $state(0);
  let message = $state("");
  let failed = $state(false);
  let requestId = "";
  let pendingId = $state("");
  let uploaded = $state(false);
  let picker: HTMLInputElement | undefined;
  async function post(path: string, body?: unknown) {
    let response: Response;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15_000);
    try {
      response = await fetch(path, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: body ? JSON.stringify(body) : "{}",
        signal: controller.signal,
      });
    } catch {
      throw new Error(
        "La conexión se interrumpió. Tu turno se conserva; podés volver a intentar.",
      );
    } finally {
      clearTimeout(timeout);
    }
    const data = await response.json().catch(() => ({}));
    if (!response.ok)
      throw new Error(
        data.message || "No pudimos completar la carga. Probá nuevamente.",
      );
    return data;
  }

  async function upload(event: SubmitEvent) {
    event.preventDefault();
    if (!selected || busy) return;
    busy = true;
    failed = false;
    message = "";
    try {
      if (pendingId && !uploaded) {
        try {
          await post(`${endpoint}/${pendingId}/complete`);
          uploaded = true;
        } catch {
          pendingId = "";
        }
      }
      if (!pendingId) {
        const validation = await validateClinicalImageFile(selected);
        if (!validation.ok) throw new Error(validation.message);
        requestId ||= crypto.randomUUID();
        const started = await post(endpoint, {
          requestId,
          filename: selected.name,
          mime: validation.mimeType,
          bytes: selected.size,
          sha256: await sha256File(selected),
          note,
        });
        pendingId = started.id;
        if (started.already_complete || started.object_present) uploaded = true;
        else {
          await uploadClinicalFileWithProgress({
            url: started.upload_url,
            file: selected,
            onProgress: (value) => (progress = Math.round(value)),
          });
          uploaded = true;
        }
      }
      if (!uploaded) {
        pendingId = "";
        throw new Error(
          "La subida se interrumpió. Volvé a elegir el archivo y probá nuevamente.",
        );
      }
      await post(`${endpoint}/${pendingId}/complete`);
      message = "El documento quedó guardado en tu ficha para la profesional.";
      files = null;
      if (picker) picker.value = "";
      pendingId = "";
      requestId = "";
      uploaded = false;
      progress = 0;
      note = "";
    } catch (cause) {
      failed = true;
      message =
        cause instanceof Error
          ? cause.message
          : "No pudimos guardar el documento. Tu turno se conserva.";
    } finally {
      busy = false;
    }
  }
</script>
<section class="ux-soft-card space-y-4 p-5" aria-labelledby="patient-documents-title">
 <h2 id="patient-documents-title" class="ux-section-title">Documentos para tu consulta</h2>
 <p class="text-sm text-fg-75 bk-muted">Podés adjuntar JPG, PNG o PDF de hasta 5 MB. Para este turno se admiten hasta tres documentos y 10 MB en total.</p>
 <form onsubmit={upload} class="space-y-4"><fieldset disabled={busy} class="space-y-4">
  <label class="block"><span class="ux-label">Documento</span><input bind:this={picker} bind:files type="file" accept="image/jpeg,image/png,application/pdf" class="sr-only" required onchange={()=>{requestId='';pendingId='';uploaded=false;progress=0;message='';}}/><span class="ux-file-picker"><span class="ux-btn-secondary shrink-0">Elegir archivo</span><span class="min-w-0 text-sm text-fg-70 bk-muted">{selected?.name ?? 'Todavía no elegiste un archivo'}</span></span></label>
  <label class="block"><span class="ux-label">Descripción (opcional)</span><input class="ux-input mt-2" maxlength="500" disabled={Boolean(pendingId)} bind:value={note}/></label>
  <button class="ux-btn-primary" disabled={!selected}>{busy?'Guardando documento…':uploaded?'Reintentar confirmación':'Adjuntar documento'}</button>
 </fieldset></form>
 {#if busy}<progress max="100" value={progress} class="w-full" aria-label="Progreso de carga"></progress>{/if}
 {#if message}<p role={failed?'alert':'status'} class={failed?'ux-alert':'ux-alert ux-alert-success'}>{message}</p>{/if}
 <p class="text-sm text-fg-70 bk-muted">Los archivos quedan privados para el equipo clínico. Tu reserva se conserva si una carga falla.</p>
 <noscript><p>Para adjuntar archivos, activá JavaScript o contactá al consultorio. Podés guardar los datos del formulario sin adjuntar documentos.</p></noscript>
</section>
