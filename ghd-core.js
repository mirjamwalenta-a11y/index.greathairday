// ============================================================
// GHD-CORE.JS — Zentrales Betriebssystem Modul
// A Great Hair Day OS
// Einbinden in jede App: <script src="/ghd-core.js"></script>
// ============================================================

const GHD_SUPABASE_URL = 'https://wrxlaltgtgkdomklgrlj.supabase.co';
const GHD_SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndyeGxhbHRndGdrZG9ta2xncmxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyNDYwMzYsImV4cCI6MjA5OTgyMjAzNn0.Bw8ch-EJb_cLYTwxHdpjUJWgoCjje3Jc32pB0yiBS8g';

// ── Supabase Client ──────────────────────────────────────────
const _ghdSupabase = supabase.createClient(GHD_SUPABASE_URL, GHD_SUPABASE_KEY, {
  auth: { persistSession: true, autoRefreshToken: true }
});

// ── Interner State ───────────────────────────────────────────
let _ghdSession  = null;
let _ghdProfil   = null;
let _ghdApps     = null;

// ============================================================
// ÖFFENTLICHE API
// ============================================================

const GHD = {

  // ── Session & Login ───────────────────────────────────────

  /** Gibt die aktuelle Session zurück (oder null) */
  async getSession() {
    const { data } = await _ghdSupabase.auth.getSession();
    _ghdSession = data?.session || null;
    return _ghdSession;
  },

  /** Gibt das Profil des eingeloggten Users zurück */
  async getProfil() {
    if (_ghdProfil) return _ghdProfil;
    const session = await GHD.getSession();
    if (!session) return null;

    const res = await fetch(
      `${GHD_SUPABASE_URL}/rest/v1/profiles?auth_user_id=eq.${session.user.id}&aktiv=eq.true&select=*&limit=1`,
      { headers: GHD._headers(session) }
    );
    const data = await res.json();
    _ghdProfil = data?.[0] || null;
    return _ghdProfil;
  },

  /** Gibt die Rolle zurück: 'boss' | 'stylist' | 'lehrling' | 'gast' | null */
  async getRolle() {
    const profil = await GHD.getProfil();
    return profil?.rolle || null;
  },

  /** Prüft ob User eine bestimmte Rolle hat */
  async hatRolle(rolle) {
    const aktuelleRolle = await GHD.getRolle();
    return aktuelleRolle === rolle;
  },

  /** Gibt erlaubte Apps für den aktuellen User zurück */
  async getErlaubteApps() {
    if (_ghdApps) return _ghdApps;
    const session = await GHD.getSession();
    const profil  = await GHD.getProfil();
    if (!session || !profil) return [];

    const res = await fetch(
      `${GHD_SUPABASE_URL}/rest/v1/ghd_app_berechtigungen?rolle=eq.${profil.rolle}&select=app_id,ghd_apps(*)`,
      { headers: GHD._headers(session) }
    );
    const data = await res.json();
    _ghdApps = (data || []).map(d => d.ghd_apps).filter(Boolean);
    _ghdApps.sort((a, b) => a.sortierung - b.sortierung);
    return _ghdApps;
  },

  /** Logout */
  async logout() {
    await _ghdSupabase.auth.signOut();
    _ghdSession = null;
    _ghdProfil  = null;
    _ghdApps    = null;
    window.location.href = '/index.html';
  },

  // ── App Guard ─────────────────────────────────────────────

  /**
   * Schützt eine App — muss am Anfang jeder App aufgerufen werden.
   * 
   * Verwendung:
   *   await GHD.requireAccess('lernquiz');
   * 
   * Bei fehlendem Zugang → Weiterleitung zu index.html
   */
  async requireAccess(appId) {
    const session = await GHD.getSession();

    // Kein Login → zur Startseite
    if (!session) {
      window.location.href = '/index.html?reason=login';
      return false;
    }

    const profil = await GHD.getProfil();

    // Kein aktives Profil → kein Zugang
    if (!profil) {
      window.location.href = '/index.html?reason=kein-profil';
      return false;
    }

    // Boss hat immer Zugang
    if (profil.rolle === 'boss') return true;

    // App-Berechtigung prüfen
    const apps = await GHD.getErlaubteApps();
    const hatZugang = apps.some(a => a.id === appId);

    if (!hatZugang) {
      window.location.href = '/index.html?reason=kein-zugang';
      return false;
    }

    return true;
  },

  // ── Navigation rendern ────────────────────────────────────

  /**
   * Rendert eine einfache Navigation in ein Element.
   * 
   * Verwendung:
   *   await GHD.renderNav('nav-container', 'lernquiz');
   */
  async renderNav(containerId, aktiveAppId = '') {
    const profil = await GHD.getProfil();
    const apps   = await GHD.getErlaubteApps();
    const el     = document.getElementById(containerId);
    if (!el || !profil) return;

    el.innerHTML = `
      <div style="display:flex;align-items:center;justify-content:space-between;
                  padding:12px 16px;background:#FAF8F3;border-bottom:1px solid #e8e0d0;">
        <a href="/index.html" style="font-weight:700;color:#1a1610;text-decoration:none;font-size:15px;">
          ← A Great Hair Day
        </a>
        <div style="display:flex;align-items:center;gap:10px;">
          <span style="font-size:12px;color:#896c32;">${profil.vorname}</span>
          <button onclick="GHD.logout()"
            style="background:none;border:1px solid #e8e0d0;border-radius:8px;
                   padding:6px 12px;font-size:12px;cursor:pointer;color:#5a4a28;">
            Abmelden
          </button>
        </div>
      </div>
    `;
  },

  // ── Startseite — Apps anzeigen ────────────────────────────

  /**
   * Rendert die erlaubten Apps als Kacheln.
   * 
   * Verwendung:
   *   await GHD.renderAppGrid('apps-container');
   */
  async renderAppGrid(containerId) {
    const apps = await GHD.getErlaubteApps();
    const profil = await GHD.getProfil();
    const el = document.getElementById(containerId);
    if (!el) return;

    if (!apps || apps.length === 0) {
      el.innerHTML = `<p style="color:#896c32;text-align:center;padding:40px;">
        Keine Apps verfügbar. Bitte wende dich an Mirjam.
      </p>`;
      return;
    }

    el.innerHTML = apps.map(app => `
      <a href="${app.url}" style="
        display:flex;flex-direction:column;gap:8px;
        background:#fff;border:1.5px solid #e8e0d0;border-radius:16px;
        padding:20px 16px;text-decoration:none;color:#1a1610;
        transition:border-color 0.15s,box-shadow 0.15s;
      "
      onmouseover="this.style.borderColor='#896c32';this.style.boxShadow='0 4px 16px rgba(137,108,50,0.12)'"
      onmouseout="this.style.borderColor='#e8e0d0';this.style.boxShadow='none'">
        <div style="font-size:28px;">${app.icon}</div>
        <div style="font-weight:700;font-size:15px;">${app.name}</div>
        <div style="font-size:12px;color:#896c32;">${app.beschreibung || ''}</div>
      </a>
    `).join('');
  },

  // ── Interne Hilfsfunktionen ───────────────────────────────

  _headers(session) {
    const token = session?.access_token || GHD_SUPABASE_KEY;
    return {
      'apikey':        GHD_SUPABASE_KEY,
      'Authorization': `Bearer ${token}`,
      'Content-Type':  'application/json'
    };
  }
};

// ============================================================
// VERWENDUNG IN EINER APP:
//
// 1. Einbinden (vor dem eigenen Script):
//    <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js"></script>
//    <script src="/ghd-core.js"></script>
//
// 2. Am Anfang der App:
//    document.addEventListener('DOMContentLoaded', async () => {
//      const ok = await GHD.requireAccess('lernquiz');
//      if (!ok) return;
//      // App-Logik hier...
//    });
//
// 3. Navigation einblenden:
//    await GHD.renderNav('nav-container', 'lernquiz');
//
// 4. App-IDs:
//    woerni, team, abwesenheit, checklisten,
//    lernquiz, schnuppertag, belege, lager,
//    reichweite, meisterin
// ============================================================
