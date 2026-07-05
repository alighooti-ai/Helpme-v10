# HelpMe v14.05 → v14.06 — مستند تغییرات

## ۰) خلاصه v14.06

دو باگ واقعی رفع شد، دو مورد مستندسازی اضافه شد، یک باگ نام فایل تصحیح شد.
از ۷ ایراد گزارش‌شده توسط تیم بررسی، ۲ مورد بحرانی/بالا واقعی بودند،
۲ مورد «نه باگ — طبق طراحی» بودند (توضیح پایین)، و بقیه مستندسازی.

---

## ۱) تغییرات v14.06

### 🔴 BUG-C1 (بحرانی): GBPNZD_InitReplay — مقیاس counter اشتباه در TF غیر H1

**محل:** `GBPNZD_InitReplay()` — حلقه اصلی Replay

**مشکل:**
`InitReplay` همیشه `for(sh=72; sh>=1)` می‌زد — ۷۲ شیفت که برابر ۷۲ کندل H1 است.
اما `Alert_CheckGBPNZDRule` به‌ازای هر کندل چارت (هر TF) یک واحد به `crisisRedH` اضافه می‌کند.

نتیجه مقیاس اشتباه:
- M1: live هر دقیقه counter++، Replay ۷۲ بار → بعد از Replay، crisisRedH مقیاس x60 اشتباه دارد
- H4: live هر ۴ ساعت، Replay ۷۲ بار (= ۲۸۸ ساعت پوشش داده) → ~۴x بیشتر از نیاز

**رفع:**
```cpp
// قبل (هاردکد):
for(int sh = 72; sh >= 1; sh--)

// بعد (TF-aware):
int _replayPeriodSec  = (g_chartPeriodSeconds > 0) ? g_chartPeriodSeconds : 3600;
int _replayBarsToScan = (int)MathMax(1, 259200 / _replayPeriodSec); // ۷۲ ساعت
for(int sh = _replayBarsToScan; sh >= 1; sh--)
```

H1: `259200/3600 = 72` — رفتار دقیقاً یکسان. M1: `4320`. H4: `18`.

**توجه مهم:** Handle های Crisis (EMA200_H1، ATR_H1، ADX_H4، ATR_D1) تغییر نکرده‌اند.
`GBPNZD_Replay_CrisisAtBar` همچنان از PERIOD_H1/H4/D1 استفاده می‌کند (طبق جدول TF ثابت کالیبره‌شده).
تنها تغییر: تعداد iteration های loop با TF چارت هماهنگ شد.

---

### 🟠 BUG-H2 (بالا): OnDemand_RunAndSend — FOREIGN بدون چک موجودیت داده

**محل:** `OnDemand_RunAndSend()` — قبل از حلقه replay

**مشکل:**
اگر broker سمبل FOREIGN در PERIOD_CURRENT کافی نداشت، `CopyClose` در loop صفر برمی‌گرداند
و counter ها صفر می‌ماندند — بدون هیچ اخطاری.

**رفع:**
```cpp
int _availBars = iBars(broker, PERIOD_CURRENT);
if(_availBars < odBarsToScan)
{
    Print("⚠️ FOREIGN ", broker, " only ", _availBars, " bars ...");
    odBarsToScan = _availBars;
}
if(odBarsToScan < 10)
{
    Print("❌ FOREIGN insufficient data — skipping");
    OnDemand_Cleanup();
    return;
}
```

---

### 🟡 BUG-M3 (رفع شد): نام فایل در هدر اشتباه

خط اول `//| HelpMe_V14_04.mq5 |` → تصحیح به `//| HelpMe_V14_06.mq5 |`

---

### 🟡 BUG-M1 و BUG-M2 (مستندسازی — نه باگ)

**BUG-M1:** `Rule_Transition` هر تیک فراخوانی می‌شود ولی counter ها فقط سر کندل آپدیت می‌شوند. این **عمدی** است: STOP فوری (Spike جدید وسط کندل) باید هر تیک واکنش دهد. counter ها بین دو کندل ثابت‌اند. کامنت توضیح‌دهنده اضافه شد.

**BUG-M2:** PATCH-7 (آستانه آخر هفته پویا) و P2 (بررسی SYMBOL_TIME) مکمل هم هستند. double-skip ممکن نیست چون gate واحد `barBoundaryReached` هر دو شرط را با هم چک می‌کند. کامنت توضیح‌دهنده اضافه شد.

---

### ❌ BUG-C2 و BUG-H1 — بررسی شد، رفع نشد (طبق طراحی)

**BUG-C2 (Zone_IsConfirmedByH1):** این تابع عمداً H1-only است و در جدول «چیزهایی که تغییر نکرده‌اند» (v14.03) قرار دارد. ZombieH1ConfirmMinutes روی H1 کالیبره شده و دست‌زدن به آن بدون بکتست مجدد خطرناک است.

**BUG-C2 (TL_Update paths):** مسیر CSL_UpdateProfitOnly تنها مسیر TL_Update خارج از isNewBar است. PATCH-4 (v14.05) g_lastBarCloseTime را قبل از TL_Update ست می‌کند. FIX-3 (v14.04) OnChartEvent را پوشش می‌دهد. هر دو مسیر پوشیده است.

---

## ۲) وضعیت کالیبراسیون — چه چیزی نیاز به بکتست دارد

این بخش برای تیم توسعه است تا قبل از لایو واقعی روی EURGBP و AUDCAD بدانند کجا اعداد
«حدسی» هستند و کجا واقعاً کالیبره شده‌اند.

### GBPNZD — کاملاً کالیبره‌شده ✅

همه آستانه‌های زیر از بکتست واقعی روی GBPNZD استخراج شده‌اند:

| مؤلفه | آستانه کالیبره‌شده | محل در کد |
|-------|-------------------|-----------|
| Crisis → Red | `rc>=3 + flowAgainst>=th_RedA_Flow + adx>th_RedA_ADX` | `Crisis_GetThresholds` — شاخه GBPNZD |
| Crisis → Orange | چندین شرط ترکیبی ADX + Flow + trendScore | همان |
| Rule STOP | spike==2 + crisis>=1 یا spike==1 + crisis∈{Orange,Red} | `Rule_Transition` |
| Rule CLOSE | crisisRedH>=6 یا (crisis==Red + haFlag) | `Rule_Transition` |
| Rule RESUME | cleanH>=24 | `Rule_Transition` |
| Spike weights | wM15=0.10، wM30=0.15، wH1=0.35، wH4=0.25، wD1=0.15 | `Rule_SpikeWeightsForSymbol` — شاخه GBPNZD |
| HighAlert | ADX>=35 + flowAgainst>=7 | `Alert_CheckGBPNZDRule` |
| Flow gate برای Spike | flowRed < -4.0، flowYellow [-4,2) + score>=2 | `GBPNZD_Replay_SpikeAtBar` |

