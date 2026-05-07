// Uses N8N_URL and N8N_KEY globals set by the bootstrap script

async function getData() {
  var req = new Request(N8N_URL + "/api/v1/workflows?limit=40");
  req.headers = {"X-N8N-API-KEY": N8N_KEY};
  var wfRes = await req.loadJSON();
  var workflows = wfRes.data ? wfRes.data : new Array();

  var req2 = new Request(N8N_URL + "/api/v1/executions?limit=100&includeData=false");
  req2.headers = {"X-N8N-API-KEY": N8N_KEY};
  var exRes = await req2.loadJSON();
  var exData = exRes.data ? exRes.data : new Array();

  exData.forEach(function(ex) {
    workflows.forEach(function(wf) {
      if (wf.id === ex.workflowId) {
        if (!wf.lastRun || ex.startedAt.localeCompare(wf.lastRun.startedAt) === 1) {
          wf.lastRun = ex;
        }
      }
    });
  });

  return workflows;
}

async function buildAndShow() {
  var workflows = await getData();

  var w = new ListWidget();
  w.backgroundColor = new Color("#1a1a2e");
  w.setPadding(12, 12, 12, 12);
  w.refreshAfterDate = new Date(Date.now() + 5 * 60 * 1000);

  var h = w.addText("n8n Pipelines");
  h.font = Font.boldSystemFont(14);
  h.textColor = new Color("#e879f9");
  w.addSpacer(8);

  if (workflows.length === 0) {
    var msg = w.addText("No workflows - check API key");
    msg.textColor = Color.gray();
    msg.font = Font.systemFont(11);
  }

  workflows.slice(0, 6).forEach(function(wf) {
    var exec = wf.lastRun ? wf.lastRun : null;
    var dotColor = Color.gray();
    if (exec) {
      if (exec.status === "success") { dotColor = new Color("#22c55e"); }
      if (exec.status === "error" || exec.status === "crashed") { dotColor = new Color("#ef4444"); }
      if (exec.status === "running") { dotColor = new Color("#3b82f6"); }
    }

    var row = w.addStack();
    row.layoutHorizontally();
    row.centerAlignContent();

    var dot = row.addText(wf.active ? "●" : "~");
    dot.font = Font.systemFont(11);
    dot.textColor = dotColor;
    row.addSpacer(5);

    var nm = row.addText(wf.name);
    nm.font = Font.systemFont(11);
    nm.textColor = wf.active ? Color.white() : Color.gray();
    nm.lineLimit = 1;
    row.addSpacer();

    var timeStr = "--";
    if (exec && exec.startedAt) {
      var secs = Math.round((Date.now() - new Date(exec.startedAt)) / 1000);
      var mins = Math.floor(secs / 60);
      var hours = Math.floor(mins / 60);
      var days = Math.floor(hours / 24);
      if (days !== 0) { timeStr = days + "d"; }
      else if (hours !== 0) { timeStr = hours + "h"; }
      else if (mins !== 0) { timeStr = mins + "m"; }
      else { timeStr = secs + "s"; }
    }

    var t = row.addText(timeStr);
    t.font = Font.systemFont(10);
    t.textColor = Color.gray();
    w.addSpacer(3);
  });

  w.presentMedium();
  Script.setWidget(w);
  Script.complete();
}

await buildAndShow();
