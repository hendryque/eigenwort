import React from 'react';
import {Composition, Still, continueRender, delayRender, staticFile} from 'remotion';
import {FilmStore, FilmTall, FilmWide} from './Film';
import {store, tall, wide} from './layout';
import {ShotMagazines, ShotNearby, ShotToday, ShotTypography} from './Shots';
import {FPS, frames} from './timing';

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
		<Composition id="Film" component={FilmWide} width={wide.width} height={wide.height} fps={FPS} durationInFrames={frames(wide.cut.total)} />
		<Composition id="FilmPortrait" component={FilmTall} width={tall.width} height={tall.height} fps={FPS} durationInFrames={frames(tall.cut.total)} />
		{/* The preview at Apple's stated 886 × 1920 and at the medium and large devices' own resolutions. */}
		{Object.entries({Preview: [store.width, store.height], PreviewMedium: [1206, 2622], PreviewLarge: [1320, 2868]}).map(([id, [width, height]]) => (
			<Composition key={id} id={id} component={FilmStore} width={width} height={height} fps={FPS} durationInFrames={frames(store.cut.total)} />
		))}
		{/* Each shot at the README's size and at the App Store's large, medium and 6.5-inch sizes. */}
		{Object.entries({Today: ShotToday, Typography: ShotTypography, Nearby: ShotNearby, Magazines: ShotMagazines}).map(([name, component]) => (
			<React.Fragment key={name}>
				<Still id={`Shot${name}`} component={component} width={900} height={1400} />
				<Still id={`Store${name}`} component={component} width={1320} height={2868} />
				<Still id={`Store63${name}`} component={component} width={1206} height={2622} />
				<Still id={`Store65${name}`} component={component} width={1242} height={2688} />
			</React.Fragment>
		))}
	</>
);
