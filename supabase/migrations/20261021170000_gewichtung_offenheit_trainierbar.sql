-- ════════════════════════════════════════════════════════════════════════
-- Salon Matcher: Gewichtung – Respekt/Wertschätzung/Zuwendung streng,
-- Offenheit trainierbar
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj, nach 20261021150000_gelb_einladen_absage_zuruecknehmen.sql)
--
-- Entscheidungen der Chefin (2026-10-21), nach dem Test mit einer passenden
-- Mitarbeiterin (3 Felder grün, Offenheit gelb → bisher Gesamt-Gelb).
-- Respekt und Wertschätzung sind ihr am wichtigsten; Offenheit kann sie
-- durch Training und Überzeugung aufbauen.
--   * Rot in Respekt, Wertschätzung oder Zuwendung → Gesamt-Rot (Ausschluss)
--   * Rot in Offenheit                             → Gesamt-Gelb (Prüfzone)
--   * zwei oder mehr Felder gelb                   → Gesamt-Gelb (Prüfzone)
--   * sonst (höchstens ein Feld gelb)              → Gesamt-Grün
-- Die Farben der einzelnen Antworten und Felder bleiben unverändert
-- (Offenheit kann also rot angezeigt werden, zählt aber nicht als Ausschluss).
-- Für die roten Offenheits-Antworten gibt es jetzt Gesprächsfragen, damit
-- sie in der Prüfzone geprüft werden können.
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

  -- Rot in Offenheit zählt wie ein gelbes Feld, aber immer mindestens Gelb
  SELECT count(*) FILTER (WHERE value #>> '{}' = 'y' OR (key = 'O' AND value #>> '{}' = 'r'))
    INTO v_gelb FROM jsonb_each(v_felder);
  v_gesamt := CASE
    WHEN EXISTS (SELECT 1 FROM jsonb_each(v_felder) WHERE key <> 'O' AND value #>> '{}' = 'r') THEN 'r'
    WHEN v_felder ->> 'O' = 'r' OR v_gelb >= 2 THEN 'y'
    ELSE 'g' END;
  RETURN jsonb_build_object('gesamt', v_gesamt, 'felder', v_felder);
END;
$$;

REVOKE ALL ON FUNCTION public.matcher_auswerten(smallint[]) FROM public, anon, authenticated;

-- Gesprächsfragen für die roten Offenheits-Antworten (Prüfzone)
UPDATE public.matcher_optionen SET
  prueffrage = 'Eine Kollegin schlägt etwas vor, das du anders machst. Wie gehst du damit um – und wann sagst du, was du denkst?',
  pruef_gut  = 'hört zu, fragt nach und probiert es aus',
  pruef_krit = 'wartet ab, bis sich die andere anpasst'
WHERE situation = 1 AND nr = 2;
UPDATE public.matcher_optionen SET
  prueffrage = 'Was war die letzte Neuerung, der du eine echte Chance gegeben hast, obwohl du skeptisch warst?',
  pruef_gut  = 'nennt ein konkretes Beispiel und hat es eine Weile ausprobiert',
  pruef_krit = 'findet kein Beispiel, alte Erfahrung als Grund gegen Neues'
WHERE situation = 2 AND nr = 2;
UPDATE public.matcher_optionen SET
  prueffrage = 'Die Chefin zeigt dir eine neue Technik, du findest deine besser. Was machst du – ganz konkret?',
  pruef_gut  = 'probiert es aus und sagt danach ehrlich, was sie denkt',
  pruef_krit = 'nickt und bleibt beim Alten'
WHERE situation = 6 AND nr = 2;

-- Offene Vorgänge nach der neuen Regel neu einordnen
UPDATE public.bewerbungen
SET matcher_gesamt = public.matcher_auswerten(matcher_antworten) ->> 'gesamt'
WHERE matcher_antworten IS NOT NULL AND status IN ('ausgewertet', 'gespraech');
