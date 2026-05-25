//+------------------------------------------------------------------+
//|                                                 HelpMe_V11.92.mq5 |
//|                 Combined EA - Ali Naderi v11.92 (EA)              |
//+------------------------------------------------------------------+
#property copyright "HelpMe v11.92 - Ali Naderi"
#property version   "11.92"
// ═══════════════════════════════════════════════════════════════════
// v11.92 CHANGELOG (base: v11.91)
// ─────────────────────────────────────────────────────────────────
// 🖱️ FIX کلیک‌ناپذیر شدن دکمه‌ها وقتی خط Zone/S/R از زیر آن‌ها رد می‌شود:
//    OBJPROP_ZORDER دکمه‌ها و لیبل‌های داشبورد = 10 (بالاترین اولویت کلیک)
//    خطوط HLINE (Zone/S/R/Liquid) و VLINE خبر صراحتاً ZORDER=0 → دکمه‌ها همیشه برنده کلیک
// 📏 INPUT جدید: DashboardScalePercent (پیش‌فرض=100)
//    50..300 درصد. عرض/ارتفاع/Spacing/فونت داشبورد متناسب کوچک/بزرگ می‌شود.
//    مثال: 70 = ۳۰٪ کوچک‌تر | 200 = دو برابر
// 🔤 CRISIS Label: سایز فونت 15 → 13 (دو ورژن کوچک‌تر)
// 🎨 Zone Lines رنگ‌بندی هوشمند:
//    • بدون پوزیشن و دکمه روی All → همه خاکستری
//    • هج باز (Buy+Sell همزمان) → همه خاکستری (حتی با وجود پوزیشن)
//    • پوزیشن Buy / دکمه Buy → طبقات منفی سبز (سود) | طبقات مثبت قرمز (ضرر)
//    • پوزیشن Sell / دکمه Sell → طبقات مثبت سبز (سود) | طبقات منفی قرمز (ضرر)
//    • هرچه از طبقه ورود دورتر، رنگ پررنگ‌تر (Gold→Orange→OrangeRed→Red و MediumSeaGreen→LimeGreen→SpringGreen)
//    • در حالت دکمه‌ی Buy/Sell بدون پوزیشن واقعی، طبقه ورود = طبقه قیمت فعلی
//    • Cache رسم خطوط: تغییر colorMode هم rebuild می‌کند (Buy↔Sell↔All فوراً اعمال می‌شود)
// ═══════════════════════════════════════════════════════════════════
//
// v11.91 CHANGELOG (base: v11.9)
// ─────────────────────────────────────────────────────────────────
// 🗺️ Zone Table: اضافه شد EURCHF / AUDNZD / GBPNZD + اصلاح AUDCAD
//    AUDCAD  : Zone 0 = [0.90000 .. 0.92000)  width=200pip
//    EURCHF  : Zone 0 = [0.90000 .. 0.92250)  width=225pip (2250 point)
//    AUDNZD  : Zone 0 = [1.19450 .. 1.22000)  width=255pip (2550 point)
//    GBPNZD  : Zone 0 = [2.26500 .. 2.30500)  width=400pip (4000 point)
//    Zone ها از دو طرف ادامه پیدا می‌کنند (Zone ±N به صورت خودکار)
// ─────────────────────────────────────────────────────────────────
// 🧹 Input Cleanup: خلوت‌سازی پنل Inputs
//    حذف از نمایش (ثابت داخلی ماندند):
//      • Initial TimeFrame
//      • News: Past/Future Days, Min Weight, رنگ‌ها، Line Style/Width، Show Labels
//      • Backtest: Lines Each Side، Yellow Border Pips
//      • اعلان‌ها: توکن ربات تلگرام (مقدار ثابت در کد)
//    اضافه‌شد گروه جدید "💡 چراغ‌ها | Light":
//      • ShowZoneLines (Draw Zone Lines)
//      • ZombieH1ConfirmBars (H1 Confirm Bars)
// ─────────────────────────────────────────────────────────────────
// 🎨 رنگ خطوط Zone Lines:
//    • بدون پوزیشن یا هج → همه خطوط خاکستری (clrDimGray)
//    • Buy position → سبز=سود / قرمز=ضرر
//    • Sell position → معکوس (سبز=سود / قرمز=ضرر برای Sell)
// ─────────────────────────────────────────────────────────────────
// ⏻ Power Off Button: دکمه خاموش کنار دکمه Sell در داشبورد
//    کلیک → پاک‌سازی کامل همه اشیاء + حذف اکسپرت از چارت
//    مطمئن‌تر از Remove از منوی متاتریدر
// ─────────────────────────────────────────────────────────────────
// 🔢 ZoneLineCount: تعداد طبقات از 12 به 30 تغییر کرد
// 🖨️ Backtest Print: رشته نسخه از پیام ذخیره CSV حذف شد
// ═══════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════
// v11.9 CHANGELOG (base: v11.8)
// ⚠️ FIX: آستانه HIGH ALERT از ADX >= 40 به ADX >= 35 کاهش یافت
//    دلیل: بررسی بکتست AUDCAD نشان داد ADX در بازه عادی بین ۲۳ تا ۳۵ است
//    با آستانه قدیمی (۴۰)، HighAlert تقریباً هیچوقت فعال نمی‌شد
//    با آستانه جدید (۳۵)، هشدار زودتر و در شرایط واقعی بازار فعال می‌شود
//    نکته: آستانه CRISIS Red-B (ADX > 40) تغییر نکرد — فقط HighAlert اصلاح شد
//    تغییرات:
//      bt_adxVal >= 40.0 → bt_adxVal >= 35.0  (CSV بکتست)
//      g_lastAdxVal >= 40.0 → g_lastAdxVal >= 35.0  (چراغ live)
//      _highAlertNow = (g_lastAdxVal >= 40.0) → (g_lastAdxVal >= 35.0)
// ═══════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════
// v11.8 CHANGELOG (base: v11.7)
// 🔤 FIX: Telegram — متن فارسی با CP_UTF8 encode می‌شود (قبلاً ???? می‌شد)
// 🚨 FIX: Alert_OnCrisis — فقط قرمز (state=2)؛ نارنجی (state=3) دیگر اعلان نمی‌دهد
// 🗑️ CSV: ستون RTM_Dist_xATR حذف شد — جایگزین: ستون HighAlert (Active/OK)
//    struct HourlySnapshot: اضافه شد bool highAlert
//    LogHourlySnapshot: پارامتر bool highAlertActive اضافه شد
//    OnTester CSV: header و data line به‌روز شد
// 🔔 FIX: ارسال تلگرام از GET → POST+JSON تغییر کرد
//    دلیل: متن فارسی در GET (URL-encode ناقص) توسط تلگرام رد می‌شد
//    راه‌حل: JSON body مستقیم با UTF-8 — بدون percent-encoding
// ═══════════════════════════════════════════════════════════════════
// v11.8 CHANGELOG (base: v11.6)
// 🐛 FIX: Remove EA — حذف قطعی StatusLabel و HM_CRISIS_LIGHT
//          علت: در بعضی بیلدهای MT5، labelها هنگام OnDeinit دوباره ساخته می‌شدند
//          یا تصویرشان بعد از ObjectDelete روی چارت cache می‌ماند.
//          راه‌حل: g_isDeinitializing + قطع رویدادها/تایمر + blank-before-delete
//          + حذف سخت‌گیرانه exact/substring در چند pass.
// ⚡ سرعت اجرا تغییر نکرده — فقط مسیر Remove/Deinit و guardهای سبک اضافه شده‌اند
//
// v11.6 CHANGELOG (base: v11.5)
// 🐛 FIX: Remove EA — پاک‌سازی چندمرحله‌ای برای HM_CRISIS_LIGHT / StatusLabel / ProfitLabel
//
// v11.5 CHANGELOG (base: v11.4)
// 🐛 FIX 1: دکمه S/R debounce با GetTickCount (600ms) به جای TimeCurrent (sec)
//          + تأیید نهایی BGCOLOR در پایان handler → toggle دیگر دوبار اتفاق نمی‌افتد
// 🐛 FIX 2: OnDeinit EARLY SWEEP در همان ابتدای تابع (قبل از هر فراخوانی‌ای)
//          → حتی اگر بقیه پاکسازی‌ها fail کنند، هیچ شیء HelpMe باقی نمی‌ماند
// ⚡ سرعت بدون تغییر — فقط دو مسیر cleanup عوض شده‌اند
//
// v11.4 CHANGELOG (base: v11.3)
// 🐛 FIX 1: دکمه S/R toggle off — کلیک دوم خطوط را پاک نمی‌کرد و دکمه سبز می‌ماند
//          علت: mutex قبل از کار سنگین آزاد نمی‌شد + reentrant click از ChartRedraw
//          راه‌حل: state و BGCOLOR در همان ابتدای handler اعمال + STATE=false فوری
//                   + رهاسازی زودهنگام mutex قبل از DrawSRLevels/Delete
// 🐛 FIX 2: Remove EA — خطوط S/R، خبر، Zone، فلش‌های سیگنال و خط Liquid روی چارت می‌ماندند
//          راه‌حل: یک sweep کامل در OnDeinit با حلقه دستی روی تمام prefixهای شناخته‌شده
//                   (ZombieLine_, ZoneLabel_, XSA_SR_, HM_LQ_, MYNEWS_, HMArr_, HM_MA_, HM_FEMA_,
//                    XSA12_, HM7_LT_) + حذف شرط ShowZoneLines از فراخوانی DeleteZoneLines
//          ⚡ سرعت اجرا تغییر نکرده (فقط مسیر cleanup در OnDeinit و handler یک دکمه)
//
// v11.3 CHANGELOG
// ─────────────────────────────────────────────────────────────────
// 🎨 FIX: رنگ‌دهی چارت در حالت Buy/Sell بدون پوزیشن
//    مشکل قبلی: وقتی دکمه Buy یا Sell می‌زدیم و پوزیشن نداشتیم،
//    چارت رنگ نمی‌گرفت (فقط با پوزیشن واقعی کار می‌کرد)
//    اصلاح: اگه Buy/Sell انتخاب شده باشه، رنگ چارت بر اساس Score ترند
//    نمایش داده می‌شه (مثل وقتی پوزیشن واقعی داریم)
//    All + بدون پوزیشن → رنگ اصلی
//
// 📊 UX: Score ترند همیشه در StatusLabel نمایش داده می‌شه
//    حتی بدون پوزیشن باز، Score عدد ترند روی چارت قابل مشاهده است
//
// 🔄 FIX: بعد از کلیک DirBtn، رنگ چارت فوری تغییر می‌کند
//    مشکل قبلی: باید صبر می‌کردیم تا تیک بعدی بیاد تا رنگ عوض بشه
//    اصلاح: CSL_Execute() بلافاصله بعد از کلیک Buy/All/Sell فراخوانی می‌شه
//
// 🧹 FIX: Reset + Remove → رنگ چارت به اصلی برمی‌گردد
//    - Reset دکمه: رنگ چارت به g_originalBgColor ریست می‌شه
//    - Remove اکسپرت: رنگ چارت در OnDeinit بازگردانی می‌شه
//
// 🔧 FIX: mutex timeout کاهش یافت (30s → 10s)
//    هنگ EA بعد از کلیک سریع دکمه‌ها کمتر اتفاق می‌افته
//
// 🔧 FIX: ForceRecalculation همیشه هر دو mutex را آزاد می‌کند
//    g_recalcBusy + g_processingChartEvent هر دو در پایان آزاد می‌شوند
//
// 🔔 FIX: Telegram/Eitaa با Token/ChatID پیش‌فرض ارسال نمی‌کند
//    Token و ChatID پیش‌فرض قابل جستجو (97864663566) هستند
//    اگه کاربر Token رو تغییر نداده باشه، ارسال انجام نمی‌شه
// ─────────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
// v11.2 CHANGELOG
// ─────────────────────────────────────────────────────────────────
// 🔔 NEW: سیستم اعلان (Notification System)
//    دو کانال: MetaTrader Mobile Push + Telegram Bot + Eitaa Bot
//    هر کانال در Inputs جداگانه روشن/خاموش می‌شود (default: روشن)
//
//    Inputs جدید (گروه 🔔 اعلان‌ها):
//      Alert_MT5Push          — اعلان MT5 Push Notification (پیش‌فرض: true)
//      Alert_Telegram         — اعلان تلگرام (پیش‌فرض: true)
//      Alert_TelegramToken    — توکن Bot تلگرام
//      Alert_TelegramChatID   — شناسه چت / کانال تلگرام
//      Alert_Eitaa            — اعلان ایتا (پیش‌فرض: false)
//      Alert_EitaaToken       — توکن Bot ایتا
//      Alert_EitaaChatID      — شناسه چت ایتا
//      Alert_OnCrisis         — اعلان وقتی CRISIS قرمز/نارنجی شود (پیش‌فرض: true)
//      Alert_OnZombie         — اعلان وقتی ZOMBIE قرمز شود (پیش‌فرض: true)
//      Alert_OnHighAlert      — اعلان وقتی HIGH ALERT فعال شود (پیش‌فرض: true)
//      Alert_OnFlow           — اعلان وقتی FLOW قرمز شود (پیش‌فرض: true)
//      Alert_OnADX            — اعلان وقتی ADX قرمز شود (پیش‌فرض: true)
//      Alert_OnRTM            — اعلان وقتی RTM قرمز شود (پیش‌فرض: true)
//      Alert_OnStruct         — اعلان وقتی STRUCT قرمز شود (پیش‌فرض: true)
//      Alert_OnThreeLights    — اعلان وقتی ۳ چراغ از ۴ همزمان قرمز (پیش‌فرض: true)
//      Alert_CooldownMinutes  — حداقل فاصله بین دو اعلان مشابه (پیش‌فرض: 60 دقیقه)
//
//    منطق Cooldown اصلاح‌شده:
//      • Cooldown فقط روی پیام‌های تکراری پشت‌سرهم اعمال می‌شود
//      • اگه چراغ قرمز → زرد → قرمز شود (edge جدید)، پیام ارسال می‌شود
//        حتی اگه کمتر از Cooldown گذشته باشد — چون state واقعاً تغییر کرده
//      • Cooldown فقط جلوی ارسال پیام در حالت "هنوز قرمز هستیم" را می‌گیرد
// ─────────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
// v11.1 CHANGELOG
// ─────────────────────────────────────────────────────────────────
// 🐛 FIX: TF تغییر کند → handles اندیکاتور اصلی ریست و بازسازی می‌شوند
//    (handleFastMA, handleSlowMA, handleRSI, handleADX, handleBB, handleATR,
//     handleRTM_EMA, handleIchimoku, g_handleFractals)
//    قبلاً سیگنال‌ها بعد از تغییر TF از داده TF قبلی محاسبه می‌شدند
//
// 🐛 FIX: g_dirMode (Buy/All/Sell) در GlobalVariable ذخیره می‌شود
//    بعد از ریستارت EA یا تغییر TF به حالت قبلی برمی‌گردد
//
// 🧹 CLEANUP: کد مرده کاملاً حذف شد:
//    SymbolMaxPercent struct + symbols_max[] (48 ردیف بی‌استفاده)
//    XSNewsEvent struct + newsEvents[]
//    WeightOptimization struct + optimizedWeights (همیشه 1.0 بود)
//    RSI_Weight, MACD_Weight (تعریف شده، هرگز استفاده نشده)
//    g_srPendingDraw, g_srPendingClear (تعریف شده، هرگز استفاده نشده)
//    g_totalRedCount (فقط نوشته می‌شد، هیچ‌جا خوانده نمی‌شد)
//    vote_total در CSL_Execute (تعریف شده، هرگز استفاده نشده)
//
// ⚡ PERF: Sleep(20) از RunSignalLoop حذف شد
//    thread اصلی MT5 دیگر بلاک نمی‌شود
//
// ⚡ PERF: CalculateHurstExponent از CopyClose یکبار استفاده می‌کند
//    به‌جای bars × iClose در یک حلقه (کاهش قابل توجه CPU)
//
// ⚡ PERF: g_impactTable درست به اندازه 53 (نه 54) رزرو می‌شود
//
// ⚡ PERF: g_cachedER — CalculateEfficiencyRatio فقط روی کندل جدید
//    داشبورد از کش می‌خواند (قبلاً هر ثانیه 100 iClose اجرا می‌شد)
//
// ✨ UX: StatusLabel و ProfitLabel حذف/ایجاد مجدد نمی‌شوند
//    update محلی → بدون فلیکر بصری روی هر کندل جدید
// ─────────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════
// v11.0 CHANGELOG
// ─────────────────────────────────────────────────────────────────
//
// ⚡ 1. سیستم جهت‌گیری سه‌گانه: دکمه‌های Buy / Sell / All
//    مشکل قبلی: هج (Hedge) کد را گیج می‌کرد — جهت اشتباه محاسبه می‌شد
//    راه‌حل: سه دکمه رادیویی در ردیف پایین داشبورد:
//      [Buy]  — همیشه چراغ‌ها برای Buy محاسبه شود (حتی بدون پوزیشن)
//      [All]  — پیش‌فرض: جهت از پوزیشن باز خوانده شود
//      [Sell] — همیشه برای Sell محاسبه شود
//    حالت هج با All: "هج باز است" نمایش داده می‌شود، چراغ‌ها خاکستری
//    حالت Buy/Sell: اسکنر جهت‌دار — بدون پوزیشن هم کار می‌کند
//
// 📐 2. داشبورد ۲۰٪ کوچک‌تر (line spacing کاهش یافت)
//    بدون تغییر اندازه فونت — فقط فواصل بین خطوط کمتر شد
//    هدف: داشبورد کامل بدون نیاز به بستن تب Trade متاتریدر
//
// ⚠️ 3. چراغ High Alert — پیش‌هشدار ADX+Flow
//    ADX >= 35 AND Flow < -7 (Buy) یا Flow > +7 (Sell)  ← v11.9: کاهش از 40
//    → ⚠️ HIGH ALERT سرخ چشمک‌زن قبل از CRISIS قرمز
//    در خط XMOON ALERT اضافه شده
//
// 🔤 4. بخش بکتست در Input تمیز شد
//    جداکننده‌ها و توضیحات دو زبانه مرتب شدند
//
// ─────────────────────────────────────────────────────────────────
// v10.9 CHANGELOG
// ─────────────────────────────────────────────────────────────────
// 🔇 FIX: ZOMBIE کاملاً Stateless شد — بدون هیچ متغیر گلوبال وابسته
//    حذف: g_zombiePendingZone, g_zombieConfirmedZone, g_zombieLastH1Time
//    Zone_IsConfirmedByH1 فقط از CopyClose H1 می‌خواند — بدون حافظه
//    نتیجه: هر بار اکسپرت روشن می‌شود از صفر محاسبه می‌کند (مثل بکتست)
//
// 📐 FIX: base_low AUDCAD اصلاح شد: 0.84000 (قبلاً 0.90450)
//    دلیل: در آوریل 2025 قیمت تا 0.8468 رفت → Zone های خارج از محدوده
//    جدید: [0.84000 .. 0.86000) = Zone 0  (پوشش 2020-2025)
//    عرض 200 پیپ حفظ شد (موج‌های 2 هفته‌ای Xmoon)
// ─────────────────────────────────────────────────────────────────
// v10.9 CHANGELOG
// ─────────────────────────────────────────────────────────────────
// 🔇 FIX: کاهش نویز ZOMBIE با فیلتر تأیید H1
//    مشکل قبلی: ZOMBIE با هر تیک Bid تغییر رنگ می‌داد → نویز بالا
//    راه‌حل: شمارش کندل‌های H1 متوالی که در Zone جدید بسته شده‌اند
//
//    منطق جدید:
//      • اگر قیمت Zone را عوض کرد → شمارنده H1ConfirmBars شروع می‌شود
//      • فقط بعد از ZombieH1ConfirmBars کندل H1 متوالی چراغ تغییر می‌کند
//      • اگر قیمت به Zone قبلی برگشت → شمارنده ریست می‌شود (نویز حذف)
//
//    Input جدید:
//      ZombieH1ConfirmBars (پیش‌فرض=2):
//        1 = اولین H1 بسته در Zone جدید کافی است (سریع‌ترین)
//        2 = دو H1 متوالی (توصیه‌شده ⭐)
//        3 = سه H1 = ~۳ ساعت تأیید (محافظه‌کارانه)
//
//    داشبورد: شمارنده نمایش داده می‌شود:
//      ● ZONE:+1 [H1:1/2]  ← در حال تأیید
//      ● ZONE:+1 [✓]       ← تأیید شده
// ─────────────────────────────────────────────────────────────────
// v10.7 CHANGELOG
// ─────────────────────────────────────────────────────────────────
// 🐛 FIX 1: عرض زون اصلاح شد — widthPips=200 (=۲۰۰ پیپ = 0.0200)
//    Zone 0 برای AUDCAD = [0.90450 .. 0.92450] (مرکز ≈ 0.91450)
//    (v10.6 اشتباهاً widthPips=20 → 0.0020 بود)
//
// 🐛 FIX 2: فلیکر خطوط Zone هنگام اسکرول/زوم چارت
//    ریشه: CHARTEVENT_CHART_CHANGE → DrawAbsoluteZoneLines →
//           DeleteZoneLines() → flash → recreate → فلیکر
//    اصلاح: RefreshZoneLabelPositions() — فقط x لیبل‌ها بروز می‌شود
//    HLINE ها ثابت و بدون حذف/ایجاد مجدد باقی می‌مانند → بدون فلیکر
//
// 🐛 FIX 3: لیبل‌های Zone روی داشبورد می‌افتادند
//    اصلاح: OBJPROP_BACK=true برای تمام OBJ_TEXT های Zone → پشت داشبورد
// ─────────────────────────────────────────────────────────────────
// v10.6 CHANGELOG (رفع ۳ باگ خطوط Zone: draw on init, no-pos draw, TF persist)
// v10.5 CHANGELOG (رفع پسوند بروکر + cleanup)
// ═══════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════
// v10.4.1 — رفع باگ‌ها + پاکسازی کد
// ─────────────────────────────────────────────────────────────────
//  🐛 FIX: در LogHourlySnapshot، nZOMBIE → stZOMBIE (باگ بحرانی: مقدار اشتباه در log)
//  🗑️ CLEANUP: ستون رنگ ZOMBIE از CSV ساعتی حذف شد (فقط Zombie_Zone عدد کافی است)
//  🗑️ CLEANUP: تابع DrawZoneLines قدیمی (entry-relative) حذف شد (dead code)
// ═══════════════════════════════════════════════════════════════════
// v10.4.0 — ZONE بر اساس گرید مطلق قیمت (نه نقطه ورود)
// ─────────────────────────────────────────────────────────────────
//  ✅ Zone از یک جدول مرجع per-symbol خوانده می‌شود (مثلاً AUDCAD: base 0.91050-
//     0.91250 با عرض 200 پیپ). موج‌های بلندمدت چارت تعیین‌کننده‌ی طبقه‌اند.
//  ✅ نقطه ورود فقط برای ثبت «طبقه ورود» استفاده می‌شود؛ سپس رنگ ZOMBIE = مقایسه
//     طبقه فعلی با طبقه ورود + جهت پوزیشن.
//        Buy : current > entry → سبز | current == entry → سبز | current < entry → قرمز
//        Sell: برعکس
//        فاصله < 10 پیپ از مرز طبقات → چراغ زرد (هشدار مرز)
//  ✅ ارز خارج از جدول → چراغ خاکستری + برچسب "Unsupported"
//  ✅ خطوط طبقات با تغییر چارت/تایم‌فریم دوباره رسم می‌شوند (CHARTEVENT_CHART_CHANGE)
//  ✅ ورودی BacktestZombieRef حذف شد (دیگر لازم نیست — گرید مطلق)
//  ✅ CSV بکتست: فقط فایل ساعتی نگه داشته شد؛ فایل sort-by-RedCount حذف شد
//  ✅ Zombie_WidthPips از CSV ساعتی حذف شد (فقط Zone_Number کافی است)
// ═══════════════════════════════════════════════════════════════════
// v10.3.2 PATCH — اصلاح قطعی GetPipSize + جهت‌دار شدن DrawZoneLines
// ─────────────────────────────────────────────────────────────────
// 🐛 باگ ۱ (جدید v10.3.2): DrawZoneLines جهت پوزیشن را نادیده می‌گرفت
//    ریشه: level = entryPrice - (i × zoneWidth) همیشه برای Buy محاسبه می‌شد
//          برای Sell: Zone+1 باید بالای Entry باشد (قیمت بالا رفت = ضرر)
//          ولی تابع آن را پایین Entry رسم می‌کرد → خطوط کاملاً معکوس!
//    اصلاح: پارامتر bool forBuy به DrawZoneLines اضافه شد
//           Buy : level = entryPrice - (i × zoneWidth)   [پایین = ضرر]
//           Sell: level = entryPrice + (i × zoneWidth)   [بالا = ضرر]
//
// 🐛 باگ ۲ (جدید v10.3.2): GetPipSize به صورت inline بود، نه تابع مستقل
//    اصلاح: تابع double GetPipSize(string sym) اضافه شد
//           برگرداندن 0.0001 برای AUDCAD (Digits=4 یا 5)
//           و 0.01 برای سه‌رقمی مثل USDJPY
//
// ─────────────────────────────────────────────────────────────────
// v10.3.1 PATCH — باگ‌زدایی Zone محاسبه + رسم خطوط مرز طبقات
// ─────────────────────────────────────────────────────────────────
// 🐛 باگ ۱: Zone همیشه ≤ 0 بود — قیمت به نفع ما zone مثبت نمی‌گرفت
//    ریشه: if(rawDisp<=0) zone=0 — این شرط zone مثبت را می‌خورد
//    اصلاح: zone = (int)MathFloor(diff/zoneWidth) — بدون if اضافه
//           Buy : diff = EntryPrice - CurrentPrice  → مثبت=ضرر, منفی=سود
//           Sell: diff = CurrentPrice - EntryPrice  → مثبت=ضرر, منفی=سود
//           zone مستقیماً از MathFloor گرفته می‌شود (مثبت/منفی/صفر)
//
// 🐛 باگ ۲: علامت منفی اضافه — zoneNumber = -(int)MathFloor(...)
//    اصلاح: علامت منفی حذف شد — MathFloor خودش علامت درست می‌دهد
//           Buy  ضرر  : diff>0 → zone>0 مثبت (دور از ورود در ضرر)
//           Buy  سود  : diff<0 → zone<0 منفی (نزدیک‌تر/بالاتر از ورود)
//           Sell ضرر  : diff>0 → zone>0 مثبت
//           Sell سود  : diff<0 → zone<0 منفی
//
// ✨ ویژگی جدید: رسم خطوط مرز طبقات روی چارت
//    Input جدید: ShowZoneLines (bool, default=false)
//    وقتی BacktestZombieRef>0 و ShowZoneLines=true:
//    خطوط افقی در فواصل ZoneWidth از Entry رسم می‌شوند
//    Zone 0 = خط سفید | سایر zones = خط خاکستری با برچسب
//
// ─────────────────────────────────────────────────────────────────
// v10.3 CHANGELOG (base: v10.2) — بازنویسی کامل ZOMBIE → Zone Counter
// ─────────────────────────────────────────────────────────────────
// 🔧 تغییر اصلی: ZOMBIE دیگر چراغ رنگی نیست — Zone Number است
//
//   فلسفه جدید:
//     ❌ حذف: dispATR, stuckDays, shiftScore, g_zombieConfirmBars,
//             g_zombieCurrentLayer, رنگ‌بندی سبز/زرد/قرمز ZOMBIE
//     ✅ اضافه: ZONE: -2 — عدد صحیح نشان‌دهنده فاصله منطقه‌ای از ورود
//
//   تعریف منطقه (Zone):
//     ZoneWidth (pip) = ATR(D1, 200) × 2.0 (Factor ثابت)
//     ATR در لحظه ورود محاسبه و تا بستن معامله ثابت می‌ماند
//     → برای هر جفت‌ارز بدون تنظیم دستی کار می‌کند
//
//   محاسبه Zone Number:
//     Buy : zone = floor( (EntryPrice - CurrentPrice) / ZoneWidth_price )
//     Sell: zone = floor( (CurrentPrice - EntryPrice) / ZoneWidth_price )
//     اگر قیمت به ضرر ما نرفته: zone = 0
//
//   نمایش در داشبورد:
//     ● ZONE: -2 (W:187p)   به جای  ● ZMB:2.1x RED
//
//   CSV بکتست — ستون‌های تغییر یافته:
//     ❌ حذف: Zombie_Score, Zombie_MidShift_xATR, Shift_Score_xATR
//     ✅ اضافه: Zombie_Zone (int), Zombie_WidthPips (int)
//
//   CRISIS:
//     ZOMBIE دیگر state رنگی ندارد → از شمارش RC حذف شد
//     RC = (RTM==2?1:0) + (TREND==2?1:0) + (STRUCT==2?1:0) + (FLOW==2?1:0)  ← max=4
//     CRISIS منطق و آستانه‌هایش دقیقاً همانند v10.2 باقی است
//
//   بکتست طولانی:
//     ZoneWidth یک‌بار در شروع بکتست محاسبه می‌شود → در طول ماه‌ها ثابت
//     Zone نشان می‌دهد قیمت چند «طبقه» از ورود فاصله گرفته
// ─────────────────────────────────────────────────────────────────
// v10.2 CHANGELOG (base: v10.1) — بهینه‌سازی کامل بر اساس بکتست ۷۷۱ معامله
// ─────────────────────────────────────────────────────────────────
// 📊 نتایج بکتست V10.1 (ژانویه-نوامبر ۲۰۲۵، AUDCAD):
//   ✅ کال‌شدن ۲۰ مارس را ۱۹ ساعت بعد از ورود شناسایی می‌کرد
//   ✅ ۹ از ۱۲ معامله بد با سیگنال ۳+ قرمز همزمان قابل شناسایی بود
//   ❌ RTM: 96٪ اوقات قرمز/زرد — چراغ کور شده بود (AUDCAD نزولی ۲۰۲۵)
//   ❌ ZOMBIE: آستانه‌های قدیمی false positive روی معاملات خوب ایجاد می‌کرد
//
// 🔧 تغییر ۱: RTM — رفع "چراغ کور" با آستانه‌های تطبیقی
//   مشکل: d0 >= 1.5x AND NOT returning → Red → ۳۸٪ اوقات قرمز!
//   علت: در روند کلی نزولی AUDCAD، Buy معاملات همیشه CT هستند
//         و قیمت معمولاً از EMA200 دور می‌ماند
//   راه‌حل:
//     🟢 سبز : d0 >= 3.5x AND بازگشت قوی (dDel < -0.3)   ← قبلاً dDel < -0.2
//     🔴 قرمز: d0 >= 2.5x AND شتاب دور‌شدن (dDel > 0.15)  ← قبلاً 1.5x
//     🟡 زرد : همه حالات دیگر
//   نتیجه پیش‌بینی: Red از ۳۸٪ به ≤ ۱۵٪ کاهش یابد
//
// 🔧 تغییر ۲: ZOMBIE — آستانه‌های تطبیقی‌تر + SHIFT Detection
//   مشکل: dispATR >= 2.0 برای Red خیلی زود فعال می‌شد
//   راه‌حل جدید:
//     🟢 سبز : dispATR < 1.5x  (قبلاً < 1.0x)
//     🟡 زرد : dispATR >= 1.5x  یا  (dispATR >= 0.8 AND stuckDays >= 2)
//     🔴 قرمز: dispATR >= 2.5x  یا  (dispATR >= 1.5 AND stuckDays >= 4)
//   🆕 SHIFT Detection (طبقه جدید قیمتی):
//     مرکز Donchian 20bar vs مرکز Donchian 100bar
//     اگه اختلاف > 1.5x ATR_D1: نشانه جابجایی کانال → Yellow+
//     اگه اختلاف > 2.5x ATR_D1 AND stuckDays >= 3: → Red (نوع ۲ اتفاق بد)
//
// 🔧 تغییر ۳: CRISIS — اضافه شد ORANGE (هشدار زودهنگام)
//   منطق جدید (۵ حالت به جای ۴):
//     🟢 سبز    : هیچ خطری نیست
//     🟡 زرد    : هشدار عادی (Y1-Y5 قبلی)
//     🟠 نارنجی : CrisisEarly — نزدیک Red، نه فوری   ← جدید v10.2
//       شرط: (RC>=2 AND Flow<=-6.5 AND ADX>30) OR (RC>=3 AND tsAg>40 AND ADX>28)
//       هدف: کاهش تأخیر از ۱۹ ساعت به ~۱۰ ساعت در معامله کال‌کننده
//     🔴 قرمز   : خروج فوری (بدون تغییر - همان A+B)
//
// 🔧 تغییر ۴: Persistence Filter — سیگنال پایدار، نه لحظه‌ای
//   مشکل: CRISIS RED گاهی فقط ۱ ساعت روشن می‌شد و خاموش می‌شد
//   راه‌حل: اضافه شد g_crisisOrangeCount و g_crisisRedCount
//     Orange: شمارنده پایداری (وقتی ۲+ چک متوالی Orange/Red باشد، Bold نمایش)
//     Red:    فقط بعد از ۱+ چک متوالی Red نمایش داده می‌شود
//   اثر: جلوگیری از آلارم‌های کاذب ۱-ساعته
//
// 🔧 تغییر ۵: CSV بکتست — ستون‌های جدید
//   اضافه شد: ShiftScore (Donchian shift xATR)
//   اضافه شد: CrisisOrange (Y/N)
//   اضافه شد: RTM_AccelDir (UP/DN/FL — شتاب دور‌شدن/نزدیک‌شدن به EMA)
//   اضافه شد: PersistenceCount (تعداد چک‌های متوالی با این وضعیت)
// ─────────────────────────────────────────────────────────────────
// v10.1 CHANGELOG (base: v10.0) — بازنویسی کامل ZOMBIE
// ─────────────────────────────────────────────────────────────────
// ❌ سه باگ بنیادی v10.0 برطرف شد:
//
//   باگ ۱ (بزرگترین): g_zombieScore در بکتست همیشه صفر بود
//     v10.0: امتیاز در یک global runtime جمع می‌شد که با هر call ریست می‌شد
//     v10.1: کاملاً stateless — هر بار از صفر از داده‌های D1 محاسبه می‌شود
//            متغیر g_zombieScore حذف شد، جایگزین: dispATR (لحظه‌ای)
//
//   باگ ۲ (اساسی): مرجع مقایسه اشتباه بود
//     v10.0: OldMid (۴۰-۲۰ bar پیش) vs CurrMid (۲۰ bar اخیر)
//            وقتی بازار قبلاً در کف بود → OldMid پایین → shift منفی → GREEN!
//            (معامله می ۲۰۲۵ با ۲۰۷ پیپ ضرر همه‌جا Green نشان می‌داد)
//     v10.1: مرجع = قیمت ورود قدیمی‌ترین پوزیشن باز (entry-anchored)
//            fallback خودکار: مرکز کانال D1 ۲۰ روزه
//
//   باگ ۳: پنجره‌های ۲۰-روزه همپوشانی داشتند
//     v10.0: ۱۳ روز مشترک → shift خیلی کوچک به نظر می‌رسید
//     v10.1: یک پنجره واحد (مرجع ورود) — بدون همپوشانی
//
// ✅ منطق جدید ZOMBIE (کاملاً Stateless):
//   dispATR = (entryRef - currentH1) / ATR_D1   [for Long]
//           = (currentH1 - entryRef) / ATR_D1   [for Short]
//   stuckDays = چند D1 bar متوالی قیمت هرگز به entryRef برنگشت
//
//   🟢 سبز : dispATR < 1.0 (یک ATR دور از مرجع — طبیعی)
//   🟡 زرد : dispATR >= 1.0 یا (dispATR >= 0.5 AND stuckDays >= 2)
//   🔴 قرمز: dispATR >= 2.0 یا (dispATR >= 1.0 AND stuckDays >= 3)
//
// 📊 نتیجه بکتست پیش‌بینی‌شده:
//   معامله می ۲۰۲۵ (VStep=15، +207 پیپ): dispATR ≈ 2.1 → RED ✅
//   معامله کال مارس (VStep=18، +415 پیپ): dispATR ≈ 4.2 → RED ✅
//   معاملات خوب که سریع بستند (< 1 ATR): dispATR < 1.0 → GREEN ✅
// ─────────────────────────────────────────────────────────────────
// v9.0 CHANGELOG (base: v8.2) — بهبود منطق CRISIS بر اساس بکتست ۶۵۹ معامله
// ─────────────────────────────────────────────────────────────────
// 🔴 CRISIS RED — دو الگو (OR):
//   الگوی A (کلاسیک — بدون تغییر):
//       RC >= 3  AND  Flow <= -7.0  AND  ADX_H4 > 32
//       ← وایپ‌اوت مارس ۲۰۲۵ را ۱۸ ساعت بعد از ورود گرفت
//   الگوی B (فشار شدید — جدید):
//       RC >= 2  AND  Flow <= -8.5  AND  ADX_H4 > 40
//       ← معامله ۶ مارس را می‌گیرد (ADX=49, Flow=-9.25, RC=2)
//         که قبلاً به‌دلیل نرسیدن RC به ۳ از دست می‌رفت
//
// 🟡 CRISIS YELLOW — پنج شرط (OR):
//   Y1: RC >= 2                                  (بدون تغییر)
//   Y2: Flow <= -5.0  AND  ADX > 28             (بدون تغییر)
//   Y3 (جدید): RC >= 2  AND  Flow <= -7.0  AND  TsAgainst > 30
//       ← معامله ۲۸ ژوئیه را می‌گیرد (RC=2, Flow=-7, TS=-45 علیه Long)
//   Y4 (جدید): RC >= 2  AND  TsAgainst > 45  AND  ADX > 25
//       ← معامله ۱۴ مارس Short را می‌گیرد (TrendScore=+46 علیه Short)
//   Y5 (جدید): RC >= 2  AND  Flow <= -7.5  AND  ADX > 35
//       ← معامله ۶ مارس را زودتر (Yellow) قبل از Red می‌گیرد
//
//   TsAgainst = امتیاز روند برخلاف پوزیشن ما:
//     برای Long: TsAgainst = -TrendScore (TrendScore منفی = بد برای Long)
//     برای Short: TsAgainst = +TrendScore (TrendScore مثبت = بد برای Short)
//
// 📊 نتیجه بکتست ۶۵۹ معامله AUDCAD (ژانویه-سپتامبر ۲۰۲۵):
//   False Alarm Rate (Red در ۶ ساعت اول معاملات خوب): 0.2% (بدون تغییر)
//   ۱۱ از ۱۲ معامله بد شناسایی شدند (قبلاً ۸ از ۱۲)
//   سه معامله‌ای که قبلاً کاملاً miss می‌شدند حالا Yellow می‌شوند
//
// 🔧 تغییر امضای تابع:
//   قدیم: UpdateCrisisLight(int rc, double flowScore, double adxVal)
//   جدید: UpdateCrisisLight(int rc, double flowScore, double adxVal,
//                           double trendScore, bool forBuy)
//   → trendScore از g_csvScore گرفته می‌شود (بدون هیچ حافظه‌ای)
//   → forBuy از جهت پوزیشن فعال تعیین می‌شود
//   → کاملاً stateless: هر بار محاسبه تازه، هیچ تاریخچه‌ای لازم نیست
// ═══════════════════════════════════════════════════════════════════
// v8.2 CHANGELOG (base: v8.1)  — طرح نهایی پس از بکتست کامل
// ─────────────────────────────────────────────────────────────────
// ❌ حذف شد: چراغ FINAL (با تمام منطق g_finalRiskScore، g_perTradeScore)
//    دلیل: ساختار تجمعی، در بکتست همیشه Yes بود و گمراه‌کننده بود
// ❌ حذف شد: چراغ GOLDEN و SURGE
//    دلیل: منطقشان در یک چراغ جدید CRISIS ادغام شد
//
// ✅ اضافه شد: چراغ CRISIS — تنها سیگنال خروج اضطراری
//    موقعیت: بالا-چپ، زیر برچسب سود/زیان، فونت بزرگ
//    منطق (کاملاً لحظه‌ای، بدون تاریخچه):
//      🟢 سبز:  RedCount <= 1
//      🟡 زرد:  RedCount == 2  یا  (Flow <= -5.0 و ADX > 28)
//      🔴 قرمز: RedCount >= 3  و   Flow <= -7.0  و  ADX_H4 > 32
//    ریشه قرمز: دقیقاً همان GoldenRule که هر دو وایپ‌اوت بکتست را گرفت
//
// ✅ CSV پاک‌سازی شد: ستون‌های PerTradeScore, PerTradeLight,
//    FinalScore, FinalLight, GoldenRule, GoldenSurge حذف؛
//    جایگزین: ستون CrisisState (Green/Yellow/Red)
// ═══════════════════════════════════════════════════════════════════
// v8.1 CHANGELOG (base: v8.0)  — تحلیل ۶۳۴ معامله AUDCAD ژانویه-آگوست ۲۰۲۵
// ─────────────────────────────────────────────────────────────────
// 🔴 GOLDEN اصلاح شد (مهم‌ترین تغییر):
//   قبلی:  RC>=3 AND Flow<=-7 AND ADX>40   → در وایپ‌اوت مارس، ساعت ۲۶ فعال می‌شد
//   جدید:  RC>=3 AND Flow<=-7 AND ADX>32   → ساعت ۱۸ فعال می‌شود (۸ ساعت زودتر!)
//   دلیل: از بکتست دیدیم ADX در وایپ‌اوت به ۳۲.۲ رسیده بود اما شرط قبلی ۴۰ بود.
//   فرکانس BUY: ۱۲→۱۹ | SELL: ۱۸→۳۱  (هنوز خیلی نادر = خوب)
//
// 🟡 SURGE اضافه شد (شرط زرد GOLDEN بهبود یافت):
//   قبلی: فقط RC>=3 AND (Flow<=-5 OR ADX>35)
//   جدید: RC>=3 AND (Flow<=-5 OR ADX>35)
//         OR (ADX>36 AND ER_H4>0.35 AND Flow<=-5)   ← الگوی «ترند داره قوی می‌شه»
//   دلیل: SURGE الگوی خاصی رو می‌گیره: ADX داره بالا میره + ER نشون می‌ده
//          جهتداره + Flow خلافه. در وایپ‌اوت این الگو ساعت ۷ ظاهر شد.
//
// 🔧 FIX بکتست FINAL (مهم‌ترین باگ):
//   مشکل: g_finalRiskScore از ابتدای بکتست جمع می‌شد و هیچوقت ریست نمی‌شد.
//          نتیجه: بعد از روز ۳ ژانویه، FinalLight همیشه Yes بود (بی‌معنی)
//   راه‌حل: اضافه شد g_perTradeScore که هر بار همه چراغ‌ها سبز بشن ریست می‌شه.
//   CSV حالا دو ستون داره:
//     PerTradeScore : امتیاز از آخرین دوره آرامش (قابل مقایسه بین معاملات)
//     PerTradeLight : Yes/No بر اساس PerTradeScore>=600 (آستانه اصلی)
//   FINAL قدیمی هم هست اما فقط برای مقایسه.
//
// ═══════════════════════════════════════════════════════════════════
// v8.0 CHANGELOG (base: v7.2)
// ─────────────────────────────────────────────────────────────────
// 🏆 FIX: باگ FLOW اصلاح شد
//   مشکل: آستانه قرمز FLOW روی fs < -0.5 بود → ۵۴٪ وقت قرمز!
//   اصلاح: آستانه‌های جدید واقع‌بینانه:
//     🟢 سبز:  fs >  3.0  (جریان موافق - مثل قبل)
//     🟡 زرد:  fs >= -5.0  (مختلط یا ضعیف)
//     🔴 قرمز: fs < -5.0  (سونامی واقعی ≈ ۴+ زوج خواهر علیه ما)
//
// 🏆 NEW: چراغ GOLDEN - فرمول طلایی پله ۵
// 🔧 FIX: آستانه FINAL از ۶۰۰ به ۲۰۰۰ تغییر کرد
// ═══════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════
// v7.2 CHANGELOG  (base: v7.1)
// ─────────────────────────────────────────────────────────────────
// 🔴 FIX: منطق چراغ RTM برای حالت Counter-Trend بازنویسی شد
//   مشکل قبلی: وقتی RTM_Type=CT (قیمت دارد از EMA دور می‌شود خلاف
//   پوزیشن Xmoon) چراغ YELLOW می‌شد — در حالی که این خطرناک‌ترین
//   حالت ممکن است و باید RED باشد.
//   کشف از تحلیل بکتست یک‌ساله AUDCAD:
//     CT + not-returning: 100% معاملات فاجعه‌بار (TrendScore<-60)
//     WT: از 996 معامله فقط 1 فاجعه‌بار بود
//   منطق جدید CT:
//     🟢 سبز : d0 >= 3.5x ATR  AND  Arrow=Down (کشیده + در حال برگشت)
//     🔴 قرمز: d0 >= 1.5x ATR  AND  Arrow≠Down  (CT+دور شدن یا ثابت)
//     🟡 زرد : بقیه حالات (نزدیک mean یا CT اما در حال برگشت)
//   نتیجه: بکتست ۱۷ رویداد ۴-قرمز برای BUY، ۱۹ برای SELL (قبلاً صفر)
// ─────────────────────────────────────────────────────────────────
// 📊 FIX: خروجی CSV بکتست بهبود یافت
//   - حذف ستون Ichimoku (همیشه N/A بود)
//   - مخفف‌ها به کلمات کامل تبدیل شدند (R→Red, Y→Yellow, G→Green,
//     CT→Counter-Trend, WT→With-Trend, DN→Down, UP→Up, FL→Flat,
//     TRD→Trending, mod→Moderate, rng→Ranging, Tok/Lon→Tokyo-London,
//     Lon/NY→London-NewYork, NewYork→New York)
//   - ستون RTM_Type اضافه ماند تا CT/WT قابل فیلتر باشد
// ─────────────────────────────────────────────────────────────────
// 🔧 FIX: تشخیص حساب سنت — DetectCentAccount() با ۳ لایه اولویت:
//   ۱) IsCentAccount input (override دستی)
//   ۲) ACCOUNT_CURRENCY — USC / CENT / پسوند C چهارکاراکتری
//   ۳) SYMBOL_TRADE_CONTRACT_SIZE — Cent≤1000 vs Standard=100000
// ✅ تأیید: UpdateLiquidationLine با TICK_VALUE/TICK_SIZE از v7.0
//    صحیح است — تغییر نداد (cross-pair + multi-symbol OK)
// ═══════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════
// v7.0 CHANGELOG  (base: v6.0)
// ─────────────────────────────────────────────────────────────────
// 🚦 TRAFFIC LIGHTS (چراغ‌های هشدار سریع - مستقل از TF جاری):
//   سه چراغ بالا-چپ زیر ProfitLabel - فقط وقتی پوزیشن باز است
//   رنگ می‌گیرند؛ در غیر این صورت خاکستری هستند.
//   • RTM  : فاصله قیمت از EMA200 روی H1 (ثابت) + جهت حرکت
//            سبز = کشیده‌شده و در حال برگشت | زرد = متوسط
//            قرمز = طرف اشتباه یا شتاب دور‌شدن
//   • ADX  : قدرت روند روی H4 (ثابت) + جهت DI در مقابل پوزیشن
//            سبز = روند ضعیف/موافق | زرد = روند متوسط
//            قرمز = روند قوی و رو به قوت‌گیری خلاف پوزیشن
//   • STRUCT: یکپارچگی ساختار D1 - آیا swing Low/High شکسته؟
//            سبز = ساختار سالم | زرد = نزدیک لبه
//            قرمز = سطح D1 شکسته → ریسک ادامه زیاد
//
// 📐 S/R LEVELS (همیشه بر اساس D1، مستقل از TF جاری):
//   منطق: سطوح روزانه بنیادی‌ترین سطوح برای تصمیم Xmoon هستند
//   swingها از D1 گرفته می‌شوند، clusterThreshold از ATR_D1
//   تایم‌فریم چارت تأثیری روی محاسبه S/R ندارد
//
// v6.0 CHANGELOG (see code history)
// ─────────────────────────────────────────────────────────────────
// NEW FILTERS (دکمه‌های ردیف سوم):
//   FVG    : Fair Value Gap / Imbalance - نواحی نقدینگی پر‌نشده
//   LiqSwp : Liquidity Sweep - شکار استاپ + برگشت (ICT/SMC)
//   RTM    : Return to Mean  - فاصله از EMA200 + هشدار Xmoon
//
// ENHANCEMENTS:
//   VolPro : Smart Volume → Vol Pro (scoring +1/+2 برای momentum)
//   Gate   : RTM Distance به Gate Monitor اضافه شد
//   UI     : ردیف سوم دکمه‌های AI (FVG, LiqSwp, RTM) + DPI-safe
//   Score  : MA Cross: v5.x=+2 → v6.0=+2 (ثابت) | FVG/Swp/RTM جدید
//
// XMOON INTEGRATION:
//   RTM >= DangerATR (پیش‌فرض 3.5x) → "DANGER: Mean Reversion ⚠️"
//   LiqSwp تازه (≤3 کندل) → برگشت قوی محتمل → TP منتظر بمان
//   FVG خلاف معامله → احتمال fill قبل از TP → زود ببند
// ═══════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════
// EA به جای Indicator - WebRequest در Indicator مجاز نیست در MT5
// تمام عملکردها یکسان است؛ فلش‌ها به عنوان Chart Object رسم می‌شوند
// ═══════════════════════════════════════════════════════════════════
#define HELPME_ARROW_PREFIX "HMArr_"


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
input int      DashboardXOffset  = 300; // ↔️ فاصله افقی داشبورد (پیکسل) | Horizontal Offset
input int      DashboardYOffset  = 50;  // ↕️ فاصله عمودی داشبورد (پیکسل) | Vertical Offset
input int      ButtonsXOffset    = -200;// ↔️ فاصله افقی دکمه‌ها (نسبت به پنل) | Buttons Horizontal
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
input double   LiquidLeverage      = 1000.0; // اهرم حساب (اگر از ای پی آی دریافت نشود) | Fallback Leverage
input double   LiquidStopOutPct    = 20.0;   // درصد  استاپ اوت بروکر (معمولاً ۲۰٪) | Broker Stop-Out
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
input bool   Alert_MT5Push           = true;   // اعلان فوری روی موبایل | MT5 Mobile Push
input bool   Alert_Telegram          = true;   // ارسال پیام به تلگرام | Telegram BotAlert
string Alert_TelegramToken     = "8801659037:AAE9qpYC_yMgg1iQcksd2gYJ-diyWLDhn0w";  // (ثابت داخلی — از Inputs حذف شد)
input string Alert_TelegramChatID    = "97992765"; // شناسه چت (برای کانال با - شروع می‌شود) | Chat ID/Channel ID
input bool   Alert_Eitaa             = false;  // ارسال پیام به ربات ایتا | Eitaa Bot Alert 
input string Alert_EitaaToken        = "97864663566EITAATOKEN"; // (BotFather از) توکن ربات ایتا | Eitaa Bot Tooken
input string Alert_EitaaChatID       = "97864663566EITAACHAT"; // 💬 شناسه چت ایتا | Eitaa Chat ID
// ─── کدام چراغ‌ها اعلان بدهند ───────────────────────────────────
input bool   Alert_OnCrisis          = true;   // 🚨 اعلان CRISIS فقط قرمز | Alert on CRISIS Red only
input bool   Alert_OnZombie          = true;   // 🧟 ZOMBIE اعلان قرمز  | Alert on ZOMBIE Red
input bool   Alert_OnHighAlert       = true;   // ⚠️ HIGH ALERT اعلان قرمز  | Alert on HIGH ALERT
input bool   Alert_OnFlow            = false;   // 🌊 FLOW اعلان قرمز  | Alert on FLOW Red
input bool   Alert_OnADX             = false;   // 📈 ADX اعلان قرمز  | Alert on ADX Red
input bool   Alert_OnRTM             = false;   // 📉 RTM اعلان قرمز  | Alert on RTM Red
input bool   Alert_OnStruct          = false;   // 🏗️ STRUCT اعلان قرمز  | Alert on STRUCT Redd
input bool   Alert_OnThreeLights     = true;   // 🔴🔴🔴 اعلان وقتی ۳ چراغ از ۴ همزمان قرمز (ADX/RTM/STRUCT/FLOW) |
// ─── کنترل تکرار اعلان ───────────────────────────────────────────
// نکته: Cooldown فقط جلوی ارسال مجدد در حالت "هنوز قرمز" را می‌گیرد
// اگر چراغ قرمز→زرد→قرمز شود (edge جدید) پیام ارسال می‌شود حتی زیر Cooldown
input int    Alert_CooldownMinutes   = 60;     // ⏱️ حداقل فاصله بین دو اعلان قرمز (دقیقه) | Cooldown Minutes


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
void DrawNewsLines();
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

