//+------------------------------------------------------------------+
//|                                                    AFA_v8-3.mq5  |
//|  Ali's Fractal Anti-Drawdown Algorithm — V8-3 (هرس هدفمند)      |
//|                                                                  |
//| نتیجهٔ V8-2: پرونینگ درست کار کرد ولی خیلی حساس بود. سبد کل ۷ ماه|
//| بین ۲۷.۹۸- و ۳۷.۸۲+ گیر کرد (هدف ۴۰+، سقف ۸۰-) — هیچ‌کدوم لمس    |
//| نشد. علت با CSV تایید شد: فاز خنثی ۷۲.۵٪ بارها فعال بود، میانهٔ  |
//| طول هر دوره فقط ۹ کندل — یعنی هر پلهٔ اضافه‌شدهٔ سمت روند، با اولین|
//| بازگشتِ موقت به خنثی (نه برگشتِ واقعیِ روند) فوراً هرس می‌شد.       |
//|                                                                  |
//| فیکس: هرس فقط وقتی فعال می‌شود که فاز واقعاً *برعکس* شده باشد —    |
//| یعنی یک سمت صریحاً دارد علیه یک روندِ مخالفِ تاییدشده کار می‌کند.   |
//| در فاز خنثی، هیچ هرسی رخ نمی‌دهد — هرچه از فاز قبلی مانده دست‌نخورده|
//| می‌ماند تا شانس رسیدن به هدف یا سقف را داشته باشد.                 |
//+------------------------------------------------------------------+
#property copyright "Ali"
#property version   "8.30"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

//================== INPUTS ==================
input group "=== General ==="
input long   InpMagic                  = 780001;
input string InpCSVFileName            = "AFA_Log_v8-3.csv";

input group "=== Kalman Trend Engine (بدون تغییر از V7-1 — قلبِ اعتبارسنجی‌شده) ==="
input double InpKalman_R               = 0.000000575;
input double InpKalman_QLevelRatio     = 0.174;
input double InpKalman_QTrendRatio     = 0.0017;

input group "=== CUSUM Changepoint (بدون تغییر از V7-1) ==="
input double InpCUSUM_Slack            = 0.7;
input double InpCUSUM_Threshold        = 7.0;
input double InpCUSUM_BoostFactor      = 6.0;
input int    InpCUSUM_BoostBars        = 6;

input group "=== V8: طبقه‌بندی فاز (بایاسِ نامتقارنِ گرید) ==="
input double InpKalmanConfidenceStrong = 1.5;    // |شیب کالمن|/انحراف‌معیارش -> این یا بالاتر = «روند قوی»
input int    InpChangepointRecentBars  = 24;     // این تعداد کندل بعد از یک changepoint، بایاس همان جهت را نگه دار

input group "=== V8: ساختار گرید ==="
input double InpBaseVolume             = 0.01;   // حجم هر پله در فاز خنثی (هر دو سمت) — با باخت هرگز افزایش نمی‌یابد
input double InpGridStepATRMult        = 0.5;    // فاصلهٔ هر پله از پلهٔ قبلیِ همان سمت، ضریب ATR(H1)
input int    InpBaseLevelsPerSide      = 4;      // فاز خنثی: تعداد پلهٔ هدف هر دو سمت (متقارن)
input int    InpMaxLevelsTrendSide     = 7;      // فاز روند قوی: سقف پله‌های سمت هم‌جهت
input int    InpMaxLevelsCounterSide   = 2;      // فاز روند قوی: سقف پله‌های سمت مخالف
input double InpTrendVolume            = 0.02;   // لاتِ مطلقِ سمت هم‌جهت در روند قوی (نه نسبت — مستقیماً لات)
input double InpCounterVolume          = 0.01;   // لاتِ مطلقِ سمت مخالف در روند قوی (نه نسبت — مستقیماً لات)
input int    InpMaxNewLevelsPerBar     = 1;       // حداکثر پلهٔ جدید در هر سمت در هر کندل — ترمز رشدِ سریع شبکه

input group "=== V8: خروج و ریسک — این بخش هیچ‌وقت توگل نمی‌شود ==="
input double InpNetCloseTargetPctBalance   = 1.0;   // کل سبد را وقتی سود تجمیعی به این % بالانس رسید ببند
input double InpStopAddingLossPctBalance   = 1.5;   // نرم: از این ضرر تجمیعی به بعد، پلهٔ جدید اضافه نکن (بایاس فاز نادیده گرفته می‌شود)
input double InpMaxBasketLossPctBalance    = 2.0;   // سخت — همیشه‌روشن: از این ضرر تجمیعی، همه چیز فوری بسته و ری‌ست شود (بود ۳٪، طبق نسبت باخت/برد واقعی پایین آمد — هنوز حدس)

