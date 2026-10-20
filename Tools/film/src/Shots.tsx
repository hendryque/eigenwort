import React from 'react';
import {AbsoluteFill} from 'remotion';
import {Backdrop, Look, Phone, ink} from './parts';

/** A README screenshot in the film's look: caption above the screen. */
const Shot: React.FC<{image: string; top: string; bottom: string; look?: Look}> = ({image, top, bottom, look = 'light'}) => (
	<AbsoluteFill>
		<Backdrop look={look} />
		<AbsoluteFill style={{alignItems: 'center', paddingTop: 70}}>
			<div style={{fontFamily: 'EBG', fontSize: 78, lineHeight: 1, marginBottom: 56, color: ink[look].strong}}>
				{top} <span style={{fontStyle: 'italic', color: ink[look].quiet}}>{bottom}</span>
			</div>
			<Phone image={image} height={1130} />
		</AbsoluteFill>
	</AbsoluteFill>
);

export const ShotToday = () => <Shot image="stills/today.png" top="Today" bottom="at a glance" />;
export const ShotTypography = () => <Shot image="stills/typography.png" top="Set" bottom="like a book" />;
export const ShotGimmick = () => <Shot image="stills/gimmick.png" top="Gimmick" bottom="after Yps" look="gimmick" />;
