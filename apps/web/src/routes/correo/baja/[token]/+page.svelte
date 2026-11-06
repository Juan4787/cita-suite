<script lang="ts">
 import { enhance } from '$app/forms';
 import type { ActionData, PageData } from './$types';
 let { data, form }: { data: PageData; form?: ActionData } = $props();
 let saving = $state(false);
 const finished = $derived(form?.done === true || (data.available && data.unsubscribed));
 const businessName = $derived(form?.businessName ?? (data.available ? data.businessName : ''));
</script>

<svelte:head><title>Correos del consultorio</title></svelte:head>
<main class="min-h-screen bg-canvas px-4 py-10 text-copy">
 <section class="ux-card mx-auto w-full max-w-xl">
  {#if !data.available}
   <h1 class="ux-section-title">Este enlace no está disponible</h1>
   <p class="mt-3 text-fg-70">{data.unavailableReason === 'error' ? 'No pudimos abrirlo en este momento. Volvé a intentar en unos minutos.' : 'Puede haber vencido. Para dejar de recibir correos, respondé uno de los mensajes del consultorio.'}</p>
  {:else if finished}
   <h1 class="ux-section-title">Listo</h1>
   <p class="mt-3 text-fg-70" role="status">No vas a recibir más correos de {businessName} en esta dirección. Tus turnos no cambian.</p>
   <p class="mt-3 text-sm text-fg-65">Si querés volver a recibirlos, pedíselo al consultorio.</p>
  {:else}
   <h1 class="ux-section-title">¿Dejar de recibir estos correos?</h1>
   <p class="mt-3 text-fg-70">No vas a recibir comprobantes ni recordatorios por correo de {businessName} en esta dirección. Tus turnos no cambian.</p>
   {#if form?.message}<p class="ux-alert mt-4" role="alert">{form.message}</p>{/if}
   <form method="POST" class="mt-5" use:enhance={() => { saving = true; return async ({ update }) => { try { await update({ reset: false }); } finally { saving = false; } }; }}>
    <button class="ux-btn-primary" disabled={saving}>{saving ? 'Guardando…' : 'Sí, dejar de recibirlos'}</button>
   </form>
  {/if}
 </section>
</main>
