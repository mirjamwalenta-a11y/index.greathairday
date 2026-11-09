/* ==================================================================
   Test: Farbkompass-Kern (farbkompass-kern.js)

   Rechnet alle 216 Antwort-Kombinationen durch und prüft:
   - jede Antwort gibt 1 Punkt auf 1–2 Richtungen
   - jede Hauptrichtung hat ein erlaubtes Alternativ-Paar
   - Alternative nur bei erlaubtem Paar, max. 1 Punkt Abstand und
     wenn das Ergebnis nicht eindeutig ist (Frage 1 und 3 stützen die
     Hauptrichtung, aber nicht genauso die Partner-Richtung)
   - Gleichstand endet nie in der allgemeinen Reihenfolge, sondern
     im fachlichen Vorrang
   - die vereinbarte Verteilung (Stand 2026-11-09, fachlicher Vorrang) bleibt erhalten,
     damit eine Änderung an der Zuordnung bewusst passiert

   Start:  node tests/farbkompass-kern.test.js
================================================================== */
"use strict";
require("../farbkompass-kern.js");
const { RICHTUNGEN, ALTERNATIVE, FRAGEN, auswerten, warumText } = globalThis.FARBKOMPASS;
const assert = require("assert");

const ERLAUBT = { WW: "RN", FL: "WW", RN: "WW", AK: "TR", TR: "AK", LH: "FL" };
const ERWARTET = { WW: 51, FL: 34, RN: 54, AK: 20, TR: 38, LH: 19 };
const ERWARTET_ALT = 111;
const ERWARTET_ENTSCHIEDEN = { punkte: 113, frage1: 27, frage3: 7, fachlich: 69 };

FRAGEN.forEach((f, i) => f.optionen.forEach(o => {
  assert(o.punkte.length >= 1 && o.punkte.length <= 2, `Frage ${i + 1} „${o.t}“: 1–2 Richtungen`);
  o.punkte.forEach(k => assert(RICHTUNGEN[k], `unbekannte Richtung ${k}`));
}));
Object.keys(RICHTUNGEN).forEach(k => assert.strictEqual(ALTERNATIVE[k].zu, ERLAUBT[k], `Paar für ${k}`));

const zaehler = {}, entschieden = {}; let alt = 0;
for (let a = 0; a < 6; a++) for (let b = 0; b < 6; b++) for (let c = 0; c < 6; c++) {
  const r = auswerten([a, b, c]);
  zaehler[r.haupt] = (zaehler[r.haupt] || 0) + 1;
  const st = k => FRAGEN[0].optionen[a].punkte.includes(k) && FRAGEN[2].optionen[c].punkte.includes(k);
  const p = ERLAUBT[r.haupt];
  entschieden[r.entschieden] = (entschieden[r.entschieden] || 0) + 1;
  if (r.punkte[p] === r.punkte[r.haupt] && r.entschieden === 'fachlich') assert(r.alternative, 'erlaubte Nachbarn gleichauf: beide zeigen');
  if (r.alternative) {
    alt++;
    assert.strictEqual(r.alternative.zu, ERLAUBT[r.haupt]);
    assert(r.punkte[r.haupt] - r.punkte[r.alternative.zu] <= 1);
    assert(!(st(r.haupt) && !st(p)), "keine Alternative, wenn eindeutig");
  }
  assert(/^Du wünschst dir .+, möchtest .+ und .+\. Genau dabei/.test(warumText([a, b, c])));
}
assert.deepStrictEqual(zaehler, ERWARTET, "Verteilung hat sich geändert – bewusst? Dann ERWARTET anpassen.");
assert.strictEqual(alt, ERWARTET_ALT, "Anzahl Zweitempfehlungen hat sich geändert");
assert.deepStrictEqual(entschieden, ERWARTET_ENTSCHIEDEN, "Entscheidungswege haben sich geändert");
assert(!entschieden.reihenfolge, "kein Fall darf über die allgemeine Reihenfolge entschieden werden");
console.log("Farbkompass-Kern ok:", zaehler, "Zweitempfehlungen:", alt);
