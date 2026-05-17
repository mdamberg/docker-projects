// ─── Configuration ───────────────────────────────────────────────────────────
const LAN_URL       = "http://192.168.1.XXX:5000/api/widget";   // replace with your local IP
const TAILSCALE_URL = "http://100.X.X.X:5000/api/widget";       // replace with your Tailscale IP
const DEFAULT_CITY  = "Somerset,WI,US";
const TIMEOUT_MS    = 3000;
// ─────────────────────────────────────────────────────────────────────────────

const COLORS = {
  bg:          new Color("#0f1923"),
  bgCard:      new Color("#1a2636"),
  accent:      new Color("#00d4ff"),
  gold:        new Color("#ffd700"),
  purple:      new Color("#b082ff"),
  textPrimary: new Color("#ffffff"),
  textMuted:   new Color("#8899aa"),
  uvLow:       new Color("#4caf50"),
  uvModerate:  new Color("#ffeb3b"),
  uvHigh:      new Color("#ff9800"),
  uvVeryHigh:  new Color("#f44336"),
  uvExtreme:   new Color("#9c27b0"),
};

// ─── Fetch with fallback ──────────────────────────────────────────────────────

async function fetchWeather(city) {
  const urls = [
    `${LAN_URL}?city=${encodeURIComponent(city)}`,
    `${TAILSCALE_URL}?city=${encodeURIComponent(city)}`,
  ];

  for (const url of urls) {
    try {
      const req = new Request(url);
      req.timeoutInterval = TIMEOUT_MS / 1000;
      const data = await req.loadJSON();
      if (data && data.city) return data;
    } catch (_) {
      // try next URL
    }
  }
  return null;
}

// ─── UV helpers ──────────────────────────────────────────────────────────────

function uvLabel(value) {
  if (value === null || value === undefined) return { text: "N/A", color: COLORS.textMuted };
  if (value <= 2)  return { text: `${value.toFixed(1)} Low`,       color: COLORS.uvLow };
  if (value <= 5)  return { text: `${value.toFixed(1)} Moderate`,  color: COLORS.uvModerate };
  if (value <= 7)  return { text: `${value.toFixed(1)} High`,      color: COLORS.uvHigh };
  if (value <= 10) return { text: `${value.toFixed(1)} Very High`, color: COLORS.uvVeryHigh };
  return            { text: `${value.toFixed(1)} Extreme`,         color: COLORS.uvExtreme };
}

// ─── Icon URL ────────────────────────────────────────────────────────────────

function iconUrl(code) {
  return `https://openweathermap.org/img/wn/${code}@2x.png`;
}

async function loadIcon(code) {
  try {
    const req = new Request(iconUrl(code));
    return await req.loadImage();
  } catch (_) {
    return null;
  }
}

// ─── Widget builder ───────────────────────────────────────────────────────────

