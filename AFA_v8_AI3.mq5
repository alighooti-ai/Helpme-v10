//+------------------------------------------------------------------+
//|                                                      AFA_v8.mq5  |
//|         Ali's Fractal Anti-Drawdown Algorithm — V8               |
//|                                                                  |
//| این نسخه قلب V7 (کالمن + CUSUM) را دست‌نخورده نگه می‌دارد —          |
//| همان چیزی که با بک‌تست واقعی MT5 تأیید شد (PF=1.84، ورود دقیقاً     |
//| سر انتقال‌های واقعی). آنچه اضافه شده، دقیقاً همان چیزی است که        |
//| خواستی: چند «کشویی» برای این‌که خودت با بک‌تست واقعی مقایسه کنی،     |
//| نه این‌که من یکی را حدس بزنم و قبول کنی.                            |
//|                                                                  |
//| === یافته‌های این دور که این نسخه را شکل داد ===                    |
//| ۱) حساب واقعی ۴۰ دلار (۴۰۰۰ سنت) است — نسخهٔ قبلی گزارش من به        |
//|    اشتباه «۴۰۰۰ دلار» گفت؛ درصدها درست بودند ولی مقیاس مطلق نه.     |
//| ۲) اسکیل کردن حجم خطی نبود: ۰.۰۱→۰.۶ (۶۰×) دراودان ۶۰٪ داد،         |
//|    نه رقم خطی‌ای که پیش‌بینی می‌شد؛ ۰.۹ کال مارجین شد. علتش را        |
//|    زیر توضیح دادم (پای هج).                                       |
//| ۳) پای هج در هر ۴ بک‌تست واقعی خالص منفی بود (-1.80 تا -11.87 —      |
//|    نه یک بار مثبت خالص). این احتمالاً بخشی از دلیل غیرخطی‌بودن       |
//|    دراودان در حجم بالاست: پای هج وقتی می‌بازد که حرکت مخالف روند     |
//|    ادامه پیدا کند — دقیقاً همان لحظه‌ای که پای روند هم دارد ضرر       |
//|    می‌دهد. یعنی هم‌بسته (correlated) با بدترین حالت است، نه          |
//|    مستقل ازش.                                                     |
//| ۴) تعداد معامله (۱۰-۱۷ در ۷ ماه) به‌قدری کم است که خودِ نتیجه —       |
//|    مثبت یا منفی — از نظر آماری قابل اعتماد نیست. این یعنی به‌جای      |
//|    این‌که من یک تنظیم را «برنده» اعلام کنم، باید امکان مقایسهٔ         |
//|    چندتایی رو بهت بدم.                                            |
//|                                                                  |
//| === دو تا AI (Gemini Pro/Flash) که فرستادی — نقد صادقانه ===        |
//| این دو گزارش دارند یک EA کاملاً متفاوت را توصیف می‌کنند —            |
//| «Grid_Step_Pips»، «Target_Net_Profit_USD»، «A-Level/F-Level»،      |
//| مارتینگل حجم افزایشی روی پای هج (۰.۰۱←۰.۰۲←۰.۰۳...) — هیچ‌کدام       |
//| این‌ها در AFA v7 وجود ندارند (نه کالمن، نه CUSUM، نه                 |
//| MaxAdverseExcursion را حتی نام بردند). این‌ها به‌جای خواندن دقیق       |
//| کد، دارند یک EA گرید کلاسیک عمومی را توصیف می‌کنند — همانی که         |
//| مدل‌های زبانی زیاد در داده‌ی آموزشی‌شان دیده‌اند. حدس درست تو            |
//| («ناپخته») بود. یک پیشنهادشان (مارتینگل روی حجم هج) مستقیم با         |
//| اصل ۲ مانیفست خودت («حجم پای هج ثابت و کوچک — بدون مارتینگل»)         |
//| در تضاد است — رد شد. آنچه از این دو گزارش واقعاً قابل استفاده بود      |
//| (نه اسمش، ایده‌اش): «هج چندلایه» و «فاصلهٔ هج بر مبنای ATR» — هر دو    |
//| قبلاً بخشی از طراحی V6/V7 بودند (InpHedgeOpenATRMult) یا دقیقاً        |
//| همان چیزی‌اند که این نسخه به‌عنوان HEDGE_MULTI اضافه می‌کند.           |
//|                                                                  |
//| === سه تغییر جدید در این نسخه ===                                 |
//| ۱) InpStrictness (کشویی): سه پیش‌تنظیم برای سخت‌گیریِ CUSUM/نگه‌داری،  |
//|    از پایتون تست شدند (نه حدس) — پایین دقیق‌شان آمده. یا CUSTOM       |
//|    برای کنترل دستی با همان ورودی‌های V7.                            |
//| ۲) InpHedgeMode (کشویی): OFF / SINGLE (رفتار V7) / MULTI (فیچر       |
//|    جدید — تا InpMaxHedgeLayers لایه هم‌زمان، هرکدام حجم ثابت کوچک،    |
//|    قانون طلایی دست‌نخورده). MULTI هنوز اعتبارسنجی نشده — دقیقاً        |
//|    همان چیزی که باید تو با بک‌تست واقعی محک بزنی.                    |
//|    ** توصیهٔ من برای اولین تست: قبل از هرچی، فقط HEDGE_OFF را        |
//|    روی حجم بالا (مثلاً ۰.۳) امتحان کن — ارزان‌ترین راه برای دیدن       |
//|    اینکه آیا حذف پای هج (که خالص منفی بوده) به‌تنهایی دراودان         |
//|    غیرخطی را حل می‌کند، قبل از این‌که با MULTI پیچیده‌ترش کنیم. **     |
//| ۳) همهٔ ورودی‌های جدید input هستند، پس در تب Optimization خود         |
//|    Strategy Tester هم قابل استفاده‌اند — MT5 خودش می‌تواند صدها        |
//|    ترکیب را برایت اجرا و مرتب کند؛ احتمالاً از تست دستی یکی‌یکی        |
//|    سریع‌تر است.                                                    |
//+------------------------------------------------------------------+
#property copyright "Ali"
#property version   "8.00"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

