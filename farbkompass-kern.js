/* ─────────────────────────────────────────────────────────────
   Farbkompass – gemeinsamer fachlicher Kern
   Fragen, Punkte-Logik und Ergebnistexte für ALLE Versionen:
   - Kund:innen-Version (farbkompass.html, später Homepage)
   - Team-Version Lernen/Beraten (Mitarbeiterhandbuch/farbkompass-team.html,
     lädt diese Datei von mirjamwalenta-a11y.github.io/index.greathairday/)
   Änderungen hier wirken überall gleich. Danach prüfen:
     node tests/farbkompass-kern.test.js
   Wirkung vor Technik · Entscheidungshilfe vor Typisierung ·
   Farbrichtung statt fixer Farbton. Keine Daten werden gespeichert.
   ───────────────────────────────────────────────────────────── */
(function (global) {
'use strict';

// Die 6 Ergebnisrichtungen
const RICHTUNGEN = {
  WW: { name: 'Weich und warm',
        wirkung: 'Diese Richtung kann dein Gesicht weicher, wärmer und zugänglicher wirken lassen.',
        salon: 'Wir achten darauf, dass die Wärme dich sanft umgibt und nicht gelblich, schwer oder flach wirkt.' },
  FL: { name: 'Frisch und lichtvoll',
        wirkung: 'Diese Richtung kann dein Gesicht offener, frischer und strahlender wirken lassen.',
        salon: 'Wir achten darauf, dass die Helligkeit dich belebt und nicht zu hart, künstlich oder unruhig wirkt.' },
  RN: { name: 'Ruhig und natürlich',
        wirkung: 'Diese Richtung kann dein Gesicht harmonisch, ausgeglichen und ganz selbstverständlich wirken lassen.',
        salon: 'Wir achten darauf, dass die Farbe nah bei dir bleibt und trotzdem lebendig wirkt – nicht flach und nicht gemacht.' },
  AK: { name: 'Mehr Ausdruck und Kontur',
        wirkung: 'Diese Richtung kann deinem Gesicht mehr Präsenz, Klarheit und Kontur geben.',
        salon: 'Wir achten darauf, dass die Kontur dich betont und nicht streng, hart oder unruhig wirkt.' },
  TR: { name: 'Tiefer und ruhiger',
        wirkung: 'Diese Richtung kann deinem Gesicht Ruhe, Tiefe und eine gesammelte Ausstrahlung geben.',
        salon: 'Wir achten darauf, dass die Tiefe dein Gesicht ruhig rahmt und nicht schwer oder hart wirkt.' },
  LH: { name: 'Lebendig mit mehr Höhe',
        wirkung: 'Diese Richtung kann dein Gesicht lebendiger wirken lassen und optisch mehr Höhe und Leichtigkeit schaffen.',
        salon: 'Wir achten darauf, dass Licht und Bewegung dort sitzen, wo sie dich heben – und nicht unruhig oder künstlich wirken.' }
};

// Erlaubte Alternativ-Paare: Hauptrichtung → Alternative + wann sie besser passen könnte
const ALTERNATIVE = {
  WW: { zu: 'RN', wann: 'Diese Alternative passt besser, wenn dir eine möglichst natürliche, unaufgeregte Wirkung wichtiger ist als spürbare Wärme.' },
  FL: { zu: 'WW', wann: 'Diese Alternative passt besser, wenn du dir neben Frische vor allem mehr Weichheit und Wärme im Gesicht wünschst.' },
  RN: { zu: 'WW', wann: 'Diese Alternative passt besser, wenn du dir etwas mehr Wärme und Weichheit wünschst, ohne an Natürlichkeit zu verlieren.' },
  AK: { zu: 'TR', wann: 'Diese Alternative passt besser, wenn du dir Ausdruck wünschst, der eher ruhig und gesammelt wirkt als kontrastreich.' },
  TR: { zu: 'AK', wann: 'Diese Alternative passt besser, wenn du dir neben Ruhe auch mehr sichtbare Kontur und Präsenz wünschst.' },
  LH: { zu: 'FL', wann: 'Diese Alternative passt besser, wenn dir Frische und Licht im Gesicht wichtiger sind als mehr Höhe am Oberkopf.' }
};

// Die drei Stationen. Jede Antwort gibt 1 Punkt auf 1–2 Richtungen (punkte).
// satz: Baustein für „Warum das zu dir passen könnte“.
const FRAGEN = [
  { titel: 'Wie möchtest du mit deiner Haarfarbe wirken?',
    hinweis: 'Wähle das Gefühl, das du dir für dein Gesicht am meisten wünschst.',
    optionen: [
      { t: 'Frischer',      s: 'mehr Lebendigkeit im Gesicht',          punkte: ['FL','LH'], satz: 'mehr Frische' },
      { t: 'Weicher',       s: 'weniger Härte in der Ausstrahlung',     punkte: ['WW'],      satz: 'mehr Weichheit' },
      { t: 'Natürlicher',   s: 'weniger gemacht, mehr harmonisch',      punkte: ['RN','WW'], satz: 'eine natürlichere Ausstrahlung' },
      { t: 'Mehr Ausdruck', s: 'mehr Präsenz und Kontur',               punkte: ['AK','TR'], satz: 'mehr Ausdruck' },
      { t: 'Ruhiger',       s: 'weniger Unruhe, mehr Ausgeglichenheit', punkte: ['TR','RN'], satz: 'mehr Ruhe' },
      { t: 'Strahlender',   s: 'mehr Licht und Offenheit',              punkte: ['FL','AK'], satz: 'mehr Strahlkraft' }
    ] },
  { titel: 'Was möchtest du mit deiner Haarfarbe eher vermeiden?',
    hinweis: 'Wähle das, was auf keinen Fall passieren soll.',
    optionen: [
      { t: 'Zu hart',           s: 'mein Gesicht soll nicht strenger wirken',   punkte: ['WW','RN'], satz: 'Härte vermeiden' },
      { t: 'Zu dunkel',         s: 'mein Gesicht soll nicht schwerer wirken',   punkte: ['LH'],      satz: 'vermeiden, dass dein Gesicht schwerer wirkt,' },
      { t: 'Zu gelb',           s: 'die Farbe soll nicht gelblich wirken',      punkte: ['RN','TR'], satz: 'einen gelblichen Schimmer vermeiden' },
      { t: 'Zu künstlich',      s: 'ich möchte nicht gemacht wirken',           punkte: ['RN','WW'], satz: 'nicht gemacht wirken' },
      { t: 'Zu pflegeintensiv', s: 'es soll im Alltag gut für mich passen',     punkte: ['RN','TR'], satz: 'eine Farbe tragen, die gut in deinen Alltag passt,' },
      { t: 'Zu unruhig',        s: 'ich möchte eine harmonische Gesamtwirkung', punkte: ['TR'],      satz: 'Unruhe vermeiden' }
    ] },
  { titel: 'Was ist dir dabei besonders wichtig?',
    hinweis: 'Wähle das, was für deine Entscheidung am meisten zählt.',
    optionen: [
      { t: 'Wenig Ansatzstress',          s: 'die Farbe soll im Alltag unkompliziert sein',            punkte: ['RN','TR'], satz: 'möglichst wenig Ansatzstress haben' },
      { t: 'Meine Augen betonen',         s: 'meine Augen sollen stärker zur Geltung kommen',          punkte: ['AK','FL'], satz: 'deine Augen stärker zur Geltung bringen' },
      { t: 'Mehr Leichtigkeit im Gesicht',s: 'mein Gesicht soll offener und frischer wirken',          punkte: ['FL','LH'], satz: 'mehr Leichtigkeit in dein Gesicht bringen' },
      { t: 'Mehr Kontur im Gesicht',      s: 'mein Gesicht soll mehr Ausdruck bekommen',               punkte: ['AK','TR'], satz: 'deinem Gesicht mehr Kontur geben' },
      { t: 'Mehr Fülle am Oberkopf',      s: 'die Farbe soll optisch mehr Höhe und Volumen unterstützen', punkte: ['LH'],   satz: 'optisch mehr Höhe und Fülle am Oberkopf gewinnen' },
      { t: 'Natürlich bleiben',           s: 'die Farbe soll zu mir passen und nicht zu gemacht wirken', punkte: ['RN','WW'], satz: 'ganz natürlich du selbst bleiben' }
    ] }
];

const ABSCHLUSS = 'Diese Richtung ist keine starre Vorgabe, sondern eine klare Orientierung für deine Farbberatung. Gemeinsam schauen wir, wie wir sie zu deinem Gesicht, deinem Alltag und deinem Haar passend umsetzen.';

// ── Ergebnislogik ──────────────────────────────────────────────
// Jede Antwort gibt 1 Punkt auf 1–2 Richtungen.
// Hauptrichtung:
//   1. höchste Punktzahl
//   2. bei Gleichstand: Frage 1 (Wunschwirkung)
//   3. weiter Gleichstand: Frage 3 (besonders wichtig)
//   4. weiter Gleichstand: fachlich gesetzter Vorrang (VORRANG).
//      (Frage 2 als eigener Schritt trennt hier nie: wer bei Punkten,
//      Frage 1 und Frage 3 gleich liegt, liegt auch bei Frage 2 gleich.)
// Zweitempfehlung nur, wenn
//   1. sie das erlaubte Paar der Hauptrichtung ist,
//   2. sie höchstens 1 Punkt hinter der Hauptrichtung liegt und
//   3. die Hauptrichtung nicht eindeutig ist. Eindeutig heißt: Frage 1 und
//      Frage 3 stützen die Hauptrichtung, die Partner-Richtung aber nicht
//      genauso. Bei echtem Gleichstand erlaubter Partner sieht man beide.
// Rückgabe: haupt, alternative (oder null), punkte und – für die
// Team-Version – warum die Hauptrichtung gewonnen hat (entschieden).

// Fachlicher Vorrang, wenn Punkte, Frage 1 und Frage 3 nichts trennen.
// Schlüssel: beide Kürzel alphabetisch, mit „|“ verbunden.
// Bei erlaubten Partner-Paaren erscheint die andere Richtung immer als
// Zweitempfehlung, der Vorrang bestimmt dort nur, welche oben steht.
const VORRANG = {
  'RN|WW': { vor: 'WW', grund: 'Erlaubte Nachbarn: beide werden gezeigt.' },
  'AK|TR': { vor: 'AK', grund: 'Erlaubte Nachbarn: beide werden gezeigt.' },
  'RN|TR': { vor: 'RN', grund: 'Ruhig und natürlich ist die sanftere Veränderung.' },
  'AK|FL': { vor: 'FL', grund: 'Frisch und lichtvoll öffnet das Gesicht, ohne Kontrast zu setzen.' },
  'FL|LH': { vor: 'FL', grund: 'Lebendig mit mehr Höhe soll nur bei einem echten Höhe-Wunsch gewinnen.' }
};
const paar = (a, b) => [a, b].sort().join('|');

function auswerten(antworten){
  const reihe = Object.keys(RICHTUNGEN);
  const punkte = {}; reihe.forEach(k => punkte[k] = 0);
  antworten.forEach((a, i) => FRAGEN[i].optionen[a].punkte.forEach(k => punkte[k]++));
  const wunsch  = FRAGEN[0].optionen[antworten[0]].punkte;
  const wichtig = FRAGEN[2].optionen[antworten[2]].punkte;
  const rang = k => punkte[k] * 100 + (wunsch.includes(k) ? 10 : 0) + (wichtig.includes(k) ? 1 : 0);
  const vorrang = (a, b) => { const v = VORRANG[paar(a, b)]; return v ? (v.vor === a ? -1 : 1) : reihe.indexOf(a) - reihe.indexOf(b); };
  const sortiert = reihe.slice().sort((a, b) => rang(b) - rang(a) || vorrang(a, b));
  const haupt = sortiert[0], zweit = sortiert[1];
  const entschieden =
    punkte[haupt] > punkte[zweit] ? 'punkte' :
    Math.floor(rang(haupt) / 10) > Math.floor(rang(zweit) / 10) ? 'frage1' :
    rang(haupt) > rang(zweit) ? 'frage3' :
    VORRANG[paar(haupt, zweit)] ? 'fachlich' : 'reihenfolge';
  const alt = ALTERNATIVE[haupt];
  const knapp = punkte[alt.zu] > 0 && punkte[haupt] - punkte[alt.zu] <= 1;
  const stuetzt = k => wunsch.includes(k) && wichtig.includes(k);
  const eindeutig = stuetzt(haupt) && !stuetzt(alt.zu);
  return { haupt, alternative: knapp && !eindeutig ? alt : null, punkte, entschieden,
           gleichauf: punkte[haupt] === punkte[zweit] ? zweit : null,
           vorrang: entschieden === 'fachlich' ? VORRANG[paar(haupt, zweit)].grund : null,
           knapp, eindeutig };
}

function warumText(antworten){
  const [a, b, c] = antworten.map((x, i) => FRAGEN[i].optionen[x].satz);
  return `Du wünschst dir ${a}, möchtest ${b} und ${c}. Genau dabei kann diese Farbrichtung dich gut unterstützen.`;
}

global.FARBKOMPASS = { RICHTUNGEN, ALTERNATIVE, FRAGEN, ABSCHLUSS, VORRANG, auswerten, warumText };
})(typeof window !== 'undefined' ? window : globalThis);
