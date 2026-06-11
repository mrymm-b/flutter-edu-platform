/* screens-home.jsx — Home (A·Quiet, B·Structured) + shared bits */

function Thumb({label='غلاف', w, h, r=12, style}){
  return (
    <div style={{width:w, height:h, borderRadius:r, flexShrink:0,
      background:'repeating-linear-gradient(135deg,var(--thumb-a) 0 9px,var(--thumb-b) 9px 18px)',
      border:'1px solid var(--line)', display:'flex', alignItems:'center', justifyContent:'center',
      color:'var(--faint)', fontSize:9, fontFamily:'ui-monospace,monospace', ...style}}>{label}</div>
  );
}
function Progress({pct=0, track='var(--line)', fill='var(--blue-600)'}){
  return (
    <div style={{height:6, borderRadius:99, background:track, overflow:'hidden'}}>
      <div style={{width:Math.max(pct,3)+'%', height:'100%', borderRadius:99, background:fill}}></div>
    </div>
  );
}
function Avatar({size=42, txt='س', tone='blue'}){
  return <div className="avatar" style={{width:size, height:size, fontSize:size*0.4}}>{txt}</div>;
}

/* greeting header — no full-bleed color block */
function Greeting(){
  return (
    <div style={{display:'flex', alignItems:'center', gap:12, padding:'8px 0 16px'}}>
      <Avatar size={44} txt="س"/>
      <div style={{flex:1, minWidth:0}}>
        <div style={{fontSize:12.5, color:'var(--muted)'}}>مرحباً،</div>
        <div style={{fontSize:17, fontWeight:700, letterSpacing:'-.2px'}}>سارة الطالبة</div>
      </div>
      <div style={{display:'flex', gap:8}}>
        <button className="icon-btn" style={iconBtn}><Icon n="bell" s={20} style={{color:'var(--ink-2)'}}/></button>
        <button className="icon-btn" style={{...iconBtn, position:'relative'}}>
          <Icon n="cart" s={20} style={{color:'var(--ink-2)'}}/>
          <span style={cartDot}>4</span>
        </button>
      </div>
    </div>
  );
}
const iconBtnLocal=null;
function SearchField({bg='var(--card)'}){
  return (
    <div className="searchfield" style={{display:'flex', alignItems:'center', gap:10, height:50, borderRadius:15, border:'1px solid var(--line)', background:bg, padding:'0 14px'}}>
      <Icon n="search" s={19} style={{color:'var(--faint)'}}/>
      <span style={{flex:1, fontSize:14, color:'var(--faint)'}}>ابحث عن دورة أو ملزمة…</span>
    </div>
  );
}

/* ---------------- HOME A · Quiet ---------------- */
function HomeA(){
  const cats=[
    {n:'live', t:'دورات أونلاين', s:'شروحات مباشرة وتسجيلات'},
    {n:'doc', t:'الملازم', s:'ملازم PDF للتحميل'},
    {n:'person', t:'دروس خصوصية', s:'أونلاين · حضوري'},
    {n:'bookmark', t:'مراجعات', s:'قريباً', soon:true},
  ];
  return (
    <div className="ph">
      <StatusBar time="8:16"/>
      <div className="body" style={{paddingTop:4}}>
        <Greeting/>
        <SearchField bg="var(--bg-2)"/>

        {/* today */}
        <div style={{display:'flex', alignItems:'center', justifyContent:'space-between', margin:'26px 0 12px'}}>
          <span className="sec-label">جدول اليوم</span>
          <span style={{fontSize:12, color:'var(--muted)'}}>الأحد</span>
        </div>
        <div style={{border:'1px dashed var(--line)', borderRadius:14, padding:'22px 16px', textAlign:'center'}}>
          <div style={{fontSize:13, color:'var(--muted)'}}>لا توجد حصص مدرسية اليوم</div>
        </div>

        {/* continue — light hero */}
        <div style={{margin:'26px 0 12px'}}><span className="sec-label">أكمل تعلّمك</span></div>
        <div className="card" style={{padding:14}}>
          <div style={{display:'flex', gap:13}}>
            <Thumb label="رياضيات" w={62} h={62} r={14}/>
            <div style={{flex:1, minWidth:0}}>
              <div style={{fontSize:14.5, fontWeight:600}}>رياضيات الصف الحادي عشر</div>
              <div style={{fontSize:12, color:'var(--muted)', marginTop:2}}>أ. محمد المعلم</div>
            </div>
          </div>
          <div style={{marginTop:14}}>
            <Progress pct={6}/>
            <div style={{display:'flex', justifyContent:'space-between', marginTop:7}}>
              <span style={{fontSize:11.5, color:'var(--muted)'}}>دورة واحدة غير مكتملة</span>
              <span style={{fontSize:11.5, color:'var(--blue-600)', fontWeight:600}}>6% مكتمل</span>
            </div>
          </div>
          <button className="btn btn-primary btn-sm" style={{marginTop:14}}>
            <Icon n="play" s={15} fill/> متابعة
          </button>
        </div>

        {/* categories — quiet list */}
        <div style={{margin:'26px 0 8px'}}><span className="sec-label">استكشف</span></div>
        <div className="card" style={{overflow:'hidden'}}>
          {cats.map((c,i)=>(
            <div key={c.t}>
              {i>0 && <div className="hr" style={{marginInline:16}}></div>}
              <div className="row-card">
                <div className="row-ic"><Icon n={c.n} s={20}/></div>
                <div className="row-main">
                  <div className="t">{c.t}</div>
                  <div className="s">{c.s}</div>
                </div>
                {c.soon
                  ? <span className="badge badge-soft">قريباً</span>
                  : <Icon n="chevL" s={18} className="chev" style={{color:'var(--faint)'}}/>}
              </div>
            </div>
          ))}
        </div>
      </div>
      <BottomNav active="home"/>
    </div>
  );
}

