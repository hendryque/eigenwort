import React from 'react';
import {Composition, Still, continueRender, delayRender, staticFile} from 'remotion';
import {FilmTall, FilmWide} from './Film';
import {tall, wide} from './layout';
import {ShotMagazines, ShotToday, ShotTypography} from './Shots';
import {FPS, frames, total} from './timing';

// EB Garamond, as bundled with the app, before anything renders.
const fonts = delayRender('EB Garamond');
Promise.all([
	new FontFace('EBG', `url(${staticFile('fonts/EBGaramond-Regular.otf')})`, {weight: '400'}).load(),
	new FontFace('EBG', `url(${staticFile('fonts/EBGaramond-Italic.otf')})`, {weight: '400', style: 'italic'}).load(),
]).then((faces) => {
	faces.forEach((face) => document.fonts.add(face));
	continueRender(fonts);
});

export const Root: React.FC = () => (
	<>
		<Composition id="Film" component={FilmWide} width={wide.width} height={wide.height} fps={FPS} durationInFrames={frames(total)} />
		<Composition id="FilmPortrait" component={FilmTall} width={tall.width} height={tall.height} fps={FPS} durationInFrames={frames(total)} />
		<Still id="ShotToday" component={ShotToday} width={900} height={1400} />
		<Still id="ShotTypography" component={ShotTypography} width={900} height={1400} />
		<Still id="ShotMagazines" component={ShotMagazines} width={900} height={1400} />
	</>
);
