//+------------------------------------------------------------------+
//|                                                    AFA_v5_EA.mq5 |
//|  AFA v5 -- Pyramid / No-Hedge / Tight-Trail Expert Advisor       |
//|                                                                    |
//|  این فایل دو بخش دارد که با خط جداکننده مشخص شده:                |
//|  (۱) موتور رژیم -- عیناً پورت‌شده از AFA_v2_11.mq5 (validated،   |
//|      کالیبراسیون+OOS روی ۶ ارز). این بخش را دست نزن مگر با       |
//|      تحقیق جدید و مستند مثل خودِ changelog v2.10/v2.11.          |
//|  (۲) منطق چرخهٔ v5 -- فاز۰ گیت‌ها، فاز۱ پیرامید، فاز۲ استاپ،     |
//|      فاز۳ فلیپ، خودانتخابی نماد، لایهٔ محافظ سراسری. فرمول‌هایش  |
//|      از سه منبع مستقل cross-check شده: مانیفست v5، شبیه‌سازی     |
//|      پایتونِ من (afa_v5_engine.py)، و afa_v5_backtest.py خودت.   |
//|                                                                    |
//|  فرض حیاتی: حساب Hedging-mode. روی Netting، هرچند پا هم اضافه    |
//|  کنیم توی یک پوزیشن نت می‌شن -- منطق n_adds/تریل دیگه معنی نداره.|
//|  دقیقاً همون هشداری که خودِ v2.11 برای Mode=Both می‌داد.          |
//|                                                                    |
//|  ================== CHANGELOG (قانون: هر تغییر اول اینجا) ======= |
//|  v5.00 (اولیه) -- تحویلِ اول: موتورِ رژیم + کل منطق چرخه.         |
//|  v5.01 -- اصلاحِ ۱۳ نقدِ کدیِ AI2 (نقدِ کاملِ خط‌به‌خط): مهم‌ترین‌ها  |
//|      Kill Switch دیگه مدیریتِ پوزیسیونِ باز رو قطع نمی‌کنه؛ نتیجهٔ  |
//|      close چک می‌شه (state زود پاک نمی‌شه)؛ R از ریسکِ زمانِ ورود  |
//|      (نه اکوییتیِ زمانِ بستن) با OnTradeTransaction؛ اسپردِ زنده؛  |
//|      چکِ مارجین قبل از ورود/Add؛ SyncBrokerStop برای محافظتِ زنده  |
//|      بینِ کندل‌ها؛ AllowMinLotWithActualRiskCap برای حساب کوچیک.  |
//|      + رفعِ بن‌بستِ گیتِ ۵.۹: شبیه‌سازیِ چرخهٔ کاغذی وقتی نماد داغ   |
//|      نیست، وگرنه تاریخچه هیچ‌وقت به ۴۰ چرخه نمی‌رسید.              |
//|  v5.02 (این نسخه) -- طبقِ گزارشِ AI4 دربارهٔ توقفِ کاملِ معامله بعد  |
//|      از تستِ GBPNZD:                                              |
//|      *** باگِ حیاتی رفع شد: cooldownLeft هیچ‌جا کم نمی‌شد -- فقط   |
//|      موقعِ بستن ست می‌شد. یعنی بعدِ اولین چرخه، برای همیشه قفل      |
//|      می‌موند (نه فقط ۳ کندل). حالا TickCooldowns() هر کندلِ        |
//|      بی‌کاری صدا زده می‌شه. ***                                    |
//|      + کول‌داونِ کاغذی/واقعی کاملاً جدا شد (یه ضررِ کاغذی نباید     |
//|      ورودِ واقعی رو عقب بندازه).                                   |
//|      + فایلِ گزارشِ «فقط-واقعی» جدا از تاریخچهٔ ترکیبیِ گیت.        |
//|      + شمارنده‌های تشخیصیِ هر گیت (چاپ هر ۱۰۰ کندل).               |
//|      + SL واقعی همراهِ خودِ سفارش فرستاده می‌شه (نه فقط کندلِ بعد   |
//|      با SyncBrokerStop).                                          |
//|      + سقفِ دومِ دلاریِ ریسکِ واقعی (علاوه‌بر درصدی) برای حساب‌های   |
//|      خیلی کوچیک.                                                  |
//|      -- هنوز باز (v5.03؟): فیکسِ ATR3 برای لَگِ K حینِ شوکِ نوسان   |
//|      (طبق یافتهٔ AI4 در سندِ R&D، بخش ز.۱) هنوز اضافه نشده.        |
//|  v5.03 (این نسخه) -- طبقِ دو گزارشِ AI4 دربارهٔ تستِ واقعیِ         |
//|      USDJPY/GBPNZD:                                               |
//|      *** باگِ حیاتی رفع شد: ValuePerPriceMovePerLot از             |
//|      TickValue/TickSize به OrderCalcProfit تغییر کرد. توی تستِ     |
//|      واقعی، نسبتِ این دو برای USDJPY_l دقیقاً ۱۵۵٫۲ برابر بود --   |
//|      عینِ نرخِ USDJPY -- یعنی این بروکر تیک‌ولیوی این نماد رو از    |
//|      ین به دلار تبدیل نمی‌کرد. نتیجه: هم لاتِ واقعی ۱۵۵ برابر      |
//|      کوچیک‌تر از هدف بود، هم R گزارش‌شده (که باید دقیقاً ۱-± باشه   |
//|      برای STOP_S0) عملاً صفر می‌شد. OrderCalcProfit همیشه درست     |
//|      تبدیل می‌کنه چون خودِ ترمینال برای سود/زیانِ واقعی همینو       |
//|      استفاده می‌کنه. (GBPNZD این باگ رو نداشت -- تیک‌ولیوش درست    |
//|      بود -- برای همین R واقعیش قابل‌اعتماد بود: ۹ برد از ۶۴،        |
//|      میانگین R=-۰.۶۱ -- این یه یافتهٔ واقعیه، نه آرتیفکت.)         |
//|      + لاگِ کاملِ ACCOUNT_BALANCE/CURRENCY/CONTRACT_SIZE در OnInit  |
//|      تا سردرگمیِ «Initial Deposit=۱۰۰۰۰۰ یعنی واقعاً ۱۰۰هزار دلاره  |
//|      نه ۱۰۰دلار» دیگه پنهان نمونه.                                 |
//|      -- هنوز باز: فیکسِ ATR3 (v5.02 از قبل مونده)، بازطراحیِ        |
//|      تایم‌فریمِ اجرا (H1 هاردکد شده، سوییچ به M1 چیزی رو عوض        |
//|      نمی‌کنه)، پاک‌سازیِ فایلِ تاریخچه بینِ اجراهای پیاپی.           |
//|  v5.04 (این نسخه) -- طبقِ پرامپتِ اختصاصیِ «اصلاح واحد Cent، حداقل  |
//|      لات» -- **فقط** لایهٔ واحد/تشخیص، طبقِ دستورِ صریح هیچ تغییری   |
//|      در ATR3/K/Trail/M1/رأی‌ها اعمال نشد:                          |
//|      + AccountUnitScale: صریح و پیش‌فرض خاموش (InpUseAccountUnitScale).|
//|      تشخیصِ خودکارِ ارزِ Cent-مانند فقط لاگ می‌شه، هرگز خودکار اعمال  |
//|      نمی‌شه -- رفتارِ پیش‌فرض (scale=۱) دقیقاً مثلِ قبل می‌مونه.       |
//|      + Raw/Economic جدا: RawBalance در سایزینگِ اصلی (scale-invariant|
//|      چون درصدیه)، فقط سقفِ دلاریِ مطلق (InpMaxActualRiskUSD) با scale|
//|      تبدیل می‌شه.                                                  |
//|      + فایلِ AFA_v5_GateDiagnostics_<RunID>_<Symbol>_<TF>.csv: تمامِ |
//|      ستون‌های خواسته‌شده، نوشته‌شده در OnInit (حتی بدونِ هیچ معامله‌ای)|
//|      و هر ۱۰۰ کندل.                                                |
//|      + RunID واقعی (نه فقط زمان‌سنجِ ساده) و FileOpen با GetLastError|
//|      روی شکست.                                                     |
//|      + Self-test هر نماد در OnInit: TickValue/TickSize (قدیمی) کنارِ|
//|      OrderCalcProfit (فعلی) -- تا اختلافِ ارزهای متقاطع مثلِ USDJPY  |
//|      از همون اول قابل‌دیدن باشه.                                    |
//|      + ClampStopToBrokerLimits: قبل از فرستادن/تغییرِ SL، با         |
//|      StopsLevel/FreezeLevel بروکر می‌سنجه و می‌چسبونه -- به‌جای اینکه |
//|      فقط بعدِ رد شدن لاگ کنه. لاگِ شکستِ SyncBrokerStop هم کامل‌تر شد |
//|      (Bid/Ask/فاصله/Retcode).                                      |
//|      -- هنوز باز: ATR3، بازطراحیِ تایم‌فریم (M1)، پاک‌سازیِ تاریخچهٔ  |
//|      گیتِ ۵.۹ بینِ اجراها (عمداً دست‌نخورده ماند چون این گیت خودش به  |
//|      تاریخچهٔ چندماهه نیاز داره تا معنی‌دار بمونه -- برای تستِ کاملاً  |
//|      ایزوله، InpUseSymbolGate=false رو موقتاً امتحان کن).           |
//|  v5.05 (این نسخه) -- ONLY execution/reporting fixes per explicit    |
//|      request. NO change to regime engine, K, S0, Trail, ATR,        |
//|      timeframes, votes, entry gates, Add rules, or risk policy:     |
//|      1) All input group titles and input-line comments translated  |
//|      to English for consistency. Input variable names/defaults     |
//|      unchanged.                                                     |
//|      2) Raw vs Economic values now explicitly labeled everywhere    |
//|      they're logged: RawRiskUnits/EconomicRiskUSD,                  |
//|      RawPnLUnits/EconomicPnLUSD, RawBalance/EconomicBalanceUSD.      |
//|      A raw Cent-unit value is never printed with a "$" sign anymore.|
//|      3) *** Root cause of retcode 10016 (Invalid Stops) found and   |
//|      fixed: OpenFirstLeg was using the ORDER-FILL side (Ask for a   |
//|      BUY) as the reference price when clamping the initial SL,     |
//|      instead of the STOP-CHECK side the broker actually validates   |
//|      against (Bid for a BUY, Ask for a SELL). Since Ask>=Bid, this  |
//|      made the computed distance look larger than it truly was,     |
//|      sometimes passing my own clamp while still being rejected by   |
//|      the broker. ClampStopToBrokerLimits() now always fetches the   |
//|      correct side itself (BUY->Bid, SELL->Ask) instead of trusting  |
//|      the caller -- same class of bug can't recur at other call      |
//|      sites. Also normalizes to the symbol's real tick size (not     |
//|      just decimal digits), which matters for non-power-of-10 tick   |
//|      sizes.                                                         |
//|      4) SyncBrokerStop never assumes success on failure: on a       |
//|      rejected modify, the previous protective SL stays untouched on |
//|      the position, and the same level is retried next bar. Added a  |
//|      proactive DEFERRED path: if the current SL is already inside   |
//|      the broker's FreezeLevel zone, no modify is even attempted     |
//|      (it would certainly fail) -- logged as deferred instead of a   |
//|      wasted rejected attempt.                                       |
//|      5) New counters SL_SYNC_SUCCESS / SL_SYNC_DEFERRED /           |
//|      SL_SYNC_REJECTED, written to both the log and the              |
//|      GateDiagnostics CSV.                                           |
//|      6) Diagnostics/RunID file behavior unchanged from v5.04 (still |
//|      written even with zero trades).                                |
//|      -- Explicitly NOT touched in this version: ATR3, M1/timeframe  |
//|      redesign, Energy, Recovery, any new filter, any parameter      |
//|      optimization.                                                  |
//|  v5.06 (this version) -- Test006 execution-state-machine fix, per   |
//|  explicit request. NO change to regime engine, K, S0, Trail         |
//|  distance, votes, entry gates, timeframe, sizing policy, or account-|
//|  unit logic:                                                        |
//|      1) Root cause of Test006's retcode 10016 found: SyncBrokerStop |
//|      clamped an already-crossed trailing SL to the nearest broker-  |
//|      valid distance and sent it via PositionModify. A negative      |
//|      EffectiveDistance (price already past the trail level -- e.g.  |
//|      -7 points in the observed SELL case) is not "too close to      |
//|      market", it is an already-triggered stop; clamping it to the   |
//|      other side fabricates a level instead of recognizing the exit. |
//|      2) SyncBrokerStop now checks market-side validity FIRST, before|
//|      any clamp/modify: BUY with desiredSL>=Bid, or SELL with        |
//|      desiredSL<=Ask, is classified SL_ALREADY_TRIGGERED.            |
//|      ClampStopToBrokerLimits (unchanged) is now only reached for a  |
//|      desired SL still on the valid side of market but inside        |
//|      StopsLevel/FreezeLevel.                                        |
//|      3) On SL_ALREADY_TRIGGERED: no clamp, no PositionModify call;  |
//|      the existing protective SL is left untouched. Instead this     |
//|      triggers the same verified close path OnNewH1Bar already uses  |
//|      for a normal stop/trail hit (CloseAllCycleLegs, reason STOP_S0 |
//|      or TRAIL_EXIT per n_adds) -- so it is counted/cooled-down      |
//|      exactly like a normal exit, never as a broker execution        |
//|      failure.                                                       |
//|      4) New counter SL_SYNC_ALREADY_TRIGGERED (struct field,        |
//|      GateDiagnostics CSV column, periodic log line) alongside the   |
//|      existing SUCCESS/DEFERRED/REJECTED counters.                   |
//|      5) Unified SL-sync log (LogSlSync) now used for all four       |
//|      outcomes, each printing Symbol, Direction, Ticket, Bid, Ask,   |
//|      DesiredSL, NormalizedSL, EffectiveDistance, StopsLevel,        |
//|      FreezeLevel, Result, CloseReason. SUCCESS previously logged    |
//|      nothing at all; it now logs under InpVerboseLog, same as       |
//|      OPEN/ADD/DEFERRED already did. Also fixed a pre-existing label |
//|      bug where a rejected modify's log line said "-> DEFERRED"      |
//|      instead of identifying itself as rejected.                     |
//|      6) Incidental fix: OnInit's startup log still printed          |
//|      "Version=5.04"; corrected to 5.06.                             |
//|      -- Explicitly NOT touched: ClampStopToBrokerLimits internals,  |
//|      OpenFirstLeg/AddLeg (their SL is computed fresh from current   |
//|      price at order time, so this staleness cannot occur there),    |
//|      regime engine, ATR3, M1/timeframe redesign, or any parameter.  |
//|  v5.07 (this version) -- execution-cleanup follow-up to v5.06's     |
//|  Test006 fix, per explicit request. NO change to K, S0, Trail       |
//|  distance, regime engine, entries, sizing, account-unit logic, or   |
//|  timeframes:                                                        |
//|      1) SyncBrokerStop now returns ENUM_SL_SYNC_RESULT (SYNC_OK /   |
//|      SYNC_DEFERRED / SYNC_REJECTED / ALREADY_TRIGGERED) instead of  |
//|      void. ALREADY_TRIGGERED is always a whole-cycle result, decided|
//|      before the per-leg loop starts. When legs sync with mixed per- |
//|      leg outcomes, the returned status uses REJECTED > DEFERRED > OK|
//|      priority (worst outcome wins).                                 |
//|      2) OnNewH1Bar now reads that status and returns immediately on |
//|      ALREADY_TRIGGERED, before reaching the closed-bar stopHit      |
//|      check. This closes a real gap, not just a log nuisance:        |
//|      previously the same bar could still evaluate Priority 2        |
//|      (flip+profit close) or Priority 3 (AP/pyramid Add) against a   |
//|      cycle that SyncBrokerStop had just told CloseAllCycleLegs to   |
//|      close -- in the AP case that meant a possible AddLeg onto a    |
//|      cycle already mid-close.                                       |
//|      3) Added the suggested second guard too: the stopHit branch now|
//|      also checks !g_cycleClosing, so a redundant close request can't|
//|      be issued while one is already in flight, independent of the   |
//|      return-value check in (2).                                     |
//|      4) Everything from v5.06 (SL_ALREADY_TRIGGERED counter, unified|
//|      LogSlSync, ClampStopToBrokerLimits untouched, etc.) is         |
//|      unchanged.                                                     |
//+------------------------------------------------------------------+
#property copyright "AFA Project"
#property version   "5.07"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//====================================================================
//  بخش ۱ / ورودی‌ها -- موتور رژیم (عیناً از v2.11، دست‌نخورده)
//====================================================================
input group "=== Regime Engine (v2.11 -- validated, do not modify) ==="
input ENUM_TIMEFRAMES InpRegimeTF        = PERIOD_H4;
input int    InpADX_Period               = 14;
input double InpADX_MinStrength          = 20.0;
input int    InpADX_ConfirmBars          = 5;
input int    InpST_ATRPeriod             = 10;
input double InpST_Multiplier            = 3.0;
input int    InpST_FastATRPeriod         = 7;
input double InpST_FastMultiplier        = 2.0;
input int    InpTFD_FractalBars          = 5;
input int    InpTFD_ScanBars             = 60;
input int    InpStruct_LookbackDays      = 10;
input int    InpER_Period                = 14;
input double InpTrendGate_ADXMin         = 20.0;
input double InpTrendGate_ERMin          = 0.25;
input int    InpMinVoteMargin            = 4;    // g_highConfidence: trend gate + vote agreement>=this (out of 5) -- ~93% accuracy (v2.11)

