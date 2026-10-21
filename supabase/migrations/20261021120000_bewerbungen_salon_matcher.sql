-- ════════════════════════════════════════════════════════════════════════
-- Bewerbungen + Salon Matcher (Supabase-Projekt wrxlaltgtgkdomklgrlj)
--
-- Ablauf siehe BEWERBUNGSPROZESS.md:
--   karriere.html     Kurzbewerbung ohne Login     → bewerbung_einreichen()
--   bewerber.html     Matcher mit persönlichem Link → matcher_laden(), matcher_abschicken()
--   bewerbungen.html  Übersicht nur für die Chefin  → bewerbungen_*() / bewerbung_*()
--
-- Sicherheit (CLAUDE.md, Regeln 1–4, SICHERHEIT-RLS-CHECK.md Abschnitt 2):
--   * Alle Tabellen: RLS an, KEINE Policy, KEINE Grants für anon/authenticated.
--     Zugriff ausschließlich über die SECURITY DEFINER-Funktionen unten.
--   * Ohne Login (anon) gibt es genau drei Aktionen: Kurzbewerbung anlegen,
--     Matcher über ein gültiges Token laden, Matcher einmal abschicken.
--     Keine davon kann Bewerbungen, Bewertungen oder Farben lesen.
--   * Die Farbzuordnung (grün/gelb/rot) liegt nur in der Datenbank. Die
--     Auswertung passiert hier, nicht im Browser.
--   * Matcher-Links: zufälliges Token, gespeichert wird nur der SHA-256-Hash,
--     7 Tage gültig, nur einmal ausfüllbar (Regel 4).
--   * Chefin-Funktionen prüfen selbst über bewerbungen_ist_chefin()
--     (teamapp_persons.rolle = 'inhaberin', wie die Schaltzentrale).
--   * Prozessregeln werden hier erzwungen, nicht nur in der Oberfläche:
--     Rot kann nie zum Gespräch, Gelb nur mit schriftlicher Begründung,
--     nach dem Matcher endet jeder Vorgang mit Zusage oder Absage.
--
-- Ausführen: einmal komplett im Supabase SQL-Editor. Mehrfach ausführbar
-- (Inhalte des Matchers werden dabei neu eingespielt, Bewerbungen bleiben).
-- ════════════════════════════════════════════════════════════════════════


-- ── 1. Tabellen ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.matcher_felder (
  kuerzel   text PRIMARY KEY CHECK (kuerzel IN ('Z','O','R','W')),
  name      text NOT NULL,
  gespraech text NOT NULL
);
ALTER TABLE public.matcher_felder ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.matcher_situationen (
  nr    smallint PRIMARY KEY CHECK (nr BETWEEN 0 AND 7),
  art   text NOT NULL,
  frage text NOT NULL
);
ALTER TABLE public.matcher_situationen ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.matcher_optionen (
  situation   smallint NOT NULL REFERENCES public.matcher_situationen(nr) ON DELETE CASCADE,
  nr          smallint NOT NULL CHECK (nr BETWEEN 0 AND 3),
  text        text NOT NULL,
  bewertung   jsonb NOT NULL,          -- z. B. {"Z":"g","O":"y"} – nie an Bewerber:innen
  begruendung text,
  prueffrage  text,                    -- nur bei gelben Antworten (Prüfzone)
  pruef_gut   text,
  pruef_krit  text,
  PRIMARY KEY (situation, nr)
);
ALTER TABLE public.matcher_optionen ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.bewerbungen (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  erstellt_am            timestamptz NOT NULL DEFAULT now(),
  loeschen_am            timestamptz NOT NULL DEFAULT now() + interval '6 months',
  -- Basisdaten (BEWERBUNGSPROZESS.md, Abschnitt 4)
  name                   text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 120),
  telefon                text CHECK (char_length(telefon) <= 40),
  email                  text CHECK (char_length(email) <= 160),
  stelle                 text NOT NULL CHECK (stelle IN ('lehrstelle','geselle','wiedereinstieg')),
  ausbildung             text NOT NULL CHECK (ausbildung IN ('schule','in_ausbildung','lehrabschluss','meisterpruefung','quereinstieg')),
  ueber_dich             text NOT NULL CHECK (char_length(ueber_dich) BETWEEN 1 AND 800),
  stunden                text NOT NULL CHECK (char_length(stunden) BETWEEN 1 AND 120),
  start                  text NOT NULL CHECK (char_length(start) BETWEEN 1 AND 80),
  portfolio              text CHECK (char_length(portfolio) <= 200),
  einwilligung_am        timestamptz NOT NULL,
  CHECK (telefon IS NOT NULL OR email IS NOT NULL),
  -- Prozess
  status                 text NOT NULL DEFAULT 'neu' CHECK (status IN (
                           'neu','basis_ok','matcher_offen','ausgewertet','gespraech',
                           'probearbeiten','zusage','absage_offen','abgesagt','geschlossen')),
  basis_grund            text,
  matcher_token_hash     text UNIQUE,
  matcher_verschickt_am  timestamptz,
  matcher_gueltig_bis    timestamptz,
  matcher_erinnert_am    timestamptz,
  matcher_ausgefuellt_am timestamptz,
  matcher_antworten      smallint[],  -- je Situation 0–7 die gewählte Option 0–3
  matcher_felder         jsonb,       -- {"Z":"g","O":"y","R":"g","W":"r"}
  matcher_gesamt         text CHECK (matcher_gesamt IN ('g','y','r')),
  pruefzone              jsonb NOT NULL DEFAULT '{}'::jsonb,
  verlauf                jsonb NOT NULL DEFAULT '[]'::jsonb
);
ALTER TABLE public.bewerbungen ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS bewerbungen_erstellt_idx ON public.bewerbungen (erstellt_am);