/* ---------------- HOME B · Structured ---------------- */
function HomeB(){
  const cats=[
    {n:'live', t:'دورات أونلاين', s:'مباشر + تسجيلات'},
    {n:'doc', t:'الملازم', s:'PDF للتحميل'},
    {n:'person', t:'دروس خصوصية', s:'أونلاين · حضوري'},
    {n:'bookmark', t:'مراجعات', s:'قريباً', soon:true},
  ];
  return (
    <div className="ph">
      <StatusBar time="8:16"/>
      <div className="body" style={{paddingTop:4, paddingLeft:16, paddingRight:16}}>
        <Greeting/>
        <SearchField/>

        <div style={{display:'flex', alignItems:'center', justifyContent:'space-between', margin:'24px 0 11px'}}>
          <span className="sec-label">جدول اليوم</span>
          <span className="badge badge-blue">الأحد</span>
        </div>
        <div className="card" style={{padding:'20px 16px', textAlign:'center'}}>
          <div style={{fontSize:13, color:'var(--muted)'}}>لا توجد حصص مدرسية اليوم</div>
        </div>

        {/* continue — single retained dark focal card, refined */}
        <div style={{margin:'24px 0 11px'}}><span className="sec-label">أكمل تعلّمك</span></div>
        <div style={{background:'var(--slate)', borderRadius:18, padding:16, color:'#fff'}}>
          <div style={{display:'flex', alignItems:'center', gap:13}}>
            <div style={{flex:1, minWidth:0}}>
              <div style={{fontSize:11, color:'rgba(255,255,255,.55)', marginBottom:4}}>رياضيات</div>
              <div style={{fontSize:15.5, fontWeight:700}}>الصف الحادي عشر</div>
              <div style={{fontSize:12, color:'rgba(255,255,255,.6)', marginTop:3}}>أ. محمد المعلم</div>
            </div>
            <div style={{width:46, height:46, borderRadius:14, background:'rgba(255,255,255,.12)', display:'flex', alignItems:'center', justifyContent:'center'}}>
              <Icon n="play" s={20} fill style={{color:'#fff'}}/>
            </div>
          </div>
          <div style={{marginTop:15}}>
            <Progress pct={6} track="rgba(255,255,255,.14)" fill="#fff"/>
            <div style={{display:'flex', justifyContent:'space-between', marginTop:8}}>
              <span style={{fontSize:11.5, color:'rgba(255,255,255,.65)'}}>6% مكتمل</span>
              <span style={{fontSize:11.5, color:'rgba(255,255,255,.65)'}}>دورة غير مكتملة</span>
            </div>
          </div>
          <button className="btn btn-sm" style={{marginTop:14, background:'#fff', color:'var(--slate)'}}>
            <Icon n="play" s={14} fill/> متابعة
          </button>
        </div>

        {/* categories grid */}
        <div style={{margin:'24px 0 11px'}}><span className="sec-label">استكشف</span></div>
        <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:11}}>
          {cats.map(c=>(
            <div key={c.t} className="card" style={{padding:14, opacity:c.soon?.7:1}}>
              <div className="row-ic" style={{marginBottom:12}}><Icon n={c.n} s={20}/></div>
              <div style={{fontSize:13.5, fontWeight:600}}>{c.t}</div>
              <div style={{fontSize:11.5, color:'var(--muted)', marginTop:3}}>{c.s}</div>
            </div>
          ))}
        </div>
      </div>
      <BottomNav active="home"/>
    </div>
  );
}

Object.assign(window, { Thumb, Progress, Avatar, Greeting, SearchField, HomeA, HomeB });
