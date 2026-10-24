import React from 'react';
import {AbsoluteFill, useVideoConfig} from 'remotion';
import {LayoutContext, tall} from './layout';
import {Backdrop, Look, Phone, ink} from './parts';

/** Caption and phone sizes: the README's 900 × 1400 as set, the store's in proportion to the height. */
const metrics = (width: number, height: number) =>
	width > 1000
		? {caption: 0.041 * height, top: 0.066 * height, gap: 0.035 * height, phone: 0.788 * height, bottom: 0.07 * height}
		: {caption: 78, top: 70, gap: 56, phone: 1130, bottom: 66};
type Metrics = ReturnType<typeof metrics>;
const captionBottom = (m: Metrics) => m.top + m.caption + m.gap;

/** A screenshot in the film's look: caption above, phones below. */
const Frame: React.FC<{top: string; bottom: string; look?: Look; children: (m: Metrics) => React.ReactNode}> = ({
	top,
	bottom,
	look = 'light',
	children,
}) => {
	const {width, height} = useVideoConfig();
	const m = metrics(width, height);
	return (
		// Portrait, so the tall backdrops crop better than the wide.
		<LayoutContext.Provider value={tall}>
			<AbsoluteFill>
				{children(m)}
				<AbsoluteFill style={{alignItems: 'center', paddingTop: m.top}}>
					<div style={{fontFamily: 'EBG', fontSize: m.caption, lineHeight: 1, color: ink[look].strong}}>
						{top} <span style={{fontStyle: 'italic', color: ink[look].quiet}}>{bottom}</span>
					</div>
				</AbsoluteFill>
			</AbsoluteFill>
		</LayoutContext.Provider>
	);
};

const Shot: React.FC<{image: string; top: string; bottom: string; look?: Look}> = ({image, top, bottom, look = 'light'}) => (
	<Frame top={top} bottom={bottom} look={look}>
		{(m) => (
			<>
				<Backdrop look={look} />
				<AbsoluteFill style={{alignItems: 'center', paddingTop: captionBottom(m)}}>
					<Phone image={image} height={m.phone} />
				</AbsoluteFill>
			</>
		)}
	</Frame>
);

// Each magazine on its own paper, split on a slant through the overlap. The
// pair is laid out for 900 wide, scaled with the canvas and centred below the caption.
const Magazines: React.FC = () => {
	const {width, height} = useVideoConfig();
	const k = width / 900;
	return (
		<Frame top="Two" bottom="magazines" look="debug">
			{(m) => {
				const pair = 1130 * k;
				const top = captionBottom(m) + Math.max(0, (height - captionBottom(m) - m.bottom - pair) / 2);
				return (
					<>
						<Backdrop look="debug" />
						<div style={{position: 'absolute', inset: 0, clipPath: 'polygon(57% 0, 100% 0, 100% 100%, 43% 100%)'}}>
							<Backdrop look="gimmick" />
						</div>
						<div style={{position: 'absolute', left: 30 * k, top: top + 66 * k}}>
							<Phone image="stills/debug.png" height={1060 * k} />
						</div>
						<div style={{position: 'absolute', right: 30 * k, top: top + 130 * k}}>
							<Phone image="stills/gimmick.png" height={1000 * k} />
						</div>
					</>
				);
			}}
		</Frame>
	);
};

export const ShotToday = () => <Shot image="stills/today.png" top="Today" bottom="at a glance" />;
export const ShotTypography = () => <Shot image="stills/typography.png" top="Set" bottom="like a book" />;
export const ShotNearby = () => <Shot image="stills/nearby.png" top="Nearby" bottom="around you" />;
export const ShotMagazines = () => <Magazines />;
