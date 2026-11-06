<script lang="ts">
	import type { LayoutProps } from './$types';

	import '../app.css';
	import { onMount } from 'svelte';
	import { installFieldValidation } from '$lib/ui/field-validation';

	let { children }: LayoutProps = $props();
	onMount(() => installFieldValidation());
</script>

<svelte:head>
	<title>Cita Suite</title>
	<link rel="icon" type="image/png" href="/logo-cita-suite.png" />
</svelte:head>

{@render children()}
