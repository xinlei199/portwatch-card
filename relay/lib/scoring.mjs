// vendored from https://portwatch-vi.xyz/assets/js/scoring.js (PortWatch VI, 4lwayz/portwatch-vi)
// Scoring model shared by the website (assets/js/app.js) and the scout (scripts/).
// Keep this file dependency-free so it runs unchanged in browsers and in Node.
//
// A project's score is "how close is it to playing GTA VI on PC, start to finish", 0-100.
// Getting in is a ladder: each step needs the one before it, and it ends at Playable (50%).
// Playing well is four tracks side by side (story, rendering, performance, stability),
// which fill the other 50% once a build is Playable. 100% is the whole game, finished.
//
//   0 ── 10 ── 20 ── 30 ── 40 ── 50 ───────────────────────────── 100
//   Groundwork │ Exe runs │ First frame │ Menus │ In the world │ Playable │ the four tracks │ Complete

export const MILESTONES = [
  { key: 'groundwork', label: 'Groundwork', at: 0, desc: 'Loader, system libraries, shader translation and graphics layer, built before the executable exists.' },
  { key: 'loads', label: 'Exe runs', at: 10, desc: "GTA VI's executable is mapped, its imports resolve and its own code starts running." },
  { key: 'boots', label: 'First frame', at: 20, desc: 'The game draws its first real frames: logos, a loading screen or the intro.' },
  { key: 'menu', label: 'Main menu', at: 30, desc: 'The title screen or first menus are reached and respond to input.' },
  { key: 'world', label: 'In the world', at: 40, desc: 'Story mode loads into the game world and draws it, however broken.' },
  { key: 'playable', label: 'Playable', at: 50, desc: 'You control a character in the world: move around, with the HUD or pause menu working.' },
  { key: 'complete', label: 'Complete', at: 100, desc: 'The whole game can be finished, looking like the console, at 30 FPS or better, without crashing.' },
];

// Past Playable: four tracks, each 0 to 1, that together fill 50 to 100%.
// Story and rendering are judged against the written steps below; performance is average FPS ÷ 30.
export const TRACKS = [
  { key: 'story', label: 'Story progress', weight: 0.35, desc: 'How far into the game you can play.', steps: [
    { v: 0, label: 'Stuck in the opening' },
    { v: 0.1, label: 'Prologue cleared' },
    { v: 0.25, label: 'First missions' },
    { v: 0.4, label: 'First act' },
    { v: 0.6, label: 'Half the story' },
    { v: 0.85, label: 'Main story to the credits' },
    { v: 1, label: '100% completion' },
  ] },
  { key: 'render', label: 'Rendering', weight: 0.25, desc: 'How close the picture is to the console.', steps: [
    { v: 0, label: 'Black or broken' },
    { v: 0.25, label: 'Shapes drawn, mostly unlit or black' },
    { v: 0.5, label: 'Lit, but major effects missing' },
    { v: 0.75, label: 'Close to the console, minor glitches' },
    { v: 1, label: 'Matches the console' },
  ] },
  { key: 'perf', label: 'Performance', weight: 0.2, desc: 'Average FPS ÷ 30, on a named PC.' },
  { key: 'stability', label: 'Stability', weight: 0.2, desc: 'From crashing constantly to stable over long sessions.' },
];

// Groundwork parts and their share of the first 10%.
export const GROUNDWORK = [
  { key: 'loader', label: 'Loader & system libraries', weight: 0.2, desc: 'PE loading plus stand-ins for the console-only DLLs (kernelx, xgameruntime, xmem…).' },
  { key: 'shaders', label: 'Shader translation', weight: 0.28, desc: "Share of GTA VI's ~26,500 precompiled RDNA2 shaders translated to PC formats (SPIR-V / DXIL)." },
  { key: 'graphics', label: 'Graphics layer', weight: 0.32, desc: 'Xbox D3D12.X → PC D3D12 / Vulkan: devices, command lists, pipelines, draws, present.' },
  { key: 'proven', label: 'Proven on another game', weight: 0.2, desc: 'The same layer already runs a different retail Xbox Series game (menu, in-game…).' },
];

export const STABILITY = {
  unknown: { label: 'Unknown', value: 0 },
  constant: { label: 'Crashes constantly', value: 0 },
  often: { label: 'Crashes often', value: 0.25 },
  sometimes: { label: 'Crashes sometimes', value: 0.55 },
  rarely: { label: 'Rarely crashes', value: 0.8 },
  stable: { label: 'Stable', value: 1 },
};

const LADDER = ['loads', 'boots', 'menu', 'world', 'playable'];
const TICK = Object.fromEntries(MILESTONES.map((m) => [m.key, m.at]));

