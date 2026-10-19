// End matter. Reference sections with nothing else visible go, heading and
// all, though their lists stay in the DOM for footnotes.js. Appendices are
// marked so article.css can set them as consulting matter.
(function () {
    function ownHeading(section) {
        var headings = section.querySelectorAll('h2, h3, h4, h5, h6');
        for (var i = 0; i < headings.length; i++) {
            if (headings[i].closest('section') === section) return headings[i];
        }
        return null;
    }

    function onlyHeadingRenders(section) {
        var heading = ownHeading(section);
        if (!heading) return false;
        var nodes = section.childNodes;
        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            if (node.nodeType === Node.TEXT_NODE) {
                if (node.textContent.trim()) return false;
                continue;
            }
            if (node.nodeType !== Node.ELEMENT_NODE || node.contains(heading)) continue;
            if (node.offsetHeight > 0) return false;
        }
        return true;
    }

    function hide(section) {
        section.classList.add('folio-reference-section');
        // A parent whose subsections were all references goes too, so en.wiki's
        // "References" does not linger once "Notes" and "Citations" are gone.
        var parent = section.parentElement && section.parentElement.closest('section');
        if (parent && !parent.classList.contains('folio-reference-section') && onlyHeadingRenders(parent)) {
            hide(parent);
        }
    }

    // Both wikis standardise their appendix headings in their layout guidelines.
    var APPENDIX = /^(siehe auch|literatur|weblinks|anmerkungen|einzelnachweise|see also|notes|footnotes|references|notes and references|citations|sources|bibliography|works cited|general references|further reading|external links)$/i;
    document.querySelectorAll('section').forEach(function (section) {
        var heading = ownHeading(section);
        if (heading && APPENDIX.test(heading.textContent.trim())) section.classList.add('folio-endmatter');
    });

    document.querySelectorAll('ol.references').forEach(function (list) {
        var section = list.closest('section');
        if (section && !section.classList.contains('folio-reference-section') && onlyHeadingRenders(section)) {
            hide(section);
        }
    });
})();