### EURGBP — فقط معماری کالیبره‌شده، اعداد حدسی ⚠️

EURGBP در v14.00 به سیستم اضافه شد. معماری (Sister table، Flow، Spike) درست است
اما آستانه‌های کمیّ از روی منطق GBPNZD تخمین زده شده‌اند. **باید بکتست شوند:**

| مؤلفه | وضعیت | توضیح |
|-------|-------|-------|
| `Crisis_GetThresholds` — شاخه EURGBP | ❌ **وجود ندارد** — از پیش‌فرض AUDCAD استفاده می‌شود | باید جداگانه کالیبره شود |
| Spike weights EURGBP | ❌ **یکسان با AUDCAD** (wH1=0.30، wH4=0.30 و غیره) | `Rule_SpikeWeightsForSymbol` — شاخه EURGBP |
| Flow gate Spike | ❌ **یکسان با GBPNZD** (-4.0 / 2.0) | در `GBPNZD_Replay_SpikeAtBar` |
| HighAlert threshold | ❌ **یکسان با GBPNZD** (ADX>=35 + flow>=7) | ممکن است برای EURGBP مقدار متفاوت بهتر باشد |
| Sister_EURGBP وزن‌ها | ⚠️ **از روی منطق تعیین شده** | GBPUSD:1.0، EURGBP:-1.0، EURUSD:0.8 و غیره |

### AUDCAD — پایه/پیش‌فرض، نسبتاً کالیبره ⚠️

AUDCAD پیش‌فرض سیستم است و از ابتدا وجود داشت اما بکتست جداگانه روی آن محدود بوده:

| مؤلفه | وضعیت |
|-------|-------|
| `Crisis_GetThresholds` — پیش‌فرض | ⚠️ این مقادیر در واقع پیش‌فرض اولیه‌اند، نه کالیبره‌شده برای AUDCAD |
| Spike weights AUDCAD | ⚠️ wM15=0.10، wM30=0.15، wH1=0.30، wH4=0.30، wD1=0.15 |
| Rule threshold ها | ⚠️ از همان Rule_Transition مشترک — تست روی AUDCAD کم بوده |

### توصیه برای کالیبراسیون

ترتیب پیشنهادی:
1. بکتست EURGBP روی ۲۰۲۴-۲۰۲۶ → ستون‌های Crisis/Spike/Rule را با CSV خروجی بررسی کنید
2. برای EURGBP یک `Crisis_GetThresholds` اختصاصی در کد بسازید (شاخه `c=="EURGBP"`)
3. Spike weights EURGBP را تنظیم کنید (`Rule_SpikeWeightsForSymbol` — شاخه EURGBP)
4. بکتست AUDCAD مشابه و اگر لازم بود آستانه‌های پیش‌فرض را override کنید

---

# HelpMe v14.02 → v14.03 — مستند تغییرات

## ۰) خلاصه v14.03 — یکپارچه‌سازی موتور Rule/Spike با تایم‌فریم چارت

### مشکل اصلی که این نسخه حل کرد

در v14.02، Rule/Spike در لایو هر تیک (و هر ۳۰ ثانیه از OnTimer) محاسبه می‌شدند،
در حالی که تمام آستانه‌های Rule (`crisisRedH >= 2` برای STOP، `crisisRedH >= 6`
برای CLOSE و غیره) از **بکتست کندل-محور** استخراج شده‌اند. نتیجه: لایو سیگنال‌هایی
می‌داد که در بکتست وجود نداشتند — اختلاف تا ۵۹ دقیقه در H1.

### راه‌حل

همه چیزهای مربوط به Rule و Spike حالا فقط با بسته‌شدن کندل در تایم‌فریم چارت
محاسبه می‌شوند. اگه اکسپرت روی H1 باشد: هر ساعت. اگه M1: هر دقیقه. اگه H4:
هر ۴ ساعت. بکتست و لایو دیگر یکسان رفتار می‌کنند.

---

## ۱) تغییرات v14.03 — فهرست کامل

### 🔴 ARCH-01 (بحرانی): موتور یکپارچه کندل-محور — حذف محاسبه تیک-محور

**متغیرهای جدید (global):**
```cpp
int      g_chartPeriodSeconds = 0;   // طول کندل چارت (ثانیه) — در OnInit
datetime g_lastBarCloseTime   = 0;   // آخرین کندلی که Rule/Spike محاسبه شد
```

**تابع جدید:**
```cpp
bool Chart_IsNewBarClosed()
// true فقط در اولین تیک بعد از بسته‌شدن هر کندل (هر TF)
// تنها قرارگاه تصمیم «آیا کندل جدیدی بسته شده؟» در کل سیستم
```

**`OnInit()` — مقداردهی:**
```cpp
g_chartPeriodSeconds = (int)PeriodSeconds(PERIOD_CURRENT);
g_lastBarCloseTime   = iTime(_Symbol, PERIOD_CURRENT, 0); // کندل ناقص جاری skip
Print("📊 HelpMe v14.03 — Chart TF:", EnumToString(PERIOD_CURRENT), "...");
// هشدار اگه TF >= D1 باشد
```

**`OnTimer()` — حذف TL_Update:**
- `TL_Update()` از OnTimer حذف شد (قبلاً هر ۳۰ ثانیه صدا زده می‌شد)
- TL_Update فقط از مسیر `isNewBar` در `CSL_Execute` داخل `OnTick` صدا زده می‌شود
- جلوگیری از double-calc و از بین بردن اجرای mid-candle

**`Alert_CheckGBPNZDRule()` — جایگزینی مرز ساعتی با مرز کندل:**
- قبل: `thisHour > g_gbpnzdLastH` (مرز H1 هاردکد)
- بعد: `g_lastBarCloseTime > g_gbpnzdLastH` (مرز تایم‌فریم چارت)
- `g_gbpnzdLastH` حالا timestamp کندل بسته نگه می‌دارد (نه timestamp مرز ساعت)
- محافظت آخر هفته (v13.49 P2) کاملاً حفظ شده

**`GBPNZD_InitReplay()` — g_gbpnzdLastH صحیح:**
- قبل: `g_gbpnzdLastH = (datetime)(iTime(H1,1) / 3600 * 3600)` (هاردکد H1)
- بعد: `g_gbpnzdLastH = iTime(_Symbol, PERIOD_CURRENT, 1)` (تایم‌فریم چارت)

---

### 🔴 ARCH-02 (بحرانی): FOREIGN از تایم‌فریم چارت پیروی می‌کند