#define MAX_HEDGE_LAYERS 10

enum ENUM_Strictness
{
   STRICT_CONSERVATIVE,  // h=7.0 k=0.7 hold=48 cool=48 -> پایتون: 10 معامله/7ماه، +0.1047 پیپ، لگ همه<0.5روز (این پیش‌فرض V7 بود)
   MEDIUM_BALANCED,      // h=6.0 k=0.6 hold=36 cool=36 -> پایتون: 19 معامله، -0.0304 پیپ (بدتر از STRICT در این تست — صادقانه گزارش می‌کنم)
   LOOSE_ACTIVE,         // h=5.0 k=0.5 hold=24 cool=24 -> پایتون: 32 معامله، +0.0152 پیپ، ولی یک انتقال ۱۲روز دیر رسید (نه یکنواخت بهتر)
   CUSTOM_MANUAL         // از InpCUSUM_Slack/Threshold/InpMinHoldBars/InpReversalCooldownBars خودت استفاده کن
};

enum ENUM_HedgeMode
{
   HEDGE_OFF,      // بدون پای هج — فقط پای روند + MaxAdverse (ارزان‌ترین تست برای ایزوله‌کردن اثر هج)
   HEDGE_SINGLE,   // رفتار V7 — یک لایه، بستن با Retrace/TrendResumed/Spike
   HEDGE_MULTI     // فیچر جدید، تست‌نشده — تا InpMaxHedgeLayers لایه هم‌زمان با فاصلهٔ ATR، همه با هم بسته می‌شوند
};

//================== INPUTS ==================
input group "=== General ==="
input ENUM_HedgeMode InpHedgeMode        = HEDGE_SINGLE;
input int    InpMagicTrend             = 780001;
input int    InpMagicHedge             = 780002;
input string InpCSVFileName            = "AFA_Log_v8.csv";

input group "=== Volumes ==="
input double InpTrendLegVolume         = 0.01;
input double InpHedgeLegVolume         = 0.01;

input group "=== Kalman Trend Engine (بدون تغییر از V7 — تأییدشده) ==="
input double InpKalman_R               = 0.000000575;
input double InpKalman_QLevelRatio     = 0.174;
input double InpKalman_QTrendRatio     = 0.0017;