datetime g_lastAlertTime_RTM     = 0;
datetime g_lastAlertTime_Trend   = 0;
datetime g_lastAlertTime_Struct  = 0;
datetime g_lastAlertTime_FLOW    = 0;
datetime g_lastAlertTime_ZOMBIE  = 0;
datetime g_lastAlertTime_Crisis  = 0;
datetime g_lastAlertTime_HighAlt = 0;
datetime g_lastAlertTime_3Lights = 0;   // v11.2: سه چراغ همزمان
bool     g_prev3LightsAlert      = false; // آیا قبلاً ۳ چراغ فعال بود

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
   int      stCRISIS;
   double   rtmX;
   string   rtmArrow;
   double   adxVal;
   double   erH4;
   double   flowScore;
   double   trendScore;
   int      zombieZone;  // v10.4+: طبقه مطلق از گرید قیمتی
   // zombieWidthPips حذف شد v10.5
   string   d1Status;
   string   regime;
   string   session;
   int      spreadPt;
   bool     highAlert;      // v11.8: وضعیت HIGH ALERT (ADX≥40 AND Flow خلاف)
};
HourlySnapshot g_hourlyLog[];
int            g_hourlyCount    = 0;
int            g_lastLoggedHour = -1;


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

// ─── GBPNZD: Buy = GBP↑  NZD↓   (GBP نیمه‌امن، NZD ریسکی، max ≈ 8.5) ─
// ⚠️ نکته کلیدی مهم: این جفت از Risk-OFF سود می‌برد (برعکس AUDCAD)!
// Risk-Off → NZD بیشتر از GBP می‌افتد → GBPNZD بالا می‌رود
// بنابراین USDJPY صعودی (Risk-On) برای Buy GBPNZD BAD است → signForBuy=-1
SisterEntry SISTER_GBPNZD[6] = {
   {"GBPUSD", 2.0,  +1, 1.00},  // قدرت مطلق GBP (مستقیم‌ترین سیگنال)
   {"NZDUSD", 1.5,  -1, 1.25},  // ضعف NZD: نزولی = خوب، اما صعودی خطرناک‌تر
   {"AUDNZD", 1.5,  +1, 1.00},  // ضعف NZD در برابر هم‌گروه AUD
   {"GBPCAD", 1.5,  +1, 1.00},  // GBP قوی در برابر ارز کالایی
   {"GBPAUD", 1.0,  +1, 1.00},  // GBP در برابر ریسکی‌های اصلی
   {"USDJPY", 1.0,  -1, 1.00},  // ⚠️ Risk-On → NZD از GBP پیشی می‌گیرد → بد
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
// 🆕 v11.7: هنگام Remove، هیچ رویداد/تیک/تایمری نباید لیبل‌ها را دوباره بسازد
bool     g_isDeinitializing      = false;
// 🆕 v7.0: جلوگیری از اجرای هم‌زمان ForceRecalculation (کلیک‌های تند + پینگ بالا)
bool     g_recalcBusy            = false;
datetime g_recalcBusySince        = 0;    // v11.2: زمان شروع ForceRecalculation برای auto-release
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
      if(PositionGetSymbol(i) == symbol)
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
   static int s_prevBuyCnt  = -99;
   static int s_prevSellCnt = -99;
   if(buy_count != s_prevBuyCnt || sell_count != s_prevSellCnt)
   {
      s_prevBuyCnt  = buy_count;
      s_prevSellCnt = sell_count;
      TL_Update();  // فراخوانی فوری - lightweight (فقط CopyBuffer چند handle)

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
      if(PositionGetSymbol(i) == symbol)
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
   int vote_total    = 0;  // نگه داشته شده برای سازگاری داخلی (استفاده نمی‌شود)
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
            // chart_bg_color از gradient محاسبه شده باقی می‌ماند
           }
         else
           {
            status_text = "ALARM (No Pos)";
            label_bg = (absScore < 30) ? C'40,0,0' :
                       (absScore < 60) ? C'70,0,0' : C'100,0,0';
            chart_bg_color = label_bg;
           }
        }
     }
   else
     {
      bool aligned = (isBull && pos_type == POSITION_TYPE_BUY) ||
                     (!isBull && pos_type == POSITION_TYPE_SELL);

      if(absScore < 10)
        {
         status_text = "NEUTRAL";
         label_bg    = clrBlack;
        }
      else if(aligned)
        {
         status_text = "SAFE";
        }
      else
        {
         status_text = "ALARM";
         label_bg = (absScore < 30) ? C'40,0,0' :
                    (absScore < 60) ? C'70,0,0' : C'100,0,0';
         chart_bg_color = (absScore < 30) ? C'40,0,0' :
                          (absScore < 60) ? C'70,0,0' : C'100,0,0';
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
   // برچسب وضعیت (بالا-راست)
   // ──────────────────────────────────────────────
   if(ObjectFind(chart_id, "StatusLabel") < 0)
      ObjectCreate(chart_id, "StatusLabel", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_CORNER,    CORNER_RIGHT_UPPER);
   ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_XDISTANCE, CSL_GetStatusXDist());
   ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_YDISTANCE, CSL_GetStatusYDist());
   ObjectSetString(chart_id,  "StatusLabel", OBJPROP_TEXT,      label_text);
   ObjectSetString(chart_id,  "StatusLabel", OBJPROP_FONT,      "Arial Bold");
   ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_FONTSIZE,  CSL_GetStatusFontSize());
   ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_COLOR,     clrWhite);
   ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_BGCOLOR,   label_bg);
   ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_BACK,      true);
   ObjectSetInteger(chart_id, "StatusLabel", OBJPROP_SELECTABLE,false);

   // برچسب پروفیت (بالا-چپ) – فقط اگر پوزیشن باز باشد – فونت 13
   if(buy_count > 0 || sell_count > 0)
     {
      string profit_text = StringFormat("Total P/L: %+.2f $", total_profit_dollar);
      color profit_color = (total_profit_dollar > 0) ? clrLime : (total_profit_dollar < 0 ? clrRed : clrWhite);

      if(ObjectFind(chart_id, "ProfitLabel") < 0)
         ObjectCreate(chart_id, "ProfitLabel", OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_YDISTANCE, 20);
      ObjectSetString(chart_id,  "ProfitLabel", OBJPROP_TEXT, profit_text);
      ObjectSetString(chart_id,  "ProfitLabel", OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_FONTSIZE, 13);
      ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_COLOR, profit_color);
      ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_BACK, false);
      ObjectSetInteger(chart_id, "ProfitLabel", OBJPROP_SELECTABLE, false);
     }

   // 🆕 v7.0: آپدیت چراغ‌ها در هر bar جدید (محاسبه کامل)
   TL_Update();

   // 🆕 v7.2: آپدیت چراغ FINAL (هر ۱۵ دقیقه - داخل تابع چک میشه)
   // v8.2: UpdateFinalRiskScore حذف شد — CRISIS جایگزین است

   // کش Score و Status برای CSV بکتست
   g_csvScore  = trend_score;
   g_csvStatus = (pos_type == -1) ? "NoPos" : status_text;

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
      Print("📐 ZoneLines v10.7: base=", DoubleToString(basePrice, _Digits),
            " | Width=", wPips, "pip | EntryZone=", entryZone, " | ±", maxZones);
}