**`OnDemand_RunAndSend()` — تایم‌فریم پویا:**
- قبل: `for(int h1Shift = 72; h1Shift >= 1; h1Shift--)` — H1 هاردکد
- بعد:
```cpp
ENUM_TIMEFRAMES odTF         = PERIOD_CURRENT;
int             odPeriodSec  = (int)PeriodSeconds(odTF);
int             odBarsToScan = (int)MathMax(72, 259200 / MathMax(odPeriodSec, 1));
// 259200 ثانیه = ۷۲ ساعت | MathMax(72,...) = حداقل ۷۲ کندل تضمین
for(int odShift = odBarsToScan; odShift >= 1; odShift--)
```

**مثال:**
- چارت H1: ۷۲ کندل H1 ≈ ۷۲ ساعت
- چارت M1: ۴۳۲۰ کندل M1 ≈ ۷۲ ساعت
- چارت H4: ۷۲ کندل H4 (MathMax گارانتی) ≈ ۲۸۸ ساعت

**متن تلگرام آپدیت شد:** نمایش تعداد کندل و نام TF دینامیک (نه هاردکد «H1»)

---

### چیزهایی که تغییر نکرده‌اند (طبق طراحی — تایم‌فریم ثابت و کالیبره)

| مؤلفه | تایم‌فریم | دلیل |
|-------|-----------|------|
| `FlowEvaluate()` | H4 | FLOW روی H4 کالیبره شده |
| `Zone_IsConfirmedByH1()` | H1 | ZOMBIE روی H1 کالیبره شده |
| چراغ‌های D1 روند بزرگ | D1 | تعریف «روند کلی» D1 است |
| ATR D1 در Crisis_GetThresholds | D1 | نرمال‌سازی نوسان روزانه |
| `GBPNZD_Replay_CrisisAtBar` | H1 | Replay recovery از H1 handles |
| `GBPNZD_Replay_SpikeAtBar` | H1 | Replay recovery از H1 handles |
| `DrawNewsLines()` | — | زمان مطلق خبر |
| Dashboard و UI | — | قیمت لحظه‌ای، هر تیک |

---

## ۲) رفتار انتظاری بعد از پچ

| تایم‌فریم چارت | حداکثر تأخیر Rule | توضیح |
|----------------|-----------------|-------|
| M1 | ۵۹ ثانیه | سریع‌ترین |
| M5 | ~۵ دقیقه | — |
| H1 | ۵۹ دقیقه | معمول‌ترین |
| H4 | ~۴ ساعت | — |
| D1 | ~۲۴ ساعت | هشدار در OnInit |

**واگرایی بکتست/لایو:** صفر — هر دو روی کندل بسته تصمیم می‌گیرند.

---

## ۳) چک‌لیست تست
## ۴) تکمیل v14.03 — سه باگ باقی‌مانده رفع شد

پس از بررسی پچ اصلی، سه نقص اجرایی شناسایی و رفع شد:

### 🔴 FIX-A: `Spike_TFScore` — از کندل بسته بخواند (shift=1)

**مشکل:** `Spike_TFScore` با `CopyHigh/Low/Open/Close(..., 0, ...)` کندل **در حال شکل‌گیری** را ارزیابی می‌کرد.

**رفع:** پارامتر `shift=1` اضافه شد:
```cpp
double Spike_TFScore(ENUM_TIMEFRAMES tf, int atrPeriod = 14, int shift = 1)
// CopyHigh(_Symbol, tf, shift, need, high) — shift=1 = کندل کاملاً بسته
```
همه فراخوانی‌های داخل `Calc_SpikeDetector` به `shift=1` تغییر کردند.

### 🔴 FIX-B: `g_isNewChartBar` + `runRuleBlock` — gate کامل در `TL_Update`

**مشکل:** `Calc_SpikeDetector`، `Alert_CheckGBPNZDRule` و `PrevSnapshot` در هر فراخوانی `TL_Update` اجرا می‌شدند — نه فقط در بستن کندل.

**رفع:** متغیر جدید `g_isNewChartBar` و `runRuleBlock` در `TL_Update`:
```cpp
bool g_isNewChartBar = false; // در OnTick: if(isNewBar) g_isNewChartBar=true; در پایان OnTick: =false
// در TL_Update:
bool runRuleBlock = g_isNewChartBar || firstRuleRun;
```

همه مکان‌های حساس gate شدند:

| مسیر | مورد gate‌شده |
|------|--------------|
| هج | `Calc_SpikeDetector`, Spike جهت‌دار, `Alert_CheckGBPNZDRule` |
| بدون پوزیشن | `Calc_SpikeDetector`, `Alert_CheckGBPNZDRule`, PrevCrisis/PrevSpike snapshot |
| با پوزیشن | `Calc_SpikeDetector`, PrevCrisis Buy/Sell, `Alert_CheckGBPNZDRule` |

### 🟡 FIX-C: `Calc_SpikeDetector` از `OnTimer` و `StatusQuery` حذف شد

- **OnTimer:** حذف کامل — Spike دیگر هر ۶۰ ثانیه محاسبه نمی‌شود
- **StatusQuery:** از `g_spikeScore` کش‌شده استفاده می‌کند؛ `Calc_SpikeDetector` فقط در `firstRun` (`g_lightSpike==-1`) فراخوانده می‌شود

---


- [ ] کامپایل بدون خطا
- [ ] H1: Rule بعد از هر ساعت آپدیت می‌شود (نه هر ۳۰ ثانیه)
- [ ] M1: Rule بعد از هر دقیقه آپدیت می‌شود
- [ ] Dashboard و قیمت هنوز هر تیک آپدیت می‌شوند
- [ ] FOREIGN روی چارت H1: AUDCAD وضعیت از ۷۲ کندل H1
- [ ] FOREIGN روی چارت M1: AUDCAD وضعیت از ۴۳۲۰ کندل M1
- [ ] بکتست GBPNZD H1: نتایج قبلی تغییر نکرده‌اند
- [ ] بعد از آخر هفته: دوشنبه اولین تیک Rule درست محاسبه می‌شود

---

# HelpMe v14.01 → v14.02 — مستند کامل تغییرات (از v13.51 تا امروز)


## ۰) v14.02 — فیکس خطای کامپایل (بعد از تحویل v14.01)

موقع کامپایل v14.01 در MetaEditor این خطا می‌آمد:

```
structures or classes containing objects are not allowed   خط 8781, 8782, 8783
built-in: int ArrayCopy(T&[...],const T&[...],int,int,int)
```

