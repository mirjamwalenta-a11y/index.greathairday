-- ════════════════════════════════════════════════════════════════════════
-- Gesprächsnotizen zum persönlichen Leitfaden
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj, nach 20261104150000_bewerbungen_wartezeit.sql)
--
-- Wunsch der Chefin (2026-11-05): Beim Kennenlernen zu jeder Frage des
-- Leitfadens Notizen oder die Antwort am Tablet eintippen. Die Notizen
-- gehören zur Bewerbung, sind auf jedem Gerät der Chefin abrufbar und
-- werden mit der Bewerbung gelöscht (spätestens nach 6 Monaten).
--
-- Sicherheit (CLAUDE.md, Regeln 1–3):
--   * Keine neue Tabelle: Spalte in public.bewerbungen (RLS an, keine
--     Policy, keine Grants für anon/authenticated – unverändert).
--   * Speichern nur über die Funktion unten; sie prüft selbst die
--     Inhaberin. EXECUTE nur für authenticated.
--   * Notizen gehen nie an die KI (bewerbung_ki_eingabe bleibt unverändert).
--   * Kein Eintrag im Verlauf: Notizen sind keine Antwort an die Person und
--     sollen die Wartezeit in der Übersicht nicht zurücksetzen.
--
-- Form: {"notizen": {"<Fragetext>": "<Notiz>", "_allgemein": "..."},
--        "geaendert_am": "..."}
-- Mehrfach ausführbar.
-- ════════════════════════════════════════════════════════════════════════

ALTER TABLE public.bewerbungen
  ADD COLUMN IF NOT EXISTS gespraech_notizen jsonb;

CREATE OR REPLACE FUNCTION public.bewerbung_gespraech_notizen(p_id uuid, p_notizen jsonb)
RETURNS timestamptz
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sauber jsonb;
  v_jetzt  timestamptz := now();
BEGIN
  PERFORM public.bewerbungen_pruefe_chefin();
  IF NOT EXISTS (SELECT 1 FROM public.bewerbungen WHERE id = p_id) THEN
    RAISE EXCEPTION 'Bewerbung nicht gefunden';
  END IF;
  IF p_notizen IS NULL OR jsonb_typeof(p_notizen) <> 'object' THEN
    RAISE EXCEPTION 'Notizen: Objekt erwartet';
  END IF;
  IF (SELECT count(*) FROM jsonb_object_keys(p_notizen)) > 30 THEN
    RAISE EXCEPTION 'Notizen: höchstens 30 Einträge';
  END IF;
  IF EXISTS (SELECT 1 FROM jsonb_each(p_notizen) e
             WHERE char_length(e.key) NOT BETWEEN 1 AND 400
                OR jsonb_typeof(e.value) <> 'string'
                OR char_length(e.value #>> '{}') > 3000) THEN
    RAISE EXCEPTION 'Notizen: jede Notiz höchstens 3000 Zeichen';
  END IF;

  -- Leere Notizen nicht speichern
  SELECT coalesce(jsonb_object_agg(e.key, e.value), '{}'::jsonb) INTO v_sauber
  FROM jsonb_each(p_notizen) e WHERE btrim(e.value #>> '{}') <> '';

  UPDATE public.bewerbungen
  SET gespraech_notizen = CASE WHEN v_sauber = '{}'::jsonb THEN NULL
                               ELSE jsonb_build_object('notizen', v_sauber, 'geaendert_am', v_jetzt) END
  WHERE id = p_id;
  RETURN v_jetzt;
END;
$$;

REVOKE ALL ON FUNCTION public.bewerbung_gespraech_notizen(uuid, jsonb) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.bewerbung_gespraech_notizen(uuid, jsonb) TO authenticated;
