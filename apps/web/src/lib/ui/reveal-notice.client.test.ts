import { afterEach, expect, it, vi } from "vitest";
import { revealNotice } from "./reveal-notice";

afterEach(() => document.body.replaceChildren());

it("focuses the notice and scrolls to it by itself, without relying on the browser", () => {
  const notice = document.createElement("p");
  notice.tabIndex = -1;
  document.body.append(notice);
  const focus = vi.spyOn(notice, "focus");
  notice.scrollIntoView = vi.fn();
  revealNotice(notice);
  expect(document.activeElement).toBe(notice);
  expect(focus).toHaveBeenCalledWith({ preventScroll: true });
  expect(notice.scrollIntoView).toHaveBeenCalledWith({ block: "center" });
});

it("does nothing while the notice is not on the page", () => {
  expect(() => revealNotice(null)).not.toThrow();
  expect(() => revealNotice(undefined)).not.toThrow();
});
