(function() {
    var lastReported = 0;
    var rafScheduled = false;
    var endTimer = null;

    function emit() {
        var y = window.scrollY || window.pageYOffset || 0;
        if (Math.abs(y - lastReported) < 8) return;
        lastReported = y;
        var remaining = Math.max(0, document.documentElement.scrollHeight - (y + window.innerHeight));
        try {
            window.webkit?.messageHandlers?.scroll?.postMessage({ y: y, remaining: remaining });
        } catch (e) {}
    }

    // rAF-throttle while scrolling so the bar can hide on the first movement; a
    // trailing timeout reports where a fling actually came to rest.
    window.addEventListener('scroll', function() {
        if (!rafScheduled) {
            rafScheduled = true;
            requestAnimationFrame(function() {
                emit();
                rafScheduled = false;
            });
        }
        if (endTimer) clearTimeout(endTimer);
        endTimer = setTimeout(emit, 120);
    }, { passive: true });

    // Native calls this after didFinish if there's a saved position.
    window.folioRestoreScroll = function(y) {
        if (typeof y !== 'number' || y <= 0) return;
        // Wait for layout to settle, then jump
        requestAnimationFrame(function() {
            window.scrollTo(0, y);
            // Report the landing, or the reader's first real scroll would be
            // mistaken for arriving and the bar would stay up.
            lastReported = -Infinity;
            emit();
        });
    };
})();
