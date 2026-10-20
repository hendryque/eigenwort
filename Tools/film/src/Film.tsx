import React from 'react';
import {AbsoluteFill, Img, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {Backdrop, Card, Look, Phone, SCREEN, Touch, ink, useArrival, useFade} from './parts';
import {FPS, clips, frames, scenes} from './timing';

const PHONE_H = 900;
// Cards on the left, the phone on the right, as the storyboard set them.
const cardSlot: React.CSSProperties = {position: 'absolute', left: 150, top: '50%', transform: 'translateY(-50%)'};
const phoneSlot: React.CSSProperties = {position: 'absolute', right: 170, top: (1080 - PHONE_H) / 2};

const Title: React.FC<{extra?: string}> = ({extra}) => {
	const icon = useArrival(0, 20);
	const name = useArrival(8, 30);
	const line = useArrival(18, 30);
	const small = useArrival(30, 20);
	return (
		<AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column'}}>
			<Img
				src={staticFile('icon.png')}
				style={{width: 170, height: 170, borderRadius: 38, boxShadow: '0 24px 50px rgba(40,30,10,.18)', marginBottom: 34, ...icon}}
			/>
			<div style={{fontFamily: 'EBG', fontSize: 150, lineHeight: 1, color: ink.light.strong, ...name}}>Eigenwort</div>
			<div style={{fontFamily: 'EBG', fontStyle: 'italic', fontSize: 52, color: ink.light.quiet, marginTop: 18, ...line}}>
				A reader for Wikipedia
			</div>
			{extra && (
				<div style={{font: '400 26px ui-monospace, Menlo, monospace', color: '#8a8273', marginTop: 50, ...small}}>{extra}</div>
			)}
		</AbsoluteFill>
	);
};

const Opening: React.FC = () => (
	<AbsoluteFill style={{opacity: useFade(frames(scenes.opening.length))}}>
		<Title />
	</AbsoluteFill>
);

const Today: React.FC = () => {
	const clip = clips.today;
	return (
		<AbsoluteFill style={{opacity: useFade(frames(scenes.today.length))}}>
			<div style={cardSlot}>
				<Card top="Today" bottom="at a glance" />
			</div>
			<div style={{...phoneSlot, ...useArrival(4, 60)}}>
				<Phone clip={clip} height={PHONE_H}>
					{/* The featured article, top left of the grid. */}
					<Touch x={0.25} y={0.27} at={clip.tap - clip.start - 0.1} />
				</Phone>
			</div>
		</AbsoluteFill>
	);
};

// The passage magnified: old-style 1925 to 1933, three hyphenations and an
// italic Bauhaus, in source pixels of the read clip's last frame.
const ZOOM = {x: 50, y: 910, width: 1110, height: 620, shown: 820, at: 6};

const Typography: React.FC = () => {
	const clip = clips.read;
	const frame = useCurrentFrame();
	const scale = ZOOM.shown / ZOOM.width;
	const zoomIn = interpolate(frame, [frames(ZOOM.at), frames(ZOOM.at + 0.5)], [0, 1], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
	});
	return (
		<AbsoluteFill style={{opacity: useFade(frames(scenes.type.length))}}>
			<div style={{...cardSlot, opacity: 1 - zoomIn * 0.85}}>
				<Card top="Set" bottom="like a book" />
			</div>
			<div style={{...phoneSlot, ...useArrival(4, 60)}}>
				<Phone clip={clip} height={PHONE_H}>
					<Touch x={0.62} y={0.78} toY={0.3} at={clip.scrollFrom - clip.start} over={clip.scrollTo - clip.scrollFrom} />
				</Phone>
			</div>
			<div
				style={{
					position: 'absolute',
					right: 470,
					top: 300,
					width: ZOOM.shown,
					height: ZOOM.height * scale,
					borderRadius: 22,
					overflow: 'hidden',
					background: '#fff',
					boxShadow: '0 40px 80px rgba(40,30,10,.22), 0 8px 20px rgba(40,30,10,.10)',
					opacity: zoomIn,
					transform: `scale(${0.92 + zoomIn * 0.08})`,
				}}
			>
				<OffthreadVideo
					src={staticFile(clip.file)}
					startFrom={frames(clip.start)}
					muted
					style={{
						position: 'absolute',
						width: SCREEN.width * scale,
						height: SCREEN.height * scale,
						left: -ZOOM.x * scale,
						top: -ZOOM.y * scale,
						maxWidth: 'none',
					}}
				/>
			</div>
		</AbsoluteFill>
	);
};

const Themes: React.FC = () => {
	const clip = clips.themes;
	const t = useCurrentFrame() / FPS;
	// Each theme's backdrop fades in as the app switches to it.
	const fades = clip.switches.map((s) =>
		interpolate(t, [s.at - clip.start, s.at - clip.start + 0.4], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}),
	);
	const current: Look = clip.switches.reduce<Look>((look, s, i) => (fades[i] > 0.5 ? s.theme : look), 'light');
	return (
		<AbsoluteFill style={{opacity: useFade(frames(scenes.themes.length))}}>
			<Backdrop look="light" />
			{clip.switches.map((s, i) => (
				<Backdrop key={s.theme} look={s.theme} opacity={fades[i]} />
			))}
			<div style={cardSlot}>
				<Card top="Five themes" bottom="two of them magazines" look={current} size={104} />
			</div>
			<div style={{...phoneSlot, ...useArrival(4, 60)}}>
				<Phone clip={clip} height={PHONE_H}>
					{/* The theme button, fourth of six in the bar. */}
					{clip.switches.map((s) => (
						<Touch key={s.theme} x={0.57} y={0.923} at={s.at - clip.start - 0.15} />
					))}
				</Phone>
			</div>
		</AbsoluteFill>
	);
};

const End: React.FC = () => (
	<AbsoluteFill style={{opacity: useFade(frames(scenes.end.length), 15)}}>
		<Title extra="Free and open source · github.com/hendryque/folio" />
	</AbsoluteFill>
);

export const Film: React.FC = () => {
	const scene = (key: keyof typeof scenes, node: React.ReactNode) => (
		<Sequence from={frames(scenes[key].from)} durationInFrames={frames(scenes[key].length)}>
			{node}
		</Sequence>
	);
	return (
		<AbsoluteFill>
			<Backdrop look="light" />
			{scene('opening', <Opening />)}
			{scene('today', <Today />)}
			{scene('type', <Typography />)}
			{scene('themes', <Themes />)}
			{scene('end', <End />)}
		</AbsoluteFill>
	);
};
