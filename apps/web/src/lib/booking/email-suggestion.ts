// EM05: a likely mistyped domain gets a suggestion, never a silent correction. The person decides.
// Only the domain is looked at: the local part, its case and any +alias belong to the mailbox.
const COMMON_DOMAINS = ['gmail.com', 'hotmail.com', 'hotmail.com.ar', 'outlook.com', 'outlook.com.ar', 'live.com', 'yahoo.com', 'yahoo.com.ar', 'icloud.com'] as const;

const distance = (left: string, right: string) => {
	const previous = Array.from({ length: right.length + 1 }, (_, index) => index);
	for (let row = 1; row <= left.length; row += 1) {
		let diagonal = previous[0] ?? 0;
		previous[0] = row;
		for (let column = 1; column <= right.length; column += 1) {
			const above = previous[column] ?? 0;
			const cost = left[row - 1] === right[column - 1] ? 0 : 1;
			previous[column] = Math.min(above + 1, (previous[column - 1] ?? 0) + 1, diagonal + cost);
			diagonal = above;
		}
	}
	return previous[right.length] ?? 0;
};

/** The corrected address if the domain looks like a typo of a common one; null otherwise. */
export const suggestEmailCorrection = (value: string): string | null => {
	const email = value.trim();
	const separator = email.lastIndexOf('@');
	if (separator < 1 || separator === email.length - 1) return null;
	const domain = email.slice(separator + 1).toLowerCase();
	if ((COMMON_DOMAINS as readonly string[]).includes(domain)) return null;
	let best: string | null = null;
	let bestDistance = 3;
	for (const candidate of COMMON_DOMAINS) {
		const difference = distance(domain, candidate);
		if (difference > 0 && difference < bestDistance) {
			best = candidate;
			bestDistance = difference;
		}
	}
	return best ? `${email.slice(0, separator)}@${best}` : null;
};