**علت:** تابع `Sister_GetTable()` (اضافه‌شده در v14.00) برای کپی جدول
Sister از `ArrayCopy()` استفاده می‌کرد. `struct SisterEntry` یک عضو
`string sym` دارد؛ در MQL5، `string` نوع «آبجکت» حساب می‌شود (رفرنس‌کانت
داخلی دارد) و `ArrayCopy()` بیلت‌این فقط برای آرایه‌هایی از نوع ساده
(POD — بدون عضو رشته/آبجکت) کار می‌کند. قبل از v14.00 این تابع اصلاً
وجود نداشت، پس این باگ قبلاً هیچ‌جا خودش را نشان نداده بود.

**راه‌حل:** یک تابع کمکی `Sister_CopyArr()` نوشته شد که همان آرایه را
عنصر‌به‌عنصر (فیلد به فیلد) کپی می‌کند — نتیجه‌اش دقیقاً همان چیزی است که
`ArrayCopy()` قرار بود بدهد، فقط با یک حلقه‌ی دستی به‌جای فراخوانی
بیلت‌این:

```cpp
void Sister_CopyArr(SisterEntry &dst[], const SisterEntry &src[])
{
   int n = ArraySize(src);
   ArrayResize(dst, n);
   for(int i = 0; i < n; i++)
   {
      dst[i].sym        = src[i].sym;
      dst[i].weight     = src[i].weight;
      dst[i].signForBuy = src[i].signForBuy;
      dst[i].negMult    = src[i].negMult;
   }
}
```

سه فراخوانی `ArrayCopy(outArr, SISTER_...)` داخل `Sister_GetTable()` با
`Sister_CopyArr(outArr, SISTER_...)` جایگزین شدند — همان سه خط، همان
منطق انتخاب (GBPNZD/EURGBP/پیش‌فرض AUDCAD)، بدون تغییر رفتاری.

بقیه‌ی فایل چک شد: تنها همین سه خط از `ArrayCopy()` روی آرایه‌ی
`SisterEntry` استفاده می‌کردند؛ پنج فراخوانی دیگر `ArrayCopy()` در فایل
(برای ساخت بدنه‌ی عکس تلگرام) روی آرایه‌ی `uchar` ساده هستند و ربطی به
این خطا ندارند — دست نخوردند.

**خروجی این پچ: `HelpMe_V14_02.mq5`** — از نظر رفتاری با v14.01 یکی است؛
فقط قابل کامپایل شد.

---


مرجع کد قبلی: `HelpMe_V13_51_mq5.txt` (v13.51)
مرجع میانی: `HelpMe_V14_00.mq5` (پچ اول — تعمیم چند سمبلی + FOREIGN)
**خروجی نهایی این سند: `HelpMe_V14_01.mq5`** (پچ تیمی — یکی‌سازی Rule واقعی)

این فایل برای این نوشته شده که اگر فقط همین یک `.md` را به کسی بدهید،
بدون نیاز به فایل‌های دیگر، کل مسیر تصمیم → اجرا → نقص → رفع نقص را بفهمد.

---

## ۱) از v13.51 چه تصمیمی گرفته شد و چرا

سیستم تا v13.51 فقط برای **GBPNZD** طراحی شده بود: کل ماشین‌حالت Rule
(GREEN → STOP → CLOSE → RESUME)، محاسبه‌ی Crisis/Spike، و ری‌پلی بعد از
ری‌استارت، همه‌جا با شرط صریح `StringFind(_Symbol,"GBPNZD")` قفل بودند.

دو نیاز جدید پیش آمد که باعث این پچ شدند:

1. **توسعه به AUDCAD و EURGBP (نامش را در کد گذاشتیم SELF):**
   می‌خواستیم بدون بازنویسی، همان منطق Rule/Crisis/Spike/Replay که برای
   GBPNZD جواب داده، عیناً روی این دو جفت‌ارز هم کار کند — چه در چارت لایو
   چه در Strategy Tester (بکتست) — تا بشود کالیبراسیون‌شان را هم با بکتست
   واقعی انجام داد.
2. **وضعیت لحظه‌ای بدون باز بودن چارت (نامش را گذاشتیم FOREIGN):**
   وقتی چارت فقط روی یکی از این سه سمبل (مثلاً GBPNZD) باز است، بخواهیم با
   فرستادن فقط اسم سمبل دیگر (مثلاً `AUDCAD`) در تلگرام، جواب متنی و
   جهت‌دار (Buy/Sell جدا) از وضعیت آن سمبل بگیریم — بدون این‌که اکسپرت آن
   سمبل در پس‌زمینه دائم اجرا شود (صفر بار CPU اضافه‌ی مستمر؛ فقط لحظه‌ی
   درخواست محاسبه، بعد آزاد‌سازی).

قرار بر این بود که:
- هیچ تغییری در رفتار موجود GBPNZD ایجاد نشود (صفر ریسک رگرسیون).
- کالیبراسیون آستانه‌ها (thresholds) برای AUDCAD/EURGBP فعلاً از روی مقادیر
  پیش‌فرض موجود در کد استفاده شود و **بعد از بکتست واقعی** تنظیم دقیق شود؛
  الان فقط باید «معماری» درست باشد.

---

## ۲) v14.00 — چه کاری انجام شد (پچ اول)

### بخش SELF — رفع قفل تک‌سمبلی (۴ باگ واقعی پیدا و رفع شد)

| # | مشکل | راه‌حل |
|---|------|--------|
| 1 | ۹ نقطه `StringFind(_Symbol,"GBPNZD")` به‌عنوان قفل — روی AUDCAD/EURGBP هیچ‌کدام اجرا نمی‌شدند | همه با `IsRuleSymbol(_Symbol)` جایگزین شدند (سمبل ∈ {GBPNZD, AUDCAD, EURGBP}) |
| 2 | 🐛 در `GBPNZD_Replay_CrisisAtBar`، FLOW فقط وقتی `baseSym=="GBPNZD"` بود محاسبه می‌شد — روی سمبل‌های دیگر همیشه صفر/خنثی می‌ماند | جدول Sister حالا با `Sister_GetTable(sym,...)` بر اساس خود سمبل انتخاب می‌شود |
| 3 | 🐛 در `GBPNZD_Replay_SpikeAtBar`، وزن‌دهی تایم‌فریم‌ها همیشه هاردکد وزن GBPNZD بود — Spike بازسازی‌شده در بکتست با Spike زنده ناهمگون می‌شد | تابع مشترک `Rule_SpikeWeightsForSymbol()` ساخته شد؛ هم لایو هم Replay از یک منبع وزن می‌گیرند |
| 4 | ۸ فراخوانی مستقیم `FlowEvaluate(SISTER_GBPNZD,...)` در مسیرهای لایو و در `StatusQuery_BuildReport` هاردکد GBPNZD بودند | با `Rule_FlowForSymbol(_Symbol, forBuy)` جایگزین شدند |
| 5 | `Crisis_GetThresholds()` فقط `_Symbol` را می‌دید — برای محاسبه‌ی یک سمبل دیگر (FOREIGN) قابل استفاده نبود | پارامتر اختیاری `symOverride=""` اضافه شد؛ رفتار پیش‌فرض بدون پارامتر عوض نشد |
| 6 | کلیدهای GlobalVariable و فایل snapshot ساعتی هاردکد بودند — اگر AUDCAD/EURGBP همزمان اجرا می‌شدند، state‌شان قاطی می‌شد | پیشوند/نام فایل بر اساس سمبل پارامتری شد؛ برای GBPNZD دقیقاً همان کلید/فایل قدیمی حفظ شد |