input group "=== Risk Gate ==="
input double InpMaxSpikeRatioBlock     = 3.0;    // در کندل اسپایک شدید، پلهٔ جدید گذاشته نشود (فقط ورود متوقف، پوزیشن باز دست‌نخورده)

//================== GLOBALS ==================
int      hATR_H1;
datetime g_lastBarTime         = 0;
int      g_csvHandle           = INVALID_HANDLE;
bool     g_eventThisBar        = false;

// --- Kalman + CUSUM (منطق دقیقاً از V7-1) ---
bool     g_kInit          = false;
double   g_kLevel         = 0.0;
double   g_kTrend         = 0.0;
double   g_kP00=1e-4, g_kP01=0.0, g_kP10=0.0, g_kP11=1e-6;
double   g_kZ             = 0.0;
double   g_cusumPos       = 0.0;
double   g_cusumNeg       = 0.0;
int      g_boostBarsLeft  = 0;
int      g_lastChangepoint= 0;
int      g_barsSinceChangepoint = 999999;
int      g_lastChangepointDir   = 0;

// --- Grid state (V8) ---
double   g_lowestBuyLevel   = 0.0;   // پایین‌ترین قیمتِ پلهٔ خرید فعلاً استفاده‌شده (فرکانتیرِ سمتِ خرید)
double   g_highestSellLevel = 0.0;   // بالاترین قیمتِ پلهٔ فروش فعلاً استفاده‌شده (فرکانتیرِ سمتِ فروش)

enum MarketPhase { PHASE_NEUTRAL=0, PHASE_STRONG_UP=1, PHASE_STRONG_DOWN=-1 };