input group "=== Phase 0 -- Entry Gates (Manifesto Section 5.1 v5) ==="
input int    InpMinConsensus             = 4;     // out of 5 votes -- matches afa_v5_backtest.py: min_consensus=4
input double InpMinER                    = 0.35;
input double InpERHysteresisMult         = 1.25;  // exit-from-range threshold = InpMinER * this
input int    InpMaxFlipCount20           = 2;
input int    InpCooldownBase             = 3;
input int    InpCooldownAfter2Losses     = 8;

input group "=== K / S0 / Trail (Manifesto Section 5.2 -- cross-checked across 3 sources) ==="
input int    InpATR_FastPeriod           = 14;    // ATR_blend = (ATR14+ATR50)/2 , matches afa_v5_backtest.py exactly
input int    InpATR_SlowPeriod           = 50;
input double InpK_ATRCoef                = 0.4;
input double InpK_FloorSpreadMult        = 3.0;
input double InpK_FloorMaxATRFrac        = 0.8;   // if floor is active and K > this fraction of ATR -> skip trading entirely
input double InpS0_Coef                  = 1.5;
input double InpS0_FloorSpreadMult       = 4.0;
input double InpS0_FloorATRFrac          = 0.25;
input double InpTrail_ATRFrac            = 0.2;
input double InpTrail_FloorSpreadMult    = 3.0;
input int    InpMaxAdds                  = 18;    // safety cap only, not a close condition

input group "=== Position Sizing & Small Account ==="
input double InpRiskPercentPerCycle      = 0.5;   // percent of current equity
input bool   InpUseHighConfidenceBoost   = true;  // v2.11 g_highConfidence -> larger size
input double InpHighConfidenceSizeMult   = 1.3;
input bool   InpRejectIfMinLotExceedsRisk= true;  // *** $100-account report: never round volume up ***
input bool   InpAllowMinLotWithActualRiskCap = false;  // AI2 review #1: accept min lot with its true logged risk
input double InpMaxActualRiskPercentCap  = 10.0;       // only when the flag above is true: percent cap on true risk
input double InpMaxActualRiskUSD         = 15.0;       // *** absolute USD cap -- always compared in economic units ***

input group "=== Account Unit (Raw vs Economic) -- v5.04 ==="
input bool   InpUseAccountUnitScale      = false;  // off by default -- conversion only with explicit user confirmation
input double InpAccountUnitScale         = 100.0;  // e.g. 100 raw Cent units = 1 economic USD
input bool   InpAutoDetectCentCurrency   = true;   // logs a suggestion only -- never applied automatically
input string InpCentCurrencyTokens       = "USC,Cent,CENT";
input bool   InpWriteDiagnosticsWhenNoTrade = true;
input string InpRunId                    = "AUTO"; // AUTO = generated from start time

input group "=== Symbol Self-Selection Gate (Manifesto Section 5.9) ==="
input bool   InpUseSymbolGate            = true;
input int    InpSymbolWindowDays         = 365;
input int    InpSymbolMinCycles          = 40;
input string InpHistoryFileName          = "AFA_v5_CycleHistory.csv";
input bool   InpUseCommonFilesFolder     = false;  // AI2 review #8: true=shared across all terminals (MQL5\Files\Common), false=this terminal only. Usually safer as false in Strategy Tester.

input group "=== Global Protection Layer ==="
input double InpGlobalMaxDD_Percent      = 25.0;  // whole account: beyond this drawdown -> shared kill switch
input string InpGlobalKillSwitchGVName   = "AFA_v5_GlobalKill";
input string InpGlobalPeakEquityGVName   = "AFA_v5_GlobalPeakEquity";

input group "=== Phase 3 -- Regime Flip Mid-Cycle ==="
input int    InpFlipConfirmBars          = 2;     // 2 consecutive candles of opposing regime
input int    InpFlipMinConsensus         = 4;

input group "=== Execution / Misc ==="
input long   InpMagic                    = 500500;
input int    InpDeviation                = 30;
input bool   InpVerboseLog               = true;

//====================================================================
//  بخش ۱ / متغیرهای سراسری -- موتور رژیم (v2.11)
//====================================================================
int hADX, hATR_ST, hATR_STFast, hATR_Fast_H1, hATR_Slow_H1;
datetime g_lastRegimeTFBar=0, g_lastH1Bar=0;

int g_regime_M2A=0, g_pendingDir_M2A=0, g_pendingCount_M2A=0;
int g_regime_M4=0;  double g_st_upper=0, g_st_lower=0;   bool g_st_init=false;
int g_regime_M4B=0; double g_stB_upper=0, g_stB_lower=0; bool g_stB_init=false;
int g_regimeTFD=0;  double g_refTFD=0;
int g_regimeStruct=0;
int g_regimeMain=0;
int g_voteUp=0, g_voteDown=0, g_voteMargin=0;
bool g_trendingGate=false, g_highConfidence=false;
double g_erH4=0, g_erHistory[5];   // g_erHistory: بافر چرخه‌ای برای ΔER(5) واقعی
int g_erHistPos=0, g_erHistCount=0;
double g_erSlope5=0;
int g_regimeStableBars=0;
int g_regimeHistory[20];           // برای نرخ فلیپ ۲۰کندلی -- حلقه‌ای
int g_regimeHistPos=0;

string RegimeStr(int r){ return (r==1)?"Up":((r==-1)?"Down":"None"); }

//================== M2A: ADX جهت‌دار با تأیید ۵کندلی ==================
void UpdateM2A()
{
   double adxMain[1], plusDI[1], minusDI[1];
   if(CopyBuffer(hADX,0,1,1,adxMain)!=1) return;
   if(CopyBuffer(hADX,1,1,1,plusDI)!=1) return;
   if(CopyBuffer(hADX,2,1,1,minusDI)!=1) return;
   if(adxMain[0] < InpADX_MinStrength) return;
   int d = (plusDI[0] > minusDI[0]) ? 1 : -1;
   if(d == g_regime_M2A) { g_pendingDir_M2A=0; g_pendingCount_M2A=0; return; }
   if(d == g_pendingDir_M2A) g_pendingCount_M2A++;
   else { g_pendingDir_M2A=d; g_pendingCount_M2A=1; }
   if(g_pendingCount_M2A >= InpADX_ConfirmBars)
   { g_regime_M2A=d; g_pendingDir_M2A=0; g_pendingCount_M2A=0; }
}

//================== M4 / M4B: Supertrend (کند/تند) ==================
void UpdateSupertrend(int handle, double mult, double &upper, double &lower, bool &init, int &regime)
{
   double atrv[1];
   if(CopyBuffer(handle,0,1,1,atrv)!=1) return;
   double hi=iHigh(_Symbol,InpRegimeTF,1), lo=iLow(_Symbol,InpRegimeTF,1), cl=iClose(_Symbol,InpRegimeTF,1);
   double bU=(hi+lo)/2.0+mult*atrv[0], bL=(hi+lo)/2.0-mult*atrv[0];
   if(!init){ upper=bU; lower=bL; regime=(cl>=bL)?1:-1; init=true; return; }
   double prevCl=iClose(_Symbol,InpRegimeTF,2);
   double fU=(bU<upper||prevCl>upper)?bU:upper;
   double fL=(bL>lower||prevCl<lower)?bL:lower;
   int nr=regime;
   if(regime==1){ if(cl<fL) nr=-1; } else { if(cl>fU) nr=1; }
   upper=fU; lower=fL; regime=nr;
}

