import { useState } from "react";

// ─── Types ───────────────────────────────────────────────────────
type TabId = "flowchart" | "rule" | "bugs" | "comparison" | "lights";

interface TabDef {
  id: TabId;
  label: string;
  icon: string;
}

const TABS: TabDef[] = [
  { id: "flowchart", label: "فلوچارت سیگنال‌ها", icon: "🔀" },
  { id: "rule", label: "ماشین حالت Rule", icon: "⚙️" },
  { id: "bugs", label: "باگ‌ها و مشکلات", icon: "🐛" },
  { id: "comparison", label: "لایو vs بکتست vs ری‌استارت", icon: "🔄" },
  { id: "lights", label: "توضیح چراغ‌ها", icon: "💡" },
];

// ─── Main App ────────────────────────────────────────────────────
export default function App() {
  const [activeTab, setActiveTab] = useState<TabId>("flowchart");

  return (
    <div className="min-h-screen bg-gray-950 text-gray-100" dir="rtl">
      {/* Header */}
      <header className="sticky top-0 z-50 border-b border-gray-800 bg-gray-950/95 backdrop-blur-sm">
        <div className="mx-auto max-w-7xl px-4 py-3">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-red-500 to-orange-600 text-lg font-bold shadow-lg">
              HM
            </div>
            <div>
              <h1 className="text-lg font-bold text-white">
                HelpMe V13.51 — تحلیل جامع
              </h1>
              <p className="text-xs text-gray-400">
                فلوچارت سیگنال‌ها • باگ‌ها • لایو vs بکتست • چراغ‌ها
              </p>
            </div>
          </div>
          {/* Tabs */}
          <nav className="mt-3 flex gap-1 overflow-x-auto pb-1">
            {TABS.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center gap-1.5 whitespace-nowrap rounded-lg px-3 py-1.5 text-sm font-medium transition-all ${
                  activeTab === tab.id
                    ? "bg-blue-600 text-white shadow-lg shadow-blue-600/20"
                    : "text-gray-400 hover:bg-gray-800 hover:text-gray-200"
                }`}
              >
                <span>{tab.icon}</span>
                <span>{tab.label}</span>
              </button>
            ))}
          </nav>
        </div>
      </header>

      {/* Critical Summary Banner */}
      <div className="border-b border-red-900/30 bg-gradient-to-r from-red-950/40 via-gray-950 to-orange-950/30">
        <div className="mx-auto max-w-7xl px-4 py-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
            <div className="flex items-start gap-3">
              <span className="text-2xl">🔴</span>
              <div>
                <h3 className="font-bold text-red-400">۲ مشکل بحرانی باز</h3>
                <p className="text-gray-400 text-xs mt-1">بدون Stop-Loss + Kill-Switch پیاده‌سازی‌نشده. HelpMe فقط هشدار می‌دهد، عمل نمی‌کند.</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <span className="text-2xl">🟡</span>
              <div>
                <h3 className="font-bold text-yellow-400">بکتست ≠ لایو</h3>
                <p className="text-gray-400 text-xs mt-1">FLOW فریز، Spike کور، Crisis آرام‌تر — بکتست خوش‌بینانه‌تر از واقعیت است.</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <span className="text-2xl">⚡</span>
              <div>
                <h3 className="font-bold text-orange-400">ری‌استارت = کوری موقت</h3>
                <p className="text-gray-400 text-xs mt-1">GV پاک می‌شود، Replay فقط کندل بسته می‌بیند. Rule ممکن است به GREEN برگردد در حالی که بحران هنوز فعال است.</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <main className="mx-auto max-w-7xl px-4 py-6">
        {activeTab === "flowchart" && <FlowchartSection />}
        {activeTab === "rule" && <RuleMachineSection />}
        {activeTab === "bugs" && <BugsSection />}
        {activeTab === "comparison" && <ComparisonSection />}
        {activeTab === "lights" && <LightsSection />}
      </main>
    </div>
  );
}

// ══════════════════════════════════════════════════════════════════
// 🔀 FLOWCHART SECTION
// ══════════════════════════════════════════════════════════════════
function FlowchartSection() {
  const [hoveredNode, setHoveredNode] = useState<string | null>(null);
  const [selectedNode, setSelectedNode] = useState<string | null>(null);

  const activeNode = selectedNode || hoveredNode;

  // Node definitions with positions
  const nodes: FlowNode[] = [
    // Level 0: Data Sources
    { id: "data_h4", x: 60, y: 30, w: 160, h: 48, label: "کندل‌های H4", sub: "۶ جفت ارز خواهر", color: "#3b82f6", level: 0,
      desc: "دیتای خام کندل‌های ۴ ساعته از ۶ جفت ارز (GBPUSD, GBPEUR, GBPAUD, GBPCAD, GBPNZD + NZDUSD) که فید اصلی موتور FLOW است." },
    { id: "data_m1", x: 260, y: 30, w: 160, h: 48, label: "قیمت M1 زنده", sub: "Bid/Ask + Volume", color: "#3b82f6", level: 0,
      desc: "قیمت لحظه‌ای نمودار M1 شامل Bid, Ask, Volume و Rate of Change که فید اصلی Spike و Crisis است." },
    { id: "data_pos", x: 460, y: 30, w: 160, h: 48, label: "پوزیشن‌های باز", sub: "Buy/Sell + Step", color: "#3b82f6", level: 0,
      desc: "پوزیشن‌های باز Xmoon روی نمودار — شامل جهت (Buy/Sell)، پله فعال (Step)، حجم و سن پوزیشن." },
    { id: "data_news", x: 660, y: 30, w: 160, h: 48, label: "دیتای اخبار", sub: "FF Calendar API", color: "#3b82f6", level: 0,
      desc: "اخبار فاندامنتال از ForexFactory — شامل ارز، تأثیر (High/Med/Low)، پیش‌بینی و قبلی. فیلتر ۳۰ دقیقه قبل/بعد خبر." },

    // Level 1: Core Engines
    { id: "engine_flow", x: 30, y: 150, w: 200, h: 56, label: "موتور FLOW", sub: "FlowEvaluate()", color: "#8b5cf6", level: 1,
      desc: "مهم‌ترین موتور تحلیلی. قدرت هر ارز (GBP, EUR, NZD) را از ۶ جفت خواهر محاسبه می‌کند. خروجی: Flow_Score (0-100)، جهت (Buy/Sell)، و چراغ FLOW. اگر خواهرها resolve نشوند → g_flowLowConfidence=true" },
    { id: "engine_spike", x: 260, y: 150, w: 200, h: 56, label: "شناساگر Spike", sub: "Calc_SpikeDetector()", color: "#8b5cf6", level: 1,
      desc: "حرکات تند و ناگهانی قیمت را شناسایی می‌کند. حالت عادی: rawPhase≥1 + FLOW=Red. حالت Low-Conf: مستقل از FLOW با آستانه بالاتر (score≥2.5). خروجی: SpikeBuy/SpikeSell (0=Normal, 1=Warning, 2=Spike)" },
    { id: "engine_crisis", x: 490, y: 150, w: 200, h: 56, label: "تحلیل‌گر Crisis", sub: "UpdateCrisisLight()", color: "#8b5cf6", level: 1,
      desc: "۴ زیرمسیر: Orange-A (FLOW+RC+ADX+tsAgainst)، Orange-B (RC+ADX+tsAgainst)، Orange-C (FLOW+RC+ADX)، Orange-D (RC+ADX). در Low-Conf، A/C به fallback بدون FLOW می‌روند." },
    { id: "engine_zombie", x: 720, y: 150, w: 180, h: 56, label: "شناساگر ZOMBIE", sub: "Zone_Compute+H1", color: "#8b5cf6", level: 1,
      desc: "پوزیشن‌های گیرکرده را شناسایی می‌کند. Zone از قیمت فعلی محاسبه، H1 با ZombieH1ConfirmMinutes تأیید. اگر پوزیشن قدیمی‌تر از آستانه و zone خارج → چراغ ZOMBIE روشن." },

    // Level 1.5: Indicators used by engines
    { id: "ind_rc", x: 400, y: 260, w: 100, h: 36, label: "RC", sub: "Rate of Change", color: "#6366f1", level: 1.5,
      desc: "Rate of Change — سرعت تغییر قیمت. هرچه بالاتر، حرکت تندتر. آستانه: RC > threshold = خطرناک." },
    { id: "ind_adx", x: 520, y: 260, w: 100, h: 36, label: "ADX", sub: "Trend Strength", color: "#6366f1", level: 1.5,
      desc: "Average Directional Index — قدرت روند. ADX بالا = روند قوی = خطرناک برای Mean-Reversion." },
    { id: "ind_ts", x: 640, y: 260, w: 120, h: 36, label: "Trend-Against", sub: "خلاف پوزیشن", color: "#6366f1", level: 1.5,
      desc: "آیا روند خلاف جهت پوزیشن باز است؟ اگر بله، بحران شدیدتر است. ترکیب با RC و ADX اثر فزاینده دارد." },

    // Level 2: Intermediate Signals
    { id: "sig_flow", x: 30, y: 370, w: 200, h: 50, label: "FLOW Signal", sub: "Green / Yellow / Red / -1", color: "#10b981", level: 2,
      desc: "خروجی نهایی FLOW: Green (بازار رنج—امن)، Yellow (دست‌کم یک ارز قوی)، Red (جریان قوی خلاف)، -1 (بدون پوزیشن/هج—نامعتبر). *** وابستگی: Spike و Crisis به FLOW وابسته‌اند ***" },
    { id: "sig_spike", x: 260, y: 370, w: 200, h: 50, label: "SPIKE Signal", sub: "Normal / Warning / Spike", color: "#10b981", level: 2,
      desc: "خروجی نهایی Spike: Normal (حرکت عادی)، Warning (حرکت تند)، Spike (حرکت بسیار تند). جهت‌دار: SpikeBuy و SpikeSell جداگانه. در Low-Conf نمایش (LC) می‌گیرد." },
    { id: "sig_crisis", x: 490, y: 370, w: 200, h: 50, label: "CRISIS Signal", sub: "Green / Orange / Red", color: "#10b981", level: 2,
      desc: "خروجی نهایی Crisis: Green (امن)، Orange (بحران در حال شکل‌گیری—۴ زیرمسیر A/B/C/D)، Red (بحران کامل). جهت‌دار: CrisisBuy و CrisisSell جداگانه." },
    { id: "sig_zombie", x: 720, y: 370, w: 180, h: 50, label: "ZOMBIE Signal", sub: "Green / Yellow / Red", color: "#10b981", level: 2,
      desc: "خروجی نهایی ZOMBIE: Green (پوزیشن تازه)، Yellow (پوزیشن قدیمی ولی zone تأیید)، Red (پوزیشن قدیمی و zone نامطلوب—گیرکرده)." },

    // Level 2.5: Accumulators
    { id: "acc_hourred", x: 200, y: 480, w: 160, h: 40, label: "HourRed", sub: "انباشت ساعتی", color: "#f59e0b", level: 2.5,
      desc: "اکومولاتور ساعتی: اگر Crisis=Red در هر لحظه از ساعت → HourRed=true. در مرز ساعت خوانده و ریست می‌شود. key برای شمارش CrisisRedH." },
    { id: "acc_hourdirty", x: 400, y: 480, w: 160, h: 40, label: "HourDirty", sub: "انباشت ساعتی", color: "#f59e0b", level: 2.5,
      desc: "اکومولاتور ساعتی: اگر Spike≥1 در هر لحظه از ساعت → HourDirty=true. در مرز ساعت خوانده و ریست می‌شود. key برای شناسایی ساعت‌های Spikeدار." },

    // Level 3: Rule Engine
    { id: "rule_counters", x: 150, y: 580, w: 220, h: 50, label: "Rule_UpdateCounters()", sub: "CrisisRedH ↗ / CleanH ↗", color: "#ef4444", level: 3,
      desc: "شمارنده‌های Rule: CrisisRedH = تعداد ساعت‌های متوالی که حداقل یک بار Crisis=Red بوده. CleanH = تعداد ساعت‌های متوالی Clean. هر کدام دیگری را ریست می‌کند." },
    { id: "rule_transition", x: 430, y: 580, w: 220, h: 50, label: "Rule_Transition()", sub: "ماشین حالت Rule", color: "#ef4444", level: 3,
      desc: "ماشین حالت: ورودی‌ها = crisis level, spike level, half-against flag, CrisisRedH, CleanH. خروجی = Rule Level (GREEN/STOP/CLOSE) + reason. هر سه مسیر لایو/بکتست/Replay این تابع واحد را صدا می‌زنند." },

    // Level 4: Dashboard
    { id: "dash_flow", x: 30, y: 700, w: 90, h: 55, label: "FLOW", sub: "🟢🟡🔴", color: "#06b6d4", level: 4,
      desc: "چراغ FLOW روی داشبورد: سبز=امن، زرد=محتاط، قرمز=خطرناک. بدون پوزیشن=خاموش(-1). محدودیت: در بکتست ممکن است فریز شود." },
    { id: "dash_spike", x: 135, y: 700, w: 90, h: 55, label: "SPIKE", sub: "⚪🟡🔴", color: "#06b6d4", level: 4,
      desc: "چراغ SPIKE: سفید=عادی، زرد=هشدار، قرمز=اسپایک. در Low-Conf نمایش (LC) اضافه‌تر دارد. بدون پوزیشن=worst-case جهت‌دار." },
    { id: "dash_crisis", x: 240, y: 700, w: 90, h: 55, label: "CRISIS", sub: "🟢🟠🔴", color: "#06b6d4", level: 4,
      desc: "چراغ CRISIS: سبز=امن، نارنجی=بحران در شکل‌گیری، قرمز=بحران کامل. نارنجی ۴ مسیر A/B/C/D دارد." },
    { id: "dash_zombie", x: 345, y: 700, w: 90, h: 55, label: "ZOMBIE", sub: "🟢🟡🔴", color: "#06b6d4", level: 4,
      desc: "چراغ ZOMBIE: سبز=تازه، زرد=قدیمی+zone، قرمز=گیرکرده. تشخیص پوزیشن‌های راکد." },
    { id: "dash_rule", x: 450, y: 700, w: 90, h: 55, label: "RULE", sub: "🟢🔴⚫", color: "#06b6d4", level: 4,
      desc: "چراغ RULE: سبز=GREEN (معامله آزاد)، قرمز=STOP (سیگنال جدید ممنوع)، مشکی=CLOSE (بستن پوزیشن‌ها). هر جهت Buy/Sell جداگانه." },
    { id: "dash_trend", x: 555, y: 700, w: 90, h: 55, label: "TREND", sub: "↑ ↓ →", color: "#06b6d4", level: 4,
      desc: "جهت روند چارت. محاسبه از قیمت و پوزیشن. کمکی برای تصمیم‌گیری." },

    // Level 5: Action
    { id: "act_green", x: 200, y: 820, w: 150, h: 44, label: "🟢 GREEN", sub: "معامله آزاد", color: "#22c55e", level: 5,
      desc: "Rule Level 0: سیگنال جدید مجاز، پوزیشن‌ها باز می‌مانند. حالت عادی سیستم." },
    { id: "act_stop", x: 400, y: 820, w: 150, h: 44, label: "🔴 STOP", sub: "سیگنال ممنوع", color: "#ef4444", level: 5,
      desc: "Rule Level 1: سیگنال جدید ممنوع. پوزیشن‌های فعلی باز می‌مانند. یادآوری هر ۶۰ دقیقه." },
    { id: "act_close", x: 600, y: 820, w: 150, h: 44, label: "⚫ CLOSE", sub: "بستن پوزیشن", color: "#a855f7", level: 5,
      desc: "Rule Level 2: توصیه به بستن پوزیشن‌ها. یادآوری هر ۳۰ دقیقه. بالاترین سطح هشدار." },
  ];

  // Connection definitions
  const connections: FlowConn[] = [
    // Data → Engines
    { from: "data_h4", to: "engine_flow", label: "کندل خواهر", type: "data" },
    { from: "data_m1", to: "engine_spike", label: "قیمت زنده", type: "data" },
    { from: "data_m1", to: "engine_crisis", label: "RC+ADX", type: "data" },
    { from: "data_pos", to: "engine_zombie", label: "سن+پله", type: "data" },
    { from: "data_pos", to: "engine_crisis", label: "جهت", type: "data" },
    { from: "data_news", to: "engine_spike", label: "فیلتر خبر", type: "data" },

    // Indicators
    { from: "ind_rc", to: "engine_crisis", label: "", type: "indicator" },
    { from: "ind_adx", to: "engine_crisis", label: "", type: "indicator" },
    { from: "ind_ts", to: "engine_crisis", label: "", type: "indicator" },

    // Engines → Signals (critical: FLOW feeds into others)
    { from: "engine_flow", to: "sig_flow", label: "", type: "signal" },
    { from: "engine_spike", to: "sig_spike", label: "", type: "signal" },
    { from: "engine_crisis", to: "sig_crisis", label: "", type: "signal" },
    { from: "engine_zombie", to: "sig_zombie", label: "", type: "signal" },

    // Cross-dependencies (THE MOST IMPORTANT ONES)
    { from: "sig_flow", to: "engine_spike", label: "تأیید", type: "critical", dash: true },
    { from: "sig_flow", to: "engine_crisis", label: "Orange A/C", type: "critical", dash: true },
    { from: "sig_flow", to: "sig_spike", label: "Low-Conf", type: "critical", dash: true },

    // Signals → Accumulators
    { from: "sig_crisis", to: "acc_hourred", label: "Red→true", type: "signal" },
    { from: "sig_spike", to: "acc_hourdirty", label: "Spike≥1→true", type: "signal" },

    // Accumulators → Rule
    { from: "acc_hourred", to: "rule_counters", label: "", type: "signal" },
    { from: "acc_hourdirty", to: "rule_counters", label: "", type: "signal" },

    // Rule internals
    { from: "rule_counters", to: "rule_transition", label: "شمارنده‌ها", type: "signal" },
    { from: "sig_crisis", to: "rule_transition", label: "سطح بحران", type: "critical", dash: true },
    { from: "sig_spike", to: "rule_transition", label: "سطح اسپایک", type: "critical", dash: true },

    // Rule → Dashboard
    { from: "rule_transition", to: "dash_rule", label: "", type: "signal" },
    { from: "sig_flow", to: "dash_flow", label: "", type: "signal" },
    { from: "sig_spike", to: "dash_spike", label: "", type: "signal" },
    { from: "sig_crisis", to: "dash_crisis", label: "", type: "signal" },
    { from: "sig_zombie", to: "dash_zombie", label: "", type: "signal" },

    // Dashboard → Action
    { from: "dash_rule", to: "act_green", label: "Level 0", type: "action" },
    { from: "dash_rule", to: "act_stop", label: "Level 1", type: "action" },
    { from: "dash_rule", to: "act_close", label: "Level 2", type: "action" },
  ];

  // Get connected nodes for highlighting
  const getConnected = (nodeId: string): Set<string> => {
    const connected = new Set<string>();
    connected.add(nodeId);
    for (const c of connections) {
      if (c.from === nodeId) connected.add(c.to);
      if (c.to === nodeId) connected.add(c.from);
    }
    return connected;
  };

  const connectedSet = activeNode ? getConnected(activeNode) : null;

  const getNodeCenter = (id: string) => {
    const n = nodes.find((n) => n.id === id);
    if (!n) return { x: 0, y: 0 };
    return { x: n.x + n.w / 2, y: n.y + n.h / 2 };
  };

  const getConnColor = (type: string) => {
    switch (type) {
      case "critical": return "#ef4444";
      case "data": return "#3b82f6";
      case "indicator": return "#6366f1";
      case "signal": return "#10b981";
      case "action": return "#f59e0b";
      default: return "#6b7280";
    }
  };

  const selectedNodeData = nodes.find(n => n.id === selectedNode);

  return (
    <div>
      <div className="mb-4 rounded-xl border border-gray-800 bg-gray-900/50 p-4">
        <h2 className="text-xl font-bold text-white mb-2">🔀 فلوچارت کامل سیگنال‌های HelpMe V13.51</h2>
        <p className="text-sm text-gray-400 mb-2">
          روی هر گره کلیک کنید تا توضیح کامل و وابستگی‌هایش را ببینید. خطوط <span className="text-red-400 font-bold">قرمز</span> = وابستگی حیاتی، <span className="text-blue-400 font-bold">آبی</span> = دیتا، <span className="text-green-400 font-bold">سبز</span> = سیگنال، <span className="text-yellow-400 font-bold">زرد</span> = عمل
        </p>
        <div className="flex flex-wrap gap-3 text-xs">
          <span className="flex items-center gap-1"><span className="h-3 w-3 rounded bg-blue-500"></span> منبع دیتا</span>
          <span className="flex items-center gap-1"><span className="h-3 w-3 rounded bg-purple-500"></span> موتور تحلیل</span>
          <span className="flex items-center gap-1"><span className="h-3 w-3 rounded bg-indigo-500"></span> اندیکاتور</span>
          <span className="flex items-center gap-1"><span className="h-3 w-3 rounded bg-emerald-500"></span> سیگنال خروجی</span>
          <span className="flex items-center gap-1"><span className="h-3 w-3 rounded bg-amber-500"></span> اکومولاتور</span>
          <span className="flex items-center gap-1"><span className="h-3 w-3 rounded bg-red-500"></span> Rule Engine</span>
          <span className="flex items-center gap-1"><span className="h-3 w-3 rounded bg-cyan-500"></span> داشبورد</span>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-4 gap-4">
        {/* Flowchart SVG */}
        <div className="xl:col-span-3 rounded-xl border border-gray-800 bg-gray-900/80 overflow-auto">
          <svg viewBox="-10 0 920 900" className="w-full min-w-[700px]" style={{ maxHeight: "80vh" }}>
            {/* Background grid */}
            <defs>
              <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#1e293b" strokeWidth="0.5" />
              </pattern>
              <marker id="arrow-data" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
                <path d="M0,0 L8,3 L0,6" fill="#3b82f6" />
              </marker>
              <marker id="arrow-critical" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
                <path d="M0,0 L8,3 L0,6" fill="#ef4444" />
              </marker>
              <marker id="arrow-signal" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
                <path d="M0,0 L8,3 L0,6" fill="#10b981" />
              </marker>
              <marker id="arrow-action" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
                <path d="M0,0 L8,3 L0,6" fill="#f59e0b" />
              </marker>
              <marker id="arrow-indicator" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
                <path d="M0,0 L8,3 L0,6" fill="#6366f1" />
              </marker>
            </defs>
            <rect width="920" height="900" fill="url(#grid)" />

            {/* Level labels */}
            <text x="-5" y="55" fill="#475569" fontSize="11" fontWeight="bold" textAnchor="end" transform="rotate(-90,-5,55)">دیتا</text>
            <text x="-5" y="175" fill="#475569" fontSize="11" fontWeight="bold" textAnchor="end" transform="rotate(-90,-5,175)">موتور</text>
            <text x="-5" y="395" fill="#475569" fontSize="11" fontWeight="bold" textAnchor="end" transform="rotate(-90,-5,395)">سیگنال</text>
            <text x="-5" y="505" fill="#475569" fontSize="11" fontWeight="bold" textAnchor="end" transform="rotate(-90,-5,505)">انباشت</text>
            <text x="-5" y="605" fill="#475569" fontSize="11" fontWeight="bold" textAnchor="end" transform="rotate(-90,-5,605)">RULE</text>
            <text x="-5" y="725" fill="#475569" fontSize="11" fontWeight="bold" textAnchor="end" transform="rotate(-90,-5,725)">دشبورد</text>
            <text x="-5" y="840" fill="#475569" fontSize="11" fontWeight="bold" textAnchor="end" transform="rotate(-90,-5,840)">عمل</text>

            {/* Connections */}
            {connections.map((c, i) => {
              const from = getNodeCenter(c.from);
              const to = getNodeCenter(c.to);
              const fromNode = nodes.find(n => n.id === c.from);
              const toNode = nodes.find(n => n.id === c.to);
              if (!fromNode || !toNode) return null;

              // Calculate edge points
              const dx = to.x - from.x;
              const dy = to.y - from.y;
              const fromEdge = getEdgePoint(fromNode, dx, dy);
              const toEdge = getEdgePoint(toNode, -dx, -dy);

              const isHighlighted = connectedSet?.has(c.from) && connectedSet?.has(c.to);
              const isDimmed = connectedSet && !isHighlighted;
              const color = getConnColor(c.type);

              const midX = (fromEdge.x + toEdge.x) / 2;
              const midY = (fromEdge.y + toEdge.y) / 2;
              // Add slight curve for cross-dependencies
              const curve = c.dash ? 30 : 0;
              const cpX = midX + (dy > 0 ? -curve : curve);
              const cpY = midY;

              return (
                <g key={`conn-${i}`}>
                  <path
                    d={`M${fromEdge.x},${fromEdge.y} Q${cpX},${cpY} ${toEdge.x},${toEdge.y}`}
                    fill="none"
                    stroke={color}
                    strokeWidth={isHighlighted ? 3 : 1.5}
                    strokeDasharray={c.dash ? "6,3" : undefined}
                    opacity={isDimmed ? 0.15 : isHighlighted ? 1 : 0.5}
                    markerEnd={`url(#arrow-${c.type})`}
                  />
                  {c.label && !isDimmed && (
                    <text
                      x={cpX}
                      y={cpY - 6}
                      fill={color}
                      fontSize="8"
                      textAnchor="middle"
                      opacity={isHighlighted ? 1 : 0.6}
                    >
                      {c.label}
                    </text>
                  )}
                </g>
              );
            })}

            {/* Nodes */}
            {nodes.map((node) => {
              const isHighlighted = connectedSet?.has(node.id);
              const isDimmed = connectedSet && !isHighlighted;
              const isSelected = selectedNode === node.id;
              const isHovered = hoveredNode === node.id;

              return (
                <g
                  key={node.id}
                  onMouseEnter={() => setHoveredNode(node.id)}
                  onMouseLeave={() => setHoveredNode(null)}
                  onClick={() => setSelectedNode(selectedNode === node.id ? null : node.id)}
                  style={{ cursor: "pointer" }}
                >
                  {/* Glow effect for selected/hovered */}
                  {(isSelected || isHovered) && (
                    <rect
                      x={node.x - 3}
                      y={node.y - 3}
                      width={node.w + 6}
                      height={node.h + 6}
                      rx={10}
                      fill="none"
                      stroke={node.color}
                      strokeWidth={2}
                      opacity={0.5}
                      filter="url(#glow)"
                    />
                  )}
                  <rect
                    x={node.x}
                    y={node.y}
                    width={node.w}
                    height={node.h}
                    rx={8}
                    fill={isDimmed ? "#111827" : "#1e293b"}
                    stroke={isSelected ? node.color : isDimmed ? "#1f2937" : node.color}
                    strokeWidth={isSelected ? 2.5 : 1}
                    opacity={isDimmed ? 0.4 : 1}
                  />
                  <text
                    x={node.x + node.w / 2}
                    y={node.y + node.h / 2 - 4}
                    fill={isDimmed ? "#374151" : "#f1f5f9"}
                    fontSize="11"
                    fontWeight="bold"
                    textAnchor="middle"
                  >
                    {node.label}
                  </text>
                  <text
                    x={node.x + node.w / 2}
                    y={node.y + node.h / 2 + 10}
                    fill={isDimmed ? "#1f2937" : "#94a3b8"}
                    fontSize="8"
                    textAnchor="middle"
                  >
                    {node.sub}
                  </text>
                </g>
              );
            })}

            {/* Critical dependency annotation */}
            <rect x="15" y="325" width="300" height="24" rx="4" fill="#7f1d1d" opacity="0.8" />
            <text x="165" y="341" fill="#fca5a5" fontSize="9" textAnchor="middle" fontWeight="bold">
              ⚠️ FLOW به Spike و Crisis وابسته — قلب سیستم
            </text>

          </svg>
        </div>

        {/* Detail Panel */}
        <div className="xl:col-span-1">
          <div className="sticky top-32 rounded-xl border border-gray-800 bg-gray-900/80 p-4">
            <h3 className="text-sm font-bold text-gray-300 mb-3">📋 جزئیات گره انتخاب‌شده</h3>
            {selectedNodeData ? (
              <div>
                <div className="mb-3 flex items-center gap-2">
                  <span className="h-3 w-3 rounded" style={{ backgroundColor: selectedNodeData.color }}></span>
                  <span className="font-bold text-white">{selectedNodeData.label}</span>
                </div>
                <p className="text-sm text-gray-400 leading-7" style={{ lineHeight: "2" }}>{selectedNodeData.desc}</p>
                <div className="mt-3 border-t border-gray-800 pt-3">
                  <p className="text-xs font-bold text-gray-400 mb-1">وابستگی‌ها:</p>
                  <div className="flex flex-wrap gap-1">
                    {connectedSet && Array.from(connectedSet).filter(id => id !== selectedNode).map(id => {
                      const n = nodes.find(n => n.id === id);
                      return n ? (
                        <button
                          key={id}
                          onClick={() => setSelectedNode(id)}
                          className="rounded px-2 py-0.5 text-xs border border-gray-700 hover:border-gray-500"
                          style={{ color: n.color }}
                        >
                          {n.label}
                        </button>
                      ) : null;
                    })}
                  </div>
                </div>
              </div>
            ) : (
              <p className="text-sm text-gray-500">روی یک گره در فلوچارت کلیک کنید تا جزئیات آن نمایش داده شود...</p>
            )}
          </div>
        </div>
      </div>

      {/* Summary of signal dependencies */}
      <div className="mt-6 rounded-xl border border-amber-900/50 bg-amber-950/30 p-4">
        <h3 className="text-lg font-bold text-amber-400 mb-2">🔑 خلاصه وابستگی‌های حیاتی</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm text-gray-300 leading-8">
          <div className="rounded-lg bg-gray-900/50 p-3">
            <span className="text-red-400 font-bold">FLOW → Spike:</span> در حالت عادی، Spike فقط وقتی FLOW=Red تأیید می‌شود. اگر FLOW فریز یا نامعتبر باشد، Spike واقعی نادیده گرفته می‌شود (رفع v13.50 با مسیر مستقل LC).
          </div>
          <div className="rounded-lg bg-gray-900/50 p-3">
            <span className="text-red-400 font-bold">FLOW → Crisis Orange A/C:</span> دو مسیر از ۴ مسیر نارنجی مستقیماً به FLOW وابسته‌اند. بدون FLOW قابل‌اعتماد، این دو مسیر خاموش می‌شدند (رفع v13.50 با fallback).
          </div>
          <div className="rounded-lg bg-gray-900/50 p-3">
            <span className="text-red-400 font-bold">Crisis → Rule:</span> Rule از CrisisRedH و CleanH تغذیه می‌شود. اگر Crisis نادرست باشد، Rule هم نادرست می‌شود → ممکن است STOP/CLOSE دیرتر از لازم فعال شود.
          </div>
          <div className="rounded-lg bg-gray-900/50 p-3">
            <span className="text-red-400 font-bold">HourAccumulators:</span> اکومولاتورهای HourRed/HourDirty از سیگنال Crisis/Spike تغذیه می‌شوند. آخر هفته بدون تیک واقعی → CleanH مصنوعی (رفع v13.49).
          </div>
        </div>
      </div>
    </div>
  );
}