int OnInit()
{
   if(EnableAllLogs) Print("🚀 HelpMe v7.0 - Initializing...");

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
      Print("✅ HelpMe v7.0 initialized!");
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
   else Print("✅ v7.0: Traffic Light handles OK (H1/H4/D1 fixed TF)");

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
      Print("✅ HelpMe v7.0 / News Subsystem initialized - Monitoring ", _Symbol);
      Print("📊 Fetched ", g_newsCount, " news events");
      Print("⚙️ MinWeightThreshold: ", MinWeightThreshold);
      // v7.1: دیباگ تشخیص حساب سنت — در Expert tab چاپ میشه
      string _dbgCur = AccountInfoString(ACCOUNT_CURRENCY);
      string _dbgSrv = AccountInfoString(ACCOUNT_SERVER);
      double _dbgCS  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      bool   _dbgCent = DetectCentAccount();
      Print("✅ HelpMe v7.1 Ready!");
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

   // --- v11.1 FIX: رسم فلش‌های تاریخی و "Now" از همان ابتدا
   // قبلاً اکسپرت ۳۰ ثانیه صبر می‌کرد تا اولین OnTimer اجرا شود
   // حالا بلافاصله در OnInit محاسبه می‌کند — بدون نیاز به Reset
   g_ratesTotal = Bars(_Symbol, PERIOD_CURRENT);
   if(g_ratesTotal >= 2)
   {
      ForceRecalculation();
      if(EnableAllLogs) Print("✅ v11.1: Initial ForceRecalculation done on init");
   }
   UpdateDashboard();   // Now / ساعت / سشن را فوری نمایش بده

   return(INIT_SUCCEEDED);
}


