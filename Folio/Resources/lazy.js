(function() {
    // Wikipedia hard-codes template colours in infoboxes. Strip those, but
    // keep geometry: location maps, collapsed rows and hidden scaffolding are
    // all built from inline position, size, display and visibility.
    var DROP_PROPERTY = /^(color|background|background-color|background-image|border-color|font-family|box-shadow|outline)$/;
    var BORDER_SHORTHAND = /^border(-top|-right|-bottom|-left)?$/;
    var BORDER_STYLE = /^(none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset)$/;
    var BORDER_WIDTH = /^(thin|medium|thick|[0-9.]+(px|em|rem|pt|ex|ch|vw|vh)?)$/;

    // Emit longhands rather than the shorthand: a shorthand resets
    // border-color to currentColor, which is near-black text, and being
    // inline it would beat the divider tone our CSS supplies.
    function borderLonghands(property, value) {
        var width = '', style = '';
        value.split(/\s+/).forEach(function(token) {
            var t = token.toLowerCase();
            if (BORDER_STYLE.test(t)) { style = t; }
            else if (BORDER_WIDTH.test(t)) { width = t; }
        });
        var out = [];
        if (width) out.push(property + '-width: ' + width);
        if (style) out.push(property + '-style: ' + style);
        return out;
    }

    function cleanInfoboxStyles() {
        // The box itself is ours entirely. de.wiki sets its padding, type
        // size, frame and width inline, and inline beats the card.
        document.querySelectorAll('.infobox[style]').forEach(function(box) {
            box.removeAttribute('style');
        });
        document.querySelectorAll('.infobox [style]').forEach(function(el) {
            var kept = [];
            el.getAttribute('style').split(';').forEach(function(declaration) {
                var split = declaration.indexOf(':');
                if (split < 0) return;
                var property = declaration.slice(0, split).trim().toLowerCase();
                var value = declaration.slice(split + 1).trim();
                if (!property || !value) return;
                if (DROP_PROPERTY.test(property)) return;
                if (BORDER_SHORTHAND.test(property)) {
                    kept.push.apply(kept, borderLonghands(property, value));
                    return;
                }
                kept.push(property + ': ' + value);
            });
            if (kept.length) {
                el.setAttribute('style', kept.join('; '));
            } else {
                el.removeAttribute('style');
            }
        });
    }

    // {{Multiple image}} sizes its cells so the pictures share one height and
    // rows them with a stylesheet we strip. Each cell's width becomes its share
    // of the row, so the row fills the column and the pictures still line up.
    function rowMultipleImages() {
        document.querySelectorAll('.tmulti .tsingle[style]').forEach(function(cell) {
            var width = parseFloat(cell.style.width);
            if (width > 0) cell.style.flex = width + ' 1 0';
        });
    }

    // de.wiki's {{Schachbrett}} and en.wiki's {{Chess diagram}} draw a board
    // for a 230px thumb. Mark it for article.css, which gives it the column,
    // and load the pieces as drawn, so they stay sharp at that size.
    var PIECE = /\/Chess_[^\/]*t45\.svg/;

    function setChessBoards() {
        var boards = new Set();
        document.querySelectorAll('img').forEach(function(img) {
            if (!PIECE.test(img.src)) return;
            var board = img.closest('.chessboard') || (img.closest('.thumbinner') || {}).parentElement;
            if (board) boards.add(board);
        });
        boards.forEach(function(board) {
            board.classList.add('folio-chess');
            board.querySelectorAll('img').forEach(function(img) {
                var file = original(img.src);
                if (!file) return;
                img.removeAttribute('srcset');
                img.src = file;
            });
            board.querySelectorAll('.chess-pieces').forEach(placePieces);
        });
    }

    // {{Chess diagram}} sets each piece in px on a board of fixed size, by a
    // stylesheet we strip. As shares of the board they scale with it.
    function placePieces(pieces) {
        var board = pieces.querySelector('img');
        var size = board && parseFloat(board.getAttribute('width'));
        if (!size) return;
        pieces.querySelectorAll(':scope > div').forEach(function(piece) {
            var img = piece.querySelector('img');
            var width = img && parseFloat(img.getAttribute('width'));
            piece.style.top = parseFloat(piece.style.top) / size * 100 + '%';
            piece.style.left = parseFloat(piece.style.left) / size * 100 + '%';
            if (width) piece.style.width = width / size * 100 + '%';
        });
    }

    // The file a Wikimedia thumbnail was made from, on the upload host.
    function original(src) {
        var path = src.split('?')[0].match(/(\/wikipedia\/[^\/]+)\/thumb(\/[^\/]+\/[^\/]+\/[^\/]+)\/[^\/]+$/);
        return path ? 'https://upload.wikimedia.org' + path[1] + path[2] : null;
    }

    // A figure is drawn as wide as the screen, 1125 pixels on a 3x phone, but
    // Wikipedia sends 330 or 500 and nothing larger. Offer Wikimedia's own
    // widths and let WebKit take what the screen needs: a drawing renders at
    // any width, a photo no wider than its file, and then the file itself.
    var WIDTHS = [500, 960, 1280];

    function wideSources(ph, src) {
        var file = parseInt(ph.getAttribute('data-data-file-width'), 10) || 0;
        var drawing = ph.getAttribute('data-data-file-type') === 'drawing';
        if (!drawing && !file) return null;
        var set = WIDTHS.filter(function(width) { return drawing || width < file; })
            .map(function(width) { return src.replace(/\/\d+px-/, '/' + width + 'px-') + ' ' + width + 'w'; });
        var whole = !drawing && file < WIDTHS[WIDTHS.length - 1] && original(src);
        if (whole) set.push(whole + ' ' + file + 'w');
        return set.length ? set.join(', ') : null;
    }

    function unwrap() {
        cleanInfoboxStyles();
        rowMultipleImages();
        var placeholders = document.querySelectorAll('.pcs-lazy-load-placeholder');
        placeholders.forEach(function(ph) {
            // Only unwrap <span> placeholders that have a data-src
            var src = ph.getAttribute('data-src');
            if (!src) return;

            var img = document.createElement('img');
            img.src = src;

            var srcset = ph.getAttribute('data-srcset');
            // Figures and gallery cells are drawn large; icons and pictures in
            // tables keep Wikipedia's size. A gallery cell is half the screen.
            var cls = ph.getAttribute('data-class');
            var gallery = cls && cls.indexOf('gallery-img') >= 0;
            var frame = ph.closest('figure, .thumb');
            var wide = (gallery || frame) && wideSources(ph, src);
            if (wide) {
                srcset = wide;
                img.sizes = gallery ? '50vw' : '100vw';
            }
            if (srcset) img.srcset = srcset;
            // A drawing keeps to the text column (article.css), a photo runs
            // edge to edge.
            if (frame && ph.getAttribute('data-data-file-type') === 'drawing') frame.classList.add('folio-drawing');

            var alt = ph.getAttribute('data-alt') || ph.getAttribute('alt') || '';
            if (alt) img.alt = alt;

            if (cls) img.className = cls;

            var w = ph.getAttribute('data-width');
            if (w) img.setAttribute('width', w);
            var h = ph.getAttribute('data-height');
            if (h) img.setAttribute('height', h);

            var style = ph.getAttribute('data-style');
            if (style) img.setAttribute('style', style);

            var decoding = ph.getAttribute('data-decoding');
            if (decoding) img.decoding = decoding;
            // Fifty figures in a long article load as they come near, not at once.
            var loading = ph.getAttribute('data-loading');
            if (loading) img.loading = loading;

            ph.parentNode.replaceChild(img, ph);
        });
        // After the placeholders: en.wiki's board picture is one of them.
        setChessBoards();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', unwrap);
    } else {
        unwrap();
    }
})();