interface FlowNode {
  id: string; x: number; y: number; w: number; h: number;
  label: string; sub: string; color: string; level: number; desc: string;
}
interface FlowConn {
  from: string; to: string; label: string; type: string; dash?: boolean;
}

function getEdgePoint(node: FlowNode, dx: number, dy: number): { x: number; y: number } {
  const cx = node.x + node.w / 2;
  const cy = node.y + node.h / 2;
  const absDx = Math.abs(dx);
  const absDy = Math.abs(dy);
  if (absDx * node.h > absDy * node.w) {
    // Exit from left/right
    const sign = dx > 0 ? 1 : -1;
    return { x: cx + sign * node.w / 2, y: cy };
  } else {
    // Exit from top/bottom
    const sign = dy > 0 ? 1 : -1;
    return { x: cx, y: cy + sign * node.h / 2 };
  }
}


// ══════════════════════════════════════════════════════════════════
// ⚙️ RULE STATE MACHINE SECTION
// ══════════════════════════════════════════════════════════════════
function RuleMachineSection() {
  const [hoveredState, setHoveredState] = useState<string | null>(null);

  const states = [
    { id: "green", x: 200, y: 100, label: "GREEN", sub: "Level 0 — آزاد", color: "#22c55e",
      desc: "حالت عادی. سیگنال‌های جدید Xmoon مجاز هستند. پوزیشن‌های باز باقی می‌مانند. این حالت پیش‌فرض است.",
      entry: "شروع اکسپرت / RESUME بعد از CleanH کافی",
      exit: "CrisisRedH ≥ آستانه STOP" },
    { id: "stop", x: 500, y: 100, label: "STOP", sub: "Level 1 — ممنوع", color: "#ef4444",
      desc: "سیگنال جدید ممنوع. پوزیشن‌های باز باقی می‌مانند و TP خودشان را می‌زنند. یادآوری هر ۶۰ دقیقه.",
      entry: "CrisisRedH ≥ threshold_STOP",
      exit: "CrisisRedH ≥ threshold_CLOSE → CLOSE\nCleanH ≥ threshold_RESUME → GREEN" },
    { id: "close", x: 500, y: 350, label: "CLOSE", sub: "Level 2 — بستن", color: "#a855f7",
      desc: "بالاترین سطح هشدار. توصیه به بستن دستی پوزیشن‌ها. یادآوری هر ۳۰ دقیقه. HelpMe نمی‌تواند خودکار ببندد (Kill-Switch پیاده‌سازی نشده).",
      entry: "CrisisRedH ≥ threshold_CLOSE",
      exit: "CleanH ≥ threshold_RESUME → GREEN" },
  ];



  return (
    <div>
      <div className="mb-4 rounded-xl border border-gray-800 bg-gray-900/50 p-4">
        <h2 className="text-xl font-bold text-white mb-2">⚙️ ماشین حالت Rule — سه سطح GOLDEN RULE</h2>
        <p className="text-sm text-gray-400">
          Rule قلب تصمیم‌گیری HelpMe است. بر اساس CrisisRedH و CleanH (شمارنده‌های ساعتی)، سطح هشدار تعیین می‌شود.
          هر جهت Buy/Sell مستقل ارزیابی می‌شود.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* State Machine SVG */}
        <div className="lg:col-span-2 rounded-xl border border-gray-800 bg-gray-900/80 p-4">
          <svg viewBox="0 0 800 500" className="w-full">
            <defs>
              <marker id="arrow-rule-red" markerWidth="10" markerHeight="7" refX="10" refY="3.5" orient="auto">
                <path d="M0,0 L10,3.5 L0,7" fill="#ef4444" />
              </marker>
              <marker id="arrow-rule-purple" markerWidth="10" markerHeight="7" refX="10" refY="3.5" orient="auto">
                <path d="M0,0 L10,3.5 L0,7" fill="#a855f7" />
              </marker>
              <marker id="arrow-rule-green" markerWidth="10" markerHeight="7" refX="10" refY="3.5" orient="auto">
                <path d="M0,0 L10,3.5 L0,7" fill="#22c55e" />
              </marker>
            </defs>

            {/* State circles */}
            {states.map((s) => {
              const isHovered = hoveredState === s.id;
              return (
                <g key={s.id}
                  onMouseEnter={() => setHoveredState(s.id)}
                  onMouseLeave={() => setHoveredState(null)}
                  style={{ cursor: "pointer" }}
                >
                  {isHovered && (
                    <circle cx={s.x} cy={s.y} r="65" fill="none" stroke={s.color} strokeWidth="2" opacity="0.4" />
                  )}
                  <circle cx={s.x} cy={s.y} r="55" fill="#1e293b" stroke={s.color} strokeWidth={isHovered ? 3 : 2} />
                  <text x={s.x} y={s.y - 8} fill={s.color} fontSize="16" fontWeight="bold" textAnchor="middle">{s.label}</text>
                  <text x={s.x} y={s.y + 10} fill="#94a3b8" fontSize="9" textAnchor="middle">{s.sub}</text>
                </g>
              );
            })}

            {/* Transitions */}
            {/* GREEN → STOP */}
            <path d="M255,100 L440,100" fill="none" stroke="#ef4444" strokeWidth="2.5" markerEnd="url(#arrow-rule-red)" />
            <text x="350" y="90" fill="#ef4444" fontSize="10" textAnchor="middle" fontWeight="bold">CrisisRedH ≥ STOP</text>
            <text x="350" y="115" fill="#94a3b8" fontSize="8" textAnchor="middle">+ Spike / Half-Against</text>

            {/* STOP → CLOSE */}
            <path d="M500,155 L500,290" fill="none" stroke="#a855f7" strokeWidth="2.5" markerEnd="url(#arrow-rule-purple)" />
            <text x="530" y="220" fill="#a855f7" fontSize="10" fontWeight="bold">CrisisRedH ≥ CLOSE</text>
            <text x="530" y="238" fill="#94a3b8" fontSize="8">بحران عمیق‌تر</text>

            {/* STOP → GREEN */}
            <path d="M445,130 Q300,200 230,155" fill="none" stroke="#22c55e" strokeWidth="2" strokeDasharray="6,3" markerEnd="url(#arrow-rule-green)" />
            <text x="310" y="190" fill="#22c55e" fontSize="10" textAnchor="middle">CleanH ≥ RESUME</text>

            {/* CLOSE → GREEN */}
            <path d="M445,370 Q300,430 225,155" fill="none" stroke="#22c55e" strokeWidth="2" strokeDasharray="6,3" markerEnd="url(#arrow-rule-green)" />
            <text x="270" y="380" fill="#22c55e" fontSize="10" textAnchor="middle">CleanH ≥ RESUME</text>
            <text x="270" y="398" fill="#94a3b8" fontSize="8">بحران فروکش کرد</text>

            {/* Accumulator diagram */}
            <rect x="30" y="280" width="200" height="150" rx="8" fill="#1e293b" stroke="#f59e0b" strokeWidth="1" />
            <text x="130" y="305" fill="#f59e0b" fontSize="11" fontWeight="bold" textAnchor="middle">اکومولاتورهای ساعتی</text>
            <text x="40" y="325" fill="#94a3b8" fontSize="9">HourRed: Crisis=Red → true</text>
            <text x="40" y="342" fill="#94a3b8" fontSize="9">HourDirty: Spike≥1 → true</text>
            <text x="40" y="359" fill="#94a3b8" fontSize="9">مرز ساعت: خواندن + ریست</text>
            <text x="40" y="376" fill="#f59e0b" fontSize="9">→ CrisisRedH++ یا CleanH++</text>
            <text x="40" y="393" fill="#94a3b8" fontSize="9">هر کدام دیگری را ریست</text>
            <text x="40" y="420" fill="#ef4444" fontSize="8">آخر هفته: فقط با تیک واقعی</text>
          </svg>
        </div>

        {/* State Details */}
        <div className="space-y-3">
          {states.map((s) => (
            <div key={s.id} className="rounded-xl border p-4" style={{ borderColor: s.color + "44", backgroundColor: s.color + "0a" }}>
              <div className="flex items-center gap-2 mb-2">
                <span className="h-3 w-3 rounded-full" style={{ backgroundColor: s.color }}></span>
                <h4 className="font-bold" style={{ color: s.color }}>{s.label}</h4>
                <span className="text-xs text-gray-500">{s.sub}</span>
              </div>
              <p className="text-sm text-gray-300 mb-2 leading-7">{s.desc}</p>
              <div className="text-xs space-y-1">
                <p><span className="text-gray-500">ورود:</span> <span className="text-gray-300">{s.entry}</span></p>
                <p><span className="text-gray-500">خروج:</span> <span className="text-gray-300 whitespace-pre-line">{s.exit}</span></p>
              </div>
            </div>
          ))}

          {/* Key insight */}
          <div className="rounded-xl border border-red-900/50 bg-red-950/20 p-4">
            <h4 className="text-sm font-bold text-red-400 mb-1">⚠️ نکته حیاتی</h4>
            <p className="text-xs text-gray-400 leading-6">
              Rule فقط <span className="text-white">هشدار</span> می‌دهد — خودکار پوزیشن نمی‌بندد.
              Kill-Switch بین HelpMe و Xmoon هنوز پیاده‌سازی نشده (RISK-01/02).
              یعنی حتی CLOSE هم فقط پیام می‌دهد و تصمیم با تریدر است.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}


