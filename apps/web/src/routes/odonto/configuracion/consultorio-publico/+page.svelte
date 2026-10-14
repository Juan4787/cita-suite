<script lang="ts">
  import { enhance } from "$app/forms";
  import { beforeNavigate } from "$app/navigation";
  let { data, form } = $props();
  let saving = $state(false);
  let instructionsSaving = $state(false);
  let cleaning = $state(false);
  let settingsDirty = $state(false);
  let instructionsDirty = $state(false);
  const initialService = () => data.services[0]?.id ?? "";
  let serviceId = $state(initialService());
  const service = $derived(data.services.find((item) => item.id === serviceId));
  beforeNavigate(({ cancel }) => {
    if (
      (settingsDirty || instructionsDirty) &&
      !confirm("Tenés cambios sin guardar. ¿Querés salir y descartarlos?")
    )
      cancel();
  });
  function changeService(event: Event) {
    const select = event.currentTarget as HTMLSelectElement;
    if (
      instructionsDirty &&
      !confirm(
        "Tenés indicaciones sin guardar. ¿Querés descartarlas y cambiar de prestación?",
      )
    ) {
      select.value = serviceId;
      return;
    }
    serviceId = select.value;
    instructionsDirty = false;
  }
  const initialSettings = () => ({ ...data.settings });
  let settings = $state(initialSettings());
  const initialInstructions = () => data.services[0]?.patient_instructions ?? "";
  const initialDescription = () =>
    data.services[0]?.public_reminder_description ?? "";
  let instructions = $state(initialInstructions());
  let description = $state(initialDescription());
  const initialSettingsVersion = () => data.settings.updated_at;
  let settingsVersion = $state(initialSettingsVersion());
  const initialInstructionsKey = () =>
    serviceId + ":" + (data.services[0]?.updated_at ?? "");
  let instructionsKey = $state(initialInstructionsKey());
  $effect(() => {
    if (!settingsDirty && settingsVersion !== data.settings.updated_at) {
      settings = { ...data.settings };
      settingsVersion = data.settings.updated_at;
    }
  });
  $effect(() => {
    const nextKey = serviceId + ":" + (service?.updated_at ?? "");
    if (!instructionsDirty && instructionsKey !== nextKey) {
      instructions = service?.patient_instructions ?? "";
      description = service?.public_reminder_description ?? "";
      instructionsKey = nextKey;
    }
  });
  const mb = (bytes: number) =>
    new Intl.NumberFormat("es-AR", { maximumFractionDigits: 1 }).format(
      bytes / 1_000_000,
    );
