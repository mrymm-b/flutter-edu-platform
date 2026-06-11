/* screens-courses-content.jsx — Online Courses + My Content (A·Quiet, B·Structured) */

function AppBar({title, sub, cart=false, tone='light'}){
  const onDark = tone==='dark';
  const col = onDark? '#fff':'var(--ink)';
  return (
    <div style={{display:'flex', alignItems:'center', gap:12, padding:'8px 0 14px'}}>
      <button style={{...iconBtn, background:'transparent', border:'1px solid var(--line)'}}>
        <Icon n="chevR" s={20} style={{color:'var(--ink-2)'}}/>
      </button>
      <div style={{flex:1, minWidth:0}}>
        <div style={{fontSize:18, fontWeight:700, color:col, letterSpacing:'-.2px'}}>{title}</div>
        {sub && <div style={{fontSize:12, color:'var(--muted)', marginTop:1}}>{sub}</div>}
      </div>
      {cart && (
        <button style={{...iconBtn, position:'relative'}}>
          <Icon n="cart" s={20} style={{color:'var(--ink-2)'}}/>
          <span style={cartDot}>4</span>
        </button>
      )}
    </div>
  );
}

function CourseCard({title, sub, students, price, isNew, inCart}){
  return (
    <div className="card" style={{padding:14}}>
      <div style={{display:'flex', gap:13}}>
        <Thumb label="غلاف" w={58} h={58} r={14}/>
        <div style={{flex:1, minWidth:0}}>
          <div style={{display:'flex', justifyContent:'space-between', gap:10}}>
            <div style={{minWidth:0}}>
              <div style={{fontSize:14.5, fontWeight:600}}>{title}</div>
              <div style={{fontSize:12, color:'var(--muted)', marginTop:2}}>{sub}</div>
            </div>
            <div style={{textAlign:'center', flexShrink:0}}>
              <div style={{fontSize:19, fontWeight:700, lineHeight:1, color:'var(--blue-700)'}}>{price}</div>
              <div style={{fontSize:9.5, color:'var(--muted)', marginTop:2}}>د.ب</div>
            </div>
          </div>
          <div style={{display:'flex', alignItems:'center', gap:6, marginTop:9}}>
            <Icon n="users" s={14} style={{color:'var(--faint)'}}/>
            <span style={{fontSize:11.5, color:'var(--muted)'}}>{students}</span>
            {isNew && <span className="badge badge-blue" style={{marginInlineStart:4}}>جديد</span>}
          </div>
        </div>
      </div>
      <div style={{display:'flex', gap:10, marginTop:13}}>
        {inCart
          ? <button className="btn btn-sm btn-tonal" style={{flex:1}}><Icon n="check" s={15}/> في السلة</button>
          : <button className="btn btn-sm btn-primary" style={{flex:1}}>أضف للسلة</button>}
        <button className="btn btn-sm btn-ghost" style={{flex:1}}>التفاصيل</button>
      </div>
    </div>
  );
}

/* ---------------- COURSES A · Quiet ---------------- */
function CoursesA(){
  return (
    <div className="ph is-scroll">
      <StatusBar time="8:17"/>
      <div style={{padding:'4px 18px 22px'}}>
        <AppBar title="الدورات الأونلاين" sub="شروحات مباشرة + تسجيلات" cart/>
        <div className="chips" style={{margin:'4px 0 18px'}}>
          <div className="chip active">الكل</div>
          <div className="chip">الفيزياء</div>
          <div className="chip">الرياضيات</div>
        </div>
        <div style={{display:'flex', flexDirection:'column', gap:12}}>
          <CourseCard title="رياضيات الصف الحادي عشر" sub="جبر وهندسة" students="٢ طلاب" price="15" inCart/>
          <CourseCard title="فيزياء متقدمة" sub="موجات وكهرباء" students="جديد" price="20" isNew/>
        </div>
      </div>
    </div>
  );
}

