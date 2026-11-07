import { afterEach, expect, it } from "vitest";
import { dialogFocus } from "./dialog-focus";

afterEach(() => document.body.replaceChildren());

const dialog = () => {
  const opener = document.createElement("button");
  const node = document.createElement("div");
  node.tabIndex = -1;
  node.innerHTML = `<button id="first">Cerrar</button><input type="hidden" /><a id="last" href="/agenda">Agenda</a>`;
  document.body.append(opener, node);
  // jsdom lays nothing out: every control counts as rendered here.
  for (const element of node.querySelectorAll<HTMLElement>("*"))
    element.getClientRects = () => [new DOMRect(0, 0, 10, 10)] as unknown as DOMRectList;
  opener.focus();
  return { opener, node, first: node.querySelector<HTMLElement>("#first")!, last: node.querySelector<HTMLElement>("#last")! };
};
const tab = (node: HTMLElement, shiftKey = false) => {
  const event = new KeyboardEvent("keydown", { key: "Tab", shiftKey, bubbles: true, cancelable: true });
  node.dispatchEvent(event);
  return event;
};

it("moves the focus into the dialog as soon as it opens", async () => {
  const { node, first } = dialog();
  dialogFocus(node);
  await Promise.resolve();
  expect(document.activeElement).toBe(first);
});

it("keeps Tab inside the dialog, in both directions", async () => {
  const { node, first, last } = dialog();
  dialogFocus(node);
  await Promise.resolve();
  expect(tab(node, true).defaultPrevented).toBe(true);
  expect(document.activeElement).toBe(last);
  expect(tab(node).defaultPrevented).toBe(true);
  expect(document.activeElement).toBe(first);
  // Between the ends the browser moves the focus by itself.
  expect(tab(node).defaultPrevented).toBe(false);
});

it("gives the focus back to the control that opened it", async () => {
  const { opener, node } = dialog();
  const action = dialogFocus(node);
  await Promise.resolve();
  action.destroy();
  expect(document.activeElement).toBe(opener);
});