async function buildWidget(data) {
  const w = new ListWidget();
  w.backgroundColor = COLORS.bg;
  w.setPadding(14, 16, 14, 16);

  if (!data) {
    const err = w.addText("⚠️ Weather Unavailable");
    err.textColor  = COLORS.gold;
    err.font       = Font.boldSystemFont(16);
    w.addSpacer(6);
    const sub = w.addText("Check LAN_URL and TAILSCALE_URL in script settings.");
    sub.textColor  = COLORS.textMuted;
    sub.font       = Font.systemFont(12);
    return w;
  }

  const c = data.current;

  // ── Header: city + updated time ──────────────────────────────────────────
  const headerStack = w.addStack();
  headerStack.layoutHorizontally();
  headerStack.centerAlignContent();

  const cityText = headerStack.addText(`${data.city}, ${data.country}`);
  cityText.textColor = COLORS.gold;
  cityText.font      = Font.boldSystemFont(15);
  headerStack.addSpacer();

  const updatedText = headerStack.addText(`Updated ${data.updated.slice(11, 16)} UTC`);
  updatedText.textColor = COLORS.textMuted;
  updatedText.font      = Font.systemFont(10);

  w.addSpacer(8);

  // ── Current conditions row ───────────────────────────────────────────────
  const currentStack = w.addStack();
  currentStack.layoutHorizontally();
  currentStack.centerAlignContent();

  // Icon
  const icon = await loadIcon(c.icon);
  if (icon) {
    const iconImg = currentStack.addImage(icon);
    iconImg.imageSize = new Size(52, 52);
  }
  currentStack.addSpacer(8);

  // Temp block
  const tempBlock = currentStack.addStack();
  tempBlock.layoutVertically();

  const tempText = tempBlock.addText(`${c.temp}°F`);
  tempText.textColor = COLORS.accent;
  tempText.font      = Font.boldSystemFont(34);

  const descText = tempBlock.addText(c.description);
  descText.textColor = COLORS.purple;
  descText.font      = Font.systemFont(13);

  currentStack.addSpacer();

  // Right stats block
  const statsBlock = currentStack.addStack();
  statsBlock.layoutVertically();

  const hlText = statsBlock.addText(`H:${c.temp_high}°  L:${c.temp_low}°`);
  hlText.textColor = COLORS.textPrimary;
  hlText.font      = Font.mediumSystemFont(13);

  statsBlock.addSpacer(3);

  const feelsText = statsBlock.addText(`Feels ${c.feels_like}°`);
  feelsText.textColor = COLORS.textMuted;
  feelsText.font      = Font.systemFont(12);

  statsBlock.addSpacer(3);

  const humidText = statsBlock.addText(`Humidity ${c.humidity}%`);
  humidText.textColor = COLORS.textMuted;
  humidText.font      = Font.systemFont(12);

  statsBlock.addSpacer(3);

  const windText = statsBlock.addText(`Wind ${c.wind_speed} mph ${c.wind_dir}`);
  windText.textColor = COLORS.textMuted;
  windText.font      = Font.systemFont(12);

  w.addSpacer(6);

  // ── UV index badge ───────────────────────────────────────────────────────
  const uvStack = w.addStack();
  uvStack.layoutHorizontally();
  uvStack.centerAlignContent();

  const uvLabel_ = uvLabel(c.uv_index);
  const uvBadge = uvStack.addText(`UV Index: ${uvLabel_.text}`);
  uvBadge.textColor = uvLabel_.color;
  uvBadge.font      = Font.mediumSystemFont(12);

  w.addSpacer(10);

  // ── Divider ──────────────────────────────────────────────────────────────
  const divider = w.addStack();
  divider.backgroundColor = new Color("#ffffff", 0.1);
  divider.size = new Size(0, 1);

  w.addSpacer(10);

  // ── 5-day forecast grid ──────────────────────────────────────────────────
  const forecastStack = w.addStack();
  forecastStack.layoutHorizontally();
  forecastStack.centerAlignContent();

  for (const day of data.forecast) {
    const dayStack = forecastStack.addStack();
    dayStack.layoutVertically();
    dayStack.centerAlignContent();

    const dayLabel = dayStack.addText(day.date);
    dayLabel.textColor = COLORS.textMuted;
    dayLabel.font      = Font.systemFont(11);
    dayLabel.centerAlignText();

    const dayIcon = await loadIcon(day.icon);
    if (dayIcon) {
      const img = dayStack.addImage(dayIcon);
      img.imageSize = new Size(28, 28);
      img.centerAlignImage();
    } else {
      dayStack.addSpacer(28);
    }

    const hiText = dayStack.addText(`${day.temp_high}°`);
    hiText.textColor = COLORS.textPrimary;
    hiText.font      = Font.mediumSystemFont(12);
    hiText.centerAlignText();

    const loText = dayStack.addText(`${day.temp_low}°`);
    loText.textColor = COLORS.textMuted;
    loText.font      = Font.systemFont(11);
    loText.centerAlignText();

    if (day.pop > 0) {
      const popText = dayStack.addText(`${day.pop}%`);
      popText.textColor = COLORS.accent;
      popText.font      = Font.systemFont(10);
      popText.centerAlignText();
    } else {
      dayStack.addSpacer(13);
    }

    forecastStack.addSpacer();
  }

  return w;
}

// ─── Entry point ─────────────────────────────────────────────────────────────

const city = args.widgetParameter || DEFAULT_CITY;
const data  = await fetchWeather(city);
const widget = await buildWidget(data);

if (config.runsInWidget) {
  Script.setWidget(widget);
} else {
  widget.presentLarge();
}

Script.complete();
