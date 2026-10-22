-- ════════════════════════════════════════════════════════════════════════
-- Bewerbung löschen (nur Chefin)
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj, nach 20261022090000_bewertung_nach_stelle.sql)
--
-- Die Chefin löscht Test-Einträge oder Bewerbungen (z. B. auf Wunsch der
-- Person, DSGVO-Widerruf) direkt in der Übersicht statt im SQL-Editor.
-- Prüft selbst, ob die Inhaberin aufruft. Löscht genau eine Bewerbung
-- samt Matcher-Antworten (alles steht in derselben Zeile).
-- Mehrfach ausführbar.
-- ════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.bewerbung_loeschen(p_id uuid)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.bewerbungen_pruefe_chefin();
  DELETE FROM public.bewerbungen WHERE id = p_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Bewerbung nicht gefunden'; END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.bewerbung_loeschen(uuid) FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.bewerbung_loeschen(uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';
