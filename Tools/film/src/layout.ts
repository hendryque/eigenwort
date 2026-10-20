import React from 'react';

/** Where the film's parts sit; the scenes and their timing are the same in both. */
export type Layout = {
	shape: 'wide' | 'tall';
	width: number;
	height: number;
	phone: {height: number; slot: React.CSSProperties};
	card: {slot: React.CSSProperties; size: number; themesSize: number; align: 'left' | 'center'};
	zoom: {shown: number; slot: React.CSSProperties};
};

// Cards on the left, the phone on the right, as the storyboard set them.
export const wide: Layout = {
	shape: 'wide',
	width: 1920,
	height: 1080,
	phone: {height: 900, slot: {position: 'absolute', right: 170, top: 90}},
	card: {slot: {position: 'absolute', left: 150, top: '50%', transform: 'translateY(-50%)'}, size: 124, themesSize: 104, align: 'left'},
	zoom: {shown: 820, slot: {position: 'absolute', right: 470, top: 300}},
};

// Cards above the phone; the magnified passage spans the width over its lower half.
export const tall: Layout = {
	shape: 'tall',
	width: 1080,
	height: 1920,
	phone: {height: 1240, slot: {position: 'absolute', left: (1080 - Math.round((1240 * 1206) / 2622)) / 2, top: 590}},
	card: {slot: {position: 'absolute', left: 0, right: 0, top: 210}, size: 116, themesSize: 92, align: 'center'},
	zoom: {shown: 980, slot: {position: 'absolute', left: 50, top: 1080}},
};

export const LayoutContext = React.createContext<Layout>(wide);
export const useLayout = () => React.useContext(LayoutContext);