### بخش FOREIGN — ویژگی جدید (وضعیت لحظه‌ای بدون اکسپرت زنده)

معماری «درخواست → گرم‌شدن → محاسبه → ارسال → آزادسازی»:

1. کاربر در تلگرام می‌نویسد `AUDCAD` یا «وضعیت AUDCAD» (فارسی/انگلیسی، substring نه exact-match).
2. اگر همان سمبل چارت باشد → مسیر status معمولی (با عکس) اجرا می‌شود.
3. اگر سمبل دیگری باشد → `OnDemand_RequestSymbol()`: سمبل بروکر (با پسوند صحیح) پیدا می‌شود، ۴ handle موقت (EMA200 H1، ATR H1، ADX H4، ATR D1) ساخته می‌شود، state=`WARMING`.
4. `OnDemand_Poll()` هر ۱ ثانیه (از OnTimer) تا حداکثر ۲۰ ثانیه صبر می‌کند تا داده کافی شود.
5. `OnDemand_RunAndSend()`: با دو تابع مستقل و پارامتری `Generic_ReplayCrisisAtBar` و `Generic_ReplaySpikeAtBar`، ۷۲ ساعت گذشته replay می‌شود؛ برای Buy و Sell جدا شمارنده ساخته می‌شود.
6. پوزیشن واقعی (اگر باشد) از `PositionsTotal()` + `HM_PositionBelongsToSymbol` پیدا و سود/ساعت بازشدنش گزارش می‌شود؛ اگر نبود، «معامله باز نداریم» گفته می‌شود.
7. دو پیام جدا (Buy و Sell) فرستاده می‌شود.
8. `OnDemand_Cleanup()`: همه handle ها release می‌شوند، state=`IDLE` — بین دو درخواست هیچ محاسبه‌ای در پس‌زمینه نیست (صفر بار CPU دائمی).

**توابع جدید v14.00:** `CleanSymbol`, `IsRuleSymbol`, `Sister_GetTable`,
`Rule_FlowForSymbol`, `Rule_SpikeWeightsForSymbol`, `Rule_GVPrefix`,
`HM_HourStateFile`, `Generic_ReplayCrisisAtBar`, `Generic_ReplaySpikeAtBar`,
`OnDemand_ResolveBrokerSymbol`, `OnDemand_Cleanup`, `OnDemand_RequestSymbol`,
`OnDemand_Poll`, `OnDemand_RunAndSend`, `OD_LightText`, `OD_RuleLevelText`.

---

## ۳) نقصی که در v14.00 باقی مانده بود (چرا این پچ لازم شد)

بعد از تحویل v14.00، بازبینی تیمی نشان داد یک نقص واقعی و مهم در قلب
ویژگی FOREIGN باقی مانده بود:

### 🔴 مشکل اصلی: `OnDemand_RunAndSend()` هرگز `Rule_Transition()` واقعی را صدا نمی‌زد

به‌جایش این خط تخمینی را داشت:
```cpp
levelBuy  = (crisisRedHBuy  >= 2) ? 1 : 0;
levelSell = (crisisRedHSell >= 2) ? 1 : 0;
```

این با Rule واقعی سیستم (که همه‌جای دیگر — لایو `Alert_CheckGBPNZDRule`،
بکتست، `GBPNZD_InitReplay` — از `Rule_Transition` مشترک استفاده می‌کند)
**یکی نبود**:

| | Rule واقعی (`Rule_Transition`) | تخمین اشتباه v14.00 |
|---|---|---|
| STOP | `(spike==2 && crisis>=1)` یا `(spike==1 && crisis∈{Orange,Red})` | فقط `crisisRedH>=2` (معیار کاملاً متفاوت) |
| CLOSE | `(crisis==Red && HighAlert)` یا `(crisisRedH>=6)` | **اصلاً وجود نداشت** |
| RESUME | `cleanH>=24` | **اصلاً وجود نداشت** |

نتیجه: عدد «Rule» که در پیام تلگرام FOREIGN دیده می‌شد، در واقع یک معیار
دیگر بود، نه همان Rule که در GBPNZD/SELF می‌بینیم — دقیقاً همان کلاس باگی
که کل ریفکتور v13.50 (RULE-01: تجمیع منطق Rule در دو تابع مشترک
`Rule_UpdateCounters`/`Rule_Transition`) قرار بود برای همیشه حلش کند. توضیح
«محدودیت ذاتی: چون accumulator زنده نداریم CLOSE قابل تشخیص نیست» که در
داک v14.00 آمده بود **درست نبود** — CLOSE (`crisisRedH>=6` یا
`crisis=Red + HighAlert`) کاملاً از روی کندل‌های بسته‌ی replay قابل
محاسبه است؛ هیچ‌کدام از این دو شرط به accumulator ساعتِ در حال شکل‌گیری
نیاز ندارند.

### 🟡 مشکل فرعی: پیش‌فرض `Sister_GetTable()` ناسازگار با بقیه‌ی سیستم

`Sister_GetTable()` برای سمبل ناشناخته از `SISTER_GBPNZD` استفاده می‌کرد،
در حالی که بقیه‌ی سیستم (`Crisis_GetThresholds`، وزن‌دهی
`Calc_SpikeDetector`) قاعده‌ی معکوس دارند: پایه/پیش‌فرض = AUDCAD،
override فقط برای GBPNZD.

---

## ۴) v14.01 — چه کاری الان انجام شد (این پچ)

### ✅ فیکس ۱ — `Generic_ReplayCrisisAtBar` حالا `flowScore` و `adxVal` را هم خروجی می‌دهد

امضای قبلی:
```cpp
int Generic_ReplayCrisisAtBar(string sym, int hEMA200, int hATR_H1, int hADX_H4, int hATR_D1,
                               int h1Shift, bool forBuy, int &rcOut)
```
امضای جدید:
```cpp
int Generic_ReplayCrisisAtBar(string sym, int hEMA200, int hATR_H1, int hADX_H4, int hATR_D1,
                               int h1Shift, bool forBuy,
                               double &flowScoreOut, double &adxValOut, int &rcOut)
```
هیچ محاسبه‌ی جدیدی اضافه نشد — فقط دو متغیر محلی که از قبل درون تابع
محاسبه می‌شدند (`flowScore`، `adxVal`) قبل از هر `return` در پارامتر
خروجی نوشته شدند. تنها نقطه‌ی فراخوانی این تابع در کل فایل
(`OnDemand_RunAndSend`) همزمان آپدیت شد — پس ریسک ناسازگاری صفر است.

