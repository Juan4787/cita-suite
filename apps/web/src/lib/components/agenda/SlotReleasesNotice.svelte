<script lang="ts">
	import DismissibleNotice from '$lib/components/notices/DismissibleNotice.svelte';
	import { SLOT_RELEASE_REASONS, slotReleaseHref, type SlotReleaseNotice } from '$lib/scheduling/slot-releases';
	import { formatInTimeZone } from '$lib/utils/format';

	// The same pattern as Seguimientos: an internal notice on top of every page, closed per browser
	// until the set of released slots changes. It reads what the agenda lists, never its own copy.
	let { notice, timezone, storageKeyPrefix }: {
		notice: SlotReleaseNotice;
		timezone: string;
		storageKeyPrefix: string;
	} = $props();

	const storageKey = $derived(`${storageKeyPrefix}:slot-releases:${notice.dismissalKey}`);
	const single = $derived(notice.single);
</script>

{#if single}
	<DismissibleNotice
		{storageKey}
		title="Se liberó un horario"
		message={`${single.professionalName}: ${formatInTimeZone(single.startsAt, timezone).full}. ${SLOT_RELEASE_REASONS[single.reason]}.`}
		tone="info"
	>
		<div class="mt-3 flex flex-wrap gap-2" data-slot-release-notice>
			<!-- A fresh page resets the wizard, as in the agenda list. -->
			<a href={slotReleaseHref(single, timezone)} data-sveltekit-reload class="ux-btn-primary">Dar este horario</a>
			<a href="/odonto/agenda#horarios-liberados" class="ux-btn-secondary">Ver en la agenda</a>
		</div>
	</DismissibleNotice>
{:else if notice.count > 0}
	<DismissibleNotice
		{storageKey}
		title={notice.truncated ? `Se liberaron más de ${notice.count} horarios` : `Se liberaron ${notice.count} horarios`}
		tone="info"
	>
		<div class="mt-3" data-slot-release-notice>
			<a href="/odonto/agenda#horarios-liberados" class="ux-btn-primary">Ver horarios</a>
		</div>
	</DismissibleNotice>
{/if}
