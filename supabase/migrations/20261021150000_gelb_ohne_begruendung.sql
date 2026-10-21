-- ════════════════════════════════════════════════════════════════════════
-- Bewerbungen: Gelb ohne schriftliche Begründung zum Gespräch einladen
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj, nach 20261021120000_bewerbungen_salon_matcher.sql)
--
-- Entscheidung der Chefin (2026-10-21): Bei Gesamt-Gelb lädt sie mit einem
-- Klick ein, ohne Häkchen und Begründung. Unverändert bleibt:
--   * Rot kann nie zum Gespräch.
--   * Gelb kommt nur zum Probearbeiten, wenn im Gespräch alle gelben
--     Prüfpunkte als „geklärt“ markiert sind.
--
-- Ersetzt nur die Funktion bewerbung_schritt. Rechte bleiben bei
-- CREATE OR REPLACE erhalten; zur Sicherheit unten noch einmal gesetzt.
-- Mehrfach ausführbar.
-- ════════════════════════════════════════════════════════════════════════

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

REVOKE ALL ON FUNCTION public.bewerbung_schritt(uuid, text, text) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.bewerbung_schritt(uuid, text, text) TO authenticated;