-- Grants: anon/authenticated bekommen nichts (Zugriff nur über Funktionen).
-- service_role für Wartung im Dashboard.
REVOKE ALL ON public.matcher_felder, public.matcher_situationen, public.matcher_optionen, public.bewerbungen
  FROM public, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.matcher_felder, public.matcher_situationen, public.matcher_optionen, public.bewerbungen
  TO service_role;


-- ── 2. Matcher-Inhalte (aus dem abgestimmten Prototyp, unverändert) ─────
-- Optionen-Nummern = Reihenfolge im Prototyp. Bewerber:innen sehen die
-- Antworten gemischt; abgeschickt wird die Nummer, nie die Farbe.

DELETE FROM public.matcher_optionen;
DELETE FROM public.matcher_situationen;
DELETE FROM public.matcher_felder;

INSERT INTO public.matcher_felder (kuerzel, name, gespraech) VALUES
  ('Z', 'Zuwendung statt Selbstdarstellung', 'Erzähl von einem Kundengespräch, bei dem du erst spät verstanden hast, was die Person eigentlich wollte. Woran hast du es gemerkt?'),
  ('O', 'Offenheit statt vorschneller Ablehnung', 'Was hast du zuletzt bei der Arbeit anders gemacht als gewohnt – und wie lange hast du es ausprobiert, bevor du dir eine Meinung gebildet hast?'),
  ('R', 'Respekt im Alltag', 'Wann hast du dich zuletzt bei jemandem im Team oder bei einer Kundin entschuldigt – und wofür?'),
  ('W', 'Wertschätzung für Menschen', 'Wie gehst du mit Kundinnen oder Kunden um, mit denen die Verständigung schwierig ist? Wie reagierst du, wenn im Team über jemanden gelästert wird?');

INSERT INTO public.matcher_situationen (nr, art, frage) VALUES
  (0, 'Kundin', 'Eine neue Kundin sitzt zur Beratung bei dir. Sie erzählt ziemlich ausführlich, was sie bei ihrem letzten Friseur gestört hat. Du hast nach zwei Sätzen schon ein Bild im Kopf, was ihr stehen würde.'),
  (1, 'Team', 'In der Teambesprechung erzählt eine neue Kollegin, wie in ihrem alten Salon die Farbberatung abgelaufen ist. Bei euch läuft das seit Jahren anders – und gut.'),
  (2, 'Neuer Ablauf', 'Ab nächstem Monat kommen Rezepturen und Kundennotizen nicht mehr auf die Karteikarte, sondern ins Tablet. Die ersten Tage dauert dadurch alles etwas länger.'),
  (3, 'Alltag', 'Du stehst im Stau. Deine erste Kundin kommt um 8:30, du wirst etwa zehn Minuten zu spät sein. Es ist 8:15.'),
  (4, 'Team', 'Samstag, voller Salon. Eine Kollegin sagt dir im Vorbeigehen ziemlich scharf, du sollst deinen Platz endlich aufräumen – vor deiner Kundin.'),
  (5, 'Kunde', 'Ein Kunde spricht kaum Deutsch. Er zeigt dir ein Foto auf dem Handy, ihr versteht euch nur mühsam. Die Kollegin am Nebenplatz sagt halblaut: „Viel Spaß, das wird eh nix.“'),
  (6, 'Lernen', 'Die Chefin sieht dir beim Föhnen zu und sagt: „Sauber – aber nimm die größere Rundbürste und arbeite von unten, dann hält es länger.“ Du hast es anders gelernt, und bisher hat es immer gut ausgesehen.'),
  (7, 'Kundin', 'Eine Stammkundin hat sich die Haare selbst gefärbt, es ist fleckig geworden. Noch an der Garderobe fragt sie: „Sag ehrlich, schaut das schlimm aus?“');

