<script lang="ts">
  import type { BookingIntakeField } from "@cita-suite/shared/booking-integration";
  import { styledSelect } from "$lib/ui/styled-controls";
  import BookingBirthDateInput from "./BookingBirthDateInput.svelte";
  let {
    field,
    value = $bindable(""),
    today,
  }: { field: BookingIntakeField; value?: string; today?: string } = $props();
  const name = $derived("intake_" + field.id);
  const inputId = $derived("patient-" + name);
  const helpId = $derived(field.help ? inputId + "-help" : undefined);
  const patientSelect = (source: HTMLSelectElement, parameter?: string) => {
    // Select bindings mount after actions and otherwise apply the server value.
    // Capture a native selection changed before hydration; a fresh client mount
    // still keeps the prop because its DOM selection equals the native default.
    const defaultIndex = [...source.options].findIndex(option => option.defaultSelected);
    if (source.selectedIndex !== Math.max(0, defaultIndex)) value = source.value;
    return styledSelect(source, parameter);
  };
</script>

{#if field.kind === "boolean"}
  <fieldset
    class="patient-field patient-question"
    aria-label={field.label}
    aria-describedby={helpId}
  >
    <legend class="patient-label"
      ><span>{field.label}</span>{#if field.required}<span
          class="patient-required"
          aria-hidden="true">*</span
        >{:else}<span class="patient-optional" aria-hidden="true">Opcional</span
        >{/if}</legend
    >
    <div
      class="patient-answers"
      class:patient-answers-optional={!field.required}
    >
      {#each [{ value: "true", label: "Sí" }, { value: "false", label: "No" }, ...(!field.required ? [{ value: "", label: "Sin responder" }] : [])] as option}
        <label class="patient-answer"
          ><input
            type="radio"
            {name}
            value={option.value}
            bind:group={value}
            required={field.required}
          /><span>{option.label}</span></label
        >
      {/each}
    </div>
  </fieldset>
{:else if field.patientField === "birth_date"}
  <div class="patient-field">
    <div class="patient-label">
      <span>{field.label}</span>{#if field.required}<span
          class="patient-required"
          aria-hidden="true">*</span
        >{:else}<span class="patient-optional" aria-hidden="true">Opcional</span
        >{/if}
    </div>
    <BookingBirthDateInput
      {name}
      label={field.label}
      bind:value
      required={field.required}
      {helpId}
      {today}
    />
  </div>
{:else}
  <div class="patient-field">
    <label class="patient-label" for={inputId}
      ><span>{field.label}</span>{#if field.required}<span
          class="patient-required"
          aria-hidden="true">*</span
        >{:else}<span class="patient-optional" aria-hidden="true">Opcional</span
        >{/if}</label
    >
    {#if field.kind === "textarea"}
      <textarea
        id={inputId}
        {name}
        aria-label={field.label}
        aria-describedby={helpId}
        required={field.required}
        maxlength={field.maxLength}
        rows="3"
        bind:value
        class="ux-textarea patient-control"
      ></textarea>
    {:else if field.kind === "text"}
      <input
        id={inputId}
        {name}
        aria-label={field.label}
        aria-describedby={helpId}
        type={field.patientField === "age" ? "number" : "text"}
        min={field.patientField === "age" ? 0 : undefined}
        max={field.patientField === "age" ? 130 : undefined}
        required={field.required}
        maxlength={field.maxLength}
        bind:value={() => field.patientField === 'age' ? value === '' ? undefined : Number(value) : value,
          (next: string | number | undefined) => value = next == null ? '' : String(next)}
        class="ux-input patient-control"
      />
    {:else}
      <select
        use:patientSelect={value}
        id={inputId}
        {name}
        aria-label={field.label}
        aria-describedby={helpId}
        required={field.required}
        bind:value
        class="ux-select patient-control"
      >
        <option value="">Elegí una opción</option
        >{#each field.options ?? [] as option}<option value={option}
            >{option}</option
          >{/each}
      </select>
    {/if}
  </div>
{/if}
{#if field.help}<p class="patient-field-help" id={helpId}>{field.help}</p>{/if}
