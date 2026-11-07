<script lang="ts">
	import type { Snippet } from 'svelte';

  import { createEventDispatcher } from "svelte";
  import { dialogFocus } from "$lib/ui/dialog-focus";

  // dismissible: cierra al click afuera / Escape. closable: muestra la X (cierre explícito) sin click-afuera.
  let {
    open = false,
    title = "",
    children,
    dismissible = false,
    closable = false,
  }: { open?: boolean; title?: string; children?: Snippet; dismissible?: boolean; closable?: boolean } = $props();

  const dispatch = createEventDispatcher<{ close: void }>();
  const close = () => dispatch("close");
</script>

{#if open}
  <div
    class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto px-3 pt-4 pb-32 backdrop-blur-sm bg-fill-black-60 sm:px-4 sm:py-10"
    role="presentation"
    onclick={(event) => {
      if (dismissible && event.target === event.currentTarget) {
        close();
      }
    }}
    onkeydown={(event: KeyboardEvent) => {
      if (event.key === "Escape") {
        if (dismissible) close();
      }
    }}
  >
    <div
      role="dialog"
      aria-modal="true"
      aria-label={title}
      tabindex="-1"
      use:dialogFocus
      class="flex max-h-[calc(100dvh-8rem)] w-full max-w-2xl flex-col overflow-hidden rounded-2xl shadow-card border border-line-strong bg-surface sm:max-h-[calc(100dvh-5rem)]"
    >
      <div
        class="flex shrink-0 items-center justify-between gap-3 border-b px-4 py-3 border-line-strong sm:px-6 sm:py-4"
      >
        <h3
          class="min-w-0 break-words text-lg font-semibold text-fg"
        >
          {title}
        </h3>
        {#if dismissible || closable}
          <button
            type="button"
            class="grid h-9 w-9 shrink-0 place-items-center rounded-full transition text-fg-n300 hover:bg-surface-2"
            onclick={close}
            aria-label="Cerrar"
          >
            <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18" /></svg>
          </button>
        {/if}
      </div>
      <div class="min-h-0 overflow-y-auto px-4 py-4 sm:px-6 sm:py-5">
        {@render children?.()}
      </div>
    </div>
  </div>
{/if}
