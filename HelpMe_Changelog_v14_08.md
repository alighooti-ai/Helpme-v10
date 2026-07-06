# HelpMe Changelog — v14.08

## خلاصه v14.08

بررسی ۵ ایراد گزارش‌شده از کد v14.07. از این ۵ مورد، **۲ مورد در کد ما وجود نداشتند**
(قبلاً فیکس شده بودند)، **۱ مورد واقعی بود** و اعمال شد، **۱ مورد فقط کامنت** نیاز
داشت، و **۱ مورد عمداً موکول** ماند.

| # | ایراد | نوع | اقدام |
|---|-------|-----|-------|
| BUG-TF1 | Rule_Transition آستانه‌های هاردکد 6/24 کندل | 🔴 بحرانی | ✅ اعمال شد |
| BUG-TF2 | InitReplay loop count هاردکد 72 | 🔴 بحرانی (ادعا) | ❎ در کد ما وجود نداشت |
| BUG-TF3 | OnDemand odBarsToScan ثابت | 🟠 بالا (ادعا) | ❎ در کد ما وجود نداشت |
| BUG-SPIKE1 | Rule_Transition هر تیک — مستندنشده | 🟡 بالا | 🔵 کامنت اضافه شد |
| BUG-GV1 | GV Keys بدون TF prefix | 🟤 متوسط | ⏸ موکول به v14.09 |

---

## ۱) BUG-TF1 — اعمال شد ✅

### مشکل واقعی (نه دقیقاً آنچه reviewer گفت)

reviewer ادعا کرد: `TimeHour(TimeCurrent()) != TimeHour(g_gbpnzdLastH)` در کد هست.

**واقعیت:** `TimeHour` اصلاً در کد v14.07 وجود نداشت. `Rule_UpdateCounters` از
`barBoundaryReached = (g_lastBarCloseTime > g_gbpnzdLastH)` استفاده می‌کرد که
**TF-aware بود**.

**اما باگ واقعی پیدا شد:** آستانه‌های داخل `Rule_Transition` هنوز هاردکد بودند:

```cpp
// قبل (BUG):
bool _closeB = (crisisRedH >= 6);   // ← 6 کندل — روی M1 = 6 دقیقه!
bool _resume = (cleanH >= 24);      // ← 24 کندل — روی M1 = 24 دقیقه!
```

روی M1: CLOSE بعد از ۶ دقیقه (نه ۶ ساعت)، روی H4: CLOSE هرگز در حالت عادی.

### رفع

سه global TF-aware اضافه شد و در `OnInit` scale می‌شوند:

```cpp
// global declarations (پیش‌فرض برای H1):
int g_ruleStopBars   = 2;
int g_ruleCloseBars  = 6;
int g_ruleResumeBars = 24;

// در OnInit — بعد از g_chartPeriodSeconds:
g_ruleStopBars   = (int)MathMax(1, MathRound(2.0  * 3600.0 / g_chartPeriodSeconds));
g_ruleCloseBars  = (int)MathMax(1, MathRound(6.0  * 3600.0 / g_chartPeriodSeconds));
g_ruleResumeBars = (int)MathMax(1, MathRound(24.0 * 3600.0 / g_chartPeriodSeconds));

// در Rule_Transition:
bool _closeB = (crisisRedH >= g_ruleCloseBars);
bool _resume = (cleanH >= g_ruleResumeBars);
```

**Scale جدول:**

| TF | g_ruleStopBars | g_ruleCloseBars | g_ruleResumeBars |
|----|----------------|-----------------|------------------|
| M1 | 120 کندل | 360 کندل | 1440 کندل |
| H1 | **2 کندل** ✓ | **6 کندل** ✓ | **24 کندل** ✓ |
| H4 | 1 کندل | 2 کندل | 6 کندل |

**صفر رگرسیون روی H1** — مقادیر دقیقاً مثل قبل.

