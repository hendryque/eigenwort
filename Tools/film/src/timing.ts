// Seconds into each recording, measured from the clips record.sh makes:
// frame differences for the tap and the scroll, the page's ground colour for
// each theme. Re-measure after re-recording.
export const FPS = 30;

export const clips = {
	today: {file: 'clips/today.mp4', start: 5.0, tap: 8.85},
	nearby: {file: 'clips/nearby.mp4', start: 2.6, tap: 6.45},
	read: {file: 'clips/read.mp4', start: 1.9, scrollFrom: 3.6, scrollTo: 7.4},
	themes: {
		file: 'clips/themes.mp4',
		start: 2.1,
		switches: [
			{theme: 'sepia', at: 3.9},
			{theme: 'dark', at: 5.55},
			{theme: 'debug', at: 7.35},
			{theme: 'gimmick', at: 8.95},
		],
	},
} as const;

// A cut: the scenes in order, each in seconds, and the whole. A length of
// zero leaves the scene out.
export type SceneKey = 'opening' | 'today' | 'nearby' | 'type' | 'themes' | 'end';
export type Cut = {scenes: Record<SceneKey, {from: number; length: number}>; total: number};
const cut = (lengths: Record<SceneKey, number>): Cut => {
	let from = 0;
	const scenes = {} as Cut['scenes'];
	for (const key of Object.keys(lengths) as SceneKey[]) {
		scenes[key] = {from, length: lengths[key]};
		from += lengths[key];
	}
	return {scenes, total: from};
};

export const film = cut({opening: 4, today: 7.5, nearby: 7, type: 9, themes: 10, end: 5});
// The App Store preview: under 30 s, and the listing already shows the icon.
export const preview = cut({opening: 0, today: 6, nearby: 5.5, type: 8, themes: 8, end: 2});
export const frames = (seconds: number) => Math.round(seconds * FPS);
