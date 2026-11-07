/** `isMobile` does not exist in Firefox: there the viewport and the touch screen stand for a phone. */
export const mobileOptions = (browserName: string) => (browserName === 'firefox' ? {} : { isMobile: true });