</script>
<svelte:window onbeforeunload={event=>{if(settingsDirty||instructionsDirty){event.preventDefault();event.returnValue="";}}}/>
<svelte:head><title>Documentos y contacto · Cita Suite</title></svelte:head>
<main class="mx-auto max-w-4xl space-y-6 p-5">
 <a class="ux-btn-secondary inline-flex" href="/odonto/configuracion/reserva-online">Volver a reserva online</a><h1 class="ux-title">Documentos y contacto del consultorio</h1>
 {#if form?.message}<p class={form.saved?'ux-success':'ux-alert'} role={form.saved?'status':'alert'}>{form.message}</p>{/if}
 <section class="ux-card space-y-3"><h2 class="ux-section-title">Espacio para archivos</h2><p>{mb(Number(data.budget.used_bytes))} MB utilizados y {mb(Number(data.budget.reserved_bytes))} MB reservados para cargas pendientes, de {mb(Number(data.budget.max_bytes))} MB de presupuesto total.</p><progress class="w-full" max="100" value={Number(data.budget.percentage)} aria-label="Uso del presupuesto de archivos"></progress><p class="text-sm text-white/75">Descargas autorizadas del mes: {mb(Number(data.budget.monthly_authorized_download_bytes))} MB estimados. Una misma autorización puede usarse más de una vez; este valor no reemplaza el consumo informado por el proveedor.</p><p class="text-sm text-white/75">Base de datos: {mb(Number(data.budget.database_bytes))} MB. Este consumo se controla por separado del espacio para archivos.</p>
 {#if Number(data.budget.percentage)>=85}<p class="ux-alert">Queda poco espacio. Al agotarse el presupuesto se detendrán las cargas nuevas; las fichas y los documentos existentes se conservarán.</p>{:else if Number(data.budget.percentage)>=70}<p class="text-sm text-white/80">El almacenamiento se está acercando a su límite. Revisá el consumo antes de ampliar las cargas.</p>{/if}
 <p class="text-sm text-white/75">Cada archivo nuevo admite hasta 5 MB. Las imágenes y documentos de la papelera siguen ocupando espacio. La transferencia mensual y el espacio usado por otros proyectos de la cuenta se controlan por separado en el proveedor.</p></section>
 <form method="POST" action="?/cleanup" use:enhance={()=>{cleaning=true;return async({result,update})=>{try{await update({reset:false,invalidateAll:result.type==='success'});}finally{cleaning=false;}};}}><button disabled={cleaning||saving||instructionsSaving} class="ux-btn-secondary">{cleaning?'Revisando cargas…':'Limpiar cargas abandonadas'}</button><p class="mt-2 text-sm text-white/75">Sólo elimina archivos de cargas nunca confirmadas cuya autorización ya venció. Conserva estudios guardados y papelera.</p></form><form method="POST" action="?/save" class="ux-card space-y-5" oninput={()=>settingsDirty=true} use:enhance={()=>{saving=true;return async({result,update})=>{try{if(result.type==='success')settingsDirty=false;await update({reset:false,invalidateAll:result.type==='success'});}finally{saving=false;}};}}>
  <input type="hidden" name="settings_updated_at" value={data.settings.updated_at}/><fieldset disabled={saving||instructionsSaving||cleaning} class="space-y-5"><legend class="ux-section-title">Envíos de pacientes y contacto público</legend>
  <label class="flex min-h-11 items-start gap-3"><input type="checkbox" name="patient_documents_enabled" value="true" bind:checked={settings.patient_documents_enabled}/><span>Permitir que el paciente adjunte documentos desde el enlace de su turno. Hasta tres archivos y 10 MB en total por reserva.</span></label>
  <label class="flex min-h-11 items-start gap-3"><input type="checkbox" name="public_contact_enabled" value="true" bind:checked={settings.public_contact_enabled}/><span>Mostrar el contacto en la web vinculada incluso cuando la reserva online esté deshabilitada.</span></label>
  <label class="flex min-h-11 items-start gap-3"><input type="checkbox" name="whatsapp_contact_enabled" value="true" bind:checked={settings.whatsapp_contact_enabled}/><span>Habilitar el botón de contacto por WhatsApp con un número confirmado.</span></label>
  <label class="block"><span class="ux-label">Número de WhatsApp con código de país</span><input class="ux-input mt-2" type="tel" name="whatsapp_phone" bind:value={settings.whatsapp_phone} maxlength="30" autocomplete="tel"/></label>
  <label class="block"><span class="ux-label">Mensaje inicial de contacto (opcional)</span><textarea class="ux-textarea mt-2" name="whatsapp_message" maxlength="180" rows="2" bind:value={settings.whatsapp_message}></textarea><span class="mt-1 block text-sm text-white/75">Usá una consulta general, sin datos clínicos del paciente.</span></label>
  <button class="ux-btn-primary">{saving?'Guardando…':'Guardar configuración'}</button></fieldset>
 </form>
 <form method="POST" action="?/instructions" class="ux-card space-y-5" oninput={event=>{if((event.target as HTMLInputElement).name!=='service_id')instructionsDirty=true;}} use:enhance={()=>{instructionsSaving=true;return async({result,update})=>{try{if(result.type==='success')instructionsDirty=false;await update({reset:false,invalidateAll:result.type==='success'});}finally{instructionsSaving=false;}};}}><fieldset disabled={instructionsSaving||saving||cleaning} class="space-y-5"><h2 class="ux-section-title">Indicaciones y descripción del aviso</h2>
  <label class="block"><span class="ux-label">Prestación</span><select name="service_id" class="ux-input mt-2" value={serviceId} onchange={changeService}>{#each data.services as item}<option value={item.id}>{item.name}</option>{/each}</select></label>
  <input type="hidden" name="service_updated_at" value={service?.updated_at??''}/><label class="block"><span class="ux-label">Indicaciones para el paciente (opcional)</span><textarea class="ux-textarea mt-2" name="instructions" maxlength="2000" rows="4" bind:value={instructions}></textarea><span class="mt-1 block text-sm text-white/75">Se muestran en la página del turno. Cambiar este texto no modifica reservas anteriores.</span></label>
  <label class="block"><span class="ux-label">Descripción breve del recordatorio (opcional)</span><textarea class="ux-textarea mt-2" name="public_description" maxlength="180" rows="2" bind:value={description}></textarea><span class="mt-1 block text-sm text-white/75">Puede aparecer en la pantalla bloqueada del teléfono. No incluyas diagnósticos, medicación ni notas internas.</span></label>
  <button class="ux-btn-primary" disabled={!serviceId}>{instructionsSaving?'Guardando…':'Guardar indicaciones para nuevas reservas'}</button></fieldset>
 </form>
</main>