const clamp01 = (v) => (Number.isFinite(+v) ? Math.min(1, Math.max(0, +v)) : 0);

// GTA ladder values are 0 (no), 0.5 (partially, e.g. "reaches the menu but it is broken") or 1 (yes).
export function ladderValue(v) {
  if (v === true) return 1;
  if (v === false || v == null) return 0;
  return clamp01(v);
}

export function groundworkFraction(gw) {
  // An effort with no public code has no groundwork to rate (the field is missing or null).
  return GROUNDWORK.reduce((sum, g) => sum + g.weight * clamp01(gw?.[g.key]), 0);
}

// Each track as 0 to 1. Story and rendering are stored as their step values.
export function trackValues(gta = {}) {
  return {
    story: clamp01(gta.story),
    render: clamp01(gta.render),
    perf: clamp01((+gta.fps || 0) / 30),
    // A label from STABILITY, or a number from 0 to 1 when the owner rates it by hand.
    stability: typeof gta.stability === 'number' ? clamp01(gta.stability) : (STABILITY[gta.stability] || STABILITY.unknown).value,
  };
}

// The STABILITY label to show for a stored value: the label itself, or for a number the
// nearest label (a tie goes to the steadier one), so 0.4 reads "Crashes sometimes".
export function stabilityKey(v) {
  if (typeof v !== 'number') return STABILITY[v] ? v : 'unknown';
  let best = 'constant';
  for (const [key, s] of Object.entries(STABILITY)) {
    if (key === 'unknown') continue;
    if (Math.abs(s.value - v) <= Math.abs(STABILITY[best].value - v) + 1e-9) best = key;
  }
  return best;
}

// The written step a story or rendering value sits on (the highest step at or below it).
export function trackStep(key, v) {
  const steps = TRACKS.find((t) => t.key === key)?.steps || [];
  return [...steps].reverse().find((s) => clamp01(v) >= s.v) || steps[0] || null;
}

export function scoreEffort(effort) {
  const gw = groundworkFraction(effort.groundwork);
  const gta = effort.gta || {};
  let score = TICK.loads * gw;
  let reached = 'groundwork';
  let prevTick = score;

  for (const key of LADDER) {
    const v = ladderValue(gta[key]);
    if (v >= 1) {
      score = TICK[key];
      prevTick = score;
      reached = key;
      continue;
    }
    if (v > 0) score = Math.max(score, prevTick + v * (TICK[key] - prevTick));
    break;
  }

  // The tracks only count once a build is Playable: you can't judge how well a game plays before you can play it.
  const tracks = trackValues(gta);
  const quality = TRACKS.reduce((sum, tr) => sum + tr.weight * tracks[tr.key], 0);
  if (reached === 'playable') {
    score = TICK.playable + quality * (TICK.complete - TICK.playable);
    if (quality >= 1) reached = 'complete';
  }

  // An owner's call the ladder can't express (EDITOR.md, "Owner decisions"): the score is set by hand.
  if (Number.isFinite(effort.manualScore)) score = Math.min(100, Math.max(0, effort.manualScore));

  return {
    score: Math.round(score * 10) / 10,
    groundwork: gw,
    reached,
    reachedLabel: MILESTONES.find((m) => m.key === reached).label,
    tracks,
    playable: reached === 'playable' || reached === 'complete',
  };
}

// Equal scores rank the effort with more GitHub stars first.
export const byStars = (a, b) => (b.stats?.stars || 0) - (a.stats?.stars || 0);

// A private build has no public code (`repo: null`): nobody else can check it, so the race
// lists it under the project it builds on (`basedOn`) without a rank. The headline counts it.
export const isPrivateBuild = (e) => !(typeof e.repo === 'string' && e.repo.includes('/'));

// The headline number: how close the leading effort is, private builds included, plus the top-3 average.
export function overall(efforts) {
  const scored = efforts
    .filter((e) => !e.nuked) // taken offline: kept in the data, no longer shown or ranked
    .map((e) => ({ effort: e, ...scoreEffort(e) }))
    .sort((a, b) => b.score - a.score || byStars(a.effort, b.effort));
  const top = scored.slice(0, 3);
  const leader = scored[0] || null;
  const furthest = scored.reduce((best, s) => {
    const idx = MILESTONES.findIndex((m) => m.key === s.reached);
    return idx > best ? idx : best;
  }, 0);
  return {
    leader,
    score: leader ? leader.score : 0,
    top3: top.length ? Math.round((top.reduce((a, s) => a + s.score, 0) / top.length) * 10) / 10 : 0,
    furthest: MILESTONES[furthest],
    ranked: scored,
  };
}
