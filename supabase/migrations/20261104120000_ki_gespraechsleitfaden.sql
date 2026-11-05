-- ════════════════════════════════════════════════════════════════════════
-- KI-Gesprächsleitfaden für Bewerbungen
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj, nach 20261101140000_luecke_team_schreibt_schliessen.sql)
--
-- Wunsch der Chefin (2026-11-04): Vor dem Kennenlernen soll eine KI aus den
-- Eckdaten und den Matcher-Antworten einen persönlichen Gesprächsleitfaden
-- vorschlagen (5–6 Fragen, je mit „warum“ und „worauf achten“).
--
-- Grundsätze (BEWERBUNGSPROZESS.md, Abschnitt „KI-Gesprächsleitfaden“):
--   * Die KI bewertet niemanden. Sie vergibt keine Farbe, keine Punkte,
--     keine Empfehlung zu- oder absagen. Grün/Gelb/Rot rechnet weiter
--     ausschließlich die Datenbank (matcher_auswerten).
--   * Datensparsam: An die KI gehen nur Stelle, Ausbildung, Stunden, Start,
--     „Über dich“ und die Matcher-Auswertung. Nie Name, Telefon, E-Mail,
--     Portfolio-Link oder die ID der Bewerbung.
--   * Kein Leitfaden bei Gesamt-Rot (Rot führt nie zum Gespräch) und nur,
--     solange es ein Gespräch geben kann (ausgewertet, gespraech,
--     probearbeiten).
--
-- Sicherheit (CLAUDE.md, Regeln 1–3):
--   * Keine neue Tabelle: der Leitfaden steht als Spalte in
--     public.bewerbungen (RLS an, keine Policy, keine Grants für
--     anon/authenticated – unverändert). Er wird mit der Bewerbung
--     gelöscht (bewerbung_loeschen, Löschfrist 6 Monate).
--   * Beide Funktionen prüfen selbst, ob die Inhaberin aufruft
--     (bewerbungen_pruefe_chefin). Die Edge Function „bewerbung-ki“ ruft sie
--     mit dem Token der angemeldeten Person auf, nie mit service_role.
--   * Ausführrechte nur für authenticated, nicht für anon.
--
-- Ausführen: einmal im Supabase SQL-Editor. Mehrfach ausführbar.
-- ════════════════════════════════════════════════════════════════════════

ALTER TABLE public.bewerbungen
  ADD COLUMN IF NOT EXISTS ki_leitfaden jsonb;   -- {"erstellt_am", "modell", "fragen":[{frage, warum, achten}]}


-- ── 1. Eingabe für die KI (nur die nötigen, nicht identifizierenden Daten) ─

CREATE OR REPLACE FUNCTION public.bewerbung_ki_eingabe(p_id uuid)
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
  IF b.matcher_antworten IS NULL OR b.matcher_gesamt IS NULL THEN
    RAISE EXCEPTION 'Der Salon Matcher ist noch nicht ausgefüllt';
  END IF;
  IF b.matcher_gesamt = 'r' THEN
    RAISE EXCEPTION 'Bei Gesamt-Rot gibt es kein Gespräch und deshalb keinen Leitfaden';
  END IF;
  IF b.status NOT IN ('ausgewertet', 'gespraech', 'probearbeiten') THEN
    RAISE EXCEPTION 'Ein Leitfaden ist nur vor oder während des Kennenlernens möglich';
  END IF;

  RETURN jsonb_build_object(
    'stelle',     b.stelle,
    'ausbildung', b.ausbildung,
    'stunden',    b.stunden,
    'start',      b.start,
    'ueber_dich', b.ueber_dich,
    'gesamt',     b.matcher_gesamt,
    'felder', (SELECT jsonb_agg(jsonb_build_object(
                 'name', f.name, 'farbe', b.matcher_felder ->> f.kuerzel,
                 'gespraechsfrage', f.gespraech) ORDER BY f.kuerzel)
               FROM public.matcher_felder f),
    -- Nur Antworten, die nicht in jedem Feld grün sind: dort braucht es Fragen.
    'auffaellig', (SELECT jsonb_agg(jsonb_build_object(
                     'situation', s.frage, 'gewaehlt', o.text,
                     'einordnung', o.begruendung, 'prueffrage', o.prueffrage,
                     'gut_waere', o.pruef_gut, 'kritisch_waere', o.pruef_krit)
                   ORDER BY o.situation)
                   FROM generate_subscripts(b.matcher_antworten, 1) i
                   JOIN public.matcher_optionen o ON o.situation = i - 1 AND o.nr = b.matcher_antworten[i]
                   JOIN public.matcher_situationen s ON s.nr = o.situation
                   WHERE EXISTS (SELECT 1 FROM jsonb_each_text(o.bewertung) e WHERE e.value <> 'g'))
  );