INSERT INTO public.matcher_optionen (situation, nr, text, bewertung, begruendung, prueffrage, pruef_gut, pruef_krit) VALUES
  (0, 0, 'Ich lasse sie ausreden und frage nach, was genau sie gestört hat, bevor ich etwas vorschlage.', '{"Z":"g"}'::jsonb, null, null, null, null),
  (0, 1, 'Ich sage ihr, dass ich schon eine klare Idee habe, und zeige ihr ein paar meiner Arbeiten auf dem Handy. Das gibt ihr Sicherheit.', '{"Z":"r"}'::jsonb, 'Unterbricht und rückt die eigene Arbeit in den Mittelpunkt, bevor die Kundin verstanden ist.', null, null, null),
  (0, 2, 'Ich höre zu, sage aber wenig. Sie soll sich nicht gedrängt fühlen – wenn sie fertig ist, lege ich los.', '{"Z":"y"}'::jsonb, 'Hört zu, fragt aber nicht nach – Interesse bleibt passiv.', 'Wenn eine Kundin viel erzählt – woran merkst du, was ihr eigentlich wichtig ist?', 'nennt Nachfragen oder ein konkretes Beispiel', 'wartet nur ab, „ich mach dann eh, was sie will“'),
  (0, 3, 'Ich erkläre ihr kurz, wie ich normalerweise arbeite, damit sie gleich weiß, was sie bei mir erwartet.', '{"Z":"y"}'::jsonb, 'Freundlich, aber stark auf die eigene Rolle statt auf die Kundin gerichtet.', 'Erzähl, wie dein erstes Gespräch mit einer neuen Kundin abläuft – Schritt für Schritt.', 'die Kundin und ihre Wünsche kommen zuerst vor', 'erzählt fast nur von eigener Technik und Erfolgen'),
  (1, 0, 'Ich frage sie, was dort besser funktioniert hat und wo es gehakt hat.', '{"Z":"g","O":"g"}'::jsonb, null, null, null, null),
  (1, 1, 'Ich warte, bis sie fertig ist, und erzähle dann von einem ähnlichen Fall bei mir, der gut ausgegangen ist.', '{"Z":"r","O":"y"}'::jsonb, 'Nimmt das Thema der Kollegin als Anlass für die eigene Geschichte.', null, null, null),
  (1, 2, 'Ich höre zu und denke mir meinen Teil. Wenn sie länger da ist, sieht sie ja, wie es bei uns läuft.', '{"Z":"y","O":"r"}'::jsonb, 'Hat das Neue innerlich schon abgelehnt, ohne es zu prüfen.', null, null, null),
  (1, 3, 'Ich finde es interessant, würde es aber erst ausprobieren, wenn die Chefin sagt, dass wir es ändern.', '{"Z":"g","O":"y"}'::jsonb, 'Offen, braucht aber Absicherung von oben, bevor etwas ausprobiert wird.', 'Du siehst bei uns etwas, das du anders besser findest. Was machst du?', 'spricht es an und probiert im Kleinen', 'wartet, bis jemand anderer entscheidet, oder es ist ihr egal'),
  (2, 0, 'Am Anfang nervt mich das sicher. Aber ich geb dem ein paar Wochen, dann weiß ich, ob es was taugt.', '{"O":"g"}'::jsonb, 'Gibt dem Neuen eine echte Chance und urteilt erst danach.', null, null, null),
  (2, 1, 'Ich trag es ein, wie es verlangt wird. Was ich davon halte, spielt ja eigentlich keine große Rolle.', '{"O":"y"}'::jsonb, 'Macht mit, setzt sich aber nicht damit auseinander.', 'Welche Umstellung hast du in der Schule, im Praktikum oder im letzten Job am Anfang blöd gefunden – und wie siehst du sie heute?', 'hat sich eine eigene Meinung gebildet, nachdem sie es ausprobiert hat', '„Ist mir egal, ich mach, was man mir sagt“ als Grundhaltung'),
  (2, 2, 'Das hatten wir in meinem alten Salon auch. Nach drei Monaten haben wieder alle auf Papier geschrieben – ich würde uns die Umstellung sparen.', '{"O":"r"}'::jsonb, 'Urteilt aus alter Erfahrung, bevor es hier ausprobiert ist.', null, null, null),
  (2, 3, 'Ich trag alles ins Tablet ein, schreib die Rezepturen aber zusätzlich auf die Karte. Wenn das Ding einmal abstürzt, ist sonst alles weg.', '{"O":"y"}'::jsonb, 'Probiert, traut dem Neuen aber nicht und sichert doppelt ab.', 'Was müsste passieren, damit du dem Tablet so vertraust wie der Karteikarte?', 'nennt etwas Konkretes und Erreichbares', 'nichts – Papier bleibt immer sicherer'),
  (3, 0, 'Ich rufe im Salon an, damit jemand die Kundin empfängt, und entschuldige mich bei ihr, wenn ich da bin.', '{"R":"g"}'::jsonb, null, null, null, null),
  (3, 1, 'Ich schreibe kurz in die Team-Gruppe und lege gleich los, wenn ich da bin. Die zehn Minuten hole ich beim Föhnen wieder rein.', '{"R":"r"}'::jsonb, 'Behandelt die Verspätung als Zeitproblem, nicht als Frage des Respekts – keine Entschuldigung.', null, null, null),
  (3, 2, 'Ich sage im Salon Bescheid. Ob ich mich bei der Kundin extra entschuldige, hängt davon ab, wie sie drauf ist.', '{"R":"y"}'::jsonb, 'Entschuldigung ist situationsabhängig statt selbstverständlich.', 'Wann entschuldigst du dich bei einer Kundin – und wann nicht?', 'Verspätung ist immer ein Grund, egal wessen Schuld', 'hängt von Laune oder Schuldfrage ab („der Stau war ja nicht ich“)'),
  (3, 3, 'Ich melde mich nicht extra – bis jemand die Nachricht liest, bin ich sowieso schon da. Vor Ort sage ich dann allen Bescheid.', '{"R":"y"}'::jsonb, 'Pragmatisch, lässt aber Team und Kundin im Unklaren.', 'Du bist zehn Minuten zu spät. Wer muss es wann wissen?', 'Salon sofort, Kundin rechtzeitig', '„Zehn Minuten merkt eh keiner“'),
  (4, 0, 'Ich räume auf und spreche sie später unter vier Augen darauf an, dass mich der Ton gestört hat.', '{"R":"g"}'::jsonb, null, null, null, null),
  (4, 1, 'Ich sage ihr gleich, dass ich das vor der Kundin nicht okay finde. Lieber sofort klar als später herumdrucksen.', '{"R":"y"}'::jsonb, 'Berechtigter Punkt, aber im Moment und vor der Kundin – Stress wird weitergegeben.', 'Eine Kollegin wird vor deiner Kundin unfreundlich. Was sagst du – und wann?', 'Kundin zuerst, Klärung danach unter vier Augen', 'klärt es vor der Kundin, „sonst traut man sich nie“'),
  (4, 2, 'Ich räume auf und sage nichts. Samstags ist jeder mal kurz angebunden, das nehme ich nicht persönlich.', '{"R":"y"}'::jsonb, 'Hält Schroffheit unter Stress für normal.', 'Wie gehst du damit um, wenn es im Team über Wochen schroff zugeht?', 'spricht es irgendwann an, statt es zu schlucken', '„Das gehört in dem Beruf halt dazu“'),
  (4, 3, 'Ich räume auf und erzähle es später den anderen, damit sie wissen, wie sie manchmal ist.', '{"R":"r","W":"y"}'::jsonb, 'Klärt nicht direkt, sondern redet hinter dem Rücken über die Kollegin.', null, null, null),
  (5, 0, 'Ich zeig ihm am Foto und an seinen Haaren, wie kurz – Stück für Stück, zwischendurch mit dem Spiegel. Wenn ich unsicher bin, hol ich kurz jemanden dazu.', '{"W":"g","Z":"g"}'::jsonb, 'Bleibt beim Kunden, findet einfache Wege, holt Hilfe statt aufzugeben.', null, null, null),
  (5, 1, 'Ich schneid nach dem Foto, so gut es geht. Ganz genau wird es bei der Verständigung eh nicht, da muss man realistisch sein.', '{"W":"r","Z":"y"}'::jsonb, 'Gibt wegen der Sprache früh auf – der Kunde bekommt weniger als andere.', null, null, null),
  (5, 2, 'Ich frag die Kollegin vorne, ob sie ihn übernimmt. Sie hat bei so was mehr Routine, dann geht es für alle schneller.', '{"W":"y","Z":"y"}'::jsonb, 'Gibt den Kunden ab, weil es bequemer ist – „bei so was“.', 'Wann gibst du einen Kunden an eine Kollegin ab?', 'wenn er dort wirklich besser aufgehoben ist – nach eigenem Versuch', 'wenn es mühsam wird oder „bei so Leuten“'),
  (5, 3, 'Auf den Spruch geh ich nicht ein, auch später nicht. Sie meint es nicht so, und das bringt nur Stimmung ins Team.', '{"W":"y"}'::jsonb, 'Lässt die Abwertung stehen, um Ruhe zu haben.', 'Im Team fällt ein abfälliger Spruch über einen Kunden. Was machst du?', 'sagt etwas, spätestens unter vier Augen', 'lacht mit oder „das ist halt so im Team“'),
  (6, 0, 'Ich mache es ab jetzt so, wie sie sagt. Sie ist die Chefin.', '{"O":"y"}'::jsonb, 'Ordnet sich unter, ohne selbst zu prüfen – Offenheit oder nur Anpassung? Im Gespräch klären.', 'Die Chefin zeigt dir etwas Neues, du bist nicht überzeugt. Was machst du?', 'probiert es und sagt dann ehrlich, was herausgekommen ist', 'macht es ohne nachzudenken oder sagt nie, was sie denkt'),
  (6, 1, 'Okay, ich probier es bei den nächsten Kundinnen so und schau, ob es wirklich länger hält.', '{"O":"g"}'::jsonb, 'Probiert die Korrektur praktisch aus und prüft selbst nach – offen, aber nicht unterwürfig.', null, null, null),
  (6, 2, 'Ich nicke und mache weiter wie bisher. Solange das Ergebnis passt, gibt es keinen Grund, etwas zu ändern.', '{"O":"r","R":"y"}'::jsonb, 'Lehnt die Korrektur ab, ohne sie auszuprobieren – und sagt es nicht offen.', null, null, null),
  (6, 3, 'Ich frage, was ihr an meiner Art fehlt, und lasse es mir einmal zeigen.', '{"O":"g","Z":"g"}'::jsonb, 'Will verstehen, worum es geht, statt sich zu verteidigen.', null, null, null),
  (7, 0, '„Ja, das ist ziemlich fleckig geworden. Kriegen wir aber hin – setz dich, ich schau mir das an.“', '{"W":"g"}'::jsonb, 'Ehrlich und gleich bei der Lösung.', null, null, null),
  (7, 1, '„Ehrlich gesagt schon. Ich sag es dir lieber gleich direkt – sonst probierst du es beim nächsten Mal wieder selber.“', '{"W":"r"}'::jsonb, 'Ehrlichkeit als Erziehungsmaßnahme – die Würde der Kundin wird zweitrangig.', null, null, null),
  (7, 2, '„Komm erst mal rein. Was hast du denn genommen?“ Was ich davon halte, sag ich ihr, wenn ich es bei Licht gesehen hab.', '{"W":"g","Z":"g"}'::jsonb, 'Fängt sie auf und will erst verstehen, bevor bewertet wird.', null, null, null),
  (7, 3, '„Mach dir nichts draus – letzte Woche war eine da, bei der war es noch viel ärger.“', '{"W":"y","Z":"y"}'::jsonb, 'Beruhigt mit einer anderen Kundin, statt bei ihr zu bleiben.', 'Eine Kundin ist mit ihren Haaren unglücklich. Wie gehst du mit ihr um?', 'bleibt bei ihr und schaut mit ihr gemeinsam hin', 'beruhigt mit Geschichten über andere Kundinnen');