### ✅ فیکس ۲ — `OnDemand_RunAndSend` حالا از `Rule_Transition` واقعی استفاده می‌کند

حلقه‌ی ۷۲-ساعته الان دقیقاً همان الگوی `GBPNZD_InitReplay` را برای هر دو
جهت (Buy/Sell) اجرا می‌کند:

```cpp
bool haBuy  = (adxBuy  >= 35.0) && (flowBuy  < -7.0);
bool haSell = (adxSell >= 35.0) && (flowSell >  7.0);

Rule_UpdateCounters(hourRedBuy,  hourDirtyBuy,  crisisRedHBuy,  cleanHBuy);
Rule_Transition(crBuy, spBuy, haBuy, crisisRedHBuy, cleanHBuy, levelBuy, reasonBuy);

Rule_UpdateCounters(hourRedSell, hourDirtySell, crisisRedHSell, cleanHSell);
Rule_Transition(crSell, spSell, haSell, crisisRedHSell, cleanHSell, levelSell, reasonSell);
```

نکات مهم این فیکس:
- خط تخمینی قدیمی (`levelBuy = (crisisRedHBuy>=2)?1:0`) کاملاً حذف شد.
- شرط `if(crBuy < 0 || spBuyDum < 0) continue;` هم حذف شد — چون
  «رد کردن (skip) ساعت» با رفتار واقعی `GBPNZD_InitReplay` فرق می‌کرد:
  آنجا داده‌ی ناقص = **خنثی (صفر)** در نظر گرفته می‌شود، نه این‌که آن ساعت
  اصلاً در شمارنده‌ی `CleanH` دیده نشود. الان همان رفتار (`spBuy = (spBuyDum>=0)?spBuyDum:0`) پیاده‌سازی شده.
- `OD_RuleLevelText()` نیازی به تغییر نداشت — از قبل هر سه سطح (0/1/2) را
  پشتیبانی می‌کرد؛ فقط حالا واقعاً مقدار ۲ (CLOSE) هم ممکن است برسد.
- متن هشدار تلگرام که می‌گفت «فقط STOP قابل تشخیص است» حذف و به هشدار
  درست‌تری («بدون accumulator ساعت نیمه‌کاره، ممکن است چند دقیقه تأخیر
  داشته باشد») تغییر یافت — چون دیگر درست نبود.

### ✅ فیکس ۳ — پیش‌فرض `Sister_GetTable()` از GBPNZD به AUDCAD

```cpp
int Sister_GetTable(string sym, SisterEntry &outArr[])
{
   string c = CleanSymbol(sym);
   if(c == "GBPNZD") { ArrayCopy(outArr, SISTER_GBPNZD); return ArraySize(outArr); }
   if(c == "EURGBP") { ArrayCopy(outArr, SISTER_EURGBP); return ArraySize(outArr); }
   ArrayCopy(outArr, SISTER_AUDCAD);   // پیش‌فرض/پایه — یکدست با Crisis_GetThresholds
   return ArraySize(outArr);
}
```
برای سه سمبل فعلی (GBPNZD/EURGBP/AUDCAD) این تغییر **هیچ رفتاری را عوض
نمی‌کند** چون هر سه شاخه‌ی صریح از قبل وجود دارند و همیشه یکی از آن‌ها
اجرا می‌شود؛ فقط برای یکدستی با بقیه‌ی سیستم و برای سمبل چهارم احتمالی در
آینده است.

### چیزهایی که تیم گفت «دست نزنید» و دست نخورد

- `Rule_FlowForSymbol()` روی ۷ نقطه‌ی لایو — قبلاً درست فیکس شده بود.
- تشخیص پوزیشن واقعی با `PositionsTotal()` + `HM_PositionBelongsToSymbol` + `DetectCentAccount`.
- state machine `OD_STATE_IDLE/WARMING` با گارد «یک درخواست در یک لحظه».
- تشخیص کلمه‌ی سمبل به‌صورت substring (نه exact-match).

---

## ۵) وضعیت فعلی رفتار سیستم (بعد از v14.01)

### SELF (چارت روی خودِ سمبل باز است)
- روی GBPNZD: **صفر تغییر رفتار** نسبت به v13.51 (همه‌جا branch پیش‌فرض/GBPNZD مقدار قبلی را برمی‌گرداند).
- روی AUDCAD/EURGBP (لایو یا بکتست): Rule/Crisis/Spike/Replay دقیقاً با همان منطق GBPNZD، ولی با جدول Sister و وزن‌دهی مخصوص خودشان اجرا می‌شود.

### FOREIGN (چارت روی سمبل دیگری باز است، وضعیت یک سمبل دیگر را می‌پرسید)
- Rule (STOP/CLOSE/RESUME) الان **همان** ماشین‌حالت واقعی سیستم است — نه یک تخمین جدا.
- محدودیت واقعی باقی‌مانده (نه رفع‌شدنی بدون اکسپرت زنده روی آن سمبل):
  accumulator ساعت **در حال شکل‌گیری** (نیمه‌کاره) در دسترس نیست، چون فقط
  با اجرای زنده‌ی EA روی همان چارت ساخته می‌شود. یعنی جواب FOREIGN ممکن
  است تا چند دقیقه (باقی‌مانده‌ی ساعت جاری) با جوابی که همان لحظه از
  اکسپرت زنده‌ی آن سمبل می‌گرفتید فرق کند — نه بیشتر از آن.
- برای Buy و Sell دو پیام جدا («پوزیشن مجازی») فرستاده می‌شود؛ اگر واقعاً
  پوزیشن باز باشد، سود و ساعت باز شدنش هم گفته می‌شود.

---

## ۶) چیزهایی که هنوز کالیبره نشده‌اند (نیاز به بکتست واقعی)

- آستانه‌های Crisis برای EURGBP: فعلاً از مقادیر پیش‌فرض (همان AUDCAD)
  استفاده می‌کند — `Crisis_GetThresholds` فقط GBPNZD را جدا کالیبره کرده.
- آستانه‌های Flow-gating در Spike (`-4.0` / `2.0`) برای هر سه سمبل یکسان است.
- وزن‌دهی Spike برای AUDCAD/EURGBP یکسان است (فقط GBPNZD وزن جدا دارد) —
  دقیقاً همان چیزی که در `Calc_SpikeDetector` زنده هم از قبل همین‌طور بود.