//================== TFD: شکست ساختار سوئینگ ==================
void UpdateTFD()
{
   int half=InpTFD_FractalBars/2;
   int bars=InpTFD_ScanBars;
   double swingHi=0, swingLo=0;
   for(int k=half; k<bars-half; k++)
   {
      bool isHigh=true, isLow=true;
      double hk=iHigh(_Symbol,InpRegimeTF,k+1), lk=iLow(_Symbol,InpRegimeTF,k+1);
      for(int j=1;j<=half;j++)
      {
         if(!(hk>=iHigh(_Symbol,InpRegimeTF,k+1-j) && hk>=iHigh(_Symbol,InpRegimeTF,k+1+j))) isHigh=false;
         if(!(lk<=iLow(_Symbol,InpRegimeTF,k+1-j)  && lk<=iLow(_Symbol,InpRegimeTF,k+1+j)))   isLow=false;
      }
      if(isHigh && swingHi==0) swingHi=hk;
      if(isLow  && swingLo==0) swingLo=lk;
      if(swingHi!=0 && swingLo!=0) break;
   }
   if(swingHi==0 || swingLo==0) return;
   double cl=iClose(_Symbol,InpRegimeTF,1);
   if(g_regimeTFD==0){ g_regimeTFD=(cl>=swingLo)?1:-1; g_refTFD=(g_regimeTFD==1)?swingLo:swingHi; return; }
   if(g_regimeTFD==1)
   {
      if(swingLo>g_refTFD) g_refTFD=swingLo;
      if(cl<g_refTFD){ g_regimeTFD=-1; g_refTFD=swingHi; }
   }
   else
   {
      if(swingHi<g_refTFD || g_refTFD==0) g_refTFD=swingHi;
      if(cl>g_refTFD){ g_regimeTFD=1; g_refTFD=swingLo; }
   }
}

//================== Struct: شکست دونچیان روزانه (۱۰روزه، بدون امروز/دیروز) ==================
void UpdateDailyStructure()
{
   double rh=iHigh(_Symbol,PERIOD_D1,2), rl=iLow(_Symbol,PERIOD_D1,2);
   for(int k=3;k<=InpStruct_LookbackDays+1;k++)
   { rh=MathMax(rh,iHigh(_Symbol,PERIOD_D1,k)); rl=MathMin(rl,iLow(_Symbol,PERIOD_D1,k)); }
   double cl=iClose(_Symbol,PERIOD_D1,1);
   if(cl>rh) g_regimeStruct=1;
   else if(cl<rl) g_regimeStruct=-1;
}

//================== ER (Kaufman) روی InpRegimeTF ==================
double EfficiencyRatio(int period)
{
   double net=MathAbs(iClose(_Symbol,InpRegimeTF,1)-iClose(_Symbol,InpRegimeTF,1+period));
   double path=0;
   for(int i=1;i<1+period;i++) path+=MathAbs(iClose(_Symbol,InpRegimeTF,i)-iClose(_Symbol,InpRegimeTF,i+1));
   if(path<=0) return 0;
   return net/path;
}

void UpdateTrendGate()
{
   double adx[1];
   if(CopyBuffer(hADX,0,1,1,adx)!=1){ g_trendingGate=false; return; }
   double er=EfficiencyRatio(InpER_Period);
   g_erH4=er;
   g_trendingGate=(adx[0]>=InpTrendGate_ADXMin)&&(er>=InpTrendGate_ERMin);
   g_highConfidence=g_trendingGate && (g_voteMargin>=InpMinVoteMargin);
}
// ΔER(5) واقعی: تفاضل با مقداری که دقیقا ۵ کندلِ InpRegimeTF قبل ثبت شده بود
double ERSlope5()
{
   if(g_erHistCount<5) return 0;   // داده کافی نیست -> گیت ۳ رد می‌کند (محافظه‌کارانه، نه false-positive)
   int oldestIdx=g_erHistPos%5;    // با پرشدن حلقه، این اندیس دقیقا مقدار ۵ کندل قبل را نگه می‌دارد
   return g_erH4 - g_erHistory[oldestIdx];
}
void PushERHistory(double er)
{
   g_erHistory[g_erHistPos%5]=er;
   g_erHistPos++;
   if(g_erHistCount<5) g_erHistCount++;
}

//================== رأی‌گیری اکثریت ۵تایی ==================
void UpdateMainEnsemble()
{
   int votes[5]={g_regime_M2A,g_regime_M4,g_regime_M4B,g_regimeTFD,g_regimeStruct};
   g_voteUp=0; g_voteDown=0;
   for(int i=0;i<5;i++){ if(votes[i]==1) g_voteUp++; else if(votes[i]==-1) g_voteDown++; }
   g_voteMargin=MathAbs(g_voteUp-g_voteDown);
   int prevRegime=g_regimeMain;
   if(g_voteUp>g_voteDown) g_regimeMain=1;
   else if(g_voteDown>g_voteUp) g_regimeMain=-1;
   // تساوی: رژیم قبلی حفظ می‌شود

   if(g_regimeMain==prevRegime && prevRegime!=0) g_regimeStableBars++;
   else g_regimeStableBars=0;
   g_regimeHistory[g_regimeHistPos%20]=(g_regimeMain!=prevRegime && prevRegime!=0)?1:0;
   g_regimeHistPos++;
}
int FlipCount20()
{
   int n=MathMin(g_regimeHistPos,20), s=0;
   for(int i=0;i<n;i++) s+=g_regimeHistory[i];
   return s;
}

//================== یک‌جا صدا زدن هر زیرموتور -- فقط وقتی کندل InpRegimeTF/D1 تازه بسته شده ==================
void UpdateRegimeEngineIfNewBar()
{
   datetime curBar=iTime(_Symbol,InpRegimeTF,0);
   if(curBar==g_lastRegimeTFBar) return;
   g_lastRegimeTFBar=curBar;
   UpdateM2A();
   UpdateSupertrend(hATR_ST,InpST_Multiplier,g_st_upper,g_st_lower,g_st_init,g_regime_M4);
   UpdateSupertrend(hATR_STFast,InpST_FastMultiplier,g_stB_upper,g_stB_lower,g_stB_init,g_regime_M4B);
   UpdateTFD();
   UpdateDailyStructure();
   UpdateTrendGate();          // g_erH4 را با مقدار تازهٔ همین کندل پر می‌کند
   g_erSlope5=ERSlope5();      // قبل از push: بافر هنوز مقدار ۵کندل‌قبل رو داره
   PushERHistory(g_erH4);      // حالا بافر رو با مقدار تازه به‌روز کن
   UpdateMainEnsemble();
}

//====================================================================
//  بخش ۲ / منطق چرخهٔ v5
//====================================================================

// -------- وضعیت چرخهٔ فعلی (فقط یک چرخه هم‌زمان روی این نماد) --------
bool   g_cycleActive=false;
int    g_cycleDirection=0;
double g_cycleK=0, g_cycleS0=0;
double g_cycleEntryPrice=0;
double g_cycleLastLegPrice=0;   // قیمت دقیقِ آخرین پا -- مبنای سطح AP بعدی (نه تقریبِ extreme)
double g_cycleExtreme=0;
double g_cycleTrail=0;          // 0 = هنوز فعال نشده
int    g_cycleNAdds=0;
double g_cycleVBase=0;
double g_cycleRiskBudgetUSD=0;   // نقد #۵: ریسکِ دلاریِ ثابت‌شده در لحظهٔ ورود (شاملِ بوست اعتماد)
double g_cycleRealizedPnL=0;     // نقد #۶: از OnTradeTransaction جمع می‌شه، نه floating قبل از close
bool   g_cycleIsPaper=false;     // *** رفعِ بن‌بستِ گیت ۵.۹: وقتی نماد داغ نیست، چرخه کاغذی شبیه‌سازی می‌شه
                                  // تا تاریخچه اصلاً بتونه جمع بشه -- نه اینکه برای همیشه صفر بمونه ***
int    g_flipStreak=0;   // برای فاز۳: شمارندهٔ کندل‌های پیاپیِ رژیم مخالف (باید همین‌جا قبل از استفاده تعریف بشه)

// -------- کول‌داون (جهت‌دار، تشدیدی) -- *** جدا برای کاغذی/واقعی طبقِ تشخیصِ AI4:
// وگرنه یه ضررِ کاغذیِ بی‌خطر می‌تونه ورودِ واقعی رو بدونِ هیچ دلیلِ واقعی عقب بندازه. ***
int g_realCooldownLeft=0, g_paperCooldownLeft=0;
int g_realConsecutiveLosses=0, g_paperConsecutiveLosses=0;
int g_realCooldownBlockedDirection=0, g_paperCooldownBlockedDirection=0;

// -------- واحدِ حساب (v5.04) -- زودهنگام تعریف شده چون WriteGateDiagnosticsRow زودتر ازش استفاده می‌کنه
double g_accountUnitScale=1.0;
bool   g_centCurrencySuggested=false;
string g_runId="";
// -------- شمارندهٔ همگام‌سازیِ SL (v5.05) -- زودهنگام چون OpenFirstLeg/AddLeg زودتر ازش استفاده می‌کنن
struct SLSyncStatsT { long success, deferred, rejected, alreadyTriggered; };   // *** v5.06: + alreadyTriggered ***
SLSyncStatsT g_slSync;

// -------- شمارنده‌های تشخیصی + فایلِ CSV (طبقِ مشخصاتِ صریح -- ستون‌به‌ستون) --------
struct GateStatsT
{
   long killSwitch,cooldown,range,consensus,erSlope,noRegime,computeK,symbolCold,minLot,margin,openFail;
};
GateStatsT g_gs;
int g_diagBarCount=0;

string GateDiagFileName() { return "AFA_v5_GateDiagnostics_"+g_runId+"_"+_Symbol+"_"+TFString(PERIOD_H1)+".csv"; }

