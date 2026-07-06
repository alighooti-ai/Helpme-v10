# HelpMe v14.06 → v14.07 — مستند تغییرات

## ۰) خلاصه v14.07

این نسخه ادامه معماری TF-aware است. دو پچ مستقل (Kimi و Claude) بررسی شدند و
تغییرات **ایمن و بدون ریسک رگرسیون** انتخاب و اعمال شدند. تغییرات معماری بزرگ‌تر
که نیاز به بکتست مجدد داشتند عمداً به نسخه بعدی موکول شدند.

| نوع | تعداد |
|-----|-------|
| 🟠 بالا (اعمال شد) | ۲ |
| 🟡 متوسط/ایمن (اعمال شد) | ۴ |
| ❌ موکول شد (نیاز به بکتست) | ۴ |

---

## ۱) تغییرات اعمال‌شده v14.07

### 🟠 PATCH-D1 (بالا): شاخه اختصاصی EURGBP در Crisis_GetThresholds

**محل:** `Crisis_GetThresholds()` — شاخه جدید `else if(StringFind(checkSym, "EURGBP"))`

**مشکل:**
تا قبل از این نسخه، EURGBP شاخه اختصاصی در `Crisis_GetThresholds` نداشت و از
پیش‌فرض AUDCAD استفاده می‌کرد. این آستانه‌ها برای EURGBP کالیبره نشده بودند.

**رفع:**
```cpp
else if(StringFind(checkSym, "EURGBP") >= 0)
{
    // ⚠️ موقت — باید با بکتست EURGBP 2024-2026 کالیبره شوند
    th_RedA_ADX = 26.0;  th_RedA_Flow = 5.5;
    th_RedB_ADX = 33.0;  th_RedB_Flow = 7.0;
    th_OrA_ADX  = 24.0;  th_OrA_Flow  = 5.0;
    // ... (اعداد موقت مشابه GBPNZD با کمی تفاوت)
}
```

**⚠️ توجه:** اعداد موقت هستند. قبل از لایو EURGBP باید بکتست ۲۰۲۴-۲۰۲۶ اجرا و
آستانه‌ها کالیبره شوند.

---

### 🟠 PATCH-D1 (بالا): شاخه اختصاصی EURGBP در Rule_SpikeWeightsForSymbol

**محل:** `Rule_SpikeWeightsForSymbol()` — شاخه جدید `else if(CleanSymbol(sym) == "EURGBP")`

**مشکل:**
EURGBP از وزن‌های AUDCAD استفاده می‌کرد (هر دو شاخه else یکسان بودند).

**رفع:**
```cpp
else if(CleanSymbol(sym) == "EURGBP")
{
    // ⚠️ موقت — باید کالیبره شوند
    wM15 = 0.10; wM30 = 0.15; wH1 = 0.35; wH4 = 0.25; wD1 = 0.15;
}
```

---

### 🟡 PATCH-P5 (متوسط): چک صحت CopyClose در OnDemand_RunAndSend

**محل:** `OnDemand_RunAndSend()` — بعد از چک `iBars` موجود از v14.06

**مشکل:**
`iBars` ممکن بود > 0 باشد اما `CopyClose` همه صفر برگرداند (broker سمبل غیرفعال
یا محدودیت تاریخ در Strategy Tester).

**رفع:**
```cpp
int _copied = CopyClose(broker, PERIOD_CURRENT, 0, MathMin(5, odBarsToScan), _testClose);
if(_copied <= 0) { OnDemand_Cleanup(); return; }
bool _allZero = true;
for(int _ci = 0; _ci < _copied; _ci++)
    if(_testClose[_ci] > 0.0) { _allZero = false; break; }
if(_allZero) { OnDemand_Cleanup(); return; }
```

---

### 🔵 PATCH-B2 (مستندسازی): کامنت‌های Design Lock

**محل‌ها:**
- `GBPNZD_InitReplay()` — قبل از handle declarations
- `FlowEvaluate()` — اول تابع
- `Zone_IsConfirmedByH1()` — اول تابع

این کامنت‌ها روشن می‌کنند که چه چیزی عمداً ثابت است و تغییر نباید بدهید:

```cpp
// 🔒 DESIGN LOCK: Handle های زیر عمداً ثابت هستند (H1/H4/D1).
// تغییر ندهید حتی اگه TF چارت متفاوت باشد.
```

