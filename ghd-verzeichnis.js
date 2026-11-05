// ============================================================
// GHD-VERZEICHNIS.JS — Inhaltsverzeichnis aller Apps
// A Great Hair Day
//
// Einbinden (eine Zeile, am Ende von <body>):
//   <script src="https://mirjamwalenta-a11y.github.io/index.greathairday/ghd-verzeichnis.js" defer></script>
//
// Optionen als Attribute am <script>-Tag:
//   data-unten="90"        Mindestabstand des Knopfs vom unteren Rand in px (Standard 16).
//                          Liegt unten links eine feste Leiste oder ein Knopf der App,
//                          rückt der Verzeichnis-Knopf automatisch darüber.
//   data-links-breit="296" Abstand von links in px auf breiten Bildschirmen,
//   data-breit-ab="900"    ab dieser Breite (z. B. wenn die App links eine feste Seitenleiste hat)
//   data-verstecken-bei="#loginScreen"  Knopf ausblenden, solange dieses Element sichtbar ist
//                          (z. B. der Anmeldebildschirm)
//
// Neue App oder neue Unterseite? Nur unten in KAPITEL eintragen.
//
// Sicherheit: Das Verzeichnis zeigt nur Links. Jede App schützt sich weiterhin
// selbst (Login, RLS). Kapitel mit `chefin: true` sieht nur die Inhaberin:
// Das Verzeichnis fragt dazu die bestehende Server-Funktion
// teamapp_ist_inhaberin() mit der Anmeldung der Person ab. Das blendet nur
// Einträge aus – es ist KEIN Zugriffsschutz (der liegt in den Apps/RLS).
// Lokal gemerkt werden nur „Zuletzt benutzt“ (Namen der Apps) und das
// Ergebnis der Rollenprüfung (pro Konto, 12 Stunden, für offline).
// ============================================================
(function () {
  'use strict';
  if (window.__ghdVerzeichnis) return;
  window.__ghdVerzeichnis = true;

  var SKRIPT = document.currentScript;
  var B = 'https://mirjamwalenta-a11y.github.io';
  var W = 'https://www.greathairday.at';
  var HB = B + '/Mitarbeiterhandbuch/Mitarbeiterhandbuch_App.html';

  // ---------- Inhalt ----------
  // n = Name, s = Untertitel, u = Adresse, k = Suchwörter, kids = Unterpunkte
  var KAPITEL = [
    { t: 'Täglich im Salon', apps: [
      { n: 'Checklisten', s: 'Tagesaufgaben & Bereiche', i: 'checks', u: B + '/salon-checklist/salon-checklist.html', k: 'aufgaben putzen einkauf einkaufsliste öffnen schließen sop' },
      { n: 'Zeitverwaltung', s: 'Stempeln & Zeiten', i: 'clock', u: B + '/abwesenheiten-ghd/zeitverwaltung.html', k: 'arbeitszeit stunden überstunden zeitkonto', kids: [
        { n: 'Stempeln', u: B + '/abwesenheiten-ghd/stempel-qr.html', k: 'einstempeln ausstempeln qr tablet' } ] },
      { n: 'Abwesenheit', s: 'Urlaub & Krankenstand', i: 'cal', u: B + '/abwesenheiten-ghd/abwesenheiten.html', k: 'urlaub krank krankenstand krankmeldung frei antrag urlaubsantrag' },
      { n: 'Team', s: 'Mitteilungen & Besprechungen', i: 'chat', u: B + '/Team/team.html', k: 'nachricht mitteilung besprechung meeting', kids: [
        { n: 'Neue Mitarbeiter:in anmelden', u: B + '/Team/anmeldung.html', k: 'anmeldung personal neue mitarbeiterin neuer mitarbeiter eintritt onboarding zugang anlegen' } ] }
    ] },
    { t: 'Lernen & Ausbildung', apps: [
      { n: 'Handbuch', s: 'Richtlinien & Standards', i: 'book', u: HB, k: 'regeln standards mitarbeiterhandbuch', kids: [
        ['01', 'Kundenempfang', 's01'], ['02', 'Kunden-Einstiegsgespräch', 's02'], ['03', 'Kunden-Beratungsgespräch', 's03'],
        ['04', 'Die Haarwäsche', 's04'], ['05', 'Haar- und Kopfhautpflege', 's05'], ['06', 'Neukundenbetreuung', 's06'],
        ['07', 'Service', 's07'], ['08', 'Haare schneiden', 's08'], ['09', 'Styling / Finish', 's09'], ['10', 'Farbbehandlung', 's10'],
        ['11', 'Dauerwelle-Behandlung', 's11'], ['12', 'Telefongesprächsführung', 's12'], ['13', 'Terminvereinbarung', 's13'],
        ['14', 'Kassenabwicklung', 's14'], ['15', 'Gäste-Verabschiedung', 's15'], ['16', 'Reklamationen', 's16'],
        ['17', 'Beschwerden', 's17'], ['18', 'Unser Auftreten – das Äußere', 's18'], ['19', 'Unser Auftreten – Limbic Check', 's19'],
        ['20', 'Unser Teamkodex', 's20'], ['', 'Häufige Situationen', 'situationen'], ['', 'Salon-Info', 'back'],
        ['', 'Wissensbank', 'wissensbank'], ['', 'Fachwissen Farbe', 'rezepturen']
      ].map(function (x) { return { num: x[0], n: x[1], u: HB + '#' + x[2] }; }) },
      { n: 'Lernquiz', s: 'Quiz & Prüfungsvorbereitung', i: 'scissors', u: B + '/lernquiz.greathairday/lernquiz.html', k: 'prüfung quiz lap lehrabschluss', kids: [
        { n: 'Zwischenprüfung', u: B + '/lernquiz.greathairday/zwischenpruefung.html' },
        { n: 'Werkzeugkunde', u: B + '/lernquiz.greathairday/werkzeugkunde.html' },
        { n: 'Beratung & Formwirkung', u: B + '/lernquiz.greathairday/beratung-formwirkung.html' },
        { n: 'Englisch im Salon', u: B + '/lernquiz.greathairday/englisch-salon.html' },
        { n: 'Schnittwerkstatt', u: B + '/lernquiz.greathairday/schnittwerkstatt.html' },
        { n: 'Schnittzeichnungs-Designer', u: B + '/lernquiz.greathairday/schnittdesigner.html' },
        { n: 'Meisterin', u: B + '/lernquiz.greathairday/meisterin.html', k: 'meisterprüfung' } ] },
      { n: 'Lerntool', s: 'Lernkarten & Themen', i: 'cards', u: B + '/lernquiz.greathairday/lerntool.html', k: 'lernkarten lernen themen' },
      { n: 'Schnuppertag', s: 'Lehrlings-Auswahl & Probezeit', i: 'spark', u: B + '/lernquiz.greathairday/schnuppertag.html', k: 'lehrling schnuppern probezeit' }
    ] },
    { t: 'Büro & Verwaltung', chefin: true, apps: [
      { n: 'Bewerbungen', s: 'Bewerbungen, Matcher & Formular', i: 'person', u: B + '/index.greathairday/bewerbungen.html', k: 'bewerbung bewerber lebenslauf stelle job personal recruiting', kids: [
        { n: 'Salon-Matcher', u: B + '/index.greathairday/bewerber.html', k: 'matcher passend' },
        { n: 'Bewerbungsformular', u: B + '/index.greathairday/karriere.html', k: 'karriere bei uns arbeiten interesse melden' },
        { n: 'Recruiting-Cockpit', u: B + '/moment.greathairday/recruiting-cockpit.html', k: 'mitarbeitersuche' },
        { n: 'Bewerber-Vorlagen', u: B + '/moment.greathairday/bewerber-vorlagen.html', k: 'antwort absage einladung' },
        { n: 'Fit-Check', u: B + '/moment.greathairday/fit-check.html' } ] },
      { n: 'Lager', s: 'Bestand & Bestellungen', i: 'box', u: B + '/lager.greathairday/Lager_index.html', k: 'bestand bestellen bestellung nachbestellen produkte shampoo farbe lieferant' },
      { n: 'Belege', s: 'Rechnungen & Steuerberater', i: 'receipt', u: B + '/belege.greathairday/belege.html', k: 'rechnung steuer steuerberater buchhaltung quittung', kids: [
        { n: 'Cockpit', u: B + '/belege.greathairday/cockpit.html', k: 'übersicht zahlen' } ] },
      { n: 'Schrank', s: 'Dokumente & Tresor', i: 'cabinet', u: B + '/dokumentenschrank-ghd/dokumentenschrank.html', k: 'dokumente verträge dienstvertrag tresor ablage passwörter' }
    ] },
    { t: 'Marketing & Assistent', chefin: true, apps: [
      { n: 'Reichweite', s: 'Posts, Storys & Hooks', i: 'mega', u: B + '/moment.greathairday/', k: 'instagram posts storys social media marketing', kids: [
        { n: 'Instagram-Mappe', u: B + '/moment.greathairday/instagram.html' },
        { n: 'Video + Text', u: B + '/moment.greathairday/video.html', k: 'reel' },
        { n: 'Clips & Fotos', u: B + '/moment.greathairday/montage.html', k: 'montage bilder' },
        { n: 'Spruch-Vorlagen', u: B + '/moment.greathairday/sprueche.html', k: 'sprüche zitate' } ] },
      { n: 'Wörni', s: 'KI-Assistent & Aufträge', i: 'bot', u: B + '/index.greathairday/schaltzentrale.html', k: 'ki assistent aufträge aufgaben schaltzentrale tagesübersicht', kids: [
        { n: 'Sprechen', u: B + '/index.greathairday/mikro.html', k: 'mikro diktieren sprache' } ] }
    ] },
    { t: 'Website', chefin: true, apps: [
      { n: 'Website', s: 'greathairday.at', i: 'globe', u: W + '/', k: 'homepage internetseite online', kids: [
        { n: 'Leistungen & Preise', u: W + '/leistungen.html', k: 'preisliste angebot behandlungen' },
        { n: 'Karriere – offene Stellen', u: W + '/karriere/', k: 'jobs stellen lehrling stylistin stellenanzeige' },
        { n: 'Impressum', u: W + '/#impressum' },
        { n: 'Datenschutz', u: W + '/datenschutz.html', k: 'dsgvo datenschutzerklärung' } ] },
      { n: 'Preise & Texte', s: 'Website-Inhalte bearbeiten', i: 'pen', u: W + '/Preise-und-Texte-bearbeiten.html', k: 'preise ändern texte bearbeiten preisliste aktualisieren' },
      { n: 'Bewertung', s: 'Kund:innen um Bewertung bitten', i: 'star', u: W + '/bewertung/', k: 'bewertung rezension google sterne feedback review qr' },
      { n: 'HaarKompass', s: 'Pflege-Guide für Kund:innen', i: 'compass', u: W + '/haarkompass/', k: 'haarkompass pflege empfehlung fragebogen kunden', kids: [
        { n: 'HaarKompass-Post erstellen', u: B + '/moment.greathairday/haarkompass-post.html', k: 'instagram reichweite beitrag' } ] }
    ] },
    { t: 'Sonstiges', chefin: true, apps: [
      { n: 'Innung', s: 'Seminare & Trainer:innen', i: 'pillars', u: B + '/innungsapp.greathairday/innungsapp.html', k: 'seminar trainer weiterbildung' },
      { n: 'Haarnetzwerk', s: 'Verein, Sponsoring & Sponsorenwand', i: 'network', k: 'verein sponsoren sponsoring kooperation', kids: [
        { n: 'Verein', u: B + '/index.greathairday/verein.html', k: 'mitglieder vereinsverwaltung' },
        { n: 'Kooperationspakete', u: B + '/index.greathairday/sponsoring.html', k: 'sponsoring pakete' },
        { n: 'Sponsorenwand', u: B + '/index.greathairday/sponsorenwand.html', k: 'danke veranstaltung bild' } ] }
    ] }
  ];
  var ALLE_GESAMT = [];
  KAPITEL.forEach(function (c) { c.apps.forEach(function (a) { a.kids = a.kids || []; a.chefin = !!c.chefin; ALLE_GESAMT.push(a); }); });

  // ---------- Rolle (nur zum Ein-/Ausblenden) ----------
  var SB_URL = 'https://wrxlaltgtgkdomklgrlj.supabase.co';
  var SB_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndyeGxhbHRndGdrZG9ta2xncmxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyNDYwMzYsImV4cCI6MjA5OTgyMjAzNn0.Bw8ch-EJb_cLYTwxHdpjUJWgoCjje3Jc32pB0yiBS8g'; // öffentlicher anon-Schlüssel
  var TOKEN_KEY = 'sb-wrxlaltgtgkdomklgrlj-auth-token'; // gemeinsames Fach der E-Mail-Apps (siehe ghd-sitzung.js)
  var ROLLE_KEY = 'ghd_verzeichnis_rolle';
  var ROLLE_GILT_MS = 12 * 60 * 60 * 1000;
  var istChefin = false, rolleGeprueft = false, pruefungLaeuft = false;

  function anmeldung() {
    try {
      var t = JSON.parse(localStorage.getItem(TOKEN_KEY) || 'null');
      if (t && t.currentSession) t = t.currentSession;
      if (!t || !t.access_token || !t.user || !t.user.id) return null;
      return { token: t.access_token, id: t.user.id };
    } catch (e) { return null; }
  }
  function rolleAusSpeicher(id) {
    try {
      var r = JSON.parse(localStorage.getItem(ROLLE_KEY) || 'null');
      if (r && r.id === id && Date.now() - r.zeit < ROLLE_GILT_MS) return !!r.chefin;
    } catch (e) { /* egal */ }
    return false;
  }
  function rolleMerken(id, chefin) {
    try { localStorage.setItem(ROLLE_KEY, JSON.stringify({ id: id, chefin: !!chefin, zeit: Date.now() })); } catch (e) { /* egal */ }
  }
  function rollePruefen(fertig) {
    var a = anmeldung();
    if (!a) { istChefin = false; rolleGeprueft = true; if (fertig) fertig(); return; }
    istChefin = rolleAusSpeicher(a.id); // sofort, auch offline
    if (pruefungLaeuft) return;
    pruefungLaeuft = true;
    fetch(SB_URL + '/rest/v1/rpc/teamapp_ist_inhaberin', {
      method: 'POST',
      headers: { apikey: SB_KEY, authorization: 'Bearer ' + a.token, 'content-type': 'application/json' },
      body: '{}'
    }).then(function (r) { return r.ok ? r.json() : null; })
      .then(function (ja) {
        if (ja === true || ja === false) { istChefin = ja; rolleMerken(a.id, ja); rolleGeprueft = true; }
      })
      .catch(function () { /* offline: gemerktes Ergebnis bleibt */ })
      .then(function () { pruefungLaeuft = false; if (fertig) fertig(); });
  }
  function sichtbareKapitel() { return KAPITEL.filter(function (c) { return !c.chefin || istChefin; }); }
  function sichtbareApps() { return ALLE_GESAMT.filter(function (a) { return !a.chefin || istChefin; }); }
  var ALLE = ALLE_GESAMT; // für die Erkennung der aktuellen Seite

  // ---------- Symbole (feine Linien) ----------
  var SYM = {
    menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
    x: '<path d="M6 6l12 12M18 6 6 18"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
    chev: '<path d="m9 6 6 6-6 6"/>',
    checks: '<path d="m3 17 2 2 4-4M3 7l2 2 4-4M13 6h8M13 12h8M13 18h8"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    cal: '<rect x="3.5" y="5" width="17" height="16" rx="2"/><path d="M8 3v4M16 3v4M3.5 10h17"/>',
    chat: '<path d="M20 15a2 2 0 0 1-2 2H8l-4 4V6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2z"/>',
    book: '<path d="M2.5 5h6a3.5 3.5 0 0 1 3.5 3.5V20a2.5 2.5 0 0 0-2.5-2.5h-7zM21.5 5h-6A3.5 3.5 0 0 0 12 8.5V20a2.5 2.5 0 0 1 2.5-2.5h7z"/>',
    scissors: '<circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M20 4 8.1 15.9M14.5 14.5 20 20M8.1 8.1 12 12"/>',
    cards: '<rect x="3" y="7" width="14" height="14" rx="2"/><path d="M7 3h12a2 2 0 0 1 2 2v12"/>',
    spark: '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8zM19 16l.7 1.8 1.8.7-1.8.7L19 21l-.7-1.8-1.8-.7 1.8-.7z"/>',
    person: '<circle cx="10" cy="8" r="3.5"/><path d="M3.5 20a6.5 6.5 0 0 1 13 0M18 8v6M15 11h6"/>',
    box: '<path d="M21 7.5 12 3 3 7.5v9L12 21l9-4.5z"/><path d="M3 7.5 12 12l9-4.5M12 12v9"/>',
    receipt: '<path d="M5 3v18l2.3-1.5L9.7 21l2.3-1.5 2.3 1.5 2.4-1.5L19 21V3l-2.3 1.5L14.3 3 12 4.5 9.7 3 7.3 4.5z"/><path d="M9 9h6M9 13h6"/>',
    cabinet: '<rect x="4.5" y="3" width="15" height="18" rx="1.5"/><path d="M4.5 12h15M10 7.5h4M10 16.5h4"/>',
    mega: '<path d="M3 10.5v3a1 1 0 0 0 1 1h2.5L13 19V5L6.5 9.5H4a1 1 0 0 0-1 1z"/><path d="M16.5 9a4 4 0 0 1 0 6M19.5 6a8 8 0 0 1 0 12"/>',
    bot: '<rect x="4" y="8" width="16" height="12" rx="3"/><path d="M12 8V5M9.5 13.5v1M14.5 13.5v1"/><circle cx="12" cy="4" r="1"/>',
    globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
    pen: '<path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16z"/><path d="m13.5 6.5 4 4"/>',
    star: '<path d="m12 3.5 2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z"/>',
    compass: '<circle cx="12" cy="12" r="9"/><path d="m15.5 8.5-2 5-5 2 2-5z"/>',
    pillars: '<path d="M3 21h18M5.5 18V11M10 18V11M14 18V11M18.5 18V11M3 8.5 12 3l9 5.5z"/>',
    network: '<circle cx="12" cy="5" r="2.3"/><circle cx="5" cy="18.5" r="2.3"/><circle cx="19" cy="18.5" r="2.3"/><path d="M11 7.1 6 16.4M13 7.1l5 9.3M7.3 18.5h9.4"/>'
  };
  function ic(n, cls) { return '<svg class="ghdv-i' + (cls ? ' ' + cls : '') + '" viewBox="0 0 24 24" aria-hidden="true">' + (SYM[n] || '') + '</svg>'; }

  // ---------- Hilfen ----------
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  // Suche: Groß/Klein, Umlaute und Endungen egal
  function norm(s) {
    return String(s).toLowerCase().replace(/ä/g, 'a').replace(/ö/g, 'o').replace(/ü/g, 'u').replace(/ß/g, 'ss')
      .replace(/ae/g, 'a').replace(/oe/g, 'o').replace(/ue/g, 'u').replace(/[^a-z0-9 ]/g, ' ');
  }
  function stamm(w) { return w.replace(/(en|er|n|s|e)$/, ''); }
  function woerter(t) { return norm(t).split(/\s+/).filter(function (w) { return w.length > 1; }).map(stamm).filter(Boolean); }
  function trifft(text, ws) { var h = norm(text); return ws.every(function (w) { return h.indexOf(w) >= 0; }); }
  function ohneHash(u) { return String(u).split('#')[0].split('?')[0].replace(/index\.html$/, ''); }

  var RAHMEN = B + '/index.greathairday/rahmen.html';
  function imRahmen() {
    try { return window.top !== window && !!window.top.__ghdRahmen; } catch (e) { return false; }
  }
  function alsAppInstalliert() {
    try {
      return (window.matchMedia && (window.matchMedia('(display-mode: standalone)').matches ||
        window.matchMedia('(display-mode: fullscreen)').matches || window.matchMedia('(display-mode: minimal-ui)').matches)) ||
        window.navigator.standalone === true;
    } catch (e) { return false; }
  }

  var ZULETZT_KEY = 'ghd_verzeichnis_zuletzt';
  function zuletztLaden() { try { var v = JSON.parse(localStorage.getItem(ZULETZT_KEY) || '[]'); return Array.isArray(v) ? v : []; } catch (e) { return []; } }
  function zuletztMerken(name) {
    try { var l = zuletztLaden().filter(function (x) { return x !== name; }); l.unshift(name); localStorage.setItem(ZULETZT_KEY, JSON.stringify(l.slice(0, 3))); } catch (e) { /* egal */ }
  }

  // Aktuelle App/Unterseite erkennen
  var hier = ohneHash(location.href), hierHash = location.hash;
  var aktApp = null, aktKid = null;
  ALLE.forEach(function (a) {
    if (a.u && ohneHash(a.u) === hier && !aktApp) aktApp = a;
    a.kids.forEach(function (k) {
      if (ohneHash(k.u) !== hier) return;
      var kh = k.u.indexOf('#') >= 0 ? '#' + k.u.split('#')[1] : '';
      if (kh && kh !== hierHash) return;
      if (kh || !aktApp) { aktApp = a; aktKid = k; }
    });
  });
  if (aktApp) zuletztMerken(aktApp.n);

  // ---------- Aussehen ----------
  var opt = SKRIPT ? SKRIPT.dataset : {};
  var unten = parseInt(opt.unten || '16', 10) || 16;
  var linksBreit = parseInt(opt.linksBreit || '0', 10) || 0;
  var breitAb = parseInt(opt.breitAb || '900', 10) || 900;
  var versteckenBei = opt.versteckenBei || '';

  var CSS = '' +
    '.ghdv-root{--ghdv-brown:#9c6b3f;--ghdv-brown-dark:#7a5330;--ghdv-ink:#211c17;--ghdv-ink-mid:#4a433c;--ghdv-ink-light:#8a7f6e;' +
    '--ghdv-cream:#faf7f0;--ghdv-paper:#fffdf8;--ghdv-rule:#ddd0bb;--ghdv-chip:#f3ead9;--ghdv-border:#ecdfc4;' +
    'font-family:"Manrope",system-ui,-apple-system,"Segoe UI",sans-serif;font-size:15px;line-height:1.45;color:var(--ghdv-ink);-webkit-text-size-adjust:100%}' +
    '.ghdv-root *,.ghdv-root *::before,.ghdv-root *::after{box-sizing:border-box}' +
    '.ghdv-root button{font:inherit;color:inherit;background:none;border:0;margin:0;cursor:pointer;-webkit-tap-highlight-color:transparent}' +
    '.ghdv-root a{color:inherit;text-decoration:none;-webkit-tap-highlight-color:transparent}' +
    '.ghdv-i{width:20px;height:20px;flex:none;fill:none;stroke:currentColor;stroke-width:1.5;stroke-linecap:round;stroke-linejoin:round}' +
    '.ghdv-root :focus-visible{outline:2px solid var(--ghdv-brown);outline-offset:2px}' +
    '.ghdv-root .ghdv-fab{position:fixed;left:calc(16px + env(safe-area-inset-left,0px));bottom:calc(var(--ghdv-unten,' + unten + 'px) + env(safe-area-inset-bottom,0px));z-index:390;' +
    'width:48px;height:48px;border-radius:50%;display:grid;place-items:center;background:var(--ghdv-cream);color:var(--ghdv-brown-dark);' +
    'border:1px solid var(--ghdv-rule)!important;box-shadow:0 4px 14px rgba(33,28,23,.14)}' +
    '.ghdv-root .ghdv-fab:hover{background:var(--ghdv-chip)}.ghdv-fab[hidden]{display:none!important}' +
    (linksBreit ? '@media (min-width:' + breitAb + 'px){.ghdv-root .ghdv-fab{left:' + linksBreit + 'px}}' : '') +
    '.ghdv-scrim{position:fixed;inset:0;background:rgba(33,28,23,.38);z-index:2147483000;opacity:0;pointer-events:none;transition:opacity .25s}' +
    '.ghdv-side{position:fixed;top:0;bottom:0;left:0;z-index:2147483001;width:min(320px,88vw);background:var(--ghdv-cream);border-right:1px solid var(--ghdv-rule);' +
    'display:flex;flex-direction:column;transform:translateX(-102%);transition:transform .28s cubic-bezier(.4,0,.2,1);visibility:hidden;' +
    'padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px);padding-left:env(safe-area-inset-left,0px)}' +
    '.ghdv-offen .ghdv-side{transform:none;visibility:visible}.ghdv-offen .ghdv-scrim{opacity:1;pointer-events:auto}' +
    '@media (prefers-reduced-motion:reduce){.ghdv-side,.ghdv-scrim{transition:none}}' +
    '.ghdv-head{padding:20px 16px 14px 20px;border-bottom:1px solid var(--ghdv-rule);display:flex;align-items:flex-start;justify-content:space-between;gap:8px}' +
    '.ghdv-eyebrow{font-size:10.5px;letter-spacing:.22em;text-transform:uppercase;color:var(--ghdv-brown)}' +
    '.ghdv-title{font-family:"Newsreader",Georgia,"Times New Roman",serif;font-weight:500;font-size:24px;line-height:1.15;margin-top:4px}' +
    '.ghdv-close{width:40px;height:40px;display:grid;place-items:center;border-radius:8px;color:var(--ghdv-ink-mid)}' +
    '.ghdv-close:hover{background:var(--ghdv-chip)}' +
    '.ghdv-search{margin:14px 16px 4px;position:relative;display:block}' +
    '.ghdv-search .ghdv-i{position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--ghdv-ink-light);width:18px;height:18px}' +
    '.ghdv-search input{width:100%;height:44px;border:1px solid var(--ghdv-border);border-radius:10px;background:var(--ghdv-paper);margin:0;' +
    'padding:0 12px 0 38px;font:inherit;font-size:16px;color:var(--ghdv-ink);-webkit-appearance:none;appearance:none}' +
    '.ghdv-search input::placeholder{color:var(--ghdv-ink-light)}.ghdv-search input:focus{outline:none;border-color:var(--ghdv-brown)}' +
    '.ghdv-nav{flex:1;overflow-y:auto;-webkit-overflow-scrolling:touch;overscroll-behavior:contain;padding:4px 0 20px}' +
    '.ghdv-lbl-sec{font-size:10.5px;letter-spacing:.2em;text-transform:uppercase;color:var(--ghdv-ink-light);padding:18px 20px 6px;font-weight:600}' +
    '.ghdv-recent{display:flex;gap:6px;flex-wrap:wrap;padding:2px 16px 4px}' +
    '.ghdv-recent a{display:flex;align-items:center;gap:6px;border:1px solid var(--ghdv-border);background:var(--ghdv-paper);border-radius:999px;padding:6px 12px 6px 9px;font-size:13px;color:var(--ghdv-ink-mid)}' +
    '.ghdv-recent .ghdv-i{width:16px;height:16px;color:var(--ghdv-brown)}' +
    '.ghdv-row{display:flex;align-items:stretch}' +
    '.ghdv-item{display:flex;align-items:center;gap:14px;flex:1;min-width:0;width:100%;text-align:left;padding:9px 20px;min-height:46px;color:var(--ghdv-ink);font-size:15px}' +
    '.ghdv-item>.ghdv-i{color:var(--ghdv-brown)}' +
    '.ghdv-item:hover,.ghdv-tog:hover{background:var(--ghdv-chip)}' +
    '.ghdv-item[aria-current="page"]{background:var(--ghdv-chip);box-shadow:inset 2px 0 0 var(--ghdv-brown)}' +
    '.ghdv-t{flex:1;min-width:0}' +
    '.ghdv-sub{display:block;font-size:12px;color:var(--ghdv-ink-light);line-height:1.3}' +
    '.ghdv-tog{width:48px;flex:none;display:grid;place-items:center;color:var(--ghdv-ink-light)}' +
    '.ghdv-tog .ghdv-i{width:18px;height:18px;transition:transform .2s}' +
    '.ghdv-tog[aria-expanded="true"] .ghdv-i{transform:rotate(90deg)}' +
    '.ghdv-kids .ghdv-item{padding-left:54px;min-height:40px;font-size:14px;color:var(--ghdv-ink-mid)}' +
    '.ghdv-num{font-family:"Newsreader",Georgia,serif;font-style:italic;color:var(--ghdv-brown);min-width:22px;font-size:14px}' +
    '.ghdv-leer{padding:16px 20px 6px;color:var(--ghdv-ink-light);font-size:14px}' +
    '.ghdv-root mark{background:none;color:var(--ghdv-brown-dark);font-weight:700}';

  function fontsLaden() {
    if (document.querySelector('link[href*="family=Newsreader"]') && document.querySelector('link[href*="family=Manrope"]')) return;
    var l = document.createElement('link');
    l.rel = 'stylesheet';
    l.href = 'https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700&family=Newsreader:ital,wght@0,500;1,400&display=swap';
    document.head.appendChild(l);
  }

  // ---------- Aufbau ----------
  var root, nav, q, offeneGruppen = {};
  if (aktApp && aktApp.kids.length) offeneGruppen[aktApp.n] = true;

  function hl(s, ws) {
    if (!ws.length) return esc(s);
    var w = ws[0], h = norm(s), ix = h.indexOf(w);
    return ix < 0 ? esc(s) : esc(s.slice(0, ix)) + '<mark>' + esc(s.slice(ix, ix + w.length)) + '</mark>' + esc(s.slice(ix + w.length));
  }
  function appLink(a, ws) {
    var cur = (a === aktApp && !aktKid) ? ' aria-current="page"' : '';
    var inner = ic(a.i) + '<span class="ghdv-t">' + hl(a.n, ws || []) + '<span class="ghdv-sub">' + esc(a.s) + '</span></span>';
    if (!a.u) return '<button type="button" class="ghdv-item" data-tog="' + esc(a.n) + '"' + cur + '>' + inner + '</button>';
    return '<a class="ghdv-item" href="' + esc(a.u) + '" data-app="' + esc(a.n) + '"' + cur + '>' + inner + '</a>';
  }
  function kidLink(a, k, ws, mitApp) {
    var cur = k === aktKid ? ' aria-current="page"' : '';
    if (mitApp) {
      return '<a class="ghdv-item" href="' + esc(k.u) + '" data-app="' + esc(a.n) + '"' + cur + '>' + ic(a.i) +
        '<span class="ghdv-t">' + hl(k.n, ws) + '<span class="ghdv-sub">' + esc(a.n) + (k.num ? ' · Kapitel ' + esc(k.num) : '') + '</span></span></a>';
    }
    return '<a class="ghdv-item" href="' + esc(k.u) + '" data-app="' + esc(a.n) + '"' + cur + '>' +
      (k.num !== undefined ? '<span class="ghdv-num">' + esc(k.num) + '</span>' : '') + '<span class="ghdv-t">' + esc(k.n) + '</span></a>';
  }
  function appZeile(a) {
    if (!a.kids.length) return appLink(a);
    var offen = !!offeneGruppen[a.n];
    var h = '<div class="ghdv-row">' + appLink(a) + '<button type="button" class="ghdv-tog" data-tog="' + esc(a.n) + '" aria-expanded="' + offen + '" aria-label="Unterpunkte von ' + esc(a.n) + '">' + ic('chev') + '</button></div>';
    if (offen) h += '<div class="ghdv-kids">' + a.kids.map(function (k) { return kidLink(a, k, [], false); }).join('') + '</div>';
    return h;
  }

  function zeichnen() {
    var ws = woerter(q.value), h = '';
    if (!ws.length) {
      var zl = zuletztLaden().map(function (n) { return sichtbareApps().filter(function (a) { return a.n === n && a.u; })[0]; }).filter(Boolean);
      if (zl.length) {
        h += '<div class="ghdv-lbl-sec">Zuletzt benutzt</div><div class="ghdv-recent">' +
          zl.map(function (a) { return '<a href="' + esc(a.u) + '" data-app="' + esc(a.n) + '">' + ic(a.i) + esc(a.n) + '</a>'; }).join('') + '</div>';
      }
      sichtbareKapitel().forEach(function (c) { h += '<div class="ghdv-lbl-sec">' + esc(c.t) + '</div>' + c.apps.map(appZeile).join(''); });
      nav.innerHTML = h;
      return;
    }
    var ALLE = sichtbareApps();
    var appT = ALLE.filter(function (a) { return trifft(a.n + ' ' + a.s + ' ' + (a.k || ''), ws); });
    var kidT = [];
    ALLE.forEach(function (a) { a.kids.forEach(function (k) { if (trifft(k.n + ' ' + (k.k || ''), ws)) kidT.push([a, k]); }); });
    if (appT.length) h += '<div class="ghdv-lbl-sec">Apps</div>' + appT.map(function (a) { return appLink(a, ws); }).join('');
    if (kidT.length) h += '<div class="ghdv-lbl-sec">Direkt zu</div>' + kidT.map(function (x) { return kidLink(x[0], x[1], ws, true); }).join('');
    if (!appT.length && !kidT.length) {
      // Ähnliche Treffer: jedes Wort einzeln, nur die ersten 4 Buchstaben
      var kurz = ws.map(function (w) { return w.slice(0, 4); }).filter(function (w) { return w.length >= 3; });
      var nah = [];
      ALLE.forEach(function (a) {
        if (kurz.some(function (w) { return norm(a.n + ' ' + a.s + ' ' + (a.k || '')).indexOf(w) >= 0; })) nah.push([a, null]);
        a.kids.forEach(function (k) { if (kurz.some(function (w) { return norm(k.n + ' ' + (k.k || '')).indexOf(w) >= 0; })) nah.push([a, k]); });
      });
      h += '<div class="ghdv-leer">Nichts gefunden für „' + esc(q.value.trim()) + '“.' + (nah.length ? ' Meintest du vielleicht:' : ' Versuch ein anderes Wort, z. B. Rechnung, Urlaub oder Haarwäsche.') + '</div>';
      h += nah.slice(0, 6).map(function (x) { return x[1] ? kidLink(x[0], x[1], [], true) : appLink(x[0], []); }).join('');
    }
    nav.innerHTML = h;
  }

  function oeffnen() {
    zeichnen();
    rollePruefen(function () { if (root.classList.contains('ghdv-offen')) zeichnen(); });
    root.classList.add('ghdv-offen');
    root.querySelector('.ghdv-side').setAttribute('aria-hidden', 'false');
    var akt = nav.querySelector('[aria-current="page"]');
    if (akt && akt.scrollIntoView) akt.scrollIntoView({ block: 'center' });
    // Am Handy nicht automatisch die Tastatur öffnen
    if (window.matchMedia && window.matchMedia('(hover:hover) and (pointer:fine)').matches) q.focus();
    else root.querySelector('.ghdv-close').focus({ preventScroll: true });
  }
  function schliessen() {
    root.classList.remove('ghdv-offen');
    root.querySelector('.ghdv-side').setAttribute('aria-hidden', 'true');
    q.blur();
  }

  function aufbauen() {
    if (document.getElementById('ghdv-root')) return;
    fontsLaden();
    var st = document.createElement('style');
    st.id = 'ghdv-style';
    st.textContent = CSS;
    document.head.appendChild(st);

    root = document.createElement('div');
    root.id = 'ghdv-root';
    root.className = 'ghdv-root';
    root.innerHTML =
      '<button type="button" class="ghdv-fab" aria-label="Alle Apps" title="Alle Apps" aria-controls="ghdv-side">' + ic('menu') + '</button>' +
      '<div class="ghdv-scrim"></div>' +
      '<nav class="ghdv-side" id="ghdv-side" aria-label="Alle Apps" aria-hidden="true">' +
        '<div class="ghdv-head"><div><div class="ghdv-eyebrow">A Great Hair Day</div><div class="ghdv-title">Alle Apps</div></div>' +
        '<button type="button" class="ghdv-close" aria-label="Verzeichnis schließen">' + ic('x') + '</button></div>' +
        '<label class="ghdv-search">' + ic('search') +
        '<input type="search" id="ghdv-q" placeholder="Was suchst du? z. B. Urlaub" autocomplete="off" enterkeyhint="search" aria-label="Apps durchsuchen"></label>' +
        '<div class="ghdv-nav"></div>' +
      '</nav>';
    document.body.appendChild(root);
    nav = root.querySelector('.ghdv-nav');
    q = root.querySelector('#ghdv-q');

    root.querySelector('.ghdv-fab').addEventListener('click', oeffnen);
    root.querySelector('.ghdv-close').addEventListener('click', schliessen);
    root.querySelector('.ghdv-scrim').addEventListener('click', schliessen);
    q.addEventListener('input', zeichnen);
    q.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') { var erster = nav.querySelector('a.ghdv-item, .ghdv-recent a'); if (erster) erster.click(); }
    });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && root.classList.contains('ghdv-offen')) schliessen(); });
    nav.addEventListener('click', function (e) {
      var t = e.target.closest('[data-tog]');
      if (t) {
        var n = t.getAttribute('data-tog');
        if (q.value) { q.value = ''; offeneGruppen[n] = true; } else offeneGruppen[n] = !offeneGruppen[n];
        zeichnen();
        return;
      }
      var a = e.target.closest('a[data-app]');
      if (!a) return;
      zuletztMerken(a.getAttribute('data-app'));
      // Gleiche Seite, anderer Abschnitt (z. B. Handbuch-Kapitel): nur schließen
      if (ohneHash(a.href) === ohneHash(location.href)) { setTimeout(schliessen, 0); return; }
      var ziel;
      try { ziel = new URL(a.href); } catch (err) { return; }
      // Website & Co. (andere Adresse): eigenes Fenster, gehört nicht zur Salon-App
      if (ziel.origin !== location.origin) {
        e.preventDefault();
        try { window.open(ziel.href, '_blank', 'noopener'); } catch (err) { location.href = ziel.href; }
        schliessen();
        return;
      }
      // Schon im App-Rahmen: der Link wechselt einfach die App im Rahmen.
      if (imRahmen()) return;
      // Installierte Salon-App: im App-Rahmen öffnen. Sonst öffnet Android eine
      // einzeln installierte App (Checkliste, Team …) als eigenes Programm und
      // „Zurück“ schließt sie ganz. Im Browser: normal im selben Fenster.
      if (alsAppInstalliert()) {
        e.preventDefault();
        location.href = RAHMEN + '#' + encodeURIComponent(ziel.href);
      }
    });
  }

  // Knopf ausblenden, solange z. B. der Anmeldebildschirm sichtbar ist
  function sichtbarkeitPruefen() {
    if (!root || !versteckenBei) return;
    var weg = false;
    try {
      var els = document.querySelectorAll(versteckenBei);
      for (var i = 0; i < els.length; i++) if (els[i].getClientRects().length) { weg = true; break; }
    } catch (e) { weg = false; }
    var fab = root.querySelector('.ghdv-fab');
    if (fab.hidden !== weg) fab.hidden = weg;
    if (weg && root.classList.contains('ghdv-offen')) schliessen();
  }
  // Feste Leiste/Knopf der App unten links? Dann den Knopf darüber setzen.
  function abstandAnpassen() {
    if (!root) return;
    var fab = root.querySelector('.ghdv-fab');
    if (fab.hidden) return;
    var h = window.innerHeight, x = fab.getBoundingClientRect().left + 24;
    var hoechst = 0, alt = fab.style.visibility;
    fab.style.visibility = 'hidden';
    try {
      [6, 30, 60].forEach(function (dy) {
        var el = document.elementFromPoint(x, h - dy);
        while (el && el !== document.body && el !== document.documentElement) {
          if (root.contains(el)) break;
          var pos = getComputedStyle(el).position;
          if (pos === 'fixed' || pos === 'sticky') {
            var r = el.getBoundingClientRect();
            // nur Leisten/Knöpfe am unteren Rand, keine Vollbild-Ebenen
            if (r.top > h * 0.55 && r.bottom >= h - 80) hoechst = Math.max(hoechst, h - r.top);
            break;
          }
          el = el.parentElement;
        }
      });
    } catch (e) { /* egal */ }
    fab.style.visibility = alt;
    var neu = hoechst ? Math.max(unten, Math.round(hoechst + 12)) + 'px' : '';
    if (fab.style.getPropertyValue('--ghdv-unten') !== neu) fab.style.setProperty('--ghdv-unten', neu);
  }
  function beobachten() {
    sichtbarkeitPruefen();
    abstandAnpassen();
    var geplant = false;
    function spaeter() {
      if (geplant) return;
      geplant = true;
      setTimeout(function () { geplant = false; sichtbarkeitPruefen(); abstandAnpassen(); }, 150);
    }
    new MutationObserver(function (liste) {
      // eigene Änderungen (Knopf, Seitenleiste) ignorieren, sonst Endlosschleife
      for (var i = 0; i < liste.length; i++) if (!root || !root.contains(liste[i].target)) { spaeter(); return; }
    }).observe(document.body, { attributes: true, attributeFilter: ['class', 'style', 'hidden'], subtree: true, childList: true });
    window.addEventListener('resize', spaeter);
    window.addEventListener('load', spaeter);
  }

  // Zurück zu einer Seite aus dem Verlauf: Verzeichnis geschlossen zeigen
  window.addEventListener('pageshow', function (e) { if (e.persisted && root && root.classList.contains('ghdv-offen')) schliessen(); });

  function start() { aufbauen(); beobachten(); setTimeout(function () { rollePruefen(); }, 1500); }
  if (document.body) start();
  else document.addEventListener('DOMContentLoaded', start);
})();