input group "=== سخت‌گیری CUSUM/Reversal (کشویی V8) ==="
input ENUM_Strictness InpStrictness    = STRICT_CONSERVATIVE;
input double InpCUSUM_Slack            = 0.7;   // فقط وقتی InpStrictness=CUSTOM_MANUAL
input double InpCUSUM_Threshold        = 7.0;   // فقط وقتی InpStrictness=CUSTOM_MANUAL
input int    InpMinHoldBars            = 48;    // فقط وقتی InpStrictness=CUSTOM_MANUAL
input int    InpReversalCooldownBars   = 48;    // فقط وقتی InpStrictness=CUSTOM_MANUAL
input double InpCUSUM_BoostFactor      = 6.0;
input int    InpCUSUM_BoostBars        = 6;
input double InpTrendConfirmZ          = 1.0;

input group "=== Hedge Leg - Open ==="
input double InpHedgeOpenATRMult       = 1.0;
input int    InpMaxHedgeLayers         = 3;     // فقط وقتی InpHedgeMode=HEDGE_MULTI
input double InpHurstThreshold         = 0.50;
input int    InpHurstBars              = 100;

input group "=== Hedge Leg - Close (fallback) ==="
input double InpHedgeCloseRetraceP     = 0.5;
input double InpSpikeATRRatio          = 2.5;

input group "=== Net-Close (روی مجموع پای روند + همهٔ لایه‌های هج باز) ==="
input bool   InpEnableNetClose         = false;
input double InpNetCloseTargetProfit   = 0.02;

input group "=== Trailing Stop روی پای روند (جانبی — ثابت شد بدتر می‌کند، پیش‌فرض خاموش) ==="
input bool   InpEnableTrailingStop     = false;
input double InpTrailingMinProfitATR   = 1.5;
input double InpTrailingATRMult        = 2.0;

input group "=== Max Adverse Excursion (ثابت شد لازم است — ریسک دم را کنترل می‌کند) ==="
input bool   InpEnableMaxAdverse       = true;
input double InpMaxAdverseATR          = 6.0;

input group "=== Risk Gate ==="
input double InpMaxSpikeRatioBlock     = 3.0;

input group "=== ADX(D1) — فقط لاگ ==="
input int    InpADXPeriod              = 14;

//================== GLOBALS ==================
int      hATR_H1, hADX_D1;
datetime g_lastBarTime         = 0;
int      g_trendDir            = 0;
ulong    g_trendTicket         = 0;
double   g_trendOpenPrice      = 0.0;
double   g_trendPeakPrice      = 0.0;
int      g_holdBarCount        = 0;
int      g_cooldownCounter     = 0;
int      g_csvHandle           = INVALID_HANDLE;
bool     g_eventThisBar        = false;

// --- Hedge (چندلایه، V8) ---
ulong    g_hedgeTickets[MAX_HEDGE_LAYERS];
double   g_hedgeEntryPrices[MAX_HEDGE_LAYERS];
int      g_hedgeLayerCount       = 0;
double   g_hedgeAdverseExtreme   = 0.0;
double   g_lastHedgeCycleClosePrice = 0.0;

// --- Kalman + CUSUM ---
bool     g_kInit          = false;
double   g_kLevel         = 0.0;
double   g_kTrend         = 0.0;
double   g_kP00=1e-4, g_kP01=0.0, g_kP10=0.0, g_kP11=1e-6;
double   g_kZ             = 0.0;
double   g_cusumPos       = 0.0;
double   g_cusumNeg       = 0.0;
int      g_boostBarsLeft  = 0;
int      g_lastChangepoint= 0;

// --- سخت‌گیریِ فعال (از روی InpStrictness پر می‌شود؛ فقط این‌ها در منطق استفاده می‌شوند) ---
double   g_activeSlack, g_activeThreshold;
int      g_activeMinHold, g_activeCooldownBars;

