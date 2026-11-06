/** @vitest-environment jsdom */
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { fieldValidationMessage, installFieldValidation } from './field-validation';

describe('field validation drawn by the page', () => {
	let remove: () => void;
	beforeEach(() => { remove = installFieldValidation(document); });
	afterEach(() => { remove(); document.body.replaceChildren(); });
	const mount = (html: string) => {
		document.body.innerHTML = `<form>${html}</form>`;
		return document.querySelector('form')!;
	};

	it('replaces the bubble with a message under the field and focuses the first problem', () => {
		const form = mount('<label>Nombre<input name="a" required /></label><label>Correo<input name="b" type="email" required /></label>');
		const [first, second] = form.querySelectorAll('input');
		const event = new Event('invalid', { cancelable: true });
		first.dispatchEvent(event);
		expect(event.defaultPrevented).toBe(true);
		second.dispatchEvent(new Event('invalid', { cancelable: true }));
		expect(document.activeElement).toBe(first);
		const message = first.nextElementSibling as HTMLElement;
		expect(message).toHaveProperty('textContent', 'Completá este dato para continuar.');
		expect(first.getAttribute('aria-invalid')).toBe('true');
		expect(first.getAttribute('aria-describedby')).toBe(message.id);
	});

	it('clears the message as soon as the field is valid', () => {
		const form = mount('<input name="a" required aria-describedby="help" />');
		const field = form.querySelector('input')!;
		field.dispatchEvent(new Event('invalid', { cancelable: true }));
		expect(form.querySelector('.ux-control-error')).not.toBeNull();
		field.value = 'Algo';
		field.dispatchEvent(new Event('input', { bubbles: true }));
		expect(form.querySelector('.ux-control-error')).toBeNull();
		expect(field.getAttribute('aria-invalid')).toBeNull();
		expect(field.getAttribute('aria-describedby')).toBe('help');
	});

	it('puts the message of a box under its whole row', () => {
		const form = mount('<label class="row"><input type="checkbox" required /><span>Acepto</span></label>');
		form.querySelector('input')!.dispatchEvent(new Event('invalid', { cancelable: true }));
		expect(form.querySelector('.row')!.nextElementSibling).toHaveProperty('textContent', 'Marcá esta casilla para continuar.');
	});

	it('leaves the styled controls to their own message', () => {
		const form = mount('<select class="ux-native-source" required><option value=""></option></select>');
		const event = new Event('invalid', { cancelable: true });
		form.querySelector('select')!.dispatchEvent(event);
		expect(event.defaultPrevented).toBe(false);
		expect(form.querySelector('.ux-control-error')).toBeNull();
	});

	it('uses the words of the page for a custom rule or a format', () => {
		const form = mount('<input id="a" /><input id="b" pattern="[0-9]+" data-invalid-message="Sólo números." value="x" />');
		const custom = form.querySelector<HTMLInputElement>('#a')!;
		custom.setCustomValidity('Esa fecha no existe.');
		expect(fieldValidationMessage(custom)).toBe('Esa fecha no existe.');
		expect(fieldValidationMessage(form.querySelector<HTMLInputElement>('#b')!)).toBe('Sólo números.');
	});
});
