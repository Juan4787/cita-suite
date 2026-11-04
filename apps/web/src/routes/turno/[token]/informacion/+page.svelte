<script lang="ts">
 import type { PageProps } from './$types';
 import PublicInformationPage from '$lib/booking/PublicInformationPage.svelte';
 let { data, form }: PageProps = $props();
</script>
<PublicInformationPage {data} {form} />
