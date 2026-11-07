type FixtureRealtimeDiagnostic = 'fixture-realtime-unavailable' | 'fixture-realtime-cancelled' | 'fixture-realtime-interrupted';

// Each engine words these in its own way; these are its literal messages, measured on all three.
// Firefox also says «interrupted» when a page is left with a socket connecting, without any native
// close: that is why it has a category of its own and does not count as a cancellation.
const KNOWN_MESSAGES: [RegExp, FixtureRealtimeDiagnostic][] = [
	[/^WebSocket connection to '(ws:\/\/[^']+)' failed: Error during WebSocket handshake: Unexpected response code: 404$/, 'fixture-realtime-unavailable'],
	[/^WebSocket connection to '(ws:\/\/[^']+)' failed: The server did not accept the WebSocket handshake\.$/, 'fixture-realtime-unavailable'],
	[/^\[JavaScript Error: "Firefox can’t establish a connection to the server at (ws:\/\/[^"]+)\."/, 'fixture-realtime-unavailable'],
	[/^WebSocket connection to '(ws:\/\/[^']+)' failed: WebSocket is closed before the connection is established\.$/, 'fixture-realtime-cancelled'],
	[/^\[JavaScript Error: "The connection to (ws:\/\/\S+) was interrupted while the page was loading\."/, 'fixture-realtime-interrupted']
];

/** Only known diagnostics of the disposable fixture, which has no Realtime server.
 * The raw message may contain an API key: return a static category, never its URL.
 */
export function fixtureRealtimeDiagnostic(
	text: string,
	environment: string | undefined,
	apiOrigin: string | undefined
): FixtureRealtimeDiagnostic | null {
	if (environment !== 'disposable') return null;
	const known = KNOWN_MESSAGES.find(([message]) => message.test(text));
	const match = known?.[0].exec(text);
	if (!match) return null;
	try {
		const socket = new URL(match[1]);
		const api = new URL(apiOrigin ?? '');
		if (api.hostname !== '127.0.0.1' || api.protocol !== 'http:' || socket.host !== api.host ||
			socket.username || socket.password || socket.pathname !== '/realtime/v1/websocket') return null;
		return known![1];
	} catch { return null; }
}
