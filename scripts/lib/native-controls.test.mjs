import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

// P2: nothing the browser draws by itself stays on screen once the page is running. Selects and
// calendars go through the styled controls of $lib/ui/styled-controls, which keep the native source
// for validation and for visitors without JavaScript. The rendered sweep of e2e/theme-modes.spec.ts
// checks the same thing on the screens; this one fails before any browser opens.
const root = path.resolve(import.meta.dirname, '../../apps/web/src');
const svelteFiles = (directory) => fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
	const full = path.join(directory, entry.name);
	return entry.isDirectory() ? svelteFiles(full) : entry.name.endsWith('.svelte') ? [full] : [];
});
const relative = (file) => path.relative(root, file);
const tags = (source, pattern) => [...source.matchAll(pattern)].map((match) => match[0].replace(/\s+/g, ' '));

// Each exception says why the browser's control is the right one there.
const NATIVE_DATE_ALLOWED = new Map([
	['lib/booking/BookingBirthDateInput.svelte', 'the fallback before the three styled fields mount, and without JavaScript']
]);
const TITLE_ALLOWED = new Map([
	['routes/odonto/+layout.svelte', 'the full practice name of a truncated header, which the page shows complete elsewhere']
]);

test('every select goes through a styled control', () => {
	const native = svelteFiles(root).flatMap((file) =>
		tags(fs.readFileSync(file, 'utf8'), /<select\b[^>]*>/g)
			.filter((tag) => !/use:(styledSelect|patientSelect)/.test(tag))
			.map((tag) => `${relative(file)}: ${tag.slice(0, 90)}`)
	);
	assert.deepEqual(native, []);
});

test('every date, month and time field goes through a styled control', () => {
	const native = svelteFiles(root).flatMap((file) => {
		if (NATIVE_DATE_ALLOWED.has(relative(file))) return [];
		return tags(fs.readFileSync(file, 'utf8'), /<input\b(?:[^>=]|=(?!>)|=>)*?type="(?:date|month|week|time|datetime-local)"(?:[^>=]|=(?!>)|=>)*>/g)
			.filter((tag) => !/use:(styledDate|styledTime)/.test(tag))
			.map((tag) => `${relative(file)}: ${tag.slice(0, 90)}`);
	});
	assert.deepEqual(native, []);
});

test('a file field shows the words of the app', () => {
	const native = svelteFiles(root).flatMap((file) =>
		tags(fs.readFileSync(file, 'utf8'), /<input\b[^>]*type="file"[^>]*>/g)
			.filter((tag) => !/\bsr-only\b/.test(tag))
			.map((tag) => `${relative(file)}: ${tag.slice(0, 90)}`)
	);
	assert.deepEqual(native, []);
});

test('nobody opens the dialogs of the browser', () => {
	const calls = svelteFiles(root).flatMap((file) =>
		[...fs.readFileSync(file, 'utf8').matchAll(/\b(?:window\.)?(?:alert|confirm|prompt)\(/g)].map((match) => `${relative(file)}: ${match[0]}`)
	);
	assert.deepEqual(calls, []);
});

test('tooltips are drawn by the page', () => {
	const native = svelteFiles(root).flatMap((file) => {
		if (TITLE_ALLOWED.has(relative(file))) return [];
		return tags(fs.readFileSync(file, 'utf8'), /<(?:a|button|input|span|p|div)\b[^>]*\stitle=[^>]*>/g)
			.filter((tag) => !/^<[a-z]+ [^>]*\btitle=\{?["']?\s*$/.test(tag))
			.map((tag) => `${relative(file)}: ${tag.slice(0, 90)}`);
	});
	assert.deepEqual(native, []);
});
