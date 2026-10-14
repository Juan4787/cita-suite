type BookingWidget = { open(): void; setTheme(theme: 'light' | 'dark'): void };
declare global { interface Window { CitaSuiteBooking?: { mount(options: { integrationKey: string; baseURL: string; theme: 'light' | 'dark' }): BookingWidget } } }
const themeButton = document.querySelector<HTMLButtonElement>('#theme-toggle');
let widget: BookingWidget | undefined;
const theme = () => document.documentElement.classList.contains('dark') ? 'dark' : 'light';
themeButton?.addEventListener('click', () => {
  document.documentElement.classList.toggle('dark');
  try { localStorage.setItem('nf_theme', theme()); } catch { /* The theme still works without storage. */ }
  widget?.setTheme(theme());
});
const menuButton = document.querySelector<HTMLButtonElement>('#menu-toggle');
const menu = document.querySelector<HTMLElement>('#mobile-menu');
function closeMenu() { if (menu) menu.hidden = true; menuButton?.setAttribute('aria-expanded', 'false'); menuButton?.setAttribute('aria-label', 'Abrir menú'); }
menuButton?.addEventListener('click', () => { if (!menu) return; menu.hidden = !menu.hidden; menuButton.setAttribute('aria-expanded', String(!menu.hidden)); menuButton.setAttribute('aria-label', menu.hidden ? 'Abrir menú' : 'Cerrar menú'); });
menu?.addEventListener('click', event => { if ((event.target as HTMLElement).closest('a')) closeMenu(); });
document.addEventListener('keydown', event => { if (event.key === 'Escape' && menu && !menu.hidden) { closeMenu(); menuButton?.focus(); } });

const base = document.body.dataset.bookingBase!;
const integrationKey = document.body.dataset.bookingKey;
let sdk: Promise<BookingWidget> | undefined;
function getWidget() {
  if (!sdk) sdk = new Promise<void>((resolve, reject) => {
    const script = document.createElement('script'); script.src = base + '/booking/embed-v1.js'; script.async = true;
    const timeout = setTimeout(() => { script.remove(); reject(new Error('El turnero no respondió.')); }, 10000);
    script.onload = () => { clearTimeout(timeout); resolve(); }; script.onerror = () => { clearTimeout(timeout); reject(new Error('No se pudo abrir el turnero.')); }; document.head.append(script);
  }).then(() => {
    if (!window.CitaSuiteBooking || !integrationKey) throw new Error('La reserva todavía no está habilitada.');
    widget = window.CitaSuiteBooking.mount({ baseURL: base, integrationKey, theme: theme() }); return widget;
  }).catch(cause => { sdk = undefined; throw cause; });
  return sdk;
}
if (integrationKey) document.addEventListener('click', async event => {
  const anchor = (event.target as HTMLElement).closest<HTMLAnchorElement>('a[data-booking]');
  if (!anchor || event instanceof MouseEvent && (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey)) return;
  event.preventDefault(); closeMenu(); anchor.setAttribute('aria-busy', 'true');
  try { (await getWidget()).open(); }
  catch { window.location.assign(anchor.href); }
  finally { anchor.removeAttribute('aria-busy'); }
});

const catalogue = document.querySelector<HTMLElement>('#public-catalogue');
async function loadCatalogue() {
  try {
    const response = await fetch(`${base}/api/public/reservas/${integrationKey}/catalogo`, { signal: AbortSignal.timeout(8000), credentials: 'omit' });
    if (!response.ok) return;
    const data = await response.json();
    if (!Array.isArray(data.services) || !data.services.length) return;
    const list = document.createElement('div'); list.className = 'services-commercial-grid';
    for (const service of data.services.slice(0, 30)) {
      const article = document.createElement('article'); article.className = 'service-commercial-card';
      const title = document.createElement('h3'); title.textContent = String(service.name);
      const detail = document.createElement('p'); detail.textContent = `${service.duration_minutes} minutos${service.price_label ? ' · ' + service.price_label : ''}`;
      const link = document.createElement('a'); link.className = 'btn btn-secondary'; link.href = `${base}/embed/v1/${integrationKey}`; link.dataset.booking = ''; link.textContent = 'Reservar consulta';
      article.append(title, detail, link); list.append(article);
    }
    catalogue!.replaceChildren(list);
    const contact = document.querySelector<HTMLElement>('#public-contact');
    if (contact && typeof data.contact?.address === 'string') { const address = document.createElement('p'); address.textContent = data.contact.address; contact.append(address); }
  } catch { /* Editorial content and the direct booking link remain available. */ }
}
if (catalogue && integrationKey) {
  if ('IntersectionObserver' in window) { const observer = new IntersectionObserver(entries => { if (entries.some(entry => entry.isIntersecting)) { observer.disconnect(); void loadCatalogue(); } }, { rootMargin: '120px' }); observer.observe(catalogue); }
  else void loadCatalogue();
}
export {};