void OnTimer()
{
   if(g_isDeinitializing) return;

   // ══════════════════════════════════════════════════════════════
   // تایمر 1 ثانیه‌ای - سه سطح بروزرسانی:
   //   هر 1 ثانیه  : Liquid Level (وقتی نماد دیگری هم پوزیشن دارد)
   //   هر 30 ثانیه : آخر هفته (داشبورد)، TL_Update
   //   هر 4 ساعت   : بررسی اخبار
   // ══════════════════════════════════════════════════════════════
   static int  s_tick30         = 0;   // شمارنده برای 30 ثانیه
   // 🔧 FIX v7.1: به جای bool (فقط یک‌بار) از retry counter استفاده می‌کنیم
   // دلیل: اگه اولین ForceRecalculation در آخر هفته ناموفق بود (بافر اندیکاتورها
   // هنوز آماده نبودن → g_cacheSize=0)، دیگه هرگز سیگنال‌های گذشته نمایش داده
   // نمی‌شدند. الان تا 10 بار (هر 30 ثانیه یک‌بار = حداکثر 5 دقیقه) retry میکنه
   // تا زمانی که g_cacheSize نشون بده داده واقعاً لود شده.
   static int  s_weekendRetries = 0; // 0..9 = هنوز تلاش می‌کنه | 10 = موفق شد

   // ── هر 1 ثانیه: Liquid Level با پوزیشن نماد دیگر ─────────────
   // وقتی equity از نماد دیگری تغییر می‌کند، باید لحظه‌ای بروز شود
   if(g_liquidActive && g_otherPosCount_lq > 0)
      UpdateLiquidationLine();

   // ── هر 30 ثانیه ───────────────────────────────────────────────
   s_tick30++;
   if(s_tick30 < 30) return;
   s_tick30 = 0;

   // v11.1 FIX: ریست خودکار mutex‌ها هر ۳۰ ثانیه
   // مشکل قبلی: اگه کلیک سریع یا کرش رخ می‌داد، g_recalcBusy/g_processingChartEvent
   // قفل می‌ماندند و هیچ دکمه‌ای (فیلتر/EMA/...) جواب نمی‌داد تا Reset بزنند
   g_recalcBusy           = false;
   g_processingChartEvent = false;

   // بررسی اخبار هر 4 ساعت
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
      // هر 60 ثانیه (۲ چرخه ۳۰ثانیه‌ای) در روزهای کاری هم سشن آپدیت می‌شود
      // تا ساعت محلی نمایش‌داده‌شده در "Now" تازه بماند
      static int s_sessionRefreshTick = 0;
      s_sessionRefreshTick++;
      if(s_sessionRefreshTick >= 2)
      {
         s_sessionRefreshTick = 0;
         UpdateDashboard();
      }
   }

   // هر 30 ثانیه چراغ‌ها آپدیت میشن
   TL_Update();
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
      Print("⚠️ v11.7 hard-delete failed: ", obj_name, " err=", GetLastError());
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
   // handleATR_D1_200 حذف شد v10.5
   // حذف اشیاء چراغ‌ها
   ObjectsDeleteAll(0, LIGHT_OBJ_PREFIX);   // چراغ‌های قدیمی (اگه باشن)
   HM_DeleteObjectHard(0, CRISIS_OBJ);       // چراغ CRISIS (v8.2)
   ObjectsDeleteAll(0, dashboardPrefix);      // تمام اشیاء داشبورد (labels, buttons, TL)

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
      if(EnableAllLogs) Print("🗑️ HelpMe v11.6: Saved states cleared on remove");
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
         Print("🧹 HelpMe v11.7 OnDeinit hard-sweep: ", _totalSwept, " stray objects removed/blanked");
   }

   // FIX v7.0: ChartRedraw آخرین خط - بعد از تمام حذف‌ها
   // MT5 بعد از OnDeinit ممکنه state قبل از آخرین ChartRedraw رو نشون بده
   ChartRedraw(0);
}

void OnTick()
{
   if(g_isDeinitializing) return;

   // ── EA equivalent of OnCalculate ────────────────────────────────
   int rates_total    = Bars(_Symbol, PERIOD_CURRENT);
   int prev_calculated = g_prevCalculated;
   
   // FIX-1 v5.3: کاهش از 2 به 1 تا در آخر هفته هم (1 کندل) اجرا شود
   if(rates_total < 1) return;
   
   // Copy price data (newest first, index 0 = current bar)
   datetime time[];       ArraySetAsSeries(time,       true);
   double   open[];       ArraySetAsSeries(open,       true);
   double   high[];       ArraySetAsSeries(high,       true);
   double   low[];        ArraySetAsSeries(low,        true);
   double   close[];      ArraySetAsSeries(close,      true);
   long     tick_volume[];ArraySetAsSeries(tick_volume,true);
   
   // 📊 🔧 FIX v7.4: بر اساس g_maxHistoryBars (از HistoryBarsPercent)
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
   
   if(isNewBar)
   {
      lastBarTime = currentBarTime;
      // FIX #6: Time-based tracking - no index increment needed
      // lastBuyTime/lastSellTime store actual datetime, not bar index
      CSL_Execute();          // Full: trend calc + background color + profit (new bar only)
      DrawOrClearAllMAs(true); // آنتی‌فلیکر: فقط TFهایی که کندل جدید دارند redraw میشن
      // CPU: ER فقط روی کندل جدید کش می‌شود (نه هر ثانیه در UpdateDashboard)
      g_cachedER = CalculateEfficiencyRatio(RegimeCalculationBars);
   }
   else
   {
      CSL_UpdateProfitOnly(); // Lightweight: real-time profit P/L update (every tick)
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
   // Note: This is separate from the old News AI filter which was removed in v5.0
   if(prev_calculated == 0)
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

   g_prevCalculated = rates_total;
}


   

//+------------------------------------------------------------------+
//| CREATE SIGNAL ARROW (EA mode - replaces indicator buffers)       |
//+------------------------------------------------------------------+
void CreateSignalArrow(datetime barTime, double price, int arrowCode,
                       color arrowColor, int arrowWidth, string typeTag)
{
   string name = HELPME_ARROW_PREFIX + typeTag + "_" + IntegerToString((int)barTime);
   if(ObjectFind(0, name) >= 0) return;  // already exists
   ObjectCreate(0, name, OBJ_ARROW, 0, barTime, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR,     arrowColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,     arrowWidth);
   ObjectSetInteger(0, name, OBJPROP_BACK,      true);   // behind chart so dashboard stays on top
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE,false);
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
         int score = AnalyzeSignal(shift, time[shift], true, open[shift], high[shift], low[shift], close[shift]);
         if(ShowScoreInfo && score > 0 && shift == 1)
            Print("🔵 BUY Score: ", score, " | Regime: ", EnumToString(currentRegime.regime));

         if(score >= localRequiredScore)
         {
            // 🔧 FIX v7.5: فاصله از بدنه کندل (نه سایه) → همه فلش‌ها فاصله یکنواخت دارند
            double bodyBottom = MathMin(open[shift], close[shift]);
            double arrowY     = bodyBottom - arrowOffset;
            if(score >= 10)
               CreateSignalArrow(time[shift], arrowY, 233, clrGold,       3, "BS");
            else if(score >= 7)
               CreateSignalArrow(time[shift], arrowY, 233, clrLimeGreen,  2, "BM");
            else
               CreateSignalArrow(time[shift], arrowY, 233, clrLightGreen, 1, "BW");
            lastBuyTime = time[shift];
            if(TimeCurrent() - time[shift] < 604800) todaySignalCount++;
            if(EnableAlerts && shift == 1) Alert("🟢 BUY ", _Symbol, " | Score:", score);
         }
      }

      //--- SELL signal analysis
      if(isBearish)
      {
         int score = AnalyzeSignal(shift, time[shift], false, open[shift], high[shift], low[shift], close[shift]);
         if(ShowScoreInfo && score > 0 && shift == 1)
            Print("🔴 SELL Score: ", score, " | Regime: ", EnumToString(currentRegime.regime));

         if(score >= localRequiredScore)
         {
            // 🔧 FIX v7.5: فاصله از بدنه کندل (نه سایه) → همه فلش‌ها فاصله یکنواخت دارند
            double bodyTop = MathMax(open[shift], close[shift]);
            double arrowY  = bodyTop + arrowOffset;
            if(score >= 10)
               CreateSignalArrow(time[shift], arrowY, 234, clrDarkRed,    3, "SS");
            else if(score >= 7)
               CreateSignalArrow(time[shift], arrowY, 234, clrRed,        2, "SM");
            else
               CreateSignalArrow(time[shift], arrowY, 234, clrLightCoral, 1, "SW");
            lastSellTime = time[shift];
            if(TimeCurrent() - time[shift] < 604800) todaySignalCount++;
            if(EnableAlerts && shift == 1) Alert("🔴 SELL ", _Symbol, " | Score:", score);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 🆕 ANALYZE SIGNAL WITH AI ENHANCEMENTS                          |
//+------------------------------------------------------------------+
int AnalyzeSignal(int shift, datetime signalTime, bool forBuy, 
                  double o, double h, double l, double c)
{
   int score = 0;
   
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
            return 0;  // Hard block
         }
         if(!forBuy && !mtfTrend.h1Bearish)
         {
            if(ShowScoreInfo)
               if(EnableAllLogs) Print("⚠️ SELL rejected: H1 not bearish");
            return 0;  // Hard block
         }
         score += 3;  // Bonus for H1 confirmation
      }
      
      if(RequireH4Confirmation)
      {
         if(forBuy && mtfTrend.h4Bullish)
            score += 2;
         if(!forBuy && mtfTrend.h4Bearish)
            score += 2;
      }
   }
   
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
      }
      else if((forBuy  && isBullishPattern) ||
              (!forBuy && isBearishPattern))
      {
         // الگو موافق جهت سیگنال: +3 امتیاز
         if(ShowScoreInfo) Print("✅ Confirming pattern: ", EnumToString(pattern), " +3");
         score += 3;
      }
      else
      {
         // الگو مخالف جهت سیگنال: -2 جریمه
         if(ShowScoreInfo) Print("⚠️ Opposing pattern: ", EnumToString(pattern), " -2");
         score -= 2;
         
         // 🔴 STRICT: الگوی مخالف = بلاک سخت
         if(currentFilterMode == MODE_STRICT)
         {
            if(ShowScoreInfo) Print("🚫 STRICT Block: opposing candle pattern");
            return 0;
         }
      }
   }
   
   //--- 🆕 v4.0 AI FILTER #5: Fractal S/R Hard Block (STRICT mode only)
   // اگر حالت Strict باشد و قیمت خیلی نزدیک به آخرین فراکتال مقاومت/حمایت باشد، سیگنال بلافاصله مسدود شود
   if(currentFilterMode == MODE_STRICT)
   {
      if(IsTooCloseToFractal(shift, forBuy, c, atrv))
      {
         if(ShowScoreInfo && shift == 1)
            Print("🧱 STRICT Fractal Block: signal too close to S/R wall");
         return 0;  // Hard block - فضای کافی برای حرکت وجود ندارد
      }
   }
   
   //--- 🆕 v4.0 BONUS: Hidden RSI Divergence (BALANCED + STRICT)
   // اگر واگرایی پنهان شناسایی شد، امتیاز بونوس می‌گیرد
   if(currentFilterMode == MODE_BALANCED || currentFilterMode == MODE_STRICT)
   {
      score += CheckHiddenDivergence(shift, forBuy);
   }
   
   //--- 🆕 Apply Weights (always 1.0 — optimization weights removed)
   double maWeight  = 1.0;
   double rsiWeight = 1.0;
   double adxWeight = 1.0;
   double bbWeight  = 1.0;
   double atrWeight = 1.0;
   
   //--- MA Cross (weighted) - v7.0: وزن کم شد (نویز زیاد در AUDCAD/رنج‌ها)
   if(forBuy && fastMAv > slowMAv)
      score += (int)(1 * maWeight);   // قبلاً 2*maWeight
   else if(!forBuy && fastMAv < slowMAv)
      score += (int)(1 * maWeight);
   
   //--- RSI Filter (weighted)
   if(UseRSIFilter)
   {
      if(forBuy && rsiv > 40 && rsiv < 70)
         score += (int)(1 * rsiWeight);
      else if(!forBuy && rsiv > 30 && rsiv < 60)
         score += (int)(1 * rsiWeight);
   }
   
   //--- ADX Filter (weighted)
   if(UseADXFilter && adxv > MinADX)
      score += (int)(1 * adxWeight);
   
   //--- BB Filter (weighted)
   if(UseBBFilter)
   {
      if(forBuy && c < bbUpperv)
         score += (int)(1 * bbWeight);
      else if(!forBuy && c > bbLowerv)
         score += (int)(1 * bbWeight);
   }
   
   //--- ATR Intensity (weighted)
   if(UseATRIntensity && atrv > 0)
   {
      double bodySize = MathAbs(c - o);
      double bodyATRRatio = bodySize / atrv;
      
      if(bodyATRRatio >= 1.2)
         score += (int)(3 * atrWeight);
      else if(bodyATRRatio >= 1.0)
         score += (int)(2 * atrWeight);
      else if(bodyATRRatio >= localMinBodyToATRRatio)
         score += (int)(1 * atrWeight);
   }
   
   //--- Wick Filter
   if(UseWickFilter)
   {
      double bodySize = MathAbs(c - o);
      double totalSize = h - l;
      double bodyRatio = totalSize > 0 ? bodySize / totalSize : 0;
      
      if(bodyRatio >= 0.8)
         score += 2;
      else if(bodyRatio >= localMinBodyToTotalRatio)
         score += 1;
   }
   
   //--- 🆕 Market Regime Bonus/Penalty
   // 🔧 FIX v7.3: همسو با Fix C — per-bar ER برای امتیاز هم استفاده می‌شه
   if(localEnableMarketRegime)
   {
      // ER را دوباره محاسبه نمی‌کنیم — از shift و close[] که به تابع پاس داده شده استفاده می‌کنیم
      // (این تابع scoring مستقیماً به close[] و shift دسترسی ندارد، پس currentRegime را حفظ می‌کنیم)
      // currentRegime برای score bonus کافی است — فقط hard-block باید per-bar باشد
      if(currentRegime.regime == REGIME_TRENDING)
         score += 2;  // Bonus in trending market
      else if(currentRegime.regime == REGIME_VOLATILE)
         score -= 1;  // Penalty in volatile market
      // RANGING: قبلاً در RunSignalLoop block شده (per-bar ER) → اینجا نمی‌رسد
   }

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
            if(ShowScoreInfo) Print("☁️ Ichi: Above Cloud (BUY) +2");
         }
         else if(!forBuy && belowCloud)
         {
            score += 2;
            if(ShowScoreInfo) Print("☁️ Ichi: Below Cloud (SELL) +2");
         }
         else
         {
            // سیگنال خلاف جهت ابر یا داخل ابر
            score -= 1;
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
                  if(ShowScoreInfo) Print("💥 Ichi: Kumo Breakout +3");
               }
            }
         }

         // ── Tenkan/Kijun Cross هم‌جهت سیگنال ──
         if(tenkan > 0 && kijun > 0)
         {
            if(forBuy  && tenkan > kijun) { score += 1; if(ShowScoreInfo) Print("📈 Ichi: Tenkan>Kijun (BUY) +1"); }
            if(!forBuy && tenkan < kijun) { score += 1; if(ShowScoreInfo) Print("📉 Ichi: Tenkan<Kijun (SELL) +1"); }
         }
      }
      else
      {
         if(ShowDebugLogs && shift == 1)
            Print("⚠️ Ichi data not ready for shift=", shift);
      }
   }
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
            { score += 6; if(ShowScoreInfo) Print("📐 FVG: In Bullish Gap (BUY) +6 [v7:×3]"); }
         else if(nearBullFVG)
            { score += 3; if(ShowScoreInfo) Print("📐 FVG: Near Bullish Gap +3 [v7:×3]"); }

         if(inBearFVG)
         {
            score -= 3;
            if(ShowScoreInfo) Print("📐 FVG: In Bearish Gap (BUY risk) -3 [v7:×3]");
            if(currentFilterMode == MODE_STRICT)
               { if(ShowScoreInfo) Print("🚫 STRICT FVG Block: opposing gap"); return 0; }
         }
      }
      else  // SELL
      {
         if(inBearFVG)
            { score += 6; if(ShowScoreInfo) Print("📐 FVG: In Bearish Gap (SELL) +6 [v7:×3]"); }
         else if(nearBearFVG)
            { score += 3; if(ShowScoreInfo) Print("📐 FVG: Near Bearish Gap +3 [v7:×3]"); }

         if(inBullFVG)
         {
            score -= 3;
            if(ShowScoreInfo) Print("📐 FVG: In Bullish Gap (SELL risk) -3 [v7:×3]");
            if(currentFilterMode == MODE_STRICT)
               { if(ShowScoreInfo) Print("🚫 STRICT FVG Block: opposing gap"); return 0; }
         }
      }
   }
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
         if(ShowScoreInfo)
            Print("💧 LiqSwp: sweep ", swpAge, " bars ago → +", swpScore, " [v7:×3]");
      }
      else
      {
         // STRICT: بدون sweep در بازار غیر‌trending → سیگنال ضعیف‌تر است
         if(currentFilterMode == MODE_STRICT && currentRegime.regime != REGIME_TRENDING)
            { score -= 3; if(ShowScoreInfo) Print("💧 LiqSwp: no sweep (STRICT non-trend) -3 [v7:×3]"); }
      }
   }
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
               if(distATR >= 4.0) { score += 3; if(ShowScoreInfo) Print("🔄 RTM: BUY ", DoubleToString(distATR,1), "x ATR below mean +3 [HighRecovery]"); }
               else if(distATR >= 3.5) { score += 3; if(ShowScoreInfo) Print("🔄 RTM: BUY 3.5x ATR - DangerZone+HighRecovery +3"); }
               else if(distATR >= 3.0) { score += 2; if(ShowScoreInfo) Print("🔄 RTM: BUY 3x ATR below +2"); }
               else if(distATR >= 2.0) { score += 1; if(ShowScoreInfo) Print("🔄 RTM: BUY 2x ATR below +1"); }
            }
            else  // قیمت بالای EMA200 → BUY ادامه‌دهنده (خلاف RTM)
            {
               if(distATR >= 2.0) { score -= 1; if(ShowScoreInfo) Print("🔄 RTM: BUY above mean -1 (continuation risk)"); }
            }
         }
         else  // SELL
         {
            // سیگنال SELL: قیمت باید بالای EMA200 و در حال برگشت باشد
            if(above)  // قیمت بالای EMA200 → SELL هم‌جهت RTM
            {
               if(distATR >= 4.0) { score += 3; if(ShowScoreInfo) Print("🔄 RTM: SELL ", DoubleToString(distATR,1), "x ATR above mean +3 [HighRecovery]"); }
               else if(distATR >= 3.5) { score += 3; if(ShowScoreInfo) Print("🔄 RTM: SELL 3.5x ATR - DangerZone+HighRecovery +3"); }
               else if(distATR >= 3.0) { score += 2; if(ShowScoreInfo) Print("🔄 RTM: SELL 3x ATR above +2"); }
               else if(distATR >= 2.0) { score += 1; if(ShowScoreInfo) Print("🔄 RTM: SELL 2x ATR above +1"); }
            }
            else  // قیمت زیر EMA200 → SELL ادامه‌دهنده
            {
               if(distATR >= 2.0) { score -= 1; if(ShowScoreInfo) Print("🔄 RTM: SELL below mean -1 (continuation risk)"); }
            }
         }
      }
      else if(ShowDebugLogs && shift == 1)
         Print("⚠️ RTM EMA not ready (bars still loading)");
   }
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
            if(vRatio >= 1.8 && vRatio < 3.0) { score += 2; if(ShowScoreInfo) Print("📊 VolPro: expansion x", DoubleToString(vRatio,1), " +2"); }
            else if(vRatio >= 1.3)             { score += 1; if(ShowScoreInfo) Print("📊 VolPro: above avg x", DoubleToString(vRatio,1), " +1"); }
            // Volume climax (>3x average): احتمال exhaustion → بدون bonus
         }
      }
   }

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
string FlowFindSym(string base6)
{
   // ۱) بدون پسوند (بروکرهای استاندارد)
   if(SymbolInfoDouble(base6, SYMBOL_BID) > 0.0) return base6;

   // ۲) پسوند از سیمبل اصلی بگیر و امتحان کن
   if(StringLen(_Symbol) > 6)
   {
      string sfx       = StringSubstr(_Symbol, 6);
      string candidate = base6 + sfx;
      if(SymbolInfoDouble(candidate, SYMBOL_BID) > 0.0) return candidate;
   }

   // ۳) fallback: همان base6 برگردان؛ iClose خودش 0 برمی‌گرداند اگه نداشت
   return base6;
}

