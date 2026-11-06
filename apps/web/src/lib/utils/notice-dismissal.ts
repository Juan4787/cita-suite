export type NoticeStorage = Pick<Storage, 'getItem' | 'setItem'>;

export const isNoticeDismissed = (storage: NoticeStorage, key: string) =>
	storage.getItem(key) === '1';

export const dismissNotice = (storage: NoticeStorage, key: string) => {
	storage.setItem(key, '1');
};

/** Names a set of items: a closed notice comes back when the set changes, never before. */
export const noticeFingerprint = (ids: string[], count: number): string => {
	let hash = 2166136261;
	const source = `${count}:${ids.join('|')}`;
	for (let index = 0; index < source.length; index += 1) {
		hash ^= source.charCodeAt(index);
		hash = Math.imul(hash, 16777619);
	}
	return `${count}-${(hash >>> 0).toString(36)}`;
};