-- ── 3. Hilfsfunktionen (nicht von außen aufrufbar) ──────────────────────

CREATE OR REPLACE FUNCTION public.bewerbungen_ist_chefin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.teamapp_persons
    WHERE lower(email) = lower(auth.jwt() ->> 'email') AND rolle = 'inhaberin'
  );
$$;

CREATE OR REPLACE FUNCTION public.bewerbungen_pruefe_chefin()
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.bewerbungen_ist_chefin() THEN
    RAISE EXCEPTION 'Kein Zugriff' USING ERRCODE = '42501';
  END IF;
END;
$$;

-- Auswertung ohne Durchschnitt: Feld = schlechteste Farbe darin,
-- Gesamt = schlechtestes Feld.
CREATE OR REPLACE FUNCTION public.matcher_auswerten(p_antworten smallint[])
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rang   jsonb := '{"g":0,"y":1,"r":2}';
  v_felder jsonb := '{"Z":"g","O":"g","R":"g","W":"g"}';
  v_gesamt text := 'g';
  r        record;
BEGIN
  FOR r IN
    SELECT e.key AS feld, e.value #>> '{}' AS farbe
    FROM public.matcher_optionen o
    JOIN LATERAL jsonb_each(o.bewertung) e ON true
    WHERE (o.situation, o.nr) IN (
      SELECT (s - 1)::smallint, p_antworten[s] FROM generate_subscripts(p_antworten, 1) s)
  LOOP
    IF (v_rang ->> r.farbe)::int > (v_rang ->> (v_felder ->> r.feld))::int THEN
      v_felder := jsonb_set(v_felder, ARRAY[r.feld], to_jsonb(r.farbe));
    END IF;
    IF (v_rang ->> r.farbe)::int > (v_rang ->> v_gesamt)::int THEN
      v_gesamt := r.farbe;
    END IF;
  END LOOP;
  RETURN jsonb_build_object('gesamt', v_gesamt, 'felder', v_felder);