// ══════════════════════════════════════════════════════════════════
// 🐛 BUGS & ISSUES SECTION
// ══════════════════════════════════════════════════════════════════
interface BugItem {
  id: string;
  severity: "critical" | "high" | "medium" | "low";
  title: string;
  titleEn: string;
  status: "fixed" | "partial" | "open";
  fixedIn?: string;
  desc: string;
  impact: string;
  detail: string;
}

const BUGS: BugItem[] = [
  {
    id: "B1", severity: "critical", title: "بدون Stop-Loss", titleEn: "No Stop-Loss",
    status: "open",
    desc: "سیستم هیچ استاپ‌لاسی ندارد. استاپ عملی = کل بالانس. یک روند قوی کافیست تا حساب صفر شود.",
    impact: "ریسک وجودی سیستم — ریشه تمام کال‌ها",
    detail: "در بکتست ۲۰۲۶، ۲ کال رخ داده که مجموعاً بیش از ۱۴,۰۰۰ سنت ضرر. بدون SL، هر بحران طولانی = نابودی کامل. HelpMe فقط هشدار می‌دهد ولی نمی‌تواند جلوی ضرر را بگیرد."
  },
  {
    id: "B2", severity: "critical", title: "Kill-Switch بین HelpMe و Xmoon نیست", titleEn: "No Kill-Switch",
    status: "open",
    desc: "HelpMe نمی‌تواند خودکار پوزیشن‌های Xmoon را ببندد. حتی وقتی Rule=CLOSE، فقط پیام ارسال می‌شود.",
    impact: "CLOSE عملاً بی‌تأثیر اگر تریدر جلوی مانیتور نباشد",
    detail: "RISK-01/02 به v13.51 تأجیل شده. نیاز به Magic Number دقیق Xmoon. بدون آن، Kill-Switch اشتباهی پوزیشن سودده را می‌بندد. این یعنی HelpMe ناقص است — نیمی از سیستم که عمل نمی‌کند."
  },
  {
    id: "B3", severity: "high", title: "FLOW فریز در بکتست", titleEn: "FLOW Freeze in Backtest",
    status: "fixed", fixedIn: "v13.49",
    desc: "FlowFindSym در Strategy Tester نمی‌تواند سیمبل خواهر را resolve کند → fallback به base6 → iClose صفر → Flow_Score برای همیشه فریز.",
    impact: "بکتست سیستماتیک آرام‌تر از واقعیت — Rule دیرتر فعال می‌شود",
    detail: "رفع: SymbolInfoInteger(SYMBOL_EXIST) + iBars(H4)>50 + renormalize با آستانه ۷۰٪. اما مشکل اساسی باقیست: بکتست همچنان نمی‌تواند Flow واقعی را شبیه‌سازی کند."
  },
  {
    id: "B4", severity: "high", title: "تریبل‌کپی Rule — واگرایی لایو/بکتست/Replay", titleEn: "Rule Triple-Copy Bug",
    status: "fixed", fixedIn: "v13.50",
    desc: "منطق Rule در ۳ جا کپی شده بود (Alert_CheckGBPNZDRule, LogHourlySnapshot, GBPNZD_InitReplay). هر فیکس باید ۳ بار اعمال می‌شد.",
    impact: "ریشه تمام باگ‌های واگرایی v13.39–v13.49 — بکتست و لایو رفتار متفاوت",
    detail: "رفع: دو تابع مشترک Rule_UpdateCounters + Rule_Transition به عنوان Single Source of Truth. هر سه مسیر اکنون این توابع واحد را صدا می‌زنند."
  },
  {
    id: "B5", severity: "high", title: "کوری Spike در No-Position/Hedge", titleEn: "Spike Blindness",
    status: "fixed", fixedIn: "v13.47",
    desc: "Calc_SpikeDetector از g_lightFLOW استفاده می‌کند که در no-position/hedge = -1 → flowConfirms=false → همیشه Normal.",
    impact: "داشبورد دقیقاً وقتی مهم‌ترینه (قبل از ورود) گمراه‌کننده بود",
    detail: "رفع: بعد از Calc_SpikeDetector، چراغ با worst-case جهت‌دار override می‌شود. اما توجه: Rule از g_gbpnzdSpike مستقل کار می‌کرد — فقط چراغ دروغ می‌گفت."
  },
  {
    id: "B6", severity: "high", title: "GV Escape-Hatch اشتباه در Replay", titleEn: "GV Escape-Hatch Confusion",
    status: "fixed", fixedIn: "v13.51",
    desc: "GBPNZD_InitReplay حالت GREEN واقعی را با GV قدیمی اشتباه می‌گرفت (هر دو Level=0) → Replay کور از کندل‌های بسته.",
    impact: "بعد از ری‌استارت، وضعیت واقعی Rule دیده نمی‌شد تا بحران بعدی",
    detail: "رفع: کلید نسخه HM_GBNZD_Ver در GV. اگر نسخه GV قدیمی باشد، نادیده گرفته می‌شود و فقط کندل‌های بسته معتبرند."
  },
  {
    id: "B7", severity: "medium", title: "CleanH مصنوعی آخر هفته", titleEn: "Weekend CleanH Inflation",
    status: "fixed", fixedIn: "v13.49",
    desc: "بدون تیک واقعی آخر هفته، Crisis در مقدار آخرین جمعه می‌ماند → ۴۸ ساعت CleanH مصنوعی → RESUME زودرس دوشنبه.",
    impact: "دوشنبه صبح Rule زودتر از لازم به GREEN برمی‌گردت",
    detail: "رفع: چک SYMBOL_TIME قبل از عبور مرز ساعت. اگر بیش از ۲ ساعت قدیمی باشد، skip. اما edge-case: اگر بازار با گپ باز شود، اولین ساعت هنوز پردازش نمی‌شود."
  },
  {
    id: "B8", severity: "medium", title: "کوری Replay وسط کندل H1", titleEn: "Replay Mid-Candle Blindness",
    status: "partial", fixedIn: "v13.49",
    desc: "Replay فقط از کندل‌های بسته H1 بازسازی می‌کند. اگر Crisis وسط کندل رخ داده و کندل با رنگ بهتر بسته شده باشد، دیده نمی‌شود.",
    impact: "بعد از ری‌استارت، state تمیزتر از واقعیت",
    detail: "رفع جزئی: HourStateFile وضعیتaccumulator ساعت در حال شکل‌گیری را ذخیره می‌کند. اما فایل ممکن است خراب شود یا MT5 کامل ری‌استارت شود و فایل هم پاک شود."
  },
  {
    id: "B9", severity: "medium", title: "FLOW Low-Confidence Cascade", titleEn: "Low-Conf Cascade",
    status: "partial", fixedIn: "v13.50",
    desc: "وقتی FLOW نامعتبر است: Spike واقعی نادیده گرفته می‌شد (رفع v13.50)، Orange A/C خاموش می‌شد (رفع v13.50 با fallback).",
    impact: "در شرایط Low-Conf، سیستم کمتر حساس است — ممکن است بحران را دیرتر ببیند",
    detail: "Fallback با آستانه‌های بالاتر جایگزین شده ولی دقت کمتر. مثلاً Spike LC نیاز به score≥2.5 دارد به‌جای 1.5. یعنی برخی اسپایک‌های واقعی نادیده گرفته می‌شوند."
  },
  {
    id: "B10", severity: "medium", title: "شمارش پوزیشن بدون Magic Number", titleEn: "No Magic Number Filter",
    status: "partial", fixedIn: "v13.49",
    desc: "پیش‌فرض InpFilterByMagic=false. پوزیشن دستی یا EA دیگر روی همون چارت در شمارش ZOMBIE/Zone دخالت می‌کند.",
    impact: "محاسبه ZOMBIE و Zone ممکن است نادرست باشد",
    detail: "input جدید اضافه شده ولی پیش‌فرض false. برای فعال‌سازی، باید InpXmoonMagic با Magic واقعی Xmoon تنظیم شود. اکثر کاربران این کار را نمی‌کنند."
  },
  {
    id: "B11", severity: "low", title: "بکتست سیستماتیک آرام‌تر از واقعیت", titleEn: "Backtest Systematically Calmer",
    status: "open",
    desc: "حتی با تمام رفع‌ها، بکتست هنوز آرام‌تر از لایو: FLOW ممکن است فریز شود، Spike در no-position عادی نشان داده می‌شود، و Tick data محدود است.",
    impact: "نتایج بکتست خوش‌بینانه‌تر از واقعیت",
    detail: "مشکل ذاتی Strategy Tester با چندنمادی. راه‌حل نهایی: تست لایو با سرمایه کوچک. هر بکتست فقط حدودی است."
  },
];

