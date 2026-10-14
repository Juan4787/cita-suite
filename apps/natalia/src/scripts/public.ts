type BookingWidget = { open(): void; setTheme(theme: 'light' | 'dark'): void };
declare global { interface Window { CitaSuiteBooking?: { mount(options: { integrationKey: string; baseURL: string; theme: 'light' | 'dark'; container?: HTMLElement; mode?: 'inline' }): BookingWidget } } }
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
function closeMenu() { if (menu) { menu.hidden = true; menu.classList.remove('is-open'); } document.body.classList.remove('menu-open'); menuButton?.setAttribute('aria-expanded', 'false'); menuButton?.setAttribute('aria-label', 'Abrir menú'); }
menuButton?.addEventListener('click', () => { if (!menu) return; if (!menu.hidden) { closeMenu(); return; } menu.hidden = false; menu.classList.add('is-open'); document.body.classList.add('menu-open'); menuButton.setAttribute('aria-expanded', 'true'); menuButton.setAttribute('aria-label', 'Cerrar menú'); menu.querySelector<HTMLButtonElement>('#menu-close')?.focus(); });
document.querySelector('#menu-close')?.addEventListener('click', () => { closeMenu(); menuButton?.focus(); });
menu?.addEventListener('click', event => { if ((event.target as HTMLElement).closest('a')) closeMenu(); });
document.addEventListener('keydown', event => {
  if (!menu || menu.hidden) return;
  if (event.key === 'Escape') { closeMenu(); menuButton?.focus(); }
  if (event.key === 'Tab') {
    const controls = [...menu.querySelectorAll<HTMLElement>('a[href],button:not([disabled])')];
    const first = controls[0], last = controls.at(-1);
    if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus(); }
    else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus(); }
  }
});

const trainingList = document.querySelector('#trainingList');
const trainingToggle = document.querySelector<HTMLButtonElement>('#trainingToggle');
if (trainingList && trainingToggle) {
  trainingList.classList.add('is-collapsed'); trainingToggle.hidden = false;
  trainingToggle.addEventListener('click', () => { const collapsed = trainingList.classList.toggle('is-collapsed'); trainingToggle.setAttribute('aria-expanded', String(!collapsed)); trainingToggle.textContent = collapsed ? 'Ver toda la formación' : 'Ver menos formación'; });
}

function closeDialogs() { document.querySelectorAll<HTMLDialogElement>('dialog[open]').forEach(dialog => dialog.close()); }
document.addEventListener('click', event => {
  const anchor = (event.target as HTMLElement).closest<HTMLAnchorElement>('a[data-dialog]');
  if (!anchor || event instanceof MouseEvent && (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey)) return;
  const dialog = document.getElementById(anchor.dataset.dialog!);
  if (!(dialog instanceof HTMLDialogElement) || typeof dialog.showModal !== 'function') return;
  event.preventDefault(); closeMenu(); closeDialogs(); dialog.showModal();
  if (anchor.dataset.dialog === 'contact-dialog') {void loadContact();void loadCatalogue();}
});
document.querySelectorAll<HTMLDialogElement>('dialog.public-dialog').forEach(dialog => {
  dialog.querySelectorAll('[data-close-dialog]').forEach(button => button.addEventListener('click', () => dialog.close()));
  dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); });
});

const base = document.body.dataset.bookingBase!;
const integrationKey = document.body.dataset.bookingKey;
const bookingContainer = document.querySelector<HTMLElement>('#public-booking');
let sdk: Promise<BookingWidget> | undefined;
function getWidget() {
  if (!sdk) sdk = new Promise<void>((resolve, reject) => {
    const script = document.createElement('script'); script.src = base + '/booking/embed-v1.js'; script.async = true;
    const timeout = setTimeout(() => { script.remove(); reject(new Error('El turnero no respondió.')); }, 10000);
    script.onload = () => { clearTimeout(timeout); resolve(); }; script.onerror = () => { clearTimeout(timeout); reject(new Error('No se pudo abrir el turnero.')); }; document.head.append(script);
  }).then(() => {
    if (!window.CitaSuiteBooking || !integrationKey) throw new Error('La reserva todavía no está habilitada.');
    widget = window.CitaSuiteBooking.mount({ baseURL: base, integrationKey, theme: theme(), ...(bookingContainer ? { container: bookingContainer, mode: 'inline' as const } : {}) }); return widget;
  }).catch(cause => { sdk = undefined; throw cause; });
  return sdk;
}
if (integrationKey && bookingContainer) {
  const feedback = document.querySelector<HTMLElement>('[data-booking-load-state]');
  void getWidget().then(() => { if (feedback) feedback.hidden = true; }).catch(() => {
    if (feedback) feedback.textContent = 'No pudimos cargar la agenda. Podés abrirla en otra página.';
  });
}
if (integrationKey) document.addEventListener('click', async event => {
  const anchor = (event.target as HTMLElement).closest<HTMLAnchorElement>('a[data-booking]');
  if (!anchor || event instanceof MouseEvent && (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey)) return;
  event.preventDefault(); closeMenu(); closeDialogs(); anchor.setAttribute('aria-busy', 'true');
  try { (await getWidget()).open(); }
  catch { window.location.assign(anchor.href); }
  finally { anchor.removeAttribute('aria-busy'); }
});

