-- ════════════════════════════════════════════════════════════════════════
-- Salon Matcher direkt nach der Kurzbewerbung
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj, nach 20261021170000_gewichtung_offenheit_trainierbar.sql)
--
-- Entscheidung der Chefin (2026-10-21): Der Weg „Kurzbewerbung → Basis-Check
-- → Link verschicken → Matcher“ ist im Alltag zu umständlich. Wer die
-- Kurzbewerbung abschickt, startet den Matcher sofort im Anschluss. Den
-- Basis-Check macht die Chefin danach zusammen mit der Entscheidung.
--
-- bewerbung_einreichen legt die Bewerbung jetzt gleich mit einem
-- persönlichen Matcher-Token an (Status matcher_offen, 7 Tage gültig,
-- einmal ausfüllbar) und gibt das Token genau einmal an den Browser zurück,
-- der die Bewerbung abgeschickt hat. Gespeichert wird weiter nur der Hash.
-- Sonst ändert sich nichts an Rechten oder Regeln: anon kann weiterhin nur
-- anlegen, nichts lesen.
--
-- Der Rückgabetyp ändert sich (void → jsonb), deshalb DROP + CREATE.
-- Mehrfach ausführbar.
-- ════════════════════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS public.bewerbung_einreichen(text, text, text, text, text, text, text, text, text, boolean);

CREATE FUNCTION public.bewerbung_einreichen(
  p_name text, p_telefon text, p_email text, p_stelle text, p_ausbildung text,
  p_ueber_dich text, p_stunden text, p_start text, p_portfolio text, p_einwilligung boolean
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id    uuid;
  v_token text := public.matcher_token_neu();
BEGIN
  IF p_einwilligung IS NOT TRUE THEN
    RAISE EXCEPTION 'Einwilligung fehlt';
  END IF;
  IF (SELECT count(*) FROM public.bewerbungen WHERE erstellt_am > now() - interval '1 hour') >= 30 THEN
    RAISE EXCEPTION 'Zu viele Bewerbungen – bitte später nochmal versuchen';
  END IF;

  INSERT INTO public.bewerbungen (name, telefon, email, stelle, ausbildung, ueber_dich, stunden, start, portfolio, einwilligung_am,
                                  status, matcher_token_hash, matcher_verschickt_am, matcher_gueltig_bis)
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
    now(),
    'matcher_offen', public.matcher_token_hash(v_token), now(), now() + interval '7 days'
  )
  RETURNING id INTO v_id;
  PERFORM public.bewerbung_verlauf(v_id, 'Kurzbewerbung eingegangen, Matcher gestartet');
  RETURN jsonb_build_object('token', v_token);
END;
$$;

REVOKE ALL ON FUNCTION public.bewerbung_einreichen(text, text, text, text, text, text, text, text, text, boolean) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.bewerbung_einreichen(text, text, text, text, text, text, text, text, text, boolean) TO anon, authenticated;
