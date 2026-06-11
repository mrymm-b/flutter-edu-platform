/* screens-schedule-profile.jsx — Schedule + Profile (A·Quiet, B·Structured) */

/* ---------------- SCHEDULE ---------------- */
const DAYS=['الأحد','الاثنين','الثلاثاء','الأربعاء','الخميس'];

function TimeGrid({events=[]}){
  const HOURH=54, start=7, end=16;
  const hours=[]; for(let h=start;h<=end;h++) hours.push(h);
  return (
    <div style={{position:'relative', padding:'6px 0'}}>
      {hours.map(h=>(
        <div key={h} style={{position:'relative', height:HOURH}}>
          <span style={{position:'absolute', insetInlineStart:0, top:-7, fontSize:11, color:'var(--faint)', fontVariantNumeric:'tabular-nums', direction:'ltr'}}>{String(h).padStart(2,'0')}:00</span>
          <div style={{position:'absolute', insetInlineStart:48, insetInlineEnd:0, top:0, borderTop:'1px solid var(--line-2)'}}></div>
        </div>
      ))}
      {events.map((e,i)=>(
        <div key={i} style={{position:'absolute', insetInlineStart:48, insetInlineEnd:0, top:(e.start-start)*HOURH+3, height:e.dur*HOURH-7,
          background:'var(--accent-tint)', borderInlineStart:'3px solid var(--accent)', borderRadius:12, padding:'9px 12px'}}>
          <div style={{fontSize:12.5, fontWeight:600, color:'var(--accent-fg)'}}>{e.title}</div>
          <div style={{fontSize:11, color:'var(--muted)', marginTop:2}}>{e.sub}</div>
        </div>
      ))}
    </div>
  );
}
function Fab(){
  return (
    <button className="fab" style={{position:'absolute', bottom:82, insetInlineStart:18, height:48, padding:'0 18px', borderRadius:15,
      background:'var(--blue-700)', color:'#fff', border:'none', display:'flex', alignItems:'center', gap:8,
      fontFamily:'inherit', fontSize:13.5, fontWeight:600, boxShadow:'var(--shadow-float)', cursor:'pointer'}}>
      <Icon n="plus" s={18}/> إضافة مواد
    </button>
  );
}
function ScheduleHead(){
  return (
    <div style={{display:'flex', alignItems:'center', gap:12, padding:'8px 0 14px'}}>
      <div style={{flex:1, fontSize:18, fontWeight:700, letterSpacing:'-.2px'}}>جدولي الدراسي</div>
      <button style={{...iconBtn, background:'transparent'}}><Icon n="trash" s={19} style={{color:'var(--muted)'}}/></button>
    </div>
  );
}
function ScheduleA(){
  return (
    <div className="ph" style={{position:'relative'}}>
      <StatusBar time="8:18"/>
      <div style={{padding:'4px 18px 0', flex:'0 0 auto'}}>
        <ScheduleHead/>
        <div style={{display:'flex', gap:6, marginBottom:6}}>
          {DAYS.map((d,i)=>(
            <div key={d} className={'chip'+(i===0?' active':'')} style={{flex:1, minWidth:0, height:32, padding:0, justifyContent:'center', fontSize:12}}>{d}</div>
          ))}
        </div>
      </div>
      <div className="body" style={{paddingTop:6}}>
        <TimeGrid events={[{start:9,dur:1,title:'رياضيات',sub:'أ. محمد المعلم'},{start:13,dur:1.5,title:'فيزياء',sub:'موجات وكهرباء'}]}/>
      </div>
      <Fab/>
      <BottomNav active="schedule"/>
    </div>
  );
}
function ScheduleB(){
  return (
    <div className="ph" style={{position:'relative'}}>
      <StatusBar time="8:18"/>
      <div style={{padding:'4px 16px 0', flex:'0 0 auto'}}>
        <ScheduleHead/>
        <div style={{display:'flex', gap:8, marginBottom:8}}>
          {DAYS.map((d,i)=>(
            <div key={d} className="card" style={{flex:1, textAlign:'center', padding:'10px 0',
              background:i===0?'var(--blue-700)':'var(--card)', border:i===0?'1px solid var(--blue-700)':'1px solid var(--line)'}}>
              <div style={{fontSize:11.5, fontWeight:600, color:i===0?'#fff':'var(--ink-2)'}}>{d.replace('ال','')}</div>
              <div style={{width:5, height:5, borderRadius:'50%', margin:'6px auto 0', background:i===0?'#fff':'var(--line)'}}></div>
            </div>
          ))}
        </div>
      </div>
      <div className="body" style={{paddingTop:6}}>
        <div className="card" style={{padding:'4px 14px'}}>
          <TimeGrid events={[{start:9,dur:1,title:'رياضيات',sub:'أ. محمد المعلم'},{start:13,dur:1.5,title:'فيزياء',sub:'موجات وكهرباء'}]}/>
        </div>
      </div>
      <Fab/>
      <BottomNav active="schedule"/>
    </div>
  );
}