void WriteGateDiagnosticsRow()
{
   // *** MinLot/MinLotRisk مستقل از اینکه گیت‌ها الان رد شدن یا نه محاسبه می‌شه --
   // چون این سطر باید حتی وقتی هیچ معامله‌ای نشده هم معنی‌دار باشه (خواستِ صریح). ***
   double atrBlend=AtrBlendH1();
   double spread=LiveSpread();
   double refK=0,refS0=0,minLotRiskRaw=0,minLotRiskUSD=0;
   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if(spread>0 && ComputeK(atrBlend,spread,refK))
   {
      refS0=ComputeS0(refK,atrBlend,spread);
      double vpp=ValuePerPriceMovePerLot();
      minLotRiskRaw=minLot*refS0*vpp;
      minLotRiskUSD=minLotRiskRaw/g_accountUnitScale;
   }
   double rawBal=RawBalance();
   double econBal=EconomicBalanceUSD();
   double targetRiskRaw=rawBal*(InpRiskPercentPerCycle/100.0);
   double targetRiskUSD=targetRiskRaw/g_accountUnitScale;

   int h=FileOpen(GateDiagFileName(),HistFileFlags(FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI),',');
   if(h==INVALID_HANDLE)
   {
      Print("!!! FileOpen شکست خورد برای '",GateDiagFileName(),"'  GetLastError=",GetLastError());
   }
   else
   {
      FileSeek(h,0,SEEK_END);
      if(FileTell(h)==0)   // سربرگ فقط یه‌بار
         FileWrite(h,"RunID","Time","Symbol","Timeframe","AccountCurrency","RawBalance","AccountUnitScale",
                   "EconomicBalanceUSD","TargetRiskRaw","TargetRiskUSD","MinLot","MinLotRiskRaw","MinLotRiskUSD",
                   "GateSymbol","GateCooldown","GateRange","GateConsensus","GateSlope","GateNoRegime",
                   "GateComputeK","GateMinLot","GateMargin","GateOpenFail","LastRegime","VoteMargin","HighConfidence",
                   "SL_SYNC_SUCCESS","SL_SYNC_DEFERRED","SL_SYNC_REJECTED","SL_ALREADY_TRIGGERED");
      FileWrite(h,g_runId,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),_Symbol,TFString(PERIOD_H1),
                AccountInfoString(ACCOUNT_CURRENCY),DoubleToString(rawBal,2),DoubleToString(g_accountUnitScale,4),
                DoubleToString(econBal,2),DoubleToString(targetRiskRaw,4),DoubleToString(targetRiskUSD,4),
                DoubleToString(minLot,2),DoubleToString(minLotRiskRaw,4),DoubleToString(minLotRiskUSD,4),
                g_gs.symbolCold,g_gs.cooldown,g_gs.range,g_gs.consensus,g_gs.erSlope,g_gs.noRegime,
                g_gs.computeK,g_gs.minLot,g_gs.margin,g_gs.openFail,g_regimeMain,g_voteMargin,
                g_highConfidence?"true":"false",g_slSync.success,g_slSync.deferred,g_slSync.rejected,
                g_slSync.alreadyTriggered);
      FileClose(h);
   }

   Print("GATES(",g_diagBarCount,"): kill=",g_gs.killSwitch," cooldown=",g_gs.cooldown," range=",g_gs.range,
         " consensus=",g_gs.consensus," slope=",g_gs.erSlope," noRegime=",g_gs.noRegime,
         " computeK=",g_gs.computeK," symbolCold=",g_gs.symbolCold," minLot=",g_gs.minLot,
         " margin=",g_gs.margin," openFail=",g_gs.openFail,
         " | SL_SYNC_SUCCESS=",g_slSync.success," SL_SYNC_DEFERRED=",g_slSync.deferred,
         " SL_SYNC_REJECTED=",g_slSync.rejected," SL_ALREADY_TRIGGERED=",g_slSync.alreadyTriggered,
         " | RawBal=",DoubleToString(rawBal,2)," EconBalUSD=",DoubleToString(econBal,2),
         " TargetRiskUSD=",DoubleToString(targetRiskUSD,4)," MinLotRiskUSD=",DoubleToString(minLotRiskUSD,4));
}
void PrintGateStatsIfDue()
{
   g_diagBarCount++;
   if(g_diagBarCount%100!=0) return;
   WriteGateDiagnosticsRow();
}

// -------- تاریخچهٔ چرخه‌های بسته‌شده --------
// *** طراحیِ عمدی: IsSymbolHot از تاریخچهٔ *ترکیبی* (کاغذی+واقعی) تصمیم می‌گیره -- چون اگه فقط
// واقعی بشمریم، دوباره بن‌بستِ قبلی برمی‌گرده (واقعی نیاز به داغ‌بودن داره، داغ‌بودن نیاز به واقعی).
// ولی طبقِ نگرانیِ درستِ AI4 (که عملکردِ کاغذی بدونِ لغزش/هزینهٔ کاملِ واقعی می‌تونه خوش‌بینانه باشه)،
// یه فایلِ جداگانهٔ «فقط-واقعی» هم نگه می‌داریم، صرفاً برای گزارش‌گیریِ شفاف -- هیچ تصمیمی ازش گرفته نمی‌شه. ***
struct HistRow { datetime t; double r; };
HistRow g_hist[];

//------------------------------------------------------ ابزار قیمت/حجم
double LiveSpread()
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) return 0;
   double s=tick.ask-tick.bid;
   return (s>0)?s:0;   // *** نقد #11: از Ask-Bid زنده، نه SYMBOL_SPREAD که می‌تونه stale/نامعتبر باشه ***
}
bool HasEnoughFreeMargin(double lot,int direction)
{
   double marginReq=0;
   ENUM_ORDER_TYPE ot=(direction==1)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
   if(!OrderCalcMargin(ot,_Symbol,lot,SymbolInfoDouble(_Symbol,(direction==1)?SYMBOL_ASK:SYMBOL_BID),marginReq))
      return false;   // محاسبه نشد -> محافظه‌کارانه رد کن
   double freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   return freeMargin>=marginReq*1.2;   // ۲۰٪ بافر ایمنی روی مارجینِ لازم
}
double AtrBlendH1()
{
   double f[1], s[1];
   if(CopyBuffer(hATR_Fast_H1,0,1,1,f)!=1) return 0;
   if(CopyBuffer(hATR_Slow_H1,0,1,1,s)!=1) return 0;
   return (f[0]+s[0])/2.0;
}
// *** رفعِ باگِ حیاتیِ v5.03: قبلاً از TickValue/TickSize استفاده می‌شد. در تستِ واقعیِ
// USDJPY_l، این نسبت ۱۵۵٫۲ برابرِ مقدارِ درست بود -- دقیقاً برابرِ نرخِ USDJPY، یعنی
// این بروکر/سرورِ Strategy Tester تیک‌ولیوی این نماد رو از ین به دلار تبدیل نمی‌کنه.
// نتیجه‌ش: هم لاتِ محاسبه‌شده ۱۵۵ برابر کوچیک‌تر از هدف بود، هم R گزارش‌شده غلط.
// OrderCalcProfit همون تابعیه که خودِ ترمینال برای سود/زیانِ واقعی استفاده می‌کنه --
// تبدیلِ ارز رو همیشه درست انجام می‌ده، صرف‌نظر از اینکه نماد چه ارزی قیمت‌گذاری شده. ***
double ValuePerPriceMovePerLot()
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) return 0;
   double refPrice=(tick.bid+tick.ask)/2.0;
   double delta=100*_Point;
   double profit=0;
   if(!OrderCalcProfit(ORDER_TYPE_BUY,_Symbol,1.0,refPrice,refPrice+delta,profit)) return 0;
   if(delta<=0) return 0;
   return MathAbs(profit/delta);
}

//------------------------------------------------------ گیت‌های فاز صفر
bool GateCooldown(int proposedDir,bool forReal)
{
   int left       = forReal ? g_realCooldownLeft : g_paperCooldownLeft;
   int blockedDir = forReal ? g_realCooldownBlockedDirection : g_paperCooldownBlockedDirection;
   if(left>0) return false;
   if(blockedDir!=0 && proposedDir==blockedDir) return false;
   return true;
}
// *** رفعِ باگِ اصلیِ این نسخه: قبلاً هیچ‌جا cooldownLeft کم نمی‌شد -- فقط موقعِ بستنِ
// چرخه ست می‌شد. یعنی بعد از اولین چرخه (کاغذی یا واقعی)، برای همیشه قفل می‌موند،
// نه فقط ۳ کندل. این تابع باید هرکندلِ بی‌کاری صدا زده بشه. ***
void TickCooldowns()
{
   if(g_realCooldownLeft>0) g_realCooldownLeft--;
   if(g_paperCooldownLeft>0) g_paperCooldownLeft--;
}
bool g_currentlyInRange=false;
bool GateRangeFilter(double er,double flipRate,double consensusVotes)
{
   double minEr = g_currentlyInRange ? InpMinER*InpERHysteresisMult : InpMinER;
   if(er<minEr) { g_currentlyInRange=true;  return false; }
   g_currentlyInRange=false;
   if(flipRate>InpMaxFlipCount20) return false;
   return true;   // *** اجماع دیگه اینجا چک نمی‌شه -- جدا و زودتر، برای شمارندهٔ تشخیصیِ دقیق ***
}
bool GateEntryConfirm(double erSlope5) { return erSlope5>0; }   // مطابق afa_v5_backtest.py (بدون شرط جداگانهٔ stable-bars)

//------------------------------------------------------ K / S0 / تریل
// برمی‌گرداند false یعنی: این نماد/ساعت اصلا معامله نشود (کف فعال و از سقف ATR رد شد)
bool ComputeK(double atrBlend,double spread,double &kOut)
{
   double k=InpK_ATRCoef*atrBlend;
   if(k<InpK_FloorSpreadMult*spread)
   {
      k=InpK_FloorSpreadMult*spread;
      if(k>InpK_FloorMaxATRFrac*atrBlend) return false;
   }
   kOut=k;
   return true;
}
double ComputeS0(double k,double atrBlend,double spread)
{
   double s0=InpS0_Coef*k;
   double floor_=MathMax(InpS0_FloorSpreadMult*spread, InpS0_FloorATRFrac*atrBlend);
   return MathMax(s0,floor_);
}
double CandidateTrailDistance(double atrBlend,double spread)
{
   return MathMax(InpTrail_ATRFrac*atrBlend, InpTrail_FloorSpreadMult*spread);
}

//------------------------------------------------------ v5.04: واحدِ حساب (Raw vs Economic)
// *** طراحی طبقِ پرامپتِ صریح: تشخیصِ خودکار فقط لاگ/پیشنهاده، هرگز خودش scale رو
// عوض نمی‌کنه. scale فقط با InpUseAccountUnitScale=true (صریحِ کاربر) فعال می‌شه.
// این یعنی رفتار با Initial Deposit=10000 (بدونِ این پرچم) دقیقاً مثلِ قبل می‌مونه. ***

void DetectCentCurrencySuggestionOnly()
{
   string cur=AccountInfoString(ACCOUNT_CURRENCY);
   string tokens[];
   int n=StringSplit(InpCentCurrencyTokens,',',tokens);
   for(int i=0;i<n;i++)
   {
      string tok=tokens[i];
      StringTrimLeft(tok); StringTrimRight(tok);
      if(tok=="" || StringFind(cur,tok)<0) continue;
      g_centCurrencySuggested=true;
      Print("*** تشخیصِ خودکار (فقط پیشنهاد، اعمال نشد): ACCOUNT_CURRENCY='",cur,
            "' شاملِ توکنِ Cent-مانندِ '",tok,"'ه. اگه واقعاً حساب Centه، ",
            "InpUseAccountUnitScale=true رو صریحاً ست کن -- خودم به‌تنهایی این کارو نمی‌کنم. ***");
      return;
   }
}
void InitAccountUnitScale()
{
   g_accountUnitScale = InpUseAccountUnitScale ? InpAccountUnitScale : 1.0;
   if(InpAutoDetectCentCurrency) DetectCentCurrencySuggestionOnly();
   Print("AccountUnitScale مؤثر = ",DoubleToString(g_accountUnitScale,4),
         "  (InpUseAccountUnitScale=",InpUseAccountUnitScale?"true":"false",
         "  تشخیصِ Cent=",g_centCurrencySuggested?"بله(نادیده‌گرفته‌شد)":"خیر",")");
}
double RawBalance()         { return AccountInfoDouble(ACCOUNT_BALANCE); }
double RawEquity()          { return AccountInfoDouble(ACCOUNT_EQUITY);  }
double EconomicBalanceUSD() { return RawBalance()/g_accountUnitScale;    }
double EconomicEquityUSD()  { return RawEquity()/g_accountUnitScale;     }
string TFString(ENUM_TIMEFRAMES tf) { return EnumToString(tf); }
void InitRunId()
{
   if(InpRunId=="AUTO" || InpRunId=="")
   {
      MqlDateTime dt; TimeToStruct(TimeLocal(),dt);
      g_runId=StringFormat("%04d%02d%02d_%02d%02d%02d",dt.year,dt.mon,dt.day,dt.hour,dt.min,dt.sec);
   }
   else g_runId=InpRunId;
}
// *** نکته: منطقِ اصلیِ سایزینگ (ComputeLotSize) عمداً روی واحدِ خام کار می‌کنه --
// چون سایزینگِ درصدی-از-اکوییتی خودش scale-invariant‌ه (هم صورت هم مخرج با هم
// مقیاس عوض می‌کنن)، به scale نیازی نداره. فقط سقفِ *دلاریِ مطلق*
// (InpMaxActualRiskUSD) واقعاً معنیِ «دلارِ واقعی» داره، پس فقط همون‌جا از
// scale استفاده می‌شه -- نه در کلِ فرمول. ***


