import { env } from "$env/dynamic/private";
import { createSupabaseAdminClient } from "$lib/server/supabase";
import { getOdontoContext } from "$lib/server/odonto-context";
import { readBoundedBookingForm } from "$lib/server/public-booking-page";
import { error, fail } from "@sveltejs/kit";
import type { PageServerLoad, Actions } from "./$types";
export const load: PageServerLoad = async (event) => {
  const context = await getOdontoContext(event);
  if (!context.business.canManage)
    error(403, "Tu usuario no puede configurar el contacto del consultorio.");
  const [
    { data: settings, error: settingsError },
    { data: budget, error: budgetError },
    { data: services, error: serviceError },
  ] = await Promise.all([
    context.supabase
      .from("businesses")
      .select(
        "id,name,updated_at,patient_documents_enabled,public_contact_enabled,whatsapp_contact_enabled,whatsapp_phone,whatsapp_message",
      )
      .eq("id", context.business.business.id)
      .single(),
    context.supabase.rpc(
      "get_clinical_storage_budget" as never,
      { p_business_id: context.business.business.id } as never,
    ),
    context.supabase
      .from("services")
      .select(
        "id,name,updated_at,patient_instructions,public_reminder_description",
      )
      .eq("business_id", context.business.business.id)
      .order("name"),
  ]);
  if (settingsError || budgetError || serviceError)
    error(503, "No pudimos cargar esta configuración. Volvé a intentar.");
  return { settings, budget: budget as any, services: services ?? [] };
};
export const actions: Actions = {
  cleanup: async (event) => {
    if (env.DEMO_MODE === "true")
      return fail(400, { message: "No disponible en modo demo." });
    const context = await getOdontoContext(event);
    if (!context.business.canManage)
      return fail(403, {
        message: "Tu usuario no puede limpiar cargas abandonadas.",
      });
    const admin = await createSupabaseAdminClient("odonto", event.fetch);
    const { data, error: cause } = await admin.rpc(
      "claim_expired_clinical_uploads" as never,
      {
        p_business_id: context.business.business.id,
        p_actor_id: context.userId,
      } as never,
    );
    if (cause)
      return fail(400, {
        message: "No pudimos revisar las cargas abandonadas. Probá nuevamente.",
      });
    let removed = 0;
    for (const item of (data ?? []) as any[]) {
      const { error: removeError } = await admin.storage
        .from(item.bucket)
        .remove(item.paths);
      if (removeError)
        return fail(503, {
          message:
            "No pudimos terminar la limpieza. Los documentos confirmados se conservan; podés volver a intentar.",
        });
      removed++;
    }
    return {
      saved: true,
      message: removed
        ? "Se limpiaron cargas abandonadas. Los documentos guardados y la papelera se conservaron."
        : "No hay cargas abandonadas que puedan limpiarse.",
    };
  },
  save: async (event) => {
    if (env.DEMO_MODE === "true")
      return fail(400, { message: "No disponible en modo demo." });
    const context = await getOdontoContext(event);
    if (!context.business.canManage)
      return fail(403, {
        message: "Tu usuario no puede cambiar esta configuración.",
      });
    try {
      const form = await readBoundedBookingForm(event.request);
      const settings = {
        patient_documents_enabled:
          form.get("patient_documents_enabled") === "true",
        public_contact_enabled: form.get("public_contact_enabled") === "true",
        whatsapp_contact_enabled:
          form.get("whatsapp_contact_enabled") === "true",
        whatsapp_phone: String(form.get("whatsapp_phone") ?? "")
          .trim()
          .replace(/[\s().-]/g, ""),
        whatsapp_message: String(form.get("whatsapp_message") ?? "").trim(),
      };
      const { error: cause } = await context.supabase.rpc(
        "save_public_practice_settings" as never,
        {
          p_business_id: context.business.business.id,
          p_settings: settings,
          p_expected_updated_at: String(form.get("settings_updated_at") ?? ""),
        } as never,
      );
      if (cause?.message.includes("CARE_CONFIGURATION_CHANGED"))
        return fail(409, {
          message:
            "La configuración cambió en otra pestaña. Recargá antes de guardar.",
        });
      if (cause)
        return fail(400, {
          message:
            "Revisá el teléfono con código de país y el texto de contacto. No se guardó ningún cambio.",
        });
      return {
        saved: true,
        message: "La configuración del consultorio quedó guardada.",
      };
    } catch {
      return fail(400, {
        message: "Revisá la configuración antes de guardar.",
      });
    }
  },
  instructions: async (event) => {
    if (env.DEMO_MODE === "true")
      return fail(400, { message: "No disponible en modo demo." });
    const context = await getOdontoContext(event);
    if (!context.business.canManage)
      return fail(403, {
        message: "Tu usuario no puede cambiar las indicaciones.",
      });
    const form = await readBoundedBookingForm(event.request);
    const { error: cause } = await context.supabase.rpc(
      "save_service_patient_instructions" as never,
      {
        p_business_id: context.business.business.id,
        p_service_id: String(form.get("service_id") ?? ""),
        p_instructions: String(form.get("instructions") ?? ""),
        p_public_description: String(form.get("public_description") ?? ""),
        p_expected_updated_at: String(form.get("service_updated_at") ?? ""),
      } as never,
    );
    if (cause?.message.includes("CARE_CONFIGURATION_CHANGED"))
      return fail(409, {
        message:
          "La prestación cambió en otra pestaña. Recargá antes de guardar.",
      });
    if (cause)
      return fail(400, {
        message: "Revisá la prestación y acortá los textos demasiado extensos.",
      });
    return {
      saved: true,
      message:
        "Las indicaciones se aplicarán a los nuevos turnos de esta prestación.",
    };
  },
};
