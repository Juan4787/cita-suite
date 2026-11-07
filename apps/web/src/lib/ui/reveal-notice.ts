/** Takes the keyboard to the result of an action and shows it. Safari does not scroll to an element
 * focused by code, so on an iPhone the notice would stay above the screen and nothing would seem to happen. */
export function revealNotice(notice: HTMLElement | null | undefined) {
  if (!notice) return;
  notice.focus({ preventScroll: true });
  notice.scrollIntoView?.({ block: "center" });
}