//+------------------------------------------------------------------+
void ApplyStrictnessPreset()
{
   switch(InpStrictness)
   {
      case STRICT_CONSERVATIVE: g_activeSlack=0.7; g_activeThreshold=7.0; g_activeMinHold=48; g_activeCooldownBars=48; break;
      case MEDIUM_BALANCED:     g_activeSlack=0.6; g_activeThreshold=6.0; g_activeMinHold=36; g_activeCooldownBars=36; break;
      case LOOSE_ACTIVE:        g_activeSlack=0.5; g_activeThreshold=5.0; g_activeMinHold=24; g_activeCooldownBars=24; break;
      case CUSTOM_MANUAL:
      default:
         g_activeSlack=InpCUSUM_Slack; g_activeThreshold=InpCUSUM_Threshold;
         g_activeMinHold=InpMinHoldBars; g_activeCooldownBars=InpReversalCooldownBars;
         break;
   }
}

int OnInit()
{
   hATR_H1  = iATR(_Symbol, PERIOD_H1,  14);
   hADX_D1  = iADX(_Symbol, PERIOD_D1, InpADXPeriod);
   if(hATR_H1==INVALID_HANDLE || hADX_D1==INVALID_HANDLE)
   { Print("AFA V8: handle error"); return(INIT_FAILED); }

   ApplyStrictnessPreset();
   ArrayInitialize(g_hedgeTickets,0);
   ArrayInitialize(g_hedgeEntryPrices,0.0);

   g_csvHandle = FileOpen(InpCSVFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(g_csvHandle != INVALID_HANDLE)
      FileWrite(g_csvHandle,
                "Time","TrendDir","Kalman_Trend","Kalman_Z","CUSUM_Pos","CUSUM_Neg","Changepoint",
                "Hurst","ATR_H1","SpikeRatio","ADX_D1","HoldBars","CooldownLeft",
                "TrendTicket","HedgeLayers","Event","PnL_USD","Balance","Equity");

   trade.SetExpertMagicNumber(InpMagicTrend);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{ if(g_csvHandle!=INVALID_HANDLE) FileClose(g_csvHandle); }

//====== Hurst — بدون تغییر از V6/V7 ======
double CalcHurstH1(int bars)
{
   if(bars<40) return 0.5;
   double prices[];
   ArraySetAsSeries(prices,false);
   if(CopyClose(_Symbol,PERIOD_H1,1,bars+1,prices)<bars+1) return 0.5;
   double ret[]; ArrayResize(ret,bars);
   for(int i=0;i<bars;i++){
      if(prices[i]<=0||prices[i+1]<=0) return 0.5;
      ret[i]=MathLog(prices[i+1])-MathLog(prices[i]);
   }
   int lags[4]={5,10,20,40};
   double logRS[4],logL[4]; int vp=0;
   for(int li=0;li<4;li++){
      int lag=lags[li],nw=bars/lag;
      if(nw<2) continue;
      double sRS=0; int cRS=0;
      for(int wi=0;wi<nw;wi++){
         int b=wi*lag; double mn=0;
         for(int i=0;i<lag;i++) mn+=ret[b+i]; mn/=lag;
         double cum=0,mx=0,mi=0;
         for(int i=0;i<lag;i++){
            cum+=(ret[b+i]-mn);
            if(i==0){mx=cum;mi=cum;}
            else{if(cum>mx)mx=cum;if(cum<mi)mi=cum;}
         }
         double rng=mx-mi,sd=0;
         for(int i=0;i<lag;i++) sd+=MathPow(ret[b+i]-mn,2);
         sd=MathSqrt(sd/lag);
         if(sd>0&&rng>0){sRS+=rng/sd;cRS++;}
      }
      if(cRS==0) continue;
      logRS[vp]=MathLog(sRS/cRS); logL[vp]=MathLog((double)lag); vp++;
   }
   if(vp<2) return 0.5;
   double sx=0,sy=0,sxy=0,sx2=0;
   for(int i=0;i<vp;i++){sx+=logL[i];sy+=logRS[i];sxy+=logL[i]*logRS[i];sx2+=logL[i]*logL[i];}
   double n=vp,dn=(n*sx2-sx*sx);
   if(dn==0) return 0.5;
   double H=(n*sxy-sx*sy)/dn;
   return MathMax(0.0,MathMin(1.0,H));
}

double CalcSpikeRatioH1()
{
   double atr[1];
   if(CopyBuffer(hATR_H1,0,1,1,atr)!=1||atr[0]<=0) return 1.0;
   return (iHigh(_Symbol,PERIOD_H1,1)-iLow(_Symbol,PERIOD_H1,1))/atr[0];
}
double GetATR_H1(){ double a[1]; return (CopyBuffer(hATR_H1,0,1,1,a)==1)?a[0]:0.0; }
double GetADX_D1(){ double a[1]; return (CopyBuffer(hADX_D1,0,1,1,a)==1)?a[0]:0.0; }

//====== قلب V7/V8 — بدون تغییر ======
double KalmanConfidence(){ return (g_kP11>0) ? MathAbs(g_kTrend)/MathSqrt(g_kP11) : 0.0; }

void UpdateKalmanCUSUM()
{
   double price = MathLog(iClose(_Symbol,PERIOD_H1,1));
   g_lastChangepoint = 0;
   if(!g_kInit) { g_kLevel=price; g_kInit=true; g_kZ=0.0; return; }

   double boost = (g_boostBarsLeft>0) ? InpCUSUM_BoostFactor : 1.0;
   if(g_boostBarsLeft>0) g_boostBarsLeft--;
   double qL = InpKalman_QLevelRatio * InpKalman_R * boost;
   double qT = InpKalman_QTrendRatio * InpKalman_R * boost;

   double levelPred = g_kLevel + g_kTrend;
   double trendPred = g_kTrend;
   double P00p = g_kP00+g_kP01+g_kP10+g_kP11+qL;
   double P01p = g_kP01+g_kP11;
   double P10p = g_kP10+g_kP11;
   double P11p = g_kP11+qT;

   double y = price - levelPred;
   double S = P00p + InpKalman_R;
   double K0 = P00p/S, K1 = P10p/S;

   g_kLevel = levelPred + K0*y;
   g_kTrend = trendPred + K1*y;
   g_kP00 = (1-K0)*P00p;
   g_kP01 = (1-K0)*P01p;
   g_kP10 = P10p - K1*P00p;
   g_kP11 = P11p - K1*P01p;

   g_kZ = y/MathSqrt(S);

   // --- CUSUM با سخت‌گیریِ فعال (از کشوی InpStrictness) ---
   g_cusumPos = MathMax(0.0, g_cusumPos + g_kZ - g_activeSlack);
   g_cusumNeg = MathMin(0.0, g_cusumNeg + g_kZ + g_activeSlack);

   if(g_cusumPos > g_activeThreshold)
   { g_lastChangepoint=1;  g_cusumPos=0.0; g_cusumNeg=0.0; g_boostBarsLeft=InpCUSUM_BoostBars; }
   else if(g_cusumNeg < -g_activeThreshold)
   { g_lastChangepoint=-1; g_cusumPos=0.0; g_cusumNeg=0.0; g_boostBarsLeft=InpCUSUM_BoostBars; }
}

bool PosExists(ulong t){ return(t!=0&&PositionSelectByTicket(t)); }

double GetLastDealPnL()
{
   ulong dt=trade.ResultDeal();
   if(dt==0||!HistoryDealSelect(dt)) return 0.0;
   return HistoryDealGetDouble(dt,DEAL_PROFIT)+HistoryDealGetDouble(dt,DEAL_SWAP)+HistoryDealGetDouble(dt,DEAL_COMMISSION);
}
double GetFloatingPnL(ulong ticket)
{
   if(!PosExists(ticket)) return 0.0;
   return PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
}

void LogRow(string ev, double h, double atr, double sr, double adx, double pnl=0.0)
{
   if(g_csvHandle==INVALID_HANDLE) return;
   FileWrite(g_csvHandle,
             TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES),
             g_trendDir,
             DoubleToString(g_kTrend,8), DoubleToString(g_kZ,3),
             DoubleToString(g_cusumPos,3), DoubleToString(g_cusumNeg,3), g_lastChangepoint,
             DoubleToString(h,3),
             DoubleToString(atr,_Digits), DoubleToString(sr,2), DoubleToString(adx,2),
             g_holdBarCount, g_cooldownCounter,
             (long)g_trendTicket, g_hedgeLayerCount,
             ev,
             DoubleToString(pnl,2),
             DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2),
             DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));
   g_eventThisBar = true;
}