// محاسبه امتیاز Sister Matrix با H4 Momentum (5 کندل = 20 ساعت)
// کاملاً lightweight: فقط iClose روی H4 - هیچ handle اضافه‌ای ندارد
// forBuy: جهت پوزیشن فعال ما
double FlowEvaluate(SisterEntry &mat[], int sz, bool forBuy)
{
   double score = 0.0;

   for(int i = 0; i < sz; i++)
   {
      string sym = FlowFindSym(mat[i].sym);

      // اطمینان از وجود داده H4 کافی
      if(Bars(sym, PERIOD_H4) < 8) continue;

      // H4 Momentum: close[1] در مقابل close[6]  (گذشته ۲۰ ساعته)
      double c1 = iClose(sym, PERIOD_H4, 1);
      double c6 = iClose(sym, PERIOD_H4, 6);
      if(c1 <= 0.0 || c6 <= 0.0) continue;  // داده موجود نیست

      // جهت: +1 صعودی  -1 نزولی  0 بدون تغییر (skip)
      double dir = (c1 > c6) ? 1.0 : (c1 < c6) ? -1.0 : 0.0;
      if(dir == 0.0) continue;

      // اگه Sell داریم، علامت همه‌ی signForBuy برعکس می‌شود
      int    effSign   = forBuy ? mat[i].signForBuy : -mat[i].signForBuy;
      double rawSignal = effSign * dir;          // +1=تأیید  -1=تضاد
      double mult      = (rawSignal < 0.0) ? mat[i].negMult : 1.0;

      score += rawSignal * mat[i].weight * mult;
   }
   return score;   // raw score (v8.0: >3.0=سبز، >=-5.0=زرد، <-5.0=قرمز)
}