/* ---------------- PROFILE ---------------- */
function ProfileRows({rows}){
  return (
    <div className="card" style={{overflow:'hidden'}}>
      {rows.map((r,i)=>(
        <div key={r.t}>
          {i>0 && <div className="hr" style={{marginInline:16}}></div>}
          <div className="row-card">
            <div className="row-ic"><Icon n={r.n} s={19}/></div>
            <div className="row-main"><div className="t">{r.t}</div></div>
            <Icon n="chevL" s={18} style={{color:'var(--faint)'}}/>
          </div>
        </div>
      ))}
    </div>
  );
}
const ACCT=[{n:'pencil',t:'تعديل الملف الشخصي'},{n:'bag',t:'دوراتي ومشترياتي'},{n:'palette',t:'مظهر التطبيق'}];
const SUPP=[{n:'help',t:'المساعدة والدعم'}];

function ProfileA(){
  return (
    <div className="ph">
      <StatusBar time="8:18"/>
      <div className="body" style={{paddingTop:14}}>
        <div style={{display:'flex', flexDirection:'column', alignItems:'center', gap:12, padding:'10px 0 24px'}}>
          <div className="avatar" style={{width:86, height:86, fontSize:30}}>سا</div>
          <div style={{textAlign:'center'}}>
            <div style={{fontSize:20, fontWeight:700}}>سارة الطالبة</div>
            <div style={{display:'flex', alignItems:'center', gap:8, justifyContent:'center', marginTop:8}}>
              <span className="badge badge-blue">الصف الحادي عشر</span>
              <span style={{fontSize:12.5, color:'var(--muted)', direction:'ltr'}}>+973 3310 0001</span>
            </div>
          </div>
        </div>
        <div className="sec-label muted" style={{marginBottom:10}}>الحساب</div>
        <ProfileRows rows={ACCT}/>
        <div className="sec-label muted" style={{margin:'22px 0 10px'}}>الدعم</div>
        <ProfileRows rows={SUPP}/>
        <button className="btn btn-ghost btn-sm" style={{marginTop:20, color:'var(--muted)'}}>تسجيل الخروج</button>
      </div>
      <BottomNav active="account"/>
    </div>
  );
}
function ProfileB(){
  return (
    <div className="ph">
      <StatusBar time="8:18"/>
      <div className="body" style={{paddingTop:14, paddingLeft:16, paddingRight:16}}>
        <div className="card" style={{padding:16, display:'flex', alignItems:'center', gap:14}}>
          <div className="avatar" style={{width:62, height:62, fontSize:22}}>سا</div>
          <div style={{flex:1, minWidth:0}}>
            <div style={{fontSize:17, fontWeight:700}}>سارة الطالبة</div>
            <div style={{fontSize:12.5, color:'var(--muted)', marginTop:3, direction:'ltr', textAlign:'right'}}>+973 3310 0001</div>
            <span className="badge badge-blue" style={{marginTop:8}}>الصف الحادي عشر</span>
          </div>
          <button style={{...iconBtn, flexShrink:0}}><Icon n="pencil" s={18} style={{color:'var(--blue-600)'}}/></button>
        </div>
        <div className="sec-label muted" style={{margin:'22px 0 10px'}}>الحساب</div>
        <ProfileRows rows={ACCT}/>
        <div className="sec-label muted" style={{margin:'22px 0 10px'}}>الدعم</div>
        <ProfileRows rows={SUPP}/>
        <button className="btn btn-ghost btn-sm" style={{marginTop:20, color:'var(--muted)'}}>تسجيل الخروج</button>
      </div>
      <BottomNav active="account"/>
    </div>
  );
}

Object.assign(window, { ScheduleA, ScheduleB, ProfileA, ProfileB });