طبق دستور اولیه، اینها عمداً کالیبره نشده مانده‌اند تا بعد از گرفتن
بکتست واقعی روی AUDCAD/EURGBP تنظیم شوند.

---

## ۷) تست پیشنهادی قبل از لایو

1. **بکتست AUDCAD** و **EURGBP** جدا — ستون‌های Rule/Crisis/Spike در CSV
   نباید خالی/صفر باشند (باگ اصلی گزارش‌شده در ابتدای این مسیر).
2. **بکتست GBPNZD** را هم دوباره بگیرید و CSV را با نسخه v13.51 دیف کنید
   — باید **صفر تفاوت** باشد (منطق GBPNZD دست‌نخورده مانده).
3. **سناریوی CLOSE در FOREIGN:** یک بازه‌ی زمانی که می‌دانید باید CLOSE
   بدهد (مثلاً با شبیه‌سازی یا مقایسه با CSV بکتست همان بازه) را بعد از
   این پچ تست کنید — قبل از پچ `OD_RuleLevelText` هرگز CLOSE نشان
   نمی‌داد، الان باید بدهد.
4. **مقایسه‌ی FOREIGN با بکتست:** یک بار AUDCAD را وقتی چارت روی GBPNZD
   باز است بپرسید و مقدار Level را با CSV بکتست همان بازه‌ی زمانی (اگر
   دارید) مقایسه کنید — باید یکی باشد (با احتمال اختلاف چند دقیقه‌ای طبق
   محدودیت accumulator بالا).
5. **لایو دمو:** چارت GBPNZD باز کنید، از تلگرام بنویسید `AUDCAD` —
   باید ظرف چند ثانیه دو پیام (Buy/Sell) بیاید. بعد بنویسید `GBPNZD`
   (همان سمبل چارت) — باید از مسیر status معمولی (با عکس) جواب بیاید، نه
   on-demand.
6. **تست handle leak:** دو بار پشت‌سرهم همان سمبل را بفرستید تا مطمئن
   شوید `OnDemand_Cleanup` هر بار درست release می‌کند.
7. چک کنید `Generic_ReplayCrisisAtBar` در جای دیگری از فایل صدا زده
   نمی‌شود که با امضای جدید (بدون `flowScoreOut`/`adxValOut`) ناسازگار
   شود — تأیید شد که فقط همان یک نقطه در `OnDemand_RunAndSend` صدایش
   می‌زند.

---

## ۸) چی مانده (کارهای بعدی)

- 🔲 کالیبراسیون آستانه‌های Crisis مخصوص EURGBP (بعد از بکتست).
- 🔲 کالیبراسیون وزن‌دهی Spike مخصوص AUDCAD/EURGBP (اگر بکتست نشان داد لازم است).
- 🔲 اجرای بندهای تست بخش ۷ (بالا) و ثبت نتیجه.
- 🔲 در صورت رضایت از نتیجه‌ی بکتست، تصمیم نهایی برای لایو گرفتن روی AUDCAD/EURGBP.

---

## ۹) فایل‌های تغییر‌یافته / تابع‌های این پچ (v14.01)

**تابع تغییریافته (امضا عوض شد):** `Generic_ReplayCrisisAtBar`
(دو پارامتر خروجی `flowScoreOut`/`adxValOut` اضافه شد).

**تابع تغییریافته (منطق داخلی بازنویسی شد):** `OnDemand_RunAndSend`
(حلقه‌ی ۷۲-ساعته حالا از `Rule_Transition` واقعی استفاده می‌کند؛ متن
هشدار تلگرام هم اصلاح شد).

**تابع تغییریافته (فقط پیش‌فرض):** `Sister_GetTable`
(پیش‌فرض سمبل ناشناخته از GBPNZD به AUDCAD).

**بدون تغییر (تأیید شد که نیازی نبود):** `Rule_FlowForSymbol`،
تشخیص پوزیشن واقعی، state machine `OD_STATE_*`، تشخیص substring سمبل،
`OD_RuleLevelText`، `Rule_UpdateCounters`، `Rule_Transition` خودش،
`Generic_ReplaySpikeAtBar`.

---

## ۱۰) بازبینی مستقل کد کامل (v14.01) — چیزی که چک شد و نتیجه

کل فایل (۱۴٬۸۱۶ خط) خوانده شد و نقطه‌به‌نقطه با درخواست اولیه (Rule/Spike
روی هر سه سمبل + وضعیت لحظه‌ای بی‌چارت از تلگرام) تطبیق داده شد:

| بررسی شد | نتیجه |
|---|---|
| آیا همه‌ی ۹+ نقطه‌ی قفل `StringFind(_Symbol,"GBPNZD")` باز شده‌اند؟ | ✅ بله، همه با `IsRuleSymbol` |
| آیا Flow/Sister/وزن Spike در Replay و لایو از یک منبع می‌آیند (نه هاردکد جدا)؟ | ✅ بله، `Sister_GetTable`/`Rule_FlowForSymbol`/`Rule_SpikeWeightsForSymbol` |
| آیا ستون‌های CSV بکتست برای AUDCAD/EURGBP هم پر می‌شوند؟ | ✅ بله، `LogHourlySnapshot` با `IsRuleSymbol` گارد شده |
| آیا `OnDemand_*` در بکتست هم اجرا/تلاش می‌شود (بار اضافه)؟ | ✅ نه، `OnDemand_Poll` با `!MQLInfoInteger(MQL_TESTER)` گارد شده |
| آیا وقتی سمبل درخواستی = سمبل چارت است، به‌جای FOREIGN از مسیر کامل (با عکس) استفاده می‌شود؟ | ✅ بله (`odReq == CleanSymbol(_Symbol)`) |
| آیا Rule واقعی (`Rule_Transition`) در FOREIGN استفاده می‌شود یا هنوز تخمینی است؟ | ✅ واقعی — این دقیقاً همان چیزی بود که v14.00 نداشت و v14.01 اضافه کرد |
| آیا handle های اندیکاتور موقت درست release می‌شوند (نشتی حافظه)؟ | ✅ `OnDemand_Cleanup` هر بار |
| آیا ترتیب تعریف توابع مشکل کامپایل می‌سازد (مثلاً `OnDemand_RunAndSend` در خط ۸۳۹۲ زودتر از `Rule_Transition` در خط ۸۸۲۵)؟ | ✅ مشکلی نیست — MQL5 کل فایل را قبل از اجرا resolve می‌کند، نیازی به forward declaration نیست |
| آیا متغیرهای global مربوط به `OD_*` قبل از استفاده تعریف شده‌اند؟ | ✅ بله (`#define` خط ۱۷۱۸-۱۷۲۸، قبل از اولین استفاده) |