/* ---------------- COURSES B · Structured ---------------- */
function CoursesB(){
  return (
    <div className="ph is-scroll">
      <StatusBar time="8:17"/>
      <div style={{padding:'4px 16px 22px'}}>
        <AppBar title="الدورات الأونلاين" sub="شروحات مباشرة + تسجيلات" cart/>
        <div style={{display:'flex', background:'var(--card)', border:'1px solid var(--line)', borderRadius:13, padding:4, gap:4, marginBottom:16}}>
          {['الكل','الفيزياء','الرياضيات'].map((t,i)=>(
            <div key={t} style={{flex:1, textAlign:'center', height:34, lineHeight:'34px', fontSize:13, fontWeight:i===0?600:500,
              borderRadius:10, background:i===0?'var(--blue-700)':'transparent', color:i===0?'#fff':'var(--ink-2)'}}>{t}</div>
          ))}
        </div>
        <div style={{display:'flex', flexDirection:'column', gap:12}}>
          <CourseCard title="رياضيات الصف الحادي عشر" sub="جبر وهندسة" students="٢ طلاب" price="15" inCart/>
          <CourseCard title="فيزياء متقدمة" sub="موجات وكهرباء" students="جديد" price="20" isNew/>
        </div>
      </div>
    </div>
  );
}

/* ---------------- MY CONTENT ---------------- */
function ContentCourseCard(){
  return (
    <div className="card" style={{padding:14}}>
      <div style={{display:'flex', gap:13}}>
        <Thumb label="رياضيات" w={58} h={58} r={14}/>
        <div style={{flex:1, minWidth:0}}>
          <div style={{display:'flex', alignItems:'center', gap:7}}>
            <span className="badge badge-blue">دورة أونلاين</span>
            <span style={{fontSize:11, color:'var(--blue-600)', display:'flex', alignItems:'center', gap:4}}>
              <span style={{width:6, height:6, borderRadius:'50%', background:'var(--blue-600)'}}></span>متابعة
            </span>
          </div>
          <div style={{fontSize:14.5, fontWeight:600, marginTop:8}}>رياضيات الصف الحادي عشر</div>
          <div style={{fontSize:12, color:'var(--muted)', marginTop:2}}>أ. محمد المعلم</div>
        </div>
      </div>
      <div style={{display:'flex', gap:10, marginTop:14}}>
        <button className="btn btn-sm btn-primary" style={{flex:1}}><Icon n="play" s={14} fill/> التسجيلات</button>
        <button className="btn btn-sm btn-ghost" style={{flex:1}}><Icon n="live" s={15}/> بث مباشر</button>
      </div>
    </div>
  );
}
function ContentTabs({variant}){
  if(variant==='seg'){
    return (
      <div style={{display:'flex', background:'var(--card)', border:'1px solid var(--line)', borderRadius:13, padding:4, gap:4, marginBottom:16}}>
        <div style={{flex:1, textAlign:'center', height:36, lineHeight:'36px', fontSize:13.5, fontWeight:600, borderRadius:10, background:'var(--blue-700)', color:'#fff'}}>دوراتي</div>
        <div style={{flex:1, textAlign:'center', height:36, lineHeight:'36px', fontSize:13.5, fontWeight:500, color:'var(--ink-2)'}}>ملازمي</div>
      </div>
    );
  }
  return (
    <div style={{display:'flex', gap:26, borderBottom:'1px solid var(--line)', marginBottom:18}}>
      <div style={{paddingBottom:12, fontSize:14.5, fontWeight:600, color:'var(--blue-700)', borderBottom:'2px solid var(--blue-700)', marginBottom:-1}}>دوراتي</div>
      <div style={{paddingBottom:12, fontSize:14.5, fontWeight:500, color:'var(--muted)'}}>ملازمي</div>
    </div>
  );
}
function ContentA(){
  return (
    <div className="ph">
      <StatusBar time="8:17"/>
      <div className="body" style={{paddingTop:4}}>
        <div style={{padding:'8px 0 16px'}}>
          <div style={{fontSize:22, fontWeight:700, letterSpacing:'-.3px'}}>محتواي</div>
          <div className="h-sub">دوراتك وملازمك في مكان واحد</div>
        </div>
        <ContentTabs variant="seg"/>
        <ContentCourseCard/>
      </div>
      <BottomNav active="content"/>
    </div>
  );
}
function ContentB(){
  return (
    <div className="ph">
      <StatusBar time="8:17"/>
      <div className="body" style={{paddingTop:4, paddingLeft:16, paddingRight:16}}>
        <div style={{padding:'8px 0 16px'}}>
          <div style={{fontSize:22, fontWeight:700, letterSpacing:'-.3px'}}>محتواي</div>
          <div className="h-sub">دوراتك وملازمك في مكان واحد</div>
        </div>
        <ContentTabs variant="seg"/>
        <ContentCourseCard/>
      </div>
      <BottomNav active="content"/>
    </div>
  );
}

Object.assign(window, { AppBar, CourseCard, CoursesA, CoursesB, ContentA, ContentB });