//+------------------------------------------------------------------+
int OnInit()
{
   hATR_H1  = iATR(_Symbol, PERIOD_H1,  14);
   if(hATR_H1==INVALID_HANDLE)
   { Print("AFA V8: handle error"); return(INIT_FAILED); }

   g_csvHandle = FileOpen(InpCSVFileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   if(g_csvHandle != INVALID_HANDLE)
      FileWrite(g_csvHandle,
                "Time","Kalman_Trend","Kalman_Z","CUSUM_Pos","CUSUM_Neg","Changepoint","Phase",
                "ATR_H1","SpikeRatio","BuyCount","SellCount","TargetBuy","TargetSell",
                "AggregatePnL_USD","Event","EventPnL_USD","Balance","Equity");

   trade.SetExpertMagicNumber(InpMagic);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{ if(g_csvHandle!=INVALID_HANDLE) FileClose(g_csvHandle); }

//====== Kalman (Local-Linear-Trend) + CUSUM روی innovation — بدون تغییر از V7-1 ======
double KalmanConfidence(){ return (g_kP11>0) ? MathAbs(g_kTrend)/MathSqrt(g_kP11) : 0.0; }

void UpdateKalmanCUSUM()
{
   double price = MathLog(iClose(_Symbol,PERIOD_H1,1));
   g_lastChangepoint = 0;
   if(!g_kInit) { g_kLevel=price; g_kInit=true; g_kZ=0.0; g_barsSinceChangepoint++; return; }

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
   g_kZ   = y/MathSqrt(S);

   g_cusumPos = MathMax(0.0, g_cusumPos + g_kZ - InpCUSUM_Slack);
   g_cusumNeg = MathMin(0.0, g_cusumNeg + g_kZ + InpCUSUM_Slack);

   g_barsSinceChangepoint++;
   if(g_cusumPos > InpCUSUM_Threshold)
   { g_lastChangepoint=1;  g_cusumPos=0.0; g_cusumNeg=0.0; g_boostBarsLeft=InpCUSUM_BoostBars;
     g_barsSinceChangepoint=0; g_lastChangepointDir=1; }
   else if(g_cusumNeg < -InpCUSUM_Threshold)
   { g_lastChangepoint=-1; g_cusumPos=0.0; g_cusumNeg=0.0; g_boostBarsLeft=InpCUSUM_BoostBars;
     g_barsSinceChangepoint=0; g_lastChangepointDir=-1; }
}

//====== V8: طبقه‌بندی فاز — همان سیگنال قبلی، شغل جدید (بایاسِ گرید نه فلیپِ پوزیشن) ======
MarketPhase ClassifyPhase()
{
   if(g_barsSinceChangepoint<=InpChangepointRecentBars)
   {
      if(g_lastChangepointDir==1  && g_kTrend>0) return PHASE_STRONG_UP;
      if(g_lastChangepointDir==-1 && g_kTrend<0) return PHASE_STRONG_DOWN;
   }
   if(KalmanConfidence()>=InpKalmanConfidenceStrong)
      return (g_kTrend>0)?PHASE_STRONG_UP:PHASE_STRONG_DOWN;
   return PHASE_NEUTRAL;
}

void GetGridTargets(MarketPhase phase, int &targetBuy, int &targetSell, double &buyVol, double &sellVol)
{
   if(phase==PHASE_STRONG_UP)
   { targetBuy=InpMaxLevelsTrendSide; targetSell=InpMaxLevelsCounterSide; buyVol=InpTrendVolume; sellVol=InpCounterVolume; }
   else if(phase==PHASE_STRONG_DOWN)
   { targetBuy=InpMaxLevelsCounterSide; targetSell=InpMaxLevelsTrendSide; buyVol=InpCounterVolume; sellVol=InpTrendVolume; }
   else
   { targetBuy=InpBaseLevelsPerSide; targetSell=InpBaseLevelsPerSide; buyVol=InpBaseVolume; sellVol=InpBaseVolume; }
}

//====== محافظِ آخر: هر حجمی قبل از ارسال سفارش از اینجا رد می‌شود ======
double NormalizeVolume(double vol)
{
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double vmin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double vmax=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(step<=0) step=0.01;
   if(vmin<=0) vmin=0.01;
   double v=MathRound(vol/step)*step;
   v=MathMax(v,vmin);
   if(vmax>0) v=MathMin(v,vmax);
   return NormalizeDouble(v,2);
}

//====== ابزارهای حساب/سفارش ======
double GetATR_H1(){ double a[1]; return (CopyBuffer(hATR_H1,0,1,1,a)==1)?a[0]:0.0; }
double CalcSpikeRatioH1()
{
   double atr[1];
   if(CopyBuffer(hATR_H1,0,1,1,atr)!=1||atr[0]<=0) return 1.0;
   return (iHigh(_Symbol,PERIOD_H1,1)-iLow(_Symbol,PERIOD_H1,1))/atr[0];
}

int CountLegs(int dir)
{
   int c=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong tk=PositionGetTicket(i);
      if(tk==0 || !PositionSelectByTicket(tk)) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;
      long t=PositionGetInteger(POSITION_TYPE);
      if((t==POSITION_TYPE_BUY && dir==1)||(t==POSITION_TYPE_SELL && dir==-1)) c++;
   }
   for(int i=0;i<OrdersTotal();i++)
   {
      ulong tk=OrderGetTicket(i);
      if(tk==0 || !OrderSelect(tk)) continue;
      if((long)OrderGetInteger(ORDER_MAGIC)!=InpMagic) continue;
      long t=OrderGetInteger(ORDER_TYPE);
      if((t==ORDER_TYPE_BUY_LIMIT && dir==1)||(t==ORDER_TYPE_SELL_LIMIT && dir==-1)) c++;
   }
   return c;
}

double GetAggregateFloatingPnL()
{
   double sum=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong tk=PositionGetTicket(i);
      if(tk==0 || !PositionSelectByTicket(tk)) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;
      sum += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
   }
   return sum;
}

bool OpenMarketLeg(int dir, double vol)
{
   bool ok=(dir==1)?trade.Buy(vol,_Symbol,0,0,0,"AFA8_MKT"):trade.Sell(vol,_Symbol,0,0,0,"AFA8_MKT");
   return ok;
}

bool PlaceLimitLegVol(int dir, double price, double vol)
{
   double p=NormalizeDouble(price,_Digits);
   if(dir==1) return trade.BuyLimit(vol,p,_Symbol,0,0,ORDER_TIME_GTC,0,"AFA8_GRID");
   return trade.SellLimit(vol,p,_Symbol,0,0,ORDER_TIME_GTC,0,"AFA8_GRID");
}

void CloseAllPositions()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong tk=PositionGetTicket(i);
      if(tk==0 || !PositionSelectByTicket(tk)) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;
      trade.PositionClose(tk);
   }
}

void CancelAllPending()
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk=OrderGetTicket(i);
      if(tk==0 || !OrderSelect(tk)) continue;
      if((long)OrderGetInteger(ORDER_MAGIC)!=InpMagic) continue;
      trade.OrderDelete(tk);
   }
}

void ResetGridState(){ g_lowestBuyLevel=0.0; g_highestSellLevel=0.0; }

