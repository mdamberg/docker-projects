// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: deep-gray; icon-glyph: bolt;
// n8n Pipeline Status Widget
// Requires: n8n API key (Settings -> API in n8n UI)
// Supports: Small (summary), Medium (6 workflows), Large (12 workflows)

var BASE_URL = "http://10.0.0.7:5678";
var API_KEY  = "YOUR_N8N_API_KEY_HERE";

// --- Data Fetching ---

async function fetchJson(path) {
  var req = new Request(BASE_URL + path);
  req.headers = { "X-N8N-API-KEY": API_KEY, "Accept": "application/json" };
  req.timeoutInterval = 10;
  return req.loadJSON();
}

async function getData() {
  var wfRes = await fetchJson("/api/v1/workflows?limit=40");
  var exRes = await fetchJson("/api/v1/executions?limit=100&includeData=false");

  var wfData = wfRes.data || [];
  var exData = exRes.data || [];

  var lastExec = {};
  for (var i = 0; i < exData.length; i++) {
    var ex = exData[i];
    var wid = ex.workflowId;
    if (!lastExec[wid]) {
      lastExec[wid] = ex;
    } else if (ex.startedAt.localeCompare(lastExec[wid].startedAt) === 1) {
      lastExec[wid] = ex;
    }
  }

  var result = [];
  for (var j = 0; j < wfData.length; j++) {
    var wf = wfData[j];
    result.push({
      id: wf.id,
      name: wf.name,
      active: wf.active,
      lastRun: lastExec[wf.id] || null
    });
  }
  return result;
}

// --- Formatting ---

function relativeTime(isoString) {
  if (!isoString) { return "never"; }
  var diff = (Date.now() - new Date(isoString)) / 1000;
  if (diff < 60)    { return Math.round(diff) + "s ago"; }
  if (diff < 3600)  { return Math.round(diff / 60) + "m ago"; }
  if (diff < 86400) { return Math.round(diff / 3600) + "h ago"; }
  return Math.round(diff / 86400) + "d ago";
}

function statusColor(exec) {
  if (!exec) { return Color.gray(); }
  if (exec.status === "success")  { return new Color("#22c55e"); }
  if (exec.status === "error")    { return new Color("#ef4444"); }
  if (exec.status === "crashed")  { return new Color("#ef4444"); }
  if (exec.status === "running")  { return new Color("#3b82f6"); }
  if (exec.status === "waiting")  { return new Color("#f59e0b"); }
  return Color.gray();
}

function statusDot(exec, active) {
  if (!active) { return "~"; }
  if (!exec)   { return "o"; }
  return "●";
}

// --- Small Widget ---

function addStat(widget, value, label, color) {
  var stack = widget.addStack();
  stack.layoutHorizontally();
  stack.centerAlignContent();
  var v = stack.addText(value);
  v.font = Font.boldSystemFont(14);
  v.textColor = color;
  if (label) {
    stack.addSpacer(4);
    var l = stack.addText(label);
    l.font = Font.systemFont(11);
    l.textColor = Color.gray();
  }
}

function buildSmall(widget, workflows) {
  widget.backgroundColor = new Color("#1a1a2e");
  var total = workflows.length;
  var active = 0, errors = 0, running = 0;
  for (var i = 0; i < workflows.length; i++) {
    var w = workflows[i];
    if (w.active) { active++; }
    if (w.lastRun && (w.lastRun.status === "error" || w.lastRun.status === "crashed")) { errors++; }
    if (w.lastRun && w.lastRun.status === "running") { running++; }
  }

  var title = widget.addText("n8n");
  title.font = Font.boldSystemFont(18);
  title.textColor = new Color("#e879f9");

  var sub = widget.addText("Pipelines");
  sub.font = Font.systemFont(11);
  sub.textColor = Color.gray();

  widget.addSpacer();
  addStat(widget, active + "/" + total, "Active", new Color("#22c55e"));
  if (errors > 0)  { addStat(widget, String(errors),  "Errors",  new Color("#ef4444")); }
  if (running > 0) { addStat(widget, String(running), "Running", new Color("#3b82f6")); }
  if (errors === 0 && running === 0) { addStat(widget, "All OK", "", new Color("#22c55e")); }
  widget.addSpacer();

  var updated = widget.addText("Refreshed just now");
  updated.font = Font.systemFont(9);
  updated.textColor = Color.gray();
}