// برمی‌گرداند 0.0 یعنی: رد کن، معامله نکن. ریسکِ دلاریِ واقعی از طریق پارامترِ خروجی برمی‌گرده
// (نه هدف؛ چون وقتی لات floor/cap می‌خوره، ریسکِ واقعی با هدف فرق می‌کنه -- نقد #۵).
double ComputeLotSize(double s0Price, double &actualRiskBudgetOut)
{
   actualRiskBudgetOut=0;
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double riskBudget=equity*(InpRiskPercentPerCycle/100.0);
   if(InpUseHighConfidenceBoost && g_highConfidence) riskBudget*=InpHighConfidenceSizeMult;

   double vpp=ValuePerPriceMovePerLot();
   if(vpp<=0 || s0Price<=0) return 0.0;
   double rawLot=riskBudget/(s0Price*vpp);

   double lotStep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double minLot =SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxLot =SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(lotStep<=0) lotStep=0.01;

   double lot=MathFloor(rawLot/lotStep+1e-9)*lotStep;   // *** فقط گرد به پایین ***
   if(lot>=minLot){ lot=MathMin(lot,maxLot); actualRiskBudgetOut=lot*s0Price*vpp; return lot; }

   // *** نقد #۱: حجم زیر حداقل لات -- دو حالت صریح، نه فقط رد خودکار ***
   if(InpAllowMinLotWithActualRiskCap)
   {
      double actualRiskAtMinLot=minLot*s0Price*vpp;                          // RawRiskUnits
      double actualRiskAtMinLotUSD=actualRiskAtMinLot/g_accountUnitScale;    // EconomicRiskUSD
      double actualRiskPct=100.0*actualRiskAtMinLot/equity; // درصد: خام/خام = بدون نیاز به scale
      // *** سقفِ درصدی به‌تنهایی برای حساب‌های خیلی کوچک کافی نیست -- پس هردو سقف
      // (درصد، در واحدِ نسبی؛ و دلار، در واحدِ اقتصادیِ واقعی) هم‌زمان رعایت می‌شن. ***
      if(actualRiskPct>InpMaxActualRiskPercentCap || actualRiskAtMinLotUSD>InpMaxActualRiskUSD)
      {
         if(InpVerboseLog) Print("REJECTED: even min lot gives RawRiskUnits=",DoubleToString(actualRiskAtMinLot,4),
                                  " EconomicRiskUSD=",DoubleToString(actualRiskAtMinLotUSD,2),
                                  " (",DoubleToString(actualRiskPct,1),"% of equity) > cap ",
                                  InpMaxActualRiskPercentCap,"%/USD",InpMaxActualRiskUSD);
         return 0.0;
      }
      if(InpVerboseLog) Print("WARNING: min lot accepted with RawRiskUnits=",DoubleToString(actualRiskAtMinLot,4),
                               " EconomicRiskUSD=",DoubleToString(actualRiskAtMinLotUSD,2),
                               " (",DoubleToString(actualRiskPct,2),"% of equity, target was ",InpRiskPercentPerCycle,"%)");
      actualRiskBudgetOut=actualRiskAtMinLot;
      return MathMin(minLot,maxLot);
   }
   if(!InpRejectIfMinLotExceedsRisk)   // override صریح قدیمی (بدون سقف) -- برای سازگاری نگه داشته شده
   {
      actualRiskBudgetOut=minLot*s0Price*vpp;
      return MathMin(minLot,maxLot);
   }
   return 0.0;   // *** قانون گزارش ۱۰۰دلاری: رد کن، گرد به بالا نکن ***
}

//------------------------------------------------------ لایهٔ محافظ سراسری (مشترک بین همهٔ نمادها/چارت‌ها)
bool GlobalKillSwitchActive()
{
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double peak=GlobalVariableCheck(InpGlobalPeakEquityGVName)?GlobalVariableGet(InpGlobalPeakEquityGVName):equity;
   peak=MathMax(peak,equity);
   GlobalVariableSet(InpGlobalPeakEquityGVName,peak);

   if(GlobalVariableCheck(InpGlobalKillSwitchGVName) && GlobalVariableGet(InpGlobalKillSwitchGVName)>0.5)
   {
      // خروج خودکار در شروع روز/هفتهٔ بعد (بخش ۵.۵.۱ v4/v5، بدون تغییر)
      MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
      if(dt.hour==0 && dt.min<5) GlobalVariableSet(InpGlobalKillSwitchGVName,0.0);
      else return true;
   }

   double ddPct=(peak>0)?(100.0*(peak-equity)/peak):0.0;
   if(ddPct>=InpGlobalMaxDD_Percent)
   {
      GlobalVariableSet(InpGlobalKillSwitchGVName,1.0);
      Print("*** GLOBAL KILL SWITCH: DD=",DoubleToString(ddPct,2),"% >= ",InpGlobalMaxDD_Percent,"% -- همهٔ نمادها متوقف تا شروع روز بعد ***");
      return true;
   }
   return false;
}

//------------------------------------------------------ خودانتخابیِ نماد (۵.۹، walk-forward، بدون نگاه‌به‌جلو)
// *** نکته: نام فایل عمداً به نماد گره خورده -- وگرنه اگه این EA رو روی چند
// چارت/نماد همزمان ببندی، همه روی یک فایل مشترک می‌نویسن و تاریخچهٔ هرکدوم
// با بقیه قاطی می‌شه. FILE_COMMON هم عمدا استفاده نشده چون در Strategy
// Tester همیشه در دسترس نیست؛ اگه بین چند ترمینال هم می‌خوای مشترک باشه،
// خودت این پرچم رو برگردون. ***
string HistFileName() { return InpHistoryFileName + "_" + _Symbol + ".csv"; }
string RealOnlyReportFileName() { return InpHistoryFileName+"_REAL_ONLY_"+g_runId+"_"+_Symbol+"_"+TFString(PERIOD_H1)+".csv"; }
// *** فایلِ فقط-واقعی: صرفاً برای گزارش‌گیریِ شفاف (خواستهٔ AI4)، هیچ‌جا خونده نمی‌شه،
// فقط نوشته می‌شه -- تا بشه دید عملکردِ *واقعیِ واقعی* (نه ترکیب‌شده با کاغذی) چیه. ***
void AppendRealOnlyReport(datetime t,double r,double pnlUsd,int nAdds,string reason)
{
   int h=FileOpen(RealOnlyReportFileName(),HistFileFlags(FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI),',');
   if(h==INVALID_HANDLE)
   {
      Print("!!! FileOpen شکست خورد برای '",RealOnlyReportFileName(),"'  GetLastError=",GetLastError());
      return;
   }
   FileSeek(h,0,SEEK_END);
   FileWrite(h,TimeToString(t,TIME_DATE|TIME_SECONDS),DoubleToString(r,4),DoubleToString(pnlUsd,2),nAdds,reason);
   FileClose(h);
}
int HistFileFlags(int base) { return InpUseCommonFilesFolder ? (base|FILE_COMMON) : base; }
void LoadCycleHistory()
{
   ArrayResize(g_hist,0);
   int h=FileOpen(HistFileName(),HistFileFlags(FILE_READ|FILE_CSV|FILE_ANSI),',');
   if(h==INVALID_HANDLE) return;
   int skipped=0;
   while(!FileIsEnding(h))
   {
      string ts=FileReadString(h);
      if(StringLen(ts)==0) break;
      double r=FileReadNumber(h);
      datetime t=(datetime)StringToTime(ts);
      // *** نقد #۹: رکوردِ نامعتبر (تاریخِ خراب/آینده، R نامعقول) رد می‌شه، نه اینکه کل گیت رو خراب کنه ***
      if(t<=0 || t>TimeCurrent()+86400 || !MathIsValidNumber(r) || MathAbs(r)>1000.0) { skipped++; continue; }
      HistRow row; row.t=t; row.r=r;
      int n=ArraySize(g_hist); ArrayResize(g_hist,n+1); g_hist[n]=row;
   }
   FileClose(h);
   if(skipped>0) Print("LoadCycleHistory: ",skipped," ردیف نامعتبر رد شد از ",HistFileName());
}
void AppendCycleHistory(datetime t,double r)
{
   int n=ArraySize(g_hist); ArrayResize(g_hist,n+1);
   g_hist[n].t=t; g_hist[n].r=r;
   int h=FileOpen(HistFileName(),HistFileFlags(FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI),',');
   if(h==INVALID_HANDLE) return;
   FileSeek(h,0,SEEK_END);
   FileWrite(h,TimeToString(t,TIME_DATE|TIME_SECONDS),DoubleToString(r,4));
   FileClose(h);
}
bool IsSymbolHot()
{
   if(!InpUseSymbolGate) return true;
   datetime now=TimeCurrent();
   int count=0; double sumR=0;
   for(int i=0;i<ArraySize(g_hist);i++)
   {
      if(now-g_hist[i].t<=(long)InpSymbolWindowDays*86400)
      { count++; sumR+=g_hist[i].r; }
   }
   return (count>=InpSymbolMinCycles) && (sumR>0.0);
}

//------------------------------------------------------ باز/بسته‌کردنِ چرخه
double CycleFloatingProfit()
{
   double p=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong tk=PositionGetTicket(i);
      if(PositionSelectByTicket(tk) && PositionGetString(POSITION_SYMBOL)==_Symbol
         && PositionGetInteger(POSITION_MAGIC)==InpMagic)
         p+=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
   }
   return p;
}
int CountCycleLegs()
{
   int c=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong tk=PositionGetTicket(i);
      if(PositionSelectByTicket(tk) && PositionGetString(POSITION_SYMBOL)==_Symbol
         && PositionGetInteger(POSITION_MAGIC)==InpMagic) c++;
   }
   return c;
}

// *** نقد #۷: فقط درخواستِ close رو می‌فرسته و نتیجهٔ فوریِ ارسال رو چک می‌کنه.
// state را پاک نمی‌کند -- این کار را FinalizeClosedCycle (از OnTradeTransaction)
// انجام می‌دهد، فقط وقتی *واقعاً* هیچ پوزیشنی از این چرخه باقی نمانده باشد. ***
bool g_cycleClosing=false;
string g_pendingCloseReason="";
void CloseAllCycleLegs(string reason)
{
   g_cycleClosing=true;
   g_pendingCloseReason=reason;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong tk=PositionGetTicket(i);
      if(PositionSelectByTicket(tk) && PositionGetString(POSITION_SYMBOL)==_Symbol
         && PositionGetInteger(POSITION_MAGIC)==InpMagic)
      {
         if(!trade.PositionClose(tk,InpDeviation))
            Print("!!! CLOSE FAILED ticket=",tk," retcode=",trade.ResultRetcode(),
                  " ",trade.ResultRetcodeDescription()," -- کندل بعد دوباره تلاش می‌شه");
      }
   }
   // اگه بعضی close ها fail بشن، g_cycleActive رو true نگه می‌داریم (پایین) تا کندل
   // بعد دوباره چک بشه (چون stopHit دوباره true خواهد بود و CloseAllCycleLegs دوباره صدا زده می‌شه).
}

// *** نقد #۵ #۶: از رویداد واقعیِ deal (نه floating PnL قبل از close) و از ریسکِ
// ذخیره‌شده در لحظهٔ ورود (نه اکوییتیِ لحظهٔ بستن) استفاده می‌کنه. ***
void ResetCycleState()
{
   g_cycleActive=false; g_cycleDirection=0; g_cycleK=0; g_cycleS0=0; g_cycleNAdds=0;
   g_cycleExtreme=0; g_cycleTrail=0; g_cycleEntryPrice=0; g_cycleLastLegPrice=0; g_cycleVBase=0;
   g_cycleRiskBudgetUSD=0; g_cycleRealizedPnL=0; g_cycleClosing=false; g_pendingCloseReason="";
   g_cycleIsPaper=false; g_flipStreak=0;
}
void ApplyCooldownAfterClose(double r,string reason,bool isPaper)
{
   bool stopLoss=(reason=="STOP_S0"||reason=="STOP_S0_BROKER"||reason=="STOP_S0_PAPER");
   if(isPaper)
   {
      g_paperConsecutiveLosses = (r<0) ? g_paperConsecutiveLosses+1 : 0;
      g_paperCooldownLeft=(g_paperConsecutiveLosses>=2)?InpCooldownAfter2Losses:InpCooldownBase;
      g_paperCooldownBlockedDirection=stopLoss?g_cycleDirection:0;
   }
   else
   {
      g_realConsecutiveLosses = (r<0) ? g_realConsecutiveLosses+1 : 0;
      g_realCooldownLeft=(g_realConsecutiveLosses>=2)?InpCooldownAfter2Losses:InpCooldownBase;
      g_realCooldownBlockedDirection=stopLoss?g_cycleDirection:0;
   }
}
void FinalizeClosedCycle()
{
   double r=(g_cycleRiskBudgetUSD>0)?(g_cycleRealizedPnL/g_cycleRiskBudgetUSD):0.0;   // R_actual: pure ratio, raw/raw, scale-invariant
   AppendCycleHistory(TimeCurrent(),r);
   AppendRealOnlyReport(TimeCurrent(),r,g_cycleRealizedPnL,g_cycleNAdds,g_pendingCloseReason);
   ApplyCooldownAfterClose(r,g_pendingCloseReason,false);
   if(InpVerboseLog) Print("CLOSED [real,",g_pendingCloseReason,"]",
                            " RawPnLUnits=",DoubleToString(g_cycleRealizedPnL,4),
                            " EconomicPnLUSD=",DoubleToString(g_cycleRealizedPnL/g_accountUnitScale,2),
                            " RawRiskUnits=",DoubleToString(g_cycleRiskBudgetUSD,4),
                            " EconomicRiskUSD=",DoubleToString(g_cycleRiskBudgetUSD/g_accountUnitScale,2),
                            " R_actual=",DoubleToString(r,3)," n_adds=",g_cycleNAdds," cooldown(real)->",g_realCooldownLeft);
   ResetCycleState();
}

