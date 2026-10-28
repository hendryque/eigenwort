// Related articles, added ahead of the colophon once the app has them. Built
// from DOM calls, not markup, since the titles come from Wikipedia.
(function () {
    window.folioRelated = function (payload) {
        var old = document.querySelector('.folio-related');
        if (old) old.remove();
        var colophon = document.querySelector('.folio-colophon');
        if (!colophon || !payload || !payload.items || !payload.items.length) return;

        var section = document.createElement('section');
        section.className = 'folio-related';
        var heading = document.createElement('h2');
        heading.textContent = payload.heading;
        section.appendChild(heading);
        var list = document.createElement('ul');
        payload.items.forEach(function (item) {
            var row = document.createElement('li');
            var link = document.createElement('a');
            link.href = './' + encodeURIComponent(item.title.replace(/ /g, '_'));
            var picture = document.createElement('span');
            picture.className = 'folio-related-picture';
            if (item.thumbnailURL) {
                var img = document.createElement('img');
                img.src = item.thumbnailURL;
                img.alt = '';
                img.loading = 'lazy';
                picture.appendChild(img);
            }
            link.appendChild(picture);
            var text = document.createElement('span');
            text.className = 'folio-related-text';
            var title = document.createElement('span');
            title.className = 'folio-related-title';
            title.textContent = item.title;
            text.appendChild(title);
            if (item.summary) {
                var summary = document.createElement('span');
                summary.className = 'folio-related-summary';
                summary.textContent = item.summary;
                text.appendChild(summary);
            }
            link.appendChild(text);
            row.appendChild(link);
            list.appendChild(row);
        });
        section.appendChild(list);
        colophon.parentNode.insertBefore(section, colophon);
    };
})();