// --- Medium / Large Widget ---

function buildList(widget, workflows, maxRows) {
  widget.backgroundColor = new Color("#1a1a2e");
  widget.setPadding(12, 12, 12, 12);

  var header = widget.addStack();
  header.layoutHorizontally();
  header.centerAlignContent();
  var titleText = header.addText("n8n Pipelines");
  titleText.font = Font.boldSystemFont(14);
  titleText.textColor = new Color("#e879f9");
  header.addSpacer();
  var ts = header.addText("now");
  ts.font = Font.systemFont(10);
  ts.textColor = Color.gray();

  widget.addSpacer(6);

  if (workflows.length === 0) {
    var empty = widget.addText("No workflows found. Check API key.");
    empty.font = Font.systemFont(11);
    empty.textColor = Color.gray();
    return;
  }

  var count = workflows.length;
  if (count > maxRows) { count = maxRows; }

  for (var i = 0; i < count; i++) {
    var wf = workflows[i];
    var row = widget.addStack();
    row.layoutHorizontally();
    row.centerAlignContent();

    var dot = row.addText(statusDot(wf.lastRun, wf.active));
    dot.font = Font.boldSystemFont(11);
    dot.textColor = statusColor(wf.lastRun);

    row.addSpacer(5);

    var name = row.addText(wf.name);
    name.font = Font.systemFont(11);
    name.textColor = wf.active ? Color.white() : Color.gray();
    name.lineLimit = 1;
    name.minimumScaleFactor = 0.8;

    row.addSpacer();

    var lastTime = wf.lastRun ? relativeTime(wf.lastRun.startedAt) : "--";
    var time = row.addText(lastTime);
    time.font = Font.systemFont(10);
    time.textColor = Color.gray();

    widget.addSpacer(3);
  }

  if (workflows.length > maxRows) {
    widget.addSpacer(4);
    var more = widget.addText("+" + (workflows.length - maxRows) + " more");
    more.font = Font.systemFont(10);
    more.textColor = Color.gray();
  }
}

// --- Entry Point ---

var widget = new ListWidget();
widget.refreshAfterDate = new Date(Date.now() + 5 * 60 * 1000);

try {
  var workflows = await getData();

  var statusOrder = { "error": 0, "crashed": 0, "running": 1, "waiting": 2, "success": 3 };

  workflows.sort(function(a, b) {
    var aActive = a.active ? 0 : 1;
    var bActive = b.active ? 0 : 1;
    if (aActive !== bActive) { return aActive - bActive; }
    var oa = (a.lastRun && statusOrder[a.lastRun.status] !== undefined) ? statusOrder[a.lastRun.status] : 4;
    var ob = (b.lastRun && statusOrder[b.lastRun.status] !== undefined) ? statusOrder[b.lastRun.status] : 4;
    return oa - ob;
  });

  var size = config.widgetFamily;
  if (size === "small") {
    buildSmall(widget, workflows);
  } else if (size === "large") {
    buildList(widget, workflows, 12);
  } else {
    buildList(widget, workflows, 6);
  }
} catch (e) {
  widget.backgroundColor = new Color("#1a1a2e");
  var err = widget.addText("Could not connect");
  err.textColor = new Color("#ef4444");
  err.font = Font.boldSystemFont(13);
  var detail = widget.addText(String(e.message || e));
  detail.textColor = Color.gray();
  detail.font = Font.systemFont(10);
  detail.lineLimit = 3;
}

widget.presentMedium();
Script.setWidget(widget);
Script.complete();