---

## ۲) تغییرات موکول‌شده (نیاز به بکتست — v14.08 یا بعد)

### ❌ P0 — Alert فوری وسط کندل (Kimi)

**دلیل رد شدن:**
طبق مستندات v14.06 BUG-M1، رفتار فعلی **عمدی** است. `Rule_Transition` هر تیک
اجرا می‌شود تا STOP فوری برای Spike وسط کندل پشتیبانی شود. counter ها فقط سر
کندل آپدیت می‌شوند. اضافه کردن `input bool` جدید بدون بکتست خطرناک است.

### ❌ P1 — Scale آستانه‌های Rule با TF (Kimi)

**دلیل رد شدن:**
آستانه‌های 2/6/24 کندل از بکتست H1 کالیبره شده‌اند. تبدیل به ساعت و scale پویا
یک تغییر معماری بزرگ است. بدون بکتست مجدد روی همه TFها، ریسک بالایی دارد.

### ❌ P3 — TF-aware GlobalVariable keys (Kimi)

**دلیل رد شدن:**
تغییر کلیدهای GV، state ذخیره‌شده کاربران فعلی را از بین می‌برد. تصمیم
migration باید با تیم هماهنگ شود. بدون migration plan اجرا نشد.

### ❌ P4 — بهینه‌سازی InitReplay برای TF < H1 (Kimi)

**دلیل رد شدن:**
کد فعلی از handle های H1/H4/D1 استفاده می‌کند (Design Lock). تغییر loop TF بدون
تضمین که Replay_CrisisAtBar پارامتر TF می‌پذیرد ممکن است counter scale را بشکند.
این بهینه‌سازی CPU پس از تأیید رفتار صحیح در نسخه بعدی اعمال می‌شود.

---

## ۳) وضعیت کالیبراسیون

### GBPNZD — کاملاً کالیبره‌شده ✅
هیچ تغییری نکرده — رفتار دقیقاً مثل v14.06.

### EURGBP — اعداد موقت اضافه شد ⚠️
شاخه‌های اختصاصی ایجاد شدند اما اعداد موقت هستند:

| مؤلفه | وضعیت |
|-------|-------|
| `Crisis_GetThresholds` — شاخه EURGBP | ⚠️ **موقت** — شاخه مستقل دارد، اعداد TODO |
| `Rule_SpikeWeightsForSymbol` — شاخه EURGBP | ⚠️ **موقت** — شاخه مستقل دارد، اعداد TODO |
| Flow gate Spike | ❌ همچنان یکسان با GBPNZD |
| HighAlert threshold | ❌ همچنان یکسان با GBPNZD |

**اقدام لازم:** بکتست EURGBP روی ۲۰۲۴-۲۰۲۶ و کالیبره کردن اعداد TODO.

### AUDCAD — بدون تغییر ⚠️
همانند v14.06.

---

## ۴) چک‌لیست تست

- [ ] کامپایل بدون خطا در MetaEditor
- [ ] بکتست GBPNZD H1: نتایج مشابه v14.06 (صفر رگرسیون)
- [ ] بکتست EURGBP H1 ۲۰۲۴-۲۰۲۶: ستون‌های Crisis/Spike/Rule پر می‌شوند
- [ ] تلگرام: درخواست AUDCAD و EURGBP روی چارت GBPNZD — پاسخ بدون خطا
- [ ] تلگرام: درخواست سمبلی که در PERIOD_CURRENT داده ندارد → Print خطا + skip

---

## ۵) فایل‌های تغییریافته v14.07

**تابع تغییریافته (شاخه جدید اضافه شد):** `Crisis_GetThresholds`

**تابع تغییریافته (شاخه جدید اضافه شد):** `Rule_SpikeWeightsForSymbol`

**تابع تغییریافته (چک اضافه):** `OnDemand_RunAndSend`

**کامنت اضافه شد (بدون تغییر کد):** `GBPNZD_InitReplay`، `FlowEvaluate`، `Zone_IsConfirmedByH1`

**بدون تغییر:** `Rule_Transition`، `Rule_UpdateCounters`، `Chart_IsNewBarClosed`،
`Alert_CheckGBPNZDRule`، `GBPNZD_InitReplay` (منطق)، `OnTimer`، `OnInit`

