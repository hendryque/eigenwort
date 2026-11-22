// article.css sizes a heading by its widest word, which only the page can
// measure in the face the theme gives it. A title or heading still too wide at
// its floor may hyphenate; nothing else does.
(function () {
    var canvas = document.createElement('canvas').getContext('2d');
    var root = document.documentElement;

    // In em, with CSS letter-spacing after every character as WebKit sets it.
    function widest(heading) {
        var style = getComputedStyle(heading);
        canvas.font = style.fontStyle + ' ' + style.fontWeight + ' 100px ' + style.fontFamily;
        var tracking = (parseFloat(style.letterSpacing) || 0) / parseFloat(style.fontSize);
        return heading.textContent.split(/\s+|(?<=[-‐–—])/).reduce(function (most, piece) {
            if (!piece) return most;
            return Math.max(most, canvas.measureText(piece).width / 100 + piece.length * tracking);
        }, 0);
    }

    // Still too wide only at the floor, where article.css stops shrinking. Not
    // by overflow: the body's break-word breaks the word at a letter instead.
    function hyphenate() {
        var body = getComputedStyle(document.body);
        var room = document.body.clientWidth - parseFloat(body.paddingLeft) - parseFloat(body.paddingRight);
        var display = Array.prototype.slice.call(document.querySelectorAll('.folio-title, h2, h3, h4'));
        var over = display.map(function (el) {
            var style = getComputedStyle(el);
            var em = parseFloat(style.getPropertyValue('--folio-fit-em')) || 0;
            return em * parseFloat(style.fontSize) > room + 0.5;
        });
        display.forEach(function (el, i) { el.classList.toggle('folio-fit-hyphenate', over[i]); });
    }

    function fit() {
        document.querySelectorAll('h2, h3, h4').forEach(function (heading) {
            var em = widest(heading);
            if (em > 0) heading.style.setProperty('--folio-fit-em', em.toFixed(3));
            else heading.style.removeProperty('--folio-fit-em');
        });
        hyphenate();
    }

    // A theme switch changes the faces; a pinch, the Settings slider or a turn
    // of the phone only the sizes. One frame takes all of a gesture's changes.
    var queued = null;
    function later(work) {
        if (queued) {
            if (work === fit) queued = fit;
            return;
        }
        queued = work;
        requestAnimationFrame(function () {
            var run = queued;
            queued = null;
            run();
        });
    }
    new MutationObserver(function () { later(fit); })
        .observe(document.body, { attributes: true, attributeFilter: ['data-theme'] });
    new MutationObserver(function () { later(hyphenate); })
        .observe(root, { attributes: true, attributeFilter: ['style'] });
    window.addEventListener('resize', function () { later(hyphenate); });

    // painted.js calls this once the theme's faces have loaded, before the reveal.
    window.folioFit = fit;
})();