**نتیجه‌ی کلی: هیچ باگ جدیدی پیدا نشد.** خود v14.01 دقیقاً همان چیزی
است که در بخش‌های ۱ تا ۹ همین سند توضیح داده. تنها چیزی که لازم است در
عمل تست شود (نه این‌که در کد مشکل باشد) بندهای بخش ۷ بالا هستند —
خصوصاً بکتست واقعی AUDCAD/EURGBP برای دیدن اعداد کالیبراسیون.

### ⚠️ یک نکته‌ی مهم که در کد درست است ولی باید حواس‌تان باشد (نه باگ، محدودیت طراحی عمدی)

ویژگی FOREIGN **کاملاً واکنشی (pull) است، نه فعال (push)**. یعنی اگر
چارت روی GBPNZD باز باشد و وضعیت AUDCAD در پس‌زمینه به STOP یا CLOSE
برسد، اکسپرت **خودش به شما پیام نمی‌دهد** — چون طبق طراحی عمدی (برای
صفر‌کردن بار CPU مستمر)، هیچ محاسبه‌ای برای AUDCAD در پس‌زمینه انجام
نمی‌شود مگر وقتی خودتان کلمه‌ی `AUDCAD` را بفرستید. برای این‌که سیستم
*خودش* هر بار وضعیت یکی از این دو سمبل خطرناک شد به‌طور خودکار خبر
بدهد، تنها راه این است که همان اکسپرت را روی چارت خودِ آن سمبل هم باز
کنید (بند SELF) — آن‌جا مثل GBPNZD هشدار خودکار STOP/CLOSE/RESUME دارد.

---

## ۱۱) به زبان ساده — این پچ چیکار می‌کند

**خلاصه‌ی یک‌خطی:** حالا Rule (قانون سه‌سطحی GREEN/STOP/CLOSE) و Spike
روی هر سه جفت‌ارز GBPNZD، EURGBP، AUDCAD کار می‌کنند — چه اکسپرت واقعاً
روی چارت آن سمبل باز باشد (SELF)، چه فقط بخواهید از راه دور با یک کلمه
در تلگرام وضعیتش را بپرسید (FOREIGN).

### حالت ۱ — اکسپرت روی چارت خودِ آن سمبل باز است (SELF)
اگر اکسپرت را روی چارت EURGBP یا AUDCAD باز کنید (لایو یا بکتست)، دقیقاً
مثل GBPNZD رفتار می‌کند: چراغ‌های Crisis/Spike/Rule هر تیک محاسبه
می‌شوند، هشدار STOP/CLOSE/RESUME خودکار در تلگرام می‌آید، ری‌استارت
اکسپرت هم state را از GlobalVariable/فایل خودش (جدا از GBPNZD) بازیابی
می‌کند. روی GBPNZD هیچ چیزی عوض نشده — همان رفتار قبلی.

### حالت ۲ — اکسپرت فقط روی یکی از این سه‌تا باز است، وضعیت یکی دیگر را می‌پرسید (FOREIGN)
وقتی در تلگرام یکی از این کلمات را بفرستید (فارسی یا انگلیسی، کافی‌ست
جایی در پیام باشد، لازم نیست کل پیام همین باشد):

| چه بفرستید | چه جوابی می‌آید |
|---|---|
| کلمه‌ی «وضعیت» (بدون اسم سمبل) | گزارش کامل + عکس چارت، فقط برای سمبلی که اکسپرت روی آن باز است |
| اسم سمبل چارت خودش (مثلاً `GBPNZD` وقتی اکسپرت هم روی GBPNZD است) | همان گزارش کامل + عکس (چون نیازی به محاسبه‌ی جدا نیست) |
| اسم یکی از دو سمبل دیگر (مثلاً `AUDCAD` یا «وضعیت AUDCAD» وقتی چارت روی GBPNZD است) | فقط متن، **بدون عکس** (چون چارتی برای آن باز نیست) — دو پیام جدا: یکی برای BUY، یکی برای SELL |

هر پیام FOREIGN شامل: چراغ Crisis، چراغ Spike، وضعیت Rule (GREEN عادی /
STOP یعنی باز نکن / CLOSE یعنی بستن توصیه می‌شود)، و اگر واقعاً معامله‌ی
باز در آن جهت دارید، سود لحظه‌ای و ساعت بازشدنش؛ اگر ندارید، می‌نویسد
«معامله باز نداریم».

محاسبه‌ی FOREIGN فقط همان لحظه‌ی درخواست انجام می‌شود (چند ثانیه طول
می‌کشد تا اندیکاتورها گرم شوند)، بعد کاملاً آزاد می‌شود — هیچ محاسبه‌ی
دائمی در پس‌زمینه برای سمبل‌های دیگر انجام نمی‌شود، پس بار CPU اضافه
نمی‌گذارد.

### تفاوت مهم بین SELF و FOREIGN که باید بدانید
- **SELF (چارت خودش باز است):** اگر وضعیت خطرناک شود، اکسپرت **خودش
  فعالانه** در تلگرام هشدار می‌دهد (STOP/CLOSE) — نیازی نیست بپرسید.
- **FOREIGN (فقط اسم سمبل را از راه دور می‌پرسید):** اکسپرت **هرگز خودش
  پیام نمی‌دهد** — فقط وقتی خودتان اسم سمبل را بفرستید جواب می‌آید. اگر
  می‌خواهید مثلاً AUDCAD هم مثل GBPNZD خودش هشدار خودکار بدهد، باید
  اکسپرت را واقعاً روی چارت AUDCAD هم باز کنید (SELF).

### بکتست
اگر Strategy Tester را روی چارت GBPNZD بگیرید، مثل قبل است. اگر روی
چارت EURGBP یا AUDCAD بکتست بگیرید، حالا ستون‌های Rule/Crisis/Spike در
گزارش/CSV هم درست پر می‌شوند (قبلاً این ستون‌ها فقط برای GBPNZD پر
می‌شدند). ویژگی FOREIGN (پرسیدن وضعیت با تلگرام) اصلاً در بکتست معنی
ندارد و اجرا نمی‌شود — چون در بکتست تلگرام وصل نیست.

### چیزی که هنوز عدد نهایی ندارد
آستانه‌های Crisis برای EURGBP و وزن‌دهی Spike برای EURGBP/AUDCAD فعلاً
از یک مقدار پیش‌فرض معقول استفاده می‌کنند (نه چیزی که مخصوص همان جفت‌ارز
کالیبره شده باشد) — دقیقاً طبق دستور اولیه، تا بعد از بکتست واقعی روی
این دو جفت‌ارز عدد دقیق‌شان تنظیم شود. رفتار GBPNZD کاملاً کالیبره‌شده و
دست‌نخورده باقی مانده.
