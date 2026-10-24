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

// The film, scene by scene, in seconds.
export const scenes = {
	opening: {from: 0, length: 4},
	today: {from: 4, length: 7.5},
	nearby: {from: 11.5, length: 7},
	type: {from: 18.5, length: 9},
	themes: {from: 27.5, length: 10},
	end: {from: 37.5, length: 5},
} as const;

export const total = 42.5;
export const frames = (seconds: number) => Math.round(seconds * FPS);
