/* shared.jsx — icons, status bar, bottom nav, phone helpers (window-exported) */

const I = {
  search:'M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14ZM20 20l-3.2-3.2',
  bell:'M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6M9.5 20a2.5 2.5 0 0 0 5 0',
  cart:'M3 4h2l2.2 11.2a1.5 1.5 0 0 0 1.5 1.2h8.2a1.5 1.5 0 0 0 1.45-1.1L21 8H6M9 20a1 1 0 1 0 .001 0M17 20a1 1 0 1 0 .001 0',
  play:'M8 5.5v13l11-6.5-11-6.5Z',
  chevL:'M14 6l-6 6 6 6',
  chevR:'M10 6l6 6-6 6',
  doc:'M7 3h7l5 5v13H7zM14 3v5h5',
  person:'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM5 20a7 7 0 0 1 14 0',
  calendar:'M5 5h14v15H5zM5 9h14M9 3v3M15 3v3',
  bookmark:'M7 4h10v16l-5-3.5L7 20z',
  chat:'M5 5h14v10H9l-4 4z',
  home:'M4 11l8-7 8 7M6 10v9h12v-9',
  pencil:'M5 19l1-4L17 4l3 3L9 18z',
  bag:'M6 8h12l-1 12H7zM9 8a3 3 0 0 1 6 0',
  palette:'M12 3a9 9 0 1 0 0 18c1.5 0 2-1 2-2s-1-1-1-2 1-1 2-1h1a3 3 0 0 0 3-3 7 7 0 0 0-7-7ZM7.5 12a1 1 0 1 0 .01 0M10 8a1 1 0 1 0 .01 0M15 8a1 1 0 1 0 .01 0',
  help:'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18ZM9.5 9a2.5 2.5 0 0 1 4 2c-.5 1-1.5 1.2-1.5 2.5M12 17h.01',
  plus:'M12 5v14M5 12h14',
  trash:'M5 7h14M9 7V5h6v2M7 7l1 13h8l1-13',
  live:'M3 7h13v10H3zM16 10l5-3v10l-5-3',
  users:'M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7ZM3 19a6 6 0 0 1 12 0M17 11a3 3 0 0 0 0-6M16 19a6 6 0 0 0-1.5-4',
  check:'M5 12.5l4.5 4.5L19 7',
  download:'M12 4v10m0 0l-4-4m4 4l4-4M5 19h14',
  clock:'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18ZM12 7v5l3 2',
  filter:'M4 6h16M7 12h10M10 18h4',
  star:'M12 4l2.3 4.7 5.2.7-3.8 3.6.9 5.1-4.6-2.4-4.6 2.4.9-5.1L4.5 9.4l5.2-.7z',
};
function Icon({n, s=22, w=1.7, fill=false, style}){
  return (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={fill?'currentColor':'none'}
      stroke={fill?'none':'currentColor'} strokeWidth={w} strokeLinecap="round"
      strokeLinejoin="round" style={style}>
      <path d={I[n]} />
    </svg>
  );
}

/* status bar */
function StatusBar({time='8:16', tone}){
  const cls = 'sb' + (tone? ' on-'+tone : '');
  const col = tone? '#fff' : 'var(--ink)';
  return (
    <div className={cls}>
      <div className="sb-time">{time}</div>
      <div className="sb-ic" style={{color:col}}>
        <svg width="16" height="11" viewBox="0 0 16 11" fill="currentColor"><path d="M8 1.5c2.2 0 4.2.8 5.7 2.2l-1 1A6.6 6.6 0 0 0 8 2.8 6.6 6.6 0 0 0 3.3 4.7l-1-1A8.1 8.1 0 0 1 8 1.5Zm0 3c1.4 0 2.6.5 3.5 1.4l-1 1A4 4 0 0 0 8 5.7a4 4 0 0 0-2.5.9l-1-1A4.9 4.9 0 0 1 8 4.5Zm0 3c.6 0 1.1.2 1.5.6L8 9.5 6.5 8c.4-.3.9-.5 1.5-.5Z"/></svg>
        <svg width="17" height="11" viewBox="0 0 17 11" fill="currentColor"><rect x="0" y="7" width="3" height="4" rx=".6"/><rect x="4.5" y="5" width="3" height="6" rx=".6"/><rect x="9" y="2.5" width="3" height="8.5" rx=".6"/><rect x="13.5" y="0" width="3" height="11" rx=".6" opacity=".35"/></svg>
        <svg width="22" height="11" viewBox="0 0 22 11" fill="none" stroke="currentColor"><rect x="1" y="1" width="17" height="9" rx="2.2" strokeWidth="1.1"/><rect x="3" y="3" width="12" height="5" rx="1" fill="currentColor" stroke="none"/><rect x="19" y="3.5" width="1.6" height="4" rx=".8" fill="currentColor" stroke="none"/></svg>
      </div>
    </div>
  );
}

/* bottom nav (active: 'home'|'schedule'|'content'|'messages'|'account') */
function BottomNav({active='home'}){
  const items=[
    {k:'account', n:'person', label:'حسابي'},
    {k:'schedule', n:'calendar', label:'جدولي'},
    {k:'content', n:'bookmark', label:'دوراتي'},
    {k:'messages', n:'chat', label:'الرسائل'},
    {k:'home', n:'home', label:'الرئيسية'},
  ];
  return (
    <div className="botnav">
      {items.map(it=>{
        const on = it.k===active;
        return (
          <div key={it.k} className={'nav-item'+(on?' active':'')}>
            <div className="nav-ic"><Icon n={it.n} s={22} w={on?2:1.7} fill={on}/></div>
            <span>{it.label}</span>
          </div>
        );
      })}
    </div>
  );
}

/* shared inline-style atoms used across screen files */
const iconBtn={width:42, height:42, borderRadius:13, border:'1px solid var(--line)', background:'var(--card)', display:'flex', alignItems:'center', justifyContent:'center', cursor:'pointer'};
const cartDot={position:'absolute', top:-5, insetInlineStart:-5, minWidth:18, height:18, padding:'0 4px', borderRadius:9, background:'var(--blue-700)', color:'#fff', fontSize:10.5, fontWeight:700, display:'flex', alignItems:'center', justifyContent:'center', border:'2px solid var(--bg)'};

Object.assign(window, { Icon, StatusBar, BottomNav, iconBtn, cartDot });
