<script lang="ts">
 import PricePolicyEditor from '$lib/booking/PricePolicyEditor.svelte';
 let {data,form}=$props();
</script>
<svelte:head><title>Aranceles · Cita Suite</title></svelte:head>
<main class="mx-auto max-w-4xl space-y-5 p-5">
 <a class="ux-btn-secondary inline-flex" href="/odonto/configuracion/reserva-online">Volver a configuración de reservas</a>
 <h1 class="ux-title">Aranceles de {data.professional.name}</h1>
 {#if form?.message}<p class={form.saved?'ux-success':'ux-alert'} role={form.saved?'status':'alert'}>{form.message}</p>{/if}
 {#if !data.canEdit}<p class="ux-alert">La edición de aranceles todavía no está habilitada para tu consultorio.</p>{/if}
 <PricePolicyEditor services={data.services} policies={data.policies} professionalId={data.professional.id} currentMonth={data.currentMonth} canEdit={data.canEdit} canConfigureShared={data.canConfigureShared}/>
</main>
