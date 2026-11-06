import { describe, expect, it } from 'vitest';
import { suggestEmailCorrection } from './email-suggestion';

describe('suggestEmailCorrection', () => {
	it('suggests a likely typo of a common domain', () => {
		expect(suggestEmailCorrection('ana@gmial.com')).toBe('ana@gmail.com');
		expect(suggestEmailCorrection('ana@gmail.con')).toBe('ana@gmail.com');
		expect(suggestEmailCorrection('ana@hotmial.com')).toBe('ana@hotmail.com');
		expect(suggestEmailCorrection(' ana@yaho.com.ar ')).toBe('ana@yahoo.com.ar');
	});
	it('keeps the mailbox exactly as it was written', () => {
		expect(suggestEmailCorrection('Ana.Perez+turnos@gmial.com')).toBe('Ana.Perez+turnos@gmail.com');
	});
	it('says nothing about a correct or an unrelated domain', () => {
		for (const email of ['ana@gmail.com', 'ANA@GMAIL.COM', 'ana@consultorio.com.ar', 'ana@empresa.org', 'ana@gmx.de'])
			expect(suggestEmailCorrection(email)).toBeNull();
	});
	it('says nothing until there is a domain', () => {
		for (const email of ['', 'ana', 'ana@', '@gmail.com']) expect(suggestEmailCorrection(email)).toBeNull();
	});
});
