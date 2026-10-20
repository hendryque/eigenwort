import React from 'react';
import {AbsoluteFill} from 'remotion';
import {LayoutContext, tall} from './layout';
import {Backdrop, Look, Phone, ink} from './parts';

/** A README screenshot in the film's look: caption above, phones below. */
const Frame: React.FC<{top: string; bottom: string; look?: Look; children: React.ReactNode}> = ({top, bottom, look = 'light', children}) => (
	// Portrait, so the tall backdrops crop better than the wide.
	<LayoutContext.Provider value={tall}>
		<AbsoluteFill>
			{children}
			<AbsoluteFill style={{alignItems: 'center', paddingTop: 70}}>
				<div style={{fontFamily: 'EBG', fontSize: 78, lineHeight: 1, color: ink[look].strong}}>
					{top} <span style={{fontStyle: 'italic', color: ink[look].quiet}}>{bottom}</span>
				</div>
			</AbsoluteFill>
		</AbsoluteFill>
	</LayoutContext.Provider>
);

// The caption's 70 + 78 + 56, so every phone ends at the same height.
const PHONE_TOP = 204;

const Shot: React.FC<{image: string; top: string; bottom: string; look?: Look}> = ({image, top, bottom, look = 'light'}) => (
	<Frame top={top} bottom={bottom} look={look}>
		<Backdrop look={look} />
		<AbsoluteFill style={{alignItems: 'center', paddingTop: PHONE_TOP}}>
			<Phone image={image} height={1130} />
		</AbsoluteFill>
	</Frame>
);

// Each magazine on its own paper, split on a slant through the overlap.
const Magazines: React.FC = () => (
	<Frame top="Two" bottom="magazines" look="debug">
		<Backdrop look="debug" />
		<div style={{position: 'absolute', inset: 0, clipPath: 'polygon(57% 0, 100% 0, 100% 100%, 43% 100%)'}}>
			<Backdrop look="gimmick" />
		</div>
		<div style={{position: 'absolute', left: 30, top: PHONE_TOP + 66}}>
			<Phone image="stills/debug.png" height={1060} />
		</div>
		<div style={{position: 'absolute', right: 30, top: PHONE_TOP + 130}}>
			<Phone image="stills/gimmick.png" height={1000} />
		</div>
	</Frame>
);

export const ShotToday = () => <Shot image="stills/today.png" top="Today" bottom="at a glance" />;
export const ShotTypography = () => <Shot image="stills/typography.png" top="Set" bottom="like a book" />;
export const ShotMagazines = () => <Magazines />;
