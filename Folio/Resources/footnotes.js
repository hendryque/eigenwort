(function() {
    // Markers arrive as "./Title#cite_note-…", not "#cite_note-…", so match on
    // the fragment. Testing the raw href for a leading "#" left every one inert.
    function noteId(link) {
        const href = link.getAttribute('href') || '';
        const hash = href.indexOf('#');
        if (hash < 0) return null;
        let id = href.slice(hash + 1);
        try { id = decodeURIComponent(id); } catch (e) {}
        return id.startsWith('cite_note') ? id : null;
    }

    function getReferenceContent(targetId) {
        const refElement = document.getElementById(targetId);
        if (!refElement) return null;
        const refText = refElement.querySelector('.reference-text, .mw-reference-text');
        return (refText || refElement).innerHTML;
    }

    function findParagraphAncestor(el) {
        let cur = el;
        for (let i = 0; i < 8 && cur && cur !== document.body; i++) {
            if (cur.tagName === 'P' || cur.tagName === 'LI' || cur.tagName === 'BLOCKQUOTE') {
                return cur;
            }
            cur = cur.parentElement;
        }
        return null;
    }

    document.addEventListener('click', function(event) {
        const link = event.target.closest('a');
        if (!link) return;
        const id = noteId(link);
        if (!id) return;

        event.preventDefault();
        event.stopPropagation();

        const anchorEl = link.closest('sup') || link;
        const paragraph = findParagraphAncestor(anchorEl) || anchorEl;

        const next = paragraph.nextElementSibling;
        if (next && next.classList.contains('folio-footnote') && next.dataset.refid === id) {
            next.remove();
            return;
        }

        const content = getReferenceContent(id);
        if (!content) return;
        const aside = document.createElement('aside');
        aside.className = 'folio-footnote';
        aside.dataset.refid = id;
        aside.innerHTML = content;
        paragraph.insertAdjacentElement('afterend', aside);
    }, true);
})();
