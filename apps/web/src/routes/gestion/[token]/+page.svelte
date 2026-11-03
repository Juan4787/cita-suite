<script lang="ts">
 import PublicAppointmentPage from '$lib/components/appointments/PublicAppointmentPage.svelte';
 import type { ComponentProps } from 'svelte';
 let { data, form }: ComponentProps<typeof PublicAppointmentPage> = $props();
</script>
<PublicAppointmentPage {data} {form} />
