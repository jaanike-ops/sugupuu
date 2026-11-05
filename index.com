<!DOCTYPE html>
<html lang="et">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sugupuu - Jaanike</title>
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Plus+Jakarta+Sans:wght@400;500;600&display=swap" rel="stylesheet">
<style>
:root{--paper:#fdfaf3;--paper2:#f5efe1;--ink:#2b1a20;--gold:#e8b44a;--line:#e8ddd0;--card:#ffffff;}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font-family:'Plus Jakarta Sans',sans-serif;}
h1,h2{font-family:'Instrument Serif',serif;}
.header{position:sticky;top:0;z-index:10;background:rgba(253,250,243,0.9);backdrop-filter:blur(12px);border-bottom:1px solid var(--line);padding:14px 20px;display:flex;gap:16px;align-items:center;justify-content:space-between;flex-wrap:wrap;}
.logo{display:flex;align-items:center;gap:12px}.logo-icon{width:40px;height:40px;background:var(--ink);color:var(--gold);display:grid;place-items:center;border-radius:12px;font-family:'Instrument Serif';font-size:22px}
.search{display:flex;gap:8px;align-items:center;background:var(--card);border:1px solid var(--line);border-radius:999px;padding:6px 14px;min-width:240px}
.search input{border:0;outline:0;background:transparent;width:100%;font:inherit}
.btn{border:1px solid var(--line);background:var(--card);padding:8px 14px;border-radius:999px;font:500 14px 'Plus Jakarta Sans';cursor:pointer}
.btn.primary{background:var(--ink);color:var(--paper);border-color:var(--ink)}
.canvas-wrap{position:relative;width:100%;height:calc(100vh - 70px);overflow:hidden;cursor:grab}
.canvas{position:absolute;left:0;top:0;transform-origin:0 0;will-change:transform}
.tree{display:flex;flex-direction:column;align-items:center;gap:48px;padding:80px}
.gen{display:flex;gap:32px;justify-content:center;flex-wrap:nowrap}
.card{width:200px;background:var(--card);border:1px solid var(--line);border-radius:20px;padding:14px;box-shadow:0 8px 24px rgba(43,26,32,0.06);cursor:pointer;transition:.2s;position:relative}
.card:hover{transform:translateY(-3px);box-shadow:0 16px 32px rgba(43,26,32,0.1);border-color:var(--gold)}
.card.selected{border-color:var(--gold);box-shadow:0 0 0 2px var(--gold)}
.avatar{width:56px;height:56px;border-radius:16px;background:var(--paper2);display:grid;place-items:center;font-family:'Instrument Serif';font-size:22px;margin-bottom:10px}
.meta{font-size:12px;color:#8a7a6e}.name{font-weight:600;font-size:15px;margin:2px 0}
.couple{display:flex;gap:16px;align-items:center;position:relative}
.couple::after{content:'♥';position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);background:var(--paper);border:1px solid var(--line);width:22px;height:22px;border-radius:50%;display:grid;place-items:center;font-size:10px;color:var(--gold)}
.side{position:fixed;right:20px;top:90px;width:360px;max-height:calc(100vh - 110px);background:var(--card);border:1px solid var(--line);border-radius:24px;padding:20px;overflow:auto;box-shadow:0 24px 48px rgba(0,0,0,0.12);z-index:20}
.side h2{margin:0 0 12px;font-size:28px}
.field{margin-bottom:12px}.field label{font-size:11px;letter-spacing:.08em;text-transform:uppercase;color:#8a7a6e;display:block;margin-bottom:4px}
.field input,.field textarea,.field select{width:100%;border:1px solid var(--line);border-radius:12px;padding:10px 12px;font:inherit;background:var(--paper)}
.toolbar{position:fixed;left:20px;bottom:20px;display:flex;gap:8px;background:var(--card);border:1px solid var(--line);border-radius:999px;padding:8px;box-shadow:0 8px 24px rgba(0,0,0,0.1);z-index:15}
.filters{position:fixed;left:50%;bottom:20px;transform:translateX(-50%);display:flex;gap:6px;background:var(--ink);border-radius:999px;padding:6px;z-index:15}
.filters button{border:0;background:transparent;color:var(--paper2);padding:8px 16px;border-radius:999px;cursor:pointer;font-size:13px}
.filters button.active{background:var(--card);color:var(--ink)}
@media(max-width:800px){.side{left:10px;right:10px;width:auto;top:auto;bottom:80px;max-height:58vh;border-radius:28px 28px 0 0}.toolbar{bottom:90px}.header{padding:10px 14px}}
svg.lines{position:absolute;left:0;top:0;width:100%;height:100%;pointer-events:none;overflow:visible}
</style>
</head>
<body>
<div class="header">
<div class="logo"><div class="logo-icon">J</div><div><h1 style="margin:0;font-size:22px;line-height:1">Sugupuu</h1><div style="font-size:12px;color:#8a7a6e">jaanike-ops / sugupuu</div></div></div>
<div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap">
<div class="search"><span>🔍</span><input id="q" placeholder="Otsi nime..."></div>
<button class="btn" onclick="exportJSON()">Ekspordi</button>
<button class="btn" onclick="document.getElementById('importFile').click()">Impordi</button>
<input id="importFile" type="file" hidden accept=".json" onchange="importJSON(event)">
<button class="btn primary" onclick="openNew()">+ Lisa isik</button>
</div>
</div>
<div class="canvas-wrap" id="wrap">
<div class="canvas" id="canvas">
<svg class="lines" id="lines"></svg>
<div class="tree" id="tree"></div>
</div>
</div>
<div class="toolbar">
<button class="btn" onclick="zoom(0.15)">+</button>
<button class="btn" onclick="zoom(-0.15)">-</button>
<button class="btn" onclick="resetView()">Keskenda</button>
</div>
<div class="filters"><button class="active" onclick="setFilter('all',this)">Kõik</button><button onclick="setFilter('3gen',this)">3 põlvkonda</button><button onclick="setFilter('my',this)">Minu liin</button></div>
<div class="side" id="side" style="display:none"></div>
<script>
const LS='sugupuu_v2';
let persons=[
{id:'p1',nimi:'Jaan Tamm',sugu:'M',synd:'1920-05-12',koht:'Viljandi',surm:'1998-02-03',lugu:'Põllumees ja külavanem. Armastas lõõtspilli.',vanemad:[],partner:['p2']},
{id:'p2',nimi:'Leida Tamm',sugu:'N',synd:'1923-08-04',koht:'Suure-Jaani',surm:'2005-11-19',lugu:'Õpetaja, hoidis pere koos.',vanemad:[],partner:['p1']},
{id:'p3',nimi:'Tiit Tamm',sugu:'M',synd:'1948-03-21',koht:'Viljandi',lugu:'Insener. Ehitas ise maja.',vanemad:['p1','p2'],partner:['p4']},
{id:'p4',nimi:'Sirje Tamm',sugu:'N',synd:'1950-09-11',koht:'Tart