const severityColors = {
  critical: { bg: "bg-red-950/40", border: "border-red-800/60", text: "text-red-400", badge: "bg-red-600" },
  high: { bg: "bg-orange-950/30", border: "border-orange-800/50", text: "text-orange-400", badge: "bg-orange-600" },
  medium: { bg: "bg-yellow-950/20", border: "border-yellow-800/40", text: "text-yellow-400", badge: "bg-yellow-600" },
  low: { bg: "bg-blue-950/20", border: "border-blue-800/40", text: "text-blue-400", badge: "bg-blue-600" },
};

function BugsSection() {
  const [expandedBug, setExpandedBug] = useState<string | null>(null);
  const [filterSeverity, setFilterSeverity] = useState<string>("all");

  const filtered = filterSeverity === "all" ? BUGS : BUGS.filter(b => b.severity === filterSeverity);

  return (
    <div>
      <div className="mb-4 rounded-xl border border-gray-800 bg-gray-900/50 p-4">
        <h2 className="text-xl font-bold text-white mb-2">🐛 باگ‌ها و مشکلات شناسایی‌شده</h2>
        <p className="text-sm text-gray-400 mb-3">
          تمام باگ‌های مهم شناسایی‌شده در کد HelpMe V13.51، با شدت، وضعیت رفع، و تأثیر عملیاتی
        </p>
        <div className="flex gap-2 flex-wrap">
          <button onClick={() => setFilterSeverity("all")} className={`rounded px-3 py-1 text-xs font-medium ${filterSeverity === "all" ? "bg-gray-600 text-white" : "bg-gray-800 text-gray-400"}`}>همه ({BUGS.length})</button>
          <button onClick={() => setFilterSeverity("critical")} className={`rounded px-3 py-1 text-xs font-medium ${filterSeverity === "critical" ? "bg-red-600 text-white" : "bg-gray-800 text-red-400"}`}>بحرانی ({BUGS.filter(b=>b.severity==="critical").length})</button>
          <button onClick={() => setFilterSeverity("high")} className={`rounded px-3 py-1 text-xs font-medium ${filterSeverity === "high" ? "bg-orange-600 text-white" : "bg-gray-800 text-orange-400"}`}>بالا ({BUGS.filter(b=>b.severity==="high").length})</button>
          <button onClick={() => setFilterSeverity("medium")} className={`rounded px-3 py-1 text-xs font-medium ${filterSeverity === "medium" ? "bg-yellow-600 text-white" : "bg-gray-800 text-yellow-400"}`}>متوسط ({BUGS.filter(b=>b.severity==="medium").length})</button>
          <button onClick={() => setFilterSeverity("low")} className={`rounded px-3 py-1 text-xs font-medium ${filterSeverity === "low" ? "bg-blue-600 text-white" : "bg-gray-800 text-blue-400"}`}>پایین ({BUGS.filter(b=>b.severity==="low").length})</button>
        </div>
      </div>

      <div className="space-y-3">
        {filtered.map((bug) => {
          const c = severityColors[bug.severity];
          const isExpanded = expandedBug === bug.id;
          return (
            <div key={bug.id} className={`rounded-xl border ${c.border} ${c.bg} overflow-hidden`}>
              <div className="flex items-center gap-3 p-4 cursor-pointer" onClick={() => setExpandedBug(isExpanded ? null : bug.id)}>
                <span className={`rounded px-2 py-0.5 text-xs font-bold text-white ${c.badge}`}>{bug.severity.toUpperCase()}</span>
                <span className={`text-xs px-2 py-0.5 rounded ${bug.status === "fixed" ? "bg-green-900/50 text-green-400" : bug.status === "partial" ? "bg-yellow-900/50 text-yellow-400" : "bg-red-900/50 text-red-400"}`}>
                  {bug.status === "fixed" ? "✅ رفع‌شده" : bug.status === "partial" ? "⚠️ جزئی" : "❌ باز"}
                </span>
                <span className="font-bold text-white flex-1">{bug.title}</span>
                <span className="text-xs text-gray-500">{bug.titleEn}</span>
                {bug.fixedIn && <span className="text-xs text-gray-500">v{bug.fixedIn.replace("v","")}</span>}
                <span className="text-gray-500">{isExpanded ? "▲" : "▼"}</span>
              </div>
              {isExpanded && (
                <div className="border-t border-gray-800 p-4 space-y-2">
                  <p className="text-sm text-gray-300 leading-7">{bug.desc}</p>
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-gray-500">تأثیر:</span>
                    <span className={`text-sm font-medium ${c.text}`}>{bug.impact}</span>
                  </div>
                  <p className="text-xs text-gray-400 leading-6 mt-2 border-t border-gray-800 pt-2">{bug.detail}</p>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Summary stats */}
      <div className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-3">
        <div className="rounded-xl bg-red-950/30 border border-red-900/30 p-4 text-center">
          <div className="text-3xl font-bold text-red-400">{BUGS.filter(b=>b.severity==="critical").length}</div>
          <div className="text-xs text-red-400/70">بحرانی</div>
        </div>
        <div className="rounded-xl bg-orange-950/30 border border-orange-900/30 p-4 text-center">
          <div className="text-3xl font-bold text-orange-400">{BUGS.filter(b=>b.severity==="high").length}</div>
          <div className="text-xs text-orange-400/70">بالا</div>
        </div>
        <div className="rounded-xl bg-green-950/30 border border-green-900/30 p-4 text-center">
          <div className="text-3xl font-bold text-green-400">{BUGS.filter(b=>b.status==="fixed").length}</div>
          <div className="text-xs text-green-400/70">رفع‌شده</div>
        </div>
        <div className="rounded-xl bg-red-950/30 border border-red-900/30 p-4 text-center">
          <div className="text-3xl font-bold text-red-300">{BUGS.filter(b=>b.status==="open").length}</div>
          <div className="text-xs text-red-300/70">باز</div>
        </div>
      </div>
    </div>
  );
}


// ══════════════════════════════════════════════════════════════════
// 🔄 LIVE vs BACKTEST vs RESTART COMPARISON
// ══════════════════════════════════════════════════════════════════
function ComparisonSection() {
  const comparisons: CompRow[] = [
    {
      feature: "FLOW Engine",
      live: "کامل — تمام خواهرها resolve می‌شوند. FLOW واقعی و قابل‌اعتماد.",
      backtest: "مشکل‌ساز — FlowFindSym ممکن است fail کند → فریز. Renormalize تا ۷۰٪. g_flowLowConfidence ممکن باشد.",
      restart: "GV پاک می‌شود. Replay از کندل‌های بسته H1. اگر Crisis وسط کندل بوده و کندل بهتر بسته شده → دیده نمی‌شود (HourStateFile جزئی رفع کرده).",
      severity: "high"
    },
    {
      feature: "Spike Detector",
      live: "کامل — FLOW تأیید می‌کند. rawPhase≥1 + FLOW=Red → Spike.",
      backtest: "در no-position/hedge، FLOW=-1 → همیشه Normal (رفع v13.47: override با worst-case).",
      restart: "حالت worst-case جهت‌دار حفظ می‌شود. در Low-Conf با آستانه بالاتر کار می‌کند.",
      severity: "high"
    },
    {
      feature: "Crisis Light",
      live: "۴ مسیر A/B/C/D فعال. FLOW واقعی برای Orange A/C.",
      backtest: "Orange A/C بدون FLOW واقعی → fallback به شرط‌های ساده‌تر (v13.50). سیستماتیک آرام‌تر.",
      restart: "بدون GV، Replay فقط از کندل‌های بسته می‌داند. Crisis وسط کندل ممکن است از دست برود.",
      severity: "medium"
    },
    {
      feature: "Rule Engine",
      live: "هر تیک ماشین حالت اجرا می‌شود. STOP فوری. یادآوری ۳۰/۶۰ دقیقه.",
      backtest: "LogHourlySnapshot فقط مرز ساعت اجرا. Rule_UpdateCounters + Rule_Transition مشترک (v13.50).",
      restart: "GBPNZD_InitReplay → Replay از H1 بسته → Rule_UpdateCounters + Rule_Transition. GV با نسخه‌چک (v13.51).",
      severity: "high"
    },
    {
      feature: "HourRed/HourDirty",
      live: "هر تیک OR می‌شود. مرز ساعت: خواندن + ریست. آخر هفته: skip بدون تیک واقعی (v13.49).",
      backtest: "فقط مرز ساعت. آخر هفته: مشکل چون بکتست tick شبیه‌سازی می‌کند.",
      restart: "از HourStateFile بازیابی (v13.49). اگر فایل نباشد، از صفر شروع.",
      severity: "medium"
    },
    {
      feature: "ZOMBIE Light",
      live: "سن پوزیشن واقعی. Zone از قیمت فعلی. H1 با ZombieH1ConfirmMinutes.",
      backtest: "Works normally — positions exist in tester.",
      restart: "پوزیشن‌ها هنوز باز هستند → ZOMBIE بلافاصله درست.",
      severity: "low"
    },
    {
      feature: "News Filter",
      live: "WebRequest به FF API. کش ۴ ساعته. ۳ URL پشتیبان.",
      backtest: "غیرفعال — WebRequest در Strategy Tester کار نمی‌کند.",
      restart: "کش از فایل محلی بارگذاری. اگه منقضی شده، دانلود مجدد.",
      severity: "low"
    },
    {
      feature: "Position Counting",
      live: "پیش‌فرض: همه پوزیشن‌های نماد. InpFilterByMagic=false.",
      backtest: "فقط پوزیشن‌های تستر. بدون تداخل.",
      restart: "پوزیشن‌ها از قبل باز هستند → شمارش بلافاصله درست (با توجه به فیلتر).",
      severity: "low"
    },
  ];

  return (
    <div>
      <div className="mb-4 rounded-xl border border-gray-800 bg-gray-900/50 p-4">
        <h2 className="text-xl font-bold text-white mb-2">🔄 مقایسه: لایو vs بکتست vs ری‌استارت</h2>
        <p className="text-sm text-gray-400">
          رفتار هر مؤلفه در سه محیط مختلف. تفاوت‌ها می‌توانند باعث واگرایی جدی بین نتایج بکتست و عملکرد واقعی شوند.
        </p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-800">
              <th className="p-3 text-right text-gray-400 font-medium w-32">مؤلفه</th>
              <th className="p-3 text-right text-gray-400 font-medium">🟢 لایو</th>
              <th className="p-3 text-right text-gray-400 font-medium">🟡 بکتست</th>
              <th className="p-3 text-right text-gray-400 font-medium">🔴 ری‌استارت</th>
            </tr>
          </thead>
          <tbody>
            {comparisons.map((row, i) => (
              <tr key={i} className={`border-b border-gray-800/50 ${i % 2 === 0 ? "bg-gray-900/30" : ""}`}>
                <td className="p-3">
                  <div className="flex items-center gap-2">
                    <span className={`h-2 w-2 rounded-full ${
                      row.severity === "high" ? "bg-red-500" : row.severity === "medium" ? "bg-yellow-500" : "bg-blue-500"
                    }`}></span>
                    <span className="font-medium text-white">{row.feature}</span>
                  </div>
                </td>
                <td className="p-3 text-gray-300 leading-7">{row.live}</td>
                <td className="p-3 text-gray-300 leading-7">{row.backtest}</td>
                <td className="p-3 text-gray-300 leading-7">{row.restart}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Key takeaway */}
      <div className="mt-6 rounded-xl border border-red-900/50 bg-red-950/20 p-4">
        <h3 className="text-lg font-bold text-red-400 mb-2">⚠️ نتیجه‌گیری کلیدی</h3>
        <div className="space-y-2 text-sm text-gray-300 leading-8">
          <p>1. <strong className="text-white">بکتست سیستماتیک خوش‌بینانه‌تر از لایو</strong> است — FLOW ممکن است فریز شود، Spike در no-position عادی نشان داده می‌شود، Orange A/C ممکن است fallback ساده‌تر داشته باشند.</p>
          <p>2. <strong className="text-white">ری‌استارت = کوری موقت</strong> — تا یک کندل H1 کامل بسته شود، Replay نمی‌تواند وضعیت دقیق را بازسازی کند. با HourStateFile و GV versioning بهتر شده ولی کامل نیست.</p>
          <p>3. <strong className="text-white">خطرناک‌ترین سناریو:</strong> ری‌استارت در وسط بحران → Rule به GREEN برمی‌گردت → Xmoon سیگنال جدید می‌گیرد → پله‌های بیشتر → ضرر سنگین‌تر.</p>
          <p>4. <strong className="text-white">جبران:</strong> با بازگشت دیتای واقعی، HourRed دوباره فعال می‌شود و Rule به STOP/CLOSE برمی‌گردد — ولی ممکن است چند ساعت طول بکشد.</p>
        </div>
      </div>
    </div>
  );
}

interface CompRow {
  feature: string; live: string; backtest: string; restart: string; severity: string;
}


// ══════════════════════════════════════════════════════════════════
// 💡 DASHBOARD LIGHTS EXPLANATION
// ══════════════════════════════════════════════════════════════════
function LightsSection() {
  const lights: LightItem[] = [
    {
      name: "FLOW", icon: "🌊", function: "FlowEvaluate()",
      states: [
        { state: "Green 🟢", condition: "Flow_Score پایین (بازار رنج)", meaning: "بازار در حالت رنج — امن برای معامله Mean-Reversion", color: "text-green-400" },
        { state: "Yellow 🟡", condition: "Flow_Score متوسط (دست‌کم یک ارز قوی)", meaning: "دست‌کم یک ارز قدرت گرفته — محتاط باش", color: "text-yellow-400" },
        { state: "Red 🔴", condition: "Flow_Score بالا (جریان قوی)", meaning: "جریان قوی خلاف پوزیشن — خطرناک! Spike فقط با FLOW=Red تأیید می‌شود", color: "text-red-400" },
        { state: "خاموش (-1)", condition: "بدون پوزیشن یا هج", meaning: "FLOW نامعتبر — Spike و Crisis به fallback می‌روند", color: "text-gray-500" },
      ],
      whatItHunts: "جریان‌های پول بین ارزها. اگر GBP قوی شود و NZD ضعیف، FLOW=Red برای Sell GBPNZD. موتور می‌خواهد بفهمد آیا پول در حال حرکت یک‌طرفه است یا بازار رنج است.",
      dependencies: "کندل‌های H4 از ۶ جفت ارز خواهر (GBPxxx, EURxxx, NZDxxx). g_flowLowConfidence اگر خواهرها resolve نشوند.",
      criticalFor: "Spike تأیید، Crisis Orange A/C، و غیرمستقیم Rule Level",
    },
    {
      name: "SPIKE", icon: "⚡", function: "Calc_SpikeDetector()",
      states: [
        { state: "Normal ⚪", condition: "rawPhase < آستانه", meaning: "حرکت عادی — نگران نباش", color: "text-gray-400" },
        { state: "Warning 🟡", condition: "rawPhase≥1 + FLOW≠Red (یا score≥1.5 LC)", meaning: "حرکت تند ولی جریان تأیید نمی‌کند — هشدار", color: "text-yellow-400" },
        { state: "Spike 🔴", condition: "rawPhase≥1 + FLOW=Red (یا score≥2.5 LC)", meaning: "اسپایک تأییدشده — حرکت تند + جریان قوی = خطر جدی", color: "text-red-400" },
      ],
      whatItHunts: "حرکات تند و ناگهانی قیمت که نشان‌دهنده تغییر فاز بازار هستند. Spike یعنی قیمت با سرعت غیرعادی حرکت می‌کند — دقیقاً چیزی که پله‌ها را یکی‌یکی فعال می‌کند.",
      dependencies: "FLOW برای تأیید (حالت عادی). در Low-Conf مستقل با آستانه بالاتر. قیمت M1 زنده.",
      criticalFor: "HourDirty accumulator → Rule Transition. Spike + Crisis = STOP/CLOSE سریع‌تر",
    },
    {
      name: "CRISIS", icon: "🔥", function: "UpdateCrisisLight()",
      states: [
        { state: "Green 🟢", condition: "هیچ شرط بحرانی", meaning: "بازار امن — RC پایین، ADX پایین، روند ملایم", color: "text-green-400" },
        { state: "Orange-A 🟠", condition: "FLOW=Red + RC + ADX + tsAgainst", meaning: "بحران از جریان + سرعت + قدرت روند + خلاف پوزیشن — شدیدترین نارنجی", color: "text-orange-400" },
        { state: "Orange-B 🟠", condition: "RC + ADX + tsAgainst (بدون FLOW)", meaning: "بحران از سرعت + قدرت + خلاف پوزیشن — مستقل از FLOW", color: "text-orange-400" },
        { state: "Orange-C 🟠", condition: "FLOW=Red + RC + ADX", meaning: "بحران از جریان + سرعت + قدرت روند — بدون شرط خلاف", color: "text-orange-400" },
        { state: "Orange-D 🟠", condition: "RC + ADX (بدون FLOW و tsAgainst)", meaning: "بحران خفیف — فقط سرعت + قدرت. مستقل از FLOW", color: "text-orange-400" },
        { state: "Red 🔴", condition: "CrisisRedH ≥ آستانه", meaning: "بحران کامل — ساعت‌ها Crisis نارنجی/قرمز متوالی", color: "text-red-400" },
      ],
      whatItHunts: "ترکیب خطرناک سرعت (RC) + قدرت روند (ADX) + جهت خلاف (tsAgainst) + جریان (FLOW). هر چه بیشتر از این عوامل هم‌زمان فعال باشند، بحران شدیدتر. Crisis = «آیا بازار در حال رفتن به جهتی است که پوزیشن من نمی‌تواند تحمل کند؟»",
      dependencies: "FLOW (Orange A/C)، RC، ADX، Trend-Against. در Low-Conf: Orange A/C به fallback بدون FLOW.",
      criticalFor: "HourRed accumulator → CrisisRedH → Rule Level. اصلی‌ترین فید Rule Engine.",
    },
    {
      name: "ZOMBIE", icon: "🧟", function: "Zone_ComputeFromPrice() + Zone_IsConfirmedByH1()",
      states: [
        { state: "Green 🟢", condition: "پوزیشن تازه یا Zone تأیید", meaning: "پوزیشن در وضعیت خوب — قیمت در Zone مناسب", color: "text-green-400" },
        { state: "Yellow 🟡", condition: "پوزیشن قدیمی + Zone نامشخص", meaning: "پوزیشن قدیمی شده ولی Zone هنوز امن — نگران نباش ولی حواست باشه", color: "text-yellow-400" },
        { state: "Red 🔴", condition: "پوزیشن قدیمی + Zone خارج + H1 تأیید", meaning: "پوزیشن گیرکرده — قیمت از Zone خارج و H1 هم تأیید. خطرناک!", color: "text-red-400" },
      ],
      whatItHunts: "پوزیشن‌های راکد و گیرکرده. وقتی پوزیشن مدت طولانی باز مانده و قیمت از محدوده امن دور شده، ZOMBIE اعلام خطر می‌کند. «آیا پوزیشن من هنوز زنده است یا زامبی شده؟»",
      dependencies: "سن پوزیشن (قدیمی‌ترین)، محاسبه Zone از قیمت فعلی، تأیید H1 با ZombieH1ConfirmMinutes.",
      criticalFor: "هشدار مستقیم به تریدر — ولی تأثیر مستقیم روی Rule ندارد (فقط اطلاع‌رسانی)",
    },
    {
      name: "RULE", icon: "⚖️", function: "Rule_UpdateCounters() + Rule_Transition()",
      states: [
        { state: "GREEN 🟢", condition: "Level 0 — CleanH کافی یا CrisisRedH پایین", meaning: "معامله آزاد — Xmoon می‌تواند سیگنال جدید بگیرد", color: "text-green-400" },
        { state: "STOP 🔴", condition: "Level 1 — CrisisRedH ≥ آستانه STOP", meaning: "سیگنال جدید ممنوع! پوزیشن‌های فعلی باز می‌مانند. یادآوری ۶۰ دقیقه‌ای.", color: "text-red-400" },
        { state: "CLOSE ⚫", condition: "Level 2 — CrisisRedH ≥ آستانه CLOSE", meaning: "بستن پوزیشن‌ها! بالاترین هشدار. یادآوری ۳۰ دقیقه‌ای.", color: "text-purple-400" },
      ],
      whatItHunts: "چرخه بحران — چه زمانی بحران شروع شده، چقدر طول کشیده، و آیا فروکش کرده. Rule = «آیا الان باید معامله کنم، دست نگه دارم، یا فرار کنم؟»",
      dependencies: "CrisisRedH (از HourRed/Crisis)، CleanH، Spike level، Half-Against flag. هر جهت Buy/Sell مستقل.",
      criticalFor: "تصمیم نهایی — آیا Xmoon سیگنال جدید بگیرد یا نه. بدون Kill-Switch، فقط هشدار.",
    },
    {
      name: "TREND", icon: "📈", function: "Chart Trend Analysis",
      states: [
        { state: "صعودی ↑", condition: "قیمت بالای میانگین + ساختار بالاتر", meaning: "روند صعودی — خطر برای Sell، امن برای Buy", color: "text-green-400" },
        { state: "نزولی ↓", condition: "قیمت زیر میانگین + ساختار پایین‌تر", meaning: "روند نزولی — خطر برای Buy، امن برای Sell", color: "text-red-400" },
        { state: "رنج →", condition: "قیمت نزدیک میانگین + بدون ساختار واضح", meaning: "بازار رنج — امن‌ترین حالت برای Mean-Reversion", color: "text-gray-400" },
      ],
      whatItHunts: "جهت کلی روند بازار. Trend می‌خواهد بفهمد آیا بازار در حال حرکت یک‌طرفه است یا خنثی. در Mean-Reversion، روند قوی = دشمن، رنج = دوست.",
      dependencies: "قیمت فعلی، میانگین متحرک، ساختار سقف/کف. M15 برای TP Extended.",
      criticalFor: "مستقیم تأثیر روی Rule ندارد — ولی وارد محاسبه Half-Against و tsAgainst می‌شود که Crisis و Rule را تحت تأثیر قرار می‌دهد.",
    },
  ];

  return (
    <div>
      <div className="mb-4 rounded-xl border border-gray-800 bg-gray-900/50 p-4">
        <h2 className="text-xl font-bold text-white mb-2">💡 توضیح چراغ‌های داشبورد — به زبان ساده</h2>
        <p className="text-sm text-gray-400">
          هر چراغ چه می‌خواهد، چه شکار می‌کند، و چرا روشن می‌شود
        </p>
      </div>

      <div className="space-y-4">
        {lights.map((light) => (
          <div key={light.name} className="rounded-xl border border-gray-800 bg-gray-900/50 overflow-hidden">
            {/* Header */}
            <div className="flex items-center gap-3 border-b border-gray-800 p-4">
              <span className="text-2xl">{light.icon}</span>
              <div>
                <h3 className="text-lg font-bold text-white">{light.name}</h3>
                <span className="text-xs text-gray-500 font-mono">{light.function}</span>
              </div>
            </div>

            <div className="p-4 grid grid-cols-1 lg:grid-cols-3 gap-4">
              {/* States */}
              <div className="lg:col-span-1">
                <h4 className="text-sm font-bold text-gray-400 mb-2">وضعیت‌ها</h4>
                <div className="space-y-2">
                  {light.states.map((s, i) => (
                    <div key={i} className="rounded-lg bg-gray-800/50 p-2.5">
                      <div className={`text-sm font-bold ${s.color}`}>{s.state}</div>
                      <div className="text-xs text-gray-400 mt-0.5">شرط: {s.condition}</div>
                      <div className="text-xs text-gray-300 mt-1 leading-5">{s.meaning}</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* What it hunts + Dependencies */}
              <div className="lg:col-span-2 space-y-3">
                <div className="rounded-lg bg-amber-950/20 border border-amber-900/30 p-3">
                  <h4 className="text-sm font-bold text-amber-400 mb-1">🎯 چه شکار می‌کند؟</h4>
                  <p className="text-sm text-gray-300 leading-7">{light.whatItHunts}</p>
                </div>
                <div className="rounded-lg bg-blue-950/20 border border-blue-900/30 p-3">
                  <h4 className="text-sm font-bold text-blue-400 mb-1">🔌 وابستگی‌ها</h4>
                  <p className="text-sm text-gray-300 leading-7">{light.dependencies}</p>
                </div>
                <div className="rounded-lg bg-red-950/20 border border-red-900/30 p-3">
                  <h4 className="text-sm font-bold text-red-400 mb-1">⚠️ حیاتی برای</h4>
                  <p className="text-sm text-gray-300 leading-7">{light.criticalFor}</p>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Signal chain summary */}
      <div className="mt-6 rounded-xl border border-gray-700 bg-gray-900/80 p-4">
        <h3 className="text-lg font-bold text-white mb-3">🔗 زنجیره سیگنال — از دیتا تا عمل</h3>
        <div className="flex flex-wrap items-center gap-2 text-sm">
          <span className="rounded bg-blue-900/50 px-3 py-1.5 text-blue-300 font-medium">H4 کندل</span>
          <span className="text-gray-600">→</span>
          <span className="rounded bg-purple-900/50 px-3 py-1.5 text-purple-300 font-medium">FLOW</span>
          <span className="text-gray-600">→</span>
          <span className="rounded bg-purple-900/50 px-3 py-1.5 text-purple-300 font-medium">Spike ✓</span>
          <span className="text-gray-600">+</span>
          <span className="rounded bg-purple-900/50 px-3 py-1.5 text-purple-300 font-medium">Crisis ✓</span>
          <span className="text-gray-600">→</span>
          <span className="rounded bg-amber-900/50 px-3 py-1.5 text-amber-300 font-medium">HourRed</span>
          <span className="text-gray-600">→</span>
          <span className="rounded bg-red-900/50 px-3 py-1.5 text-red-300 font-medium">CrisisRedH++</span>
          <span className="text-gray-600">→</span>
          <span className="rounded bg-red-900/50 px-3 py-1.5 text-red-300 font-bold">STOP / CLOSE</span>
        </div>
        <div className="mt-3 flex flex-wrap items-center gap-2 text-sm">
          <span className="text-gray-600">بازگشت:</span>
          <span className="rounded bg-green-900/50 px-3 py-1.5 text-green-300 font-medium">CleanH++</span>
          <span className="text-gray-600">→</span>
          <span className="rounded bg-green-900/50 px-3 py-1.5 text-green-300 font-bold">GREEN / RESUME</span>
        </div>
      </div>
    </div>
  );
}

interface LightItem {
  name: string; icon: string; function: string;
  states: { state: string; condition: string; meaning: string; color: string }[];
  whatItHunts: string; dependencies: string; criticalFor: string;
}
