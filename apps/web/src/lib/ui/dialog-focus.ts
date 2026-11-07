/** Keeps the keyboard inside an open dialog: focus enters on opening, Tab cycles inside and the opener gets it back. */
export function dialogFocus(node: HTMLElement) {
  const previous = document.activeElement as HTMLElement | null;
  const controls = () =>
    [
      ...node.querySelectorAll<HTMLElement>(
        'input:not([type="hidden"]),select,textarea,button,a[href],[tabindex="0"]',
      ),
    ].filter(
      (element) =>
        !element.matches(':disabled,[aria-hidden="true"]') &&
        element.getClientRects().length > 0,
    );
  queueMicrotask(() =>
    (
      node.querySelector<HTMLElement>("[autofocus]") ??
      controls()[0] ??
      node
    ).focus(),
  );
  const trap = (event: KeyboardEvent) => {
    if (event.key !== "Tab") return;
    const elements = controls();
    if (!elements.length) {
      event.preventDefault();
      node.focus();
      return;
    }
    const first = elements[0],
      last = elements.at(-1)!;
    if (
      event.shiftKey &&
      (document.activeElement === first || document.activeElement === node)
    ) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  };
  node.addEventListener("keydown", trap);
  return {
    destroy() {
      node.removeEventListener("keydown", trap);
      if (previous?.isConnected) previous.focus();
    },
  };
}