END;
$$;


-- ── 2. Leitfaden speichern (mit Prüfung der Form) ───────────────────────

CREATE OR REPLACE FUNCTION public.bewerbung_ki_leitfaden_speichern(p_id uuid, p_fragen jsonb, p_modell text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  b       public.bewerbungen%ROWTYPE;
  v_neu   jsonb;
  f       jsonb;
BEGIN
  PERFORM public.bewerbungen_pruefe_chefin();
  SELECT * INTO b FROM public.bewerbungen WHERE id = p_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Bewerbung nicht gefunden'; END IF;
  IF b.matcher_gesamt IS DISTINCT FROM 'y' AND b.matcher_gesamt IS DISTINCT FROM 'g' THEN
    RAISE EXCEPTION 'Kein Leitfaden für diese Bewerbung';
  END IF;
  IF b.status NOT IN ('ausgewertet', 'gespraech', 'probearbeiten') THEN
    RAISE EXCEPTION 'Ein Leitfaden ist nur vor oder während des Kennenlernens möglich';
  END IF;

  IF jsonb_typeof(p_fragen) <> 'array' OR jsonb_array_length(p_fragen) NOT BETWEEN 1 AND 8 THEN
    RAISE EXCEPTION 'Leitfaden: 1 bis 8 Fragen erwartet';
  END IF;
  FOR f IN SELECT * FROM jsonb_array_elements(p_fragen) LOOP
    IF jsonb_typeof(f) <> 'object'
       OR char_length(coalesce(f ->> 'frage', ''))  NOT BETWEEN 5 AND 400
       OR char_length(coalesce(f ->> 'warum', ''))  NOT BETWEEN 1 AND 400
       OR char_length(coalesce(f ->> 'achten', '')) NOT BETWEEN 1 AND 400 THEN
      RAISE EXCEPTION 'Leitfaden: jede Frage braucht frage, warum und achten (je höchstens 400 Zeichen)';
    END IF;
  END LOOP;

  v_neu := jsonb_build_object(
    'erstellt_am', now(),
    'modell', left(coalesce(p_modell, ''), 60),
    'fragen', (SELECT jsonb_agg(jsonb_build_object('frage', e ->> 'frage', 'warum', e ->> 'warum', 'achten', e ->> 'achten'))
               FROM jsonb_array_elements(p_fragen) e));

  UPDATE public.bewerbungen SET ki_leitfaden = v_neu WHERE id = p_id;
  PERFORM public.bewerbung_verlauf(p_id,
    CASE WHEN b.ki_leitfaden IS NULL THEN 'KI-Gesprächsleitfaden erstellt (Vorschlag, keine Bewertung)'
         ELSE 'KI-Gesprächsleitfaden neu erstellt (Vorschlag, keine Bewertung)' END);
  RETURN v_neu;
END;
$$;


-- ── 3. Ausführrechte ────────────────────────────────────────────────────
-- Supabase gibt neuen Funktionen per Default EXECUTE für anon/authenticated.

REVOKE ALL ON FUNCTION
  public.bewerbung_ki_eingabe(uuid),
  public.bewerbung_ki_leitfaden_speichern(uuid, jsonb, text)
FROM public, anon, authenticated;

-- Angemeldet; jede Funktion prüft selbst, ob es die Chefin ist
GRANT EXECUTE ON FUNCTION
  public.bewerbung_ki_eingabe(uuid),
  public.bewerbung_ki_leitfaden_speichern(uuid, jsonb, text)
TO authenticated;