//====== V8-2: هرس — وقتی target یک سمت (بر اثر تغییر فاز) کوچیک‌تر از تعداد فعلی شد ======
//====== اول Pendingهای همان سمت رایگان کنسل می‌شوند، بعد بدترین پوزیشن‌های باز (بیشترین ضرر شناور) ======
void PruneSide(int dir, int targetCount, double atr, double sr, MarketPhase phase,
                int buyCount, int sellCount, int tB, int tS, double aggPnL)
{
   int count = CountLegs(dir);
   if(count<=targetCount) return;

   for(int i=OrdersTotal()-1; i>=0 && count>targetCount; i--)
   {
      ulong tk=OrderGetTicket(i);
      if(tk==0 || !OrderSelect(tk)) continue;
      if((long)OrderGetInteger(ORDER_MAGIC)!=InpMagic) continue;
      long t=OrderGetInteger(ORDER_TYPE);
      if((t==ORDER_TYPE_BUY_LIMIT && dir==1)||(t==ORDER_TYPE_SELL_LIMIT && dir==-1))
      {
         if(trade.OrderDelete(tk))
         {
            count--;
            LogRow(dir==1?"GRID_PRUNE_BUY_PENDING":"GRID_PRUNE_SELL_PENDING",
                   atr,sr,phase,buyCount,sellCount,tB,tS,aggPnL);
         }
      }
   }
   if(count<=targetCount) return;

   ulong tickets[]; double pnls[];
   int n=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      ulong tk=PositionGetTicket(i);
      if(tk==0 || !PositionSelectByTicket(tk)) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;
      long t=PositionGetInteger(POSITION_TYPE);
      if((t==POSITION_TYPE_BUY && dir==1)||(t==POSITION_TYPE_SELL && dir==-1))
      {
         ArrayResize(tickets,n+1); ArrayResize(pnls,n+1);
         tickets[n]=tk; pnls[n]=PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
         n++;
      }
   }
   for(int i=0;i<n-1;i++)
      for(int j=0;j<n-1-i;j++)
         if(pnls[j]>pnls[j+1])
         { double tp=pnls[j];pnls[j]=pnls[j+1];pnls[j+1]=tp; ulong tt=tickets[j];tickets[j]=tickets[j+1];tickets[j+1]=tt; }

   for(int i=0;i<n && count>targetCount;i++)
   {
      double pnlBefore=pnls[i];
      if(trade.PositionClose(tickets[i]))
      {
         count--;
         LogRow(dir==1?"GRID_PRUNE_BUY_POSITION":"GRID_PRUNE_SELL_POSITION",
                atr,sr,phase,buyCount,sellCount,tB,tS,aggPnL,pnlBefore);
      }
   }
}

void LogRow(string ev, double atr, double sr, MarketPhase phase, int buyC, int sellC,
            int tgtBuy, int tgtSell, double aggPnl, double evPnl=0.0)
{
   if(g_csvHandle==INVALID_HANDLE) return;
   FileWrite(g_csvHandle,
             TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES),
             DoubleToString(g_kTrend,8), DoubleToString(g_kZ,3),
             DoubleToString(g_cusumPos,3), DoubleToString(g_cusumNeg,3), g_lastChangepoint, (int)phase,
             DoubleToString(atr,_Digits), DoubleToString(sr,2),
             buyC, sellC, tgtBuy, tgtSell,
             DoubleToString(aggPnl,2),
             ev, DoubleToString(evPnl,2),
             DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2),
             DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));
   g_eventThisBar = true;
}