END;
$$;

CREATE OR REPLACE FUNCTION public.bewerbung_verlauf(p_id uuid, p_text text)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.bewerbungen
  SET verlauf = verlauf || jsonb_build_array(jsonb_build_object('zeit', now(), 'text', p_text))
  WHERE id = p_id;
$$;

CREATE OR REPLACE FUNCTION public.matcher_token_neu()
RETURNS text
LANGUAGE sql
VOLATILE
SET search_path = public
AS $$
  -- 2 × UUIDv4 = 244 Zufallsbits, ohne Zusatz-Erweiterung
  SELECT replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', '');
$$;

CREATE OR REPLACE FUNCTION public.matcher_token_hash(p_token text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT encode(sha256(convert_to(coalesce(p_token, ''), 'UTF8')), 'hex');
$$;


-- ── 4. Ohne Login: Kurzbewerbung ────────────────────────────────────────
-- Legt nur eine neue Zeile an, liest nichts. Gegen Massen-Einträge höchstens
-- 30 Bewerbungen pro Stunde (wie schnuppertag_test_einreichen).

CREATE OR REPLACE FUNCTION public.bewerbung_einreichen(
  p_name text, p_telefon text, p_email text, p_stelle text, p_ausbildung text,
  p_ueber_dich text, p_stunden text, p_start text, p_portfolio text, p_einwilligung boolean
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF p_einwilligung IS NOT TRUE THEN
    RAISE EXCEPTION 'Einwilligung fehlt';
  END IF;
  IF (SELECT count(*) FROM public.bewerbungen WHERE erstellt_am > now() - interval '1 hour') >= 30 THEN
    RAISE EXCEPTION 'Zu viele Bewerbungen – bitte später nochmal versuchen';
  END IF;

  INSERT INTO public.bewerbungen (name, telefon, email, stelle, ausbildung, ueber_dich, stunden, start, portfolio, einwilligung_am)
  VALUES (
    nullif(trim(p_name), ''),
    nullif(left(trim(p_telefon), 40), ''),
    nullif(left(lower(trim(p_email)), 160), ''),
    p_stelle,
    p_ausbildung,
    nullif(left(trim(p_ueber_dich), 800), ''),
    nullif(left(trim(p_stunden), 120), ''),
    nullif(left(trim(p_start), 80), ''),
    nullif(left(trim(p_portfolio), 200), ''),
    now()
  )
  RETURNING id INTO v_id;
  PERFORM public.bewerbung_verlauf(v_id, 'Kurzbewerbung eingegangen');
END;
$$;


-- ── 5. Ohne Login: Matcher über persönlichen Link ───────────────────────

-- Liefert Situationen und Antworttexte – ohne Farben und Begründungen.
CREATE OR REPLACE FUNCTION public.matcher_laden(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  b public.bewerbungen%ROWTYPE;
BEGIN
  SELECT * INTO b FROM public.bewerbungen
  WHERE matcher_token_hash = public.matcher_token_hash(p_token);

  IF NOT FOUND THEN
    RETURN jsonb_build_object('status', 'ungueltig');
  END IF;
  IF b.matcher_ausgefuellt_am IS NOT NULL THEN
    RETURN jsonb_build_object('status', 'erledigt');
  END IF;
  IF b.status <> 'matcher_offen' OR b.matcher_gueltig_bis < now() THEN
    RETURN jsonb_build_object('status', 'abgelaufen');
  END IF;

  RETURN jsonb_build_object(
    'status', 'ok',
    'situationen', (
      SELECT jsonb_agg(jsonb_build_object(
               'nr', s.nr, 'frage', s.frage,
               'optionen', (SELECT jsonb_agg(jsonb_build_object('nr', o.nr, 'text', o.text) ORDER BY o.nr)
                            FROM public.matcher_optionen o WHERE o.situation = s.nr))
             ORDER BY s.nr)
      FROM public.matcher_situationen s));
END;
$$;

-- Nimmt genau 8 Antworten (je Situation die Option 0–3), wertet sie hier aus
-- und sperrt den Link. Gibt nichts über das Ergebnis zurück.
CREATE OR REPLACE FUNCTION public.matcher_abschicken(p_token text, p_antworten smallint[])
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  b        public.bewerbungen%ROWTYPE;
  v_ergeb  jsonb;
BEGIN
  SELECT * INTO b FROM public.bewerbungen
  WHERE matcher_token_hash = public.matcher_token_hash(p_token)
  FOR UPDATE;

  IF NOT FOUND OR b.status <> 'matcher_offen' OR b.matcher_ausgefuellt_am IS NOT NULL THEN
    RAISE EXCEPTION 'Link ungültig oder schon verwendet';
  END IF;
  IF b.matcher_gueltig_bis < now() THEN
    RAISE EXCEPTION 'Link abgelaufen';
  END IF;
  IF p_antworten IS NULL OR array_length(p_antworten, 1) <> 8
     OR array_lower(p_antworten, 1) <> 1
     OR EXISTS (SELECT 1 FROM unnest(p_antworten) a WHERE a IS NULL OR a NOT BETWEEN 0 AND 3) THEN
    RAISE EXCEPTION 'Antworten unvollständig';
  END IF;

  v_ergeb := public.matcher_auswerten(p_antworten);

  UPDATE public.bewerbungen SET
    status                 = 'ausgewertet',
    matcher_ausgefuellt_am = now(),
    matcher_antworten      = p_antworten,
    matcher_felder         = v_ergeb -> 'felder',
    matcher_gesamt         = v_ergeb ->> 'gesamt'
  WHERE id = b.id;
  PERFORM public.bewerbung_verlauf(b.id, 'Matcher ausgefüllt');
END;
$$;


-- ── 6. Nur Chefin: Übersicht, Detail, Schritte ──────────────────────────

-- Liste; löscht vorher abgelaufene Bewerbungen (Einwilligung: max. 6 Monate).
CREATE OR REPLACE FUNCTION public.bewerbungen_liste()
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.bewerbungen_pruefe_chefin();
  DELETE FROM public.bewerbungen WHERE loeschen_am < now();

  RETURN coalesce((
    SELECT jsonb_agg(jsonb_build_object(
      'id', b.id, 'erstellt_am', b.erstellt_am, 'name', b.name, 'stelle', b.stelle,
      'status', b.status, 'gesamt', b.matcher_gesamt,
      'matcher_verschickt_am', b.matcher_verschickt_am, 'matcher_gueltig_bis', b.matcher_gueltig_bis,
      'matcher_erinnert_am', b.matcher_erinnert_am, 'matcher_ausgefuellt_am', b.matcher_ausgefuellt_am,
      'gelb_eingeladen', (b.pruefzone ->> 'eingeladen')::boolean,
      -- frühere Bewerbung mit gleichem Kontakt (BEWERBUNGSPROZESS.md: kein zweiter Versuch)
      'frueher', (SELECT jsonb_agg(jsonb_build_object('erstellt_am', f.erstellt_am, 'gesamt', f.matcher_gesamt, 'status', f.status)
                                   ORDER BY f.erstellt_am DESC)
                  FROM public.bewerbungen f
                  WHERE f.id <> b.id AND f.erstellt_am < b.erstellt_am
                    AND ((b.email IS NOT NULL AND f.email = b.email)
                      OR (b.telefon IS NOT NULL AND regexp_replace(f.telefon, '\D', '', 'g') = regexp_replace(b.telefon, '\D', '', 'g'))))
    ) ORDER BY b.erstellt_am DESC)
    FROM public.bewerbungen b), '[]'::jsonb);
END;
$$;

-- Detail inklusive Auswertung pro Pflichtfeld und Prüfpunkten bei Gelb.
CREATE OR REPLACE FUNCTION public.bewerbung_detail(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  b public.bewerbungen%ROWTYPE;
BEGIN
  PERFORM public.bewerbungen_pruefe_chefin();
  SELECT * INTO b FROM public.bewerbungen WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Bewerbung nicht gefunden'; END IF;

  RETURN (to_jsonb(b) - 'matcher_token_hash') || jsonb_build_object(
    'frueher', (SELECT jsonb_agg(jsonb_build_object('erstellt_am', f.erstellt_am, 'gesamt', f.matcher_gesamt, 'status', f.status)
                                 ORDER BY f.erstellt_am DESC)
                FROM public.bewerbungen f
                WHERE f.id <> b.id AND f.erstellt_am < b.erstellt_am
                  AND ((b.email IS NOT NULL AND f.email = b.email)
                    OR (b.telefon IS NOT NULL AND regexp_replace(f.telefon, '\D', '', 'g') = regexp_replace(b.telefon, '\D', '', 'g')))),
    'felder_info', (SELECT jsonb_object_agg(kuerzel, jsonb_build_object('name', name, 'gespraech', gespraech))
                    FROM public.matcher_felder),
    'antworten', CASE WHEN b.matcher_antworten IS NULL THEN NULL ELSE (
      SELECT jsonb_agg(jsonb_build_object(
               'situation', o.situation, 'option', o.nr, 'frage', s.frage, 'text', o.text,
               'bewertung', o.bewertung, 'begruendung', o.begruendung,
               'prueffrage', o.prueffrage, 'pruef_gut', o.pruef_gut, 'pruef_krit', o.pruef_krit)
             ORDER BY o.situation)
      FROM generate_subscripts(b.matcher_antworten, 1) i
      JOIN public.matcher_optionen o ON o.situation = i - 1 AND o.nr = b.matcher_antworten[i]
      JOIN public.matcher_situationen s ON s.nr = o.situation) END);
END;
$$;

-- Fragenkatalog mit Bewertung (nur Chefin).
CREATE OR REPLACE FUNCTION public.matcher_katalog()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.bewerbungen_pruefe_chefin();
  RETURN jsonb_build_object(
    'felder', (SELECT jsonb_object_agg(kuerzel, jsonb_build_object('name', name, 'gespraech', gespraech)) FROM public.matcher_felder),
    'situationen', (
      SELECT jsonb_agg(jsonb_build_object('nr', s.nr, 'art', s.art, 'frage', s.frage,
               'optionen', (SELECT jsonb_agg(to_jsonb(o) - 'situation' ORDER BY o.nr)
                            FROM public.matcher_optionen o WHERE o.situation = s.nr))
             ORDER BY s.nr)
      FROM public.matcher_situationen s));
END;
$$;

-- Persönlichen Matcher-Link erzeugen. Gibt das Token genau einmal zurück;
-- gespeichert wird nur der Hash. Erneut aufgerufen (z. B. für die Erinnerung)
-- ersetzt es den alten Link, die Gültigkeit verlängert sich NICHT.
CREATE OR REPLACE FUNCTION public.bewerbung_matcher_link(p_id uuid, p_erinnerung boolean DEFAULT false)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  b       public.bewerbungen%ROWTYPE;
  v_token text := public.matcher_token_neu();
BEGIN
  PERFORM public.bewerbungen_pruefe_chefin();
  SELECT * INTO b FROM public.bewerbungen WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Bewerbung nicht gefunden'; END IF;
  IF b.status NOT IN ('basis_ok','matcher_offen') THEN
    RAISE EXCEPTION 'Matcher-Link nur nach bestandenem Basis-Check und vor dem Ausfüllen';
  END IF;
  IF b.status = 'matcher_offen' AND b.matcher_gueltig_bis < now() THEN
    RAISE EXCEPTION 'Link ist abgelaufen – einen neuen Versuch gibt es nicht';
  END IF;

  UPDATE public.bewerbungen SET
    status                = 'matcher_offen',
    matcher_token_hash    = public.matcher_token_hash(v_token),
    matcher_verschickt_am = coalesce(matcher_verschickt_am, now()),
    matcher_gueltig_bis   = coalesce(matcher_gueltig_bis, now() + interval '7 days'),
    matcher_erinnert_am   = CASE WHEN p_erinnerung THEN now() ELSE matcher_erinnert_am END
  WHERE id = p_id
  RETURNING matcher_gueltig_bis INTO b.matcher_gueltig_bis;

  PERFORM public.bewerbung_verlauf(p_id, CASE WHEN p_erinnerung THEN 'Erinnerung mit neuem Link' ELSE 'Matcher-Link erstellt' END);
  RETURN jsonb_build_object('token', v_token, 'gueltig_bis', b.matcher_gueltig_bis);
END;
$$;

-- Prüfzone Gelb speichern: {stark, fach, begruendung, urteile:{"s-o":"g|y|r"}}
CREATE OR REPLACE FUNCTION public.bewerbung_pruefzone(p_id uuid, p_daten jsonb)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  b         public.bewerbungen%ROWTYPE;
  v_urteile jsonb := '{}'::jsonb;
  v_key     text;
  v_begr    text := left(trim(coalesce(p_daten ->> 'begruendung', '')), 500);
  v_stark   boolean := coalesce((p_daten ->> 'stark')::boolean, false);
  v_fach    boolean := coalesce((p_daten ->> 'fach')::boolean, false);
BEGIN
  PERFORM public.bewerbungen_pruefe_chefin();
  SELECT * INTO b FROM public.bewerbungen WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Bewerbung nicht gefunden'; END IF;
  IF b.matcher_gesamt IS DISTINCT FROM 'y' OR b.status NOT IN ('ausgewertet','gespraech') THEN
    RAISE EXCEPTION 'Prüfzone gibt es nur bei Gelb, vor oder nach dem Gespräch';
  END IF;

  -- Urteile nur für die tatsächlich gewählten gelben Antworten
  FOR v_key IN
    SELECT (i - 1) || '-' || b.matcher_antworten[i]
    FROM generate_subscripts(b.matcher_antworten, 1) i
    JOIN public.matcher_optionen o ON o.situation = i - 1 AND o.nr = b.matcher_antworten[i]
    WHERE o.prueffrage IS NOT NULL
  LOOP
    IF p_daten -> 'urteile' ->> v_key IN ('g','y','r') THEN
      v_urteile := v_urteile || jsonb_build_object(v_key, p_daten -> 'urteile' ->> v_key);
    END IF;
  END LOOP;

  UPDATE public.bewerbungen SET pruefzone = jsonb_build_object(
    'stark', v_stark, 'fach', v_fach, 'begruendung', v_begr,
    -- eingeladen erst ab vollständiger Begründung; danach nicht mehr zurücknehmbar
    'eingeladen', coalesce((pruefzone ->> 'eingeladen')::boolean, false)
                  OR ((v_stark OR v_fach) AND char_length(v_begr) >= 10),
    'urteile', v_urteile)
  WHERE id = p_id;
END;
$$;

-- Prozessschritte. Die Regeln aus BEWERBUNGSPROZESS.md werden hier erzwungen.
CREATE OR REPLACE FUNCTION public.bewerbung_schritt(p_id uuid, p_aktion text, p_notiz text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  b        public.bewerbungen%ROWTYPE;
  v_neu    text;
  v_notiz  text := nullif(left(trim(coalesce(p_notiz, '')), 300), '');
  v_offen  int;
  v_gelb   int;
BEGIN
  PERFORM public.bewerbungen_pruefe_chefin();
  SELECT * INTO b FROM public.bewerbungen WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Bewerbung nicht gefunden'; END IF;

  CASE p_aktion
  WHEN 'basis_passt' THEN
    IF b.status <> 'neu' THEN RAISE EXCEPTION 'Basis-Check ist schon erledigt'; END IF;
    v_neu := 'basis_ok';

  WHEN 'basis_passt_nicht' THEN
    IF b.status <> 'neu' THEN RAISE EXCEPTION 'Basis-Check ist schon erledigt'; END IF;
    IF v_notiz IS NULL THEN RAISE EXCEPTION 'Grund für den Basis-Check fehlt'; END IF;
    UPDATE public.bewerbungen SET basis_grund = v_notiz WHERE id = p_id;
    v_neu := 'absage_offen';

  WHEN 'schliessen' THEN
    -- Nur VOR dem Matcher (keine Antwort, Link abgelaufen). Nach dem Matcher
    -- bekommt jede Person eine Rückmeldung: Zusage oder Absage.
    IF b.status = 'matcher_offen' AND b.matcher_gueltig_bis >= now() THEN
      RAISE EXCEPTION 'Der Link ist noch gültig';
    END IF;
    IF b.status NOT IN ('neu','basis_ok','matcher_offen') THEN
      RAISE EXCEPTION 'Nach dem Matcher endet jeder Vorgang mit Zusage oder Absage';
    END IF;
    v_neu := 'geschlossen';

  WHEN 'gespraech' THEN
    IF b.status <> 'ausgewertet' THEN RAISE EXCEPTION 'Gespräch erst nach dem Matcher'; END IF;
    IF b.matcher_gesamt = 'r' THEN
      RAISE EXCEPTION 'Rot bleibt Ausschluss – keine Einladung zum Gespräch';
    END IF;
    IF b.matcher_gesamt = 'y' AND NOT coalesce((b.pruefzone ->> 'eingeladen')::boolean, false) THEN
      RAISE EXCEPTION 'Gelb: Einladung nur mit schriftlicher Begründung in der Prüfzone';
    END IF;
    v_neu := 'gespraech';

  WHEN 'probearbeiten' THEN
    IF b.status <> 'gespraech' THEN RAISE EXCEPTION 'Probearbeiten erst nach dem Gespräch'; END IF;
    IF b.matcher_gesamt = 'y' THEN
      SELECT count(*) FILTER (WHERE coalesce(b.pruefzone -> 'urteile' ->> ((i - 1) || '-' || b.matcher_antworten[i]), '') <> 'g'),
             count(*)
        INTO v_offen, v_gelb
      FROM generate_subscripts(b.matcher_antworten, 1) i
      JOIN public.matcher_optionen o ON o.situation = i - 1 AND o.nr = b.matcher_antworten[i]
      WHERE o.prueffrage IS NOT NULL;
      IF v_offen > 0 THEN
        RAISE EXCEPTION 'Gelb: Weiter nur, wenn alle Prüfpunkte geklärt sind – Gelb ist eine Prüfzone, keine Warteschleife';
      END IF;
    END IF;
    v_neu := 'probearbeiten';

  WHEN 'zusage' THEN
    IF b.status <> 'probearbeiten' THEN RAISE EXCEPTION 'Zusage erst nach dem Probearbeiten'; END IF;
    v_neu := 'zusage';

  WHEN 'absage' THEN
    IF b.status NOT IN ('basis_ok','ausgewertet','gespraech','probearbeiten') THEN
      RAISE EXCEPTION 'Absage in diesem Schritt nicht möglich';
    END IF;
    v_neu := 'absage_offen';

  WHEN 'absage_verschickt' THEN
    -- Freigabe durch die Chefin = Absage geht raus. Ändert nie die Farbe.
    IF b.status <> 'absage_offen' THEN RAISE EXCEPTION 'Keine Absage offen'; END IF;
    v_neu := 'abgesagt';

  ELSE
    RAISE EXCEPTION 'Unbekannter Schritt';
  END CASE;

  UPDATE public.bewerbungen SET status = v_neu WHERE id = p_id;
  PERFORM public.bewerbung_verlauf(p_id, CASE p_aktion
    WHEN 'basis_passt'       THEN 'Basis-Check: passt'
    WHEN 'basis_passt_nicht' THEN 'Basis-Check: passt nicht (' || v_notiz || ')'
    WHEN 'schliessen'        THEN 'Vorgang geschlossen' || coalesce(' (' || v_notiz || ')', '')
    WHEN 'gespraech'         THEN 'Zum Gespräch eingeladen'
    WHEN 'probearbeiten'     THEN 'Probearbeiten vereinbart'
    WHEN 'zusage'            THEN 'Zusage'
    WHEN 'absage'            THEN 'Absage vorbereitet' || coalesce(' (' || v_notiz || ')', '')
    WHEN 'absage_verschickt' THEN 'Absage freigegeben und verschickt'
  END);
END;
$$;


-- ── 7. Ausführrechte ────────────────────────────────────────────────────
-- Supabase gibt neuen Funktionen per Default EXECUTE für anon/authenticated.
-- Deshalb erst alles entziehen, dann gezielt freigeben.

REVOKE ALL ON FUNCTION
  public.bewerbungen_ist_chefin(), public.bewerbungen_pruefe_chefin(),
  public.matcher_auswerten(smallint[]), public.bewerbung_verlauf(uuid, text),
  public.matcher_token_neu(), public.matcher_token_hash(text),
  public.bewerbung_einreichen(text, text, text, text, text, text, text, text, text, boolean),
  public.matcher_laden(text), public.matcher_abschicken(text, smallint[]),
  public.bewerbungen_liste(), public.bewerbung_detail(uuid), public.matcher_katalog(),
  public.bewerbung_matcher_link(uuid, boolean), public.bewerbung_pruefzone(uuid, jsonb),
  public.bewerbung_schritt(uuid, text, text)
FROM public, anon, authenticated;

-- Ohne Login (Karriere-Seite, Matcher-Link)
GRANT EXECUTE ON FUNCTION
  public.bewerbung_einreichen(text, text, text, text, text, text, text, text, text, boolean),
  public.matcher_laden(text), public.matcher_abschicken(text, smallint[])
TO anon, authenticated;

-- Angemeldet; jede Funktion prüft selbst, ob es die Chefin ist
GRANT EXECUTE ON FUNCTION
  public.bewerbungen_ist_chefin(),
  public.bewerbungen_liste(), public.bewerbung_detail(uuid), public.matcher_katalog(),
  public.bewerbung_matcher_link(uuid, boolean), public.bewerbung_pruefzone(uuid, jsonb),
  public.bewerbung_schritt(uuid, text, text)
TO authenticated;


-- ── 8. Kontrolle (nur lesen) ────────────────────────────────────────────
-- Erwartung: keine Zeile (alle neuen Tabellen haben RLS).
SELECT c.relname AS tabelle_ohne_rls
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r' AND NOT c.relrowsecurity
  AND c.relname IN ('bewerbungen','matcher_felder','matcher_situationen','matcher_optionen');
-- Erwartung: nur service_role.
SELECT table_name, grantee, string_agg(privilege_type, ', ') AS rechte
FROM information_schema.role_table_grants
WHERE table_schema = 'public' AND grantee IN ('anon','authenticated','service_role')
  AND table_name IN ('bewerbungen','matcher_felder','matcher_situationen','matcher_optionen')
GROUP BY 1, 2 ORDER BY 1, 2;
