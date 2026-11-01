-- ════════════════════════════════════════════════════════════════════════
-- Lücke schließen: „Team schreibt“ auf den Wörni-Tabellen
-- (Supabase-Projekt wrxlaltgtgkdomklgrlj)
--
-- Fund 2026-11-01: ghd_aufgaben und ghd_aufgaben_vorlagen haben eine
-- INSERT-Policy „Team schreibt“ für die Rolle public (= auch anon, also
-- jede Person ohne Anmeldung mit dem öffentlichen Schlüssel aus dem
-- Quelltext). Zusätzlich hat anon dort sämtliche Tabellenrechte.
--
-- Die Policy ist überflüssig: Angemeldete dürfen weiterhin anlegen über
-- „ghd_aufgaben_insert“ / „ghd_aufgaben_vorlagen_insert“ (authenticated)
-- und „eingeloggt_alles“. Alle Apps greifen auf diese Tabellen nur noch
-- angemeldet oder über Serverfunktionen (SECURITY DEFINER) zu – geprüft in
-- allen App-Repos: Schaltzentrale, Mikro, Startseite (Badge) nutzen das
-- Anmelde-Token, die übrigen Apps melden per RPC.
--
-- CLAUDE.md Regel 1: anon bekommt nur Rechte, wenn eine anon-Policy
-- begründet ist – hier ist keine.
--
-- Mehrfach ausführbar. Am Ende ein Bericht über weitere Policies, die
-- Schreiben ohne Anmeldungs-Prüfung erlauben könnten (nur lesen, ändert nichts).
-- ════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Team schreibt" ON public.ghd_aufgaben;
DROP POLICY IF EXISTS "Team schreibt" ON public.ghd_aufgaben_vorlagen;

REVOKE ALL ON public.ghd_aufgaben          FROM anon;
REVOKE ALL ON public.ghd_aufgaben_vorlagen FROM anon;

NOTIFY pgrst, 'reload schema';

-- ── Bericht: weitere verdächtige Schreib-Policies im ganzen Projekt ──────
-- Policies für public/anon, die schreiben erlauben und in ihrer Bedingung
-- keine Anmeldung prüfen. Leeres Ergebnis = nichts Weiteres gefunden.
SELECT p.tablename                         AS tabelle,
       p.policyname                        AS policy,
       p.cmd                               AS aktion,
       array_to_string(p.roles, ',')       AS rollen,
       coalesce(p.qual, '-')               AS bedingung,
       coalesce(p.with_check, '-')         AS pruefung_neu,
       has_table_privilege('anon', format('public.%I', p.tablename), 'INSERT') AS anon_darf_einfuegen
FROM pg_policies p
WHERE p.schemaname = 'public'
  AND p.roles && ARRAY['public', 'anon']::name[]
  AND p.cmd IN ('INSERT', 'UPDATE', 'DELETE', 'ALL')
  AND coalesce(p.qual, '')       !~* '(auth\.|current_user|teamapp_|ist_inhaberin|ist_chefin)'
  AND coalesce(p.with_check, '') !~* '(auth\.|current_user|teamapp_|ist_inhaberin|ist_chefin)'
ORDER BY 1, 2;
