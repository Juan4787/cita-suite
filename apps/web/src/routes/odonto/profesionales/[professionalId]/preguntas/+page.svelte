<script lang="ts">
	import type { PageProps } from './$types';

  import ProfessionalBookingFormEditor from "$lib/booking/ProfessionalBookingFormEditor.svelte";
  import BackLink from "$lib/components/BackLink.svelte";
  let { data, form }: PageProps = $props();
</script>

<svelte:head
  ><title>Preguntas de {data.professional.name} · Cita Suite</title
  ></svelte:head
>
<section class="ux-page">
  <div class="ux-hero">
    <BackLink
      href={data.canManage ? "/odonto/configuracion/usuarios" : "/odonto/mis-turnos"}
      label={data.canManage ? "Volver" : "Mis turnos"}
      class="mb-5"
    />
    <h1 class="ux-title">{data.professional.name}</h1>
    <p class="ux-subtitle">Definí qué atiende y cuándo.</p>
  </div>
  {#if data.canManage}<nav aria-label="Configuración del profesional" class="ux-card p-2">
      <div class="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
        {#each [{ id: "perfil", label: "Perfil" }, { id: "servicios", label: "Servicios y aranceles" }, { id: "horarios", label: "Horarios" }] as tab}<a
            class="ux-profile-tab text-center"
            href={`/odonto/profesionales/${data.professional.id}?tab=${tab.id}`}
            >{tab.label}</a
          >{/each}<span class="ux-profile-tab ux-profile-tab-active text-center" aria-current="page">Preguntas al paciente</span>
      </div>
    </nav>{/if}
  {#if form?.message}<p
      class={form.formSaved ? "ux-alert ux-alert-success" : "ux-alert"}
      role={form.formSaved ? "status" : "alert"}
    >
      {form.message}
    </p>{/if}
  <section class="ux-card">
    {#if data.enabled}<ProfessionalBookingFormEditor
        professional={data.professional}
        configuration={data.configuration}
      />{:else}<p class="ux-empty">
        Las preguntas de reserva todavía no están habilitadas.
      </p>{/if}
  </section>
</section>