// *** رفعِ بن‌بستِ گیت ۵.۹: بستنِ چرخهٔ کاغذی. هیچ پوزیشنِ واقعی‌ای نیست، پس R از
// همون فرمولِ تحلیلیِ afa_v5_engine.py محاسبه می‌شه -- مستقل از حجم/دلار، فقط از
// سطوحِ قیمت: gross = (n+1)·d·(exit−entry) − K·n·(n+1)/2 ، سپس R=gross/S0.
// کول‌داونِ کاغذی از واقعی جداست (طبقِ تشخیصِ AI4) -- یه ضررِ کاغذی نباید ورودِ
// واقعی رو عقب بندازه، چون هیچ سرمایهٔ واقعی‌ای درگیر نبوده. ***
void ClosePaperCycle(string reason,double exitPrice)
{
   int n=g_cycleNAdds;
   double pnlPriceUnits=g_cycleDirection*(n+1)*(exitPrice-g_cycleEntryPrice) - g_cycleK*n*(n+1)/2.0;
   double r=(g_cycleS0>0)?(pnlPriceUnits/g_cycleS0):0.0;
   AppendCycleHistory(TimeCurrent(),r);
   ApplyCooldownAfterClose(r,reason,true);
   if(InpVerboseLog) Print("CLOSED [paper,",reason,"] R=",DoubleToString(r,3)," n_adds=",n,
                            " cooldown(paper)->",g_paperCooldownLeft);
   ResetCycleState();
}

// *** نقد #۶: PnL واقعی را از خودِ dealهای بسته‌شده جمع می‌زند، نه از floating لحظه‌ای قبل از close. ***
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
{
   if(g_cycleIsPaper) return;   // چرخهٔ کاغذی هیچ deal واقعی‌ای تولید نمی‌کنه
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetString(trans.deal,DEAL_SYMBOL)!=_Symbol) return;
   if(HistoryDealGetInteger(trans.deal,DEAL_MAGIC)!=InpMagic) return;
   ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
   if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_INOUT) return;   // فقط دیل‌های بستن (نه بازکردن)

   double profit=HistoryDealGetDouble(trans.deal,DEAL_PROFIT);
   double swap=HistoryDealGetDouble(trans.deal,DEAL_SWAP);
   double comm=HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
   g_cycleRealizedPnL+=profit+swap+comm;

   // *** چرخه ممکنه با درخواستِ خودمون (CloseAllCycleLegs) بسته شده باشه، یا با SL
   // واقعیِ بروکر (SyncBrokerStop) که بین دو کندل مستقلاً تریگر شده -- هردو حالت
   // اینجا یکسان تشخیص داده می‌شن: چرخه فعال بود، الان دیگه پوزیشنی نمونده. ***
   if(g_cycleActive && CountCycleLegs()==0)
   {
      if(!g_cycleClosing) g_pendingCloseReason=(g_cycleNAdds==0?"STOP_S0_BROKER":"TRAIL_EXIT_BROKER");
      FinalizeClosedCycle();
   }
}
bool OpenFirstLeg(int direction,double k,double s0,double lot,double riskBudgetUSD,bool isPaper)
{
   MqlTick tick; if(!SymbolInfoTick(_Symbol,tick)) return false;
   double price=(direction==1)?tick.ask:tick.bid;
   if(!isPaper)
   {
      double effRef=0,effDist=0;
      double slPrice=ClampStopToBrokerLimits(price-direction*s0,direction,effRef,effDist);
      bool ok=(direction==1)?trade.Buy(lot,_Symbol,0,slPrice,0,"AFAv5"):trade.Sell(lot,_Symbol,0,slPrice,0,"AFAv5");
      if(!ok)
      {
         g_slSync.rejected++;
         Print("!!! OpenFirstLeg FAILED  Symbol=",_Symbol," Direction=",direction,
               " Bid=",DoubleToString(tick.bid,_Digits)," Ask=",DoubleToString(tick.ask,_Digits),
               " RequestedSL=",DoubleToString(slPrice,_Digits)," EffectiveDistance=",DoubleToString(effDist,1),"pts",
               " Retcode=",trade.ResultRetcode()," (",trade.ResultRetcodeDescription(),")");
         return false;
      }
      g_slSync.success++;
   }
   g_cycleActive=true; g_cycleDirection=direction; g_cycleK=k; g_cycleS0=s0;
   g_cycleEntryPrice=price; g_cycleLastLegPrice=price; g_cycleExtreme=price; g_cycleTrail=0;
   g_cycleNAdds=0; g_cycleVBase=lot; g_cycleIsPaper=isPaper;
   g_cycleRiskBudgetUSD=riskBudgetUSD;  // raw units -- economic conversion happens only at log/report time
   g_cycleRealizedPnL=0;
   if(InpVerboseLog) Print(isPaper?"OPEN[PAPER] ":"OPEN[REAL] ",(direction==1?"BUY":"SELL")," lot=",lot,
                            " K=",DoubleToString(k,_Digits)," S0=",DoubleToString(s0,_Digits),
                            " price=",DoubleToString(price,_Digits),
                            " RawRiskUnits=",DoubleToString(riskBudgetUSD,2),
                            " EconomicRiskUSD=",DoubleToString(riskBudgetUSD/g_accountUnitScale,2));
   return true;
}
bool AddLeg(int direction,double lot,double fillPriceRef,bool isPaper)
{
   if(!isPaper)
   {
      MqlTick tick; if(!SymbolInfoTick(_Symbol,tick)) return false;
      double effRef=0,effDist=0;
      double slPrice=ClampStopToBrokerLimits(GoverningStopLevel(),direction,effRef,effDist);
      bool ok=(direction==1)?trade.Buy(lot,_Symbol,0,slPrice,0,"AFAv5"):trade.Sell(lot,_Symbol,0,slPrice,0,"AFAv5");
      if(!ok)
      {
         g_slSync.rejected++;
         Print("!!! AddLeg FAILED  Symbol=",_Symbol," Direction=",direction,
               " Bid=",DoubleToString(tick.bid,_Digits)," Ask=",DoubleToString(tick.ask,_Digits),
               " RequestedSL=",DoubleToString(slPrice,_Digits)," EffectiveDistance=",DoubleToString(effDist,1),"pts",
               " Retcode=",trade.ResultRetcode()," (",trade.ResultRetcodeDescription(),")");
         return false;
      }
      g_slSync.success++;
   }
   g_cycleNAdds++;
   // مرجع سطح AP بعدی: قیمتِ سطحی که همین الان لمس شد (fillPriceRef از کندل H1)، نه tick لحظه‌ای --
   // برای هم‌خوانی دقیق با afa_v5_engine.py که ap_level را از entry_price دقیقِ آخرین پا می‌سازد.
   g_cycleLastLegPrice=fillPriceRef;
   if(InpVerboseLog) Print(isPaper?"ADD[PAPER] #":"ADD[REAL] #",g_cycleNAdds," lot=",lot,
                            " levelRef=",DoubleToString(fillPriceRef,_Digits));
   return true;
}

//------------------------------------------------------ به‌روزرسانیِ اکسترمم/تریل (ratchet -- هرگز عقب نمی‌رود)
// عمداً از high/low کندلِ H1 *بسته‌شده* استفاده می‌کند (نه tick لحظه‌ای) -- هم‌خوان با
// afa_v5_engine.py و با اینکه بقیهٔ دیسپچر (استاپ/AP) هم روی همین مبنا کار می‌کنن.
void UpdateTrail(double atrBlend,double spread)
{
   if(g_cycleNAdds==0) return;
   double h1=iHigh(_Symbol,PERIOD_H1,1), l1=iLow(_Symbol,PERIOD_H1,1);
   double dist=CandidateTrailDistance(atrBlend,spread);
   if(g_cycleDirection==1)
   {
      g_cycleExtreme=MathMax(g_cycleExtreme,h1);
      double cand=g_cycleExtreme-dist;
      g_cycleTrail=(g_cycleTrail==0)?cand:MathMax(g_cycleTrail,cand);
   }
   else
   {
      g_cycleExtreme=(g_cycleExtreme==0)?l1:MathMin(g_cycleExtreme,l1);
      double cand=g_cycleExtreme+dist;
      g_cycleTrail=(g_cycleTrail==0)?cand:MathMin(g_cycleTrail,cand);
   }
}
double GoverningStopLevel()
{
   if(g_cycleNAdds==0) return g_cycleEntryPrice-g_cycleDirection*g_cycleS0;
   return g_cycleTrail;
}
// *** نقد #۱۰: SL واقعیِ بروکر رو با سطحِ محاسبه‌شده هماهنگ نگه می‌داره -- محافظتِ
// زنده بینِ دو کندلِ H1، نه فقط منتظرِ کندل بعدی موندن. روی Hedging چند پوزیشن
// جدا داریم که همه باید هم‌زمان SL بخورن؛ روی Netting فقط یکی هست. ***
// *** پیشگیریِ خطای «Invalid stops» به‌جای فقط لاگ‌کردنش بعد از رد شدن: قبل از
// فرستادن/تغییرِ SL، فاصله‌ش از قیمتِ مرجع رو با StopsLevel/FreezeLevel بروکر
// می‌سنجیم و اگه لازم بود، به نزدیک‌ترین فاصلهٔ مجاز می‌چسبونیم. ***
// -------- شمارندهٔ همگام‌سازیِ SL طبقِ درخواستِ صریح --------
double NormalizeToTickSize(double price)
{
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tickSize<=0) return NormalizeDouble(price,_Digits);
   return NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
}

// *** v5.05: علتِ واقعیِ 10016 پیدا شد -- OpenFirstLeg سمتِ *fillِ سفارش* (Ask برای
// خرید) را به‌عنوانِ مرجعِ فاصلهٔ استاپ می‌فرستاد، نه سمتِ *چکِ استاپِ* بروکر (Bid برای
// خرید طبقِ دستورِ صریح). چون Ask همیشه >= Bid، این فاصله را واقعی‌تر از چیزی که
// بروکر می‌بیند نشان می‌داد و گاهی رد می‌شد. الان خودِ این تابع سمتِ درست را از
// تیکِ تازه می‌گیرد -- دیگر به caller وابسته نیست. همچنین نرمال‌سازی حالا به
// اندازهٔ *تیک* است، نه فقط تعدادِ رقمِ اعشار (که برای تیک‌سایزهای غیرِ ۱۰^n کافی نبود). ***
double ClampStopToBrokerLimits(double proposedSL,int direction,double &effRefPrice,double &effDistPts)
{
   MqlTick tick;
   SymbolInfoTick(_Symbol,tick);
   double refPrice=(direction==1)?tick.bid:tick.ask;   // BUY->Bid ، SELL->Ask ، طبقِ دستورِ صریح
   effRefPrice=refPrice;
   double normalizedSL=NormalizeToTickSize(proposedSL);
   int stopLevel=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   int freezeLevel=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   int minPts=MathMax(stopLevel,freezeLevel);
   double dist=(refPrice-normalizedSL)*direction;
   effDistPts=dist/_Point;
   if(minPts<=0) return normalizedSL;
   double minDist=minPts*_Point;
   if(dist<minDist)
   {
      normalizedSL=NormalizeToTickSize(refPrice-direction*minDist);
      effDistPts=minPts;
   }
   return normalizedSL;
}

