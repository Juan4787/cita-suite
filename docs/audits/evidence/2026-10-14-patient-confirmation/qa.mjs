import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { readFileSync, writeFileSync } from "node:fs";
import assert from "node:assert/strict";
const root = fileURLToPath(new URL("../../../../", import.meta.url)).replace(
  /\/$/,
  "",
);
const require = createRequire(root + "/apps/web/package.json");
const { chromium, expect } = require("@playwright/test");
const { createClient } = require("@supabase/supabase-js");
const f = JSON.parse(readFileSync("/tmp/cita-booking-runtime.json", "utf8"));
for (const o of [f.apiOrigin, f.appOrigin])
  assert.equal(new URL(o).hostname, "127.0.0.1");
assert.equal(f.businessId, "90000000-0000-4000-8000-000000000001");
const db = createClient(f.apiOrigin, f.service, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const owner = createClient(f.apiOrigin, f.anon, {
  auth: { persistSession: false, autoRefreshToken: false },
  global: { headers: { Authorization: "Bearer " + f.ownerToken } },
});
const result = {
  scope:
    "Local Chromium, isolated PostgreSQL/PostgREST; simulated Auth; synthetic fields and price; no production requests.",
  checks: [],
  screenshots: [],
  errors: [],
  console: [],
};
const dir = root + "/.impeccable/review/patient-confirmation";
function pass(name) {
  result.checks.push(name);
  console.log("PASS " + name);
}
async function rpc(name, params) {
  const r = await owner.rpc(name, params);
  assert.equal(r.error, null);
  return r.data;
}
const old = (
  await db
    .from("professional_booking_forms")
    .select("revision")
    .eq("professional_id", f.professionalId)
    .single()
).data;
await rpc("save_professional_booking_form", {
  p_business_id: f.businessId,
  p_professional_id: f.professionalId,
  p_expected_revision: old.revision,
  p_fields: [
    {
      id: "contact_time",
      label: "Horario de contacto preferido",
      kind: "choice",
      required: false,
      options: ["Mañana", "Tarde", "Indistinto"],
      patientField: "custom",
    },
    {
      id: "studies",
      label: "¿Traés estudios para la consulta?",
      kind: "boolean",
      required: true,
      patientField: "custom",
    },
    {
      id: "birth",
      label: "Fecha de nacimiento",
      kind: "text",
      required: false,
      maxLength: 10,
      patientField: "birth_date",
    },
  ],
});
const profile = (
  await db
    .from("booking_integrations")
    .select("*")
    .eq("public_key", f.key)
    .single()
).data;
await rpc("save_booking_integration", {
  p_business_id: f.businessId,
  p_integration_id: profile.id,
  p_expected_revision: profile.revision,
  p_config: {
    name: profile.name,
    theme: profile.theme,
    origins: profile.allowed_origins,
    professional_ids: profile.allowed_professional_ids,
    service_ids: profile.allowed_service_ids,
    intake_schema: [],
    modality_windows: profile.modality_windows,
    modalities: profile.allowed_modalities,
    video_instructions: profile.video_instructions,
    active: profile.is_active,
    default: profile.is_default,
  },
});
const currentMonth = new Intl.DateTimeFormat("sv-SE", {
  timeZone: "America/Argentina/Cordoba",
  year: "numeric",
  month: "2-digit",
}).format(new Date());
const [year, month] = currentMonth.split("-").map(Number);
const first = `${year + (month === 12 ? 1 : 0)}-${String(month === 12 ? 1 : month + 1).padStart(2, "0")}-01`;
const existingPrice = (
  await db
    .from("service_price_policies")
    .select("revision")
    .eq("business_id", f.businessId)
    .eq("service_id", f.serviceId)
    .eq("professional_id", f.professionalId)
    .maybeSingle()
).data;
await rpc("save_service_price_policy", {
  p_business_id: f.businessId,
  p_service_id: f.serviceId,
  p_professional_id: f.professionalId,
  p_expected_revision: existingPrice?.revision ?? 0,
  p_configuration: {
    base_amount: "20000",
    currency: "ARS",
    base_month: currentMonth + "-01",
    first_adjustment_month: first,
    monthly_percentage: "2",
    rounding_unit: 1,
    adjustments: [],
  },
});
pass(
  "Only the local synthetic clinic is configured, through the existing owner RPCs.",
);
const browser = await chromium.launch({ headless: true });
try {
  const ctx = await browser.newContext({
    viewport: { width: 1440, height: 960 },
    locale: "es-AR",
    reducedMotion: "reduce",
  });
  const p = await ctx.newPage();
  p.on("pageerror", (e) => result.errors.push(e.message));
  p.on("console", (m) => {
    if (
      ["error", "warning"].includes(m.type()) &&
      !m.text().includes("Failed to load resource")
    )
      result.console.push(
        m.text().replace(/apikey=[^&\s']+/g, "apikey=[redacted]"),
      );
  });
  await ctx.route("**/*", (route) => {
    const u = new URL(route.request().url());
    return [
      "127.0.0.1",
      "localhost",
      "fonts.googleapis.com",
      "fonts.gstatic.com",
    ].includes(u.hostname) || u.protocol === "data:"
      ? route.continue()
      : route.abort();
  });
  await p.goto(
    f.appOrigin +
      "/reservar/" +
      f.businessId +
      "?service_id=" +
      f.serviceId +
      "&professional_id=" +
      f.professionalId,
  );
  await p
    .getByRole("link", { name: /Horarios disponibles/ })
    .nth(1)
    .click();
  await p
    .getByRole("link", { name: /^\d{2}:\d{2}$/ })
    .first()
    .click();
  await expect(p.locator(".patient-booking-form")).toBeVisible();
  await expect(p).toHaveTitle(/Reservar turno/);
  const finalURL = p.url();
  const form = p.locator(".patient-booking-form");
  // Begin interaction after enhancement, not during SSR hydration.
  await expect(form.getByRole("combobox", { name: "Horario de contacto preferido", exact: true })).toBeVisible();
  await p.getByLabel("Nombre y apellido", { exact: true }).fill("Ramón Prueba");
  await p
    .getByLabel("Teléfono de contacto", { exact: true })
    .fill("3425123456");
  const bool = form.getByRole("group", {
    name: "¿Traés estudios para la consulta?",
    exact: true,
  });
  const no = bool.getByRole("radio", { name: "No", exact: true });
  assert.equal(await no.isChecked(), false);
  await no.check();
  const fieldOrder = await form.evaluate((node) =>
    [...node.querySelectorAll("input,select,textarea")]
      .filter((e) => e.name && e.type !== "hidden")
      .map((e) => ({ name: e.name, required: e.required })),
  );
  const optionalIndex = fieldOrder.findIndex((field) => !field.required);
  assert(optionalIndex > 0);
  assert(fieldOrder.slice(optionalIndex).every((field) => !field.required));
  await expect(form.getByText("Información para el consultorio")).toHaveCount(
    0,
  );
  await expect(form.locator(".patient-price")).toHaveText(/20\.000/);
  await expect(form.locator(".patient-price")).toHaveCount(1);
  pass(
    "Native final form has required data before all optional data, an explicit No, and one actual date quote.",
  );
  async function shot(name, width) {
    await p.setViewportSize({ width, height: 960 });
    await p.evaluate(() => document.fonts.ready);
    assert(
      await p.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth + 1,
      ),
    );
    await expect(p.locator("vite-error-overlay")).toHaveCount(0);
    await form.screenshot({ path: dir + "/" + name + ".png" });
    result.screenshots.push(name + ".png");
  }
  await shot("desktop", 1440);
  await shot("mobile", 390);
  await shot("user-320", 320);
  await p.setViewportSize({ width: 390, height: 960 });
  await form
    .getByRole("combobox", {
      name: "Horario de contacto preferido",
      exact: true,
    })
    .click();
  await expect(p.getByRole("listbox")).toBeVisible();
  await p.getByRole("listbox").screenshot({ path: dir + "/choice-cita.png" });
  result.screenshots.push("choice-cita.png");
  await p.keyboard.press("Home");
  await p.keyboard.press("ArrowDown");
  await p.keyboard.press("ArrowDown");
  await p.keyboard.press("Enter");
  await expect(
    form.getByRole("combobox", {
      name: "Horario de contacto preferido",
      exact: true,
    }),
  ).toHaveText(/Tarde/);
  pass(
    "Choice uses the authored popup and keyboard selection; 1440/390/320 have no horizontal overflow.",
  );
  await p.getByLabel("Fecha de nacimiento: día", { exact: true }).fill("15");
  await p.getByLabel("Fecha de nacimiento: mes", { exact: true }).fill("03");
  await p.getByLabel("Fecha de nacimiento: año", { exact: true }).fill("1990");
  const payload = await form.evaluate((node) =>
    Object.fromEntries(new FormData(node)),
  );
  const birthKey = Object.keys(payload).find((key) => key.includes("birth"));
  assert.equal(payload[birthKey], "1990-03-15");
  const boolKey = await no.getAttribute("name");
  assert.equal(payload[boolKey], "false");
  pass(
    "Birth-date parts produce the original ISO field and explicit No produces the original false value.",
  );
  const attempt = payload.idempotency_key;
  await p
    .getByRole("button", { name: "Confirmar reserva", exact: true })
    .click();
  await expect(
    p.getByRole("heading", { name: "Tu turno quedó reservado", exact: true }),
  ).toBeVisible();
  const saved = await db
    .from("appointments")
    .select("id,patient_id,price_quote_snapshot")
    .eq("business_id", f.businessId)
    .eq("creation_request_key", attempt)
    .single();
  assert.equal(saved.error, null);
  assert.equal(Number(saved.data.price_quote_snapshot.amount), 20000);
  const submission = await db
    .from("appointment_intake_submissions")
    .select("answers")
    .eq("appointment_id", saved.data.id)
    .single();
  assert.equal(submission.error, null);
  assert.equal(submission.data.answers[boolKey.slice(7)], false);
  const patient = await db
    .from("patients")
    .select("birth_date")
    .eq("id", saved.data.patient_id)
    .single();
  assert.equal(patient.data.birth_date, "1990-03-15");
  pass(
    "Actual local confirmation persists false, ISO birth date and the quoted amount into appointment/patient records.",
  );
  const embedURL = new URL(finalURL);
  embedURL.pathname = "/embed/v1/" + f.key;
  embedURL.searchParams.delete("slot");
  embedURL.searchParams.set("parent_origin", f.apiOrigin);
  embedURL.searchParams.set("instance_id", "c".repeat(32));
  await p.goto(embedURL.toString());
  await p
    .getByRole("link", { name: /^\d{2}:\d{2}$/ })
    .first()
    .click();
  await expect(p.locator(".patient-booking-form")).toBeVisible();
  await p
    .getByLabel("Nombre y apellido", { exact: true })
    .fill("Paciente Prueba");
  await p
    .getByLabel("Teléfono de contacto", { exact: true })
    .fill("3425123457");
  await p
    .locator(".patient-booking-form")
    .getByRole("group", {
      name: "¿Traés estudios para la consulta?",
      exact: true,
    })
    .getByRole("radio", { name: "No", exact: true })
    .check();
  for (const mode of ["light", "dark"]) {
    await p.evaluate(
      (mode) => (document.documentElement.dataset.bookingColorMode = mode),
      mode,
    );
    await shot("natalia-" + mode, 390);
    await p
      .locator(".patient-booking-form")
      .getByRole("combobox", {
        name: "Horario de contacto preferido",
        exact: true,
      })
      .click();
    await expect(p.locator(".booking-control-menu-natalia")).toBeVisible();
    const colors = await p
      .locator(".booking-control-menu-natalia")
      .evaluate((menu) => ({
        text: getComputedStyle(menu).color,
        bg: getComputedStyle(menu).backgroundColor,
      }));
    if (mode === "light") assert.equal(colors.bg, "rgb(255, 250, 242)");
    else assert.equal(colors.bg, "rgb(33, 28, 23)");
    await p
      .getByRole("listbox")
      .screenshot({ path: dir + "/choice-natalia-" + mode + ".png" });
    result.screenshots.push("choice-natalia-" + mode + ".png");
    await p.keyboard.press("Escape");
  }
  pass(
    "Embedded Natalia light/dark preserves its own palette, including authored choice popups.",
  );
  assert.deepEqual(result.errors, []);
  assert.deepEqual(result.console, []);
  pass(
    "Page identity, actual confirmation, no overlay and no relevant console errors.",
  );
  await ctx.close();
} finally {
  await browser.close();
  writeFileSync(dir + "/results.json", JSON.stringify(result, null, 2));
}