// رنگ چراغ بر اساس state (-1=خاکستری, 0=سبز, 1=زرد, 2=قرمز)
color TL_GetBgColor(int state)
{
   if(state == 0) return C'0,120,0';    // سبز تیره
   if(state == 1) return C'160,120,0';  // زرد تیره
   if(state == 2) return C'160,0,0';    // قرمز تیره
   return C'50,50,50';                  // خاکستری
}
color TL_GetTxColor(int state)
{
   if(state == -1) return clrGray;
   return clrWhite;
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

// ─── ارسال پیام به ایتا ──────────────────────────────────────────
// API ایتا: https://eitaa.com/BotAPI  — مشابه تلگرام
// برای فعال‌سازی: https://eitaa.com/BotAPI را به WebRequest اضافه کنید
void Alert_SendEitaa(const string message)
{
   if(!Alert_Eitaa) return;
   // v11.3: اگه token پیش‌فرض یا خالی باشه → silent skip
   if(StringLen(Alert_EitaaToken) < 5 || StringLen(Alert_EitaaChatID) < 2
      || StringFind(Alert_EitaaToken, "97864663566") >= 0)
      return;  // silent
   string enc = message;
   StringReplace(enc, " ", "%20"); StringReplace(enc, "\n", "%0A");
   StringReplace(enc, "!", "%21");
   string url = "https://eitaa.com/BotAPI/bot" + Alert_EitaaToken
              + "/sendMessage?chat_id=" + Alert_EitaaChatID + "&text=" + enc;
   char post[]; char result[]; string headers;
   ResetLastError();
   int res = WebRequest("GET", url, "HelpMe EA v11.2", NULL, 5000, post, 0, result, headers);
   if(ShowDebugLogs) Print(res==200 ? "✅ Eitaa OK" :
      "❌ Eitaa fail HTTP="+IntegerToString(res)+" Err="+IntegerToString(GetLastError()));
}

// ─── ارسال اعلان MT5 Push ────────────────────────────────────────
void Alert_SendPush(const string message)
{
   if(!Alert_MT5Push) return;
   SendNotification(message);
   if(ShowDebugLogs) Print("📱 MT5 Push: ", message);
}

// ─── ارسال اعلان به همه کانال‌های فعال ─────────────────────────
void Alert_Send(const string message)
{
   Alert_SendPush(message);
   Alert_SendTelegram(message);
   Alert_SendEitaa(message);
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
   if(Alert_OnCrisis)
   {
      bool nowAlert  = (g_crisisState == 2);   // فقط قرمز — نارنجی (3) اعلان نمی‌دهد
      bool prevAlert = (g_prevAlertCrisis == 2);
      bool isNewEdge = nowAlert && !prevAlert;
      if(nowAlert && Alert_CooldownOK(g_lastAlertTime_Crisis, isNewEdge))
      {
         string msg = head;
         if(g_crisisState == 2) msg += "چراغ CRISIS قرمز شد\nشک نکن و همین الان معامله رو ببند یا یه هیج تپل باز کن";
         else msg += "چراغ CRISIS زرد شد\nدقتت و بیشتر کن و زودتر به چارت سر بزن";
         msg += StringFormat("\nADX=%.1f | Flow=%.2f", g_lastAdxVal, g_lastFlowScore);
         Alert_Send(msg);
      }
      g_prevAlertCrisis = g_crisisState;
   }

   // ─── HIGH ALERT ──────────────────────────────────────────────
   if(Alert_OnHighAlert)
   {
      bool isNewEdge = highAlertActive && !g_prevAlertHighAlt;
      if(highAlertActive && Alert_CooldownOK(g_lastAlertTime_HighAlt, isNewEdge))
      {
         string msg = head + "چراغ HIGH ALERT قرمز شد\n"
            + StringFormat("ADX=%.1f | Flow=%.2f\n", g_lastAdxVal, g_lastFlowScore)
            + "بنظر اتفاقات بد داره میافته ، CRISIS سریع بررسی کن";
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
         Alert_Send(head + "چراغ ZOMBIE قرمز شد\nطبقه قیمتی عوض شده و معامله ات در خطر");
      }
      g_prevAlertZOMBIE = g_lightZOMBIE;
   }

   // ─── FLOW ────────────────────────────────────────────────────
   if(Alert_OnFlow)
   {
      bool isNewEdge = (g_lightFLOW == 2 && g_prevAlertFLOW != 2);
      if(g_lightFLOW == 2 && Alert_CooldownOK(g_lastAlertTime_FLOW, isNewEdge))
      {
         Alert_Send(head + "چراغ FLOW قرمز شد\n"
            + StringFormat("ببین Flow=%.2f - همه ارز های مرتبط دارن سونامی وار در جهت مخالف تو حرکت میکنن", g_lastFlowScore));
      }
      g_prevAlertFLOW = g_lightFLOW;
   }

   // ─── ADX ─────────────────────────────────────────────────────
   if(Alert_OnADX)
   {
      bool isNewEdge = (g_lightTrend == 2 && g_prevAlertTrend != 2);
      if(g_lightTrend == 2 && Alert_CooldownOK(g_lastAlertTime_Trend, isNewEdge))
      {
         Alert_Send(head + "چراغ ADX قرمز شد\n"
            + StringFormat("ببین ADX=%.1f - روند قویی خلاف جهت پوزیشن تو شکل گرفته", g_lastAdxVal));
      }
      g_prevAlertTrend = g_lightTrend;
   }

   // ─── RTM ─────────────────────────────────────────────────────
   if(Alert_OnRTM)
   {
      bool isNewEdge = (g_lightRTM == 2 && g_prevAlertRTM != 2);
      if(g_lightRTM == 2 && Alert_CooldownOK(g_lastAlertTime_RTM, isNewEdge))
      {
         Alert_Send(head + "چراغ RTM قرمز شد\nقیمت از میانگین خودش در جهت مخالف تو داره");
      }
      g_prevAlertRTM = g_lightRTM;
   }

   // ─── STRUCT ──────────────────────────────────────────────────
   if(Alert_OnStruct)
   {
      bool isNewEdge = (g_lightStruct == 2 && g_prevAlertStruct != 2);
      if(g_lightStruct == 2 && Alert_CooldownOK(g_lastAlertTime_Struct, isNewEdge))
      {
         Alert_Send(head + "چراغ STRUCT قرمز شد\nساختار روزانه D1 شکسته شد");
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
            + StringFormat("3 LIGHTS RED! (%d/4)\n", redCount4)
            + "قرمز: " + which + "\n"
            + StringFormat("ADX=%.1f | Flow=%.2f\n", g_lastAdxVal, g_lastFlowScore)
            + "وضعیت خطرناک CRISIS را بررسی کن");
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

   // TrendScore علیه پوزیشن: هرچه بالاتر، بازار بیشتر خلاف ما
   double tsAgainst = forBuy ? -trendScore : trendScore;

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
      // الگوی A (کلاسیک):
      (rc >= 3 && flowScore <= -7.0 && adxVal > 32.0)
      ||
      // الگوی B (فشار شدید — جدید v9.0):
      (rc >= 2 && flowScore <= -8.5 && adxVal > 40.0)
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
      if(rc >= 3 && flowScore <= -7.0 && adxVal > 32.0)
         activePattern = StringFormat(
            "🔴 الگوی A (کلاسیک):\n"
            "   ✅ RedCount=%d (≥3)\n"
            "   ✅ Flow=%.1f (≤-7.0)\n"
            "   ✅ ADX=%.1f (>32)",
            rc, flowScore, adxVal);
      else
         activePattern = StringFormat(
            "🔴 الگوی B (فشار شدید):\n"
            "   ✅ RedCount=%d (≥2)\n"
            "   ✅ Flow=%.1f (≤-8.5) ← سونامی!\n"
            "   ✅ ADX=%.1f (>40) ← روند خیلی قوی!",
            rc, flowScore, adxVal);

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
      // Orange-A: RC>=2 + Flow خیلی منفی + ADX بالا (نزدیک به Red-A)
      (rc >= 2 && flowScore <= -6.5 && adxVal > 30.0)
      ||
      // Orange-B: RC>=3 + TrendScore قوی علیه ما + ADX متوسط
      (rc >= 3 && tsAgainst > 40.0 && adxVal > 28.0)
      ||
      // Orange-C: RC>=2 + Flow شدید + روند قوی علیه (مثل Red-B اما ضعیف‌تر)
      (rc >= 2 && flowScore <= -7.5 && adxVal > 32.0 && tsAgainst > 25.0)
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

      txt = StringFormat("  ⬤ CRISIS: 🟠 EARLY WARN!%s ", persistOrange);

      string whyOrange = "";
      if(rc >= 2 && flowScore <= -6.5 && adxVal > 30.0)
         whyOrange += StringFormat("Orange-A: RC=%d + Flow=%.1f + ADX=%.1f\n", rc, flowScore, adxVal);
      if(rc >= 3 && tsAgainst > 40.0 && adxVal > 28.0)
         whyOrange += StringFormat("Orange-B: RC=%d + TsAgainst=%.1f + ADX=%.1f\n", rc, tsAgainst, adxVal);
      if(rc >= 2 && flowScore <= -7.5 && adxVal > 32.0 && tsAgainst > 25.0)
         whyOrange += StringFormat("Orange-C: RC=%d + Flow=%.1f + ADX=%.1f + TsAg=%.1f\n", rc, flowScore, adxVal, tsAgainst);

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
      // Y2 — کلاسیک: Flow+ADX هشداردهنده
      (flowScore <= -5.0 && adxVal > 28.0)
      ||
      // Y3 — جدید: RC=2 + Flow منفی + روند قوی علیه ما
      // این الگو معامله ۲۸ ژوئیه را می‌گیرد (RC=2, Flow=-7, TS=-45)
      (rc >= 2 && flowScore <= -7.0 && tsAgainst > 30.0)
      ||
      // Y4 — جدید: RC=2 + روند خیلی قوی علیه جهت پوزیشن
      // این الگو معامله ۱۴ مارس Short را می‌گیرد (TS=+46 علیه Short)
      (rc >= 2 && tsAgainst > 45.0 && adxVal > 25.0)
      ||
      // Y5 — جدید: RC=2 + Flow شدید + ADX قوی (زیر آستانه Red-B)
      // این الگو معامله ۶ مارس را زودتر Yellow می‌گیرد
      (rc >= 2 && flowScore <= -7.5 && adxVal > 35.0)
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
      if(flowScore <= -5.0 && adxVal > 28.0)
         whyYellow += StringFormat("Y2: Flow=%.1f + ADX=%.1f\n", flowScore, adxVal);
      if(rc >= 2 && flowScore <= -7.0 && tsAgainst > 30.0)
         whyYellow += StringFormat("Y3: Flow=%.1f + TsAgainst=%.1f (روند علیه ما)\n", flowScore, tsAgainst);
      if(rc >= 2 && tsAgainst > 45.0 && adxVal > 25.0)
         whyYellow += StringFormat("Y4: TsAgainst=%.1f + ADX=%.1f (واگرایی جهت)\n", tsAgainst, adxVal);
      if(rc >= 2 && flowScore <= -7.5 && adxVal > 35.0)
         whyYellow += StringFormat("Y5: Flow=%.1f + ADX=%.1f (نزدیک Red-B)\n", flowScore, adxVal);

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

   // ── ساخت یا آپدیت شیء CRISIS روی چارت ────────────────────────
   if(ObjectFind(chart_id, CRISIS_OBJ) < 0)
   {
      ObjectCreate(chart_id, CRISIS_OBJ, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(chart_id, CRISIS_OBJ, OBJPROP_CORNER,    CORNER_LEFT_UPPER);
      ObjectSetInteger(chart_id, CRISIS_OBJ, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(chart_id, CRISIS_OBJ, OBJPROP_YDISTANCE, 50);
      ObjectSetString (chart_id, CRISIS_OBJ, OBJPROP_FONT,      "Arial Bold");
      ObjectSetInteger(chart_id, CRISIS_OBJ, OBJPROP_FONTSIZE,  13);  // v11.92: دو ورژن کوچک‌تر (15→13)
      ObjectSetInteger(chart_id, CRISIS_OBJ, OBJPROP_BACK,      false);
      ObjectSetInteger(chart_id, CRISIS_OBJ, OBJPROP_SELECTABLE,false);
   }
   ObjectSetString (chart_id, CRISIS_OBJ, OBJPROP_TEXT,    txt);
   ObjectSetInteger(chart_id, CRISIS_OBJ, OBJPROP_COLOR,   txt_col);
   ObjectSetString (chart_id, CRISIS_OBJ, OBJPROP_TOOLTIP, tip);
}

// ════════════════════════════════════════════════════════════════════
void TL_SetLight(string id, int state, string txt, string tooltip)
{
   // v11.0: HIGH ALERT = قرمز چشمک‌زن — همیشه جلب توجه کند
   color txC;
   if(id == "HIGHALT" && state == 2)
      txC = clrRed;      // پررنگ‌ترین قرمز برای ⚠️ HIGH
   else
      txC = (state == 0) ? clrLime  :
            (state == 1) ? clrGold  :
            (state == 2) ? clrRed   :
            clrDimGray;

   string nm = dashboardPrefix + "TL_" + id;
   if(ObjectFind(0, nm) >= 0)
   {
      ObjectSetString (0, nm, OBJPROP_TEXT,    txt);
      ObjectSetInteger(0, nm, OBJPROP_COLOR,   txC);
      ObjectSetString (0, nm, OBJPROP_TOOLTIP, tooltip);
   }
}

// ایجاد/ریست اولیه چراغ‌ها (labels توسط CreateDashboard ساخته می‌شوند)
void TL_Create()
{
   if(g_isDeinitializing) return;

   TL_SetLight("RTM",    -1, "● RTM: --      ", "بدون پوزیشن فعال");
   TL_SetLight("TREND",  -1, "● ADX: --      ", "بدون پوزیشن فعال");
   TL_SetLight("STRUCT", -1, "● D1:  --      ", "بدون پوزیشن فعال");
   TL_SetLight("FLOW",   -1, "● FLOW: --     ", "بدون پوزیشن فعال");
   TL_SetLight("ZOMBIE", -1, "● ZONE: --     ", "بدون پوزیشن فعال");
   TL_SetLight("HIGHALT",-1, "● ALERT: --    ", "HIGH ALERT: بدون پوزیشن فعال");  // v11.0
   UpdateCrisisLight(-1, 0.0, 0.0, 0.0, true);  // خاکستری - بدون پوزیشن
   ChartRedraw(0);
}

// محاسبه و بروزرسانی کامل سه چراغ
// فراخوانی: هر بار که پوزیشن تغییر کند یا هر 30 ثانیه (OnTimer)
void TL_Update()
{
   if(g_isDeinitializing) return;

   // 🆕 متغیرهای محلی برای snapshot CSV (با مقادیر پیش‌فرض ایمن)
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
   int buy_cnt = 0, sell_cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol)
      {
         long pt = PositionGetInteger(POSITION_TYPE);
         if(pt == POSITION_TYPE_BUY)  buy_cnt++;
         if(pt == POSITION_TYPE_SELL) sell_cnt++;
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
         UpdateCrisisLight(-1, 0.0, 0.0, 0.0, true);
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
   if(hasPos)
   {
      datetime oldestT  = (datetime)9223372036854775807; // LLONG_MAX
      double   oldestPx = 0.0;
      bool     wantBuy  = (buy_cnt >= sell_cnt);
      for(int _zi = PositionsTotal() - 1; _zi >= 0; _zi--)
      {
         if(PositionGetSymbol(_zi) == _Symbol)
         {
            long _pt = PositionGetInteger(POSITION_TYPE);
            bool _match = wantBuy ? (_pt == POSITION_TYPE_BUY) : (_pt == POSITION_TYPE_SELL);
            if(_match)
            {
               datetime _t = (datetime)PositionGetInteger(POSITION_TIME);
               if(_t < oldestT)
               {
                  oldestT  = _t;
                  oldestPx = PositionGetDouble(POSITION_PRICE_OPEN);
               }
            }
         }
      }
      if(oldestPx > 0.0)
      {
         // v10.4: پوزیشن جدید → طبقه ورود تازه ثبت شود
         if(MathAbs(oldestPx - g_zombieEntryPrice) > _Point * 10)
         {
            g_zombieEntryPrice = oldestPx;
            g_zombieEntryZone  = Zone_ComputeFromPrice(_Symbol, oldestPx);
            // v10.9: فیلتر H1 کاملاً stateless است — ریست نیازی نیست
         }
         else if(g_zombieEntryPrice <= 0.0)
         {
            g_zombieEntryPrice = oldestPx;
            g_zombieEntryZone  = Zone_ComputeFromPrice(_Symbol, oldestPx);
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
      if(g_lightRTM != -1 || g_lightTrend != -1 || g_lightStruct != -1 || g_lightFLOW != -1 || g_lightGOLDEN != -1)
      {
         g_lightRTM = g_lightTrend = g_lightStruct = g_lightFLOW = g_lightGOLDEN = g_lightZOMBIE = -1;
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
         TL_SetLight("ZOMBIE", -1, "● ZONE: --     ", "بدون پوزیشن فعال");
         TL_SetLight("HIGHALT",-1, "● ALERT: --    ", "HIGH ALERT: بدون پوزیشن فعال");  // v11.0
         UpdateCrisisLight(-1, 0.0, 0.0, 0.0, true);
         ChartRedraw(0);
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
            "ADX+ER - قدرت روند H4\n"
            "ADX: %.1f %s | +DI:%.1f | -DI:%.1f\n"
            "ER(14): %.2f → %s | روند: %s\n"
            "──────────\n"
            "ER<0.20=رنج  0.20-0.35=متوسط  >0.35=ترند\n"
            "CT→ سبز:ضعیف | زرد:متوسط | قرمز:قوی\n"
            "WT→ سبز:پشتیبان | زرد:ضعیف",
            adx, rArr, pDI, mDI, erH4, erLabel,
            !oppTrend ? "موافق" : "⚠️ خلاف");

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
               "پایین‌ترین Low D1 (10 کندل): %s\n"
               "قیمت فعلی H1: %s\n"
               "فاصله: %.0f pip | ATR_D1: %.0f pip\n"
               "──────────────────\n"
               "سبز: > 2×ATR دور از سطح\n"
               "زرد: ≤ 2×ATR (هشدار نزدیکی)\n"
               "قرمز: Low D1 شکسته!",
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
               "بالاترین High D1 (10 کندل): %s\n"
               "قیمت فعلی H1: %s\n"
               "فاصله: %.0f pip | ATR_D1: %.0f pip",
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
         if(fs > 3.0)        newFLOW = 0;   // سبز
         else if(fs >= -5.0) newFLOW = 1;   // زرد
         else                newFLOW = 2;   // قرمز (سونامی واقعی)

         string arrow = (fs > 0.5) ? "▲" : (fs < -0.5) ? "▼" : "→";
         flowTxt = StringFormat("● FLOW:%+.1f%s  ", fs, arrow);
         bt_flowScore = fs;   // 🆕 snapshot برای CSV
         g_lastFlowScore = fs; // 🆕 v8.0: برای GOLDEN rule

         string stDesc = (newFLOW == 0) ? "جریان پول موافق - صبر کن" :
                         (newFLOW == 1) ? "بازار دوگانه - آماده‌باش" :
                                          "⚠️ سونامی/Risk-Off - خطر!";
         flowTip = StringFormat(
            "FLOW - جریان پول Sister Pairs\n"
            "امتیاز: %+.2f %s | پوزیشن: %s | جفت: %s\n"
            "وضعیت: %s\n"
            "──────────\n"
            "🟢 >3.0 : موافق | 🟡 >=-5.0 : مختلط\n"
            "🔴 <-5.0 : سونامی! | GOLDEN قرمز=فرار پله ۵\n"
            "محاسبه: H4 momentum 5 کندل",
            fs, arrow, forBuy ? "Buy" : "Sell", baseSym, stDesc);
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
         "v10.9: فیلتر تأیید H1 (Stateless)\n"
         "کندل‌های H1 متوالی در Zone: %d از %d لازم\n"
         "وضعیت: %s\n"
         "(کاهش نویز: Zone فقط بعد از %d H1 متوالی تأیید می‌شود)",
         h1count_display,
         ZombieH1ConfirmBars,
         h1Confirmed ? "✅ تأیید شده" : "⏳ در انتظار تأیید",
         ZombieH1ConfirmBars);

      zombieTip = StringFormat(
         "ZONE v10.8 — Absolute Grid + H1 Filter\n"
         "─────────────────────────────────\n"
         "نماد        : %s  (پشتیبانی‌شده)\n"
         "Base Zone 0 : [%s .. %s]\n"
         "عرض هر طبقه: %d pip (= %.4f قیمت)\n"
         "─────────────────────────────────\n"
         "قیمت فعلی   : %s\n"
         "محدوده طبقه : [%s .. %s]\n"
         "فاصله تا مرز: %.1f pip  (مرز زرد: ≤ %d pip)\n"
         "─────────────────────────────────\n"
         "طبقه ورود   : %+d   (قیمت ورود: %s)\n"
         "طبقه فعلی   : %+d\n"
         "Δ (current−entry): %+d  | جهت: %s\n"
         "%s\n"
         "─────────────────────────────────\n"
         "وضعیت چراغ  : %s",
         _Symbol,
         DoubleToString(zcfg.base_low,_Digits), DoubleToString(zcfg.base_high,_Digits),
         zcfg.widthPips, (double)zcfg.widthPips * GetPipSize(_Symbol),
         DoubleToString(currPx,_Digits),
         lowS, highS,
         borderDistPips, ZoneBorderYellowPips,
         g_zombieEntryZone,
         (g_zombieEntryPrice>0?DoubleToString(g_zombieEntryPrice,_Digits):"(auto)"),
         zoneNumber, delta,
         forBuy?"Buy":"Sell",
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
         forBuy ? "BUY" : "SELL", _btHighAlert);
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
            StringFormat("HIGH ALERT v11\n"
               "ADX=%.1f (≥35) | Flow=%.2f\n"
               "جهت: %s\n"
               "─────────────────\n"
               "این هشدار قبل از CRISIS قرمز فعال می‌شود.\n"
               "خروج فوری را در نظر بگیرید!",
               g_lastAdxVal, g_lastFlowScore,
               forBuy ? "Buy (Flow باید > -7 باشد)" : "Sell (Flow باید < +7 باشد)"));
      }
      else
      {
         TL_SetLight("HIGHALT", 0, "● ALERT: OK    ",
            "HIGH ALERT: ADX < 35 یا Flow در محدوده مجاز");
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
      bool isRedA   = (rc >= 3 && g_lastFlowScore <= -7.0 && g_lastAdxVal > 32.0);
      bool isRedB   = (rc >= 2 && g_lastFlowScore <= -8.5 && g_lastAdxVal > 40.0);
      bool isOrangeA= (rc >= 2 && g_lastFlowScore <= -6.5 && g_lastAdxVal > 30.0);
      bool isOrangeB= (rc >= 3 && tsAgainst > 40.0 && g_lastAdxVal > 28.0);
      bool isOrangeC= (rc >= 2 && g_lastFlowScore <= -7.5 && g_lastAdxVal > 32.0 && tsAgainst > 25.0);
      bool isYellow = (rc >= 2)
                   || (g_lastFlowScore <= -5.0 && g_lastAdxVal > 28.0)
                   || (rc >= 2 && g_lastFlowScore <= -7.0 && tsAgainst > 30.0)
                   || (rc >= 2 && tsAgainst > 45.0 && g_lastAdxVal > 25.0)
                   || (rc >= 2 && g_lastFlowScore <= -7.5 && g_lastAdxVal > 35.0);

      // g_lightGOLDEN mapping: 0=Green 1=Yellow 2=Orange 3=Red (legacy compat: Red maps to 2 for BT)
      if(isRedA || isRedB)
         g_lightGOLDEN = 2;    // Red → legacy 2
      else if(isOrangeA || isOrangeB || isOrangeC)
         g_lightGOLDEN = 2;    // Orange → legacy 2 (보수적으로 Red로 처리)
      else if(isYellow)
         g_lightGOLDEN = 1;
      else
         g_lightGOLDEN = 0;

      UpdateCrisisLight(rc, g_lastFlowScore, g_lastAdxVal, g_csvScore, forBuy);
   }

   // ── v11.2: بررسی تغییر چراغ‌ها و ارسال اعلان ────────────────
   if(!(bool)MQLInfoInteger(MQL_TESTER))  // در بکتست اعلان نده
   {
      bool _highAlertNow = (g_lastAdxVal >= 35.0) &&
                           (forBuy ? (g_lastFlowScore < -7.0) : (g_lastFlowScore > 7.0));
      Alert_CheckAndSend(forBuy, _highAlertNow);
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
   string direction, bool highAlertActive = false)
{
   if(!(bool)MQLInfoInteger(MQL_TESTER)) return;

   datetime now = iTime(_Symbol, PERIOD_H1, 1);
   if(now == 0) now = TimeCurrent();

   MqlDateTime mdt;
   TimeToStruct(now, mdt);
   int curHour = mdt.hour;

   if(curHour == g_lastLoggedHour) return;
   g_lastLoggedHour = curHour;

   // جلسه معاملاتی
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
   bool isRedA   = (rc >= 3 && flowScore <= -7.0 && adxVal > 32.0);
   bool isRedB   = (rc >= 2 && flowScore <= -8.5 && adxVal > 40.0);
   bool isYellow = (rc >= 2) || (flowScore <= -5.0 && adxVal > 28.0)
                || (rc >= 2 && flowScore <= -7.0 && tsAg > 30.0)
                || (rc >= 2 && tsAg > 45.0 && adxVal > 25.0)
                || (rc >= 2 && flowScore <= -7.5 && adxVal > 35.0);
   int crisisState = (isRedA || isRedB) ? 2 : isYellow ? 1 : 0;

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
            "HighAlert,RTM_Arrow,"        // v11.8: RTM_Dist_xATR حذف شد، HighAlert جایگزین
            "ADX_Val,EffRatio_H4,Flow_Score,Trend_Score,"
            "D1_Status,Zombie_Zone,"
            "Regime,Session,Spread_Points\n";
         FileWriteString(hh, hhdr);

         for(int _i = 0; _i < g_hourlyCount; _i++)
         {
            string _cris = (g_hourlyLog[_i].stCRISIS == 2) ? "Red" :
                           (g_hourlyLog[_i].stCRISIS == 1) ? "Yellow" : "Green";
            string _haStr = g_hourlyLog[_i].highAlert ? "Active" : "OK";  // v11.8
            string _line = StringFormat(
               "%s,%s,%s,%s,%s,%s,%s,%s,%s,%.1f,%.3f,%+.2f,%.1f,%s,%d,%s,%s,%d\n",
               TimeToString(g_hourlyLog[_i].snapTime, TIME_DATE|TIME_MINUTES),
               g_hourlyLog[_i].direction,
               BT_StateStr(g_hourlyLog[_i].stRTM),
               BT_StateStr(g_hourlyLog[_i].stTrend),
               BT_StateStr(g_hourlyLog[_i].stStruct),
               BT_StateStr(g_hourlyLog[_i].stFLOW),
               _cris,                                    // v10.4.1: _zom حذف شد، مستقیم _cris
               _haStr,                                   // v11.8: HighAlert
               g_hourlyLog[_i].rtmArrow,
               g_hourlyLog[_i].adxVal,
               g_hourlyLog[_i].erH4,
               g_hourlyLog[_i].flowScore,
               g_hourlyLog[_i].trendScore,
               g_hourlyLog[_i].d1Status,
               g_hourlyLog[_i].zombieZone,     // v10.4: فقط شماره طبقه
               g_hourlyLog[_i].regime,
               g_hourlyLog[_i].session,
               g_hourlyLog[_i].spreadPt
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

      if(sym != _Symbol) { otherCount++; continue; }

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

   Print("💧 LQ debug | symPos=", symPosCount, " netLots=", netLots,
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

   Print("💧 LQ debug | equity=", equity, " margin=", margin,
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

   Print("💧 LQ debug | tickValue=", tickValue, " tickSize=", tickSize,
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

   Print("💧 LQ debug | equityConst=", equityConst, " equityTarget=", equityTarget,
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
   // ─── تابع ساخت کامل داشبورد ─────────────────────────────────────────
   // این تابع فقط یک‌بار در OnInit فراخوانی می‌شود.
   // بروزرسانی مقادیر با UpdateDashboard() انجام می‌شود که هر tick/بار جدید صدا زده می‌شود.
   // ترتیب رسم: Header → Preset buttons → MA buttons → Filter buttons → AI buttons
   //             → Market Regime → Gate Monitor → Session → XMOON ALERT → Statistics
   if(!ShowDashboard) return;
   
   // ─── محاسبه DPI و scale ────────────────────────────────────────
   // DPI مرجع = 96 (ویندوز استاندارد، 100% scaling)
   // 4K با 150% scaling → DPI=144 → scale=1.5
   // 4K با 200% scaling → DPI=192 → scale=2.0
   int    screenDPI     = GetScreenDPI();
   double dpiScale      = screenDPI / 96.0;

   // v11.92: ─── اعمال DashboardScalePercent روی همه ابعاد ───────
   double userScale     = DashboardScalePercent / 100.0;
   if(userScale < 0.50) userScale = 0.50;
   if(userScale > 3.00) userScale = 3.00;
   g_dashUserScale      = userScale;                // برای CreateButton/CreateLabel
   dpiScale            *= userScale;                // همه‌چیز با dpiScale مقیاس می‌شود
   int    dashFont      = (int)MathMax(6, MathRound(DashboardFontSize * userScale));
   int    dashFontSmall = (int)MathMax(6, MathRound((DashboardFontSize - 1) * userScale));
   g_dashBtnFontPt      = (int)MathMax(6, MathRound(8.0 * userScale));

   // ─── محاسبه اندازه‌های مقیاس‌پذیر ────────────────────────────
   // فونت در MQL5 به نقطه (pt) است. هر نقطه = DPI/72 پیکسل
   // lineHeight = ارتفاع واقعی فونت در پیکسل + فاصله
   double ptToPixel     = screenDPI / 72.0;
   int    labelPixH     = (int)MathCeil(dashFont * ptToPixel);
   int    lineHeight    = labelPixH + (int)MathMax(2, MathRound(3 * dpiScale));  // v11: ۲۰٪ کمتر — فاصله عمودی
   int    btnPixH       = (int)MathCeil(g_dashBtnFontPt * ptToPixel);  // فونت دکمه (scaled)
   int    btnHeight     = btnPixH + (int)MathMax(6, 6 * dpiScale);    // ارتفاع دکمه
   int    lqBtnH        = (int)MathRound(btnHeight * 1.3);            // 💧 ارتفاع دکمه Liquid (30٪ بلندتر)
   int    btnGap        = (int)MathMax(4, MathRound(4 * dpiScale));   // فاصله بین دکمه‌ها
   int    padX          = (int)MathMax(8, MathRound(8 * dpiScale));   // padding داخلی افقی
   int    sectionGap    = (int)MathMax(5, MathRound(5 * dpiScale));   // فاصله بین بخش‌ها
   
   // ─── عرض دکمه‌ها ─────────────────────────────────────────────
   // بر اساس DPI scale کنید تا متن داخل جا بخوره
   // v7.0: aiBtnW از 56→62 افزایش یافت برای "LiqSwp" و "VolPro"
   int    presetBtnW    = (int)MathMax(34, MathRound(36 * dpiScale)); // M1,M5,M15,M30,H1
   int    filterBtnW    = (int)MathMax(56, MathRound(60 * dpiScale)); // Relaxed,Balanced,Strict
   int    aiBtnW        = (int)MathMax(62, MathRound(66 * dpiScale)); // Regime,MTF,Price|SR,VolPro,Ichi|FVG,LiqSwp,RTM
   
   // ─── عرض کل background ───────────────────────────────────────
   // باید همه دکمه‌ها رو بپوشونه + padding
   int    presetRowW    = 5 * (presetBtnW + btnGap) - btnGap;
   int    filterRowW    = 3 * (filterBtnW + btnGap) - btnGap;
   int    aiRowW        = 3 * (aiBtnW + btnGap) - btnGap;  // 3 ردیف، هر ردیف 3 دکمه
   int    contentWidth  = (int)MathMax(presetRowW, MathMax(filterRowW, aiRowW));
   int    bgWidth       = contentWidth + 2 * padX + (int)MathRound(10 * dpiScale);
   
   // ─── مختصات شروع (همه offset ها با DPI scale می‌شوند) ──────────
   // کاربر عدد رو برای 96 DPI وارد می‌کنه → کد خودکار scale می‌کنه
   // مثال: XOffset=200 روی 96DPI=200px | روی 144DPI=300px | روی 192DPI=400px
   int xStart       = (int)MathRound(DashboardXOffset * dpiScale);
   int yStart       = (int)MathRound(DashboardYOffset * dpiScale);
   int scaledBtnOfs = (int)MathRound(ButtonsXOffset   * dpiScale);
   int yPos         = yStart;
   
   // ─── محاسبه ارتفاع background بر اساس خطوط واقعی ─────────────
   int bgHeight = (int)(lineHeight * 1.3);  // Title
   if(ShowPresetButtons) bgHeight += btnHeight + sectionGap;
   if(ShowPresetButtons) bgHeight += btnHeight + sectionGap;  // MA buttons row
   if(ShowFilterButtons) bgHeight += btnHeight + sectionGap;
   // 🆕 v7.0: سه ردیف دکمه‌های AI (قبلاً دو ردیف بود)
   if(ShowAIButtons)     bgHeight += lineHeight + 3 * (btnHeight + sectionGap);
   if(ShowRegimeInfo)    bgHeight += 3 * lineHeight + sectionGap;
   // v7.0: MTF Confluence از پنل حذف شد (برای Xmoon کاربردی ندارد)
   // if(ShowMTFInfo)    bgHeight += 3 * lineHeight + sectionGap;
   // v7.0: Gate Monitor: ATR و 3-Bar حذف شدند (4 خط به جای 6)
   if(ShowGateMonitor)   bgHeight += 4 * lineHeight + sectionGap;
   // v7.0: Session: یک خط اسپرد اضافه شد
   if(ShowSessionInfo)   bgHeight += 3 * lineHeight + sectionGap;
   // Liquid Level button (جایگزین Statistics) + لیبل وضعیت زیر دکمه + ردیف Reset
   bgHeight += lqBtnH + lineHeight + sectionGap + padX;
   bgHeight += btnHeight + sectionGap;  // 🔧 FIX v7.3: ردیف Reset + EAStatus
   // 🆕 v7.0: XMOON ALERT (Traffic Lights داخل داشبورد)
   bgHeight += 7 * lineHeight + sectionGap;  // v11: title+RTM+TREND+STRUCT+FLOW+ZOMBIE+HIGHALT
   bgHeight += padX * 2;  // حاشیه بالا/پایین
   
   // ─── Background ───────────────────────────────────────────────
   // bgShift: BG را 20px (DPI-scaled) به چپ شیفت می‌دهد تا متن‌ها از ابتدا پوشانده شوند
   // bgWidthFull: عرض 20٪ بیشتر برای پوشش کامل دکمه‌های سمت راست
   int bgShift     = (int)MathRound(20 * dpiScale);
   int bgWidthFull = (int)MathRound(bgWidth * 1.2);

   string bgName = dashboardPrefix + "BG";
   ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER,    DashboardCorner);
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, xStart + bgShift);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, yStart - (int)MathRound(5 * dpiScale));
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE,     bgWidthFull + bgShift);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE,     bgHeight);
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR,   DashboardBackColor);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bgName, OBJPROP_BACK,      false);
   
   int lx = xStart + padX;  // شروع افقی labels
   

   
   // ─── Preset Buttons ───────────────────────────────────────────
   if(ShowPresetButtons)
   {
      string presets[] = {"M1", "M5", "M15", "M30", "H1"};
      int btnsStartX = lx + scaledBtnOfs;
      for(int i = 0; i < 5; i++)
      {
         string btnName = dashboardPrefix + "Btn_" + presets[i];
         int btnX = btnsStartX + (i * (presetBtnW + btnGap));
         CreateButton(btnName, btnX, yPos, presetBtnW, btnHeight, presets[i], clrWhite, clrNavy);
      }
      yPos += btnHeight + sectionGap;
   }

   // ─── MA Overlay Buttons (دقیقاً زیر Preset buttons) ─────────────
   // شش دکمه MA: M15, M30, H1, H4, D1, EMA - عرض محاسبه‌شده به‌صورت خودکار
   // نام داخلی دکمه (برای کلیک handler) و متن نمایشی جداست
   if(ShowPresetButtons)
   {
      // نام‌های داخلی برای شناسایی در OnChartEvent - تغییر نده
      string maTFs[]    = {"MA15",         "MA30",          "MA1H",   "MA4H",    "MA1D", "FEMA"};
      // متن کوتاه برای نمایش داخل دکمه (حداکثر ۳-۴ حرف)
      string maTexts[]  = {"M15",          "M30",           "H1",     "H4",      "D1",   "EMA"};
      bool   maActive[] = {g_maM15Active, g_maM30Active, g_maH1Active, g_maH4Active, g_maD1Active, g_femaActive};
      color  maColors[] = {clrDodgerBlue, clrMediumOrchid, clrOrange, clrDeepPink, clrGold, clrMediumSpringGreen};
      int btnsStartX = lx + scaledBtnOfs;
      // محاسبه عرض دکمه: ۶ دکمه باید در فضای presetRowW جا بشن
      // فرمول: (totalWidth + gap) / count - gap
      int femaW = (presetRowW + btnGap) / 6 - btnGap;
      if(femaW < 28) femaW = 28;  // حداقل ۲۸ پیکسل برای خوانایی
      for(int i = 0; i < 6; i++)
      {
         string btnName = dashboardPrefix + "MABtn_" + maTFs[i];
         int    btnX    = btnsStartX + (i * (femaW + btnGap));
         color  bgCol   = maActive[i] ? maColors[i] : clrDarkSlateGray;
         CreateButton(btnName, btnX, yPos, femaW, btnHeight, maTexts[i], clrWhite, bgCol);
      }
      yPos += btnHeight + sectionGap;
   }
   
   // ─── Filter Mode Buttons ──────────────────────────────────────
   if(ShowFilterButtons)
   {
      string filters[] = {"Relaxed", "Balanced", "Strict"};
      int btnsStartX = lx + scaledBtnOfs;
      for(int i = 0; i < 3; i++)
      {
         string btnName = dashboardPrefix + "FilterBtn_" + filters[i];
         int btnX = btnsStartX + (i * (filterBtnW + btnGap));
         color btnColor = (currentFilterMode == i) ? clrDarkGreen : clrDarkSlateGray;
         CreateButton(btnName, btnX, yPos, filterBtnW, btnHeight, filters[i], clrWhite, btnColor);
      }
      yPos += btnHeight + sectionGap;
   }
   
   // ─── AI Toggle Buttons ────────────────────────────────────────
   if(ShowAIButtons)
   {
      CreateLabel(dashboardPrefix + "AITitle", lx, yPos, "-- AI FEATURES --", clrCyan, dashFont);
      yPos += lineHeight;
      
      int btnsStartX = lx + scaledBtnOfs;
      
      // ردیف ۱: Regime, MTF, Price
      string ai1[]       = {"Regime", "MTF", "Price"};
      bool   ai1Active[] = {localEnableMarketRegime, localEnableMTF, localEnablePriceAction};
      for(int i = 0; i < 3; i++)
      {
         string btnName = dashboardPrefix + "AIBtn_" + ai1[i];
         int btnX = btnsStartX + (i * (aiBtnW + btnGap));
         color btnColor = ai1Active[i] ? clrDarkGreen : clrMaroon;
         CreateButton(btnName, btnX, yPos, aiBtnW, btnHeight, ai1[i], clrWhite, btnColor);
      }
      yPos += btnHeight + sectionGap;
      
      // ردیف ۲: S/R, VolPro, Ichi
      string ai2_name[]   = {"SR",    "Vol",     "Ichi"};
      string ai2_text[]   = {"S/R",   "VolPro",  "Ichi"};
      bool   ai2_active[] = {localEnableSR, localEnableSmartVol, localEnableIchimoku};
      for(int i = 0; i < 3; i++)
      {
         string btnName = dashboardPrefix + "AIBtn_" + ai2_name[i];
         int btnX = btnsStartX + (i * (aiBtnW + btnGap));
         color btnColor = ai2_active[i] ? clrDarkGreen : clrMaroon;
         CreateButton(btnName, btnX, yPos, aiBtnW, btnHeight, ai2_text[i], clrWhite, btnColor);
      }
      yPos += btnHeight + sectionGap;
      
      // 🆕 v7.0 ردیف ۳: FVG, LiqSwp, RTM
      // این ردیف به‌طور خاص برای کمک به Xmoon طراحی شده
      // FVG → ناحیه‌های نقدینگی پر‌نشده
      // LiqSwp → تشخیص شکار استاپ + برگشت
      // RTM → هشدار فاصله از میانگین (مهم‌ترین برای Xmoon)
      string ai3_name[]   = {"FVG",    "LiqSwp",  "RTM"};
      string ai3_text[]   = {"FVG",    "LiqSwp",  "RTM"};
      bool   ai3_active[] = {localEnableFVG, localEnableLiqSwp, localEnableRTM};
      for(int i = 0; i < 3; i++)
      {
         string btnName = dashboardPrefix + "AIBtn_" + ai3_name[i];
         int btnX = btnsStartX + (i * (aiBtnW + btnGap));
         color btnColor = ai3_active[i] ? clrDarkGreen : clrMaroon;
         CreateButton(btnName, btnX, yPos, aiBtnW, btnHeight, ai3_text[i], clrWhite, btnColor);
      }
      yPos += btnHeight + sectionGap;
   }
   
   // ─── Market Regime ────────────────────────────────────────────
   if(ShowRegimeInfo)
   {
      CreateLabel(dashboardPrefix + "RegimeTitle",  lx, yPos, "-- MARKET REGIME --",  clrWhite, dashFont); yPos += lineHeight;
      CreateLabel(dashboardPrefix + "RegimeStatus", lx, yPos, "Regime: ...",           clrGray,  dashFont); yPos += lineHeight;
      CreateLabel(dashboardPrefix + "RegimeER",     lx, yPos, "ER: 0.00",              clrGray,  dashFont); yPos += lineHeight + sectionGap;
   }
   
   // ─── MTF Confluence ───────────────────────────────────────────
   // v7.0: از پنل حذف شد - برای تصمیم Xmoon پس از پله ۵ کاربردی ندارد
   // (محاسبات MTF داخلی همچنان فعال هستند و روی سیگنال‌ها اثر دارند)

   // ─── Gate Monitor ─────────────────────────────────────────────
   if(ShowGateMonitor)
   {
      CreateLabel(dashboardPrefix + "GateTitle",  lx, yPos, "-- GATE MONITOR --",  clrWhite, dashFont); yPos += lineHeight;
      CreateLabel(dashboardPrefix + "ADXStatus",  lx, yPos, "ADX: 0.0",             clrGray,  dashFont); yPos += lineHeight;
      // v7.0: ATR حذف شد (در Gate Monitor نمایش داده نمی‌شود)
      // v7.0: 3-Bar Momentum حذف شد (برای Xmoon کاربردی ندارد)
      CreateLabel(dashboardPrefix + "WickStatus", lx, yPos, "Wick: 0.00",           clrGray,  dashFont); yPos += lineHeight;
      // 🆕 v7.0: RTM Distance برای Xmoon assessment
      CreateLabel(dashboardPrefix + "RTMStatus",  lx, yPos, "RTM: --",              clrGray,  dashFont); yPos += lineHeight + sectionGap;
   }
   
   // ─── Session ──────────────────────────────────────────────────
   if(ShowSessionInfo)
   {
      CreateLabel(dashboardPrefix + "SessionTitle",  lx, yPos, "-- SESSION --",  clrWhite, dashFont); yPos += lineHeight;
      CreateLabel(dashboardPrefix + "SessionStatus", lx, yPos, "Now: ...",        clrGray,  dashFont); yPos += lineHeight;
      // 🆕 v7.0: اسپرد لحظه‌ای (هر ۱۰+ ثانیه آپدیت می‌شود)
      CreateLabel(dashboardPrefix + "SpreadStatus",  lx, yPos, "Spread: ...",     clrGray,  dashFont); yPos += lineHeight + sectionGap;
   }

   // ─── v8.2: XMOON ALERT (Traffic Lights داخل داشبورد) ─────────
   // چهار چراغ اصلی — CRISIS به‌صورت جداگانه بالا-چپ نمایش داده می‌شود
   CreateLabel(dashboardPrefix + "TLTitle",   lx, yPos, "-- XMOON ALERT --",  clrYellow, dashFont); yPos += lineHeight;
   CreateLabel(dashboardPrefix + "TL_RTM",   lx, yPos, "● RTM: --      ",    clrDimGray, dashFont); yPos += lineHeight;
   CreateLabel(dashboardPrefix + "TL_TREND", lx, yPos, "● ADX: --      ",    clrDimGray, dashFont); yPos += lineHeight;
   CreateLabel(dashboardPrefix + "TL_STRUCT",lx, yPos, "● D1:  --      ",    clrDimGray, dashFont); yPos += lineHeight;
   CreateLabel(dashboardPrefix + "TL_FLOW",  lx, yPos, "● FLOW: --     ",    clrDimGray, dashFont); yPos += lineHeight;
   CreateLabel(dashboardPrefix + "TL_ZOMBIE",lx, yPos, "● ZONE: --     ",    clrDimGray, dashFont); yPos += lineHeight;
   // v11.0: HIGH ALERT — پیش‌هشدار ADX+Flow
   CreateLabel(dashboardPrefix + "TL_HIGHALT",lx, yPos,"● ALERT: --    ",    clrDimGray, dashFont); yPos += lineHeight + sectionGap;
   
   // ─── Liquid Level Button (جایگزین Statistics) ────────────────
   // 🆕 v8.0 FIX: موقعیت ثابت داخل پنل - مستقل از ButtonsXOffset
   // scaledBtnOfs منفی است (-200) و دکمه‌های دیگر رو به سمت دکمه‌های Preset هدایت می‌کند
   // اما Liquid Level باید وسط-پایین پنل باشد، نه کنار دکمه‌های بالا
   {
      int lqBtnW = (int)(bgWidthFull * 0.70);   // ۷۰٪ عرض پنل
      // موقعیت X: از لبه راست پنل (xStart + bgShift) + padding داخلی
      // این مستقل از ButtonsXOffset است تا دکمه همیشه داخل پنل بماند
      int lqBtnX = xStart + bgShift + (bgWidthFull - lqBtnW) / 2 - 95;  // وسط‌چین در پنل
      string lqBtnName    = dashboardPrefix + "LiquidBtn";
      string lqStatusName = dashboardPrefix + "LiquidStatus";
      // ─── دکمه: رنگ طلایی با متن سیاه، ارتفاع 30٪ بیشتر ───────
      CreateButton(lqBtnName, lqBtnX, yPos, lqBtnW, lqBtnH,
                   "💧 LIQUID LEVEL", clrBlack, clrGold);
      // ─── لیبل وضعیت زیر دکمه ─────────────────────────────────
      int lqLblY = yPos + lqBtnH + 2;
      CreateLabel(lqStatusName, lqBtnX, lqLblY, "غیرفعال | برای فعال‌سازی کلیک کن", clrDimGray, dashFontSmall);
   }
   
   // ─── v11.0: دکمه‌های رادیویی Buy / All / Sell ─────────────────
   // این دکمه‌ها جهت محاسبه چراغ‌ها را override می‌کنند
   // All=پیش‌فرض | Buy=همیشه Buy | Sell=همیشه Sell (حتی بدون پوزیشن)
   bgHeight += btnHeight + sectionGap;  // فضا برای ردیف جدید
   {
      int dirRowOffset = -190;
      int dirY = yPos + lqBtnH + lineHeight + sectionGap;
      int dirTotalW = (int)(bgWidthFull * 0.80);
      int dirBtnW   = (int)(dirTotalW * 0.28);
      int dirStartX = xStart + bgShift + (bgWidthFull - dirTotalW) / 2 + dirRowOffset;

      // Buy دکمه
      color buyCol = (g_dirMode == 1) ? clrDarkGreen : clrDarkSlateGray;
      CreateButton(dashboardPrefix + "DirBtn_Buy",
                   dirStartX, dirY, dirBtnW, btnHeight,
                   "▲ Buy", clrWhite, buyCol);
      // All دکمه (پیش‌فرض انتخاب‌شده)
      color allCol = (g_dirMode == 0) ? clrMidnightBlue : clrDarkSlateGray;
      CreateButton(dashboardPrefix + "DirBtn_All",
                   dirStartX + dirBtnW + btnGap, dirY, dirBtnW, btnHeight,
                   "◆ All", clrWhite, allCol);
      // Sell دکمه
      color sellCol = (g_dirMode == 2) ? clrDarkRed : clrDarkSlateGray;
      CreateButton(dashboardPrefix + "DirBtn_Sell",
                   dirStartX + 2 * (dirBtnW + btnGap), dirY, dirBtnW, btnHeight,
                   "▼ Sell", clrWhite, sellCol);
   }

   // ─── Reset + Minimal + EAStatus ────────────────────────────────
   // resetRowOffset: تنظیم دستی آفست افقی — مثبت = راست، منفی = چپ
   {
      int resetRowOffset = -190;  // ← آفست دستی (پیکسل)

      int resetY = yPos + lqBtnH + lineHeight + sectionGap * 2 + btnHeight + sectionGap;

      // ردیف: [↺ RESET] [🧹 Minimal]   ✅ آماده
      int rowTotalW   = (int)(bgWidthFull * 0.80);
      // دو دکمه مساوی + یک gap بینشون
      int eachBtnW    = (int)(rowTotalW * 0.34);
      int rowStartX   = xStart + bgShift + (bgWidthFull - rowTotalW) / 2 + resetRowOffset;
      int minimalBtnX = rowStartX + eachBtnW + btnGap;
      int statusLblX  = minimalBtnX + eachBtnW + btnGap;

      CreateButton(dashboardPrefix + "ResetBtn",
                   rowStartX, resetY, eachBtnW, btnHeight,
                   "↺ RESET", clrWhite, clrDarkSlateGray);
      CreateButton(dashboardPrefix + "MinimalBtn",
                   minimalBtnX, resetY, eachBtnW, btnHeight,
                   "🧹 Minimal", clrWhite, clrDarkSlateGray);
      CreateLabel(dashboardPrefix + "EAStatus",
                  statusLblX, resetY + (int)(btnHeight * 0.15),
                  "✅ آماده", clrLimeGreen, dashFontSmall);
      // ⏻ دکمه خاموش‌کردن — ردیف Reset، سمت راست EAStatus
      // v11.91: مربعی‌شکل، همان ارتفاع دکمه‌های ردیف Reset
      int powerBtnW = btnHeight;
      int powerOffHShift = -60;   // ← آفست افقی دکمه ⏻ (پیکسل) — برای تنظیم دستی
      int powerBtnX = rowStartX - powerBtnW - btnGap + powerOffHShift;
      CreateButton(dashboardPrefix + "PowerOffBtn",
                   powerBtnX, resetY, powerBtnW, btnHeight,
                   "X", clrWhite, clrRed);
   }

   ChartRedraw();
}


//+------------------------------------------------------------------+
//| 🔄 UPDATE DASHBOARD PRO                                          |
//| بروزرسانی مقادیر داشبورد - هر بار جدید یا بعد از کلیک دکمه    |
//| این تابع فقط متن label ها را عوض می‌کند؛ داشبورد را از نو      |
//| نمی‌سازد (برای صرفه‌جویی CPU)                                   |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!ShowDashboard) return;
   // 🔧 FIX v7.2 (فلیکر Wingo M1): throttle - حداکثر هر 800ms یک‌بار داشبورد رفرش بشه
   // دلیل: Wingo Markets tick rate روی M1 خیلی بالاست و هر tick باعث ChartRedraw می‌شد
   // → پرش چارت و فلیکر داشبورد. حالا اگه g_forceUpdateDashboard باشه override می‌کنه.
   static datetime s_lastUpdate = 0;
   datetime _nowU = TimeCurrent();
   if(!g_forceUpdateDashboard && (_nowU - s_lastUpdate) < 1)
      return;  // کمتر از 1 ثانیه گذشته و force نشده → رد کن
   s_lastUpdate = _nowU;
   
   // --- تشخیص آخر هفته در ابتدا (برای استفاده در تمام بخش‌ها) ---
   MqlDateTime _gmtNow;
   TimeToStruct(TimeGMT(), _gmtNow);
   int _dow = _gmtNow.day_of_week;
   int _hr  = _gmtNow.hour;
   bool marketClosed = (_dow == 6) ||
                       (_dow == 0 && _hr < 22) ||
                       (_dow == 5 && _hr >= 22);
   string closedTag = " [Market Closed]";

   // Update Market Regime
   if(ShowRegimeInfo)
   {
      // همیشه رژیم را محاسبه می‌کنیم حتی اگه دکمه Regime خاموش باشد
      // (دکمه Regime فقط فیلتر سیگنال را کنترل می‌کند، نه نمایش داشبورد)
      if(currentRegime.description == "" || marketClosed)
      {
         // اگه تا به حال محاسبه نشده (چون دکمه خاموش بوده) یا بازار بسته است
         if(!marketClosed)
            currentRegime = DetectMarketRegime(RegimeCalculationBars);
      }
      
      string regimeText;
      color  regimeColor;
      
      if(marketClosed)
      {
         regimeText  = "Regime: Market Closed";
         regimeColor = clrDimGray;
      }
      else
      {
         switch(currentRegime.regime)
         {
            case REGIME_TRENDING:
               regimeText  = "Regime: Trending ↗";
               regimeColor = clrLime;
               break;
            case REGIME_RANGING:
               regimeText  = "Regime: Ranging ↔";
               regimeColor = clrOrange;
               break;
            case REGIME_VOLATILE:
               regimeText  = "Regime: Volatile ⚡";
               regimeColor = clrRed;
               break;
            case REGIME_QUIET:
            default:
               regimeText  = "Regime: Quiet / Basing";
               regimeColor = clrGray;
               break;
         }
      }
      
      string regimeTip =
         "Trending  → سیگنال ادامه‌دهنده بهتر عمل می‌کند\n"
         "Ranging   → سیگنال برگشتی بهتر عمل می‌کند\n"
         "Volatile  → نوسان غیرعادی بالاست - احتیاط\n"
         "Quiet      → آرامش قبل طوفان";
      UpdateLabelTip(dashboardPrefix + "RegimeStatus", regimeText, regimeColor, regimeTip);

      double erVal = marketClosed ? 0.0 : GetCurrentEfficiencyRatio();
      string erTip = StringFormat(
         "Efficiency Ratio (ER): %.3f\n"
         "0.00 - 0.20 → بازار رنج / تصادفی (ورود نکن)\n"
         "0.20 - 0.35 → روند متوسط (با احتیاط)\n"
         "0.35 - 1.00 → روند قوی (خیال راحت)", erVal);
      UpdateLabelTip(dashboardPrefix + "RegimeER",
                     marketClosed ? "ER: --" : StringFormat("ER: %.3f", erVal),
                     marketClosed ? clrDimGray : clrWhite, erTip);
   }
   
   // Update MTF Status
   if(ShowMTFInfo)
   {
      string h1Text = "H1: ";
      color h1Color = clrGray;
      
      if(mtfTrend.h1Bullish)
      {
         h1Text += "BULLISH ↑";
         h1Color = clrLime;
      }
      else if(mtfTrend.h1Bearish)
      {
         h1Text += "BEARISH ↓";
         h1Color = clrRed;
      }
      else
      {
         h1Text += "NEUTRAL";
      }
      
      UpdateLabel(dashboardPrefix + "H1Status", h1Text, h1Color);
      
      string h4Text = "H4: ";
      color h4Color = clrGray;
      
      if(mtfTrend.h4Bullish)
      {
         h4Text += "BULLISH ↑";
         h4Color = clrLime;
      }
      else if(mtfTrend.h4Bearish)
      {
         h4Text += "BEARISH ↓";
         h4Color = clrRed;
      }
      else
      {
         h4Text += "NEUTRAL";
      }
      
      UpdateLabel(dashboardPrefix + "H4Status", h4Text, h4Color);
   }
   
   // Update Gate Monitor
   if(ShowGateMonitor)
   {
      if(marketClosed)
      {
         UpdateLabelTip(dashboardPrefix + "ADXStatus",  "ADX: --" + closedTag, clrDimGray, "بازار بسته است");
         UpdateLabelTip(dashboardPrefix + "WickStatus", "Wick: --" + closedTag, clrDimGray, "بازار بسته است");
         UpdateLabelTip(dashboardPrefix + "RTMStatus",  "RTM: --" + closedTag, clrDimGray, "بازار بسته است");
      }
      else
      {
      // ADX with direction arrow
      double adx[2];  // Get current and previous
      if(CopyBuffer(handleADX, 0, 0, 2, adx) == 2)
      {
         string adxArrow = "";
         if(adx[0] > adx[1] + 1)
            adxArrow = " ▲";  // Rising
         else if(adx[0] < adx[1] - 1)
            adxArrow = " ▼";  // Falling
         else
            adxArrow = " →";  // Flat
         
         color adxColor = adx[0] > MinADX ? clrLime : clrOrange;
         string adxTip = StringFormat(
            " روند ضعیف → زیر 20\n"
            "روند متوسط  → بین 20 تا 30\n"
            "روند قوی  → بالای 30\n",
            adx[0], adxArrow,
            adx[0] > adx[1]+1 ? "رشد میکنه" : (adx[0] < adx[1]-1 ? "کاهش میابه" : "ثابته"),
            adx[0] > MinADX ? "خوبه" : "کافی نیست");
         UpdateLabelTip(dashboardPrefix + "ADXStatus", 
                        StringFormat("ADX: %.1f%s", adx[0], adxArrow),
                        adxColor, adxTip);
      }
      // v7.0: ATR از Gate Monitor حذف شد
      // v7.0: 3-Bar Momentum از Gate Monitor حذف شد
      
      // Wick Ratio - bar 1 (آخرین کندل بسته‌شده) تا بار باز شدن کندل جدید صفر نشه
      double close_val = iClose(_Symbol, PERIOD_CURRENT, 1);
      double open_val  = iOpen (_Symbol, PERIOD_CURRENT, 1);
      double high_val  = iHigh (_Symbol, PERIOD_CURRENT, 1);
      double low_val   = iLow  (_Symbol, PERIOD_CURRENT, 1);
      
      double bodySize  = MathAbs(close_val - open_val);
      double totalSize = high_val - low_val;
      double wickRatio = totalSize > 0 ? bodySize / totalSize : 0;
      
      color  wickColor = wickRatio >= localMinBodyToTotalRatio ? clrLime : clrOrange;
      string wickTip   = StringFormat(
         "فشار خریداران/فروشندگان قوی‌تره → هرچه بدنه بزرگ‌تر باشه\n"
         "کندل بلاتکلیف → زیر %.2f  \n"
         "کندل جهت دار → بالای %.2f \n"
         "مقدار فعلی: %.2f",
         localMinBodyToTotalRatio,
         localMinBodyToTotalRatio,
         wickRatio);
      UpdateLabelTip(dashboardPrefix + "WickStatus",
                     StringFormat("Wick: %.2f", wickRatio),
                     wickColor, wickTip);
      
      // v7.0: 3-Bar Momentum کد حذف شد
      
      // 🆕 v7.0: RTM Distance - کلیدی برای Xmoon assessment
      // حتی اگه دکمه RTM خاموش باشد، فاصله از میانگین نمایش داده می‌شود
      // چون این اطلاعات همیشه مفیده (مخصوصاً برای Xmoon)
      if(handleRTM_EMA != INVALID_HANDLE)
      {
         double rtmBuf[]; ArraySetAsSeries(rtmBuf, true);
         if(CopyBuffer(handleRTM_EMA, 0, 1, 1, rtmBuf) > 0)
         {
            double lastClose = iClose(_Symbol, PERIOD_CURRENT, 1);
            double atrNow    = (g_cacheSize > 1 && ArraySize(g_atr) > 1) ? g_atr[1] : 0;
            double dist      = MathAbs(lastClose - rtmBuf[0]);
            double distATR   = (atrNow > 0) ? dist / atrNow : 0;
            bool   above     = (lastClose > rtmBuf[0]);
            string dirArr    = above ? " ↑" : " ↓";  // قیمت بالا یا پایین میانگین
            
            string rtmText;
            color  rtmColor;
            string rtmDashTip;
            if(distATR >= RTM_DangerATR)
            {
               rtmText  = "RTM: " + DoubleToString(distATR, 1) + "x" + dirArr + " ← برگشت محتمل";
               rtmColor = clrLime;
               rtmDashTip = StringFormat(
                  "قیمت از میانگین فاصله زیادی گرفته (EMA%d)\n"
                  "وضعیت: کشیده‌شده %s → احتمال برگشت بالاست ✅\n"
                  "فاصله: %.1f ATR (آستانه خطر: %.1f ATR)\n",
                  RTM_EMAPeriod, above ? "به بالا" : "به پایین",
                  distATR, RTM_DangerATR);
            }
            else if(distATR >= 2.0)
            {
               rtmText  = "RTM: " + DoubleToString(distATR, 1) + "x" + dirArr + " Caution";
               rtmColor = clrOrange;
               rtmDashTip = StringFormat(
                  "قیمت از میانگین دور شده ولی نه خیلی (EMA%d)\n"
                  "فاصله: %.1f ATR | آستانه خطر: %.1f ATR\n"
                  "وضعیت: با احتیاط ⚠️\n",
                  RTM_EMAPeriod, distATR, RTM_DangerATR);
            }
            else
            {
               rtmText  = "RTM: " + DoubleToString(distATR, 1) + "x" + dirArr + " Near Mean";
               rtmColor = clrGray;
               rtmDashTip = StringFormat(
                  "قیمت نزدیک میانگین هست (EMA%d)\n"
                  "فاصله: %.1f ATR\n"
                  "وضعیت: در محدوده میانگین\n",
                  RTM_EMAPeriod, distATR);
            }
            UpdateLabelTip(dashboardPrefix + "RTMStatus", rtmText, rtmColor, rtmDashTip);
         }
      }
      else if(!localEnableRTM)
      {
         UpdateLabel(dashboardPrefix + "RTMStatus", "RTM: OFF (click to enable)", clrDimGray);
      }
      } // end else (market open) for Gate Monitor
   }
   // این روش از تمام خطاهای offset محاسباتی جلوگیری میکنه
   if(ShowSessionInfo)
   {
      int gmtHour   = _gmtNow.hour;
      int gmtMinute = _gmtNow.min;

      string sessionName  = "Off Hours";
      color  sessionColor = clrGray;

      if(marketClosed)
      {
         sessionColor = clrRed;
         // ساعت باز شدن بازار: یکشنبه ساعت 22:00 GMT (تبدیل به وقت محلی)
         int localOffsetSec2 = (int)(TimeLocal() - TimeGMT());
         int localOffsetMin2 = localOffsetSec2 / 60;
         int openGMT = 22;   // Sunday 22:00 GMT = Monday forex open
         int localH  = ((openGMT * 60 + localOffsetMin2) % 1440 + 1440) % 1440 / 60;
         int localM  = MathAbs(localOffsetMin2 % 60);
         string nextOpenStr = StringFormat("Market Open: Sun %02d:%02d (Local)", localH, localM);
         UpdateLabel(dashboardPrefix + "SessionStatus",
                     "Now: Market Closed | " + nextOpenStr,
                     clrRed);
         UpdateLabel(dashboardPrefix + "SpreadStatus", "Spread: Market Closed", clrDimGray);
      }
      else
      {
         sessionName = GetCurrentSession(gmtHour, sessionColor);
         
         // نمایش فقط نام سشن با ساعت‌های محلی — بدون ساعت جاری (کاهش بار CPU)
         // مثال: "Now: London/NY (16:30 - 20:30)"
         UpdateLabel(dashboardPrefix + "SessionStatus",
                     "Now: " + sessionName,
                     sessionColor);

         // اسپرد لحظه‌ای - آپدیت هر ۱۰+ ثانیه
         static datetime s_lastSpread = 0;
         datetime nowT = TimeCurrent();
         if(nowT - s_lastSpread >= 10 || s_lastSpread == 0)
         {
            s_lastSpread = nowT;
            long sp = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
            if(sp == 0)
               UpdateLabel(dashboardPrefix + "SpreadStatus", "Spread: No Spread", clrDimGray);
            else
            {
               color spC = (sp <= 3) ? clrLime : (sp <= 12) ? clrGold : clrRed;
               UpdateLabel(dashboardPrefix + "SpreadStatus",
                           StringFormat("Spread: %d pt", sp), spC);
            }
         }
      }
   } // end if(ShowSessionInfo)
   // Statistics section removed - replaced by Liquid Level button

   // 🔧 FIX v7.2: بروزرسانی لیبل وضعیت EA
   {
      color stC = (StringFind(g_eaStatus, "✅") >= 0) ? clrLimeGreen :
                  (StringFind(g_eaStatus, "⚙️") >= 0) ? clrYellow    :
                  (StringFind(g_eaStatus, "🔄") >= 0) ? clrDodgerBlue :
                  clrOrangeRed;
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
      color btnColor = (currentFilterMode == i) ? clrDarkGreen : clrDarkSlateGray;
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
      sessionColor = clrGold;
   }
   else if(inLondon && inNY)
   {
      // Overlap London / New York: فصلی (زمستان 13–17 | تابستان 12–17)
      sessionName  = "London/NY (" + TO_LOCAL_STR(nyOpen) + " - " + TO_LOCAL_STR(17) + ")";
      sessionColor = clrAqua;
   }
   else if(inTokyo)
   {
      // Tokyo only: 00:00–08:00 GMT
      sessionName  = "Tokyo (" + TO_LOCAL_STR(0) + " - " + TO_LOCAL_STR(9) + ")";
      sessionColor = clrOrange;
   }
   else if(inLondon)
   {
      // London only: 09:00–nyOpen and 17:00 close
      sessionName  = "London (" + TO_LOCAL_STR(8) + " - " + TO_LOCAL_STR(17) + ")";
      sessionColor = clrGold;
   }
   else if(inNY)
   {
      // New York only: بعد از همپوشانی تا بسته شدن (فصلی)
      sessionName  = "New York (" + TO_LOCAL_STR(nyOpen) + " - " + TO_LOCAL_STR(nyClose) + ")";
      sessionColor = clrDodgerBlue;
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
      if(TimeCurrent() - g_recalcBusySince > 10)  // v11.3: timeout کاهش یافت
      {
         if(EnableAllLogs) Print("⚠️ ForceRecalculation: mutex timeout (>30s) — auto-releasing");
         g_recalcBusy = false;
         // ادامه به اجرا
      }
      else
      {
         g_eaStatus = "🔄 مشغول - لطفاً صبر کن...";
         if(EnableAllLogs) Print("⚠️ ForceRecalculation: already busy, skipping");
         return;
      }
   }
   g_recalcBusy = true;
   g_recalcBusySince = TimeCurrent();
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
      ObjectsDeleteAll(0, HELPME_ARROW_PREFIX);   // حالا بعد از تأیید داده
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

   // 🔧 FIX: mutex برای جلوگیری از re-entrant event (MT5 bug)
   // وقتی داخل handler شیء تغییر دهی + ChartRedraw بزنی، MT5 ممکنه event دوباره fire کنه
   if(g_processingChartEvent) return;
   g_processingChartEvent = true;

   // v10.7 FIX: تغییر چارت/تایم‌فریم/اسکرول → فقط موقعیت x لیبل‌ها بروز شود
   // HLINE ها قیمت-محور هستند و روی اسکرول نیازی به بروز ندارند
   // این رویکرد فلیکر را کاملاً حذف می‌کند (بدون DeleteZoneLines + recreate)
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      if(ShowZoneLines)
      {
         SymbolZoneCfg _zc_cc;
         if(Zone_GetCfg(_Symbol, _zc_cc))
            RefreshZoneLabelPositions();
         // اگر خطوطی وجود ندارند (اولین بار یا سیمبل تغییر کرده) → بازسازی کامل
         else if(ObjectFind(0, "ZombieLine_0") < 0 && Zone_GetCfg(_Symbol, _zc_cc))
         {
            double _pip_cc = GetPipSize(_Symbol);
            // v11.91: رنگ بر اساس وجود پوزیشن و جهت
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
   }

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // ─── Preset Buttons ────────────────────────────────────────────
      if(StringFind(sparam, dashboardPrefix + "Btn_") >= 0)
      {
         string clicked = StringSubstr(sparam, StringLen(dashboardPrefix + "Btn_"));
         
         if     (clicked == "M1")  ApplyPreset(PRESET_M1);
         else if(clicked == "M5")  ApplyPreset(PRESET_M5);
         else if(clicked == "M15") ApplyPreset(PRESET_M15);
         else if(clicked == "M30") ApplyPreset(PRESET_M30);
         else if(clicked == "H1")  ApplyPreset(PRESET_H1);
         
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         SaveButtonStates();
         g_processingChartEvent = false;  // v11.2 FIX: آزاد کردن mutex قبل از ForceRecalculation
         ForceRecalculation();
         return;
      }
      
      // ─── Filter Mode Buttons ────────────────────────────────────────
      if(StringFind(sparam, dashboardPrefix + "FilterBtn_") >= 0)
      {
         string clicked = StringSubstr(sparam, StringLen(dashboardPrefix + "FilterBtn_"));
         
         if     (clicked == "Relaxed")  ApplyFilterMode(MODE_RELAXED);
         else if(clicked == "Balanced") ApplyFilterMode(MODE_BALANCED);
         else if(clicked == "Strict")   ApplyFilterMode(MODE_STRICT);
         
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         SaveButtonStates();
         g_processingChartEvent = false;  // v11.2 FIX: آزاد کردن mutex
         ForceRecalculation();
         return;
      }
      
      // ─── MA Overlay Buttons ────────────────────────────────────────
      // MQL5 از pointer پشتیبانی نمی‌کنه - هر دکمه جداگانه handle میشه
      if(StringFind(sparam, dashboardPrefix + "MABtn_") >= 0)
      {
         string clicked = StringSubstr(sparam, StringLen(dashboardPrefix + "MABtn_"));
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);

         if(clicked == "MA15")
         {
            g_maM15Active = !g_maM15Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maM15Active ? clrDodgerBlue    : clrDarkSlateGray);
            DrawOrClearMA("M15", PERIOD_M15, g_handleMA_M15, g_maM15Active);
         }
         else if(clicked == "MA30")
         {
            g_maM30Active = !g_maM30Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maM30Active ? clrMediumOrchid  : clrDarkSlateGray);
            DrawOrClearMA("M30", PERIOD_M30, g_handleMA_M30, g_maM30Active);
         }
         else if(clicked == "MA1H")
         {
            g_maH1Active = !g_maH1Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maH1Active  ? clrOrange        : clrDarkSlateGray);
            DrawOrClearMA("H1",  PERIOD_H1,  g_handleMA_H1,  g_maH1Active);
         }
         else if(clicked == "MA4H")
         {
            g_maH4Active = !g_maH4Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maH4Active  ? clrDeepPink      : clrDarkSlateGray);
            DrawOrClearMA("H4",  PERIOD_H4,  g_handleMA_H4,  g_maH4Active);
         }
         else if(clicked == "MA1D")
         {
            g_maD1Active = !g_maD1Active;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, g_maD1Active  ? clrGold          : clrDarkSlateGray);
            DrawOrClearMA("D1",  PERIOD_D1,  g_handleMA_D1,  g_maD1Active);
         }
         else if(clicked == "FEMA")
         {
            g_femaActive = !g_femaActive;
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               g_femaActive ? clrMediumSpringGreen : clrDarkSlateGray);
            DrawOrClearFEMA(g_femaActive);
         }
         // v11.2 FIX: MA buttons هم باید mutex آزاد کنن و SaveButtonStates بزنن
         SaveButtonStates();
         ChartRedraw(0);
         g_processingChartEvent = false;
         return;
      }

      // ─── Liquid Level Button ────────────────────────────────────────
      if(sparam == dashboardPrefix + "LiquidBtn")
      {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);   // دکمه رو از حالت pressed در بیار
         string statusLabel = dashboardPrefix + "LiquidStatus";

         // ═══ اگه در هر حالت غیر صفر هستیم → ریست به طلایی ══════════
         if(g_liquidBtnState != 0)
         {
            g_liquidActive   = false;
            g_liquidBtnState = 0;
            // پاک کردن خط و لیبل
            ObjectsDeleteAll(0, LQ_OBJ_PREFIX);
            g_prevSymPosCount = -1;
            // بازگشت دکمه به رنگ طلایی
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrGold);
            ObjectSetInteger(0, sparam, OBJPROP_COLOR,   clrBlack);
            // پاک کردن متن وضعیت → برگشت به حالت اولیه
            ObjectSetString (0, statusLabel, OBJPROP_TEXT,  "غیرفعال | برای فعال‌سازی کلیک کن");
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
               if(PositionGetSymbol(_pi) == _Symbol) _symPos++;

            if(_symPos == 0)
            {
               // ─── هیچ پوزیشن بازی نداریم ───────────────────────────
               g_liquidBtnState = 1;  // حالت: بدون پوزیشن
               ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrRed);
               ObjectSetInteger(0, sparam, OBJPROP_COLOR,   clrWhite);
               ObjectSetString (0, statusLabel, OBJPROP_TEXT,
                                "موقعیت بازی این نماد نداریم");
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
                  ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrGreen);
                  ObjectSetInteger(0, sparam, OBJPROP_COLOR,   clrWhite);
                  ObjectSetString (0, statusLabel, OBJPROP_TEXT,
                                   "خط با موفقیت پیدا شد ✅");
                  ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrLimeGreen);
                  Print("💧 Liquid Level: ON - line drawn successfully");
               }
               else if(lqResult == 0)
               {
                  // ─── هج کامل: خط رسم نمیشه ──────────────────────
                  g_liquidBtnState = 3;
                  ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrRed);
                  ObjectSetInteger(0, sparam, OBJPROP_COLOR,   clrWhite);
                  ObjectSetString (0, statusLabel, OBJPROP_TEXT,
                                   "هج کامل - خط قابل محاسبه نیست");
                  ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, clrGold);
                  Print("💧 Liquid Level: Hedge complete - N/A");
               }
               else
               {
                  // ─── شکست در محاسبه ──────────────────────────────
                  g_liquidBtnState = 3;
                  ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrRed);
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
            OBJPROP_BGCOLOR, (g_dirMode == 1) ? clrDarkGreen   : clrDarkSlateGray);
         ObjectSetInteger(0, dashboardPrefix + "DirBtn_All",
            OBJPROP_BGCOLOR, (g_dirMode == 0) ? clrMidnightBlue: clrDarkSlateGray);
         ObjectSetInteger(0, dashboardPrefix + "DirBtn_Sell",
            OBJPROP_BGCOLOR, (g_dirMode == 2) ? clrDarkRed      : clrDarkSlateGray);

         if(ShowDebugLogs) Print("v11 DirMode: ", (g_dirMode==1)?"Buy":(g_dirMode==2)?"Sell":"All");
         // v11.3 FIX: mutex آزاد + CSL_Execute برای رنگ فوری چارت
         // قبل از CSL_Execute mutex آزاد باشه تا re-entrant نشه
         g_processingChartEvent = false;
         SaveButtonStates();   // ذخیره dirMode جدید
         CSL_Execute();        // رنگ چارت فوری با جهت جدید
         TL_Update();
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
                  ai_states[_ri] ? clrDarkGreen : clrMaroon);
         }

         // ⑤ Filter Mode → Balanced (default)
         currentFilterMode = MODE_BALANCED;
         string fm_names[] = {"Relaxed","Balanced","Strict"};
         for(int _fi = 0; _fi < 3; _fi++)
         {
            string _fb = dashboardPrefix + "FilterBtn_" + fm_names[_fi];
            if(ObjectFind(0, _fb) >= 0)
               ObjectSetInteger(0, _fb, OBJPROP_BGCOLOR,
                  (_fi == 1) ? clrNavy : clrDarkSlateGray);
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
         // news fail cooldown رو هم پاک کن تا دوباره تلاش کنه
         GlobalVariableDel("HelpMe_NewsFailedAt_" + _Symbol);

         g_eaStatus = "↺ ریست کامل شد";
         if(EnableAllLogs) Print("↺ FULL RESET v11.5: all buttons → default, mutexes + chart color cleared");

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
            DrawNewsLines();  // رسم مجدد خطوط خبری
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
               localEnablePriceAction ? clrDarkGreen : clrMaroon);
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
               localEnableMTF ? clrDarkGreen : clrMaroon);
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
               localEnableMarketRegime ? clrDarkGreen : clrMaroon);
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
               localEnableSmartVol ? clrDarkGreen : clrMaroon);
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
               localEnableIchimoku ? clrDarkGreen : clrMaroon);
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
               localEnableFVG ? clrDarkGreen : clrMaroon);
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
               localEnableLiqSwp ? clrDarkGreen : clrMaroon);
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
               localEnableRTM ? clrDarkGreen : clrMaroon);
            ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
            
            // RTM handle: ساخت وقتی روشن میشه، حذف وقتی خاموش
            if(localEnableRTM && handleRTM_EMA == INVALID_HANDLE)
            {
               handleRTM_EMA = iMA(_Symbol, PERIOD_CURRENT, RTM_EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
               if(handleRTM_EMA == INVALID_HANDLE)
               {
                  Print("⚠️ RTM EMA handle failed - turning RTM off");
                  localEnableRTM = false;
                  ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR, clrMaroon);
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
                  localEnableSR ? clrDarkGreen : clrMaroon);
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
               srNowOn ? clrDarkGreen : clrMaroon);
            ChartRedraw(0);

            // ② کار اصلی (mutex همچنان نگه‌داشته → reentrant click نمی‌تواند toggle کند)
            if(srNowOn)
            {
               Print("📐 S/R ON: calculating...");
               DrawSRLevels();
            }
            else
            {
               int deleted = ObjectsDeleteAll(0, SR_OBJ_PREFIX);
               int manualDel = 0;
               for(int _i = ObjectsTotal(0, 0, -1) - 1; _i >= 0; _i--)
               {
                  string _nm = ObjectName(0, _i, 0, -1);
                  if(StringFind(_nm, SR_OBJ_PREFIX) == 0)
                  {
                     if(ObjectDelete(0, _nm)) manualDel++;
                  }
               }
               Print("📐 S/R OFF: Deleted ", deleted, " + manual ", manualDel, " objects");
            }

            // ③ تأیید نهایی رنگ دکمه (override هر چیزی که حین کار اصلی عوضش کرده باشد)
            ObjectSetInteger(0, sparam, OBJPROP_BGCOLOR,
               srNowOn ? clrDarkGreen : clrMaroon);
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
   
   if(ShowDebugLogs)
      Print("📰 Parsed ", g_newsCount, " news events (from=", TimeToString(from), 
            " to=", TimeToString(to), ")");
}

//+------------------------------------------------------------------+
//| Add News to Array                                                |
//+------------------------------------------------------------------+
void AddNews(NewsEvent &news)
{
   int newSize = g_newsCount + 1;
   ArrayResize(g_newsList, newSize);
   g_newsList[g_newsCount] = news;
   g_newsCount++;
}

//+------------------------------------------------------------------+
//| Draw News Lines and Labels                                       |
//+------------------------------------------------------------------+
void DrawNewsLines()
{
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