//====== V8: تراز کردن شبکه — حداکثر یک پلهٔ جدید هر سمت در هر کندل (ترمزِ رشد) ======
void ReconcileGrid(double atr, double sr, MarketPhase phase, double aggPnL)
{
   int targetBuy, targetSell; double buyVol, sellVol;
   GetGridTargets(phase, targetBuy, targetSell, buyVol, sellVol);

   int buyCount  = CountLegs(1);
   int sellCount = CountLegs(-1);

   bool spikeBlk = (sr>=InpMaxSpikeRatioBlock);
   bool softStop = (aggPnL <= -InpStopAddingLossPctBalance/100.0*AccountInfoDouble(ACCOUNT_BALANCE));

   if(buyCount==0 && sellCount==0)
   {
      // بوت‌استرپ: اولین پا همیشه مارکت (طبق دستور — «مارکت و لیمیت»)، سمتی که فاز/شیب الان طرفدارش است
      if(spikeBlk) { LogRow("IDLE_SPIKE_BLOCK",atr,sr,phase,buyCount,sellCount,targetBuy,targetSell,aggPnL); return; }
      int dir=(g_kTrend>=0)?1:-1;
      double vol=NormalizeVolume((dir==1)?buyVol:sellVol);
      if(OpenMarketLeg(dir,vol))
      {
         double px=(dir==1)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
         g_lowestBuyLevel=px; g_highestSellLevel=px;
         LogRow("GRID_BOOTSTRAP_MARKET",atr,sr,phase,buyCount,sellCount,targetBuy,targetSell,aggPnL);
      }
      else
         LogRow("BOOTSTRAP_ORDER_FAILED",atr,sr,phase,buyCount,sellCount,targetBuy,targetSell,aggPnL);
      return;
   }

   if(g_lowestBuyLevel<=0)   g_lowestBuyLevel  = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(g_highestSellLevel<=0) g_highestSellLevel= SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   // V8-3: هرس فقط وقتی فعال می‌شود که فاز واقعاً *برعکس* شده باشد — نه صرفاً بازگشت به خنثی.
   // در فاز خنثی، هرچه از قبل مانده دست‌نخورده می‌ماند تا شانس رسیدن به هدف/سقف را داشته باشد.
   if(phase==PHASE_STRONG_DOWN)
      PruneSide(1, InpMaxLevelsCounterSide, atr,sr,phase,buyCount,sellCount,targetBuy,targetSell,aggPnL);
   if(phase==PHASE_STRONG_UP)
      PruneSide(-1, InpMaxLevelsCounterSide, atr,sr,phase,buyCount,sellCount,targetBuy,targetSell,aggPnL);
   buyCount  = CountLegs(1);
   sellCount = CountLegs(-1);

   int addedBuy=0, addedSell=0;
   while(!spikeBlk && !softStop && buyCount<targetBuy && addedBuy<InpMaxNewLevelsPerBar)
   {
      double lvl=g_lowestBuyLevel-InpGridStepATRMult*atr;
      if(!PlaceLimitLegVol(1,lvl,NormalizeVolume(buyVol))) break;
      g_lowestBuyLevel=lvl; addedBuy++; buyCount++;
      LogRow("GRID_ADD_BUY",atr,sr,phase,buyCount,sellCount,targetBuy,targetSell,aggPnL);
   }
   while(!spikeBlk && !softStop && sellCount<targetSell && addedSell<InpMaxNewLevelsPerBar)
   {
      double lvl=g_highestSellLevel+InpGridStepATRMult*atr;
      if(!PlaceLimitLegVol(-1,lvl,NormalizeVolume(sellVol))) break;
      g_highestSellLevel=lvl; addedSell++; sellCount++;
      LogRow("GRID_ADD_SELL",atr,sr,phase,buyCount,sellCount,targetBuy,targetSell,aggPnL);
   }
   if(addedBuy==0 && addedSell==0 && !g_eventThisBar)
      LogRow("BAR_TICK",atr,sr,phase,buyCount,sellCount,targetBuy,targetSell,aggPnL);
}

//+------------------------------------------------------------------+
void OnTick()
{
   datetime curBar=iTime(_Symbol,PERIOD_H1,0);
   if(curBar==g_lastBarTime) return;
   g_lastBarTime=curBar;
   g_eventThisBar=false;

   UpdateKalmanCUSUM();

   double atr = GetATR_H1();
   double sr  = CalcSpikeRatioH1();
   MarketPhase phase = ClassifyPhase();
   double aggPnL = GetAggregateFloatingPnL();
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   int buyCount=CountLegs(1), sellCount=CountLegs(-1);
   int tB,tS; double bM,sM; GetGridTargets(phase,tB,tS,bM,sM);

   // ===== خط قرمز ۱: هدف سود تجمیعی — کل سبد را ببند و از صفر شروع کن =====
   if((buyCount+sellCount)>0 && aggPnL >= InpNetCloseTargetPctBalance/100.0*balance)
   {
      LogRow("BASKET_CLOSE_TARGET",atr,sr,phase,buyCount,sellCount,tB,tS,aggPnL,aggPnL);
      CloseAllPositions(); CancelAllPending(); ResetGridState();
      return;
   }
   // ===== خط قرمز ۲: سقف ضرر سخت — همیشه روشن، هیچ‌وقت toggle نمی‌شود =====
   if((buyCount+sellCount)>0 && aggPnL <= -InpMaxBasketLossPctBalance/100.0*balance)
   {
      LogRow("BASKET_CLOSE_SAFETY_STOP",atr,sr,phase,buyCount,sellCount,tB,tS,aggPnL,aggPnL);
      CloseAllPositions(); CancelAllPending(); ResetGridState();
      return;
   }

   ReconcileGrid(atr,sr,phase,aggPnL);
}
//+------------------------------------------------------------------+
