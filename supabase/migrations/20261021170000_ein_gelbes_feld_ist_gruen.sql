-- ════════════════════════════════════════════════════════════════════════
-- Salon Matcher: ein einzelnes gelbes Feld ergibt Gesamt-Grün
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj, nach 20261021150000_gelb_einladen_absage_zuruecknehmen.sql)
--
-- Entscheidung der Chefin (2026-10-21), nach dem Test mit einer passenden
-- Mitarbeiterin (3 Felder grün, Offenheit gelb → bisher Gesamt-Gelb):
--   * mindestens ein Feld rot          → Gesamt-Rot   (unverändert)
--   * zwei oder mehr Felder gelb       → Gesamt-Gelb  (Prüfzone)
--   * höchstens ein Feld gelb, kein rot → Gesamt-Grün (gelbes Feld als Hinweis)
-- Die Farben der einzelnen Antworten und Felder bleiben unverändert.
--
-- Ersetzt matcher_auswerten und rechnet offene Vorgänge (ausgewertet,
-- Gespräch) neu. Abgeschlossene Vorgänge bleiben, wie sie entschieden wurden.
-- Mehrfach ausführbar.
-- ════════════════════════════════════════════════════════════════════════

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
  v_gesamt text;
  v_gelb   int;
  r        record;
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

  SELECT count(*) FILTER (WHERE value #>> '{}' = 'y') INTO v_gelb FROM jsonb_each(v_felder);
  v_gesamt := CASE
    WHEN EXISTS (SELECT 1 FROM jsonb_each(v_felder) WHERE value #>> '{}' = 'r') THEN 'r'
    WHEN v_gelb >= 2 THEN 'y'
    ELSE 'g' END;
  RETURN jsonb_build_object('gesamt', v_gesamt, 'felder', v_felder);
END;
$$;

REVOKE ALL ON FUNCTION public.matcher_auswerten(smallint[]) FROM public, anon, authenticated;

-- Offene Vorgänge nach der neuen Regel neu einordnen
UPDATE public.bewerbungen
SET matcher_gesamt = public.matcher_auswerten(matcher_antworten) ->> 'gesamt'
WHERE matcher_antworten IS NOT NULL AND status IN ('ausgewertet', 'gespraech');