void ResetHedgeCycleState()
{
   for(int i=0;i<g_hedgeLayerCount;i++) g_hedgeTickets[i]=0;
   g_hedgeLayerCount = 0;
   g_hedgeAdverseExtreme = 0.0;
   g_lastHedgeCycleClosePrice = 0.0;
}

void ResetAfterReversal()
{
   g_holdBarCount    = 0;
   g_cooldownCounter = g_activeCooldownBars;
   ResetHedgeCycleState();
}

bool OpenFreshTrend(int dir)
{
   trade.SetExpertMagicNumber(InpMagicTrend);
   bool ok=(dir==1)?trade.Buy(InpTrendLegVolume,_Symbol,0,0,0,"AFA_TREND")
                   :trade.Sell(InpTrendLegVolume,_Symbol,0,0,0,"AFA_TREND");
   if(ok)
   {
      g_trendTicket = trade.ResultOrder();
      g_trendDir    = dir;
      double refP   = (dir==1)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
      g_trendOpenPrice = refP;
      g_trendPeakPrice = refP;
   }
   else { g_trendTicket=0; g_trendDir=0; }
   return ok;
}

//+------------------------------------------------------------------+
void OnTick()
{
   datetime curBar=iTime(_Symbol,PERIOD_H1,0);
   if(curBar==g_lastBarTime) return;
   g_lastBarTime=curBar;
   g_eventThisBar=false;

   if(g_trendDir!=0) g_holdBarCount++;
   if(g_cooldownCounter>0) g_cooldownCounter--;

   UpdateKalmanCUSUM();

   double h    = CalcHurstH1(InpHurstBars);
   double atr  = GetATR_H1();
   double sr   = CalcSpikeRatioH1();
   double adx  = GetADX_D1();
   bool   spike    = (sr>=InpSpikeATRRatio);
   bool   spikeBlk = (sr>=InpMaxSpikeRatioBlock);

   if(g_trendTicket!=0&&!PosExists(g_trendTicket)){g_trendTicket=0;g_trendDir=0;}
   // health-check لایه‌های هج (اگر بیرون از منطق ما بسته شده باشند، جمع‌شان کن)
   for(int i=g_hedgeLayerCount-1;i>=0;i--)
   {
      if(!PosExists(g_hedgeTickets[i]))
      {
         for(int j=i;j<g_hedgeLayerCount-1;j++)
         { g_hedgeTickets[j]=g_hedgeTickets[j+1]; g_hedgeEntryPrices[j]=g_hedgeEntryPrices[j+1]; }
         g_hedgeLayerCount--;
      }
   }

   //===== STEP 1: ورود اولیه با یک changepoint واقعی =====
   if(g_trendDir==0)
   {
      if(!spikeBlk && g_lastChangepoint!=0)
      {
         int wantDir = g_lastChangepoint;
         if(OpenFreshTrend(wantDir)) { ResetAfterReversal(); LogRow("OPEN_TREND",h,atr,sr,adx); }
         else LogRow("ORDER_FAILED",h,atr,sr,adx);
      }
      else LogRow("IDLE_WAIT_TREND",h,atr,sr,adx);
      return;
   }

   //===== STEP 1.5: Trailing Stop (جانبی — پیش‌فرض خاموش) =====
   double closeP = iClose(_Symbol,PERIOD_H1,1);
   if(g_trendDir==1) g_trendPeakPrice = MathMax(g_trendPeakPrice, closeP);
   else               g_trendPeakPrice = MathMin(g_trendPeakPrice, closeP);

   if(InpEnableTrailingStop)
   {
      double peakProfit = (g_trendDir==1) ? (g_trendPeakPrice-g_trendOpenPrice) : (g_trendOpenPrice-g_trendPeakPrice);
      double giveBack   = (g_trendDir==1) ? (g_trendPeakPrice-closeP)           : (closeP-g_trendPeakPrice);
      bool wasProfitable = (atr>0) && (peakProfit >= InpTrailingMinProfitATR*atr);
      bool trailHit       = wasProfitable && (atr>0) && (giveBack >= InpTrailingATRMult*atr);
      if(trailHit)
      {
         double hp=0,tp=0;
         for(int i=0;i<g_hedgeLayerCount;i++) if(PosExists(g_hedgeTickets[i])){ trade.PositionClose(g_hedgeTickets[i]); hp+=GetLastDealPnL(); }
         if(PosExists(g_trendTicket)){ trade.PositionClose(g_trendTicket); tp=GetLastDealPnL(); }
         LogRow("TRAILING_STOP_TREND",h,atr,sr,adx,tp+hp);
         g_trendTicket=0; g_trendDir=0;
         ResetAfterReversal();
         return;
      }
   }

   //===== STEP 1.6: سقف ضرر مستقل (ثابت شد لازم است) =====
   if(InpEnableMaxAdverse && atr>0)
   {
      double adverseNow = (g_trendDir==1) ? (g_trendOpenPrice-closeP) : (closeP-g_trendOpenPrice);
      if(adverseNow >= InpMaxAdverseATR*atr)
      {
         double hp=0,tp=0;
         for(int i=0;i<g_hedgeLayerCount;i++) if(PosExists(g_hedgeTickets[i])){ trade.PositionClose(g_hedgeTickets[i]); hp+=GetLastDealPnL(); }
         if(PosExists(g_trendTicket)){ trade.PositionClose(g_trendTicket); tp=GetLastDealPnL(); }
         LogRow("MAX_ADVERSE_STOP",h,atr,sr,adx,tp+hp);
         g_trendTicket=0; g_trendDir=0;
         ResetAfterReversal();
         return;
      }
   }

   //===== STEP 2: Reversal-Swap =====
   bool holdOK = (g_holdBarCount >= g_activeMinHold);
   bool coolOK = (g_cooldownCounter == 0);
   bool doReversal = (g_lastChangepoint == -g_trendDir) && holdOK && coolOK;

   if(doReversal)
   {
      double hp=0.0;
      for(int i=0;i<g_hedgeLayerCount;i++)
         if(PosExists(g_hedgeTickets[i])){ trade.PositionClose(g_hedgeTickets[i]); hp+=GetLastDealPnL(); }
      if(g_hedgeLayerCount>0) LogRow("CLOSE_HEDGE_FOR_REVERSAL",h,atr,sr,adx,hp);
      g_hedgeLayerCount=0;

      double tpnl=0.0;
      if(g_trendTicket!=0 && PosExists(g_trendTicket))
      { trade.PositionClose(g_trendTicket); tpnl=GetLastDealPnL(); }
      LogRow("CLOSE_TREND_ON_REVERSAL",h,atr,sr,adx,tpnl);
      g_trendTicket=0;

      int newDir=-g_trendDir;
      if(OpenFreshTrend(newDir)) { ResetAfterReversal(); LogRow("OPEN_TREND_AFTER_REVERSAL",h,atr,sr,adx); }
      else { ResetAfterReversal(); LogRow("ORDER_FAILED",h,atr,sr,adx); }
      return;
   }

   if(InpHedgeMode==HEDGE_OFF)
   { if(!g_eventThisBar) LogRow("BAR_TICK",h,atr,sr,adx); return; }

   //===== STEP 3: مدیریت پای هج (OFF/SINGLE/MULTI) =====
   double curPrice=(g_trendDir==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   // --- 3a: Net-Close روی مجموع پای روند + همهٔ لایه‌های هج باز ---
   if(InpEnableNetClose && g_hedgeLayerCount>0)
   {
      double combined = GetFloatingPnL(g_trendTicket);
      for(int i=0;i<g_hedgeLayerCount;i++) combined += GetFloatingPnL(g_hedgeTickets[i]);
      if(combined >= InpNetCloseTargetProfit)
      {
         double tot=0;
         for(int i=0;i<g_hedgeLayerCount;i++)
            if(PosExists(g_hedgeTickets[i])){ trade.PositionClose(g_hedgeTickets[i]); tot+=GetLastDealPnL(); }
         g_hedgeLayerCount=0;
         double tp=0;
         if(PosExists(g_trendTicket)){ trade.PositionClose(g_trendTicket); tp=GetLastDealPnL(); }
         g_trendTicket=0;
         LogRow("NET_CLOSE_BOTH",h,atr,sr,adx,tp+tot);
         int keepDir=g_trendDir;
         if(OpenFreshTrend(keepDir==0?1:keepDir)) { ResetHedgeCycleState(); LogRow("REOPEN_TREND_AFTER_NETCLOSE",h,atr,sr,adx); }
         else LogRow("ORDER_FAILED",h,atr,sr,adx);
         return;
      }
   }

   // --- 3b: باز کردن لایهٔ هج بعدی (SINGLE: حداکثر ۱ لایه؛ MULTI: تا InpMaxHedgeLayers) ---
   int maxLayers = (InpHedgeMode==HEDGE_MULTI) ? InpMaxHedgeLayers : 1;
   if(g_hedgeLayerCount < maxLayers)
   {
      double refPrice;
      if(g_hedgeLayerCount>0) refPrice=g_hedgeEntryPrices[g_hedgeLayerCount-1];
      else if(g_lastHedgeCycleClosePrice!=0.0) refPrice=g_lastHedgeCycleClosePrice;
      else if(PosExists(g_trendTicket)) refPrice=PositionGetDouble(POSITION_PRICE_OPEN);
      else refPrice=curPrice;

      double advMove=(g_trendDir==1)?(refPrice-curPrice):(curPrice-refPrice);
      bool mOK=advMove>=InpHedgeOpenATRMult*atr;
      bool hOK=h<InpHurstThreshold;
      bool sOK=!spike&&!spikeBlk;

      if(mOK&&hOK&&sOK)
      {
         int hdir=-g_trendDir;
         trade.SetExpertMagicNumber(InpMagicHedge);
         bool ok=(hdir==1)?trade.Buy(InpHedgeLegVolume,_Symbol,0,0,0,"AFA_HEDGE")
                          :trade.Sell(InpHedgeLegVolume,_Symbol,0,0,0,"AFA_HEDGE");
         trade.SetExpertMagicNumber(InpMagicTrend);
         if(ok)
         {
            g_hedgeTickets[g_hedgeLayerCount]=trade.ResultOrder();
            g_hedgeEntryPrices[g_hedgeLayerCount]=curPrice;
            g_hedgeLayerCount++;
            if(g_hedgeLayerCount==1) g_hedgeAdverseExtreme=curPrice;
            LogRow(g_hedgeLayerCount>1?"OPEN_HEDGE_LAYER":"OPEN_HEDGE",h,atr,sr,adx);
         }
      }
   }

   // --- 3c: بستن همهٔ لایه‌های باز با هم ---
   if(g_hedgeLayerCount>0)
   {
      if(g_trendDir==1) g_hedgeAdverseExtreme=MathMin(g_hedgeAdverseExtreme,curPrice);
      else               g_hedgeAdverseExtreme=MathMax(g_hedgeAdverseExtreme,curPrice);

      double advT=(g_trendDir==1)?(g_hedgeEntryPrices[0]-g_hedgeAdverseExtreme):(g_hedgeAdverseExtreme-g_hedgeEntryPrices[0]);
      double retF=(g_trendDir==1)?(curPrice-g_hedgeAdverseExtreme):(g_hedgeAdverseExtreme-curPrice);
      bool rOK  =(advT>0)&&(retF>=InpHedgeCloseRetraceP*advT);
      bool trOK =(KalmanConfidence()>=InpTrendConfirmZ)&&(((g_trendDir==1)&&(g_kTrend>0))||((g_trendDir==-1)&&(g_kTrend<0)));
      bool spSafe=spike;

      if(rOK||trOK||spSafe)
      {
         double tot=0;
         for(int i=0;i<g_hedgeLayerCount;i++)
            if(PosExists(g_hedgeTickets[i])){ trade.PositionClose(g_hedgeTickets[i]); tot+=GetLastDealPnL(); }
         g_lastHedgeCycleClosePrice=curPrice;
         g_hedgeLayerCount=0; g_hedgeAdverseExtreme=0.0;
         string ev=rOK?"CLOSE_HEDGE_RETRACE":(trOK?"CLOSE_HEDGE_TREND_RESUMED":"CLOSE_HEDGE_SPIKE_SAFETY");
         LogRow(ev,h,atr,sr,adx,tot);
      }
   }

   if(!g_eventThisBar) LogRow("BAR_TICK",h,atr,sr,adx);
}
//+------------------------------------------------------------------+
