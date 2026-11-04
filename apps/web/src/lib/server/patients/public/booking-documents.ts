import { isUuid } from '@cita-suite/shared/uuid';
import { json, type RequestEvent } from '@sveltejs/kit';
import { informationContext } from './booking-information';
import { clinicalFileError, clinicalFileErrorBody, createClinicalFileUploadUrls, CLINICAL_FILE_MAX_BYTES,
 isClinicalFileMime, normalizeClinicalFilename, normalizeClinicalNote, readClinicalJson, verifyStoredClinicalImage } from './clinical-files';
import { enforceRateLimits } from '$lib/server/platform/rate-limits';

export const createPublicPatientDocumentUpload = (legacy: boolean) => async (event: RequestEvent) => {
  try {
    const { admin, token } = await informationContext(event);
    const body = await readClinicalJson(event.request);
    await enforceRateLimits(
      [
        {
          action: "radiograph_upload_by_user",
          subject: "patient-ip:" + event.getClientAddress(),
          limit: 20,
          windowSeconds: 3600,
          message: "Se iniciaron muchas cargas desde tu conexión.",
        },
        {
          action: "radiograph_upload_by_user",
          subject: "patient-ip:" + event.getClientAddress(),
          limit: 100,
          windowSeconds: 86400,
          message: "Se alcanzó el límite diario de cargas desde tu conexión.",
        },
      ],
      event.fetch,
    );
    const filename = normalizeClinicalFilename(body.filename);
    const note = normalizeClinicalNote(body.note);
    const bytes = Number(body.bytes);
    if (
      !filename ||
      note === undefined ||
      !isClinicalFileMime(body.mime) ||
      !Number.isSafeInteger(bytes) ||
      bytes < 1 ||
      bytes > CLINICAL_FILE_MAX_BYTES ||
      typeof body.sha256 !== 'string' || !/^[a-f0-9]{64}$/.test(body.sha256) ||
      typeof body.requestId !== 'string' || !isUuid(body.requestId)
    )
      throw new Error("RADIOGRAPH_UPLOAD_INVALID");
    const { data, error } = await admin.rpc(
      "begin_public_patient_document_upload",
      {
        p_token: token, p_legacy: legacy,
        p_request_id: body.requestId,
        p_filename: filename,
        p_mime: body.mime,
        p_bytes: bytes,
        p_sha256: body.sha256,
        p_note: note,
      },
    );
    if (error) throw error;
    const file = data;
    if (!file || !isUuid(file.id)) throw new Error("RADIOGRAPH_NOT_FOUND");
    if (file.status === "ready")
      return json({ id: file.id, already_complete: true });
    if (file.status !== "uploading") throw new Error("RADIOGRAPH_UPLOAD_EXPIRED");
    if (!file.storage_bucket || !file.storage_path) throw new Error("RADIOGRAPH_UPLOAD_INVALID");
    const existing = await admin.storage
      .from(file.storage_bucket)
      .info(file.storage_path);
    if (!existing.error && existing.data)
      return json({ id: file.id, object_present: true });
    const urls = await createClinicalFileUploadUrls(admin, {
      original: file.storage_path,
      thumbnail: null,
    });
    return json({ id: file.id, upload_url: urls.originalUrl });
  } catch (cause) {
    const safe = clinicalFileError(
      cause,
      "No pudimos preparar el archivo. Revisá el enlace de tu turno y probá nuevamente.",
    );
    return json(clinicalFileErrorBody(safe), { status: safe.status });
  }
};

export const createPublicPatientDocumentCompletion = (legacy: boolean) => async (event: RequestEvent) => {
  try {
    const { admin, token } = await informationContext(event);
    const fileId = event.params.fileId;
    if (!fileId || !isUuid(fileId)) throw new Error("RADIOGRAPH_UPLOAD_INVALID");
    const { data, error } = await admin.rpc(
      "get_public_patient_document_upload",
      { p_token: token, p_legacy: legacy, p_file_id: fileId },
    );
    if (error) throw error;
    const file = data;
    if (!file || file.id !== fileId || !["uploading", "ready"].includes(file.status)) throw new Error("RADIOGRAPH_NOT_FOUND");
    if (file.status === "ready") return json({ ready: true, id: file.id });
    if (!file.storage_bucket || !file.storage_path) throw new Error("RADIOGRAPH_UPLOAD_INVALID");
    if (!isClinicalFileMime(file.mime_type))
      throw new Error("RADIOGRAPH_FORMAT_INVALID");
    const verified = await verifyStoredClinicalImage({
      admin,
      bucket: file.storage_bucket,
      path: file.storage_path,
      expectedBytes: Number(file.bytes),
      expectedMime: file.mime_type,
    });
    const result = await admin.rpc(
      "complete_public_patient_document_upload",
      {
        p_token: token, p_legacy: legacy,
        p_file_id: file.id,
        p_bytes: verified.bytes,
        p_mime: verified.mimeType,
      },
    );
    if (result.error) throw result.error;
    if (result.data !== file.id) throw new Error("CLINICAL_DOCUMENT_RESULT_UNCERTAIN");
    return json({ ready: true, id: file.id });
  } catch (cause) {
    const safe = clinicalFileError(
      cause,
      "No pudimos confirmar el archivo. Tu turno se conserva; podés volver a intentar.",
    );
    return json(clinicalFileErrorBody(safe), { status: safe.status });
  }
};