// *** v5.06: تابعِ لاگِ یکپارچه برای هر ۴ حالتِ SyncBrokerStop، طبقِ دستورِ صریح --
// هر حالت (SUCCESS/DEFERRED/REJECTED/ALREADY_TRIGGERED) این فیلدها رو می‌نویسه:
// Symbol, Direction, Bid, Ask, DesiredSL, NormalizedSL, EffectiveDistance,
// StopsLevel, FreezeLevel, Result, CloseReason. جایگزینِ LogSlFailureِ v5.05 --
// اون فقط حالتِ رد را لاگ می‌کرد و متنش هم اشتباهاً «DEFERRED» می‌گفت. ***
void LogSlSync(string resultStatus,ulong ticket,double desiredSL,double normalizedSL,
               double effDistPts,MqlTick &tick,string closeReason)
{
   Print("SL_SYNC  Symbol=",_Symbol," Direction=",(g_cycleDirection==1?"BUY":"SELL"),
         " Ticket=",ticket,
         " Bid=",DoubleToString(tick.bid,_Digits)," Ask=",DoubleToString(tick.ask,_Digits),
         " DesiredSL=",DoubleToString(desiredSL,_Digits),
         " NormalizedSL=",DoubleToString(normalizedSL,_Digits),
         " EffectiveDistance=",DoubleToString(effDistPts,1),"pts",
         " StopsLevel=",SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL),"pts",
         " FreezeLevel=",SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL),"pts",
         " Result=",resultStatus,
         " CloseReason=",(closeReason==""?"-":closeReason));
}

// *** v5.06 (فیکسِ Test006): اعتبارِ سمتِ بازارِ SLِ خواسته‌شده رو مستقیم با Bid/Ask
// می‌سنجه -- طبقِ دستورِ صریح: BUY باید SL اکیداً زیرِ Bid باشه، SELL باید SL اکیداً
// بالایِ Ask باشه. این چک از چکِ StopsLevel/FreezeLevelِ تویِ ClampStopToBrokerLimits
// کاملاً جداست و همیشه *قبل* از اون اجرا می‌شه: اگه قیمت از سطحِ تریل رد شده باشه (نه
// فقط بهش نزدیک شده باشه)، این دیگه یه سطحِ قابل‌clamp نیست -- استاپ از قبل triggered
// شده، پس نباید به سمتِ دیگه چسبونده و فرستاده بشه (دقیقاً همون علتِ 10016 توی Test006). ***
bool IsSlAlreadyTriggered(double desiredSL,int direction,double bid,double ask)
{
   if(direction==1  && desiredSL>=bid) return true;   // BUY: SL باید اکیداً زیرِ Bid باشه
   if(direction==-1 && desiredSL<=ask) return true;   // SELL: SL باید اکیداً بالایِ Ask باشه
   return false;
}

// *** v5.07: طبقِ دستورِ صریح -- SyncBrokerStop به‌جایِ void، وضعیتِ این فراخوانی رو
// برمی‌گردونه تا OnNewH1Bar بتونه رویِ ALREADY_TRIGGERED رفتارِ متفاوت نشون بده.
// ALREADY_TRIGGERED همیشه یه نتیجهٔ سطحِ کل‌چرخه‌ست (قبل از حلقهٔ per-leg تعیین می‌شه).
// وقتی چند leg نتیجه‌های متفاوت دارن، اولویتِ REJECTED > DEFERRED > OK (بدترین نتیجه
// برنده‌ست) استفاده می‌شه -- چون REJECTED یعنی SL واقعاً sync نشده و نیاز به توجه داره. ***
enum ENUM_SL_SYNC_RESULT { SYNC_OK, SYNC_DEFERRED, SYNC_REJECTED, ALREADY_TRIGGERED };

ENUM_SL_SYNC_RESULT SyncBrokerStop()
{
   if(!g_cycleActive) return SYNC_OK;
   MqlTick tick; if(!SymbolInfoTick(_Symbol,tick)) return SYNC_OK;
   double desiredSL=GoverningStopLevel();

   // *** v5.06: اگه از قبل triggered شده، هیچ clamp/PositionModify‌ای در کار نیست --
   // SL محافظِ فعلی دست‌نخورده می‌مونه (نقدِ #۵) و مسیرِ verified بستنِ چرخه (عینِ
   // چیزی که OnNewH1Bar برای stopHit صدا می‌زنه) صدا زده می‌شه. طبقِ نقدِ صریح #۷:
   // این یه شکستِ اجرا شمرده نمی‌شه، یه خروجِ عادیه -- پس close-reasonش هم دقیقاً
   // مثلِ یه STOP_S0/TRAIL_EXIT معمولی (n_adds==0 یعنی هنوز استاپِ اولیه، وگرنه تریله)،
   // نه یه رویدادِ «_BROKER» جدا (چون خودِ EA داره close رو درخواست می‌ده، نه اینکه
   // بعداً کشف کنه بروکر مستقل بسته -- اون حالت مالِ OnTradeTransaction هست). ***
   if(IsSlAlreadyTriggered(desiredSL,g_cycleDirection,tick.bid,tick.ask))
   {
      g_slSync.alreadyTriggered++;
      string reason=(g_cycleNAdds==0?"STOP_S0":"TRAIL_EXIT");
      double crossedDistPts=(g_cycleDirection==1)?((tick.bid-desiredSL)/_Point):((desiredSL-tick.ask)/_Point);
      LogSlSync("SL_ALREADY_TRIGGERED",0,desiredSL,NormalizeToTickSize(desiredSL),crossedDistPts,tick,reason);
      CloseAllCycleLegs(reason);
      return ALREADY_TRIGGERED;
   }

   double effRef=0,effDist=0;
   double stopPrice=ClampStopToBrokerLimits(desiredSL,g_cycleDirection,effRef,effDist);
   int freezeLevel=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   bool anyRejected=false,anyDeferred=false;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong tk=PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol || PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;
      double curSL=PositionGetDouble(POSITION_SL);
      if(MathAbs(curSL-stopPrice)<=_Point) continue;   // از قبل هماهنگه، کاری لازم نیست

      // *** DEFERRED: اگه SLِ فعلی همین الان داخلِ ناحیهٔ freeze باشه، تلاشِ modify
      // قطعاً رد می‌شه -- به‌جای هدردادنِ یه تلاشِ محکوم‌به‌شکست، همین‌جا صریحاً
      // به‌تعویق می‌ندازیم و کندلِ بعد دوباره چک می‌کنیم. SL قبلی دست‌نخورده می‌مونه. ***
      if(freezeLevel>0 && curSL!=0)
      {
         double curDistPts=MathAbs((effRef-curSL))/_Point;
         if(curDistPts<freezeLevel)
         {
            g_slSync.deferred++;
            anyDeferred=true;
            if(InpVerboseLog)
            {
               LogSlSync("SL_SYNC_DEFERRED",tk,desiredSL,stopPrice,effDist,tick,"-");
               Print("   -> CurrentSL is inside FreezeLevel zone (",DoubleToString(curDistPts,1),
                     "pts < ",freezeLevel,"pts), retry next bar.");
            }
            continue;
         }
      }

      if(!trade.PositionModify(tk,stopPrice,PositionGetDouble(POSITION_TP)))
      {
         // *** هرگز به این معنی گرفته نمی‌شه که «هماهنگ شد» -- SL قبلی (که موقعِ
         // بازکردن/Add فرستاده شده بود) دست‌نخورده رو پوزیشن می‌مونه، فقط کندلِ بعد
         // دوباره تلاش می‌کنیم (SyncBrokerStop هرکندل صدا زده می‌شه). ***
         g_slSync.rejected++;
         anyRejected=true;
         LogSlSync("SL_SYNC_REJECTED",tk,desiredSL,stopPrice,effDist,tick,"-");
         Print("   -> Retcode=",trade.ResultRetcode()," (",trade.ResultRetcodeDescription(),")",
               "  protective SL NOT removed, retry next tick/bar.");
      }
      else
      {
         g_slSync.success++;
         if(InpVerboseLog) LogSlSync("SL_SYNC_SUCCESS",tk,desiredSL,stopPrice,effDist,tick,"-");
      }
   }
   if(anyRejected) return SYNC_REJECTED;
   if(anyDeferred) return SYNC_DEFERRED;
   return SYNC_OK;
}

//------------------------------------------------------ فاز۳: تشخیص فلیپِ معتبر (۲کندل پیاپی، اجماع>=۴)
bool RegimeFlippedValid()
{
   if(!g_cycleActive) return false;
   bool opp=(g_regimeMain==-g_cycleDirection) && (MathMax(g_voteUp,g_voteDown)>=InpFlipMinConsensus);
   g_flipStreak=opp?(g_flipStreak+1):0;
   return g_flipStreak>=InpFlipConfirmBars;
}

