//+------------------------------------------------------------------+
//|                                                HelpMe_V14_08.mq5 |
//|                     Combined EA - Ali Naderi v14.08 (EA)         |
//+------------------------------------------------------------------+
#property copyright "HelpMe v14.08 - Ali Naderi"
#property version   "14.08"
// ════════════════════════════════════════════════════════════════════
// 📋 v14.08 — فیکس BUG-TF1: آستانه‌های Rule_Transition → TF-aware
//            + کامنت DESIGN LOCK برای BUG-SPIKE1
//
// تغییرات این نسخه:
// 🔴 BUG-TF1 FIX: آستانه‌های Rule_Transition (crisisRedH>=6, cleanH>=24)
//    به g_ruleCloseBars و g_ruleResumeBars TF-aware تبدیل شدند.
//    در OnInit: g_ruleCloseBars = MathMax(1, MathRound(6h*3600/chartPeriodSec))
//    H1: 2/6/24 کندل (صفر رگرسیون) | M1: 120/360/1440 | H4: 1/2/6
// 🔵 BUG-SPIKE1: کامنت DESIGN LOCK اضافه شد — Rule_Transition هر تیک عمدی است
//
// تغییرات رد شده (با دلیل دقیق):
// ✅ BUG-TF2 (InitReplay loop هاردکد): در کد ما وجود ندارد —
//    از v14.06 BUG-C1 قبلاً 259200/g_chartPeriodSeconds اعمال شده بود.
// ✅ BUG-TF3 (OnDemand odBarsToScan ثابت): در کد ما وجود ندارد —
//    از PATCH-5 v14.05 قبلاً 72h*3600/odPeriodSec اعمال شده بود.
// ❌ BUG-GV1 (TF-aware GV keys): موکول به v14.09 — migration plan لازم است
//
// ════════════════════════════════════════════════════════════════════
// 📋 v14.07 — اضافه کردن شاخه EURGBP در Crisis_GetThresholds و SpikeWeights
//            + بررسی صحت CopyClose در FOREIGN + کامنت‌های Design Lock
//
// تغییرات این نسخه:
// 🟠 PATCH-D1: شاخه اختصاصی EURGBP در Crisis_GetThresholds (اعداد موقت/TODO)
// 🟠 PATCH-D1: شاخه اختصاصی EURGBP در Rule_SpikeWeightsForSymbol (اعداد موقت/TODO)
// 🟡 PATCH-P5: چک صحت CopyClose در OnDemand_RunAndSend — اگه همه قیمت‌ها صفر → skip
// 🔵 PATCH-B2: کامنت DESIGN LOCK در GBPNZD_InitReplay (handle های H1/H4/D1 ثابت)
// 🔵 PATCH-B2: کامنت DESIGN LOCK در FlowEvaluate (همیشه H4)
// 🔵 PATCH-B2: کامنت DESIGN LOCK در Zone_IsConfirmedByH1 (همیشه H1)
// ════════════════════════════════════════════════════════════════════
// 📋 v14.06 — رفع BUG-C1 (مقیاس Replay) + BUG-H2 (FOREIGN data check)
//            + مستندسازی BUG-M1/M2 + BUG-M3 (نام فایل)
// ════════════════════════════════════════════════════════════════════
//
// 🔴 BUG-C1 (بحرانی): GBPNZD_InitReplay — مقیاس counter اشتباه در TF غیر H1
//   مشکل: InitReplay همیشه for(sh=72; sh>=1) می‌زد — ۷۲ شیفت H1.
//         اما Alert_CheckGBPNZDRule هر کندل چارت (هر TF) counter می‌زند.
//         روی M1: Replay ۷۲ ساعت را با ۷۲ شیفت می‌شمارد، live هر دقیقه
//         یک واحد → crisisRedH بعد از Replay با مقیاس x60 اشتباه شروع می‌کند.
//         روی H4: Replay ۷۲ شیفت H1 = فقط ۱۸ شیفت H4ی کامل (۷۲ ساعت)،
//         اما live هر H4 یک واحد → counter حدوداً ۴x بزرگتر از Replay.
//         نتیجه: بدترین حالت برای M1 — اولین ساعت‌های کار Rule state غلط دارد.
//   راه‌حل: barsToScan = 259200 / g_chartPeriodSeconds (همان منطق PATCH-5).
//           برای H1: 259200/3600 = ۷۲ — رفتار دقیقاً یکسان.
//           برای M1: 259200/60  = ۴۳۲۰ کندل M1 = ۷۲ ساعت.
//           برای H4: 259200/14400 = ۱۸ کندل H4 = ۷۲ ساعت.
//   توجه: handle های موجود (H1/H4/D1) برای Crisis همچنان ثابت هستند —
//          تغییر فقط تعداد iteration های loop است، نه TF محاسبه.
//
// 🟠 BUG-H2 (بالا): OnDemand_RunAndSend — FOREIGN بدون چک موجودیت داده
//   مشکل: اگر سیمبل FOREIGN در PERIOD_CURRENT داده کافی نداشت،
//          CopyClose صفر برمی‌گرداند و counter ها خاموش می‌شوند — بدون اخطار.
//   راه‌حل: قبل از loop، iBars(broker, PERIOD_CURRENT) بررسی می‌شود.
//           اگر کمتر از odBarsToScan بود، odBarsToScan به available کاهش
//           می‌یابد (نه skip کامل). اگر < 10 بود، اخطار داده می‌شود.
//
// 🟡 BUG-M1 (مستندسازی): Rule_Transition هر تیک با مقادیر cache
//   واقعیت: Rule_Transition هر تیک فراخوانی می‌شود ولی crisisRedH/cleanH
//   فقط سر کندل آپدیت می‌شوند. این عمدی است: برای STOP فوری (intra-candle
//   Spike جدید)، Rule باید هر تیک واکنش دهد اما با counter ثابت کندل قبل.
//   تضمین: بین دو کندل هیچ‌وقت counter تغییر نمی‌کند — فقط crisis/spike
//   جاری عوض می‌شود. این رفتار در کامنت مستند شد.
//
// 🟡 BUG-M2 (مستندسازی): PATCH-7 و P2 مکمل هم هستند
//   تعامل دو مکانیزم در کامنت مستند شد تا double-skip بررسی‌پذیر باشد.
//
// 🟡 BUG-M3 (رفع شد): نام فایل در هدر اشتباه بود («HelpMe_V14_04.mq5»)
//   راه‌حل: خط اول به «HelpMe_V14_06.mq5» تصحیح شد.
//
// ℹ️ BUG-C2 (Zone_IsConfirmedByH1 و TL_Update paths): بررسی شد، رفع شده.
//   Zone_IsConfirmedByH1 عمداً H1-only است (طبق جدول TF ثابت در Changelog).
//   CSL_UpdateProfitOnly/PATCH-4: g_lastBarCloseTime تنها مسیر TL_Update
//   خارج از isNewBar را پوشش می‌دهد — OnChartEvent (FIX-3 v14.04) هم
//   g_isNewChartBar=true ست می‌کند و g_lastBarCloseTime از FIX-3 پوشیده است.
//
// ════════════════════════════════════════════════════════════════════
// 📋 v14.05 — رفع ۴ ایراد موتور کندل-محور (بررسی دو تیم مستقل)
// ════════════════════════════════════════════════════════════════════
//
// 🔴 PATCH-2: Chart_IsNewBarClosed — رفع race condition اولین تیک
//   مشکل: iTime(0) در اولین تیک بعد از بسته‌شدن کندل، زمان کندل جدید
//         (ناقص) را برمی‌گرداند — اگه بین چک و آپدیت تأخیر بود، یک
//         کندل می‌توانست دوبار پردازش شود.
//   راه‌حل: iTime(1) — همیشه آخرین کندل کاملاً بسته؛ هماهنگ با shift=1
//           در Spike_TFScore (v14.03 FIX-A). ثبت فوری قبل از return.
//
// 🟠 PATCH-4: CSL_UpdateProfitOnly — g_lastBarCloseTime قبل از TL_Update
//   مشکل: وقتی پوزیشن باز/بسته می‌شد، TL_Update فوری صدا می‌شد ولی
//         g_lastBarCloseTime آپدیت نمی‌شد → در اولین تیک بعد از آن،
//         Chart_IsNewBarClosed دوباره true می‌شد → Rule/Spike دوبار اجرا.
//         (در H1 بعد از ۵۹ دقیقه مشکل ساز، در M1 در چند ثانیه).
//   راه‌حل: قبل از TL_Update، iTime(1) در g_lastBarCloseTime ست می‌شود.
//
// 🟠 PATCH-5: OnDemand_RunAndSend — پنجره زمانی ثابت ۷۲ ساعت
//   مشکل: MathMax(72, 259200/period) پنجره را برای TFهای بزرگ اعوجاج
//         می‌داد: H4=12 روز، D1=72 روز — در حالی که H1 فقط ۳ روز.
//   راه‌حل: پنجره ثابت ۷۲ ساعت = 259200 ثانیه؛ تعداد کندل‌ها از TF.
//           FOREIGN با همان پنجره چارت اصلی محاسبه می‌شود.
//
// 🟠 PATCH-6: HM_HourStateFile — نام فایل snapshot شامل TF
//   مشکل: نام فایل ثابت بود (بدون TF) — اگه اکسپرت روی H1 و M1 هم‌زمان
//         باز بود، هر دو یک فایل را می‌خواندند/می‌نوشتند → counters اشتباه.
//   راه‌حل: EnumToString(PERIOD_CURRENT) به نام فایل اضافه شد.
//           مثال: HelpMe_GBNZD_HourStateSnapshot_PERIOD_H1.dat
//
// 🟡 PATCH-7: Alert_CheckGBPNZDRule — آستانه آخر هفته پویا
//   مشکل: ۷۲۰۰ ثانیه (۲ ساعت) ثابت — برای H4 کمتر از یک کندل بود.
//   راه‌حل: MathMax(2h, 3×chartPeriod) — برای H4 می‌شود ۱۲ ساعت.
//
// ℹ️ BUG-1 (firstRuleRun): در v14.04 این متغیر static نیست و از
//   g_gbnzdCrisisBuy<0 محاسبه می‌شود — رفتار درست است، باگ وجود ندارد.
//
// ℹ️ BUG-3 (counter scaling): در v14.04 InitReplay از ابتدا روی
//   PERIOD_CURRENT شمرده می‌کند — scale اضافی لازم نیست.
//
// ════════════════════════════════════════════════════════════════════
// 📋 v14.04 — رفع سه باگ TF-aware در موتور کندل-محور
// ════════════════════════════════════════════════════════════════════
//
// 🔴 FIX-1 (بحرانی): ترتیب OnInit + gap-fill در GBPNZD_GV_Load
//   مشکل: g_chartPeriodSeconds بعد از GBPNZD_InitReplay ست می‌شد → GV_Load
//         gap-fill با g_chartPeriodSeconds=0 → fallback به 3600 (H1 هاردکد).
//         روی M1: counters خیلی کمتر (60x). روی H4: خیلی بیشتر از واقع.
//   راه‌حل: g_chartPeriodSeconds پیش از GBPNZD_InitReplay در OnInit ست شد.
//           gap-fill از gapStep=g_chartPeriodSeconds و iTime(1) استفاده می‌کند.
//
// 🔴 FIX-2 (بحرانی): GBPNZD_SaveHourStateFile / InitReplay P3
//   مشکل: فایل snapshot با مرز H1 (/ 3600 * 3600) ذخیره/مقایسه می‌شد.
//         روی M1 یا H4 snapshot اشتباه شناسایی می‌شد یا اصلاً match نمی‌کرد.
//   راه‌حل: هر دو طرف از gapStep=g_chartPeriodSeconds استفاده می‌کنند.
//
// 🟡 FIX-3 (متوسط): TL_Update از OnChartEvent بدون g_isNewChartBar
//   مشکل: تغییر DirMode یا باز/بسته پوزیشن → TL_Update → runRuleBlock=false
//         → Rule/Spike برای جهت جدید تا کندل بعدی stale می‌ماند.
//   راه‌حل: g_isNewChartBar=true قبل / =false بعد از هر TL_Update خارج از OnTick.
//
// ════════════════════════════════════════════════════════════════════
// 📋 v14.03 — یکپارچه‌سازی موتور Rule/Spike با تایم‌فریم چارت
// ════════════════════════════════════════════════════════════════════
//
// 🔴 ARCH-01 (بحرانی): یکپارچه‌سازی موتور Rule/Spike با تایم‌فریم چارت
//   مشکل: Rule_Transition() و Calc_SpikeDetector() در لایو هر تیک اجرا می‌شدند
//         در حالی که آستانه‌های تمام قوانین از بکتست کندل-محور استخراج شده‌اند.
//         این ناهمخوانی ساختاری باعث می‌شد لایو سیگنال‌هایی بدهد که
//         در بکتست وجود نداشتند (یا برعکس) — تفاوت تا ۵۹ دقیقه در H1.
//   راه‌حل: تابع جدید Chart_IsNewBarClosed() — تشخیص بسته‌شدن کندل در هر
//           تایم‌فریمی. Rule و Spike (از طریق TL_Update در CSL_Execute)
//           فقط روی کندل بسته محاسبه می‌شوند.
//           TL_Update از OnTimer حذف شد — فقط از مسیر isNewBar در OnTick.
//           واگرایی بکتست/لایو به صفر کاهش می‌یابد.
//
// 🔴 ARCH-02 (بحرانی): FOREIGN از تایم‌فریم چارت جاری پیروی می‌کند
//   مشکل: OnDemand_RunAndSend ۷۲ کندل H1 هاردکد replay می‌کرد.
//         اگه اکسپرت روی M1 بود و AUDCAD از تلگرام درخواست می‌شد،
//         Replay روی H1 اجرا می‌شد — یک موتور دوگانه داشتیم.
//   راه‌حل: PERIOD_CURRENT برای replay. پنجره زمانی ۷۲ ساعت حفظ شده
//           ولی granularity با تایم‌فریم چارت است.
//           یک موتور — همه سمبل‌ها — همه تایم‌فریم‌ها.
//
// 🟡 CLEAN-01: حذف چک ساعتی H1 داخلی از Alert_CheckGBPNZDRule
//   مشکل: داخل تابع، چک thisHour > g_gbpnzdLastH (مرز H1) وجود داشت.
//         حالا از g_lastBarCloseTime (مرز تایم‌فریم چارت) استفاده می‌شود.
//   راه‌حل: g_gbpnzdLastH به‌جای timestamp ساعتی، timestamp کندل بسته نگه می‌دارد.
//
// 🟡 CLEAN-02: حذف TL_Update از OnTimer
//   مشکل: TL_Update هم در OnTick (از طریق CSL_Execute) هم در OnTimer هر ۳۰
//         ثانیه صدا زده می‌شد — خطر double-calc و race condition.
//   راه‌حل: TL_Update از OnTimer حذف شد. فقط از مسیر isNewBar در OnTick.
//
// متغیرهای جدید:
//   g_chartPeriodSeconds : int      — طول کندل چارت (ثانیه)
//   g_lastBarCloseTime   : datetime — زمان آخرین کندل پردازش‌شده
//
// توابع جدید:
//   Chart_IsNewBarClosed() : bool — تشخیص بسته‌شدن کندل در هر TF
//
// توابع تغییریافته:
//   OnInit()                 — مقداردهی g_lastBarCloseTime و g_chartPeriodSeconds
//   OnTimer()                — حذف TL_Update
//   Alert_CheckGBPNZDRule()  — جایگزینی مرز ساعتی با مرز کندل چارت
//   OnDemand_RunAndSend()    — از PERIOD_CURRENT و odBarsToScan پویا
//   GBPNZD_InitReplay()      — g_gbpnzdLastH از PERIOD_CURRENT (نه H1 هاردکد)
//
// چیزهایی که تغییر نکرده‌اند (تایم‌فریم ثابت و از قبل کالیبره):
//   FlowEvaluate()     → H4   | Zone_IsConfirmedByH1() → H1
//   چراغ‌های D1 روند  → D1   | ATR D1 در Crisis_GetThresholds → D1
//   GBPNZD_Replay_CrisisAtBar / SpikeAtBar → H1 (برای InitReplay state recovery)
//
// ════════════════════════════════════════════════════════════════════
// 📋 v14.02 — فیکس خطای کامپایل (ArrayCopy روی struct با string)
//   قرار بود حلش کنه. راه‌حل: کلید نسخه HM_GBNZD_Ver در GV (نگاه کن به
//   GBPNZD_GV_Save، GBPNZD_GV_Load، GBPNZD_InitReplay).
//
// 📋 v13.50 — پچ معماری: حذف تکرار سه‌گانه Rule + سخت‌گیری FLOW/Spike + بهینه‌سازی CPU
// ════════════════════════════════════════════════════════════════════
//
// 🔴 RULE-01 (بحرانی): منطق Rule در سه‌جا کپی‌شده بود
//   محل: Alert_CheckGBPNZDRule() / LogHourlySnapshot() / GBPNZD_InitReplay()
//   مشکل: ماشین‌حالت Rule (CleanH/CrisisRedH، STOP/CLOSE/RESUME) در سه مکان
//         مستقل پیاده‌سازی شده بود. هر فیکس باید در هر سه‌جا دستی اعمال
//         می‌شد — ریشه‌ی تمام باگ‌های واگرایی v13.39–v13.49.
//   راه‌حل: دو تابع مشترک ایجاد شد (Single Source of Truth):
//     • Rule_UpdateCounters(hourRed, hourDirty, &crisisRedH, &cleanH)
//     • Rule_Transition(crisis, spike, haFlag, crisisRedH, cleanH, &level, &reason)
//   هر سه مسیر (لایو/بکتست/Replay) اکنون این دو تابع واحد را صدا می‌زنند.
//   عمداً دو تابع جدا شدند نه یکی: در لایو، شمارنده‌ها فقط سر مرز ساعت
//   آپدیت می‌شوند ولی ماشین‌حالت باید هر تیک واکنش نشون بده (تأخیر در
//   STOP خطرناکه) — ادغام در یک تابع واحد این رفتار را می‌شکست.
//
// 🔴 FLOW-02: آستانه renormalize ۵۰٪ → ۷۰٪ + وضعیت low-confidence
//   محل: FlowEvaluate()
//   مشکل: اگر خواهرهای پُروزن (GBP/EUR/NZD) resolve نمی‌شدند، حتی با
//         renormalize ۵۰٪، امتیاز FLOW سیستماتیک منحرف می‌شد بدون
//         هیچ نشانه‌ای که نتیجه قابل اعتماد نیست.
//   راه‌حل: آستانه به ۷۰٪ افزایش یافت. اگر پوشش وزن کافی نبود،
//         g_flowLowConfidence=true ست می‌شود.
//
// 🟠 FLOW-03: استقلال Spike از FLOW — مسیر Spike خام در شرایط low-confidence
//   محل: Calc_SpikeDetector()
//   مشکل: چراغ Spike فقط با rawPhase≥1 AND FLOW==Red تأیید می‌شد — اگر
//         FLOW فریز/غیرقابل‌اعتماد بود، Spike واقعی نادیده گرفته می‌شد.
//   راه‌حل: در حالت g_flowLowConfidence یا FLOW نامعتبر (-1)، Spike با
//         آستانه‌ی بالاتر (score≥2.5 → Spike (LC)، score≥1.5 → Warning (LC))
//         مستقل از FLOW تأیید می‌شود.
//
// 🟠 RULE-04: یادآوری وابسته به سطح — CLOSE هر ۳۰ دقیقه، STOP هر ۶۰ دقیقه
//   محل: Alert_CheckGBPNZDRule()
//   مشکل: یادآوری ثابت هر ۱۲۰ دقیقه برای همه سطح‌ها — پیام CLOSE
//         حساس‌ترین سطح بود ولی با همان تناوب STOP یادآوری می‌شد.
//   راه‌حل: input جدید Alert_CLOSERepeatMinutes (پیش‌فرض ۳۰) جدا از
//         Alert_GBPNZDRule_RepeatMinutes (پیش‌فرض ۶۰ — قبلاً ۱۲۰).
//
// 🟠 CPU-01: رفع O(n²) در AddNews — Pre-Allocate آرایه خبر
//   محل: AddNews() / ParseCSVString()
//   مشکل: AddNews() هر خبر ArrayResize(g_newsList, count+1) صدا می‌زد —
//         n بار realloc با کپی کامل آرایه = O(n²) برای ۲۰۰+ خبر محسوس بود.
//   راه‌حل: ParseCSVString ابتدا یک‌بار pre-allocate (worst-case) می‌کند،
//         AddNews فقط assign+increment، در انتها trim به اندازه واقعی.
//
// 🟠 CPU-02: حذف حلقه دستی اضافی S/R — کد مرده
//   محل: OnChartEvent() ← دکمه S/R
//   مشکل: پس از ObjectsDeleteAll(0, SR_OBJ_PREFIX)، یک حلقه‌ی دستی روی
//         کل اشیای چارت هم اجرا می‌شد — کد مرده با هزینه CPU.
//   راه‌حل: حلقه دستی حذف شد؛ ObjectsDeleteAll با prefix کافی است.
//
// 🟡 LIGHT-02: ZOMBIE — کاهش تأخیر H1 با پارامتر ZombieH1ConfirmMinutes
//   محل: Zone_IsConfirmedByH1()
//   مشکل: ZOMBIE باید منتظر بسته شدن کامل کندل H1 می‌ماند — تا ۶۰ دقیقه تأخیر.
//   راه‌حل: input جدید ZombieH1ConfirmMinutes (پیش‌فرض ۳۰). اگر کندل H1
//         جاری حداقل این تعداد دقیقه تشکیل شده باشد، تأیید نیمه‌کامل قبول می‌شود.
//
// 🟡 LIGHT-04: Orange A/B/C — fallback بدون FLOW در شرایط low-confidence
//   محل: UpdateCrisisLight()
//   مشکل: Orange-A/C به FLOW وابسته بودند — در g_flowLowConfidence هیچ
//         Orange (از این دو مسیر) دیده نمی‌شد.
//   راه‌حل: fallback به شرط‌های ساده‌تر (rc/ADX/tsAgainst بدون Flow) +
//         نمایش (LC) روی داشبورد وقتی fallback فعال شده.
//
// 🟡 CPU-03: بهینه‌سازی DrawNewsLines — جلوگیری از rebuild کامل در هر tick
//   محل: DrawNewsLines()
//   مشکل: هر بار ObjectsDeleteAll + redraw کامل انجام می‌داد — حتی وقتی
//         هیچ تغییری نبود.
//   راه‌حل: dirty-check — rebuild فقط اگر g_newsCount یا g_lastUpdate
//         تغییر کرده باشد (پارامتر force=true برای rebuild اجباری حفظ شد).
//
// 🟢 RULE-05: اصلاح نام مستندات — BT_CheckGBPNZDRule → LogHourlySnapshot
//   تمام ارجاعات به تابع وهمی BT_CheckGBPNZDRule در comment های کد با
//   نام درست LogHourlySnapshot جایگزین شدند (آن تابع هرگز وجود نداشت).
//
// ℹ️ RISK-01/02 — تأجیل به v13.51
//   Kill-Switch سخت بین HelpMe و Xmoon (دو EA جدا روی دو چارت) نیاز به
//   Magic Number دقیق Xmoon و تست مستقل دارد. بدون SL، Kill-Switch
//   اشتباه می‌تواند پوزیشن سودده را زود ببندد — برنامه‌ریزی برای v13.51.
// ════════════════════════════════════════════════════════════════════
// 📋 v13.49 — پچ تجمیعی بعد از راستی‌آزمایی دو ریویوی Claude و GLM 5.2
// ════════════════════════════════════════════════════════════════════
//
// 🔴 P0 (فوری، یافته جدید): else یتیم در GBPNZD_InitReplay
//   مشکل: در بازنویسی accumulator نسخه v13.48 FIX1، دو خط «else ... = 0؛»
//         بدون if منطبق (بعد از دو خط assignment ساده) در بلوک BUY و SELL
//         باقی مانده بودند — از نظر گرامر C/MQL5 نامعتبر (Compile Error).
//   راه‌حل: هر دو خط یتیم حذف شدند. منطق درست همان دو خط if/else بالاتر بود.
//
// 🔴 P1: FLOW Freeze در بکتست‌های بلندمدت (ریشه در FlowFindSym)
//   مشکل: FlowFindSym فقط با SymbolInfoDouble(sym, SYMBOL_BID)>0.0 سیمبل
//         خواهر را resolve می‌کرد. در Strategy Tester این چک بعد از چند روز
//         می‌تواند false بدهد حتی اگه سیمبل واقعاً موجود باشه → fallback به
//         base6 خام → iClose/CopyClose صفر → آن خواهر سهم صفر → اگه برای
//         همه خواهرها هم‌زمان رخ بده، Flow_Score برای همیشه فریز می‌شه.
//   راه‌حل:
//     • FlowFindSym: تأیید جایگزین با SymbolInfoInteger(SYMBOL_EXIST) +
//       iBars(H4)>50 اضافه شد (هم بدون پسوند، هم با پسوند بروکر).
//     • FlowEvaluate: امتیاز نسبت به وزن خواهرهای واقعاً resolve-شده
//       renormalize می‌شه (فقط اگه ≥۵۰٪ وزن کل مشارکت کرده باشه) تا غیبت
//       موقت چند خواهر باعث کوچک‌شدن/فریز مصنوعی Flow_Score نشه.
//     • Debug print (با ShowDebugLogs) قبل از هر fallback در FlowEvaluate
//       اضافه شد تا محل دقیق resolve ناموفق در یک بکتست کوتاه قابل تأیید باشه.
//
// 🟡 P2: HourRed/HourDirty در آخر هفته بدون tick واقعی
//   مشکل: بلوک accumulator در Alert_CheckGBPNZDRule هر بار (هر تیک/OnTimer)
//         از مقدار فعلی Crisis می‌خواند. آخر هفته که قیمت جدید نمی‌آد، این
//         مقدار همان آخرین Crisis جمعه است — تا ۴۸ ساعت CleanH مصنوعی
//         می‌تونه اضافه بشه و RESUME زودتر از حد لازم دوشنبه صبح رخ بده.
//   راه‌حل: قبل از عبور از مرز ساعت، آخرین quote واقعی سیمبل (SYMBOL_TIME)
//         چک می‌شه. اگه بیش از ۲ ساعت قدیمی باشه (بازار بی‌داده)، نه ++ نه
//         ریست — فقط skip می‌شه و g_gbpnzdLastH هم آپدیت نمی‌شه تا با
//         بازگشت دیتای واقعی، همون بلوک با وضعیت واقعی لحظه بازگشایی
//         پردازش بشه.
//
// 🟠 P3 (اختیاری): کوری Replay بعد از ری‌استارت کامل MT5
//   مشکل: GlobalVariable با ری‌استارت کامل MT5 پاک می‌شه (طراحی عمدی
//         v13.38). Replay فقط از کندل‌های کاملاً بسته H1 بازسازی می‌کنه —
//         اگه Crisis وسط یک کندل رخ داده و کندل با رنگ بهتر بسته شده
//         باشه، آن اپیزود دیده نمی‌شه (خودترمیم با بحران بعدی، ولی تا
//         اون موقع state از واقعیت تمیزتره).
//   راه‌حل: توابع جدید GBPNZD_SaveHourStateFile/LoadHourStateFile —
//         وضعیت accumulator ساعت در حال شکل‌گیری در یک فایل (نه GV) ذخیره
//         می‌شه که با ری‌استارت کامل MT5 هم پاک نمی‌شه. GBPNZD_InitReplay
//         بعد از Replay کندل‌های بسته، این فایل رو (اگه مربوط به همون
//         ساعت در حال شکل‌گیری باشه) با accumulator OR می‌کنه.
//
// 🟡 P4 (اختیاری): فیلتر Magic Number در شمارش پوزیشن‌ها
//   مشکل: همه لوپ‌های PositionsTotal/PositionGetSymbol فقط با _Symbol
//         فیلتر می‌شدند — پوزیشن دستی یا EA دیگر روی همون چارت در شمارش
//         Buy/Sell و محاسبه ZOMBIE/Zone دخالت می‌کرد.
//   راه‌حل: input های جدید InpFilterByMagic (پیش‌فرض false) و
//         InpXmoonMagic + تابع کمکی HM_PositionBelongsToSymbol که در همه
//         لوپ‌های شمارش پوزیشن (CSL_UpdateProfitOnly، UpdateProfitLabel،
//         GetMaxStep، ZOMBIE oldest-position، Chart Trend، Liquid Level،
//         محاسبه equity چندنمادی) اعمال شد. پیش‌فرض false = رفتار قبلی
//         بدون تغییر؛ برای فعال‌سازی، InpFilterByMagic=true کنید و
//         InpXmoonMagic رو با Magic Number واقعی Xmoon ست کنید.
//
// 🟢 P5 (کم‌فوریت، بهینه‌سازی CPU — انجام نشد، نیازمند بررسی جداگانه):
//   PERF-1..4 (redraw خطوط خبری، WebRequest همگام، دیباونس دکمه‌های AI) در
//   گزارش‌های CodeReview_Claude/GLM ذکر شده بودند ولی جزئیات دقیق خط‌به‌خط
//   آن گزارش‌ها در این پچ در دسترس نبود. بررسی مستقیم کد نشون داد اکثر
//   WebRequest ها همین الان با throttle/cooldown محافظت می‌شن (مثلاً
//   SmartLoadNews هر ۴ ساعت، نه هر تیک) و debounce دکمه‌های AI هم قبلاً در
//   v11.3 با g_recalcBusy جایگزین شده. برای جلوگیری از تغییر ریسکی بدون
//   مشخصات دقیق روی یک سیستم زنده بدون Stop-Loss، P5 در این نسخه دست
//   نخورده باقی ماند — اگه گزارش کامل CPU profiling موجوده، در یک پچ جدا
//   با جزئیات دقیق پیاده می‌شه.
//
// ❌ رد شد: ادعای نبود چراغ ZOMBIE (GLM) — چراغ ZOMBIE کاملاً پیاده‌سازی
//   شده (g_lightZOMBIE, Zone_ComputeFromPrice, Zone_IsConfirmedByH1) —
//   نیازی به اقدام نبود.
// ════════════════════════════════════════════════════════════════════
// 📋 v13.48 — ترکیب بهترین‌های v13.47 من + v13.47 شما
// ════════════════════════════════════════════════════════════════════
//
// FIX1 (از نسخه شما): Accumulator ساعتی — جایگزین PrevCrisis/PrevSpike
//   مشکل: PrevCrisis/Spike در ۳ جا overwrite می‌شد (هر ۳۰s، هر تیک، بعد از STOP)
//         → وقتی counter می‌خواند، Prev = Current بود نه وضعیت ساعت قبل
//         → wasClean از لحظه چک می‌خواند نه از کل ساعت گذشته
//   راه‌حل (معماری بهتر از شما): 4 boolean — HourRed/HourDirty — که در طول
//         ساعت OR می‌شوند. هر بار Crisis=Red → HourRed=true. هر بار Spike>=1 → HourDirty=true.
//         در مرز ساعت counter از این worst-case می‌خونه → بعد ریست می‌شه.
//         این تضاد "چه وقت Prev آپدیت شه؟" را کلاً حذف می‌کند.
//   GV جدید: HM_GBNZD_HRedBuy/HDirtyBuy/HRedSell/HDirtySell
//   GV حذف‌شده: HM_GBNZD_PrCrBuy/PrCrSell/PrSpBuy/PrSpSell
//
// FIX2 (از من): Orange A/B/C در بکتست — بدون تغییر از v13.47
//
// FIX3 (از من): چراغ SPIKE در no-position و هج — بدون تغییر از v13.47
//
// FIX4 (از من): جهت مقابل در بکتست — بدون تغییر از v13.47
//
// FIX5 (از شما بهبود یافته): Reminder با input param
//   v13.47 من: reminder هر ۴ ساعت ثابت
//   v13.48: input bool Alert_GBPNZDRule_Repeat + input int Alert_GBPNZDRule_RepeatMinutes
//   پیش‌فرض ۱۲۰ دقیقه. کاربر می‌تواند تغییر دهد.
//
// FIX6 (از من): g_lastLoggedHour datetime — بدون تغییر از v13.47
//
// ════════════════════════════════════════════════════════════════════
// 📋 v13.47 — رفع 6 باگ شناسایی‌شده در بررسی کامل v13.46
// ════════════════════════════════════════════════════════════════════
//
// FIX1: حذف sync اضافه PrevCrisis/Spike در لحظه STOP/CLOSE
//   مشکل (v13.39 FIX3): وقتی level به STOP escalate می‌شد، Prev فوری
//   با وضعیت بحرانی لحظه STOP پر می‌شد. این با rolling update های
//   TL_Update (v13.39 FIX2, v13.40 FIX-B) تضاد نداشت، اما یک sync
//   اضافه بود — Prev الان از TL_Update هر ۳۰ثانیه/تیک آپدیت می‌شه.
//   راه‌حل: بلوک sync بعد از state machine در Alert_CheckGBPNZDRule حذف شد.
//   محل: Alert_CheckGBPNZDRule() بعد از state machine BUY/SELL
//
// FIX2: Orange A/B/C در بکتست (LogHourlySnapshot) اضافه شد
//   مشکل: بکتست فقط isOrangeD داشت — مسیرهای A/B/C (وابسته به FLOW)
//         وجود نداشتند. بکتست سیستماتیک آروم‌تر از واقعیت نشون می‌داد
//         و STOP-B هایی که به Orange+Spike Warning نیاز دارند fire نمی‌شدند.
//         متغیرهای lt_OrA/B/C declare شده اما هرگز استفاده نشده بودند.
//   راه‌حل: isOrangeA/B/C با همان فرمول UpdateCrisisLight اضافه شدند.
//   محل: LogHourlySnapshot() — بلوک crisis calculation
//
// FIX3: چراغ SPIKE در no-position و هج قفل روی Normal بود
//   مشکل: Calc_SpikeDetector از g_lightFLOW استفاده می‌کند که در
//         no-position و هج = -1 → flowConfirms=false → همیشه Normal.
//         داشبورد دقیقاً وقتی مهم‌ترینه (قبل از ورود) گمراه‌کننده بود.
//         Rule درست کار می‌کرد (از g_gbnzdSpike* مستقل) ولی چراغ دروغ می‌گفت.
//   راه‌حل: بعد از Calc_SpikeDetector، چراغ SPIKE با worst-case جهت‌دار
//           (MathMax(SpikeBuy, SpikeSell)) override می‌شود.
//   محل: TL_Update() — بلوک no-position و بلوک hedge
//
// FIX4: جهت مقابل در بکتست (LogHourlySnapshot) بیات می‌ماند
//   مشکل: FIX-B4 (v13.46) برای لایو fix شد اما BT mirror نشد.
//         وقتی isBuySnap=true، SpikeSell از آخرین SELL snapshot باقی می‌ماند.
//   راه‌حل: در هر snapshot، جهت مقابل با Flow جهت‌دار محاسبه می‌شود.
//           (اگه flowScore مقابل موجود نباشد، از negated همین جهت fallback)
//   محل: LogHourlySnapshot() — بلوک isBuySnap
//
// FIX5: یادآوری تکراری STOP/CLOSE هر 4 ساعت
//   مشکل: Alert_CheckGBPNZDRule فقط سر لبه‌ی تغییر حالت پیام می‌فرستاد.
//         اگه پیام CLOSE گم می‌شد، دیگه یادآوری نمی‌آمد (ریسک عملیاتی).
//   راه‌حل: اگه Level > 0 و 4 ساعت از آخرین reminder گذشته، پیام یادآوری
//           با وضعیت فعلی Buy/Sell Rule و CleanH ارسال می‌شود.
//           متغیر: g_gbpnzdLastReminderH (datetime)
//   محل: انتهای Alert_CheckGBPNZDRule()
//
// FIX6: g_lastLoggedHour از int (hour 0-23) به datetime timestamp
//   مشکل: اگه gap داده (بازگشایی آخر هفته) با همان عدد ساعت قبل از gap
//         تطابق داشت، آن ساعت رد می‌شد (edge-case کم‌اثر).
//   راه‌حل: مقایسه timestamp کامل رند‌شده به مرز ساعت — مثل g_gbpnzdLastH
//   محل: LogHourlySnapshot() — شرط early-return
//
// ════════════════════════════════════════════════════════════════════
// 📋 v13.46 — FIX-B4: Spike جهت مقابل در حالت single-direction
// ════════════════════════════════════════════════════════════════════
//
// مشکل کشف‌شده (از بررسی کد v13.45):
//   وقتی فقط یک پوزیشن باز داری (مثلاً فقط Buy)، TL_Update با forBuy=true
//   اجرا می‌شه. در انتهای TL_Update:
//     g_gbnzdSpikeBuy  = g_lightSpike   ← آپدیت می‌شه (جهت پوزیشن)
//     g_gbnzdSpikeSell = ?              ← آپدیت نمی‌شه → مقدار قدیمی از
//                                          آخرین no-position یا hedge می‌مونه
//
//   g_lightSpike از Calc_SpikeDetector می‌آد که از g_lightFLOW غیرجهت‌دار
//   استفاده می‌کنه (نه Flow جهت‌دار). پس حتی جهت پوزیشن هم کاملاً
//   جهت‌دار نیست — اما چون هج و no-position هر دو قبلاً fix شدن (FIX-B2/B3)،
//   single-direction آخرین حالت باقی‌مانده بود.
//
//   نتیجه: در حالت single-direction، Spike جهت مقابل stale بود →
//   Alert_CheckGBPNZDRule از مقدار قدیمی می‌خوند → STOP/RESUME ممکن بود
//   با تأخیر یا زودتر trigger بشه.
//
// راه‌حل:
//   در بلوک snapshot انتهای TL_Update (لایو)، بعد از آپدیت جهت پوزیشن،
//   جهت مقابل با همان فرمول FIX-B3 (no-position) محاسبه و آپدیت می‌شه:
//     score خام + دروازه Flow جهت‌دار (fs<-4.0 = قرمز | score>=2.0+fs<2.0 = زرد)
//   Flow جهت مقابل از FlowEvaluate(..., opposite) گرفته می‌شه.
//   PrevSpike جهت مقابل هم sync می‌شه.
//
//   این پچ فقط در رئال (لایو) اثر داره — بکتست از LogHourlySnapshot
//   مسیر جدا داره و از قبل درست بود.
//
// محل: TL_Update() — بلوک snapshot انتهای تابع (if(forBuy)/else)
//
// ════════════════════════════════════════════════════════════════════
// 📋 v13.45 — خلاصه تغییرات این نسخه (اولویت: هم‌سو کردن با بکتست)
// ════════════════════════════════════════════════════════════════════
//
// زمینه: بررسی کد نشون داد منطق Rule/Spike در ۴-۵ جای مختلف کد جدا
// پیاده‌سازی شده بود (لایو، Replay، GV gap-fill، بکتست) و این کپی‌ها
// با هم سینک نبودن. طبق دستور علی: بدون رفکتور به تابع مشترک — فقط
// یکی‌سازی نقطه‌به‌نقطه، با معیار اینکه فرمول بکتست (LogHourlySnapshot)
// درسته چون قوانین طلایی سند از همون ۴۳۰ معامله بکتست بیرون اومده.
//
// FIX-A: wasClean در GBPNZD_InitReplay — حذف شرط اضافه‌ی «rc<2»
//   مشکل: InitReplay تنها جایی بود که wasClean رو با یه شرط سوم
//         (prevRc<2) محاسبه می‌کرد. لایو (Alert_CheckGBPNZDRule)،
//         GV_Load gap-fill، و بکتست (LogHourlySnapshot) هیچ‌کدوم این
//         شرط رو نداشتن — فقط دو شرط: نه Crisis=Red، نه Spike>=Warning.
//         نتیجه: بعد از ری‌استارت EA، CleanH بازسازی‌شده توسط Replay
//         می‌تونست با چیزی که لایو واقعاً حساب می‌کرد فرق کنه —
//         یعنی RESUME زودتر/دیرتر از واقعیت.
//   راه‌حل: rc<2 حذف شد. حالا هر ۴ مسیر (لایو/Replay/gap-fill/بکتست)
//         دقیقاً یک تعریف wasClean دارن.
//   محل: GBPNZD_InitReplay() — بلوک BUY و بلوک SELL
//
// FIX-B: فرمول Spike جهت‌دار — حذف ضرایب ساختگی ۰.۱۲ و ۰.۰۸
//   مشکل: سه محل کد (StatusQuery no-position، TL_Update no-position،
//         TL_Update حالت هج) هر کدوم یک فرمول «تقویت‌شده با Flow»
//         برای Spike جهت‌دار می‌ساختن — با ضرایب متفاوت (۰.۱۲ در یکی،
//         ۰.۰۸ در دوتای دیگه). این فرمول اصلاً در بکتست وجود نداشت:
//         بکتست (LogHourlySnapshot) از g_lightSpike خام استفاده می‌کرد
//         (بدون هیچ ضریبی)، و GBPNZD_Replay_SpikeAtBar هم از اول بدون
//         ضریب بود. یعنی همون خودِ Replay از قبل با بکتست هم‌فرمول بود؛
//         سه محل لایوِ بالا بودن که از بکتست فاصله گرفته بودن.
//         نتیجه: مقدار Spike Buy/Sell که واقعاً STOP رو تریگر می‌کرد،
//         با چیزی که رو داشبورد نشون داده می‌شد و با چیزی که Replay
//         بعد از ری‌استارت می‌ساخت، می‌تونست فرق کنه.
//   راه‌حل: هر سه محل حالا از امتیاز خام g_spikeScore (بدون ضریب) +
//         دروازه‌ی Flow جهت‌دار (fs<-4.0=قرمز، [-4,2) با score>=2.0=زرد)
//         استفاده می‌کنن — دقیقاً فرمول GBPNZD_Replay_SpikeAtBar و بکتست.
//   محل: خط ~3029 (StatusQuery)، ~8201 (TL_Update هج)، ~8364 (TL_Update no-position)
//
// نکته: بلوک‌های GV_Load gap-fill و LogHourlySnapshot دست نخوردن —
//   از قبل هم با تعریف درست wasClean کار می‌کردن (بدون rc<2).
//   بلوک active-position (پوزیشن واقعی باز) هم دست نخورد — از قبل
//   مثل بکتست از g_lightSpike/g_crisisState مشترک استفاده می‌کرد.
//
// نتیجه کلی: بعد از این پچ، مسیر لایو (هر ۳ حالت: no-position/هج/
// پوزیشن باز) + Replay + بکتست همه یک فرمول Spike و یک تعریف
// wasClean دارن. پیام‌های STOP/CLOSE/RESUME از همین مقادیر ساخته
// می‌شن، پس خودشون هم با این پچ درست می‌شن — نیازی به تغییر جدا
// در متن پیام نبود.
//
// ════════════════════════════════════════════════════════════════════
// 📋 v13.44 — خلاصه کامل تمام تغییرات این نسخه
// ════════════════════════════════════════════════════════════════════
//
// ── از v13.43 ارث برده شد ──────────────────────────────────────────
// FIX-43-1: wasClean — Orange بدون Spike دیگر CleanH را ریست نمی‌کند
//   مشکل: Crisis=Orange به تنهایی CleanH=0 می‌کرد → RESUME تا 9 روز تاخیر
//   راه‌حل: wasClean = (نه Crisis=Red) AND (Spike=Normal)
//   محل: Alert_CheckGBPNZDRule + GBPNZD_InitReplay + LogHourlySnapshot
//
// ── تغییرات جدید v13.44 ────────────────────────────────────────────
//
// FIX1: GV_Load — ساعت‌های از دست رفته بعد از ری‌استارت
//   مشکل: EA که N ساعت خاموش بود، فقط 1 ساعت CleanH++ می‌کرد نه N ساعت
//          → RESUME تا N ساعت دیرتر از واقعیت
//   راه‌حل: while loop در GV_Load — تمام gap بین lastH و nowH را با
//            PrevSnapshot fill می‌کند (حداکثر 72 ساعت)
//   لاگ تأیید: «✅ v13.44 GV_Load gap-fill: Buy CleanH=X | Sell CleanH=X»
//
// FIX2: instant reset — Yellow+Warning اشتباه CleanH=0 می‌کرد
//   مشکل: شرط قدیمی (Crisis>=1 AND Spike>=1) یعنی Crisis=Yellow + Spike=Warning
//          هم CleanH را ریست می‌کرد — اما STOP trigger نمی‌زند (stopB نیاز به
//          Orange/Red دارد). نتیجه: CleanH بی‌دلیل ریست → RESUME دیرتر
//   راه‌حل: trigger دقیقاً = stopA OR stopB (همان شرط state machine)
//            Yellow+Warning → instant reset نمی‌شود
//
// FIX3: Replay counter یک‌پاسه (off-by-one)
//   مشکل: counter (CleanH++/CrisisRedH++) و state machine (_resume چک)
//          هر دو از ساعت جاری می‌خواندند → Replay یک ساعت زودتر RESUME می‌داد
//   راه‌حل: متغیرهای prevCr/Sp/Rc برای counter، state machine از ساعت جاری
//            مثل Alert_CheckGBPNZDRule که از PrevSnapshot می‌خواند
//            انتهای هر iteration: prev ← current
//
// FIX4: Flow freeze در بکتست H1
//   مشکل: در Strategy Tester با چارت H1، FlowEvaluate از iClose(H4,1/6)
//          استفاده می‌کرد که MT5 بین H1 bar ها refresh نمی‌کند
//          → Flow روی یک مقدار ثابت (مثل -2.38) برای 100+ کندل freeze می‌شد
//          → بکتست H1 با M1 فرق می‌کرد (v42: 20 ساعت CRISIS متفاوت)
//          نتیجه v43+v44 بکتست: CRISIS و Flow در H1=M1 کاملاً یکسان ✅
//   راه‌حل: در MQL_TESTER از CopyClose() به جای iClose() — force refresh buffer
//
// FIX5: فرمت نمایشی Run<24h تمیزتر
//   مشکل: وقتی level=0 و CleanH<24، پیام «CrisisRedH=0h | CleanH=23h» نشان
//          می‌داد که اطلاعات اضافه و گیج‌کننده بود
//   راه‌حل: «🟢 Run — Spike=X | CRISIS=X | CleanH=Xh» (بدون CrisisRedH)
//
// ── نتایج بکتست مقایسه‌ای (Sell GBPNZD 19ژوئن–1جولای) ─────────────
//   Flow freeze:   v42_H1=❌(114x) | v43_H1=✅ | v44_H1=✅
//   CRISIS H1=M1:  v42=❌(20 diff) | v43=✅    | v44=✅
//   Flow H1=M1:    v42=❌(92 diff) | v43=✅    | v44=✅
//   Spike H1≠M1:   ذاتی (mid-candle) — H1 range کامل vs M1 دقیقه آخر
//                  H1: 37 Warning/Spike | M1: 17 Warning/Spike (هر دو درست)
//
// ── تفاوت باقی‌مانده H1 vs M1 (ذاتی — patch نمی‌شود) ───────────────
//   Spike در H1 بیشتر Warning/Spike می‌دهد چون snapshot = close کندل H1
//   (range کامل ساعت). M1 snapshot = close آخرین دقیقه (range کوچک).
//   نتیجه: H1 بکتست محافظه‌کارانه‌تر است — RESUME دیرتر.
//   توصیه: M1 را مرجع بگذار — به رئال نزدیک‌تر است.
//
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.43 FIX: wasClean — Orange بدون Spike دیگر CleanH را ریست نمی‌کند
//   مشکل: Crisis=Orange به تنهایی شرط wasClean را false می‌کرد
//         → بعد از هر ساعت Orange (بدون Spike)، CleanH=0 → RESUME تاخیر داشت
//   مثال: در بازه 22ژوئن–1جولای (بکتست Sell)، CleanH هیچوقت به 24 نرسید
//         چون Orange مکرر در هر چند ساعت ریست می‌کرد (9 روز Close)
//   راه‌حل: wasClean = (نه Crisis=Red) AND (Spike=Normal)
//           Orange فقط اگه همزمان Spike>=Warning هم باشد → false
//   تأثیر: RESUME سریع‌تر در شرایط Orange بدون Spike (منطقی‌تر)
//          رفتار STOP/CLOSE بدون تغییر
//   محل اعمال (طبق GBPNZD_Rule_Patch_v2.md، بخش ۵):
//     1) Alert_CheckGBPNZDRule() — counter ساعتی (BUY+SELL)
//     2) GBPNZD_InitReplay()     — داخل loop بازسازی ۷۲ساعته (BUY+SELL)
//     3) LogHourlySnapshot()     — بلوک state machine بکتست (BUY+SELL)
//        نکته: پچ سند این بلوک سوم را «BT_CheckGBPNZDRule» نامیده بود؛
//        چنین تابعی در کد وجود ندارد — منطق بکتست واقعاً همینجا،
//        داخل LogHourlySnapshot، پیاده‌سازی شده. اسم در سند اصلاح شود.
//
// 🔴 ISSUE بازِ جدا — نیاز به بررسی مستقل تیم (هنوز FIX نشده در این نسخه):
//   «FLOW فریز در بکتست‌های طولانی» — با شواهد از بکتست 19ژوئن-1جولای:
//     • Flow_Score (SELL) از 2026.06.26 07:00 تا انتهای بکتست (07.01 22:00،
//       ~5 روز/۱۰۰+ کندل H1) دقیقاً روی -2.38 فریز شده — بدون کوچکترین تغییر.
//     • Flow_Score (BUY) مشابه از 2026.06.29 11:00 روی +0.75 فریز شده.
//     • در همان بازه، ADX_Val (که از handleADX_H4_TL/CopyBuffer می‌آد) و
//       Trend_Score عادی و پیوسته تغییر می‌کنند — یعنی کل بکتست فریز نشده،
//       فقط مسیر محاسبه FLOW.
//   پیامد مهم: Calc_SpikeDetector() چراغ Spike نمایشی را فقط وقتی
//     rawPhase>=1 AND FLOW==Red (یا FLOW==Yellow AND score>=2.0) تأیید
//     می‌کند. چون FLOW فریزشده همیشه Yellow ماند (هرگز Red)، هیچ Spike
//     خامی — even 07.01 15:00 که rawPhase عملاً SPIKE! بود (score=1.928,
//     بالاترین امتیاز آن روز) — هرگز به Warning/Spike نمایشی ارتقا نیافت؛
//     به‌جایش «Normal (Vol↑)» ثبت شد. این یعنی گپ واقعی-بکتست ۰۷.۰۱
//     فقط از mid-candle-vs-closed-candle نیست (طبق پچ v2 بخش ۱.۱)؛
//     بخشی از آن یک باگ واقعی FLOW freeze است که کل تحلیل بکتست ۵+ روز
//     آخر (Crisis/Spike/CleanH/RESUME) را غیرقابل‌اعتماد می‌کند.
//   ریشه احتمالی (نیاز به تأیید با لاگ/دیباگ توسط تیم):
//     FlowEvaluate() نه handle دارد نه CopyBuffer — مستقیماً iClose(sym,H4,1/6)
//     روی سیمبل‌های خواهر می‌خواند. اما FlowFindSym() قبل از آن با
//     SymbolInfoDouble(sym, SYMBOL_BID) > 0.0 سیمبل را resolve می‌کند.
//     در Strategy Tester، BID سیمبل‌های غیر از چارت اصلی همیشه قابل‌اعتماد
//     آپدیت نمی‌شود (شناخته‌شده در MT5) — اگه این چک بعد از چند روز شبیه‌سازی
//     false برگرده، FlowFindSym به‌جای سیمبل با پسوند صحیح (base6+"sfx")
//     روی base6 خام fallback می‌کنه که ممکنه برای این بروکر سیمبل معتبری
//     نباشه → iClose آن سیمبل 0 برمی‌گردونه → آن خواهر در FlowEvaluate
//     continue می‌شه (سهمش صفر) → اگه این برای همه خواهرها همزمان اتفاق
//     بیفته، امتیاز روی یک مقدار جزئی/صفر برای همیشه فریز می‌مونه.
//   اقدام درخواستی: Issue مستقل برای تیم — قبل از هر چیز یک بکتست کوتاه
//     با Print از (sym resolve شده، Bars(sym,H4)، iClose(sym,H4,1)) در هر
//     فراخوانی FlowEvaluate اجرا بشه تا محل دقیق freeze (resolve سیمبل غلط
//     در برابر iClose واقعاً ثابت) مشخص بشه. این باگ مستقل از پچ wasClean
//     بالاست و باید جدا رفع بشه — چون Crisis هم از FLOW==Red تغذیه می‌شه
//     و در این بازه هرگز Red نشده (rc هیچوقت از سهم FLOW کامل نمی‌شه).
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.39 — Fix: سه باگ no-position Crisis overwrite / PrevSnapshot / STOP-Prev
//   root cause: در no-position path، GBPNZD_Replay_CrisisAtBar(shift=1) هر ۳۰ثانیه
//   g_gbnzdCrisisBuy/Sell را overwrite می‌کرد — حتی بعد از اینکه Alert_CheckGBPNZDRule
//   STOP زده بود و Crisis=Orange ثبت شده بود. نتیجه: Level=STOP بعد از ۳۰ثانیه
//   Crisis=Green می‌شد و CleanH در ساعت بعد +1 می‌خورد → RESUME اشتباه.
//   FIX1 (TL_Update no-position): Replay فقط اگه مقدار -1 باشد overwrite می‌کند.
//   FIX2 (TL_Update no-position): PrevCrisis/Spike بعد از هر Alert_CheckGBPNZDRule
//        آپدیت می‌شود (هر ۳۰ثانیه) — نه فقط در start-of-hour.
//   FIX3 (Alert_CheckGBPNZDRule): وقتی Level escalate می‌شود (STOP/CLOSE)،
//        Prev فوری با وضعیت بحرانی جاری پر می‌شود تا ساعت بعد درست بخواند.
// 🐛 v13.38 — Fix: Rule state بعد از ری‌استارت EA با GlobalVariable ذخیره می‌شه
//
//   سناریوی باگ:
//     ساعت 16:12 — Spike=Warning + Crisis=Orange → STOP زده شد ✓ (Alert درست)
//     EA ری‌استارت شد → InitReplay نتوانست STOP را rebuild کند
//     (Orange در کندل جاری بود، کندل بسته شد با Crisis=Yellow/Green)
//     6+ ساعت بعد: Rule «34h متوالی تمیز (RESUME تأیید شد)»
//
//   ریشه مشکل:
//     Replay فقط کندل‌های کاملاً بسته H1 را می‌بیند. اگه Crisis=Orange
//     در اواسط کندل بود و کندل بسته با Crisis=Yellow/Green محاسبه بشه،
//     Replay آن STOP episode را نمی‌بینه → Level=0 → CleanH از صفر رشد.
//
//   FIX — ذخیره/بازیابی Rule state در GlobalVariable:
//     هر بار که Level، CleanH، یا LastH تغییر کرد، در GlobalVariable
//     ذخیره می‌شه. بعد از ری‌استارت، GBPNZD_InitReplay اول چک می‌کنه
//     GlobalVariable موجوده یا نه:
//       - موجوده و جدیده (< 72h): از آن لود می‌کنه (نه Replay)
//       - موجوده ولی کهنه‌ست (> 72h): Replay کامل
//       - موجود نیست: Replay کامل
//     بعد از لود از GV، Replay فقط counter ها رو از GV_LastH به الان
//     آپدیت می‌کنه — بدون ریست Level.
//     GlobalVariable با ری‌استارت MT5 پاک می‌شه — این مطلوبه چون
//     وقتی MT5 ری‌استارت می‌شه، Replay کافی داره تا state رو rebuild کنه.
//
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.37 — Fix: سه باگ Rule — CleanH بدون reset + counter از لحظه جاری
//
//   سناریوی باگ:
//     Sell: CRISIS=🟠 Orange | Spike=⚡ Warning → Alert فرستاد (درست)
//     6 ساعت بعد «وضعیت» → Rule: 🟢 Run — 33h متوالی تمیز
//     یعنی state machine اصلاً STOP نزد.
//
//   FIX 1 — CleanH فوری ریست نمی‌شد وقتی Spike/Crisis فعال بود:
//     قبلاً: CleanH فقط داخل بلوک (thisHour > g_gbpnzdLastH) آپدیت
//     می‌شد. وقتی STOP trigger می‌خورد اما level تغییر نمی‌کرد
//     (مثلاً قبلاً STOP بود)، early-return قبل از هر CleanH ریست
//     اجرا می‌شد. همچنین اگه Spike Warning + Crisis Orange در همان
//     ساعت اتفاق می‌افتاد، CleanH تا ساعت بعد ریست نمی‌شد.
//     حالا: بلافاصله قبل از early-return، اگه STOP trigger فعاله
//     (Spike>=1 AND Crisis>=1) CleanH هر دو جهت فوری صفر می‌شه.
//
//   FIX 2 — counter ساعتی از وضعیت لحظه فعلی می‌خواند نه ساعت قبل:
//     قبلاً: buyRed/buyClean از g_gbnzdCrisisBuy لحظه فعلی می‌خوند.
//     اگه ساعت N: Spike+Crisis خطرناک بود اما STOP نخورد،
//     ساعت N+1: Crisis=Yellow → counter با وضعیت N+1 آپدیت → CleanH++
//     گویی ساعت N هم تمیز بود → 33h بعد RESUME اشتباه.
//     حالا: چهار متغیر جدید g_gbpnzdPrevCrisis/SpikeBuy/Sell
//     وضعیت آخر ساعت پردازش‌شده را ذخیره می‌کنند. counter از prev
//     می‌خونه، سپس snapshot فعلی را برای ساعت بعد ذخیره می‌کنه.
//
//   FIX 3 — prevSnapshot بعد از InitReplay init می‌شه:
//     بعد از GBPNZD_InitReplay، prevSnapshot با وضعیت لحظه Replay
//     پر می‌شه تا اولین counter ساعتی live از مقدار درست بخونه.
//
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.36 — Fix: Replay wasClean شرط اشتباه — باگ اصلی «73h تمیز»
//
//   ریشه مشکل:
//     در GBPNZD_Replay_CrisisAtBar، trendScore از g_csvScore (لحظه جاری)
//     گرفته می‌شه — نه از مقدار تاریخی آن کندل. وقتی EA باز می‌شه،
//     g_csvScore مثلاً +35 هست اما در ساعت‌های بحرانی گذشته trendScore
//     واقعی +50 تا +72 بوده. این باعث می‌شه Orange-B/D trigger نشه
//     (threshold: tsAgainst > 40) و Crisis=Yellow محاسبه بشه.
//     Crisis=Yellow → wasClean=True → CleanH++ هر ساعت → بعد 24h RESUME!
//     در حالی که بکتست Close نشون می‌داد.
//
//   راه‌حل:
//     شرط wasClean در GBPNZD_InitReplay (حلقه replay) و در TL_Update
//     no-position: به جای فقط (crisis<=1 AND spike=Normal)، شرط
//     (rc < 2) هم اضافه می‌شه. یعنی اگه حداقل دو چراغ Red داشته باشیم
//     (TREND+STRUCT یا ترکیب دیگه)، آن ساعت "تمیز" حساب نمی‌شه —
//     حتی اگه Crisis=Yellow محاسبه شده باشه.
//
//     منطق: RC >= 2 در بازار رنجینگ آروم نادره (فقط 8/136 ساعت در بکتست).
//     این شرط مقاوم در برابر هر مقدار trendScore هست — با ts=0, 35, 70
//     همه نتیجه Close درست می‌دن.
//
//   تأییدیه simulation:
//     Sell → Level=Close, cleanH=0 با trendScore=0,35,70 ✅
//     Buy  → Level=Run,   cleanH=58 (مطابق بکتست) ✅
//
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.34 — Fix: دو باگ Spike/Rule در StatusQuery
//
//   FIX 1 — Spike score در سه پیام All/Sell/Buy متفاوت بود:
//     ریشه: در no-position و virtual mode، FlowEvaluate لحظه‌ای
//     صدا زده می‌شد. سه پیام چند ثانیه فاصله دارن — در این چند ثانیه
//     g_spikeScore یا FlowEvaluate ممکنه عوض شده باشه (تیک جدید،
//     یا کندل H1 جدید) → score سه پیام متفاوت می‌شد.
//     راه‌حل: StatusQuery_BuildReport هر بار ابتدا Calc_SpikeDetector()
//     را صدا می‌زند تا g_spikeScore به‌روز باشد، سپس از همان
//     g_gbnzdFlowBuy/Sell که در TL_Update کش شده استفاده می‌کند
//     (نه FlowEvaluate لحظه‌ای). این تضمین می‌کند هر سه snapshot
//     (All/Sell/Buy) از یک baseScore + یک FlowSnapshot مشترک بخوانند.
//     اگر g_gbnzdFlowBuy/Sell هنوز صفر باشد (اول باز شدن)، fallback
//     به FlowEvaluate لحظه‌ای هنوز وجود دارد.
//
//   FIX 2 — Rule در StatusQuery بعد از RESUME نمایش "Run" می‌داد
//     حتی وقتی واقعاً CLOSE بود (Sell=Close در بکتست ولی All=Run):
//     ریشه دوگانه:
//     a) SQ_SpikeRuleText: g_gbpnzdLevel یک متغیر مشترک برای هر دو
//        جهته. در حالت no-position، worstCrisis=MathMax(Buy,Sell)
//        درست محاسبه می‌شد و Level به CLOSE می‌رفت. اما StatusQuery
//        پارامترهای هر جهت را جداگانه pass می‌کند؛ چون g_gbpnzdLevel
//        مشترکه، هر دو جهت پیام یکسان (درست) می‌گرفتند — این قسمت ok.
//     b) مشکل اصلی: در no-position، g_gbnzdCrisisBuy/Sell = -1 (ریست
//        صریح v13.27). worstCrisis=MathMax(-1,-1)=-1 → wasClean=true
//        در هر ساعت → CleanH همیشه بالا می‌رفت → trigResume فعال →
//        Level به 0 می‌رفت در حالی که Replay/Alert گزارش CLOSE داده بود.
//     راه‌حل: در no-position، به جای Crisis=-1، Crisis جهت‌دار را
//        از GBPNZD_Replay_CrisisAtBar(1,...) بخوان و در
//        g_gbnzdCrisisBuy/Sell ذخیره کن. این snapshot هر ساعت
//        در TL_Update آپدیت می‌شود و Rule همیشه از وضعیت لحظه‌ای
//        واقعی بازار (نه N/A) استفاده می‌کند.
//        مهم: بعد از چند ساعت live (g_gbpnzdReplayDone=true)،
//        snapshot های لایو جایگزین Replay می‌شوند — by design.
//
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.33 — Fix: GBPNZD_Replay_CrisisAtBar — flowAgainst علامت اشتباه برای Sell
//
//   مشکل: در GBPNZD_Replay_CrisisAtBar، خط:
//     flowAgainst = forBuy ? -flowScore : flowScore
//   برای Sell: flowAgainst = flowScore = fsSell = مثلاً -9.62 (منفی!)
//   شرط Red: flowAgainst >= th_RedA_Flow = 6.0 → -9.62 >= 6.0 = FALSE
//   → Crisis هرگز Red نمی‌شد در Replay برای Sell direction
//   → wasRed = false، wasClean = true در تمام shifts
//   → g_gbpnzdCleanH = 70 (همه shifts تمیز حساب می‌شدند!)
//   → trigResume فعال → Level=0 → پیام «70h متوالی تمیز (RESUME تأیید شد)»
//   در حالی که بکتست CSV نشان می‌دهد از 22 Jun 20:00 تا 24 Jun 22:00 = Close بوده.
//
//   ریشه: LogHourlySnapshot (که CSV را ساخت) از شرط درست استفاده می‌کرد:
//     isRedA = (flowScore <= -th_RedA_Flow) ← معادل flowAgainst = -flowScore
//   اما CrisisAtBar از فرمول اشتباه استفاده می‌کرد:
//     flowAgainst = fsSell (منفی) ← هرگز >= threshold مثبت نمی‌شود
//
//   راه‌حل: flowAgainst = -flowScore (همیشه نگیشن، هر دو جهت)
//   این با LogHourlySnapshot و منطق FlowEvaluate هماهنگ است:
//     fsSell = -9.62 (منفی = بازار علیه Sell) → -fsSell = +9.62 → Red ✓
//     fsBuy  = -9.62 (منفی = بازار علیه Buy)  → -fsBuy  = +9.62 → Red ✓
//   تمام شرط‌های Orange/Yellow هم به صورت خودکار درست می‌شوند.
//
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.32 — Fix: Spike یکسان در Virtual Buy و Virtual Sell
//   مشکل: در StatusQuery_BuildReport، virtual mode (دکمه Buy/Sell بدون
//     پوزیشن واقعی) به اشتباه از branch "active position" استفاده
//     می‌کرد. این branch از g_gbnzdSpikeSell/Buy که هر دو برابر
//     g_lightSpike بودن استفاده می‌کرد → هر دو score یکسان.
//   راه‌حل: وقتی hasVirtual=true (پوزیشن واقعی نداریم)، branch
//     "no-position" را برای محاسبه Spike جهت‌دار اجرا کن.
//     activeMode هنوز true است (برای نمایش Crisis/ADX/Flow) اما
//     spikeSellVal/spikeBuyVal از محاسبه FlowEvaluate جهت‌دار میان.
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.31 — Fix: چهار باگ کندی / Rule / MktPhase / اول باز کردن
//   FIX 1 — StatusQuery_PollTelegram در OnTick باعث بلاک شدن EA میشد:
//     WebRequest با timeout=1500ms در هر تیک اجرا میشد. اگه اینترنت
//     کند باشه، هر تیک ۱.۵ ثانیه freeze → داشبورد و دکمه‌ها کند.
//     حالا فقط در OnTimer اجرا میشه (هر ۳۰ ثانیه). OnTick فقط
//     شمارنده تیک چک میکنه بدون هیچ WebRequest. این کندی MKT و
//     کندی تلگرام هر دو را حل میکنه چون ریشه یکیه.
//   FIX 2 — Rule text در اول باز کردن Expert در virtual mode اشتباه:
//     وقتی g_gbpnzdReplayDone=false هست (هنوز replay کامل نشده)،
//     StatusQuery_BuildReport یه پیام واضح میفرسته که «در حال
//     بازسازی state...» تا کاربر بدونه اطلاعات هنوز آماده نیست.
//     قبلاً Rule رو از state ناقص می‌خوند → اطلاعات غلط.
//   FIX 3 — Spike score در StatusQuery بعد از switch بین Sell/Buy/All
//     وقتی هیچ پوزیشنی نیست گاهی هر دو یکسان بودن:
//     اگه g_lightSpike == -1 (Calc_SpikeDetector هنوز اجرا نشده)،
//     baseScore=0 → هر دو Spike score صفر → هر دو Normal.
//     حالا وقتی g_lightSpike == -1 و Replay کامل نشده، در پیام
//     تلگرام توضیح داده میشه که داده‌ها در حال لود هستند.
//   FIX 4 — MktPhase در داشبورد دیر نمایش داده میشه:
//     مشکل اصلی همان FIX1 بود (بلاک WebRequest در OnTick). با
//     انتقال poll به OnTimer، داشبورد دیگه block نمیشه.
//     علاوه بر این، در no-position path، TL_SetLight برای MKTPHASE
//     هم اکنون unconditionally (نه فقط NeedRedraw) صدا زده میشه.
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.30 — Fix: سه باگ Rule/Spike/MktPhase
//   FIX 1 — SQ_SpikeRuleText وضعیت g_gbpnzdLevel را نادیده می‌گرفت:
//     تابع فقط شرایط لحظه‌ای را بررسی می‌کرد. وقتی Crisis از Orange
//     به Yellow برمی‌گشت (بدون اینکه 24h CleanH بگذرد)، هیچ trigger
//     فعال نبود → Run برمی‌گشت. اما ماشین حالت g_gbpnzdLevel=2
//     (CLOSE) هنوز فعال بود. نتیجه: query "Run" می‌گفت در حالی که
//     واقعاً CLOSE بود.
//     حالا اگه g_gbpnzdLevel > 0 باشد، مستقیماً STOP یا CLOSE
//     برمی‌گرداند با توضیح اینکه منتظر RESUME (24h clean) است.
//   FIX 2 — Spike score در StatusQuery همیشه یکسان نمایش داده می‌شد:
//     وقتی fsSell ≈ 0 و fsBuy ≈ 0 بودند (بازار نسبتاً آرام)،
//     flowAgainst هر دو تقریباً صفر → spikeScoreSell ≈ spikeScoreBuy.
//     حالا وزن FLOW از ۸٪ به ۱۲٪ افزایش یافت + حداقل اختلاف ۰.۰۲
//     بین Buy/Sell تضمین می‌شود اگر fsSell ≠ fsBuy.
//   FIX 3 — MktPhase در داشبورد همیشه -- بود (هر سه path):
//     مشکل اصلی: retry block فقط با شرط g_mktPhaseNeedRedraw اجرا
//     می‌شد. ولی بعد از اولین موفقیت، این flag false می‌شد. سپس
//     وقتی کاربر بین Sell/Buy/All سوئیچ می‌کرد، داشبورد refresh
//     نمی‌شد چون throttle روزانه Calc_MktPhase از TL_SetLight جلوگیری
//     می‌کرد و NeedRedraw هم false بود.
//     حالا در هر سه path (no-position، hedge، active-position)،
//     هر بار که g_lightMktPhase >= 0 باشد، TL_SetLight بدون قید
//     NeedRedraw صدا زده می‌شود.
//   FIX 4 — Replay window از 24h به 72h افزایش یافت:
//     با shift=24، Replay از صفر شروع می‌کرد. اگه CLOSE episode بیش
//     از 24h پیش شروع شده بود، state اولیه غلط بود → CleanH از
//     صفر شروع → بعد از 24h live بدون trigger → RESUME اشتباه.
//     مثال واقعی: 22 Jun 16:00 تا 23 Jun 22:00 = 30h CLOSE.
//     با shift=24 → Replay از ~23 Jun 22:00 شروع می‌شد → counter
//     از صفر → Crisis بعدی Yellow → CleanH=26h → RESUME → query
//     "Run" نشان می‌داد در حالی که باید CLOSE می‌بود.
//     حالا shift=72: Replay از ~21 Jun 22:00 شروع می‌شود → CLOSE
//     از shift~44 درست ساخته می‌شود → CleanH واقعی → RESUME فقط
//     وقتی واقعاً 24h تمیز گذشته.
//     guard BarsCalculated از 220 به 290 آپدیت شد (210+72+margin).
// ════════════════════════════════════════════════════════════════════
//     تابع فقط شرایط لحظه‌ای را بررسی می‌کرد. وقتی Crisis از Orange
//     به Yellow برمی‌گشت (بدون اینکه 24h CleanH بگذرد)، هیچ trigger
//     فعال نبود → Run برمی‌گشت. اما ماشین حالت g_gbpnzdLevel=2
//     (CLOSE) هنوز فعال بود. نتیجه: query "Run" می‌گفت در حالی که
//     واقعاً CLOSE بود.
//     حالا اگه g_gbpnzdLevel > 0 باشد، مستقیماً STOP یا CLOSE
//     برمی‌گرداند با توضیح اینکه منتظر RESUME (24h clean) است.
//   FIX 2 — Spike score در StatusQuery همیشه یکسان نمایش داده می‌شد:
//     وقتی fsSell ≈ 0 و fsBuy ≈ 0 بودند (بازار نسبتاً آرام)،
//     flowAgainst هر دو تقریباً صفر → spikeScoreSell ≈ spikeScoreBuy.
//     حالا score نمایشی با فرمول دقیق‌تر: هر واحد FLOW علیه جهت
//     → ۱۲٪ تقویت (بجای ۸٪) + حداقل اختلاف ۰.۰۲ بین Buy/Sell اگر
//     fsSell ≠ fsBuy. این تضمین می‌کند حتی در بازار آرام score
//     عددی متفاوت باشد.
//   FIX 3 — MktPhase در داشبورد وقتی پوزیشن باز بود همیشه -- بود:
//     در path پوزیشن‌دار (Sell/Buy active) بعد از Calc_MktPhase()
//     هیچ retry برای g_mktPhaseNeedRedraw وجود نداشت. فقط در
//     no-position و hedge path این retry وجود داشت. حالا retry
//     در هر سه path اضافه شد.
// ════════════════════════════════════════════════════════════════════
//   FIX 1 — MktPhase در داشبورد همیشه خاکستری می‌موند:
//     TL_SetLight پارامتر txt را نادیده می‌گرفت و متن hardcoded
//     ("Safe") می‌نوشت. نتیجه: label داشبورد هیچ‌وقت از "--" به
//     "Range/Neutral/Trend!" تغییر نمی‌کرد و رنگ همیشه DimGray بود.
//     حالا TL_SetLight اگه txt غیر خالی باشه از همون استفاده می‌کنه.
//   FIX 2 — MktPhase از Cache بار اول object داشبورد را پیدا نمی‌کرد:
//     در firstRun وقتی GlobalVariable معتبر بود، TL_SetLight صدا
//     زده می‌شد اما dashboardPrefix هنوز به‌درستی ست نشده بود یا
//     object داشبورد هنوز ساخته نشده بود (بار اول بعد از OnInit).
//     حالا بعد از ست کردن g_lightMktPhase در cache hit، یک flag
//     اضافه شد که در اولین OnTick بعد از ساخت داشبورد دوباره
//     TL_SetLight را صدا بزند.
//   FIX 3 — Spike Buy/Sell در no-position همیشه یکسان بودند:
//     g_spikeScore یک عدد مشترک برای هر دو جهت است — فقط rawPhase
//     که از score ثابت ساخته می‌شد تعیین‌کننده بود. FLOW فیلتر
//     (flowRedSell/flowRedBuy) با آستانه -4.0 در بازار روند
//     یک‌طرفه هیچ‌وقت فعال نمی‌شد. نتیجه: هر دو Normal می‌شدند.
//     حالا score جهت‌دار (spikeScoreSell/spikeScoreBuy) با وزن‌دهی
//     FLOW محاسبه می‌شه: هر واحد FLOW علیه جهت (+1 برای Sell،
//     -1 برای Buy) score را ۸٪ تقویت می‌کنه. در بازار صعودی قوی
//     fsSell منفی‌تر = Sell علیه روند = Spike Sell بالاتر.
//     همچنین آستانه‌های flowYellow/flowRed برای هر جهت به‌صورت
//     جداگانه از spikeScoreDir محاسبه می‌شوند.
//     در SQ_SpikeLineText نیز score جهت‌دار پاس داده می‌شه تا
//     عدد نمایشی Buy و Sell واقعاً متفاوت باشد.
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.28 — Fix: پنج باگ no-position / Replay / Hedge→Single
//   FIX 5 — Spike Buy/Sell در no-position همیشه یکسان و Normal بود:
//     g_lightSpike با g_lightFLOW=-1 (خاکستری) محاسبه شده بود → همیشه
//     flowConfirms=false → dispPhase=0 → هر دو snapshot برابر 0.
//     حالا در no-position، Spike هر جهت با FlowEvaluate جهت‌دار جداگانه
//     محاسبه میشه (همون منطق StatusQuery) → Buy و Sell میتونن متفاوت باشن.
//   FIX 4 — جابجایی یک ساعته در Replay (RTM + STRUCT + Spike):
//     CrisisAtBar از h1Shift+1 و SpikeAtBar از sh+1 استفاده می‌کردن.
//     با h1Shift=1 (آخرین کندل بسته) این یعنی کندل 2 رو تحلیل می‌کردن
//     نه کندل 1. نتیجه: همه counter های CrisisRedH/CleanH یه ساعت
//     به عقب می‌رفتن و Rule بعد از Replay وضعیت غلطی رو نشون می‌داد.
//     حالا: CopyBuffer/iClose با h1Shift (نه h1Shift+1)،
//            CopyHigh/Low/Open/Close با sh (نه sh+1).
//   FIX 3 — Hedge→Single transition: snapshot طرف مخالف stale می‌موند:
//     وقتی از هج بیرون میومدیم، g_gbnzdCrisisSell یا CrisisBuy از قبل
//     از هج stale بود. worstCrisis=MathMax(fresh,stale) Rule رو خراب
//     می‌کرد. حالا طرف مقابل بلافاصله به -1 ریست می‌شه.
//   FIX 2 — wasClean در GBPNZD_InitReplay با Alert_CheckGBPNZDRule
//     ناسازگار بود:
//     Replay: (worstSpike <= 0)         ← worstSpike==-1 را رد می‌کرد
//     Alert:  (worstSpike <= 0 || == -1) ← -1 را Clean حساب می‌کرد
//     حالا هر دو یکسانند: (worstSpike <= 0 || worstSpike == -1)
//   FIX 1 — Spike+Rule در no-position پایدار اجرا نمی‌شد:
//     بلوک Calc_SpikeDetector / snapshot ریست / Alert_CheckGBPNZDRule
//     داخل if(g_lightRTM != -1 || ...) قرار داشت. وقتی چراغ‌ها از
//     قبل خاکستری بودن (مثلاً ریستارت EA در حالت no-position یا هر
//     چرخه بعد از اولین ریست)، شرط false می‌شد و این سه تابع اصلاً
//     صدا نمی‌شدن. نتیجه: g_lightSpike بیات می‌موند، snapshot های
//     Spike ریست نمی‌شدن، و CleanH هر ۳۰ ثانیه پیشرفت نمی‌کرد.
//     حالا این سه تابع بیرون از if قرار دارن — همیشه در no-position
//     اجرا می‌شن.
//   FIX 2 — wasClean در GBPNZD_InitReplay با Alert_CheckGBPNZDRule
//     ناسازگار بود:
//     Replay: (worstSpike <= 0)         ← worstSpike==-1 را رد می‌کرد
//     Alert:  (worstSpike <= 0 || == -1) ← -1 را Clean حساب می‌کرد
//     حالا هر دو یکسانند: (worstSpike <= 0 || worstSpike == -1)
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.27 — Fix: دو باگ بلوک no-position در TL_Update
//   FIX 1 — Alert_CheckGBPNZDRule در no-position صدا زده نمی‌شد:
//     قبلاً snapshot های Spike آپدیت می‌شد ولی Rule بعدش return
//     می‌کرد. نتیجه: وقتی پوزیشن بسته می‌شد و EA بدون پوزیشن بود،
//     g_gbpnzdCleanH در ساعت‌های بدون پوزیشن پیشرفت نمی‌کرد و
//     RESUME نمی‌تونست trigger بشه.
//     حالا Alert_CheckGBPNZDRule() در no-position هم صدا میشه.
//   FIX 2 — Crisis snapshot در no-position ریست نمی‌شد:
//     قبلاً g_gbnzdCrisisBuy/Sell مقدار آخرین پوزیشن رو نگه می‌داشت
//     (stale value). worstCrisis در Rule از همین مقدار می‌خوند و
//     Crisis رو Red نشون می‌داد حتی بعد از بستن همه پوزیشن‌ها.
//     حالا وقتی پوزیشن نیست، هر دو به -1 (N/A واقعی) ریست میشن.
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.26 — Fix: چهار باگ بخش Rule/Spike/StatusQuery
//   FIX 1 — Crisis در حالت «بدون پوزیشن» در StatusQuery:
//     قبلاً فقط FLOW+ADX استفاده می‌شد (بدون RC چراغ‌ها).
//     حالا اگه g_gbnzdCrisisBuy/Sell معتبر باشن (>=0) از همون‌ها
//     استفاده می‌کنه، در غیر اینصورت از GBPNZD_Replay_CrisisAtBar(1,...)
//     که RC کامل (RTM+TREND+STRUCT+FLOW) داره محاسبه می‌کنه.
//     نتیجه: Crisis در No-Position با حالت با-پوزیشن سازگاره.
//   FIX 2 — Replay retry در OnTimer:
//     اگه GBPNZD_InitReplay در OnInit به خاطر handle های warm نشده
//     fail کنه (g_gbpnzdReplayDone=false)، هر ۳۰ ثانیه تا موفقیت
//     دوباره امتحان می‌کنه (حداکثر ۲۰ بار = ۱۰ دقیقه).
//   FIX 3 — Orange-D در Crisis بدون پوزیشن:
//     شرط اشتباه (th_OrD_Ts > 0) جایگزین شد با (tsAgainst > th_OrD_Ts)
//     تا با منطق UpdateCrisisLight سینک باشه.
//   FIX 4 — Spike Sell در Replay:
//     GBPNZD_Replay_SpikeAtBar مقدار واحدی برمی‌گردوند (فقط Buy).
//     حالا تابع دو مقدار (buy/sell) رو از طریق پارامتر ref برمی‌گردونه
//     و InitReplay هر دو رو جداگانه در worstSpike استفاده می‌کنه.
// ════════════════════════════════════════════════════════════════════
// 🆕 v13.25 — GBPNZD_InitReplay: بازسازی state واقعی هنگام restart
//   • تابع GBPNZD_Replay_CrisisAtBar: محاسبه Crisis برای یک کندل H1
//     تاریخی — همان منطق UpdateCrisisLight بدون side-effect داشبورد
//   • تابع GBPNZD_Replay_SpikeAtBar: محاسبه Spike برای یک shift
//     تاریخی — همان منطق Spike_TFScore با offset
//   • تابع GBPNZD_Replay_FlowAtBar: محاسبه FLOW برای یک shift
//     تاریخی — همان منطق FlowEvaluate با iClose+shift
//   • تابع GBPNZD_InitReplay: loop روی 24 کندل H1 گذشته،
//     بازسازی g_gbpnzdCrisisRedH / g_gbpnzdCleanH / g_gbpnzdLevel
//   • فراخوانی در OnInit بعد از ForceRecalculation و handle warmup
//   • بعد از Replay: g_gbpnzdReplayDone=true — Rule قابل اعتماد است
// ════════════════════════════════════════════════════════════════════
// 🆕 v13.24 — StatusQuery: Spike چهار خطی جدا برای Buy و Sell
//   • خط «Spike:» قدیمی (یک خط مشترک) → چهار خط جداگانه:
//     Spike Sell / Spike Buy : رنگ + score + بازه‌های Normal/Warning/Spike
//     Spike Sell Rule / Spike Buy Rule : Run | Stop | Close + توضیح کامل
//   • SpikeRule برای هر جهت مستقل از g_gbpnzdLevel و
//     g_gbnzdSpikeSell/Buy و g_gbnzdCrisisSell/Buy محاسبه می‌شه
//   • توضیح Rule شامل: چرا Run / چرا Stop (چند ساعت Spike + شرایط
//     چراغ الان) / چرا Close (Crisis + HighAlert یا 6h متوالی قرمز)
// ════════════════════════════════════════════════════════════════════
// 🆕 v13.23 — StatusQuery: Rule + Symbol Check + Hedge Age
//   • StatusQuery_BuildReport: چک اول — اگه ارز GBPNZD نباشه
//     پیام "این ارز ساپورت نمیشه" برمی‌گردونه
//   • Rule section جدید در پیام وضعیت: سطح (GREEN/STOP/CLOSE)
//     + دلیل + ساعت‌های Crisis Red + ساعت‌های Clean
//     — در حالت هج هم نمایش داده می‌شه چون از g_gbpnzdLevel خونده
//   • Open Time در هج: مدت Buy و Sell جداگانه نمایش داده می‌شن
// ════════════════════════════════════════════════════════════════════
// 🧹 v13.22 — Cleanup / Final pass (نسبت به v13.21)
//   • پیام‌های تلگرام GBPNZD rule: Unicode escape → متن فارسی literal
//   • LQ debug Print ها: gate شدن پشت ShowDebugLogs
//   • کامنت‌های تایمر (FIX v12.08 / v12.15f): اصلاح اعداد غلط
//   • tooltip TL_MKTPHASE: حذف کاراکتر ━━ ناسازگار
//   • کامنت‌های قدیمی v5/v6/v7/v10/v11 در OnInit/OnDeinit: ساده‌سازی
// ════════════════════════════════════════════════════════════════════
// 🆕 v13.21 — قانون ترید ۳سطحی GBPNZD (Alert_OnGBPNZDRule)
//   • تابع Alert_CheckGBPNZDRule() — state machine: GREEN→STOP→CLOSE→RESUME
//   • STOP  A: Spike=🔴 AND CRISIS≠سبز (Yellow/Orange/Red)
//   • STOP  B: Spike=⚡ Warning AND CRISIS=🟠/🔴
//   • CLOSE A: CRISIS=🔴 AND HighAlert فعال (ADX≥35 + |Flow|>7)
//   • CLOSE B: CRISIS=🔴 برای ۶ ساعت متوالی
//   • RESUME:  CRISIS=سبز/زرد AND Spike=Normal برای ۲۴ ساعت متوالی
//   • State فقط در RAM — با ری‌استارت EA ریست می‌شه (by design)
//   • اعلان‌های تلگرام کاملاً فارسی با مشخصات فنی در خط جداگانه
//   • تغییر default اینپوت‌های کم‌کاربرد به false:
//     Alert_OnCrisisOrange / Alert_OnFlow / Alert_OnThreeLights /
//     Alert_OnMktPhase / Alert_OnSpikeFlowRed
// ════════════════════════════════════════════════════════════════════
// 🧹 v13.20 — Cleanup / Optimize pass (نسبت به v13.19)
//   • حذف کامل STEP DECAY (چراغ، اینپوت Alert_OnStepDecay، تابع‌های
//     SD_AnalyzeSteps/CalcStepDecayLight که اصلاً صدا زده نمی‌شدند،
//     struct های StepInfo/PriceVol، ثابت‌های SD_*، تمام gها و
//     widget داشبورد مربوطه). از v13.19 چراغ از منو حذف شده بود ولی
//     کد و محاسباتش هنوز در پس‌زمینه اجرا می‌شد.
//   • TL_Update(): دو لوپ جدای PositionsTotal() (شمارش buy/sell +
//     پیدا کردن قدیمی‌ترین پوزیشن) به یک لوپ واحد ادغام شد —
//     این تابع روی هر باز/بسته شدن پوزیشن (نه فقط هر ۳۰ ثانیه)
//     صدا زده می‌شود، پس نصف‌کردن تعداد لوپ‌ها مستقیماً سرعت تشخیص
//     چراغ‌ها بعد از بسته شدن پوزیشن را بهتر می‌کند.
//   • چیدمان پنل Alerts از ۶ ردیف به ۵ ردیف جمع شد (جای خالی StepDecay
//     پر شد، پنل کوتاه‌تر شد).
// ════════════════════════════════════════════════════════════════════
#define HELPME_ARROW_PREFIX "HMArr_"

// ── شماره‌های فیلتر برای آرایه filterContrib ──────────────────────
#define FILT_MA        0
#define FILT_RSI       1
#define FILT_ADX       2
#define FILT_BB        3
#define FILT_ATR       4
#define FILT_WICK      5
#define FILT_CANDLE    6
#define FILT_ICHI      7
#define FILT_FVG       8
#define FILT_LIQSWP    9
#define FILT_RTM      10
#define FILT_MTF      11
#define FILT_VOL      12
#define FILT_REGIME   13
#define FILT_HIDDENDIV 14
#define FILT_FRACTAL  15
#define FILT_COUNT    16


// ═══════════════════════════════════════════════════════════════════
// ─── مقادیر داخلی ثابت (نیازی به تنظیم دستی ندارند) ───────────────
// ═══════════════════════════════════════════════════════════════════
// AI Toggles — توسط دکمه‌های داشبورد کنترل می‌شوند
bool   EnableMarketRegimeDetection = false;
bool   EnableMTFConfluence         = false;
bool   EnablePriceActionFilter     = true;
bool   EnableSmartVolume           = false;
int    SmartVolumeThresholdPct     = 60;
bool   EnableSmartNewsFilter       = false;
bool   EnableFVG                   = true;
bool   EnableLiqSwp                = true;
bool   EnableRTM                   = true;
int    RTM_EMAPeriod               = 200;
double RTM_DangerATR               = 3.5;
// Market Regime — خودکار
int    RegimeCalculationBars  = 100;
double TrendingThreshold      = 0.35;
double RangingThreshold       = 0.20;
double HighVolatilityThreshold = 1.5;
bool   BlockSignalsInRanging  = true;
// News Filter — زمان‌بندی فیلتر خبر (داخلی، نمایش در tooltip)
int    NewsBlockMinutesBefore = 30;
int    NewsBlockMinutesAfter  = 30;
double NewsMinImpactWeight    = 0.7;
// MTF — تنظیمات Multi-Timeframe
bool   RequireH1Confirmation  = true;
bool   RequireH4Confirmation  = false;
int    MTF_EMAPeriod          = 200;
// Price Action — الگوهای کندلی
bool   RequireCandlePattern   = true;
double PinBarWickRatio        = 2.0;
double EngulfingMinBodyRatio  = 0.6;
// Core Indicators — اندیکاتورهای پایه
int    FastMA    = 12;
int    SlowMA    = 26;
int    RSIPeriod = 14;
int    ADXPeriod = 14;
int    BBPeriod  = 20;
double BBDeviation = 2.0;
int    ATRPeriod = 14;
// Signal Settings — تنظیمات سیگنال
int    MinBarsBetweenSignals  = 15;
double ArrowOffsetPips        = 5.0;
bool   EnableAlerts           = false;
bool   ShowOnChart            = true;
// Filters — فیلترهای پایه و پیشرفته
bool   UseRSIFilter           = true;
bool   UseADXFilter           = true;
double MinADX                 = 18.0;
bool   UseBBFilter            = true;
bool   UseATRIntensity        = true;
double MinBodyToATRRatio      = 0.3;
bool   UseEfficiencyRatio     = true;
double MinEfficiencyRatio     = 0.20;
bool   UseWickFilter          = true;
double MinBodyToTotalRatio    = 0.3;
// Dashboard Visibility — همه نمایش‌ها همیشه روشن
bool   ShowDashboard          = true;
bool   ShowPresetButtons      = true;
bool   ShowFilterButtons      = true;
bool   ShowAIButtons          = true;
bool   ShowRegimeInfo         = true;
bool   ShowMTFInfo            = true;
bool   ShowGateMonitor        = true;
bool   ShowSessionInfo        = true;
bool   ShowStats              = true;
color  DashboardTextColor     = clrWhite;
// Cache — ذخیره‌سازی اخبار (7 روز پیش‌فرض)
int    CacheValidHours        = 168;

// ═══════════════════════════════════════════════════════════════════
// ──────────── تنظیمات قابل مشاهده در پنل Inputs ─────────────────
// ═══════════════════════════════════════════════════════════════════

//------------------------------------------------------------------------
// ENUMS (باید قبل از input group مربوطه تعریف شوند)
//------------------------------------------------------------------------
enum ENUM_TIMEFRAME_PRESET
{
   PRESET_M1,      // M1 - Ultra Scalp
   PRESET_M5,      // M5 - Quick Scalp
   PRESET_M15,     // M15 - Balanced ⭐
   PRESET_M30,     // M30 - Conservative
   PRESET_H1,      // H1 - Long Term
   PRESET_CUSTOM   // Custom
};

enum ENUM_FILTER_MODE
{
   MODE_RELAXED,    // Relaxed - سیگنال بیشتر
   MODE_BALANCED,   // Balanced - توصیه‌شده ⭐
   MODE_STRICT      // Strict - کیفیت بالاتر
};

//------------------------------------------------------------------------
// ─── لاگ و دیباگ | Logs & Debug ────────────────────────────────────
//------------------------------------------------------------------------
input group "════════ 🔧 تنظیمات عمومی | General ════════"
input bool     EnableAllLogs = false;   // 📋 فعال‌سازی لاگ کامل | Enable All Logs
input bool     ShowDebugLogs = false;   // 🐛 نمایش دیباگ در تب Expert | Show Debug Log
// 🆕 v13.49 P4 (اختیاری): فیلتر Magic Number برای شمارش پوزیشن‌ها.
// همه لوپ‌های PositionsTotal/PositionGetSymbol فعلی فقط با _Symbol فیلتر
// می‌شن — اگه پوزیشن دستی یا از EA دیگری روی همین چارت باز بشه، در شمارش
// Buy/Sell و محاسبه ZOMBIE/Zone دخالت می‌کنه. پیش‌فرض false = رفتار قبلی
// بدون تغییر (چون احتمالاً فقط Xmoon روی این چارت‌ها ترید می‌کنه).
input bool     InpFilterByMagic = false;  // 🎯 فیلتر پوزیشن‌ها بر اساس Magic Number | Filter Positions by Magic
input long     InpXmoonMagic    = 0;      // 🔢 Magic Number اکسپرت Xmoon (0=همه) | Xmoon Magic Number

// 🆕 v13.49 P4: تابع کمکی مرکزی — پوزیشن ایندکس i (بعد از PositionGetSymbol/
// PositionSelectByIndex) متعلق به سیمبل موردنظر است؟ اگه InpFilterByMagic
// فعال باشه، Magic Number هم چک می‌شه تا پوزیشن دستی/EA دیگر روی همان چارت
// در شمارش دخالت نکنه.
bool HM_PositionBelongsToSymbol(string sym, string targetSymbol)
{
   if(sym != targetSymbol) return false;
   if(InpFilterByMagic && PositionGetInteger(POSITION_MAGIC) != InpXmoonMagic) return false;
   return true;
}

//------------------------------------------------------------------------
// ─── سیستم امتیازدهی | Scoring System ──────────────────────────────
//------------------------------------------------------------------------
input group "════════ 🏆 سیستم امتیازدهی | Scoring System ════════"
input int      BaseRequiredScore = 4;     // 🎯 حداقل امتیاز برای ثبت سیگنال | Min Score (1-10)
input bool     ShowScoreInfo     = false; // 📊 نمایش جزئیات امتیاز روی چارت | Show Score Details
input int      HistoryBarsPercent = 100;  // 📊 درصد کندل‌های تاریخچه سیگنال (100=500 | 200=1000 | حداکثر 5000) | History Depth %

//------------------------------------------------------------------------
// ─── داشبورد اصلی | Dashboard Pro ──────────────────────────────────
//------------------------------------------------------------------------
input group "════════ 📊 داشبورد اصلی | Dashboard Pro ════════"
// LiteFinance Cent → Currency=USD, ContractSize=100000 (مثل Standard → قابل تشخیص خودکار نیست)
// اگه حساب Standard یا ECN داری این رو false کن | Standard/ECN users: set false
// برای بروکرهای دیگه: auto-detect (USC/CENT currency یا ContractSize<=1000) فعاله
input bool     IsCentAccount    = true;               // ¢ حساب سنت (÷100) | Cent Account — LiteFinance Cent: true
ENUM_TIMEFRAME_PRESET InitialPreset = PRESET_H1;              // تایم‌فریم اولیه (ثابت داخلی — از Inputs حذف شد)
input ENUM_FILTER_MODE InitialFilterMode  = MODE_BALANCED;    // 🎯 سطح فیلتر اولیه | Initial Filter Mode
input int      DashboardCorner   = 3;   // 📌 موقعیت: 0=بالاچپ | 1=بالاراست | 2=پایین‌چپ | 3=پایین‌راست
input int      DashboardXOffset  = 130; // ↔️ فاصله افقی داشبورد (پیکسل) | Horizontal Offset
input int      DashboardYOffset  = 24;  // ↕️ فاصله عمودی داشبورد (پیکسل) | Vertical Offset
input int      ButtonsXOffset    = 0;// ↔️ فاصله افقی دکمه‌ها (نسبت به پنل) | Buttons Horizontal
input int      ButtonsYOffset    = 0;   // ↕️ فاصله عمودی دکمه‌ها (نسبت به پنل) | Buttons Vertical
input bool     DashboardOnTop    = true;  // 🔝 داشبورد روی چارت باشد (نه پشت آن) | Dashboard On Top
input int      DashboardFontSize = 9;     // 🔤 اندازه فونت داشبورد | Font Size
input int      DashboardScalePercent = 100; // 📏 اندازه کلی داشبورد (٪) — 50..300 | Dashboard Scale %
input color    DashboardBackColor = clrDarkSlateBlue; // 🎨 رنگ پس‌زمینه | Background Color

//------------------------------------------------------------------------
// ─── تنظیمات اخبار | News Settings ─────────────────────────────────
//------------------------------------------------------------------------
input group "════════ 📰 تنظیمات اخبار | News Settings ════════"
int      NewsLookbackDays     = 3;   // ⏪ (ثابت داخلی — از Inputs حذف شد)
int      NewsLookforwardDays  = 3;   // ⏩ (ثابت داخلی — از Inputs حذف شد)
input string   AdditionalCurrencies = "";  // 🌐 ارزهای اضافی (مثال: USD,EUR) | Extra Currencies
double   MinWeightThreshold   = 0.2; // ⚖️ (ثابت داخلی — از Inputs حذف شد)
// ─── فیلتر قدرت خبر ───
input bool     ShowHighImpact       = true;  // 🔴 نمایش اخبار پرقدرت | High Impact News
input bool     ShowMediumImpact     = true;  // 🟡 نمایش اخبار متوسط | Medium Impact News
input bool     ShowLowImpact        = false; // ⚪ نمایش اخبار کم‌قدرت | Low Impact News
// ─── ظاهر خطوط خبری ───
color    HighImpactColor      = clrRed;     // 🎨 (ثابت داخلی — از Inputs حذف شد)
color    MediumImpactColor    = clrOrange;  // 🎨 (ثابت داخلی — از Inputs حذف شد)
color    LowImpactColor       = clrGray;    // 🎨 (ثابت داخلی — از Inputs حذف شد)
ENUM_LINE_STYLE NewsLineStyle = STYLE_DASH; // 📏 (ثابت داخلی — از Inputs حذف شد)
int      NewsLineWidth        = 1;           // 📏 (ثابت داخلی — از Inputs حذف شد)
bool     ShowNewsLabels       = true;        // 🏷️ (ثابت داخلی — از Inputs حذف شد)
input int      LabelFontSize        = 10;          // 🔤 اندازه فونت برچسب | Label Font Size
input double   LabelOffsetPips      = 10.0;        // 📐 فاصله برچسب از High/Low (pip) | Label Offset

//------------------------------------------------------------------------
// ─── سطح لیکوئید | Liquid Level ────────────────────────────────────
//------------------------------------------------------------------------
input group "════════ 💧 سطح لیکوئید | Liquid Level ════════"
// اهرم و استاپ‌اوت ثابت داخلی هستند — برای تغییر در کد ویرایش کنید
double LiquidLeverage   = 1000.0;   // (ثابت داخلی) اهرم حساب
double LiquidStopOutPct = 20.0;     // (ثابت داخلی) درصد استاپ اوت بروکر
// ─────────────────────────────────────────────────────────────────
// فقط برای حساب‌های Cent که حجم پوزیشن به صورت سنت‌لات گزارش می‌شود
// (مثل لایت‌فایننس) — اگر لات نمایش‌داده‌شده ×۱۰۰ واقعی است، True کنید
// Only for Cent accounts where broker reports volume in cent-lots (e.g. LiteFinance)
input bool     CentVolumeIsCentLot = true;   // ¢ حجم به سنت‌لات گزارش می‌شود | Volume in Cent-Lots

//------------------------------------------------------------------------
// ─── تنظیمات بکتست | Backtest Settings ─────────────────────────────
//------------------------------------------------------------------------
input group "════════ 💡 چراغ‌ها | Light ════════"
input bool   ShowZoneLines        = true; // 🗺️ رسم خطوط مرز طبقات روی چارت | Draw Zone Lines
input int    ZombieH1ConfirmBars  = 2;   // ⏱️ تعداد کندل H1 متوالی برای تأیید طبقه جدید | H1 Confirm Bars
input int    ZombieH1ConfirmMinutes = 30; // 🆕 v13.50 LIGHT-02: اگه کندل H1 جاری حداقل این تعداد دقیقه شکل گرفته باشه، تأیید نیمه‌کامل قبول می‌شود | Partial H1 confirm minutes

input group "════════ 🔍 بکتست | Backtest Settings ════════"
// جهت مجازی برای چراغ‌های XMOON ALERT در Strategy Tester (بدون پوزیشن واقعی)
input int    BacktestPositionDir  = 0;   // جهت پوزیشن بکتست (فروش=1  خرید=0)
// ─── Zone Lines ────────────────────────────────────────────────
// ShowZoneLines و ZombieH1ConfirmBars به گروه "چراغ‌ها | Light" منتقل شدند
int    ZoneLineCount        = 30;   // تعداد طبقه در هر طرف از منطقه 0 (ثابت=30)
int    ZoneBorderYellowPips = 10;   // فاصله از مرز برای چراغ زرد (ثابت)

//------------------------------------------------------------------------
// ─── سیستم اعلان‌ها | Notification System ──────────────────
//------------------------------------------------------------------------
input group "════════ 🔔 اعلان‌ها | Notifications ════════"
input bool   Alert_MT5Push           = false;   // اعلان فوری روی موبایل | MT5 Mobile Push
input bool   Alert_Telegram          = true;   // ارسال پیام به تلگرام | Telegram BotAlert
string Alert_TelegramToken     = "8801659037:AAE9qpYC_yMgg1iQcksd2gYJ-diyWLDhn0w";  // (ثابت داخلی — از Inputs حذف شد)
input string Alert_TelegramChatID    = "97992765"; // شناسه چت (برای کانال با - شروع می‌شود) | Chat ID/Channel ID
// ─── کدام چراغ‌ها اعلان بدهند ───────────────────────────────────
input bool   Alert_OnCrisis          = true;   // 🚨 اعلان CRISIS قرمز | Alert on CRISIS Red
input bool   Alert_OnCrisisOrange    = false;  // 🟠 اعلان CRISIS نارنجی (مثل قرمز) | Alert on CRISIS Orange too — 🆕 v13.19
input bool   Alert_OnZombie          = true;   // 🧟 Price Zone اعلان قرمز  | Alert on Price Zone Red
input bool   Alert_OnHighAlert       = false;   // ⚠ ️Hi Alert اعلان قرمز  | Alert on Hi Alert
input bool   Alert_OnFlow            = false;  // 🌊 Currency Flow اعلان قرمز  | Alert on Currency Flow
input bool   Alert_OnADX             = false;   // 📈 Trend Strength اعلان قرمز  | Alert on Trend Strength(ADX)
input bool   Alert_OnRTM             = false;   // 📉 Reversion اعلان قرمز  | Alert on Reversion(RTM)
input bool   Alert_OnStruct          = false;   // 🏗 ️Daily StructT اعلان قرمز  | Alert on Daily Struct
input bool   Alert_OnThreeLights     = false;  // 🔴🔴🔴 اعلان وقتی ۳ چراغ از ۴ همزمان قرمز (ADX/RTM/STRUCT/FLOW) |
input bool   Alert_OnKiller          = true;   // ☠️ KILLER اعلان (هر دو جهت | Buy: Zone↓+Trend↓ | Sell: Zone↑+Trend↑) | Alert on KILLER
input bool   Alert_OnMktPhase        = false;  // 🌍 Mkt Phase اعلان (زرد=Neutral، قرمز=Trend) | Alert on Market Phase change
input bool   Alert_OnSpike           = true;   // ⚡ Spike Detector اعلان قرمز | Alert on Spike (multi-TF sudden move)
input bool   Alert_OnSpikeFlowRed    = false;  // ⚡🌊 اعلان مستقل وقتی Spike و FLOW همزمان قرمز شدن | Alert on Spike+FLOW Red together — 🆕 v13.19
input bool   Alert_OnGBPNZDRule      = true;   // 📊 قانون ترید GBPNZD: STOP/CLOSE/RESUME | 3-Level GBPNZD Trading Rule — 🆕 v13.21
// 🆕 v13.48 FIX5: یادآوری تکراری STOP/CLOSE
input bool   Alert_GBPNZDRule_Repeat        = true;  // 🔁 یادآوری تکراری STOP/CLOSE | Repeat reminder while active
input int    Alert_GBPNZDRule_RepeatMinutes = 60;    // ⏱️ فاصله یادآوری STOP (دقیقه، حداقل ۵) | STOP reminder interval — v13.50: 120→60
input int    Alert_CLOSERepeatMinutes       = 30;    // 🆕 v13.50 RULE-04: فاصله یادآوری CLOSE (دقیقه) — حساس‌ترین سطح، تناوب کوتاه‌تر | CLOSE reminder interval
// ─── EMA Cross Alert ─────────────────────────────────────────────
input bool   Alert_OnEMACross        = true;   // 📡 اعلان کراس EMA25/EMA200 در M15 و M30 | EMA Cross Alert
input bool   EMACross_CleanOnly      = true;   // 🕯️ فقط کراس تمیز (بدنه کندل از EMA200 رد شده، نه فقط سایه) | Clean Cross Only
// ─── کنترل تکرار اعلان ───────────────────────────────────────────
// نکته: Cooldown فقط جلوی ارسال مجدد در حالت "هنوز قرمز" را می‌گیرد
// اگر چراغ قرمز→زرد→قرمز شود (edge جدید) پیام ارسال می‌شود حتی زیر Cooldown
input int    Alert_CooldownMinutes   = 60;     // ⏱️ حداقل فاصله بین دو اعلان قرمز (دقیقه) | Cooldown Minutes

//------------------------------------------------------------------------
// ─── Status Query via Telegram | پرسش وضعیت از تلگرام ──────────────
//------------------------------------------------------------------------
input group "════════ 📡 Status Query | پرسش وضعیت ════════"
input bool   StatusQuery_Enable      = true;   // فعال‌سازی پاسخ به «وضعیت» | Enable Status Reply
input int    StatusQuery_PollSeconds = 5;      // هر چند ثانیه Telegram را بررسی کنیم | Poll Interval (s)


enum ENUM_MARKET_REGIME
{
   REGIME_TRENDING,     // Strong Trend - Best for Trading
   REGIME_RANGING,      // Sideways - Avoid Trading
   REGIME_VOLATILE,     // High Volatility - Caution
   REGIME_QUIET         // Low Volatility - Weak Signals
};

enum ENUM_CANDLE_PATTERN
{
   PATTERN_NONE,
   PATTERN_DOJI,             // بی‌طرف: +1 امتیاز در هر دو جهت
   // --- صعودی (فقط برای BUY)
   PATTERN_HAMMER,           // چکش: کف بلند، بدنه بالا
   PATTERN_INVERTED_HAMMER,  // چکش معکوس صعودی: سقف بلند، بدنه پایین (تأیید برگشت صعودی)
   PATTERN_BULLISH_ENGULFING,// اینگالفینگ صعودی
   PATTERN_BULLISH_PINBAR,   // پین‌بار صعودی (دم پایین بلند)
   // --- نزولی (فقط برای SELL)
   PATTERN_SHOOTING_STAR,    // ستاره دنباله‌دار: سقف بلند، بدنه پایین
   PATTERN_BEARISH_ENGULFING,// اینگالفینگ نزولی
   PATTERN_BEARISH_PINBAR    // پین‌بار نزولی (دم بالا بلند)
};

//------------------------------------------------------------------------
// 🆕 STRUCTURES
//------------------------------------------------------------------------
struct MarketRegimeInfo
{
   ENUM_MARKET_REGIME regime;
   double efficiencyRatio;
   double volatilityRatio;
   double hurstExponent;
   string description;
};

struct MTFTrendInfo
{
   bool h1Bullish;
   bool h1Bearish;
   bool h4Bullish;
   bool h4Bearish;
   double h1RSI;
   double h4RSI;
};

//------------------------------------------------------------------------

//| Currency Impact Weight Structure                                 |
//+------------------------------------------------------------------+
struct CurrencyImpact
{
   string symbol;
   double usd, eur, gbp, jpy, chf, aud, cad, nzd;
   double try_weight, mxn, zar, sgd, hkd, nok, sek, dkk, pln, rub, brl;
};

CurrencyImpact g_impactTable[];

//+------------------------------------------------------------------+
//| News Event Structure                                             |
//+------------------------------------------------------------------+
struct NewsEvent
{
   datetime time;
   string   currency;
   string   name;
   int      impact;
   double   actual;
   double   forecast;
   double   previous;
   double   deviation;
   int      direction;
   double   weight;
};

NewsEvent g_newsList[];
int       g_newsCount = 0;

//+------------------------------------------------------------------+
// MYNEWSINDICATOR FUNCTION PROTOTYPES (Forward Declarations)
//+------------------------------------------------------------------+
bool IsCacheValid();
bool LoadCachedNews();
bool DownloadAndSaveNews();

void ParseCSVString(string csv);
double GetCurrencyWeight(string curr);
void AddNews(NewsEvent &news);
void DrawNewsLines(bool force = false);
void InitializeImpactTable();
void SmartLoadNews();

//+------------------------------------------------------------------+
// Get Currency Weight for Symbol
//+------------------------------------------------------------------+
double GetCurrencyWeight(string curr)
{
   string clean_symbol = _Symbol;
   StringReplace(clean_symbol, "_l", "");
   StringReplace(clean_symbol, "_sb", "");
   StringReplace(clean_symbol, ".raw", "");
   StringReplace(clean_symbol, ".", "");
   
   string base  = StringSubstr(clean_symbol, 0, 3);
   string quote = StringSubstr(clean_symbol, 3, 3);
   
   if(curr == base || curr == quote) return 1.0;
   
   if(StringLen(AdditionalCurrencies) > 0)
   {
      string add[];
      int count = StringSplit(AdditionalCurrencies, ',', add);
      for(int j = 0; j < count; j++)
      {
         string trimmed = add[j];
         StringTrimLeft(trimmed);
         StringTrimRight(trimmed);
         StringToUpper(trimmed);
         if(curr == trimmed) return 0.6;
      }
   }
   
   for(int i = 0; i < ArraySize(g_impactTable); i++)
   {
      if(StringFind(clean_symbol, g_impactTable[i].symbol) == 0)
      {
         if(curr == "USD") return g_impactTable[i].usd;
         if(curr == "EUR") return g_impactTable[i].eur;
         if(curr == "GBP") return g_impactTable[i].gbp;
         if(curr == "JPY") return g_impactTable[i].jpy;
         if(curr == "CHF") return g_impactTable[i].chf;
         if(curr == "AUD") return g_impactTable[i].aud;
         if(curr == "CAD") return g_impactTable[i].cad;
         if(curr == "NZD") return g_impactTable[i].nzd;
         if(curr == "TRY") return g_impactTable[i].try_weight;
         if(curr == "MXN") return g_impactTable[i].mxn;
         if(curr == "ZAR") return g_impactTable[i].zar;
         if(curr == "SGD") return g_impactTable[i].sgd;
         if(curr == "HKD") return g_impactTable[i].hkd;
         if(curr == "NOK") return g_impactTable[i].nok;
         if(curr == "SEK") return g_impactTable[i].sek;
         if(curr == "DKK") return g_impactTable[i].dkk;
         if(curr == "PLN") return g_impactTable[i].pln;
         if(curr == "RUB") return g_impactTable[i].rub;
         if(curr == "BRL") return g_impactTable[i].brl;
      }
   }
   return 0.0;
}

//+------------------------------------------------------------------+
// Initialize Impact Table - 54 Currency Pairs + Exotics
//+------------------------------------------------------------------+
void InitializeImpactTable()
{
   ArrayResize(g_impactTable, 53);
   int i = 0;
   
   // === MAJORS ===
   g_impactTable[i].symbol="EURUSD"; g_impactTable[i].usd=0.85; g_impactTable[i].eur=1.00; g_impactTable[i].gbp=0.40; g_impactTable[i].jpy=0.20; i++;
   g_impactTable[i].symbol="GBPUSD"; g_impactTable[i].usd=0.85; g_impactTable[i].gbp=1.00; g_impactTable[i].eur=0.40; g_impactTable[i].jpy=0.20; i++;
   g_impactTable[i].symbol="USDJPY"; g_impactTable[i].usd=1.00; g_impactTable[i].jpy=0.90; g_impactTable[i].eur=0.30; g_impactTable[i].gbp=0.20; i++;
   g_impactTable[i].symbol="USDCHF"; g_impactTable[i].usd=1.00; g_impactTable[i].chf=0.90; g_impactTable[i].eur=0.50; g_impactTable[i].gbp=0.20; i++;
   g_impactTable[i].symbol="AUDUSD"; g_impactTable[i].usd=0.80; g_impactTable[i].aud=1.00; g_impactTable[i].nzd=0.50; g_impactTable[i].cad=0.30; i++;
   g_impactTable[i].symbol="USDCAD"; g_impactTable[i].usd=1.00; g_impactTable[i].cad=1.00; g_impactTable[i].aud=0.30; g_impactTable[i].eur=0.20; i++;
   g_impactTable[i].symbol="NZDUSD"; g_impactTable[i].usd=0.80; g_impactTable[i].nzd=1.00; g_impactTable[i].aud=0.50; g_impactTable[i].gbp=0.20; i++;
   
   // === EUR CROSSES ===
   g_impactTable[i].symbol="EURGBP"; g_impactTable[i].eur=1.00; g_impactTable[i].gbp=1.00; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="EURJPY"; g_impactTable[i].eur=1.00; g_impactTable[i].jpy=0.90; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="EURCHF"; g_impactTable[i].eur=1.00; g_impactTable[i].chf=0.90; g_impactTable[i].usd=0.40; i++;
   g_impactTable[i].symbol="EURAUD"; g_impactTable[i].eur=1.00; g_impactTable[i].aud=1.00; g_impactTable[i].nzd=0.40; i++;
   g_impactTable[i].symbol="EURCAD"; g_impactTable[i].eur=1.00; g_impactTable[i].cad=1.00; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="EURNZD"; g_impactTable[i].eur=1.00; g_impactTable[i].nzd=1.00; g_impactTable[i].aud=0.40; i++;
   
   // === GBP CROSSES ===
   g_impactTable[i].symbol="GBPJPY"; g_impactTable[i].gbp=1.00; g_impactTable[i].jpy=0.90; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="GBPCHF"; g_impactTable[i].gbp=1.00; g_impactTable[i].chf=0.90; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="GBPAUD"; g_impactTable[i].gbp=1.00; g_impactTable[i].aud=1.00; g_impactTable[i].eur=0.30; i++;
   g_impactTable[i].symbol="GBPCAD"; g_impactTable[i].gbp=1.00; g_impactTable[i].cad=1.00; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="GBPNZD"; g_impactTable[i].gbp=1.00; g_impactTable[i].nzd=1.00; g_impactTable[i].aud=0.40; i++;
   
   // === AUD/NZD CROSSES ===
   g_impactTable[i].symbol="AUDJPY"; g_impactTable[i].aud=1.00; g_impactTable[i].jpy=0.90; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="AUDCHF"; g_impactTable[i].aud=1.00; g_impactTable[i].chf=0.90; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="AUDCAD"; g_impactTable[i].aud=1.00; g_impactTable[i].cad=1.00; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="AUDNZD"; g_impactTable[i].aud=1.00; g_impactTable[i].nzd=1.00; g_impactTable[i].usd=0.20; i++;
   g_impactTable[i].symbol="NZDJPY"; g_impactTable[i].nzd=1.00; g_impactTable[i].jpy=0.90; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="NZDCHF"; g_impactTable[i].nzd=1.00; g_impactTable[i].chf=0.90; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="NZDCAD"; g_impactTable[i].nzd=1.00; g_impactTable[i].cad=1.00; g_impactTable[i].usd=0.30; i++;
   
   // === CAD/CHF/JPY CROSSES ===
   g_impactTable[i].symbol="CADJPY"; g_impactTable[i].cad=1.00; g_impactTable[i].jpy=0.90; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="CADCHF"; g_impactTable[i].cad=1.00; g_impactTable[i].chf=0.90; g_impactTable[i].usd=0.30; i++;
   g_impactTable[i].symbol="CHFJPY"; g_impactTable[i].chf=1.00; g_impactTable[i].jpy=0.90; g_impactTable[i].usd=0.30; i++;
   
   // === EXOTICS - TRY (Turkish Lira) ===
   g_impactTable[i].symbol="USDTRY"; g_impactTable[i].usd=1.00; g_impactTable[i].try_weight=1.00; g_impactTable[i].eur=0.50; i++;
   g_impactTable[i].symbol="EURTRY"; g_impactTable[i].eur=1.00; g_impactTable[i].try_weight=1.00; g_impactTable[i].usd=0.40; i++;
   
   // === EXOTICS - MXN (Mexican Peso) ===
   g_impactTable[i].symbol="USDMXN"; g_impactTable[i].usd=1.00; g_impactTable[i].mxn=1.00; g_impactTable[i].cad=0.40; i++;
   
   // === EXOTICS - ZAR (South African Rand) ===
   g_impactTable[i].symbol="USDZAR"; g_impactTable[i].usd=1.00; g_impactTable[i].zar=1.00; g_impactTable[i].eur=0.30; i++;
   g_impactTable[i].symbol="EURZAR"; g_impactTable[i].eur=1.00; g_impactTable[i].zar=1.00; g_impactTable[i].usd=0.40; i++;
   
   // === EXOTICS - SGD (Singapore Dollar) ===
   g_impactTable[i].symbol="USDSGD"; g_impactTable[i].usd=1.00; g_impactTable[i].sgd=1.00; g_impactTable[i].jpy=0.40; i++;
   g_impactTable[i].symbol="EURSGD"; g_impactTable[i].eur=1.00; g_impactTable[i].sgd=1.00; g_impactTable[i].usd=0.30; i++;
   
   // === EXOTICS - HKD (Hong Kong Dollar) ===
   g_impactTable[i].symbol="USDHKD"; g_impactTable[i].usd=1.00; g_impactTable[i].hkd=1.00; g_impactTable[i].jpy=0.30; i++;
   
   // === SCANDINAVIAN - NOK (Norwegian Krone) ===
   g_impactTable[i].symbol="USDNOK"; g_impactTable[i].usd=1.00; g_impactTable[i].nok=1.00; g_impactTable[i].eur=0.60; i++;
   g_impactTable[i].symbol="EURNOK"; g_impactTable[i].eur=1.00; g_impactTable[i].nok=1.00; g_impactTable[i].sek=0.50; i++;
   g_impactTable[i].symbol="GBPNOK"; g_impactTable[i].gbp=1.00; g_impactTable[i].nok=1.00; g_impactTable[i].eur=0.30; i++;
   
   // === SCANDINAVIAN - SEK (Swedish Krona) ===
   g_impactTable[i].symbol="USDSEK"; g_impactTable[i].usd=1.00; g_impactTable[i].sek=1.00; g_impactTable[i].eur=0.60; i++;
   g_impactTable[i].symbol="EURSEK"; g_impactTable[i].eur=1.00; g_impactTable[i].sek=1.00; g_impactTable[i].nok=0.50; i++;
   g_impactTable[i].symbol="GBPSEK"; g_impactTable[i].gbp=1.00; g_impactTable[i].sek=1.00; g_impactTable[i].eur=0.30; i++;
   
   // === SCANDINAVIAN - DKK (Danish Krone) ===
   g_impactTable[i].symbol="USDDKK"; g_impactTable[i].usd=1.00; g_impactTable[i].dkk=1.00; g_impactTable[i].eur=0.80; i++;
   g_impactTable[i].symbol="EURDKK"; g_impactTable[i].eur=1.00; g_impactTable[i].dkk=1.00; g_impactTable[i].sek=0.30; i++;
   
   // === EASTERN EUROPEAN - PLN (Polish Zloty) ===
   g_impactTable[i].symbol="USDPLN"; g_impactTable[i].usd=1.00; g_impactTable[i].pln=1.00; g_impactTable[i].eur=0.70; i++;
   g_impactTable[i].symbol="EURPLN"; g_impactTable[i].eur=1.00; g_impactTable[i].pln=1.00; g_impactTable[i].usd=0.30; i++;
   
   // === EASTERN EUROPEAN - RUB (Russian Ruble) ===
   g_impactTable[i].symbol="USDRUB"; g_impactTable[i].usd=1.00; g_impactTable[i].rub=1.00; g_impactTable[i].eur=0.50; i++;
   g_impactTable[i].symbol="EURRUB"; g_impactTable[i].eur=1.00; g_impactTable[i].rub=1.00; g_impactTable[i].usd=0.40; i++;
   
   // === LATIN AMERICAN - BRL (Brazilian Real) ===
   g_impactTable[i].symbol="USDBRL"; g_impactTable[i].usd=1.00; g_impactTable[i].brl=1.00; g_impactTable[i].cad=0.30; i++;
   g_impactTable[i].symbol="EURBRL"; g_impactTable[i].eur=1.00; g_impactTable[i].brl=1.00; g_impactTable[i].usd=0.40; i++;
   
   // === COMMODITIES ===
   g_impactTable[i].symbol="XAUUSD"; g_impactTable[i].usd=1.00; g_impactTable[i].eur=0.40; g_impactTable[i].jpy=0.30; i++;
   g_impactTable[i].symbol="XAGUSD"; g_impactTable[i].usd=1.00; g_impactTable[i].eur=0.40; i++;
   g_impactTable[i].symbol="XPTUSD"; g_impactTable[i].usd=1.00; g_impactTable[i].eur=0.30; i++;
   
   if(ShowDebugLogs) if(EnableAllLogs) Print("📊 Impact table loaded: ", ArraySize(g_impactTable), " currency pairs");
}

//+------------------------------------------------------------------+
// GLOBAL VARIABLES
//------------------------------------------------------------------------
// Arrow objects drawn as OBJ_ARROW (EA mode - no indicator buffers needed)
// Colors match original indicator colors:
//   BuyWeak=clrLightGreen  BuyMedium=clrLimeGreen  BuyStrong=clrGold
//   SellWeak=clrLightCoral SellMedium=clrRed       SellStrong=clrDarkRed

// ── رنگ اصلی چارت کاربر قبل از اجرا (برای بازگردانی در حذف) ─────────
color g_originalBgColor    = clrBlack;
color g_originalFgColor    = clrWhite;
color g_originalGridColor  = clrDimGray;

// ── وضعیت دکمه‌های MA (false=off, true=on) ───────────────────────────
bool  g_maM15Active  = false;
bool  g_maM30Active  = false;
bool  g_maH1Active   = false;
bool  g_maH4Active   = false;
bool  g_maD1Active   = false;
bool  g_maRetryNeeded = false;   // اگه handle هنوز آماده نبود، retry کن

// ── handle های MA برای تایم‌فریم‌های مختلف ───────────────────────────
int   g_handleMA_M15 = INVALID_HANDLE;
int   g_handleMA_M30 = INVALID_HANDLE;
int   g_handleMA_H1  = INVALID_HANDLE;
int   g_handleMA_H4  = INVALID_HANDLE;
int   g_handleMA_D1  = INVALID_HANDLE;
#define MA_OBJ_PREFIX  "HM_MA_"
#define FEMA_OBJ_PREFIX "HM_FEMA_"   // پیشوند اشیاء FEMA

// handles چهارگانه FEMA (تایم‌فریم جاری)
int g_handleFEMA_25  = INVALID_HANDLE;
int g_handleFEMA_50  = INVALID_HANDLE;
int g_handleFEMA_100 = INVALID_HANDLE;
int g_handleFEMA_200 = INVALID_HANDLE;
bool g_femaActive    = false;          // وضعیت دکمه FEMA

int handleFastMA, handleSlowMA, handleRSI, handleADX, handleBB, handleATR;
int g_handleFractals = INVALID_HANDLE;  // 🆕 v4.0: Fractal handle for Strict S/R filter
int handleH1_EMA, handleH4_EMA, handleH1_RSI, handleH4_RSI;

// CSL trend handles (created once in OnInit, not per-bar)
// FIXED timeframes - same result on M1, M5, M15, M30, H1, etc.
int handleCSL_H1  = INVALID_HANDLE;  // EMA34 روی H1  (وزن ۴) - چند ساعت
int handleCSL_M30 = INVALID_HANDLE;  // EMA34 روی M30 (وزن ۳) - ساعتی
int handleCSL_D1  = INVALID_HANDLE;  // EMA50 روی D1  (وزن ۲) - روزانه
int handleCSL_M5  = INVALID_HANDLE;  // EMA20 روی M5  (وزن ۱) - کوتاه‌مدت
int handleCSL_W1  = INVALID_HANDLE;  // EMA20 روی W1  (وزن ۱) - زمینه کلی

// FIX #6: Time-based signal distance tracking instead of index-based
// Reason: with AsSeries, bar indices shift on each new bar. If connection drops
// and multiple bars load at once, lastBuyBar++ goes out of sync.
// Solution: store the TIME of last signal. Distance = time difference / PeriodSeconds()
datetime lastBuyTime  = 0;   // time of last BUY signal bar
datetime lastSellTime = 0;   // time of last SELL signal bar
int todaySignalCount = 0;

// FIX #5: Pre-cached indicator arrays filled ONCE before the signal loop
// Replaces 9 CopyBuffer calls per bar (= up to 4500 calls for 500 bars)
// Now: 9 calls total per OnCalculate tick
double g_fastMA[];
double g_slowMA[];
double g_rsi[];
double g_adx[];
double g_plusDI[];
double g_minusDI[];
double g_bbUpper[];
double g_bbLower[];
double g_atr[];
// 🆕 v4.0: Fractal cache - filled once per recalc (eliminates per-bar CopyBuffer in Strict mode)
double g_fractalUp[];   // Bill Williams Upper Fractal (resistance)
double g_fractalDn[];   // Bill Williams Lower Fractal (support)
int    g_cacheSize = 0;  // how many bars are cached

MarketRegimeInfo currentRegime;
MTFTrendInfo mtfTrend;

//------------------------------------------------------------------------
// Dashboard Variables
//------------------------------------------------------------------------
string dashboardPrefix = "XSA12_";
// v11.92: scale & font globals used by CreateButton/CreateLabel
double g_dashUserScale  = 1.0;   // = DashboardScalePercent / 100
int    g_dashBtnFontPt  = 8;     // سایز فونت دکمه‌ها — در CreateDashboard مقداردهی می‌شود
double currentTrendStrength = 0;

// Local variables that can be modified by buttons
ENUM_TIMEFRAME_PRESET currentPreset = PRESET_M15;
ENUM_FILTER_MODE currentFilterMode = MODE_BALANCED;
bool localEnableMarketRegime = true;
bool localEnableMTF = true;
bool localEnablePriceAction = true;
// v5.0: localEnableNews (AI filter) حذف شد - جایگزین: S/R Levels button
// News WebRequest (خطوط عمودی روی چارت) دست نخورده باقی می‌ماند
bool localEnableSR       = false;  // 🆕 v5.0: S/R Levels display (on-demand, not auto)
bool localEnableSmartVol = false;   // 🆕 v4.0: Smart Volume Filter (replaces SelfOpt)
bool localEnableIchimoku = false;   // 🆕 v5.1: Ichimoku Cloud Filter (weighted scoring)

// ── ایچیموکو: Handle و کش آرایه‌ها ──
int    handleIchimoku = INVALID_HANDLE;
double g_ichiTenkan[];    // Tenkan-sen (9)
double g_ichiKijun[];     // Kijun-sen (26)
double g_ichiSpanA[];     // Senkou Span A (آینده +26 در buffer MT5)
double g_ichiSpanB[];     // Senkou Span B (آینده +26 در buffer MT5)

// ════════════════════════════════════════════════════════════════════
// 🆕 v7.0 GLOBALS - FVG, LiqSwp, RTM
// ════════════════════════════════════════════════════════════════════
// دکمه‌های ردیف سوم - وضعیت فعال/غیرفعال
bool   localEnableFVG     = false;  // Fair Value Gap filter
bool   localEnableLiqSwp  = false;  // Liquidity Sweep filter
bool   localEnableRTM     = false;  // Return to Mean filter

// Handle برای EMA200 مخصوص RTM (TF جاری)
int    handleRTM_EMA      = INVALID_HANDLE;

// ════════════════════════════════════════════════════════════════════
// 🆕 v7.0: TRAFFIC LIGHTS - handle های ثابت (مستقل از TF جاری)
// ════════════════════════════════════════════════════════════════════
int    handleEMA200_H1_TL = INVALID_HANDLE; // EMA200 روی H1 (RTM چراغ ۱)
int    handleATR_H1_TL    = INVALID_HANDLE; // ATR روی H1  (مرجع فاصله RTM)
int    handleADX_H4_TL    = INVALID_HANDLE; // ADX روی H4  (قدرت روند، چراغ ۲)
int    handleATR_D1_TL    = INVALID_HANDLE; // ATR روی D1  (مرجع Struct، چراغ ۳)
// handleATR_D1_200 حذف شد v10.5 — Zone از گرید مطلق محاسبه می‌شود

// وضعیت چراغ‌ها: -1=خاکستری(بدون پوزیشن) 0=سبز 1=زرد 2=قرمز
int    g_lightRTM    = -1;
int    g_lightTrend  = -1;
int    g_lightStruct = -1;
int    g_lightFLOW   = -1;
int    g_lightGOLDEN = -1;   // داخلی (سازگاری با BT_TrackLightChanges)
const  string LIGHT_OBJ_PREFIX = "HM7_LT_";

// ════════════════════════════════════════════════════════════════════
// 🆕 v12.14: KILLER LIGHT
// ─────────────────────────────────────────────────────────────────
// قانون کلی (هر دو جهت):
//   Regime == Trending روی H1 (تایم‌فریم ثابت، مستقل از چارت)
//   |Trend_Score| >= 50  (روند قوی خلاف جهت پوزیشن)
//   ZoneDelta >= 1       (قیمت حداقل یه Zone در ضرر رفته از زمان ورود)
//   MaxStep >= 4         (پله ۴ یا ۵ فعال — پوزیشن‌های هم‌جهت باز)
//
// برای BUY:  روند نزولی (Trend_Score <= -50) + Zone پایین‌تر از ورود
// برای SELL: روند صعودی (Trend_Score >= +50) + Zone بالاتر از ورود
//
// فقط نوتیف (Telegram + MT5 Push) — داخل داشبورد نمایش ندارد
// ════════════════════════════════════════════════════════════════════
int    g_lightKILLER  = -1;   // -1=خاکستری | 0=سبز | 1=زرد(پله۳) | 2=قرمز(پله۴+)

// ════════════════════════════════════════════════════════════════════
// v10.2: CRISIS LIGHT — پنج حالت (اضافه شد ORANGE)
// منطق کاملاً لحظه‌ای و stateless — هر بار از نو محاسبه می‌شود:
//   🟢 سبز   : هیچ‌کدام از شروط برقرار نیست
//   🟡 زرد   : Y1(RC≥2) | Y2(Flow≤-5+ADX>28)
//              Y3(RC≥2+Flow≤-7+TsAg>30) | Y4(RC≥2+TsAg>45+ADX>25) | Y5(RC≥2+Flow≤-7.5+ADX>35)
//   🟠 نارنجی: CrisisEarly — (RC≥2+Flow≤-6.5+ADX>30) | (RC≥3+TsAg>40+ADX>28)  ← جدید v10.2
//   🔴 قرمز  : Red-A(RC≥3+Flow≤-7+ADX>32) | Red-B(RC≥2+Flow≤-8.5+ADX>40)
// v10.3: RC = RTM+TREND+STRUCT+FLOW (max=4 — ZOMBIE حذف شد)
// ════════════════════════════════════════════════════════════════════
int    g_crisisState   = -1;
const  string CRISIS_OBJ = "HM_CRISIS_LIGHT";

double g_lastAdxVal    = 0.0;
double g_lastErH4      = 0.0;
double g_lastFlowScore = 0.0;
int    g_lastRedCount  = 0;

// ╔═════════════════════════════════════════════════════════════════╗
// 🆕 v10.4: ZOMBIE → Absolute-Grid Zone Classifier
// ╔═════════════════════════════════════════════════════════════════╗
// Zone از یک گرید مطلق per-symbol خوانده می‌شود (نه از قیمت ورود).
// مثال AUDCAD: base_low=0.90450 base_high=0.92450 width=200pip(=0.0200)
//   [0.90450 .. 0.92450)  → Zone 0   (مرکز ≈ 0.91450)
//   [0.92450 .. 0.94450)  → Zone +1
//   [0.88450 .. 0.90450)  → Zone -1
// معیار انتخاب عرض: بر اساس موج‌های چند ساله چارت — قیمت معمولاً ۲۰۰ پیپ
// بالاتر/پایین‌تر حرکت می‌کند تا به طبقه بعدی برسد.
// ─────────────────────────────────────────────────────────────────
struct SymbolZoneCfg
{
   string symbol;
   double base_low;    // قیمت پایین Zone 0
   double base_high;   // قیمت بالای Zone 0 (= base_low + widthPips×0.0001)
   int    widthPips;   // عرض هر طبقه به پیپ استاندارد — 200 × 0.0001 = 0.0200
   bool   supported;
};
// جدول مرجع — هر کاربر می‌تواند بر اساس بک‌تست/مشاهده‌اش گسترش دهد
SymbolZoneCfg g_zoneTable[] =
{
   // widthPips = پیپ استاندارد (GetPipSize=0.0001 برای AUDCAD)
   // عرض واقعی به قیمت = widthPips × 0.0001
   // AUDCAD: widthPips=200 → 200 × 0.0001 = 0.0200 = ۲۰۰ پیپ استاندارد
   // Zone 0 = [0.90450 .. 0.92450)  مرکز ≈ 0.91450
   // symbol   base_low  base_high  widthPips  supported
   // v10.9: base_low اصلاح شد — پوشش کامل 2020-2025 (کف 0.8318 در مارس 2020)
   // Zone 0 = [0.84000 .. 0.86000) | Zone +1 = [0.86000..0.88000) | Zone -1 = [0.82000..0.84000)
   // با عرض 200 پیپ: موج 2 هفته‌ای Xmoon معمولاً 1-2 Zone جابجا می‌شود
   // v11.91: Zone Table — AUDCAD اصلاح + EURCHF / AUDNZD / GBPNZD اضافه شد
   // AUDCAD: Zone 0 = [0.90000 .. 0.92000) | width=200pip
   { "AUDCAD",  0.90000,  0.92000,   200,       true  },
   // EURCHF: Zone 0 = [0.90000 .. 0.92250) | width=225pip (2250 point)
   { "EURCHF",  0.90000,  0.92250,   225,       true  },
   // AUDNZD: Zone 0 = [1.19450 .. 1.22000) | width=255pip (2550 point)
   { "AUDNZD",  1.19450,  1.22000,   255,       true  },
   // GBPNZD: Zone 0 = [2.26500 .. 2.30500) | width=400pip (4000 point)
   { "GBPNZD",  2.26500,  2.30500,   400,       true  },
   // EURGBP: Zone 0 = [0.83000 .. 0.85000) | width=200pip (2000 point)
   // پوشش تاریخی 2020-2025: کف 0.8281 (مارس 2020)، سقف 0.9267 (دسامبر 2020)
   // Zone -4 = [0.75000..0.77000) | Zone +4 = [0.91000..0.93000)
   { "EURGBP",  0.83000,  0.85000,   200,       true  },
};
// forward decl (تعریف کامل در فایل پایین‌تر)
double GetPipSize(string sym);
// پیش‌فرض برای ارز خارج از جدول: supported=false → چراغ خاکستری
// (اگر نیاز به fallback خودکار داشتید، supported=true و base_low/high را تنظیم کنید)
bool   g_zombieSupported     = false;
int    g_lightZOMBIE         = -1;
double g_zombieEntryPrice    = 0.0;
int    g_zombieEntryZone     = 0;    // v10.4: طبقه‌ای که در آن وارد شدیم (ثابت تا بستن پوزیشن)
int    g_zombieCurrentZone   = 0;    // طبقه فعلی قیمت
double g_zombieZoneWidthPips = 0.0;  // عرض طبقه (برای سازگاری/نمایش)

// v10.9: H1 Confirmation Filter — کاملاً Stateless
// هیچ متغیر گلوبالی لازم نیست — Zone_CountH1BarsInZone مستقیماً CopyClose H1 می‌خواند
// هر بار اکسپرت روشن می‌شود یا بکتست اجرا می‌شود از صفر محاسبه می‌کند

// v11.0: Direction Mode — کنترل دکمه‌های Buy/All/Sell
// 0 = All  (پیش‌فرض — جهت از پوزیشن باز خوانده می‌شود)
// 1 = Buy  (همیشه Buy، حتی بدون پوزیشن یا در حالت هج)
// 2 = Sell (همیشه Sell، حتی بدون پوزیشن یا در حالت هج)
int    g_dirMode = 0;

// ════════════════════════════════════════════════════════════════════
// v11.2: NOTIFICATION SYSTEM — ردیابی state قبلی چراغ‌ها
// ════════════════════════════════════════════════════════════════════
int    g_prevAlertRTM      = -1;
int    g_prevAlertTrend    = -1;
int    g_prevAlertStruct   = -1;
int    g_prevAlertFLOW     = -1;
int    g_prevAlertZOMBIE   = -1;
int    g_prevAlertCrisis   = -1;
bool   g_prevAlertHighAlt  = false;
int    g_prevAlertKILLER   = -1;   // 🆕 v12.14

// 🆕 v13.12: MktPhase alert tracking
int      g_prevAlertMKTPHASE      = -1;
datetime g_lastAlertTime_MKTPHASE = 0;

// 🆕 v13.12: Market Phase — فاز بازار بلندمدت
// منطق: ratio = ADR(10روز) / ADR(60روز)
// ratio < 0.95  → سبز  (رنج، مناسب سیستم)
// 0.95–1.25     → زرد  (خنثی)
// ratio > 1.25  → قرمز (ترند انفجاری، خطرناک)
int      g_lightMktPhase          = -1;
double   g_mktPhaseRatio          = 0.0;
double   g_mktPhaseADRfast        = 0.0;
double   g_mktPhaseADRslow        = 0.0;
datetime g_mktPhaseLastChange     = 0;
int      g_mktPhasePrev           = -1;
// 🐛 v13.29 FIX2: cache hit در firstRun → object هنوز ساخته نشده
// این flag باعث می‌شه TL_SetLight در اولین فرصت بعد از ساخت داشبورد دوباره صدا زده بشه
bool     g_mktPhaseNeedRedraw     = false;

// 🆕 v13.14: Spike Detector — حرکت ناگهانی چندتایم‌فریمه
// مستقل از پله Xmoon — فقط روی قیمت کار میکنه، در بکتست هم دیده میشه
int      g_lightSpike             = -1;   // -1=N/A | 0=Normal | 1=Warning | 2=Spike
double   g_spikeScore             = 0.0;
// 🆕 v13.50 FLOW-02: اگه خواهرهای پُروزن resolve نشدن و renormalize (۷۰٪) پوشش
// کافی نداشت، این پرچم true می‌شود — FLOW با پسوند (LC!) روی داشبورد نمایش می‌یابد
bool     g_flowLowConfidence      = false;
double   g_spikeTF[5];                    // امتیاز هر TF: [M15,M30,H1,H4,D1]
datetime g_spikeLastCalc          = 0;
int      g_prevAlertSPIKE         = -1;
datetime g_lastAlertTime_SPIKE    = 0;
bool     g_prevAlertSpikeFlowRed  = false;   // 🆕 v13.19: اعلان مستقل Spike+FLOW قرمز همزمان
datetime g_lastAlertTime_SpikeFlowRed = 0;   // 🆕 v13.19

datetime g_lastAlertTime_RTM     = 0;
datetime g_lastAlertTime_Trend   = 0;
datetime g_lastAlertTime_Struct  = 0;
datetime g_lastAlertTime_FLOW    = 0;
datetime g_lastAlertTime_ZOMBIE  = 0;
datetime g_lastAlertTime_Crisis  = 0;
datetime g_lastAlertTime_HighAlt = 0;
datetime g_lastAlertTime_3Lights = 0;   // v11.2: سه چراغ همزمان
datetime g_lastAlertTime_KILLER  = 0;   // 🆕 v12.14
bool     g_prev3LightsAlert      = false; // آیا قبلاً ۳ چراغ فعال بود

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.21: قانون ترید GBPNZD — state machine سه‌سطحی
// 0=GREEN (عادی) | 1=STOP (توقف ورود) | 2=CLOSE (بستن اجباری)
// با ری‌استارت EA ریست می‌شه (by design — کاربر خواسته)
// ════════════════════════════════════════════════════════════════════
// 🐛 v13.36 FIX: state machine جداگانه برای Buy و Sell
// قبلاً یک Level/CleanH/CrisisRedH مشترک بود → اگه فقط Sell Spike می‌خورد، Buy Rule هم STOP می‌شد
int      g_gbpnzdLevelBuy      = 0;   // سطح Buy: 0=GREEN | 1=STOP | 2=CLOSE
int      g_gbpnzdLevelSell     = 0;   // سطح Sell: 0=GREEN | 1=STOP | 2=CLOSE
int      g_gbpnzdStopReasonBuy = -1;  // دلیل Buy: 0=StopA 1=StopB 10=CloseA 11=CloseB -1=none
int      g_gbpnzdStopReasonSell= -1;  // دلیل Sell
int      g_gbpnzdCrisisRedHBuy = 0;   // counter Buy: ساعت‌های متوالی Crisis=Red
int      g_gbpnzdCrisisRedHSell= 0;   // counter Sell
int      g_gbpnzdCleanHBuy     = 0;   // counter Buy: ساعت‌های متوالی تمیز (برای RESUME)
int      g_gbpnzdCleanHSell    = 0;   // counter Sell
// متغیر مشترک قدیمی — فقط برای سازگاری با کدهای دیگر (worst-case هر دو)
int      g_gbpnzdLevel      = 0;   // worst-case: MathMax(LevelBuy, LevelSell) — read-only از بیرون
int      g_gbpnzdStopReason = -1;
int      g_gbpnzdCrisisRedH = 0;
int      g_gbpnzdCleanH     = 0;
datetime g_gbpnzdLastH      = 0;   // آخرین ساعت پردازش‌شده برای counter
datetime g_gbpnzdLastReminderH = 0; // آخرین ساعت ارسال یادآوری STOP/CLOSE
// 🆕 v13.48 FIX1: accumulator بدترین حالت ساعت جاری (جایگزین PrevCrisis/PrevSpike)
bool     g_gbpnzdHourRedBuy     = false;  // این ساعت: Crisis=Red دیده شد؟
bool     g_gbpnzdHourDirtyBuy   = false;  // این ساعت: Red یا Spike≥Warning دیده شد؟
bool     g_gbpnzdHourRedSell    = false;
bool     g_gbpnzdHourDirtySell  = false;
bool     g_gbpnzdReplayDone = false; // 🆕 v13.25: true = InitReplay اجرا شده و Rule قابل اعتماده
int      g_gbpnzdReplayRetry= 0;     // 🆕 v13.26: تعداد تلاش‌های retry در OnTimer (max 20)
bool     g_gbpnzdNeedsLiveCheck = false; // 🐛 v13.42: بعد از Replay، یک‌بار با مقادیر live چک بشه
// 🆕 v13.21b: وضعیت مستقل Buy/Sell برای GBPNZD rule — جدا از g_crisisState که به forBuy وابسته‌ست
// در TL_Update هر جهت که اجرا می‌شه مقدار مربوطه آپدیت می‌شه
// Rule همیشه از worst-case هر دو جهت استفاده می‌کنه
int      g_gbnzdCrisisBuy   = -1;  // g_crisisState آخرین محاسبه برای forBuy=true
int      g_gbnzdCrisisSell  = -1;  // g_crisisState آخرین محاسبه برای forBuy=false
int      g_gbnzdSpikeBuy    = -1;  // g_lightSpike آخرین محاسبه برای forBuy=true
int      g_gbnzdSpikeSell   = -1;  // g_lightSpike آخرین محاسبه برای forBuy=false
// 🆕 v13.37: snapshot ساعت قبل — برای counter ساعتی در Alert_CheckGBPNZDRule
// counter باید از وضعیت ساعت گذشته (نه لحظه فعلی) استفاده کنه
int      g_gbpnzdPrevCrisisBuy  = -1;   // Crisis ذخیره‌شده از ساعت آخر پردازش
int      g_gbpnzdPrevSpikeBuy   = -1;
int      g_gbpnzdPrevCrisisSell = -1;
int      g_gbpnzdPrevSpikeSell  = -1;
double   g_gbnzdAdxBuy      = 0.0; // g_lastAdxVal در لحظه محاسبه Buy
double   g_gbnzdFlowBuy     = 0.0; // g_lastFlowScore در لحظه محاسبه Buy
double   g_gbnzdAdxSell     = 0.0;
double   g_gbnzdFlowSell    = 0.0;

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.11: EMA CROSS ALERT — handles و state
// ════════════════════════════════════════════════════════════════════
int      g_handleEMA25_M15  = INVALID_HANDLE;
int      g_handleEMA200_M15 = INVALID_HANDLE;
int      g_handleEMA25_M30  = INVALID_HANDLE;
int      g_handleEMA200_M30 = INVALID_HANDLE;
datetime g_lastEMACrossCheck    = 0;      // آخرین بار چک شد
datetime g_lastAlertTime_EMA_M15 = 0;    // cooldown برای M15
datetime g_lastAlertTime_EMA_M30 = 0;    // cooldown برای M30

// ════════════════════════════════════════════════════════════════════
// STATUS QUERY SYSTEM — پاسخ به پیام «وضعیت» از تلگرام
// ════════════════════════════════════════════════════════════════════
long     g_lastTelegramUpdateId  = 0;    // آخرین update_id پردازش‌شده
uint     g_lastStatusPollTime    = 0;    // زمان آخرین بررسی inbox (GetTickCount — real-time)
bool     g_statusPollBusy        = false; // mutex: جلوگیری از اجرای همزمان دو poll
int      g_statusPollTickCounter = 0;   // شمارنده تیک برای poll

// ════════════════════════════════════════════════════════════════════
// 🆕 v14.00: FOREIGN on-demand — محاسبه لحظه‌ای وضعیت یک سمبل بدون اکسپرت
//
// چرا state machine و نه محاسبه بلاک‌کننده: handle های اندیکاتور
// (iMA/iATR/iADX) تازه‌ساخته‌شده نیاز به چند تیک زمان دارند تا
// BarsCalculated() به مقدار کافی برسد؛ نمی‌شود همان لحظه CopyBuffer زد.
// بنابراین: درخواست → ساخت handle → صبر در OnTimer تا آماده شود →
// محاسبه کامل → ارسال دو پیام (Buy/Sell) → آزادسازی handle → استراحت.
// این یعنی صفر بار CPU دائمی — فقط وقتی واقعاً درخواست شده کار می‌کند.
// ════════════════════════════════════════════════════════════════════
#define OD_STATE_IDLE     0
#define OD_STATE_WARMING  1
int      g_odState        = OD_STATE_IDLE;
string   g_odCleanSymbol  = "";
string   g_odBrokerSymbol = "";
int      g_odHandleEMA200 = INVALID_HANDLE;
int      g_odHandleATR_H1 = INVALID_HANDLE;
int      g_odHandleADX_H4 = INVALID_HANDLE;
int      g_odHandleATR_D1 = INVALID_HANDLE;
int      g_odRetryCount   = 0;
#define  OD_MAX_RETRIES   20   // با تیک 1 ثانیه‌ای OnTimer یعنی حداکثر ~20 ثانیه صبر

// ════════════════════════════════════════════════════════════════════
// 🆕 v14.03: موتور یکپارچه کندل-محور
// Rule/Spike فقط با بسته‌شدن کندل چارت محاسبه می‌شوند — نه هر تیک.
// این واگرایی بکتست/لایو را به صفر می‌رساند چون آستانه‌های Rule
// از بکتست کندل-محور استخراج شده‌اند.
// ════════════════════════════════════════════════════════════════════
int      g_chartPeriodSeconds = 0;   // طول کندل چارت به ثانیه — در OnInit ست می‌شود
datetime g_lastBarCloseTime   = 0;   // زمان آخرین کندلی که Rule/Spike برای آن محاسبه شد
// 🆕 v14.08 BUG-TF1 FIX: آستانه‌های Rule_Transition به کندل (TF-aware) تبدیل شده‌اند
// روی H1: همان 2/6/24 کندل (= 2/6/24 ساعت) — صفر رگرسیون
// روی M1: 120/360/1440 کندل (= 2/6/24 ساعت)
// روی H4: 1/2/6 کندل (= 4/8/24 ساعت — MathMax(1,...) گارانتی)
int      g_ruleStopBars   = 2;   // معادل 2  ساعت — در OnInit با TF scale می‌شود
int      g_ruleCloseBars  = 6;   // معادل 6  ساعت — در OnInit با TF scale می‌شود
int      g_ruleResumeBars = 24;  // معادل 24 ساعت — در OnInit با TF scale می‌شود
bool     g_isNewChartBar      = false; // 🆕 v14.03: آیا کندل چارت تازه بسته شده؟ TL_Update از این برای gate کردن Rule/Spike/Crisis استفاده می‌کند — در پایان OnTick ریست می‌شود

// v10.4: یافتن کانفیگ Zone برای سیمبل — اگر پیدا نشد، supported=false برمی‌گرداند
bool Zone_GetCfg(const string sym, SymbolZoneCfg &out)
{
   // v10.5 FIX: پاک‌سازی پسوند بروکر قبل از جستجو
   string clean = sym;
   StringReplace(clean, ".raw", ""); StringReplace(clean, ".pro", "");
   StringReplace(clean, "_ecn", ""); StringReplace(clean, "_sb",  "");
   StringReplace(clean, "_l",   ""); StringReplace(clean, "_m",   "");
   StringReplace(clean, "_n",   "");
   StringToUpper(clean);
   if(StringLen(clean) > 6) clean = StringSubstr(clean, 0, 6);

   int n = ArraySize(g_zoneTable);
   for(int i = 0; i < n; i++)
   {
      if(g_zoneTable[i].symbol == clean)
      {
         out = g_zoneTable[i];
         return out.supported;
      }
   }
   out.symbol="";  out.base_low=0; out.base_high=0; out.widthPips=0; out.supported=false;
   return false;
}

// v10.4: شماره طبقه قیمت در گرید مطلق — مستقل از نقطه ورود
//   Zone 0 = [base_low, base_high)
//   Zone N = [base_low + N*width, base_low + (N+1)*width)
int Zone_ComputeFromPrice(const string sym, const double price)
{
   SymbolZoneCfg cfg;
   if(!Zone_GetCfg(sym, cfg)) return 0;
   double pipSz = GetPipSize(sym);
   if(pipSz <= 0 || cfg.widthPips <= 0) return 0;
   double w = (double)cfg.widthPips * pipSz;
   if(w <= 0) return 0;
   return (int)MathFloor((price - cfg.base_low) / w);
}

// v10.4: فاصله قیمت تا نزدیک‌ترین مرز طبقه (پیپ مثبت)
double Zone_DistanceToBorderPips(const string sym, const double price)
{
   SymbolZoneCfg cfg;
   if(!Zone_GetCfg(sym, cfg)) return 1e9;
   double pipSz = GetPipSize(sym);
   if(pipSz <= 0 || cfg.widthPips <= 0) return 1e9;
   double w = (double)cfg.widthPips * pipSz;
   double rel = MathMod(price - cfg.base_low, w);
   if(rel < 0) rel += w;
   double dPrice = MathMin(rel, w - rel);
   return dPrice / pipSz;
}

// v10.4: قیمت پایین/بالای یک Zone خاص
double Zone_PriceLow(const string sym, const int zone)
{
   SymbolZoneCfg cfg;
   if(!Zone_GetCfg(sym, cfg)) return 0;
   double pipSz = GetPipSize(sym);
   return cfg.base_low + (double)zone * (double)cfg.widthPips * pipSz;
}

// ╔═════════════════════════════════════════════════════════════════╗
// v10.8: ZOMBIE H1 CONFIRMATION FILTER
// تعداد کندل H1 متوالی که در یک Zone خاص بسته شده‌اند را می‌شمارد
// این stateless است: فقط به داده H1 کندل‌ها نیاز دارد، هیچ حافظه‌ای نمی‌خواهد
// ╔═════════════════════════════════════════════════════════════════╗
int Zone_CountH1BarsInZone(const string sym, const int targetZone, const int maxBars = 5)
{
   int count = 0;
   for(int i = 1; i <= maxBars; i++)  // i=1 → آخرین کندل بسته‌شده H1
   {
      double closeH1[];
      if(CopyClose(sym, PERIOD_H1, i, 1, closeH1) < 1) break;
      int z = Zone_ComputeFromPrice(sym, closeH1[0]);
      if(z == targetZone) count++;
      else break;  // اگر یک کندل خارج از zone بود، زنجیره متوالی قطع است
   }
   return count;
}

// ╔═════════════════════════════════════════════════════════════════╗
// v10.9: Zone_IsConfirmedByH1 — کاملاً Stateless
// هیچ متغیر گلوبالی تغییر نمی‌دهد — هر بار از صفر از CopyClose H1 محاسبه می‌کند
// مناسب برای: بکتست، اکسپرت با پوزیشن‌های متناوب، restart بدون از دست دادن context
//
// منطق:
//   اگر قیمت در Zone ورود یا بهتر → فوری سبز (بدون تأخیر)
//   اگر قیمت در Zone بدتر:
//     شمارش H1 های متوالی که close آن‌ها در currentZone بود
//     اگر count >= ZombieH1ConfirmBars → قرمز تأیید شده
//     در غیر این صورت → زرد (در انتظار)
// ╔═════════════════════════════════════════════════════════════════╗
bool Zone_IsConfirmedByH1(const string sym, const int currentZone, const int entryZone, const bool forBuy, string &statusStr)
{
   // 🔒 DESIGN LOCK (v14.07): همیشه H1 — ZombieH1ConfirmMinutes روی H1 کالیبره شده.
   // ZOMBIE همیشه حداقل ZombieH1ConfirmMinutes تأخیر دارد — صرف نظر از TF چارت.
   // تغییر ندهید حتی اگه TF چارت متفاوت باشد.
   int effDelta = forBuy ? (currentZone - entryZone) : -(currentZone - entryZone);
   
   // اگر قیمت در zone ورود یا بهتر است → فوری سبز، بدون تأیید
   if(effDelta >= 0)
   {
      statusStr = "";
      return true;
   }
   
   // قیمت در zone بدتر است — شمارش کاملاً stateless از CopyClose H1
   int needed  = (ZombieH1ConfirmBars < 1) ? 1 : ZombieH1ConfirmBars;
   int h1count = Zone_CountH1BarsInZone(sym, currentZone, needed + 3);

   // 🆕 v13.50 LIGHT-02: کاهش تأخیر H1 با پارامتر ZombieH1ConfirmMinutes
   // 🟡 مشکل: ZOMBIE باید منتظر بسته شدن کامل کندل H1 می‌ماند — تا ۶۰ دقیقه تأخیر.
   // ✅ راه‌حل: اگر کندل H1 جاری (در حال شکل‌گیری) حداقل ZombieH1ConfirmMinutes
   //   دقیقه از عمرش گذشته باشد و قیمت جاری هم در همان targetZone باشد،
   //   این کندل نیمه‌کامل هم به شمارش اضافه می‌شود (تأیید نیمه‌کامل).
   if(h1count < needed && ZombieH1ConfirmMinutes > 0)
   {
      datetime curBarOpen = iTime(sym, PERIOD_H1, 0);
      if(curBarOpen > 0)
      {
         int ageMin = (int)((TimeCurrent() - curBarOpen) / 60);
         if(ageMin >= ZombieH1ConfirmMinutes)
         {
            double lastClose[];
            if(CopyClose(sym, PERIOD_H1, 0, 1, lastClose) == 1)
            {
               int zNow = Zone_ComputeFromPrice(sym, lastClose[0]);
               if(zNow == currentZone) h1count++;
            }
         }
      }
   }

   bool confirmed = (h1count >= needed);
   
   if(confirmed)
      statusStr = " [✓]";
   else
      statusStr = StringFormat(" [H1:%d/%d]", h1count, needed);
   
   return confirmed;
}

// ╔═════════════════════════════════════════════════════════════════╗
// 🆕 v10.2: PERSISTENCE FILTER — جلوگیری از آلارم‌های لحظه‌ای
// ╔═════════════════════════════════════════════════════════════════╗
// شمارنده چند چک متوالی با همان وضعیت (0=ریست، 1=اول، 2+=پایدار)
int    g_crisisOrangeCount = 0;  // چند چک متوالی Orange یا بالاتر بوده
int    g_crisisRedCount    = 0;  // چند چک متوالی Red بوده (برای نمایش تأکید)
int    g_lastCrisisState   = -1; // آخرین وضعیت CRISIS برای tracking persistence

// ╔═════════════════════════════════════════════════════════════════╗
// v10.3: SHIFT DETECTION حذف شد (جایگزین: Zone Counter در ZOMBIE)
// ╔═════════════════════════════════════════════════════════════════╝

struct HourlySnapshot
{
   datetime snapTime;
   string   direction;
   int      stRTM;
   int      stTrend;
   int      stStruct;
   int      stFLOW;
   int      stZOMBIE;   // v10.4+: 0=سبز | 1=زرد | 2=قرمز | -1=خاکستری
   int      stCRISIS;   // 🆕 v13.16: 0=سبز | 1=زرد | 2=قرمز | 3=نارنجی (Orange-D)
   int      stKILLER;   // 🆕 v12.14: 0=سبز | 1=زرد | 2=قرمز | -1=خاکستری
   int      stMKTPHASE; // 🆕 v13.12: 0=Range | 1=Neutral | 2=Trend | -1=N/A
   double   mktRatio;   // 🆕 v13.12: ADR_fast/ADR_slow
   int      stSPIKE;    // 🆕 v13.14: 0=Normal | 1=Warning | 2=Spike | -1=N/A
   double   spikeScore; // 🆕 v13.14: امتیاز ترکیبی MTF
   double   rtmX;
   string   rtmArrow;
   double   adxVal;
   double   erH4;
   double   flowScore;
   double   trendScore;
   int      zombieZone;  // v10.4+: طبقه مطلق از گرید قیمتی
   string   d1Status;
   string   regime;
   string   session;
   int      spreadPt;
   bool     highAlert;      // v11.8: وضعیت HIGH ALERT (ADX≥40 AND Flow خلاف)
   int      stGBPNZD;    // 🆕 v13.21: 0=Run | 1=Stop | 2=Close | -1=N/A (قانون ترید GBPNZD)
};
HourlySnapshot g_hourlyLog[];
int            g_hourlyCount    = 0;
datetime       g_lastLoggedHour = 0;  // 🐛 v13.47 FIX6: از int→datetime تغییر کرد (timestamp کامل)


// ════════════════════════════════════════════════════════════════════
// 🆕 BACKTEST CSV TRACKING - ردیابی تغییرات چراغ‌ها برای CSV بکتست
// ════════════════════════════════════════════════════════════════════
struct BtLightEvent
{
   datetime startTime;       // زمان شروع قرمز شدن
   datetime endTime;         // زمان پایان (0 = هنوز قرمز)
   int      redCountAtStart; // چند چراغ همزمان قرمز بود (4/3/2/1)
   string   direction;       // BUY یا SELL
   // ── وضعیت چهار چراغ در لحظه رویداد ──────────────────────────
   int      stRTM;           // G=0, Y=1, R=2
   int      stTrend;
   int      stStruct;
   int      stFLOW;
   // ── مقادیر عددی خام چراغ‌ها ──────────────────────────────────
   double   rtmX;            // فاصله از EMA200 بر حسب ATR (e.g. 5.8)
   string   rtmArrow;        // جهت RTM: UP=دور شدن | DN=برگشت | FL=ثابت
   bool     rtmCT;           // Counter-Trend=true | With-Trend=false
   double   adxVal;          // مقدار ADX روی H4
   double   erH4;            // Efficiency Ratio روی H4 (0-1)
   string   erLabel;         // rng=رنج | mod=متوسط | TRD=ترند قوی
   string   d1Status;        // ساختار D1: OK | EDGE | BREAK
   double   d1Pips;          // فاصله پیپ از سطح کلیدی D1 (+ = طرف امن)
   double   flowScore;       // امتیاز جریان ارزهای خواهر
   // ── اطلاعات عمومی بازار در لحظه رویداد ──────────────────────
   double   trendScore;      // امتیاز کلی روند HelpMe (-100 تا +100)
   string   regime;          // رژیم بازار: Trending|Ranging|Volatile|Quiet
   string   session;         // جلسه: Tokyo|London|NewYork|Off
   int      spreadPt;        // اسپرد (point)
   // ── v8.2: CRISIS چراغ نهایی (جایگزین FINAL+GOLDEN) ──────────
   // Green=امن | Yellow=احتیاط | Red=فرار
   string   crisisState;     // "Green" | "Yellow" | "Red"
   string   chartBG;         // رنگ پس‌زمینه: SAFE|ALARM|NEUTRAL|NoPos
   // ── v10.4+: ZOMBIE → Absolute Zone ─────────────────────────────
   int      zombieZone;   // طبقه مطلق از گرید قیمتی
   // zombieWidthPips حذف شد v10.5
};
BtLightEvent g_btEvents[];
int          g_btEventCount = 0;

// آخرین مقادیر متنی چراغ‌ها برای ثبت در CSV
string g_lastRTMVal    = "";
string g_lastTrendVal  = "";
string g_lastStructVal = "";
string g_lastFLOWVal   = "";
// کش داده‌های CSL_Execute برای CSV
double g_csvScore      = 0.0;
string g_csvStatus     = "";
string g_csvRegime     = "?";   // آخرین رژیم بازار برای CSV
string g_csvIchi       = "?";   // آخرین وضعیت ایچیموکو برای CSV
int    g_csvSpread     = 0;     // آخرین اسپرد (point)

// v12.05: کش پیام‌های کامل سیگنال (برای MessageBox بدون محدودیت tooltip)
datetime g_sigMsgTimes[];   // barTime هر سیگنال
string   g_sigMsgTexts[];   // متن کامل tipB


// ════════════════════════════════════════════════════════════════════
// 🆕 v7.0: SISTER PAIRS MATRIX - Currency Strength Flow (FLOW Light)
// تشخیص "نوسان عادی" vs "سونامی/Risk-Off" از طریق ارزهای خواهر
// بدون هیچ handle اضافه‌ای - فقط iClose روی H4 (بسیار lightweight)
// ════════════════════════════════════════════════════════════════════
struct SisterEntry
{
   string   sym;         // نماد خواهر (۶ کاراکتر، بدون پسوند بروکر)
   double   weight;      // وزن پایه این جفت در محاسبه امتیاز
   int      signForBuy;  // +1=صعودی این جفت به نفع Buy ماست  -1=برعکس
   double   negMult;     // ضریب نامتقارن برای جهت مخالف (ریسک‌های کلیدی > 1.0)
};

// ─── AUDCAD: Buy = AUD↑  CAD↓   (حداکثر امتیاز ≈ 8.5) ────────────
// منطق: AUD ارز کالایی/ریسکی، CAD ارز نفتی. هنگام Risk-On هر دو بالا
// می‌روند ولی AUD معمولاً بیشتر. AUDCHF ترموستر Risk-On/Off است.
SisterEntry SISTER_AUDCAD[6] = {
   // pair      wt    sign  negM   توضیح
   {"AUDNZD", 2.0,  +1, 1.00},  // AUD قوی vs NZD = AUD واقعاً قوی (بدون دخالت CAD)
   {"NZDCAD", 1.5,  +1, 1.00},  // بلوک AUD/NZD در برابر CAD: اگه کالایی‌ها > CAD → خوب
   {"AUDCHF", 2.0,  +1, 1.25},  // Risk-On ترموستر: AUD vs پناهگاه CHF (منفی: CHF spike)
   {"GBPCAD", 1.0,  +1, 1.00},  // تأیید ضعف CAD از منظر GBP
   {"GBPJPY", 1.0,  +1, 1.00},  // سنتیمنت: JPY ضعیف = Risk-On = خوب برای AUD
   {"USDCAD", 1.0,  +1, 1.25},  // USDCAD صعودی = CAD ضعیف = خوب برای Buy AUDCAD
   // ⚠️ CADCHF حذف شد (گمراه‌کننده: CADCHF↑ = CAD قوی = بد برای Buy، نه خوب)
};

// ─── EURCHF: Buy = EUR↑  CHF↓   (بازی خالص Risk-On/Off, max ≈ 9.0) ─
// منطق: CHF و JPY دو پناهگاه اصلی هستند و همبستگی بالا دارند.
// Risk-On → هر دو تضعیف می‌شوند → EURCHF و USDJPY همزمان بالا می‌روند.
SisterEntry SISTER_EURCHF[6] = {
   {"USDJPY", 2.0,  +1, 1.25},  // JPY ضعیف = Risk-On (CHF و JPY کاملاً همبسته‌اند)
   {"GBPCHF", 2.0,  +1, 1.00},  // تأیید مستقیم ضعف CHF از منظر GBP
   {"EURUSD", 1.5,  +1, 1.00},  // قدرت مطلق EUR در برابر USD
   {"EURJPY", 1.5,  +1, 1.00},  // EUR قوی + JPY ضعیف = دوتایی تأیید
   {"AUDCHF", 1.0,  +1, 1.00},  // Risk-On: ارز کالایی در برابر CHF
   {"EURGBP", 1.0,  +1, 1.00},  // EUR از GBP قوی‌تر است (تأیید قدرت EUR)
};

// ─── AUDNZD: Buy = AUD↑  NZD↓   (max ≈ 8.0) ──────────────────────
// منطق: هر دو ارز کالایی ریسکی‌اند. AUD به استرالیا/چین وابسته،
// NZD به کشاورزی/لبنیات. AUD معمولاً در چرخه‌های صعودی قوی‌تر است.
SisterEntry SISTER_AUDNZD[6] = {
   {"AUDCAD", 2.0,  +1, 1.00},  // AUD قوی vs ارز کالایی دیگر (تأیید مستقل)
   {"AUDCHF", 1.5,  +1, 1.00},  // قدرت مطلق AUD در برابر پناهگاه
   {"NZDUSD", 1.5,  -1, 1.00},  // ضعف NZD: نزولی NZDUSD = NZD ضعیف = خوب
   {"NZDCAD", 1.0,  -1, 1.00},  // ضعف NZD در برابر ارز کالایی دیگر
   {"GBPNZD", 1.0,  +1, 1.00},  // تأیید ضعف NZD از منظر GBP
   {"USDJPY", 1.0,  +1, 1.00},  // Risk-On: AUD بیشتر از NZD سود می‌برد
};

// ─── GBPNZD: Buy = GBP↑  NZD↓   (GBP نیمه‌امن، NZD ریسکی، max ≈ 8.0) ─
// ⚠️ نکته کلیدی مهم: این جفت از Risk-OFF سود می‌برد (برعکس AUDCAD)!
// Risk-Off → NZD بیشتر از GBP می‌افتد → GBPNZD بالا می‌رود
// 🆕 v13.15: بازطراحی کامل بر اساس تحلیل بکتست BT09 (Jan-Jun 2026)
// تغییرات کلیدی نسبت به نسخه قبل:
//   - GBPCAD/GBPAUD حذف شدند: با GBPUSD همبستگی بالا داشتند → false positive
//   - USDJPY حذف شد: هم GBP هم NZD از آن تأثیر مشابه می‌گیرند → سیگنال خنثی
//   - NZDCAD اضافه شد: منبع مستقل ضعف NZD (غیر از USD)
//   - EURGBP اضافه شد: تأیید مستقل قدرت GBP بدون دخالت ریسک
//   - GBPCHF اضافه شد: سنجنده بهتر Risk-Off (GBP vs پناهگاه واقعی)
//   - وزن NZD ضعف افزایش یافت (4.5) چون اسپایک‌های GBPNZD عموماً NZD-driven بودند
SisterEntry SISTER_GBPNZD[6] = {
   // pair      wt    sign  negM   توضیح
   {"NZDUSD", 2.0,  -1, 1.50},  // ⭐ NZD ضعف مطلق — مستقیم‌ترین و قوی‌ترین سیگنال
   {"GBPUSD", 1.5,  +1, 1.00},  // ⭐ GBP قدرت مطلق — مستقیم‌ترین
   {"NZDCAD", 1.5,  -1, 1.25},  // NZD ضعف vs ارز کالایی مستقل (نه USD)
   {"EURGBP", 1.0,  -1, 1.00},  // GBP قوی‌تر از EUR (نزولی=GBP>EUR=خوب) — تأیید مستقل GBP
   {"AUDNZD", 1.0,  +1, 1.00},  // NZD ضعف در بلوک کالایی — مستقل از USD
   {"GBPCHF", 1.0,  +1, 1.25},  // GBP vs پناهگاه — Risk-Off سنجنده درست‌تر از USDJPY
};

// ═══════════════════════════════════════════════════════════════════
// ماتریس‌های آینده‌نگر - پوشش کامل جفت‌ارزهای اصلی برای Xmoon
// هر ماتریس مستقل است؛ تنها یکی بر اساس _Symbol فراخوانی می‌شود
// ═══════════════════════════════════════════════════════════════════

// ─── EURUSD: Buy = EUR↑ USD↓  (max ≈ 8.0) ────────────────────────
// EUR ارز نیمه‌ریسکی، USD پناهگاه اصلی. USD ضعیف = خوب برای Buy.
SisterEntry SISTER_EURUSD[6] = {
   {"GBPUSD", 1.5,  +1, 1.00},  // USD ضعیف از منظر GBP (تأیید بدون EUR)
   {"EURGBP", 1.5,  +1, 1.00},  // EUR قوی‌تر از GBP (قدرت خالص EUR)
   {"USDCHF", 1.5,  -1, 1.25},  // USD قوی vs CHF (نزولی=USD ضعیف=خوب، ریسک بالا)
   {"USDJPY", 1.5,  -1, 1.25},  // USD قوی vs JPY (نزولی=USD ضعیف=خوب)
   {"AUDUSD", 1.0,  +1, 1.00},  // Risk-On / USD ضعیف از منظر کالایی
   {"EURJPY", 1.0,  +1, 1.00},  // EUR قوی + JPY ضعیف (تأیید دوگانه)
};

// ─── EURGBP: Buy = EUR↑ GBP↓  (max ≈ 9.0) ────────────────────────
// هر دو ارز اروپایی. حرکت توسط واگرایی سیاست پولی ECB/BoE هدایت می‌شود.
SisterEntry SISTER_EURGBP[6] = {
   {"EURUSD", 2.0,  +1, 1.00},  // قدرت مطلق EUR (مستقیم‌ترین)
   {"GBPUSD", 2.0,  -1, 1.00},  // ضعف مطلق GBP (نزولی=GBP ضعیف=خوب)
   {"EURJPY", 1.5,  +1, 1.00},  // EUR قوی در بستر ریسک
   {"GBPJPY", 1.5,  -1, 1.00},  // GBP ضعیف (نزولی=GBP ضعیف=خوب)
   {"EURCHF", 1.0,  +1, 1.00},  // تقاضای EUR در برابر پناهگاه
   {"GBPAUD", 1.0,  -1, 1.00},  // GBP ضعیف vs ارز ریسکی (نزولی=خوب)
};

// ─── GBPUSD: Buy = GBP↑ USD↓  (max ≈ 9.0) ────────────────────────
// GBP نیمه‌ریسکی، USD پناهگاه. Risk-On + GBP سیاست پولی BoE.
SisterEntry SISTER_GBPUSD[6] = {
   {"EURUSD", 1.5,  +1, 1.00},  // USD ضعیف از منظر EUR
   {"EURGBP", 2.0,  -1, 1.00},  // GBP قوی (نزولی EURGBP = GBP>EUR = خوب)
   {"USDJPY", 1.5,  -1, 1.25},  // USD ضعیف vs JPY (نزولی=خوب، ریسک بالا)
   {"USDCHF", 1.5,  -1, 1.25},  // USD ضعیف vs CHF (نزولی=خوب، ریسک بالا)
   {"GBPJPY", 1.5,  +1, 1.00},  // GBP قوی در برابر JPY
   {"GBPAUD", 1.0,  +1, 1.00},  // GBP قوی در برابر ارز کالایی
};

// ─── USDJPY: Buy = USD↑ JPY↓  (خالص Risk-On، max ≈ 9.0) ─────────
// ⚠️ نکته: این جفت‌ارز بسیار پرروند است. Xmoon فقط در رنج از آن سود می‌برد.
// JPY پناهگاه اصلی در Risk-Off. صعود = Risk-On / JPY ضعیف.
SisterEntry SISTER_USDJPY[6] = {
   {"AUDJPY", 2.0,  +1, 1.25},  // JPY ضعیف + Risk-On قوی (ریسک نامتقارن)
   {"EURJPY", 1.5,  +1, 1.00},  // JPY ضعیف از منظر EUR
   {"GBPJPY", 1.5,  +1, 1.00},  // JPY ضعیف از منظر GBP
   {"USDCHF", 1.5,  +1, 1.00},  // USD قوی + CHF ضعیف (هر دو پناهگاه تضعیف)
   {"AUDUSD", 1.5,  +1, 1.00},  // Risk-On sentiment
   {"NZDJPY", 1.0,  +1, 1.00},  // JPY ضعیف از منظر NZD
};

// ─── USDCAD: Buy = USD↑ CAD↓  (USD قوی، CAD نفتی ضعیف، max ≈ 8.0) ─
// CAD به قیمت نفت و Risk-On حساس. USD قوی + نفت ضعیف = USDCAD صعودی.
SisterEntry SISTER_USDCAD[6] = {
   {"USDJPY", 1.5,  +1, 1.00},  // USD قوی broad
   {"USDCHF", 1.5,  +1, 1.00},  // USD قوی broad (تأیید دوم)
   {"AUDUSD", 1.5,  -1, 1.00},  // USD قوی (نزولی AUD=USD قوی=خوب)
   {"CADJPY", 1.5,  -1, 1.25},  // CAD ضعیف (نزولی=CAD ضعیف=خوب، ریسک بالا)
   {"AUDCAD", 1.0,  +1, 1.00},  // CAD ضعیف از منظر AUD کالایی
   {"NZDCAD", 1.0,  +1, 1.00},  // CAD ضعیف از منظر NZD کالایی
};

// ─── AUDUSD: Buy = AUD↑ USD↓  (Risk-On کلاسیک، max ≈ 9.0) ───────
// AUD کالایی ریسکی، USD پناهگاه. یکی از بهترین جفت‌ها برای Xmoon.
SisterEntry SISTER_AUDUSD[6] = {
   {"NZDUSD", 2.0,  +1, 1.00},  // بلوک AUD/NZD vs USD (تأیید قوی)
   {"AUDCHF", 1.5,  +1, 1.25},  // Risk-On ترموستر اصلی (ریسک نامتقارن)
   {"AUDNZD", 1.5,  +1, 1.00},  // AUD مشخصاً قوی در بلوک کالایی
   {"USDCAD", 1.5,  -1, 1.00},  // USD ضعیف (نزولی=USD ضعیف=خوب)
   {"USDJPY", 1.5,  -1, 1.25},  // USD ضعیف vs JPY (نزولی=خوب، ریسک بالا)
   {"AUDCAD", 1.0,  +1, 1.00},  // AUD قوی در برابر ارز کالایی هم‌گروه
};

// ─── NZDUSD: Buy = NZD↑ USD↓  (کالایی ریسکی، max ≈ 9.0) ─────────
// مشابه AUDUSD ولی NZD به لبنیات/کشاورزی وابسته. رنج‌زننده‌تر از AUD.
SisterEntry SISTER_NZDUSD[6] = {
   {"AUDUSD", 2.0,  +1, 1.00},  // بلوک کالایی/ریسکی vs USD
   {"AUDNZD", 1.5,  -1, 1.00},  // NZD مشخصاً قوی (نزولی=NZD>AUD=خوب)
   {"NZDCAD", 1.5,  +1, 1.00},  // NZD قوی در برابر ارز کالایی هم‌گروه
   {"USDJPY", 1.5,  -1, 1.25},  // USD ضعیف (نزولی=خوب، ریسک بالا)
   {"NZDJPY", 1.5,  +1, 1.00},  // NZD قوی vs JPY (مستقیم)
   {"USDCAD", 1.0,  -1, 1.00},  // USD ضعیف (نزولی=خوب)
};

// ─── USDCHF: Buy = USD↑ CHF↓  (max ≈ 8.5) ────────────────────────
// هر دو پناهگاه ولی CHF اروپایی. Risk-On → CHF بیشتر از USD ضعیف می‌شود.
SisterEntry SISTER_USDCHF[6] = {
   {"EURCHF", 2.0,  +1, 1.00},  // CHF ضعیف از منظر EUR (قوی‌ترین سیگنال)
   {"GBPCHF", 1.5,  +1, 1.00},  // CHF ضعیف از منظر GBP
   {"USDJPY", 1.5,  +1, 1.00},  // USD قوی broad
   {"EURUSD", 1.5,  -1, 1.00},  // USD قوی (نزولی EURUSD=USD قوی=خوب)
   {"AUDCHF", 1.0,  +1, 1.00},  // CHF ضعیف از طریق Risk-On
   {"USDCAD", 1.0,  +1, 1.00},  // USD قوی (تأیید broad)
};

// ─── CADJPY: Buy = CAD↑ JPY↓  (نفت+Risk-On، max ≈ 8.5) ──────────
// CAD نفتی، JPY پناهگاه. Risk-On + نفت قوی = CAD از JPY پیشی می‌گیرد.
SisterEntry SISTER_CADJPY[6] = {
   {"USDJPY", 2.0,  +1, 1.25},  // JPY ضعیف (اصلی‌ترین محرک، ریسک نامتقارن)
   {"AUDJPY", 1.5,  +1, 1.00},  // Risk-On + JPY ضعیف (تأیید کالایی)
   {"USDCAD", 1.5,  -1, 1.00},  // CAD قوی (نزولی USDCAD=CAD قوی=خوب)
   {"EURJPY", 1.5,  +1, 1.00},  // JPY ضعیف از منظر EUR
   {"GBPJPY", 1.0,  +1, 1.00},  // JPY ضعیف از منظر GBP
   {"AUDCAD", 1.0,  -1, 1.00},  // CAD قوی نسبی (نزولی=CAD>AUD=خوب)
};

// ─── GBPAUD: Buy = GBP↑ AUD↓  (Risk-Off به GBP کمک می‌کند، max ≈ 8.5) ─
// GBP نیمه‌امن، AUD ریسکی. Risk-Off → AUD بیشتر از GBP می‌افتد.
SisterEntry SISTER_GBPAUD[6] = {
   {"GBPUSD", 2.0,  +1, 1.00},  // GBP قوی مطلق (مستقیم‌ترین)
   {"AUDCHF", 1.5,  -1, 1.25},  // AUD ضعیف + Risk-Off (نزولی=خوب، ریسک بالا)
   {"AUDUSD", 1.5,  -1, 1.00},  // AUD ضعیف مطلق (نزولی=خوب)
   {"GBPJPY", 1.5,  +1, 1.00},  // GBP قوی در برابر پناهگاه JPY
   {"EURGBP", 1.0,  -1, 1.00},  // GBP قوی‌تر از EUR (نزولی=خوب)
   {"AUDCAD", 1.0,  -1, 1.00},  // AUD ضعیف vs هم‌گروه (نزولی=AUD ضعیف=خوب)
};

// ─── EURAUD: Buy = EUR↑ AUD↓  (دفاعی vs ریسکی، max ≈ 8.5) ───────
// EUR نیمه‌دفاعی، AUD ریسکی. Risk-Off → AUD بیشتر می‌افتد.
SisterEntry SISTER_EURAUD[6] = {
   {"EURUSD", 2.0,  +1, 1.00},  // EUR قوی مطلق
   {"AUDCHF", 1.5,  -1, 1.25},  // AUD ضعیف + Risk-Off (نزولی=خوب، ریسک بالا)
   {"AUDUSD", 1.5,  -1, 1.00},  // AUD ضعیف مطلق (نزولی=خوب)
   {"EURJPY", 1.5,  +1, 1.00},  // EUR قوی در بستر ریسک
   {"EURGBP", 1.0,  +1, 1.00},  // EUR قوی نسبت به همتایان اروپایی
   {"GBPAUD", 1.0,  +1, 1.00},  // AUD ضعیف از منظر GBP (صعودی=AUD ضعیف=خوب)
};

// ─── NZDCAD: Buy = NZD↑ CAD↓  (رنج‌زننده - کاندید Xmoon، max ≈ 8.5) ─
// هر دو کالایی ولی NZD به لبنیات و CAD به نفت وابسته. رنج خوبی دارد.
SisterEntry SISTER_NZDCAD[6] = {
   {"AUDCAD", 2.0,  +1, 1.00},  // بلوک AUD/NZD vs CAD (حرکت موازی قوی)
   {"NZDUSD", 1.5,  +1, 1.00},  // NZD قوی مطلق
   {"AUDNZD", 1.5,  -1, 1.00},  // NZD مشخصاً قوی (نزولی=NZD>AUD=خوب)
   {"AUDCHF", 1.5,  +1, 1.00},  // Risk-On: کالایی vs پناهگاه
   {"USDCAD", 1.0,  +1, 1.25},  // CAD ضعیف (صعودی=CAD ضعیف=خوب، ریسک بالا)
   {"GBPJPY", 1.0,  +1, 1.00},  // سنتیمنت Risk-On
};

// ─── GBPCAD: Buy = GBP↑ CAD↓  (کاندید رنج Xmoon، max ≈ 8.0) ─────
// GBP نیمه‌ریسکی، CAD نفتی. واگرایی بین BoE و BoC محرک اصلی.
SisterEntry SISTER_GBPCAD[6] = {
   {"GBPUSD", 1.5,  +1, 1.00},  // GBP قوی مطلق
   {"EURGBP", 1.5,  -1, 1.00},  // GBP قوی‌تر از EUR (نزولی=خوب)
   {"USDCAD", 1.5,  +1, 1.25},  // CAD ضعیف (صعودی=CAD ضعیف=خوب، ریسک بالا)
   {"GBPJPY", 1.5,  +1, 1.00},  // GBP قوی در برابر پناهگاه
   {"AUDCAD", 1.0,  +1, 1.00},  // CAD ضعیف از منظر کالایی AUD
   {"GBPAUD", 1.0,  +1, 1.00},  // GBP قوی در برابر ریسکی AUD
};

// ─── AUDJPY: Buy = AUD↑ JPY↓  (خالص Risk-On، max ≈ 9.0) ─────────
// یکی از بهترین سنجنده‌های Risk-On/Off. AUD ریسکی، JPY پناهگاه.
SisterEntry SISTER_AUDJPY[6] = {
   {"USDJPY", 2.0,  +1, 1.25},  // JPY ضعیف (اصلی‌ترین محرک، ریسک بالا)
   {"EURJPY", 1.5,  +1, 1.00},  // JPY ضعیف از منظر EUR
   {"AUDUSD", 1.5,  +1, 1.00},  // AUD قوی مطلق
   {"NZDJPY", 1.5,  +1, 1.00},  // JPY ضعیف از منظر NZD (هم‌گروه AUD)
   {"AUDCHF", 1.0,  +1, 1.25},  // Risk-On ترموستر (AUD vs CHF، ریسک بالا)
   {"AUDNZD", 1.0,  +1, 1.00},  // AUD مشخصاً قوی در بلوک کالایی
};

// ─── GBPJPY: Buy = GBP↑ JPY↓  (پرنوسان، max ≈ 9.0) ─────────────
// معروف به "widow maker". هم GBP قوی هم JPY ضعیف باید همزمان باشد.
SisterEntry SISTER_GBPJPY[6] = {
   {"USDJPY", 2.0,  +1, 1.25},  // JPY ضعیف (اصلی‌ترین، ریسک بالا)
   {"AUDJPY", 1.5,  +1, 1.00},  // Risk-On + JPY ضعیف (تأیید کالایی)
   {"GBPUSD", 1.5,  +1, 1.00},  // GBP قوی مطلق
   {"EURJPY", 1.5,  +1, 1.00},  // JPY ضعیف از منظر EUR
   {"EURGBP", 1.0,  -1, 1.00},  // GBP قوی‌تر از EUR (نزولی=خوب)
   {"GBPAUD", 1.0,  +1, 1.00},  // GBP قوی در برابر ریسکی
};

// کش آرایه‌های OHLC برای FVG و LiqSwp
// (یکبار قبل از حلقه پر می‌شوند - بدون overhead per-bar)
double g_highCache[];   // High cache برای FVG/LiqSwp
double g_lowCache[];    // Low cache
double g_closeCache[];  // Close cache برای LiqSwp snap-back check
long   g_volCache[];    // Tick volume cache برای VolPro scoring
double g_rtmEMA[];      // EMA200 cache برای RTM distance calculation
// ════════════════════════════════════════════════════════════════════

// 🆕 v5.0: S/R Lines prefix - for fast bulk deletion
const string SR_OBJ_PREFIX = "XSA_SR_";

// ════════════════════════════════════════════════════════════
// 💧 LIQUID LEVEL - global variables
// ════════════════════════════════════════════════════════════
bool         g_liquidActive     = false;   // وضعیت دکمه Liquid Level
int          g_prevSymPosCount  = -1;      // تعداد پوزیشن‌های قبلی این نماد
int          g_otherPosCount_lq = 0;       // پوزیشن روی نمادهای دیگر
const string LQ_OBJ_PREFIX      = "HM_LQ_"; // پیشوند اشیاء خط لیکوئید
// ── حالت دکمه Liquid ──────────────────────────────────────
// 0 = خاموش (طلایی)  1 = بدون پوزیشن (قرمز)
// 2 = موفق/خط رسم شد (سبز)  3 = شکست (قرمز، خط رسم نشد)
int          g_liquidBtnState   = 0;

// Local parameters that can be modified
double localMinBodyToATRRatio = 0.3;
int    localRequiredScore   = 4;   // 🆕 v5.0: امتیاز حداقل - با هر مد فیلتر تغییر می‌کند
double localMinEfficiencyRatio = 0.20;
double localMinBodyToTotalRatio = 0.3;
int localMinBarsBetweenSignals = 15;
double localArrowOffsetPips = 5.0;  // auto-adjusted by preset

// GMT Offset
int BrokerGMTOffset = 0;

// Recalculation flag
// v4.0: recalcNeeded removed - ForceRecalculation now calls RunSignalLoop directly
int g_ratesTotal     = 0;  // Updated each OnTick
int g_maxHistoryBars = 500; // 📊 تعداد واقعی کندل تاریخچه ← از HistoryBarsPercent محاسبه می‌شود
int g_prevCalculated = 0;  // EA equivalent of prev_calculated in OnCalculate
ENUM_TIMEFRAMES g_lastChartPeriod = PERIOD_CURRENT;  // تشخیص تغییر تایم‌فریم



//+------------------------------------------------------------------+
//| Global Cache Variables                                           |
//+------------------------------------------------------------------+
datetime g_lastUpdate = 0;

//+------------------------------------------------------------------+
//| File Paths                                                       |
//+------------------------------------------------------------------+
// New Bar Detection for CSL optimization
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
// CPU OPTIMIZATION GLOBALS
//+------------------------------------------------------------------+
bool     g_forceUpdateDashboard = false;   // Force dashboard update after button click
// 🔧 FIX v5.0: جلوگیری از re-entrant event (MT5 bug: ChartRedraw داخل OnChartEvent دوباره event می‌زنه)
bool     g_processingChartEvent  = false;
uint     g_processingChartEventSince = 0;  // v11.94 FIX: uint (نه datetime) چون GetTickCount() مقدار uint برمی‌گرداند
// 🆕 v11.7: هنگام Remove، هیچ رویداد/تیک/تایمری نباید لیبل‌ها را دوباره بسازد
bool     g_isDeinitializing      = false;
// 🆕 v7.0: جلوگیری از اجرای هم‌زمان ForceRecalculation (کلیک‌های تند + پینگ بالا)
bool     g_recalcBusy            = false;
uint     g_recalcBusySince          = 0;    // v11.94 FIX: uint (نه datetime) چون GetTickCount() مقدار uint برمی‌گرداند
bool     g_minimalMode           = false; // 🧹 دکمه Minimal: فلش‌ها + خطوط خبری پنهان
datetime g_lastSRClickTime       = 0;      // debounce: S/R دو کلیک تند پشت سر هم رو نادیده بگیر
// 🔧 FIX v7.2: debounce برای همه دکمه‌های AI/Filter (نه فقط S/R)
datetime g_lastAIBtnClickTime    = 0;      // debounce: کلیک‌های تند دکمه‌های AI/Filter را رد کن
// 🔧 FIX v7.2: وضعیت EA برای نمایش در داشبورد (OK / Busy / Error)
string   g_eaStatus              = "✅ آماده";
double   g_cachedER             = 0.0;     // Cached Efficiency Ratio (updated per bar)
string GetCacheFilePath()
{
   return "MyNewsCache.csv";
}

string GetTimestampFilePath()
{
   return "MyNewsTimestamp.txt";
}

// 🔑 کلید GlobalVariable برای تشخیص اولین بارگذاری در این نشست MT5
// GlobalVariableها با ری‌استارت MT5 پاک می‌شن → هر بار MT5 باز میشه fresh download
string GetNewsSessionKey()
{
   return "HelpMe_NewsLoadedAt";
}

//+------------------------------------------------------------------+
//| Fallback CSV URLs (3 mirrors)                                    |
//+------------------------------------------------------------------+
const string URL_PRIMARY   = "https://nfs.faireconomy.media/ff_calendar_thisweek.csv";
const string URL_BACKUP1   = "https://cdn.forexfactory.com/ff_calendar_thisweek.csv";
const string URL_BACKUP2   = "https://www.forexfactory.com/ff_calendar_thisweek.csv";

//+------------------------------------------------------------------+
//| Embedded Fallback CSV (Last Resort)                              |

//+------------------------------------------------------------------+
//| DetectCentAccount: تشخیص هوشمند حساب سنت — ۳ لایه اولویت      |
//| ۱) IsCentAccount input (override دستی)                          |
//| ۲) ACCOUNT_CURRENCY — USC / CENT / پسوند C چهارکاراکتری        |
//| ۳) CONTRACT_SIZE ≤ 1000 → Cent  |  > 1000 → Standard/ECN        |
//+------------------------------------------------------------------+
bool DetectCentAccount()
{
   // ── اولویت ۱: تنظیم دستی کاربر ──────────────────────────────────
   if(IsCentAccount) return true;

   // ── اولویت ۲: ارز حساب (USC / CENT / پسوند C) ────────────────────
   // توجه: LiteFinance Cent ارز رو "USD" گزارش میده — این لایه برای بروکرهای دیگه‌ست
   string acctCur = AccountInfoString(ACCOUNT_CURRENCY);
   StringToUpper(acctCur);
   if(StringFind(acctCur, "USC")  >= 0 ||
      StringFind(acctCur, "CENT") >= 0 ||
      (StringLen(acctCur) == 4 &&
       StringGetCharacter(acctCur, StringLen(acctCur)-1) == 'C'))
      return true;

   // ── اولویت ۳: نام سرور بروکر (cent / cen / micro در اسم سرور) ────
   // توجه: LiteFinance Cent سرور هم شاید "cent" نداشته باشه
   string srv = AccountInfoString(ACCOUNT_SERVER);
   StringToLower(srv);
   if(StringFind(srv, "cent") >= 0 || StringFind(srv, "micro") >= 0)
      return true;

   // ── اولویت ۴: Contract Size ≤ 1000 ───────────────────────────────
   // توجه: LiteFinance Cent این رو 100000 گزارش میده — این لایه برای بروکرهای دیگه‌ست
   double cs = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(cs > 0.0 && cs <= 1000.0)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| CSL: Real-time Profit Update Only (called every tick)            |
//| Lightweight: no CopyRates, no trend calc, just P/L display       |
//+------------------------------------------------------------------+
void CSL_UpdateProfitOnly()
{
   long chart_id = ChartID();
   string symbol = _Symbol;
   
   double total_profit_cent = 0.0;
   int buy_count = 0, sell_count = 0;
   
   int total_pos = PositionsTotal();
   for(int i = total_pos - 1; i >= 0; i--)
   {
      if(HM_PositionBelongsToSymbol(PositionGetSymbol(i), symbol))   // 🆕 v13.49 P4
      {
         long type = PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY)  buy_count++;
         if(type == POSITION_TYPE_SELL) sell_count++;
         total_profit_cent += PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   // v7.1: تشخیص هوشمند ۳ لایه‌ای — DetectCentAccount()
   double _profitDivisor = DetectCentAccount() ? 100.0 : 1.0;
   double total_profit_dollar = total_profit_cent / _profitDivisor;
   
   if(buy_count > 0 || sell_count > 0)
   {
      string profit_text = StringFormat("Total P/L: %+.2f $", total_profit_dollar);
      color profit_color = (total_profit_dollar > 0) ? clrLime : 
                           (total_profit_dollar < 0)  ? clrRed : clrWhite;
      
      // Update existing label if present, else create it
      if(ObjectFind(chart_id, "ProfitLabel") >= 0)
      {
         ObjectSetString(chart_id,  "ProfitLabel", OBJPROP_TEXT,  profit_text);
         ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_COLOR, profit_color);
      }
      else
      {
         ObjectCreate(chart_id, "ProfitLabel", OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_CORNER,    CORNER_LEFT_UPPER);
         ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_XDISTANCE, 10);
         ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_YDISTANCE, 20);
         ObjectSetString(chart_id,  "ProfitLabel", OBJPROP_TEXT,      profit_text);
         ObjectSetString(chart_id,  "ProfitLabel", OBJPROP_FONT,      "Arial Bold");
         ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_FONTSIZE,  13);
         ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_COLOR,     profit_color);
         ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_BACK,      false);
         ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_SELECTABLE,false);
      }
      ChartRedraw(chart_id);
   }
   else
   {
      // No open positions – remove profit label if visible
      if(ObjectFind(chart_id, "ProfitLabel") >= 0)
      {
         ObjectDelete(chart_id, "ProfitLabel");
         ChartRedraw(chart_id);
      }
   }

   // 🆕 v7.0: اگه تعداد پوزیشن تغییر کرده → فوری چراغ‌ها رو آپدیت کن
   // (باز شدن/بسته شدن پوزیشن - بدون صبر برای OnTimer 30 ثانیه)
   // 🆕 v14.04 FIX-3: g_isNewChartBar=true تنظیم می‌شود تا runRuleBlock در TL_Update
   // فعال شود. بدون این، Rule/Spike برای جهت جدید پوزیشن تا کندل بعدی stale می‌ماند.
   static int s_prevBuyCnt  = -99;
   static int s_prevSellCnt = -99;
   if(buy_count != s_prevBuyCnt || sell_count != s_prevSellCnt)
   {
      s_prevBuyCnt  = buy_count;
      s_prevSellCnt = sell_count;
      // ✅ PATCH-4 v14.05: g_lastBarCloseTime آپدیت می‌شود تا در اولین تیک بعد
      // از این رویداد، Chart_IsNewBarClosed دوباره true نشود (دوبار اجرای Rule/Spike)
      {
         datetime _latestClosed = iTime(_Symbol, PERIOD_CURRENT, 1);
         if(_latestClosed > 0 && _latestClosed > g_lastBarCloseTime)
            g_lastBarCloseTime = _latestClosed;
      }
      g_isNewChartBar = true;   // 🆕 v14.04 FIX-3: gate باز — Rule/Spike با پوزیشن جدید
      TL_Update();              // فراخوانی فوری - lightweight (فقط CopyBuffer چند handle)
      g_isNewChartBar = false;  // 🆕 v14.04 FIX-3: gate بسته

      // 💧 LIQUID LEVEL: تعداد پوزیشن تغییر کرده → محاسبه مجدد خط لیکوئید
      // (UpdateLiquidationLine خودش بسته شدن همه پوزیشن‌ها رو هندل میکنه)
      if(g_liquidActive)
         UpdateLiquidationLine();
   }
   else if(g_liquidActive && g_otherPosCount_lq == 0 && g_prevSymPosCount != (buy_count + sell_count))
   {
      // تعداد پوزیشن این نماد تغییر کرده (فقط این نماد، بدون نمادهای دیگر)
      UpdateLiquidationLine();
   }
}

//+------------------------------------------------------------------+
//| CSL: محاسبه موقعیت StatusLabel بر اساس DPI                      |
//+------------------------------------------------------------------+
int CSL_GetStatusFontSize()
{
   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   // فونت 12pt در DPI 96. در DPI بالاتر خود لیبل بزرگ‌تر میشه
   // پس فونت رو ثابت نگه میداریم ولی موقعیتش scale میشه
   if(dpi <= 96)  return 11;
   if(dpi <= 120) return 11;
   if(dpi <= 144) return 10;
   return 9;  // 192 DPI
}

int CSL_GetStatusXDist()
{
   // CORNER_RIGHT_UPPER: XDISTANCE = فاصله از لبه راست صفحه
   // متن StatusLabel در DPI بالا پیکسل‌های بیشتری اشغال می‌کند
   // پس در DPI بالا باید xdist بیشتر باشه تا متن از لبه بیرون نزنه
   // فرمول صحیح: baseX × (dpi/96)  ← نه برعکس!
   int dpi   = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   int baseX = 300;   // در 96 DPI (رزولوشن مرجع کاربر)
   return (int)MathRound(baseX * MathMax(dpi, 96) / 96.0);
}

int CSL_GetStatusYDist()
{
   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   return (int)MathRound(15.0 * dpi / 96.0);
}

void CSL_Execute()
{
   if(g_isDeinitializing) return;

   long chart_id = ChartID();
   string symbol = _Symbol;

   // ──────────────────────────────────────────────
   // پوزیشن‌ها + مجموع پروفیت (برای حساب سنت: تقسیم بر 100)
   ENUM_POSITION_TYPE pos_type = -1;
   int buy_count = 0, sell_count = 0;
   double total_profit_cent = 0.0;  // پروفیت در سنت
   double total_profit_dollar = 0.0; // تبدیل به دلار

   int total_pos = PositionsTotal();
   for(int i = total_pos - 1; i >= 0; i--)
     {
      if(HM_PositionBelongsToSymbol(PositionGetSymbol(i), symbol))   // 🆕 v13.49 P4
        {
         long type = PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY)  buy_count++;
         if(type == POSITION_TYPE_SELL) sell_count++;

         total_profit_cent += PositionGetDouble(POSITION_PROFIT);
        }
     }

   // v7.1: تشخیص هوشمند ۳ لایه‌ای — DetectCentAccount()
   total_profit_dollar = total_profit_cent / (DetectCentAccount() ? 100.0 : 1.0);

   if(buy_count > 0 && sell_count == 0)  pos_type = POSITION_TYPE_BUY;
   if(sell_count > 0 && buy_count == 0)  pos_type = POSITION_TYPE_SELL;

   // ──────────────────────────────────────────────
   // سیستم تشخیص روند ۵ لایه - ثابت در همه تایم‌فریم‌ها
   // H1 EMA34 وزن ۴ | M30 EMA34 وزن ۳ | D1 EMA50 وزن ۲ | M5 EMA20 وزن ۱ | W1 EMA20 وزن ۱
   // max_weight = 11  →  score -100 تا +100
   // 🔧 FIX: تقسیم بر valid_weight نه ثابت 11
   //   اگه H1 هنوز لود نشده و فقط D1 داریم → 2/2×100=100 نه 2/11×100=18
   // ──────────────────────────────────────────────
   int valid_weight  = 0;   // 🔧 مجموع وزن تایم‌فریم‌های لود شده (نه count)
   double _csl_ema, _csl_cl, _csl_buf[1], _csl_cls[];

   // ──────────────────────────────────────────────
   // امتیازدهی هوشمند: نه فقط بالا/پایین EMA
   // هر تایم‌فریم: فاصله % قیمت از EMA → strength 0..1
   // اگه قیمت دقیقاً روی EMA باشه → strength≈0 → score کوچک
   // اگه 0.5% فاصله داشته باشه → strength≈1 → score کامل
   // threshold اتصال: 0.5% (قابل تنظیم با SCORE_DIST_PCT زیر)
   // ──────────────────────────────────────────────
   #define SCORE_DIST_PCT 0.005  // فاصله برای score کامل (0.5%)
   double vote_weighted = 0.0;   // مجموع وزن‌دار امتیازات (float)

   // تابع کمکی inline: محاسبه strength
   // distance = |close - ema| / ema
   // strength = MathMin(1, distance / SCORE_DIST_PCT)
   // sign = +1 if close>ema, -1 otherwise
   // contribution = weight × sign × strength

   // --- H1  EMA34  (وزن ۴)
   _csl_ema = 0;
   if(handleCSL_H1 != INVALID_HANDLE && BarsCalculated(handleCSL_H1) > 34 &&
      CopyBuffer(handleCSL_H1, 0, 0, 1, _csl_buf) == 1) _csl_ema = _csl_buf[0];
   if(_csl_ema <= 0 && CopyClose(symbol, PERIOD_H1, 0, 34, _csl_cls) == 34)
      { double s=0; for(int k=0;k<34;k++) s+=_csl_cls[k]; _csl_ema=s/34; }
   _csl_cl = iClose(symbol, PERIOD_H1, 0);
   if(_csl_ema > 0 && _csl_cl > 0) {
      double dist = MathAbs(_csl_cl - _csl_ema) / _csl_ema;
      double str  = MathMin(1.0, dist / SCORE_DIST_PCT);
      double sign = (_csl_cl > _csl_ema) ? 1.0 : -1.0;
      vote_weighted += 4.0 * sign * str;
      valid_weight  += 4;
   }

   // --- M30 EMA34  (وزن ۳)
   _csl_ema = 0;
   if(handleCSL_M30 != INVALID_HANDLE && BarsCalculated(handleCSL_M30) > 34 &&
      CopyBuffer(handleCSL_M30, 0, 0, 1, _csl_buf) == 1) _csl_ema = _csl_buf[0];
   if(_csl_ema <= 0 && CopyClose(symbol, PERIOD_M30, 0, 34, _csl_cls) == 34)
      { double s=0; for(int k=0;k<34;k++) s+=_csl_cls[k]; _csl_ema=s/34; }
   _csl_cl = iClose(symbol, PERIOD_M30, 0);
   if(_csl_ema > 0 && _csl_cl > 0) {
      double dist = MathAbs(_csl_cl - _csl_ema) / _csl_ema;
      double str  = MathMin(1.0, dist / SCORE_DIST_PCT);
      double sign = (_csl_cl > _csl_ema) ? 1.0 : -1.0;
      vote_weighted += 3.0 * sign * str;
      valid_weight  += 3;
   }

   // --- D1  EMA50  (وزن ۲)
   _csl_ema = 0;
   if(handleCSL_D1 != INVALID_HANDLE && BarsCalculated(handleCSL_D1) > 50 &&
      CopyBuffer(handleCSL_D1, 0, 0, 1, _csl_buf) == 1) _csl_ema = _csl_buf[0];
   if(_csl_ema <= 0 && CopyClose(symbol, PERIOD_D1, 0, 50, _csl_cls) == 50)
      { double s=0; for(int k=0;k<50;k++) s+=_csl_cls[k]; _csl_ema=s/50; }
   _csl_cl = iClose(symbol, PERIOD_D1, 0);
   if(_csl_ema > 0 && _csl_cl > 0) {
      double dist = MathAbs(_csl_cl - _csl_ema) / _csl_ema;
      double str  = MathMin(1.0, dist / SCORE_DIST_PCT);
      double sign = (_csl_cl > _csl_ema) ? 1.0 : -1.0;
      vote_weighted += 2.0 * sign * str;
      valid_weight  += 2;
   }

   // --- M5  EMA20  (وزن ۱)
   _csl_ema = 0;
   if(handleCSL_M5 != INVALID_HANDLE && BarsCalculated(handleCSL_M5) > 20 &&
      CopyBuffer(handleCSL_M5, 0, 0, 1, _csl_buf) == 1) _csl_ema = _csl_buf[0];
   if(_csl_ema <= 0 && CopyClose(symbol, PERIOD_M5, 0, 20, _csl_cls) == 20)
      { double s=0; for(int k=0;k<20;k++) s+=_csl_cls[k]; _csl_ema=s/20; }
   _csl_cl = iClose(symbol, PERIOD_M5, 0);
   if(_csl_ema > 0 && _csl_cl > 0) {
      double dist = MathAbs(_csl_cl - _csl_ema) / _csl_ema;
      double str  = MathMin(1.0, dist / SCORE_DIST_PCT);
      double sign = (_csl_cl > _csl_ema) ? 1.0 : -1.0;
      vote_weighted += 1.0 * sign * str;
      valid_weight  += 1;
   }

   // --- W1  EMA20  (وزن ۱)
   _csl_ema = 0;
   if(handleCSL_W1 != INVALID_HANDLE && BarsCalculated(handleCSL_W1) > 20 &&
      CopyBuffer(handleCSL_W1, 0, 0, 1, _csl_buf) == 1) _csl_ema = _csl_buf[0];
   if(_csl_ema <= 0 && CopyClose(symbol, PERIOD_W1, 0, 20, _csl_cls) == 20)
      { double s=0; for(int k=0;k<20;k++) s+=_csl_cls[k]; _csl_ema=s/20; }
   _csl_cl = iClose(symbol, PERIOD_W1, 0);
   if(_csl_ema > 0 && _csl_cl > 0) {
      double dist = MathAbs(_csl_cl - _csl_ema) / _csl_ema;
      double str  = MathMin(1.0, dist / SCORE_DIST_PCT);
      double sign = (_csl_cl > _csl_ema) ? 1.0 : -1.0;
      vote_weighted += 1.0 * sign * str;
      valid_weight  += 1;
   }
   #undef SCORE_DIST_PCT

   // نرمال‌سازی: تقسیم بر valid_weight
   // اگه قیمت دقیقاً روی EMA همه TF ها → score≈0 (Neutral)
   // اگه 0.5%+ فاصله داشته باشه → score کامل (±100)
   // مقادیر بین ۰ تا ±100 نشون‌دهنده قدرت واقعی روند
   double trend_score = (valid_weight > 0) ? vote_weighted / valid_weight * 100.0 : 0.0;

   // ──────────────────────────────────────────────
   // اگه handle‌ها هنوز آماده نشدن (اول بار بعد لود)
   // score=0 نشون نده - صبر کن تا data بیاد
   // ──────────────────────────────────────────────
   if(valid_weight == 0)
     {
      // label قبلی رو با "..." نگه میداریم - رنگ چارت رو تغییر نمیدیم
      string waitText = "Loading... / " + symbol;
      if(ObjectFind(chart_id, "StatusLabel") >= 0)
         ObjectSetString(chart_id, "StatusLabel", OBJPROP_TEXT, waitText);
      else
        {
         ObjectCreate(chart_id, "StatusLabel", OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_CORNER,    CORNER_RIGHT_UPPER);
         ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_XDISTANCE, CSL_GetStatusXDist());
         ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_YDISTANCE, CSL_GetStatusYDist());
         ObjectSetString(chart_id,  "StatusLabel", OBJPROP_TEXT,      waitText);
         ObjectSetString(chart_id,  "StatusLabel", OBJPROP_FONT,      "Arial Bold");
         ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_FONTSIZE,  CSL_GetStatusFontSize());
         ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_COLOR,     clrGray);
         ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_BACK,      true);
         ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_SELECTABLE,false);
        }
      ChartRedraw(chart_id);
      return;  // ← از CSL_Execute خارج میشیم، صبر برای tick بعدی
     }

   // ──────────────────────────────────────────────
   // سیستم رنگ gradient بر اساس قدرت score
   // ──────────────────────────────────────────────
   // score مطلق چقدره؟
   double absScore = MathAbs(trend_score);
   bool   isBull   = (trend_score > 0);

   // رنگ‌های پس‌زمینه چارت (gradient 4 مرحله‌ای)
   // مقادیر R,G,B برای سبز و قرمز در ۴ شدت
   //          ±10      ±30         ±60         ±80
   // سبز:  0,15,0  | 0,35,0  | 0,60,0  | 0,90,0
   // قرمز: 15,0,0  | 40,0,0  | 70,0,0  | 100,0,0
   color chart_bg_color;
   if(absScore < 10)
      chart_bg_color = clrBlack;                    // NEUTRAL خالص
   else if(absScore < 30)
      chart_bg_color = isBull ? C'0,15,0' : C'15,0,0';   // ضعیف
   else if(absScore < 60)
      chart_bg_color = isBull ? C'0,35,0' : C'40,0,0';   // متوسط
   else if(absScore < 80)
      chart_bg_color = isBull ? C'0,60,0' : C'70,0,0';   // قوی
   else
      chart_bg_color = isBull ? C'0,90,0' : C'100,0,0';  // خیلی قوی

   // ──────────────────────────────────────────────
   // وضعیت و متن label
   // ──────────────────────────────────────────────
   string trend_text     = (absScore < 10) ? "Neutral" :
                            isBull          ? "Uptrend" : "Downtrend";
   string direction_text = "";
   if(buy_count  > 0) direction_text = "(" + IntegerToString(buy_count)  + ") Buy";
   if(sell_count > 0) direction_text = "(" + IntegerToString(sell_count) + ") Sell";

   string score_text = "Score: " + StringFormat("%+.0f", trend_score);

   string status_text = "";
   color  label_bg    = chart_bg_color;

   // ─── v11.3 FIX: رنگ چارت در حالت Buy/Sell بدون پوزیشن ───────────
   // اگه دکمه Buy یا Sell زده شده، مثل حالت پوزیشن باز رنگ‌دهی می‌شه
   // مگه اینکه All باشه و پوزیشنی نباشه که رنگ اصلی برمی‌گرده
   if(pos_type == -1)
     {
      if(g_dirMode == 0)
        {
         // All و بدون پوزیشن → رنگ اصلی
         status_text    = "No Position";
         label_bg       = clrBlack;
         chart_bg_color = g_originalBgColor;
        }
      else
        {
         // Buy یا Sell انتخاب شده → رنگ بر اساس Score ترند
         bool dirBuy = (g_dirMode == 1);
         bool aligned = (isBull && dirBuy) || (!isBull && !dirBuy);

         if(absScore < 10)
           {
            status_text    = "NEUTRAL (No Pos)";
            label_bg       = clrBlack;
            chart_bg_color = clrBlack;
           }
         else if(aligned)
           {
            status_text = "SAFE (No Pos)";
            // FIX v12.16: رنگ چارت باید بر اساس جهت معامله باشه نه جهت روند
            // aligned=true یعنی دکمه موافق روند → همیشه سبز
            chart_bg_color = (absScore < 30) ? C'0,15,0' :
                             (absScore < 60) ? C'0,35,0' :
                             (absScore < 80) ? C'0,60,0' : C'0,90,0';
           }
         else
           {
            status_text = "ALARM (No Pos)";
            // aligned=false یعنی دکمه مخالف روند → همیشه قرمز
            chart_bg_color = (absScore < 30) ? C'15,0,0' :
                             (absScore < 60) ? C'40,0,0' :
                             (absScore < 80) ? C'70,0,0' : C'100,0,0';
            label_bg = chart_bg_color;
           }
        }
     }
   else
     {
      bool aligned = (isBull && pos_type == POSITION_TYPE_BUY) ||
                     (!isBull && pos_type == POSITION_TYPE_SELL);

      if(absScore < 10)
        {
         status_text    = "NEUTRAL";
         label_bg       = clrBlack;
         chart_bg_color = clrBlack;
        }
      else if(aligned)
        {
         status_text    = "SAFE";
         // FIX v12.16: پوزیشن موافق روند → همیشه سبز
         chart_bg_color = (absScore < 30) ? C'0,15,0' :
                          (absScore < 60) ? C'0,35,0' :
                          (absScore < 80) ? C'0,60,0' : C'0,90,0';
         label_bg = chart_bg_color;
        }
      else
        {
         status_text    = "ALARM";
         // پوزیشن مخالف روند → همیشه قرمز
         chart_bg_color = (absScore < 30) ? C'15,0,0' :
                          (absScore < 60) ? C'40,0,0' :
                          (absScore < 80) ? C'70,0,0' : C'100,0,0';
         label_bg = chart_bg_color;
        }
     }

   // ─── label_text: بر اساس حالت دکمه و پوزیشن ──────────────────
   // قانون:
   //   All + بدون پوزیشن  → "No Position" فقط (بدون Score)
   //   هج + All           → "Hedge Active" (بدون Score)
   //   Buy/Sell + هر حالت → Score نمایش داده می‌شه
   //   All + پوزیشن باز   → Score نمایش داده می‌شه
   string dir_label = (g_dirMode == 1) ? "[Buy]" : (g_dirMode == 2) ? "[Sell]" : "";
   bool isHedge = (buy_count > 0 && sell_count > 0);
   string label_text;
   if(pos_type == -1 && g_dirMode == 0)
      label_text = "No Position / " + symbol;     // All + بدون پوز → بدون Score
   else if(isHedge && g_dirMode == 0)
      label_text = "⇄ Hedge / " + symbol + "\n" + direction_text;  // هج + All → بدون Score
   else if(pos_type == -1)
      label_text = status_text + " " + dir_label + " / " + trend_text + "\n" + score_text;  // Buy/Sell بدون پوز
   else
      label_text = status_text + " / " + trend_text + " + " + direction_text + "\n" + score_text;  // با پوز

   // ──────────────────────────────────────────────
   // اعمال رنگ چارت
   // ──────────────────────────────────────────────
   ChartSetInteger(chart_id, CHART_COLOR_BACKGROUND, chart_bg_color);
   ChartSetInteger(chart_id, CHART_COLOR_FOREGROUND, clrWhite);
   ChartSetInteger(chart_id, CHART_COLOR_GRID,       clrDimGray);

   // ──────────────────────────────────────────────
   // v12: StatusLabel is shown inside dashboard (InfoTrend) — hide external label
   // chart background color is still applied
   // ──────────────────────────────────────────────
   if(ObjectFind(chart_id, "StatusLabel") >= 0)
      ObjectDelete(chart_id, "StatusLabel");

   // v12: ProfitLabel shown inside dashboard (InfoPL) — hide external label
   if(ObjectFind(chart_id, "ProfitLabel") >= 0)
      ObjectDelete(chart_id, "ProfitLabel");

   // Store data so UpdateDashboard can pick it up
   g_csvScore  = trend_score;
   g_csvStatus = (pos_type == -1) ? "NoPos" : status_text;

   // Update traffic lights & dashboard
   TL_Update();
   g_forceUpdateDashboard = true;

   // کش رژیم بازار
   switch(currentRegime.regime)
   {
      case REGIME_TRENDING:  g_csvRegime = "Trending";  break;
      case REGIME_RANGING:   g_csvRegime = "Ranging";   break;
      case REGIME_VOLATILE:  g_csvRegime = "Volatile";  break;
      case REGIME_QUIET:     g_csvRegime = "Quiet";     break;
      default:               g_csvRegime = "?";
   }

   // کش وضعیت ایچیموکو (از آخرین کندل بسته)
   if(localEnableIchimoku && handleIchimoku != INVALID_HANDLE
      && BarsCalculated(handleIchimoku) > 60)
   {
      int    iShift = 1;
      int    iSpanIdx = iShift + 26;
      if(iShift < ArraySize(g_ichiTenkan) && iSpanIdx < ArraySize(g_ichiSpanA))
      {
         double cP      = iClose(_Symbol, PERIOD_CURRENT, iShift);
         double cTop    = MathMax(g_ichiSpanA[iSpanIdx], g_ichiSpanB[iSpanIdx]);
         double cBot    = MathMin(g_ichiSpanA[iSpanIdx], g_ichiSpanB[iSpanIdx]);
         if(cP > cTop)       g_csvIchi = "above";
         else if(cP < cBot)  g_csvIchi = "below";
         else                g_csvIchi = "in";
      }
   }
   else g_csvIchi = "N/A";

   // کش اسپرد
   g_csvSpread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   ChartRedraw(chart_id);

   
}

// ════════════════════════════════════════════════════════════════════
// 🩹 Patch 1 (V12.06): به‌روزرسانی لحظه‌ای (هر تیک) Profit (P/L)
// بدون throttle — هر تیک اجرا می‌شود
// ════════════════════════════════════════════════════════════════════
void UpdateProfitLabel()
{
   if(g_isDeinitializing) return;
   double total_profit_cent = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(HM_PositionBelongsToSymbol(PositionGetSymbol(i), _Symbol))   // 🆕 v13.49 P4
         total_profit_cent += PositionGetDouble(POSITION_PROFIT);

   double profit = total_profit_cent / (DetectCentAccount() ? 100.0 : 1.0);

   int buy_cnt = 0, sell_cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(HM_PositionBelongsToSymbol(PositionGetSymbol(i), _Symbol))   // 🆕 v13.49 P4
      {
         long pt = PositionGetInteger(POSITION_TYPE);
         if(pt == POSITION_TYPE_BUY)  buy_cnt++;
         if(pt == POSITION_TYPE_SELL) sell_cnt++;
      }
   }

   string plLine;
   color  plColor;
   if(buy_cnt == 0 && sell_cnt == 0)
   {
      plLine  = "Profit: No open position";
      plColor = clrDimGray;
   }
   else
   {
      plLine  = "Profit: " + (profit >= 0 ? "+" : "") + DoubleToString(profit, 2) + " $";
      plColor = (profit > 0) ? clrLime : (profit < 0) ? clrRed : clrWhite;
   }
   UpdateLabel(dashboardPrefix + "InfoPL", plLine, plColor);
}

void CM_Execute()
{
   long chart = ChartID();
   
   // 1. خاموش کردن Scale Fix
   ChartSetInteger(chart, CHART_SCALEFIX, false);
   
   // 2. روشن کردن Shift
   ChartSetInteger(chart, CHART_SHIFT, true);
   
   // 3. به انتها رفتن
   ChartNavigate(chart, CHART_END, 0);
   
   // 4. 🔥 اثر NUM5: تغییر سریع Scale
   int scale = (int)ChartGetInteger(chart, CHART_SCALE);
   ChartSetInteger(chart, CHART_SCALE, scale + 2);
   ChartRedraw(chart);
   
   // تأخیر خیلی کوتاه
   int i = 0; while(i++ < 50) {}
   
   ChartSetInteger(chart, CHART_SCALE, scale);
   ChartRedraw(chart);
   
   // 5. روشن کردن Scale Fix با مقادیر 1 و 0
   ChartSetInteger(chart, CHART_SCALEFIX, true);
   ChartSetDouble(chart, CHART_FIXED_MAX, 1.0);
   ChartSetDouble(chart, CHART_FIXED_MIN, 0.0);
   
   Print("انجام شد. اثر معادل NUM5 اعمال گردید.");
}

//+------------------------------------------------------------------+
// Create MTF indicator handles
//+------------------------------------------------------------------+
void CreateMTFHandles()
{
   if(handleH1_EMA == INVALID_HANDLE)
      handleH1_EMA = iMA(_Symbol, PERIOD_H1, MTF_EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(handleH4_EMA == INVALID_HANDLE)
      handleH4_EMA = iMA(_Symbol, PERIOD_H4, MTF_EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(handleH1_RSI == INVALID_HANDLE)
      handleH1_RSI = iRSI(_Symbol, PERIOD_H1, RSIPeriod, PRICE_CLOSE);
   if(handleH4_RSI == INVALID_HANDLE)
      handleH4_RSI = iRSI(_Symbol, PERIOD_H4, RSIPeriod, PRICE_CLOSE);
   
   if(ShowDebugLogs)
      Print("📊 MTF handles created");
}

//+------------------------------------------------------------------+
// Release MTF indicator handles
//+------------------------------------------------------------------+
void ReleaseMTFHandles()
{
   if(handleH1_EMA != INVALID_HANDLE) { IndicatorRelease(handleH1_EMA); handleH1_EMA = INVALID_HANDLE; }
   if(handleH4_EMA != INVALID_HANDLE) { IndicatorRelease(handleH4_EMA); handleH4_EMA = INVALID_HANDLE; }
   if(handleH1_RSI != INVALID_HANDLE) { IndicatorRelease(handleH1_RSI); handleH1_RSI = INVALID_HANDLE; }
   if(handleH4_RSI != INVALID_HANDLE) { IndicatorRelease(handleH4_RSI); handleH4_RSI = INVALID_HANDLE; }
   
   if(ShowDebugLogs)
      Print("📊 MTF handles released");
}

// ════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════
// v10.3.2: GetPipSize — اندازه یک پیپ برای هر نماد
// ─────────────────────────────────────────────────────────────────
// برای نمادهای 3/5 رقمی: PipSize = Point × 10
// برای نمادهای 2/4 رقمی: PipSize = Point
// مثال: AUDCAD (Digits=5) → 0.00001×10 = 0.0001
//        USDJPY (Digits=3) → 0.001×10   = 0.01
// ════════════════════════════════════════════════════════════════
double GetPipSize(string sym)
{
   int    digs  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt    = SymbolInfoDouble(sym, SYMBOL_POINT);
   return (digs == 3 || digs == 5) ? pt * 10.0 : pt;
}

// DrawZoneLines (v10.3.x entry-relative) — حذف شد در v10.4.1 (dead code)

// v10.5: حذف خطوط طبقه از چارت
void DeleteZoneLines()
{
   ObjectsDeleteAll(0, "ZombieLine_");
   ObjectsDeleteAll(0, "ZoneLabel_");
}

// ─────────────────────────────────────────────────────────────────
// v10.7: RefreshZoneLabelPositions — فقط موقعیت x لیبل‌ها بروز می‌شود
//   بدون حذف/ایجاد مجدد → بدون فلیکر روی اسکرول/زوم چارت
//   HLINE ها قیمت-محور هستند و نیازی به بروز روی اسکرول ندارند
// ─────────────────────────────────────────────────────────────────
void RefreshZoneLabelPositions()
{
   datetime labelTime = iTime(_Symbol, PERIOD_H1, 3);
   if(labelTime == 0) labelTime = TimeCurrent() - 3 * 3600;

   int total = ObjectsTotal(0, 0, OBJ_TEXT);
   for(int i = total - 1; i >= 0; i--)
   {
      string nm = ObjectName(0, i, 0, OBJ_TEXT);
      if(StringFind(nm, "ZoneLabel_") == 0)
         ObjectSetInteger(0, nm, OBJPROP_TIME, labelTime);
   }
}

// ─────────────────────────────────────────────────────────────────
// v10.4: DrawAbsoluteZoneLines — رسم کامل گرید مطلق (با حذف قبلی)
//   فقط برای موارد واقعی تغییر پارامتر صدا بزن (نه هر اسکرول):
//   basePrice    : قیمت پایین Zone 0  (g_zoneTable[i].base_low)
//   zoneWPrice   : عرض هر طبقه به قیمت (widthPips × pipSz)
//   pipSz        : اندازه پیپ استاندارد
//   maxZones     : چند طبقه در هر طرف
//   entryZone    : طبقه ورود — با خط سفید ضخیم برجسته می‌شود
// ─────────────────────────────────────────────────────────────────
void DrawAbsoluteZoneLines(double basePrice, double zoneWPrice, double pipSz,
                            int maxZones, int entryZone, int colorMode = 0)
// colorMode: 0=خاکستری(بدون پوزیشن/هج) | 1=Buy(سبز/قرمز) | 2=Sell(معکوس)
{
   if(basePrice <= 0.0 || zoneWPrice <= 0.0) return;
   // حذف خطوط قبلی (فقط در بازسازی کامل — نه در اسکرول)
   DeleteZoneLines();

   int wPips = (int)MathRound(zoneWPrice / pipSz);
   datetime labelTime = iTime(_Symbol, PERIOD_H1, 3);
   if(labelTime == 0) labelTime = TimeCurrent() - 3 * 3600;

   int zLo = entryZone - maxZones;
   int zHi = entryZone + maxZones + 1;

   for(int z = zLo; z <= zHi; z++)
   {
      double level = basePrice + (double)z * zoneWPrice;
      string name  = "ZombieLine_" + IntegerToString(z);
      string lname = "ZoneLabel_"  + IntegerToString(z);

      color  lineCol;
      int    lineWidth;
      ENUM_LINE_STYLE lineStyle;
      string labelTxt;

      int dz = z - entryZone;
      labelTxt = StringFormat("Zone %+d  [%.5f]", z, level);

      if(colorMode == 0)   // خاکستری — بدون پوزیشن یا هج
      {
         lineCol   = clrDimGray;
         lineWidth = 1;
         lineStyle = (dz == 0) ? STYLE_SOLID : STYLE_DOT;
         if(dz == 0) { lineCol = clrGray; lineWidth = 2; labelTxt = StringFormat("Zone %+d  [%.5f]", entryZone, level); }
      }
      else
      {
         // colorMode 1=Buy | 2=Sell: برای Sell جهت معکوس می‌شود
         int effDz = (colorMode == 2) ? -dz : dz;  // Sell: بالا=سود=سبز | پایین=ضرر=قرمز
         if(dz == 0)
         {
            lineCol = clrWhite; lineWidth = 2; lineStyle = STYLE_SOLID;
            labelTxt = StringFormat("Zone %+d  [%.5f]", entryZone, level);
         }
         else if(effDz > 0)   // ضرر — قرمز
         {
            if(effDz == 1)      lineCol = clrGold;
            else if(effDz == 2) lineCol = clrOrange;
            else if(effDz == 3) lineCol = clrOrangeRed;
            else                lineCol = clrRed;
            lineWidth = 1; lineStyle = STYLE_DASH;
         }
         else   // سود — سبز
         {
            if(effDz == -1)      lineCol = clrMediumSeaGreen;
            else if(effDz == -2) lineCol = clrLimeGreen;
            else                 lineCol = clrSpringGreen;
            lineWidth = 1; lineStyle = STYLE_DOT;
         }
      }

      // ── HLINE (قیمت-محور، ثابت روی اسکرول) ─────────────────────
      if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, level))
         ObjectMove(0, name, 0, 0, level);
      ObjectSetInteger(0, name, OBJPROP_COLOR,      lineCol);
      ObjectSetInteger(0, name, OBJPROP_WIDTH,      lineWidth);
      ObjectSetInteger(0, name, OBJPROP_STYLE,      lineStyle);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_BACK,       true);   // پشت کندل‌ها
      ObjectSetInteger(0, name, OBJPROP_ZORDER,     0);      // v11.92: کلیک به دکمه‌های داشبورد (ZORDER=10) برسد

      // ── OBJ_TEXT لیبل (BACK=true → پشت داشبورد) ─────────────────
      if(!ObjectCreate(0, lname, OBJ_TEXT, 0, labelTime, level))
         ObjectMove(0, lname, 0, labelTime, level);
      ObjectSetString (0, lname, OBJPROP_TEXT,       labelTxt);
      ObjectSetInteger(0, lname, OBJPROP_COLOR,      lineCol);
      ObjectSetInteger(0, lname, OBJPROP_FONTSIZE,   8);
      ObjectSetInteger(0, lname, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lname, OBJPROP_BACK,       true);  // v10.7: پشت داشبورد
   }

   if(ShowDebugLogs)
      Print("📐 ZoneLines: base=", DoubleToString(basePrice, _Digits),
            " | Width=", wPips, "pip | EntryZone=", entryZone, " | ±", maxZones);
}


// ════════════════════════════════════════════════════════════════════
// STATUS QUERY SYSTEM v1.0 — پاسخ به کلمه «وضعیت» از تلگرام
// ════════════════════════════════════════════════════════════════════

// ─── ساخت متن کامل گزارش وضعیت ────────────────────────────────────
// ── تبدیل state عدد به آیکن+متن رنگی (برای تلگرام) ─────────────────
// s: -1=خاکستری/بدون پوز  0=سبز  1=زرد  2=قرمز  3=نارنجی
string SQ_Light(int s)
{
   if(s == 2)  return "🔴 Red";
   if(s == 3)  return "🟠 Orange";
   if(s == 1)  return "🟡 Yellow";
   if(s == 0)  return "🟢 Green";
   return "⚫ --";
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.24: SQ_SpikeLineText — یک خط رنگ + score + بازه‌ها برای یک جهت
//   spikeVal: -1=N/A | 0=Normal | 1=Warning | 2=Spike
//   scoreVal: g_spikeScore (مستقل از جهت، همیشه مشترکه)
//   بازه‌ها: Normal < 1.00 | Warning 1.00-1.50 | Spike > 1.50
// ════════════════════════════════════════════════════════════════════
string SQ_SpikeLineText(int spikeVal, double scoreVal)
{
   if(spikeVal == -1)
      return "⚫ N/A  score=-- ";
   string icon  = (spikeVal == 2) ? "🔴" : (spikeVal == 1) ? "🟠" : "🟢";
   string label = (spikeVal == 2) ? "Spike"   : (spikeVal == 1) ? "Warning" : "Normal";
   return StringFormat("%s %s  score=%.2f ",
                       icon, label, scoreVal);
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.24: SQ_SpikeRuleText — وضعیت Run/Stop/Close برای یک جهت + توضیح کامل
//
//   STOP  A: Spike=🔴 AND CRISIS ≠ سبز (Yellow/Orange/Red)
//   STOP  B: Spike=⚡ Warning AND CRISIS = 🟠/🔴
//   CLOSE A: CRISIS=🔴 AND HighAlert فعال (ADX≥35 + Flow علیه جهت)
//   CLOSE B: CRISIS=🔴 برای ≥6 ساعت متوالی (g_gbpnzdCrisisRedH)
//   در غیر اینصورت: Run (فقط اگه g_gbpnzdLevel=0 باشد)
//
//   ⚠️  g_gbpnzdCrisisRedH با restart ریست می‌شه (by design) —
//   اگه EA تازه ران شده باشه و CleanH=0 نشون بده، ممکنه counter
//   واقعی‌ای نداشته باشیم → در Rule نشون داده می‌شه
//
//   🐛 v13.30 FIX1: ماشین حالت g_gbpnzdLevel را respect کن.
//   قبلاً تابع فقط شرایط لحظه‌ای را چک می‌کرد و وقتی Crisis از
//   Orange به Yellow برمی‌گشت (CleanH هنوز < 24) مستقیماً Run
//   برمی‌گرداند. حالا اگه Level > 0 باشد، وضعیت STOP یا CLOSE
//   را نگه می‌داریم تا RESUME (24h clean) تأیید شود.
// ════════════════════════════════════════════════════════════════════
string SQ_SpikeRuleText(int spikeVal, int crisisVal,
                        double adxVal, double flowScore, bool isForBuy)
{
   string crisisName = (crisisVal == 2) ? "Red" :
                       (crisisVal == 3) ? "Orange" :
                       (crisisVal == 1) ? "Yellow" :
                       (crisisVal == 0) ? "Green"  : "N/A";
   string spikeName  = (spikeVal == 2) ? "Spike" :
                       (spikeVal == 1) ? "Warning" :
                       (spikeVal == 0) ? "Normal"  : "N/A";

   // نشانه restart: Replay هنوز اجرا نشده
   string restartNote = (!g_gbpnzdReplayDone) ? " ⚠️ Replay pending" : "";

   // 🐛 v13.36 FIX: از state machine جهت‌دار استفاده کن (نه مشترک)
   // قبلاً g_gbpnzdLevel مشترک بود → اگه Sell Spike می‌خورد، Buy Rule هم STOP می‌شد
   int  dirLevel    = isForBuy ? g_gbpnzdLevelBuy    : g_gbpnzdLevelSell;
   int  dirCleanH   = isForBuy ? g_gbpnzdCleanHBuy   : g_gbpnzdCleanHSell;
   int  dirRedH     = isForBuy ? g_gbpnzdCrisisRedHBuy : g_gbpnzdCrisisRedHSell;

   // اگه ماشین حالت در STOP یا CLOSE است، نتیجه را مستقیماً از آن بخوان
   // RESUME فقط با 24h CleanH کامل ممکن است
   if(dirLevel == 2)
   {
      if(dirCleanH >= 24)
         return StringFormat("🟢 Run | CleanH=%dh (RESUME)", dirCleanH);
      return StringFormat("🔴 Close | CleanH=%dh%s", dirCleanH, restartNote);
   }
   if(dirLevel == 1)
   {
      if(dirCleanH >= 24)
         return StringFormat("🟢 Run | CleanH=%dh (RESUME)", dirCleanH);
      return StringFormat("⛔ Stop | CleanH=%dh%s", dirCleanH, restartNote);
   }

   // dirLevel == 0 → چک کن آیا الان trigger جدیدی فعال شده
   bool spikeIsSpike   = (spikeVal == 2);
   bool spikeIsWarning = (spikeVal == 1);
   bool crisisNotGreen = (crisisVal >= 1);
   bool crisisOrangeRed= (crisisVal == 2 || crisisVal == 3);
   bool crisisRed      = (crisisVal == 2);

   // HighAlert جهت‌دار: ADX≥35 + Flow علیه جهت
   bool highAlert = (adxVal >= 35.0) &&
                    (isForBuy ? (flowScore < -7.0) : (flowScore > 7.0));

   bool trigStopA  = spikeIsSpike   && crisisNotGreen;
   bool trigStopB  = spikeIsWarning && crisisOrangeRed;
   bool trigCloseA = crisisRed      && highAlert;
   bool trigCloseB = (dirRedH >= 6);

   if(trigCloseA)
      return StringFormat("🔴 Close — CRISIS=%s + HighAlert  (علیه جهت ADX=%.0f|Flow=%.1f)",
                          crisisName, adxVal, flowScore);
   if(trigCloseB)
      return StringFormat("🔴 Close — CRISIS=Red برای 4 ساعت متوالی قرمز (باید <6ساعت بشه)",
                          crisisName, dirRedH);
   if(trigStopA)
      return StringFormat("⛔ Stop — Spike=%s + CRISIS=%s (Normal+Green منتظر)%s",
                          spikeName, crisisName, restartNote);
   if(trigStopB)
      return StringFormat("⛔ Stop — Spike=%s Warning + CRISIS=%s (سبز/زرد CRISIS منتظر)%s",
                          spikeName, crisisName, restartNote);

   // Run — نشون بده چرا ایمنه
   if(dirCleanH >= 24)
      return StringFormat("🟢 Run — Spike=%s | CRISIS=%s | %dh متوالی تمیز ",
                          spikeName, crisisName, dirCleanH);

   // 🐛 v13.44 FIX5: فرمت نمایشی تمیزتر — CrisisRedH حذف شد (اطلاعات اضافه)
   return StringFormat("🟢 Run — Spike=%s | CRISIS=%s | CleanH=%dh%s",
                       spikeName, crisisName,
                       dirCleanH, restartNote);
}

string StatusQuery_BuildReport()
{
   string sym = _Symbol;

   // ── چک ساپورت ارز ──────────────────────────────────────────────────
   if(StringFind(sym, "GBPNZD") < 0)
   {
      return "📊 " + sym + " — HelpMe Status\n"
           + "─────────────────────\n"
           + "⚠️ این ارز ساپورت نمیشه\n"
           + "HelpMe فقط برای GBPNZD طراحی شده.\n"
           + "─────────────────────\n"
           + "لطفاً چارت رو روی GBPNZD باز کن.";
   }

   // ── موقعیت‌های باز ──────────────────────────────────────────────
   int buy_cnt = 0, sell_cnt = 0;
   double total_profit_cent = 0.0;
   datetime oldest_buy_time  = 0;
   datetime oldest_sell_time = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!HM_PositionBelongsToSymbol(PositionGetSymbol(i), sym)) continue;   // 🆕 v13.49 P4
      long pt = PositionGetInteger(POSITION_TYPE);
      if(pt == POSITION_TYPE_BUY)
      {
         buy_cnt++;
         datetime t = (datetime)PositionGetInteger(POSITION_TIME);
         if(oldest_buy_time == 0 || t < oldest_buy_time) oldest_buy_time = t;
      }
      else
      {
         sell_cnt++;
         datetime t = (datetime)PositionGetInteger(POSITION_TIME);
         if(oldest_sell_time == 0 || t < oldest_sell_time) oldest_sell_time = t;
      }
      total_profit_cent += PositionGetDouble(POSITION_PROFIT);
   }
   double profit = total_profit_cent / (DetectCentAccount() ? 100.0 : 1.0);

   bool hasPos  = (buy_cnt > 0 || sell_cnt > 0);
   bool isHedge = (buy_cnt > 0 && sell_cnt > 0);

   // FIX v12.16: g_dirMode به عنوان پوزیشن مجازی در نظر گرفته میشه
   // اگه پوزیشن واقعی نداریم ولی dirMode=Buy/Sell، چراغ‌ها رو نشون بده
   bool virtualBuy  = (!hasPos && g_dirMode == 1);
   bool virtualSell = (!hasPos && g_dirMode == 2);
   bool hasVirtual  = (virtualBuy || virtualSell);
   bool activeMode  = (hasPos || hasVirtual);  // پوزیشن واقعی یا مجازی

   // forBuy: جهت فعال (واقعی یا مجازی)
   bool forBuy;
   if(hasPos)
      forBuy = isHedge ? (buy_cnt >= sell_cnt) : (buy_cnt > 0);
   else
      forBuy = virtualBuy;  // از dirMode

   // ── Trade ───────────────────────────────────────────────────────
   string tradeIcon;
   if(!hasPos && !hasVirtual)  tradeIcon = "⚫ No Position";
   else if(hasVirtual)         tradeIcon = forBuy ? "🔵 Virtual Buy (no position)" : "🔵 Virtual Sell (no position)";
   else if(isHedge)            tradeIcon = "↕️ Buy+" + IntegerToString(buy_cnt) + " / Sell+" + IntegerToString(sell_cnt);
   else if(buy_cnt>0)          tradeIcon = "⬆️ Buy x" + IntegerToString(buy_cnt);
   else                        tradeIcon = "⬇️ Sell x" + IntegerToString(sell_cnt);

   // ── Profit ──────────────────────────────────────────────────────
   string profitStr;
   if(!hasPos)
      profitStr = "No open position";
   else
   {
      string pIcon = (profit > 0) ? "💚" : (profit < 0) ? "❤️" : "⚪";
      profitStr = StringFormat("%s %+.2f $", pIcon, profit);
   }

   // ── Steps ───────────────────────────────────────────────────────
   string stepsStr;
   if(!hasPos)
      stepsStr = "No open position";
   else if(isHedge)
      stepsStr = StringFormat("Buy: step %d | Sell: step %d", buy_cnt, sell_cnt);
   else
      stepsStr = IntegerToString(buy_cnt + sell_cnt);

   // ── Open Time ───────────────────────────────────────────────────
   string openTimeStr;
   if(!hasPos)
   {
      openTimeStr = "No open position";
   }
   else
   {
      datetime ref_time = 0;
      if(isHedge)
         ref_time = (oldest_buy_time > 0 && oldest_sell_time > 0)
                    ? MathMin(oldest_buy_time, oldest_sell_time)
                    : (oldest_buy_time > 0 ? oldest_buy_time : oldest_sell_time);
      else
         ref_time = (buy_cnt > 0) ? oldest_buy_time : oldest_sell_time;

      if(ref_time > 0)
      {
         int elapsed = (int)(TimeCurrent() - ref_time);
         int days  = elapsed / 86400;
         int hours = (elapsed % 86400) / 3600;
         int mins  = (elapsed % 3600)  / 60;
         if(days > 0)
            openTimeStr = StringFormat("%dd %dh %dm", days, hours, mins);
         else if(hours > 0)
            openTimeStr = StringFormat("%dh %dm", hours, mins);
         else
            openTimeStr = StringFormat("%dm", mins);
      }
      else
         openTimeStr = "N/A";
   }

   // ── Trend ───────────────────────────────────────────────────────
   string trendIcon;
   if(!activeMode)
   {
      trendIcon = "⚫";
   }
   else
   {
      double absScore = MathAbs(g_csvScore);
      if(absScore < 10)
         trendIcon = "⚫";
      else
      {
         bool isBull  = (g_csvScore > 0);
         bool aligned = (isBull && forBuy) || (!isBull && !forBuy);
         trendIcon = aligned ? "🟢" : "🔴";
      }
   }
   string trendStr = StringFormat("%s  Score %+.0f", trendIcon, g_csvScore);

   // ── Crisis ──────────────────────────────────────────────────────
   int crisisRC = (g_lightRTM==2?1:0)+(g_lightTrend==2?1:0)+
                  (g_lightStruct==2?1:0)+(g_lightFLOW==2?1:0);
   string crisisStr;
   if(!activeMode || g_crisisState < 0)
      crisisStr = "⚫  --";
   else
      crisisStr = SQ_Light(g_crisisState == 3 ? 3 :
                           g_crisisState == 2 ? 2 :
                           g_crisisState == 1 ? 1 : 0)
                  + StringFormat("  (RC=%d)", crisisRC);

   // ── Hi Alert ────────────────────────────────────────────────────
   bool highAlert = activeMode &&
                    ((forBuy  && g_lastAdxVal >= 35.0 && g_lastFlowScore < -7.0) ||
                     (!forBuy && g_lastAdxVal >= 35.0 && g_lastFlowScore >  7.0));
   string hiAlertStr;
   if(!activeMode)
      hiAlertStr = "⚫  --";
   else if(highAlert)
      hiAlertStr = "🔴  Active (ADX>=35 + Flow against)";
   else
      hiAlertStr = "🟢  OK";

   // ── Zombie / Price Zone ─────────────────────────────────────────
   string zombieStr;
   if(!g_zombieSupported)
      zombieStr = "⚫  N/A";
   else if(!activeMode)
      zombieStr = "⚫  --";
   else
      zombieStr = SQ_Light(g_lightZOMBIE)
                  + StringFormat("  Start=%+d  Now=%+d",
                                 g_zombieEntryZone, g_zombieCurrentZone);

   // ── Killer ──────────────────────────────────────────────────────
   string killerStr = activeMode ? SQ_Light(g_lightKILLER) : "⚫  --";

   // ── Mkt Phase ────────────────────────────────────────────────── 🆕 v13.12
   string mktPhaseStr;
   if(g_lightMktPhase == -1)
      mktPhaseStr = "⚫  --";
   else
      mktPhaseStr = SQ_Light(g_lightMktPhase)
                    + StringFormat("  ratio=%.3f", g_mktPhaseRatio);

   // ── Spike Detector — چهار خط جداگانه Buy و Sell 🆕 v13.24/v13.25 ─
   //
   // وقتی پوزیشن باز داری: از snapshot هایی که TL_Update ذخیره کرده استفاده کن
   // وقتی پوزیشن نداری:   TL_Update برای هیچ جهتی اجرا نشده →
   //                        FLOW و Crisis رو الان جهت‌دار محاسبه کن
   //
   int spikeSellVal, spikeBuyVal;
   int crisisSellVal, crisisBuyVal;
   double adxSellVal, adxBuyVal;
   double flowSell, flowBuy;
   // 🐛 v13.29 FIX3: score نمایشی جهت‌دار — در no-position متفاوت، در activeMode مشترک
   double spikeSellDisplayScore = g_spikeScore;
   double spikeBuyDisplayScore  = g_spikeScore;

   if(!activeMode || hasVirtual)
   {
      // ── بدون پوزیشن یا Virtual: جهت‌دار محاسبه کن ─────────────────
      // 🐛 v13.32 FIX: virtual mode (hasVirtual=true) باید اینجا باشه.
      // قبلاً چون activeMode=true بود، به branch "active position" میرفت
      // و g_gbnzdSpikeSell/Buy که هر دو = g_lightSpike بودن رو مستقیم میخوند.
      // حالا virtual هم مثل no-position محاسبه جهت‌دار از FlowEvaluate میکنه.
      //
      // 🐛 v13.34 FIX1: از g_gbnzdFlowBuy/Sell که در TL_Update کش شدن استفاده کن
      // نه FlowEvaluate لحظه‌ای. سه StatusQuery چند ثانیه فاصله دارن و
      // FlowEvaluate ممکنه در هر فراخوانی مقدار متفاوتی برگردونه →
      // score سه پیام متفاوت می‌شد. کش TL_Update هر ساعت آپدیت می‌شه
      // (منطق یکسان، timestamp یکسان برای هر سه پیام).
      // fallback به FlowEvaluate فقط اگه کش هنوز آماده نیست (اول باز شدن).
      // 🆕 v14.03: StatusQuery از g_spikeScore کش‌شده استفاده می‌کند (آخرین کندل بسته)
      // Calc_SpikeDetector فقط اگه هنوز هیچ داده‌ای نداریم (firstRun) فراخوانده می‌شود
      // در حالت عادی g_spikeScore از آخرین TL_Update (کندل بسته) کش شده است
      if(g_lightSpike == -1) Calc_SpikeDetector();  // فقط firstRun
      double fsBuy  = (g_gbnzdFlowBuy  != 0.0) ? g_gbnzdFlowBuy  : Rule_FlowForSymbol(_Symbol, true);
      double fsSell = (g_gbnzdFlowSell != 0.0) ? g_gbnzdFlowSell : Rule_FlowForSymbol(_Symbol, false);
      flowBuy  = fsBuy;
      flowSell = fsSell;

      // ADX از handle H4 (مشترک)
      adxBuyVal  = g_lastAdxVal;
      adxSellVal = g_lastAdxVal;

      // ════════════════════════════════════════════════════════════
      // 🐛 v13.45 FIX-B1: حذف فرمول تقویت‌شده «×0.12» — هرگز در بکتست
      // وجود نداشت. بکتست (LogHourlySnapshot) و Replay هر دو Spike را
      // بدون هیچ ضریبی حساب می‌کنند: امتیاز خام g_spikeScore + دروازه‌ی
      // Flow جهت‌دار (fs<-4.0 = قرمز، [-4,2) با score>=2.0 = زرد).
      // قبلاً این‌جا ۰.۱۲ بود، جای دیگه (TL_Update) ۰.۰۸ بود، Replay اصلاً
      // ضریب نداشت — سه مقدار متفاوت برای یک محاسبه. حالا هر سه یکی‌ان.
      // ════════════════════════════════════════════════════════════
      double baseScore = (g_spikeScore > 0.0) ? g_spikeScore : 0.0;
      if(g_lightSpike == -1) baseScore = 0.0;  // Calc_SpikeDetector هنوز داده نداره
      // 🐛 v13.31 FIX3: اگه Spike هنوز لود نشده و Replay هم نشده، score=0 اشتباهه
      // در این حالت، score را با -1 علامت می‌زنیم تا SQ_SpikeLineText "Loading" نشون بده
      bool spikeDataReady = (g_lightSpike >= 0 && g_gbpnzdReplayDone);

      // score یکسان برای هر دو جهت (مثل بکتست) — تفکیک واقعی از دروازه‌ی Flow می‌آد نه از score
      double spikeScoreSell = spikeDataReady ? baseScore : 0.0;
      double spikeScoreBuy  = spikeDataReady ? baseScore : 0.0;

      // rawPhase (مشترک، از روی امتیاز خام)
      int rawPhaseSell = (spikeScoreSell < 1.00) ? 0 : (spikeScoreSell <= 1.50) ? 1 : 2;
      int rawPhaseBuy  = (spikeScoreBuy  < 1.00) ? 0 : (spikeScoreBuy  <= 1.50) ? 1 : 2;

      // flowRed/Yellow با آستانه‌های جهت‌دار — همان منطق GBPNZD_Replay_SpikeAtBar
      bool flowRedSell    = (fsSell < -4.0);
      bool flowRedBuy     = (fsBuy  < -4.0);
      bool flowYellowSell = (spikeScoreSell >= 2.0 && fsSell < 2.0 && fsSell >= -4.0);
      bool flowYellowBuy  = (spikeScoreBuy  >= 2.0 && fsBuy  < 2.0 && fsBuy  >= -4.0);

      // Spike Sell جهت‌دار
      if(rawPhaseSell >= 1 && flowRedSell)   spikeSellVal = rawPhaseSell;
      else if(flowYellowSell)                spikeSellVal = 1;
      else                                   spikeSellVal = 0;
      // 🐛 v13.31 FIX3: اگه داده آماده نیست، N/A نشون بده
      if(!spikeDataReady) spikeSellVal = -1;

      // Spike Buy جهت‌دار
      if(rawPhaseBuy  >= 1 && flowRedBuy)    spikeBuyVal  = rawPhaseBuy;
      else if(flowYellowBuy)                 spikeBuyVal  = 1;
      else                                   spikeBuyVal  = 0;
      // 🐛 v13.31 FIX3: اگه داده آماده نیست، N/A نشون بده
      if(!spikeDataReady) spikeBuyVal = -1;

      // score نمایشی جهت‌دار (برای SQ_SpikeLineText — تا score عدداً هم متفاوت باشد)
      // 🐛 v13.29 FIX3: assign به متغیر outer scope (نه تعریف مجدد)
      spikeSellDisplayScore = spikeScoreSell;
      spikeBuyDisplayScore  = spikeScoreBuy;

      // Crisis برای هر جهت:
      // 🐛 v13.26 FIX1: اگه snapshot معتبر از آخرین Replay/TL_Update داریم، از همون استفاده کن.
      // این تضمین می‌کنه Crisis در No-Position با RC کامل (RTM+TREND+STRUCT+FLOW) محاسبه شده باشه.
      // اگه snapshot معتبر نداریم، با GBPNZD_Replay_CrisisAtBar(1,...) که RC کامل داره محاسبه کن.
      if(g_gbnzdCrisisBuy >= 0)
         crisisBuyVal = g_gbnzdCrisisBuy;
      else
         crisisBuyVal = GBPNZD_Replay_CrisisAtBar(1, true);

      if(g_gbnzdCrisisSell >= 0)
         crisisSellVal = g_gbnzdCrisisSell;
      else
         crisisSellVal = GBPNZD_Replay_CrisisAtBar(1, false);

      // اگه هنوز هم -1 بود (handle مشکل دارد)، از تخمین FLOW+ADX استفاده کن
      if(crisisBuyVal < 0 || crisisSellVal < 0)
      {
         double th_RedA_ADX,th_RedA_Flow,th_RedB_ADX,th_RedB_Flow;
         double th_OrA_ADX,th_OrA_Flow,th_OrB_ADX,th_OrB_Ts;
         double th_OrC_ADX,th_OrC_Flow,th_OrC_Ts,th_OrD_ADX,th_OrD_Ts;
         double th_Y2_ADX,th_Y2_Flow,th_Y3_Flow,th_Y3_Ts;
         double th_Y4_ADX,th_Y4_Ts,th_Y5_ADX,th_Y5_Flow;
         Crisis_GetThresholds(
            th_RedA_ADX,th_RedA_Flow,th_RedB_ADX,th_RedB_Flow,
            th_OrA_ADX,th_OrA_Flow,th_OrB_ADX,th_OrB_Ts,
            th_OrC_ADX,th_OrC_Flow,th_OrC_Ts,th_OrD_ADX,th_OrD_Ts,
            th_Y2_ADX,th_Y2_Flow,th_Y3_Flow,th_Y3_Ts,
            th_Y4_ADX,th_Y4_Ts,th_Y5_ADX,th_Y5_Flow);

         double adx    = g_lastAdxVal;
         double tScore = (g_csvScore != 0.0) ? g_csvScore : 0.0;
         double faSell = fsSell;
         double faBuy  = -fsBuy;
         double tsAgSell = tScore;    // Sell: trendScore مثبت = بازار علیه Sell
         double tsAgBuy  = -tScore;   // Buy:  trendScore منفی = بازار علیه Buy

         // 🐛 v13.26 FIX3: Orange-D با شرط صحیح tsAgainst > th_OrD_Ts
         if(crisisBuyVal < 0)
         {
            if((faBuy >= th_RedA_Flow && adx > th_RedA_ADX) ||
               (faBuy >= th_RedB_Flow && adx > th_RedB_ADX))
               crisisBuyVal = 2;
            else if((faBuy >= th_OrA_Flow && adx > th_OrA_ADX) ||
                    (tsAgBuy > th_OrD_Ts   && adx > th_OrD_ADX))
               crisisBuyVal = 3;
            else if(faBuy >= th_Y2_Flow && adx > th_Y2_ADX)
               crisisBuyVal = 1;
            else
               crisisBuyVal = 0;
         }

         if(crisisSellVal < 0)
         {
            if((faSell >= th_RedA_Flow && adx > th_RedA_ADX) ||
               (faSell >= th_RedB_Flow && adx > th_RedB_ADX))
               crisisSellVal = 2;
            else if((faSell >= th_OrA_Flow && adx > th_OrA_ADX) ||
                    (tsAgSell > th_OrD_Ts   && adx > th_OrD_ADX))
               crisisSellVal = 3;
            else if(faSell >= th_Y2_Flow && adx > th_Y2_ADX)
               crisisSellVal = 1;
            else
               crisisSellVal = 0;
         }
      }
   }
   else
   {
      // ── پوزیشن واقعی باز (نه virtual): از snapshot های TL_Update استفاده کن ────
      spikeSellVal  = (g_gbnzdSpikeSell  >= 0) ? g_gbnzdSpikeSell  : g_lightSpike;
      spikeBuyVal   = (g_gbnzdSpikeBuy   >= 0) ? g_gbnzdSpikeBuy   : g_lightSpike;
      crisisSellVal = (g_gbnzdCrisisSell >= 0) ? g_gbnzdCrisisSell : g_crisisState;
      crisisBuyVal  = (g_gbnzdCrisisBuy  >= 0) ? g_gbnzdCrisisBuy  : g_crisisState;
      adxSellVal    = (g_gbnzdAdxSell    > 0.0) ? g_gbnzdAdxSell   : g_lastAdxVal;
      adxBuyVal     = (g_gbnzdAdxBuy     > 0.0) ? g_gbnzdAdxBuy    : g_lastAdxVal;
      flowSell      = (g_gbnzdFlowSell   != 0.0) ? g_gbnzdFlowSell : g_lastFlowScore;
      flowBuy       = (g_gbnzdFlowBuy    != 0.0) ? g_gbnzdFlowBuy  : g_lastFlowScore;
   }

   // 🐛 v13.29 FIX3: score جهت‌دار برای نمایش متفاوت Buy/Sell
   string spikeSellStr    = SQ_SpikeLineText(spikeSellVal, spikeSellDisplayScore);
   string spikeBuyStr     = SQ_SpikeLineText(spikeBuyVal,  spikeBuyDisplayScore);
   string spikeRuleSellStr= SQ_SpikeRuleText(spikeSellVal, crisisSellVal,
                                             adxSellVal, flowSell, false);
   string spikeRuleBuyStr = SQ_SpikeRuleText(spikeBuyVal, crisisBuyVal,
                                             adxBuyVal, flowBuy, true);

   // ── ADX ─────────────────────────────────────────────────────────
   string adxStr;
   if(!activeMode)
      adxStr = "⚫  --";
   else
      adxStr = SQ_Light(g_lightTrend)
               + StringFormat("  %.1f  ER=%.2f", g_lastAdxVal, g_lastErH4);

   // ── Flow ────────────────────────────────────────────────────────
   string flowStr;
   if(!activeMode)
      flowStr = "⚫  --";
   else
      flowStr = SQ_Light(g_lightFLOW)
                + StringFormat("  %.2f", g_lastFlowScore);

   // ── Daily / RTM ─────────────────────────────────────────────────
   string dailyStr = activeMode ? SQ_Light(g_lightStruct) : "⚫  --";
   string rtmStr   = activeMode ? SQ_Light(g_lightRTM)    : "⚫  --";

   // ── GBPNZD Rule — 🐛 v13.36 FIX: SQ_SpikeRuleText از state machine جهت‌دار استفاده می‌کنه
   // نمایش Spike Sell Rule / Spike Buy Rule از spikeRuleSellStr / spikeRuleBuyStr (پایین) میاد

   // ── مدت زمان هر جهت در حالت هج ─────────────────────────────────
   string posAgeStr = "";
   if(isHedge)
   {
      // نمایش مدت زمان Buy و Sell جداگانه در هج
      string buyAge = "—", sellAge = "—";
      if(oldest_buy_time > 0)
      {
         int el = (int)(TimeCurrent() - oldest_buy_time);
         int d=el/86400, h=(el%86400)/3600, m=(el%3600)/60;
         if(d > 0)      buyAge = StringFormat("%dd %dh %dm", d, h, m);
         else if(h > 0) buyAge = StringFormat("%dh %dm", h, m);
         else           buyAge = StringFormat("%dm", m);
      }
      if(oldest_sell_time > 0)
      {
         int el = (int)(TimeCurrent() - oldest_sell_time);
         int d=el/86400, h=(el%86400)/3600, m=(el%3600)/60;
         if(d > 0)       sellAge = StringFormat("%dd %dh %dm", d, h, m);
         else if(h > 0)  sellAge = StringFormat("%dh %dm", h, m);
         else            sellAge = StringFormat("%dm", m);
      }
      posAgeStr = "Buy: " + buyAge + " | Sell: " + sellAge;
   }
   else
      posAgeStr = openTimeStr;

   // ── Assemble — دو پیام جداگانه (telegram max ~4096 chars) ────────
   // پیام یک: اطلاعات معامله
   string msg = "";
   msg += "📊 " + sym + " — HelpMe Status\n";
   msg += "────────────────────────\n";
   msg += "Trade:          " + tradeIcon       + "\n";
   msg += "Profit:           " + profitStr       + "\n";
   msg += "Steps:           " + stepsStr        + "\n";
   msg += "Open Time:  "     + posAgeStr       + "\n";   // 🆕 v13.23: مدت هج جداست
   msg += "────────────────────────\n";
   msg += "Trend:          " + trendStr        + "\n";
   msg += "Crisis:          " + crisisStr       + "\n";
   msg += "Hi Alert:       " + hiAlertStr      + "\n";
   msg += "Zone:           " + zombieStr       + "\n";
   msg += "Killer:           " + killerStr       + "\n";
   msg += "MktPhase:  "   + mktPhaseStr    + "\n";   // 🆕 v13.12
   msg += "Spike Sell:   " + spikeSellStr    + "\n";   // 🆕 v13.24
   msg += "Spike Buy:   " + spikeBuyStr     + "\n";   // 🆕 v13.24
   msg += "────────────────────────\n";
   msg += "Spike Sell Rule:  " + spikeRuleSellStr+ "\n";   // 🆕 v13.24
   msg += "Spike Buy Rule:  " + spikeRuleBuyStr + "\n";   // 🆕 v13.24
   msg += "────────────────────────\n";
   msg += "ADX:        " + adxStr          + "\n";
   msg += "Flow:       " + flowStr         + "\n";
   msg += "Daily:       " + dailyStr        + "\n";
   msg += "RTM:        " + rtmStr;

   return msg;
}

// ─── تبدیل \uXXXX در JSON به کاراکتر واقعی ────────────────────────
string SQ_JsonUnescape(const string raw)
{
   string out = "";
   int len = StringLen(raw);
   int i = 0;
   while(i < len)
   {
      ushort c = StringGetCharacter(raw, i);
      if(c == '\\' && i + 1 < len)
      {
         ushort n = StringGetCharacter(raw, i + 1);
         if(n == 'u' && i + 5 < len)
         {
            string hex = StringSubstr(raw, i + 2, 4);
            uint code = 0;
            for(int h = 0; h < 4; h++)
            {
               ushort hc = StringGetCharacter(hex, h);
               code <<= 4;
               if(hc >= '0' && hc <= '9')      code += hc - '0';
               else if(hc >= 'a' && hc <= 'f') code += hc - 'a' + 10;
               else if(hc >= 'A' && hc <= 'F') code += hc - 'A' + 10;
            }
            out += ShortToString((ushort)code);
            i += 6;
            continue;
         }
         else if(n == 'n') { out += "\n"; i += 2; continue; }
         else if(n == 'r') { i += 2; continue; }
         else if(n == 't') { out += "\t"; i += 2; continue; }
         else { out += ShortToString(n); i += 2; continue; }
      }
      out += ShortToString(c);
      i++;
   }
   return out;
}

// ─── بررسی inbox تلگرام برای کلمه «وضعیت» ─────────────────────────
void StatusQuery_PollTelegram()
{
   // 🆕 v13.15 FIX: گارد نهایی — در بکتست هیچ WebRequest واقعی به تلگرام
   // ممکن نیست (بدون اینترنت)؛ صرف نظر از مسیر صدا زدن (OnTick/OnTimer/...)
   // این جلوی لاگ مکرر "StatusQuery: HTTP=-1 err=4014" در بکتست رو میگیره
   if((bool)MQLInfoInteger(MQL_TESTER)) return;

   if(!StatusQuery_Enable)     return;
   if(!Alert_Telegram)         return;
   if(StringLen(Alert_TelegramToken) < 5)  return;
   if(StringLen(Alert_TelegramChatID) < 1) return;

   // V13.10 FIX: اگه داره دکمه پردازش میشه، WebRequest نزن → دکمه‌ها کند نشن
   if(g_processingChartEvent) return;

   // mutex: جلوگیری از اجرای همزمان از OnTimer و OnTick
   if(g_statusPollBusy) return;
   g_statusPollBusy = true;

   // throttle با GetTickCount
   uint nowMs   = GetTickCount();
   uint pollMs  = (uint)MathMax(1, StatusQuery_PollSeconds) * 1000;
   uint elapsed = nowMs - g_lastStatusPollTime;
   if(elapsed < pollMs)
   {
      g_statusPollBusy = false;
      return;
   }

   if(EnableAllLogs)
      Print("StatusQuery: polling Telegram (offset=", g_lastTelegramUpdateId, ")");

   // throttle را اینجا set کن — قبل از WebRequest
   g_lastStatusPollTime = GetTickCount();

   string url = "https://api.telegram.org/bot" + Alert_TelegramToken +
                "/getUpdates?limit=20&timeout=0";
   if(g_lastTelegramUpdateId > 0)
      url += "&offset=" + IntegerToString(g_lastTelegramUpdateId + 1);

   char   result[];
   string resHeaders;
   char   postData[];

   ResetLastError();
   int httpCode = WebRequest("GET", url, "", 1500, postData, result, resHeaders);

   if(httpCode != 200)
   {
      Print("StatusQuery: HTTP=", httpCode, " err=", GetLastError());
      g_statusPollBusy = false;
      return;
   }

   string body = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   long expectedChatId = (long)StringToInteger(Alert_TelegramChatID);
   bool alreadyReplied = false;  // فقط یک reply در هر poll cycle — بقیه skip

   int pos = 0;
   while(true)
   {
      // ── یافتن update_id ──────────────────────────────────────────
      int p_uid = StringFind(body, "\"update_id\":", pos);
      if(p_uid < 0) break;

      int vs = p_uid + 12;
      // رد کردن فاصله‌ها
      while(vs < StringLen(body) && StringGetCharacter(body, vs) == ' ') vs++;
      int ve = vs;
      while(ve < StringLen(body) && StringGetCharacter(body, ve) >= '0' && StringGetCharacter(body, ve) <= '9') ve++;
      long updateId = (long)StringToInteger(StringSubstr(body, vs, ve - vs));

      // آپدیت offset — همیشه حتی اگر پیام مربوطه نباشد
      if(updateId > g_lastTelegramUpdateId)
         g_lastTelegramUpdateId = updateId;

      // ── محدوده این آپدیت (تا update_id بعدی) ────────────────────
      int nextUidPos = StringFind(body, "\"update_id\":", ve);
      int blockEnd   = (nextUidPos > 0) ? nextUidPos : StringLen(body);
      string blk     = StringSubstr(body, p_uid, blockEnd - p_uid);

      // ── استخراج chat.id ─────────────────────────────────────────
      // در JSON تلگرام ساختار: "chat":{"id":12345,...}
      // باید دنبال "chat": بگردیم نه اولین "id":
      long chatId = 0;
      int chatSection = StringFind(blk, "\"chat\":");
      if(chatSection >= 0)
      {
         int cidPos = StringFind(blk, "\"id\":", chatSection);
         if(cidPos >= 0)
         {
            int cs = cidPos + 5;
            while(cs < StringLen(blk) && StringGetCharacter(blk, cs) == ' ') cs++;
            // ممکنه منفی باشه (group chat)
            bool neg = false;
            if(cs < StringLen(blk) && StringGetCharacter(blk, cs) == '-') { neg = true; cs++; }
            int ce = cs;
            while(ce < StringLen(blk) && StringGetCharacter(blk, ce) >= '0' && StringGetCharacter(blk, ce) <= '9') ce++;
            chatId = (long)StringToInteger(StringSubstr(blk, cs, ce - cs));
            if(neg) chatId = -chatId;
         }
      }

      if(ShowDebugLogs)
         Print("StatusQuery: update_id=", updateId, " chat_id=", chatId, " expected=", expectedChatId);

      // ── استخراج text ─────────────────────────────────────────────
      int txtPos = StringFind(blk, "\"text\":\"");
      if(txtPos >= 0)
      {
         int ts = txtPos + 8;
         // پیدا کردن انتهای string — باید escape را هم حساب کنیم
         string msgText = "";
         int ti = ts;
         while(ti < StringLen(blk))
         {
            ushort ch = StringGetCharacter(blk, ti);
            if(ch == '\\') { ti += 2; continue; }  // escape
            if(ch == '"')  break;
            ti++;
         }
         msgText = SQ_JsonUnescape(StringSubstr(blk, ts, ti - ts));
         StringTrimLeft(msgText);
         StringTrimRight(msgText);

         if(ShowDebugLogs)
            Print("StatusQuery: text=[", msgText, "] len=", StringLen(msgText), " chatId=", chatId);

         // ── بررسی کلمه وضعیت ────────────────────────────────────
         // روش مطمئن: چک کردن کد کاراکتر اول «و» = 0x0648
         // و همچنین مقایسه انگلیسی
         string msgLow = msgText;
         StringToLower(msgLow);
         bool isStatus = false;
         // چک انگلیسی
         if(msgLow == "status" || StringFind(msgLow, "status") >= 0)
            isStatus = true;
         // چک فارسی — اگر اولین کاراکتر «و» (0x0648) باشد و طول 5 حرف
         if(!isStatus && StringLen(msgText) >= 5)
         {
            ushort c0 = StringGetCharacter(msgText, 0); // و = 0x0648
            ushort c1 = StringGetCharacter(msgText, 1); // ض = 0x0636
            ushort c2 = StringGetCharacter(msgText, 2); // ع = 0x0639
            ushort c3 = StringGetCharacter(msgText, 3); // ی = 0x06CC
            ushort c4 = StringGetCharacter(msgText, 4); // ت = 0x062A
            if(c0==0x0648 && c1==0x0636 && c2==0x0639 && c3==0x06CC && c4==0x062A)
               isStatus = true;
         }
         // چک کلی — اگر متن حاوی «و»+«ض»+«ع» پشت سر هم بود
         if(!isStatus)
         {
            for(int _si = 0; _si <= StringLen(msgText) - 5; _si++)
            {
               if(StringGetCharacter(msgText,_si)==0x0648 &&
                  StringGetCharacter(msgText,_si+1)==0x0636 &&
                  StringGetCharacter(msgText,_si+2)==0x0639)
               { isStatus = true; break; }
            }
         }

         if(ShowDebugLogs)
            Print("StatusQuery: isStatus=", isStatus,
                  "  c0=", StringGetCharacter(msgText,0),
                  "  chatOk=", (chatId==expectedChatId||expectedChatId==0));

         // ── بررسی chat id ────────────────────────────────────────
         bool chatOk = (chatId == expectedChatId) || (expectedChatId == 0);

         if(isStatus && chatOk)
         {
            static long lastRepliedUpdateId = 0;
            if(updateId == lastRepliedUpdateId || alreadyReplied)
            {
               Print("StatusQuery: skip duplicate reply update_id=", updateId);
            }
            else
            {
               lastRepliedUpdateId = updateId;
               alreadyReplied      = true;
               string report = StatusQuery_BuildReport();
               Alert_SendTelegram(report);
               // V13.10: caption با TF فعلی (H1)
               string _tf = EnumToString((ENUM_TIMEFRAMES)Period());
               StringReplace(_tf, "PERIOD_", "");
               Alert_SendTelegramPhoto(_Symbol + " | " + _tf + " | Score:" + DoubleToString(g_csvScore, 0));
               // V13.10: ارسال چارت‌های M5, M30, D1 (اگه باز باشن)
               Alert_SendExtraCharts(_Symbol);
               Print("StatusQuery: ✅ Replied  update_id=", updateId, "  chat=", chatId);
               // cooldown: بعد از reply، 30 ثانیه poll نرو تا پیام تکراری نیاد
               g_lastStatusPollTime = GetTickCount() + 30000;
            }
         }
         else if(isStatus && !chatOk)
         {
            Print("StatusQuery: ❌ chat_id mismatch — got=", chatId, "  expected=", expectedChatId);
         }
         else if(!isStatus && ShowDebugLogs)
         {
            Print("StatusQuery: not a status request, skipped");
         }

         // ── 🆕 v14.00: کلمه یکی از سه سمبل Rule → وضعیت لحظه‌ای ─────
         // "وضعیت AUDCAD" یا فقط "AUDCAD" یا "audcad" همه کار می‌کنند —
         // فقط باید نام یکی از سه سمبل به‌عنوان substring در متن باشد.
         if(!isStatus && chatOk)
         {
            string odReq = "";
            if(StringFind(msgLow, "audcad") >= 0)      odReq = "AUDCAD";
            else if(StringFind(msgLow, "eurgbp") >= 0) odReq = "EURGBP";
            else if(StringFind(msgLow, "gbpnzd") >= 0) odReq = "GBPNZD";

            if(odReq != "")
            {
               static long lastOdUpdateId = 0;
               if(updateId == lastOdUpdateId || alreadyReplied)
               {
                  Print("StatusQuery: skip duplicate on-demand reply update_id=", updateId);
               }
               else
               {
                  lastOdUpdateId  = updateId;
                  alreadyReplied  = true;
                  if(odReq == CleanSymbol(_Symbol))
                  {
                     // همون سمبل چارت خودمونه → از مسیر status معمولی (کامل‌تر، با عکس) استفاده کن
                     string report2 = StatusQuery_BuildReport();
                     Alert_SendTelegram(report2);
                     string _tf3 = EnumToString((ENUM_TIMEFRAMES)Period());
                     StringReplace(_tf3, "PERIOD_", "");
                     Alert_SendTelegramPhoto(_Symbol + " | " + _tf3 + " | Score:" + DoubleToString(g_csvScore, 0));
                     Alert_SendExtraCharts(_Symbol);
                  }
                  else
                  {
                     // سمبل دیگری‌ست — محاسبه on-demand (async، چند ثانیه طول می‌کشد)
                     OnDemand_RequestSymbol(odReq);
                  }
                  g_lastStatusPollTime = GetTickCount() + 3000;
                  Print("StatusQuery: 🆕 on-demand request=", odReq, "  update_id=", updateId);
               }
            }
         }
      }

      pos = ve;
      if(nextUidPos < 0) break;
   }
   g_statusPollBusy = false;
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.11: EMACross_Check — بررسی کراس EMA25/EMA200 در M15 و M30
// هر ۱۵ دقیقه یکبار از OnTimer صدا زده می‌شود
// بار CPU تقریباً صفر: فقط 2 CopyBuffer در هر تایم‌فریم (4 کال کل)
// کراس = EMA25 از یک طرف EMA200 به طرف دیگر رفته بین کندل[2] و کندل[1]
// EMACross_CleanOnly=true: بدنه کندل باید از EMA200 رد شده باشه (نه فقط سایه)
// Cooldown: هر تایم‌فریم جداگانه، ۴ ساعت (این اتفاق کم میفته — نمی‌خوایم spam بشه)
// ════════════════════════════════════════════════════════════════════
void EMACross_Check()
{
   if(!Alert_OnEMACross)  return;
   if(!Alert_Telegram)    return;
   if(g_isDeinitializing) return;

   // throttle: هر ۱۵ دقیقه یکبار کافیه
   datetime now = TimeCurrent();
   if(now - g_lastEMACrossCheck < 900) return;
   g_lastEMACrossCheck = now;

   // cooldown per TF: 4 ساعت (این سیگنال نادره — spam نمیشه)
   int crossCooldownSec = 4 * 3600;

   // ─── تابع کمکی inline: بررسی کراس برای یک تایم‌فریم ─────────
   // شرط کراس:
   //   کندل[2]: EMA25 یه طرف EMA200 بود
   //   کندل[1]: EMA25 طرف دیگه EMA200 رفت
   // EMACross_CleanOnly: Close[1] هم باید از EMA200 رد شده باشه

   // ─── M15 ─────────────────────────────────────────────────────
   if(g_handleEMA25_M15 != INVALID_HANDLE && g_handleEMA200_M15 != INVALID_HANDLE
      && BarsCalculated(g_handleEMA25_M15)  > 5
      && BarsCalculated(g_handleEMA200_M15) > 5)
   {
      double e25[], e200[];
      ArraySetAsSeries(e25,  true);
      ArraySetAsSeries(e200, true);

      if(CopyBuffer(g_handleEMA25_M15,  0, 1, 2, e25)  == 2 &&
         CopyBuffer(g_handleEMA200_M15, 0, 1, 2, e200) == 2)
      {
         // کندل[2] = index 1 در آرایه (چون از bar1 کپی کردیم، index0=bar1, index1=bar2)
         bool prevAbove = (e25[1] > e200[1]);   // کندل قبلی
         bool currAbove = (e25[0] > e200[0]);   // کندل اخیر بسته‌شده

         bool crossed = (prevAbove != currAbove);

         if(crossed && EMACross_CleanOnly)
         {
            // بدنه کندل[1] باید از EMA200 رد شده باشه
            double closeM15 = iClose(_Symbol, PERIOD_M15, 1);
            double openM15  = iOpen (_Symbol, PERIOD_M15, 1);
            double bodyTop  = MathMax(openM15, closeM15);
            double bodyBot  = MathMin(openM15, closeM15);
            // کراس صعودی: close باید بالای EMA200 باشه
            // کراس نزولی: close باید زیر EMA200 باشه
            if(currAbove && closeM15 < e200[0]) crossed = false;  // سایه رد شد ولی بدنه نه
            if(!currAbove && closeM15 > e200[0]) crossed = false;
         }

         if(crossed && (now - g_lastAlertTime_EMA_M15 > crossCooldownSec))
         {
            g_lastAlertTime_EMA_M15 = now;
            string dir = currAbove ? "📈 صعودی" : "📉 نزولی";
            string msg = StringFormat(
               "📡 EMA Cross | %s\n"
               "M15 | %s\n"
               "━━━━━━━━━━━━━━━━\n"
               "جهت: %s\n"
               "EMA25: %.5f | EMA200: %.5f\n"
               "━━━━━━━━━━━━━━━━\n"
               "سیگنال ورود خوب داره میاد",
               _Symbol, TimeToString(TimeCurrent(), TIME_MINUTES), dir, e25[0], e200[0]);
            Alert_SendTelegram(msg);
            if(EnableAllLogs) Print("📡 v13.11: EMA Cross M15 alert sent | dir=", dir);
         }
      }
   }

   // ─── M30 ─────────────────────────────────────────────────────
   if(g_handleEMA25_M30 != INVALID_HANDLE && g_handleEMA200_M30 != INVALID_HANDLE
      && BarsCalculated(g_handleEMA25_M30)  > 5
      && BarsCalculated(g_handleEMA200_M30) > 5)
   {
      double e25[], e200[];
      ArraySetAsSeries(e25,  true);
      ArraySetAsSeries(e200, true);

      if(CopyBuffer(g_handleEMA25_M30,  0, 1, 2, e25)  == 2 &&
         CopyBuffer(g_handleEMA200_M30, 0, 1, 2, e200) == 2)
      {
         bool prevAbove = (e25[1] > e200[1]);
         bool currAbove = (e25[0] > e200[0]);
         bool crossed   = (prevAbove != currAbove);

         if(crossed && EMACross_CleanOnly)
         {
            double closeM30 = iClose(_Symbol, PERIOD_M30, 1);
            if(currAbove  && closeM30 < e200[0]) crossed = false;
            if(!currAbove && closeM30 > e200[0]) crossed = false;
         }

         if(crossed && (now - g_lastAlertTime_EMA_M30 > crossCooldownSec))
         {
            g_lastAlertTime_EMA_M30 = now;
            string dir = currAbove ? "📈 صعودی" : "📉 نزولی";
            string msg = StringFormat(
               "📡 EMA Cross | %s\n"
               "M30 | %s\n"
               "━━━━━━━━━━━━━━━━\n"
               "جهت: %s\n"
               "EMA25: %.5f | EMA200: %.5f\n"
               "━━━━━━━━━━━━━━━━\n"
               "سیگنال ورود خوب داره میاد",
               _Symbol, TimeToString(TimeCurrent(), TIME_MINUTES), dir, e25[0], e200[0]);
            Alert_SendTelegram(msg);
            if(EnableAllLogs) Print("📡 v13.11: EMA Cross M30 alert sent | dir=", dir);
         }
      }
   }
}

int OnInit()
{
   // ═══════════════════════════════════════════════════════════════════
   // v11.95 CRITICAL FIX: ریست پرچم‌های global که بین OnDeinit→OnInit
   // (هنگام تغییر TF/Symbol) در EAها persist می‌شوند.
   //
   // باگ: بعد از تغییر تایم‌فریم، g_isDeinitializing از OnDeinit قبلی
   // روی true باقی می‌ماند → خط اول OnChartEvent فوراً return می‌کرد
   // → هیچ کلیک دکمه‌ای handler را اجرا نمی‌کرد (MT5 خودش OBJPROP_STATE
   // را toggle می‌کند، پس دکمه ظاهراً «فشرده» می‌ماند تا کلیک بعدی).
   //
   // همین مشکل برای mutexهای g_processingChartEvent و g_recalcBusy هم
   // وجود داشت — اگر OnDeinit وسط یک رویداد قطع می‌شد، true باقی می‌ماندند.
   // ═══════════════════════════════════════════════════════════════════
   g_isDeinitializing          = false;
   g_processingChartEvent      = false;
   g_processingChartEventSince = 0;
   g_recalcBusy                = false;
   g_recalcBusySince           = 0;
   g_statusPollBusy            = false;

   if(EnableAllLogs) Print("🚀 HelpMe v13.20 - Initializing...");

   // --- 0. ذخیره رنگ‌های اصلی چارت قبل از هر تغییری
   g_originalBgColor   = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
   g_originalFgColor   = (color)ChartGetInteger(0, CHART_COLOR_FOREGROUND);
   g_originalGridColor = (color)ChartGetInteger(0, CHART_COLOR_GRID);

   // --- CSL and CM setup
   CSL_Execute();
   CM_Execute();

   // --- 1. Initialize local variables from inputs (defaults)
   localEnableMarketRegime = EnableMarketRegimeDetection;

   // 📊 محاسبه تعداد کندل‌های تاریخچه بر اساس درصد ورودی
   g_maxHistoryBars = (int)(500.0 * MathMax(1, HistoryBarsPercent) / 100.0);
   g_maxHistoryBars = MathMax(50,   g_maxHistoryBars);  // حداقل منطقی
   g_maxHistoryBars = MathMin(5000,  g_maxHistoryBars);  // حداکثر برای حفظ کارایی
   if(EnableAllLogs) Print("📊 HistoryBarsPercent=", HistoryBarsPercent, " → g_maxHistoryBars=", g_maxHistoryBars, " bars");
   localEnableMTF          = EnableMTFConfluence;
   localEnablePriceAction  = EnablePriceActionFilter;
   // v5.0: localEnableNews (AI filter) removed - replaced by S/R button
   // localEnableSR starts FALSE always - user must click button (on-demand design)
   localEnableSR       = false;
   localEnableSmartVol = EnableSmartVolume;  // Init from input (default false)
   // 🆕 v7.0: فیلترهای جدید از inputs
   localEnableFVG    = EnableFVG;
   localEnableLiqSwp = EnableLiqSwp;
   localEnableRTM    = EnableRTM;

   // 🆕 v7.0: ساخت handle EMA200 برای RTM
   if(localEnableRTM || EnableRTM)
   {
      handleRTM_EMA = iMA(_Symbol, PERIOD_CURRENT, RTM_EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(handleRTM_EMA == INVALID_HANDLE)
         Print("⚠️ RTM EMA handle failed - RTM filter inactive");
      else
         Print("✅ RTM EMA", RTM_EMAPeriod, " handle created");
   }

   localMinBodyToATRRatio   = MinBodyToATRRatio;
   localMinEfficiencyRatio  = MinEfficiencyRatio;
   localMinBodyToTotalRatio = MinBodyToTotalRatio;
   localMinBarsBetweenSignals = MinBarsBetweenSignals;
   localArrowOffsetPips = ArrowOffsetPips;

   // --- 2. Load saved button states (BEFORE creating dashboard!)
   LoadButtonStates();
   // Note: LoadButtonStates may have overwritten currentPreset/currentFilterMode
   // with saved values. Only fall back to InitialPreset if nothing was saved.
   // (currentPreset is initialized to InitialPreset at declaration)

   // --- 3. Apply loaded (or initial) preset and filter mode
   ApplyPreset(currentPreset);
   ApplyFilterMode(currentFilterMode);

   // --- 3b. Override ArrowOffset based on ACTUAL chart TF (after ApplyPreset)
   // ApplyPreset sets based on preset name, but user may be on different TF
   // This ensures offset always matches the real chart timeframe
   {
      ENUM_TIMEFRAMES tf = ChartPeriod();
      if     (tf == PERIOD_M1)  localArrowOffsetPips = 1.0;
      else if(tf == PERIOD_M5)  localArrowOffsetPips = 2.0;
      else if(tf == PERIOD_M15) localArrowOffsetPips = 3.0;
      else if(tf == PERIOD_M30) localArrowOffsetPips = 4.0;
      else if(tf == PERIOD_H1)  localArrowOffsetPips = 5.0;
      else if(tf == PERIOD_H4)  localArrowOffsetPips = 6.0;
      else                      localArrowOffsetPips = ArrowOffsetPips;
      if(EnableAllLogs) Print("📏 ArrowOffset set to ", localArrowOffsetPips, " pips for TF=", EnumToString(tf));
   }

   // --- 4. (EA mode: no indicator buffers - arrows drawn as OBJ_ARROW objects)
   // Clear any leftover arrow objects from previous session
   ObjectsDeleteAll(0, LQ_OBJ_PREFIX);
   ObjectsDeleteAll(0, HELPME_ARROW_PREFIX);
   SigMsg_Clear();

   // --- 5. Create core indicator handles (always needed)
   handleFastMA = iMA(_Symbol, PERIOD_CURRENT, FastMA, 0, MODE_EMA, PRICE_CLOSE);
   handleSlowMA = iMA(_Symbol, PERIOD_CURRENT, SlowMA, 0, MODE_EMA, PRICE_CLOSE);
   handleRSI    = iRSI(_Symbol, PERIOD_CURRENT, RSIPeriod, PRICE_CLOSE);
   handleADX    = iADX(_Symbol, PERIOD_CURRENT, ADXPeriod);
   handleBB     = iBands(_Symbol, PERIOD_CURRENT, BBPeriod, 0, BBDeviation, PRICE_CLOSE);
   handleATR    = iATR(_Symbol, PERIOD_CURRENT, ATRPeriod);
   
   // 🆕 v4.0: Fractal handle for Strict mode S/R filter (created once, reused)
   g_handleFractals = iFractals(_Symbol, PERIOD_CURRENT);

   // CSL trend handles - ساخته شده یک بار در OnInit
   // تایم‌فریم‌های ثابت - مستقل از TF فعلی چارت
   handleCSL_H1  = iMA(_Symbol, PERIOD_H1,  34, 0, MODE_EMA, PRICE_CLOSE);
   handleCSL_M30 = iMA(_Symbol, PERIOD_M30, 34, 0, MODE_EMA, PRICE_CLOSE);
   handleCSL_D1  = iMA(_Symbol, PERIOD_D1,  50, 0, MODE_EMA, PRICE_CLOSE);
   handleCSL_M5  = iMA(_Symbol, PERIOD_M5,  20, 0, MODE_EMA, PRICE_CLOSE);
   handleCSL_W1  = iMA(_Symbol, PERIOD_W1,  20, 0, MODE_EMA, PRICE_CLOSE);

   // --- 5b. ایچیموکو handle - همیشه ساخته می‌شود تا در اولین کلیک داده آماده باشد
   handleIchimoku = iIchimoku(_Symbol, PERIOD_CURRENT, 9, 26, 52);
   if(handleIchimoku == INVALID_HANDLE)
      Print("⚠️ Ichimoku handle failed to create");
   else
      Print("📊 Ichimoku handle OK (9,26,52)");

   // --- 6. Create MTF handles ONLY if localEnableMTF is true (after loading states)
   if(localEnableMTF)
   {
      CreateMTFHandles();
      UpdateMTFTrendInfo();  // Populate trend immediately
      if(EnableAllLogs) Print("📊 MTF handles created and trend updated");
   }

   // --- 7. Check core handles
   if(handleFastMA == INVALID_HANDLE || handleSlowMA == INVALID_HANDLE ||
      handleRSI    == INVALID_HANDLE || handleADX    == INVALID_HANDLE ||
      handleBB     == INVALID_HANDLE || handleATR    == INVALID_HANDLE)
   {
      Print("❌ Failed to initialize core indicators!");
      return(INIT_FAILED);
   }

   // --- 8. Initialize weights placeholder (all 1.0 — optimization removed)
   // (nothing to initialize — weights are literal 1.0 in AnalyzeSignal)

   // --- 9. Print AI features summary
   if(EnableAllLogs)
   {
      Print("✅ HelpMe v14.04 initialized!");
      Print("🤖 AI Features:");
      Print("   - Market Regime Detection: ", localEnableMarketRegime ? "ON" : "OFF");
      Print("   - MTF Confluence: ",          localEnableMTF          ? "ON" : "OFF");
      Print("   - Price Action Filter: ",     localEnablePriceAction  ? "ON" : "OFF");
      Print("   - Smart Volume Pro: ",        localEnableSmartVol     ? "ON" : "OFF");
      Print("   - Ichimoku Filter: ",         localEnableIchimoku     ? "ON" : "OFF");
      Print("   - FVG Filter: ",              localEnableFVG          ? "ON" : "OFF");
      Print("   - LiqSwp Filter: ",           localEnableLiqSwp       ? "ON" : "OFF");
      Print("   - RTM (EMA", RTM_EMAPeriod, "): ", localEnableRTM     ? "ON" : "OFF");
      Print("   - S/R Levels: on-demand (click S/R button)");
   }

   // --- 10. Detect GMT offset
   BrokerGMTOffset = DetectBrokerGMTOffset();
   if(EnableAllLogs) Print("📍 Broker GMT Offset: ", BrokerGMTOffset);

   // --- 11. Create dashboard AFTER loading states
   // Dashboard will use the correct localEnable values
   CreateDashboard();

   // --- 12. News system setup
   ArrayResize(g_newsList, 0);
   g_newsCount = 0;
   InitializeImpactTable();
   // v13.13: در بکتست news دانلود نکن — کار نمیکنه و لاگ اضافه میده
   if(!(bool)MQLInfoInteger(MQL_TESTER))
      SmartLoadNews();
   
   // --- 13. Timer: 1 ثانیه برای Liquid Level لحظه‌ای + چک داخلی برای 30 ثانیه و 4 ساعت
   EventSetTimer(1);   // 1s: Liquid Level (other symbols) + 30s: weekend + 4h: news

   // --- 14. پیش‌ساخت همه handle های MA در OnInit
   // هدف: MT5 از همون لحظه شروع data رو از سرور می‌گیره
   // وقتی کاربر دکمه رو میزنه، data آماده‌ست و رسم فوری انجام میشه
   if(g_handleMA_M15 == INVALID_HANDLE) g_handleMA_M15 = iMA(_Symbol, PERIOD_M15, 200, 0, MODE_EMA, PRICE_CLOSE);
   if(g_handleMA_M30 == INVALID_HANDLE) g_handleMA_M30 = iMA(_Symbol, PERIOD_M30, 200, 0, MODE_EMA, PRICE_CLOSE);
   if(g_handleMA_H1  == INVALID_HANDLE) g_handleMA_H1  = iMA(_Symbol, PERIOD_H1,  200, 0, MODE_EMA, PRICE_CLOSE);
   if(g_handleMA_H4  == INVALID_HANDLE) g_handleMA_H4  = iMA(_Symbol, PERIOD_H4,  200, 0, MODE_EMA, PRICE_CLOSE);
   if(g_handleMA_D1  == INVALID_HANDLE) g_handleMA_D1  = iMA(_Symbol, PERIOD_D1,  200, 0, MODE_EMA, PRICE_CLOSE);
   // FEMA: چهار EMA روی تایم‌فریم جاری (ساخته‌شده در OnInit، ریست نمیشن تا TF تغییر کنه)
   if(g_handleFEMA_25  == INVALID_HANDLE) g_handleFEMA_25  = iMA(_Symbol, PERIOD_CURRENT, 25,  0, MODE_EMA, PRICE_CLOSE);
   if(g_handleFEMA_50  == INVALID_HANDLE) g_handleFEMA_50  = iMA(_Symbol, PERIOD_CURRENT, 50,  0, MODE_EMA, PRICE_CLOSE);
   if(g_handleFEMA_100 == INVALID_HANDLE) g_handleFEMA_100 = iMA(_Symbol, PERIOD_CURRENT, 100, 0, MODE_EMA, PRICE_CLOSE);
   if(g_handleFEMA_200 == INVALID_HANDLE) g_handleFEMA_200 = iMA(_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
   Print("📊 MA handles created: M15/M30/H1/H4/D1 - data loading in background...");

   // --- 🆕 v13.11: EMA Cross Alert handles (M15 و M30 — ثابت، مستقل از TF جاری)
   if(Alert_OnEMACross)
   {
      g_handleEMA25_M15  = iMA(_Symbol, PERIOD_M15, 25,  0, MODE_EMA, PRICE_CLOSE);
      g_handleEMA200_M15 = iMA(_Symbol, PERIOD_M15, 200, 0, MODE_EMA, PRICE_CLOSE);
      g_handleEMA25_M30  = iMA(_Symbol, PERIOD_M30, 25,  0, MODE_EMA, PRICE_CLOSE);
      g_handleEMA200_M30 = iMA(_Symbol, PERIOD_M30, 200, 0, MODE_EMA, PRICE_CLOSE);
      if(g_handleEMA25_M15  == INVALID_HANDLE) Print("⚠️ v13.11: EMA25 M15 handle failed");
      if(g_handleEMA200_M15 == INVALID_HANDLE) Print("⚠️ v13.11: EMA200 M15 handle failed");
      if(g_handleEMA25_M30  == INVALID_HANDLE) Print("⚠️ v13.11: EMA25 M30 handle failed");
      if(g_handleEMA200_M30 == INVALID_HANDLE) Print("⚠️ v13.11: EMA200 M30 handle failed");
      else Print("✅ v13.11: EMA Cross handles OK (M15+M30 EMA25/200)");
   }

   // --- 14b. 🆕 v7.0: Traffic Light handles (fixed timeframes, low CPU)
   handleEMA200_H1_TL = iMA  (_Symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
   handleATR_H1_TL    = iATR (_Symbol, PERIOD_H1, ATRPeriod);
   handleADX_H4_TL    = iADX (_Symbol, PERIOD_H4, ADXPeriod);
   handleATR_D1_TL    = iATR (_Symbol, PERIOD_D1, ATRPeriod);
   // handleATR_D1_200 حذف شد v10.5
   if(handleEMA200_H1_TL == INVALID_HANDLE) Print("⚠️ v7.0: TL EMA200 H1 failed");
   if(handleATR_H1_TL    == INVALID_HANDLE) Print("⚠️ v7.0: TL ATR H1 failed");
   if(handleADX_H4_TL    == INVALID_HANDLE) Print("⚠️ v7.0: TL ADX H4 failed");
   if(handleATR_D1_TL    == INVALID_HANDLE) Print("⚠️ v7.0: TL ATR D1 failed");
   else Print("✅ HelpMe: Traffic Light handles OK (H1/H4/D1 fixed TF)");

   // تحریک MT5 برای دانلود داده D1 اضافه (برای S/R و Struct چراغ)
   { double tmp[]; CopyClose(_Symbol, PERIOD_H1, 0, 220, tmp); }

   // تحریک MT5 برای دانلود داده H4 و D1 از سرور (از همون اول)
   // CopyClose مؤثرتر از CopyTime است چون data واقعی قیمت رو درخواست میکنه
   {
      double closeBuf[];
      CopyClose(_Symbol, PERIOD_H4, 0, 300, closeBuf);
      CopyClose(_Symbol, PERIOD_D1, 0, 300, closeBuf);
   }
   g_maRetryNeeded = false;

   if(EnableAllLogs)
   {
      Print("✅ HelpMe: News Subsystem initialized - Monitoring ", _Symbol);
      Print("📊 Fetched ", g_newsCount, " news events");
      Print("⚙️ MinWeightThreshold: ", MinWeightThreshold);
      // v7.1: دیباگ تشخیص حساب سنت — در Expert tab چاپ میشه
      string _dbgCur = AccountInfoString(ACCOUNT_CURRENCY);
      string _dbgSrv = AccountInfoString(ACCOUNT_SERVER);
      double _dbgCS  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      bool   _dbgCent = DetectCentAccount();
      Print("✅ HelpMe v13.22 Ready!");
      Print("🔍 CentDetect | Currency=\"", _dbgCur, "\" | Server=\"", _dbgSrv,
            "\" | ContractSize=", _dbgCS,
            " | IsCentAccount(input)=", IsCentAccount ? "YES" : "NO",
            " | Result=", _dbgCent ? "CENT ÷100 ✅" : "STANDARD x1");
   }

   // --- 🆕 v7.0: ایجاد اولیه چراغ‌های traffic light (خاکستری)
   TL_Create();

   // --- 🆕 v10.6: رسم خطوط Zone در همان لحظه OnInit (بدون نیاز به تیک یا پوزیشن)
   // این باعث می‌شود حتی وقتی بازار بسته است خطوط Zone روی چارت دیده شوند
   if(ShowZoneLines)
   {
      SymbolZoneCfg _zc_init;
      if(Zone_GetCfg(_Symbol, _zc_init))
      {
         double _pip_init = GetPipSize(_Symbol);
         DrawAbsoluteZoneLines(_zc_init.base_low,
                               (double)_zc_init.widthPips * _pip_init,
                               _pip_init, ZoneLineCount, 0);
         if(EnableAllLogs) Print("📐 ZoneLines drawn on init: ", _Symbol,
                                 " base=", _zc_init.base_low,
                                 " width=", _zc_init.widthPips, "pts");
      }
   }

   // --- V11.93 FIX: مقداردهی g_lastChartPeriod برای جلوگیری از تشخیص اشتباه TF change
   // بدون این مقداردهی، اولین OnTick بعد از OnInit همیشه TF change را تشخیص می‌دهد
   // (چون g_lastChartPeriod = PERIOD_CURRENT = 0 است ولی Period() مقدار واقعی دارد)
   // این باعث می‌شد handle ها بلافاصله release و rebuild شوند و ForceRecalculation
   // دو بار اجرا شود — یک بار در OnInit و یک بار در اولین OnTick
   g_lastChartPeriod = Period();

   // ── Status Query: skip همه پیام‌های قبل از اجرای EA ──────────────
   // همه pending رو skip و acknowledge کن
   // 🆕 v13.15 FIX: این یه مسیر WebRequest کاملاً مستقل بود که گارد بکتست نداشت
   // (نه از طریق StatusQuery_PollTelegram، نه از طریق Alert_Send رد میشه)
   if(!(bool)MQLInfoInteger(MQL_TESTER) &&
      StatusQuery_Enable && Alert_Telegram
      && StringLen(Alert_TelegramToken) > 5
      && StringFind(Alert_TelegramToken, "97864663566") < 0)
   {
      string _sqUrl = "https://api.telegram.org/bot" + Alert_TelegramToken +
                      "/getUpdates?limit=100&timeout=0";
      char _sqRes[]; char _sqPost[]; string _sqHdr;
      ArrayResize(_sqPost, 0);
      int _sqHttp = WebRequest("GET", _sqUrl, "", 5000, _sqPost, _sqRes, _sqHdr);
      if(_sqHttp == 200)
      {
         string _sqBody = CharArrayToString(_sqRes, 0, WHOLE_ARRAY, CP_UTF8);
         int _p = 0;
         while(true)
         {
            int _uidPos = StringFind(_sqBody, "\"update_id\":", _p);
            if(_uidPos < 0) break;
            int _uStart = _uidPos + 12;
            while(_uStart < StringLen(_sqBody) && StringGetCharacter(_sqBody,_uStart)==' ') _uStart++;
            int _uEnd = _uStart;
            while(_uEnd < StringLen(_sqBody) && StringGetCharacter(_sqBody,_uEnd)>='0' && StringGetCharacter(_sqBody,_uEnd)<='9') _uEnd++;
            long _uid = (long)StringToInteger(StringSubstr(_sqBody, _uStart, _uEnd - _uStart));
            if(_uid > g_lastTelegramUpdateId) g_lastTelegramUpdateId = _uid;
            _p = _uEnd;
         }
         if(g_lastTelegramUpdateId > 0)
         {
            // acknowledge: تلگرام پیام‌های تا این offset رو از صف پاک میکنه
            string _ackUrl = "https://api.telegram.org/bot" + Alert_TelegramToken +
                             "/getUpdates?limit=1&offset=" + IntegerToString(g_lastTelegramUpdateId + 1);
            char _ackPost[]; char _ackRes[]; string _ackHdr;
            ArrayResize(_ackPost, 0);
            int _ackHttp = WebRequest("GET", _ackUrl, "", 5000, _ackPost, _ackRes, _ackHdr);
            if(EnableAllLogs) Print("StatusQuery ack: HTTP=", _ackHttp);
         }
      }
      Print("StatusQuery: initialized, last update_id=", g_lastTelegramUpdateId);
   }

   // --- v11.1 FIX: رسم فلش‌های تاریخی و "Now" از همان ابتدا
   // قبلاً اکسپرت ۳۰ ثانیه صبر می‌کرد تا اولین OnTimer اجرا شود
   // حالا بلافاصله در OnInit محاسبه می‌کند — بدون نیاز به Reset
   g_ratesTotal = Bars(_Symbol, PERIOD_CURRENT);
   if(g_ratesTotal >= 2)
   {
      ForceRecalculation();
      if(EnableAllLogs) Print("✅ HelpMe: Initial ForceRecalculation done on init");
   }
   UpdateDashboard();   // Now / ساعت / سشن را فوری نمایش بده

   // 🆕 v14.04 FIX-1: g_chartPeriodSeconds باید قبل از GBPNZD_InitReplay مقداردهی شود.
   // دلیل: GBPNZD_GV_Load() (که از GBPNZD_InitReplay صدا زده می‌شود) در gap-fill
   // خود از g_chartPeriodSeconds برای تعیین اندازه قدم استفاده می‌کند.
   // اگه بعد از InitReplay ست شود، gap-fill همیشه با قدم ۳۶۰۰ (H1) کار می‌کند —
   // روی M1 counters خیلی کمتر، روی H4 خیلی بیشتر از واقعیت پر می‌شوند.
   g_chartPeriodSeconds = (int)PeriodSeconds(PERIOD_CURRENT);
   g_lastBarCloseTime   = iTime(_Symbol, PERIOD_CURRENT, 0);
   // 🆕 v14.08 BUG-TF1 FIX: آستانه‌های Rule را به کندل‌های TF فعلی scale کن
   // H1: 2*3600/3600=2 | M1: 2*3600/60=120 | H4: max(1,2*3600/14400)=1
   if(g_chartPeriodSeconds > 0)
   {
      g_ruleStopBars   = (int)MathMax(1, MathRound(2.0  * 3600.0 / g_chartPeriodSeconds));
      g_ruleCloseBars  = (int)MathMax(1, MathRound(6.0  * 3600.0 / g_chartPeriodSeconds));
      g_ruleResumeBars = (int)MathMax(1, MathRound(24.0 * 3600.0 / g_chartPeriodSeconds));
   }
   Print("📊 HelpMe v14.04 — Chart TF: ", EnumToString(PERIOD_CURRENT),
         " (", g_chartPeriodSeconds, "s) | Rule/Spike sync: per-bar-close",
         " | STOP=", g_ruleStopBars, " CLOSE=", g_ruleCloseBars,
         " RESUME=", g_ruleResumeBars, " bars");
   if(PERIOD_CURRENT >= PERIOD_D1)
      Print("⚠️ HelpMe v14.04: Chart TF=", EnumToString(PERIOD_CURRENT),
            " — Rule/Spike delay up to ",
            g_chartPeriodSeconds / 3600, "h. Consider H1/H4.");

   // 🆕 v13.25: بازسازی state واقعی GBPNZD از 24h گذشته
   // باید بعد از ForceRecalculation باشه تا handle ها warm شده باشن
   // 🆕 v14.04: g_chartPeriodSeconds قبل از اینجاست — gap-fill در GV_Load درست کار می‌کند
   if(Alert_OnGBPNZDRule && IsRuleSymbol(_Symbol)
      && !(bool)MQLInfoInteger(MQL_TESTER))
   {
      GBPNZD_InitReplay();
      // 🐛 v13.42 FIX: Replay فقط کندل‌های بسته می‌خونه — ممکنه وسط کندل
      // Crisis/Spike زنده باشه که Replay ندیده. پرچم زیر باعث میشه
      // اولین TL_Update بعد از init، یک‌بار با مقادیر live چک کنه.
      g_gbpnzdNeedsLiveCheck = true;
   }

   return(INIT_SUCCEEDED);
}


void OnTimer()
{
   if(g_isDeinitializing) return;

   // ══════════════════════════════════════════════════════════════
   // تایمر 1 ثانیه‌ای - دو سطح بروزرسانی:
   //   هر 1 ثانیه  : Liquid Level (وقتی نماد دیگری هم پوزیشن دارد)
   //   هر 30 ثانیه : آخر هفته (داشبورد)
   //   هر 4 ساعت   : بررسی اخبار
   // 🆕 v14.03: TL_Update از OnTimer حذف شد — فقط از OnTick (isNewBar)
   // ══════════════════════════════════════════════════════════════
   static int  s_tick30         = 0;   // شمارنده برای 30 ثانیه
   // retry counter آخر هفته: تا ۱۰ بار (هر ۳۰ ثانیه = حداکثر ۵ دقیقه) تا بافرها آماده شوند
   static int  s_weekendRetries = 0; // 0..9 = هنوز تلاش می‌کنه | 10 = موفق شد

   // ── هر 1 ثانیه: Liquid Level با پوزیشن نماد دیگر ─────────────
   // وقتی equity از نماد دیگری تغییر می‌کند، باید لحظه‌ای بروز شود
   if(g_liquidActive && g_otherPosCount_lq > 0)
      UpdateLiquidationLine();

   // 🆕 v14.00: هر 1 ثانیه — اگه یک درخواست FOREIGN on-demand در حال گرم‌شدن
   // است، چک کن. وقتی g_odState==IDLE (یعنی اکثر وقت‌ها) این تابع فوراً
   // برمی‌گرده و هیچ باری اضافه نمی‌کند.
   if(!(bool)MQLInfoInteger(MQL_TESTER))
      OnDemand_Poll();

   // ── هر ۳۰ ثانیه: بررسی‌های دوره‌ای ─────────────────────────────
   s_tick30++;
   if(s_tick30 < 30) return;  // بازه ۳۰ ثانیه‌ای — کاهش فشار CPU و تاخیر دکمه‌ها
   s_tick30 = 0;

   // v11.1 FIX: ریست خودکار mutex‌ها هر ۵ ثانیه
   g_recalcBusy           = false;
   g_processingChartEvent = false;

   // ── Telegram Status Query poll ──────────────────────────────────
   // FIX v12.15f: poll اینجاست — بعد از s_tick30 و بدون EventSetTimer
   // OnTick هم poll میزنه ولی آخر هفته tick نیست — این مسیر پشتیبانه
   if(StatusQuery_Enable && Alert_Telegram)
      StatusQuery_PollTelegram();

   // 🐛 v13.26 FIX2: اگه GBPNZD_InitReplay در OnInit به خاطر handle های warm نشده
   // fail کرده بود، هر ۳۰ ثانیه تا موفقیت دوباره تلاش می‌کنه (حداکثر ۲۰ بار)
   if(Alert_OnGBPNZDRule && IsRuleSymbol(_Symbol)
      && !(bool)MQLInfoInteger(MQL_TESTER)
      && !g_gbpnzdReplayDone
      && g_gbpnzdReplayRetry < 20)
   {
      g_gbpnzdReplayRetry++;
      GBPNZD_InitReplay();
      if(g_gbpnzdReplayDone)
         Print("✅ v13.26 GBPNZD_InitReplay succeeded on retry #", g_gbpnzdReplayRetry);
   }

   // 🆕 v13.11: EMA Cross Alert — هر ۱۵ دقیقه یکبار (throttle داخل تابع)
   EMACross_Check();

   // 🆕 v13.12: Market Phase — هر روز یکبار (throttle داخل تابع)
   Calc_MktPhase();

   // 🆕 v14.03: Calc_SpikeDetector از OnTimer حذف شد.
   // Spike فقط از TL_Update و فقط در بستن کندل چارت محاسبه می‌شود.
   // (داخل بلوک runRuleBlock در TL_Update)

   // بررسی اخبار هر 4 ساعت — v13.15: در بکتست skip (این OnTimer هر تیک صدا میشه)
   if(!(bool)MQLInfoInteger(MQL_TESTER))
   {
      static datetime lastNewsRefresh = 0;
      datetime nowT = TimeCurrent();
      if(nowT - lastNewsRefresh > 4 * 3600)
      {
         lastNewsRefresh = nowT;
         if(!IsCacheValid() || g_newsCount == 0)
         {
            Print("Refresh news...");
            ArrayResize(g_newsList, 0);
            g_newsCount = 0;
            SmartLoadNews();
         }
      }
   }

   // ----- آخر هفته -----
   MqlDateTime gmt;
   TimeToStruct(TimeGMT(), gmt);
   int  gmtDow  = gmt.day_of_week;
   int  gmtHour = gmt.hour;
   bool isWeekend = (gmtDow == 6) ||
                    (gmtDow == 0 && gmtHour < 22) ||
                    (gmtDow == 5 && gmtHour >= 22);

   if(isWeekend)
   {
      // 🔧 FIX v7.1: retry تا 10 بار (هر 30 ثانیه) تا بافرهای اندیکاتور آماده شوند
      if(s_weekendRetries < 10)
      {
         g_ratesTotal = Bars(_Symbol, PERIOD_CURRENT);
         if(g_ratesTotal >= 2)
         {
            ForceRecalculation();
            if(g_cacheSize > 50)
            {
               // بافرها آماده بودن و سیگنال‌ها رسم شدن → دیگه retry نکن
               s_weekendRetries = 10;
               if(EnableAllLogs) Print("Weekend draw OK (cacheSize=", g_cacheSize, ")");
            }
            else
            {
               // بافرها هنوز آماده نیستن → دفعه بعد دوباره امتحان
               s_weekendRetries++;
               if(EnableAllLogs) Print("Weekend retry ", s_weekendRetries, "/10 (cacheSize=", g_cacheSize, ")");
            }
         }
      }
      CSL_Execute();
      UpdateDashboard();
      ChartRedraw(0);
   }
   else
   {
      s_weekendRetries = 0;  // بازار باز شد → ریست برای آخر هفته بعدی
      // هر ۶ دقیقه (۱۲ چرخه ۳۰ثانیه‌ای) سشن آپدیت می‌شود
      // تا ساعت محلی نمایش‌داده‌شده در "Now" تازه بماند
      static int s_sessionRefreshTick = 0;
      s_sessionRefreshTick++;
      if(s_sessionRefreshTick >= 12)
      {
         s_sessionRefreshTick = 0;
         UpdateDashboard();
      }
   }

   // 🆕 v14.03: TL_Update از OnTimer حذف شد.
   // Rule و Spike دیگر از OnTimer صدا زده نمی‌شوند —
   // OnTick با Chart_IsNewBarClosed مسئولیت را دارد.
   // حذف از اینجا از race condition (هرچند در MQL5 سریالی) و
   // محاسبه دوبل جلوگیری می‌کند.
}


// ════════════════════════════════════════════════════════════════════
// v11.7: حذف سخت‌گیرانه آبجکت‌ها در Remove
// نکته: بعضی بیلدهای MT5 بعد از ObjectDelete تصویر label را تا redraw بعدی نگه می‌دارند.
// پس قبل از delete، متن/رنگ را خالی و آبجکت را خارج از صفحه می‌بریم.
// ════════════════════════════════════════════════════════════════════
bool HM_DeleteObjectHard(const long chart_id, const string obj_name)
{
   if(obj_name == "") return false;
   if(ObjectFind(chart_id, obj_name) < 0) return false;

   ResetLastError();
   ObjectSetString (chart_id, obj_name, OBJPROP_TEXT,    "");
   ObjectSetString (chart_id, obj_name, OBJPROP_TOOLTIP, "");
   ObjectSetInteger(chart_id, obj_name, OBJPROP_COLOR,   clrNONE);
   ObjectSetInteger(chart_id, obj_name, OBJPROP_BGCOLOR, clrNONE);
   ObjectSetInteger(chart_id, obj_name, OBJPROP_BACK,    false);
   ObjectSetInteger(chart_id, obj_name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(chart_id, obj_name, OBJPROP_HIDDEN,     true);
   ObjectSetInteger(chart_id, obj_name, OBJPROP_XDISTANCE,  30000);
   ObjectSetInteger(chart_id, obj_name, OBJPROP_YDISTANCE,  30000);

   bool ok = ObjectDelete(chart_id, obj_name);
   if(!ok && EnableAllLogs)
      Print("⚠️ hard-delete failed: ", obj_name, " err=", GetLastError());
   return true;
}

int HM_RemoveHelpMeObjectsPass(const long chart_id)
{
   string _prefixes[] = {
      "ZombieLine_", "ZoneLabel_",
      "XSA_SR_", "HM_LQ_", "MYNEWS_",
      "HMArr_", "HM_MA_", "HM_FEMA_",
      "HM7_LT_", "HM_", dashboardPrefix
   };
   string _contains[] = {
      "StatusLabel", "ProfitLabel", "HM_CRISIS_LIGHT", "CRISIS"
   };
   string _exactNames[] = {
      CRISIS_OBJ, "HM_CRISIS_LIGHT", "StatusLabel", "ProfitLabel", "CRISIS_OBJ"
   };

   int removed = 0;
   for(int _oi = ObjectsTotal(chart_id, 0, -1) - 1; _oi >= 0; _oi--)
   {
      string _onm = ObjectName(chart_id, _oi, 0, -1);
      bool _match = false;
      for(int _pi = 0; _pi < ArraySize(_prefixes); _pi++)
      {
         if(StringLen(_prefixes[_pi]) > 0 && StringFind(_onm, _prefixes[_pi]) == 0)
         {
            _match = true;
            break;
         }
      }
      if(!_match)
      {
         for(int _ci = 0; _ci < ArraySize(_contains); _ci++)
         {
            if(StringFind(_onm, _contains[_ci]) >= 0)
            {
               _match = true;
               break;
            }
         }
      }
      if(_match)
      {
         if(HM_DeleteObjectHard(chart_id, _onm)) removed++;
      }
   }

   for(int _ei = 0; _ei < ArraySize(_exactNames); _ei++)
   {
      if(HM_DeleteObjectHard(chart_id, _exactNames[_ei])) removed++;
   }

   return removed;
}

void OnDeinit(const int reason)
{
   // v11.7: اول از همه EA را وارد حالت حذف کن تا OnTick/OnTimer/OnChartEvent
   // هیچ StatusLabel یا HM_CRISIS_LIGHT جدیدی نسازند.
   g_isDeinitializing = true;
   EventKillTimer();
   OnDemand_Cleanup();   // 🆕 v14.00: آزادسازی handle های موقت اگه درخواستی نیمه‌کاره مونده باشه

   // FIX v7.0: ریست mutex در ابتدا - اگه EA وسط ForceRecalculation کرش کنه، EA فلج نمیشه
   g_recalcBusy           = false;
   g_processingChartEvent = false;
   g_minimalMode          = false;

   // ═══════════════════════════════════════════════════════════════════
   // 🆕 v11.5 EARLY SWEEP: قبل از هر کار دیگه، همه اشیاء HelpMe پاک شوند
   // علت: اگر هر کدام از فراخوانی‌های زیر error/exception بدهند، باقی کارها
   // اجرا نمی‌شوند و خطوط روی چارت می‌مانند. این sweep تضمینی است.
   // ═══════════════════════════════════════════════════════════════════
   {
      // v11.7: استفاده از hard-delete؛ قبل از حذف، متن label خالی می‌شود.
      HM_RemoveHelpMeObjectsPass(0);
      ChartRedraw(0);
   }


   // 🆕 بکتست: حالت Minimal خودکار (فلش‌ها رسم نمی‌شوند → سرعت بیشتر)
   if((bool)MQLInfoInteger(MQL_TESTER))
      g_minimalMode = true;

   EventKillTimer();
   if(handleFastMA != INVALID_HANDLE) IndicatorRelease(handleFastMA);
   if(handleSlowMA != INVALID_HANDLE) IndicatorRelease(handleSlowMA);
   if(handleRSI != INVALID_HANDLE) IndicatorRelease(handleRSI);
   if(handleADX != INVALID_HANDLE) IndicatorRelease(handleADX);
   if(handleBB != INVALID_HANDLE) IndicatorRelease(handleBB);
   if(handleATR != INVALID_HANDLE) IndicatorRelease(handleATR);
   if(g_handleFractals != INVALID_HANDLE) IndicatorRelease(g_handleFractals); // 🆕 v4.0
   if(handleCSL_H1  != INVALID_HANDLE) IndicatorRelease(handleCSL_H1);
   if(handleCSL_M30 != INVALID_HANDLE) IndicatorRelease(handleCSL_M30);
   if(handleCSL_D1  != INVALID_HANDLE) IndicatorRelease(handleCSL_D1);
   if(handleCSL_M5  != INVALID_HANDLE) IndicatorRelease(handleCSL_M5);
   if(handleCSL_W1  != INVALID_HANDLE) IndicatorRelease(handleCSL_W1);
   if(handleIchimoku  != INVALID_HANDLE) IndicatorRelease(handleIchimoku);
   // 🆕 v7.0: آزاد کردن handle RTM
   if(handleRTM_EMA   != INVALID_HANDLE) { IndicatorRelease(handleRTM_EMA); handleRTM_EMA = INVALID_HANDLE; }
   // 🆕 v7.0: آزاد کردن handle های Traffic Lights
   if(handleEMA200_H1_TL != INVALID_HANDLE) { IndicatorRelease(handleEMA200_H1_TL); handleEMA200_H1_TL = INVALID_HANDLE; }
   if(handleATR_H1_TL    != INVALID_HANDLE) { IndicatorRelease(handleATR_H1_TL);    handleATR_H1_TL    = INVALID_HANDLE; }
   if(handleADX_H4_TL    != INVALID_HANDLE) { IndicatorRelease(handleADX_H4_TL);    handleADX_H4_TL    = INVALID_HANDLE; }
   if(handleATR_D1_TL    != INVALID_HANDLE) { IndicatorRelease(handleATR_D1_TL);    handleATR_D1_TL    = INVALID_HANDLE; }
   // 🆕 v13.11: آزاد کردن handle های EMA Cross
   if(g_handleEMA25_M15  != INVALID_HANDLE) { IndicatorRelease(g_handleEMA25_M15);  g_handleEMA25_M15  = INVALID_HANDLE; }
   if(g_handleEMA200_M15 != INVALID_HANDLE) { IndicatorRelease(g_handleEMA200_M15); g_handleEMA200_M15 = INVALID_HANDLE; }
   if(g_handleEMA25_M30  != INVALID_HANDLE) { IndicatorRelease(g_handleEMA25_M30);  g_handleEMA25_M30  = INVALID_HANDLE; }
   if(g_handleEMA200_M30 != INVALID_HANDLE) { IndicatorRelease(g_handleEMA200_M30); g_handleEMA200_M30 = INVALID_HANDLE; }
   // handleATR_D1_200 حذف شد v10.5
   // حذف اشیاء چراغ‌ها
   ObjectsDeleteAll(0, LIGHT_OBJ_PREFIX);   // چراغ‌های قدیمی (اگه باشن)
   HM_DeleteObjectHard(0, CRISIS_OBJ);       // چراغ CRISIS (v8.2)
   ObjectsDeleteAll(0, dashboardPrefix);      // تمام اشیاء داشبورد (labels, buttons, TL)
   // 🆕 v13.12: ریست Market Phase
   g_lightMktPhase = -1;   g_mktPhasePrev = -1;
   g_mktPhaseRatio = 0.0;  g_mktPhaseLastChange = 0;
   g_prevAlertMKTPHASE = -1; g_lastAlertTime_MKTPHASE = 0;
   // 🆕 v13.14: ریست Spike Detector
   g_lightSpike = -1;      g_spikeScore = 0.0;
   g_prevAlertSPIKE = -1;  g_lastAlertTime_SPIKE = 0;
   g_prevAlertSpikeFlowRed = false; g_lastAlertTime_SpikeFlowRed = 0;   // 🆕 v13.19

   ReleaseMTFHandles();

   DeleteDashboard();
   Comment("");
   ObjectsDeleteAll(0, "MYNEWS_");
   ObjectsDeleteAll(0, SR_OBJ_PREFIX);
   ArrayResize(g_newsList, 0);
   g_newsCount = 0;
   HM_DeleteObjectHard(0, "StatusLabel");
   HM_DeleteObjectHard(0, "ProfitLabel");
   Comment("");

   // FIX v7.0: حذف صریح فلش‌ها و خطوط خبری (قبل از loop دستی)
   // 🆕 v8.0 FIX: حذف اشیاء Liquid Level هنگام حذف EA از چارت
   ObjectsDeleteAll(0, LQ_OBJ_PREFIX);
   ObjectsDeleteAll(0, HELPME_ARROW_PREFIX);
   SigMsg_Clear();
   ObjectsDeleteAll(0, "MYNEWS_");
   ObjectsDeleteAll(0, FEMA_OBJ_PREFIX);
   // v10.3.1: پاک کردن خطوط Zone (v11.4: بدون شرط — همیشه پاک کن)
   DeleteZoneLines();

   // FIX v7.0: حذف مطمئن فلش‌ها با loop دستی
   // دلیل: ObjectsDeleteAll(0, prefix) در بعضی بیلدهای MT5 داخل OnDeinit
   // silent fail میده و فلش‌ها روی چارت میمونن
   for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
   {
      string _nm = ObjectName(0, i, 0, -1);
      if(StringFind(_nm, HELPME_ARROW_PREFIX) == 0)
         ObjectDelete(0, _nm);
   }
   // 💧 LIQUID LEVEL: حذف مطمئن با loop دستی (ObjectsDeleteAll در OnDeinit گاهی fail میشه)
   for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
   {
      string _nm = ObjectName(0, i, 0, -1);
      if(StringFind(_nm, LQ_OBJ_PREFIX) == 0)
         ObjectDelete(0, _nm);
   }
   // 🔧 FIX v7.2: حذف مطمئن خطوط خبری با loop دستی
   // باگ قدیمی: ObjectsDeleteAll(0,"MYNEWS_") در OnDeinit روی بعضی بیلدهای MT5
   // silent fail می‌داد و خطوط خبری روی چارت می‌ماندند
   for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
   {
      string _nm = ObjectName(0, i, 0, -1);
      if(StringFind(_nm, "MYNEWS_") == 0)
         ObjectDelete(0, _nm);
   }

   // Save button states before ANY kind of deinit
   if(reason != REASON_REMOVE)
      SaveButtonStates();

   // بازگردانی رنگ‌های اصلی چارت (همیشه - حتی تایم‌فریم عوض شه)
   // v11.3 FIX: رنگ اصلی ذخیره‌شده اگه black باشه از clrBlack استفاده کن
   color _restoreBg = (g_originalBgColor != 0) ? g_originalBgColor : clrBlack;
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, _restoreBg);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, g_originalFgColor);
   ChartSetInteger(0, CHART_COLOR_GRID,       g_originalGridColor);

   // پاکسازی خطوط MA
   DrawOrClearAllMAs(false);
   ReleaseMAHandles();
   // 🔧 FIX v11.3: حذف مطمئن خطوط MA با loop دستی
   // DrawOrClearAllMAs(false) بعضی اوقات در OnDeinit خطوط MA رو پاک نمی‌کنه
   // (مشابه مشکل فلش‌ها که قبلاً با loop دستی حل شد)
   ObjectsDeleteAll(0, MA_OBJ_PREFIX);
   ObjectsDeleteAll(0, FEMA_OBJ_PREFIX);
   for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
   {
      string _nm = ObjectName(0, i, 0, -1);
      if(StringFind(_nm, MA_OBJ_PREFIX)   == 0) ObjectDelete(0, _nm);
      if(StringFind(_nm, FEMA_OBJ_PREFIX) == 0) ObjectDelete(0, _nm);
   }

   // When EA is REMOVED from chart, clear saved states
   if(reason == REASON_REMOVE)
   {
      // v11.3 FIX: ریست رنگ چارت هنگام REMOVE (قبل از پاکسازی state)
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, g_originalBgColor);
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, g_originalFgColor);
      ChartSetInteger(0, CHART_COLOR_GRID,       g_originalGridColor);
      
      string prefix = "HelpMe_" + _Symbol + "_" + IntegerToString(ChartID()) + "_";
      GlobalVariableDel(prefix + "Price");
      GlobalVariableDel(prefix + "MTF");
      GlobalVariableDel(prefix + "Regime");
      GlobalVariableDel(prefix + "Ichi");
      GlobalVariableDel(prefix + "SmartVol");
      // 🔧 FIX v11.3: این سه کلید در نسخه‌های قبلی فراموش شده بودند
      GlobalVariableDel(prefix + "FVG");
      GlobalVariableDel(prefix + "LiqSwp");
      GlobalVariableDel(prefix + "RTM");
      GlobalVariableDel(prefix + "Preset");
      GlobalVariableDel(prefix + "FilterMode");
      GlobalVariableDel(prefix + "DirMode");
      // v5.0: News AI filter removed; S/R is on-demand (no saved state needed)
      if(EnableAllLogs) Print("🗑️ HelpMe: Saved states cleared on remove");
   }

   // 🆕 v11.7 FIX: SWEEP نهایی — hard-delete + blank-before-delete
   // این pass عمداً چند بار اجرا می‌شود تا اگر MT5 حین Deinit آبجکتی را دوباره ساخت،
   // همان لحظه متنش خالی و خودش حذف شود.
   {
      int _totalSwept = 0;
      for(int _pass = 0; _pass < 5; _pass++)
      {
         _totalSwept += HM_RemoveHelpMeObjectsPass(0);
         ChartRedraw(0);
      }
      if(EnableAllLogs && _totalSwept > 0)
         Print("🧹 HelpMe OnDeinit hard-sweep: ", _totalSwept, " stray objects removed/blanked");
   }

   // FIX v7.0: ChartRedraw آخرین خط - بعد از تمام حذف‌ها
   // MT5 بعد از OnDeinit ممکنه state قبل از آخرین ChartRedraw رو نشون بده
   ChartRedraw(0);
}

void OnTick()
{
   if(g_isDeinitializing) return;

   // 🐛 v13.31 FIX1: StatusQuery_PollTelegram از OnTick حذف شد!
   // WebRequest بلاکینگ با timeout=1500ms در هر تیک = کندی کل EA.
   // حالا فقط در OnTimer (هر 30 ثانیه) poll میزنه — بدون بلاک تیک.
   // (کد قبلی: StatusQuery_PollTelegram() در هر تیک)

   // ── EA equivalent of OnCalculate ────────────────────────────────
   int rates_total    = Bars(_Symbol, PERIOD_CURRENT);
   int prev_calculated = g_prevCalculated;
   
   // حداقل ۱ کندل لازمه تا در آخر هفته هم اجرا شود
   if(rates_total < 1) return;
   
   // Copy price data (newest first, index 0 = current bar)
   datetime time[];       ArraySetAsSeries(time,       true);
   double   open[];       ArraySetAsSeries(open,       true);
   double   high[];       ArraySetAsSeries(high,       true);
   double   low[];        ArraySetAsSeries(low,        true);
   double   close[];      ArraySetAsSeries(close,      true);
   long     tick_volume[];ArraySetAsSeries(tick_volume,true);
   
   // بر اساس g_maxHistoryBars (از HistoryBarsPercent)
   int barsToFetch = (prev_calculated == 0) ? MathMin(g_maxHistoryBars + 2, rates_total) : 3;
   if(CopyTime (_Symbol, PERIOD_CURRENT, 0, barsToFetch, time)       < 1) return;
   if(CopyOpen (_Symbol, PERIOD_CURRENT, 0, barsToFetch, open)       < 1) return;
   if(CopyHigh (_Symbol, PERIOD_CURRENT, 0, barsToFetch, high)       < 1) return;
   if(CopyLow  (_Symbol, PERIOD_CURRENT, 0, barsToFetch, low)        < 1) return;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, barsToFetch, close)      < 1) return;
   if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, barsToFetch, tick_volume) < 1) return;

   // Price arrays already set as series in declarations above
   // (no indicator buffers in EA mode)

   // --- تشخیص تغییر تایم‌فریم → recalc کامل
   ENUM_TIMEFRAMES currentPeriod = Period();
   if(currentPeriod != g_lastChartPeriod)
   {
      g_lastChartPeriod = currentPeriod;
      // تغییر تایم‌فریم → mutex های احتمالی گیرکرده را آزاد کن
      g_processingChartEvent      = false;
      g_processingChartEventSince = 0;
      g_recalcBusy                = false;
      // ── FEMA ریست: handle قدیمی آزاد، دکمه خاموش، خطوط پاک ──
      if(g_femaActive)
      {
         g_femaActive = false;
         DrawOrClearFEMA(false);
         string femaBtn = dashboardPrefix + "MABtn_FEMA";
         ObjectSetInteger(0, femaBtn, OBJPROP_BGCOLOR, clrDarkSlateGray);
      }
      // handle های FEMA با TF جدید ساخته بشن
      if(g_handleFEMA_25  != INVALID_HANDLE) { IndicatorRelease(g_handleFEMA_25);  g_handleFEMA_25  = INVALID_HANDLE; }
      if(g_handleFEMA_50  != INVALID_HANDLE) { IndicatorRelease(g_handleFEMA_50);  g_handleFEMA_50  = INVALID_HANDLE; }
      if(g_handleFEMA_100 != INVALID_HANDLE) { IndicatorRelease(g_handleFEMA_100); g_handleFEMA_100 = INVALID_HANDLE; }
      if(g_handleFEMA_200 != INVALID_HANDLE) { IndicatorRelease(g_handleFEMA_200); g_handleFEMA_200 = INVALID_HANDLE; }
      g_handleFEMA_25  = iMA(_Symbol, currentPeriod, 25,  0, MODE_EMA, PRICE_CLOSE);
      g_handleFEMA_50  = iMA(_Symbol, currentPeriod, 50,  0, MODE_EMA, PRICE_CLOSE);
      g_handleFEMA_100 = iMA(_Symbol, currentPeriod, 100, 0, MODE_EMA, PRICE_CLOSE);
      g_handleFEMA_200 = iMA(_Symbol, currentPeriod, 200, 0, MODE_EMA, PRICE_CLOSE);
      // ── Core indicator handles ریست: handles قبلی آزاد، با TF جدید ساخته می‌شوند ──
      // بدون این، سیگنال‌ها بعد از تغییر TF از داده TF قدیمی محاسبه می‌شوند
      if(handleFastMA  != INVALID_HANDLE) { IndicatorRelease(handleFastMA);  handleFastMA  = INVALID_HANDLE; }
      if(handleSlowMA  != INVALID_HANDLE) { IndicatorRelease(handleSlowMA);  handleSlowMA  = INVALID_HANDLE; }
      if(handleRSI     != INVALID_HANDLE) { IndicatorRelease(handleRSI);     handleRSI     = INVALID_HANDLE; }
      if(handleADX     != INVALID_HANDLE) { IndicatorRelease(handleADX);     handleADX     = INVALID_HANDLE; }
      if(handleBB      != INVALID_HANDLE) { IndicatorRelease(handleBB);      handleBB      = INVALID_HANDLE; }
      if(handleATR     != INVALID_HANDLE) { IndicatorRelease(handleATR);     handleATR     = INVALID_HANDLE; }
      if(handleIchimoku!= INVALID_HANDLE) { IndicatorRelease(handleIchimoku);handleIchimoku= INVALID_HANDLE; }
      if(g_handleFractals != INVALID_HANDLE) { IndicatorRelease(g_handleFractals); g_handleFractals = INVALID_HANDLE; }
      if(handleRTM_EMA != INVALID_HANDLE && localEnableRTM)
         { IndicatorRelease(handleRTM_EMA); handleRTM_EMA = INVALID_HANDLE; }
      // recreate با TF جدید
      handleFastMA    = iMA(_Symbol, currentPeriod, FastMA, 0, MODE_EMA, PRICE_CLOSE);
      handleSlowMA    = iMA(_Symbol, currentPeriod, SlowMA, 0, MODE_EMA, PRICE_CLOSE);
      handleRSI       = iRSI(_Symbol, currentPeriod, RSIPeriod, PRICE_CLOSE);
      handleADX       = iADX(_Symbol, currentPeriod, ADXPeriod);
      handleBB        = iBands(_Symbol, currentPeriod, BBPeriod, 0, BBDeviation, PRICE_CLOSE);
      handleATR       = iATR(_Symbol, currentPeriod, ATRPeriod);
      handleIchimoku  = iIchimoku(_Symbol, currentPeriod, 9, 26, 52);
      g_handleFractals= iFractals(_Symbol, currentPeriod);
      if(localEnableRTM) handleRTM_EMA = iMA(_Symbol, currentPeriod, RTM_EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      g_prevCalculated = 0;  // force full recalc on next tick
      // MA handles زنده می‌مانند (تایم‌فریم‌های ثابت، مستقل از چارت)
      ForceRecalculation();
      DrawOrClearAllMAs(true, true);  // تغییر TF: همیشه force redraw
      return;
   }

   // Update global for AnalyzeSignal (CopyBuffer uses same index now)
   g_ratesTotal = rates_total;

   // --- New bar detection
   datetime currentBarTime = time[0];
   bool isNewBar = (currentBarTime != lastBarTime);
   
   // 🆕 v14.03: در اولین تیک هر کندل جدید g_lastBarCloseTime و g_isNewChartBar آپدیت می‌شوند
   // هر دو باید قبل از CSL_Execute ست شوند تا Rule/Spike/Crisis gate درست کار کند
   if(isNewBar) { Chart_IsNewBarClosed(); g_isNewChartBar = true; }
   if(isNewBar)
   {
      lastBarTime = currentBarTime;
      // ردیابی زمانی: datetime ذخیره می‌شه نه index
      CSL_Execute();          // Full: trend calc + background color + profit (new bar only)
      DrawOrClearAllMAs(true); // آنتی‌فلیکر: فقط TFهایی که کندل جدید دارند redraw میشن
      // CPU: ER فقط روی کندل جدید کش می‌شود (نه هر ثانیه در UpdateDashboard)
      g_cachedER = CalculateEfficiencyRatio(RegimeCalculationBars);
   }
   else
   {
      CSL_UpdateProfitOnly(); // Lightweight: real-time profit P/L update (every tick)
      // V13.10 FIX: در حالت مجازی (Buy/Sell بدون پوزیشن) هر کندل جدیدی که نیست
      // باید رنگ چارت و ترند آپدیت بشه تا فوری واکنش نشون بده
      if(g_dirMode != 0)
      {
         static datetime s_lastVirtualUpdate = 0;
         datetime _now = TimeCurrent();
         if(_now - s_lastVirtualUpdate >= 2)  // هر ۲ ثانیه یکبار کافیه
         {
            s_lastVirtualUpdate = _now;
            CSL_Execute();
         }
      }
   }

   // --- retry MA اگه قبلاً data آماده نبود
   // هر tick چک میکنه - وقتی MT5 data رو از سرور گرفت فوری رسم میشه
   if(g_maRetryNeeded)
   {
      g_maRetryNeeded = false;
      DrawOrClearAllMAs(true, true);  // retry: force redraw
   }

   if(rates_total < 100) return;

   int start;

   // --- Determine processing range
   // Normal incremental update or first load
      if(prev_calculated == 0)
      {
         // First run – process up to g_maxHistoryBars back (از HistoryBarsPercent input)
         // 🔧 FIX v7.4: 500 hard-code → g_maxHistoryBars (dynamic)
         start = MathMin(g_maxHistoryBars, rates_total - 2);
         if(start < 1) start = 1;

         // EA mode: clear all arrow objects on first load (full rescan)
         ObjectsDeleteAll(0, HELPME_ARROW_PREFIX);
         SigMsg_Clear();

         lastBuyTime = 0;
         lastSellTime = 0;
         todaySignalCount = 0;

         // v4.0: SmartVol replaced SelfOpt - no weight optimization
      }
      else
      {
         // Incremental: only recheck the last closed bar (index 1 with AsSeries)
         start = 1;
      }

   // --- Market regime detection (once per bar, if enabled)
   if(localEnableMarketRegime && prev_calculated != rates_total)
   {
      currentRegime = DetectMarketRegime(RegimeCalculationBars);
      if(ShowScoreInfo)
         Print("🌊 Market Regime: ", EnumToString(currentRegime.regime),
               " | ER:", DoubleToString(GetCurrentEfficiencyRatio(), 3),
               " | Volatility:", DoubleToString(currentRegime.volatilityRatio, 2));
   }

   // --- Load news events for WebRequest news lines (unchanged from v4)
   // v13.13: در بکتست skip — WebRequest در بکتست کار نمیکنه
   if(prev_calculated == 0 && !(bool)MQLInfoInteger(MQL_TESTER))
      LoadNewsEvents();

   // --- Update MTF trend info if enabled (new bar only)
   if(isNewBar && localEnableMTF)
      UpdateMTFTrendInfo();

   // 🆕 v4.0: All cache filling + signal loop extracted into RunSignalLoop()
   // This allows direct calls from ForceRecalculation (no more "wait for next tick" bug)
   // 🧹 Minimal Mode: وقتی فعاله، RunSignalLoop رو رد کن تا فلش دوباره رسم نشه
   if(!g_minimalMode)
      RunSignalLoop(start, time, open, high, low, close, tick_volume);

   // 🔧 FIX v7.4: رفع «داده ناکافی» در شروع اکسپرت
   // OnTick بعد از اجرای موفق RunSignalLoop وضعیت را اصلاح می‌کند — بدون نیاز به Reset
   if(g_cacheSize > 0 && StringFind(g_eaStatus, "⚠️") >= 0)
      g_eaStatus = "✅ آماده";


   // --- Update dashboard (new bar or forced – saves CPU on every tick)
   if(isNewBar || g_forceUpdateDashboard)
   {
      g_forceUpdateDashboard = false;
      UpdateDashboard();
   }

   // 🩹 Patch 1 (V12.06): به‌روزرسانی لحظه‌ای P/L بدون throttle (هر تیک)
   UpdateProfitLabel();

   g_prevCalculated = rates_total;
   // 🆕 v14.03: ریست پرچم کندل بسته در پایان هر OnTick
   // این تضمین می‌کند که TL_Update از OnTimer (که قبلاً هر 30 ثانیه بود)
   // نمی‌تواند در وسط کندل Rule/Spike/Crisis را فعال کند
   g_isNewChartBar = false;
}


   

//+------------------------------------------------------------------+
//| CREATE SIGNAL ARROW (EA mode - replaces indicator buffers)       |
//+------------------------------------------------------------------+
void CreateSignalArrow(datetime barTime, double price, int arrowCode,
                       color arrowColor, int arrowWidth, string typeTag)
{
   // typeTag: "BH","BM","BL" (buy high/mid/low) or "SH","SM","SL" (sell)
   string name = HELPME_ARROW_PREFIX + typeTag + "_" + IntegerToString((int)barTime);
   if(ObjectFind(0, name) >= 0) return;
   ObjectCreate(0, name, OBJ_ARROW, 0, barTime, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE,  arrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR,      arrowColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      arrowWidth);
   ObjectSetInteger(0, name, OBJPROP_BACK,       true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   // tooltip will be set by CreateSignalLabel (Part B)
}

//+------------------------------------------------------------------+
//| v12.04: حداکثر امتیاز ممکن سیگنال بر اساس Filter Mode فعلی       |
//|   Easy   (Relaxed)  → 25                                          |
//|   Normal (Balanced) → 30                                          |
//|   Hard   (Strict)   → 35                                          |
//+------------------------------------------------------------------+
int GetMaxSignalScore()
{
   switch(currentFilterMode)
   {
      case MODE_RELAXED:  return 25;
      case MODE_BALANCED: return 30;
      case MODE_STRICT:   return 35;
   }
   return 30;
}

//+------------------------------------------------------------------+
//| v12.04: CREATE SIGNAL LABEL (High/Mid/Low) + بزرگ‌نمایی آیکن ❓    |
//|         + Tooltip اصلاح‌شده (Score: X / MaxOfMode)                |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| v12.05: ذخیره / بازیابی متن کامل سیگنال در حافظه (بدون محدودیت)|
//+------------------------------------------------------------------+
void SigMsg_Store(datetime t, const string &txt)
{
   int n = ArraySize(g_sigMsgTimes);
   // اگر قبلاً همین timestamp بود، آپدیت کن
   for(int i = 0; i < n; i++)
      if(g_sigMsgTimes[i] == t) { g_sigMsgTexts[i] = txt; return; }
   // وگرنه اضافه کن
   ArrayResize(g_sigMsgTimes, n + 1);
   ArrayResize(g_sigMsgTexts, n + 1);
   g_sigMsgTimes[n] = t;
   g_sigMsgTexts[n] = txt;
}

string SigMsg_Get(datetime t)
{
   int n = ArraySize(g_sigMsgTimes);
   for(int i = 0; i < n; i++)
      if(g_sigMsgTimes[i] == t) return g_sigMsgTexts[i];
   return "";
}

void SigMsg_Clear()
{
   ArrayFree(g_sigMsgTimes);
   ArrayFree(g_sigMsgTexts);
}

void CreateSignalLabel(datetime barTime, double price, string level,
                       bool forBuy, int score,
                       double openP, double closeP, double rsiV,
                       double adxV, double fastMAV, double slowMAV,
                       const int &filterContrib[])
{
   string prefix = forBuy ? "BLbl_" : "SLbl_";
   string name   = HELPME_ARROW_PREFIX + prefix + IntegerToString((int)barTime);
   if(ObjectFind(0, name) >= 0) return;

   // فاصله کمتر از v12.1 — label چسبیده به فلش
   double atrUnit     = (g_cacheSize > 1 && ArraySize(g_atr) > 1) ? g_atr[1] : 0.0;
   double closeOffset = (barTime > 0 && handleATR != INVALID_HANDLE) ? atrUnit * 0.15 : 0.0;
   double lblPrice    = forBuy ? price - closeOffset : price + closeOffset;

   // ── Label A : فقط متن سطح سیگنال (High / Mid / Low) بدون ❓ ──────
   ObjectCreate(0, name, OBJ_TEXT, 0, barTime, lblPrice);
   ObjectSetString (0, name, OBJPROP_TEXT,      level);
   ObjectSetString (0, name, OBJPROP_FONT,      "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE,  8);
   ObjectSetInteger(0, name, OBJPROP_COLOR,     forBuy ? clrLime : clrRed);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR,    forBuy ? ANCHOR_UPPER : ANCHOR_LOWER);
   ObjectSetInteger(0, name, OBJPROP_BACK,      true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);

   // ── Build tooltip — split into two parts to bypass MT5 ~250-char limit ──
   // Part 1 (روی label): اطلاعات کلی + عوامل اصلی
   // Part 2 (روی arrow): بقیه فیلترها
   // هر دو بخش مستقل و قابل خواندن هستند

   // ── حداکثر امتیاز ممکن بر اساس Filter Mode فعلی ──
   int maxScore = GetMaxSignalScore();

   // tipA — روی فلش (arrow): امتیاز / حداکثر حالت فعلی
   string _modeName = (currentFilterMode == MODE_RELAXED) ? "Easy" :
                      (currentFilterMode == MODE_STRICT)  ? "Hard" : "Normal";
   string tipA = StringFormat("Score: %d / %d  [%s]", score, maxScore, _modeName);

   // ── تبدیل مقدار عددی filterContrib به نماد نمایشی ──
   // 1=✓ (مثبت)  0=~ (خنثی)  -1=✗ (منفی/بلاک)  -2=Off (خاموش)
   #define _FS(i) (ArraySize(filterContrib)>i ? (filterContrib[i]==1?"✓":(filterContrib[i]==-1?"✗":(filterContrib[i]==-2?"Off":"~"))) : "~")

   string tipB = StringFormat(
      "MA: %s\n"
      "RSI: %s\n"
      "ADX: %s\n"
      "BB: %s\n"
      "ATR: %s\n"
      "Wick: %s\n"
      "Candle: %s\n"
      "Ichi: %s\n"
      "Price G: %s\n"
      "Stop H: %s\n"
      "M Return: %s\n"
      "Trend: %s\n"
      "Vol: %s\n"
      "Market S: %s\n"
      "RSI D: %s\n"
      "Fractal: %s",
      _FS(FILT_MA),  _FS(FILT_RSI),  _FS(FILT_ADX),     _FS(FILT_BB),
      _FS(FILT_ATR), _FS(FILT_WICK), _FS(FILT_CANDLE),   _FS(FILT_ICHI),
      _FS(FILT_FVG), _FS(FILT_LIQSWP), _FS(FILT_RTM),   _FS(FILT_MTF),
      _FS(FILT_VOL), _FS(FILT_REGIME), _FS(FILT_HIDDENDIV), _FS(FILT_FRACTAL)
   );

   #undef _FS

   // ── ست کردن tooltip روی label (High/Mid/Low) ──
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tipB);

   // ── ست کردن tooltip روی arrow — فقط Score: X / Y ──
   string levelTag  = (level == "High") ? "H" : (level == "Mid") ? "M" : "L";
   string arrowTag  = (forBuy ? "B" : "S") + levelTag;
   string arrowName = HELPME_ARROW_PREFIX + arrowTag + "_" + IntegerToString((int)barTime);
   if(ObjectFind(0, arrowName) >= 0)
      ObjectSetString(0, arrowName, OBJPROP_TOOLTIP, tipA);   // tipA = "Score: X / Y"
}

//+------------------------------------------------------------------+
//| 🆕 v4.0: RUN SIGNAL LOOP                                        |
//| استخراج شده از OnCalculate - قابل صدازدن از ForceRecalculation  |
//| این تابع باگ "باید تایم‌فریم عوض کنی تا اعمال شه" را حل می‌کند  |
//+------------------------------------------------------------------+
void RunSignalLoop(int start,
                   const datetime &time[],
                   const double &open[],
                   const double &high[],
                   const double &low[],
                   const double &close[],
                   const long &tick_volume[])
{
   // FIX-5 v5.3: محافظت در مقابل edge case یک‌کندلی (آخر هفته)
   // حداقل 2 کندل برای تحلیل لازم است (current + at least one closed bar)
   if(g_ratesTotal < 2) return;
   if(start < 1) return;

   int cacheNeeded = start + 1;

   // --- Fill indicator caches ONCE before the loop (9 CopyBuffer calls total)
   ArraySetAsSeries(g_fastMA,  true); ArraySetAsSeries(g_slowMA,  true);
   ArraySetAsSeries(g_rsi,     true); ArraySetAsSeries(g_adx,     true);
   ArraySetAsSeries(g_plusDI,  true); ArraySetAsSeries(g_minusDI, true);
   ArraySetAsSeries(g_bbUpper, true); ArraySetAsSeries(g_bbLower, true);
   ArraySetAsSeries(g_atr,     true);

   int r1 = CopyBuffer(handleFastMA, 0, 0, cacheNeeded, g_fastMA);
   int r2 = CopyBuffer(handleSlowMA, 0, 0, cacheNeeded, g_slowMA);
   int r3 = CopyBuffer(handleRSI,    0, 0, cacheNeeded, g_rsi);
   int r4 = CopyBuffer(handleADX,    0, 0, cacheNeeded, g_adx);
   int r5 = CopyBuffer(handleADX,    1, 0, cacheNeeded, g_plusDI);
   int r6 = CopyBuffer(handleADX,    2, 0, cacheNeeded, g_minusDI);
   int r7 = CopyBuffer(handleBB,     1, 0, cacheNeeded, g_bbUpper);
   int r8 = CopyBuffer(handleBB,     2, 0, cacheNeeded, g_bbLower);
   int r9 = CopyBuffer(handleATR,    0, 0, cacheNeeded, g_atr);

   // FIX-7: retry یک‌بار در صورت شکست (بدون Sleep — جلوگیری از block شدن thread اصلی MT5)
   if(r1 < 1) r1 = CopyBuffer(handleFastMA, 0, 0, cacheNeeded, g_fastMA);
   if(r4 < 1) r4 = CopyBuffer(handleADX,    0, 0, cacheNeeded, g_adx);

   g_cacheSize = MathMin(r1, MathMin(r2, MathMin(r3, MathMin(r4,
                 MathMin(r5, MathMin(r6, MathMin(r7, MathMin(r8, r9))))))));

   if(EnableAllLogs && g_cacheSize < cacheNeeded)
      Print("⚠️ Cache: needed=", cacheNeeded, " got=", g_cacheSize);

   // FIX-6 v5.3: Ichimoku آرایه‌ها قبل از CopyBuffer باید SetAsSeries شوند
   // بدون این، وقتی کندل جدید می‌آید shift index اشتباه می‌شود
   // این بلوک تنها وقتی Ichi روشن است اجرا می‌شود (بهینه‌سازی CPU)
   if(localEnableIchimoku && handleIchimoku != INVALID_HANDLE)
   {
      int ichiNeed = cacheNeeded + 52;  // +52 برای Senkou Span displacement
      ArraySetAsSeries(g_ichiTenkan, true);
      ArraySetAsSeries(g_ichiKijun,  true);
      ArraySetAsSeries(g_ichiSpanA,  true);
      ArraySetAsSeries(g_ichiSpanB,  true);
      CopyBuffer(handleIchimoku, 0, 0, ichiNeed, g_ichiTenkan);  // Tenkan
      CopyBuffer(handleIchimoku, 1, 0, ichiNeed, g_ichiKijun);   // Kijun
      CopyBuffer(handleIchimoku, 2, 0, ichiNeed, g_ichiSpanA);   // Span A (future)
      CopyBuffer(handleIchimoku, 3, 0, ichiNeed, g_ichiSpanB);   // Span B (future)
   }

   // ════════════════════════════════════════════════════════════════
   // 🆕 v7.0: کش OHLC + Volume برای FVG, LiqSwp, VolPro
   // یکبار قبل از حلقه → بدون overhead per-bar
   // ════════════════════════════════════════════════════════════════
   int ohlcNeed = cacheNeeded + 25;  // +25 برای lookback LiqSwp
   if(localEnableFVG || localEnableLiqSwp)
   {
      ArraySetAsSeries(g_highCache,  true);
      ArraySetAsSeries(g_lowCache,   true);
      ArraySetAsSeries(g_closeCache, true);
      CopyHigh (_Symbol, PERIOD_CURRENT, 0, ohlcNeed, g_highCache);
      CopyLow  (_Symbol, PERIOD_CURRENT, 0, ohlcNeed, g_lowCache);
      CopyClose(_Symbol, PERIOD_CURRENT, 0, ohlcNeed, g_closeCache);
   }
   // VolPro volume cache (جداگانه - کمتر بار دارد)
   if(localEnableSmartVol)
   {
      ArraySetAsSeries(g_volCache, true);
      CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, cacheNeeded, g_volCache);
   }
   // RTM EMA200 cache
   if(localEnableRTM && handleRTM_EMA != INVALID_HANDLE)
   {
      ArraySetAsSeries(g_rtmEMA, true);
      int rtmCopied = CopyBuffer(handleRTM_EMA, 0, 0, cacheNeeded, g_rtmEMA);
      if(rtmCopied < 1 && EnableAllLogs) Print("⚠️ RTM EMA not ready yet (bars loading)");
   }
   // ════════════════════════════════════════════════════════════════

   // 🆕 v4.0: Fill fractal cache once (eliminates per-bar CopyBuffer in Strict mode)
   if(currentFilterMode == MODE_STRICT && g_handleFractals != INVALID_HANDLE)
   {
      ArraySetAsSeries(g_fractalUp, true);
      ArraySetAsSeries(g_fractalDn, true);
      CopyBuffer(g_handleFractals, 0, 0, cacheNeeded, g_fractalUp);
      CopyBuffer(g_handleFractals, 1, 0, cacheNeeded, g_fractalDn);
   }

   // --- Main signal loop (index 0=newest, loop from oldest down to 1)
   int periodSec = PeriodSeconds();
   for(int shift = start; shift >= 1; shift--)
   {
      // FIX v7.0: محافظت در مقابل out-of-bounds روی کش‌های indicator
      // وقتی چارت تازه باز میشه یا داده سرور هنوز کامل نیست،
      // g_cacheSize ممکنه کمتر از start+1 باشه → دسترسی خارج آرایه → crash
      if(shift >= g_cacheSize) continue;

      //--- Time-based distance check (immune to bar index shift on reconnect)
      int minGapSec = localMinBarsBetweenSignals * periodSec;
      bool tooClose = false;
      if(lastBuyTime  > 0 && (int)(time[shift] - lastBuyTime)  < minGapSec && lastBuyTime  < time[shift]) tooClose = true;
      if(lastSellTime > 0 && (int)(time[shift] - lastSellTime) < minGapSec && lastSellTime < time[shift]) tooClose = true;
      if(lastBuyTime  > 0 && time[shift] <= lastBuyTime)  tooClose = true;
      if(lastSellTime > 0 && time[shift] <= lastSellTime) tooClose = true;
      if(tooClose) continue;

      // EA mode: arrow objects are not overwritten per bar
      // (objects persist; only created if not already existing)

      //--- AI FILTER #1: Block Signals in Ranging Market
      // 🔧 FIX v7.3: باگ Regime — قبلاً currentRegime (رژیم لحظه حال) را روی همه بارهای
      // تاریخی اعمال می‌کرد → اگه الان بازار Trending بود، فیلتر Regime هیچ تأثیری نداشت!
      // حالا: برای هر بار تاریخی، ER (Efficiency Ratio) را از close[] که قبلاً لود شده
      // مستقیماً محاسبه می‌کنیم — بدون iClose اضافه و بدون CopyBuffer جدید.
      if(localEnableMarketRegime && BlockSignalsInRanging)
      {
         int erWindow = MathMin(RegimeCalculationBars, g_cacheSize - shift - 1);
         if(erWindow > 5)
         {
            double _netChange   = MathAbs(close[shift] - close[shift + erWindow]);
            double _totalChange = 0;
            for(int _k = shift; _k < shift + erWindow - 1 && _k + 1 < g_cacheSize; _k++)
               _totalChange += MathAbs(close[_k] - close[_k + 1]);
            double _er = (_totalChange > 0) ? _netChange / _totalChange : 0.5;
            if(_er <= RangingThreshold) continue;  // بازار در این بار Ranging بوده → رد کن
         }
      }

      //--- AI FILTER #2: (v5.0: News AI filter removed - S/R button is on-demand)

      //--- v4.0: Smart Volume Filter (Vol button) - tick volume check
      if(localEnableSmartVol)
      {
         // FIX: use ArraySize(tick_volume) not g_ratesTotal
         // g_ratesTotal = full chart bars, tick_volume may be a smaller local buffer (502 elements)
         // Using g_ratesTotal caused out-of-bounds access → MQL5 critical error → all signals killed
         int maxIdx   = ArraySize(tick_volume) - 1;
         int avgBars  = MathMin(20, maxIdx - shift);
         if(avgBars > 0)
         {
            long avgVol = 0;
            for(int k = 1; k <= avgBars; k++)
               avgVol += tick_volume[shift + k];
            avgVol /= avgBars;
            // آستانه 50% (نه 80%): تیک‌ولوم فارکس در بروکرهای مختلف بسیار متغیر است
            // فقط کندل‌هایی که واقعاً خیلی کم‌حجم هستند (نصف میانگین) فیلتر می‌شوند
            if(avgVol > 0 && tick_volume[shift] < avgVol * SmartVolumeThresholdPct / 100)
            {
               if(ShowScoreInfo && shift == 1)
                  Print("📊 Vol filtered: tick=", tick_volume[shift], " avg=", avgVol);
               continue;
            }
         }
      }

      if(tick_volume[shift] == 0) continue;

      double bodySize = MathAbs(close[shift] - open[shift]);
      double totalSize = high[shift] - low[shift];
      if(bodySize < 0.00001 || totalSize < 0.00001) continue;

      bool isBullish = close[shift] > open[shift];
      bool isBearish = close[shift] < open[shift];

      double pipSize    = (_Digits == 3 || _Digits == 5) ? _Point * 10 : _Point;
      double arrowOffset = localArrowOffsetPips * pipSize;

      //--- BUY signal analysis
      if(isBullish)
      {
         int filterBuy[];
         int score = AnalyzeSignal(shift, time[shift], true, open[shift], high[shift], low[shift], close[shift], filterBuy);
         if(ShowScoreInfo && score > 0 && shift == 1)
            Print("🔵 BUY Score: ", score, " | Regime: ", EnumToString(currentRegime.regime));

      if(score >= localRequiredScore)
         {
            // 🔧 FIX v7.5: فاصله از بدنه کندل (نه سایه) → همه فلش‌ها فاصله یکنواخت دارند
            double bodyBottom = MathMin(open[shift], close[shift]);
            double arrowY     = bodyBottom - arrowOffset;
            // v12: همه BUY یک رنگ (سبز) و یک اندازه
            string sigLevel = (score >= 10) ? "High" : (score >= 7) ? "Mid" : "Low";
            string sigTag   = (score >= 10) ? "BH"   : (score >= 7) ? "BM"  : "BL";
            CreateSignalArrow(time[shift], arrowY, 233, clrLime, 2, sigTag);
            // لیبل زیر فلش
            CreateSignalLabel(time[shift], arrowY - arrowOffset * 1, sigLevel, true, score,
               open[shift], close[shift], g_rsi[shift<g_cacheSize?shift:0],
               g_adx[shift<g_cacheSize?shift:0], g_fastMA[shift<g_cacheSize?shift:0],
               g_slowMA[shift<g_cacheSize?shift:0], filterBuy);
            lastBuyTime = time[shift];
            if(TimeCurrent() - time[shift] < 604800) todaySignalCount++;
            if(EnableAlerts && shift == 1) Alert("Buy ", _Symbol, " | Score:", score, " | ", sigLevel);
         }
      }

      //--- SELL signal analysis
      if(isBearish)
      {
         int filterSell[];
         int score = AnalyzeSignal(shift, time[shift], false, open[shift], high[shift], low[shift], close[shift], filterSell);
         if(ShowScoreInfo && score > 0 && shift == 1)
            Print("🔴 SELL Score: ", score, " | Regime: ", EnumToString(currentRegime.regime));

         if(score >= localRequiredScore)
         {
            // 🔧 FIX v7.5: فاصله از بدنه کندل (نه سایه) → همه فلش‌ها فاصله یکنواخت دارند
            double bodyTop = MathMax(open[shift], close[shift]);
            double arrowY  = bodyTop + arrowOffset* 1.7;
            // v12: همه SELL یک رنگ (قرمز) و یک اندازه
            string sigLevel = (score >= 10) ? "High" : (score >= 7) ? "Mid" : "Low";
            string sigTag   = (score >= 10) ? "SH"   : (score >= 7) ? "SM"  : "SL";
            CreateSignalArrow(time[shift], arrowY, 234, clrRed, 2, sigTag);
            // لیبل بالای فلش
            CreateSignalLabel(time[shift], arrowY + arrowOffset * 0.5, sigLevel, false, score,
               open[shift], close[shift], g_rsi[shift<g_cacheSize?shift:0],
               g_adx[shift<g_cacheSize?shift:0], g_fastMA[shift<g_cacheSize?shift:0],
               g_slowMA[shift<g_cacheSize?shift:0], filterSell);
            lastSellTime = time[shift];
            if(TimeCurrent() - time[shift] < 604800) todaySignalCount++;
            if(EnableAlerts && shift == 1) Alert("Sell ", _Symbol, " | Score:", score, " | ", sigLevel);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 🆕 ANALYZE SIGNAL WITH AI ENHANCEMENTS                          |
//+------------------------------------------------------------------+
int AnalyzeSignal(int shift, datetime signalTime, bool forBuy, 
                  double o, double h, double l, double c,
                  int &filterContrib[])
{
   int score = 0;
   ArrayResize(filterContrib, FILT_COUNT);
   ArrayInitialize(filterContrib, 0);   // 0 = خنثی (~)
   
   // FIX #5: Use pre-cached global arrays filled once before the loop
   // Validate shift is within cache
   if(shift >= g_cacheSize || g_cacheSize == 0) return 0;

   double fastMAv  = g_fastMA[shift];
   double slowMAv  = g_slowMA[shift];
   double rsiv     = g_rsi[shift];
   double adxv     = g_adx[shift];
   double plusDIv  = g_plusDI[shift];
   double minusDIv = g_minusDI[shift];
   double bbUpperv = g_bbUpper[shift];
   double bbLowerv = g_bbLower[shift];
   double atrv     = g_atr[shift];

   if(fastMAv == 0 || slowMAv == 0 || rsiv == 0 || atrv == 0) return 0;
   
   //--- 🆕 AI FILTER #3: Multi-Timeframe Confluence
   if(localEnableMTF)
   {
      if(RequireH1Confirmation)
      {
         if(forBuy && !mtfTrend.h1Bullish)
         {
            if(ShowScoreInfo)
               if(EnableAllLogs) Print("⚠️ BUY rejected: H1 not bullish");
            filterContrib[FILT_MTF] = -1;
            return 0;  // Hard block
         }
         if(!forBuy && !mtfTrend.h1Bearish)
         {
            if(ShowScoreInfo)
               if(EnableAllLogs) Print("⚠️ SELL rejected: H1 not bearish");
            filterContrib[FILT_MTF] = -1;
            return 0;  // Hard block
         }
         score += 3;  // Bonus for H1 confirmation
         filterContrib[FILT_MTF] = 1;
      }
      
      if(RequireH4Confirmation)
      {
         if(forBuy && mtfTrend.h4Bullish)
         { score += 2; filterContrib[FILT_MTF] = 1; }
         if(!forBuy && mtfTrend.h4Bearish)
         { score += 2; filterContrib[FILT_MTF] = 1; }
      }
      
      // اگه H1/H4 فعال نبودند ولی MTF روشنه → خنثی
      if(filterContrib[FILT_MTF] == 0) filterContrib[FILT_MTF] = 0;
   }
   else
      filterContrib[FILT_MTF] = -2;  // Off
   
   //--- 🆕 v5.0 AI FILTER #4: Price Action Pattern (Direction-Aware Scoring)
   if(localEnablePriceAction && RequireCandlePattern)
   {
      ENUM_CANDLE_PATTERN pattern = DetectCandlePattern(shift, o, h, l, c, atrv, forBuy);
      
      // الگوهای موافق سیگنال خرید
      bool isBullishPattern = (pattern == PATTERN_HAMMER        ||
                               pattern == PATTERN_INVERTED_HAMMER ||
                               pattern == PATTERN_BULLISH_ENGULFING ||
                               pattern == PATTERN_BULLISH_PINBAR);
      // الگوهای موافق سیگنال فروش
      bool isBearishPattern = (pattern == PATTERN_SHOOTING_STAR   ||
                               pattern == PATTERN_BEARISH_ENGULFING ||
                               pattern == PATTERN_BEARISH_PINBAR);
      bool isDoji           = (pattern == PATTERN_DOJI);
      
      if(pattern == PATTERN_NONE)
      {
         // هیچ الگویی وجود ندارد - جریمه کوچک
         if(ShowScoreInfo && EnableAllLogs)
            Print("⚠️ No candlestick pattern detected");
         score -= 1;
         filterContrib[FILT_CANDLE] = -1;
         
         // 🔴 STRICT: الگوی موافق اجباری است - بدون الگو = سیگنال لغو
         if(currentFilterMode == MODE_STRICT)
         {
            if(ShowScoreInfo) Print("🚫 STRICT Block: no confirming candle pattern");
            return 0;
         }
      }
      else if(isDoji)
      {
         // دوجی: بی‌طرف، امتیاز کمی مثبت در هر دو جهت
         if(ShowScoreInfo) Print("🕯️ Doji: neutral +1");
         score += 1;
         filterContrib[FILT_CANDLE] = 0;  // خنثی (~)
      }
      else if((forBuy  && isBullishPattern) ||
              (!forBuy && isBearishPattern))
      {
         // الگو موافق جهت سیگنال: +3 امتیاز
         if(ShowScoreInfo) Print("✅ Confirming pattern: ", EnumToString(pattern), " +3");
         score += 3;
         filterContrib[FILT_CANDLE] = 1;
      }
      else
      {
         // الگو مخالف جهت سیگنال: -2 جریمه
         if(ShowScoreInfo) Print("⚠️ Opposing pattern: ", EnumToString(pattern), " -2");
         score -= 2;
         filterContrib[FILT_CANDLE] = -1;
         
         // 🔴 STRICT: الگوی مخالف = بلاک سخت
         if(currentFilterMode == MODE_STRICT)
         {
            if(ShowScoreInfo) Print("🚫 STRICT Block: opposing candle pattern");
            return 0;
         }
      }
   }
   else
      filterContrib[FILT_CANDLE] = -2;  // Off
   
   //--- 🆕 v4.0 AI FILTER #5: Fractal S/R Hard Block (STRICT mode only)
   // اگر حالت Strict باشد و قیمت خیلی نزدیک به آخرین فراکتال مقاومت/حمایت باشد، سیگنال بلافاصله مسدود شود
   if(currentFilterMode == MODE_STRICT)
   {
      if(IsTooCloseToFractal(shift, forBuy, c, atrv))
      {
         if(ShowScoreInfo && shift == 1)
            Print("🧱 STRICT Fractal Block: signal too close to S/R wall");
         filterContrib[FILT_FRACTAL] = -1;
         return 0;  // Hard block - فضای کافی برای حرکت وجود ندارد
      }
      filterContrib[FILT_FRACTAL] = 1;  // Fractal تأیید کرد (بلاک نشد)
   }
   else
      filterContrib[FILT_FRACTAL] = -2;  // Off — فقط در Strict فعاله
   
   //--- 🆕 v4.0 BONUS: Hidden RSI Divergence (BALANCED + STRICT)
   // اگر واگرایی پنهان شناسایی شد، امتیاز بونوس می‌گیرد
   if(currentFilterMode == MODE_BALANCED || currentFilterMode == MODE_STRICT)
   {
      int divScore = CheckHiddenDivergence(shift, forBuy);
      score += divScore;
      if(divScore > 0)       filterContrib[FILT_HIDDENDIV] = 1;
      else if(divScore < 0)  filterContrib[FILT_HIDDENDIV] = -1;
      else                   filterContrib[FILT_HIDDENDIV] = 0;
   }
   else
      filterContrib[FILT_HIDDENDIV] = -2;  // Off (Relaxed)
   
   //--- 🆕 Apply Weights (always 1.0 — optimization weights removed)
   double maWeight  = 1.0;
   double rsiWeight = 1.0;
   double adxWeight = 1.0;
   double bbWeight  = 1.0;
   double atrWeight = 1.0;
   
   //--- MA Cross (weighted) - v7.0: وزن کم شد (نویز زیاد در AUDCAD/رنج‌ها)
   if(forBuy && fastMAv > slowMAv)
   { score += (int)(1 * maWeight); filterContrib[FILT_MA] = 1; }
   else if(!forBuy && fastMAv < slowMAv)
   { score += (int)(1 * maWeight); filterContrib[FILT_MA] = 1; }
   else
      filterContrib[FILT_MA] = -1;  // MA خلاف جهت
   
   //--- RSI Filter (weighted)
   if(UseRSIFilter)
   {
      if(forBuy && rsiv > 40 && rsiv < 70)
      { score += (int)(1 * rsiWeight); filterContrib[FILT_RSI] = 1; }
      else if(!forBuy && rsiv > 30 && rsiv < 60)
      { score += (int)(1 * rsiWeight); filterContrib[FILT_RSI] = 1; }
      else
         filterContrib[FILT_RSI] = -1;  // RSI خارج از محدوده مطلوب
   }
   else
      filterContrib[FILT_RSI] = -2;  // Off
   
   //--- ADX Filter (weighted)
   if(UseADXFilter)
   {
      if(adxv > MinADX)
      { score += (int)(1 * adxWeight); filterContrib[FILT_ADX] = 1; }
      else
         filterContrib[FILT_ADX] = -1;  // ADX ضعیف
   }
   else
      filterContrib[FILT_ADX] = -2;  // Off
   
   //--- BB Filter (weighted)
   if(UseBBFilter)
   {
      if(forBuy && c < bbUpperv)
      { score += (int)(1 * bbWeight); filterContrib[FILT_BB] = 1; }
      else if(!forBuy && c > bbLowerv)
      { score += (int)(1 * bbWeight); filterContrib[FILT_BB] = 1; }
      else
         filterContrib[FILT_BB] = -1;  // قیمت خارج از محدوده BB
   }
   else
      filterContrib[FILT_BB] = -2;  // Off
   
   //--- ATR Intensity (weighted)
   if(UseATRIntensity && atrv > 0)
   {
      double bodySize = MathAbs(c - o);
      double bodyATRRatio = bodySize / atrv;
      
      if(bodyATRRatio >= 1.2)
      { score += (int)(3 * atrWeight); filterContrib[FILT_ATR] = 1; }
      else if(bodyATRRatio >= 1.0)
      { score += (int)(2 * atrWeight); filterContrib[FILT_ATR] = 1; }
      else if(bodyATRRatio >= localMinBodyToATRRatio)
      { score += (int)(1 * atrWeight); filterContrib[FILT_ATR] = 1; }
      else
         filterContrib[FILT_ATR] = -1;  // بدنه کوچک‌تر از حد مجاز ATR
   }
   else
      filterContrib[FILT_ATR] = -2;  // Off
   
   //--- Wick Filter
   if(UseWickFilter)
   {
      double bodySize = MathAbs(c - o);
      double totalSize = h - l;
      double bodyRatio = totalSize > 0 ? bodySize / totalSize : 0;
      
      if(bodyRatio >= 0.8)
      { score += 2; filterContrib[FILT_WICK] = 1; }
      else if(bodyRatio >= localMinBodyToTotalRatio)
      { score += 1; filterContrib[FILT_WICK] = 1; }
      else
         filterContrib[FILT_WICK] = -1;  // سایه بیش از حد بزرگ
   }
   else
      filterContrib[FILT_WICK] = -2;  // Off
   
   //--- 🆕 Market Regime Bonus/Penalty
   // 🔧 FIX v7.3: همسو با Fix C — per-bar ER برای امتیاز هم استفاده می‌شه
   if(localEnableMarketRegime)
   {
      // ER را دوباره محاسبه نمی‌کنیم — از shift و close[] که به تابع پاس داده شده استفاده می‌کنیم
      // (این تابع scoring مستقیماً به close[] و shift دسترسی ندارد، پس currentRegime را حفظ می‌کنیم)
      // currentRegime برای score bonus کافی است — فقط hard-block باید per-bar باشد
      if(currentRegime.regime == REGIME_TRENDING)
      { score += 2; filterContrib[FILT_REGIME] = 1; }  // Bonus in trending market
      else if(currentRegime.regime == REGIME_VOLATILE)
      { score -= 1; filterContrib[FILT_REGIME] = -1; }  // Penalty in volatile market
      else
         filterContrib[FILT_REGIME] = 0;  // خنثی (Ranging block قبلاً در RunSignalLoop انجام شده)
      // RANGING: قبلاً در RunSignalLoop block شده (per-bar ER) → اینجا نمی‌رسد
   }
   else
      filterContrib[FILT_REGIME] = -2;  // Off

   // ─────────────────────────────────────────────────────────────────
   // 🆕 v5.1 AI FILTER #6: Ichimoku Cloud (دکمه Ichi)
   // ─────────────────────────────────────────────────────────────────
   // معماری:
   //   ● Senkou Span A/B در MT5 به +26 آینده shift شده‌اند
   //     → برای bar[shift]: از ایندکس shift+26 در آرایه استفاده می‌کنیم
   //   ● Tenkan/Kijun: بدون shift، مستقیم از ایندکس shift
   //   ● Chikou: استفاده نمی‌شود (برای سادگی و سرعت)
   //
   // امتیازدهی:
   //   +2  قیمت بالای ابر + سیگنال خرید (یا زیر ابر + فروش)
   //   -1  قیمت خلاف جهت ابر (در Strict: Hard Block)
   //   +3  Kumo Breakout: کندل قبلی داخل ابر، کندل فعلی خارج از ابر
   //   +1  Tenkan > Kijun هم‌جهت سیگنال (یا بلعکس برای فروش)
   // ─────────────────────────────────────────────────────────────────
   if(localEnableIchimoku)
   {
      int ichiSpanIdx = shift + 26;  // ایندکس Senkou Span برای این bar
      bool ichiDataOk = (ArraySize(g_ichiTenkan) > shift) &&
                        (ArraySize(g_ichiSpanA)   > ichiSpanIdx) &&
                        (g_ichiSpanA[ichiSpanIdx] > 0) &&
                        (g_ichiSpanB[ichiSpanIdx] > 0);

      if(ichiDataOk)
      {
         double tenkan  = g_ichiTenkan[shift];
         double kijun   = g_ichiKijun[shift];
         double spanA   = g_ichiSpanA[ichiSpanIdx];   // ابر برای این bar
         double spanB   = g_ichiSpanB[ichiSpanIdx];
         double cloudTop = MathMax(spanA, spanB);
         double cloudBot = MathMin(spanA, spanB);

         bool aboveCloud = (c > cloudTop);   // قیمت بالای کل ابر
         bool belowCloud = (c < cloudBot);   // قیمت زیر کل ابر
         bool inCloud    = !aboveCloud && !belowCloud;

         // ── موقعیت قیمت نسبت به ابر ──
         if(forBuy && aboveCloud)
         {
            score += 2;
            filterContrib[FILT_ICHI] = 1;
            if(ShowScoreInfo) Print("☁️ Ichi: Above Cloud (BUY) +2");
         }
         else if(!forBuy && belowCloud)
         {
            score += 2;
            filterContrib[FILT_ICHI] = 1;
            if(ShowScoreInfo) Print("☁️ Ichi: Below Cloud (SELL) +2");
         }
         else
         {
            // سیگنال خلاف جهت ابر یا داخل ابر
            score -= 1;
            filterContrib[FILT_ICHI] = -1;
            if(ShowScoreInfo) Print("☁️ Ichi: Against/In Cloud -1");

            // 🔴 STRICT: قیمت باید طرف درست ابر باشد
            if(currentFilterMode == MODE_STRICT)
            {
               if(ShowScoreInfo) Print("🚫 STRICT Ichi Block: price not on cloud side");
               return 0;
            }
         }

         // ── Kumo Breakout: کندل قبلی داخل ابر → فعلی خارج ──
         if(shift + 1 < ArraySize(g_ichiTenkan))
         {
            int prevIdx    = shift + 1;
            int prevSpanIdx = prevIdx + 26;
            if(prevSpanIdx < ArraySize(g_ichiSpanA))
            {
               double prevClose  = iClose(_Symbol, PERIOD_CURRENT, prevIdx);
               double prevSpanA  = g_ichiSpanA[prevSpanIdx];
               double prevSpanB  = g_ichiSpanB[prevSpanIdx];
               double prevTop    = MathMax(prevSpanA, prevSpanB);
               double prevBot    = MathMin(prevSpanA, prevSpanB);
               bool   prevInCloud = (prevClose >= prevBot && prevClose <= prevTop);
               bool   currOutSide = (forBuy ? aboveCloud : belowCloud);

               if(prevInCloud && currOutSide)
               {
                  score += 3;
                  filterContrib[FILT_ICHI] = 1;
                  if(ShowScoreInfo) Print("💥 Ichi: Kumo Breakout +3");
               }
            }
         }

         // ── Tenkan/Kijun Cross هم‌جهت سیگنال ──
         if(tenkan > 0 && kijun > 0)
         {
            if(forBuy  && tenkan > kijun) { score += 1; filterContrib[FILT_ICHI] = 1; if(ShowScoreInfo) Print("📈 Ichi: Tenkan>Kijun (BUY) +1"); }
            if(!forBuy && tenkan < kijun) { score += 1; filterContrib[FILT_ICHI] = 1; if(ShowScoreInfo) Print("📉 Ichi: Tenkan<Kijun (SELL) +1"); }
         }
      }
      else
      {
         filterContrib[FILT_ICHI] = 0;  // داده آماده نیست → خنثی
         if(ShowDebugLogs && shift == 1)
            Print("⚠️ Ichi data not ready for shift=", shift);
      }
   }
   else
      filterContrib[FILT_ICHI] = -2;  // Off
   // ─────────────────────────────────────────────────────────────────

   // ─────────────────────────────────────────────────────────────────
   // 🆕 v7.0 AI FILTER #7: Fair Value Gap (FVG / Imbalance)
   // ─────────────────────────────────────────────────────────────────
   // FVG = ناحیه‌ای که بازار با سرعت از آن عبور کرده و "خلأ" ایجاد شده
   // بازار تمایل دارد به این نواحی برگردد (unfilled orders)
   //
   // Bullish FVG: کندل سه‌تایی که شکاف صعودی دارد
   //   شرط: high[fi+2] < low[fi]  (کندل سوم پایین‌تر از کندل اول)
   //   = قیمت سریع بالا رفته، gap باقی مانده
   //
   // امتیازدهی:
   //   +2  قیمت داخل FVG هم‌جهت (ناحیه اعتبار دارد)
   //   +1  FVG درست زیر/بالای قیمت (magnet effect)
   //   -1  FVG خلاف جهت نزدیک (ریسک fill شدن قبل از TP)
   //   STRICT: FVG خلاف → Hard Block (نه فقط جریمه)
   //
   // کاربرد Xmoon:
   //   اگه Xmoon buy باز کرده و یک Bearish FVG بالاتر هست →
   //   قیمت ممکنه اول بره gap رو پر کنه (TP miss) → زود ببند
   // ─────────────────────────────────────────────────────────────────
   if(localEnableFVG)
   {
      bool inBullFVG   = false;  // قیمت داخل FVG صعودی
      bool inBearFVG   = false;  // قیمت داخل FVG نزولی
      bool nearBullFVG = false;  // FVG صعودی درست زیر قیمت
      bool nearBearFVG = false;  // FVG نزولی درست بالای قیمت

      // FVG scan از shift شروع میشه (نه shift+1) تا شکاف‌های بسیار تازه هم دیده بشن
      // مثال: کندل جاری (shift=1) خودش بخشی از یه FVG تازه باشه
      int fvgScanEnd = MathMin(shift + 16, ArraySize(g_highCache) - 3);

      for(int fi = shift; fi < fvgScanEnd; fi++)
      {
         if(fi + 2 >= ArraySize(g_highCache)) break;

         double minFVGsize = atrv * 0.25;  // FVG باید حداقل ربع ATR باشد

         // ── Bullish FVG ──────────────────────────────────────────
         // three-candle: bar[fi+2] high < bar[fi] low
         double bHigh2 = g_highCache[fi + 2];
         double bLow0  = g_lowCache[fi];
         if(bHigh2 < bLow0 && (bLow0 - bHigh2) >= minFVGsize)
         {
            double fvgBot = bHigh2;
            double fvgTop = bLow0;
            if(c >= fvgBot && c <= fvgTop)
               inBullFVG = true;
            else if(c > fvgTop && c <= fvgTop + atrv * 0.8)
               nearBullFVG = true;  // قیمت درست بالای FVG
         }

         // ── Bearish FVG ──────────────────────────────────────────
         double bLow2  = g_lowCache[fi + 2];
         double bHigh0 = g_highCache[fi];
         if(bLow2 > bHigh0 && (bLow2 - bHigh0) >= minFVGsize)
         {
            double fvgBot = bHigh0;
            double fvgTop = bLow2;
            if(c >= fvgBot && c <= fvgTop)
               inBearFVG = true;
            else if(c < fvgBot && c >= fvgBot - atrv * 0.8)
               nearBearFVG = true;
         }
      }

      // امتیازدهی FVG
      // 🆕 v7.0: وزن FVG سه‌برابر شد - SMC مهم‌ترین سیگنال برای Xmoon پس از پله ۵
      if(forBuy)
      {
         if(inBullFVG)
            { score += 6; filterContrib[FILT_FVG] = 1; if(ShowScoreInfo) Print("📐 FVG: In Bullish Gap (BUY) +6 [v7:×3]"); }
         else if(nearBullFVG)
            { score += 3; filterContrib[FILT_FVG] = 1; if(ShowScoreInfo) Print("📐 FVG: Near Bullish Gap +3 [v7:×3]"); }
         else
            filterContrib[FILT_FVG] = 0;  // خنثی

         if(inBearFVG)
         {
            score -= 3;
            filterContrib[FILT_FVG] = -1;
            if(ShowScoreInfo) Print("📐 FVG: In Bearish Gap (BUY risk) -3 [v7:×3]");
            if(currentFilterMode == MODE_STRICT)
               { if(ShowScoreInfo) Print("🚫 STRICT FVG Block: opposing gap"); return 0; }
         }
      }
      else  // SELL
      {
         if(inBearFVG)
            { score += 6; filterContrib[FILT_FVG] = 1; if(ShowScoreInfo) Print("📐 FVG: In Bearish Gap (SELL) +6 [v7:×3]"); }
         else if(nearBearFVG)
            { score += 3; filterContrib[FILT_FVG] = 1; if(ShowScoreInfo) Print("📐 FVG: Near Bearish Gap +3 [v7:×3]"); }
         else
            filterContrib[FILT_FVG] = 0;  // خنثی

         if(inBullFVG)
         {
            score -= 3;
            filterContrib[FILT_FVG] = -1;
            if(ShowScoreInfo) Print("📐 FVG: In Bullish Gap (SELL risk) -3 [v7:×3]");
            if(currentFilterMode == MODE_STRICT)
               { if(ShowScoreInfo) Print("🚫 STRICT FVG Block: opposing gap"); return 0; }
         }
      }
   }
   else
      filterContrib[FILT_FVG] = -2;  // Off
   // ─────────────────────────────────────────────────────────────────

   // ─────────────────────────────────────────────────────────────────
   // 🆕 v7.0 AI FILTER #8: Liquidity Sweep (شکار نقدینگی)
   // ─────────────────────────────────────────────────────────────────
   // LiqSwp = بازار به سطح نقدینگی (high/low قبلی) زده، استاپ‌ها خورده،
   // و با سرعت برگشته - این یکی از قوی‌ترین سیگنال‌های برگشت در ICT/SMC
   //
   // Bullish Sweep (برای BUY):
   //   1. در 5-25 کندل اخیر یک low مشخص بوده
   //   2. bar[si].low از آن low پایین‌تر رفته (sweep)
   //   3. bar[si].close > آن low (برگشته = fake breakout)
   //   = پول smart money استاپ‌های زیر را جمع کرده → برگشت صعودی
   //
   // امتیازدهی:
   //   +3  sweep تازه (1-2 کندل پیش)
   //   +2  sweep اخیر (3-5 کندل)
   //   +1  sweep نسبتاً تازه (6-8 کندل)
   //   STRICT بدون sweep در بازار غیر‌trending: -1
   //
   // کاربرد Xmoon:
   //   LiqSwp تازه + سیگنال HelpMe → TP احتمالی، صبر کن
   //   بدون LiqSwp + قیمت ادامه‌دار → خطر call → زودتر ببند
   // ─────────────────────────────────────────────────────────────────
   if(localEnableLiqSwp)
   {
      int swpAge = -1;      // چند کندل پیش sweep اتفاق افتاد (-1 = نیافت)
      int swpRef = 20;      // چقدر به عقب برای پیدا کردن reference low/high نگاه کنیم
      int swpScanEnd = MathMin(shift + 8, ArraySize(g_highCache) - swpRef - 2);

      for(int si = shift; si < swpScanEnd; si++)
      {
         if(si + swpRef >= ArraySize(g_lowCache)) break;

         if(forBuy)
         {
            // ── Bullish Sweep: low[si] از minimum 5-25 کندل قبل پایین‌تر رفته و بسته بالاتر شده ──
            double refLowMin = 1e15;
            for(int k = si + 3; k <= si + swpRef; k++)
               refLowMin = MathMin(refLowMin, g_lowCache[k]);

            double sweepLow  = g_lowCache[si];
            double sweepClose = g_closeCache[si];
            double sweepDepth = refLowMin - sweepLow;  // چقدر پایین‌تر رفته

            // شرط sweep: پایین‌تر رفته (حداقل 0.1 ATR) و بسته شده بالاتر از سطح
            if(sweepDepth >= atrv * 0.1 && sweepClose > refLowMin)
            {
               swpAge = si - shift;
               break;
            }
         }
         else  // SELL
         {
            // ── Bearish Sweep: high[si] از maximum 5-25 کندل قبل بالاتر رفته و بسته پایین‌تر شده ──
            double refHighMax = -1e15;
            for(int k = si + 3; k <= si + swpRef; k++)
               refHighMax = MathMax(refHighMax, g_highCache[k]);

            double sweepHigh  = g_highCache[si];
            double sweepClose = g_closeCache[si];
            double sweepHeight = sweepHigh - refHighMax;

            if(sweepHeight >= atrv * 0.1 && sweepClose < refHighMax)
            {
               swpAge = si - shift;
               break;
            }
         }
      }

      // امتیازدهی LiqSwp
      // 🆕 v7.0: وزن LiqSwp سه‌برابر شد - sweep = پول smart money استاپ جمع کرده
      if(swpAge >= 0)
      {
         // v7.0: +9, +6, +3 (قبلاً: +3, +2, +1)
         int swpScore = (swpAge <= 2) ? 9 : (swpAge <= 5) ? 6 : 3;
         score += swpScore;
         filterContrib[FILT_LIQSWP] = 1;
         if(ShowScoreInfo)
            Print("💧 LiqSwp: sweep ", swpAge, " bars ago → +", swpScore, " [v7:×3]");
      }
      else
      {
         // STRICT: بدون sweep در بازار غیر‌trending → سیگنال ضعیف‌تر است
         if(currentFilterMode == MODE_STRICT && currentRegime.regime != REGIME_TRENDING)
            { score -= 3; filterContrib[FILT_LIQSWP] = -1; if(ShowScoreInfo) Print("💧 LiqSwp: no sweep (STRICT non-trend) -3 [v7:×3]"); }
         else
            filterContrib[FILT_LIQSWP] = 0;  // روشنه ولی sweep پیدا نشد → خنثی
      }
   }
   else
      filterContrib[FILT_LIQSWP] = -2;  // Off
   // ─────────────────────────────────────────────────────────────────

   // ─────────────────────────────────────────────────────────────────
   // 🆕 v7.0 AI FILTER #9: Return to Mean (بازگشت به میانگین)
   // ─────────────────────────────────────────────────────────────────
   // RTM = هرچه قیمت از EMA200 (RTM_EMAPeriod) دورتر باشد،
   // احتمال mean reversion بیشتر است
   //
   // امتیازدهی:
   //   +3  قیمت 4+ ATR دور از EMA و سیگنال هم‌جهت برگشت
   //   +2  قیمت 3-4 ATR دور
   //   +1  قیمت 2-3 ATR دور (خفیف)
   //    0  قیمت نزدیک EMA (کمتر از 1 ATR)
   //   -1  قیمت آن‌طرف EMA و سیگنال ادامه‌دهنده (خلاف RTM)
   //
   // کاربرد Xmoon (مهم‌ترین):
   //   RTM_Distance > RTM_DangerATR → داشبورد قرمز: "DANGER ⚠️"
   //   Xmoon معامله خلاف trend باز کرده و قیمت خیلی دور از میانگینه
   //   → برگشت طبیعی است، صبر کن برای TP
   //   اما اگه قیمت بیشتر از mean فاصله گرفت → call risk بالا → ببند
   // ─────────────────────────────────────────────────────────────────
   if(localEnableRTM && handleRTM_EMA != INVALID_HANDLE)
   {
      if(shift < ArraySize(g_rtmEMA) && g_rtmEMA[shift] > 0.0 && atrv > 0.0)
      {
         double ema      = g_rtmEMA[shift];
         double dist     = MathAbs(c - ema);
         double distATR  = dist / atrv;        // فاصله بر حسب ATR
         bool   above    = (c > ema);          // قیمت بالای EMA200

         if(forBuy)
         {
            // سیگنال BUY: قیمت باید زیر EMA200 و در حال برگشت باشد
            if(!above)  // قیمت زیر EMA200 → BUY هم‌جهت RTM
            {
               // 🆕 v7.0: >3.5 ATR = Danger Zone اما برای Xmoon یعنی برگشت قوی محتمل
               if(distATR >= 4.0)       { score += 3; filterContrib[FILT_RTM] = 1; if(ShowScoreInfo) Print("🔄 RTM: BUY ", DoubleToString(distATR,1), "x ATR below mean +3 [HighRecovery]"); }
               else if(distATR >= 3.5)  { score += 3; filterContrib[FILT_RTM] = 1; if(ShowScoreInfo) Print("🔄 RTM: BUY 3.5x ATR - DangerZone+HighRecovery +3"); }
               else if(distATR >= 3.0)  { score += 2; filterContrib[FILT_RTM] = 1; if(ShowScoreInfo) Print("🔄 RTM: BUY 3x ATR below +2"); }
               else if(distATR >= 2.0)  { score += 1; filterContrib[FILT_RTM] = 1; if(ShowScoreInfo) Print("🔄 RTM: BUY 2x ATR below +1"); }
               else                       filterContrib[FILT_RTM] = 0;  // نزدیک EMA → خنثی
            }
            else  // قیمت بالای EMA200 → BUY ادامه‌دهنده (خلاف RTM)
            {
               if(distATR >= 2.0) { score -= 1; filterContrib[FILT_RTM] = -1; if(ShowScoreInfo) Print("🔄 RTM: BUY above mean -1 (continuation risk)"); }
               else                 filterContrib[FILT_RTM] = 0;
            }
         }
         else  // SELL
         {
            // سیگنال SELL: قیمت باید بالای EMA200 و در حال برگشت باشد
            if(above)  // قیمت بالای EMA200 → SELL هم‌جهت RTM
            {
               if(distATR >= 4.0)       { score += 3; filterContrib[FILT_RTM] = 1; if(ShowScoreInfo) Print("🔄 RTM: SELL ", DoubleToString(distATR,1), "x ATR above mean +3 [HighRecovery]"); }
               else if(distATR >= 3.5)  { score += 3; filterContrib[FILT_RTM] = 1; if(ShowScoreInfo) Print("🔄 RTM: SELL 3.5x ATR - DangerZone+HighRecovery +3"); }
               else if(distATR >= 3.0)  { score += 2; filterContrib[FILT_RTM] = 1; if(ShowScoreInfo) Print("🔄 RTM: SELL 3x ATR above +2"); }
               else if(distATR >= 2.0)  { score += 1; filterContrib[FILT_RTM] = 1; if(ShowScoreInfo) Print("🔄 RTM: SELL 2x ATR above +1"); }
               else                       filterContrib[FILT_RTM] = 0;
            }
            else  // قیمت زیر EMA200 → SELL ادامه‌دهنده
            {
               if(distATR >= 2.0) { score -= 1; filterContrib[FILT_RTM] = -1; if(ShowScoreInfo) Print("🔄 RTM: SELL below mean -1 (continuation risk)"); }
               else                 filterContrib[FILT_RTM] = 0;
            }
         }
      }
      else
      {
         filterContrib[FILT_RTM] = 0;  // داده آماده نیست → خنثی
         if(ShowDebugLogs && shift == 1)
            Print("⚠️ RTM EMA not ready (bars still loading)");
      }
   }
   else
      filterContrib[FILT_RTM] = -2;  // Off
   // ─────────────────────────────────────────────────────────────────

   // 🆕 v7.0: VolPro scoring (bonus برای momentum volume - hard block در RunSignalLoop)
   // این بخش امتیاز مثبت میده، hard-block قبلاً در RunSignalLoop انجام شده
   if(localEnableSmartVol && shift < ArraySize(g_volCache))
   {
      int vAvgBars = MathMin(20, ArraySize(g_volCache) - shift - 1);
      if(vAvgBars > 2)
      {
         long vSum = 0;
         for(int k = 1; k <= vAvgBars; k++) vSum += g_volCache[shift + k];
         long vAvg = vSum / vAvgBars;
         if(vAvg > 0)
         {
            double vRatio = (double)g_volCache[shift] / (double)vAvg;
            // Volume expansion bonus (بدون اینکه climax باشه)
            if(vRatio >= 1.8 && vRatio < 3.0) { score += 2; filterContrib[FILT_VOL] = 1; if(ShowScoreInfo) Print("📊 VolPro: expansion x", DoubleToString(vRatio,1), " +2"); }
            else if(vRatio >= 1.3)             { score += 1; filterContrib[FILT_VOL] = 1; if(ShowScoreInfo) Print("📊 VolPro: above avg x", DoubleToString(vRatio,1), " +1"); }
            // Volume climax (>3x average): احتمال exhaustion → بدون bonus
            else                                 filterContrib[FILT_VOL] = 0;  // حجم عادی → خنثی
         }
         else filterContrib[FILT_VOL] = 0;
      }
      else filterContrib[FILT_VOL] = 0;
   }
   else
      filterContrib[FILT_VOL] = -2;  // Off

   return score;
}
//| الگوریتم: Swing clustering + ARGB gradient + On Top dashboard   |
//+------------------------------------------------------------------+

struct SRCluster
{
   double price;
   int    touches;   // تعداد برخورد (قدرت سطح)
   bool   isAbove;   // بالای قیمت = مقاومت، پایین = حمایت
};

// ════════════════════════════════════════════════════════════════════
// 🆕 v7.0: TRAFFIC LIGHTS - توابع اصلی
// سه چراغ ثابت روی H1/H4/D1 - مستقل از تایم‌فریم جاری چارت
// ════════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════════
// 🆕 v7.0: FLOW توابع کمکی Sister Pairs
// ════════════════════════════════════════════════════════════════════

// یافتن نام کامل سیمبل با مدیریت پسوند بروکر (مثلاً .r، m، _SB)
// اگه AUDCAD.raw در ترمینال باشد، AUDNZD.raw را هم پیدا می‌کند
//
// 🐛 v13.49 P1 FIX: قبلاً resolve فقط با SymbolInfoDouble(sym, SYMBOL_BID) > 0.0
// چک می‌شد. در Strategy Tester، BID سیمبل‌های غیر از چارت اصلی به‌طور قابل‌اعتماد
// آپدیت نمی‌شود — بعد از چند روز شبیه‌سازی این چک می‌تواند false بدهد حتی وقتی
// سیمبل واقعاً موجود و دارای دیتای H4 است. نتیجه: fallback نادرست به base6 خام →
// iClose/CopyClose صفر برمی‌گرداند → آن خواهر سهم صفر می‌دهد → اگر برای همه
// خواهرها هم‌زمان رخ دهد، Flow_Score برای همیشه فریز می‌شود.
// راه‌حل: علاوه بر BID>0، وجود سیمبل (SYMBOL_EXIST) + کافی‌بودن دیتای H4
// (iBars > 50) هم به‌عنوان تأیید جایگزین پذیرفته می‌شود.
string FlowFindSym(string base6)
{
   // ۱) بدون پسوند (بروکرهای استاندارد) — BID زنده
   if(SymbolInfoDouble(base6, SYMBOL_BID) > 0.0) return base6;

   // 🆕 v13.49: اگه BID موقتاً صفره ولی سیمبل واقعاً وجود داره و دیتای H4 کافی داره
   // (مثلاً در بکتست بلندمدت که BID سیمبل‌های غیرچارت رفرش نمی‌شه)، همین رو قبول کن
   if(SymbolInfoInteger(base6, SYMBOL_EXIST) && iBars(base6, PERIOD_H4) > 50) return base6;

   // ۲) پسوند از سیمبل اصلی بگیر و امتحان کن
   if(StringLen(_Symbol) > 6)
   {
      string sfx       = StringSubstr(_Symbol, 6);
      string candidate = base6 + sfx;
      if(SymbolInfoDouble(candidate, SYMBOL_BID) > 0.0) return candidate;
      if(SymbolInfoInteger(candidate, SYMBOL_EXIST) && iBars(candidate, PERIOD_H4) > 50) return candidate;
   }

   // ۳) fallback: همان base6 برگردان؛ iClose خودش 0 برمی‌گرداند اگه نداشت
   return base6;
}

// محاسبه امتیاز Sister Matrix با H4 Momentum (5 کندل = 20 ساعت)
// کاملاً lightweight: فقط iClose روی H4 - هیچ handle اضافه‌ای ندارد
// forBuy: جهت پوزیشن فعال ما
double FlowEvaluate(SisterEntry &mat[], int sz, bool forBuy)
{
   // 🔒 DESIGN LOCK (v14.07): همیشه H4 — FLOW یک شاخص ساختاری است.
   // روی H1 یا کمتر = نویز. ورودی موتور Rule است — خروجی TF چارت نیست.
   // تغییر ندهید حتی اگه TF چارت متفاوت باشد.
   double score = 0.0;
   // 🆕 v13.50 FLOW-02: پرچم low-confidence این فراخوانی را ریست کن —
   // در انتها اگه پوشش وزن کافی نبود، دوباره true می‌شود.
   g_flowLowConfidence = false;
   // 🆕 v13.49 P1 FIX: به‌جای اینکه خواهرهای resolve-نشده صرفاً سهم صفر بدهند
   // (که در صورت رخداد هم‌زمان برای همه خواهرها Flow_Score را مصنوعاً کوچک/فریز
   // می‌کند)، مجموع وزن خواهرهای واقعاً استفاده‌شده را نگه می‌داریم تا در انتها
   // امتیاز را نسبت به وزن کل renormalize کنیم.
   double totalWeight = 0.0, usedWeight = 0.0;

   for(int i = 0; i < sz; i++)
   {
      totalWeight += mat[i].weight;
      string sym = FlowFindSym(mat[i].sym);

      // اطمینان از وجود داده H4 کافی
      if(Bars(sym, PERIOD_H4) < 8)
      {
         if(ShowDebugLogs)
            Print("⚠️ v13.49 FlowEvaluate: sister '", mat[i].sym, "' → resolve='", sym,
                  "' rejected (Bars H4 < 8) — سهم صفر");
         continue;
      }

      // 🐛 v13.44 FIX4: Flow freeze در بکتست روی H1
      // مشکل: iClose(sym, H4, 1) در بکتست H1، وقتی چند H1 bar داخل همان H4 هستیم،
      // مقدار ثابت برمیگردونه → fs ثابت → Flow freeze (چند روز همان عدد)
      // روی M1: هر دقیقه call میشه → MT5 buffer به‌روز → freeze نمیشه
      // راه‌حل: CopyClose مجبور MT5 میکنه buffer رو refresh کنه قبل از iClose
      double c1, c6;
      if((bool)MQLInfoInteger(MQL_TESTER))
      {
         double tmp[1];
         // یک CopyClose به MT5 سیگنال میده که H4 data رو از disk بخونه
         if(CopyClose(sym, PERIOD_H4, 1, 1, tmp) == 1) c1 = tmp[0]; else c1 = 0.0;
         if(CopyClose(sym, PERIOD_H4, 6, 1, tmp) == 1) c6 = tmp[0]; else c6 = 0.0;
      }
      else
      {
         c1 = iClose(sym, PERIOD_H4, 1);
         c6 = iClose(sym, PERIOD_H4, 6);
      }
      if(c1 <= 0.0 || c6 <= 0.0)  // داده موجود نیست
      {
         if(ShowDebugLogs)
            Print("⚠️ v13.49 FlowEvaluate: sister '", mat[i].sym, "' → resolve='", sym,
                  "' c1=", c1, " c6=", c6, " → fallback رد شد — سهم صفر");
         continue;
      }

      // جهت: +1 صعودی  -1 نزولی  0 بدون تغییر (skip)
      double dir = (c1 > c6) ? 1.0 : (c1 < c6) ? -1.0 : 0.0;
      if(dir == 0.0) continue;

      usedWeight += mat[i].weight;   // 🆕 v13.49 P1 FIX: این خواهر واقعاً مشارکت کرد

      // اگه Sell داریم، علامت همه‌ی signForBuy برعکس می‌شود
      int    effSign   = forBuy ? mat[i].signForBuy : -mat[i].signForBuy;
      double rawSignal = effSign * dir;          // +1=تأیید  -1=تضاد
      double mult      = (rawSignal < 0.0) ? mat[i].negMult : 1.0;

      score += rawSignal * mat[i].weight * mult;
   }

   // 🆕 v13.50 FLOW-02: آستانه renormalize از ۵۰٪ به ۷۰٪ افزایش یافت.
   // 🔴 مشکل v13.49: حتی با renormalize ۵۰٪، اگه خواهرهای پُروزن (GBP/EUR/NZD)
   //   resolve نمی‌شدند، امتیاز FLOW سیستماتیک منحرف می‌شد و هیچ نشانه‌ای
   //   وجود نداشت که نتیجه قابل اعتماد نیست.
   // ✅ راه‌حل: آستانه به ۷۰٪ افزایش یافت. اگه پوشش وزن کمتر از ۷۰٪ بود،
   //   renormalize انجام نمی‌شود و g_flowLowConfidence=true ست می‌شود —
   //   FLOW با پسوند (LC!) روی داشبورد نمایش می‌یابد (نگاه کن FLOW-03/LIGHT-04).
   if(usedWeight > 0.0 && usedWeight < totalWeight && usedWeight >= totalWeight * 0.7)
   {
      double renormFactor = totalWeight / usedWeight;
      if(ShowDebugLogs && renormFactor > 1.05)
         Print("ℹ️ v13.50 FlowEvaluate renormalize: usedWeight=", usedWeight,
               "/", totalWeight, " → factor=", renormFactor);
      score *= renormFactor;
   }
   else if(usedWeight < totalWeight)
   {
      // پوشش وزن کافی نیست (یا هیچ خواهری resolve نشد) → نتیجه کم‌اعتماد
      g_flowLowConfidence = true;
      if(ShowDebugLogs)
         Print("⚠️ v13.50 FlowEvaluate: پوشش وزن ناکافی (", usedWeight, "/", totalWeight,
               ") — g_flowLowConfidence=true، renormalize انجام نشد");
   }

   return score;   // raw score (v8.0: >3.0=سبز، >=-5.0=زرد، <-5.0=قرمز)
}

// 🆕 v7.0: بروزرسانی چراغ داخل داشبورد (با dashboardPrefix)
// state: -1=خاکستری(بدون پوز) 0=سبز 1=زرد 2=قرمز
// ════════════════════════════════════════════════════════════════════
// v11.2: NOTIFICATION SYSTEM — توابع ارسال اعلان
// ════════════════════════════════════════════════════════════════════

// ─── بررسی Cooldown ─────────────────────────────────────────────
// isNewEdge=true: چراغ تازه قرمز شده → Cooldown نادیده گرفته می‌شود
// isNewEdge=false: هنوز قرمز است (تکراری) → Cooldown رعایت می‌شود
bool Alert_CooldownOK(datetime &lastTime, bool isNewEdge)
{
   if(isNewEdge)
   {
      lastTime = TimeCurrent();
      return true;
   }
   datetime now = TimeCurrent();
   int cooldownSec = Alert_CooldownMinutes * 60;
   if(now - lastTime < cooldownSec) return false;
   lastTime = now;
   return true;
}

// ─── ارسال پیام به تلگرام ───────────────────────────────────────
void Alert_SendTelegram(const string message)
{
   if(!Alert_Telegram) return;
   // v11.3: اگه token پیش‌فرض یا خالی باشه → silent skip
   if(StringLen(Alert_TelegramToken) < 5 || StringLen(Alert_TelegramChatID) < 2
      || StringFind(Alert_TelegramToken, "97864663566") >= 0)
      return;  // silent - پیش‌فرض یا خالیه

   // v11.8 FIX: POST + JSON به جای GET+URLencode
   // دلیل: متن فارسی در GET request (encode ناقص) به تلگرام نمی‌رسید
   // راه‌حل: JSON body با UTF-8 مستقیم — نیازی به percent-encoding ندارد
   string url = "https://api.telegram.org/bot" + Alert_TelegramToken + "/sendMessage";

   // escape special JSON chars در متن پیام
   string txt = message;
   StringReplace(txt, "\\", "\\\\");  // backslash اول
   StringReplace(txt, "\"",  "\\\"");   // double-quote
   StringReplace(txt, "\n",  "\\n");     // newline → literal \n در JSON
   StringReplace(txt, "\r",  "\\r");

   string json = "{\"chat_id\":" + Alert_TelegramChatID + ",\"text\":\"" + txt + "\"}";

   // تبدیل JSON string به byte array با UTF-8 (برای فارسی و یونیکد)
   // CP_UTF8=65001 — بدون آن فارسی به ???? تبدیل می‌شود
   uchar  postData[];
   StringToCharArray(json, postData, 0, WHOLE_ARRAY, CP_UTF8);
   int sz = ArraySize(postData);
   if(sz > 0 && postData[sz-1] == 0) ArrayResize(postData, sz-1);  // حذف null terminator

   string reqHeaders = "Content-Type: application/json\r\n";
   char   result[];
   string resHeaders;
   ResetLastError();
   int res = WebRequest("POST", url, reqHeaders, 5000, postData, result, resHeaders);
   if(ShowDebugLogs) Print(res==200 ? "✅ Telegram OK" :
      "❌ Telegram fail HTTP="+IntegerToString(res)+" Err="+IntegerToString(GetLastError())
      +" | resp="+CharArrayToString(result));
}

// ─── ارسال عکس یک چارت مشخص به تلگرام ─────────────────────────
// chartId  : شناسه چارت (0 = چارت فعلی)
// caption  : متن زیر عکس
// fname    : نام فایل موقت
// return   : true اگه موفق بود
bool Alert_SendChartPhoto(long chartId, const string caption, const string fname)
{
   if(!Alert_Telegram) return false;
   if(StringLen(Alert_TelegramToken) < 5 || StringLen(Alert_TelegramChatID) < 2
      || StringFind(Alert_TelegramToken, "97864663566") >= 0)
      return false;

   // screenshot چارت مشخص شده
   if(!ChartScreenShot(chartId, fname, 1280, 720, ALIGN_LEFT))
   {
      Print("❌ ChartScreenShot failed chartId=", chartId, " err=", GetLastError());
      return false;
   }
   Sleep(200); // صبر کن فایل flush بشه

   // خواندن فایل
   int fh = FileOpen(fname, FILE_READ | FILE_BIN | FILE_COMMON);
   if(fh == INVALID_HANDLE)
      fh = FileOpen(fname, FILE_READ | FILE_BIN);
   if(fh == INVALID_HANDLE)
   {
      Print("❌ Cannot open screenshot err=", GetLastError());
      return false;
   }
   ulong fsize = FileSize(fh);
   if(fsize == 0) { FileClose(fh); Print("❌ Screenshot empty"); return false; }
   uchar imgData[];
   ArrayResize(imgData, (int)fsize);
   FileReadArray(fh, imgData, 0, (int)fsize);
   FileClose(fh);
   FileDelete(fname);

   // multipart/form-data
   string bnd  = "HelpMe1234567890";
   string CRLF = "\r\n";

   string p1 = "--" + bnd + CRLF
             + "Content-Disposition: form-data; name=\"chat_id\"" + CRLF + CRLF
             + Alert_TelegramChatID + CRLF;

   string cap = StringSubstr(caption, 0, 1000);
   string p2 = "--" + bnd + CRLF
             + "Content-Disposition: form-data; name=\"caption\"" + CRLF + CRLF
             + cap + CRLF;

   string p3 = "--" + bnd + CRLF
             + "Content-Disposition: form-data; name=\"photo\"; filename=\"chart.png\"" + CRLF
             + "Content-Type: image/png" + CRLF + CRLF;

   string p4 = CRLF + "--" + bnd + "--" + CRLF;

   uchar b1[], b2[], b3[], b4[];
   int n1, n2, n3, n4;
   StringToCharArray(p1, b1, 0, WHOLE_ARRAY, CP_UTF8); n1 = ArraySize(b1); if(n1>0 && b1[n1-1]==0) n1--;
   StringToCharArray(p2, b2, 0, WHOLE_ARRAY, CP_UTF8); n2 = ArraySize(b2); if(n2>0 && b2[n2-1]==0) n2--;
   StringToCharArray(p3, b3, 0, WHOLE_ARRAY, CP_UTF8); n3 = ArraySize(b3); if(n3>0 && b3[n3-1]==0) n3--;
   StringToCharArray(p4, b4, 0, WHOLE_ARRAY, CP_UTF8); n4 = ArraySize(b4); if(n4>0 && b4[n4-1]==0) n4--;

   int total = n1 + n2 + n3 + (int)fsize + n4;
   uchar body[];
   ArrayResize(body, total);
   int off = 0;
   ArrayCopy(body, b1, off, 0, n1); off += n1;
   ArrayCopy(body, b2, off, 0, n2); off += n2;
   ArrayCopy(body, b3, off, 0, n3); off += n3;
   ArrayCopy(body, imgData, off, 0, (int)fsize); off += (int)fsize;
   ArrayCopy(body, b4, off, 0, n4);

   string url = "https://api.telegram.org/bot" + Alert_TelegramToken + "/sendPhoto";
   string hdr = "Content-Type: multipart/form-data; boundary=" + bnd + "\r\n";
   char   res[];
   string resHdr;
   ResetLastError();
   int code = WebRequest("POST", url, hdr, 10000, body, res, resHdr);
   if(code == 200)
   {
      Print("✅ Telegram Photo OK | ", caption);
      return true;
   }
   Print("❌ Telegram Photo HTTP=", code, " err=", GetLastError(),
         " resp=", CharArrayToString(res, 0, MathMin(200, ArraySize(res))));
   return false;
}

// ─── backward compat wrapper (صدا زده میشه از Alert_CheckAndSend) ─
void Alert_SendTelegramPhoto(const string caption)
{
   string sym = _Symbol;
   // caption فعلی از بیرون میاد مثلا "EURUSD | Score:45"
   // V13.10: TF فعلی (H1) رو اضافه کن
   string tf  = EnumToString((ENUM_TIMEFRAMES)Period());
   StringReplace(tf, "PERIOD_", "");
   // اگه caption قبلاً TF داره skip (جلوگیری از دوباره‌کاری)
   string capFull = caption;
   if(StringFind(caption, "|") >= 0 && StringFind(caption, "H1") < 0 &&
      StringFind(caption, "M1") < 0 && StringFind(caption, "M5") < 0)
      capFull = sym + " | " + tf + " | Score:" + DoubleToString(g_csvScore, 0);

   Alert_SendChartPhoto(0, capFull, "hm_chart_h1.png");
}

// ─── V13.10: ارسال عکس چارت‌های اضافی (M5, M30, D1) ────────────
// فقط برای StatusQuery — بدون متن وضعیت (فقط عکس)
void Alert_SendExtraCharts(const string sym)
{
   // تایم‌فریم‌هایی که باید ارسال بشن
   ENUM_TIMEFRAMES tfs[3];
   tfs[0] = PERIOD_M5;
   tfs[1] = PERIOD_M30;
   tfs[2] = PERIOD_D1;

   string tfNames[3];
   tfNames[0] = "M5";
   tfNames[1] = "M30";
   tfNames[2] = "D1";

   for(int i = 0; i < 3; i++)
   {
      long foundChartId = -1;

      // جستجوی چارت با این symbol و timeframe در بین چارت‌های باز
      long cid = ChartFirst();
      while(cid >= 0)
      {
         if(ChartSymbol(cid) == sym && ChartPeriod(cid) == tfs[i])
         {
            foundChartId = cid;
            break;
         }
         cid = ChartNext(cid);
         if(cid < 0) break;
      }

      if(foundChartId < 0)
      {
         Print("📷 Extra chart not found: ", sym, " ", tfNames[i], " — skip");
         continue;
      }

      string cap   = sym + " | " + tfNames[i];
      string fname = "hm_chart_" + tfNames[i] + ".png";
      Alert_SendChartPhoto(foundChartId, cap, fname);

      Sleep(300); // کمی فاصله بین ارسال‌ها تا flood نشه
   }
}


void Alert_SendPush(const string message)
{
   if(!Alert_MT5Push) return;
   SendNotification(message);
   if(ShowDebugLogs) Print("📱 MT5 Push: ", message);
}

// ─── ارسال اعلان به همه کانال‌های فعال ─────────────────────────
void Alert_Send(const string message)
{
   // 🆕 v13.15 FIX: گارد ریشه‌ای — هیچ Push/Telegram در بکتست واقعی
   // ارسال نمیشه (بدون اینترنت). این تنها نقطه ورودیه که همه‌ی
   // Alert_CheckAndSend / Calc_MktPhase / Calc_SpikeDetector و... از آن رد میشن
   if((bool)MQLInfoInteger(MQL_TESTER)) return;

   Alert_SendPush(message);
   Alert_SendTelegram(message);
}

// ─── بررسی تغییر چراغ‌ها و ارسال اعلان ─────────────────────────
// منطق Cooldown:
//   isNewEdge=true  → چراغ تازه قرمز شده → همیشه ارسال (حتی زیر Cooldown)
//   isNewEdge=false → هنوز قرمز است (تکراری) → فقط اگه Cooldown تموم شده
void Alert_CheckAndSend(bool forBuy, bool highAlertActive)
{
   string sym  = _Symbol;
   string dir  = forBuy ? "BUY" : "SELL";
   string head = "HelpMe [" + sym + " " + dir + "]\n";

   // ─── CRISIS ──────────────────────────────────────────────────
   // 🆕 v13.19: Orange (3) حالا هم می‌تونه اعلان بفرسته — مثل Red، با
   // اینپوت جدا (Alert_OnCrisisOrange) که پیش‌فرضش روشنه.
   if(Alert_OnCrisis || Alert_OnCrisisOrange)
   {
      bool nowAlert  = (g_crisisState == 2 && Alert_OnCrisis) ||
                        (g_crisisState == 3 && Alert_OnCrisisOrange);
      bool prevAlert = (g_prevAlertCrisis == 2 && Alert_OnCrisis) ||
                        (g_prevAlertCrisis == 3 && Alert_OnCrisisOrange);
      bool isNewEdge = nowAlert && !prevAlert;
      if(nowAlert && Alert_CooldownOK(g_lastAlertTime_Crisis, isNewEdge))
      {
         string emoji = (g_crisisState == 2) ? "🔴" : "🟠";
         string msg = head + StringFormat("🚨 Crisis %s شد\n"
            "━━━━━━━━━━━━━━━━\n"
            "ADX: %.0f | Flow: %.1f\n"
            "━━━━━━━━━━━━━━━━\n"
            "اگه Rule هنوز CLOSE نداده\n"
            "خودت دستی چک کن و ببند", emoji, g_lastAdxVal, g_lastFlowScore);
         Alert_Send(msg);
      }
   }
   g_prevAlertCrisis = g_crisisState;

   // ─── HIGH ALERT ──────────────────────────────────────────────
   if(Alert_OnHighAlert)
   {
      bool isNewEdge = highAlertActive && !g_prevAlertHighAlt;
      if(highAlertActive && Alert_CooldownOK(g_lastAlertTime_HighAlt, isNewEdge))
      {
         string msg = head + "⚡ High Alert روشن شد\n"
            + StringFormat("━━━━━━━━━━━━━━━━\n"
               "ADX: %.0f | Flow: %.1f\n"
               "━━━━━━━━━━━━━━━━\n"
               "یعنی Crisis داره نزدیک میشه\n"
               "بررسی کن اگه Crisis قرمز شد آماده باش", g_lastAdxVal, g_lastFlowScore);
         Alert_Send(msg);
      }
      g_prevAlertHighAlt = highAlertActive;
   }

   // ─── ZOMBIE ──────────────────────────────────────────────────
   if(Alert_OnZombie)
   {
      bool isNewEdge = (g_lightZOMBIE == 2 && g_prevAlertZOMBIE != 2);
      if(g_lightZOMBIE == 2 && Alert_CooldownOK(g_lastAlertTime_ZOMBIE, isNewEdge))
      {
         Alert_Send(head + "🧟 Zone عوض شد\n"
            "━━━━━━━━━━━━━━━━\n"
            "قیمت ۲ طبقه از ورود دور شده\n"
            "اگه Crisis هم قرمزه خیلی خطرناکه");
      }
      g_prevAlertZOMBIE = g_lightZOMBIE;
   }

   // ─── FLOW ────────────────────────────────────────────────────
   if(Alert_OnFlow)
   {
      bool isNewEdge = (g_lightFLOW == 2 && g_prevAlertFLOW != 2);
      if(g_lightFLOW == 2 && Alert_CooldownOK(g_lastAlertTime_FLOW, isNewEdge))
      {
         Alert_Send(head + "🌊 Flow قرمز شد\n"
            "━━━━━━━━━━━━━━━━\n"
            + StringFormat("Flow: %.1f\n", g_lastFlowScore)
            + "━━━━━━━━━━━━━━━━\n"
            "ارزهای خواهر همگی خلاف جهت تو دارن میرن\n"
            "اگه Crisis هم قرمزه منتظر برگشت نباش");
      }
      g_prevAlertFLOW = g_lightFLOW;
   }

   // ─── ADX ─────────────────────────────────────────────────────
   if(Alert_OnADX)
   {
      bool isNewEdge = (g_lightTrend == 2 && g_prevAlertTrend != 2);
      if(g_lightTrend == 2 && Alert_CooldownOK(g_lastAlertTime_Trend, isNewEdge))
      {
         Alert_Send(head + "📈 Trend Str قرمز شد\n"
            "━━━━━━━━━━━━━━━━\n"
            + StringFormat("ADX: %.0f\n", g_lastAdxVal)
            + "━━━━━━━━━━━━━━━━\n"
            "روند قوی خلاف معامله شکل گرفته\n"
            "به تنهایی کافی نیست ولی Crisis رو چک کن");
      }
      g_prevAlertTrend = g_lightTrend;
   }

   // ─── RTM ─────────────────────────────────────────────────────
   if(Alert_OnRTM)
   {
      bool isNewEdge = (g_lightRTM == 2 && g_prevAlertRTM != 2);
      if(g_lightRTM == 2 && Alert_CooldownOK(g_lastAlertTime_RTM, isNewEdge))
      {
         Alert_Send(head + "🔄 RTM قرمز شد\n"
            "━━━━━━━━━━━━━━━━\n"
            "قیمت از EMA200 خلاف جهت تو داره فاصله میگیره\n"
            "تنها ملاک نیست ولی با Crisis ترکیب خطرناکه");
      }
      g_prevAlertRTM = g_lightRTM;
   }

   // ─── STRUCT ──────────────────────────────────────────────────
   if(Alert_OnStruct)
   {
      bool isNewEdge = (g_lightStruct == 2 && g_prevAlertStruct != 2);
      if(g_lightStruct == 2 && Alert_CooldownOK(g_lastAlertTime_Struct, isNewEdge))
      {
         Alert_Send(head + "🏗 ساختار روزانه شکست\n"
            "━━━━━━━━━━━━━━━━\n"
            "سقف یا کف روزانه شکسته شد\n"
            "برگشت سخت‌تر میشه — Crisis رو جدی بگیر");
      }
      g_prevAlertStruct = g_lightStruct;
   }

   // ─── THREE LIGHTS: 3 چراغ از 4 همزمان قرمز ──────────────────
   // چراغ‌های مشمول: ADX, RTM, STRUCT, FLOW (همان 4 چراغ RC)
   if(Alert_OnThreeLights)
   {
      int redCount4 = (g_lightTrend  == 2 ? 1 : 0)
                    + (g_lightRTM    == 2 ? 1 : 0)
                    + (g_lightStruct == 2 ? 1 : 0)
                    + (g_lightFLOW   == 2 ? 1 : 0);
      bool now3Red   = (redCount4 >= 3);
      bool isNewEdge = now3Red && !g_prev3LightsAlert;
      if(now3Red && Alert_CooldownOK(g_lastAlertTime_3Lights, isNewEdge))
      {
         string which = "";
         if(g_lightRTM    == 2) which += "RTM ";
         if(g_lightTrend  == 2) which += "ADX ";
         if(g_lightStruct == 2) which += "STRUCT ";
         if(g_lightFLOW   == 2) which += "FLOW ";
         Alert_Send(head
            + StringFormat("🔴🔴🔴 سه چراغ قرمز (%d از ۴)\n", redCount4)
            + "━━━━━━━━━━━━━━━━\n"
            + "قرمز: " + which + "\n"
            + StringFormat("ADX: %.0f | Flow: %.1f\n", g_lastAdxVal, g_lastFlowScore)
            + "━━━━━━━━━━━━━━━━\n"
            + "منتظر نباش — Crisis رو الان چک کن");
      }
      g_prev3LightsAlert = now3Red;
   }
}

// v9.0: UpdateCrisisLight — چراغ CRISIS (بهبود یافته)
// rc=-1 یعنی بدون پوزیشن (خاکستری)
//
// پارامترهای جدید:
//   trendScore : امتیاز روند HelpMe (-100 تا +100) از g_csvScore
//   forBuy     : جهت پوزیشن فعال (true=Long, false=Short)
//
// TrendScore Against Position (TsAgainst):
//   برای Long:  TsAgainst = -trendScore  (منفی‌تر = روند بیشتر علیه ما)
//   برای Short: TsAgainst = +trendScore  (مثبت‌تر = روند بیشتر علیه ما)
//   هرچه TsAgainst بالاتر، روند قوی‌تر علیه پوزیشن ما حرکت می‌کند
//
// CRISIS RED — الگوی A یا B:
//   A (کلاسیک): RC>=3  AND  Flow<=-7.0  AND  ADX>32
//   B (فشار شدید): RC>=2  AND  Flow<=-8.5  AND  ADX>40
//     دلیل B: معاملاتی که ADX خیلی بالا (>40) و Flow خیلی منفی (<=-8.5)
//             دارند حتی با RC=2 در خطر جدی هستند (مثل ۶ مارس: ADX=49, Flow=-9.25)
//
// CRISIS YELLOW — هر یک از شرایط:
//   Y1: RC>=2                                       (کلاسیک)
//   Y2: Flow<=-5.0  AND  ADX>28                    (کلاسیک)
//   Y3: RC>=2  AND  Flow<=-7.0  AND  TsAgainst>30  (جدید — فشار پایدار)
//   Y4: RC>=2  AND  TsAgainst>45  AND  ADX>25      (جدید — واگرایی جهت)
//   Y5: RC>=2  AND  Flow<=-7.5  AND  ADX>35        (جدید — نزدیک به B)
// ════════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════════
// 🆕 v13.15: Crisis_GetThresholds — آستانه‌های ADX/Flow وابسته به سیمبل
// دلیل: GBPNZD ذاتاً ADX بالاتری داره — ADX=32 برای این جفت نرمال
// است نه خطرناک. این تابع تنها منبع آستانه‌هاست تا UpdateCrisisLight
// و محاسبه g_lightGOLDEN (برای CSV/بکتست) همیشه سینک بمونن.
// ════════════════════════════════════════════════════════════════════
void Crisis_GetThresholds(
   double &th_RedA_ADX, double &th_RedA_Flow,
   double &th_RedB_ADX, double &th_RedB_Flow,
   double &th_OrA_ADX,  double &th_OrA_Flow,
   double &th_OrB_ADX,  double &th_OrB_Ts,
   double &th_OrC_ADX,  double &th_OrC_Flow, double &th_OrC_Ts,
   double &th_OrD_ADX,  double &th_OrD_Ts,    // 🆕 v13.16: مسیر مستقل از FLOW
   double &th_Y2_ADX,   double &th_Y2_Flow,
   double &th_Y3_Flow,  double &th_Y3_Ts,
   double &th_Y4_ADX,   double &th_Y4_Ts,
   double &th_Y5_ADX,   double &th_Y5_Flow,
   string symOverride = "")   // 🆕 v14.00: برای FOREIGN on-demand — سمبلی غیر از _Symbol
{
   string checkSym = (symOverride != "") ? symOverride : _Symbol;
   // آستانه‌های پایه (AUDCAD و بقیه) — کالیبره برای رفتار AUDCAD
   th_RedA_ADX = 32.0;  th_RedA_Flow = 7.0;
   th_RedB_ADX = 40.0;  th_RedB_Flow = 8.5;
   th_OrA_ADX  = 30.0;  th_OrA_Flow  = 6.5;
   th_OrB_ADX  = 28.0;  th_OrB_Ts    = 40.0;
   th_OrC_ADX  = 32.0;  th_OrC_Flow  = 7.5; th_OrC_Ts = 25.0;
   th_OrD_ADX  = 32.0;  th_OrD_Ts    = 50.0;   // 🆕 v13.16
   th_Y2_ADX   = 28.0;  th_Y2_Flow   = 5.0;
   th_Y3_Flow  = 7.0;   th_Y3_Ts     = 30.0;
   th_Y4_ADX   = 25.0;  th_Y4_Ts     = 45.0;
   th_Y5_ADX   = 35.0;  th_Y5_Flow   = 7.5;

   if(StringFind(checkSym, "GBPNZD") >= 0)
   {
      // GBPNZD: ADX به‌طور طبیعی بالاتره — آستانه‌ها بالاتر برده شدن
      // تا فقط حرکات واقعاً غیرعادی (نه نوسان عادی این جفت) قرمز/زرد بشن
      th_RedA_ADX = 28.0;  th_RedA_Flow = 6.0;
      th_RedB_ADX = 35.0;  th_RedB_Flow = 7.5;
      th_OrA_ADX  = 26.0;  th_OrA_Flow  = 5.5;
      th_OrB_ADX  = 24.0;
      th_OrC_ADX  = 28.0;  th_OrC_Flow  = 6.5;
      // 🆕 v13.18: کالیبراسیون دور دوم — 33/45 هنوز سخت‌گیرانه‌تر از حد
      // لازم بود؛ آستانه‌ها کمی شل‌تر شدن تا بحران‌های واقعی زودتر گرفته بشن
      th_OrD_ADX  = 30.0;  th_OrD_Ts    = 40.0;   // 🆕 v13.18 (قبلاً 33.0/45.0 در v13.17)
      th_Y2_ADX   = 24.0;  th_Y2_Flow   = 4.0;
      th_Y3_Flow  = 6.0;
      th_Y4_ADX   = 21.0;
      th_Y5_ADX   = 31.0;  th_Y5_Flow   = 6.5;
   }
   else if(StringFind(checkSym, "EURGBP") >= 0)
   {
      // 🆕 v14.07 PATCH-D1: شاخه اختصاصی EURGBP در Crisis_GetThresholds
      // ⚠️ این اعداد موقت هستند و باید با بکتست EURGBP 2024-2026 کالیبره شوند.
      // فعلاً مشابه GBPNZD با کمی تفاوت — EURGBP نوسان کمتری دارد
      th_RedA_ADX = 26.0;  th_RedA_Flow = 5.5;
      th_RedB_ADX = 33.0;  th_RedB_Flow = 7.0;
      th_OrA_ADX  = 24.0;  th_OrA_Flow  = 5.0;
      th_OrB_ADX  = 22.0;  th_OrB_Ts    = 38.0;
      th_OrC_ADX  = 26.0;  th_OrC_Flow  = 6.0; th_OrC_Ts = 22.0;
      th_OrD_ADX  = 28.0;  th_OrD_Ts    = 38.0;
      th_Y2_ADX   = 22.0;  th_Y2_Flow   = 3.5;
      th_Y3_Flow  = 5.5;   th_Y3_Ts     = 28.0;
      th_Y4_ADX   = 19.0;  th_Y4_Ts     = 42.0;
      th_Y5_ADX   = 29.0;  th_Y5_Flow   = 6.0;
   }
   // پیش‌فرض AUDCAD — مقادیر پایه برای سمبل‌های ناشناخته هم همین هستند
}

void UpdateCrisisLight(int rc, double flowScore, double adxVal,
                       double trendScore = 0.0, bool forBuy = true)
{
   long chart_id = ChartID();
   if(g_isDeinitializing)
   {
      HM_DeleteObjectHard(chart_id, CRISIS_OBJ);
      return;
   }
   color bg_col, txt_col;
   string txt, tip;

   // 🆕 v13.15: آستانه‌های ADX/Flow وابسته به سیمبل (از تابع مشترک)
   double th_RedA_ADX, th_RedA_Flow, th_RedB_ADX, th_RedB_Flow;
   double th_OrA_ADX, th_OrA_Flow, th_OrB_ADX, th_OrB_Ts;
   double th_OrC_ADX, th_OrC_Flow, th_OrC_Ts;
   double th_OrD_ADX, th_OrD_Ts;   // 🆕 v13.16: Orange-D — مسیر مستقل از FLOW
   double th_Y2_ADX, th_Y2_Flow, th_Y3_Flow, th_Y3_Ts;
   double th_Y4_ADX, th_Y4_Ts, th_Y5_ADX, th_Y5_Flow;
   Crisis_GetThresholds(
      th_RedA_ADX, th_RedA_Flow, th_RedB_ADX, th_RedB_Flow,
      th_OrA_ADX, th_OrA_Flow, th_OrB_ADX, th_OrB_Ts,
      th_OrC_ADX, th_OrC_Flow, th_OrC_Ts,
      th_OrD_ADX, th_OrD_Ts,    // 🆕 v13.16
      th_Y2_ADX, th_Y2_Flow, th_Y3_Flow, th_Y3_Ts,
      th_Y4_ADX, th_Y4_Ts, th_Y5_ADX, th_Y5_Flow);

   // TrendScore علیه پوزیشن: هرچه بالاتر، بازار بیشتر خلاف ما
   double tsAgainst = forBuy ? -trendScore : trendScore;

   // 🐛 v13.33 FIX — flowAgainst sign همسو با LogHourlySnapshot و CrisisAtBar
   // قبلاً: flowAgainst = forBuy ? -flowScore : flowScore
   //   برای Sell: flowAgainst = flowScore = fsSell = مثلاً -9.62 (منفی!)
   //   شرط Red: -9.62 >= 6.0 = FALSE → Crisis هرگز Red نمی‌شد برای Sell!
   // اما LogHourlySnapshot (که CSV بکتست را می‌سازد) درست کار می‌کرد:
   //   isRedA = (flowScore <= -th_RedA_Flow) ← معادل flowAgainst = -flowScore
   // FlowEvaluate برای هر دو جهت وقتی بازار علیه ماست:
   //   fsBuy = -9.62 (منفی) → -fsBuy = +9.62 → Red ✓ (قبلاً هم درست بود)
   //   fsSell = -9.62 (منفی) → -fsSell = +9.62 → Red ✓ (FIX)
   // یعنی: flowAgainst = -flowScore همیشه درست است.
   // مثال Buy:  Flow=-9 → flowAgainst=+9 (خیلی بد) ✓
   // مثال Sell: Flow=-9 → flowAgainst=+9 (خیلی بد) ✓ (قبلاً: +9 فقط اگه Flow=+9 می‌بود!)
   double flowAgainst = -flowScore;

   if(rc < 0)
   {
      // ── بدون پوزیشن: خاکستری ──────────────────────────────────
      g_crisisState = -1;
      bg_col  = clrDimGray;
      txt_col = clrWhite;
      txt = "   CRISIS: No Position  ";
      tip = " .هنوز پوزیشنی باز نیست";
   }
   // ══════════════════════════════════════════════════════════════
   // 🔴 CRISIS RED — فرار فوری!
   // الگوی A: کلاسیک (وایپ‌اوت مارس ۲۰۲۵ را گرفت)
   // الگوی B: فشار شدید ADX+Flow بدون نیاز به RC=3
   // ══════════════════════════════════════════════════════════════
   else if(
      // الگوی A (کلاسیک): FIX v12.09 از flowAgainst استفاده می‌شود (Buy و Sell هر دو)
      (rc >= 3 && flowAgainst >= th_RedA_Flow && adxVal > th_RedA_ADX)
      ||
      // الگوی B (فشار شدید — جدید v9.0):
      (rc >= 2 && flowAgainst >= th_RedB_Flow && adxVal > th_RedB_ADX)
   )
   {
      g_crisisState = 2;
      // 🆕 v10.2: Persistence tracking
      if(g_lastCrisisState == 2) g_crisisRedCount++;
      else { g_crisisRedCount = 1; }
      if(g_lastCrisisState >= 2) g_crisisOrangeCount++;
      else g_crisisOrangeCount = 1;
      g_lastCrisisState = 2;

      bg_col  = clrRed;
      txt_col = clrWhite;

      // 🆕 v10.2: اگه Red پایدار است (2+ چک متوالی)، پیام تأکیدی
      string persistNote = (g_crisisRedCount >= 2)
         ? StringFormat("⚠️ پایدار: %d چک متوالی Red!\n", g_crisisRedCount)
         : "";
      txt = StringFormat("  ⬤ CRISIS: 🔴 CLOSE NOW! %s ", (g_crisisRedCount >= 2) ? "⚠️" : "");

      // توضیح دقیق کدام الگو فعال شده
      string activePattern;
      if(rc >= 3 && flowAgainst >= th_RedA_Flow && adxVal > th_RedA_ADX)
         activePattern = StringFormat(
            "🔴 الگوی A (کلاسیک):\n"
            "   ✅ RedCount=%d (≥3)\n"
            "   ✅ FlowAgainst=%.1f (≥%.1f)\n"
            "   ✅ ADX=%.1f (>%.0f)",
            rc, flowAgainst, th_RedA_Flow, adxVal, th_RedA_ADX);
      else
         activePattern = StringFormat(
            "🔴 الگوی B (فشار شدید):\n"
            "   ✅ RedCount=%d (≥2)\n"
            "   ✅ FlowAgainst=%.1f (≥%.1f) ← سونامی!\n"
            "   ✅ ADX=%.1f (>%.0f) ← روند خیلی قوی!",
            rc, flowAgainst, th_RedB_Flow, adxVal, th_RedB_ADX);

      tip = StringFormat(
         "🚨 خطر جدی\n"
         "──────────────────────\n"
         "%s\n"
         "%s"
         "──────────────────────\n"
         "TrendScore: %.1f (علیه پوزیشن: %.1f)\n"
         "جهت: %s | پایداری: %d چک متوالی\n"
         "──────────────────────\n"
         "⛔ اگر در پله ۵ هستی: الان دستی ببند!",
         activePattern, persistNote, trendScore, tsAgainst,
         forBuy ? "Long (Buy)" : "Short (Sell)", g_crisisRedCount);
   }
   // ══════════════════════════════════════════════════════════════
   // 🟠 CRISIS ORANGE — هشدار زودهنگام (جدید v10.2!)
   // هدف: کاهش تأخیر از ۱۹ ساعت به ~۱۰ ساعت
   // شرط: نزدیک به Red اما هنوز برنگشته
   // ══════════════════════════════════════════════════════════════
   else if(
      // Orange-A: RC>=2 + Flow خیلی علیه پوزیشن + ADX بالا (نزدیک به Red-A) — FIX v12.09
      (rc >= 2 && flowAgainst >= th_OrA_Flow && adxVal > th_OrA_ADX)
      ||
      // Orange-B: RC>=3 + TrendScore قوی علیه ما + ADX متوسط
      (rc >= 3 && tsAgainst > th_OrB_Ts && adxVal > th_OrB_ADX)
      ||
      // Orange-C: RC>=2 + Flow شدید + روند قوی علیه (مثل Red-B اما ضعیف‌تر) — FIX v12.09
      (rc >= 2 && flowAgainst >= th_OrC_Flow && adxVal > th_OrC_ADX && tsAgainst > th_OrC_Ts)
      ||
      // 🆕 v13.16 Orange-D: TrendScore قوی + ADX — مستقل از FLOW و RC
      // این مسیر بحران‌هایی رو می‌گیره که FLOW به آستانه نرسیده
      // (مثل Feb06, May09, Jun11 در بکتست GBPNZD)
      (tsAgainst > th_OrD_Ts && adxVal > th_OrD_ADX)
      ||
      // 🆕 v13.50 LIGHT-04: fallback بدون FLOW در شرایط low-confidence
      // 🟡 مشکل: Orange A/C به flowAgainst وابسته‌اند — در g_flowLowConfidence
      //   (وقتی خواهرهای پُروزن FLOW resolve نشدن)، این دو مسیر هرگز فایر نمی‌شدند
      //   و تنها Orange-B/D (که ذاتاً مستقل از FLOW هستند) باقی می‌ماندند.
      // ✅ راه‌حل: وقتی g_flowLowConfidence فعال است، شرط‌های ساده‌تر (بدون Flow)
      //   جایگزین Orange-A/C می‌شوند — rc/ADX/tsAgainst به‌تنهایی.
      (g_flowLowConfidence && rc >= 3 && adxVal > th_OrA_ADX)
      ||
      (g_flowLowConfidence && rc >= 2 && adxVal > th_OrC_ADX && tsAgainst > th_OrC_Ts)
   )
   {
      g_crisisState = 3;   // 3 = ORANGE (جدید)
      // Persistence tracking
      if(g_lastCrisisState >= 2) g_crisisOrangeCount++;
      else if(g_lastCrisisState == 3) g_crisisOrangeCount++;
      else g_crisisOrangeCount = 1;
      g_crisisRedCount = 0;  // Red ریست می‌شود چون Orange هستیم نه Red
      g_lastCrisisState = 3;

      bg_col  = C'140,70,0';    // نارنجی تیره (بین زرد و قرمز)
      txt_col = clrOrange;

      string persistOrange = (g_crisisOrangeCount >= 2)
         ? StringFormat(" [%d چک پایدار]", g_crisisOrangeCount) : "";
      // 🆕 v13.50 LIGHT-04: نشانگر (LC) وقتی Orange از مسیر fallback بدون FLOW فعال شده
      string lcSuffix = (g_flowLowConfidence &&
                          !(rc >= 2 && flowAgainst >= th_OrA_Flow && adxVal > th_OrA_ADX) &&
                          !(rc >= 3 && tsAgainst > th_OrB_Ts && adxVal > th_OrB_ADX) &&
                          !(rc >= 2 && flowAgainst >= th_OrC_Flow && adxVal > th_OrC_ADX && tsAgainst > th_OrC_Ts) &&
                          !(tsAgainst > th_OrD_Ts && adxVal > th_OrD_ADX))
         ? " (LC)" : "";

      txt = StringFormat("  ⬤ CRISIS: 🟠 EARLY WARN!%s%s ", persistOrange, lcSuffix);

      string whyOrange = "";
      if(rc >= 2 && flowAgainst >= th_OrA_Flow && adxVal > th_OrA_ADX)
         whyOrange += StringFormat("Orange-A: RC=%d + FlowAgainst=%.1f + ADX=%.1f\n", rc, flowAgainst, adxVal);
      if(rc >= 3 && tsAgainst > th_OrB_Ts && adxVal > th_OrB_ADX)
         whyOrange += StringFormat("Orange-B: RC=%d + TsAgainst=%.1f + ADX=%.1f\n", rc, tsAgainst, adxVal);
      if(rc >= 2 && flowAgainst >= th_OrC_Flow && adxVal > th_OrC_ADX && tsAgainst > th_OrC_Ts)
         whyOrange += StringFormat("Orange-C: RC=%d + FlowAgainst=%.1f + ADX=%.1f + TsAg=%.1f\n", rc, flowAgainst, adxVal, tsAgainst);
      if(tsAgainst > th_OrD_Ts && adxVal > th_OrD_ADX)
         whyOrange += StringFormat("Orange-D: TsAgainst=%.1f (>%.0f) + ADX=%.1f (>%.0f) ← مستقل از FLOW\n", tsAgainst, th_OrD_Ts, adxVal, th_OrD_ADX);

      tip = StringFormat(
         "هشدار زودهنگام بین زرد و قرمز\n"
         "──────────────────────\n"
         "RC=%d | Flow=%.1f | ADX=%.1f\n"
         "TrendScore=%.1f | TsAgainst=%.1f\n"
         "جهت: %s | پایداری: %d چک\n"
         "──────────────────────\n"
         "دلایل Orange:\n%s"
         "──────────────────────\n",
         rc, flowScore, adxVal, trendScore, tsAgainst,
         forBuy ? "Long (Buy)" : "Short (Sell)",
         g_crisisOrangeCount, whyOrange);
   }
   // ══════════════════════════════════════════════════════════════
   // 🟡 CRISIS YELLOW — احتیاط و نظارت بیشتر
   // Y1,Y2: کلاسیک | Y3,Y4,Y5: جدید v9.0
   // ══════════════════════════════════════════════════════════════
   else if(
      // Y1 — کلاسیک: چند چراغ همزمان قرمز
      (rc >= 2)
      ||
      // Y2 — کلاسیک: Flow+ADX هشداردهنده — FIX v12.09: flowAgainst برای Buy و Sell
      (flowAgainst >= th_Y2_Flow && adxVal > th_Y2_ADX)
      ||
      // Y3 — جدید: RC=2 + Flow علیه پوزیشن + روند قوی علیه ما — FIX v12.09
      // این الگو معامله ۲۸ ژوئیه را می‌گیرد (RC=2, Flow=-7, TS=-45)
      (rc >= 2 && flowAgainst >= th_Y3_Flow && tsAgainst > th_Y3_Ts)
      ||
      // Y4 — جدید: RC=2 + روند خیلی قوی علیه جهت پوزیشن
      // این الگو معامله ۱۴ مارس Short را می‌گیرد (TS=+46 علیه Short)
      (rc >= 2 && tsAgainst > th_Y4_Ts && adxVal > th_Y4_ADX)
      ||
      // Y5 — جدید: RC=2 + Flow شدید + ADX قوی (زیر آستانه Red-B) — FIX v12.09
      // این الگو معامله ۶ مارس را زودتر Yellow می‌گیرد
      (rc >= 2 && flowAgainst >= th_Y5_Flow && adxVal > th_Y5_ADX)
   )
   {
      g_crisisState = 1;
      // 🆕 v10.2: Persistence reset
      g_crisisOrangeCount = 0;
      g_crisisRedCount = 0;
      if(g_lastCrisisState != 1) g_lastCrisisState = 1;

      bg_col  = (color)0x008080A0;
      txt_col = clrGold;
      txt = "  ⬤ CRISIS: ⚠ WATCH  ";

      // تشخیص کدام شرط Yellow فعال شده
      string whyYellow = "";
      if(rc >= 2)
         whyYellow += StringFormat("Y1: %d چراغ قرمز همزمان\n", rc);
      if(flowAgainst >= th_Y2_Flow && adxVal > th_Y2_ADX)
         whyYellow += StringFormat("Y2: FlowAgainst=%.1f + ADX=%.1f\n", flowAgainst, adxVal);
      if(rc >= 2 && flowAgainst >= th_Y3_Flow && tsAgainst > th_Y3_Ts)
         whyYellow += StringFormat("Y3: FlowAgainst=%.1f + TsAgainst=%.1f (روند علیه ما)\n", flowAgainst, tsAgainst);
      if(rc >= 2 && tsAgainst > th_Y4_Ts && adxVal > th_Y4_ADX)
         whyYellow += StringFormat("Y4: TsAgainst=%.1f + ADX=%.1f (واگرایی جهت)\n", tsAgainst, adxVal);
      if(rc >= 2 && flowAgainst >= th_Y5_Flow && adxVal > th_Y5_ADX)
         whyYellow += StringFormat("Y5: FlowAgainst=%.1f + ADX=%.1f (نزدیک Red-B)\n", flowAgainst, adxVal);

      tip = StringFormat(
         "RedCount=%d\n"
         "──────────────────────\n"
         "Flow=%.1f | ADX=%.1f\n"
         "TrendScore=%.1f | TsAgainst=%.1f\n"
         "──────────────────────\n"
         ".شرایط قرمز هنوز تکمیل نشده اما نگران‌کننده است\n"
         "──────────────────────\n",
         rc, flowScore, adxVal, trendScore, tsAgainst,
         forBuy ? "Long (Buy)" : "Short (Sell)",
         whyYellow);
   }
   else
   {
      // ── 🟢 سبز: امن ────────────────────────────────────────────
      g_crisisState = 0;
      // 🆕 v10.2: Persistence reset
      g_crisisOrangeCount = 0;
      g_crisisRedCount    = 0;
      g_lastCrisisState   = 0;

      bg_col  = (color)0x00204020;
      txt_col = clrLime;
      txt = "  ⬤ CRISIS: ✓ SAFE  ";
      tip = StringFormat(
         "RedCount=%d\n"
         "──────────────────────\n"
         "Flow=%.1f | ADX=%.1f\n"
         "TrendScore=%.1f | TsAgainst=%.1f\n"
         "──────────────────────\n"
         ".اعتماد کن — معامله دارد کار می‌کند Xmoon به\n"
         "──────────────────────\n",
         rc, flowScore, adxVal, trendScore, tsAgainst,
         forBuy ? "Long (Buy)" : "Short (Sell)");
   }

   // ── v12: CRISIS داخل داشبورد (TL_CRISIS label) ─────────────────
   // دیگر CRISIS_OBJ خارج از داشبورد نداریم
   // متن ساده: «ایمن» / «خطر» با tooltip کامل
   {
      string crNm   = dashboardPrefix + "TL_CRISIS";
      string crTxt;
      color  crColor;
      if(rc < 0)
      {
         crTxt   = "● Crisis: --";
         crColor = clrDimGray;
      }
      else if(g_crisisState == 2)
      {
         crTxt   = "● Crisis: Danger 🔴";
         crColor = clrRed;
      }
      else if(g_crisisState == 1)
      {
         crTxt   = "● Crisis: Warning 🟡";
         crColor = clrGold;
      }
      else
      {
         crTxt   = "● Crisis: Safe ✅";
         crColor = clrLime;
      }
      if(ObjectFind(0, crNm) >= 0)
      {
         ObjectSetString (0, crNm, OBJPROP_TEXT,    crTxt);
         ObjectSetInteger(0, crNm, OBJPROP_COLOR,   crColor);
         ObjectSetString (0, crNm, OBJPROP_TOOLTIP, SafeTip(tip));
      }
      // حذف CRISIS_OBJ قدیمی اگه وجود دارد
      if(ObjectFind(chart_id, CRISIS_OBJ) >= 0)
         HM_DeleteObjectHard(chart_id, CRISIS_OBJ);
   }
}

// ════════════════════════════════════════════════════════════════════
void TL_SetLight(string id, int state, string txt, string tooltip)
{
   color  txC;
   string dispTxt;
   string fname = TL_FriendlyName(id);

   if(state == -1)
   {
      txC     = clrDimGray;
      // 🐛 v13.29 FIX1: اگه txt پاس داده شده از اون استفاده کن
      dispTxt = (StringLen(txt) > 0) ? txt : "● " + fname + ": --";
   }
   else if(state == 2)
   {
      txC     = clrRed;
      // 🐛 v13.29 FIX1: اگه txt پاس داده شده از اون استفاده کن
      dispTxt = (StringLen(txt) > 0) ? txt : "● " + fname + ": Warning";
   }
   else   // 0 or 1 — green / yellow
   {
      txC     = (state == 0) ? clrLime : clrGold;
      // 🐛 v13.29 FIX1: اگه txt پاس داده شده از اون استفاده کن (قبلاً همیشه "Safe" بود)
      dispTxt = (StringLen(txt) > 0) ? txt : "● " + fname + ": Safe";
   }

   string nm = dashboardPrefix + "TL_" + id;
   if(ObjectFind(0, nm) >= 0)
   {
      ObjectSetString (0, nm, OBJPROP_TEXT,    dispTxt);
      ObjectSetInteger(0, nm, OBJPROP_COLOR,   txC);
      ObjectSetString (0, nm, OBJPROP_TOOLTIP, SafeTip(tooltip));
   }
}

string TL_FriendlyName(string id)
{
   if(id == "RTM")      return "Reversion";
   if(id == "TREND")    return "Trend Strength";
   if(id == "STRUCT")   return "Daily Struct";
   if(id == "FLOW")     return "Currency Flow";
   if(id == "ZOMBIE")   return "Price Zone";
   if(id == "HIGHALT")  return "Hi Alert";
   if(id == "CRISIS")   return "Crisis";
   if(id == "KILLER")   return "Killer";
   if(id == "MKTPHASE") return "Mkt Phase";   // 🆕 v13.13
   if(id == "SPIKE")    return "Spike";       // 🆕 v13.14
   return id;
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.14: Calc_MktPhase — فاز بازار بلندمدت
//
// ویژگی‌ها:
//   - مستقل از جهت (Buy/Sell/All) و تایم‌فریم (همیشه D1)
//   - یک‌بار در روز محاسبه — بار CPU صفر
//   - کش در GlobalVariable — عوض شدن TF یا ری‌استارت EA باعث
//     محاسبه مجدد نمیشه؛ همون روز از حافظه خونده میشه (فوری)
//   - هشدار تلگرام فقط وقتی فاز تغییر کنه
//
// منطق: MA10 از ratio روزانه
//   ratio_daily = ADR(1روز) / ADR_baseline(60روز)
//   MA10 = میانگین متحرک ۱۰ روز از ratio_daily   (v13.13: از MA30 کاهش یافت — lag کمتر)
//
//   MA10 < 0.85  → Range   (سبز)  — بازار رنج، سیستم عالی
//   0.85–1.30    → Neutral (زرد)  — فاز گذار
//   MA10 > 1.30  → Trend   (قرمز) — روند انفجاری، خطر
//
// کالیبراسیون از HelpMe CSV واقعی (GBPNZD 2024-2026):
//   2024 مارس-جولای: MA10 ~0.78-0.81 → Range   ✅ سود خوب
//   2025 ژانویه-مارس: MA10 ~0.90-1.05 → Neutral ⚠️ کال‌ها (دلیل واقعی: بالانس کم)
//   2025 آوریل:       MA10 ~1.73      → Trend   ✅ فاجعه واقعی تشخیص داده شد
//   2026 کل:          MA10 ~0.81-1.17 → Range/Neutral ✅ سود خوب
// ════════════════════════════════════════════════════════════════════
void Calc_MktPhase()
{
   // throttle روزانه برای محاسبه عادی
   static datetime s_lastCalcDay = 0;
   // PERF FIX v13.13: retry در firstRun هر ۳۰ثانیه — نه هر ثانیه
   static datetime s_lastRetry   = 0;

   datetime todayD1 = iTime(_Symbol, PERIOD_D1, 0);
   if(todayD1 == 0) todayD1 = (datetime)((long)TimeCurrent() / 86400 * 86400);

   bool firstRun = (g_lightMktPhase == -1);

   // PERF FIX v13.14: اگه firstRun است، اول از GlobalVariable بخون (فوری)
   // این باعث میشه عوض شدن تایم‌فریم یا ری‌استارت EA بدون محاسبه مجدد کار کنه
   // چون MktPhase کاملاً مستقل از تایم‌فریم و پوزیشن است (همیشه D1)
   if(firstRun)
   {
      string gvKey    = "HelpMe_MktPhase_"    + _Symbol;
      string gvDayKey = "HelpMe_MktPhaseDay_" + _Symbol;
      double cachedDay = GlobalVariableCheck(gvDayKey) ? GlobalVariableGet(gvDayKey) : 0;
      double cachedVal = GlobalVariableCheck(gvKey)    ? GlobalVariableGet(gvKey)    : 0;

      if(cachedDay > 0 && cachedVal > 0 && (datetime)cachedDay == todayD1)
      {
         g_mktPhaseRatio = cachedVal;
         int ph = (cachedVal < 0.85) ? 0 : (cachedVal <= 1.30 ? 1 : 2);
         string lbl = (ph==0) ? "Range" : (ph==1) ? "Neutral" : "Trend!";
         g_lightMktPhase = ph;
         g_mktPhasePrev  = ph;
         s_lastCalcDay   = todayD1;

         MqlDateTime lc2;
         TimeToStruct(g_mktPhaseLastChange > 0 ? g_mktPhaseLastChange : TimeCurrent(), lc2);
         string lcStr2 = StringFormat("%04d.%02d.%02d", lc2.year, lc2.mon, lc2.day);

         string distLine2;
         if(ph == 0)
            distLine2 = StringFormat("تا Neutral: %.3f مانده (مرز: 0.85)", 0.85 - cachedVal);
         else if(ph == 1)
            distLine2 = StringFormat("تا Range: %.3f | تا Trend: %.3f", cachedVal - 0.85, 1.30 - cachedVal);
         else
            distLine2 = StringFormat("%.3f بالاتر از مرز Trend (1.30)", cachedVal - 1.30);

         string tip2 = StringFormat(
            "Mkt Phase | D1 | %s\n"
            "MA10 = %.3f\n"
            "%s\n"
            "─────────────────────\n"
            "< 0.85  🟢 Range  : رنج — سیستم عالی\n"
            "0.85-1.30 🟡 Neutral: گذار — احتیاط\n"
            "> 1.30  🔴 Trend  : روند — خطر\n"
            "─────────────────────\n"
            "آخرین تغییر: %s",
            _Symbol, cachedVal, distLine2, lcStr2);

         // 🐛 v13.29 FIX2: اگه object داشبورد هنوز ساخته نشده (OnInit در حال اجرا)
         // TL_SetLight الان fail می‌کند. flag را ست کن تا در اولین OnTick دوباره امتحان بشه.
         string nm = dashboardPrefix + "TL_MKTPHASE";
         if(ObjectFind(0, nm) >= 0)
         {
            TL_SetLight("MKTPHASE", ph, "● Mkt Phase: " + lbl, tip2);
            g_mktPhaseNeedRedraw = false;
         }
         else
         {
            // object هنوز وجود نداره — flag برای retry در OnTick/TL_Update
            g_mktPhaseNeedRedraw = true;
         }
         return;
      }
   }

   if(!firstRun && todayD1 == s_lastCalcDay) return;

   // PERF FIX: اگه firstRun است، retry را به ۳۰ ثانیه محدود کن
   if(firstRun)
   {
      datetime now = TimeCurrent();
      if(s_lastRetry > 0 && (now - s_lastRetry) < 30) return;
      s_lastRetry = now;
   }

   // نیاز: 60 روز baseline + 10 روز MA window
   const int BASELINE = 60;
   const int MA_WIN   = 10;   // FIX v13.13: از 30 به 10 — lag کاهش یافت
   const int NEED     = BASELINE + MA_WIN + 2;

   double arrH[], arrL[];
   ArraySetAsSeries(arrH, true);
   ArraySetAsSeries(arrL, true);

   int chH = CopyHigh(_Symbol, PERIOD_D1, 1, NEED, arrH);
   int chL = CopyLow (_Symbol, PERIOD_D1, 1, NEED, arrL);

   if(chH < NEED || chL < NEED)
   {
      if(firstRun)
         TL_SetLight("MKTPHASE", -1, "● Mkt Phase: --",
            "داده D1 کافی نیست (90 روز لازم)");
      return;
   }

   // baseline ADR: میانگین روزهای MA_WIN+1 تا MA_WIN+BASELINE (قدیمی‌تر)
   double baseline = 0.0;
   for(int i = MA_WIN; i < MA_WIN + BASELINE; i++)
      baseline += (arrH[i] - arrL[i]);
   baseline /= BASELINE;
   if(baseline <= 0.0) return;

   // MA10 v13.13: میانگین ratio روزانه در ۱۰ روز اخیر
   double ma10 = 0.0;
   for(int i = 0; i < MA_WIN; i++)
   {
      double dayRange = arrH[i] - arrL[i];
      ma10 += dayRange / baseline;
   }
   ma10 /= MA_WIN;

   g_mktPhaseRatio = ma10;
   s_lastCalcDay   = todayD1;
   s_lastRetry     = 0;   // reset retry بعد از موفقیت

   // PERF FIX v13.14: ذخیره در GlobalVariable برای بازیابی سریع
   // بعد از تغییر تایم‌فریم یا ری‌استارت EA — همون روز دوباره محاسبه نمیشه
   GlobalVariableSet("HelpMe_MktPhase_"    + _Symbol, ma10);
   GlobalVariableSet("HelpMe_MktPhaseDay_" + _Symbol, (double)todayD1);

   // تعیین فاز
   int    newPhase;
   string phaseLabel;
   // v13.13: آستانه‌های جدید
   if(ma10 < 0.85)
      { newPhase = 0; phaseLabel = "Range";   }
   else if(ma10 <= 1.30)
      { newPhase = 1; phaseLabel = "Neutral"; }
   else
      { newPhase = 2; phaseLabel = "Trend!";  }

   // ردیابی تغییر فاز
   bool phaseChanged = (newPhase != g_mktPhasePrev && g_mktPhasePrev != -1);
   if(phaseChanged || g_mktPhaseLastChange == 0)
      g_mktPhaseLastChange = TimeCurrent();

   // هشدار تلگرام — فقط وقتی فاز تغییر کنه و زرد یا قرمز باشه
   if(Alert_OnMktPhase && phaseChanged && newPhase >= 1)
   {
      bool isEdge = (g_prevAlertMKTPHASE != newPhase);
      if(Alert_CooldownOK(g_lastAlertTime_MKTPHASE, isEdge))
      {
         string aPrev  = (g_mktPhasePrev == 0) ? "Range" :
                         (g_mktPhasePrev == 1) ? "Neutral" : "Trend";
         string aMsg;
         if(newPhase == 2)
            aMsg = StringFormat("🌍 Market Trend شد | %s\n"
                                 "━━━━━━━━━━━━━━━━\n"
                                 "MA10: %.3f | فاز قبلی: %s\n"
                                 "━━━━━━━━━━━━━━━━\n"
                                 "بازار از رنج خارج شده\n"
                                 "Xmoon توی خطره — Rule رو چک کن",
                                 _Symbol, ma10, aPrev);
         else
            aMsg = StringFormat(
               "🌍 Market Neutral شد | %s\n"
               "━━━━━━━━━━━━━━━━\n"
               "MA10: %.3f | فاز قبلی: %s\n"
               "━━━━━━━━━━━━━━━━\n"
               "بازار داره از رنج خارج میشه\n"
               "مراقب باش",
               _Symbol, ma10, aPrev);
         Alert_Send(aMsg);
         g_lastAlertTime_MKTPHASE = TimeCurrent();
      }
      g_prevAlertMKTPHASE = newPhase;
   }
   else if(newPhase == 0)
      g_prevAlertMKTPHASE = 0;

   g_mktPhasePrev  = newPhase;
   g_lightMktPhase = newPhase;

   // tooltip — v13.14: عدد دقیق MA10 + فاصله تا هر مرز
   MqlDateTime lc;
   TimeToStruct(g_mktPhaseLastChange, lc);
   string lcStr = StringFormat("%04d.%02d.%02d", lc.year, lc.mon, lc.day);

   string distLine;
   if(newPhase == 0)
      distLine = StringFormat("تا Neutral: %.3f مانده (مرز: 0.85)", 0.85 - ma10);
   else if(newPhase == 1)
      distLine = StringFormat("تا Range: %.3f | تا Trend: %.3f", ma10 - 0.85, 1.30 - ma10);
   else
      distLine = StringFormat("%.3f بالاتر از مرز Trend (1.30)", ma10 - 1.30);

   string tip = StringFormat(
      "Mkt Phase | D1 | %s\n"
      "MA10 = %.3f\n"
      "%s\n"
      "━━━━━━━━━━\n"
      "< 0.85  🟢 رنج   : سیستم Xmoon عالیه\n"
      "0.85-1.30 🟡 خنثی  : احتیاط\n"
      "> 1.30  🔴 ترند  : خطر — Xmoon در ریسکه\n"
      "━━━━━━━━━━\n"
      "آخرین تغییر: %s",
      _Symbol, ma10, distLine, lcStr);

   TL_SetLight("MKTPHASE", newPhase, "● Mkt Phase: " + phaseLabel, tip);
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.14: Calc_SpikeDetector — تشخیص حرکت ناگهانی چندتایم‌فریمه
//
// هدف: گرفتن اسپایک‌های سریع (مثل GBPNZD ۳ ژوئن که در ۶-۸ ساعت
// VS=6 رفت) که Step Decay (وابسته به پله Xmoon) نمی‌تواند ببیند
// چون این چراغ کاملاً مستقل از پوزیشن/پله است — فقط قیمت خام.
//
// منطق هر تایم‌فریم:
//   tf_score = Range(کندل جاری) / ATR(14) همان TF
//   اگه کندل جاری خیلی بزرگ‌تر از حد عادی باشه، score بالا میره
//
//   علاوه بر آن، Body Ratio هم اضافه می‌شود:
//   body_ratio = |Close-Open| کندل جاری / |Close-Open| کندل قبلی
//   (تشخیص engulfing / پیوستگی جهت‌دار حرکت)
//
// ترکیب نهایی: tf_score و body_ratio با هم میانگین وزن‌دار می‌شوند
// سپس ۵ تایم‌فریم با وزن‌های متفاوت جمع می‌شوند:
//
//   M15: 15%  — سریع‌ترین واکنش، نویزی‌ترین
//   M30: 15%  — تایید کوتاه‌مدت
//   H1 : 30%  — وزن اصلی؛ بهترین signal/noise برای اسپایک ساعتی
//   H4 : 25%  — روند کوتاه‌مدت، تاییدکننده
//   D1 : 15%  — فاز کلی (همان جهت MktPhase اما با وزن کمتر اینجا)
//
//   spike_score < 1.00      → 🟢 Normal
//   1.00 – 1.50              → 🟡 Warning
//   spike_score > 1.50      → 🔴 Spike
//
// throttle: هر ۱۵ دقیقه یک‌بار محاسبه (نه هر تیک) — بار CPU پایین
// و چون M15 سریع‌ترین TF استفاده‌شده‌ست، کافی است.
// ════════════════════════════════════════════════════════════════════

// محاسبه امتیاز یک تایم‌فریم: Range نسبت به ATR + Body Ratio
// 🆕 v14.03: پارامتر shift اضافه شد — پیش‌فرض 1 = کندل بسته‌شده قبلی
// shift=0 → کندل در حال شکل‌گیری (تیک-محور، برای لایو دیگر استفاده نمی‌شود)
// shift=1 → آخرین کندل کاملاً بسته (هم‌خوان با بکتست)
double Spike_TFScore(ENUM_TIMEFRAMES tf, int atrPeriod = 14, int shift = 1)
{
   double high[], low[], openP[], closeP[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low,  true);
   ArraySetAsSeries(openP,  true);
   ArraySetAsSeries(closeP, true);

   // 🆕 v14.03: CopyXxx از shift شروع می‌کند (نه از 0)
   // need+shift تضمین می‌کند که atrPeriod کندل بسته کافی داریم
   int need = atrPeriod + 3;
   if(CopyHigh (_Symbol, tf, shift, need, high)   < need) return 0.0;
   if(CopyLow  (_Symbol, tf, shift, need, low)    < need) return 0.0;
   if(CopyOpen (_Symbol, tf, shift, need, openP)  < need) return 0.0;
   if(CopyClose(_Symbol, tf, shift, need, closeP) < need) return 0.0;

   // ATR ساده روی (atrPeriod) کندل — index 0 حالا = آخرین کندل بسته (shift=1)
   double atrSum = 0.0;
   for(int i = 1; i <= atrPeriod; i++)
      atrSum += (high[i] - low[i]);
   double atr = atrSum / atrPeriod;
   if(atr <= 0.0) return 0.0;

   // Range آخرین کندل بسته (index 0 = shift=1)
   double curRange = high[0] - low[0];
   double rangeScore = curRange / atr;

   // Body Ratio: بدنه آخرین کندل بسته نسبت به کندل قبل از آن
   // 🆕 v13.15 FIX: اگه کندل قبلی دوجی (body نزدیک صفر) باشه،
   // تقسیم باعث false positive غول‌پیکر می‌شه (مثلاً 0.0001/0.00001=10)
   // راه‌حل: کف ایمن = حداقل 10% از ATR همون TF
   double curBody  = MathAbs(closeP[0] - openP[0]);
   double prevBody = MathAbs(closeP[1] - openP[1]);
   double prevBodySafe = MathMax(prevBody, atr * 0.10);
   double bodyScore = curBody / prevBodySafe;
   // سقف منطقی برای جلوگیری از نویز افراطی روی کندل‌های خیلی کوچک قبلی
   if(bodyScore > 4.0) bodyScore = 4.0;

   // ترکیب: 60% رنج نسبت به ATR + 40% نسبت بدنه به کندل قبل
   double score = (rangeScore * 0.6) + (bodyScore * 0.4);
   return score;
}

void Calc_SpikeDetector()
{
   // 🆕 v14.03: throttle زمانی حذف شد.
   // این تابع فقط از داخل بلوک runRuleBlock در TL_Update صدا زده می‌شود
   // که خودش فقط در بستن کندل چارت فعال است.
   // بنابراین throttle اضافی غیرضروری است و حذف شد.
   // داده‌ها از shift=1 (آخرین کندل بسته) خوانده می‌شوند — هم‌خوان با بکتست.
   bool firstRun = (g_lightSpike == -1);

   double sM15 = Spike_TFScore(PERIOD_M15, 14, 1);
   double sM30 = Spike_TFScore(PERIOD_M30, 14, 1);
   double sH1  = Spike_TFScore(PERIOD_H1,  14, 1);
   double sH4  = Spike_TFScore(PERIOD_H4,  14, 1);
   double sD1  = Spike_TFScore(PERIOD_D1,  14, 1);

   // اگه هیچ‌کدام داده نداشتن (نماد تازه باز شده) خاکستری بمون
   if(sM15==0.0 && sM30==0.0 && sH1==0.0 && sH4==0.0 && sD1==0.0)
   {
      if(firstRun) TL_SetLight("SPIKE", -1, "● Spike: --", "داده کافی نیست");
      return;
   }

   g_spikeTF[0] = sM15;
   g_spikeTF[1] = sM30;
   g_spikeTF[2] = sH1;
   g_spikeTF[3] = sH4;
   g_spikeTF[4] = sD1;

   // وزن‌دهی — پایه از اسپایک‌های واقعی AUDCAD، اصلاح‌شده برای GBPNZD
   // 🆕 v13.15: GBPNZD سریع‌تر حرکت می‌کنه → وزن M15/M30 بیشتر، H4 کمتر
   double wM15, wM30, wH1, wH4, wD1;
   if(StringFind(_Symbol, "GBPNZD") >= 0)
   {
      wM15 = 0.25; wM30 = 0.20; wH1 = 0.30; wH4 = 0.15; wD1 = 0.10;
   }
   else
   {
      wM15 = 0.15; wM30 = 0.15; wH1 = 0.30; wH4 = 0.25; wD1 = 0.15;
   }
   double score = sM15*wM15 + sM30*wM30 + sH1*wH1 + sH4*wH4 + sD1*wD1;
   g_spikeScore = score;

   // ── خام: فقط بر اساس Range/Body — این چیزیه که قبلاً مستقیماً نمایش داده می‌شد
   int    rawPhase;
   string rawLabel;
   if(score < 1.00)
      { rawPhase = 0; rawLabel = "Normal";  }
   else if(score <= 1.50)
      { rawPhase = 1; rawLabel = "Warning"; }
   else
      { rawPhase = 2; rawLabel = "SPIKE!";  }

   // ════════════════════════════════════════════════════════════════
   // 🆕 v13.17: قانون ترکیبی Spike+FLOW — بکتست V13.16 نشون داد Spike
   // به‌تنهایی غیرقابل‌اعتماده (در DANGER کمتر از SAFE فعال می‌شد — نوسان
   // کلی بازار رو می‌سنجه نه حرکت علیه پوزیشن). از این به بعد، هشدار
   // واقعی فقط وقتی نمایش داده می‌شه که FLOW هم هم‌زمان قرمز باشه
   // (یعنی جریان پول واقعاً علیه پوزیشن سونامی شده، نه فقط نوسان عمومی).
   // 🆕 v13.18: یه مسیر دوم اضافه شد — اگه Score خیلی بالا باشه (>=2.0)
   // حتی با FLOW زرد (نه قرمز کامل) هم به‌عنوان Warning (نه Spike) نشون
   // داده می‌شه، چون شدت حرکت به‌تنهایی نشونه‌ی شروع یه چیز جدیه.
   // امتیاز خام (g_spikeScore) همیشه برای لاگ/بکتست محفوظ می‌مونه.
   // ════════════════════════════════════════════════════════════════
   bool flowConfirms   = (g_lightFLOW == 2);             // FLOW قرمز — تأیید کامل
   bool flowYellowHigh  = (g_lightFLOW == 1 && score >= 2.0); // 🆕 v13.18: FLOW زرد + Score بالا
   // 🆕 v13.50 FLOW-03: استقلال Spike از FLOW در شرایط low-confidence
   // 🔴 مشکل: چراغ Spike فقط با rawPhase≥1 AND FLOW==Red تأیید می‌شد. اگه FLOW
   //   فریز/غیرقابل‌اعتماد بود (g_flowLowConfidence یا g_lightFLOW==-1)، Spike
   //   واقعی نادیده گرفته می‌شد — نمونه: FLOW فریز، Spike=1.928 نادیده گرفته شد.
   // ✅ راه‌حل: در این حالت، Spike با آستانه‌ی بالاتر (مستقل از FLOW) تأیید می‌شود.
   bool flowIsUnavailable = (g_lightFLOW == -1);
   bool flowUntrusted     = (g_flowLowConfidence || flowIsUnavailable);
   int    dispPhase;
   string dispLabel;
   if(rawPhase >= 1 && flowConfirms)
   {
      dispPhase = rawPhase;                 // Warning یا Spike — تأییدشده با FLOW قرمز
      dispLabel = rawLabel + " ✓Flow";
   }
   else if(flowYellowHigh)
   {
      dispPhase = 1;                        // 🆕 v13.18: Warning — Score بالا + FLOW زرد
      dispLabel = "Warning (Score≥2 +Flow زرد)";
   }
   else if(flowUntrusted && score >= 2.5)
   {
      dispPhase = 2;                        // 🆕 v13.50 FLOW-03: Spike (LC) — مستقل از FLOW
      dispLabel = "Spike (LC) — FLOW غیرقابل‌اعتماد";
   }
   else if(flowUntrusted && score >= 1.5)
   {
      dispPhase = 1;                        // 🆕 v13.50 FLOW-03: Warning (LC)
      dispLabel = "Warning (LC) — FLOW غیرقابل‌اعتماد";
   }
   else if(rawPhase >= 1 && !flowConfirms)
   {
      dispPhase = 0;                        // فقط نوسان عمومی — هشدار واقعی نیست
      dispLabel = "Normal (Vol↑)";
   }
   else
   {
      dispPhase = 0;
      dispLabel = "Normal";
   }

   bool changed = (dispPhase != g_prevAlertSPIKE && g_prevAlertSPIKE != -1);

   // هشدار تلگرام فقط وقتی Spike واقعی + FLOW قرمز با هم تأیید بشن
   if(Alert_OnSpike && dispPhase == 2)
   {
      bool isEdge = (g_prevAlertSPIKE != 2);
      if(Alert_CooldownOK(g_lastAlertTime_SPIKE, isEdge))
      {
         string aMsg = StringFormat(
            "⚡ Spike تأیید شد | %s\n"
            "━━━━━━━━━━━━━━━━\n"
            "Score: %.2f\n"
            "M15=%.2f  M30=%.2f  H1=%.2f  H4=%.2f  D1=%.2f\n"
            "━━━━━━━━━━━━━━━━\n"
            "حرکت انفجاری + Flow قرمز\n"
            "ورود جدید ممنوع — معامله باز رو زیر نظر بگیر",
            _Symbol, score, sM15, sM30, sH1, sH4, sD1);
         Alert_Send(aMsg);
         g_lastAlertTime_SPIKE = TimeCurrent();
      }
   }
   g_prevAlertSPIKE = dispPhase;
   g_lightSpike = dispPhase;

   // ════════════════════════════════════════════════════════════════
   // 🆕 v13.19: اعلان مستقل Spike+FLOW قرمز همزمان — اینپوت جداگانه
   // (Alert_OnSpikeFlowRed) از Alert_OnSpike، با فرمت پیام اختصاصی.
   // شرط: Spike واقعی (rawPhase==2, score>1.5) + FLOW قرمز هم‌زمان
   // ════════════════════════════════════════════════════════════════
   if(Alert_OnSpikeFlowRed)
   {
      bool comboNow = (rawPhase == 2 && g_lightFLOW == 2);
      bool isEdgeSF = comboNow && !g_prevAlertSpikeFlowRed;
      if(comboNow && Alert_CooldownOK(g_lastAlertTime_SpikeFlowRed, isEdgeSF))
      {
         string sfMsg = StringFormat(
            "⚡🌊 Spike + Flow قرمز | %s\n"
            "━━━━━━━━━━━━━━━━\n"
            "Score: %.2f | Flow: %.1f\n"
            "━━━━━━━━━━━━━━━━\n"
            "حرکت سریع + سونامی پول\n"
            "معامله خلاف جهت رو ببند",
            _Symbol, score, g_lastFlowScore);
         Alert_Send(sfMsg);
      }
      g_prevAlertSpikeFlowRed = comboNow;
   }

   string tip = StringFormat(
      "Spike | %s\n"
      "Score: %.2f (%s)\n"
      "━━━━━━━━━━\n"
      "M15=%.2f  M30=%.2f  H1=%.2f\n"
      "H4=%.2f  D1=%.2f\n"
      "━━━━━━━━━━\n"
      "Flow قرمز (تأیید کامل): %s\n"
      "وضعیت نمایش‌داده‌شده: %s\n"
      "━━━━━━━━━━\n"
      "< 1.00  🟢 عادی\n"
      "1.00-1.50 🟡 هشدار\n"
      "> 1.50  🔴 اسپایک\n"
      "هشدار واقعی فقط وقتی Flow هم قرمز باشه",
      _Symbol, score, rawLabel, sM15, sM30, sH1, sH4, sD1,
      flowConfirms ? "بله 🔴" : "خیر",
      dispLabel);

   TL_SetLight("SPIKE", dispPhase, "● Spike: " + dispLabel, tip);
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.21: Alert_CheckGBPNZDRule — قانون ترید ۳سطحی GBPNZD
//
// سطح ۰ (GREEN):  ورود عادی — EA ران
// سطح ۱ (STOP):   ورود جدید متوقف — معاملات باز دست نزن
// سطح ۲ (CLOSE):  همه معاملات GBPNZD ببند — EA رو Pause کن
//
// STOP  trigger A: Spike=🔴 AND CRISIS≠سبز (Yellow/Orange/Red)
// STOP  trigger B: Spike=⚡ Warning AND CRISIS=🟠/🔴
// ════════════════════════════════════════════════════════════════════
// 🆕 v13.25: GBPNZD_Replay_CrisisAtBar
//
// Crisis state را برای یک کندل H1 تاریخی محاسبه می‌کنه.
// shift: چند کندل H1 عقب (1=آخرین بسته‌شده، 2=قبل از آن، ...)
// forBuy: جهت پوزیشن
//
// همان منطق UpdateCrisisLight — بدون side-effect روی داشبورد/g_crisisState
// برگشتی: 0=Green | 1=Yellow | 2=Red | 3=Orange
//
// داده‌های لازم (همه از handle های موجود):
//   RTM  : handleEMA200_H1_TL (H1) + handleATR_H1_TL (H1)
//   ADX  : handleADX_H4_TL (H4) → shift H4 = shift/4 (تقریب)
//   STRUCT: iHigh/iLow D1 — نسبتاً ثابت در 24h گذشته، shift تأثیر کمی داره
//   FLOW : iClose H4 sister pairs با offset
// ════════════════════════════════════════════════════════════════════
int GBPNZD_Replay_CrisisAtBar(int h1Shift, bool forBuy, int &rcOut)
{
   // ── RTM ───────────────────────────────────────────────────────
   int newRTM = 1;  // پیش‌فرض زرد
   if(handleEMA200_H1_TL != INVALID_HANDLE && handleATR_H1_TL != INVALID_HANDLE
      && BarsCalculated(handleEMA200_H1_TL) > 210 + h1Shift
      && BarsCalculated(handleATR_H1_TL)    > 20  + h1Shift)
   {
      double ema[], atr[];
      ArraySetAsSeries(ema, true);
      ArraySetAsSeries(atr, true);
      // shift+1 چون index 0 = کندل در حال شکل‌گیری — همیشه از بسته‌شده می‌خونیم
      bool ok = (CopyBuffer(handleEMA200_H1_TL, 0, h1Shift + 1, 3, ema) == 3) &&
                (CopyBuffer(handleATR_H1_TL,    0, h1Shift + 1, 2, atr) == 2) &&
                (atr[0] > 0);
      if(ok)
      {
         double h1c0     = iClose(_Symbol, PERIOD_H1, h1Shift + 1);
         double h1c1     = iClose(_Symbol, PERIOD_H1, h1Shift + 2);
         double d0       = MathAbs(h1c0 - ema[0]) / atr[0];
         double d1       = MathAbs(h1c1 - ema[1]) / atr[1];
         double dDel     = d0 - d1;
         bool   rightSide= forBuy ? (h1c0 < ema[0]) : (h1c0 > ema[0]);
         bool   withTrend= !rightSide;
         bool   returning   = (dDel < -0.3);
         bool   runningAway = (dDel > 0.15);

         if(withTrend)
         {
            if(d0 >= 2.0 && dDel > 0.15) newRTM = 0;
            else if(d0 < 0.8 || dDel < -0.35) newRTM = 2;
            else newRTM = 1;
         }
         else
         {
            if(d0 >= 3.5 && returning)        newRTM = 0;
            else if(d0 >= 2.5 && runningAway) newRTM = 2;
            else                               newRTM = 1;
         }
      }
   }

   // ── ADX/TREND (H4) ─────────────────────────────────────────
   // تبدیل shift H1 به H4: هر 4 کندل H1 = 1 کندل H4
   int h4Shift = h1Shift / 4;
   int newTrend = 1;
   double adxVal = 0.0;
   double erH4   = 0.0;
   if(handleADX_H4_TL != INVALID_HANDLE
      && BarsCalculated(handleADX_H4_TL) > 20 + h4Shift)
   {
      double adxB[], pdiB[], mdiB[];
      ArraySetAsSeries(adxB, true);
      ArraySetAsSeries(pdiB, true);
      ArraySetAsSeries(mdiB, true);
      bool ok = (CopyBuffer(handleADX_H4_TL, 0, h4Shift + 1, 2, adxB) == 2) &&
                (CopyBuffer(handleADX_H4_TL, 1, h4Shift + 1, 2, pdiB) == 2) &&
                (CopyBuffer(handleADX_H4_TL, 2, h4Shift + 1, 2, mdiB) == 2);
      if(ok)
      {
         double adx   = adxB[0];
         adxVal       = adx;
         double pDI   = pdiB[0], mDI = mdiB[0];
         bool rising  = (adx > adxB[1] + 0.4);

         int erBars   = MathMin(14, Bars(_Symbol, PERIOD_H4) - (h4Shift + 3));
         if(erBars >= 5)
         {
            double netMove = MathAbs(iClose(_Symbol, PERIOD_H4, h4Shift + 1) -
                                     iClose(_Symbol, PERIOD_H4, h4Shift + erBars + 1));
            double sumPath = 0;
            for(int k = 1; k <= erBars; k++)
               sumPath += MathAbs(iClose(_Symbol, PERIOD_H4, h4Shift + k) -
                                  iClose(_Symbol, PERIOD_H4, h4Shift + k + 1));
            erH4 = (sumPath > 0) ? netMove / sumPath : 0;
         }

         bool oppTrend = forBuy ? (mDI > pDI + 5.0) : (pDI > mDI + 5.0);
         if(!oppTrend)
         {
            newTrend = (adx > 20.0 && erH4 > 0.25) ? 0 : 1;
         }
         else
         {
            bool adxWeak = (adx < 20.0), erWeak = (erH4 < 0.20);
            bool adxStr  = (adx >= 32.0 && rising), erStr = (erH4 >= 0.35);
            if(adxWeak || erWeak)          newTrend = 0;
            else if(adxStr && erStr)        newTrend = 2;
            else                            newTrend = 1;
         }
      }
   }

   // ── STRUCT (D1) ─────────────────────────────────────────────
   // D1 در بازه 24h تغییر چندانی نمی‌کنه — از قیمت تاریخی H1 + D1 ثابت استفاده
   int newStruct = 1;
   {
      double atrD1 = 0;
      if(handleATR_D1_TL != INVALID_HANDLE && BarsCalculated(handleATR_D1_TL) > 5)
      {
         double aB[]; ArraySetAsSeries(aB, true);
         if(CopyBuffer(handleATR_D1_TL, 0, 1, 1, aB) == 1 && aB[0] > 0)
            atrD1 = aB[0];
      }
      if(atrD1 <= 0)
         atrD1 = iClose(_Symbol, PERIOD_D1, 1) * 0.006;

      double curPrice = iClose(_Symbol, PERIOD_H1, h1Shift + 1);
      int    lookD1   = MathMin(10, Bars(_Symbol, PERIOD_D1) - 2);
      if(lookD1 >= 5)
      {
         if(forBuy)
         {
            double swLow = iLow(_Symbol, PERIOD_D1, 1);
            for(int k = 2; k <= lookD1; k++)
               swLow = MathMin(swLow, iLow(_Symbol, PERIOD_D1, k));
            double dist = curPrice - swLow;
            if(curPrice < swLow)         newStruct = 2;
            else if(dist < atrD1 * 2.0)  newStruct = 1;
            else                          newStruct = 0;
         }
         else
         {
            double swHigh = iHigh(_Symbol, PERIOD_D1, 1);
            for(int k = 2; k <= lookD1; k++)
               swHigh = MathMax(swHigh, iHigh(_Symbol, PERIOD_D1, k));
            double dist = swHigh - curPrice;
            if(curPrice > swHigh)         newStruct = 2;
            else if(dist < atrD1 * 2.0)   newStruct = 1;
            else                           newStruct = 0;
         }
      }
   }

   // ── FLOW ────────────────────────────────────────────────────
   // FlowEvaluate با iClose H4 + offset
   int newFLOW = 1;
   double flowScore = 0.0;
   {
      // بازسازی FlowEvaluate با shift روی iClose H4
      // h4Shift = offset H4 معادل h1Shift
      // 🐛 v14.00 FIX: قبلاً این بلوک فقط برای baseSym=="GBPNZD" اجرا می‌شد —
      // روی AUDCAD/EURGBP، flowScore همیشه 0.0 و newFLOW همیشه خنثی (1)
      // می‌ماند، یعنی Replay/بکتست روی این دو سمبل هرگز rc واقعی نمی‌ساخت.
      // حالا با Sister_GetTable(_Symbol,...) جدول درست هر سه سمبل استفاده می‌شود.
      {
         SisterEntry sArr[];
         int sN = Sister_GetTable(_Symbol, sArr);
         double fs = 0.0;
         for(int si = 0; si < sN; si++)
         {
            string sym = FlowFindSym(sArr[si].sym);
            if(Bars(sym, PERIOD_H4) < 8 + h4Shift) continue;

            // H4 Momentum: close[h4Shift+1] vs close[h4Shift+6]
            double c1 = iClose(sym, PERIOD_H4, h4Shift + 1);
            double c6 = iClose(sym, PERIOD_H4, h4Shift + 6);
            if(c1 <= 0.0 || c6 <= 0.0) continue;

            double dir = (c1 > c6) ? 1.0 : (c1 < c6) ? -1.0 : 0.0;
            if(dir == 0.0) continue;

            int    effSign   = forBuy ? sArr[si].signForBuy : -sArr[si].signForBuy;
            double rawSignal = effSign * dir;
            double mult      = (rawSignal < 0.0) ? sArr[si].negMult : 1.0;
            fs += rawSignal * sArr[si].weight * mult;
         }
         flowScore = fs;
         if(fs > 2.0)        newFLOW = 0;
         else if(fs >= -4.0) newFLOW = 1;
         else                 newFLOW = 2;
      }
   }

   // ── RC و Crisis state ───────────────────────────────────────
   int rc = (newRTM==2?1:0) + (newTrend==2?1:0) + (newStruct==2?1:0) + (newFLOW==2?1:0);
   rcOut  = rc;  // 🆕 v13.35: rc رو برای wasClean در InitReplay export کن

   // همان منطق UpdateCrisisLight — بدون side-effect
   double th_RedA_ADX, th_RedA_Flow, th_RedB_ADX, th_RedB_Flow;
   double th_OrA_ADX,  th_OrA_Flow,  th_OrB_ADX,  th_OrB_Ts;
   double th_OrC_ADX,  th_OrC_Flow,  th_OrC_Ts;
   double th_OrD_ADX,  th_OrD_Ts;
   double th_Y2_ADX,   th_Y2_Flow, th_Y3_Flow, th_Y3_Ts;
   double th_Y4_ADX,   th_Y4_Ts,   th_Y5_ADX,  th_Y5_Flow;
   Crisis_GetThresholds(
      th_RedA_ADX, th_RedA_Flow, th_RedB_ADX, th_RedB_Flow,
      th_OrA_ADX,  th_OrA_Flow,  th_OrB_ADX,  th_OrB_Ts,
      th_OrC_ADX,  th_OrC_Flow,  th_OrC_Ts,
      th_OrD_ADX,  th_OrD_Ts,
      th_Y2_ADX,   th_Y2_Flow,   th_Y3_Flow,  th_Y3_Ts,
      th_Y4_ADX,   th_Y4_Ts,     th_Y5_ADX,   th_Y5_Flow);

   // trendScore: از g_csvScore استفاده می‌کنیم (در زمان Replay ممکنه 0 باشه)
   // اگه 0 بود trendScore را از erH4 × adxVal تخمین می‌زنیم — تأثیر فقط روی Orange/Yellow
   double trendScore  = (g_csvScore != 0.0) ? g_csvScore : (erH4 * adxVal * 0.5);
   double tsAgainst   = forBuy ? -trendScore : trendScore;
   // 🐛 v13.33 FIX — flowAgainst sign همیشه نگیشن flowScore
   //
   // قبلاً: flowAgainst = forBuy ? -flowScore : flowScore
   //   برای Sell: flowAgainst = flowScore = fsSell = مثلاً -9.62 (منفی!)
   //   شرط: flowAgainst >= 6.0 → -9.62 >= 6.0 = FALSE → Crisis هرگز Red نمی‌شد!
   //
   // اما LogHourlySnapshot (که CSV بکتست را ساخت) از شرط:
   //   isRedA = (flowScore <= -th_RedA_Flow) استفاده می‌کند
   //   معادل: -flowScore >= th_RedA_Flow → یعنی flowAgainst = -flowScore
   //
   // FlowEvaluate برای Sell وقتی بازار علیه Sell است:
   //   fsSell = -9.62 (منفی بزرگ = بد برای Sell)
   //   -fsSell = +9.62 → flowAgainst مثبت و بزرگ → Red ✓
   //
   // برای Buy وقتی بازار علیه Buy است:
   //   fsBuy = -9.62 (منفی) → -fsBuy = +9.62 → Red ✓ (قبلاً هم درست بود)
   //
   // نتیجه: با flowAgainst = -flowScore هر دو جهت درست کار می‌کنند
   // و Replay با بکتست CSV سینک می‌شود.
   double flowAgainst = -flowScore;

   if(rc < 0) return -1;

   if((rc >= 3 && flowAgainst >= th_RedA_Flow && adxVal > th_RedA_ADX) ||
      (rc >= 2 && flowAgainst >= th_RedB_Flow && adxVal > th_RedB_ADX))
      return 2;  // Red

   if((rc >= 2 && flowAgainst >= th_OrA_Flow && adxVal > th_OrA_ADX) ||
      (rc >= 3 && tsAgainst > th_OrB_Ts && adxVal > th_OrB_ADX) ||
      (rc >= 2 && flowAgainst >= th_OrC_Flow && adxVal > th_OrC_ADX && tsAgainst > th_OrC_Ts) ||
      (tsAgainst > th_OrD_Ts && adxVal > th_OrD_ADX))
      return 3;  // Orange

   if((rc >= 2) ||
      (flowAgainst >= th_Y2_Flow && adxVal > th_Y2_ADX) ||
      (rc >= 2 && flowAgainst >= th_Y3_Flow && tsAgainst > th_Y3_Ts) ||
      (rc >= 2 && tsAgainst > th_Y4_Ts && adxVal > th_Y4_ADX) ||
      (rc >= 2 && flowAgainst >= th_Y5_Flow && adxVal > th_Y5_ADX))
      return 1;  // Yellow

   return 0;  // Green
}

// 🆕 v13.35: wrapper بدون rcOut برای call‌های قدیمی که rc نمی‌خوان
int GBPNZD_Replay_CrisisAtBar(int h1Shift, bool forBuy)
{
   int _dummy = 0;
   return GBPNZD_Replay_CrisisAtBar(h1Shift, forBuy, _dummy);
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.25 / 🐛 v13.26 FIX4: GBPNZD_Replay_SpikeAtBar
//
// Spike dispPhase را برای shift تاریخی محاسبه می‌کنه — هر دو جهت
// spikeBuy و spikeSell جداگانه از طریق ref برگشت داده می‌شن.
// برگشتی int: raw score phase (0/1/2) یا -1 اگه داده نبود.
// ════════════════════════════════════════════════════════════════════
int GBPNZD_Replay_SpikeAtBar(int h1Shift, int &spikeBuyOut, int &spikeSellOut)
{
   spikeBuyOut  = -1;
   spikeSellOut = -1;

   // هر TF باید کافی داده داشته باشه
   // h1Shift روی M15: ×4، روی M30: ×2، روی H4: /4، روی D1: /24
   int m15Shift = h1Shift * 4;
   int m30Shift = h1Shift * 2;
   int h4Shift  = h1Shift / 4;
   int d1Shift  = h1Shift / 24;

   // Spike_TFScore با offset: باید از CopyHigh/Low/Open/Close با startPos استفاده کنیم
   // تابع کمکی inline:
   double sM15 = 0.0, sM30 = 0.0, sH1 = 0.0, sH4 = 0.0, sD1 = 0.0;

   // ── تابع داخلی: TFScore با shift ──────────────────────────────
   // این بلاک برای هر TF تکرار می‌شه
   {
      ENUM_TIMEFRAMES tfs[5]  = {PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
      int             shifts[5]= {m15Shift, m30Shift, h1Shift, h4Shift, d1Shift};
      double          results[5];
      int atrPeriod = 14;

      for(int t = 0; t < 5; t++)
      {
         ENUM_TIMEFRAMES tf = tfs[t];
         int             sh = shifts[t];
         int             need = atrPeriod + 3;

         // باید sh + need کندل داشته باشیم
         if(Bars(_Symbol, tf) < sh + need + 2) { results[t] = 0.0; continue; }

         double high[], low[], openP[], closeP[];
         ArraySetAsSeries(high,   true);
         ArraySetAsSeries(low,    true);
         ArraySetAsSeries(openP,  true);
         ArraySetAsSeries(closeP, true);

         // startPos = sh+1 تا کندل بسته‌شده در آن زمان رو داشته باشیم
         if(CopyHigh (_Symbol, tf, sh + 1, need, high)   < need) { results[t] = 0.0; continue; }
         if(CopyLow  (_Symbol, tf, sh + 1, need, low)    < need) { results[t] = 0.0; continue; }
         if(CopyOpen (_Symbol, tf, sh + 1, need, openP)  < need) { results[t] = 0.0; continue; }
         if(CopyClose(_Symbol, tf, sh + 1, need, closeP) < need) { results[t] = 0.0; continue; }

         double atrSum = 0.0;
         for(int i = 1; i <= atrPeriod; i++)
            atrSum += (high[i] - low[i]);
         double atr = atrSum / atrPeriod;
         if(atr <= 0.0) { results[t] = 0.0; continue; }

         double curRange  = high[0] - low[0];
         double rangeScore= curRange / atr;

         double curBody   = MathAbs(closeP[0] - openP[0]);
         double prevBody  = MathAbs(closeP[1] - openP[1]);
         double prevSafe  = MathMax(prevBody, atr * 0.10);
         double bodyScore = curBody / prevSafe;
         if(bodyScore > 4.0) bodyScore = 4.0;

         results[t] = (rangeScore * 0.6) + (bodyScore * 0.4);
      }
      sM15 = results[0];
      sM30 = results[1];
      sH1  = results[2];
      sH4  = results[3];
      sD1  = results[4];
   }

   // وزن‌دهی — 🐛 v14.00 FIX: قبلاً همیشه وزن GBPNZD هاردکد بود، حتی وقتی
   // چارت AUDCAD/EURGBP بود — یعنی Spike بازسازی‌شده در Replay با Spike
   // زنده (Calc_SpikeDetector که خودش وزن را بر حسب سمبل عوض می‌کند)
   // ناهمگون بود. حالا از همان تابع مشترک استفاده می‌شود.
   double wM15, wM30, wH1, wH4, wD1;
   Rule_SpikeWeightsForSymbol(_Symbol, wM15, wM30, wH1, wH4, wD1);
   double score = sM15*wM15 + sM30*wM30 + sH1*wH1 + sH4*wH4 + sD1*wD1;

   int rawPhase = (score < 1.00) ? 0 : (score <= 1.50) ? 1 : 2;

   // قانون ترکیبی Spike+FLOW: برای replay نیاز به Flow در همان لحظه داریم
   // Flow تاریخی رو inline محاسبه می‌کنیم — برای هر دو جهت جداگانه
   // 🐛 v14.00 FIX: جدول Sister هم بر حسب سمبل انتخاب می‌شود (نه همیشه GBPNZD)
   int h4ShiftFlow = h1Shift / 4;
   double fsBuy = 0.0, fsSell = 0.0;
   SisterEntry spArr[];
   int spN = Sister_GetTable(_Symbol, spArr);
   for(int si = 0; si < spN; si++)
   {
      string sym = FlowFindSym(spArr[si].sym);
      if(Bars(sym, PERIOD_H4) < h4ShiftFlow + 8) continue;
      double c1 = iClose(sym, PERIOD_H4, h4ShiftFlow + 1);
      double c6 = iClose(sym, PERIOD_H4, h4ShiftFlow + 6);
      if(c1 <= 0.0 || c6 <= 0.0) continue;
      double dir = (c1 > c6) ? 1.0 : (c1 < c6) ? -1.0 : 0.0;
      if(dir == 0.0) continue;
      // Buy
      double rawB  = spArr[si].signForBuy * dir;
      double multB = (rawB < 0.0) ? spArr[si].negMult : 1.0;
      fsBuy  += rawB * spArr[si].weight * multB;
      // Sell (جهت معکوس)
      double rawS  = -spArr[si].signForBuy * dir;
      double multS = (rawS < 0.0) ? spArr[si].negMult : 1.0;
      fsSell += rawS * spArr[si].weight * multS;
   }

   if(sM15==0.0 && sM30==0.0 && sH1==0.0 && sH4==0.0 && sD1==0.0)
   {
      spikeBuyOut  = -1;
      spikeSellOut = -1;
      return -1;  // داده کافی نیست
   }

   // ── Buy Spike ─────────────────────────────────────────────────
   {
      bool flowRedBuy     = (fsBuy < -4.0);
      bool flowYellowBuy  = (fsBuy >= -4.0 && fsBuy < 2.0 && score >= 2.0);
      if(rawPhase >= 1 && flowRedBuy)  spikeBuyOut = rawPhase;
      else if(flowYellowBuy)           spikeBuyOut = 1;
      else                             spikeBuyOut = 0;
   }

   // ── Sell Spike ────────────────────────────────────────────────
   {
      bool flowRedSell    = (fsSell < -4.0);
      bool flowYellowSell = (fsSell >= -4.0 && fsSell < 2.0 && score >= 2.0);
      if(rawPhase >= 1 && flowRedSell) spikeSellOut = rawPhase;
      else if(flowYellowSell)          spikeSellOut = 1;
      else                             spikeSellOut = 0;
   }

   return rawPhase;
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v14.00: نسخه‌های عمومی (پارامتری) Replay برای حالت FOREIGN
//
// چرا نسخه جدا: GBPNZD_Replay_CrisisAtBar/SpikeAtBar بالا از _Symbol و
// handle های زنده چارت (handleEMA200_H1_TL و...) استفاده می‌کنند که فقط
// برای سمبل خود چارت معتبرند. وقتی کاربر می‌نویسد "AUDCAD" ولی چارت باز
// روی GBPNZD است، باید همین محاسبه برای یک سمبل و یک دسته handle موقتِ
// جداگانه انجام شود — بدون دست‌زدن به state زنده‌ی چارت. برای صفر ریسک
// رگرسیون، این دو تابع کپی مستقل با پارامتر صریح symbol/handle هستند
// (نه فراخوانی توابع بالا با تغییر _Symbol که در MQL5 اصلاً ممکن نیست).
// ════════════════════════════════════════════════════════════════════
// 🩹 v14.01 (Team Patch RuleTransition Fix): دو پارامتر خروجی flowScoreOut/adxValOut
// اضافه شد تا OnDemand_RunAndSend بتونه haFlag واقعی (برای Rule_Transition) را
// دقیقاً مثل GBPNZD_InitReplay/Alert_CheckGBPNZDRule بسازد. هیچ محاسبه‌ی جدیدی
// اضافه نشده — فقط دو متغیر محلی موجود (fs→flowScore, adxVal) قبل از هر
// return در پارامتر خروجی نوشته می‌شوند. تنها فراخوان این تابع (OnDemand_RunAndSend)
// همزمان با این تغییر آپدیت شده — نقطه فراخوانی دیگری در فایل وجود ندارد.
int Generic_ReplayCrisisAtBar(string sym, int hEMA200, int hATR_H1, int hADX_H4, int hATR_D1,
                               int h1Shift, bool forBuy,
                               double &flowScoreOut, double &adxValOut, int &rcOut)
{
   // ── RTM ───────────────────────────────────────────────────────
   int newRTM = 1;
   if(hEMA200 != INVALID_HANDLE && hATR_H1 != INVALID_HANDLE
      && BarsCalculated(hEMA200) > 210 + h1Shift
      && BarsCalculated(hATR_H1) > 20  + h1Shift)
   {
      double ema[], atr[];
      ArraySetAsSeries(ema, true);
      ArraySetAsSeries(atr, true);
      bool ok = (CopyBuffer(hEMA200, 0, h1Shift + 1, 3, ema) == 3) &&
                (CopyBuffer(hATR_H1, 0, h1Shift + 1, 2, atr) == 2) &&
                (atr[0] > 0);
      if(ok)
      {
         double h1c0     = iClose(sym, PERIOD_H1, h1Shift + 1);
         double h1c1     = iClose(sym, PERIOD_H1, h1Shift + 2);
         double d0       = MathAbs(h1c0 - ema[0]) / atr[0];
         double d1       = MathAbs(h1c1 - ema[1]) / atr[1];
         double dDel     = d0 - d1;
         bool   rightSide= forBuy ? (h1c0 < ema[0]) : (h1c0 > ema[0]);
         bool   withTrend= !rightSide;
         bool   returning   = (dDel < -0.3);
         bool   runningAway = (dDel > 0.15);

         if(withTrend)
         {
            if(d0 >= 2.0 && dDel > 0.15) newRTM = 0;
            else if(d0 < 0.8 || dDel < -0.35) newRTM = 2;
            else newRTM = 1;
         }
         else
         {
            if(d0 >= 3.5 && returning)        newRTM = 0;
            else if(d0 >= 2.5 && runningAway) newRTM = 2;
            else                               newRTM = 1;
         }
      }
   }

   // ── ADX/TREND (H4) ─────────────────────────────────────────
   int h4Shift = h1Shift / 4;
   int newTrend = 1;
   double adxVal = 0.0;
   double erH4   = 0.0;
   if(hADX_H4 != INVALID_HANDLE && BarsCalculated(hADX_H4) > 20 + h4Shift)
   {
      double adxB[], pdiB[], mdiB[];
      ArraySetAsSeries(adxB, true);
      ArraySetAsSeries(pdiB, true);
      ArraySetAsSeries(mdiB, true);
      bool ok = (CopyBuffer(hADX_H4, 0, h4Shift + 1, 2, adxB) == 2) &&
                (CopyBuffer(hADX_H4, 1, h4Shift + 1, 2, pdiB) == 2) &&
                (CopyBuffer(hADX_H4, 2, h4Shift + 1, 2, mdiB) == 2);
      if(ok)
      {
         double adx   = adxB[0];
         adxVal       = adx;
         double pDI   = pdiB[0], mDI = mdiB[0];
         bool rising  = (adx > adxB[1] + 0.4);

         int erBars   = MathMin(14, Bars(sym, PERIOD_H4) - (h4Shift + 3));
         if(erBars >= 5)
         {
            double netMove = MathAbs(iClose(sym, PERIOD_H4, h4Shift + 1) -
                                     iClose(sym, PERIOD_H4, h4Shift + erBars + 1));
            double sumPath = 0;
            for(int k = 1; k <= erBars; k++)
               sumPath += MathAbs(iClose(sym, PERIOD_H4, h4Shift + k) -
                                  iClose(sym, PERIOD_H4, h4Shift + k + 1));
            erH4 = (sumPath > 0) ? netMove / sumPath : 0;
         }

         bool oppTrend = forBuy ? (mDI > pDI + 5.0) : (pDI > mDI + 5.0);
         if(!oppTrend)
         {
            newTrend = (adx > 20.0 && erH4 > 0.25) ? 0 : 1;
         }
         else
         {
            bool adxWeak = (adx < 20.0), erWeak = (erH4 < 0.20);
            bool adxStr  = (adx >= 32.0 && rising), erStr = (erH4 >= 0.35);
            if(adxWeak || erWeak)          newTrend = 0;
            else if(adxStr && erStr)        newTrend = 2;
            else                            newTrend = 1;
         }
      }
   }

   // ── STRUCT (D1) ─────────────────────────────────────────────
   int newStruct = 1;
   {
      double atrD1 = 0;
      if(hATR_D1 != INVALID_HANDLE && BarsCalculated(hATR_D1) > 5)
      {
         double aB[]; ArraySetAsSeries(aB, true);
         if(CopyBuffer(hATR_D1, 0, 1, 1, aB) == 1 && aB[0] > 0)
            atrD1 = aB[0];
      }
      if(atrD1 <= 0)
         atrD1 = iClose(sym, PERIOD_D1, 1) * 0.006;

      double curPrice = iClose(sym, PERIOD_H1, h1Shift + 1);
      int    lookD1   = MathMin(10, Bars(sym, PERIOD_D1) - 2);
      if(lookD1 >= 5)
      {
         if(forBuy)
         {
            double swLow = iLow(sym, PERIOD_D1, 1);
            for(int k = 2; k <= lookD1; k++)
               swLow = MathMin(swLow, iLow(sym, PERIOD_D1, k));
            double dist = curPrice - swLow;
            if(curPrice < swLow)         newStruct = 2;
            else if(dist < atrD1 * 2.0)  newStruct = 1;
            else                          newStruct = 0;
         }
         else
         {
            double swHigh = iHigh(sym, PERIOD_D1, 1);
            for(int k = 2; k <= lookD1; k++)
               swHigh = MathMax(swHigh, iHigh(sym, PERIOD_D1, k));
            double dist = swHigh - curPrice;
            if(curPrice > swHigh)         newStruct = 2;
            else if(dist < atrD1 * 2.0)   newStruct = 1;
            else                           newStruct = 0;
         }
      }
   }

   // ── FLOW ────────────────────────────────────────────────────
   int newFLOW = 1;
   double flowScore = 0.0;
   {
      SisterEntry sArr[];
      int sN = Sister_GetTable(sym, sArr);
      double fs = 0.0;
      for(int si = 0; si < sN; si++)
      {
         string ssym = FlowFindSym(sArr[si].sym);
         if(Bars(ssym, PERIOD_H4) < 8 + h4Shift) continue;
         double c1 = iClose(ssym, PERIOD_H4, h4Shift + 1);
         double c6 = iClose(ssym, PERIOD_H4, h4Shift + 6);
         if(c1 <= 0.0 || c6 <= 0.0) continue;
         double dir = (c1 > c6) ? 1.0 : (c1 < c6) ? -1.0 : 0.0;
         if(dir == 0.0) continue;
         int    effSign   = forBuy ? sArr[si].signForBuy : -sArr[si].signForBuy;
         double rawSignal = effSign * dir;
         double mult      = (rawSignal < 0.0) ? sArr[si].negMult : 1.0;
         fs += rawSignal * sArr[si].weight * mult;
      }
      flowScore = fs;
      if(fs > 2.0)        newFLOW = 0;
      else if(fs >= -4.0) newFLOW = 1;
      else                 newFLOW = 2;
   }

   // ── RC و Crisis state ───────────────────────────────────────
   int rc = (newRTM==2?1:0) + (newTrend==2?1:0) + (newStruct==2?1:0) + (newFLOW==2?1:0);
   rcOut  = rc;
   // 🩹 v14.01: export مقادیر محلی موجود (بدون محاسبه‌ی جدید) برای haFlag در OnDemand_RunAndSend
   flowScoreOut = flowScore;
   adxValOut    = adxVal;

   double th_RedA_ADX, th_RedA_Flow, th_RedB_ADX, th_RedB_Flow;
   double th_OrA_ADX,  th_OrA_Flow,  th_OrB_ADX,  th_OrB_Ts;
   double th_OrC_ADX,  th_OrC_Flow,  th_OrC_Ts;
   double th_OrD_ADX,  th_OrD_Ts;
   double th_Y2_ADX,   th_Y2_Flow, th_Y3_Flow, th_Y3_Ts;
   double th_Y4_ADX,   th_Y4_Ts,   th_Y5_ADX,  th_Y5_Flow;
   Crisis_GetThresholds(
      th_RedA_ADX, th_RedA_Flow, th_RedB_ADX, th_RedB_Flow,
      th_OrA_ADX,  th_OrA_Flow,  th_OrB_ADX,  th_OrB_Ts,
      th_OrC_ADX,  th_OrC_Flow,  th_OrC_Ts,
      th_OrD_ADX,  th_OrD_Ts,
      th_Y2_ADX,   th_Y2_Flow,   th_Y3_Flow,  th_Y3_Ts,
      th_Y4_ADX,   th_Y4_Ts,     th_Y5_ADX,   th_Y5_Flow,
      sym);   // 🆕 v14.00: کالیبراسیون آستانه‌ها برای همین سمبل، نه چارت

   // trendScore زنده (g_csvScore) متعلق به سمبل چارت است، نه سمبل درخواستی
   // FOREIGN — همیشه از تخمین erH4×adxVal استفاده می‌کنیم (مثل حالتی که
   // g_csvScore=0 است در نسخه SELF).
   double trendScore  = erH4 * adxVal * 0.5;
   double tsAgainst   = forBuy ? -trendScore : trendScore;
   double flowAgainst = -flowScore;

   if(rc < 0) return -1;

   if((rc >= 3 && flowAgainst >= th_RedA_Flow && adxVal > th_RedA_ADX) ||
      (rc >= 2 && flowAgainst >= th_RedB_Flow && adxVal > th_RedB_ADX))
      return 2;  // Red

   if((rc >= 2 && flowAgainst >= th_OrA_Flow && adxVal > th_OrA_ADX) ||
      (rc >= 3 && tsAgainst > th_OrB_Ts && adxVal > th_OrB_ADX) ||
      (rc >= 2 && flowAgainst >= th_OrC_Flow && adxVal > th_OrC_ADX && tsAgainst > th_OrC_Ts) ||
      (tsAgainst > th_OrD_Ts && adxVal > th_OrD_ADX))
      return 3;  // Orange

   if((rc >= 2) ||
      (flowAgainst >= th_Y2_Flow && adxVal > th_Y2_ADX) ||
      (rc >= 2 && flowAgainst >= th_Y3_Flow && tsAgainst > th_Y3_Ts) ||
      (rc >= 2 && tsAgainst > th_Y4_Ts && adxVal > th_Y4_ADX) ||
      (rc >= 2 && flowAgainst >= th_Y5_Flow && adxVal > th_Y5_ADX))
      return 1;  // Yellow

   return 0;  // Green
}

int Generic_ReplaySpikeAtBar(string sym, int h1Shift, int &spikeBuyOut, int &spikeSellOut)
{
   spikeBuyOut  = -1;
   spikeSellOut = -1;

   int m15Shift = h1Shift * 4;
   int m30Shift = h1Shift * 2;
   int h4Shift  = h1Shift / 4;
   int d1Shift  = h1Shift / 24;

   double sM15 = 0.0, sM30 = 0.0, sH1 = 0.0, sH4 = 0.0, sD1 = 0.0;
   {
      ENUM_TIMEFRAMES tfs[5]   = {PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H4, PERIOD_D1};
      int              shifts[5]= {m15Shift, m30Shift, h1Shift, h4Shift, d1Shift};
      double           results[5];
      int atrPeriod = 14;

      for(int t = 0; t < 5; t++)
      {
         ENUM_TIMEFRAMES tf = tfs[t];
         int             sh = shifts[t];
         int             need = atrPeriod + 3;

         if(Bars(sym, tf) < sh + need + 2) { results[t] = 0.0; continue; }

         double high[], low[], openP[], closeP[];
         ArraySetAsSeries(high,   true);
         ArraySetAsSeries(low,    true);
         ArraySetAsSeries(openP,  true);
         ArraySetAsSeries(closeP, true);

         if(CopyHigh (sym, tf, sh + 1, need, high)   < need) { results[t] = 0.0; continue; }
         if(CopyLow  (sym, tf, sh + 1, need, low)    < need) { results[t] = 0.0; continue; }
         if(CopyOpen (sym, tf, sh + 1, need, openP)  < need) { results[t] = 0.0; continue; }
         if(CopyClose(sym, tf, sh + 1, need, closeP) < need) { results[t] = 0.0; continue; }

         double atrSum = 0.0;
         for(int i = 1; i <= atrPeriod; i++)
            atrSum += (high[i] - low[i]);
         double atr = atrSum / atrPeriod;
         if(atr <= 0.0) { results[t] = 0.0; continue; }

         double curRange  = high[0] - low[0];
         double rangeScore= curRange / atr;

         double curBody   = MathAbs(closeP[0] - openP[0]);
         double prevBody  = MathAbs(closeP[1] - openP[1]);
         double prevSafe  = MathMax(prevBody, atr * 0.10);
         double bodyScore = curBody / prevSafe;
         if(bodyScore > 4.0) bodyScore = 4.0;

         results[t] = (rangeScore * 0.6) + (bodyScore * 0.4);
      }
      sM15 = results[0]; sM30 = results[1]; sH1 = results[2]; sH4 = results[3]; sD1 = results[4];
   }

   double wM15, wM30, wH1, wH4, wD1;
   Rule_SpikeWeightsForSymbol(sym, wM15, wM30, wH1, wH4, wD1);
   double score = sM15*wM15 + sM30*wM30 + sH1*wH1 + sH4*wH4 + sD1*wD1;

   int rawPhase = (score < 1.00) ? 0 : (score <= 1.50) ? 1 : 2;

   int h4ShiftFlow = h1Shift / 4;
   double fsBuy = 0.0, fsSell = 0.0;
   SisterEntry spArr[];
   int spN = Sister_GetTable(sym, spArr);
   for(int si = 0; si < spN; si++)
   {
      string ssym = FlowFindSym(spArr[si].sym);
      if(Bars(ssym, PERIOD_H4) < h4ShiftFlow + 8) continue;
      double c1 = iClose(ssym, PERIOD_H4, h4ShiftFlow + 1);
      double c6 = iClose(ssym, PERIOD_H4, h4ShiftFlow + 6);
      if(c1 <= 0.0 || c6 <= 0.0) continue;
      double dir = (c1 > c6) ? 1.0 : (c1 < c6) ? -1.0 : 0.0;
      if(dir == 0.0) continue;
      double rawB  = spArr[si].signForBuy * dir;
      double multB = (rawB < 0.0) ? spArr[si].negMult : 1.0;
      fsBuy  += rawB * spArr[si].weight * multB;
      double rawS  = -spArr[si].signForBuy * dir;
      double multS = (rawS < 0.0) ? spArr[si].negMult : 1.0;
      fsSell += rawS * spArr[si].weight * multS;
   }

   if(sM15==0.0 && sM30==0.0 && sH1==0.0 && sH4==0.0 && sD1==0.0)
   {
      spikeBuyOut  = -1;
      spikeSellOut = -1;
      return -1;
   }

   {
      bool flowRedBuy     = (fsBuy < -4.0);
      bool flowYellowBuy  = (fsBuy >= -4.0 && fsBuy < 2.0 && score >= 2.0);
      if(rawPhase >= 1 && flowRedBuy)  spikeBuyOut = rawPhase;
      else if(flowYellowBuy)           spikeBuyOut = 1;
      else                             spikeBuyOut = 0;
   }
   {
      bool flowRedSell    = (fsSell < -4.0);
      bool flowYellowSell = (fsSell >= -4.0 && fsSell < 2.0 && score >= 2.0);
      if(rawPhase >= 1 && flowRedSell) spikeSellOut = rawPhase;
      else if(flowYellowSell)          spikeSellOut = 1;
      else                             spikeSellOut = 0;
   }

   return rawPhase;
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v14.00: FOREIGN on-demand — پیاده‌سازی کامل
// ════════════════════════════════════════════════════════════════════

// پیدا کردن سمبل واقعی بروکر برای یک نام پاک — همان روش FlowFindSym
// (بدون پسوند → با پسوند چارت خودی) به‌علاوه SymbolSelect برای اطمینان
// از این‌که سمبل در Market Watch فعال است (لازم برای handle ساختن).
string OnDemand_ResolveBrokerSymbol(string cleanSym)
{
   if(SymbolInfoInteger(cleanSym, SYMBOL_EXIST))
   {
      SymbolSelect(cleanSym, true);
      return cleanSym;
   }
   if(StringLen(_Symbol) > 6)
   {
      string candidate = cleanSym + StringSubstr(_Symbol, 6);
      if(SymbolInfoInteger(candidate, SYMBOL_EXIST))
      {
         SymbolSelect(candidate, true);
         return candidate;
      }
   }
   return "";  // پیدا نشد
}

void OnDemand_Cleanup()
{
   if(g_odHandleEMA200 != INVALID_HANDLE) { IndicatorRelease(g_odHandleEMA200); g_odHandleEMA200 = INVALID_HANDLE; }
   if(g_odHandleATR_H1 != INVALID_HANDLE) { IndicatorRelease(g_odHandleATR_H1); g_odHandleATR_H1 = INVALID_HANDLE; }
   if(g_odHandleADX_H4 != INVALID_HANDLE) { IndicatorRelease(g_odHandleADX_H4); g_odHandleADX_H4 = INVALID_HANDLE; }
   if(g_odHandleATR_D1 != INVALID_HANDLE) { IndicatorRelease(g_odHandleATR_D1); g_odHandleATR_D1 = INVALID_HANDLE; }
   g_odState        = OD_STATE_IDLE;
   g_odCleanSymbol  = "";
   g_odBrokerSymbol = "";
   g_odRetryCount   = 0;
}

// نقطه ورود: وقتی کاربر "AUDCAD" یا "EURGBP" یا "GBPNZD" (سمبلی غیر از
// سمبل چارت جاری) را در تلگرام می‌فرستد.
void OnDemand_RequestSymbol(string cleanSym)
{
   if(g_odState != OD_STATE_IDLE)
   {
      Alert_SendTelegram("⏳ یک درخواست وضعیت قبلی هنوز در حال محاسبه است — چند ثانیه صبر کن و دوباره بفرست.");
      return;
   }

   string broker = OnDemand_ResolveBrokerSymbol(cleanSym);
   if(broker == "")
   {
      Alert_SendTelegram("❌ سمبل " + cleanSym + " روی این بروکر پیدا نشد.");
      return;
   }

   g_odCleanSymbol  = cleanSym;
   g_odBrokerSymbol = broker;
   g_odHandleEMA200 = iMA (broker, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
   g_odHandleATR_H1 = iATR(broker, PERIOD_H1, ATRPeriod);
   g_odHandleADX_H4 = iADX(broker, PERIOD_H4, ADXPeriod);
   g_odHandleATR_D1 = iATR(broker, PERIOD_D1, ATRPeriod);

   if(g_odHandleEMA200 == INVALID_HANDLE || g_odHandleATR_H1 == INVALID_HANDLE ||
      g_odHandleADX_H4 == INVALID_HANDLE || g_odHandleATR_D1 == INVALID_HANDLE)
   {
      Alert_SendTelegram("❌ ساخت اندیکاتور برای " + broker + " ناموفق بود.");
      OnDemand_Cleanup();
      return;
   }

   g_odState      = OD_STATE_WARMING;
   g_odRetryCount = 0;
   if(EnableAllLogs)
      Print("OnDemand: درخواست ", cleanSym, " (broker=", broker, ") — در حال گرم‌کردن handle ها...");
}

// هر تیک OnTimer صدا زده می‌شود؛ اگه درخواستی در حال انتظار نباشه فوراً برمی‌گرده (بار صفر)
void OnDemand_Poll()
{
   if(g_odState != OD_STATE_WARMING) return;

   bool ready = (BarsCalculated(g_odHandleEMA200) > 210) &&
                (BarsCalculated(g_odHandleATR_H1) > 20)  &&
                (BarsCalculated(g_odHandleADX_H4) > 20)  &&
                (BarsCalculated(g_odHandleATR_D1) > 5);

   if(ready)
   {
      OnDemand_RunAndSend();
      OnDemand_Cleanup();
      return;
   }

   g_odRetryCount++;
   if(g_odRetryCount > OD_MAX_RETRIES)
   {
      Alert_SendTelegram("❌ دیتای " + g_odCleanSymbol + " آماده نشد (تاریخچه کافی از بروکر دریافت نشد). دوباره امتحان کن.");
      OnDemand_Cleanup();
   }
}

// متن یک چراغ Crisis/Spike به سبک همون چیزی که در Alert_CheckGBPNZDRule استفاده میشه
string OD_LightText(int v)
{
   if(v == 0) return "🟢 Green";
   if(v == 1) return "🟡 Yellow";
   if(v == 2) return "🔴 Red";
   if(v == 3) return "🟠 Orange";
   return "⚪ N/A";
}

string OD_RuleLevelText(int level)
{
   if(level == 0) return "🟢 عادی (GREEN)";
   if(level == 1) return "🛑 STOP — باز نکن";
   if(level == 2) return "🚪 CLOSE — بستن توصیه میشه";
   return "❔ نامشخص";
}

// محاسبه کامل Buy/Sell برای g_odBrokerSymbol با 72 ساعت Replay + دو پیام جدا ارسال می‌کند
void OnDemand_RunAndSend()
{
   string broker = g_odBrokerSymbol;
   string clean  = g_odCleanSymbol;

   // ── 72 ساعت گذشته را replay می‌کنیم (h1Shift از 72 تا 1) — دقیقاً
   // همون منطق GBPNZD_InitReplay ولی روی سمبل/handle موقت این درخواست.
   // 🩹 v14.01 (Team Patch RuleTransition Fix، بخش ۲): قبلاً اینجا به‌جای
   // Rule_Transition واقعی یک تخمین جدا (crisisRedH>=2) استفاده می‌شد که با
   // Rule واقعی سیستم (لایو/بکتست/GBPNZD_InitReplay) یکی نبود و اصلاً CLOSE/
   // RESUME را نمی‌دید. حالا دقیقاً همان دو تابع مشترک Rule_UpdateCounters +
   // Rule_Transition صدا زده می‌شود — همان Single Source of Truth که همه‌جای
   // دیگر سیستم استفاده می‌کند. محدودیت واقعی که باقی می‌ماند فقط این است که
   // accumulator ساعت *در حال شکل‌گیری* (نیمه‌کاره، فقط با EA زنده روی همان
   // چارت موجود است) در دسترس نیست؛ STOP/CLOSE/RESUME بر مبنای ۷۲ ساعت
   // کاملاً بسته کاملاً قابل تشخیص‌اند (نه فقط STOP).
   // 🆕 v14.03: تایم‌فریم FOREIGN از چارت جاری پیروی می‌کند — نه H1 هاردکد.
   // اگه اکسپرت روی H1 باشد: ۷۲ کندل H1 replay. اگه M1: ۴۳۲۰ کندل M1.
   // یک موتور قانون‌گذار — همه سمبل‌ها — همه تایم‌فریم‌ها.
   ENUM_TIMEFRAMES odTF         = PERIOD_CURRENT;
   int             odPeriodSec  = (int)PeriodSeconds(odTF);
   // ✅ PATCH-5 v14.05: پنجره زمانی ثابت ۷۲ ساعت — granularity از TF چارت
   // قبلاً MathMax(72,...) پنجره را برای H4/D1 اعوجاج می‌داد:
   //   H4: max(72, 18) = 72 کندل H4 = 288 ساعت = 12 روز (نه 3 روز!)
   //   D1: max(72, 3)  = 72 کندل D1 = 72 روز
   // حالا: پنجره همیشه ۷۲ ساعت است، فقط تعداد کندل‌ها با TF فرق می‌کنه
   int             odWindowSec  = 72 * 3600; // ۷۲ ساعت — ثابت برای همه TF
   int             odBarsToScan = (int)MathMax(1, odWindowSec / MathMax(odPeriodSec, 1));
   string          odTFName     = EnumToString(odTF);

   // 🔴 v14.06 BUG-H2 FIX: بررسی موجودیت داده FOREIGN قبل از loop
   // اگر broker در PERIOD_CURRENT داده کافی نداشت، CopyClose در loop صفر
   // برمی‌گرداند و counter ها خاموش می‌شوند بدون هیچ اخطاری.
   // حالا: اگر availBars < odBarsToScan → odBarsToScan به available کاهش می‌یابد.
   // اگر < 10 → کاملاً skip (داده ناکافی).
   {
      int _availBars = iBars(broker, PERIOD_CURRENT);
      if(_availBars < odBarsToScan)
      {
         Print("⚠️ FOREIGN ", broker, " only ", _availBars, " bars on ", odTFName,
               " (needed ", odBarsToScan, ") — reducing window");
         odBarsToScan = _availBars;
      }
      if(odBarsToScan < 10)
      {
         Print("❌ FOREIGN ", broker, " insufficient data on ", odTFName,
               " (", odBarsToScan, " bars) — skipping OnDemand");
         OnDemand_Cleanup();
         return;
      }
   }

   // 🆕 v14.07 P5: چک اضافه صحت CopyClose — iBars ممکنه > 0 باشه ولی داده واقعی صفر
   {
      double _testClose[];
      int _copied = CopyClose(broker, PERIOD_CURRENT, 0, MathMin(5, odBarsToScan), _testClose);
      if(_copied <= 0)
      {
         Print("❌ FOREIGN CopyClose failed for ", broker, " TF=", EnumToString(PERIOD_CURRENT));
         OnDemand_Cleanup();
         return;
      }
      bool _allZero = true;
      for(int _ci = 0; _ci < _copied; _ci++)
         if(_testClose[_ci] > 0.0) { _allZero = false; break; }
      if(_allZero)
      {
         Print("❌ FOREIGN all-zero prices for ", broker, " — data not ready");
         OnDemand_Cleanup();
         return;
      }
   }

   int crisisRedHBuy = 0, crisisRedHSell = 0, cleanHBuy = 0, cleanHSell = 0;
   int levelBuy = 0, levelSell = 0, reasonBuy = -1, reasonSell = -1;
   int lastCrBuy = -1, lastSpBuy = -1, lastCrSell = -1, lastSpSell = -1;
   int lastRcBuy = 0, lastRcSell = 0;

   // 🆕 v14.03: shift از odBarsToScan تا 1 (با تایم‌فریم چارت)
   for(int odShift = odBarsToScan; odShift >= 1; odShift--)
   {
      double flowBuy = 0.0, adxBuy = 0.0; int rcBuy = 0;
      double flowSell = 0.0, adxSell = 0.0; int rcSell = 0;
      int crBuy  = Generic_ReplayCrisisAtBar(broker, g_odHandleEMA200, g_odHandleATR_H1, g_odHandleADX_H4, g_odHandleATR_D1, odShift, true,  flowBuy,  adxBuy,  rcBuy);
      int crSell = Generic_ReplayCrisisAtBar(broker, g_odHandleEMA200, g_odHandleATR_H1, g_odHandleADX_H4, g_odHandleATR_D1, odShift, false, flowSell, adxSell, rcSell);

      int spBuyDum = -1, spSellDum = -1;
      Generic_ReplaySpikeAtBar(broker, odShift, spBuyDum, spSellDum);
      // مثل GBPNZD_InitReplay اصلی: داده‌ی ناقص = خنثی (0)، نه continue/skip
      int spBuy  = (spBuyDum  >= 0) ? spBuyDum  : 0;
      int spSell = (spSellDum >= 0) ? spSellDum : 0;

      // HighAlert جهت‌دار — دقیقاً همان آستانه‌های GBPNZD_InitReplay/Alert_CheckGBPNZDRule
      bool haBuy  = (adxBuy  >= 35.0) && (flowBuy  < -7.0);
      bool haSell = (adxSell >= 35.0) && (flowSell >  7.0);

      bool hourRedBuy    = (crBuy == 2);
      bool hourDirtyBuy  = (crBuy == 2 || spBuy  >= 1);
      bool hourRedSell   = (crSell == 2);
      bool hourDirtySell = (crSell == 2 || spSell >= 1);

      Rule_UpdateCounters(hourRedBuy,  hourDirtyBuy,  crisisRedHBuy,  cleanHBuy);
      Rule_Transition(crBuy, spBuy, haBuy, crisisRedHBuy, cleanHBuy, levelBuy, reasonBuy);

      Rule_UpdateCounters(hourRedSell, hourDirtySell, crisisRedHSell, cleanHSell);
      Rule_Transition(crSell, spSell, haSell, crisisRedHSell, cleanHSell, levelSell, reasonSell);

      lastCrBuy = crBuy;   lastSpBuy  = spBuy;   lastRcBuy  = rcBuy;
      lastCrSell = crSell; lastSpSell = spSell;  lastRcSell = rcSell;
   }
   // levelBuy/levelSell دیگر تخمینی نیستند — همان ماشین‌حالت سه‌سطحی واقعی
   // GREEN(0)/STOP(1)/CLOSE(2) سیستم است (از حلقه‌ی بالا خارج شد).

   // ── پوزیشن واقعی (اگه باشه) ──────────────────────────────────────
   int buyCnt = 0, sellCnt = 0;
   double buyProfit = 0.0, sellProfit = 0.0;
   datetime buyOldest = 0, sellOldest = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      string psym = PositionGetSymbol(i);
      if(!HM_PositionBelongsToSymbol(psym, broker)) continue;
      long pt = PositionGetInteger(POSITION_TYPE);
      double pr = PositionGetDouble(POSITION_PROFIT);
      datetime pt_time = (datetime)PositionGetInteger(POSITION_TIME);
      if(pt == POSITION_TYPE_BUY)
      {
         buyCnt++; buyProfit += pr;
         if(buyOldest == 0 || pt_time < buyOldest) buyOldest = pt_time;
      }
      else
      {
         sellCnt++; sellProfit += pr;
         if(sellOldest == 0 || pt_time < sellOldest) sellOldest = pt_time;
      }
   }
   bool centAcc = DetectCentAccount();
   if(centAcc) { buyProfit /= 100.0; sellProfit /= 100.0; }

   // ── ساخت و ارسال دو پیام جدا (طبق درخواست: Buy و Sell مجزا) ────────
   // 🆕 v14.03: تایم‌فریم نمایش‌داده‌شده همان تایم‌فریم چارت جاری است
   string hdr = "📟 وضعیت لحظه‌ای " + clean + " (" + broker + ")\n"
              + "⚠️ اکسپرت روی این سمبل اجرا نیست — محاسبه یک‌باره بر پایه "
              + IntegerToString(odBarsToScan) + " کندل " + odTFName + " بسته اخیر.\n"
              + "⚠️ بدون accumulator کندل جاری (نیمه‌کاره) — ممکن است یک کندل با لایو خودِ سمبل تأخیر داشته باشد.\n"
              + "─────────────────────\n";

   string msgBuy = hdr
      + "📈 جهت BUY (پوزیشن مجازی)\n"
      + "Crisis: " + OD_LightText(lastCrBuy) + "\n"
      + "Spike : " + OD_LightText(lastSpBuy) + "\n"
      + "rc="+IntegerToString(lastRcBuy)+"  CrisisRedH="+IntegerToString(crisisRedHBuy)+"  CleanH="+IntegerToString(cleanHBuy) + "\n"
      + "Rule  : " + OD_RuleLevelText(levelBuy) + "\n"
      + "─────────────────────\n";
   if(buyCnt > 0)
      msgBuy += "💰 پوزیشن باز BUY: " + IntegerToString(buyCnt) + " | سود: " + DoubleToString(buyProfit, 2)
              + " | از ساعت: " + TimeToString(buyOldest, TIME_DATE|TIME_MINUTES);
   else
      msgBuy += "معامله باز BUY نداریم.";

   string msgSell = hdr
      + "📉 جهت SELL (پوزیشن مجازی)\n"
      + "Crisis: " + OD_LightText(lastCrSell) + "\n"
      + "Spike : " + OD_LightText(lastSpSell) + "\n"
      + "rc="+IntegerToString(lastRcSell)+"  CrisisRedH="+IntegerToString(crisisRedHSell)+"  CleanH="+IntegerToString(cleanHSell) + "\n"
      + "Rule  : " + OD_RuleLevelText(levelSell) + "\n"
      + "─────────────────────\n";
   if(sellCnt > 0)
      msgSell += "💰 پوزیشن باز SELL: " + IntegerToString(sellCnt) + " | سود: " + DoubleToString(sellProfit, 2)
               + " | از ساعت: " + TimeToString(sellOldest, TIME_DATE|TIME_MINUTES);
   else
      msgSell += "معامله باز SELL نداریم.";

   Alert_SendTelegram(msgBuy);
   Alert_SendTelegram(msgSell);

   if(EnableAllLogs)
      Print("OnDemand: ارسال کامل شد برای ", clean, " (", broker, ")");
}


//
// کلیدها (بدون پیشوند Symbol تا با ری‌استارت EA روی همان Symbol کار کنه):
//   HM_GBNZD_LvBuy   → g_gbpnzdLevelBuy
//   HM_GBNZD_LvSell  → g_gbpnzdLevelSell
//   HM_GBNZD_ClHBuy  → g_gbpnzdCleanHBuy
//   HM_GBNZD_ClHSell → g_gbpnzdCleanHSell
//   HM_GBNZD_RdHBuy  → g_gbpnzdCrisisRedHBuy
//   HM_GBNZD_RdHSell → g_gbpnzdCrisisRedHSell
//   HM_GBNZD_LastH   → g_gbpnzdLastH (datetime as double)
//   HM_GBNZD_SRBuy   → g_gbpnzdStopReasonBuy
//   HM_GBNZD_SRSell  → g_gbpnzdStopReasonSell
//   HM_GBNZD_Saved   → timestamp آخرین save (برای تشخیص stale)
// ════════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.49 P3 (اختیاری): Snapshot فایلی برای وضعیت لحظه‌ای ساعت جاری
//
// مشکل: GlobalVariable با ری‌استارت کامل MT5 پاک می‌شه (طراحی عمدی v13.38).
// بعد از پاک شدن، GBPNZD_InitReplay فقط از روی کندل‌های کاملاً بسته H1
// بازسازی می‌کنه — اگه Crisis=Red وسط یک کندل رخ داده و کندل با رنگ بهتر
// بسته شده باشه، Replay آن اپیزود رو نمی‌بینه (کوری موقت تا بحران بعدی).
//
// راه‌حل: وضعیت accumulator ساعت در حال شکل‌گیری (نه فقط کندل بسته) در یک
// فایل (نه GlobalVariable) ذخیره می‌شه — فایل با ری‌استارت MT5 پاک نمی‌شه.
// این فقط وقتی نوشته می‌شه که حداقل یکی از چراغ‌ها Red/Dirty باشه (نه هر
// تیک سبز) تا اضافه‌باری I/O ایجاد نشه.
// ════════════════════════════════════════════════════════════════════
// 🆕 v14.00: نام فایل بر حسب سمبل — برای GBPNZD همان نام قدیمی
// (صفر ریسک برای فایل موجود کاربر فعلی)، برای AUDCAD/EURGBP فایل جدا
string HM_HourStateFile(string sym)
{
   // ✅ PATCH-6 v14.05: نام فایل شامل TF می‌شود تا اگه اکسپرت روی دو چارت با
   // تایم‌فریم متفاوت باز باشد، هر نمونه فایل مستقل خودش را داشته باشد.
   // قبلاً: HelpMe_GBNZD_HourStateSnapshot.dat (یکسان برای H1 و M1)
   // حالا:  HelpMe_GBNZD_HourStateSnapshot_PERIOD_H1.dat
   string c   = CleanSymbol(sym);
   string tfStr = EnumToString(PERIOD_CURRENT);
   if(c == "GBPNZD") return "HelpMe_GBNZD_HourStateSnapshot_" + tfStr + ".dat";
   return "HelpMe_" + c + "_HourStateSnapshot_" + tfStr + ".dat";
}

void GBPNZD_SaveHourStateFile()
{
   if((bool)MQLInfoInteger(MQL_TESTER)) return;
   // 🆕 v14.04 FIX-2: مرز کندل چارت (نه H1 هاردکد).
   // این مقدار باید با curFormingBar در GBPNZD_InitReplay هماهنگ باشد
   // تا فایل snapshot درست شناسایی شود (fHour == curFormingBar).
   int      gapStep    = (g_chartPeriodSeconds > 0) ? g_chartPeriodSeconds : 3600;
   datetime thisBar    = (datetime)(((long)TimeCurrent()) / gapStep * gapStep);
   int fh = FileOpen(HM_HourStateFile(_Symbol), FILE_WRITE | FILE_TXT | FILE_COMMON);
   if(fh == INVALID_HANDLE) return;
   FileWrite(fh, (long)thisBar,
              g_gbpnzdHourRedBuy   ? 1 : 0, g_gbpnzdHourDirtyBuy  ? 1 : 0,
              g_gbpnzdHourRedSell  ? 1 : 0, g_gbpnzdHourDirtySell ? 1 : 0);
   FileClose(fh);
}

// خروجی: true اگه فایل موجود و قابل‌خواندن بود
bool GBPNZD_LoadHourStateFile(datetime &fileHour, bool &redBuy, bool &dirtyBuy, bool &redSell, bool &dirtySell)
{
   redBuy = dirtyBuy = redSell = dirtySell = false;
   fileHour = 0;
   string fname = HM_HourStateFile(_Symbol);
   if(!FileIsExist(fname, FILE_COMMON)) return false;
   int fh = FileOpen(fname, FILE_READ | FILE_TXT | FILE_COMMON);
   if(fh == INVALID_HANDLE) return false;
   long hh = (long)FileReadNumber(fh);
   int  rb = (int)FileReadNumber(fh);
   int  db = (int)FileReadNumber(fh);
   int  rs = (int)FileReadNumber(fh);
   int  ds = (int)FileReadNumber(fh);
   FileClose(fh);
   fileHour = (datetime)hh;
   redBuy   = (rb != 0);
   dirtyBuy = (db != 0);
   redSell  = (rs != 0);
   dirtySell= (ds != 0);
   return true;
}

void GBPNZD_GV_Save()
{
   // 🩹 PATCH v13.51: کلید نسخه ساختار GV — برای تشخیص GV قدیمی (قبل از پچ)
   // از GV جدید که واقعاً Level=0 (GREEN) هست. بدون این کلید، InitReplay
   // نمی‌تونست این دو حالت رو از هم تشخیص بده (نگاه کن به GBPNZD_GV_Load
   // و GBPNZD_InitReplay برای توضیح کامل).
   // 🆕 v14.00: پیشوند کلید بر حسب سمبل — برای GBPNZD دقیقاً همان
   // "HM_GBNZD_" قدیمی (صفر ریسک برای state ذخیره‌شده فعلی)، برای
   // AUDCAD/EURGBP پیشوند مستقل خودشون (مثلاً "HM_AUDCAD_") تا هرکدوم
   // GV جدای خودشون رو داشته باشن و با هم تداخل نکنن.
   string pfx = Rule_GVPrefix(_Symbol);
   GlobalVariableSet(pfx+"Ver", 1400.0);
   GlobalVariableSet(pfx+"LvBuy",   (double)g_gbpnzdLevelBuy);
   GlobalVariableSet(pfx+"LvSell",  (double)g_gbpnzdLevelSell);
   GlobalVariableSet(pfx+"ClHBuy",  (double)g_gbpnzdCleanHBuy);
   GlobalVariableSet(pfx+"ClHSell", (double)g_gbpnzdCleanHSell);
   GlobalVariableSet(pfx+"RdHBuy",  (double)g_gbpnzdCrisisRedHBuy);
   GlobalVariableSet(pfx+"RdHSell", (double)g_gbpnzdCrisisRedHSell);
   GlobalVariableSet(pfx+"LastH",   (double)g_gbpnzdLastH);
   GlobalVariableSet(pfx+"SRBuy",   (double)g_gbpnzdStopReasonBuy);
   GlobalVariableSet(pfx+"SRSell",  (double)g_gbpnzdStopReasonSell);
   // 🐛 v13.40 FIX-A: PrevCrisis/Spike و Crisis جاری هم ذخیره می‌شن
   // بدون اینها: بعد از ری‌استارت، Prev=-1 → counter اول CleanH++ غلط می‌زنه
   GlobalVariableSet(pfx+"PrCrBuy",  (double)g_gbpnzdPrevCrisisBuy);
   GlobalVariableSet(pfx+"PrCrSell", (double)g_gbpnzdPrevCrisisSell);
   GlobalVariableSet(pfx+"PrSpBuy",  (double)g_gbpnzdPrevSpikeBuy);
   GlobalVariableSet(pfx+"PrSpSell", (double)g_gbpnzdPrevSpikeSell);
   GlobalVariableSet(pfx+"CrBuy",    (double)g_gbnzdCrisisBuy);
   GlobalVariableSet(pfx+"CrSell",   (double)g_gbnzdCrisisSell);
   GlobalVariableSet(pfx+"SpBuy",    (double)g_gbnzdSpikeBuy);
   GlobalVariableSet(pfx+"SpSell",   (double)g_gbnzdSpikeSell);
   // 🆕 v13.48 FIX1: accumulator ذخیره
   GlobalVariableSet(pfx+"HRedBuy",   (double)(g_gbpnzdHourRedBuy   ? 1 : 0));
   GlobalVariableSet(pfx+"HDirtyBuy", (double)(g_gbpnzdHourDirtyBuy ? 1 : 0));
   GlobalVariableSet(pfx+"HRedSell",  (double)(g_gbpnzdHourRedSell  ? 1 : 0));
   GlobalVariableSet(pfx+"HDirtySell",(double)(g_gbpnzdHourDirtySell? 1 : 0));
   GlobalVariableSet(pfx+"Saved",   (double)TimeCurrent());
}

// بازگشت: true = لود موفق | false = GV موجود نبود یا stale بود
bool GBPNZD_GV_Load()
{
   string pfx = Rule_GVPrefix(_Symbol);
   if(!GlobalVariableCheck(pfx+"Saved")) return false;

   // 🩹 PATCH v13.51: اگه کلید ورژن نباشه یعنی این GV مال قبل از پچ است —
   // قابل‌اعتماد نیست چون ممکنه از نسخه‌ای باشه که LvBuy/LvSell رو کامل
   // ذخیره نمی‌کرده. در این حالت InitReplay باید Replay کامل بزنه.
   if(!GlobalVariableCheck(pfx+"Ver")) return false;

   datetime savedAt = (datetime)GlobalVariableGet(pfx+"Saved");
   // اگه بیشتر از 72 ساعت گذشته → stale، از Replay استفاده کن
   if(TimeCurrent() - savedAt > 72 * 3600) return false;

   g_gbpnzdLevelBuy        = (int)GlobalVariableGet(pfx+"LvBuy");
   g_gbpnzdLevelSell       = (int)GlobalVariableGet(pfx+"LvSell");
   g_gbpnzdCleanHBuy       = (int)GlobalVariableGet(pfx+"ClHBuy");
   g_gbpnzdCleanHSell      = (int)GlobalVariableGet(pfx+"ClHSell");
   g_gbpnzdCrisisRedHBuy   = (int)GlobalVariableGet(pfx+"RdHBuy");
   g_gbpnzdCrisisRedHSell  = (int)GlobalVariableGet(pfx+"RdHSell");
   g_gbpnzdLastH           = (datetime)GlobalVariableGet(pfx+"LastH");
   g_gbpnzdStopReasonBuy   = (int)GlobalVariableGet(pfx+"SRBuy");
   g_gbpnzdStopReasonSell  = (int)GlobalVariableGet(pfx+"SRSell");
   // 🆕 v13.48 FIX1: accumulator بازیابی (جایگزین PrevCrisis/Spike)
   g_gbnzdCrisisBuy        = GlobalVariableCheck(pfx+"CrBuy")    ? (int)GlobalVariableGet(pfx+"CrBuy")    : -1;
   g_gbnzdCrisisSell       = GlobalVariableCheck(pfx+"CrSell")   ? (int)GlobalVariableGet(pfx+"CrSell")   : -1;
   g_gbnzdSpikeBuy         = GlobalVariableCheck(pfx+"SpBuy")    ? (int)GlobalVariableGet(pfx+"SpBuy")    : -1;
   g_gbnzdSpikeSell        = GlobalVariableCheck(pfx+"SpSell")   ? (int)GlobalVariableGet(pfx+"SpSell")   : -1;
   g_gbpnzdHourRedBuy    = GlobalVariableCheck(pfx+"HRedBuy")   ? (GlobalVariableGet(pfx+"HRedBuy")   != 0.0) : (g_gbnzdCrisisBuy  == 2);
   g_gbpnzdHourDirtyBuy  = GlobalVariableCheck(pfx+"HDirtyBuy") ? (GlobalVariableGet(pfx+"HDirtyBuy") != 0.0) : (g_gbnzdCrisisBuy  == 2 || g_gbnzdSpikeBuy  >= 1);
   g_gbpnzdHourRedSell   = GlobalVariableCheck(pfx+"HRedSell")  ? (GlobalVariableGet(pfx+"HRedSell")  != 0.0) : (g_gbnzdCrisisSell == 2);
   g_gbpnzdHourDirtySell = GlobalVariableCheck(pfx+"HDirtySell")? (GlobalVariableGet(pfx+"HDirtySell") != 0.0): (g_gbnzdCrisisSell == 2 || g_gbnzdSpikeSell >= 1);

   // ── gap-fill با accumulator ──────────────────────────────────────
   // 🆕 v14.04 FIX-1: به‌جای H1 هاردکد (3600s) از تایم‌فریم چارت استفاده می‌شود.
   // قبلاً: h += 3600 — روی M1 counters خیلی کم، روی H4 خیلی زیاد پر می‌شدند.
   // حالا: قدم = g_chartPeriodSeconds (که پیش از GBPNZD_InitReplay در OnInit ست شده).
   // مرز "الان" هم از iTime(1) گرفته می‌شود (کندل بسته‌ی آخر TF چارت)،
   // نه از wall-clock رند‌شده — تا با Chart_IsNewBarClosed هماهنگ باشد.
   {
      int gapStep = (g_chartPeriodSeconds > 0) ? g_chartPeriodSeconds : 3600;
      // آخرین کندل بسته در TF چارت — همان مرزی که Alert_CheckGBPNZDRule چک می‌کند
      datetime nowBar = iTime(_Symbol, PERIOD_CURRENT, 1);
      if(nowBar == 0) nowBar = (datetime)(((long)TimeCurrent()) / gapStep * gapStep);
      datetime h    = g_gbpnzdLastH + gapStep;
      // حداکثر ۷۲ ساعت معادل (نه ۷۲ کندل ثابت) — جلوگیری از loop بی‌پایان روی M1
      int maxFill = (int)MathMin(72 * 3600 / gapStep, 5184); // سقف مطلق ۵۱۸۴ (M1×72h)
      while(h <= nowBar && maxFill > 0)
      {
         if(g_gbpnzdHourRedBuy)     g_gbpnzdCrisisRedHBuy++;  else g_gbpnzdCrisisRedHBuy = 0;
         if(!g_gbpnzdHourDirtyBuy)  g_gbpnzdCleanHBuy++;      else g_gbpnzdCleanHBuy = 0;
         if(g_gbpnzdHourRedSell)    g_gbpnzdCrisisRedHSell++; else g_gbpnzdCrisisRedHSell = 0;
         if(!g_gbpnzdHourDirtySell) g_gbpnzdCleanHSell++;     else g_gbpnzdCleanHSell = 0;
         g_gbpnzdLastH = h;
         h += gapStep;
         maxFill--;
      }
      g_gbpnzdHourRedBuy    = (g_gbnzdCrisisBuy  == 2);
      g_gbpnzdHourDirtyBuy  = (g_gbnzdCrisisBuy  == 2) || (g_gbnzdSpikeBuy  >= 1);
      g_gbpnzdHourRedSell   = (g_gbnzdCrisisSell == 2);
      g_gbpnzdHourDirtySell = (g_gbnzdCrisisSell == 2) || (g_gbnzdSpikeSell >= 1);
      Print(StringFormat(
         "✅ v14.04 GV_Load gap-fill (step=%ds): Buy CleanH=%d RedH=%d | Sell CleanH=%d RedH=%d",
         gapStep, g_gbpnzdCleanHBuy, g_gbpnzdCrisisRedHBuy,
         g_gbpnzdCleanHSell, g_gbpnzdCrisisRedHSell));
   }

   // worst-case مشترک همگام‌سازی
   g_gbpnzdLevel      = MathMax(g_gbpnzdLevelBuy,    g_gbpnzdLevelSell);
   g_gbpnzdCleanH     = MathMin(g_gbpnzdCleanHBuy,   g_gbpnzdCleanHSell);
   g_gbpnzdCrisisRedH = MathMax(g_gbpnzdCrisisRedHBuy, g_gbpnzdCrisisRedHSell);
   g_gbpnzdStopReason = (g_gbpnzdLevelBuy >= g_gbpnzdLevelSell) ? g_gbpnzdStopReasonBuy : g_gbpnzdStopReasonSell;

   return true;
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.25: GBPNZD_InitReplay
//
// هدف: بازسازی g_gbpnzdCrisisRedH، g_gbpnzdCleanH، g_gbpnzdLevel
//       از 24 کندل H1 گذشته — اجرا یک‌بار در OnInit
//
// منطق:
//   - از کندل 24 ساعت پیش تا کندل 1 ساعت پیش (shift 24 → 1)
//   - برای هر ساعت: worst-case از Buy و Sell محاسبه
//   - counter های CrisisRedH و CleanH بازسازی
//   - ماشین حالت g_gbpnzdLevel همان قانون Alert_CheckGBPNZDRule
//
// 🆕 v13.38: اگه GlobalVariable معتبر موجود باشه، از Replay استفاده نمی‌کنه.
//   GlobalVariable از آخرین اجرای live پر شده → Level واقعی ذخیره‌شده.
//   بعد از لود GV، فقط counter ها از GV_LastH تا الان آپدیت می‌شوند.
//
// بعد از اجرا: g_gbpnzdReplayDone = true
// ════════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════════
// 🆕 v13.50 RULE-01: منطق مشترک Rule — Single Source of Truth
//
// 🔴 مشکل قبلی: ماشین‌حالت Rule (CleanH/CrisisRedH، STOP/CLOSE/RESUME) در
//   سه‌جای مستقل کپی شده بود — Alert_CheckGBPNZDRule() (لایو)،
//   GBPNZD_InitReplay() (بازسازی state بعد از ری‌استارت)، و
//   LogHourlySnapshot() (بکتست). هر فیکس باید در هر سه‌جا دستی اعمال
//   می‌شد؛ ریشه‌ی تمام باگ‌های واگرایی v13.39–v13.49 همین بود.
//
// ✅ راه‌حل: منطق به دو تابع مشترک تقسیم شد (نه یکی، عمداً):
//   • Rule_UpdateCounters(): فقط شمارنده‌های ساعتی (crisisRedH/cleanH) را
//     آپدیت می‌کند — در لایو فقط سر مرز ساعت صدا زده می‌شود، در Replay و
//     بکتست هر «ساعت» معادل یک صدازدن است.
//   • Rule_Transition(): ماشین‌حالت سه‌سطحی GREEN(0)→STOP(1)→CLOSE(2)،
//     مستقل از مرز ساعت — در لایو هر تیک صدا زده می‌شود (چون STOP باید
//     فوری واکنش نشون بده، نه فقط سر مرز ساعت)، در Replay/بکتست هر
//     iteration یک‌بار صدا زده می‌شود.
//   این تفکیک عمداً است: اگر این دو در یک تابع واحد ادغام می‌شدند، مسیر
//   لایو مجبور می‌شد یا state را فقط سر مرز ساعت آپدیت کند (تأخیر در STOP)
//   یا شمارنده‌ها را هر تیک آپدیت کند (رفتار قدیمی را می‌شکست). این دو
//   تابع دقیقاً همان توالی و شرط‌های سه پیاده‌سازی قبلی را حفظ می‌کنند —
//   فقط دیگر در سه‌جا کپی نشده‌اند.
// ════════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════════
// 🆕 v14.00: هسته تعمیم چند سمبلی — GBPNZD / EURGBP / AUDCAD
//
// چرا: قبلاً کل ماشین‌حالت Rule/Replay فقط با StringFind(_Symbol,"GBPNZD")
// قفل بود؛ روی چارت AUDCAD/EURGBP (لایو یا بکتست) اصلاً اجرا نمی‌شد.
// همچنین چند نقطه (Flow در Replay/Spike/no-position/hedge) به‌جای دیدن
// سمبل چارت، همیشه SISTER_GBPNZD را هاردکد صدا می‌زدند — یعنی حتی اگر
// قفل بالا برداشته می‌شد، روی AUDCAD/EURGBP عدد Flow اشتباه (یا صفر)
// تولید می‌شد. این بخش، سه نقطه تزریق را جایگزین می‌کند:
//   1) IsRuleSymbol(): آیا این سمبل یکی از سه سمبل تحت پوشش Rule هست؟
//   2) Sister_GetTable(): جدول Sister درست را برای سمبل برمی‌گرداند
//   3) Rule_FlowForSymbol(): اسکور Flow لحظه‌ای با جدول درست سمبل
// نکته مهم: برای GBPNZD خروجی این توابع دقیقاً همان چیزیست که قبلاً
// هاردکد بود — یعنی صفر تغییر رفتار برای GBPNZD (صفر ریسک رگرسیون).
// ════════════════════════════════════════════════════════════════════
string CleanSymbol(string sym)
{
   string s = sym;
   StringReplace(s, "_l", "");
   StringReplace(s, "_m", "");
   StringReplace(s, ".raw", "");
   StringReplace(s, ".a", "");
   if(StringLen(s) > 6) s = StringSubstr(s, 0, 6);
   return s;
}

bool IsRuleSymbol(string sym)
{
   string c = CleanSymbol(sym);
   return (c == "GBPNZD" || c == "EURGBP" || c == "AUDCAD");
}

// جدول Sister درست را برحسب سمبل در outArr کپی می‌کند و تعداد را برمی‌گرداند.
// 🩹 v14.01 (Team Patch بخش ۳): پیش‌فرض (سمبل ناشناخته) از GBPNZD به AUDCAD
// تغییر کرد تا با بقیه‌ی سیستم (Crisis_GetThresholds، وزن‌دهی Calc_SpikeDetector
// که پایه/پیش‌فرض=AUDCAD و override فقط برای GBPNZD دارند) یکدست باشد.
// برای GBPNZD/EURGBP/AUDCAD (سه سمبلی که همین الان پشتیبانی می‌شوند) این تغییر
// هیچ رفتاری را عوض نمی‌کند چون هر سه شاخه صریح دارند و همیشه یکی از آن‌ها می‌خورد؛
// فقط برای یکدستی/سمبل ناشناخته‌ی احتمالی آینده است.
// 🩹 v14.02 FIX (خطای کامپایل): built-in ArrayCopy() آرایه‌ای از struct که
// عضو string دارد (SisterEntry.sym) را قبول نمی‌کند — پیام کامپایلر:
// "structures or classes containing objects are not allowed". به‌جایش
// این تابع کمکی عنصر‌به‌عنصر کپی می‌کند (بدون تغییر در نتیجه/رفتار).
void Sister_CopyArr(SisterEntry &dst[], const SisterEntry &src[])
{
   int n = ArraySize(src);
   ArrayResize(dst, n);
   for(int i = 0; i < n; i++)
   {
      dst[i].sym        = src[i].sym;
      dst[i].weight      = src[i].weight;
      dst[i].signForBuy = src[i].signForBuy;
      dst[i].negMult     = src[i].negMult;
   }
}

int Sister_GetTable(string sym, SisterEntry &outArr[])
{
   string c = CleanSymbol(sym);
   if(c == "GBPNZD") { Sister_CopyArr(outArr, SISTER_GBPNZD); return ArraySize(outArr); }
   if(c == "EURGBP") { Sister_CopyArr(outArr, SISTER_EURGBP); return ArraySize(outArr); }
   Sister_CopyArr(outArr, SISTER_AUDCAD);   // پیش‌فرض/پایه
   return ArraySize(outArr);
}

// جایگزین امن الگوی هاردکد: FlowEvaluate(SISTER_GBPNZD, ArraySize(SISTER_GBPNZD), forBuy)
double Rule_FlowForSymbol(string sym, bool forBuy)
{
   SisterEntry arr[];
   int n = Sister_GetTable(sym, arr);
   return FlowEvaluate(arr, n, forBuy);
}

// وزن‌دهی Spike بر حسب سمبل — دقیقاً همان شرط استفاده‌شده در Calc_SpikeDetector
// (خط ~7309) را برای همگام بودن Replay/بکتست با لایو تکرار می‌کند.
void Rule_SpikeWeightsForSymbol(string sym, double &wM15, double &wM30, double &wH1, double &wH4, double &wD1)
{
   if(CleanSymbol(sym) == "GBPNZD")
   {
      wM15 = 0.25; wM30 = 0.20; wH1 = 0.30; wH4 = 0.15; wD1 = 0.10;
   }
   else if(CleanSymbol(sym) == "EURGBP")
   {
      // 🆕 v14.07 PATCH-D1: وزن‌های اختصاصی EURGBP برای Spike
      // ⚠️ موقت — باید بعد از بکتست EURGBP 2024-2026 کالیبره شوند.
      // فعلاً بین GBPNZD و AUDCAD — H1 کمی بیشتر، M15 کمتر
      wM15 = 0.10; wM30 = 0.15; wH1 = 0.35; wH4 = 0.25; wD1 = 0.15;
   }
   else
   {
      // AUDCAD و پیش‌فرض
      wM15 = 0.15; wM30 = 0.15; wH1 = 0.30; wH4 = 0.25; wD1 = 0.15;
   }
}

// پیشوند کلید GlobalVariable برحسب سمبل — برای GBPNZD دقیقاً همان پیشوند
// قدیمی "HM_GBNZD_" حفظ می‌شود تا state ذخیره‌شده کاربرهای فعلی روی
// ری‌استارت از دست نرود. برای AUDCAD/EURGBP پیشوند جدید و جدا ساخته می‌شود.
string Rule_GVPrefix(string sym)
{
   string c = CleanSymbol(sym);
   if(c == "GBPNZD") return "HM_GBNZD_";
   return "HM_" + c + "_";
}

//+------------------------------------------------------------------+
//| 🆕 v14.03: تشخیص بسته‌شدن کندل جدید در تایم‌فریم چارت          |
//| مقدار برمی‌گرداند: true فقط یک بار در اولین تیک بعد از بسته‌شدن |
//| این تابع تنها قرارگاه تصمیم «آیا کندل جدیدی بسته شده؟» است.    |
//+------------------------------------------------------------------+
bool Chart_IsNewBarClosed()
{
   // ✅ PATCH-2 v14.05: از shift=1 (کندل کاملاً بسته) نه shift=0 (کندل جاری باز)
   // این از race condition جلوگیری می‌کند: در اولین تیک بعد از بسته‌شدن کندل،
   // iTime(0) زمان کندل جدید (ناقص) است — iTime(1) همیشه آخرین کندل بسته است.
   // با shift=1 هماهنگ است (Spike_TFScore در v14.03 FIX-A).
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 1);
   if(barTime <= 0) return false;
   if(barTime > g_lastBarCloseTime)
   {
      g_lastBarCloseTime = barTime; // ثبت فوری قبل از هر return
      return true;
   }
   return false;
}

void Rule_UpdateCounters(bool hourRed, bool hourDirty, int &crisisRedH, int &cleanH)
{
   if(hourRed)     crisisRedH++; else crisisRedH = 0;
   if(!hourDirty)  cleanH++;     else cleanH = 0;
}

void Rule_Transition(int crisis, int spike, bool haFlag, int crisisRedH, int cleanH,
                      int &level, int &reason)
{
   // 🆕 v14.08 BUG-TF1 FIX: آستانه‌ها از global TF-aware vars (در OnInit scale می‌شوند)
   // H1: g_ruleCloseBars=6, g_ruleResumeBars=24 — دقیقاً مثل قبل (صفر رگرسیون)
   // M1: g_ruleCloseBars=360, g_ruleResumeBars=1440
   // H4: g_ruleCloseBars=2, g_ruleResumeBars=6 (MathMax(1,...) گارانتی حداقل 1)
   bool _stopA  = (spike == 2) && (crisis >= 1);
   bool _stopB  = (spike == 1) && (crisis == 2 || crisis == 3);
   bool _closeA = (crisis == 2) && haFlag;
   bool _closeB = (crisisRedH >= g_ruleCloseBars);
   bool _resume = (cleanH >= g_ruleResumeBars);

   if(level == 0)
   {
      if(_closeA || _closeB)    { level = 2; reason = _closeA ? 10 : 11; }
      else if(_stopA || _stopB) { level = 1; reason = _stopA  ?  0 :  1; }
   }
   else if(level == 1)
   {
      if(_closeA || _closeB)    { level = 2; reason = _closeA ? 10 : 11; }
      else if(_resume)          { level = 0; reason = -1; }
   }
   else if(level == 2)
   {
      if(_resume)               { level = 0; reason = -1; }
   }
}

void GBPNZD_InitReplay()
{
   if(!IsRuleSymbol(_Symbol)) return;
   if((bool)MQLInfoInteger(MQL_TESTER)) return;

   // صبر کن handle ها warm شده باشن
   if(handleEMA200_H1_TL == INVALID_HANDLE ||
      handleATR_H1_TL    == INVALID_HANDLE ||
      handleADX_H4_TL    == INVALID_HANDLE ||
      handleATR_D1_TL    == INVALID_HANDLE) return;

   if(BarsCalculated(handleEMA200_H1_TL) < 290) return;  // 🐛 v13.30 FIX4: 220→290 (72h replay)
   if(BarsCalculated(handleADX_H4_TL)    < 25)  return;
   //
   // 🔒 DESIGN LOCK (v14.07 PATCH-B2): Handle های زیر عمداً ثابت هستند (H1/H4/D1).
   // تغییر ندهید حتی اگه TF چارت متفاوت باشد.
   // دلیل: این TF ها از بکتست واقعی GBPNZD کالیبره شده‌اند.
   // تنها تغییر مجاز در این تابع: تعداد iteration های loop (barsToScan).
   //   handleEMA200_H1_TL, handleATR_H1_TL → PERIOD_H1
   //   handleADX_H4_TL                     → PERIOD_H4
   //   handleATR_D1_TL                     → PERIOD_D1

   // ── 🆕 v13.38: اول سعی کن از GlobalVariable لود کن ──────────────
   // اگه GlobalVariable معتبر موجود باشه (< 72h)، Level واقعی live
   // ذخیره شده — از Replay کامل بپرهیز چون Replay نمی‌تونه STOP های
   // داخل کندل (نه کندل بسته) رو ببینه.
   // 🐛 v13.41 FIX: اگه GV لود شد ولی هر دو Level=0 بودن، ممکنه GV
   // از نسخه قدیمی‌تر باشه که LvSell/Buy رو ذخیره نمی‌کرد (مثل v13.35).
   // در این حالت Replay هم اجرا میشه تا state واقعی بازسازی بشه.
   // اگه Replay نتیجه بهتری داشت (Level>0)، از آن استفاده میشه.
   // 🩹 PATCH v13.51: قبلاً شرط اضافه‌ی (Level>0) اینجا بود تا GV قدیمی
   // (نسخه‌های قبل از v13.38 که LvBuy/LvSell ذخیره نمی‌شد) تشخیص داده بشه.
   // مشکل: یک GV معتبر و جدید که واقعاً GREEN(0) است هم با همین شرط دور
   // ریخته می‌شد و InitReplay به Replay کور از کندل‌های بسته برمی‌گشت —
   // دقیقاً همون کوری intra-candle که این مکانیزم GV قرار بود حلش کنه.
   // حالا GBPNZD_GV_Load() خودش با کلید HM_GBNZD_Ver تشخیص GV قدیمی/جدید
   // رو می‌ده، پس اینجا کافیه فقط gvLoaded چک بشه.
   bool gvLoaded = GBPNZD_GV_Load();
   if(gvLoaded)
   {
      // GV معتبر (و versioned) با state واقعی — از Replay بپرهیز
      g_gbpnzdPrevCrisisBuy  = g_gbnzdCrisisBuy;
      g_gbpnzdPrevSpikeBuy   = g_gbnzdSpikeBuy;
      g_gbpnzdPrevCrisisSell = g_gbnzdCrisisSell;
      g_gbpnzdPrevSpikeSell  = g_gbnzdSpikeSell;
      g_gbpnzdReplayDone = true;
      Print(StringFormat(
         "✅ v13.51 GBPNZD state loaded from GlobalVariable (versioned) — Buy=%s CleanH=%d | Sell=%s CleanH=%d",
         g_gbpnzdLevelBuy  == 0 ? "GREEN" : g_gbpnzdLevelBuy  == 1 ? "STOP" : "CLOSE", g_gbpnzdCleanHBuy,
         g_gbpnzdLevelSell == 0 ? "GREEN" : g_gbpnzdLevelSell == 1 ? "STOP" : "CLOSE", g_gbpnzdCleanHSell));
      return;
   }
   // GV موجود نبود یا نسخه قدیمی (بدون HM_GBNZD_Ver) بود → Replay کامل اجرا میشه

   // ── ریست counter ها قبل از replay ───────────────────────────
   g_gbpnzdCrisisRedHBuy  = 0;
   g_gbpnzdCrisisRedHSell = 0;
   g_gbpnzdCleanHBuy      = 0;
   g_gbpnzdCleanHSell     = 0;
   g_gbpnzdLevelBuy       = 0;
   g_gbpnzdLevelSell      = 0;
   g_gbpnzdStopReasonBuy  = -1;
   g_gbpnzdStopReasonSell = -1;
   // متغیرهای مشترک (worst-case) هم ریست
   g_gbpnzdCrisisRedH = 0;
   g_gbpnzdCleanH     = 0;
   g_gbpnzdLevel      = 0;
   g_gbpnzdStopReason = -1;

   // ── loop از کهنه‌ترین به جدیدترین ──────────────────────────
   // 🐛 v13.30 FIX4: پنجره Replay از 24h به 72h افزایش یافت.
   // 🔴 v14.06 BUG-C1 FIX: تعداد کندل‌ها بر اساس TF چارت محاسبه می‌شود.
   //   قبلاً: for(sh=72; sh>=1) — همیشه ۷۲ شیفت، یعنی ۷۲ ساعت اما فقط برای H1.
   //   روی M1: live هر دقیقه counter++ می‌زند، Replay فقط ۷۲ بار → مقیاس x60 اشتباه.
   //   روی H4: live هر ۴ ساعت، Replay ۷۲ بار → ~۴x بیشتر از واقع.
   //   حالا: پنجره ثابت ۷۲ ساعت (= ۲۵۹۲۰۰ ثانیه)، تعداد کندل از TF چارت.
   //   H1: 259200/3600 = ۷۲ — کاملاً یکسان با قبل.
   //   M1: 259200/60   = ۴۳۲۰ — ۴۳۲۰ کندل M1 = ۷۲ ساعت.
   //   H4: 259200/14400= ۱۸  — ۱۸ کندل H4 = ۷۲ ساعت.
   //   توجه مهم: handle های Crisis/Spike (H1، H4، D1) تغییر نکرده‌اند —
   //   فقط تعداد iteration ها تغییر کرد. GBPNZD_Replay_CrisisAtBar همچنان
   //   از handleEMA200_H1_TL و PERIOD_H1 استفاده می‌کند (طبق طراحی — این
   //   تایم‌فریم‌ها از قبل کالیبره شده‌اند). تغییر فقط این است که هر iteration
   //   یک «کندل چارت» معادل دارد نه یک «ساعت H1».
   int _replayPeriodSec  = (g_chartPeriodSeconds > 0) ? g_chartPeriodSeconds : 3600;
   int _replayBarsToScan = (int)MathMax(1, 259200 / _replayPeriodSec); // ۷۲ ساعت
   // برای H1: ۷۲ — دقیقاً مثل قبل
   // shift=1 = آخرین کندل چارت بسته‌شده (معادل H1 shift برای GBPNZD_Replay_CrisisAtBar)
   // 🆕 v13.48 FIX1: accumulator در Replay — مثل Alert_CheckGBPNZDRule
   // هر کندل accumulator از کندل جاری OR می‌شه، در مرز کندل counter آپدیت
   int prevCrBuy  = -1, prevCrSell  = -1;
   int prevSpBuy  = -1, prevSpSell  = -1;
   int prevRcBuy  =  0, prevRcSell  =  0;
   bool rHourRedBuy = false, rHourDirtyBuy = false;
   bool rHourRedSell= false, rHourDirtySell= false;

   for(int sh = _replayBarsToScan; sh >= 1; sh--)
   {
      // Crisis برای هر دو جهت
      int rcBuy = 0, rcSell = 0;
      int crBuy  = GBPNZD_Replay_CrisisAtBar(sh, true,  rcBuy);
      int crSell = GBPNZD_Replay_CrisisAtBar(sh, false, rcSell);
      int worstCrisis = MathMax(crBuy, crSell);
      int worstRC     = MathMax(rcBuy, rcSell);  // 🆕 v13.35: برای wasClean

      // 🐛 v13.26 FIX4: Spike جداگانه برای Buy و Sell
      int replaySpikeBuy = -1, replaySpikeSell = -1;
      GBPNZD_Replay_SpikeAtBar(sh, replaySpikeBuy, replaySpikeSell);
      int spikeBuy  = (replaySpikeBuy  >= 0) ? replaySpikeBuy  : 0;
      int spikeSell = (replaySpikeSell >= 0) ? replaySpikeSell : 0;
      int worstSpike = MathMax(spikeBuy, spikeSell);

      // HighAlert برای هر جهت — از ADX H4 و Flow در آن ساعت
      // تقریب: از g_lastAdxVal فعلی استفاده نمی‌کنیم، ADX تاریخی رو می‌خونیم
      int h4Shift = sh / 4;
      double adxHist = 0.0;
      if(handleADX_H4_TL != INVALID_HANDLE && BarsCalculated(handleADX_H4_TL) > h4Shift + 2)
      {
         double adxB[]; ArraySetAsSeries(adxB, true);
         if(CopyBuffer(handleADX_H4_TL, 0, h4Shift + 1, 1, adxB) == 1)
            adxHist = adxB[0];
      }

      // Flow تاریخی برای HighAlert — 🐛 v14.00 FIX: جدول Sister بر حسب سمبل
      double fsBuyHist = 0.0, fsSellHist = 0.0;
      SisterEntry hrArr[];
      int hrN = Sister_GetTable(_Symbol, hrArr);
      for(int si = 0; si < hrN; si++)
      {
         string sym = FlowFindSym(hrArr[si].sym);
         if(Bars(sym, PERIOD_H4) < h4Shift + 8) continue;
         double c1 = iClose(sym, PERIOD_H4, h4Shift + 1);
         double c6 = iClose(sym, PERIOD_H4, h4Shift + 6);
         if(c1 <= 0.0 || c6 <= 0.0) continue;
         double dir = (c1 > c6) ? 1.0 : (c1 < c6) ? -1.0 : 0.0;
         if(dir == 0.0) continue;
         double rawB = hrArr[si].signForBuy  * dir;
         double rawS = -hrArr[si].signForBuy * dir;
         fsBuyHist  += rawB * hrArr[si].weight * ((rawB < 0) ? hrArr[si].negMult : 1.0);
         fsSellHist += rawS * hrArr[si].weight * ((rawS < 0) ? hrArr[si].negMult : 1.0);
      }

      bool haBuy  = (adxHist >= 35.0) && (fsBuyHist  < -7.0);
      bool haSell = (adxHist >= 35.0) && (fsSellHist >  7.0);
      bool highAlertHist = haBuy || haSell;

      // ── بازسازی counter جهت‌دار — 🐛 v13.36 FIX ──────────────
      // قبلاً worst-case مشترک بود → اگه فقط Sell Spike می‌خورد، Buy هم STOP می‌شد

      // ── BUY ─────────────────────────────────────────────────
      // 🆕 v13.48 FIX1: accumulator در Replay
      if(crBuy  == 2)                    rHourRedBuy   = true;
      if(crBuy  == 2 || spikeBuy  >= 1)  rHourDirtyBuy = true;

      // 🆕 v13.50 RULE-01: منطق مشترک — به‌جای کپی مستقل، از Rule_UpdateCounters/Rule_Transition
      Rule_UpdateCounters(rHourRedBuy, rHourDirtyBuy, g_gbpnzdCrisisRedHBuy, g_gbpnzdCleanHBuy);
      // seed برای ساعت بعد
      rHourRedBuy   = (crBuy == 2);
      rHourDirtyBuy = (crBuy == 2) || (spikeBuy >= 1);

      Rule_Transition(crBuy, spikeBuy, haBuy, g_gbpnzdCrisisRedHBuy, g_gbpnzdCleanHBuy,
                       g_gbpnzdLevelBuy, g_gbpnzdStopReasonBuy);

      // ── SELL ─────────────────────────────────────────────────
      // 🐛 v13.44 FIX3: همان منطق prev برای SELL
      // 🐛 v13.45 FIX-A: همان حذف rc<2 برای SELL (نگاه کن به کامنت بالای BUY)
      // 🆕 v13.48 FIX1: accumulator SELL در Replay
      if(crSell  == 2)                    rHourRedSell   = true;
      if(crSell  == 2 || spikeSell >= 1)  rHourDirtySell = true;

      // 🆕 v13.50 RULE-01: منطق مشترک — به‌جای کپی مستقل
      Rule_UpdateCounters(rHourRedSell, rHourDirtySell, g_gbpnzdCrisisRedHSell, g_gbpnzdCleanHSell);
      rHourRedSell   = (crSell == 2);
      rHourDirtySell = (crSell == 2) || (spikeSell >= 1);

      Rule_Transition(crSell, spikeSell, haSell, g_gbpnzdCrisisRedHSell, g_gbpnzdCleanHSell,
                       g_gbpnzdLevelSell, g_gbpnzdStopReasonSell);

      // ── worst-case مشترک (برای سازگاری با کدهای دیگر) ──────
      g_gbpnzdLevel      = MathMax(g_gbpnzdLevelBuy, g_gbpnzdLevelSell);
      g_gbpnzdCrisisRedH = MathMax(g_gbpnzdCrisisRedHBuy, g_gbpnzdCrisisRedHSell);
      g_gbpnzdCleanH     = MathMin(g_gbpnzdCleanHBuy, g_gbpnzdCleanHSell);

         // 🆕 v13.48: accumulator در انتهای loop به روز شد (بالا)
   }
   // seed accumulator ساعت جاری (نیمه‌کاره) با آخرین ساعت Replay
   g_gbpnzdHourRedBuy    = rHourRedBuy;
   g_gbpnzdHourDirtyBuy  = rHourDirtyBuy;
   g_gbpnzdHourRedSell   = rHourRedSell;
   g_gbpnzdHourDirtySell = rHourDirtySell;

   // 🆕 v13.49 P3 (اختیاری): Replay فقط کندل‌های کاملاً بسته رو می‌بینه —
   // اگه Crisis وسط کندل جاری در حال شکل‌گیری رخ داده باشه، فایل snapshot
   // (که با ری‌استارت کامل MT5 هم پاک نمی‌شه) اون رو داره. اگه فایل مربوط
   // به همین کندل جاری باشه، اطلاعاتش رو OR کن تا کوری موقت Replay جبران بشه.
   // 🆕 v14.04 FIX-2: مرز کندل چارت (نه H1 هاردکد) — باید با SaveHourStateFile هماهنگ باشد.
   {
      int      gapStep       = (g_chartPeriodSeconds > 0) ? g_chartPeriodSeconds : 3600;
      datetime curFormingBar = (datetime)(((long)TimeCurrent()) / gapStep * gapStep);
      datetime fHour; bool fRedBuy, fDirtyBuy, fRedSell, fDirtySell;
      if(GBPNZD_LoadHourStateFile(fHour, fRedBuy, fDirtyBuy, fRedSell, fDirtySell) && fHour == curFormingBar)
      {
         g_gbpnzdHourRedBuy    = g_gbpnzdHourRedBuy    || fRedBuy;
         g_gbpnzdHourDirtyBuy  = g_gbpnzdHourDirtyBuy  || fDirtyBuy;
         g_gbpnzdHourRedSell   = g_gbpnzdHourRedSell   || fRedSell;
         g_gbpnzdHourDirtySell = g_gbpnzdHourDirtySell || fDirtySell;
         if(ShowDebugLogs)
            Print("ℹ️ v14.04 P3: bar-state snapshot فایلی برای کندل جاری (step=", gapStep, "s) اعمال شد.");
      }
   }

   // ── g_gbpnzdLastH به آخرین کندل پردازش‌شده (تایم‌فریم چارت) تنظیم بشه ──────
   // 🆕 v14.03: به‌جای H1 هاردکد از PERIOD_CURRENT استفاده می‌شود
   // این تضمین می‌کند که اولین Alert_CheckGBPNZDRule بعد از init
   // از صحیح‌ترین مرز کندل استفاده می‌کند
   g_gbpnzdLastH = iTime(_Symbol, PERIOD_CURRENT, 1);

   // 🆕 v13.37: prevSnapshot را با وضعیت لحظه Replay init کن
   // این تضمین می‌کنه اولین counter ساعتی از مقدار درست بخونه
   g_gbpnzdPrevCrisisBuy  = g_gbnzdCrisisBuy;
   g_gbpnzdPrevSpikeBuy   = g_gbnzdSpikeBuy;
   g_gbpnzdPrevCrisisSell = g_gbnzdCrisisSell;
   g_gbpnzdPrevSpikeSell  = g_gbnzdSpikeSell;

   g_gbpnzdReplayDone = true;

   // 🐛 v13.41 FIX: بعد از Replay، فوری در GV ذخیره کن
   // اگه قبلاً GV از نسخه قدیمی (مثل v13.35) با Level=0 بود،
   // حالا state درست Replay در GV نوشته میشه.
   // ری‌استارت بعدی از این state درست لود میکنه.
   GBPNZD_GV_Save();

   Print(StringFormat(
      "✅ v13.41 GBPNZD_InitReplay done (full Replay) — Buy=%s CleanH=%d | Sell=%s CleanH=%d",
      g_gbpnzdLevelBuy  == 0 ? "GREEN" : g_gbpnzdLevelBuy  == 1 ? "STOP" : "CLOSE", g_gbpnzdCleanHBuy,
      g_gbpnzdLevelSell == 0 ? "GREEN" : g_gbpnzdLevelSell == 1 ? "STOP" : "CLOSE", g_gbpnzdCleanHSell));
}

// CLOSE trigger A: CRISIS=🔴 AND HighAlert فعال (ADX≥35 + |Flow|>7)
// CLOSE trigger B: CRISIS=🔴 برای ≥6 ساعت متوالی
// RESUME:          CRISIS=سبز/زرد AND Spike=Normal برای ≥24 ساعت متوالی
//
// اعلان فقط در لحظه تغییر سطح ارسال می‌شه (edge-only)
// Counter ها هر ساعت یک‌بار به‌روز می‌شن
// 🆕 v13.38: State در GlobalVariable ذخیره می‌شه — با ری‌استارت EA بازیابی می‌شه
// State فقط با ری‌استارت MT5 ریست می‌شه (GlobalVariable پاک می‌شه)
// ════════════════════════════════════════════════════════════════════
void Alert_CheckGBPNZDRule()
{
   // ── پیش‌شرط‌ها ──────────────────────────────────────────────────────
   if(!Alert_OnGBPNZDRule)                return;
   if((bool)MQLInfoInteger(MQL_TESTER))   return;
   if(!IsRuleSymbol(_Symbol))             return;

   // ── 🆕 v13.48 FIX1: accumulator — worst-case ساعت جاری OR می‌شه ───────
   // هر تیک: اگه Crisis=Red یا Spike>=Warning → accumulator روشن می‌شه (OR)
   // مرز ساعت: counter از accumulator → ریست → seed با وضعیت جدید
   // این رویکرد "چه وقت Prev آپدیت شه؟" را کاملاً حذف می‌کند
   if(g_gbnzdCrisisBuy  == 2) g_gbpnzdHourRedBuy   = true;
   if(g_gbnzdCrisisBuy  == 2 || g_gbnzdSpikeBuy  >= 1) g_gbpnzdHourDirtyBuy  = true;
   if(g_gbnzdCrisisSell == 2) g_gbpnzdHourRedSell  = true;
   if(g_gbnzdCrisisSell == 2 || g_gbnzdSpikeSell >= 1) g_gbpnzdHourDirtySell = true;

   // 🆕 v13.49 P3 (اختیاری): اگه حداقل یکی از چراغ‌ها Red/Dirty شد، در فایل
   // snapshot ذخیره کن — بر خلاف GV، این فایل با ری‌استارت کامل MT5 پاک نمی‌شه
   if(g_gbpnzdHourRedBuy || g_gbpnzdHourDirtyBuy || g_gbpnzdHourRedSell || g_gbpnzdHourDirtySell)
      GBPNZD_SaveHourStateFile();

   // 🆕 v14.03: جایگزینی چک ساعتی H1 با چک کندل-محور (تایم‌فریم چارت)
   // -------------------------------------------------------------------
   // v14.02 و قبل: accumulator هر ساعت H1 (هاردکد) تخلیه می‌شد.
   //               این با بکتست که روی کندل‌های بسته کار می‌کرد ناهمخوان بود.
   // v14.03: accumulator با هر کندل بسته در تایم‌فریم چارت تخلیه می‌شود.
   //         اگه اکسپرت روی H1 باشد → هر ساعت. اگه M1 باشد → هر دقیقه.
   //
   // محافظت آخر هفته (از v13.49) حفظ شده: بازار بی‌داده → skip.
   // این تضمین می‌کند که CleanH مصنوعی در طول تعطیلی اضافه نشود.
   // -------------------------------------------------------------------
   datetime lastQuoteTime     = (datetime)SymbolInfoInteger(_Symbol, SYMBOL_TIME);
   // ✅ PATCH-7 v14.05: آستانه پویا — حداقل ۲ ساعت، حداکثر ۳ کندل چارت
   // M1: max(7200, 180)   = 7200s (۲ ساعت — منطقی)
   // H4: max(7200, 43200) = 43200s (۱۲ ساعت — برای H4 منطقی‌تر)
   // قبلاً: ۷۲۰۰ ثابت = برای H4 نیمی از کندل بود و skip نمی‌کرد
   //
   // 🗒 v14.06 BUG-M2 (مستندسازی — نه باگ): PATCH-7 و P2 (v13.49) مکمل هم هستند:
   //   • P2 (SYMBOL_TIME check): تشخیص می‌دهد که آیا بازار اصلاً داده دارد (بی‌داده = آخر هفته).
   //   • PATCH-7: آستانه زمانی را تنظیم می‌کند که چه مدت بی‌داده بودن = «stale» تلقی شود.
   //   تعامل: اگر هر دو true باشند (بازار بی‌داده + از آستانه گذشته)، barBoundaryReached=false
   //   → counter آپدیت نمی‌شود. double-skip: ممکن نیست چون barBoundaryReached gate واحد است
   //   و هر دو شرط (lastBarClose > lastH) AND (NOT stale) باید true باشند.
   int      _weekendStaleThreshold = (int)MathMax(2 * 3600, 3 * g_chartPeriodSeconds);
   bool     gbpnzdMarketStale = (lastQuoteTime > 0) && ((TimeCurrent() - lastQuoteTime) > _weekendStaleThreshold);

   // مرز کندل: از g_lastBarCloseTime که در Chart_IsNewBarClosed آپدیت شده
   // این تابع (Alert_CheckGBPNZDRule) فقط از TL_Update صدا زده می‌شود،
   // و TL_Update در لایو فقط از CSL_Execute (که روی isNewBar است) صدا زده می‌شود.
   // پس هر فراخوانی = یک کندل تازه بسته شده.
   // با این حال برای ایمنی (فراخوانی‌های فوری تغییر پوزیشن) از g_gbpnzdLastH
   // به‌عنوان gate استفاده می‌کنیم تا دوبار شمارش نشود.
   bool barBoundaryReached = (g_gbpnzdLastH > 0) &&
                              (g_lastBarCloseTime > g_gbpnzdLastH) &&
                              !gbpnzdMarketStale;

   if(barBoundaryReached)
   {
      // 🆕 v14.03 + v13.50 RULE-01: شمارنده با هر کندل بسته آپدیت می‌شود
      Rule_UpdateCounters(g_gbpnzdHourRedBuy,  g_gbpnzdHourDirtyBuy,  g_gbpnzdCrisisRedHBuy,  g_gbpnzdCleanHBuy);
      Rule_UpdateCounters(g_gbpnzdHourRedSell, g_gbpnzdHourDirtySell, g_gbpnzdCrisisRedHSell, g_gbpnzdCleanHSell);
      g_gbpnzdCrisisRedH = MathMax(g_gbpnzdCrisisRedHBuy, g_gbpnzdCrisisRedHSell);
      g_gbpnzdCleanH     = MathMin(g_gbpnzdCleanHBuy,     g_gbpnzdCleanHSell);
   }
   if(g_lastBarCloseTime > g_gbpnzdLastH && !gbpnzdMarketStale)
   {
      // شروع کندل جدید: seed accumulator با وضعیت اولین تیک کندل جدید
      g_gbpnzdHourRedBuy    = (g_gbnzdCrisisBuy  == 2);
      g_gbpnzdHourDirtyBuy  = (g_gbnzdCrisisBuy  == 2) || (g_gbnzdSpikeBuy  >= 1);
      g_gbpnzdHourRedSell   = (g_gbnzdCrisisSell == 2);
      g_gbpnzdHourDirtySell = (g_gbnzdCrisisSell == 2) || (g_gbnzdSpikeSell >= 1);
      // 🆕 v14.03: به‌جای thisHour (مرز H1) از g_lastBarCloseTime (مرز چارت) استفاده می‌شود
      g_gbpnzdLastH = g_lastBarCloseTime;
      // v13.38: بعد از آپدیت کندلی، state در GV ذخیره می‌شود
      GBPNZD_GV_Save();
   }
   else if(gbpnzdMarketStale && ShowDebugLogs && g_lastBarCloseTime > g_gbpnzdLastH)
   {
      Print("ℹ️ v14.03: بازار بی‌داده (آخر هفته) — مرز کندل skip شد. lastQuote=",
            TimeToString(lastQuoteTime), " gap=", (long)(TimeCurrent() - lastQuoteTime), "s");
   }

   // HighAlert جهت‌دار
   bool haBuy  = (g_gbnzdAdxBuy  >= 35.0) && (g_gbnzdFlowBuy  < -7.0);
   bool haSell = (g_gbnzdAdxSell >= 35.0) && (g_gbnzdFlowSell >  7.0);

   // ── ماشین حالت BUY ────────────────────────────────────────────────
   // 🆕 v13.50 RULE-01: منطق مشترک — به‌جای کپی مستقل از Rule_Transition استفاده می‌شود
   // 🗒 v14.06 BUG-M1 (مستندسازی — نه باگ): Rule_Transition هر تیک فراخوانی می‌شود
   // ولی crisisRedH/cleanH فقط سر هر کندل بسته آپدیت می‌شوند (barBoundaryReached بالا).
   // این عمدی است: برای STOP فوری (Spike جدید وسط کندل)، ماشین‌حالت باید هر تیک
   // واکنش دهد. بین دو کندل، counter ها ثابت‌اند — فقط crisis/spike جاری (تیک-محور)
   // تغییر می‌کنند. شرط STOP نیاز به crisis/spike تیک‌جاری دارد نه counter تاریخی.
   //
   // 🔒 DESIGN LOCK (v14.08 BUG-SPIKE1): Rule_Transition عمداً هر تیک صدا زده می‌شود.
   // تغییر ندهید. دو منطق عمداً جدا هستند:
   //   (۱) Rule_UpdateCounters → فقط سر کندل (barBoundaryReached) — شمارش تاریخی
   //   (۲) Rule_Transition     → هر تیک — واکنش فوری به Spike جدید وسط کندل
   // روی M1: چک هر تیک بدون هزینه معنادار (transition فقط اگه Spike تغییر کند عمل می‌کند).
   // روی H4: تیک‌های کم مشکلی ایجاد نمی‌کنند چون counter ها بین تیک‌ها ثابت‌اند.
   int oldLevelBuy  = g_gbpnzdLevelBuy;
   int newLevelBuy  = oldLevelBuy;
   int newReasonBuy = g_gbpnzdStopReasonBuy;
   Rule_Transition(g_gbnzdCrisisBuy, g_gbnzdSpikeBuy, haBuy,
                    g_gbpnzdCrisisRedHBuy, g_gbpnzdCleanHBuy,
                    newLevelBuy, newReasonBuy);

   // ── ماشین حالت SELL ───────────────────────────────────────────────
   int oldLevelSell  = g_gbpnzdLevelSell;
   int newLevelSell  = oldLevelSell;
   int newReasonSell = g_gbpnzdStopReasonSell;
   Rule_Transition(g_gbnzdCrisisSell, g_gbnzdSpikeSell, haSell,
                    g_gbpnzdCrisisRedHSell, g_gbpnzdCleanHSell,
                    newLevelSell, newReasonSell);

   // 🐛 v13.37 FIX1: CleanH را فوری ریست کن وقتی شرایط خطرناکه
   // 🐛 v13.44 FIX2: شرط دقیق‌تر — فقط وقتی واقعاً STOP trigger فعاله
   // مشکل v13.37: _crBuy = Crisis>=1 یعنی Yellow هم شامل میشد.
   // Yellow+Warning → CleanH=0 اما STOP trigger نمیزنه (stopB نیاز به Orange/Red داره).
   // نتیجه: CleanH اشتباه ریست میشد → RESUME بی‌دلیل دیرتر.
   // راه‌حل: exact همان شرط STOP trigger ها رو چک کن، نه Crisis>=1.
   {
      // trigBuy = دقیقاً همان شرط‌های stopA یا stopB برای Buy
      bool _trigBuy  = ((g_gbnzdSpikeBuy == 2) && (g_gbnzdCrisisBuy >= 1))     // stopA
                    || ((g_gbnzdSpikeBuy == 1) && (g_gbnzdCrisisBuy == 2 || g_gbnzdCrisisBuy == 3));  // stopB: Orange یا Red
      // trigSell = دقیقاً همان شرط‌های stopA یا stopB برای Sell
      bool _trigSell = ((g_gbnzdSpikeSell == 2) && (g_gbnzdCrisisSell >= 1))
                    || ((g_gbnzdSpikeSell == 1) && (g_gbnzdCrisisSell == 2 || g_gbnzdCrisisSell == 3));
      if(_trigBuy  && g_gbpnzdCleanHBuy  > 0)  g_gbpnzdCleanHBuy  = 0;
      if(_trigSell && g_gbpnzdCleanHSell > 0)  g_gbpnzdCleanHSell = 0;
      // همگام‌سازی مشترک
      g_gbpnzdCleanH = MathMin(g_gbpnzdCleanHBuy, g_gbpnzdCleanHSell);
   }

   // اگه هیچ تغییری نبود → خروج
   if(newLevelBuy == oldLevelBuy && newLevelSell == oldLevelSell) return;

   g_gbpnzdLevelBuy      = newLevelBuy;
   g_gbpnzdStopReasonBuy = newReasonBuy;
   g_gbpnzdLevelSell      = newLevelSell;
   g_gbpnzdStopReasonSell = newReasonSell;

   // worst-case مشترک
   g_gbpnzdLevel      = MathMax(g_gbpnzdLevelBuy, g_gbpnzdLevelSell);
   g_gbpnzdStopReason = (g_gbpnzdLevelBuy >= g_gbpnzdLevelSell) ? g_gbpnzdStopReasonBuy : g_gbpnzdStopReasonSell;

   // 🆕 v13.38: Level تغییر کرد → فوری در GV ذخیره کن
   // این مهم‌ترین save است — STOP/CLOSE/RESUME همینجا ثبت می‌شه
   GBPNZD_GV_Save();

   // 🐛 v13.47 FIX1: حذف sync اضافه Prev در لحظه STOP/CLOSE
   // مشکل v13.39 FIX3: این sync بعد از state machine اجرا می‌شد و Prev را
   // با مقدار "لحظه STOP" پر می‌کرد — که با rolling update خط 8518 و 9341
   // تضادی نداشت، اما counter بعدی از مقدار "لحظه STOP" می‌خواند نه از
   // "پایان ساعت". این sync اضافی است چون:
   // ۱. TL_Update هر ۳۰ثانیه Prev = Current می‌کند (v13.39 FIX2, خط 8518)
   // ۲. TL_Update هر تیک هم Prev = Current می‌کند (v13.40 FIX-B, خط 9341)
   // یعنی وقتی counter می‌خواند، Prev قبلاً = آخرین وضعیت تیک قبل از مرز ساعت.
   // این sync در اینجا فقط یک نوشتن اضافه بود — حذف می‌شود.

   // ── تشخیص جهت‌های خطر برای پیام ─────────────────────────────────
   bool buyDanger  = (newLevelBuy  > oldLevelBuy);
   bool sellDanger = (newLevelSell > oldLevelSell);
   if(!buyDanger && !sellDanger) { buyDanger = true; sellDanger = true; }

   string dirLine = "";
   if(buyDanger  && sellDanger) dirLine = "جهت: 🔴 BUY و SELL هر دو در خطر";
   else if(buyDanger)           dirLine = "جهت: 🔴 BUY (خطر برای پوزیشن Long)";
   else if(sellDanger)          dirLine = "جهت: 🔴 SELL (خطر برای پوزیشن Short)";

   // ── وضعیت چراغ‌های هر جهت برای پیام ───────────────────────────────
   string timeStr   = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);
   string crBuyTxt  = (g_gbnzdCrisisBuy==2)?"🔴 Red":(g_gbnzdCrisisBuy==3)?"🟠 Orange":(g_gbnzdCrisisBuy==1)?"🟡 Yellow":(g_gbnzdCrisisBuy==0)?"🟢 Green":"⚪";
   string crSellTxt = (g_gbnzdCrisisSell==2)?"🔴 Red":(g_gbnzdCrisisSell==3)?"🟠 Orange":(g_gbnzdCrisisSell==1)?"🟡 Yellow":(g_gbnzdCrisisSell==0)?"🟢 Green":"⚪";
   string spBuyTxt  = (g_gbnzdSpikeBuy==2)?"🔴 Spike":(g_gbnzdSpikeBuy==1)?"⚡ Warning":"🟢 Normal";
   string spSellTxt = (g_gbnzdSpikeSell==2)?"🔴 Spike":(g_gbnzdSpikeSell==1)?"⚡ Warning":"🟢 Normal";
   string detailLine= "Buy:  CRISIS=" + crBuyTxt  + " | Spike=" + spBuyTxt  + "\n"
                    + "Sell: CRISIS=" + crSellTxt + " | Spike=" + spSellTxt;
   double maxAdx    = MathMax(g_gbnzdAdxBuy, g_gbnzdAdxSell);

   // ── ساخت پیام ────────────────────────────────────────────────────
   string msg = "";

   if(newLevelBuy > oldLevelBuy || newLevelSell > oldLevelSell)
   {
      // worst-case برای تیتر پیام
      int newLevel  = MathMax(newLevelBuy, newLevelSell);
      int newReason = (newLevelBuy >= newLevelSell) ? newReasonBuy : newReasonSell;

      if(newLevel == 1)
      {
         // reasonLine جداگانه برای هر جهت که STOP شده
         string buyReasonTxt  = "";
         string sellReasonTxt = "";
         if(newLevelBuy == 1 && oldLevelBuy < 1)
            buyReasonTxt  = (newReasonBuy  == 0) ? "Spike=🔴 + CRISIS≠سبز" : "Spike=⚡ Warning + CRISIS=🟠/🔴";
         if(newLevelSell == 1 && oldLevelSell < 1)
            sellReasonTxt = (newReasonSell == 0) ? "Spike=🔴 + CRISIS≠سبز" : "Spike=⚡ Warning + CRISIS=🟠/🔴";
         string reasonLine = "";
         if(StringLen(buyReasonTxt)  > 0) reasonLine += "Buy:  " + buyReasonTxt  + "\n";
         if(StringLen(sellReasonTxt) > 0) reasonLine += "Sell: " + sellReasonTxt + "\n";

         msg = "⛔ STOP — ورود ممنوع\n"
             + _Symbol + " | " + timeStr + "\n"
             + dirLine + "\n"
             + "━━━━━━━━━━━━━━━━\n"
             + detailLine + "\n"
             + StringFormat("ADX: %.0f | Flow: %.1f",
                  maxAdx, (MathAbs(g_gbnzdFlowBuy) > MathAbs(g_gbnzdFlowSell) ? g_gbnzdFlowBuy : g_gbnzdFlowSell)) + "\n"
             + "━━━━━━━━━━━━━━━━\n"
             + reasonLine
             + "هیچ معامله جدیدی باز نکن\n"
             + "معاملات فعلی رو مدیریت کن\n"
             + "گوش به زنگ باش\n"
             + "اگه Crisis قرمز و High Alert روشن شد\n"
             + "یا با ضرر ببند یا هج کن";
      }
      else if(newLevel == 2)
      {
         int dirRedH = (newLevelBuy == 2) ? g_gbpnzdCrisisRedHBuy : g_gbpnzdCrisisRedHSell;
         string reasonLine = (newReason == 10)
            ? "CRISIS=🔴 + HighAlert فعال"
            : StringFormat("CRISIS=🔴 برای %d ساعت متوالی", dirRedH);
      msg = "🔴 CLOSE — ببند الان\n"
          + _Symbol + " | " + timeStr + "\n"
          + dirLine + "\n"
          + "━━━━━━━━━━━━━━━━\n"
          + detailLine + "\n"
          + StringFormat("ADX: %.0f | Flow: %.1f | قرمز %dh",
               maxAdx, (MathAbs(g_gbnzdFlowBuy) > MathAbs(g_gbnzdFlowSell) ? g_gbnzdFlowBuy : g_gbnzdFlowSell), dirRedH) + "\n"
          + "━━━━━━━━━━━━━━━━\n"
          + "روند قوی داره — برنمیگرده\n"
          + "با هر ضرری همه پوزیشن‌ها رو ببند\n"
          + "بعدش Xmoon رو خاموش کن";
      }
   }
   // RESUME: فقط وقتی هر دو جهت به GREEN برگشتن
   else if(newLevelBuy == 0 && newLevelSell == 0
           && (oldLevelBuy > 0 || oldLevelSell > 0))
   {
      int oldWorst = MathMax(oldLevelBuy, oldLevelSell);
      string prevStr = (oldWorst == 2)
         ? "CLOSE (بستن معاملات)"
         : "STOP (توقف ورود)";
      string cleanLine = StringFormat("%dh متوالی بدون خطر گذشت (Buy=%dh | Sell=%dh)",
         MathMin(g_gbpnzdCleanHBuy, g_gbpnzdCleanHSell), g_gbpnzdCleanHBuy, g_gbpnzdCleanHSell);
      msg = "✅ RESUME — وضعیت آروم شد\n"
          + _Symbol + " | " + timeStr + "\n"
          + "━━━━━━━━━━━━━━━━\n"
          + "Crisis=🟢  Spike=🟢  (Buy و Sell)\n"
          + cleanLine + "\n"
          + "━━━━━━━━━━━━━━━━\n"
          + "میتونی دوباره با Xmoon معامله کنی\n"
          + "سیگنال‌ها رو روشن کن";
   }

   if(StringLen(msg) > 0)
      Alert_Send(msg);

   // 🐛 v13.47 FIX5: یادآوری تکراری STOP/CLOSE هر 4 ساعت
   // مشکل: Alert_CheckGBPNZDRule فقط سر لبه‌ی تغییر حالت پیام می‌فرستاد.
   //        اگه پیام CLOSE گم بشه (گوشی خاموش، اینترنت قطع)، دیگه یادآوری نمی‌اومد.
   //        با توجه به تجربه ژوئن (25 روز پوزیشن باز)، این ریسک عملیاتی جدیه.
   // راه‌حل: اگه Level > 0 و 4 ساعت از آخرین reminder گذشته، یادآوری بفرست.
   // 🆕 v13.48 FIX5: یادآوری تکراری STOP/CLOSE با interval قابل تنظیم
   if(!(bool)MQLInfoInteger(MQL_TESTER) && Alert_GBPNZDRule_Repeat)
   {
      int worstLevel = MathMax(g_gbpnzdLevelBuy, g_gbpnzdLevelSell);
      if(worstLevel > 0)
      {
         // 🆕 v13.50 RULE-04: یادآوری وابسته به سطح — CLOSE (حساس‌ترین سطح) هر
         // Alert_CLOSERepeatMinutes (پیش‌فرض ۳۰ دقیقه)، STOP هر Alert_GBPNZDRule_RepeatMinutes
         // (پیش‌فرض ۶۰ دقیقه — قبلاً ثابت ۱۲۰ دقیقه برای هر دو سطح بود)
         int repMin = MathMax(5, (worstLevel == 2) ? Alert_CLOSERepeatMinutes : Alert_GBPNZDRule_RepeatMinutes);
         datetime nowR = TimeCurrent();
         if(g_gbpnzdLastReminderH == 0 || (nowR - g_gbpnzdLastReminderH) >= repMin * 60)
         {
            g_gbpnzdLastReminderH = nowR;
            string wLbl   = (worstLevel == 2) ? "🔴 CLOSE هنوز فعاله" : "⛔ STOP هنوز فعاله";
            string buyLbl = (g_gbpnzdLevelBuy  == 2) ? "🔴 CLOSE" : (g_gbpnzdLevelBuy  == 1) ? "⛔ STOP" : "🟢 OK";
            string selLbl = (g_gbpnzdLevelSell == 2) ? "🔴 CLOSE" : (g_gbpnzdLevelSell == 1) ? "⛔ STOP" : "🟢 OK";
            string remMsg = wLbl + "\n"
               + _Symbol + " | " + TimeToString(nowR, TIME_DATE|TIME_MINUTES) + "\n"
               + "━━━━━━━━━━━━━━━━\n"
               + "Buy:  " + buyLbl + " | CleanH=" + IntegerToString(g_gbpnzdCleanHBuy)  + "h\n"
               + "Sell: " + selLbl + " | CleanH=" + IntegerToString(g_gbpnzdCleanHSell) + "h\n"
               + "━━━━━━━━━━━━━━━━\n"
               + (worstLevel == 2 ? "هنوز نبستی؟ الان ببند." : "هنوز پوزیشن جدید باز نکن.");
            Alert_Send(remMsg);
         }
      }
      else
      {
         g_gbpnzdLastReminderH = 0;
      }
   }
}


// ════════════════════════════════════════════════════════════════════
// 🆕 v12.14: GetMaxStep — شمارش پله‌های فعال Xmoon
//
// Xmoon در هر جهت ۵ پله باز می‌کند:
//   پله ۱: Market Order  |  پله ۲-۵: Limit Orders
//
// تعداد پوزیشن‌های هم‌جهت باز روی این نماد = پله فعلی
// کاملاً Stateless و Real-time است.
// در هج هم درست کار می‌کند چون Buy و Sell جدا شمرده می‌شوند.
// ════════════════════════════════════════════════════════════════════
int GetMaxStep(bool forBuy)
{
   int count = 0;
   ENUM_POSITION_TYPE wantType = forBuy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!HM_PositionBelongsToSymbol(PositionGetSymbol(i), _Symbol)) continue;   // 🆕 v13.49 P4
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == wantType)
         count++;
   }
   return count;
}

// ════════════════════════════════════════════════════════════════════
// 🆕 v12.14: ComputeRegimeH1 — رژیم بازار روی H1 ثابت
//
// مشکل: Regime Detection در کد اصلی روی تایم‌فریم جاری چارت اجرا
// می‌شود. اگه کاربر روی M1 باشد، ممکن است Regime=Ranging نشون بده
// در حالی که H1 کاملاً Trending است.
//
// راه‌حل: یک Efficiency Ratio ساده روی H1 محاسبه می‌کنیم.
// ER > TrendingThreshold → Trending
// ════════════════════════════════════════════════════════════════════
bool ComputeRegimeTrendingH1()
{
   int erWindow = RegimeCalculationBars;   // همان 100 بار پیش‌فرض
   int bars = Bars(_Symbol, PERIOD_H1);
   if(bars < erWindow + 2) return false;

   double cl[];
   ArraySetAsSeries(cl, true);
   if(CopyClose(_Symbol, PERIOD_H1, 0, erWindow + 2, cl) < erWindow + 1) return false;

   double netChange   = MathAbs(cl[1] - cl[erWindow]);
   double totalChange = 0.0;
   for(int k = 1; k < erWindow; k++)
      totalChange += MathAbs(cl[k] - cl[k + 1]);

   if(totalChange <= 0.0) return false;
   double er = netChange / totalChange;
   return (er > TrendingThreshold);  // TrendingThreshold = 0.35 پیش‌فرض
}



// ایجاد/ریست اولیه چراغ‌ها
void TL_Create()
{
   if(g_isDeinitializing) return;
   TL_SetLight("RTM",    -1, "", "بدون پوزیشن فعال");
   TL_SetLight("TREND",  -1, "", "بدون پوزیشن فعال");
   TL_SetLight("STRUCT", -1, "", "بدون پوزیشن فعال");
   TL_SetLight("FLOW",   -1, "", "بدون پوزیشن فعال");
   TL_SetLight("ZOMBIE", -1, "", "بدون پوزیشن فعال");
   TL_SetLight("HIGHALT",-1, "", "HIGH ALERT: بدون پوزیشن فعال");
   // v12: CRISIS داخل داشبورد (TL_CRISIS label) — دیگر CRISIS_OBJ خارج نداریم
   string crNm = dashboardPrefix + "TL_CRISIS";
   if(ObjectFind(0, crNm) >= 0)
   {
      ObjectSetString (0, crNm, OBJPROP_TEXT,  "● Crisis: --");
      ObjectSetInteger(0, crNm, OBJPROP_COLOR, clrDimGray);
   }
   UpdateCrisisLight(-1, 0.0, 0.0, 0.0, true);
   ChartRedraw(0);
}

// محاسبه و بروزرسانی کامل سه چراغ
// فراخوانی: هر بار که پوزیشن تغییر کند یا هر 30 ثانیه (OnTimer)

void TL_Update()
{
   if(g_isDeinitializing) return;

   // ═══════════════════════════════════════════════════════════════
   // 🆕 v14.03: gate کندل-محور برای Rule/Spike/Crisis
   // runRuleBlock=true فقط در بستن کندل چارت یا اولین اجرا (init)
   // در وسط کندل: Spike/Rule/PrevSnapshot آپدیت نمی‌شوند
   // چراغ‌های ثابت (RTM/TREND/STRUCT/FLOW/ZOMBIE): بدون قید آپدیت می‌شوند
   // ═══════════════════════════════════════════════════════════════
   bool firstRuleRun = (g_gbnzdCrisisBuy < 0 || g_gbnzdCrisisSell < 0);
   bool runRuleBlock = g_isNewChartBar || firstRuleRun;

   // 🆕 v14.03: متغیرهای محلی برای snapshot CSV (با مقادیر پیش‌فرض ایمن)
   double bt_rtmX     = 0.0;
   string bt_rtmArrow = "FL";   // UP | DN | FL (text, no Unicode arrows)
   bool   bt_rtmCT    = true;
   double bt_adxVal   = 0.0;
   double bt_erH4     = 0.0;
   string bt_erLabel  = "?";
   string bt_d1Status = "?";
   double bt_d1Pips   = 0.0;   // distance in pips to key D1 level
   double bt_flowScore= 0.0;

   // ──── v11.0: تشخیص پوزیشن + مدیریت هج + حالت Buy/All/Sell ────
   // 🧹 v13.20: یک لوپ واحد به‌جای دو لوپ جدا — هم شمارش buy/sell، هم
   // قدیمی‌ترین پوزیشن هر جهت (برای ZOMBIE) در یک پاس محاسبه می‌شود
   int      buy_cnt = 0, sell_cnt = 0;
   datetime oldestT_buy  = (datetime)9223372036854775807; // LLONG_MAX
   datetime oldestT_sell = (datetime)9223372036854775807;
   double   oldestPx_buy  = 0.0;
   double   oldestPx_sell = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(HM_PositionBelongsToSymbol(PositionGetSymbol(i), _Symbol))   // 🆕 v13.49 P4
      {
         long     pt = PositionGetInteger(POSITION_TYPE);
         datetime pTime = (datetime)PositionGetInteger(POSITION_TIME);
         if(pt == POSITION_TYPE_BUY)
         {
            buy_cnt++;
            if(pTime < oldestT_buy) { oldestT_buy = pTime; oldestPx_buy = PositionGetDouble(POSITION_PRICE_OPEN); }
         }
         else if(pt == POSITION_TYPE_SELL)
         {
            sell_cnt++;
            if(pTime < oldestT_sell) { oldestT_sell = pTime; oldestPx_sell = PositionGetDouble(POSITION_PRICE_OPEN); }
         }
      }
   }
   bool hasRealPos = (buy_cnt > 0 || sell_cnt > 0);
   bool isHedge    = (buy_cnt > 0 && sell_cnt > 0);

   // ── حالت Buy یا Sell انتخاب‌شده توسط دکمه ───────────────────
   bool hasPos = true;   // در حالت Buy/Sell همیشه true است
   bool forBuy = true;
   bool isForced = false;  // true = جهت از دکمه آمده نه از پوزیشن

   if(g_dirMode == 1)        // دکمه Buy فعال
   {
      forBuy   = true;
      isForced = true;
   }
   else if(g_dirMode == 2)   // دکمه Sell فعال
   {
      forBuy   = false;
      isForced = true;
   }
   else  // g_dirMode == 0 → All (حالت پیش‌فرض)
   {
      hasPos = hasRealPos;
      // بررسی هج: اگر هر دو جهت باز هستند
      if(isHedge)
      {
         // هج: چراغ‌های جهت‌دار خاکستری، P/L نمایش داده می‌شود
         // مقادیر چراغ‌ها را خاکستری کن و پیام نمایش بده
         TL_SetLight("RTM",    -1, "● RTM: هج باز  ", "هج باز است — جهت نامشخص");
         TL_SetLight("TREND",  -1, "● ADX: هج باز  ", "هج باز است — جهت نامشخص");
         TL_SetLight("STRUCT", -1, "● D1:  هج باز  ", "هج باز است — جهت نامشخص");
         TL_SetLight("FLOW",   -1, "● FLOW: هج باز  ", "هج باز است — جهت نامشخص");
         TL_SetLight("ZOMBIE", -1, "● ZONE: هج باز  ", "هج باز است — جهت نامشخص");
         TL_SetLight("HIGHALT",-1, "● ALERT: هج    ", "هج باز است");
         TL_SetLight("KILLER",    -1, "● Killer: --", "هج باز — جهت نامشخص");   // 🆕 v13.05
         // v13.12: MktPhase در هج هم نشون میده (مستقل از پوزیشن)
         Calc_MktPhase();
         // 🐛 v13.30 FIX3b: هر بار که مقدار داریم آپدیت کن (نه فقط NeedRedraw)
         if(g_lightMktPhase >= 0)
         {
            string _mktLblH = (g_lightMktPhase==0) ? "Range" : (g_lightMktPhase==1) ? "Neutral" : "Trend!";
            string _mktTipH = StringFormat("Mkt Phase | MA10=%.3f", g_mktPhaseRatio);
            TL_SetLight("MKTPHASE", g_lightMktPhase, "● Mkt Phase: " + _mktLblH, _mktTipH);
            g_mktPhaseNeedRedraw = false;
         }
         // 🆕 v14.03: Spike (و بلوک Rule) فقط در بستن کندل چارت
         if(runRuleBlock) Calc_SpikeDetector();
         UpdateCrisisLight(-1, 0.0, 0.0, 0.0, true);
         // 🐛 v13.47 FIX3: چراغ SPIKE در هج هم با Flow جهت‌دار override شود (مثل no-position)
         if(Alert_OnGBPNZDRule && IsRuleSymbol(_Symbol))
         {
            int _hDispSp = MathMax(g_gbnzdSpikeBuy, g_gbnzdSpikeSell);
            if(_hDispSp >= 0)
            {
               string _hSpLbl = (_hDispSp==2) ? "Spike ⚠️" : (_hDispSp==1) ? "Warning" : "Normal";
               string _hSpTip = StringFormat("Spike (جهت‌دار، هج) | Buy=%d Sell=%d | score=%.2f",
                               g_gbnzdSpikeBuy, g_gbnzdSpikeSell, g_spikeScore);
               TL_SetLight("SPIKE", _hDispSp, "● Spike: " + _hSpLbl, _hSpTip);
               g_lightSpike = _hDispSp;
            }
         }
         // 🆕 v13.21b FIX: در حالت هج snapshot های Buy/Sell را با مقادیر واقعی آپدیت کن
         // 🐛 v13.34 FIX2b: Spike در هج هم جهت‌دار باشه (مثل no-position)
         //   قبلاً هر دو = g_lightSpike (مشترک). حالا مثل no-position با FLOW جهت‌دار.
         //   Crisis: از Replay آخرین کندل H1 (shift=1) برای هر جهت جداگانه.
         //   این از stale ماندن worstCrisis در هج جلوگیری می‌کنه.
         // 🆕 v14.03: Spike جهت‌دار، Crisis و Alert_CheckGBPNZDRule فقط در بستن کندل
         if(runRuleBlock && !((bool)MQLInfoInteger(MQL_TESTER)) && Alert_OnGBPNZDRule && IsRuleSymbol(_Symbol))
         {
            // Spike جهت‌دار در هج
            // 🐛 v13.45 FIX-B2: حذف ضریب «×0.08» — نگاه کن به کامنت v13.45 FIX-B1
            // (بخش no-position بالاتر). score یکسان + دروازه‌ی Flow جهت‌دار، بدون ضریب.
            double _fsBuyH  = Rule_FlowForSymbol(_Symbol, true);
            double _fsSellH = Rule_FlowForSymbol(_Symbol, false);
            double _baseH   = (g_lightSpike >= 0 && g_spikeScore > 0.0) ? g_spikeScore : 0.0;
            double _scBuyH  = _baseH;
            double _scSellH = _baseH;
            int _rpBuy  = (_scBuyH  < 1.00) ? 0 : (_scBuyH  <= 1.50) ? 1 : 2;
            int _rpSell = (_scSellH < 1.00) ? 0 : (_scSellH <= 1.50) ? 1 : 2;
            bool _frBuy  = (_fsBuyH  < -4.0);
            bool _frSell = (_fsSellH < -4.0);
            bool _fyBuy  = (_scBuyH  >= 2.0 && _fsBuyH  < 2.0 && _fsBuyH  >= -4.0);
            bool _fySell = (_scSellH >= 2.0 && _fsSellH < 2.0 && _fsSellH >= -4.0);
            if(_rpBuy  >= 1 && _frBuy)  g_gbnzdSpikeBuy  = _rpBuy;
            else if(_fyBuy)              g_gbnzdSpikeBuy  = 1;
            else                         g_gbnzdSpikeBuy  = 0;
            if(_rpSell >= 1 && _frSell) g_gbnzdSpikeSell = _rpSell;
            else if(_fySell)             g_gbnzdSpikeSell = 1;
            else                         g_gbnzdSpikeSell = 0;
            // Crisis در هج از Replay آخرین کندل H1
            if(g_gbpnzdReplayDone)
            {
               int _crBuyH  = GBPNZD_Replay_CrisisAtBar(1, true);
               int _crSellH = GBPNZD_Replay_CrisisAtBar(1, false);
               // فقط اگه snapshot قبلی از پوزیشن واقعی بود، worst بگیر
               // در هج قبلاً هر دو جهت از TL_Update آپدیت شدن → از Replay override نکن
               // اما اگه هر جهت -1 بود (N/A)، از Replay پر کن
               if(g_gbnzdCrisisBuy  < 0) g_gbnzdCrisisBuy  = (_crBuyH  >= 0) ? _crBuyH  : 0;
               if(g_gbnzdCrisisSell < 0) g_gbnzdCrisisSell = (_crSellH >= 0) ? _crSellH : 0;
            }
            g_gbnzdFlowBuy  = _fsBuyH;
            g_gbnzdFlowSell = _fsSellH;
            Alert_CheckGBPNZDRule();
         }
         // v11.92: خطوط Zone را در حالت هج خاکستری (colorMode=0) رسم کن
         if(ShowZoneLines)
         {
            SymbolZoneCfg _zc_hg;
            if(Zone_GetCfg(_Symbol, _zc_hg))
            {
               double _pip_hg = GetPipSize(_Symbol);
               double _wPx_hg = (double)_zc_hg.widthPips * _pip_hg;
               DrawAbsoluteZoneLines(_zc_hg.base_low, _wPx_hg, _pip_hg, ZoneLineCount, 0, 0);
            }
         }
         // P/L همچنان نمایش داده می‌شود (در UpdateDashboard)
         ChartRedraw(0);
         return;
      }
      forBuy = (buy_cnt >= sell_cnt);  // جهت غالب پوزیشن
   }

   // 🆕 v10.1: ZOMBIE — استخراج قیمت ورود قدیمی‌ترین پوزیشن باز
   // این فقط وقتی پوزیشن واقعی داریم اجرا می‌شود (live + Strategy Tester با پوزیشن)
   // 🧹 v13.20: دیگه لوپ جدا نمی‌زنه — از مقادیر محاسبه‌شده در لوپ بالا استفاده می‌کند
   if(hasPos)
   {
      bool     wantBuy  = (buy_cnt >= sell_cnt);
      double   oldestPx = wantBuy ? oldestPx_buy : oldestPx_sell;
      if(oldestPx > 0.0)
      {
         // v10.4: پوزیشن جدید → طبقه ورود تازه ثبت شود
         if(MathAbs(oldestPx - g_zombieEntryPrice) > _Point * 10)
         {
            g_zombieEntryPrice    = oldestPx;
            g_zombieEntryZone     = Zone_ComputeFromPrice(_Symbol, oldestPx);
            // v10.9: فیلتر H1 کاملاً stateless است — ریست نیازی نیست
         }
         else if(g_zombieEntryPrice <= 0.0)
         {
            g_zombieEntryPrice    = oldestPx;
            g_zombieEntryZone     = Zone_ComputeFromPrice(_Symbol, oldestPx);
         }
      }
   }
   // v10.4: BacktestZombieRef حذف شد — گرید مطلق نیازی به مرجع دستی ندارد

   // v11.92: حالت Forced بدون پوزیشن واقعی → طبقه ورود = طبقه قیمت فعلی
   //         (تا خطوط Zone حول قیمت فعلی رنگی شوند)
   if(isForced && !hasRealPos)
   {
      double _curPx = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(_curPx > 0.0)
      {
         g_zombieEntryPrice = _curPx;
         g_zombieEntryZone  = Zone_ComputeFromPrice(_Symbol, _curPx);
      }
   }

   // 🆕 بکتست: وقتی پوزیشن واقعی نیست، از BacktestPositionDir استفاده کن
   // در حالت Forced (Buy/Sell دکمه) این بلوک نادیده گرفته می‌شود
   if(!isForced && !hasPos && (bool)MQLInfoInteger(MQL_TESTER))
   {
      hasPos = true;
      forBuy = (BacktestPositionDir == 0);  // 0=Buy, 1=Sell
   }

   // ──── بدون پوزیشن: همه خاکستری ──────────────────────────────
   if(!hasPos)
   {
      // ── ریست چراغ‌های جهت‌دار — فقط یک‌بار (اولین تبدیل به no-position) ──
      // 🐛 v13.28 FIX1: Spike/Rule از این if بیرون رفتن تا هر ۳۰ ثانیه اجرا بشن
      if(g_lightRTM != -1 || g_lightTrend != -1 || g_lightStruct != -1 || g_lightFLOW != -1 || g_lightGOLDEN != -1)
      {
         g_lightRTM = g_lightTrend = g_lightStruct = g_lightFLOW = g_lightGOLDEN = g_lightZOMBIE = g_lightKILLER = -1;
         g_lastAdxVal = 0.0; g_lastFlowScore = 0.0; g_lastRedCount = 0; g_lastErH4 = 0.0;
         // v10.4: ریست ZOMBIE Zone state (طبقه ورود را پاک کن)
         g_zombieEntryPrice    = 0.0;
         g_zombieEntryZone     = 0;
         g_zombieCurrentZone   = 0;
         // v10.9: فیلتر H1 کاملاً stateless است — ریست نیازی نیست
         // v10.6 FIX: وقتی ShowZoneLines=true خطوط را حذف نکن — در عوض رسم کن
         if(ShowZoneLines)
         {
            SymbolZoneCfg _zc_np;
            if(Zone_GetCfg(_Symbol, _zc_np))
            {
               double _pip_np = GetPipSize(_Symbol);
               double _basePx_np = _zc_np.base_low;
               double _wPx_np    = (double)_zc_np.widthPips * _pip_np;
               DrawAbsoluteZoneLines(_basePx_np, _wPx_np, _pip_np, ZoneLineCount, 0);
            }
         }
         TL_SetLight("RTM",    -1, "● RTM: --      ", "بدون پوزیشن فعال");
         TL_SetLight("TREND",  -1, "● ADX: --      ", "بدون پوزیشن فعال");
         TL_SetLight("STRUCT", -1, "● D1:  --      ", "بدون پوزیشن فعال");
         TL_SetLight("FLOW",   -1, "● FLOW: --     ", "بدون پوزیشن فعال");
         TL_SetLight("KILLER",    -1, "● Killer: --", "No Position");   // 🆕 v13.05
         TL_SetLight("ZOMBIE", -1, "● ZONE: --     ", "بدون پوزیشن فعال");
         TL_SetLight("HIGHALT",-1, "● ALERT: --    ", "HIGH ALERT: بدون پوزیشن فعال");  // v11.0
         ChartRedraw(0);
      }

      // ── MktPhase + Spike + Crisis + Rule — هر ۳۰ ثانیه، بدون توجه به وضعیت چراغ‌ها ──
      // 🐛 v13.28 FIX1: قبلاً این سه تابع داخل if بالا بودن و بعد از اولین ریست
      //   دیگه صدا نمی‌شدن. CleanH در no-position پیشرفت نمی‌کرد و g_lightSpike
      //   بیات می‌موند.
      // v13.12: MktPhase حتی بدون پوزیشن نشون میده
      Calc_MktPhase();
      // 🐛 v13.31 FIX4: MktPhase را بدون قید NeedRedraw به داشبورد بزن.
      // قبلاً اگه g_mktPhaseNeedRedraw=false بود (cache hit یا روز قبل حساب شده بود)
      // TL_SetLight صدا زده نمیشد → وقتی کاربر Sell/Buy/All سوئیچ میکرد، روی -- می‌موند.
      // حالا هر بار که g_lightMktPhase معتبره، بدون هیچ شرطی TL_SetLight صدا زده میشه.
      if(g_lightMktPhase >= 0)
      {
         string _mktLbl = (g_lightMktPhase==0) ? "Range" : (g_lightMktPhase==1) ? "Neutral" : "Trend!";
         string _mktTip = StringFormat("Mkt Phase | MA10=%.3f", g_mktPhaseRatio);
         TL_SetLight("MKTPHASE", g_lightMktPhase, "● Mkt Phase: " + _mktLbl, _mktTip);
         g_mktPhaseNeedRedraw = false;
      }
      // v13.14: Spike نمایش — 🆕 v14.03: محاسبه فقط در بستن کندل
      if(runRuleBlock) Calc_SpikeDetector();
      UpdateCrisisLight(-1, 0.0, 0.0, 0.0, true);
      // 🐛 v13.47 FIX3: چراغ SPIKE در no-position با Flow جهت‌دار override شود
      // مشکل: Calc_SpikeDetector از g_lightFLOW استفاده می‌کند که در no-position = -1
      //        → flowConfirms=false → همیشه Normal نشون می‌داد، حتی وقتی score بالاست
      //        → داشبورد دقیقاً وقتی مهم‌ترینه (قبل از ورود جدید) گمراه‌کننده بود
      // راه‌حل: بدترین (worst-case) چراغ Spike بین Buy و Sell جهت‌دار رو نمایش بده
      //         این همان مقداری است که Rule برای STOP/CLOSE استفاده می‌کند
      if(Alert_OnGBPNZDRule && IsRuleSymbol(_Symbol))
      {
         int _dispSp = MathMax(g_gbnzdSpikeBuy, g_gbnzdSpikeSell);
         if(_dispSp >= 0)
         {
            string _spLbl = (_dispSp==2) ? "Spike ⚠️" : (_dispSp==1) ? "Warning" : "Normal";
            string _spTip = StringFormat("Spike (جهت‌دار) | Buy=%d Sell=%d | score=%.2f",
                            g_gbnzdSpikeBuy, g_gbnzdSpikeSell, g_spikeScore);
            TL_SetLight("SPIKE", _dispSp, "● Spike: " + _spLbl, _spTip);
            g_lightSpike = _dispSp;   // sync برای LogHourlySnapshot
         }
      }
      // 🆕 v13.24: بدون پوزیشن — snapshot هر دو جهت با Spike جهت‌دار آپدیت بشه
      // 🐛 v13.27 FIX: Crisis به -1 ریست میشه (N/A واقعی) + Alert_CheckGBPNZDRule صدا میشه
      // 🐛 v13.29 FIX3: score جهت‌دار با وزن FLOW — همسو با منطق StatusQuery
      // 🐛 v13.34 FIX2: Crisis در no-position از Replay محاسبه بشه (نه -1)
      //   قبلاً: g_gbnzdCrisisBuy/Sell = -1 → worstCrisis = MathMax(-1,-1) = -1
      //   → wasClean=true هر ساعت → CleanH رشد → trigResume → Level=0 اشتباه.
      //   حالا: Crisis واقعی از آخرین کندل H1 بسته (shift=1) محاسبه می‌شه.
      //   بعد از چند ساعت live که TL_Update با پوزیشن واقعی اجرا بشه،
      //   g_gbnzdCrisisBuy/Sell از snapshot های لایو پر می‌شن (by design).
      if(!(bool)MQLInfoInteger(MQL_TESTER) && Alert_OnGBPNZDRule && IsRuleSymbol(_Symbol))
      {
         // FLOW جهت‌دار برای هر دو جهت
         double _fsBuy  = Rule_FlowForSymbol(_Symbol, true);
         double _fsSell = Rule_FlowForSymbol(_Symbol, false);

         // 🐛 v13.45 FIX-B3: حذف ضریب «×0.08» — نگاه کن به کامنت v13.45 FIX-B1
         // (بخش StatusQuery no-position بالاتر در فایل). score یکسان برای هر دو
         // جهت + دروازه‌ی Flow جهت‌دار، دقیقاً هم‌فرمول با Replay و بکتست.
         double _baseScore    = (g_lightSpike >= 0 && g_spikeScore > 0.0) ? g_spikeScore : 0.0;
         double _scoreSell    = _baseScore;
         double _scoreBuy     = _baseScore;

         int _rawPhaseSell    = (_scoreSell < 1.00) ? 0 : (_scoreSell <= 1.50) ? 1 : 2;
         int _rawPhaseBuy     = (_scoreBuy  < 1.00) ? 0 : (_scoreBuy  <= 1.50) ? 1 : 2;

         bool _flowRedSell    = (_fsSell < -4.0);
         bool _flowRedBuy     = (_fsBuy  < -4.0);
         bool _flowYellowSell = (_scoreSell >= 2.0 && _fsSell < 2.0 && _fsSell >= -4.0);
         bool _flowYellowBuy  = (_scoreBuy  >= 2.0 && _fsBuy  < 2.0 && _fsBuy  >= -4.0);

         // Spike Buy جهت‌دار
         if(_rawPhaseBuy  >= 1 && _flowRedBuy)   g_gbnzdSpikeBuy  = _rawPhaseBuy;
         else if(_flowYellowBuy)                  g_gbnzdSpikeBuy  = 1;
         else                                     g_gbnzdSpikeBuy  = 0;
         // Spike Sell جهت‌دار
         if(_rawPhaseSell >= 1 && _flowRedSell)  g_gbnzdSpikeSell = _rawPhaseSell;
         else if(_flowYellowSell)                 g_gbnzdSpikeSell = 1;
         else                                     g_gbnzdSpikeSell = 0;

         // 🐛 v13.39 FIX1 + v13.42 FIX: Crisis assignment در no-position
         if(g_gbpnzdReplayDone)
         {
            // 🐛 v13.42: اولین بار بعد از Replay، از g_crisisState (RC زنده) استفاده کن
            // نه از Replay(shift=1) کندل بسته — Replay نمیتونه وضعیت داخل کندل جاری رو ببینه
            if(g_gbpnzdNeedsLiveCheck)
            {
               g_gbnzdCrisisBuy  = g_crisisState;
               g_gbnzdCrisisSell = g_crisisState;
               g_gbpnzdNeedsLiveCheck = false;
               Print("🔄 v13.42 GBPNZD live Crisis check after Replay — Crisis=", g_gbnzdCrisisSell);
            }
            else
            {
               if(g_gbnzdCrisisBuy < 0)
               {
                  int _crBuy = GBPNZD_Replay_CrisisAtBar(1, true);
                  g_gbnzdCrisisBuy = (_crBuy >= 0) ? _crBuy : 0;
               }
               if(g_gbnzdCrisisSell < 0)
               {
                  int _crSell = GBPNZD_Replay_CrisisAtBar(1, false);
                  g_gbnzdCrisisSell = (_crSell >= 0) ? _crSell : 0;
               }
            }
         }
         else
         {
            // Replay هنوز کامل نشده — نگه داری مقادیر قبلی
         }
         // ADX و Flow ذخیره برای HighAlert (در no-position HighAlert غیرفعاله ولی Flow برای Rule لازمه)
         g_gbnzdAdxBuy  = g_lastAdxVal;
         g_gbnzdAdxSell = g_lastAdxVal;
         g_gbnzdFlowBuy  = _fsBuy;
         g_gbnzdFlowSell = _fsSell;
         // 🆕 v14.03: Alert_CheckGBPNZDRule و PrevSnapshot فقط در بستن کندل چارت
         // قبلاً هر ۳۰ ثانیه آپدیت می‌شدند — حالا فقط در بستن کندل
         // این با بکتست (که فقط روی کندل بسته تصمیم می‌گیرد) هم‌خوان است
         if(runRuleBlock)
         {
            Alert_CheckGBPNZDRule();   // CleanH با هر کندل بسته پیشرفت می‌کند
            g_gbpnzdPrevCrisisBuy  = g_gbnzdCrisisBuy;
            g_gbpnzdPrevSpikeBuy   = g_gbnzdSpikeBuy;
            g_gbpnzdPrevCrisisSell = g_gbnzdCrisisSell;
            g_gbpnzdPrevSpikeSell  = g_gbnzdSpikeSell;
         }
      }
      return;
   }

   // ════════════════════════════════════════════════════════════════
   // چراغ ۱: RTM - Return to Mean  (EMA200 روی H1، ثابت)
   // ─────────────────────────────────────────────────────────────
   // دو حالت اصلی:
   // A) COUNTER-TREND (معمول Xmoon): قیمت خلاف EMA200
   //    سبز: کشیده شده (>3.5x) + دارد برمیگردد
   //    زرد: فاصله متوسط
   //    قرمز: خیلی دور + شتاب دور‌شدن
   // B) WITH-TREND (نادر - Sell در نزول یا Buy در صعود):
   //    قیمت هم‌جهت EMA200 → RTM ریسک = برگشت به میانگین علیه ما
   //    سبز: روند ادامه دارد (فاصله رو به رشد)
   //    زرد: فاصله ثابت یا کم
   //    قرمز: فاصله دارد کم میشه = mean reversion شروع شده
   // ════════════════════════════════════════════════════════════════
   int    newRTM  = 1;  // پیش‌فرض زرد (محتاطانه)
   string rtmTxt  = "  ● RTM: ??   ";
   string rtmTip  = "RTM: EMA200 H1 (ثابت)";

   if(handleEMA200_H1_TL != INVALID_HANDLE && handleATR_H1_TL != INVALID_HANDLE
      && BarsCalculated(handleEMA200_H1_TL) > 210
      && BarsCalculated(handleATR_H1_TL) > 20)
   {
      double ema[], atr[];
      ArraySetAsSeries(ema, true);
      ArraySetAsSeries(atr, true);
      bool ok = (CopyBuffer(handleEMA200_H1_TL, 0, 1, 3, ema) == 3) &&
                (CopyBuffer(handleATR_H1_TL,    0, 1, 2, atr) == 2) &&
                (atr[0] > 0);
      if(ok)
      {
         double h1c0 = iClose(_Symbol, PERIOD_H1, 1);
         double h1c1 = iClose(_Symbol, PERIOD_H1, 2);

         double d0   = MathAbs(h1c0 - ema[0]) / atr[0];
         double d1   = MathAbs(h1c1 - ema[1]) / atr[1];
         double dDel = d0 - d1;   // مثبت = دارد دور می‌شود از mean

         // rightSide = true  → قیمت طرف درست برای mean-reversion (Counter-Trend)
         // rightSide = false → قیمت هم‌جهت EMA200 است (With-Trend)
         bool rightSide = forBuy ? (h1c0 < ema[0]) : (h1c0 > ema[0]);
         // With-Trend: قیمت در جهت پوزیشن ما نسبت به EMA200 حرکت کرده
         bool withTrend = !rightSide;

         string dirArrow = (dDel >  0.2) ? "↑" : (dDel < -0.2) ? "↓" : "→";
         string modeTag  = withTrend ? "[WT]" : "[CT]";  // With/Counter Trend

         rtmTxt = StringFormat("● RTM:%4.1fx%s", d0, dirArrow);

         // 🆕 snapshot برای CSV (text arrows for ANSI compatibility)
         bt_rtmX    = d0;
         bt_rtmArrow= (dDel >  0.2) ? "UP" : (dDel < -0.2) ? "DN" : "FL";
         bt_rtmCT   = !withTrend;  // CT = Counter-Trend = خلاف روند (معمول Xmoon)

         if(withTrend)
         {
            // ── حالت B: WITH-TREND ──────────────────────────────
            // قیمت در جهت پوزیشن از mean فاصله گرفته
            // ریسک = mean reversion ← دارد به EMA200 نزدیک میشه
            rtmTip = StringFormat(
               "وضعیت: هم‌جهت با روند\n"
               "──────────\n"
               "سبز: روند ادامه (↑ فاصله)\n"
               "زرد: فاصله ثابت / کم\n"
               "قرمز: فاصله کم‌میشه = ریسک",
               modeTag, d0, dirArrow);

            if(d0 >= 2.0 && dDel > 0.15)
               newRTM = 0;           // سبز: روند ادامه دارد، فاصله رو به رشد
            else if(d0 < 0.8 || dDel < -0.35)
               newRTM = 2;           // قرمز: خیلی نزدیک mean یا برگشت شدید
            else
               newRTM = 1;           // زرد: حالت میانه
         }
         else
         {
            // ── حالت A: COUNTER-TREND (معمول Xmoon) ────────────
            // قیمت در طرف مخالف EMA200 از پوزیشن ما
            //
            // 🔴 v7.2 FIX - منطق بازنویسی شد:
            // تحلیل بکتست یک‌ساله AUDCAD نشان داد که CT + عدم برگشت
            // (Arrow≠Down) = 100% معاملات فاجعه‌بار (نه فقط 6.5x!)
            // وقتی قیمت CT است (خلاف Xmoon) و در حال برگشت نیست،
            // بازار دارد از میانگین فرار می‌کند — این قرمز است.
            //
            // منطق جدید:
            //   🟢 d0 >= 3.5x AND Arrow=Down  → کشیده + در حال برگشت
            //   🔴 d0 >= 1.5x AND Arrow≠Down  → CT + دور می‌شود یا ثابت
            //   🟡 بقیه حالات                  → نزدیک mean یا CT+برگشت کند
            rtmTip = StringFormat(
               "وضعیت: خلاف روند\n"
               "فاصله: %.1f × ATR  %s\n"
               "شتاب: %.2f (+ = دور، - = نزدیک)\n"
               "──────────\n"
               "🟢 سبز : ≥3.5x + بازگشت قوی (dDel<-0.3)\n"
               "🔴 قرمز: ≥2.5x + شتاب دور‌شدن (dDel>0.15) ← v10.2\n"
               "🟡 زرد : بقیه (نزدیک EMA یا حرکت غیرشتابدار)\n",
               modeTag, d0, dirArrow, dDel);

            bool returning = (dDel < -0.3);         // 🆕 v10.2: -0.2 → -0.3 (برگشت قوی‌تر لازم)
            bool runningAway = (dDel > 0.15);         // 🆕 v10.2: شتاب دور‌شدن فعال

            // 🆕 v10.2: آستانه‌های تطبیقی RTM Counter-Trend
            // مشکل قبلی: 1.5x → Red باعث ۳۸٪ قرمز در AUDCAD نزولی ۲۰۲۵ شد
            // راه‌حل: Red فقط وقتی هردو شرط: فاصله زیاد (≥2.5x) AND شتاب واگرایی
            //
            // 🟢 سبز : کشیده‌شده + بازگشت قوی    (قبلاً: 3.5x+returning)
            // 🔴 قرمز: ≥2.5x AND شتاب دور شدن    (قبلاً: 1.5x+NOT returning)
            // 🟡 زرد : همه چیز دیگر
            if(d0 >= 3.5 && returning)
               newRTM = 0;           // 🟢 سبز: کشیده + بازگشت قوی
            else if(d0 >= 2.5 && runningAway)
               newRTM = 2;           // 🔴 قرمز: خیلی دور + شتاب دور‌شدن (واگرایی فعال)
            else
               newRTM = 1;           // 🟡 زرد: بقیه حالات
         }
      }
      else { rtmTxt = "● RTM:load.."; rtmTip = "در حال بارگذاری H1 data..."; }
   }
   else { rtmTxt = "● RTM:init.."; rtmTip = "handle هنوز آماده نیست"; }

   // ════════════════════════════════════════════════════════════════
   // چراغ ۲: TREND - قدرت روند  (ADX + ER روی H4، هر دو ثابت)
   // ─────────────────────────────────────────────────────────────
   // ADX = قدرت روند (مقدار عددی)
   // ER  = Efficiency Ratio = کیفیت روند (چقدر جهت‌دار حرکت کرده)
   //       ER = |net move| / Σ|bar moves| → 0=تصادفی, 1=کاملاً جهت‌دار
   // ترکیب هر دو → تشخیص دقیق‌تر: "آیا روند واقعی وجود دارد؟"
   // ─────────────────────────────────────────────────────────────
   // برای Counter-Trend (معمول Xmoon):
   //   سبز:  ADX<20 یا ER<0.20 → رنج/ضعیف → برگشت محتمل
   //   زرد:  ADX ۲۰-۳۲ و ER ۰.۲-۰.۳۵ → روند متوسط → مراقب
   //   قرمز: هر دو ADX>32 + ER>0.35 + رو به رشد → روند قوی
   // برای With-Trend (نادر):
   //   سبز:  ADX>20 و ER>0.25 → روند پشتیبان قوی
   //   زرد:  ADX ضعیف یا ER کم → پشتیبانی روند ناپایدار
   // ════════════════════════════════════════════════════════════════
   int    newTrend  = 1;
   string trendTxt  = "  ● ADX: ??   ";
   string trendTip  = "ADX+ER: H4 (ثابت)";

   if(handleADX_H4_TL != INVALID_HANDLE
      && BarsCalculated(handleADX_H4_TL) > 20)
   {
      double adxB[], pdiB[], mdiB[];
      ArraySetAsSeries(adxB, true);
      ArraySetAsSeries(pdiB, true);
      ArraySetAsSeries(mdiB, true);
      bool ok = (CopyBuffer(handleADX_H4_TL, 0, 1, 2, adxB) == 2) &&
                (CopyBuffer(handleADX_H4_TL, 1, 1, 2, pdiB) == 2) &&
                (CopyBuffer(handleADX_H4_TL, 2, 1, 2, mdiB) == 2);
      if(ok)
      {
         double adx    = adxB[0];
         bool   rising = (adx > adxB[1] + 0.4);
         double pDI    = pdiB[0], mDI = mdiB[0];
         string rArr   = rising ? "▲" : (adx < adxB[1] - 0.4 ? "▼" : "→");

         // ── Efficiency Ratio روی H4 (14 کندل، بدون handle اضافه) ──
         // ER = |Close_now - Close_14| / Σ|ΔClose| → lightweight, فقط 15 iClose
         double erH4   = 0;
         int    erBars = MathMin(14, Bars(_Symbol, PERIOD_H4) - 2);
         if(erBars >= 5)
         {
            double netMove = MathAbs(iClose(_Symbol, PERIOD_H4, 1) -
                                     iClose(_Symbol, PERIOD_H4, erBars + 1));
            double sumPath = 0;
            for(int k = 1; k <= erBars; k++)
               sumPath += MathAbs(iClose(_Symbol, PERIOD_H4, k) -
                                  iClose(_Symbol, PERIOD_H4, k + 1));
            erH4 = (sumPath > 0) ? netMove / sumPath : 0;
         }
         // ER: <0.20=رنج | 0.20-0.35=متوسط | >0.35=ترند
         string erLabel = (erH4 < 0.20) ? "rng" : (erH4 < 0.35) ? "mod" : "TRD";

         // 🆕 snapshot برای CSV
         bt_adxVal  = adx;
         bt_erH4    = erH4;
         bt_erLabel = erLabel;
         g_lastAdxVal = adx;   // 🆕 v8.0: برای GOLDEN rule
         g_lastErH4   = erH4;  // 🆕 v8.1: برای SURGE condition

         // روند خلاف پوزیشن؟ (margin 5 unit)
         bool oppTrend = forBuy ? (mDI > pDI + 5.0) : (pDI > mDI + 5.0);

         trendTxt = StringFormat("● ADX:%3.0f %s", adx, erLabel);
         trendTip = StringFormat(
            "Trend Str — قدرت روند (H4)\n"
            "ADX: %.0f %s | ER: %.2f → %s\n"
            "روند: %s\n"
            "━━━━━━━━━━\n"
            "🟢 ضعیف : رنج — Xmoon راحته\n"
            "🟡 متوسط: مراقب\n"
            "🔴 قوی  : روند واقعی — خطر برگشت",
            adx, rArr, erH4, erLabel,
            !oppTrend ? "موافق پوزیشن" : "⚠️ خلاف پوزیشن");

         if(!oppTrend)
         {
            // ── With-Trend: روند موافق پوزیشن ──────────────────
            // ADX و ER هر دو قوی = پشتیبانی خوب
            if(adx > 20.0 && erH4 > 0.25)
               newTrend = 0;   // سبز: روند قوی در جهت ما
            else
               newTrend = 1;   // زرد: پشتیبانی ضعیف (بی‌روند)
         }
         else
         {
            // ── Counter-Trend: روند خلاف پوزیشن ─────────────────
            // هر دو ضعیف = بازار رنج = Xmoon موفق
            bool adxWeak  = (adx < 20.0);
            bool erWeak   = (erH4 < 0.20);
            bool adxMid   = (adx >= 20.0 && adx < 32.0);
            bool erMid    = (erH4 >= 0.20 && erH4 < 0.35);
            bool adxStr   = (adx >= 32.0 && rising);
            bool erStr    = (erH4 >= 0.35);

            if(adxWeak || erWeak)
               newTrend = 0;   // سبز: حداقل یکی ضعیف → رنج احتمالی
            else if(adxStr && erStr)
               newTrend = 2;   // قرمز: هر دو قوی → روند واقعی خطرناک
            else
               newTrend = 1;   // زرد: حالت میانه
         }
      }
      else { trendTxt = "● ADX:load.."; trendTip = "در حال بارگذاری H4..."; }
   }
   else { trendTxt = "● ADX:init.."; trendTip = "handle هنوز آماده نیست"; }

   // ════════════════════════════════════════════════════════════════
   // چراغ ۳: STRUCT - یکپارچگی ساختار D1 (swing Low/High روی D1)
   // منطق: آیا قیمت یک سطح اساسی روزانه رو شکسته؟
   //        اگه آره، این دیگه mean-reversion نیست - ساختار عوض شده
   //  سبز: قیمت فراتر از swing D1 (10 کندل ≈ 2 هفته) نرفته
   //  زرد: قیمت در فاصله ≤ 2 ATR_D1 از سطح کلیدی (حالت اعلام خطر زودتر)
   //  قرمز: سطح swing D1 شکسته → احتمال برگشت خیلی کم
   //
   //  تغییر v7.1: lookback 30→10 روز (رنج ۲ هفته اخیر، نه ۶ هفته)
   //              این باعث می‌شه برای جفت‌ارزهای رنجی مثل AUDCAD
   //              هنگام تحرکات چند روزه هم چراغ فعال شود
   //              threshold EDGE: 1×ATR → 2×ATR (هشدار زودتر)
   // ════════════════════════════════════════════════════════════════
   int    newStruct  = 1;
   string structTxt  = "  ● D1: ??    ";
   string structTip  = "Struct: D1 Swing (ثابت)";

   {
      double atrD1 = 0;
      if(handleATR_D1_TL != INVALID_HANDLE && BarsCalculated(handleATR_D1_TL) > 20)
      {
         double aB[]; ArraySetAsSeries(aB, true);
         if(CopyBuffer(handleATR_D1_TL, 0, 1, 1, aB) == 1 && aB[0] > 0)
            atrD1 = aB[0];
      }
      if(atrD1 <= 0)
         atrD1 = iClose(_Symbol, PERIOD_D1, 1) * 0.006;  // fallback تقریبی

      double curPrice = iClose(_Symbol, PERIOD_H1, 1);
      int    lookD1   = MathMin(10, Bars(_Symbol, PERIOD_D1) - 2);  // ← 30→10

      if(lookD1 >= 5)
      {
         if(forBuy)
         {
            // پایین‌ترین Low در ۱۰ کندل D1 = کف ساختاری اخیر (۲ هفته)
            double swLow = iLow(_Symbol, PERIOD_D1, 1);
            for(int k = 2; k <= lookD1; k++)
               swLow = MathMin(swLow, iLow(_Symbol, PERIOD_D1, k));

            double dist = curPrice - swLow;
            structTip = StringFormat(
               "D1 Struct - یکپارچگی روزانه (10 کندل اخیر)\n"
               "سبز: فاصله بیش از ۲ ای تی آر (ایمن)\n"
               "زرد: فاصله کمتر از ۲ ای تی آر (هشدار)\n"
               "قرمز: کف روزانه شکسته شده!",
               DoubleToString(swLow, _Digits),
               DoubleToString(curPrice, _Digits),
               dist / (_Point * 10),
               atrD1 / (_Point * 10));

            if(curPrice < swLow)
            { newStruct = 2; structTxt = "● D1:BREAK! "; }
            else if(dist < atrD1 * 2.0)          // ← 0.9×ATR → 2.0×ATR
            { newStruct = 1; structTxt = "● D1: EDGE  "; }
            else
            { newStruct = 0; structTxt = "● D1: OK    "; }
         }
         else // sell
         {
            double swHigh = iHigh(_Symbol, PERIOD_D1, 1);
            for(int k = 2; k <= lookD1; k++)
               swHigh = MathMax(swHigh, iHigh(_Symbol, PERIOD_D1, k));

            double dist = swHigh - curPrice;
            structTip = StringFormat(
               "D1 Struct - یکپارچگی روزانه (10 کندل اخیر)\n"
               "سبز: فاصله بیش از ۲ ای تی آر (ایمن)\n"
               "زرد: فاصله کمتر از ۲ ای تی آر (هشدار)\n"
               "قرمز: سقف روزانه شکسته شده!",
               DoubleToString(swHigh, _Digits),
               DoubleToString(curPrice, _Digits),
               dist / (_Point * 10),
               atrD1 / (_Point * 10));

            if(curPrice > swHigh)
            { newStruct = 2; structTxt = "● D1:BREAK! "; }
            else if(dist < atrD1 * 2.0)          // ← 0.9×ATR → 2.0×ATR
            { newStruct = 1; structTxt = "● D1: EDGE  "; }
            else
            { newStruct = 0; structTxt = "● D1: OK    "; }
         }
      }
      else { structTxt = "● D1:data.."; structTip = "داده D1 کافی نیست"; }
   }

   // 🆕 snapshot ساختار D1 برای CSV
   bt_d1Status = (newStruct == 0) ? "OK" : (newStruct == 1) ? "EDGE" : "BREAK";
   // محاسبه فاصله پیپ از سطح کلیدی D1
   {
      double curP = iClose(_Symbol, PERIOD_H1, 1);
      int    lk   = MathMin(10, Bars(_Symbol, PERIOD_D1) - 2);
      if(lk >= 3)
      {
         if(forBuy)
         {
            double swL = iLow(_Symbol, PERIOD_D1, 1);
            for(int k=2;k<=lk;k++) swL = MathMin(swL, iLow(_Symbol, PERIOD_D1, k));
            bt_d1Pips = (curP - swL) / (_Point * 10);
         }
         else
         {
            double swH = iHigh(_Symbol, PERIOD_D1, 1);
            for(int k=2;k<=lk;k++) swH = MathMax(swH, iHigh(_Symbol, PERIOD_D1, k));
            bt_d1Pips = (swH - curP) / (_Point * 10);
         }
      }
   }

   // ════════════════════════════════════════════════════════════════
   // چراغ ۴: FLOW - قدرت نسبی ارزهای خواهر (Sister Pairs, H4 ثابت)
   // ─────────────────────────────────────────────────────────────
   // بدون handle اضافه. 5 کندل H4 momentum برای هر جفت خواهر.
   // آستانه (v8.0 اصلاح شد): >3.0=سبز | >=-5.0=زرد | <-5.0=قرمز (سونامی واقعی)
   // اگه چهار چراغ همگی قرمز شدند → خروج فوری از پله ۵
   // ════════════════════════════════════════════════════════════════
   int    newFLOW = 1;
   string flowTxt = "● FLOW: ??    ";
   string flowTip = "FLOW: Sister Pairs (H4 ثابت)";

   {
      string baseSym = (StringLen(_Symbol) >= 6) ? StringSubstr(_Symbol, 0, 6) : _Symbol;
      double fs      = 0.0;
      bool   known   = true;

      if     (baseSym == "AUDCAD") fs = FlowEvaluate(SISTER_AUDCAD, ArraySize(SISTER_AUDCAD), forBuy);
      else if(baseSym == "EURCHF") fs = FlowEvaluate(SISTER_EURCHF, ArraySize(SISTER_EURCHF), forBuy);
      else if(baseSym == "AUDNZD") fs = FlowEvaluate(SISTER_AUDNZD, ArraySize(SISTER_AUDNZD), forBuy);
      else if(baseSym == "GBPNZD") fs = FlowEvaluate(SISTER_GBPNZD, ArraySize(SISTER_GBPNZD), forBuy);
      // ─── جفت‌ارزهای آینده‌نگر ──────────────────────────────────────
      else if(baseSym == "EURUSD") fs = FlowEvaluate(SISTER_EURUSD, ArraySize(SISTER_EURUSD), forBuy);
      else if(baseSym == "EURGBP") fs = FlowEvaluate(SISTER_EURGBP, ArraySize(SISTER_EURGBP), forBuy);
      else if(baseSym == "GBPUSD") fs = FlowEvaluate(SISTER_GBPUSD, ArraySize(SISTER_GBPUSD), forBuy);
      else if(baseSym == "USDJPY") fs = FlowEvaluate(SISTER_USDJPY, ArraySize(SISTER_USDJPY), forBuy);
      else if(baseSym == "USDCAD") fs = FlowEvaluate(SISTER_USDCAD, ArraySize(SISTER_USDCAD), forBuy);
      else if(baseSym == "AUDUSD") fs = FlowEvaluate(SISTER_AUDUSD, ArraySize(SISTER_AUDUSD), forBuy);
      else if(baseSym == "NZDUSD") fs = FlowEvaluate(SISTER_NZDUSD, ArraySize(SISTER_NZDUSD), forBuy);
      else if(baseSym == "USDCHF") fs = FlowEvaluate(SISTER_USDCHF, ArraySize(SISTER_USDCHF), forBuy);
      else if(baseSym == "CADJPY") fs = FlowEvaluate(SISTER_CADJPY, ArraySize(SISTER_CADJPY), forBuy);
      else if(baseSym == "GBPAUD") fs = FlowEvaluate(SISTER_GBPAUD, ArraySize(SISTER_GBPAUD), forBuy);
      else if(baseSym == "EURAUD") fs = FlowEvaluate(SISTER_EURAUD, ArraySize(SISTER_EURAUD), forBuy);
      else if(baseSym == "NZDCAD") fs = FlowEvaluate(SISTER_NZDCAD, ArraySize(SISTER_NZDCAD), forBuy);
      else if(baseSym == "GBPCAD") fs = FlowEvaluate(SISTER_GBPCAD, ArraySize(SISTER_GBPCAD), forBuy);
      else if(baseSym == "AUDJPY") fs = FlowEvaluate(SISTER_AUDJPY, ArraySize(SISTER_AUDJPY), forBuy);
      else if(baseSym == "GBPJPY") fs = FlowEvaluate(SISTER_GBPJPY, ArraySize(SISTER_GBPJPY), forBuy);
      else known = false;

      if(!known)
      {
         newFLOW = 1;
         flowTxt = "● FLOW: N/A   ";
         flowTip = StringFormat(
            "FLOW: سیمبل %s در Sister Matrix نیست\n"
            "پشتیبانی: AUDCAD | EURCHF | AUDNZD | GBPNZD", _Symbol);
      }
      else
      {
         // 🆕 v8.0: آستانه‌های واقع‌بینانه FLOW
         // قبلی: -0.5 → قرمز (باعث ۵۴٪ False Red می‌شد)
         // جدید: -5.0 → قرمز (سونامی واقعی = ۴+ زوج خواهر علیه ما)
         // 🆕 v13.15: GBPNZD آستانه پایین‌تر — max score matrix جدید ≈8.0 (قبلاً 8.5)
         double flowGreenTh, flowRedTh;
         if(baseSym == "GBPNZD")
         {
            flowGreenTh =  2.0;
            flowRedTh   = -4.0;
         }
         else
         {
            flowGreenTh =  3.0;
            flowRedTh   = -5.0;
         }

         if(fs > flowGreenTh)   newFLOW = 0;   // سبز
         else if(fs >= flowRedTh) newFLOW = 1;   // زرد
         else                newFLOW = 2;   // قرمز (سونامی واقعی)

         string arrow = (fs > 0.5) ? "▲" : (fs < -0.5) ? "▼" : "→";
         flowTxt = StringFormat("● FLOW:%+.1f%s  ", fs, arrow);
         bt_flowScore = fs;   // 🆕 snapshot برای CSV
         g_lastFlowScore = fs; // 🆕 v8.0: برای GOLDEN rule

         string stDesc = (newFLOW == 0) ? "جریان پول موافق - صبر کن" :
                         (newFLOW == 1) ? "بازار دوگانه - آماده‌باش" :
                                          "⚠️ سونامی/Risk-Off - خطر!";
         flowTip = StringFormat(
            "Flow — جریان پول\n"
            "امتیاز: %+.2f %s | جفت: %s\n"
            "وضعیت: %s\n"
            "━━━━━━━━━━\n"
            "🟢 موافق : Xmoon خوشحاله\n"
            "🟡 مختلط : مراقب باش\n"
            "🔴 سونامی: Crisis + Flow قرمز = فرار\n"
            "محاسبه: ارزهای خواهر در H4",
            fs, arrow, baseSym, stDesc);
      }
   }


   // ════════════════════════════════════════════════════════════════
   // 🆕 v10.4: ZOMBIE → Absolute-Grid Zone Classifier
   // ─────────────────────────────────────────────────────────────────
   // طبقه از گرید مطلق per-symbol خوانده می‌شود (نه بر اساس قیمت ورود).
   // در زمان باز شدن پوزیشن g_zombieEntryZone ثبت شده است.
   // رنگ ZOMBIE = مقایسه طبقه فعلی با طبقه ورود + جهت پوزیشن.
   //   Buy : current > entry → سبز  | == → سبز  | < → قرمز
   //   Sell: برعکس
   //   فاصله از مرز ≤ ZoneBorderYellowPips → چراغ زرد
   //   ارز خارج از جدول → چراغ خاکستری (Unsupported)
   // ─────────────────────────────────────────────────────────────────

   int    newZOMBIE   = 0;     // 0=سبز, 1=زرد, 2=قرمز, -1=خاکستری(unsupported)
   string zombieTxt   = "● ZONE: --     ";
   string zombieTip   = "ZONE: اطلاعات در حال بارگذاری...";
   int    zoneNumber  = 0;
   int    zoneWPips   = 0;

   SymbolZoneCfg zcfg;
   bool   zSupported = Zone_GetCfg(_Symbol, zcfg);
   g_zombieSupported = zSupported;

   if(!zSupported)
   {
      newZOMBIE = -1;   // خاکستری
      zombieTxt = "● ZONE: N/A    ";
      zombieTip = StringFormat(
         "این ارز (%s) در جدول Zone پشتیبانی نمی‌شود.\n"
         "برای فعال کردن، یک ردیف به g_zoneTable[] در کد اضافه کنید:\n"
         "   { \"%s\", base_low, base_high, widthPips, true }",
         _Symbol, _Symbol);
   }
   else
   {
      double pipSz   = GetPipSize(_Symbol);
      zoneWPips      = zcfg.widthPips;
      g_zombieZoneWidthPips = (double)zcfg.widthPips;

      // قیمت فعلی (Bid لحظه‌ای؛ در بکتست هم درست کار می‌کند)
      double currPx = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(currPx <= 0.0) currPx = iClose(_Symbol, PERIOD_H1, 0);

      zoneNumber = Zone_ComputeFromPrice(_Symbol, currPx);
      g_zombieCurrentZone = zoneNumber;

      // اگر طبقه ورود هنوز ثبت نشده (مثلاً بکتست بدون پوزیشن واقعی)،
      // طبقه فعلی را به عنوان مبنا در نظر بگیر
      if(g_zombieEntryPrice <= 0.0)
         g_zombieEntryZone = zoneNumber;

      int delta = zoneNumber - g_zombieEntryZone;
      double borderDistPips = Zone_DistanceToBorderPips(_Symbol, currPx);
      bool   nearBorder = (borderDistPips <= (double)ZoneBorderYellowPips);

      // ── v10.8: H1 Confirmation Filter ────────────────────────────
      // قبل از قرمز کردن، باید ZombieH1ConfirmBars کندل H1 متوالی در Zone جدید بسته شود
      // اگر سبز است (zone بهتر یا برابر) → فوری سبز، بدون تأخیر
      string h1StatusStr = "";
      bool h1Confirmed = Zone_IsConfirmedByH1(_Symbol, zoneNumber, g_zombieEntryZone, forBuy, h1StatusStr);

      // رنگ بر اساس جهت پوزیشن + تأیید H1
      // Buy: delta>0 سبز | delta==0 سبز | delta<0 → فقط بعد از تأیید H1 قرمز
      // Sell: برعکس
      int effDelta = forBuy ? delta : -delta;
      if(effDelta < 0)
      {
         if(h1Confirmed) newZOMBIE = 2;   // قرمز — تأیید شده توسط H1
         else            newZOMBIE = 1;   // زرد — در انتظار تأیید H1 (کاهش نویز)
      }
      else                    newZOMBIE = 0;   // سبز (delta>=0)
      if(nearBorder && newZOMBIE == 0) newZOMBIE = 1;   // زرد روی مرز (فقط اگر سبز بود)

      // نمایش
      string lowS  = DoubleToString(Zone_PriceLow(_Symbol, zoneNumber),     _Digits);
      string highS = DoubleToString(Zone_PriceLow(_Symbol, zoneNumber + 1), _Digits);
      // v10.8: نمایش شمارنده H1 در داشبورد
      zombieTxt = StringFormat("● ZONE:%+d (E:%+d)%s", zoneNumber, g_zombieEntryZone, h1StatusStr);

      string colorTag = (newZOMBIE==2)?"🔴 قرمز (تأیید H1)":(newZOMBIE==1 && effDelta<0)?"🟡 زرد (انتظار H1)":(newZOMBIE==1)?"🟡 زرد (نزدیک مرز)":"🟢 سبز";
      // v10.9: h1count از statusStr استخراج می‌شود (stateless — نیازی به گلوبال نیست)
      int h1count_display = 0;
      if(StringFind(h1StatusStr, "H1:") >= 0)
      {
         string tmp = h1StatusStr;
         StringReplace(tmp, " [H1:", ""); StringReplace(tmp, "]", "");
         string parts[]; StringSplit(tmp, '/', parts);
         if(ArraySize(parts) >= 1) h1count_display = (int)StringToInteger(parts[0]);
      }
      string h1Info = StringFormat(
         "─────────────────────────────────\n"
         "کندل‌های H1 متوالی در Zone: %d از %d لازم\n"
         "وضعیت: %s\n",
         h1count_display,
         ZombieH1ConfirmBars,
         h1Confirmed ? "✅ تأیید شده" : "⏳ در انتظار تأیید",
         ZombieH1ConfirmBars);

      // 🩹 Patch 4 (V12.06): Tooltip فقط شماره طبقه‌ها (نه قیمت)
      zombieTip = StringFormat(
         "طبقه ورود   : %+d\n"
         "طبقه فعلی   : %+d\n"
         "─────────────────────────────────\n"
         "%s\n%s",
         g_zombieEntryZone,
         zoneNumber,
         h1Info,
         colorTag);

      // رسم/بازرسم خطوط طبقات — فقط وقتی پارامتر واقعاً تغییر کند (بدون فلیکر)
      if(ShowZoneLines)
      {
         static int    s_lastDrawnEntryZone = INT_MIN;
         static string s_lastDrawnSym       = "";
         static long   s_lastDrawnChartId   = -1;
         static int    s_lastDrawnCMode     = -999;   // v11.92
         long curChartId = ChartID();
         // v11.92: colorMode: 0=gray(no pos) | 1=Buy | 2=Sell
         int _cmode = (!hasPos) ? 0 : (forBuy ? 1 : 2);
         bool needRebuild = (s_lastDrawnEntryZone != g_zombieEntryZone
                             || s_lastDrawnSym    != _Symbol
                             || s_lastDrawnChartId != curChartId
                             || s_lastDrawnCMode  != _cmode               // v11.92
                             || ObjectFind(0, "ZombieLine_0") < 0);  // اگر خط Zone 0 حذف شده بود
         if(needRebuild)
         {
            double basePx = zcfg.base_low;   // پایه ثابت از جدول (نه Zone_PriceLow(0) که همان است)
            double wPx    = (double)zcfg.widthPips * pipSz;
            DrawAbsoluteZoneLines(basePx, wPx, pipSz, ZoneLineCount, g_zombieEntryZone, _cmode);
            s_lastDrawnEntryZone = g_zombieEntryZone;
            s_lastDrawnSym       = _Symbol;
            s_lastDrawnChartId   = curChartId;
            s_lastDrawnCMode     = _cmode;   // v11.92
         }
         else
         {
            // پارامتر تغییر نکرده → فقط لیبل‌ها را بروز کن (بدون فلیکر)
            RefreshZoneLabelPositions();
         }
      }
   }

   // متغیرهای سازگاری با امضای BT_TrackLightChanges / LogHourlySnapshot
   double bt_zombieScore    = (double)zoneNumber;
   double bt_zombieMidShift = (double)zoneWPips;

   // ══════════════════════════════════════════════════════════════
   // 🆕 v12.14: KILLER — پیش‌محاسبه قبل از BT log
   // هر دو جهت Buy و Sell | Regime H1 ثابت | ZoneDelta | TsAgainst | MaxStep
   // آپدیت: هر 30 ثانیه + هر تغییر پوزیشن (هر بار TL_Update)
   // ══════════════════════════════════════════════════════════════
   {
      if(hasPos)
      {
         int _kCur    = Zone_ComputeFromPrice(_Symbol, SymbolInfoDouble(_Symbol, SYMBOL_BID));
         int _kEntry  = g_zombieEntryZone;
         // ZoneDelta: چند Zone از ورود در جهت ضرر رفتیم
         // BUY:  قیمت پایین‌تر رفته  → entryZone - currentZone > 0
         // SELL: قیمت بالاتر رفته    → currentZone - entryZone > 0
         int    _kDelta  = forBuy ? (_kEntry - _kCur) : (_kCur - _kEntry);
         bool   _kTrend  = ComputeRegimeTrendingH1();
         double _kTs     = forBuy ? -g_csvScore : g_csvScore;
         int    _kStep   = GetMaxStep(forBuy);

         bool _kRed    = _kTrend && (_kDelta >= 1) && (_kTs >= 50.0) && (_kStep >= 4);
         bool _kYellow = _kTrend && (_kDelta >= 1) && (_kTs >= 40.0) && (_kStep >= 3) && !_kRed;
         int  _kState  = _kRed ? 2 : (_kYellow ? 1 : 0);

         g_lightKILLER = _kState;

         // نوتیف فقط در Live
         if(!(bool)MQLInfoInteger(MQL_TESTER) && Alert_OnKiller)
         {
            bool _kEdge = (_kState == 2 && g_prevAlertKILLER != 2);
            if(_kState == 2 && Alert_CooldownOK(g_lastAlertTime_KILLER, _kEdge))
            {
               string _kDir = forBuy ? "BUY" : "SELL";
               string _kDng = forBuy ? "نزولی" : "صعودی";
               Alert_Send(StringFormat(
                  "HelpMe [%s %s]\n"
                  "☠️ KILLER قرمز شد\n"
                  "━━━━━━━━━━━━━━━━\n"
                  "پله: %d از ۵\n"
                  "Zone ضرر: %d طبقه\n"
                  "روند مخالف — Score: %+.0f\n"
                  "━━━━━━━━━━━━━━━━\n"
                  "الان وقت خروجه یا هج کن",
                  _Symbol, _kDir, _kStep, _kDelta, g_csvScore));
            }
            if(_kState == 1 && g_prevAlertKILLER < 1)
            {
               string _kDir = forBuy ? "BUY" : "SELL";
               Alert_Send(StringFormat(
                  "HelpMe [%s %s]\n"
                  "⚠️ KILLER هشدار\n"
                  "━━━━━━━━━━━━━━━━\n"
                  "پله: %d | Zone: %d | Score: %+.0f\n"
                  "━━━━━━━━━━━━━━━━\n"
                  "اگه پله ۴ شد قرمز میشه\n"
                  "چشم باز باش",
                  _Symbol, _kDir, _kStep, _kDelta, g_csvScore));
            }
            g_prevAlertKILLER = _kState;
         }
      }
      else
      {
         g_lightKILLER    = -1;
         g_prevAlertKILLER = -1;
      }
   }

   // نمایش KILLER در داشبورد (🆕 v13.05: از push-only به dashboard display)
   {
      string kTxt, kTip;
      switch(g_lightKILLER)
      {
         case -1: kTxt = "● Killer: --";      kTip = "پوزیشنی نیست یا پله کمتر از ۵"; break;
         case  0: kTxt = "● Killer: Safe";    kTip = "اوضاع عادیه — روند موافقه یا Zone مشکلی نداره"; break;
         case  1: kTxt = "● Killer: Warning"; kTip = StringFormat("پله %d | Zone ضرر | Score: %.0f\nاگه پله ۴ شد قرمز میشه", GetMaxStep(forBuy), g_csvScore); break;
         case  2: kTxt = "● Killer: Danger";  kTip = "☠️ الان وقت خروجه یا هج کن!"; break;
         default: kTxt = "● Killer: --";      kTip = "";
      }
      TL_SetLight("KILLER", g_lightKILLER, kTxt, kTip);
   }

   // 🆕 v13.12: Market Phase — نمایش آخرین مقدار محاسبه‌شده
   // (Calc_MktPhase هر روز یکبار در OnTick صدا زده میشه)
   // اینجا فقط مطمئن میشیم داشبورد همیشه آخرین state رو نشون میده
   Calc_MktPhase();
   // 🐛 v13.30 FIX3b: هر بار که مقدار داریم آپدیت کن (نه فقط NeedRedraw)
   if(g_lightMktPhase >= 0)
   {
      string _mktLblP = (g_lightMktPhase==0) ? "Range" : (g_lightMktPhase==1) ? "Neutral" : "Trend!";
      string _mktTipP = StringFormat("Mkt Phase | MA10=%.3f", g_mktPhaseRatio);
      TL_SetLight("MKTPHASE", g_lightMktPhase, "● Mkt Phase: " + _mktLblP, _mktTipP);
      g_mktPhaseNeedRedraw = false;
   }

   // 🆕 v13.14: Spike Detector — 🆕 v14.03: فقط در بستن کندل
   if(runRuleBlock) Calc_SpikeDetector();

   // ─── ذخیره state و بروزرسانی کامل نمایش ──────────────────────
   // 🆕 BACKTEST CSV: ردیابی تغییرات چراغ قبل از آپدیت state ها
   // OLD state = g_lightXxx هنوز قبلی است
   if((bool)MQLInfoInteger(MQL_TESTER))
   {
      BT_TrackLightChanges(
         newRTM, newTrend, newStruct, newFLOW, newZOMBIE,
         g_lightRTM, g_lightTrend, g_lightStruct, g_lightFLOW, g_lightZOMBIE,
         bt_rtmX, bt_rtmArrow, bt_rtmCT,
         bt_adxVal, bt_erH4, bt_erLabel,
         bt_d1Status, bt_d1Pips, bt_flowScore,
         bt_zombieScore, bt_zombieMidShift,  // v10.3: zone number و width پشت سازگاری
         forBuy ? "BUY" : "SELL");
      // v11.8: محاسبه HIGH ALERT برای ثبت در CSV
      bool _btHighAlert = false;
      if(forBuy  && bt_adxVal >= 35.0 && bt_flowScore < -7.0) _btHighAlert = true;
      if(!forBuy && bt_adxVal >= 35.0 && bt_flowScore >  7.0) _btHighAlert = true;
      LogHourlySnapshot(
         newRTM, newTrend, newStruct, newFLOW, newZOMBIE,
         bt_rtmX, bt_rtmArrow, bt_adxVal, bt_erH4, bt_flowScore,
         bt_d1Status, bt_zombieScore, bt_zombieMidShift,  // v10.3: zone و width
         forBuy ? "BUY" : "SELL", _btHighAlert, g_lightKILLER);  // 🆕 v12.14: KILLER
   }

   g_lightRTM    = newRTM;
   g_lightTrend  = newTrend;
   g_lightStruct = newStruct;
   g_lightFLOW   = newFLOW;
   g_lightZOMBIE = newZOMBIE;

   TL_SetLight("RTM",    newRTM,    rtmTxt,    rtmTip);
   TL_SetLight("TREND",  newTrend,  trendTxt,  trendTip);
   TL_SetLight("STRUCT", newStruct, structTxt, structTip);
   TL_SetLight("FLOW",   newFLOW,   flowTxt,   flowTip);
   // v10.4: ZOMBIE رنگی است — state از منطق گرید مطلق آمده
   TL_SetLight("ZOMBIE", newZOMBIE, zombieTxt, zombieTip);

   // ══════════════════════════════════════════════════════════════
   // v11.0: HIGH ALERT — پیش‌هشدار فوری قبل از CRISIS
   // شرط Buy : ADX >= 35 AND Flow < -7.0
   // شرط Sell: ADX >= 35 AND Flow > +7.0
   // فعال می‌شود قبل از اینکه CRISIS قرمز بشود
   // ══════════════════════════════════════════════════════════════
   {
      bool highAlert = false;
      if(forBuy  && g_lastAdxVal >= 35.0 && g_lastFlowScore < -7.0) highAlert = true;
      if(!forBuy && g_lastAdxVal >= 35.0 && g_lastFlowScore >  7.0) highAlert = true;

      if(highAlert)
      {
         // چشمک: هر تیک alternating text برای جلب توجه
         static int s_alertTick = 0;
         s_alertTick++;
         string alertTxt = (s_alertTick % 2 == 0)
            ? "⚠️ HIGH ALERT ⚠️ "
            : "!! HIGH ALERT !! ";
         TL_SetLight("HIGHALT", 2, alertTxt,
            StringFormat("High Alert\n"
               "ADX: %.0f (باید زیر ۳۵ باشه) | Flow: %.1f\n"
               "━━━━━━━━━━\n"
               "یعنی Crisis داره نزدیک میشه\n"
               "اگه Crisis قرمز شد — آماده خروج باش",
               g_lastAdxVal, g_lastFlowScore));
      }
      else
      {
         TL_SetLight("HIGHALT", 0, "● ALERT: OK    ",
            "High Alert: همه چیز عادیه\nADX زیر ۳۵ یا Flow در محدوده مجاز");
      }
   }


   // ── v10.2: CRISIS — محاسبه لحظه‌ای با Orange state جدید ─────────
   {
      // v10.3: ZOMBIE از RC حذف شد (دیگر چراغ رنگی نیست، Zone counter است)
      // RC = RTM + TREND + STRUCT + FLOW → max = 4
      int rc = (newRTM==2?1:0) + (newTrend==2?1:0) + (newStruct==2?1:0) + (newFLOW==2?1:0);
      g_lastRedCount  = rc;

      // TrendScore علیه پوزیشن (stateless — هر بار از g_csvScore تازه محاسبه می‌شود)
      double tsAgainst = forBuy ? -g_csvScore : g_csvScore;

      // g_lightGOLDEN: state داخلی CRISIS برای BT_TrackLightChanges
      // 🆕 v10.2: Orange = 3 اضافه شد
      // 🐛 v13.33 FIX: flowAgainst = -g_lastFlowScore (همیشه نگیشن، هر دو جهت)
      // قبلاً: forBuy ? -fs : fs → برای Sell: fs=fsSell=-9.62 (منفی) → bug
      // الان: -fs → برای Sell: -(-9.62)=+9.62 → Red درست ✓
      // 🆕 v13.15: آستانه‌ها از تابع مشترک — همیشه سینک با UpdateCrisisLight
      double _fa = -g_lastFlowScore;  // flowAgainst (مثبت = بد)

      double gt_RedA_ADX, gt_RedA_Flow, gt_RedB_ADX, gt_RedB_Flow;
      double gt_OrA_ADX, gt_OrA_Flow, gt_OrB_ADX, gt_OrB_Ts;
      double gt_OrC_ADX, gt_OrC_Flow, gt_OrC_Ts;
      double gt_OrD_ADX, gt_OrD_Ts;   // 🆕 v13.16
      double gt_Y2_ADX, gt_Y2_Flow, gt_Y3_Flow, gt_Y3_Ts;
      double gt_Y4_ADX, gt_Y4_Ts, gt_Y5_ADX, gt_Y5_Flow;
      Crisis_GetThresholds(
         gt_RedA_ADX, gt_RedA_Flow, gt_RedB_ADX, gt_RedB_Flow,
         gt_OrA_ADX, gt_OrA_Flow, gt_OrB_ADX, gt_OrB_Ts,
         gt_OrC_ADX, gt_OrC_Flow, gt_OrC_Ts,
         gt_OrD_ADX, gt_OrD_Ts,   // 🆕 v13.16
         gt_Y2_ADX, gt_Y2_Flow, gt_Y3_Flow, gt_Y3_Ts,
         gt_Y4_ADX, gt_Y4_Ts, gt_Y5_ADX, gt_Y5_Flow);

      bool isRedA   = (rc >= 3 && _fa >= gt_RedA_Flow && g_lastAdxVal > gt_RedA_ADX);
      bool isRedB   = (rc >= 2 && _fa >= gt_RedB_Flow && g_lastAdxVal > gt_RedB_ADX);
      bool isOrangeA= (rc >= 2 && _fa >= gt_OrA_Flow && g_lastAdxVal > gt_OrA_ADX);
      bool isOrangeB= (rc >= 3 && tsAgainst > gt_OrB_Ts && g_lastAdxVal > gt_OrB_ADX);
      bool isOrangeC= (rc >= 2 && _fa >= gt_OrC_Flow && g_lastAdxVal > gt_OrC_ADX && tsAgainst > gt_OrC_Ts);
      // 🆕 v13.16 Orange-D: مستقل از FLOW/RC — همگام با UpdateCrisisLight
      bool isOrangeD= (tsAgainst > gt_OrD_Ts && g_lastAdxVal > gt_OrD_ADX);
      bool isYellow = (rc >= 2)
                   || (_fa >= gt_Y2_Flow && g_lastAdxVal > gt_Y2_ADX)
                   || (rc >= 2 && _fa >= gt_Y3_Flow && tsAgainst > gt_Y3_Ts)
                   || (rc >= 2 && tsAgainst > gt_Y4_Ts && g_lastAdxVal > gt_Y4_ADX)
                   || (rc >= 2 && _fa >= gt_Y5_Flow && g_lastAdxVal > gt_Y5_ADX);

      // g_lightGOLDEN mapping: 0=Green 1=Yellow 2=Orange 3=Red (legacy compat: Red maps to 2 for BT)
      if(isRedA || isRedB)
         g_lightGOLDEN = 2;    // Red → legacy 2
      else if(isOrangeA || isOrangeB || isOrangeC || isOrangeD)
         g_lightGOLDEN = 2;    // Orange → legacy 2 (보수적으로 Red로 처리)
      else if(isYellow)
         g_lightGOLDEN = 1;
      else
         g_lightGOLDEN = 0;

      UpdateCrisisLight(rc, g_lastFlowScore, g_lastAdxVal, g_csvScore, forBuy);
   }

   // ── بررسی تغییر چراغ‌ها و ارسال اعلان ─────────────────────────
   if(!(bool)MQLInfoInteger(MQL_TESTER))  // در بکتست اعلان نده
   {
      bool _highAlertNow = (g_lastAdxVal >= 35.0) &&
                           (forBuy ? (g_lastFlowScore < -7.0) : (g_lastFlowScore > 7.0));
      Alert_CheckAndSend(forBuy, _highAlertNow);

      // 🆕 v13.21b: snapshot وضعیت هر جهت — مستقل از forBuy نمایش
      // TL_Update برای هر جهت جداگانه اجرا می‌شه؛ ما آخرین مقدار هر جهت رو نگه می‌داریم
      if(forBuy)
      {
         g_gbnzdCrisisBuy  = g_crisisState;
         // جهت پوزیشن: از g_lightSpike مستقیم (Flow gate از g_lastFlowScore همین جهت)
         g_gbnzdSpikeBuy   = g_lightSpike;
         g_gbnzdAdxBuy     = g_lastAdxVal;
         g_gbnzdFlowBuy    = g_lastFlowScore;
         // 🐛 v13.40 FIX-B + 🆕 v14.03: PrevCrisis فقط در بستن کندل sync می‌شود
         if(runRuleBlock) { g_gbpnzdPrevCrisisBuy = g_gbnzdCrisisBuy; g_gbpnzdPrevSpikeBuy = g_gbnzdSpikeBuy; }

         // 🐛 v13.46 FIX-B4: جهت مقابل (Sell) با فرمول جهت‌دار آپدیت بشه
         // مشکل: g_gbnzdSpikeSell تا الان از آخرین no-position/hedge مانده بود (stale)
         // چون TL_Update forBuy=true فقط SpikeBuy رو آپدیت می‌کرد.
         // راه‌حل: همان فرمول FIX-B3 (no-position) برای جهت مقابل اجرا بشه.
         if(Alert_OnGBPNZDRule && IsRuleSymbol(_Symbol))
         {
            double _fsSellOpp = Rule_FlowForSymbol(_Symbol, false);
            double _baseOpp   = (g_lightSpike >= 0 && g_spikeScore > 0.0) ? g_spikeScore : 0.0;
            int    _rpOpp     = (_baseOpp < 1.00) ? 0 : (_baseOpp <= 1.50) ? 1 : 2;
            bool   _frOpp     = (_fsSellOpp < -4.0);
            bool   _fyOpp     = (_baseOpp >= 2.0 && _fsSellOpp < 2.0 && _fsSellOpp >= -4.0);
            if(_rpOpp >= 1 && _frOpp)  g_gbnzdSpikeSell = _rpOpp;
            else if(_fyOpp)             g_gbnzdSpikeSell = 1;
            else                        g_gbnzdSpikeSell = 0;
            g_gbnzdFlowSell = _fsSellOpp;
            g_gbpnzdPrevSpikeSell = g_gbnzdSpikeSell;
         }
      }
      else
      {
         g_gbnzdCrisisSell = g_crisisState;
         // جهت پوزیشن: از g_lightSpike مستقیم
         g_gbnzdSpikeSell  = g_lightSpike;
         g_gbnzdAdxSell    = g_lastAdxVal;
         g_gbnzdFlowSell   = g_lastFlowScore;
         // 🐛 v13.40 FIX-B + 🆕 v14.03: PrevCrisis فقط در بستن کندل sync می‌شود
         if(runRuleBlock) { g_gbpnzdPrevCrisisSell = g_gbnzdCrisisSell; g_gbpnzdPrevSpikeSell = g_gbnzdSpikeSell; }

         // 🐛 v13.46 FIX-B4: جهت مقابل (Buy) با فرمول جهت‌دار آپدیت بشه
         if(Alert_OnGBPNZDRule && IsRuleSymbol(_Symbol))
         {
            double _fsBuyOpp  = Rule_FlowForSymbol(_Symbol, true);
            double _baseOpp   = (g_lightSpike >= 0 && g_spikeScore > 0.0) ? g_spikeScore : 0.0;
            int    _rpOpp     = (_baseOpp < 1.00) ? 0 : (_baseOpp <= 1.50) ? 1 : 2;
            bool   _frOpp     = (_fsBuyOpp < -4.0);
            bool   _fyOpp     = (_baseOpp >= 2.0 && _fsBuyOpp < 2.0 && _fsBuyOpp >= -4.0);
            if(_rpOpp >= 1 && _frOpp)  g_gbnzdSpikeBuy = _rpOpp;
            else if(_fyOpp)             g_gbnzdSpikeBuy = 1;
            else                        g_gbnzdSpikeBuy = 0;
            g_gbnzdFlowBuy  = _fsBuyOpp;
            g_gbpnzdPrevSpikeBuy = g_gbnzdSpikeBuy;
         }
      }
      // 🆕 v14.03: Alert_CheckGBPNZDRule فقط در بستن کندل چارت
      if(runRuleBlock) Alert_CheckGBPNZDRule();
   }

   ChartRedraw(0);
}




//+------------------------------------------------------------------+
//| BT_TrackLightChanges: ردیابی تغییر چراغ‌ها + کپی کامل snapshot |
//| فقط وقتی یک چراغ از غیرقرمز → قرمز می‌شود رویداد ثبت می‌کند  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| LogHourlySnapshot: لاگ ساعتی وضعیت چراغ‌ها (فقط بکتست)        |
//+------------------------------------------------------------------+
void LogHourlySnapshot(
   int stRTM, int stTrend, int stStruct, int stFLOW, int stZOMBIE,
   double rtmX, string rtmArrow, double adxVal, double erH4, double flowScore,
   string d1Status, double zombieScoreOrZone, double zombieMidShiftOrWidth,
   string direction, bool highAlertActive = false, int stKILLER = -1)
{
   if(!(bool)MQLInfoInteger(MQL_TESTER)) return;

   datetime now = iTime(_Symbol, PERIOD_H1, 1);
   if(now == 0) now = TimeCurrent();

   // 🐛 v13.47 FIX6: از timestamp کامل به‌جای فقط hour-of-day استفاده کن
   // مشکل: مقایسه mdt.hour (0-23) — اگه gap داده (مثلاً بازگشایی آخر هفته)
   //        دقیقاً با همان عدد ساعتِ قبل از gap یکی بیفتد، آن ساعت رد می‌شود.
   // راه‌حل: timestamp رند‌شده به مرز ساعت (مثل g_gbpnzdLastH)
   datetime curHourTs = (datetime)(((long)now) / 3600 * 3600);
   if(curHourTs == (datetime)g_lastLoggedHour) return;
   g_lastLoggedHour = (int)curHourTs;

   MqlDateTime mdt;
   TimeToStruct(now, mdt);
   int gmtH = mdt.hour;
   string sess = "Off-Hours";
   if(gmtH >= 0  && gmtH < 9)  sess = "Tokyo";
   if(gmtH >= 8  && gmtH < 17) sess = "London";
   if(gmtH >= 13 && gmtH < 22) sess = "New York";
   if(gmtH >= 8  && gmtH < 9)  sess = "Tokyo-London";
   if(gmtH >= 13 && gmtH < 17) sess = "London-NewYork";

   // محاسبه Crisis لحظه‌ای (v10.3: ZOMBIE از RC حذف شد)
   int rc = (stRTM==2?1:0)+(stTrend==2?1:0)+(stStruct==2?1:0)+(stFLOW==2?1:0);
   bool isBuy    = (direction == "BUY");
   double tsAg   = isBuy ? -g_csvScore : g_csvScore;
   // 🆕 v13.15: آستانه‌ها از تابع مشترک — همیشه سینک با UpdateCrisisLight
   double lt_RedA_ADX, lt_RedA_Flow, lt_RedB_ADX, lt_RedB_Flow;
   double lt_OrA_ADX, lt_OrA_Flow, lt_OrB_ADX, lt_OrB_Ts;
   double lt_OrC_ADX, lt_OrC_Flow, lt_OrC_Ts;
   double lt_OrD_ADX, lt_OrD_Ts;   // 🆕 v13.16
   double lt_Y2_ADX, lt_Y2_Flow, lt_Y3_Flow, lt_Y3_Ts;
   double lt_Y4_ADX, lt_Y4_Ts, lt_Y5_ADX, lt_Y5_Flow;
   Crisis_GetThresholds(
      lt_RedA_ADX, lt_RedA_Flow, lt_RedB_ADX, lt_RedB_Flow,
      lt_OrA_ADX, lt_OrA_Flow, lt_OrB_ADX, lt_OrB_Ts,
      lt_OrC_ADX, lt_OrC_Flow, lt_OrC_Ts,
      lt_OrD_ADX, lt_OrD_Ts,    // 🆕 v13.16
      lt_Y2_ADX, lt_Y2_Flow, lt_Y3_Flow, lt_Y3_Ts,
      lt_Y4_ADX, lt_Y4_Ts, lt_Y5_ADX, lt_Y5_Flow);

   bool isRedA   = (rc >= 3 && flowScore <= -lt_RedA_Flow && adxVal > lt_RedA_ADX);
   bool isRedB   = (rc >= 2 && flowScore <= -lt_RedB_Flow && adxVal > lt_RedB_ADX);
   // 🐛 v13.47 FIX2: Orange A/B/C در بکتست اضافه شد
   // مشکل: LogHourlySnapshot فقط isOrangeD داشت — A/B/C (که به FLOW وابسته‌ند)
   //        وجود نداشتند. بکتست سیستماتیک آروم‌تر از واقعیت نشون داده می‌شد
   //        و STOP-B هایی که نیاز به Orange+Spike Warning دارند اصلاً fire نمی‌شدند.
   //        (متغیرهای lt_OrA/B/C declare شده بودند اما هیچ‌جا استفاده نمی‌شدند)
   // راه‌حل: همان فرمول UpdateCrisisLight و GBPNZD_Replay_CrisisAtBar
   bool isOrangeA= (rc >= 2 && flowScore <= -lt_OrA_Flow && adxVal > lt_OrA_ADX);
   bool isOrangeB= (rc >= 3 && tsAg > lt_OrB_Ts && adxVal > lt_OrB_ADX);
   bool isOrangeC= (rc >= 2 && flowScore <= -lt_OrC_Flow && adxVal > lt_OrC_ADX && tsAg > lt_OrC_Ts);
   // 🆕 v13.16 Orange-D: مستقل از FLOW/RC — برای کالیبراسیون CSV با UpdateCrisisLight سینک شد
   bool isOrangeD= (tsAg > lt_OrD_Ts && adxVal > lt_OrD_ADX);
   bool isYellow = (rc >= 2) || (flowScore <= -lt_Y2_Flow && adxVal > lt_Y2_ADX)
                || (rc >= 2 && flowScore <= -lt_Y3_Flow && tsAg > lt_Y3_Ts)
                || (rc >= 2 && tsAg > lt_Y4_Ts && adxVal > lt_Y4_ADX)
                || (rc >= 2 && flowScore <= -lt_Y5_Flow && adxVal > lt_Y5_ADX);
   // ترتیب اولویت مطابق UpdateCrisisLight → Red > Orange > Yellow > Green
   int crisisState = (isRedA || isRedB) ? 2
                   : (isOrangeA || isOrangeB || isOrangeC || isOrangeD) ? 3
                   : isYellow ? 1 : 0;

   // افزودن به آرایه
   ArrayResize(g_hourlyLog, g_hourlyCount + 1);
   int _hi = g_hourlyCount;
   g_hourlyCount++;

   g_hourlyLog[_hi].snapTime       = now;
   g_hourlyLog[_hi].direction      = direction;
   g_hourlyLog[_hi].stRTM          = stRTM;
   g_hourlyLog[_hi].stTrend        = stTrend;
   g_hourlyLog[_hi].stStruct       = stStruct;
   g_hourlyLog[_hi].stFLOW         = stFLOW;
   g_hourlyLog[_hi].stZOMBIE       = stZOMBIE;  // v10.4: 0=Green,1=Yellow,2=Red,-1=Gray  [FIX v10.4.1: was nZOMBIE]
   g_hourlyLog[_hi].stCRISIS       = crisisState;
   g_hourlyLog[_hi].rtmX           = rtmX;
   g_hourlyLog[_hi].rtmArrow       = rtmArrow;
   g_hourlyLog[_hi].adxVal         = adxVal;
   g_hourlyLog[_hi].erH4           = erH4;
   g_hourlyLog[_hi].flowScore      = flowScore;
   g_hourlyLog[_hi].trendScore     = g_csvScore;
   g_hourlyLog[_hi].zombieZone     = (int)zombieScoreOrZone;     // v10.3: Zone number
   // zombieWidthPips حذف شد v10.5
   g_hourlyLog[_hi].d1Status       = d1Status;
   g_hourlyLog[_hi].regime         = g_csvRegime;
   g_hourlyLog[_hi].session        = sess;
   g_hourlyLog[_hi].spreadPt       = g_csvSpread;
   g_hourlyLog[_hi].highAlert       = highAlertActive;  // v11.8
   g_hourlyLog[_hi].stKILLER        = stKILLER;         // 🆕 v12.14
   g_hourlyLog[_hi].stMKTPHASE      = g_lightMktPhase;  // 🆕 v13.12
   g_hourlyLog[_hi].mktRatio        = g_mktPhaseRatio;  // 🆕 v13.12
   g_hourlyLog[_hi].stSPIKE         = g_lightSpike;     // 🆕 v13.14
   g_hourlyLog[_hi].spikeScore      = g_spikeScore;     // 🆕 v13.14

   // 🆕 v13.21: محاسبه وضعیت قانون ترید GBPNZD — همان منطق Alert_CheckGBPNZDRule
   // بدون تلگرام — فقط state را برای ستون CSV محاسبه می‌کند
   // 🆕 v14.00: تعمیم به هر سه سمبل Rule — قبلاً این بلاک فقط برای GBPNZD
   // اجرا می‌شد، یعنی ستون‌های Rule/Spike/Crisis در بکتست AUDCAD/EURGBP
   // اصلاً محاسبه نمی‌شدند (دقیقاً همان باگ بکتستی که گزارش شده بود).
   if(IsRuleSymbol(_Symbol))
   {
      // ── FIX v13.21b: جلوگیری از double-count ───────────────────────
      // LogHourlySnapshot هر ساعت دوبار صدا می‌شه: یکبار BUY، یکبار SELL
      // بدون guard، counter دوبار increment می‌شه و state اشتباه می‌شه
      // راه‌حل: اگه snapshot این ساعت قبلاً از همین direction آمده pass کن
      // ما worst-case (Red=بدترین) را از هر دو جهت می‌خوایم:
      // BUY را اول ثبت کن، وقتی SELL آمد worst-case را بگیر
      bool isBuySnap = (direction == "BUY");
      if(isBuySnap)
      {
         g_gbnzdCrisisBuy  = crisisState;
         g_gbnzdSpikeBuy   = g_lightSpike;
         g_gbnzdAdxBuy     = adxVal;
         g_gbnzdFlowBuy    = flowScore;
         // 🐛 v13.47 FIX4: جهت مقابل (Sell) در بکتست بیات نماند
         // مشکل: وقتی فقط BUY snapshot داریم، SpikeSell از آخرین SELL snapshot
         //        باقی می‌ماند (stale). این mirror همان FIX-B4 در لایو است.
         // راه‌حل: SpikeSell را با Flow جهت‌دار برعکس محاسبه کن
         {
            double _btFsSell = (g_gbnzdFlowSell != 0.0) ? g_gbnzdFlowSell : flowScore * -1.0;
            double _btBase   = (g_lightSpike >= 0 && g_spikeScore > 0.0) ? g_spikeScore : 0.0;
            int    _btRp     = (_btBase < 1.00) ? 0 : (_btBase <= 1.50) ? 1 : 2;
            bool   _btFr     = (_btFsSell < -4.0);
            bool   _btFy     = (_btBase >= 2.0 && _btFsSell < 2.0 && _btFsSell >= -4.0);
            if(_btRp >= 1 && _btFr)  g_gbnzdSpikeSell = _btRp;
            else if(_btFy)            g_gbnzdSpikeSell = 1;
            else                      g_gbnzdSpikeSell = 0;
         }
      }
      else
      {
         g_gbnzdCrisisSell = crisisState;
         g_gbnzdSpikeSell  = g_lightSpike;
         g_gbnzdAdxSell    = adxVal;
         g_gbnzdFlowSell   = flowScore;
         // 🐛 v13.47 FIX4: جهت مقابل (Buy) در بکتست بیات نماند
         {
            double _btFsBuy  = (g_gbnzdFlowBuy != 0.0) ? g_gbnzdFlowBuy : flowScore * -1.0;
            double _btBase   = (g_lightSpike >= 0 && g_spikeScore > 0.0) ? g_spikeScore : 0.0;
            int    _btRp     = (_btBase < 1.00) ? 0 : (_btBase <= 1.50) ? 1 : 2;
            bool   _btFr     = (_btFsBuy < -4.0);
            bool   _btFy     = (_btBase >= 2.0 && _btFsBuy < 2.0 && _btFsBuy >= -4.0);
            if(_btRp >= 1 && _btFr)  g_gbnzdSpikeBuy = _btRp;
            else if(_btFy)            g_gbnzdSpikeBuy = 1;
            else                      g_gbnzdSpikeBuy = 0;
         }
      }

      // counter و state فقط یک‌بار در ساعت آپدیت بشه — وقتی SELL آمد (یعنی هر دو داریم)
      // اگه فقط یک جهت داریم (BUY-only backtest)، با اولین snapshot آپدیت می‌کنیم
      bool bothSnapped = (g_gbnzdCrisisBuy >= 0 && g_gbnzdCrisisSell >= 0);
      bool canUpdate   = !isBuySnap || !bothSnapped;   // SELL همیشه → یا BUY وقتی SELL هنوز نیست

      if(canUpdate)
      {
         // 🐛 v13.36 FIX: state machine جهت‌دار برای BT
         bool _haBuy  = (g_gbnzdAdxBuy  >= 35.0) && (g_gbnzdFlowBuy  < -7.0);
         bool _haSell = (g_gbnzdAdxSell >= 35.0) && (g_gbnzdFlowSell >  7.0);

         // BUY
         // 🆕 v13.50 RULE-01: منطق مشترک — به‌جای کپی مستقل از Rule_UpdateCounters/Rule_Transition
         // 🐛 v13.43 FIX (حفظ‌شده در تابع مشترک): wasClean در بکتست — Orange بدون Spike ریست نمی‌کند
         // 🔤 RULE-05: این بلوک قبلاً در سند به اشتباه «BT_CheckGBPNZDRule» نامیده شده بود؛
         //    چنین تابعی در کد وجود ندارد — منطق همیشه همینجا، داخل LogHourlySnapshot بوده.
         {
            bool _bRed   = (g_gbnzdCrisisBuy == 2);
            bool _bDirty = _bRed || !(g_gbnzdSpikeBuy <= 0 || g_gbnzdSpikeBuy == -1);
            Rule_UpdateCounters(_bRed, _bDirty, g_gbpnzdCrisisRedHBuy, g_gbpnzdCleanHBuy);
            int _dummyReasonBuy = 0;   // بکتست reason را در CSV ثبت نمی‌کند (رفتار قبلی حفظ شد)
            Rule_Transition(g_gbnzdCrisisBuy, g_gbnzdSpikeBuy, _haBuy,
                             g_gbpnzdCrisisRedHBuy, g_gbpnzdCleanHBuy,
                             g_gbpnzdLevelBuy, _dummyReasonBuy);
         }

         // SELL
         {
            bool _sRed   = (g_gbnzdCrisisSell == 2);
            bool _sDirty = _sRed || !(g_gbnzdSpikeSell <= 0 || g_gbnzdSpikeSell == -1);
            Rule_UpdateCounters(_sRed, _sDirty, g_gbpnzdCrisisRedHSell, g_gbpnzdCleanHSell);
            int _dummyReasonSell = 0;
            Rule_Transition(g_gbnzdCrisisSell, g_gbnzdSpikeSell, _haSell,
                             g_gbpnzdCrisisRedHSell, g_gbpnzdCleanHSell,
                             g_gbpnzdLevelSell, _dummyReasonSell);
         }

         // worst-case مشترک
         g_gbpnzdLevel      = MathMax(g_gbpnzdLevelBuy, g_gbpnzdLevelSell);
         g_gbpnzdCrisisRedH = MathMax(g_gbpnzdCrisisRedHBuy, g_gbpnzdCrisisRedHSell);
         g_gbpnzdCleanH     = MathMin(g_gbpnzdCleanHBuy, g_gbpnzdCleanHSell);
      }

      g_hourlyLog[_hi].stGBPNZD = g_gbpnzdLevel;
   }
   else
      g_hourlyLog[_hi].stGBPNZD = -1;   // سیمبل غیر GBPNZD — N/A
}

void BT_TrackLightChanges(
   int nRTM, int nTrend, int nStruct, int nFLOW, int nZOMBIE,
   int oRTM, int oTrend, int oStruct, int oFLOW, int oZOMBIE,
   // مقادیر عددی خام چراغ‌ها
   double rtmX,    string rtmArrow, bool rtmCT,
   double adxVal,  double erH4,    string erLabel,
   string d1Status, double d1Pips, double flowScore,
   double zombieScoreOrZone, double zombieMidShiftOrWidth,
   string direction)
{
   // v10.4: ردیابی رویدادهای قرمز شدن چراغ‌ها (و CSV مرتب‌شده) حذف شد.
   // تنها CSV ساعتی (LogHourlySnapshot) باقی ماند — سبک‌تر و سریع‌تر.
   // پارامترها برای حفظ امضای فراخوانی نگه داشته شده‌اند.
}

//+------------------------------------------------------------------+
//| StateStr: تبدیل عدد state به رشته رنگ برای CSV                  |
//+------------------------------------------------------------------+
string BT_StateStr(int s)
{
   if(s == 0) return "Green";   // سبز
   if(s == 1) return "Yellow";  // زرد
   if(s == 2) return "Red";     // قرمز
   return "-";                   // خاکستری / نامشخص
}

//+------------------------------------------------------------------+
//| OnTester: در پایان بکتست فراخوانی می‌شود — CSV رویدادها را ذخیره|
//| ساختار CSV:                                                       |
//|  RedCount = تعداد چراغ‌های قرمز همزمان (4,3,2,1)                |
//|  هر سطر = یک رویداد تغییر چراغ به قرمز + اطلاعات کامل          |
//|  قابل Sort بر اساس RedCount برای یافتن بحرانی‌ترین لحظات       |
//+------------------------------------------------------------------+
double OnTester()
{
   // v10.4: CSV مرتب‌شده بر اساس RedCount حذف شد — فقط CSV ساعتی نگه داشته می‌شود.
   string sym = _Symbol;
   StringReplace(sym, ".", "");

   // ══════════════════════════════════════════════════════════════
   // 🆕 v10.0: CSV ساعتی (HourlySnapshot) — دقت یک ساعته
   // ══════════════════════════════════════════════════════════════
   if(g_hourlyCount > 0)
   {
      MqlDateTime _dth, _dte;
      TimeToStruct(g_hourlyLog[0].snapTime,                 _dth);
      TimeToStruct(g_hourlyLog[g_hourlyCount-1].snapTime,   _dte);

      string fhourly = StringFormat(
         "HelpMe_Hourly_%s_%04d%02d%02d_%04d%02d%02d.csv",
         sym,
         _dth.year, _dth.mon, _dth.day,
         _dte.year, _dte.mon, _dte.day);

      int hh = FileOpen(fhourly, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
      if(hh != INVALID_HANDLE)
      {
         string hhdr =
            "Snapshot_Time,Direction,"
            "RTM,ADX,D1,FLOW,CRISIS,"    // v10.4.1: ZOMBIE color col removed-zone only
            "HighAlert,KILLER,"          // 🆕 v12.14: KILLER column added
            "MktPhase,MktRatio,"         // 🆕 v13.12: Market Phase
            "Spike,SpikeScore,"          // 🆕 v13.14: Spike Detector
            "RTM_Arrow,"
            "ADX_Val,EffRatio_H4,Flow_Score,Trend_Score,"
            "D1_Status,Zombie_Zone,"
            "Regime,Session,Spread_Points,GBPNZD_Rule\n";
         FileWriteString(hh, hhdr);

         for(int _i = 0; _i < g_hourlyCount; _i++)
         {
            // 🆕 v13.16: حالت Orange (3) از مسیر Orange-D اضافه شد
            string _cris  = (g_hourlyLog[_i].stCRISIS == 2) ? "Red" :
                            (g_hourlyLog[_i].stCRISIS == 3) ? "Orange" :
                            (g_hourlyLog[_i].stCRISIS == 1) ? "Yellow" : "Green";
            string _haStr = g_hourlyLog[_i].highAlert ? "Active" : "OK";  // v11.8
            string _killStr = (g_hourlyLog[_i].stKILLER == 2) ? "Red" :  // 🆕 v12.14
                              (g_hourlyLog[_i].stKILLER == 1) ? "Yellow" :
                              (g_hourlyLog[_i].stKILLER == 0) ? "Green"  : "-";
            string _mktStr = (g_hourlyLog[_i].stMKTPHASE == 2) ? "Trend" :   // 🆕 v13.12
                             (g_hourlyLog[_i].stMKTPHASE == 1) ? "Neutral" :
                             (g_hourlyLog[_i].stMKTPHASE == 0) ? "Range"   : "-";
            string _spkStr = (g_hourlyLog[_i].stSPIKE == 2) ? "Spike" :     // 🆕 v13.14
                             (g_hourlyLog[_i].stSPIKE == 1) ? "Warning" :
                             (g_hourlyLog[_i].stSPIKE == 0) ? "Normal"  : "-";
            string _gbpnzdStr = (g_hourlyLog[_i].stGBPNZD == 0) ? "Run"   :  // 🆕 v13.21
                                (g_hourlyLog[_i].stGBPNZD == 1) ? "Stop"  :
                                (g_hourlyLog[_i].stGBPNZD == 2) ? "Close" : "-";
            string _line = StringFormat(
               "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%.3f,%s,%.3f,%s,%.1f,%.3f,%+.2f,%.1f,%s,%d,%s,%s,%d,%s\n",
               TimeToString(g_hourlyLog[_i].snapTime, TIME_DATE|TIME_MINUTES),
               g_hourlyLog[_i].direction,
               BT_StateStr(g_hourlyLog[_i].stRTM),
               BT_StateStr(g_hourlyLog[_i].stTrend),
               BT_StateStr(g_hourlyLog[_i].stStruct),
               BT_StateStr(g_hourlyLog[_i].stFLOW),
               _cris,
               _haStr,                                   // v11.8: HighAlert
               _killStr,                                 // 🆕 v12.14: KILLER
               _mktStr,                                  // 🆕 v13.12: MktPhase
               g_hourlyLog[_i].mktRatio,                 // 🆕 v13.12: ratio
               _spkStr,                                  // 🆕 v13.14: Spike
               g_hourlyLog[_i].spikeScore,                // 🆕 v13.14: spike score
               g_hourlyLog[_i].rtmArrow,
               g_hourlyLog[_i].adxVal,
               g_hourlyLog[_i].erH4,
               g_hourlyLog[_i].flowScore,
               g_hourlyLog[_i].trendScore,
               g_hourlyLog[_i].d1Status,
               g_hourlyLog[_i].zombieZone,
               g_hourlyLog[_i].regime,
               g_hourlyLog[_i].session,
               g_hourlyLog[_i].spreadPt,
               _gbpnzdStr                                // 🆕 v13.21: GBPNZD Rule
            );
            FileWriteString(hh, _line);
         }
         FileClose(hh);
         Print("✅ HelpMe Hourly CSV: ", g_hourlyCount, " ساعت → ", fhourly);
      }
   }

   Print("✅ HelpMe Backtest: CSV ساعتی ذخیره شد (", g_hourlyCount, " ساعت) — فقط Zombie_Zone، بدون ستون رنگ.");
   Print("   مسیر: %APPDATA%\\MetaQuotes\\Terminal\\Common\\Files\\HelpMe_Hourly_*.csv");
   return 0.0;
}

// ════════════════════════════════════════════════════════════════════
// S/R LEVELS - همیشه از D1 (مستقل از TF جاری)
// ════════════════════════════════════════════════════════════════════

// ─── رسم یک خط S/R روی چارت ────────────────────────────────────────
void DrawSRLine(string name, double price, color clr, int width, bool isResistance)
{
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR,  clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,  width);
   ObjectSetInteger(0, name, OBJPROP_STYLE,  STYLE_SOLID);
   // S/R خطوط پشت همه چیز - داشبورد همیشه On Top
   ObjectSetInteger(0, name, OBJPROP_BACK,   true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);   // v11.92: اولویت کلیک پایین‌تر از داشبورد
   // Tooltip
   string lbl = isResistance ? "R" : "S";
   ObjectSetString(0, name, OBJPROP_TOOLTIP, lbl + ": " + DoubleToString(price, _Digits));
}

// ─── موتور اصلی محاسبه و رسم ───────────────────────────────────────
// 🆕 v7.0: همیشه از PERIOD_D1 - مستقل از TF جاری چارت
// دلیل: سطوح D1 بنیادی‌ترین سطوح برای تصمیم Xmoon پس از پله ۵ هستند
void DrawSRLevels()
{
   // پاک کردن خطوط قبلی
   ObjectsDeleteAll(0, SR_OBJ_PREFIX);

   // ─── تعداد کندل D1 قابل استفاده ──────────────────────────────
   int lookback = MathMin(500, Bars(_Symbol, PERIOD_D1) - 5);
   if(lookback < 20)
   {
      Print("⚠️ S/R(D1): Not enough D1 bars (", lookback, ")");
      return;
   }

   // ─── ATR روزانه برای clustering threshold ─────────────────────
   double clusterThreshold = 0;
   if(handleATR_D1_TL != INVALID_HANDLE && BarsCalculated(handleATR_D1_TL) > 20)
   {
      double tmpArr[];
      ArraySetAsSeries(tmpArr, true);
      if(CopyBuffer(handleATR_D1_TL, 0, 1, 2, tmpArr) > 0 && tmpArr[0] > 0)
         clusterThreshold = tmpArr[0] * 0.5;
   }
   if(clusterThreshold <= 0)
   {
      // fallback: ATR موقت از D1
      int hTmp = iATR(_Symbol, PERIOD_D1, ATRPeriod);
      if(hTmp != INVALID_HANDLE)
      {
         double ta[];
         ArraySetAsSeries(ta, true);
         if(CopyBuffer(hTmp, 0, 1, 2, ta) > 0 && ta[0] > 0)
            clusterThreshold = ta[0] * 0.5;
      }
      if(clusterThreshold <= 0)
         clusterThreshold = iClose(_Symbol, PERIOD_D1, 1) * 0.003;
   }

   // ─── جمع‌آوری Swing Highs و Lows از D1 ──────────────────────
   // Swing = کندل میانی که از ۲ کندل طرفینش بالاتر/پایین‌تر است
   double swingLevels[];
   ArrayResize(swingLevels, 0);
   int swingCount = 0;

   for(int i = 2; i < lookback - 2; i++)
   {
      double hi  = iHigh(_Symbol, PERIOD_D1, i);
      double lo  = iLow (_Symbol, PERIOD_D1, i);
      double hi1 = iHigh(_Symbol, PERIOD_D1, i - 1);
      double hi2 = iHigh(_Symbol, PERIOD_D1, i + 1);
      double lo1 = iLow (_Symbol, PERIOD_D1, i - 1);
      double lo2 = iLow (_Symbol, PERIOD_D1, i + 1);
      double hi3 = iHigh(_Symbol, PERIOD_D1, i - 2);
      double hi4 = iHigh(_Symbol, PERIOD_D1, i + 2);
      double lo3 = iLow (_Symbol, PERIOD_D1, i - 2);
      double lo4 = iLow (_Symbol, PERIOD_D1, i + 2);

      if(hi > hi1 && hi > hi2 && hi > hi3 && hi > hi4)
      {
         ArrayResize(swingLevels, swingCount + 1);
         swingLevels[swingCount++] = hi;
      }
      if(lo < lo1 && lo < lo2 && lo < lo3 && lo < lo4)
      {
         ArrayResize(swingLevels, swingCount + 1);
         swingLevels[swingCount++] = lo;
      }
   }

   if(swingCount < 5)
   {
      Print("⚠️ S/R(D1): Too few swing points (", swingCount, ")");
      return;
   }

   // ─── مرتب‌سازی صعودی ─────────────────────────────────────────
   ArraySort(swingLevels);

   // ─── Clustering: ادغام سطوح نزدیک ───────────────────────────
   SRCluster clusters[];
   ArrayResize(clusters, 0);
   int clusterCount = 0;

   int ci = 0;
   while(ci < swingCount)
   {
      double clusterPrice  = swingLevels[ci];
      int    clusterTouches = 1;
      while(ci + 1 < swingCount && (swingLevels[ci+1] - clusterPrice) < clusterThreshold)
      {
         ci++;
         clusterPrice = (clusterPrice * clusterTouches + swingLevels[ci]) / (clusterTouches + 1);
         clusterTouches++;
      }
      double nearestRound = MathRound(clusterPrice / (clusterThreshold * 2)) * (clusterThreshold * 2);
      if(MathAbs(clusterPrice - nearestRound) < clusterThreshold * 0.3)
         clusterTouches++;
      ArrayResize(clusters, clusterCount + 1);
      clusters[clusterCount].price   = clusterPrice;
      clusters[clusterCount].touches = clusterTouches;
      clusterCount++;
      ci++;
   }

   // ─── جداسازی مقاومت و حمایت ─────────────────────────────────
   double currentPrice = iClose(_Symbol, PERIOD_D1, 1);

   SRCluster resistance[], support[];
   ArrayResize(resistance, 0);
   ArrayResize(support, 0);
   int resCount = 0, supCount = 0;

   for(int k = 0; k < clusterCount; k++)
   {
      clusters[k].isAbove = (clusters[k].price > currentPrice);
      if(clusters[k].isAbove)
      {
         ArrayResize(resistance, resCount + 1);
         resistance[resCount++] = clusters[k];
      }
      else
      {
         ArrayResize(support, supCount + 1);
         support[supCount++] = clusters[k];
      }
   }

   // ─── رسم ۵ مقاومت + ۵ حمایت ─────────────────────────────────
   color resColors[] = {clrRed, clrCrimson, clrFireBrick, clrIndianRed, clrRosyBrown};
   int   resWidths[] = {3, 2, 2, 1, 1};
   color supColors[] = {clrLime, clrLimeGreen, clrMediumSeaGreen, clrSeaGreen, clrDarkGreen};
   int   supWidths[] = {3, 2, 2, 1, 1};
   int   maxLevels = 5;

   for(int r = 0; r < MathMin(maxLevels, resCount); r++)
   {
      int   lineW = resWidths[r];
      color clr   = resColors[r];
      if(resistance[r].touches >= 4) lineW = MathMin(lineW + 1, 4);
      string objName = SR_OBJ_PREFIX + "R_" + IntegerToString(r+1);
      DrawSRLine(objName, resistance[r].price, clr, lineW, true);
      if(ShowDebugLogs)
         Print("📐 D1-R", r+1, ": ", DoubleToString(resistance[r].price, _Digits),
               " t=", resistance[r].touches);
   }
   for(int s = 0; s < MathMin(maxLevels, supCount); s++)
   {
      int idx   = supCount - 1 - s;
      int lineW = supWidths[s];
      color clr = supColors[s];
      if(support[idx].touches >= 4) lineW = MathMin(lineW + 1, 4);
      string objName = SR_OBJ_PREFIX + "S_" + IntegerToString(s+1);
      DrawSRLine(objName, support[idx].price, clr, lineW, false);
      if(ShowDebugLogs)
         Print("📐 D1-S", s+1, ": ", DoubleToString(support[idx].price, _Digits),
               " t=", support[idx].touches);
   }

   Print("✅ S/R(D1): ", MathMin(maxLevels,resCount), " R + ", MathMin(maxLevels,supCount),
         " S | swings=", swingCount, " clusters=", clusterCount,
         " lookback=", lookback, " D1 bars | threshold=",
         DoubleToString(clusterThreshold / (_Point*10), 1), " pip");
}

//+------------------------------------------------------------------+
//| 🆕 v4.0 - FRACTAL S/R SPACE CHECK (برای حالت Strict)            |
//| از آرایه‌های کَش شده استفاده می‌کند - بدون CopyBuffer در حلقه    |
//+------------------------------------------------------------------+
bool IsTooCloseToFractal(int shift, bool forBuy, double price, double atr)
{
   if(atr <= 0) return false;
   
   // استفاده از آرایه‌های g_fractalUp/Dn که قبل از حلقه پر شده‌اند
   // (اگر fractal cache پر نشده باشد، فیلتر را رد می‌کنیم)
   if(ArraySize(g_fractalUp) <= shift || ArraySize(g_fractalDn) <= shift)
      return false;

   if(forBuy)
   {
      // برای خرید: آیا سقف فراکتالی خیلی نزدیک است؟
      for(int i = shift; i < MathMin(shift + 50, ArraySize(g_fractalUp)); i++)
      {
         if(g_fractalUp[i] != EMPTY_VALUE && g_fractalUp[i] > 0)
         {
            double distanceToCeiling = g_fractalUp[i] - price;
            if(distanceToCeiling > 0 && distanceToCeiling < 0.5 * atr)
            {
               if(ShowScoreInfo && shift == 1)
                  Print("🧱 Fractal ceiling at ", g_fractalUp[i], " | gap=",
                        DoubleToString(distanceToCeiling / atr, 2), " ATR");
               return true;
            }
            break;
         }
      }
   }
   else
   {
      // برای فروش: آیا کف فراکتالی خیلی نزدیک است؟
      for(int i = shift; i < MathMin(shift + 50, ArraySize(g_fractalDn)); i++)
      {
         if(g_fractalDn[i] != EMPTY_VALUE && g_fractalDn[i] > 0)
         {
            double distanceToFloor = price - g_fractalDn[i];
            if(distanceToFloor > 0 && distanceToFloor < 0.5 * atr)
            {
               if(ShowScoreInfo && shift == 1)
                  Print("🧱 Fractal floor at ", g_fractalDn[i], " | gap=",
                        DoubleToString(distanceToFloor / atr, 2), " ATR");
               return true;
            }
            break;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| 🆕 v4.0 - HIDDEN RSI DIVERGENCE (برای حالت Balanced + Strict)   |
//| واگرایی پنهان مثبت: قیمت Higher Low + RSI Lower Low            |
//| واگرایی پنهان منفی: قیمت Lower High + RSI Higher High          |
//| بازگشتی: +4 امتیاز بونوس اگر واگرایی پیدا شود                   |
//+------------------------------------------------------------------+
int CheckHiddenDivergence(int shift, bool forBuy)
{
   if(shift + 8 >= g_cacheSize) return 0;
   
   const double MIN_SWING_ATR = 0.3;
   double atr = g_atr[shift];
   if(atr <= 0) return 0;
   
   if(forBuy)
   {
      // Hidden Bullish: قیمت Higher Low + RSI Lower Low = ادامه صعود
      int prevLowBar = -1;
      for(int i = shift + 2; i <= shift + 8 && i + 1 < g_cacheSize; i++)
      {
         double lo_prev = iLow(_Symbol, PERIOD_CURRENT, i-1);
         double lo_curr = iLow(_Symbol, PERIOD_CURRENT, i);
         double lo_next = iLow(_Symbol, PERIOD_CURRENT, i+1);
         if(lo_curr < lo_prev && lo_curr < lo_next)
         {
            prevLowBar = i;
            break;
         }
      }
      if(prevLowBar == -1) return 0;
      
      double currentLow = iLow(_Symbol, PERIOD_CURRENT, shift);
      double prevLow    = iLow(_Symbol, PERIOD_CURRENT, prevLowBar);
      double rsiNow     = g_rsi[shift];
      double rsiPrev    = g_rsi[prevLowBar];
      
      if(currentLow > prevLow &&
         rsiNow < rsiPrev &&
         (currentLow - prevLow) > MIN_SWING_ATR * atr)
      {
         if(ShowScoreInfo && shift == 1)
            Print("Hidden Bullish Div: PriceLow ", DoubleToString(prevLow, _Digits),
                  " -> ", DoubleToString(currentLow, _Digits),
                  " | RSI ", DoubleToString(rsiPrev, 1), " -> ", DoubleToString(rsiNow, 1), " +4pts");
         return 4;
      }
   }
   else
   {
      // Hidden Bearish: قیمت Lower High + RSI Higher High = ادامه نزول
      int prevHighBar = -1;
      for(int i = shift + 2; i <= shift + 8 && i + 1 < g_cacheSize; i++)
      {
         double hi_prev = iHigh(_Symbol, PERIOD_CURRENT, i-1);
         double hi_curr = iHigh(_Symbol, PERIOD_CURRENT, i);
         double hi_next = iHigh(_Symbol, PERIOD_CURRENT, i+1);
         if(hi_curr > hi_prev && hi_curr > hi_next)
         {
            prevHighBar = i;
            break;
         }
      }
      if(prevHighBar == -1) return 0;
      
      double currentHigh = iHigh(_Symbol, PERIOD_CURRENT, shift);
      double prevHigh    = iHigh(_Symbol, PERIOD_CURRENT, prevHighBar);
      double rsiNow      = g_rsi[shift];
      double rsiPrev     = g_rsi[prevHighBar];
      
      if(currentHigh < prevHigh &&
         rsiNow > rsiPrev &&
         (prevHigh - currentHigh) > MIN_SWING_ATR * atr)
      {
         if(ShowScoreInfo && shift == 1)
            Print("Hidden Bearish Div: PriceHigh ", DoubleToString(prevHigh, _Digits),
                  " -> ", DoubleToString(currentHigh, _Digits),
                  " | RSI ", DoubleToString(rsiPrev, 1), " -> ", DoubleToString(rsiNow, 1), " +4pts");
         return 4;
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| 🆕 DETECT MARKET REGIME                                         |
//+------------------------------------------------------------------+
MarketRegimeInfo DetectMarketRegime(int bars)
{
   MarketRegimeInfo regime;
   regime.efficiencyRatio = CalculateEfficiencyRatio(bars);
   regime.hurstExponent = CalculateHurstExponent(bars);
   
   //--- Calculate Volatility Ratio (bulk CopyBuffer – much faster than 100 individual calls)
   double atr[1];
   if(CopyBuffer(handleATR, 0, 0, 1, atr) == 1)
   {
      int lookback = MathMin(100, Bars(_Symbol, PERIOD_CURRENT));
      double atrBuf[];
      ArrayResize(atrBuf, lookback);
      int copiedATR = CopyBuffer(handleATR, 0, 0, lookback, atrBuf);
      
      double avgATR = 0;
      if(copiedATR > 0)
      {
         for(int i = 0; i < copiedATR; i++) avgATR += atrBuf[i];
         avgATR /= copiedATR;
      }
      
      double _atrCur[1]; if(CopyBuffer(handleATR,0,0,1,_atrCur)==1) regime.volatilityRatio = avgATR > 0 ? _atrCur[0] / avgATR : 1.0; else regime.volatilityRatio = 1.0;
   }
   else
   {
      regime.volatilityRatio = 1.0;
   }
   
   //--- Determine Regime
   if(regime.efficiencyRatio >= TrendingThreshold && regime.volatilityRatio < HighVolatilityThreshold)
   {
      regime.regime = REGIME_TRENDING;
      regime.description = "Strong Trend - Best for Trading";
   }
   else if(regime.efficiencyRatio <= RangingThreshold)
   {
      regime.regime = REGIME_RANGING;
      regime.description = "Sideways Market - Avoid Trading";
   }
   else if(regime.volatilityRatio >= HighVolatilityThreshold)
   {
      regime.regime = REGIME_VOLATILE;
      regime.description = "High Volatility - Trade with Caution";
   }
   else
   {
      regime.regime = REGIME_QUIET;
      regime.description = "Low Activity - Weak Signals";
   }
   
   return regime;
}

//+------------------------------------------------------------------+
//| 🆕 CALCULATE HURST EXPONENT (simplified)                        |
//+------------------------------------------------------------------+
double CalculateHurstExponent(int bars)
{
   // Simplified Hurst calculation for regime detection
   // H > 0.5 = trending, H < 0.5 = mean-reverting, H ≈ 0.5 = random walk
   
   if(bars < 20) return 0.5;
   
   // استفاده از CopyClose یک‌بار به‌جای bars بار iClose (بهینه‌سازی CPU)
   double prices[];
   ArraySetAsSeries(prices, false);
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, bars, prices) < bars) return 0.5;
   
   // Calculate range over different time scales
   double H = 0.5;  // Default neutral
   
   int lags[] = {5, 10, 20, 40};
   double logRS[];
   double logLags[];
   
   int validPoints = 0;
   ArrayResize(logRS, ArraySize(lags));
   ArrayResize(logLags, ArraySize(lags));
   
   for(int lagIdx = 0; lagIdx < ArraySize(lags); lagIdx++)
   {
      int lag = lags[lagIdx];
      if(lag >= bars) continue;
      
      // Calculate mean
      double mean = 0;
      for(int i = 0; i < lag; i++)
         mean += prices[i];
      mean /= lag;
      
      // Calculate cumulative deviation
      double cumDev[];
      ArrayResize(cumDev, lag);
      cumDev[0] = prices[0] - mean;
      
      for(int i = 1; i < lag; i++)
         cumDev[i] = cumDev[i-1] + (prices[i] - mean);
      
      // Find range
      double maxCumDev = cumDev[0];
      double minCumDev = cumDev[0];
      
      for(int i = 1; i < lag; i++)
      {
         if(cumDev[i] > maxCumDev) maxCumDev = cumDev[i];
         if(cumDev[i] < minCumDev) minCumDev = cumDev[i];
      }
      
      double range = maxCumDev - minCumDev;
      
      // Calculate standard deviation
      double stdDev = 0;
      for(int i = 0; i < lag; i++)
         stdDev += MathPow(prices[i] - mean, 2);
      stdDev = MathSqrt(stdDev / lag);
      
      if(stdDev > 0)
      {
         double RS = range / stdDev;
         if(RS > 0)
         {
            logRS[validPoints] = MathLog(RS);
            logLags[validPoints] = MathLog(lag);
            validPoints++;
         }
      }
   }
   
   // Linear regression to find H
   if(validPoints >= 2)
   {
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      
      for(int i = 0; i < validPoints; i++)
      {
         sumX += logLags[i];
         sumY += logRS[i];
         sumXY += logLags[i] * logRS[i];
         sumX2 += logLags[i] * logLags[i];
      }
      
      double denominator = validPoints * sumX2 - sumX * sumX;
      if(denominator != 0)
      {
         H = (validPoints * sumXY - sumX * sumY) / denominator;
         
         // Clamp between 0 and 1
         if(H < 0) H = 0;
         if(H > 1) H = 1;
      }
   }
   
   return H;
}

//+------------------------------------------------------------------+
//| CALCULATE EFFICIENCY RATIO                                       |
//+------------------------------------------------------------------+
double CalculateEfficiencyRatio(int bars)
{
   if(bars <= 1) return 0;
   
   double netChange = MathAbs(iClose(_Symbol, PERIOD_CURRENT, 0) - 
                              iClose(_Symbol, PERIOD_CURRENT, bars-1));
   double totalChange = 0;
   
   for(int i = 0; i < bars - 1; i++)
      totalChange += MathAbs(iClose(_Symbol, PERIOD_CURRENT, i) - 
                            iClose(_Symbol, PERIOD_CURRENT, i+1));
   
   return totalChange > 0 ? netChange / totalChange : 0;
}

//+------------------------------------------------------------------+
// Get Current Efficiency Ratio (از کش می‌خواند - هر بار محاسبه نمی‌کند)
// g_cachedER در OnTick روی هر کندل جدید آپدیت می‌شود
//+------------------------------------------------------------------+
double GetCurrentEfficiencyRatio()
{
   return g_cachedER;
}

// ─── ذخیره/بارگذاری state دکمه‌ها در GlobalVariable ────────────────────
// هدف: بعد از تغییر تایم‌فریم یا ری‌استارت EA، تنظیمات دکمه‌ها حفظ شوند
// ────────────────────────────────────────────────────────────────────────
void SaveButtonStates()
{
   // 🔧 FIX v7.0: اضافه کردن ChartID به prefix تا چارت‌های مختلف با همان سیمبل تداخل نداشته باشند
   // مثال: EURUSD M15 و EURUSD H1 هر کدام GlobalVariable جداگانه دارند
   string prefix = "HelpMe_" + _Symbol + "_" + IntegerToString(ChartID()) + "_";
   
   GlobalVariableSet(prefix + "Price",    localEnablePriceAction  ? 1.0 : 0.0);
   GlobalVariableSet(prefix + "MTF",      localEnableMTF          ? 1.0 : 0.0);
   GlobalVariableSet(prefix + "Regime",   localEnableMarketRegime ? 1.0 : 0.0);
   GlobalVariableSet(prefix + "SmartVol", localEnableSmartVol     ? 1.0 : 0.0);
   GlobalVariableSet(prefix + "Ichi",     localEnableIchimoku     ? 1.0 : 0.0);
   // 🆕 v7.0: ذخیره وضعیت فیلترهای ردیف سوم
   GlobalVariableSet(prefix + "FVG",      localEnableFVG          ? 1.0 : 0.0);
   GlobalVariableSet(prefix + "LiqSwp",   localEnableLiqSwp       ? 1.0 : 0.0);
   GlobalVariableSet(prefix + "RTM",      localEnableRTM          ? 1.0 : 0.0);
   // v5.0: SR button state NOT saved intentionally - lines must be redrawn on reload
   // (TF change resets SR: user clicks off→on to recalculate for new TF)
   // FIX: also persist preset and filter mode so TF change doesn't reset them
   GlobalVariableSet(prefix + "Preset",     (double)currentPreset);
   GlobalVariableSet(prefix + "FilterMode", (double)currentFilterMode);
   // v11: ذخیره حالت دکمه‌های Buy/All/Sell
   GlobalVariableSet(prefix + "DirMode",    (double)g_dirMode);
}

//+------------------------------------------------------------------+
// Load button states from GlobalVariable (restore after timeframe change)
//+------------------------------------------------------------------+
void LoadButtonStates()
{
   // 🔧 FIX v7.0: ChartID در prefix تا state چارت‌های مختلف ایزوله باشند
   string prefix = "HelpMe_" + _Symbol + "_" + IntegerToString(ChartID()) + "_";
   
   if(GlobalVariableCheck(prefix + "Price"))
      localEnablePriceAction = (GlobalVariableGet(prefix + "Price") > 0.5);
   
   if(GlobalVariableCheck(prefix + "MTF"))
      localEnableMTF = (GlobalVariableGet(prefix + "MTF") > 0.5);
   
   if(GlobalVariableCheck(prefix + "Regime"))
      localEnableMarketRegime = (GlobalVariableGet(prefix + "Regime") > 0.5);
   
   if(GlobalVariableCheck(prefix + "SmartVol"))
      localEnableSmartVol = (GlobalVariableGet(prefix + "SmartVol") > 0.5);
   if(GlobalVariableCheck(prefix + "Ichi"))
      localEnableIchimoku = (GlobalVariableGet(prefix + "Ichi") > 0.5);

   // 🆕 v7.0: بارگذاری وضعیت فیلترهای ردیف سوم
   if(GlobalVariableCheck(prefix + "FVG"))
      localEnableFVG = (GlobalVariableGet(prefix + "FVG") > 0.5);
   if(GlobalVariableCheck(prefix + "LiqSwp"))
      localEnableLiqSwp = (GlobalVariableGet(prefix + "LiqSwp") > 0.5);
   if(GlobalVariableCheck(prefix + "RTM"))
      localEnableRTM = (GlobalVariableGet(prefix + "RTM") > 0.5);
   
   // v5.0: SR always starts OFF on load (on-demand design)
   // Lines disappear on TF change - user clicks button to redraw for new TF
   localEnableSR = false;

   // FIX: restore preset and filter mode after TF change
   if(GlobalVariableCheck(prefix + "Preset"))
      currentPreset = (ENUM_TIMEFRAME_PRESET)(int)GlobalVariableGet(prefix + "Preset");

   if(GlobalVariableCheck(prefix + "FilterMode"))
      currentFilterMode = (ENUM_FILTER_MODE)(int)GlobalVariableGet(prefix + "FilterMode");

   // v11: بارگذاری حالت دکمه‌های Buy/All/Sell
   if(GlobalVariableCheck(prefix + "DirMode"))
   {
      g_dirMode = (int)GlobalVariableGet(prefix + "DirMode");
      if(g_dirMode < 0 || g_dirMode > 2) g_dirMode = 0;  // sanity check
   }
}



//+------------------------------------------------------------------+
//| 🆕 LOAD NEWS EVENTS (v5.3: cleaned up - was dead placeholder)   |
//+------------------------------------------------------------------+
void LoadNewsEvents()
{
   // این تابع فقط برای سازگاری backward نگه داشته شده.
   // g_newsList توسط SmartLoadNews() در OnInit و OnTimer پر می‌شود
   // و مستقیماً در IsNearHighImpactNews() استفاده می‌شود
}

//+------------------------------------------------------------------+
//| 🆕 CHECK IF NEAR HIGH IMPACT NEWS                               |
//+------------------------------------------------------------------+
bool IsNearHighImpactNews(datetime signalTime)
{
   // v5.0: این تابع فقط برای خطوط عمودی خبری (WebRequest) استفاده می‌شود
   // فیلتر AI news حذف شده - این بررسی همیشه فعال است اگه گروه خبری لود شده باشه
   if(g_newsCount == 0) return false;
   
   // Use g_newsList instead of newsEvents (which is always empty)
   for(int i = 0; i < g_newsCount; i++)
   {
      if(g_newsList[i].impact < 3) continue;  // Only High Impact news
      
      int minutesDiff = (int)((signalTime - g_newsList[i].time) / 60);
      if(minutesDiff >= -NewsBlockMinutesBefore && minutesDiff <= NewsBlockMinutesAfter)
      {
         if(EnableAllLogs) 
            Print("🚫 Signal blocked by news: ", g_newsList[i].name, " at ", TimeToString(g_newsList[i].time));
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| 🆕 UPDATE MTF TREND INFO                                        |
//+------------------------------------------------------------------+
void UpdateMTFTrendInfo()
{
   // --- H1 Trend with fallback
   double h1Close = iClose(_Symbol, PERIOD_H1, 0);
   double h1EMA[1];

   if(CopyBuffer(handleH1_EMA, 0, 0, 1, h1EMA) == 1)
   {
      mtfTrend.h1Bullish = (h1Close > h1EMA[0]);
      mtfTrend.h1Bearish = (h1Close < h1EMA[0]);
   }
   else
   {
      // Fallback: use SMA of last MTF_EMAPeriod H1 closes
      double h1Closes[];
      if(CopyClose(_Symbol, PERIOD_H1, 0, MTF_EMAPeriod, h1Closes) == MTF_EMAPeriod)
      {
         double sum = 0;
         for(int i = 0; i < MTF_EMAPeriod; i++) sum += h1Closes[i];
         double sma = sum / MTF_EMAPeriod;
         mtfTrend.h1Bullish = (h1Close > sma);
         mtfTrend.h1Bearish = (h1Close < sma);
         if(EnableAllLogs) Print("📊 H1 using fallback SMA");
      }
   }

   // H1 RSI
   double h1RSI_val[1];
   if(CopyBuffer(handleH1_RSI, 0, 0, 1, h1RSI_val) == 1)
      mtfTrend.h1RSI = h1RSI_val[0];

   // --- H4 Trend with fallback
   double h4Close = iClose(_Symbol, PERIOD_H4, 0);
   double h4EMA[1];

   if(CopyBuffer(handleH4_EMA, 0, 0, 1, h4EMA) == 1)
   {
      mtfTrend.h4Bullish = (h4Close > h4EMA[0]);
      mtfTrend.h4Bearish = (h4Close < h4EMA[0]);
   }
   else
   {
      // Fallback: use SMA
      double h4Closes[];
      if(CopyClose(_Symbol, PERIOD_H4, 0, MTF_EMAPeriod, h4Closes) == MTF_EMAPeriod)
      {
         double sum = 0;
         for(int i = 0; i < MTF_EMAPeriod; i++) sum += h4Closes[i];
         double sma = sum / MTF_EMAPeriod;
         mtfTrend.h4Bullish = (h4Close > sma);
         mtfTrend.h4Bearish = (h4Close < sma);
         if(EnableAllLogs) Print("📊 H4 using fallback SMA");
      }
   }

   // H4 RSI
   double h4RSI_val[1];
   if(CopyBuffer(handleH4_RSI, 0, 0, 1, h4RSI_val) == 1)
      mtfTrend.h4RSI = h4RSI_val[0];
}


//+------------------------------------------------------------------+
//| 🆕 DETECT CANDLESTICK PATTERN                                   |
//+------------------------------------------------------------------+
// 🆕 v5.0: Direction-aware pattern detection
// forBuy=true: دنبال الگوی صعودی می‌گردیم; forBuy=false: نزولی
// این تابع اکنون دو نسخه دارد - با جهت و بدون جهت
ENUM_CANDLE_PATTERN DetectCandlePattern(int shift, double o, double h, double l, double c, double atr, bool forBuy = true)
{
   double bodySize  = MathAbs(c - o);
   double totalSize = h - l;
   double upperWick = (c > o) ? (h - c) : (h - o);
   double lowerWick = (c > o) ? (o - l) : (c - l);
   
   if(totalSize < atr * 0.05) return PATTERN_NONE;  // کندل خیلی کوچک، نادیده گرفته می‌شود
   
   bool isBullCandle = (c > o);
   bool isBearCandle = (c < o);
   
   //--- 1. Doji: بدنه کمتر از ۱۰٪ ATR
   if(bodySize < atr * 0.10 && totalSize > atr * 0.20)
      return PATTERN_DOJI;  // بی‌طرف، در هر دو جهت قابل استفاده
   
   //--- 2. Hammer (چکش صعودی):
   // کندل صعودی + دم پایین بلند (>2x بدنه) + سقف کوتاه (<30% بدنه)
   if(isBullCandle && lowerWick > bodySize * 2.0 && upperWick < bodySize * 0.3)
      return PATTERN_HAMMER;
   
   //--- 3. Inverted Hammer (چکش معکوس صعودی):
   // کندل صعودی + سقف بلند (>2x بدنه) + دم کوتاه (<30% بدنه)
   // نشانه برگشت صعودی پس از حرکت نزولی
   if(isBullCandle && upperWick > bodySize * 2.0 && lowerWick < bodySize * 0.3)
      return PATTERN_INVERTED_HAMMER;
   
   //--- 4. Shooting Star (ستاره دنباله‌دار نزولی):
   // کندل نزولی + سقف بلند (>2x بدنه) + دم کوتاه (<30% بدنه)
   if(isBearCandle && upperWick > bodySize * 2.0 && lowerWick < bodySize * 0.3)
      return PATTERN_SHOOTING_STAR;
   
   //--- 5. Bullish/Bearish Pin Bar (پین‌بار با جهت):
   if(shift >= 0 && atr > 0)
   {
      // Pin Bar صعودی: دم پایین طولانی، بدنه در بالای کندل
      if(lowerWick > bodySize * PinBarWickRatio && upperWick < bodySize * 0.5 && totalSize > atr * 0.5)
         return PATTERN_BULLISH_PINBAR;
      // Pin Bar نزولی: دم بالا طولانی، بدنه در پایین کندل
      if(upperWick > bodySize * PinBarWickRatio && lowerWick < bodySize * 0.5 && totalSize > atr * 0.5)
         return PATTERN_BEARISH_PINBAR;
   }
   
   //--- 6. Engulfing (اینگالفینگ با جهت):
   if(shift >= 1)
   {
      double prevOpen  = iOpen (_Symbol, PERIOD_CURRENT, shift + 1);
      double prevClose = iClose(_Symbol, PERIOD_CURRENT, shift + 1);
      double prevBody  = MathAbs(prevClose - prevOpen);
      
      if(prevBody > atr * 0.05)  // کندل قبلی باید معنادار باشد
      {
         // Bullish Engulfing: کندل صعودی که کندل نزولی قبل را می‌بلعد
         if(isBullCandle && prevClose < prevOpen)
            if(o < prevClose && c > prevOpen && bodySize > prevBody * EngulfingMinBodyRatio)
               return PATTERN_BULLISH_ENGULFING;
         
         // Bearish Engulfing: کندل نزولی که کندل صعودی قبل را می‌بلعد
         if(isBearCandle && prevClose > prevOpen)
            if(o > prevClose && c < prevOpen && bodySize > prevBody * EngulfingMinBodyRatio)
               return PATTERN_BEARISH_ENGULFING;
      }
   }
   
   return PATTERN_NONE;
}



//+------------------------------------------------------------------+
//| 🖥️ CREATE DASHBOARD PRO                                         |
//+------------------------------------------------------------------+
// ─────────────────────────────────────────────────────────────────────────────
// تابع دریافت DPI واقعی صفحه‌نمایش - کلید حل مشکل رزولوشن‌های مختلف
// ─────────────────────────────────────────────────────────────────────────────
int GetScreenDPI()
{
   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   if(dpi <= 0) dpi = 96;
   return dpi;
}

//+------------------------------------------------------------------+
//| MA OVERLAY SYSTEM - رسم MA تایم‌فریم‌های مختلف روی چارت          |
//+------------------------------------------------------------------+

// رنگ هر MA
color MA_Color(string tf)
{
   if(tf == "M15") return clrDodgerBlue;
   if(tf == "M30") return clrMediumOrchid;
   if(tf == "H1")  return clrOrange;
   if(tf == "H4")  return clrDeepPink;
   if(tf == "D1")  return clrGold;
   return clrWhite;
}

// رسم یا حذف MA یک تایم‌فریم
// handle هرگز در اینجا آزاد نمیشه (فقط در ReleaseMAHandles/OnDeinit)
void DrawOrClearMA(string tfName, ENUM_TIMEFRAMES tf, int &handle, bool draw)
{
   string objPrefix = MA_OBJ_PREFIX + tfName + "_";

   // همیشه اول objects قبلی رو پاک کن
   ObjectsDeleteAll(0, objPrefix);

   if(!draw) return;  // فقط objects حذف شدن، handle دست نخورد

   // اگه handle نداریم بساز (معمولاً از OnInit ساخته شده)
   if(handle == INVALID_HANDLE)
      handle = iMA(_Symbol, tf, 200, 0, MODE_EMA, PRICE_CLOSE);
   if(handle == INVALID_HANDLE) { Print("⚠️ MA handle create failed: ", tfName); return; }

   // بررسی آماده بودن data
   int calculated = BarsCalculated(handle);
   if(calculated < 2)
   {
      // هنوز data از سرور نرسیده → retry در tick بعدی
      g_maRetryNeeded = true;
      return;
   }

   int fetch = MathMin(500, calculated);

   double   maVals[];
   datetime tfTime[];
   ArraySetAsSeries(maVals, true);
   ArraySetAsSeries(tfTime, true);

   int copied  = CopyBuffer(handle, 0, 0, fetch, maVals);
   if(copied < 2) { g_maRetryNeeded = true; return; }

   int tcopied = CopyTime(_Symbol, tf, 0, copied, tfTime);
   if(tcopied < 2) { g_maRetryNeeded = true; return; }

   int    pts   = MathMin(copied, tcopied);
   color  lc    = MA_Color(tfName);
   string lbl   = "EMA200 " + tfName;
   int    drawn = 0;

   for(int i = pts - 2; i >= 0; i--)
   {
      if(maVals[i] <= 0 || maVals[i+1] <= 0) continue;
      string name = objPrefix + IntegerToString(i);
      if(ObjectCreate(0, name, OBJ_TREND, 0, tfTime[i+1], maVals[i+1], tfTime[i], maVals[i]))
      {
         ObjectSetInteger(0, name, OBJPROP_COLOR,     lc);
         ObjectSetInteger(0, name, OBJPROP_WIDTH,     2);
         ObjectSetInteger(0, name, OBJPROP_STYLE,     STYLE_SOLID);
         ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, name, OBJPROP_RAY_LEFT,  false);
         ObjectSetInteger(0, name, OBJPROP_BACK,      true);
         ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
         ObjectSetString (0, name, OBJPROP_TOOLTIP,   lbl + " = " + DoubleToString(maVals[i], _Digits));
         drawn++;
      }
   }

   // اگه هیچ قطعه‌ای رسم نشد یا جدیدترین مقدار EMA هنوز صفره
   // یعنی data هنوز از سرور نرسیده → retry در tick بعدی
   // CPU: فقط یک بار بررسی bool - بعد از رسم موفق دیگه retry نمیشه
   if(drawn == 0 || (pts > 0 && maVals[0] <= 0))
   {
      g_maRetryNeeded = true;
      return;
   }

   // لیبل روی جدیدترین نقطه (سمت راست)
   string lblName = objPrefix + "LBL";
   ObjectCreate(0, lblName, OBJ_TEXT, 0, tfTime[0], maVals[0]);
   ObjectSetString (0, lblName, OBJPROP_TEXT,       lbl);
   ObjectSetInteger(0, lblName, OBJPROP_COLOR,      lc);
   ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE,   8);
   ObjectSetString (0, lblName, OBJPROP_FONT,       "Arial Bold");
   ObjectSetInteger(0, lblName, OBJPROP_BACK,       false);
   ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);

   ChartRedraw(0);
}

// ════════════════════════════════════════════════════════════════
// FEMA: رسم/حذف ۴ EMA هم‌زمان روی تایم‌فریم جاری
// EMA25=سبز | EMA50=زرد | EMA100=نارنجی | EMA200=قرمز
// ════════════════════════════════════════════════════════════════
void DrawOrClearFEMA(bool draw)
{
   // اول همه اشیاء قدیمی رو پاک کن
   ObjectsDeleteAll(0, FEMA_OBJ_PREFIX);
   if(!draw) return;

   // مشخصات چهار EMA
   int    periods[4] = {25, 50, 100, 200};
   color  colors[4]  = {clrLime, clrYellow, clrOrange, clrRed};
   int    handles[4];
   handles[0] = g_handleFEMA_25;
   handles[1] = g_handleFEMA_50;
   handles[2] = g_handleFEMA_100;
   handles[3] = g_handleFEMA_200;

   ENUM_TIMEFRAMES curTF = Period();
   string tfStr = EnumToString(curTF);
   StringReplace(tfStr, "PERIOD_", "");

   for(int e = 0; e < 4; e++)
   {
      int h = handles[e];
      if(h == INVALID_HANDLE) { g_maRetryNeeded = true; continue; }

      int calculated = BarsCalculated(h);
      if(calculated < 2)   { g_maRetryNeeded = true; continue; }

      int fetch = MathMin(500, calculated);

      double   vals[];
      datetime tfTime[];
      ArraySetAsSeries(vals,   true);
      ArraySetAsSeries(tfTime, true);

      int copied  = CopyBuffer(h, 0, 0, fetch, vals);
      int tcopied = CopyTime(_Symbol, curTF, 0, fetch, tfTime);
      if(copied < 2 || tcopied < 2) { g_maRetryNeeded = true; continue; }

      int    pts    = MathMin(copied, tcopied);
      color  lc     = colors[e];
      string emaLbl = StringFormat("EMA%d (%s)", periods[e], tfStr);
      string pfx    = FEMA_OBJ_PREFIX + IntegerToString(periods[e]) + "_";

      // رسم به‌صورت قطعات OBJ_TREND پشت کندل‌ها
      for(int i = pts - 2; i >= 0; i--)
      {
         if(vals[i] <= 0 || vals[i+1] <= 0) continue;
         string nm = pfx + IntegerToString(i);
         if(ObjectCreate(0, nm, OBJ_TREND, 0, tfTime[i+1], vals[i+1], tfTime[i], vals[i]))
         {
            ObjectSetInteger(0, nm, OBJPROP_COLOR,     lc);
            ObjectSetInteger(0, nm, OBJPROP_WIDTH,     2);
            ObjectSetInteger(0, nm, OBJPROP_STYLE,     STYLE_SOLID);
            ObjectSetInteger(0, nm, OBJPROP_RAY_RIGHT, false);
            ObjectSetInteger(0, nm, OBJPROP_RAY_LEFT,  false);
            ObjectSetInteger(0, nm, OBJPROP_BACK,      true);
            ObjectSetInteger(0, nm, OBJPROP_SELECTABLE,false);
            ObjectSetString (0, nm, OBJPROP_TOOLTIP,
               emaLbl + " = " + DoubleToString(vals[i], _Digits));
         }
      }

      // لیبل روی جدیدترین نقطه (سمت راست)
      string lblNm = pfx + "LBL";
      ObjectCreate(0, lblNm, OBJ_TEXT, 0, tfTime[0], vals[0]);
      ObjectSetString (0, lblNm, OBJPROP_TEXT,       emaLbl);
      ObjectSetInteger(0, lblNm, OBJPROP_COLOR,      lc);
      ObjectSetInteger(0, lblNm, OBJPROP_FONTSIZE,   8);
      ObjectSetString (0, lblNm, OBJPROP_FONT,       "Arial Bold");
      ObjectSetInteger(0, lblNm, OBJPROP_BACK,       false);
      ObjectSetInteger(0, lblNm, OBJPROP_SELECTABLE, false);
   }

   ChartRedraw(0);
}

// رسم یا حذف همه MA ها
// keepActive=true: رسم/حذف بر اساس وضعیت دکمه‌ها
// keepActive=false: حذف همه objects (OnDeinit - بدون release handle)
// FIX v8.1: آنتی‌فلیکر — هر MA فقط وقتی TF خودش کندل جدید داره redraw میشه.
// forceRedraw=true: همیشه redraw کن (تغییر TF، کلیک دکمه، retry داده)
// forceRedraw=false (پیش‌فرض): فقط وقتی کندل جدید TF مربوطه باشد
void DrawOrClearAllMAs(bool keepActive = true, bool forceRedraw = false)
{
   static datetime s_lastM15 = 0, s_lastM30 = 0;
   static datetime s_lastH1  = 0, s_lastH4  = 0, s_lastD1 = 0;

   datetime tfBar[1];

   // ── M15 ──────────────────────────────────────────────────────────
   bool drawM15 = keepActive ? g_maM15Active : false;
   bool needM15 = !drawM15   // حالت clear: همیشه اجرا (پاک کردن اشیاء)
               || forceRedraw || g_maRetryNeeded
               || (CopyTime(_Symbol, PERIOD_M15, 0, 1, tfBar) == 1 && tfBar[0] != s_lastM15);
   if(needM15)
   {
      DrawOrClearMA("M15", PERIOD_M15, g_handleMA_M15, drawM15);
      if(drawM15 && CopyTime(_Symbol, PERIOD_M15, 0, 1, tfBar) == 1) s_lastM15 = tfBar[0];
   }

   // ── M30 ──────────────────────────────────────────────────────────
   bool drawM30 = keepActive ? g_maM30Active : false;
   bool needM30 = !drawM30
               || forceRedraw || g_maRetryNeeded
               || (CopyTime(_Symbol, PERIOD_M30, 0, 1, tfBar) == 1 && tfBar[0] != s_lastM30);
   if(needM30)
   {
      DrawOrClearMA("M30", PERIOD_M30, g_handleMA_M30, drawM30);
      if(drawM30 && CopyTime(_Symbol, PERIOD_M30, 0, 1, tfBar) == 1) s_lastM30 = tfBar[0];
   }

   // ── H1 ───────────────────────────────────────────────────────────
   bool drawH1 = keepActive ? g_maH1Active : false;
   bool needH1 = !drawH1
              || forceRedraw || g_maRetryNeeded
              || (CopyTime(_Symbol, PERIOD_H1, 0, 1, tfBar) == 1 && tfBar[0] != s_lastH1);
   if(needH1)
   {
      DrawOrClearMA("H1", PERIOD_H1, g_handleMA_H1, drawH1);
      if(drawH1 && CopyTime(_Symbol, PERIOD_H1, 0, 1, tfBar) == 1) s_lastH1 = tfBar[0];
   }

   // ── H4 ───────────────────────────────────────────────────────────
   bool drawH4 = keepActive ? g_maH4Active : false;
   bool needH4 = !drawH4
              || forceRedraw || g_maRetryNeeded
              || (CopyTime(_Symbol, PERIOD_H4, 0, 1, tfBar) == 1 && tfBar[0] != s_lastH4);
   if(needH4)
   {
      DrawOrClearMA("H4", PERIOD_H4, g_handleMA_H4, drawH4);
      if(drawH4 && CopyTime(_Symbol, PERIOD_H4, 0, 1, tfBar) == 1) s_lastH4 = tfBar[0];
   }

   // ── D1 ───────────────────────────────────────────────────────────
   bool drawD1 = keepActive ? g_maD1Active : false;
   bool needD1 = !drawD1
              || forceRedraw || g_maRetryNeeded
              || (CopyTime(_Symbol, PERIOD_D1, 0, 1, tfBar) == 1 && tfBar[0] != s_lastD1);
   if(needD1)
   {
      DrawOrClearMA("D1", PERIOD_D1, g_handleMA_D1, drawD1);
      if(drawD1 && CopyTime(_Symbol, PERIOD_D1, 0, 1, tfBar) == 1) s_lastD1 = tfBar[0];
   }

   // FEMA فقط زمانی redraw میشه که keepActive=true و دکمه روشنه
   if(keepActive && g_femaActive)
      DrawOrClearFEMA(true);
}

// آزاد کردن handle های MA
void ReleaseMAHandles()
{
   if(g_handleMA_M15 != INVALID_HANDLE) { IndicatorRelease(g_handleMA_M15); g_handleMA_M15 = INVALID_HANDLE; }
   if(g_handleMA_M30 != INVALID_HANDLE) { IndicatorRelease(g_handleMA_M30); g_handleMA_M30 = INVALID_HANDLE; }
   if(g_handleMA_H1  != INVALID_HANDLE) { IndicatorRelease(g_handleMA_H1);  g_handleMA_H1  = INVALID_HANDLE; }
   if(g_handleMA_H4  != INVALID_HANDLE) { IndicatorRelease(g_handleMA_H4);  g_handleMA_H4  = INVALID_HANDLE; }
   if(g_handleMA_D1  != INVALID_HANDLE) { IndicatorRelease(g_handleMA_D1);  g_handleMA_D1  = INVALID_HANDLE; }
   if(g_handleFEMA_25  != INVALID_HANDLE) { IndicatorRelease(g_handleFEMA_25);  g_handleFEMA_25  = INVALID_HANDLE; }
   if(g_handleFEMA_50  != INVALID_HANDLE) { IndicatorRelease(g_handleFEMA_50);  g_handleFEMA_50  = INVALID_HANDLE; }
   if(g_handleFEMA_100 != INVALID_HANDLE) { IndicatorRelease(g_handleFEMA_100); g_handleFEMA_100 = INVALID_HANDLE; }
   if(g_handleFEMA_200 != INVALID_HANDLE) { IndicatorRelease(g_handleFEMA_200); g_handleFEMA_200 = INVALID_HANDLE; }
}


//+------------------------------------------------------------------+
//| 💧 LIQUID LEVEL - محاسبه و رسم خط لیکوئید شدن حساب             |
//| سه حالت: بدون پوزیشن / فقط این نماد / نمادهای دیگه هم پوزیشن   |
//| بازگشت:  -1=خطا/بدون پوزیشن  0=هج کامل  1=موفق (خط رسم شد)    |
//+------------------------------------------------------------------+
int UpdateLiquidationLine()
{
   // ══════════════════════════════════════════════════════════════════
   // مرحله ۱: جمع‌آوری پوزیشن‌های Market (نه Pending) برای این نماد
   // ══════════════════════════════════════════════════════════════════
   double buyLots = 0.0,   sellLots = 0.0;
   double buySum  = 0.0,   sellSum  = 0.0;   // برای میانگین وزنی قیمت ورود
   double symbolProfit = 0.0;
   int    symPosCount  = 0;
   int    otherCount   = 0;

   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      string sym  = PositionGetSymbol(i);
      double prof = PositionGetDouble(POSITION_PROFIT)
                  + PositionGetDouble(POSITION_SWAP);   // swap هم در equity هست

      // 🆕 v13.49 P4: پوزیشن با سیمبل درست ولی Magic نامنطبق (اگه فیلتر فعال باشه)
      // مثل پوزیشن «سایر» حساب می‌شه — نه بخشی از شمارش Xmoon
      if(sym != _Symbol || (InpFilterByMagic && PositionGetInteger(POSITION_MAGIC) != InpXmoonMagic))
      { otherCount++; continue; }

      symPosCount++;
      symbolProfit += prof;

      long   ptype = PositionGetInteger(POSITION_TYPE);
      double lots  = PositionGetDouble(POSITION_VOLUME);
      double open  = PositionGetDouble(POSITION_PRICE_OPEN);

      if(ptype == POSITION_TYPE_BUY) { buyLots += lots; buySum  += open * lots; }
      else                            { sellLots += lots; sellSum += open * lots; }
   }
   g_otherPosCount_lq = otherCount;

   // ══════════════════════════════════════════════════════════════════
   // مرحله ۲: بررسی پوزیشن
   // ══════════════════════════════════════════════════════════════════
   if(symPosCount == 0)
   {
      ObjectsDeleteAll(0, LQ_OBJ_PREFIX);
      g_prevSymPosCount = 0;
      // اگه دکمه فعال بود و پوزیشن‌ها بسته شدن → برگشت به حالت اولیه
      if(g_liquidActive)
      {
         g_liquidActive   = false;
         g_liquidBtnState = 0;
         string _btn = dashboardPrefix + "LiquidBtn";
         string _lbl = dashboardPrefix + "LiquidStatus";
         ObjectSetInteger(0, _btn, OBJPROP_BGCOLOR, clrGold);
         ObjectSetInteger(0, _btn, OBJPROP_COLOR,   clrBlack);
         ObjectSetString (0, _lbl, OBJPROP_TEXT,    "پوزیشن بسته شد - غیرفعال");
         ObjectSetInteger(0, _lbl, OBJPROP_COLOR,   clrDimGray);
         ChartRedraw(0);
      }
      return -1;
   }

   // ── حجم خالص ──────────────────────────────────────────────────────
   // BUG FIX: فقط وقتی IsCentAccount=true AND CentVolumeIsCentLot=true تقسیم کن
   // روی ECN، netLots = 0.3 لات واقعی است و نیازی به تقسیم ندارد
   double netLots    = buyLots - sellLots;
   double netLotsStd = netLots;
   if(IsCentAccount && CentVolumeIsCentLot)
      netLotsStd = netLots / 100.0;   // 30 cent-lot → 0.30 standard lot

   if(ShowDebugLogs) Print("💧 LQ debug | symPos=", symPosCount, " netLots=", netLots,
         " netLotsStd=", netLotsStd, " IsCent=", IsCentAccount,
         " buyLots=", buyLots, " sellLots=", sellLots);

   // ── بررسی هج کامل ─────────────────────────────────────────────────
   if(MathAbs(netLotsStd) < 0.00001)
   {
      ObjectsDeleteAll(0, LQ_OBJ_PREFIX);
      string hgName = LQ_OBJ_PREFIX + "hedge";
      if(ObjectFind(0, hgName) < 0)
         ObjectCreate(0, hgName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, hgName, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(0, hgName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, hgName, OBJPROP_YDISTANCE, 50);
      ObjectSetString (0, hgName, OBJPROP_TEXT,      "LIQUID: Hedge Complete - N/A");
      ObjectSetString (0, hgName, OBJPROP_FONT,      "Arial Bold");
      ObjectSetInteger(0, hgName, OBJPROP_FONTSIZE,  9);
      ObjectSetInteger(0, hgName, OBJPROP_COLOR,     clrGold);
      ObjectSetInteger(0, hgName, OBJPROP_SELECTABLE,false);
      ObjectSetString (0, hgName, OBJPROP_TOOLTIP,
         "هج کامل: Buy و Sell هم‌حجم\nخط لیکوئید قابل محاسبه نیست");
      g_prevSymPosCount = symPosCount;
      ChartRedraw(0);
      return 0;
   }
   ObjectDelete(0, LQ_OBJ_PREFIX + "hedge");

   bool isLong  = (netLotsStd > 0);
   bool isHedge = (buyLots > 0.0 && sellLots > 0.0);

   // ── میانگین وزنی قیمت ورود برای جهت غالب ─────────────────────────
   double avgOpen;
   if(isLong)
      avgOpen = (buyLots > 0) ? (buySum / buyLots) : 0.0;
   else
      avgOpen = (sellLots > 0) ? (sellSum / sellLots) : 0.0;

   if(avgOpen <= 0.0)
   {
      Print("💧 LQ: avgOpen=0 → skip");
      g_prevSymPosCount = symPosCount;
      return -1;
   }

   // ══════════════════════════════════════════════════════════════════
   // مرحله ۳: متغیرهای حساب
   // ══════════════════════════════════════════════════════════════════
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin = AccountInfoDouble(ACCOUNT_MARGIN);

   double stopOutPct = AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
   if(stopOutPct <= 0.0) stopOutPct = LiquidStopOutPct;

   if(ShowDebugLogs) Print("💧 LQ debug | equity=", equity, " margin=", margin,
         " stopOut=", stopOutPct, "% symbolProfit=", symbolProfit,
         " avgOpen=", avgOpen);

   if(margin <= 0.0)
   {
      Print("💧 LQ: margin=0 → skip");
      g_prevSymPosCount = symPosCount;
      return -1;
   }

   double equityTarget = margin * stopOutPct / 100.0;

   // ── فاکتور تبدیل قیمت به سود ──────────────────────────────────────
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   // ══ CENT ACCOUNT FIX ══════════════════════════════════════════════
   // در حساب Cent، equity/margin/profit به سنت (×100) گزارش میشن.
   // اما tickValue که MT5 برمیگردونه برای Standard Lot به دلار است.
   // برای اینکه واحد denom با واحد equity یکی باشه، tickValue × 100 میکنیم.
   // مثال: equity=19600 سنت, tickValue=10 دلار → باید tickValue=1000 سنت باشه
   if(IsCentAccount)
      tickValue *= 100.0;

   if(ShowDebugLogs) Print("💧 LQ debug | tickValue=", tickValue, " tickSize=", tickSize,
         " (IsCent=", IsCentAccount, " → tickValue after cent-adjust)");

   if(tickSize <= 0.0 || tickValue <= 0.0)
   {
      Print("💧 LQ: tickSize/tickValue invalid → skip");
      g_prevSymPosCount = symPosCount;
      return -1;
   }
   double lotFactor = tickValue / tickSize;

   // ══════════════════════════════════════════════════════════════════
   // مرحله ۴: فرمول قیمت لیکوئید (V8 - avgOpen based)
   // ══════════════════════════════════════════════════════════════════
   // equityConst = بخشی از equity که به این نماد مربوط نیست
   //             = equity فعلی - سود/زیان این نماد (شامل swap)
   // در liqPrice: equityConst + (liqPrice - avgOpen) * netLotsStd * lotFactor = equityTarget
   //
   // Long : liqPrice = avgOpen + (equityTarget - equityConst) / (lotFactor * netLotsStd)
   // Short: همون فرمول - علامت netLotsStd منفی خودکار جهت درست میده
   double equityConst = equity - symbolProfit;
   double liqPrice;
   double denom = lotFactor * netLotsStd;

   if(MathAbs(denom) < 1e-10)
   {
      Print("💧 LQ: denom~0 → skip | lotFactor=", lotFactor, " netLotsStd=", netLotsStd);
      g_prevSymPosCount = symPosCount;
      return -1;
   }

   liqPrice = avgOpen + (equityTarget - equityConst) / denom;

   if(ShowDebugLogs) Print("💧 LQ debug | equityConst=", equityConst, " equityTarget=", equityTarget,
         " denom=", denom, " liqPrice=", liqPrice, " avgOpen=", avgOpen);

   if(!MathIsValidNumber(liqPrice) || liqPrice <= 0.0)
   {
      Print("💧 LQ: liqPrice invalid (", liqPrice, ") → skip");
      g_prevSymPosCount = symPosCount;
      return -1;
   }

   // ══════════════════════════════════════════════════════════════════
   // مرحله ۵: رنگ پویا بر اساس فاصله (pip)
   // ══════════════════════════════════════════════════════════════════
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double distPips   = MathAbs(currentBid - liqPrice) / (_Point * 10);

   color lineColor;
   if(distPips > 50)      lineColor = clrLimeGreen;   // ایمن
   else if(distPips > 20) lineColor = clrOrange;       // هشدار
   else                   lineColor = clrRed;           // خطر

   // ══════════════════════════════════════════════════════════════════
   // مرحله ۶: رسم/بروزرسانی خط افقی
   // ══════════════════════════════════════════════════════════════════
   string lqLine = LQ_OBJ_PREFIX + "line";
   if(ObjectFind(0, lqLine) >= 0)
   {
      ObjectSetDouble (0, lqLine, OBJPROP_PRICE, liqPrice);
      ObjectSetInteger(0, lqLine, OBJPROP_COLOR, lineColor);
   }
   else
   {
      if(!ObjectCreate(0, lqLine, OBJ_HLINE, 0, 0, liqPrice))
         Print("💧 LQ: ObjectCreate failed! err=", GetLastError());
      ObjectSetInteger(0, lqLine, OBJPROP_WIDTH,      3);
      ObjectSetInteger(0, lqLine, OBJPROP_STYLE,      STYLE_SOLID);
      ObjectSetInteger(0, lqLine, OBJPROP_BACK,       true);
      ObjectSetInteger(0, lqLine, OBJPROP_ZORDER,     0);     // v11.92: اولویت کلیک پایین‌تر از داشبورد
      ObjectSetInteger(0, lqLine, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lqLine, OBJPROP_COLOR,      lineColor);
   }

   // ── لیبل توضیحی ────────────────────────────────────────────────────
   string lqLabel   = LQ_OBJ_PREFIX + "label";
   string hedgeTxt  = isHedge ? " [هج ناقص]" : "";
   string lqText    = "LIQUID: " + DoubleToString(liqPrice, _Digits)
                    + " | " + DoubleToString(distPips, 0) + "pip"
                    + " | " + (isLong ? "L+" : "S-")
                    + DoubleToString(MathAbs(netLotsStd), 2) + hedgeTxt;

   datetime lblTime = (Bars(_Symbol, PERIOD_CURRENT) >= 6)
                    ? iTime(_Symbol, PERIOD_CURRENT, 5)
                    : TimeCurrent();
   if(ObjectFind(0, lqLabel) < 0)
   {
      ObjectCreate(0, lqLabel, OBJ_TEXT, 0, lblTime, liqPrice);
      ObjectSetString (0, lqLabel, OBJPROP_FONT,      "Arial Bold");
      ObjectSetInteger(0, lqLabel, OBJPROP_FONTSIZE,  9);
      ObjectSetInteger(0, lqLabel, OBJPROP_BACK,      false);
      ObjectSetInteger(0, lqLabel, OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0, lqLabel, OBJPROP_ANCHOR,    ANCHOR_LEFT_LOWER);
   }
   ObjectSetDouble (0, lqLabel, OBJPROP_PRICE,   liqPrice);
   ObjectSetString (0, lqLabel, OBJPROP_TEXT,    lqText);
   ObjectSetInteger(0, lqLabel, OBJPROP_COLOR,   lineColor);

   // ── Tooltip کامل ───────────────────────────────────────────────────
   string acctType = DetectCentAccount() ? "Cent" : "Standard/ECN";
   string riskTxt  = (distPips > 50) ? "ایمن ✅" : (distPips > 20) ? "هشدار ⚠️" : "خطر ❌";
   string lqTip = "LIQUID LEVEL\n"
      + "قیمت لیکوئید: "   + DoubleToString(liqPrice, _Digits)   + "\n"
      + "قیمت فعلی: "      + DoubleToString(currentBid, _Digits) + "\n"
      + "فاصله: "           + DoubleToString(distPips, 1) + " pip | " + riskTxt + "\n"
      + "avgOpen: "         + DoubleToString(avgOpen, _Digits)    + "\n"
      + "Equity: "          + DoubleToString(equity, 2)
      + " | SO: "           + DoubleToString(stopOutPct, 0) + "%\n"
      + "Margin: "          + DoubleToString(margin, 2)
      + " | Target: "       + DoubleToString(equityTarget, 2)     + "\n"
      + "Net: "             + DoubleToString(netLotsStd, 3)
      + " lot (" + (isLong ? "Long" : "Short") + ")" + hedgeTxt  + "\n"
      + "نماد: " + _Symbol + " (" + acctType + ")";
   ObjectSetString(0, lqLine,  OBJPROP_TOOLTIP, lqTip);
   ObjectSetString(0, lqLabel, OBJPROP_TOOLTIP, lqTip);

   g_prevSymPosCount = symPosCount;
   ChartRedraw(0);
   return 1;
}

void CreateDashboard()
{
   if(!ShowDashboard) return;

   // ─── DPI و scale ────────────────────────────────────────────────
   // FIX v12.11: تفکیک dpiScale (فونت) از layoutScale (ابعاد پنل)
   //
   // مشکل: dpiScale = (DPI/96) × userScale برای همه چیز → روی DPI=144 پنل 1.5× بزرگتر
   // ویندوز خودش همه چیز را به DPI scale می‌کند → داشبورد دوباره scale می‌خورد
   //
   // راه‌حل:
   //   dpiScale    = (DPI/96) × userScale  ← فقط فونت (MT5 فونت را scale نمی‌کند)
   //   layoutScale = userScale             ← ابعاد/فاصله‌ها (ویندوز DPI را handle می‌کند)
   //
   // نتیجه: Scale=85 روی هر DPI همان اندازه بصری نسبی دارد
   int    screenDPI   = GetScreenDPI();
   double dpiNorm     = 96.0 / screenDPI;   // DPI=96→1.0 | DPI=144→0.667 | DPI=192→0.5
   double userScale   = DashboardScalePercent / 100.0;
   if(userScale < 0.50) userScale = 0.50;
   if(userScale > 3.00) userScale = 3.00;
   g_dashUserScale = userScale;

   // ─── دو scale جداگانه ──────────────────────────────────────────────────
   // Sf = فونت: MT5 فونت را به DPI رندر می‌کند → باید با dpiNorm خنثی شود
   // Sl = layout: ویندوز پیکسل‌ها را scale می‌کند → فقط userScale کافی است
   double Sf = userScale * dpiNorm;   // برای font point size
   double Sl = userScale;             // برای عرض/ارتفاع/فاصله

   // فونت point size
   int dashFont      = (int)MathMax(6, MathRound(DashboardFontSize * Sf));
   int dashFontSmall = (int)MathMax(6, MathRound((DashboardFontSize-1) * Sf));
   g_dashBtnFontPt   = (int)MathMax(6, MathRound(8.0 * Sf));

   // ارتفاع ردیف و دکمه
   // ptToPixel با DPI واقعی: تبدیل pt→px فیزیکی (برای btnH که باید فونت را جا بدهد)
   double ptToPixel = screenDPI / 72.0;
   int labelPixH    = (int)MathCeil(dashFont * ptToPixel);
   int lineH        = labelPixH + (int)MathMax(2, MathRound(4*Sl));
   int btnPixH      = (int)MathCeil(g_dashBtnFontPt * ptToPixel);
   int btnH         = btnPixH + (int)MathMax(6, MathRound(8*Sl));
   int lqBtnH       = (int)MathRound(btnH * 1.3);
   int gap          = (int)MathMax(2, MathRound(4*Sl));
   int padX         = (int)MathMax(14, MathRound(28*Sl));
   int secGap       = (int)MathMax(3, MathRound(5*Sl));

   // ─── عرض دکمه‌ها ────────────────────────────────────────────────
   // در DPI بالا (>96) عرض دکمه‌ها ۲۰٪ بیشتر می‌شود تا خوانایی بهتر باشد
   // widthBoost: DPI=96→1.0 | DPI=144→1.2 | DPI=192→1.2 (سقف ۱.۲)
   double widthBoost = (screenDPI > 96) ? 1.20 : 1.0;
   int pBtnW  = (int)MathMax(28, MathRound(30*Sl*widthBoost));  // preset (1D…1H)
   int fBtnW  = (int)MathMax(50, MathRound(54*Sl*widthBoost));  // filter mode
   int aBtnW  = (int)MathMax(52, MathRound(56*Sl*widthBoost));  // AI/filter buttons

   // ردیف‌های دکمه
   int presetW = 5*(pBtnW+gap)-gap;
   int filterW = 3*(fBtnW+gap)-gap;
   int ai4W    = 4*(aBtnW+gap)-gap;
   int ai3W    = 3*(aBtnW+gap)-gap;
   int dirW    = 3*(fBtnW+gap)-gap;
   // فیلترهای AI با عرض 20٪ بیشتر — 3 دکمه در هر ردیف
   int fAIBtnWCalc = (int)MathRound(aBtnW * 1.20);
   int aiFilter3W  = 3*(fAIBtnWCalc+gap)-gap;

   // عرض پنل: حداکثر تمام ردیف‌ها + padding دو طرف
   int innerW  = (int)MathMax(presetW, MathMax(filterW, MathMax(aiFilter3W, dirW)));
   int panelW  = innerW + 2*padX;

   // ─── مختصات ─────────────────────────────────────────────────────
   // FIX v12.08: DashboardXOffset/YOffset مستقیماً به پیکسل فیزیکی ترجمه می‌شوند
   // (قبلاً دوباره ضربدر dpiScale می‌شدند → در DPI 192 پنل دوبرابر جابجا و از صفحه خارج می‌شد)
   // در DPI بالا فاصله از لبه راست را بیشتر می‌کنیم تا داشبورد به کادر نچسبد
   // DPI=96: +0px | DPI=144: +DashboardXOffset×0.5 | DPI=192: +DashboardXOffset×1.0
   int dpiExtraMargin = (screenDPI > 96) ? (int)MathRound(DashboardXOffset * (screenDPI - 96) / 96.0 * 0.5) : 0;
   int xStart  = DashboardXOffset + dpiExtraMargin;
   int yStart  = DashboardYOffset;

   // titleBtnW اینجا تعریف می‌شه چون هم در BG calc و هم در Title Bar لازمه
   int titleBtnW = (int)MathRound(22*Sl);

   // FIX v12.08: ButtonsXOffset و ButtonsYOffset اعمال می‌شوند
   // این offset ها موقعیت دکمه‌ها را نسبت به پنل جابجا می‌کنند
   int bxOff = ButtonsXOffset;   // پیکسل‌های افقی اضافه برای دکمه‌ها
   int byOff = ButtonsYOffset;   // پیکسل‌های عمودی اضافه برای دکمه‌ها

   // lx = XDISTANCE اولین ستون محتوا (برای دکمه‌ها که از lx به راست امتداد دارند)
   int lx   = xStart + padX + bxOff;
   int yPos = yStart + byOff;

   // در corner 1/3: OBJ_LABEL از XDISTANCE به راست کشیده می‌شه (به سمت لبه راست صفحه)
   // پس برای نمایش داخل پنل:
   //   labelLx   = lبه چپ بصری پنل ← text از اینجا به راست = نیمه چپ پنل
   //   labelMidX = وسط بصری پنل    ← text از اینجا به راست = نیمه راست پنل
   int labelLx   = lx + innerW;            // visual left of panel  → چپ‌ترین label شروع
   int labelMidX = lx + innerW * 1 / 5;  // right column — فاصله کافی از ستون چپ

   // ─── ارتفاع BG ─────────────────────────────────────────────────
   int bgH  = btnH  + secGap;                               // title bar
   if(ShowPresetButtons) bgH += btnH  + secGap;             // preset
   if(ShowFilterButtons) bgH += btnH  + secGap;             // filter mode
   if(ShowAIButtons)     bgH += lineH + 4*(btnH+secGap) + lineH + secGap;  // AI: title+4 btn rows+status label
   bgH += lineH + 5*lineH + secGap;                         // market info (title+5 rows)
   bgH += lineH + 6*lineH + secGap;  // 🆕 v13.14: alert (title + 6 rows = 6x2 grid, Spike row added)
   bgH += lineH + btnH + secGap;                            // direction title + buttons
   bgH += padX + 20;                                             // bottom padding

   // ─── BG — corner 1/3 aware ─────────────────────────────────────
   // در corner 1/3: XDISTANCE بزرگتر = شیء بیشتر به چپ صفحه
   // بزرگترین XDISTANCE در محتوا = چپ‌ترین نقطه بصری
   // برای OBJ_BUTTON: هر دکمه از XDISTANCE به سمت چپ صفحه امتداد دارد (XSIZE به چپ)
   // پس چپ‌ترین دکمه: آن‌که XDISTANCE + XSIZE = max → دکمه AI با XDISTANCE = lx + innerW - fAIBtnWCalc
   // و close button با XDISTANCE + titleBtnW = lx + innerW
   int maxContentXDist = MathMax(lx + innerW - fAIBtnWCalc,
                                 lx + innerW - titleBtnW);
   int bgXDist = maxContentXDist + padX;            // padX فضای خالی سمت چپ پنل
   int bgXSizeBase = (maxContentXDist - lx) + fAIBtnWCalc + 2*padX + 30;  // عرض پایه بدون boost
   int bgXSize     = (int)MathRound(bgXSizeBase * widthBoost);             // عرض نهایی با boost
   // گسترش BG فقط به سمت چپ: bgXDist را ثابت نگه می‌داریم، bgXSize بزرگتر می‌شه
   // در corner راست: XDISTANCE = فاصله از راست به لبه چپ BG
   // bgXDist ثابت → لبه راست BG ثابت → bgXSize بزرگتر → فقط لبه چپ گسترش پیدا می‌کنه

   // ─── AUTO-CLAMP corner 1/3 ───────────────────────────────────────────────
   // bgXDist بر اساس bgXSizeBase محاسبه شده — clamp هم از bgXSizeBase استفاده می‌کند
   // bgXSize بزرگتر از bgXSizeBase است و به چپ گسترش پیدا می‌کند (بدون تغییر bgXDist)
   {
      int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      if(chartW <= 0) chartW = 1366;
      if(bgXDist < bgXSizeBase) bgXDist = bgXSizeBase;  // نریفتن از راست (بر اساس اندازه پایه)
      if(bgXDist + bgXSize > chartW) bgXDist = chartW - bgXSize;  // نریفتن از چپ
      if(bgXDist < 0) bgXDist = 0;
   }
   // ─────────────────────────────────────────────────────────────────────────────

   string bgNm = dashboardPrefix + "BG";
   ObjectCreate(0, bgNm, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgNm, OBJPROP_CORNER,      DashboardCorner);
   ObjectSetInteger(0, bgNm, OBJPROP_XDISTANCE,   bgXDist);
   ObjectSetInteger(0, bgNm, OBJPROP_YDISTANCE,   yStart - (int)MathRound(4*Sl));
   ObjectSetInteger(0, bgNm, OBJPROP_XSIZE,       bgXSize);
   ObjectSetInteger(0, bgNm, OBJPROP_YSIZE,       bgH);
   ObjectSetInteger(0, bgNm, OBJPROP_BGCOLOR,     DashboardBackColor);
   ObjectSetInteger(0, bgNm, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bgNm, OBJPROP_BACK,        false);

   // helper: center a row of width rowW inside the panel
   // returns the starting X (XDISTANCE) for the first button in the row
   // در corner 1/3: i=0 سمت راست بصری، i=n-1 سمت چپ بصری (XDISTANCE بزرگتر = چپ‌تر)
   #define ROW_X(rowW)  (lx + (innerW - (rowW)) / 2)

   // ─── TITLE BAR ─────────────────────────────────────────────────
   {
      // در corner 1/3:
      //   PowerOff (✕): سمت راست بصری = XDISTANCE کوچک = lx + titleBtnW + gap (نزدیک لبه راست BG)
      //   Reset (↺): سمت چپ بصری = XDISTANCE بزرگ = lx + innerW - titleBtnW
      // PowerOff: چسبیده به لبه راست بصری پنل
      // FIX v12.11: از bgLeftEdge امن استفاده می‌کنیم (بعد از clamp)
      const int POWEROFF_RIGHT_MARGIN = 50;  // <-- فاصله از لبه راست پنل (پیکسل DPI-independent)
      int bgLeftEdge = bgXDist - bgXSize;
      if(bgLeftEdge < 0) bgLeftEdge = 0;
      int pwrOffX = bgLeftEdge + POWEROFF_RIGHT_MARGIN;
      CreateButton(dashboardPrefix+"PowerOffBtn",
                   pwrOffX, yPos, titleBtnW, btnH, "X", clrWhite, clrRed);
      ObjectSetString(0,dashboardPrefix+"PowerOffBtn",OBJPROP_TOOLTIP,
         "بستن کامل اکسپرت و پاک‌کردن تمام خطوط و اشیاء از چارت");
      // عنوان وسط
      int tLblX = labelMidX + (int)MathRound(25*Sl);
      CreateLabel(dashboardPrefix+"TitleLbl", tLblX, yPos+(int)(btnH*0.15),
                  "HelpMe v13.20", clrNavy, dashFontSmall);
      // Reset: سمت چپ بصری (XDISTANCE بزرگتر)
      int closeX = lx + innerW - titleBtnW;
      CreateButton(dashboardPrefix+"ResetBtn",
                   closeX, yPos, titleBtnW, btnH, "R", clrWhite, clrDarkSlateGray);
      ObjectSetString(0,dashboardPrefix+"ResetBtn",OBJPROP_TOOLTIP,
         "بازنشانی همه‌ی تنظیمات به حالت اولیه (پیش‌فرض)");
   }
   yPos += btnH + secGap;

   // ─── PRESET BUTTONS — Signal Gap ──────────────────────────────
   if(ShowPresetButtons)
   {
      CreateLabel(dashboardPrefix+"SignalGapTitle", labelLx, yPos, "Signal Gap:", clrCyan, dashFont);
      yPos += lineH;
      string ids[]  = {"M1",   "M5",   "M15",  "M30",  "H1"};
      string lbls[] = {"10",   "12",   "15",   "20",   "25"};
      string tips[] = {
         "حداقل فاصله نمایش سیگنال‌ها از هم\nسیگنال جدید حداقل ۱۰ کندل بعد از آخرین سیگنال داده می‌شود",
         "حداقل فاصله نمایش سیگنال‌ها از هم\nسیگنال جدید حداقل ۱۲ کندل بعد از آخرین سیگنال داده می‌شود",
         "حداقل فاصله نمایش سیگنال‌ها از هم\nسیگنال جدید حداقل ۱۵ کندل بعد از آخرین سیگنال داده می‌شود",
         "حداقل فاصله نمایش سیگنال‌ها از هم\nسیگنال جدید حداقل ۲۰ کندل بعد از آخرین سیگنال داده می‌شود",
         "حداقل فاصله نمایش سیگنال‌ها از هم\nسیگنال جدید حداقل ۲۵ کندل بعد از آخرین سیگنال داده می‌شود"
      };
      int rx = ROW_X(presetW)-(int)MathRound(43*Sl);
      for(int i=0;i<5;i++)
      {
         string nm = dashboardPrefix+"Btn_"+ids[i];
         color bc  = (currentPreset==(ENUM_TIMEFRAME_PRESET)i) ? clrDodgerBlue : clrDarkSlateGray;
         CreateButton(nm, rx+i*(pBtnW+gap), yPos, pBtnW, btnH, lbls[i], clrWhite, bc);
         ObjectSetString(0,nm,OBJPROP_TOOLTIP,tips[i]);
      }
      yPos += btnH + secGap;
   }

   // ─── FILTER LEVEL ──────────────────────────────────────────────
   if(ShowFilterButtons)
   {
      CreateLabel(dashboardPrefix+"FilterLevelTitle", labelLx, yPos, "Filter Level:", clrCyan, dashFont);
      yPos += lineH;
      string ids[]  = {"Relaxed",  "Balanced", "Strict"};
      string lbls[] = {"Easy",     "Normal",   "Hard"};
      string tips[] = {
         "تنظیم حساسیت سیگنال‌دهی\nفیلترهای کمتر → سیگنال‌های بیشتری دریافت می‌کنید",
         "تنظیم حساسیت سیگنال‌دهی\nحالت استاندارد و متوازن",
         "تنظیم حساسیت سیگنال‌دهی\nفیلترهای سخت‌گیرانه → فقط سیگنال‌های بسیار مطمئن نمایش داده می‌شوند"
      };
      int rx = ROW_X(filterW)-20;
      for(int i=0;i<3;i++)
      {
         string nm = dashboardPrefix+"FilterBtn_"+ids[i];
         color bc  = (currentFilterMode==i) ? clrDodgerBlue : clrDarkSlateGray;
         CreateButton(nm, rx+i*(fBtnW+gap), yPos, fBtnW, btnH, lbls[i], clrWhite, bc);
         ObjectSetString(0,nm,OBJPROP_TOOLTIP,tips[i]);
      }
      yPos += btnH + secGap;
   }

   // ─── FILTERS (AI section) ─────────────────────────────────────
   if(ShowAIButtons)
   {
      CreateLabel(dashboardPrefix+"AITitle", labelLx, yPos, "Filters:", clrCyan, dashFont);
      yPos += lineH;

      // ابعاد دکمه فیلتر: 20٪ بزرگتر از aBtnW برای خوانایی بهتر
      int fAIBtnW = (int)MathRound(aBtnW * 1.70);
      int ai3rowW = 3*(fAIBtnW+gap)-gap;

      // row 1: Support/Resist | Candle Pattern | Trend Filter
      {
         string ns[] = {"SR",             "Price",           "MTF"};
         string ls[] = {"Support/Resist", "Candle Pattern",  "Trend Filter"};
         bool   as[] = {localEnableSR, localEnablePriceAction, localEnableMTF};
         string ts[] = {
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nنمایش خطوط حمایت و مقاومت روزانه روی چارت",
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nتشخیص الگوهای کندلی (پین‌بار، اینگالفینگ، چکش و...) برای تأیید سیگنال",
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nفقط سیگنال‌هایی نمایش داده شوند که هم‌جهت با روند تایم‌فریم‌های بالاتر (یک و چهار ساعته) باشند"
         };
         int rx = ROW_X(ai3rowW) +(int)MathRound(18*Sl);
         for(int i=0;i<3;i++){
            string nm=dashboardPrefix+"AIBtn_"+ns[i];
            CreateButton(nm,rx+i*(fAIBtnW+gap),yPos,fAIBtnW,btnH,ls[i],clrWhite,as[i]?clrDodgerBlue:clrDarkSlateGray);
            ObjectSetString(0,nm,OBJPROP_TOOLTIP,ts[i]);
         }
         yPos += btnH + secGap;
      }
      // row 2: Market State | Stop Hunt | Price Gap
      {
         string ns[] = {"Regime",      "LiqSwp",    "FVG"};
         string ls[] = {"Market State","Stop Hunt", "Price Gap"};
         bool   as[] = {localEnableMarketRegime, localEnableLiqSwp, localEnableFVG};
         string ts[] = {
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nتشخیص وضعیت بازار (روند دار / رنج / پرنوسان / آرام) و فیلتر سیگنال در بازار رنج",
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nتشخیص شکار استاپ و برگشت از نواحی نقدینگی (فیک‌بریک) — از قوی‌ترین سیگنال‌های برگشت",
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nتشخیص شکاف‌های قیمتی که بازار تمایل به پر کردن آن‌ها دارد"
         };
         int rx = ROW_X(ai3rowW)+(int)MathRound(18*Sl);
         for(int i=0;i<3;i++){
            string nm=dashboardPrefix+"AIBtn_"+ns[i];
            CreateButton(nm,rx+i*(fAIBtnW+gap),yPos,fAIBtnW,btnH,ls[i],clrWhite,as[i]?clrDodgerBlue:clrDarkSlateGray);
            ObjectSetString(0,nm,OBJPROP_TOOLTIP,ts[i]);
         }
         yPos += btnH + secGap;
      }
      // row 3: Ichimoku | Volume | Mean Return
      {
         string ns[] = {"Ichi",      "Vol",      "RTM"};
         string ls[] = {"Ichimoku",  "Volume",   "Mean Return"};
         bool   as[] = {localEnableIchimoku, localEnableSmartVol, localEnableRTM};
         string ts[] = {
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nاستفاده از ابر ایچیموکو برای تأیید سیگنال (در تایم فریم‌های بالاتر نویز دارد)",
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nبررسی حجم تیک نسبت به میانگین → سیگنال‌های با حجم خیلی کم فیلتر می‌شوند",
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nبررسی فاصله‌ی قیمت از میانگین دویست کندل → هرچه دورتر، احتمال برگشت بیشتر"
         };
         int rx = ROW_X(ai3rowW)+(int)MathRound(18*Sl);
         for(int i=0;i<3;i++){
            string nm=dashboardPrefix+"AIBtn_"+ns[i];
            CreateButton(nm,rx+i*(fAIBtnW+gap),yPos,fAIBtnW,btnH,ls[i],clrWhite,as[i]?clrDodgerBlue:clrDarkSlateGray);
            ObjectSetString(0,nm,OBJPROP_TOOLTIP,ts[i]);
         }
         yPos += btnH + secGap;
      }
      // row 4: Local EMA | Global EMA | Liquid Level
      {
         bool maAny = g_maM15Active||g_maM30Active||g_maH1Active||g_maH4Active||g_maD1Active;
         int  rx    = ROW_X(ai3rowW)+(int)MathRound(18*Sl);
         CreateButton(dashboardPrefix+"MABtn_MAPLUS", rx,               yPos, fAIBtnW, btnH,
            "Global EMA",   clrWhite, maAny?clrDodgerBlue:clrDarkSlateGray);
         ObjectSetString(0,dashboardPrefix+"MABtn_MAPLUS",OBJPROP_TOOLTIP,
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nرسم هم‌زمان EMAهای ۲۰، ۵۰، ۱۰۰ و ۲۰۰ کندلی روی همین چارت");
         CreateButton(dashboardPrefix+"MABtn_FEMA",   rx+fAIBtnW+gap,   yPos, fAIBtnW, btnH,
            "Local EMA",  clrWhite, g_femaActive?clrDodgerBlue:clrDarkSlateGray);
         ObjectSetString(0,dashboardPrefix+"MABtn_FEMA",OBJPROP_TOOLTIP,
            "اعمال فیلترهای بیشتر برای بهتر کردن سیگنال‌ها\nرسم EMA200 از تایم‌فریم‌های مختلف (M15, M30, H1, H4, D1)");
         CreateButton(dashboardPrefix+"LiqLevelFilterBtn", rx+2*(fAIBtnW+gap), yPos, fAIBtnW, btnH,
            "Liquid Level", clrWhite, g_liquidActive?clrDodgerBlue:clrDarkSlateGray);
         ObjectSetString(0,dashboardPrefix+"LiqLevelFilterBtn",OBJPROP_TOOLTIP,
            "محاسبه و رسم خط لیکوئید شدن حساب → فاصله‌ی قیمت تا صفر شدن موجودی را نشان می‌دهد");
         yPos += btnH + secGap;
      }
      // row 5: Liquid Level Status (centered, single label)
      {
         CreateLabel(dashboardPrefix+"LiquidStatus", labelLx, yPos,
                      "Liquid: inactive - click to activate", clrDimGray, dashFontSmall);
         ObjectSetString(0,dashboardPrefix+"LiquidStatus",OBJPROP_TOOLTIP,
            "نمایش وضعیت محاسبه و رسم خط لیکوئیدی برای پوزیشن شما در این زوج ارز");
         yPos += lineH + secGap;
      }
   }

   // ─── MARKET ─────────────────────────────────────────────────
   {
      CreateLabel(dashboardPrefix+"InfoTitle",    labelLx, yPos, "Market:", clrCyan, dashFont);
      yPos += lineH;
      CreateLabel(dashboardPrefix+"SessionStatus",labelLx, yPos, "Now: ...", clrGray, dashFont);
      ObjectSetString(0,dashboardPrefix+"SessionStatus",OBJPROP_TOOLTIP,
         "جلسه‌ی معاملاتی فعلی به ساعت محلی شما\nبازار باز یا بسته بودن را نشان می‌دهد\nتوکیو: ۰۰:۰۰-۰۹:۰۰ گرینویچ\nلندن: ۰۸:۰۰-۱۷:۰۰ گرینویچ\nنیویورک: ۱۳:۰۰-۲۲:۰۰ گرینویچ");
      yPos += lineH;
      // ADX
      CreateLabel(dashboardPrefix+"ADXStatus",    labelLx, yPos, "ADX: ...", clrGray, dashFont);
      yPos += lineH;
      // Profit
      CreateLabel(dashboardPrefix+"InfoPL",       labelLx, yPos, "Profit: No open position", clrGray, dashFont);
      ObjectSetString(0,dashboardPrefix+"InfoPL",OBJPROP_TOOLTIP,
         "سود یا زیان فعلی همه‌ی پوزیشن‌های باز روی این نماد (به دلار)");
      yPos += lineH;
      // Spread
      CreateLabel(dashboardPrefix+"SpreadStatus", labelLx, yPos, "Spread: ...", clrGray, dashFont);
      ObjectSetString(0,dashboardPrefix+"SpreadStatus",OBJPROP_TOOLTIP,
         "فاصله بین قیمت خرید و فروش در لحظه به پوینت\n۰-۳ پوینت: اسپرد عالی\n۳-۱۲ پوینت: قابل قبول\nبیش از ۱۲: اسپرد بالا");
      yPos += lineH;
      // Trend
      CreateLabel(dashboardPrefix+"InfoTrend",    labelLx, yPos, "Trend: ...", clrGray, dashFont);
      ObjectSetString(0,dashboardPrefix+"InfoTrend",OBJPROP_TOOLTIP,
         "مقایسه جهت معامله شما با روند قیمت زوج ارز در تمام تایم فریم‌ها بر اساس جدول وزن‌دار");
      yPos += lineH + secGap;
   }

   // ─── ALERTS (چراغ‌ها) — v13.20: ۵ ردیف ۲ ستون (StepDecay حذف شد) ──
   // ترتیب (چپ | راست):
   //   ردیف ۱: Crisis         | Price Zone
   //   ردیف ۲: Killer         | Currency Flow
   //   ردیف ۳: Trend Strength | Hi Alert
   //   ردیف ۴: Daily Struct   | Mkt Phase
   //   ردیف ۵: Reversion      | Spike
   {
      CreateLabel(dashboardPrefix+"TLTitle", labelLx, yPos, "Alerts:", clrCyan, dashFont);
      yPos += lineH;

      // در corner RIGHT_UPPER:
      // labelLx = lx + innerW = لبه چپ بصری پنل
      // ستون راست بصری = labelLx        (شروع از لبه چپ پنل)
      // ستون چپ  بصری = labelLx - lColW (داخل پنل، به سمت راست بصری)
      // V13.10 FIX: lxLeft = labelLx - lColW تا داخل پنل بمونه
      int lColW   = (innerW * 80) / 100;   // ۴۸٪ عرض پنل
      int lxRight = labelLx;               // ستون راست بصری (لبه چپ پنل)
      int lxLeft  = labelLx - lColW;       // ستون چپ  بصری (داخل پنل)

      // ── ردیف ۱: Crisis (چپ) | Price Zone (راست) ─────────────
      CreateLabel(dashboardPrefix+"TL_CRISIS", lxLeft, yPos, "● Crisis: --",      clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_CRISIS",OBJPROP_TOOLTIP,
         "Crisis Light\n"
         "Green : هیچ شرطی برقرار نیست\n"
         "Yellow: ۲ چراغ قرمز + Flow ضعیف\n"
         "Orange: ۲ چراغ قرمز + ADX>40\n"
         "Red   : ۳ چراغ قرمز + بحران کامل\n"
         "─────\nترکیب RTM+ADX+STRUCT+FLOW");

      CreateLabel(dashboardPrefix+"TL_ZOMBIE", lxRight, yPos, "● Price Zone: --",  clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_ZOMBIE",OBJPROP_TOOLTIP,
         "Price Zone\n"
         "Safe  : قیمت در Zone ورود یا بهتر\n"
         "Red   : Zone ضرر (تایید H1)\n"
         "─────\nگرید مطلق قیمت + تایید H1");
      yPos += lineH;

      // ── ردیف ۲: Killer (چپ) | Currency Flow (راست) ──────────
      CreateLabel(dashboardPrefix+"TL_KILLER", lxLeft, yPos, "● Killer: --",       clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_KILLER",OBJPROP_TOOLTIP,
         "KILLER Alert\n"
         "Safe  : شرایط عادی\n"
         "Warn  : پله3+ZoneDelta+Score40\n"
         "Red   : پله4+ZoneDelta+Score50+H1\n"
         "─────\nهج بگیر یا با ضرر ببند\nفقط روی step5 فعال");

      CreateLabel(dashboardPrefix+"TL_FLOW",   lxRight, yPos, "● Curr Flow: --",   clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_FLOW",OBJPROP_TOOLTIP,
         "Currency Flow | H4\n"
         "Safe   : جریان موافق\n"
         "Danger : سونامی ارزی\n"
         "─────\nSister Pairs momentum H4");
      yPos += lineH;

      // ── ردیف ۳: Trend Strength (چپ) | Hi Alert (راست) ────────
      CreateLabel(dashboardPrefix+"TL_TREND",    lxLeft, yPos, "● Trend Str: --",  clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_TREND",OBJPROP_TOOLTIP,
         "Trend Strength | H4\n"
         "Safe   : روند ضعیف\n"
         "Danger : روند قوی خلاف\n"
         "─────\nترکیب ADX + Efficiency Ratio");

      CreateLabel(dashboardPrefix+"TL_HIGHALT",  lxRight, yPos, "● Hi Alert: --",    clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_HIGHALT",OBJPROP_TOOLTIP,
         "Hi Alert\n"
         "Active: ADX>=35 + Flow خلاف\n"
         "─────\nپیش‌هشدار پیش از بحران");
      yPos += lineH;

      // ── ردیف ۴: Daily Struct (چپ) | Mkt Phase (راست) ─────────
      CreateLabel(dashboardPrefix+"TL_STRUCT",   lxLeft, yPos, "● Daily Struct: --", clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_STRUCT",OBJPROP_TOOLTIP,
         "Daily Structure | D1\n"
         "Safe   : کف/سقف D1 سالم\n"
         "Danger : سطح D1 شکست\n"
         "─────\nکف/سقف ۱۰ کندل اخیر D1");

      CreateLabel(dashboardPrefix+"TL_MKTPHASE", lxRight, yPos, "● Mkt Phase: --", clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_MKTPHASE",OBJPROP_TOOLTIP,
         "Mkt Phase — فاز بازار بلندمدت\n"
         "─────────────────────\n"
         "🟢 Range   : بازار رنج — سیستم عالی کار میکنه\n"
         "🟡 Neutral : فاز گذار — احتیاط\n"
         "🔴 Trend   : روند انفجاری — سیستم در خطر\n"
         "─────\nADR(10روز) / ADR(60روز) روی D1");
      yPos += lineH;

      // ── ردیف ۵: Reversion (چپ) | Spike (راست) ──────────────── 🆕 v13.14
      CreateLabel(dashboardPrefix+"TL_RTM",      lxLeft, yPos, "● Reversion: --",  clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_RTM",OBJPROP_TOOLTIP,
         "Reversion (RTM) | H1\n"
         "فاصله از میانگین ۲۰۰ کندل گذشته\n"
         "Safe   : قیمت نزدیک میانگین\n"
         "Danger : دور، احتمال برگشت کم\n"
         "─────\nEMA200 روی H1");

      CreateLabel(dashboardPrefix+"TL_SPIKE", lxRight, yPos, "● Spike: --", clrDimGray, dashFontSmall);
      ObjectSetString(0,dashboardPrefix+"TL_SPIKE",OBJPROP_TOOLTIP,
         "Spike Detector — حرکت ناگهانی چندتایم‌فریمه\n"
         "مستقل از پله Xmoon — فقط قیمت\n"
         "🟢 Normal  : حرکت طبیعی بازار\n"
         "🟡 Warning : شروع حرکت سریع\n"
         "🔴 Spike   : حرکت انفجاری در چند TF\n"
         "─────\nM15+M30+H1+H4+D1 وزن‌دار");

      yPos += lineH + secGap;
   }

   // ─── DIRECTION — DPI-safe, panel-anchored ────────────────────
   {
      int dirY = yPos;
      // عنوان Direction
      CreateLabel(dashboardPrefix+"DirTitle", labelLx, dirY, "Direction:", clrCyan, dashFont);
      dirY += lineH;
      int rx   = ROW_X(dirW)-(int)MathRound(20*Sl);
      color buyCol  = (g_dirMode==1) ? clrDodgerBlue   : clrDarkSlateGray;
      color allCol  = (g_dirMode==0) ? clrDodgerBlue   : clrDarkSlateGray;
      color sellCol = (g_dirMode==2) ? clrDodgerBlue    : clrDarkSlateGray;
      CreateButton(dashboardPrefix+"DirBtn_Buy",  rx,               dirY, fBtnW, btnH, "Buy",  clrWhite, buyCol);
      ObjectSetString(0,dashboardPrefix+"DirBtn_Buy",OBJPROP_TOOLTIP,
         "تحلیل چراغ‌ها و رنگ چارت برای حالت خرید\nچه پوزیشن داشته باشید چه نداشته باشید");
      CreateButton(dashboardPrefix+"DirBtn_All",  rx+fBtnW+gap,     dirY, fBtnW, btnH, "All",  clrWhite, allCol);
      ObjectSetString(0,dashboardPrefix+"DirBtn_All",OBJPROP_TOOLTIP,
         "تشخیص خودکار: اگر پوزیشن خرید دارید تحلیل خرید، اگر فروش دارید تحلیل فروش");
      CreateButton(dashboardPrefix+"DirBtn_Sell", rx+2*(fBtnW+gap), dirY, fBtnW, btnH, "Sell", clrWhite, sellCol);
      ObjectSetString(0,dashboardPrefix+"DirBtn_Sell",OBJPROP_TOOLTIP,
         "تحلیل چراغ‌ها و رنگ چارت برای حالت فروش\nچه پوزیشن داشته باشید چه نداشته باشید");
   }

   #undef ROW_X
   ChartRedraw();
}
   


//+------------------------------------------------------------------+
//| 🔄 UPDATE DASHBOARD v12                                          |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!ShowDashboard) return;
   static datetime s_lastUpdate = 0;
   datetime _nowU = TimeCurrent();
   if(!g_forceUpdateDashboard && (_nowU - s_lastUpdate) < 1)
      return;
   s_lastUpdate = _nowU;

   // ── تشخیص آخر هفته ─────────────────────────────────────────────
   MqlDateTime _gmtNow;
   TimeToStruct(TimeGMT(), _gmtNow);
   int _dow = _gmtNow.day_of_week;
   int _hr  = _gmtNow.hour;
   bool marketClosed = (_dow == 6) || (_dow == 0 && _hr < 22) || (_dow == 5 && _hr >= 22);

   // ── EA Status (بالای عنوان داشبورد، داخل پنل) ────────────────
   // در v12 EAStatus داخل title bar نیست بلکه در tooltip داشبورد است

   // ══════════════════════════════════════════════════════════════
   // بخش ۱: اطلاعات بازار
   // ══════════════════════════════════════════════════════════════

   // ── Chart Trend (جایگزین StatusLabel خارجی + InfoPosition) ────
   {
      int buy_cnt = 0, sell_cnt = 0;
      double pl = 0;
      for(int i = PositionsTotal()-1; i >= 0; i--)
      {
         if(HM_PositionBelongsToSymbol(PositionGetSymbol(i), _Symbol))   // 🆕 v13.49 P4
         {
            long pt = PositionGetInteger(POSITION_TYPE);
            if(pt == POSITION_TYPE_BUY)  buy_cnt++;
            if(pt == POSITION_TYPE_SELL) sell_cnt++;
            pl += PositionGetDouble(POSITION_PROFIT);
         }
      }
      pl /= DetectCentAccount() ? 100.0 : 1.0;

      string trendLine;
      color  trendColor;
      string plLine = "";
      color  plColor = clrGray;

      bool isHedge = (buy_cnt > 0 && sell_cnt > 0);

      if(buy_cnt == 0 && sell_cnt == 0 && g_dirMode == 0)
      {
         // بدون معامله و دکمه All — روند کلی چارت نشان داده می‌شود
         double absScore = MathAbs(g_csvScore);
         bool isBull = (g_csvScore > 0);
         string trendDir = (absScore < 10) ? "Neutral" : (isBull ? "Uptrend" : "Downtrend");
         trendLine  = "Trend: No Position | " + trendDir
                      + " (" + (g_csvScore >= 0 ? "+" : "") + IntegerToString((int)g_csvScore) + ")";
         trendColor = clrDimGray;
         // 🩹 Patch 1: plLine توسط UpdateProfitLabel هر تیک آپدیت می‌شود — اینجا فقط مقدار اولیه
         plLine = "Profit: No open position";
         plColor = clrDimGray;
      }
      else if(buy_cnt == 0 && sell_cnt == 0 && g_dirMode != 0)
      {
         // 🩹 Patch 2 (V12.06): دکمه Buy/Sell انتخاب شده بدون پوزیشن واقعی
         bool dirBuy    = (g_dirMode == 1);
         double absScore = MathAbs(g_csvScore);
         bool isBull     = (g_csvScore > 0);
         bool aligned    = (isBull && dirBuy) || (!isBull && !dirBuy);
         string trendDir = (absScore < 10) ? "Neutral" : (isBull ? "Uptrend" : "Downtrend");
         string dirLabel = dirBuy ? "[Buy]" : "[Sell]";
         string statusTxt = (absScore < 10) ? "NEUTRAL" : (aligned ? "SAFE" : "ALARM");
         trendLine  = "Trend: " + dirLabel + " " + statusTxt + " | " + trendDir
                      + " (" + (g_csvScore >= 0 ? "+" : "") + IntegerToString((int)g_csvScore) + ")";
         trendColor = (absScore < 10) ? clrDimGray : (aligned ? clrLime : clrOrangeRed);
         plLine = "Profit: No open position";
         plColor = clrDimGray;
      }
      else if(isHedge)
      {
         trendLine  = "Trend: Hedge Active (" + IntegerToString(buy_cnt) + "B / " + IntegerToString(sell_cnt) + "S)";
         trendColor = clrDimGray;
         plLine     = "Profit: " + (pl >= 0 ? "+" : "") + DoubleToString(pl, 2) + " $";
         plColor    = (pl > 0) ? clrLime : (pl < 0) ? clrRed : clrWhite;
      }
      else
      {
         double absScore = MathAbs(g_csvScore);
         bool isBull = (g_csvScore > 0);
         string trendDir = (absScore < 10) ? "Neutral" : (isBull ? "Uptrend" : "Downtrend");
         string dirTxt   = (buy_cnt > 0)
                           ? "Buy (" + IntegerToString(buy_cnt) + ")"
                           : "Sell (" + IntegerToString(sell_cnt) + ")";
         bool aligned = (isBull && buy_cnt > 0) || (!isBull && sell_cnt > 0);
         trendLine  = "Trend: " + dirTxt + " | " + trendDir
                      + " (" + (g_csvScore >= 0 ? "+" : "") + IntegerToString((int)g_csvScore) + ")";
         trendColor = aligned ? clrLime : clrOrangeRed;
         plLine     = "Profit: " + (pl >= 0 ? "+" : "") + DoubleToString(pl, 2) + " $";
         plColor    = (pl > 0) ? clrLime : (pl < 0) ? clrRed : clrWhite;
      }

      UpdateLabel(dashboardPrefix + "InfoTrend", trendLine, trendColor);
      UpdateLabel(dashboardPrefix + "InfoPL",    plLine,    plColor);
   }

   // ── سشن ─────────────────────────────────────────────────────
   if(marketClosed)
   {
      int localOffsetSec = (int)(TimeLocal() - TimeGMT());
      int localOffsetMin = localOffsetSec / 60;
      int openGMT = 22;
      int localH  = ((openGMT*60 + localOffsetMin) % 1440 + 1440) % 1440 / 60;
      UpdateLabel(dashboardPrefix + "SessionStatus",
                  StringFormat("Now: بازار بسته | یکشنبه %02d:00 (محلی) باز می‌شود ", localH), clrRed);
      UpdateLabel(dashboardPrefix + "SpreadStatus", "Spread: market closed", clrDimGray);
   }
   else
   {
      color sessionColor;
      string sessionName = GetCurrentSession(_gmtNow.hour, sessionColor);
      UpdateLabel(dashboardPrefix + "SessionStatus", "Now: " + sessionName, sessionColor);

      // ── Spread ───────────────────────────────────────────────
      static datetime s_lastSpread = 0;
      datetime nowT = TimeCurrent();
      if(nowT - s_lastSpread >= 10 || s_lastSpread == 0)
      {
         s_lastSpread = nowT;
         long sp = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
         if(sp == 0)
            UpdateLabel(dashboardPrefix + "SpreadStatus", "Spread: 0 pt", clrDimGray);
         else
         {
            color spC = (sp <= 3) ? clrLime : (sp <= 12) ? clrGold : clrRed;
            string spTip = (sp <= 3) ? "Excellent spread ✅" : (sp <= 12) ? "Acceptable spread ⚠️" : "High spread ❌";
            UpdateLabel(dashboardPrefix + "SpreadStatus",
                        StringFormat("Spread: %d pt", sp), spC);
         }
      }
   }

   // ── ADX ─────────────────────────────────────────────────────
   if(!marketClosed && ObjectFind(0, dashboardPrefix + "ADXStatus") >= 0)
   {
      double adx[2];
      if(CopyBuffer(handleADX, 0, 0, 2, adx) == 2)
      {
         string adxArrow = (adx[0] > adx[1]+1) ? " ↑" : (adx[0] < adx[1]-1) ? " ↓" : " →";
         color adxColor = adx[0] > MinADX ? clrLime : clrOrange;
         string adxTip = StringFormat(
            "ADX = %.1f%s\n"
            "روند ضعیف: زیر ۲۰\n"
            "روند متوسط: ۲۰-۳۰\n"
            "روند قوی: بالای ۳۰\n"
            "وضعیت: %s",
            adx[0], adxArrow,
            adx[0] > MinADX ? "روند کافی ✅" : "روند ضعیف ⚠️");
         UpdateLabelTip(dashboardPrefix + "ADXStatus",
                        StringFormat("ADX: %.1f%s", adx[0], adxArrow),
                        adxColor, adxTip);
      }
   }
   else if(marketClosed)
      UpdateLabel(dashboardPrefix + "ADXStatus", "ADX: Market Close", clrDimGray);

   // ══════════════════════════════════════════════════════════════
   // بخش ۲: هشدارها — v12: «امن» / «خطر»
   // ══════════════════════════════════════════════════════════════
   // چراغ‌ها توسط TL_SetLight و UpdateCrisisLight آپدیت می‌شوند
   // اما متن display در اینجا override می‌شود به فارسی ساده

   // EA status
   {
      color stC = (StringFind(g_eaStatus, "✅") >= 0) ? clrLimeGreen :
                  (StringFind(g_eaStatus, "⚙️") >= 0) ? clrYellow    :
                  (StringFind(g_eaStatus, "🔄") >= 0) ? clrDodgerBlue :
                  clrOrangeRed;
      if(ObjectFind(0, dashboardPrefix + "EAStatus") >= 0)
         UpdateLabel(dashboardPrefix + "EAStatus", g_eaStatus, stC);
   }

   ChartRedraw();
}



//+------------------------------------------------------------------+
//| 🗑️ DELETE DASHBOARD                                             |
//+------------------------------------------------------------------+
void DeleteDashboard()
{
   ObjectsDeleteAll(0, dashboardPrefix);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| CREATE LABEL                                                     |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, DashboardCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_BACK, !DashboardOnTop);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   // v11.92: لیبل‌های داشبورد هم بالای خطوط HLINE قرار گیرند
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| CREATE BUTTON                                                    |
//+------------------------------------------------------------------+
void CreateButton(string name, int x, int y, int width, int height, string text, color txtColor, color bgColor)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, DashboardCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txtColor);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BACK, !DashboardOnTop);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, g_dashBtnFontPt);     // v11.92: scaled
   // v11.92: اولویت کلیک بالاتر از خطوط HLINE (Zone/S/R/Liquid) که ZORDER=0 هستند
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 10);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| SAFE TOOLTIP - کوتاه‌کردن tooltip برای جلوگیری از قطع شدن متن  |
//| MT5 در برخی ورژن‌ها tooltip بیش از ~250 کاراکتر را قطع می‌کند  |
//| این تابع اطمینان می‌دهد که متن مهم کامل نمایش داده شود         |
//| پارامتر maxLen: حداکثر طول مجاز (پیش‌فرض ۲۵۰ کاراکتر)         |
//+------------------------------------------------------------------+
string SafeTip(string tip, int maxLen = 250)
{
   if(StringLen(tip) <= maxLen) return tip;
   // برش در آخرین خط کامل قبل از maxLen
   string cut = StringSubstr(tip, 0, maxLen - 3);
   int lastNL = StringFind(cut, "\n", 0);
   int pos = 0;
   while(lastNL >= 0 && lastNL < maxLen - 3)
   {
      pos = lastNL;
      lastNL = StringFind(cut, "\n", lastNL + 1);
   }
   if(pos > 10) return StringSubstr(tip, 0, pos) + "\n...";
   return StringSubstr(tip, 0, maxLen - 3) + "...";
}

//+------------------------------------------------------------------+
//| UPDATE LABEL                                                     |
//+------------------------------------------------------------------+
void UpdateLabel(string name, string text, color clr)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   }
}

// همان UpdateLabel ولی با tooltip - tooltip به‌طور خودکار کوتاه می‌شود
void UpdateLabelTip(string name, string text, color clr, string tip)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetString (0, name, OBJPROP_TEXT,    text);
      ObjectSetInteger(0, name, OBJPROP_COLOR,   clr);
      // SafeTip: جلوگیری از قطع شدن tooltip در MT5
      ObjectSetString (0, name, OBJPROP_TOOLTIP, SafeTip(tip));
   }
}

//+------------------------------------------------------------------+
//| APPLY FILTER MODE                                                |
//+------------------------------------------------------------------+
void ApplyFilterMode(ENUM_FILTER_MODE mode)
{
   currentFilterMode = mode;
   
   switch(mode)
   {
      case MODE_RELAXED:
         localMinBodyToATRRatio  = 0.40;
         localMinEfficiencyRatio = 0.18;
         localMinBodyToTotalRatio= 0.35;
         localRequiredScore      = 3;    // آستانه پایین = سیگنال بیشتر
         Print("🟢 RELAXED Mode: Max signals | MinScore=3 | No Divergence filters");
         break;
         
      case MODE_BALANCED:
         localMinBodyToATRRatio  = 0.55;
         localMinEfficiencyRatio = 0.24;
         localMinBodyToTotalRatio= 0.48;
         localRequiredScore      = 5;    // آستانه متوسط + بونوس واگرایی پنهان
         Print("🟡 BALANCED Mode: Quality signals | MinScore=5 | Hidden Divergence bonus active");
         break;
         
      case MODE_STRICT:
         localMinBodyToATRRatio  = 0.70;
         localMinEfficiencyRatio = 0.30;
         localMinBodyToTotalRatio= 0.60;
         localRequiredScore      = 7;    // آستانه بالا + فراکتال بلاک + واگرایی
         Print("🔴 STRICT Mode: Premium signals | MinScore=7 | Fractal Guard + Divergence + Candle");
         break;
   }
   
   // Update button colors
   string filters[] = {"Relaxed", "Balanced", "Strict"};
   for(int i = 0; i < 3; i++)
   {
      string btnName = dashboardPrefix + "FilterBtn_" + filters[i];
      color btnColor = (currentFilterMode == i) ? clrDodgerBlue : clrDarkSlateGray;
      ObjectSetInteger(0, btnName, OBJPROP_BGCOLOR, btnColor);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| APPLY PRESET                                                     |
//+------------------------------------------------------------------+
void ApplyPreset(ENUM_TIMEFRAME_PRESET preset)
{
   currentPreset = preset;
   
   switch(preset)
   {
      case PRESET_M1:
         localMinBarsBetweenSignals = 10;
         localArrowOffsetPips = 1.0;
         break;
         
      case PRESET_M5:
         localMinBarsBetweenSignals = 12;
         localArrowOffsetPips = 2.0;
         break;
         
      case PRESET_M15:
         localMinBarsBetweenSignals = 15;
         localArrowOffsetPips = 3.0;
         break;
         
      case PRESET_M30:
         localMinBarsBetweenSignals = 20;
         localArrowOffsetPips = 4.0;
         break;
         
      case PRESET_H1:
         localMinBarsBetweenSignals = 25;
         localArrowOffsetPips = 5.0;
         break;
         
      case PRESET_CUSTOM:
         localMinBarsBetweenSignals = MinBarsBetweenSignals;
         localArrowOffsetPips = ArrowOffsetPips;  // use input value
         break;
   }
   
   Print("📋 Preset: ", EnumToString(preset), " | ArrowOffset: ", localArrowOffsetPips, " pips");

   // FIX v12.15b: بروزرسانی فوری رنگ دکمه‌های SignalGap
   // ApplyFilterMode این کار رو میکرد ولی ApplyPreset نمیکرد → highlight نمیشد
   string _gpIds[] = {"M1", "M5", "M15", "M30", "H1"};
   for(int _gi = 0; _gi < 5; _gi++)
   {
      color _gc = (currentPreset == (ENUM_TIMEFRAME_PRESET)_gi) ? clrDodgerBlue : clrDarkSlateGray;
      ObjectSetInteger(0, dashboardPrefix + "Btn_" + _gpIds[_gi], OBJPROP_BGCOLOR, _gc);
   }
   UpdateDashboard();
}

//+------------------------------------------------------------------+
//| 🔧 DETECT BROKER GMT OFFSET                                      |
//+------------------------------------------------------------------+
int DetectBrokerGMTOffset()
{
   // FIX-2 v5.3: روش قدیمی (TimeCurrent - TimeGMT) در آخر هفته اشتباه بود
   // چون TimeCurrent آخرین تیک جمعه رو برمی‌گردوند نه زمان فعلی
   //
   // روش جدید: مقایسه زمان کندل H1 بروکر با UTC
   // اگه کندل H1 در بروکر ساعت 10:00 باز شده و در UTC ساعت 08:00 هست
   // → آفست = 10 - 8 = +2
   //
   // برای محاسبه درست:
   //   - از iTime برای زمان برروکر H1 استفاده می‌کنیم
   //   - از TimeGMT برای زمان UTC استفاده می‌کنیم
   //   - آفست = ساعت_بروکر - ساعت_UTC (با مدیریت تغییر روز)

   datetime brokerH1Time = iTime(_Symbol, PERIOD_H1, 0);
   datetime gmtNow       = TimeGMT();

   if(brokerH1Time <= 0)
   {
      // Fallback: اگر H1 data هنوز لود نشده، روش قدیمی رو امتحان کن
      datetime serverTime = TimeCurrent();
      int offsetSeconds   = (int)(serverTime - gmtNow);
      int offsetHours     = offsetSeconds / 3600;
      if(offsetSeconds % 3600 > 1800) offsetHours++;
      if(offsetHours < -12 || offsetHours > 14) offsetHours = 0;
      if(EnableAllLogs) Print("⚠️ GMT offset: H1 unavailable, fallback method used: ", offsetHours);
      return offsetHours;
   }

   // ساعت H1 کندل (زمان باز شدن، دقیقاً روی ساعت است)
   MqlDateTime brokerDT, gmtDT;
   TimeToStruct(brokerH1Time, brokerDT);

   // ساعت UTC را به ابتدای ساعت رند کن تا با H1 قابل مقایسه باشه
   TimeToStruct(gmtNow, gmtDT);
   int gmtHourFloor = gmtDT.hour;  // دقیقه و ثانیه نادیده گرفته می‌شوند

   int brokerHour = brokerDT.hour;

   // محاسبه اختلاف با مدیریت تغییر روز (±1 روز)
   int rawDiff = brokerHour - gmtHourFloor;

   // اگه اختلاف خیلی زیاد بود (>12 یا <-12)، احتمالاً تغییر روز رخ داده
   if(rawDiff >  12) rawDiff -= 24;
   if(rawDiff < -12) rawDiff += 24;

   // اگه کندل H1 قدیمی بود (آخر هفته)، تفاوت روز رو هم در نظر بگیر
   int brokerDay = brokerDT.day_of_week;
   int gmtDay    = gmtDT.day_of_week;
   if(brokerDay != gmtDay)
   {
      // تفاوت روز وجود داره - استفاده از fallback ایمن‌تره
      datetime serverTime = TimeCurrent();
      int offsetSeconds   = (int)(serverTime - gmtNow);
      int offsetHours     = offsetSeconds / 3600;
      if(offsetSeconds % 3600 > 1800) offsetHours++;
      if(offsetHours >= -12 && offsetHours <= 14)
      {
         if(EnableAllLogs) Print("📍 GMT offset (day-boundary fallback): ", offsetHours);
         return offsetHours;
      }
      // اگه fallback هم اشتباه بود، از rawDiff استفاده کن
   }

   // Sanity check
   if(rawDiff < -12 || rawDiff > 14)
   {
      if(EnableAllLogs) Print("⚠️ GMT offset out of range: ", rawDiff, ". Using 0");
      return 0;
   }

   if(EnableAllLogs) Print("📍 GMT offset detected (H1 method): ", rawDiff);
   return rawDiff;
}

//+------------------------------------------------------------------+
//| 🕐 GET CURRENT SESSION                                           |
//+------------------------------------------------------------------+
string GetCurrentSession(int gmtHour, color &sessionColor)
{
   // ── Session GMT ranges (v8.1 — DST-aware) ──────────────────────
   // Tokyo   : 00:00–09:00  (سشن آسیا؛ 23:00 مربوط به سیدنی است نه توکیو)
   // London  : 08:00–17:00
   // New York: زمستان 13:00–22:00 | تابستان (DST) 12:00–21:00
   // Overlaps: Tokyo/London 08:00–09:00 | London/NY فصلی
   // Off     : زمستان 22:00–00:00 | تابستان 21:00–00:00
   // ───────────────────────────────────────────────────────────────

   // ── DST Detection (US DST: 2nd Sun Mar → 1st Sun Nov) ──────────
   // برای سادگی از ماه تقریبی استفاده می‌کنیم:
   //   ماه ۴ تا ۱۰ (آوریل–اکتبر) = تابستان (DST فعال)
   //   ماه ۱۱ تا ۳  (نوامبر–مارس) = زمستان (DST غیرفعال)
   MqlDateTime _now;
   TimeToStruct(TimeGMT(), _now);
   bool isDST = (_now.mon >= 4 && _now.mon <= 10);

   // محدوده نیویورک بر اساس فصل
   int nyOpen  = isDST ? 12 : 13;   // GMT
   int nyClose = isDST ? 21 : 22;   // GMT

   bool inTokyo  = (gmtHour >= 0 && gmtHour < 9);   // فقط 00:00–09:00
   bool inLondon = (gmtHour >= 8 && gmtHour < 17);
   bool inNY     = (gmtHour >= nyOpen && gmtHour < nyClose);

   // آفست ساعت محلی کاربر نسبت به GMT (مثلاً تهران = +210 دقیقه)
   int localOffsetSec = (int)(TimeLocal() - TimeGMT());
   int localOffsetMin = localOffsetSec / 60;

   // تبدیل GMT hour به رشته ساعت محلی HH:MM
   // FIX v7.1: localOffsetMin کامل (نه فقط باقیمانده دقیقه)
   #define TO_LOCAL_STR(gmtH) StringFormat("%02d:%02d", \
      (((int)(gmtH)*60 + localOffsetMin + 1440) % 1440) / 60, \
      MathAbs(localOffsetMin % 60))

   string sessionName;

   if(inTokyo && inLondon)
   {
      // Overlap Tokyo / London: GMT 08:00–09:00
      sessionName  = "Tokyo/London (" + TO_LOCAL_STR(8) + " - " + TO_LOCAL_STR(9) + ")";
      sessionColor = clrWhite;
   }
   else if(inLondon && inNY)
   {
      // Overlap London / New York: فصلی (زمستان 13–17 | تابستان 12–17)
      sessionName  = "London/NY (" + TO_LOCAL_STR(nyOpen) + " - " + TO_LOCAL_STR(17) + ")";
      sessionColor = clrWhite;
   }
   else if(inTokyo)
   {
      // Tokyo only: 00:00–08:00 GMT
      sessionName  = "Tokyo (" + TO_LOCAL_STR(0) + " - " + TO_LOCAL_STR(9) + ")";
      sessionColor = clrWhite;
   }
   else if(inLondon)
   {
      // London only: 09:00–nyOpen and 17:00 close
      sessionName  = "London (" + TO_LOCAL_STR(8) + " - " + TO_LOCAL_STR(17) + ")";
      sessionColor = clrWhite;
   }
   else if(inNY)
   {
      // New York only: بعد از همپوشانی تا بسته شدن (فصلی)
      sessionName  = "New York (" + TO_LOCAL_STR(nyOpen) + " - " + TO_LOCAL_STR(nyClose) + ")";
      sessionColor = clrWhite;
   }
   else
   {
      // Off Hours: زمستان 22:00–00:00 | تابستان 21:00–00:00
      sessionName  = "Off Hours (" + TO_LOCAL_STR(nyClose) + " - " + TO_LOCAL_STR(0) + ")";
      sessionColor = clrGray;
   }

   #undef TO_LOCAL_STR
   return sessionName;
}

//+------------------------------------------------------------------+
//| 🔧 FORCE RECALCULATION                                           |
//| پردازش مجدد سیگنال‌ها بعد از تغییر تنظیمات دکمه‌ها             |
//| مشکل قدیمی: "باید تایم‌فریم عوض کنی تا اعمال بشه" - حل شد     |
//| این تابع مستقیماً داده‌های Rate را کپی و RunSignalLoop می‌زند    |
//+------------------------------------------------------------------+
void ForceRecalculation()
{
   // 🧹 Minimal Mode: فلش رسم نکن — فقط از طریق دکمه Minimal قابل رسم است
   if(g_minimalMode) return;

   // 🆕 v7.0: mutex ساده - جلوگیری از اجرای هم‌زمان روی کلیک‌های تند / پینگ بالا
   // 🔧 FIX v7.2: وضعیت EA رو نشون بده وقتی مشغوله
   if(g_recalcBusy)
   {
      // v11.2 FIX: اگه بیشتر از 30 ثانیه در حالت busy مانده، auto-release کن
      // این از حالتی که crash باعث قفل ماندن mutex شده جلوگیری می‌کنه
      // v11.92c: GetTickCount() به‌جای TimeCurrent() — TimeCurrent فقط با تیک جدید پیش می‌رود
      // و بعد از تغییر TF در بازارهای کم‌حرکت، mutex برای همیشه گیر می‌کرد.
      if(GetTickCount() - g_recalcBusySince > 10000)  // 10 ثانیه
      {
         if(EnableAllLogs) Print("⚠️ ForceRecalculation: mutex timeout (>10s) — auto-releasing");
         g_recalcBusy = false;
      }
      else
      {
         g_eaStatus = "🔄 مشغول - لطفاً صبر کن...";
         if(EnableAllLogs) Print("⚠️ ForceRecalculation: already busy, skipping");
         return;
      }
   }
   g_recalcBusy = true;
   g_recalcBusySince = GetTickCount();
   g_eaStatus   = "⚙️ در حال محاسبه...";

   lastBuyTime  = 0;
   lastSellTime = 0;
   todaySignalCount = 0;

   if(g_ratesTotal < 2)
   {
      g_eaStatus = "⚠️ داده ناکافی";
      g_recalcBusy = false;
      return;
   }

   int start = MathMin(g_maxHistoryBars, g_ratesTotal - 2);  // 🔧 FIX v7.4: از HistoryBarsPercent

   // Copy rate arrays using CopyXxx (same data OnCalculate receives)
   datetime time_buf[];
   double   open_buf[], high_buf[], low_buf[], close_buf[];
   long     vol_buf[];
   ArraySetAsSeries(time_buf,  true);
   ArraySetAsSeries(open_buf,  true);
   ArraySetAsSeries(high_buf,  true);
   ArraySetAsSeries(low_buf,   true);
   ArraySetAsSeries(close_buf, true);
   ArraySetAsSeries(vol_buf,   true);

   int copied = CopyTime  (_Symbol, PERIOD_CURRENT, 0, start + 2, time_buf);
   CopyOpen (_Symbol, PERIOD_CURRENT, 0, start + 2, open_buf);
   CopyHigh (_Symbol, PERIOD_CURRENT, 0, start + 2, high_buf);
   CopyLow  (_Symbol, PERIOD_CURRENT, 0, start + 2, low_buf);
   CopyClose(_Symbol, PERIOD_CURRENT, 0, start + 2, close_buf);
   CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, start + 2, vol_buf);

   // 🔧 FIX v7.2: ObjectsDeleteAll فقط وقتی داده موجود است
   // باگ قدیمی: اول حذف می‌کرد ← بعد CopyBuffer می‌زد
   // اگه CopyBuffer شکست می‌خورد (اینترنت کند/قطع) → فلش‌ها حذف شده ولی رسم نشده → Hang ظاهری
   if(copied >= 2)
   {
      ObjectsDeleteAll(0, HELPME_ARROW_PREFIX);
      SigMsg_Clear();   // v12.05: پاک کردن کش پیام‌های سیگنال
      RunSignalLoop(start, time_buf, open_buf, high_buf, low_buf, close_buf, vol_buf);
      g_eaStatus = "✅ آماده";
   }
   else
   {
      // فلش‌های قدیمی را حفظ کن — داده موجود نیست
      g_eaStatus = "⚠️ عدم دسترسی به داده";
      if(EnableAllLogs) Print("⚠️ ForceRecalculation: CopyBuffer failed (copied=", copied,
                              ") — existing arrows kept intact");
   }

   g_forceUpdateDashboard = true;
   UpdateDashboard();
   // بعد از رسم فلش‌ها، MA ها رو دوباره رسم کن (force: چون از کلیک دکمه فراخوانی شده)
   DrawOrClearAllMAs(true, true);
   ChartRedraw(0);

   g_recalcBusy = false;              // قفل آزاد - آخرین خط
   g_processingChartEvent = false;   // v11.3 FIX: اطمینان از آزاد بودن event mutex
}

//+------------------------------------------------------------------+
//| ON CHART EVENT - HANDLE BUTTON CLICKS                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(g_isDeinitializing) return;

   // ═══════════════════════════════════════════════════════════════════
   // V11.93 FIX: CHARTEVENT_CHART_CHANGE را قبل از mutex بررسی کن
   // علت باگ قبلی: تغییر TF باعث می‌شد CHARTEVENT_CHART_CHANGE چندین بار fire شود.
   // هر بار g_processingChartEvent=true می‌شد ولی هرگز reset نمی‌شد (فقط handler
   // دکمه‌ها آن را reset می‌کردند). نتیجه: mutex برای همیشه قفل → هیچ دکمه‌ای جواب نمی‌داد.
   // راه‌حل: CHART_CHANGE را بدون mutex پردازش کن و در پایان mutex را reset کن.
   // ═══════════════════════════════════════════════════════════════════
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      // v10.7 FIX: فقط موقعیت x لیبل‌های Zone بروز شود (بدون DeleteZoneLines + recreate → بدون فلیکر)
      if(ShowZoneLines)
      {
         SymbolZoneCfg _zc_cc;
         if(Zone_GetCfg(_Symbol, _zc_cc))
            RefreshZoneLabelPositions();
         // اگر خطوطی وجود ندارند (اولین بار یا سیمبل تغییر کرده) → بازسازی کامل
         else if(ObjectFind(0, "ZombieLine_0") < 0 && Zone_GetCfg(_Symbol, _zc_cc))
         {
            double _pip_cc = GetPipSize(_Symbol);
            {
               int _cmode_cc = 0; // gray by default
               if(g_lightZOMBIE >= 0) // پوزیشن دارد
               {
                  bool _fb_cc = (g_dirMode == 1) ? true : (g_dirMode == 2) ? false : (PositionsTotal() > 0);
                  _cmode_cc = _fb_cc ? 1 : 2;
               }
               DrawAbsoluteZoneLines(_zc_cc.base_low, (double)_zc_cc.widthPips * _pip_cc,
                                     _pip_cc, ZoneLineCount, g_zombieEntryZone, _cmode_cc);
            }
         }
      }
      // CRITICAL: همیشه mutex را reset کن تا دکمه‌ها بعد از تغییر TF کار کنند
      g_processingChartEvent      = false;
      g_processingChartEventSince = 0;
      return;
   }

   // 🔧 FIX: mutex فقط برای CHARTEVENT_OBJECT_CLICK و سایر رویدادها (نه CHART_CHANGE)
   // وقتی داخل handler شیء تغییر دهی + ChartRedraw بزنی، MT5 ممکنه event دوباره fire کنه
   // v11.92c: GetTickCount() (ms از بوت سیستم، همیشه پیش می‌رود)
   if(g_processingChartEvent)
   {
      if(g_processingChartEventSince != 0 && (GetTickCount() - g_processingChartEventSince) > 500)  // V13.10 FIX: 500ms timeout (was 2000ms)
      {
         if(EnableAllLogs) Print("⚠️ OnChartEvent: mutex timeout (>2s) — auto-releasing");
         g_processingChartEvent = false;
      }
      else return;
   }
   g_processingChartEvent = true;
   g_processingChartEventSince = GetTickCount();

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // v12.09: Signal label/arrow click → no action (MessageBox removed)
      // Tooltip روی Label: لیست کامل فیلترها | Tooltip روی Arrow: Score X/Y [Mode]

      // ─── Preset Buttons ────────────────────────────────────────────
      if(StringFind(sparam, dashboardPrefix + "Btn_") >= 0)
      {
         string clicked = StringSubstr(sparam, StringLen(dashboardPrefix + "Btn_"));
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         SaveButtonStates();
         // v11.94 FIX: mutex را قبل از ApplyPreset آزاد کن
         // ApplyPreset → UpdateDashboard → ChartRedraw → ممکنه CHARTEVENT_OBJECT_CLICK جدید fire کنه
         // اگه mutex هنگام ApplyPreset قفل باشه، همه کلیک‌های بعدی بلافاصله رد می‌شن
         g_processingChartEvent      = false;
         g_processingChartEventSince = 0;
         if     (clicked == "M1")  ApplyPreset(PRESET_M1);
         else if(clicked == "M5")  ApplyPreset(PRESET_M5);
         else if(clicked == "M15") ApplyPreset(PRESET_M15);
         else if(clicked == "M30") ApplyPreset(PRESET_M30);
         else if(clicked == "H1")  ApplyPreset(PRESET_H1);
         ForceRecalculation();
         return;
      }
      
      // ─── Filter Mode Buttons ────────────────────────────────────────
      if(StringFind(sparam, dashboardPrefix + "FilterBtn_") >= 0)
      {
         string clicked = StringSubstr(sparam, StringLen(dashboardPrefix + "FilterBtn_"));
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         SaveButtonStates();
         // v11.94 FIX: mutex را قبل از ApplyFilterMode آزاد کن (همان دلیل Preset buttons)
         g_processingChartEvent      = false;
         g_processingChartEventSince = 0;
         if     (clicked == "Relaxed")  ApplyFilterMode(MODE_RELAXED);
         else if(clicked == "Balanced") ApplyFilterMode(MODE_BALANCED);
         else if(clicked == "Strict")   ApplyFilterMode(MODE_STRICT);
         ForceRecalculation();
         return;
      }
      
      // ─── MA Overlay Buttons ────────────────────────────────────────
      // MQL5 از pointer پشتیبانی نمی‌کنه - هر دکمه جداگانه handle میشه
      if(StringFind(sparam, dashboardPrefix + "MABtn_") >= 0)
      {
         string clicked = StringSubstr(sparam, StringLen(dashboardPrefix + "MABtn_"));
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

         if(clicked == "MAPLUS")
         {
            // v12: MA+ دکمه — همه ۵ MA را یکجا روشن/خاموش می‌کند
            bool maAny = g_maM15Active || g_maM30Active || g_maH1Active || g_maH4Active || g_maD1Active;
            bool newState = !maAny;
            g_maM15Active = newState; g_maM30Active = newState;
            g_maH1Active  = newState; g_maH4Active  = newState; g_maD1Active = newState;
            color btnCol = newState ? clrDodgerBlue : clrDarkSlateGray;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, btnCol);
            DrawOrClearMA("M15", PERIOD_M15, g_handleMA_M15, g_maM15Active);
            DrawOrClearMA("M30", PERIOD_M30, g_handleMA_M30, g_maM30Active);
            DrawOrClearMA("H1",  PERIOD_H1,  g_handleMA_H1,  g_maH1Active);
            DrawOrClearMA("H4",  PERIOD_H4,  g_handleMA_H4,  g_maH4Active);
            DrawOrClearMA("D1",  PERIOD_D1,  g_handleMA_D1,  g_maD1Active);
         }
         else if(clicked == "MA15")
         {
            g_maM15Active = !g_maM15Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maM15Active ? clrDodgerBlue : clrDarkSlateGray);
            DrawOrClearMA("M15", PERIOD_M15, g_handleMA_M15, g_maM15Active);
         }
         else if(clicked == "MA30")
         {
            g_maM30Active = !g_maM30Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maM30Active ? clrDodgerBlue   : clrDarkSlateGray);
            DrawOrClearMA("M30", PERIOD_M30, g_handleMA_M30, g_maM30Active);
         }
         else if(clicked == "MA1H")
         {
            g_maH1Active = !g_maH1Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maH1Active  ? clrDodgerBlue   : clrDarkSlateGray);
            DrawOrClearMA("H1",  PERIOD_H1,  g_handleMA_H1,  g_maH1Active);
         }
         else if(clicked == "MA4H")
         {
            g_maH4Active = !g_maH4Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maH4Active  ? clrDodgerBlue   : clrDarkSlateGray);
            DrawOrClearMA("H4",  PERIOD_H4,  g_handleMA_H4,  g_maH4Active);
         }
         else if(clicked == "MA1D")
         {
            g_maD1Active = !g_maD1Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maD1Active  ? clrDodgerBlue   : clrDarkSlateGray);
            DrawOrClearMA("D1",  PERIOD_D1,  g_handleMA_D1,  g_maD1Active);
         }
         else if(clicked == "FEMA")
         {
            g_femaActive = !g_femaActive;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               g_femaActive ? clrDodgerBlue : clrDarkSlateGray);
            DrawOrClearFEMA(g_femaActive);
         }
         // v11.2 FIX: MA buttons هم باید mutex آزاد کنن و SaveButtonStates بزنن
         SaveButtonStates();
         ChartRedraw(0);
         g_processingChartEvent = false;
         return;
      }

      // ─── Liquid Level Button (both old large button and filter row button) ────────────────────────────────────────
      if(sparam == dashboardPrefix + "LiquidBtn" || sparam == dashboardPrefix + "LiqLevelFilterBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);   // دکمه رو از حالت pressed در بیار
         string statusLabel = dashboardPrefix + "LiquidStatus";

         // ═══ اگه در هر حالت غیر صفر هستیم → ریست به حالت اولیه ══════════
         if(g_liquidBtnState != 0)
         {
            g_liquidActive   = false;
            g_liquidBtnState = 0;
            // پاک کردن خط و لیبل
            ObjectsDeleteAll(0, LQ_OBJ_PREFIX);
            g_prevSymPosCount = -1;
            // بازگشت دکمه‌های Liquid به رنگ پیش‌فرض
            if(ObjectFind(0, dashboardPrefix+"LiquidBtn") >= 0) {
               ObjectSetInteger(0, dashboardPrefix+"LiquidBtn", OBJPROP_BGCOLOR, clrGold);
               ObjectSetInteger(0, dashboardPrefix+"LiquidBtn", OBJPROP_COLOR,   clrBlack);
            }
            if(ObjectFind(0, dashboardPrefix+"LiqLevelFilterBtn") >= 0)
               ObjectSetInteger(0, dashboardPrefix+"LiqLevelFilterBtn", OBJPROP_BGCOLOR, clrDarkSlateGray);
            // پاک کردن متن وضعیت → برگشت به حالت اولیه
            ObjectSetString (0, statusLabel, OBJPROP_TEXT,  "Liquid: inactive - click to activate");
            ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrDimGray);
            Print("💧 Liquid Level: OFF");
            ChartRedraw(0);
            g_processingChartEvent = false;  // v11.2 FIX
            return;
         }
         else
         {
            // ═══ حالت اولیه: بررسی پوزیشن‌ها ══════════════════════════
            int _symPos = 0;
            for(int _pi = PositionsTotal()-1; _pi >= 0; _pi--)
               if(HM_PositionBelongsToSymbol(PositionGetSymbol(_pi), _Symbol)) _symPos++;   // 🆕 v13.49 P4

            if(_symPos == 0)
            {
               // ─── هیچ پوزیشن بازی نداریم ───────────────────────────
               g_liquidBtnState = 1;  // حالت: بدون پوزیشن
               ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrDarkSlateGray);
               ObjectSetInteger(0, sparam, OBJPROP_COLOR,   clrWhite);
               if(ObjectFind(0, dashboardPrefix+"LiqLevelFilterBtn") >= 0)
                  ObjectSetInteger(0, dashboardPrefix+"LiqLevelFilterBtn", OBJPROP_BGCOLOR, clrDarkSlateGray);
               ObjectSetString (0, statusLabel, OBJPROP_TEXT,
                                "No open position on this symbol");
               ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrOrangeRed);
               Print("💧 Liquid Level: No open positions on ", _Symbol);
               ChartRedraw(0);
               g_processingChartEvent = false;  // v11.2 FIX
               return;
            }
            else
            {
               // ─── پوزیشن باز داریم → در حال محاسبه ────────────────
               ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrOrange);
               ObjectSetInteger(0, sparam, OBJPROP_COLOR,   clrBlack);
               ObjectSetString (0, statusLabel, OBJPROP_TEXT, "در حال محاسبه...");
               ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrYellow);
               ChartRedraw(0);

               g_prevSymPosCount = -1;
               int lqResult = UpdateLiquidationLine();

               if(lqResult == 1)
               {
                  // ─── موفق: خط رسم شد ─────────────────────────────
                  g_liquidActive   = true;
                  g_liquidBtnState = 2;
                  if(ObjectFind(0, dashboardPrefix+"LiquidBtn") >= 0)
                     ObjectSetInteger(0, dashboardPrefix+"LiquidBtn", OBJPROP_BGCOLOR, clrDodgerBlue);
                  if(ObjectFind(0, dashboardPrefix+"LiqLevelFilterBtn") >= 0)
                     ObjectSetInteger(0, dashboardPrefix+"LiqLevelFilterBtn", OBJPROP_BGCOLOR, clrDodgerBlue);
                  ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrDodgerBlue);
                  ObjectSetInteger(0, sparam, OBJPROP_COLOR,   clrWhite);
                  ObjectSetString (0, statusLabel, OBJPROP_TEXT,
                                   "Liquid line drawn successfully ✅");
                  ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrLimeGreen);
                  Print("💧 Liquid Level: ON - line drawn successfully");
               }
               else if(lqResult == 0)
               {
                  // ─── هج کامل: خط رسم نمیشه ──────────────────────
                  g_liquidBtnState = 3;
                  ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrDarkSlateGray);
                  ObjectSetInteger(0, sparam, OBJPROP_COLOR,   clrWhite);
                  if(ObjectFind(0, dashboardPrefix+"LiqLevelFilterBtn") >= 0)
                     ObjectSetInteger(0, dashboardPrefix+"LiqLevelFilterBtn", OBJPROP_BGCOLOR, clrDarkSlateGray);
                  ObjectSetString (0, statusLabel, OBJPROP_TEXT,
                                   "Full hedge - line not available");
                  ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrGold);
                  Print("💧 Liquid Level: Hedge complete - N/A");
               }
               else
               {
                  // ─── شکست در محاسبه ──────────────────────────────
                  g_liquidBtnState = 3;
                  ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrDarkSlateGray);
                  ObjectSetInteger(0, sparam, OBJPROP_COLOR,   clrWhite);
                  ObjectSetString (0, statusLabel, OBJPROP_TEXT,
                                   "خط پیدا نشد ❌");
                  ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrOrangeRed);
                  Print("💧 Liquid Level: Calculation failed");
               }
               ChartRedraw(0);
               g_processingChartEvent = false;  // v11.2 FIX
               return;
            }
         }
      }

      // ─── v11.0: Buy / All / Sell Radio Buttons ───────────────────────
      if(StringFind(sparam, dashboardPrefix + "DirBtn_") >= 0)
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         string clicked = StringSubstr(sparam, StringLen(dashboardPrefix + "DirBtn_"));

         if     (clicked == "Buy")  g_dirMode = 1;
         else if(clicked == "All")  g_dirMode = 0;
         else if(clicked == "Sell") g_dirMode = 2;

         // بروزرسانی رنگ دکمه‌ها (Radio: فقط یکی فعال)
         ObjectSetInteger(0, dashboardPrefix + "DirBtn_Buy",
            OBJPROP_BGCOLOR, (g_dirMode == 1) ? clrDodgerBlue  : clrDarkSlateGray);
         ObjectSetInteger(0, dashboardPrefix + "DirBtn_All",
            OBJPROP_BGCOLOR, (g_dirMode == 0) ? clrDodgerBlue  : clrDarkSlateGray);
         ObjectSetInteger(0, dashboardPrefix + "DirBtn_Sell",
            OBJPROP_BGCOLOR, (g_dirMode == 2) ? clrDodgerBlue   : clrDarkSlateGray);

         if(ShowDebugLogs) Print("v11 DirMode: ", (g_dirMode==1)?"Buy":(g_dirMode==2)?"Sell":"All");
         // V13.10 FIX: mutex آزاد قبل از CSL_Execute + TL_Update فوری
         // 🆕 v14.04 FIX-3: g_isNewChartBar=true تنظیم می‌شود تا runRuleBlock در TL_Update
         // فعال شود — بدون این، چراغ‌های Rule/Spike برای DirMode جدید stale می‌مانند.
         g_processingChartEvent = false;
         SaveButtonStates();
         CSL_Execute();
         g_isNewChartBar = true;   // 🆕 v14.04 FIX-3: gate باز برای DirMode جدید
         TL_Update();              // V13.10: فوری چراغ‌ها و Zone آپدیت بشن
         g_isNewChartBar = false;  // 🆕 v14.04 FIX-3: gate بسته
         g_forceUpdateDashboard = true;
         UpdateDashboard();
         ChartRedraw(0);
         return;
      }

      // ─── ⏻ Power Off Button — پاک‌سازی کامل و حذف اکسپرت ────────────
      // v11.91: دکمه خاموش‌کردن سریع‌تر و مطمئن‌تر از Remove از متاتریدر
      if(sparam == dashboardPrefix + "PowerOffBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         g_processingChartEvent = false;
         if(ShowDebugLogs) Print("⏻ PowerOff: شروع پاک‌سازی اکسپرت...");
         // پاک‌سازی فوری همه اشیاء
         HM_RemoveHelpMeObjectsPass(0);
         DeleteZoneLines();
         ObjectsDeleteAll(0, "ZombieLine_");
         ObjectsDeleteAll(0, "ZoneLabel_");
         ObjectsDeleteAll(0, "MYNEWS_");
         ObjectsDeleteAll(0, LQ_OBJ_PREFIX);
         ObjectsDeleteAll(0, HELPME_ARROW_PREFIX);
   SigMsg_Clear();
         ObjectsDeleteAll(0, MA_OBJ_PREFIX);
         ObjectsDeleteAll(0, FEMA_OBJ_PREFIX);
         ObjectsDeleteAll(0, SR_OBJ_PREFIX);
         ObjectsDeleteAll(0, dashboardPrefix);
         HM_DeleteObjectHard(0, CRISIS_OBJ);
         HM_DeleteObjectHard(0, "StatusLabel");
         HM_DeleteObjectHard(0, "ProfitLabel");
         // بازگردانی رنگ چارت
         ChartSetInteger(0, CHART_COLOR_BACKGROUND, g_originalBgColor);
         ChartSetInteger(0, CHART_COLOR_FOREGROUND, g_originalFgColor);
         ChartSetInteger(0, CHART_COLOR_GRID,       g_originalGridColor);
         ChartRedraw(0);
         // حذف اکسپرت از چارت
         ExpertRemove();
         return;
      }

      // ─── Reset Button ───────────────────────────────────────────────
      // 🔧 FIX v7.2: ریست کامل وضعیت EA
      // این دکمه برای زمانی است که EA در حالت Hung/Stuck است و به تیک جدید جواب نمی‌دهد
      if(sparam == dashboardPrefix + "ResetBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

         // ── v11.2 FIX: FULL RESET — همه mutex ها + همه دکمه‌ها به default ──
         // ① mutex و debounce
         g_recalcBusy           = false;
         g_processingChartEvent = false;
         g_lastAIBtnClickTime   = 0;
         g_lastSRClickTime      = 0;

         // ② دکمه‌های Buy/All/Sell → All
         g_dirMode = 0;
         ObjectSetInteger(0, dashboardPrefix + "DirBtn_Buy",  OBJPROP_BGCOLOR, clrDarkSlateGray);
         ObjectSetInteger(0, dashboardPrefix + "DirBtn_All",  OBJPROP_BGCOLOR, clrMidnightBlue);
         ObjectSetInteger(0, dashboardPrefix + "DirBtn_Sell", OBJPROP_BGCOLOR, clrDarkSlateGray);

         // ③ AI filter buttons → مقدار پیش‌فرض (مطابق تعریف اولیه global ها)
         localEnablePriceAction  = true;    // EnablePriceActionFilter default
         localEnableMTF          = false;   // EnableMTFConfluence default
         localEnableMarketRegime = false;   // EnableMarketRegimeDetection default
         localEnableSmartVol     = false;   // EnableSmartVolume default
         localEnableIchimoku     = false;
         localEnableFVG          = true;    // EnableFVG default
         localEnableLiqSwp       = true;    // EnableLiqSwp default
         localEnableRTM          = true;    // EnableRTM default
         localEnableSR           = false;   // S/R همیشه OFF روی reset

         // ④ رنگ دکمه‌های AI مطابق state جدید
         string ai_names[]  = {"Price","MTF","Regime","Vol","Ichi","FVG","LiqSwp","RTM","SR"};
         bool   ai_states[] = {localEnablePriceAction, localEnableMTF, localEnableMarketRegime,
                                localEnableSmartVol, localEnableIchimoku, localEnableFVG,
                                localEnableLiqSwp, localEnableRTM, false};
         for(int _ri = 0; _ri < 9; _ri++)
         {
            string _bn = dashboardPrefix + "AIBtn_" + ai_names[_ri];
            if(ObjectFind(0, _bn) >= 0)
               ObjectSetInteger(0, _bn, OBJPROP_BGCOLOR,
                  ai_states[_ri] ? clrDodgerBlue : clrDarkSlateGray);
         }

         // ⑤ Filter Mode → Balanced (default)
         currentFilterMode = MODE_BALANCED;
         string fm_names[] = {"Relaxed","Balanced","Strict"};
         for(int _fi = 0; _fi < 3; _fi++)
         {
            string _fb = dashboardPrefix + "FilterBtn_" + fm_names[_fi];
            if(ObjectFind(0, _fb) >= 0)
               ObjectSetInteger(0, _fb, OBJPROP_BGCOLOR,
                  (_fi == 1) ? clrDodgerBlue : clrDarkSlateGray);
         }

         // ⑥ S/R خطوط پاک کن
         ObjectsDeleteAll(0, SR_OBJ_PREFIX);

         // ⑦ GlobalVariable هم ریست کن
         string _gvp = "HelpMe_" + _Symbol + "_" + IntegerToString(ChartID()) + "_";
         GlobalVariableDel(_gvp + "Price");   GlobalVariableDel(_gvp + "MTF");
         GlobalVariableDel(_gvp + "Regime");  GlobalVariableDel(_gvp + "SmartVol");
         GlobalVariableDel(_gvp + "Ichi");    GlobalVariableDel(_gvp + "FVG");
         GlobalVariableDel(_gvp + "LiqSwp");  GlobalVariableDel(_gvp + "RTM");
         GlobalVariableDel(_gvp + "DirMode"); GlobalVariableDel(_gvp + "FilterMode");
         GlobalVariableDel(_gvp + "Preset");
         // news fail cooldown رو هم پاک کن تا دوباره تلاش کنه
         GlobalVariableDel("HelpMe_NewsFailedAt_" + _Symbol);

         // FIX v12.08: ریست Preset → H1 (مقدار پیش‌فرض)
         currentPreset = PRESET_H1;
         string ps_names[] = {"M1","M5","M15","M30","H1"};
         for(int _pi = 0; _pi < 5; _pi++)
         {
            string _pb = dashboardPrefix + "Btn_" + ps_names[_pi];
            if(ObjectFind(0, _pb) >= 0)
               ObjectSetInteger(0, _pb, OBJPROP_BGCOLOR,
                  (_pi == 4) ? clrDodgerBlue : clrDarkSlateGray);  // H1 = index 4
         }
         ApplyPreset(currentPreset);

         // FIX v12.08: ریست Liquid Level
         if(g_liquidActive || g_liquidBtnState != 0)
         {
            g_liquidActive   = false;
            g_liquidBtnState = 0;
            ObjectsDeleteAll(0, LQ_OBJ_PREFIX);
            g_prevSymPosCount = -1;
            if(ObjectFind(0, dashboardPrefix+"LiquidBtn") >= 0) {
               ObjectSetInteger(0, dashboardPrefix+"LiquidBtn", OBJPROP_BGCOLOR, clrGold);
               ObjectSetInteger(0, dashboardPrefix+"LiquidBtn", OBJPROP_COLOR,   clrBlack);
            }
            if(ObjectFind(0, dashboardPrefix+"LiqLevelFilterBtn") >= 0)
               ObjectSetInteger(0, dashboardPrefix+"LiqLevelFilterBtn", OBJPROP_BGCOLOR, clrDarkSlateGray);
            string _lqStatus = dashboardPrefix + "LiquidStatus";
            if(ObjectFind(0, _lqStatus) >= 0) {
               ObjectSetString (0, _lqStatus, OBJPROP_TEXT,  "Liquid: inactive - click to activate");
               ObjectSetInteger(0, _lqStatus, OBJPROP_COLOR, clrDimGray);
            }
         }

         // FIX v12.08: ریست MA / FEMA buttons و پاک کردن خطوط
         if(g_maM15Active || g_maM30Active || g_maH1Active || g_maH4Active || g_maD1Active || g_femaActive)
         {
            g_maM15Active = false; g_maM30Active = false;
            g_maH1Active  = false; g_maH4Active  = false; g_maD1Active = false;
            g_femaActive  = false;
            DrawOrClearAllMAs(false);
            ObjectsDeleteAll(0, MA_OBJ_PREFIX);
            ObjectsDeleteAll(0, FEMA_OBJ_PREFIX);
            if(ObjectFind(0, dashboardPrefix+"MABtn_MAPLUS") >= 0)
               ObjectSetInteger(0, dashboardPrefix+"MABtn_MAPLUS", OBJPROP_BGCOLOR, clrDarkSlateGray);
            if(ObjectFind(0, dashboardPrefix+"MABtn_FEMA") >= 0)
               ObjectSetInteger(0, dashboardPrefix+"MABtn_FEMA", OBJPROP_BGCOLOR, clrDarkSlateGray);
         }

         // FIX v12.08: ریست Minimal Mode
         if(g_minimalMode)
         {
            g_minimalMode = false;
            if(ObjectFind(0, dashboardPrefix+"MinimalBtn") >= 0)
               ObjectSetInteger(0, dashboardPrefix+"MinimalBtn", OBJPROP_BGCOLOR, clrDarkSlateGray);
         }

         g_eaStatus = "↺ ریست کامل شد";
         if(EnableAllLogs) Print("↺ FULL RESET: all buttons → default, mutexes + chart color cleared");

         // ⑨ v11.3 FIX: رنگ چارت ریست بشه (همیشه بعد از Reset → رنگ اصلی)
         ChartSetInteger(0, CHART_COLOR_BACKGROUND, g_originalBgColor);
         ChartSetInteger(0, CHART_COLOR_FOREGROUND, g_originalFgColor);
         ChartSetInteger(0, CHART_COLOR_GRID,       g_originalGridColor);

         // ⑩ محاسبه مجدد
         g_ratesTotal = Bars(_Symbol, PERIOD_CURRENT);
         g_processingChartEvent = false;
         ForceRecalculation();
         return;
      }

      // ─── Minimal Mode Button ──────────────────────────────────────
      if(sparam == dashboardPrefix + "MinimalBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         g_minimalMode = !g_minimalMode;

         if(g_minimalMode)
         {
            // ── Minimal ON: حذف فلش‌ها و خطوط خبری ──
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrSaddleBrown);
            g_eaStatus = "🧹 Minimal";

            // فلش‌های سیگنال
            for(int _i = ObjectsTotal(0, 0, -1) - 1; _i >= 0; _i--)
            {
               string _nm = ObjectName(0, _i, 0, -1);
               if(StringFind(_nm, HELPME_ARROW_PREFIX) == 0)
                  ObjectDelete(0, _nm);
            }
            // خطوط خبری
            for(int _i = ObjectsTotal(0, 0, -1) - 1; _i >= 0; _i--)
            {
               string _nm = ObjectName(0, _i, 0, -1);
               if(StringFind(_nm, "MYNEWS_") == 0)
                  ObjectDelete(0, _nm);
            }
         }
         else
         {
            // ── Minimal OFF: رسم مجدد همه چیز ──
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrDarkSlateGray);
            g_eaStatus = "↺ بازگشایی...";
            g_ratesTotal = Bars(_Symbol, PERIOD_CURRENT);
            ForceRecalculation();
            DrawNewsLines(true);  // رسم مجدد خطوط خبری — 🆕 v13.50: force=true چون اشیاء دستی پاک شدن
         }

         UpdateDashboard();
         ChartRedraw(0);
         g_processingChartEvent = false;
         return;
      }

      // ─── AI Toggle Buttons ──────────────────────────────────────────
      if(StringFind(sparam, dashboardPrefix + "AIBtn_") >= 0)
      {
         string clicked = StringSubstr(sparam, StringLen(dashboardPrefix + "AIBtn_"));

         // 🔧 FIX v11.3: debounce مشترک بین ۹ دکمه AI حذف شد
         // مشکل قبلی: کلیک روی هر دکمه AI باعث می‌شد همه دکمه‌های AI به مدت ۲ ثانیه
         // بلاک شوند → کاربر فکر می‌کرد EA هنگ کرده
         // جایگزین: g_recalcBusy در ForceRecalculation از اجرای هم‌زمان جلوگیری می‌کند
         // هر دکمه به صورت مستقل کلیک‌پذیر است

         // --- Price Action ---
         if(clicked == "Price")
         {
            localEnablePriceAction = !localEnablePriceAction;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               localEnablePriceAction ? clrDodgerBlue : clrDarkSlateGray);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            SaveButtonStates();
            if(ShowDebugLogs) Print("📊 Price Action: ", localEnablePriceAction ? "ON" : "OFF");
            g_processingChartEvent = false;  // v11.2 FIX
            ForceRecalculation();
            return;
         }
         
         // --- MTF Confluence ---
         else if(clicked == "MTF")
         {
            localEnableMTF = !localEnableMTF;
            if(localEnableMTF) { CreateMTFHandles(); UpdateMTFTrendInfo(); }
            else               { ReleaseMTFHandles(); }
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               localEnableMTF ? clrDodgerBlue : clrDarkSlateGray);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            SaveButtonStates();
            if(ShowDebugLogs) Print("🔄 MTF: ", localEnableMTF ? "ON" : "OFF");
            g_processingChartEvent = false;  // v11.2 FIX
            ForceRecalculation();
            return;
         }
         
         // --- Market Regime ---
         else if(clicked == "Regime")
         {
            localEnableMarketRegime = !localEnableMarketRegime;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               localEnableMarketRegime ? clrDodgerBlue : clrDarkSlateGray);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            SaveButtonStates();
            if(ShowDebugLogs) Print("🌊 Regime: ", localEnableMarketRegime ? "ON" : "OFF");
            g_processingChartEvent = false;  // v11.2 FIX
            ForceRecalculation();
            return;
         }
         
         // --- Smart Volume ---
         else if(clicked == "Vol")
         {
            localEnableSmartVol = !localEnableSmartVol;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               localEnableSmartVol ? clrDodgerBlue : clrDarkSlateGray);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            SaveButtonStates();
            if(ShowDebugLogs) Print("📊 SmartVol: ", localEnableSmartVol ? "ON" : "OFF");
            g_processingChartEvent = false;  // v11.2 FIX
            ForceRecalculation();
            return;
         }
         else if(clicked == "Ichi")
         {
            localEnableIchimoku = !localEnableIchimoku;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               localEnableIchimoku ? clrDodgerBlue : clrDarkSlateGray);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            SaveButtonStates();
            if(ShowDebugLogs) Print("📊 Ichimoku Filter: ", localEnableIchimoku ? "ON" : "OFF");
            g_processingChartEvent = false;  // v11.2 FIX
            ForceRecalculation();
            return;
         }
         
         // ═══════════════════════════════════════════════════════════
         // 🆕 v7.0: FVG, LiqSwp, RTM - ردیف سوم دکمه‌های AI
         // ═══════════════════════════════════════════════════════════
         
         // --- FVG: Fair Value Gap ---
         else if(clicked == "FVG")
         {
            localEnableFVG = !localEnableFVG;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               localEnableFVG ? clrDodgerBlue : clrDarkSlateGray);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            SaveButtonStates();
            if(ShowDebugLogs) Print("📐 FVG Filter: ", localEnableFVG ? "ON (imbalance zones active)" : "OFF");
            g_processingChartEvent = false;  // v11.2 FIX
            ForceRecalculation();
            return;
         }
         
         // --- LiqSwp: Liquidity Sweep ---
         else if(clicked == "LiqSwp")
         {
            localEnableLiqSwp = !localEnableLiqSwp;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               localEnableLiqSwp ? clrDodgerBlue : clrDarkSlateGray);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            SaveButtonStates();
            if(ShowDebugLogs) Print("💧 LiqSwp Filter: ", localEnableLiqSwp ? "ON (sweep detection active)" : "OFF");
            g_processingChartEvent = false;  // v11.2 FIX
            ForceRecalculation();
            return;
         }
         
         // --- RTM: Return to Mean ---
         else if(clicked == "RTM")
         {
            localEnableRTM = !localEnableRTM;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               localEnableRTM ? clrDodgerBlue : clrDarkSlateGray);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            
            // RTM handle: ساخت وقتی روشن میشه، حذف وقتی خاموش
            if(localEnableRTM && handleRTM_EMA == INVALID_HANDLE)
            {
               handleRTM_EMA = iMA(_Symbol, PERIOD_CURRENT, RTM_EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
               if(handleRTM_EMA == INVALID_HANDLE)
               {
                  Print("⚠️ RTM EMA handle failed - turning RTM off");
                  localEnableRTM = false;
                  ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrDarkSlateGray);
               }
               else
                  Print("✅ RTM EMA", RTM_EMAPeriod, " handle created");
            }
            else if(!localEnableRTM && handleRTM_EMA != INVALID_HANDLE)
            {
               IndicatorRelease(handleRTM_EMA);
               handleRTM_EMA = INVALID_HANDLE;
               UpdateLabel(dashboardPrefix + "RTMStatus", "RTM: OFF (click to enable)", clrDimGray);
            }
            
            SaveButtonStates();
            if(ShowDebugLogs) Print("🔄 RTM Filter (EMA", RTM_EMAPeriod, "): ", localEnableRTM ? "ON" : "OFF");
            g_processingChartEvent = false;  // v11.2 FIX
            ForceRecalculation();
            return;
         }
         
         // --- S/R Levels --- (v11.4 FIX: toggle-off قابل اعتماد)
         // ═══════════════════════════════════════════════════════
         // APPROACH v11.4:
         //  ① STATE=false + BGCOLOR + توگل localEnableSR + ChartRedraw فوری
         //  ② mutex بلافاصله آزاد می‌شود (قبل از کار سنگین)
         //  ③ کار اصلی (Draw / Delete سخت‌گیرانه با حلقه دستی) بعد انجام می‌شود
         //     → reentrant click نمی‌تواند حالت را برگرداند چون قبلش هر چیزی commit شده
         // ═══════════════════════════════════════════════════════
         else if(clicked == "SR")
         {
            // ═══════════════════════════════════════════════════════
            // v11.5 FIX: debounce با GetTickCount (ms) → جلوگیری قطعی
            // از double-trigger که در v11.4 با TimeCurrent (sec) رد می‌شد
            // و باعث toggle off→on→off→on می‌شد.
            // ═══════════════════════════════════════════════════════
            static uint s_srLastTickMs = 0;
            uint nowMs = GetTickCount();
            if(s_srLastTickMs != 0 && (nowMs - s_srLastTickMs) < 600)
            {
               // event دوم در کمتر از 600ms → نادیده بگیر
               ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
               ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
                  localEnableSR ? clrDodgerBlue : clrDarkSlateGray);
               g_processingChartEvent = false;
               ChartRedraw(0);
               return;
            }
            s_srLastTickMs = nowMs;
            g_lastSRClickTime = TimeCurrent();

            // ① toggle و commit بصری
            localEnableSR = !localEnableSR;
            bool srNowOn = localEnableSR;
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               srNowOn ? clrDodgerBlue : clrDarkSlateGray);
            ChartRedraw(0);

            // ② کار اصلی (mutex همچنان نگه‌داشته → reentrant click نمی‌تواند toggle کند)
            if(srNowOn)
            {
               Print("📐 S/R ON: calculating...");
               DrawSRLevels();
            }
            else
            {
               // 🆕 v13.50 CPU-02: حلقه دستی اضافی روی کل اشیای چارت حذف شد — کد مرده
               // با هزینه CPU. ObjectsDeleteAll(0, SR_OBJ_PREFIX) به‌تنهایی کافی است.
               int deleted = ObjectsDeleteAll(0, SR_OBJ_PREFIX);
               Print("📐 S/R OFF: Deleted ", deleted, " objects");
            }

            // ③ تأیید نهایی رنگ دکمه (override هر چیزی که حین کار اصلی عوضش کرده باشد)
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               srNowOn ? clrDodgerBlue : clrDarkSlateGray);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            ChartRedraw(0);

            g_processingChartEvent = false;
            return;
         }
      }
   }

   g_processingChartEvent = false;
}

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
void SmartLoadNews()
{
   // 🆕 v13.15 FIX: گارد نهایی — صرف نظر از اینکه از کجا صدا زده شده
   // (OnInit/OnTick/OnTimer/دکمه دستی)، در بکتست هرگز وارد این تابع نشو.
   // این جلوی هر مسیر فراموش‌شده‌ای رو میگیره که قبلاً باعث لاگ
   // "Refresh news..." و تلاش مکرر WebRequest در بکتست می‌شد.
   if((bool)MQLInfoInteger(MQL_TESTER)) return;

   // ─────────────────────────────────────────────────────────────────
   // 🔧 FIX v7.0: منطق بارگذاری درست
   // اولویت ۱: کش معتبر موجود → استفاده کن (بدون دانلود)
   // اولویت ۲: دانلود تازه از اینترنت
   // اولویت ۳: فایل دستی کاربر: ff_calendar_thisweek.csv در Common\Files
   // اولویت ۴: Embedded fallback (هفته فعلی، فرمت جدید)
   //
   // ⚠️ هرگز فایل موجود را قبل از دانلود پاک نکن!
   //    کاربر ممکنه دستی فایل گذاشته باشه
   // ─────────────────────────────────────────────────────────────────

   // ─── Priority 1: Valid cache ────────────────────────────────────
   if(LoadCachedNews() && IsCacheValid() && g_newsCount > 0)
   {
      Print("✅ Valid cached news loaded (", g_newsCount, " events)");
      DrawNewsLines();
      return;
   }

   // اگه کش بود ولی منقضی شده، g_newsCount رو ریست کن
   ArrayResize(g_newsList, 0);
   g_newsCount = 0;

   // ─── Priority 2: Download from internet ────────────────────────
   // v11.2 FIX: اگر اخیراً تلاش کردیم و شکست خوردیم، 15 دقیقه retry نکن (بدون goto)
   {
      datetime _newsFailedAt = (datetime)GlobalVariableGet("HelpMe_NewsFailedAt_" + _Symbol);
      bool _skipDownload = (_newsFailedAt > 0 && TimeCurrent() - _newsFailedAt < 900);

      if(!_skipDownload)
      {
         if(DownloadAndSaveNews())
         {
            GlobalVariableSet(GetNewsSessionKey(), (double)TimeCurrent());
            Print("✅ News downloaded and cached (", g_newsCount, " events)");
            ArrayResize(g_newsList, 0);
            g_newsCount = 0;
            LoadCachedNews();
            DrawNewsLines();
            return;
         }
         // دانلود شکست خورد — زمان شکست رو ثبت کن
         GlobalVariableSet("HelpMe_NewsFailedAt_" + _Symbol, (double)TimeCurrent());
      }
      else
      {
         if(ShowDebugLogs) Print("ℹ️ News: download failed recently, skipping retry (15min cooldown)");
      }
   }

   // ─── Priority 3: Manual file (ff_calendar_thisweek.csv) ────────
   // کاربر می‌تونه فایل FF رو دستی از سایت بگیره و اینجا بزاره:
   // C:\Users\...\AppData\Roaming\MetaQuotes\Terminal\Common\Files\
   Print("📂 Trying manual file: ff_calendar_thisweek.csv ...");
   int manualHandle = FileOpen("ff_calendar_thisweek.csv", FILE_READ|FILE_TXT|FILE_COMMON);
   if(manualHandle != INVALID_HANDLE)
   {
      string csv = "";
      while(!FileIsEnding(manualHandle))
         csv += FileReadString(manualHandle) + "\n";
      FileClose(manualHandle);

      if(StringLen(csv) > 100)
      {
         ArrayResize(g_newsList, 0);
         g_newsCount = 0;
         ParseCSVString(csv);
         if(g_newsCount > 0)
         {
            Print("✅ Manual file loaded (", g_newsCount, " events)");
            // کش کن تا دفعه بعد لازم نباشه دوباره بخونه
            SaveToCache(csv);
            DrawNewsLines();
            return;
         }
      }
   }

   // ─── اگه هیچ منبعی در دسترس نبود ───────────────────────────────
   Print("❌ HelpMe: News data unavailable. Check:");
   Print("   MT5 → Tools → Options → Expert Advisors → Allow WebRequest");
   Print("   Add URL: https://nfs.faireconomy.media");
   Print("   For Telegram (v11.2): also add https://api.telegram.org");
   Print("   Algo Trading button must be ON in toolbar");
}

//+------------------------------------------------------------------+
//| Check if Cache is Valid                                          |
//+------------------------------------------------------------------+
bool IsCacheValid()
{
   int handle = FileOpen(GetTimestampFilePath(), FILE_READ|FILE_TXT|FILE_COMMON);
   if(handle == INVALID_HANDLE) return false;
   
   string timestamp_str = FileReadString(handle);
   FileClose(handle);
   
   datetime cached_time = (datetime)StringToInteger(timestamp_str);
   datetime now = TimeCurrent();
   
   int hours_passed = (int)((now - cached_time) / 3600);
   
   return (hours_passed < CacheValidHours);
}

//+------------------------------------------------------------------+
//| Load News from Local Cache                                       |
//+------------------------------------------------------------------+
bool LoadCachedNews()
{
   int handle = FileOpen(GetCacheFilePath(), FILE_READ|FILE_TXT|FILE_COMMON);
   if(handle == INVALID_HANDLE)
   {
      Print("📂 No cache file found");
      return false;
   }
   
   string csv = "";
   while(!FileIsEnding(handle))
   {
      csv += FileReadString(handle) + "\n";
   }
   FileClose(handle);
   
   if(StringLen(csv) < 50)
   {
      if(EnableAllLogs) Print("⚠️ Cache file is empty or corrupted");
      return false;
   }
   
   ParseCSVString(csv);
   
   int ts_handle = FileOpen(GetTimestampFilePath(), FILE_READ|FILE_TXT|FILE_COMMON);
   if(ts_handle != INVALID_HANDLE)
   {
      string ts = FileReadString(ts_handle);
      g_lastUpdate = (datetime)StringToInteger(ts);
      FileClose(ts_handle);
   }
   
   return (g_newsCount > 0);
}

//+------------------------------------------------------------------+
//| Download News and Save to Cache                                  |
//+------------------------------------------------------------------+
bool DownloadAndSaveNews()
{
   string urls[] = {URL_PRIMARY, URL_BACKUP1, URL_BACKUP2};
   
   for(int i = 0; i < ArraySize(urls); i++)
   {
      Print("📡 Trying to download from: ", urls[i]);
      
      char post[];
      char result[];
      string headers;
      string user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36";
      
      ResetLastError();
      int res = WebRequest("GET", urls[i], user_agent, NULL, 5000, post, 0, result, headers);
      int error = GetLastError();
      
      if(res == 200 && error == 0)
      {
         string csv = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
         
         if(StringFind(csv, "<!DOCTYPE") >= 0 || 
            StringFind(csv, "<html") >= 0 ||
            StringFind(csv, "exceeded") >= 0)
         {
            if(EnableAllLogs) Print("⚠️ Server returned HTML instead of CSV - trying next mirror");
            continue;
         }
         
         // Validate: new FF format starts with "Title,Country,Date,Time"
         // Old format was "Date,Time,Currency" – accept both for compatibility
         bool validFormat = (StringFind(csv, "Title,Country,Date,Time") >= 0) ||
                            (StringFind(csv, "Date,Time,Currency")      >= 0);
         
         if(!validFormat)
         {
            if(EnableAllLogs) Print("⚠️ Invalid CSV format - trying next mirror");
            continue;
         }
         
         if(SaveToCache(csv))
         {
            Print("✅ Downloaded from: ", urls[i]);
            return true;
         }
      }
      else
      {
         if(EnableAllLogs) Print("⚠️ Download failed - HTTP:", res, " Error:", error);
         // v11.2 FIX: بدون Sleep — هنگ نکن، برو سراغ mirror بعدی فوراً
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Save CSV to Local Cache                                          |
//+------------------------------------------------------------------+
bool SaveToCache(string csv)
{
   int handle = FileOpen(GetCacheFilePath(), FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(handle == INVALID_HANDLE)
   {
      Print("❌ Failed to create cache file");
      return false;
   }
   
   FileWriteString(handle, csv);
   FileClose(handle);
   
   int ts_handle = FileOpen(GetTimestampFilePath(), FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(ts_handle != INVALID_HANDLE)
   {
      FileWriteString(ts_handle, IntegerToString(TimeCurrent()));
      FileClose(ts_handle);
   }
   
   g_lastUpdate = TimeCurrent();
   
   return true;
}

//+------------------------------------------------------------------+
//| Parse CSV String                                                 |
//| Supports:                                                        |
//|  NEW format: Title,Country,Date(MM-DD-YYYY),Time(H:MMam/pm),    |
//|              Impact,Forecast,Previous,URL                        |
//|  OLD format: Date(YYYY-MM-DD),Time(HH:MM),Currency,Impact,      |
//|              Event,Actual,Forecast,Previous                      |
//+------------------------------------------------------------------+
void ParseCSVString(string csv)
{
   ArrayResize(g_newsList, 0);
   g_newsCount = 0;
   
   string lines[];
   int line_count = StringSplit(csv, '\n', lines);

   // 🆕 v13.50 CPU-01: پیش‌تخصیص worst-case (هر خط حداکثر یک خبر) — یک‌بار
   // ArrayResize به‌جای اینکه AddNews() هر خبر خودش resize کند (O(n²)).
   // در انتها به اندازه واقعی trim می‌شود.
   if(line_count > 0) ArrayResize(g_newsList, line_count);
   
   datetime from = TimeCurrent() - NewsLookbackDays * 86400;
   datetime to   = TimeCurrent() + NewsLookforwardDays * 86400;
   
   string clean_symbol = _Symbol;
   StringReplace(clean_symbol, "_l", "");
   StringReplace(clean_symbol, "_sb", "");
   StringReplace(clean_symbol, ".raw", "");
   StringReplace(clean_symbol, ".", "");
   
   string base  = StringSubstr(clean_symbol, 0, 3);
   string quote = StringSubstr(clean_symbol, 3, 3);
   
   // Auto-detect format from header line
   bool isNewFormat = false;
   if(line_count > 0)
   {
      string header = lines[0];
      if(StringFind(header, "Title,Country") >= 0)
         isNewFormat = true;
   }
   
   if(ShowDebugLogs)
      Print("📰 ParseCSV: ", isNewFormat ? "NEW format (FF 2025+)" : "OLD format", 
            " | Lines: ", line_count);
   
   for(int i = 1; i < line_count; i++)
   {
      string line = lines[i];
      StringReplace(line, "\r", "");  // 🔧 FIX v7.0: حذف \r از CSV با line ending ویندوزی
      if(StringLen(line) < 10) continue;
      
      string fields[];
      int field_count = StringSplit(line, StringGetCharacter(",", 0), fields);
      
      datetime event_time = 0;
      string   currency   = "";
      string   impact_str = "";
      string   event_name = "";
      string   actual_str    = "";
      string   forecast_str  = "";
      string   previous_str  = "";
      
      if(isNewFormat)
      {
         // NEW: Title,Country,Date,Time,Impact,Forecast,Previous,URL
         if(field_count < 7) continue;
         
         event_name  = fields[0];
         currency    = fields[1];
         string date_raw = fields[2]; // MM-DD-YYYY
         string time_raw = fields[3]; // H:MMam  or  All Day
         impact_str  = fields[4];
         forecast_str = fields[5];
         previous_str = fields[6];
         actual_str   = "";  // not present in new format
         StringTrimLeft(date_raw);  StringTrimRight(date_raw);
         StringTrimLeft(time_raw);  StringTrimRight(time_raw);
         
         // Convert date MM-DD-YYYY → YYYY.MM.DD (با leading zero برای ماه و روز)
         string dateParts[];
         if(StringSplit(date_raw, '-', dateParts) == 3)
         {
            // 🔧 FIX v7.0: استفاده از StringFormat با %02d برای leading zero
            // بدون این فیکس: "2026.2.22" → StringToTime برمیگردونه 0
            // با این فیکس: "2026.02.22" → StringToTime درست کار می‌کنه
            int month_i = (int)StringToInteger(dateParts[0]);
            int day_i   = (int)StringToInteger(dateParts[1]);
            int year_i  = (int)StringToInteger(dateParts[2]);
            
            // Convert time H:MMam/pm → HH:MM
            string timeConverted = "00:00";
            StringTrimLeft(time_raw);
            StringTrimRight(time_raw);
            
            if(StringFind(time_raw, "All Day") >= 0 || StringLen(time_raw) < 4)
            {
               timeConverted = "00:00";
            }
            else
            {
               // Detect am/pm
               bool isPM = (StringFind(time_raw, "pm") >= 0 || StringFind(time_raw, "PM") >= 0);
               bool isAM = (StringFind(time_raw, "am") >= 0 || StringFind(time_raw, "AM") >= 0);
               
               // Strip am/pm suffix
               StringReplace(time_raw, "pm", "");
               StringReplace(time_raw, "am", "");
               StringReplace(time_raw, "PM", "");
               StringReplace(time_raw, "AM", "");
               StringTrimRight(time_raw);
               
               // Split H:MM
               string timeParts[];
               if(StringSplit(time_raw, ':', timeParts) == 2)
               {
                  int hour   = (int)StringToInteger(timeParts[0]);
                  int minute = (int)StringToInteger(timeParts[1]);
                  
                  // 12-hour → 24-hour conversion
                  if(isPM && hour != 12)  hour += 12;
                  if(isAM && hour == 12)  hour  = 0;
                  
                  timeConverted = StringFormat("%02d:%02d", hour, minute);
               }
            }
            
            // 🔧 StringFormat تضمین می‌کنه "2026.02.22" نه "2026.2.22"
            string dt_str = StringFormat("%04d.%02d.%02d %s", year_i, month_i, day_i, timeConverted);
            event_time = StringToTime(dt_str);
            
            if(ShowDebugLogs && event_time == 0)
               Print("⚠️ ParseCSV: date parse failed for '", date_raw, "' → '", dt_str, "'");

            // 🔧 تبدیل زمان: CSV زمان UTC است (تأییدشده با FF)
            // StringToTime رشته را به‌عنوان broker time تفسیر می‌کند
            // پس فقط BrokerGMTOffset اضافه می‌شود: UTC → broker
            // مثال: 23:30 UTC + 2h broker = 01:30 broker ✓
            if(event_time > 0)
            {
               event_time += BrokerGMTOffset * 3600;
               if(ShowDebugLogs)
                  Print("📅 Time: UTC=", TimeToString(event_time - BrokerGMTOffset*3600, TIME_DATE|TIME_MINUTES),
                        " → broker(+", BrokerGMTOffset, "h)=", TimeToString(event_time, TIME_DATE|TIME_MINUTES));
            }
         }
      }
      else
      {
         // OLD: Date(YYYY-MM-DD),Time(HH:MM),Currency,Impact,Event,Actual,Forecast,Previous
         if(field_count < 8) continue;
         
         // Replace dashes in date with dots for StringToTime
         string date_raw = fields[0];
         StringReplace(date_raw, "-", ".");
         // 🔧 FIX v7.5: اطمینان از leading zero در زمان OLD format
         // اگه منبع "9:30" بده (بدون صفر) → StringToTime مقدار 0 برمی‌گرداند
         string time_old = fields[1];
         {
            string _tp[];
            if(StringSplit(time_old, ':', _tp) == 2)
               time_old = StringFormat("%02d:%02d",
                          (int)StringToInteger(_tp[0]),
                          (int)StringToInteger(_tp[1]));
         }
         string dt_str = date_raw + " " + time_old;
         event_time   = StringToTime(dt_str);

         // 🔧 OLD format: CSV زمان UTC است، فقط broker offset اضافه می‌شود
         if(event_time > 0)
            event_time += BrokerGMTOffset * 3600;
         
         currency     = fields[2];
         impact_str   = fields[3];
         event_name   = fields[4];
         actual_str   = fields[5];
         forecast_str = fields[6];
         previous_str = fields[7];
      }
      
      if(event_time == 0) continue;
      
      if(event_time < from || event_time > to) continue;
      
      // Normalize currency to uppercase
      StringTrimLeft(currency);
      StringTrimRight(currency);
      StringToUpper(currency);
      
      double weight = GetCurrencyWeight(currency);
      if(weight < MinWeightThreshold) continue;
      
      StringToUpper(impact_str);
      StringTrimLeft(impact_str);
      StringTrimRight(impact_str);
      
      int impact = (StringFind(impact_str, "HIGH") >= 0)   ? 3 :
                   (StringFind(impact_str, "MEDIUM") >= 0) ? 2 :
                   (StringFind(impact_str, "LOW") >= 0)    ? 1 : 0;
      
      if(impact == 0) continue;  // skip Holiday and unknown
      if(impact == 3 && !ShowHighImpact)   continue;
      if(impact == 2 && !ShowMediumImpact) continue;
      if(impact == 1 && !ShowLowImpact)    continue;
      
      // Clean numeric strings
      string cleanStr[3];
      cleanStr[0] = actual_str;
      cleanStr[1] = forecast_str;
      cleanStr[2] = previous_str;
      
      for(int k = 0; k < 3; k++)
      {
         StringReplace(cleanStr[k], "%", "");
         StringReplace(cleanStr[k], "B", "");
         StringReplace(cleanStr[k], "M", "");
         StringReplace(cleanStr[k], "K", "");
         StringReplace(cleanStr[k], "T", "");
         StringTrimLeft(cleanStr[k]);
         StringTrimRight(cleanStr[k]);
      }
      
      NewsEvent news;
      news.time     = event_time;
      news.currency = currency;
      news.name     = event_name;
      news.impact   = impact;
      news.actual   = (cleanStr[0] != "") ? StringToDouble(cleanStr[0]) : 0;
      news.forecast = (cleanStr[1] != "") ? StringToDouble(cleanStr[1]) : 0;
      news.previous = (cleanStr[2] != "") ? StringToDouble(cleanStr[2]) : 0;
      news.weight   = weight;
      
      news.deviation = (news.time < TimeCurrent()) ?
                       (news.actual - news.forecast) :
                       (news.forecast - news.previous);
      
      bool positive = (news.deviation > 0);
      
      if(currency == base)
         news.direction = positive ? 1 : -1;
      else if(currency == quote)
         news.direction = positive ? -1 : 1;
      else
         news.direction = positive ? 1 : -1;
      
      AddNews(news);
   }

   // 🆕 v13.50 CPU-01: trim به اندازه واقعی (worst-case pre-alloc بالا ممکنه بزرگ‌تر بوده)
   ArrayResize(g_newsList, g_newsCount);
   
   if(ShowDebugLogs)
      Print("📰 Parsed ", g_newsCount, " news events (from=", TimeToString(from), 
            " to=", TimeToString(to), ")");
}

//+------------------------------------------------------------------+
//| Add News to Array                                                |
//+------------------------------------------------------------------+
void AddNews(NewsEvent &news)
{
   // 🆕 v13.50 CPU-01: دیگه هر خبر خودش ArrayResize صدا نمی‌زند (O(n²) با ۲۰۰+ خبر).
   // ParseCSVString از قبل آرایه را به اندازه worst-case (line_count) pre-allocate
   // کرده — اینجا فقط assign + increment. اگر آرایه به هر دلیلی کوچک‌تر بود
   // (فراخوانی از مسیر دیگری غیر از ParseCSVString)، fallback ایمن resize می‌کند.
   if(g_newsCount >= ArraySize(g_newsList))
      ArrayResize(g_newsList, g_newsCount + 1);
   g_newsList[g_newsCount] = news;
   g_newsCount++;
}

//+------------------------------------------------------------------+
//| Draw News Lines and Labels                                       |
//+------------------------------------------------------------------+
void DrawNewsLines(bool force = false)
{
   // 🆕 v13.50 CPU-03: جلوگیری از rebuild کامل در هر tick
   // 🟡 مشکل: DrawNewsLines() هر بار ObjectsDeleteAll + redraw کامل انجام می‌داد —
   //   حتی وقتی هیچ تغییری در لیست اخبار نبود.
   // ✅ راه‌حل: dirty-check — فقط اگر g_newsCount یا g_lastUpdate تغییر کرده باشد
   //   (یا caller صراحتاً force=true بدهد، مثلاً بعد از پاک‌سازی دستی اشیای چارت) rebuild کن.
   static int      s_lastDrawnCount  = -1;
   static datetime s_lastDrawnUpdate = 0;
   if(!force && g_newsCount == s_lastDrawnCount && g_lastUpdate == s_lastDrawnUpdate) return;
   s_lastDrawnCount  = g_newsCount;
   s_lastDrawnUpdate = g_lastUpdate;

   string prefix = "MYNEWS_";
   ObjectsDeleteAll(0, prefix);
   
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 5) point *= 10;
   double offset = LabelOffsetPips * point;
   
   for(int i = 0; i < g_newsCount; i++)
   {
      NewsEvent news = g_newsList[i];
      
      color line_color = (news.impact == 3) ? HighImpactColor :
                         (news.impact == 2) ? MediumImpactColor : LowImpactColor;
      
      string vline = prefix + "VLINE_" + IntegerToString(i);

      // ── دیدوپلیکیت: اگر برای این زمان قبلاً VLine رسم شده، فقط tooltip ادغام کن ──
      bool timeAlreadyDrawn = false;
      string existingVLine  = "";
      for(int j = 0; j < i; j++)
      {
         if(g_newsList[j].time == news.time)
         {
            existingVLine  = prefix + "VLINE_" + IntegerToString(j);
            timeAlreadyDrawn = true;
            break;
         }
      }

      if(!timeAlreadyDrawn)
      {
         ObjectCreate(0, vline, OBJ_VLINE, 0, news.time, 0);
         ObjectSetInteger(0, vline, OBJPROP_COLOR, line_color);
         ObjectSetInteger(0, vline, OBJPROP_STYLE, NewsLineStyle);
         ObjectSetInteger(0, vline, OBJPROP_WIDTH, NewsLineWidth);
         ObjectSetInteger(0, vline, OBJPROP_BACK, true);
         ObjectSetInteger(0, vline, OBJPROP_ZORDER, 0);   // v11.92: اولویت کلیک پایین‌تر از داشبورد
         ObjectSetInteger(0, vline, OBJPROP_SELECTABLE, false);
      }
      else
      {
         // رنگ مهم‌ترین خبر را نگه دار (High > Medium > Low)
         color existingColor = (color)ObjectGetInteger(0, existingVLine, OBJPROP_COLOR);
         if(line_color == HighImpactColor)
            ObjectSetInteger(0, existingVLine, OBJPROP_COLOR, HighImpactColor);
         else if(line_color == MediumImpactColor && existingColor == LowImpactColor)
            ObjectSetInteger(0, existingVLine, OBJPROP_COLOR, MediumImpactColor);
      }
      
      string impact_text = (news.impact == 3) ? "High" : 
                          (news.impact == 2) ? "Medium" : "Low";
      
      string tooltip = StringFormat(
         "%s\nCurrency: %s | Impact: %s\nForecast: %.4f | Previous: %.4f",
         news.name, news.currency, impact_text, news.forecast, news.previous
      );
      
      if(news.time < TimeCurrent())
         tooltip += StringFormat("\nActual: %.4f | Deviation: %.4f", news.actual, news.deviation);
      
      // اضافه کردن tooltip به خط صحیح (اصلی یا ادغام‌شده)
      string targetVLine = timeAlreadyDrawn ? existingVLine : vline;
      // ادغام tooltip: محتوای قبلی + جدید
      string prevTip = ObjectGetString(0, targetVLine, OBJPROP_TOOLTIP);
      if(StringLen(prevTip) > 0 && !timeAlreadyDrawn)
         ObjectSetString(0, targetVLine, OBJPROP_TOOLTIP, tooltip);
      else if(timeAlreadyDrawn)
         ObjectSetString(0, targetVLine, OBJPROP_TOOLTIP, prevTip + "\n──\n" + tooltip);
      else
         ObjectSetString(0, targetVLine, OBJPROP_TOOLTIP, tooltip);
      
      if(ShowNewsLabels && !timeAlreadyDrawn)
      {
         int bars_total = Bars(_Symbol, PERIOD_CURRENT);
         int bar = Bars(_Symbol, PERIOD_CURRENT, news.time, TimeCurrent());
         
         // 🆕 v5.0 FIX: لیبل را 30 پوینت پایین‌تر از سقفکندل قرار می‌دهیم
         // و زاویه 90 درجه برای نوشتن عمودی (عمود بر خط خبری)
         double labelPrice;
         if(bar >= 0 && bar < bars_total)
         {
            double high[];
            ArraySetAsSeries(high, true);
            CopyHigh(_Symbol, PERIOD_CURRENT, bar, 1, high);
            // موقعیت: سقف + offset اصلی - 30 وینت (پایین‌تر از قبل)
            labelPrice = high[0] + offset - 30 * point;
         }
         else
         {
            double close[];
            ArraySetAsSeries(close, true);
            CopyClose(_Symbol, PERIOD_CURRENT, 0, 1, close);
            labelPrice = close[0] + offset - 30 * point;
         }
         
         string dir = (news.direction > 0) ? "^" : 
                     (news.direction < 0) ? "v" : "-";
         color dir_color = (news.direction > 0) ? clrLimeGreen : 
                          (news.direction < 0) ? clrRed : clrGray;
         
         string label = prefix + "LABEL_" + IntegerToString(i);
         string label_text = news.currency + " " + dir;
         
         ObjectCreate(0, label, OBJ_TEXT, 0, news.time, labelPrice);
         ObjectSetString (0, label, OBJPROP_TEXT,      label_text);
         ObjectSetInteger(0, label, OBJPROP_COLOR,     dir_color);
         ObjectSetInteger(0, label, OBJPROP_FONTSIZE,  LabelFontSize);
         ObjectSetString (0, label, OBJPROP_FONT,      "Arial Bold");
         // 🆕 v5.0: عمودی (زاویه 90 درجه) - خوانده می‌شود از پایین به بالا
         ObjectSetDouble (0, label, OBJPROP_ANGLE,     90.0);
         ObjectSetInteger(0, label, OBJPROP_ANCHOR,    ANCHOR_LEFT);
         ObjectSetInteger(0, label, OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0, label, OBJPROP_BACK,      true);  // behind dashboard
      }
   }
   
   ChartRedraw();
}