⚠️ **نکته بکتست:** روی H1 باید اجرا شود و نتیجه با v14.07 مقایسه گردد.

---

## ۲) BUG-TF2 — رد شد ❎

**ادعا:** `int barsToScan = 72;` هاردکد در `GBPNZD_InitReplay`.

**واقعیت:** از v14.06 (BUG-C1 fix) این خط در کد بود:
```cpp
int _replayBarsToScan = (int)MathMax(1, 259200 / _replayPeriodSec);
```
`259200 = 72h × 3600s` — کاملاً TF-aware. هیچ تغییری لازم نبود.

---

## ۳) BUG-TF3 — رد شد ❎

**ادعا:** `odBarsToScan = 72` ثابت در `OnDemand_RunAndSend`.

**واقعیت:** از PATCH-P5 v14.05 کد این بود:
```cpp
int odWindowSec  = 72 * 3600;
int odBarsToScan = (int)MathMax(1, odWindowSec / MathMax(odPeriodSec, 1));
```
`odPeriodSec = PeriodSeconds(odTF)` — کاملاً TF-aware. هیچ تغییری لازم نبود.

---

## ۴) BUG-SPIKE1 — کامنت اضافه شد 🔵

فقط `DESIGN LOCK` comment اضافه شد در `Alert_CheckGBPNZDRule`:

```cpp
// 🔒 DESIGN LOCK (v14.08 BUG-SPIKE1): Rule_Transition عمداً هر تیک صدا زده می‌شود.
// دو منطق عمداً جدا هستند:
//   (۱) Rule_UpdateCounters → فقط سر کندل — شمارش تاریخی
//   (۲) Rule_Transition     → هر تیک — واکنش فوری به Spike جدید
```

هیچ تغییر کدی انجام نشد.

---

## ۵) BUG-GV1 — موکول به v14.09 ⏸

GV keys بدون TF prefix (`HM_GBNZD_CrisisRedH`) مشکل واقعی است اما:
- تغییر state ذخیره‌شده کاربران فعلی را خراب می‌کند
- migration plan یک‌طرفه نیاز دارد
- reviewer خودش گفت: موکول به v14.09

**اقدام لازم در v14.09:**
```cpp
string tfSuffix = IntegerToString(g_chartPeriodSeconds);
string keyNew   = "HM_GBNZD_" + tfSuffix + "_CrisisRedH";
string keyOld   = "HM_GBNZD_CrisisRedH";
// اگر کلید جدید نبود ولی قدیمی بود → migration یک‌طرفه
```

---

## فایل‌های تغییریافته v14.08

| تابع | نوع تغییر |
|------|-----------|
| `OnInit` | محاسبه `g_ruleStopBars/CloseBars/ResumeBars` اضافه شد |
| `Rule_Transition` | `>= 6` و `>= 24` → `>= g_ruleCloseBars` و `>= g_ruleResumeBars` |
| `Alert_CheckGBPNZDRule` | کامنت DESIGN LOCK اضافه شد |
| Global declarations | سه متغیر `g_ruleStopBars/CloseBars/ResumeBars` اضافه شد |

**بدون تغییر:** `GBPNZD_InitReplay`، `OnDemand_RunAndSend`، `GBPNZD_GV_Save/Load`،
`Chart_IsNewBarClosed`، `Rule_UpdateCounters`، تمام EURGBP patches، تمام v14.06 fixes

---

## چک‌لیست تست

- [ ] کامپایل بدون خطا در MetaEditor
- [ ] بکتست GBPNZD **H1**: نتایج مثل v14.07 (صفر رگرسیون — g_ruleCloseBars=6, g_ruleResumeBars=24)
- [ ] بکتست GBPNZD **M15** یا **M30**: CLOSE بعد از ۲۴ کندل (= ۶ ساعت) نه ۶ کندل
- [ ] لاگ OnInit: مقادیر `STOP=X CLOSE=Y RESUME=Z bars` چاپ می‌شود
