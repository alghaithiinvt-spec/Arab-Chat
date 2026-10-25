/* backend.js — طبقة بيانات محلية تحاكي Firebase Firestore.
   تحفظ البيانات في localStorage وتزامنها بين التبويبات (كل تبويب = مستخدم مختلف).
   لربط التطبيق بخادم حقيقي: استبدل هذا الملف بنسخة تعيد نفس الدوال (انظر README). */
(function () {
  const KEY = "ac_db", BOT = "bot_sara";
  const uid = sessionStorage.ac_uid || (sessionStorage.ac_uid = "u" + Math.random().toString(36).slice(2, 9));
  const bc = new BroadcastChannel("ac"), subs = new Set();
  const load = () => JSON.parse(localStorage.getItem(KEY) || "{}");
  const fire = () => subs.forEach(f => f());
  const save = d => { localStorage.setItem(KEY, JSON.stringify(d)); bc.postMessage(1); fire(); };
  bc.onmessage = fire;
  addEventListener("storage", e => { if (e.key === KEY) fire(); });
  const parent = p => p.slice(0, p.lastIndexOf("/"));
  const snapD = (p, d) => ({ id: p.split("/").pop(), exists: d !== undefined, data: () => d === undefined ? undefined : JSON.parse(JSON.stringify(d)), metadata: {} });

  function col(path, q = { w: [], o: null, l: 0 }) {
    const run = () => {
      let r = Object.entries(load()).filter(([k]) => parent(k) === path);
      q.w.forEach(([f, op, v]) => r = r.filter(([, x]) => op === "==" ? x[f] === v : op === "array-contains" ? (x[f] || []).includes(v) : true));
      if (q.o) r.sort((a, b) => (a[1][q.o[0]] > b[1][q.o[0]] ? 1 : -1) * (q.o[1] === "desc" ? -1 : 1));
      return q.l ? r.slice(0, q.l) : r;
    };
    const mk = prev => { const docs = run().map(([k, x]) => snapD(k, x)); return { docs, size: docs.length, empty: !docs.length, metadata: {}, docChanges: () => docs.filter(d => !prev.has(d.id)).map(doc => ({ type: "added", doc })) }; };
    return {
      doc: id => docRef(path + "/" + id),
      where: (f, op, v) => col(path, { ...q, w: [...q.w, [f, op, v]] }),
      orderBy: (f, dir) => col(path, { ...q, o: [f, dir] }),
      limit: n => col(path, { ...q, l: n }),
      get: async () => mk(new Set()),
      onSnapshot(cb) {
        let prev = new Set(), last;
        const f = () => { const j = JSON.stringify(run()); if (j === last) return; last = j; const s = mk(prev); prev = new Set(s.docs.map(d => d.id)); cb(s); };
        subs.add(f); setTimeout(f, 0); return () => subs.delete(f);
      }
    };
  }
  function docRef(path) {
    return {
      id: path.split("/").pop(), path,
      get: async () => snapD(path, load()[path]),
      set: async v => { const d = load(); d[path] = v; save(d); },
      update: async v => { const d = load(); d[path] = { ...(d[path] || {}), ...v }; save(d); },
      delete: async () => { const d = load(); Object.keys(d).forEach(k => { if (k === path || k.startsWith(path + "/")) delete d[k]; }); save(d); },
      collection: p => col(path + "/" + p),
      onSnapshot(cb) {
        let last; const f = () => { const v = load()[path], j = JSON.stringify(v); if (j !== last) { last = j; cb(snapD(path, v)); } };
        subs.add(f); setTimeout(f, 0); return () => subs.delete(f);
      }
    };
  }
  const db = { collection: p => col(p) };
  const user = { id: async () => uid, me: async () => ({ name: "" }), isOwner: () => true, canEdit: () => true };
  window.claude = { use: async n => n === "db" ? db : n === "user" ? user : null };

  /* شريك تجريبي: إذا انتظرت 5 ثوانٍ بلا أحد، يتصل بك "سارة" لتجرب الواجهة وحدك */
  const done = new Set();
  setInterval(() => {
    const d = load(); let ch = false;
    for (const k in d) {
      if (parent(k) === "queue" && Date.now() - d[k].ts > 5000) {
        const u = k.split("/")[1]; if (u === BOT || d["matches/" + u]) continue;
        const id = u + "_" + BOT + "_" + Date.now();
        d["chats/" + id] = { a: u, b: BOT, na: d[k].name, nb: "سارة (تجريبي)", members: [u, BOT], last: "", ts: Date.now() };
        d["matches/" + u] = { chat: id }; delete d[k]; ch = true;
      }
      const m = k.match(/^(chats\/[^/]+)\/msgs\/([^/]+)$/);
      if (m && d[k].from !== BOT && (d[m[1]].members || []).includes(BOT) && !d["botdone/" + m[2]] && !done.has(m[2])) {
        done.add(m[2]); d["botdone/" + m[2]] = { t: 1 }; ch = true;
        const R = ["أهلاً وسهلاً! 😊", "من أي بلد أنت؟", "حلو، وش تحب تسوي في وقت فراغك؟", "ههه صحيح", "تشرفت بمعرفتك!"];
        setTimeout(() => { const x = load(), ts = Date.now(), t = R[Math.floor(Math.random() * R.length)];
          x[m[1] + "/msgs/" + ts + "_bot"] = { from: BOT, text: t, ts }; if (x[m[1]]) { x[m[1]].last = t; x[m[1]].ts = ts; } save(x); }, 1200);
      }
    }
    if (ch) save(d);
  }, 1000);
})();
