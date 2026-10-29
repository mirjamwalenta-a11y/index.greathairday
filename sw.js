// Service Worker dieser App: macht sie offline nutzbar.
// Die eigentliche Logik (Dateien merken, Supabase-Daten merken, Änderungen
// ohne Netz in einer Warteschlange sammeln und nachschicken, Konfliktregel
// „nichts überschreiben“) steckt zentral in ghd-offline-sw.js im Repo
// abwesenheiten-ghd und gilt für alle Great-Hair-Day-Apps gleich.
// Neue Seiten/Dateien dieser App hier bei `vorab` ergänzen.
self.GHD_OFFLINE = {
  app: 'start',
  version: '2026-10-29d',
  start: './index.html',
  vorab: [
    './',
    './index.html',
    './apps.html',
    './mikro.html',
    './mitarbeiter.html',
    './schaltzentrale.html',
    './sponsorenwand.html',
    './verein.html',
    './sponsoring.html',
    './impressum.html',
    './bilder/haarnetzwerk-logo-schwarz.png',
    './fonts/CormorantGaramond-normal-500.woff2',
    './fonts/CormorantGaramond-italic-500.woff2',
    './fonts/Jost-normal-400.woff2',
    './manifest.json',
    'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js',
    'https://mirjamwalenta-a11y.github.io/abwesenheiten-ghd/icon-512.png'
  ]
};
importScripts('https://mirjamwalenta-a11y.github.io/abwesenheiten-ghd/ghd-offline-sw.js');
