// Seconds into each recording, measured from the clips record.sh makes:
// frame differences for the tap and the scroll, the page's ground colour for
// each theme. Re-measure after re-recording.
export const FPS = 30;

export const clips = {
	today: {file: 'clips/today.mp4', start: 4.3, tap: 8.7},
	read: {file: 'clips/read.mp4', start: 1.9, scrollFrom: 3.55, scrollTo: 7.45},
	themes: {
		file: 'clips/themes.mp4',
		start: 2.2,
		switches: [
			{theme: 'sepia', at: 4.0},
			{theme: 'dark', at: 5.65},
			{theme: 'debug', at: 7.4},
			{theme: 'gimmick', at: 9.05},
		],
	},
} as const;

// The film, scene by scene, in seconds.
export const scenes = {
	opening: {from: 0, length: 4},
	today: {from: 4, length: 7.5},
	type: {from: 11.5, length: 8},
	themes: {from: 19.5, length: 10},
	end: {from: 29.5, length: 5},
} as const;

export const total = 34.5;
export const frames = (seconds: number) => Math.round(seconds * FPS);
