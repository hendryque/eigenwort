# App Store listing

What goes into App Store Connect for 1.0. The text keeps other apps' names
out, as Apple's metadata rules ask, and uses "Wikipedia" only to say what the
app reads.

## App information

| Field | Value |
|---|---|
| Name | Eigenwort |
| Subtitle | A reader for Wikipedia |
| Primary category | Reference |
| Secondary category | Education |
| Content rights | Does not contain, show or access third-party content: **No**. It shows Wikipedia, under CC BY-SA, with attribution on every article. |
| Age rating | Answer the questionnaire for Wikipedia's content as a whole: infrequent or mild for the themed categories, and no to gambling, contests and unrestricted web access (the app opens only Wikipedia). This lands at 12+. |
| Copyright | 2026 Scott-Hendryk Dillan |
| Support URL | https://github.com/hendryque/eigenwort/issues |
| Marketing URL | https://github.com/hendryque/eigenwort |
| Privacy policy URL | https://github.com/hendryque/eigenwort/blob/main/PRIVACY.md |
| Price | Free |

## Description

Eigenwort reads Wikipedia the way a good book reads: one column of text, set
in EB Garamond at a measured line length, with old-style figures, proper
hyphenation in English and German, and pictures that open to full screen.

Today shows the day's featured article, the most-read pages and the news as a
grid of photographs, so a glance tells you what the day is about. Nearby puts
the articles around you on a map. Search covers the whole encyclopedia, in
English or German with one tap.

Every article ends with a few related ones, and a word you select can be
looked up in Wiktionary, in English or German.

Five themes change the whole app, not only its colours. Light, Sepia and Dark
keep the book. De:Bug and Gimmick are tributes to two magazines, each with its
own typefaces and its own paper.

Articles you read, searches you make and bookmarks you keep stay with you,
synced through your own iCloud so your devices agree. Nothing about you goes
anywhere else except the requests Wikipedia needs to answer. There is no
account, no tracking and no advertising.

Eigenwort is open source.

## Keywords

Up to 100 characters, commas, no spaces. The name and subtitle are indexed
already, so "wikipedia" and "reader" would be wasted here:

```
wiki,encyclopedia,lexikon,reading,typography,garamond,articles,nearby,map,today,german,knowledge
```

## Promotional text

Shown above the description and changeable without a new build:

> A reader for Wikipedia, set like a book. Today's articles as a photo grid,
> the ones around you on a map, and five themes.

## What's new in 1.0

> First release.

## German localization

The listing in German, for the de.wikipedia readers it is half built for. The
app's own interface stays English, which the last paragraph says.

**Untertitel** (30 max): `Wikipedia lesen wie ein Buch`

**Werbetext** (170 max):

> Wikipedia, gesetzt wie ein Buch. Die Artikel des Tages als Fotoraster, die
> in deiner Nähe auf der Karte, und fünf Themen.

**Beschreibung:**

> Eigenwort liest Wikipedia so, wie sich ein gutes Buch liest: eine Spalte
> Text in EB Garamond mit maßvoller Zeilenlänge, mit Mediävalziffern,
> richtiger Silbentrennung auf Deutsch und Englisch, und Bildern, die sich
> bildschirmfüllend öffnen.
>
> Heute zeigt den Artikel des Tages, die meistgelesenen Seiten und die
> Nachrichten als Raster aus Fotos, so dass ein Blick genügt, um zu wissen,
> worum es an diesem Tag geht. In der Nähe legt die Artikel um dich herum auf
> eine Karte. Die Suche umfasst die ganze Enzyklopädie, auf Deutsch oder
> Englisch mit einem Tipp.
>
> Jeder Artikel endet mit einigen verwandten, und ein markiertes Wort schlägt
> Wiktionary nach, auf Deutsch oder Englisch.
>
> Fünf Themen verändern die ganze App, nicht nur ihre Farben. Hell, Sepia
> und Dunkel bleiben beim Buch. De:Bug und Gimmick sind Hommagen an zwei
> Zeitschriften, jede mit eigenen Schriften und eigenem Papier.
>
> Was du liest, wonach du suchst und was du dir merkst, bleibt bei dir,
> abgeglichen über deine eigene iCloud, damit deine Geräte dasselbe wissen.
> Nichts über dich geht sonst irgendwohin, außer den Anfragen, die Wikipedia
> zum Antworten braucht. Kein Konto, kein Tracking, keine Werbung.
>
> Eigenwort ist Open Source. Die Oberfläche der App ist auf Englisch.

**Schlüsselwörter** (100 max, 92):

```
wiki,enzyklopädie,lexikon,lesen,typografie,garamond,artikel,nähe,karte,heute,englisch,wissen
```

**Neue Funktionen in 1.0:** `Erste Version.`

The screenshots and the preview carry English captions; App Store Connect
falls back to the primary language's media when a localization has none, so
nothing needs uploading twice.

## Screenshots

`cd Tools/film && npm run store` renders four JPEGs for each upload slot in
App Store Connect, under `Tools/film/out/store/`: `6.9` (1320 × 2868) for
"iPhone with Dynamic Island, large display", `6.3` (1206 × 2622) for the
medium display, `6.5` (1242 × 2688) for the older slot. In order: Today, Set
like a book, Nearby, Two magazines.

## App preview

`npm run preview` renders `Tools/film/out/eigenwort-preview.mp4`: the film's
scenes without the opening, cut to 29.5 s at 886 × 1920, which every current
iPhone slot takes, with the silent audio track App Store Connect insists on.
Upload it to the same slots as the screenshots; it plays first.

## App privacy

The honest answers, from PRIVACY.md:

- **Location.** Declare *Precise Location*, used for *App Functionality*,
  *not linked to the user*, *not used for tracking*. The coordinates do leave
  the phone, to Wikipedia's geosearch, and that is what the question asks.
- **Everything else: not collected.** Reading history, searches and bookmarks
  stay on the device and in the reader's own private iCloud database, which
  the developer cannot read. Search terms go to Wikipedia as queries, which
  Apple's definition treats as using a service, not collecting data. Worth
  re-reading Apple's definitions once before submitting, now that sync exists.
- No tracking, no third-party SDKs.

## Review notes

> Eigenwort is an independent reader for Wikipedia. It uses Wikipedia's public
> APIs under the Wikimedia user-agent policy and shows every article with its
> CC BY-SA attribution. "Wikipedia" appears in the subtitle descriptively;
> the app does not claim affiliation with the Wikimedia Foundation.
>
> No account or sign-in is needed. The Nearby tab asks for location when
> opened; any location works, for instance Apple Park. Everything else is
> reachable from the first screen.

## Before submitting

- The app record's name is Eigenwort (the SKU cannot change and does not
  matter).
- Build 1.0 (the commit count) is the one tested on TestFlight.
- Export compliance is answered by `ITSAppUsesNonExemptEncryption = NO` in
  the build.
