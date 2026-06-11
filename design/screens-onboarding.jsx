/* screens-onboarding.jsx — Welcome / Login / Sign-up (A·Quiet, B·Structured) */

function Logo({size=34, sub=true}){
  return (
    <div style={{display:'flex', flexDirection:'column', alignItems:'center', gap:14}}>
      <div style={{display:'flex', alignItems:'baseline', gap:2, lineHeight:1}}>
        <span style={{fontSize:size, fontWeight:700, color:'var(--ink)', letterSpacing:'-.5px'}}>عرب</span>
        <span style={{fontSize:size, fontWeight:700, color:'var(--blue-700)', letterSpacing:'-1px', direction:'ltr'}}>BH</span>
      </div>
      {sub && (
        <div style={{display:'flex', alignItems:'center', gap:10}}>
          <span style={{width:24, height:1, background:'var(--line)'}}></span>
          <span style={{fontSize:12, color:'var(--muted)', fontWeight:500}}>منصة التعليم الشاملة</span>
          <span style={{width:24, height:1, background:'var(--line)'}}></span>
        </div>
      )}
    </div>
  );
}

/* ---------------- WELCOME ---------------- */
function WelcomeA(){
  return (
    <div className="ph">
      <StatusBar time="8:14"/>
      <div style={{flex:1, display:'flex', flexDirection:'column', padding:'0 22px 30px'}}>
        <div style={{flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center'}}>
          <Logo size={36}/>
        </div>
        <div style={{display:'flex', flexDirection:'column', gap:12}}>
          <button className="btn btn-primary">تسجيل الدخول</button>
          <button className="btn btn-ghost">إنشاء حساب</button>
          <p style={{textAlign:'center', fontSize:11.5, color:'var(--faint)', marginTop:4}}>
            بالمتابعة فإنك توافق على الشروط وسياسة الخصوصية
          </p>
        </div>
      </div>
    </div>
  );
}
function WelcomeB(){
  return (
    <div className="ph">
      <StatusBar time="8:14"/>
      <div style={{flex:1, display:'flex', flexDirection:'column', padding:'0 20px 26px'}}>
        <div style={{flex:1, display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:26}}>
          <div className="card" style={{width:96, height:96, borderRadius:26, display:'flex', alignItems:'center', justifyContent:'center'}}>
            <div style={{display:'flex', alignItems:'baseline', gap:1}}>
              <span style={{fontSize:24, fontWeight:700, color:'var(--ink)'}}>عرب</span>
              <span style={{fontSize:24, fontWeight:700, color:'var(--blue-700)', direction:'ltr'}}>BH</span>
            </div>
          </div>
          <div style={{textAlign:'center'}}>
            <div style={{fontSize:23, fontWeight:700, letterSpacing:'-.3px'}}>منصة التعليم الشاملة</div>
            <div style={{fontSize:13.5, color:'var(--muted)', marginTop:8, lineHeight:1.6, maxWidth:230}}>
              دوراتك، ملازمك، وجدولك الدراسي في مكان واحد هادئ ومنظّم.
            </div>
          </div>
        </div>
        <div className="card" style={{padding:16, display:'flex', flexDirection:'column', gap:10}}>
          <button className="btn btn-primary">تسجيل الدخول</button>
          <button className="btn btn-ghost">إنشاء حساب</button>
        </div>
      </div>
    </div>
  );
}

/* ---------------- LOGIN ---------------- */
function LoginForm(){
  return (
    <>
      <div className="field-label">رقم الهاتف</div>
      <div className="phone-row">
        <div className="input"><span className="ph-text">3312 3456</span></div>
        <div className="input cc">+973</div>
      </div>
      <div style={{height:20}}></div>
      <button className="btn btn-primary">دخول</button>
      <p style={{textAlign:'center', fontSize:13, color:'var(--muted)', marginTop:18}}>
        ليس لديك حساب؟ <span style={{color:'var(--blue-700)', fontWeight:600}}>سجّل الآن</span>
      </p>
    </>
  );
}
function LoginA(){
  return (
    <div className="ph">
      <StatusBar time="8:14"/>
      <div style={{flex:1, display:'flex', flexDirection:'column', padding:'32px 22px 0'}}>
        <div style={{marginBottom:32}}>
          <div className="h-title" style={{fontSize:26}}>تسجيل الدخول</div>
          <div className="h-sub">أهلاً بعودتك — تابع من حيث توقفت</div>
        </div>
        <LoginForm/>
      </div>
    </div>
  );
}
function LoginB(){
  return (
    <div className="ph">
      <StatusBar time="8:14"/>
      <div style={{flex:1, display:'flex', flexDirection:'column', padding:'30px 18px 0'}}>
        <div style={{display:'flex', flexDirection:'column', alignItems:'center', marginBottom:22}}>
          <Logo size={26} sub={false}/>
          <div className="h-title" style={{fontSize:22, marginTop:22}}>تسجيل الدخول</div>
          <div className="h-sub">أهلاً بعودتك</div>
        </div>
        <div className="card" style={{padding:20}}>
          <LoginForm/>
        </div>
      </div>
    </div>
  );
}

/* ---------------- SIGN-UP ---------------- */
function SignupFields(){
  return (
    <>
      <div className="field-label">الاسم الكامل</div>
      <div className="input"><span className="ph-text">أحمد محمد</span></div>
      <div style={{height:18}}></div>
      <div className="field-label">رقم الهاتف</div>
      <div className="phone-row">
        <div className="input"><span className="ph-text">3312 3456</span></div>
        <div className="input cc">+973</div>
      </div>
      <div style={{height:18}}></div>
      <div className="field-label">المرحلة الدراسية</div>
      <div className="input" style={{justifyContent:'space-between'}}>
        <span>الصف الحادي عشر</span>
        <Icon n="chevL" s={18} style={{transform:'rotate(-90deg)', color:'var(--faint)'}}/>
      </div>
    </>
  );
}
function SignupA(){
  return (
    <div className="ph is-scroll">
      <StatusBar time="8:15"/>
      <div style={{padding:'28px 22px 26px'}}>
        <div className="h-title" style={{fontSize:26}}>إنشاء حساب</div>
        <div className="h-sub" style={{marginBottom:26}}>سجّل الآن وابدأ رحلتك التعليمية</div>
        <SignupFields/>
        <div style={{height:24}}></div>
        <button className="btn btn-primary">إنشاء الحساب</button>
        <p style={{textAlign:'center', fontSize:13, color:'var(--muted)', marginTop:18}}>
          لديك حساب؟ <span style={{color:'var(--blue-700)', fontWeight:600}}>سجّل دخولك</span>
        </p>
      </div>
    </div>
  );
}
function SignupB(){
  return (
    <div className="ph is-scroll">
      <StatusBar time="8:15"/>
      <div style={{padding:'26px 18px 26px'}}>
        <div style={{marginBottom:18}}>
          <div className="h-title" style={{fontSize:23}}>إنشاء حساب</div>
          <div className="h-sub">سجّل الآن وابدأ رحلتك التعليمية</div>
        </div>
        <div className="card" style={{padding:20}}>
          <SignupFields/>
        </div>
        <div style={{height:18}}></div>
        <button className="btn btn-primary">إنشاء الحساب</button>
        <p style={{textAlign:'center', fontSize:13, color:'var(--muted)', marginTop:16}}>
          لديك حساب؟ <span style={{color:'var(--blue-700)', fontWeight:600}}>سجّل دخولك</span>
        </p>
      </div>
    </div>
  );
}

Object.assign(window, { Logo, WelcomeA, WelcomeB, LoginA, LoginB, SignupA, SignupB });