//====================================================================
//  حلقهٔ اصلیِ منطق چرخه -- یک‌بار به‌ازای هر کندل H1 تازه (بخش ۵.۶: تصمیم بعد از close، اجرا اول کندل بعد)
//====================================================================
void OnNewH1Bar()
{
   bool killSwitch=GlobalKillSwitchActive();   // *** دیگه اینجا return نمی‌کنیم -- طبق نقد AI2 #2 ***

   double atrBlend=AtrBlendH1();
   double spread=LiveSpread();
   if(spread<=0) return;   // *** نقد #11: اسپرد نامعتبر/صفر -- هیچ تصمیمی نگیر ***

   if(g_cycleActive)
   {
      UpdateTrail(atrBlend,spread);
      if(!g_cycleIsPaper)   // *** نقد #10 -- فقط چرخهٔ واقعی SL بروکر داره ***
      {
         // *** v5.07 طبقِ دستورِ صریح: اگه SyncBrokerStop تشخیص بده SLِ تریل از قبل
         // توسطِ قیمت رد شده، خودش CloseAllCycleLegs رو با reasonِ درست صدا زده --
         // این کندل دیگه کاری نمونده. اگه اینجا برنگردیم، چکِ stopHitِ زیر (که رویِ
         // کندلِ بسته‌شده حساب می‌کنه، نه تیکِ زنده) و حتی اولویت‌هایِ ۲/۳ (فلیپ،
         // AP/Add) هم می‌تونستن رویِ همین کندل روی چرخه‌ای که تازه داره می‌بنده اجرا
         // بشن -- توی حالتِ AP یعنی Add-کردنِ یه leg تازه به چرخه‌ای که مدام بستنه. ***
         ENUM_SL_SYNC_RESULT syncResult=SyncBrokerStop();
         if(syncResult==ALREADY_TRIGGERED) return;
      }
      double stop=GoverningStopLevel();
      bool stopHit=(g_cycleDirection==1)?(iLow(_Symbol,PERIOD_H1,1)<=stop):(iHigh(_Symbol,PERIOD_H1,1)>=stop);

      // اولویت ۱: استاپ/تریل -- حتی زیر Kill Switch هم این باید کار کنه (مدیریتِ باز، نه ورودِ تازه)
      // *** v5.07: !g_cycleClosing هم گارد شد -- طبقِ دستورِ صریح، محافظِ دومِ مستقل
      // برایِ درخواستِ closeِ تکراری (جدا از چکِ بالا رویِ ALREADY_TRIGGERED). ***
      if(stopHit && !g_cycleClosing)
      {
         if(g_cycleIsPaper) ClosePaperCycle(g_cycleNAdds==0?"STOP_S0_PAPER":"TRAIL_EXIT_PAPER",stop);
         else CloseAllCycleLegs(g_cycleNAdds==0?"STOP_S0":"TRAIL_EXIT");
         return;
      }

      // اولویت ۲: فلیپ معتبر AND در سود -> بستن فوری
      if(RegimeFlippedValid())
      {
         double lastClose=iClose(_Symbol,PERIOD_H1,1);
         int n=g_cycleNAdds;
         double pnlNow = g_cycleIsPaper
            ? (g_cycleDirection*(n+1)*(lastClose-g_cycleEntryPrice) - g_cycleK*n*(n+1)/2.0)
            : CycleFloatingProfit();
         if(pnlNow>0)
         {
            if(g_cycleIsPaper) ClosePaperCycle("FLIP_PROFIT_PAPER",lastClose);
            else CloseAllCycleLegs("FLIP_PROFIT");
            return;
         }
      }

      // اولویت ۳: AP -- «ریسکِ جدید»ه، پس فقط چرخهٔ *واقعی* با Kill Switch/مارجین بلاک می‌شه؛
      // چرخهٔ کاغذی هیچ سرمایه‌ای درگیر نمی‌کنه، فقط داره تاریخچه می‌سازه -- بلاک لازم نداره.
      if(!g_cycleIsPaper && killSwitch) return;
      if(g_cycleNAdds<InpMaxAdds)
      {
         double apLevel=g_cycleLastLegPrice+g_cycleDirection*g_cycleK;
         bool apHit=(g_cycleDirection==1)?(iHigh(_Symbol,PERIOD_H1,1)>=apLevel):(iLow(_Symbol,PERIOD_H1,1)<=apLevel);
         if(apHit)
         {
            if(!g_cycleIsPaper && !HasEnoughFreeMargin(g_cycleVBase,g_cycleDirection))
            { if(InpVerboseLog) Print("ADD رد شد: مارجین آزاد کافی نیست"); return; }
            AddLeg(g_cycleDirection,g_cycleVBase,apLevel,g_cycleIsPaper);
         }
      }
      return;
   }

   // چرخه‌ای باز نیست -> گیت‌های فاز صفر
   TickCooldowns();   // *** همین‌جا -- دقیقاً همون خطی که قبلاً جا افتاده بود ***
   int proposedDir=(g_regimeMain!=0)?g_regimeMain:0;
   if(proposedDir==0){ g_gs.noRegime++; PrintGateStatsIfDue(); return; }
   double consensusVotes=(double)MathMax(g_voteUp,g_voteDown);
   if(consensusVotes<InpMinConsensus){ g_gs.consensus++; PrintGateStatsIfDue(); return; }
   if(!GateRangeFilter(g_erH4,(double)FlipCount20(),consensusVotes)){ g_gs.range++; PrintGateStatsIfDue(); return; }
   if(!GateEntryConfirm(g_erSlope5)){ g_gs.erSlope++; PrintGateStatsIfDue(); return; }

   double k;
   if(!ComputeK(atrBlend,spread,k)){ g_gs.computeK++; PrintGateStatsIfDue(); return; }
   double s0=ComputeS0(k,atrBlend,spread);

   // *** طبقِ طراحیِ جدید: اول معلوم می‌شه این ورود کاغذیه یا واقعی، بعد کول‌داونِ
   // *همون مسیر* چک می‌شه -- چون حالا کول‌داونِ کاغذی/واقعی جدان. ***
   bool hot=IsSymbolHot();
   if(!GateCooldown(proposedDir,hot)){ g_gs.cooldown++; PrintGateStatsIfDue(); return; }

   if(!hot)
   {
      // *** رفعِ بن‌بستِ گیت ۵.۹: به‌جای فقط رد کردن، کاغذی شبیه‌سازی کن. بدون این،
      // چون تاریخچه از صفر شروع می‌شه و رد-کردن هیچی ثبت نمی‌کنه، گیت هرگز به ۴۰
      // چرخه نمی‌رسه و برای همیشه رد می‌مونه. ***
      g_gs.symbolCold++; PrintGateStatsIfDue();
      OpenFirstLeg(proposedDir,k,s0,0.0,0.0,true);
      return;
   }

   if(killSwitch){ g_gs.killSwitch++; PrintGateStatsIfDue(); return; }   // فقط ورودِ واقعیِ تازه بلاک می‌شه

   double riskBudgetUSD=0;
   double lot=ComputeLotSize(s0,riskBudgetUSD);
   if(lot<=0.0){ g_gs.minLot++; PrintGateStatsIfDue(); return; }   // ریسک لات حداقلی از بودجه/سقف بیشتره
   if(!HasEnoughFreeMargin(lot,proposedDir)){ if(InpVerboseLog) Print("ورود رد شد: مارجین آزاد کافی نیست"); return; }

   OpenFirstLeg(proposedDir,k,s0,lot,riskBudgetUSD,false);
}

//====================================================================
//  رویدادهای EA
//====================================================================
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpDeviation);

   if((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
   {
      Print("توجه: حساب Netting شناسایی شد. برخلاف v4 (که هج هم‌زمانِ دوجهته داشت و روی Netting واقعاً "
           +"می‌شکست)، v5 هیچ هجی نداره -- همهٔ پاها هم‌جهتن، و entry هر پا رو خودِ EA (نه از پوزیشن) "
           +"نگه می‌داره، پس منطقاً باید کار کنه: بروکر پاها رو با میانگین وزنی ادغام می‌کنه ولی P&L "
           +"تجمعی و بستنِ یک‌جا هنوز درسته. این تحلیله، نه تست‌شده -- حتماً با Strategy Tester با هردو "
           +"نوع حساب که در دسترسته مقایسه کن قبل از اعتماد. Hedging همچنان توصیه می‌شه.");
   }

   hADX        = iADX(_Symbol, InpRegimeTF, InpADX_Period);
   hATR_ST     = iATR(_Symbol, InpRegimeTF, InpST_ATRPeriod);
   hATR_STFast = iATR(_Symbol, InpRegimeTF, InpST_FastATRPeriod);
   hATR_Fast_H1= iATR(_Symbol, PERIOD_H1, InpATR_FastPeriod);
   hATR_Slow_H1= iATR(_Symbol, PERIOD_H1, InpATR_SlowPeriod);
   if(hADX==INVALID_HANDLE||hATR_ST==INVALID_HANDLE||hATR_STFast==INVALID_HANDLE
      ||hATR_Fast_H1==INVALID_HANDLE||hATR_Slow_H1==INVALID_HANDLE)
   { Print("خطا در ساخت هندل اندیکاتورها"); return(INIT_FAILED); }

   InitRunId();
   InitAccountUnitScale();
   ArrayInitialize(g_regimeHistory,0);
   LoadCycleHistory();

   // *** بخشِ تشخیصیِ v5.04 -- ستون‌به‌ستون طبقِ مشخصاتِ صریح، هیچ حدسی دربارهٔ واحدِ
   // پول زده نمی‌شه، فقط خام و اقتصادی جدا گزارش می‌شن. ***
   Print("=== RunID=",g_runId," | Version=5.07 | Symbol=",_Symbol," | TF=",TFString(PERIOD_H1)," ===");
   Print("ACCOUNT_CURRENCY=",AccountInfoString(ACCOUNT_CURRENCY),
         "  RawBalance=",DoubleToString(RawBalance(),2),"  RawEquity=",DoubleToString(RawEquity(),2),
         "  AccountUnitScale=",DoubleToString(g_accountUnitScale,4),
         "  EconomicBalanceUSD=",DoubleToString(EconomicBalanceUSD(),2),
         "  ACCOUNT_LEVERAGE=1:",AccountInfoInteger(ACCOUNT_LEVERAGE));

   // *** Self-test طبقِ مشخصات: ۰٫۰۱ لات، فاصلهٔ S0ِ مرجع، از همون مسیرِ واقعیِ
   // OrderCalcProfit -- تا قبل از هر تصمیمی، خودِ عددها روی لاگ باشن. ***
   {
      double atrBlend0=AtrBlendH1(), spread0=LiveSpread(), refK0=0;
      double vpp0=ValuePerPriceMovePerLot();
      double tickVal=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
      double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      Print("SELF-TEST ",_Symbol,": TickValue=",DoubleToString(tickVal,6),
            "  TickSize=",DoubleToString(tickSize,6),
            "  TickValue/TickSize(قدیمی، ناسازگار با ارزهای متقاطع)=",
            DoubleToString(tickSize>0?tickVal/tickSize:0,2),
            "  ValuePerPriceMovePerLot(OrderCalcProfit، فعلی)=",DoubleToString(vpp0,2));
      if(spread0>0 && ComputeK(atrBlend0,spread0,refK0))
      {
         double refS0_0=ComputeS0(refK0,atrBlend0,spread0);
         double minLot0=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
         double riskRaw0=minLot0*refS0_0*vpp0;
         Print("SELF-TEST ",_Symbol,": K=",DoubleToString(refK0,_Digits)," S0=",DoubleToString(refS0_0,_Digits),
               " MinLot=",minLot0," -> ریسکِ خام=",DoubleToString(riskRaw0,4),
               " -> ریسکِ اقتصادیِ USD=",DoubleToString(riskRaw0/g_accountUnitScale,4));
      }
      else Print("SELF-TEST ",_Symbol,": هنوز داده کافی برای K/S0 در دسترس نیست (طبیعیه، اولِ اجراست).");
      Print("SYMBOL_TRADE_STOPS_LEVEL=",SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL),
            " points  SYMBOL_TRADE_FREEZE_LEVEL=",SymbolInfoInteger(_Symbol,SYMBOL_TRADE_FREEZE_LEVEL)," points");
   }
   if(g_centCurrencySuggested && !InpUseAccountUnitScale)
      Print(">>> یادآوری: تشخیصِ Cent پیشنهاد شده بود ولی InpUseAccountUnitScale=false مونده -- "
           +"یعنی الان همه‌چی با scale=۱ (بدونِ تبدیل) حساب می‌شه. اگه فکر می‌کنی حساب واقعاً Centه، "
           +"صریحاً InpUseAccountUnitScale=true کن. <<<");

   // *** درخواستِ صریح کاربر: تشخیصِ کفایتِ دیتاست، به‌جای حدس‌زدن با چارت باز‌کردنِ دستی.
   // TFD به ۶۰ کندلِ H4 نیاز داره، Struct به ۱۲ روزِ D1. اگه اینجا عدد کمه، مشکل واقعاً دیتاست‌ه؛
   // اگه کافیه (که طبق لاگت بود)، مشکل جای دیگه‌ست -- دقیقاً چیزی که همین الان پیدا شد. ***
   int barsH4=Bars(_Symbol,InpRegimeTF), barsD1=Bars(_Symbol,PERIOD_D1), barsH1=Bars(_Symbol,PERIOD_H1);
   Print("=== چکِ کفایتِ دیتاست ===  H4 bars=",barsH4," (نیاز>=",InpTFD_ScanBars,")   D1 bars=",barsD1,
         " (نیاز>=",InpStruct_LookbackDays+2,")   H1 bars=",barsH1," (نیاز>=",MathMax(InpATR_SlowPeriod,50)+5,")");
   if(barsH4<InpTFD_ScanBars || barsD1<InpStruct_LookbackDays+2 || barsH1<InpATR_SlowPeriod+5)
      Print("!!! دیتاست ناکافیه -- توی Strategy Tester تاریخ شروع رو عقب‌تر ببر یا از منوی Symbols دیتای بیشتری دانلود کن.");

   if(InpVerboseLog) Print("AFA v5 EA initialized on ",_Symbol,". Hedging=",
        ((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING));

   // *** الزامِ صریح: حتی اگه هیچ معامله‌ای پیش نیاد، فایلِ تشخیصی باید از همون
   // اولِ اجرا نوشته بشه -- نه فقط بعدِ ۱۰۰ کندلِ اول. ***
   if(InpWriteDiagnosticsWhenNoTrade) WriteGateDiagnosticsRow();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { Comment(""); }

void OnTick()
{
   // *** نقد #۳: کیل‌سوئیچ رو هر تیک هم چک کن (سبکه: چند AccountInfoDouble + GlobalVariable) --
   // اینطوری اگه اکوییتی وسطِ یک کندلِ H1 سقوط کنه، پرچم زودتر ست می‌شه؛ مدیریتِ پوزیشنِ باز هم
   // (طبق فیکسِ نقد #۲) صرف‌نظر از این پرچم هرکندل ادامه داره. ***
   GlobalKillSwitchActive();

   // موتور رژیم: خودش چک می‌کند کندل InpRegimeTF/D1 تازه بسته شده یا نه
   UpdateRegimeEngineIfNewBar();

   // منطق چرخه: دقیقاً یک‌بار به‌ازای هر کندل H1 تازه (بخش ۵.۶)
   datetime curH1=iTime(_Symbol,PERIOD_H1,0);
   if(curH1==g_lastH1Bar) return;
   g_lastH1Bar=curH1;
   OnNewH1Bar();
}
//+------------------------------------------------------------------+
