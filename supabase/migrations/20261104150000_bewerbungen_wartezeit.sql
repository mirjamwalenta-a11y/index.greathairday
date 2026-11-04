-- ════════════════════════════════════════════════════════════════════════
-- Bewerbungen: Wartezeit in der Übersicht
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj, nach 20261104120000_ki_gespraechsleitfaden.sql)
--
-- Wunsch der Chefin (2026-11-04): Bei rund 5 Bewerbungen im Monat ist jede
-- wertvoll, gute Leute sind schnell vergeben. Die Übersicht soll zeigen, wer
-- seit wie vielen Tagen auf eine Antwort wartet.
--
-- bewerbungen_liste liefert dafür zusätzlich „seit“: Zeitpunkt des letzten
-- Schritts im Verlauf (KI-Einträge zählen nicht, das ist keine Antwort an
-- die Person). Sonst unverändert gegenüber 20261021120000.
-- Sicherheit unverändert: prüft selbst die Inhaberin, nur authenticated.
-- Mehrfach ausführbar.
-- ════════════════════════════════════════════════════════════════════════

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
      'seit', coalesce((SELECT max((v ->> 'zeit')::timestamptz)
                        FROM jsonb_array_elements(b.verlauf) v
                        WHERE v ->> 'text' NOT LIKE 'KI-%'), b.erstellt_am),
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

REVOKE ALL ON FUNCTION public.bewerbungen_liste() FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.bewerbungen_liste() TO authenticated;