const catalogue = document.querySelector<HTMLElement>('#public-catalogue');
const contactSinks = [...document.querySelectorAll<HTMLElement>('[data-public-contact]')];
let catalogueRequest: Promise<void> | undefined;
let contactRequest:Promise<void>|undefined;
function loadContact(){if(!integrationKey)return Promise.resolve();return contactRequest??=fetch(`${base}/api/public/contacto/${integrationKey}`,{signal:AbortSignal.timeout(8000),credentials:'omit'}).then(async response=>{if(!response.ok)throw new Error('Contacto no disponible');const data=await response.json();if(data.contact)renderContact(data.contact);}).catch(()=>{contactRequest=undefined;});}
function renderContact(contact: { phone?: unknown; address?: unknown;whatsapp_phone?:unknown;whatsapp_message?:unknown }) {
  const rawPhone = typeof contact.phone === 'string' ? contact.phone.trim() : '';
  const phone = rawPhone.replace(/[\s().-]/g, '');
  const validPhone = /^\+?[0-9]{6,15}$/.test(phone);
  const address = typeof contact.address === 'string' ? contact.address.trim() : '';
  const whatsapp=typeof contact.whatsapp_phone==='string'?contact.whatsapp_phone.trim():'';
  const whatsappValid=/^\+[1-9][0-9]{5,14}$/.test(whatsapp);
  const whatsappMessage=typeof contact.whatsapp_message==='string'?contact.whatsapp_message.slice(0,180):'';
  for (const sink of contactSinks) {
    if (!validPhone && !address && !whatsappValid) continue;
    sink.dataset.contactLoaded='true';
    const heading = document.createElement(sink.dataset.publicContact === 'section' ? 'span' : 'h4');
    heading.textContent = 'Contacto del consultorio';
    if (sink.dataset.publicContact === 'section') heading.className = 'contact-info-label';
    const number = document.createElement('p');
    if (validPhone) { const link = document.createElement('a'); link.href = `tel:${phone}`; link.textContent = rawPhone; number.append(link); }
    else number.textContent = 'Teléfono pendiente de confirmación.';
    const location = document.createElement('p'); location.textContent = address || 'Dirección pendiente de confirmación.';
    sink.replaceChildren(heading, number, location);
    if(whatsappValid){const link=document.createElement('a');link.className=sink.dataset.publicContact==='section'?'btn btn-outline-cream':'btn btn-secondary';link.href=`https://wa.me/${whatsapp.slice(1)}${whatsappMessage?'?text='+encodeURIComponent(whatsappMessage):''}`;link.target='_blank';link.rel='noopener noreferrer';link.textContent='Consultar por WhatsApp';sink.append(link);}
  }
}
function loadCatalogue(): Promise<void> {
  void loadContact();
  if (!integrationKey) return Promise.resolve();
  return catalogueRequest ??= fetch(`${base}/api/public/reservas/${integrationKey}/catalogo`, { signal: AbortSignal.timeout(8000), credentials: 'omit' }).then(async response => {
    if (!response.ok) throw new Error('El catálogo no está disponible.');
    const data = await response.json();
    if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('El catálogo no está disponible.');
    if (data.contact && typeof data.contact === 'object') renderContact(data.contact);
    if (!catalogue) return;
    const heading = document.createElement('h3'); heading.textContent = 'Prestaciones disponibles en la agenda';
    const list = document.createElement('div'); list.className = 'services-commercial-grid';
    for (const service of (Array.isArray(data.services) ? data.services : []).slice(0, 30)) {
      if (!service || typeof service.id !== 'string' || !/^[a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i.test(service.id) || typeof service.name !== 'string' || !service.name.trim() || !Number.isFinite(service.duration_minutes) || service.duration_minutes <= 0) continue;
      const article = document.createElement('article'); article.className = 'service-commercial-card';
      const title = document.createElement('h3'); title.textContent = service.name;
      const detail = document.createElement('p'); detail.textContent = `${service.duration_minutes} minutos${service.price_label ? ' · ' + service.price_label : ''}`;
      // The supported direct route preserves selection; the generic SDK cannot select a service.
      const link = document.createElement('a'); link.className = 'btn btn-secondary'; link.href = `${base}/embed/v1/${integrationKey}?service_id=${encodeURIComponent(service.id)}`; link.textContent = 'Reservar consulta';
      article.append(title, detail, link); list.append(article);
    }
    if (list.children.length) catalogue.replaceChildren(heading, list);
    else { const empty = document.createElement('p'); empty.textContent = 'No hay prestaciones disponibles en la agenda en este momento.'; catalogue.replaceChildren(heading, empty); }
  }).catch(() => {
    catalogueRequest = undefined;
    for (const sink of contactSinks) { if(sink.dataset.contactLoaded==='true')continue;const feedback = document.createElement('p'); feedback.textContent = 'No pudimos consultar los datos de contacto. Podés abrir la agenda o volver a intentar al abrir Contacto.'; sink.replaceChildren(feedback); }
    // Editorial information and direct booking destinations remain available.
  });
}
if (integrationKey && (catalogue || contactSinks.length)) {
  if (catalogue && 'IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => { if (entries.some(entry => entry.isIntersecting)) { observer.disconnect(); void loadCatalogue(); } }, { rootMargin: '120px' });
    observer.observe(document.querySelector('#areas') || catalogue);
    const contactSection = document.querySelector('#contacto'); if (contactSection) observer.observe(contactSection);
  }
  else void loadCatalogue();
}
export {};
