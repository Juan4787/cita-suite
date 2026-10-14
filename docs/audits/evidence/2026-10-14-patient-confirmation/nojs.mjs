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
for (const url of [f.apiOrigin, f.appOrigin])
  assert.equal(new URL(url).hostname, "127.0.0.1");
assert.equal(f.businessId, "90000000-0000-4000-8000-000000000001");
const db = createClient(f.apiOrigin, f.service, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const owner = createClient(f.apiOrigin, f.anon, {
  auth: { persistSession: false, autoRefreshToken: false },
  global: { headers: { Authorization: "Bearer " + f.ownerToken } },
});
const proof = {
  scope:
    "Disposable local clinic and simulated Auth only; browser JavaScript disabled. No production requests.",
  checks: [],
};
const browser = await chromium.launch({ headless: true });
try {
  for (const required of [true, false]) {
    const schema = await db
      .from("professional_booking_forms")
      .select("fields,revision")
      .eq("professional_id", f.professionalId)
      .single();
    assert.equal(schema.error, null);
    const fields = schema.data.fields.map((field) =>
      field.id === "birth" ? { ...field, required } : field,
    );
    const savedSchema = await owner.rpc("save_professional_booking_form", {
      p_business_id: f.businessId,
      p_professional_id: f.professionalId,
      p_expected_revision: schema.data.revision,
      p_fields: fields,
    });
    assert.equal(savedSchema.error, null);
    const ctx = await browser.newContext({
      viewport: { width: 390, height: 960 },
      locale: "es-AR",
      javaScriptEnabled: false,
    });
    await ctx.route("**/*", (route) =>
      [
        "127.0.0.1",
        "localhost",
        "fonts.googleapis.com",
        "fonts.gstatic.com",
      ].includes(new URL(route.request().url()).hostname)
        ? route.continue()
        : route.abort(),
    );
    const p = await ctx.newPage();
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
    const form = p.locator(".patient-booking-form");
    await expect(form).toBeVisible();
    await p
      .getByLabel("Nombre y apellido", { exact: true })
      .fill(required ? "Fecha Obligatoria Prueba" : "Fecha Opcional Prueba");
    await p
      .getByLabel("Teléfono de contacto", { exact: true })
      .fill(required ? "3425123458" : "3425123459");
    await form
      .getByRole("group", {
        name: "¿Traés estudios para la consulta?",
        exact: true,
      })
      .getByRole("radio", { name: "No", exact: true })
      .check();
    const birth = p.getByLabel("Fecha de nacimiento", { exact: true });
    await expect(birth).toHaveAttribute("type", "date");
    assert.equal((await birth.getAttribute("required")) !== null, required);
    assert(await birth.getAttribute("min"));
    assert(await birth.getAttribute("max"));
    assert.equal(await form.locator('[name*="birth"]').count(), 1);
    await birth.fill("1991-04-16");
    const attempt = await form.locator('[name="idempotency_key"]').inputValue();
    await p
      .getByRole("button", { name: "Confirmar reserva", exact: true })
      .click();
    await expect(
      p.getByRole("heading", { name: "Tu turno quedó reservado", exact: true }),
    ).toBeVisible();
    const booking = await db
      .from("appointments")
      .select("patient_id")
      .eq("business_id", f.businessId)
      .eq("creation_request_key", attempt)
      .single();
    assert.equal(booking.error, null);
    const patient = await db
      .from("patients")
      .select("birth_date")
      .eq("id", booking.data.patient_id)
      .single();
    assert.equal(patient.error, null);
    assert.equal(patient.data.birth_date, "1991-04-16");
    const description = `Without JavaScript, ${required ? "required" : "optional"} birth date has one native named control and persists the entered ISO value in the patient record.`;
    proof.checks.push(description);
    console.log("PASS " + description);
    await ctx.close();
  }
} finally {
  await browser.close();
  writeFileSync(
    root + "/.impeccable/review/patient-confirmation/nojs-results.json",
    JSON.stringify(proof, null, 2),
  );
}
