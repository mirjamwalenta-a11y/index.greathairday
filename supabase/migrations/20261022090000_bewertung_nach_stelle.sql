-- ════════════════════════════════════════════════════════════════════════
-- Salon Matcher: Bewertung je nach Stelle (Lehrling / fertige Stylist:in)
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj, nach 20261021180000_matcher_direkt_nach_kurzbewerbung.sql)
--
-- Bewertungsregel der Chefin (2026-10-22): Der Matcher ist ein Kulturfilter,
-- kein Persönlichkeitstest und kein endgültiges Urteil. Von fertigen
-- Stylist:innen wird mehr berufliche und menschliche Reife erwartet; bei
-- Lehrlingen zählen Haltung, Lernbereitschaft und Entwicklungspotenzial.
-- Respektlosigkeit und Geringschätzung werden bei niemandem verharmlost.
--
--                                   Stylist:in        Lehrling
--   Rot bei Respekt / Wertschätzung  Rot               Rot
--   Rot bei Offenheit                Rot               Rot (fehlende Lernoffenheit)
--   Rot bei Zuwendung                Rot               zählt als gelbes Feld
--   zwei oder mehr Felder gelb       Gelb              Gelb
--   sonst (höchstens ein Feld gelb)  Grün              Grün
--
-- Ersetzt die Gewichtung aus 20261021170000 (dort war Rot bei Offenheit
-- für alle nur Gelb). Stylist:in = Stelle 'geselle' oder 'wiedereinstieg'.
-- Die Farben der einzelnen Antworten und Felder bleiben unverändert.
--
-- matcher_auswerten bekommt dafür die Stelle als zweiten Parameter.
-- Mehrfach ausführbar. Rechte wie bisher: niemand von außen darf
-- matcher_auswerten aufrufen.
-- ════════════════════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS public.matcher_auswerten(smallint[]);

CREATE OR REPLACE FUNCTION public.matcher_auswerten(p_antworten smallint[], p_stelle text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rang    jsonb := '{"g":0,"y":1,"r":2}';
  v_felder  jsonb := '{"Z":"g","O":"g","R":"g","W":"g"}';
  v_lehrling boolean := p_stelle = 'lehrstelle';
  v_gesamt  text;
  v_gelb    int;
  r         record;
BEGIN
  -- Feld = schlechteste Farbe darin (keine Durchschnitte)
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
  END LOOP;

  -- Lehrlinge: Rot bei Zuwendung zählt als gelbes Feld (oft jugendliche Unreife)
  SELECT count(*) FILTER (WHERE value #>> '{}' = 'y' OR (v_lehrling AND key = 'Z' AND value #>> '{}' = 'r'))
    INTO v_gelb FROM jsonb_each(v_felder);
  v_gesamt := CASE
    WHEN EXISTS (SELECT 1 FROM jsonb_each(v_felder)
                 WHERE value #>> '{}' = 'r' AND NOT (v_lehrling AND key = 'Z')) THEN 'r'
    WHEN (v_lehrling AND v_felder ->> 'Z' = 'r') OR v_gelb >= 2 THEN 'y'
    ELSE 'g' END;
  RETURN jsonb_build_object('gesamt', v_gesamt, 'felder', v_felder);
END;
$$;

REVOKE ALL ON FUNCTION public.matcher_auswerten(smallint[], text) FROM public, anon, authenticated;

-- Abschicken wertet jetzt mit der Stelle aus
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

  v_ergeb := public.matcher_auswerten(p_antworten, b.stelle);

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

REVOKE ALL ON FUNCTION public.matcher_abschicken(text, smallint[]) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.matcher_abschicken(text, smallint[]) TO anon, authenticated;

-- Gesprächsfragen für rote Zuwendungs-Antworten (bei Lehrlingen Prüfzone)
UPDATE public.matcher_optionen SET
  prueffrage = 'Eine neue Kundin erzählt dir lange, was sie stört. Was machst du, bevor du ihr deine Idee zeigst?',
  pruef_gut  = 'hört zu, fragt nach, will verstehen',
  pruef_krit = 'zeigt sofort eigene Arbeiten, lenkt auf sich'
WHERE situation = 0 AND nr = 1;
UPDATE public.matcher_optionen SET
  prueffrage = 'Eine Kollegin erzählt von ihrer Arbeit. Was interessiert dich daran – was fragst du sie?',
  pruef_gut  = 'stellt echte Fragen an die Kollegin',
  pruef_krit = 'kommt schnell auf eigene Geschichten'
WHERE situation = 1 AND nr = 1;

-- Offene Vorgänge nach der neuen Regel neu einordnen
UPDATE public.bewerbungen
SET matcher_gesamt = public.matcher_auswerten(matcher_antworten, stelle) ->> 'gesamt'
WHERE matcher_antworten IS NOT NULL AND status IN ('ausgewertet', 'gespraech');
