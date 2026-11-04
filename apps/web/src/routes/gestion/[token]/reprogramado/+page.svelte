<script lang="ts">
 import RescheduleNoticePage from '$lib/components/appointments/RescheduleNoticePage.svelte';
 import type { PageData } from './$types';
 let { data }: { data: PageData } = $props();
</script>
<RescheduleNoticePage {data} />
