import React from 'react';
import {
	Easing,
	Img,
	OffthreadVideo,
	interpolate,
	spring,
	staticFile,
	useCurrentFrame,
	useVideoConfig,
} from 'remotion';
import {useLayout} from './layout';
import {FPS, frames} from './timing';

// The recordings are the iPhone 17 Pro's 1206 × 2622 screen.
export const SCREEN = {width: 1206, height: 2622};
// The display's corner radius, 55 pt of its 402 pt width.
const CORNER = 55 / 402;

export type Look = 'light' | 'sepia' | 'dark' | 'debug' | 'gimmick';

/** Card ink per backdrop, so type stays readable as the themes change. */
export const ink: Record<Look, {strong: string; quiet: string}> = {
	light: {strong: '#1c1b19', quiet: '#7a7366'},
	sepia: {strong: '#3d2f1d', quiet: '#76614a'},
	dark: {strong: '#e8e8ea', quiet: '#9a9a9c'},
	debug: {strong: '#1c1b19', quiet: '#6b6862'},
	gimmick: {strong: '#1a1a1a', quiet: '#086bad'},
};

export const Backdrop: React.FC<{look: Look; opacity?: number}> = ({look, opacity = 1}) => (
	<Img
		src={staticFile(`backdrops/${look}-${useLayout().shape}.png`)}
		style={{position: 'absolute', inset: 0, width: '100%', height: '100%', objectFit: 'cover', opacity}}
	/>
);

/** In over the first frames, out over the last, for a scene's own layers. */
export const useFade = (length: number, edge = 12) => {
	const frame = useCurrentFrame();
	return interpolate(frame, [0, edge, length - edge, length], [0, 1, 1, 0], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});
};

/** A gentle arrival: from `distance` px below, settling with a spring. */
export const useArrival = (delay = 0, distance = 40) => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();
	const progress = spring({frame: frame - delay, fps, config: {damping: 200}});
	return {opacity: progress, transform: `translateY(${(1 - progress) * distance}px)`};
};

export const Card: React.FC<{top: string; bottom: string; look?: Look; size?: number; delay?: number}> = ({
	top,
	bottom,
	look = 'light',
	size,
	delay = 0,
}) => {
	const {card} = useLayout();
	const arrival = useArrival(delay, 30);
	const line: React.CSSProperties = {fontFamily: 'EBG', fontSize: size ?? card.size, lineHeight: 1.02, letterSpacing: '-0.005em'};
	return (
		<div style={{...arrival, textAlign: card.align}}>
			<div style={{...line, color: ink[look].strong}}>{top}</div>
			<div style={{...line, fontStyle: 'italic', color: ink[look].quiet}}>{bottom}</div>
		</div>
	);
};

type Media = {clip: {file: string; start: number}} | {image: string};

/** The screen alone, no bezel, floating on the page with a soft shadow. */
export const Phone: React.FC<Media & {height: number; children?: React.ReactNode}> = (props) => {
	const width = Math.round((props.height * SCREEN.width) / SCREEN.height);
	const fill: React.CSSProperties = {width: '100%', height: '100%', display: 'block'};
	return (
		<div
			style={{
				width,
				height: props.height,
				borderRadius: width * CORNER,
				overflow: 'hidden',
				position: 'relative',
				background: '#fff',
				boxShadow: '0 50px 90px rgba(40,30,10,.22), 0 10px 24px rgba(40,30,10,.10)',
			}}
		>
			{'clip' in props ? (
				<OffthreadVideo src={staticFile(props.clip.file)} startFrom={frames(props.clip.start)} muted style={fill} />
			) : (
				<Img src={staticFile(props.image)} style={fill} />
			)}
			{props.children}
		</div>
	);
};

/**
 * A fingertip, since iOS records no touches. `x`, `y` and `toY` are shares of
 * the screen; `at` is in seconds of the scene. A tap presses in, a drag slides.
 */
export const Touch: React.FC<{x: number; y: number; at: number; toY?: number; over?: number}> = ({
	x,
	y,
	at,
	toY,
	over = 0,
}) => {
	const t = useCurrentFrame() / FPS;
	const appear = interpolate(t, [at - 0.25, at - 0.12, at + over + 0.15, at + over + 0.35], [0, 0.9, 0.9, 0], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});
	if (appear <= 0) return null;
	const press = over > 0 ? 0.9 : interpolate(t, [at - 0.08, at, at + 0.12], [1, 0.8, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
	const top =
		toY === undefined
			? y
			: interpolate(t, [at, at + over], [y, toY], {
					extrapolateLeft: 'clamp',
					extrapolateRight: 'clamp',
					easing: Easing.inOut(Easing.quad),
				});
	return (
		<div
			style={{
				position: 'absolute',
				left: `${x * 100}%`,
				top: `${top * 100}%`,
				width: '11%',
				aspectRatio: '1',
				transform: `translate(-50%, -50%) scale(${press})`,
				borderRadius: '50%',
				background: 'rgba(255,255,255,.55)',
				border: '2px solid rgba(0,0,0,.14)',
				boxShadow: '0 6px 18px rgba(0,0,0,.22)',
				opacity: appear,
			}}
		/>
	);
};
