const puts = (...args)=>{
  console.log(...args);
};

class Comet {
  constructor() {
    this.timer = null;
    this.connected = true;
    this.sessionId = Date.now();
  }

  _open() {
    $.post("/comet", { sessionid: this.sessionId })
      .then((data)=>{
        if (this.connected) {
          this.onmessage(data);
          this.open();
        }
      })
      .catch((...args)=>{
        if (this.connected) {
          console.info("comet > catch", args);
        } else {
          // ignore
        }
      });
  }

  open() {
    clearTimeout(this.timer);
    this.timer = setTimeout(()=>{
      this._open();
    }, 0);
  }

  onclose() {
    this.connected = false;
    console.info("onclose");
    $.post("/close");
    clearTimeout(this.timer);
  }
}

class CanvasWrapper {
  constructor(el) {
    this.el = el;
    this.$el = $(el);
    this.ctx = el.getContext("2d");
  }

  reset(w, h) {
    this.$el.attr("width" , w);
    this.$el.attr("height", h);
    this.$el.show();
  }

  execCmd(cmd) {
    const _cmd  = cmd[0];
    const args = cmd.slice(1);

    if (_cmd in this.ctx) {
      if (typeof this.ctx[_cmd] === "function") {
        this.ctx[_cmd](...args);
      } else {
        this.ctx[_cmd] = args[0];
      }
    } else {
      console.error("invalid command", _cmd);
    }
  }
}

class App {
  constructor() {
    this.comet = new Comet();
    this.cw = new CanvasWrapper($("canvas").get(0));
    this.resTimes = [];
  }

  start() {
    // comet
    this.comet.onmessage = this.onmessage.bind(this);
    this.comet.open();

    // ping thread
    setInterval(()=>{
      this.ping();
    }, 1000);
  }

  onmessage(data) {
    this.refreshRps();
    this.refreshQsize(data.qsize, data.events.length);

    data.events.forEach((event)=>{
      switch (event.type) {
      case "reset":
        this.cw.reset(event.payload.w, event.payload.h);
        break;

      case "cmds":
        event.cmds.forEach((cmd)=>{
          this.cw.execCmd(cmd);
        });
        break;

      case "close":
        this.comet.onclose();
        break;

      default:
        console.error("unknown event", event);
      }
    });
  }

  refreshRps() {
    const currentTime = Date.now();
    this.resTimes.push(currentTime);
    const limit = currentTime - 1000;

    const recent =
      this.resTimes.filter((time)=> limit <= time );

    this.resTimes = recent;

    $("#rps").text(recent.length);
  }

  refreshQsize(qsize, numEvents) {
    $("#qsize").text(qsize);

    let qsizeBar = "#".repeat(numEvents);
    if (numEvents < qsize) {
      qsizeBar += "-".repeat(qsize - numEvents);
    }
    $("#qsize_bar").text(qsizeBar);
  }

  ping() {
    if (this.comet.connected) {
      return;
    }

    $.post("/ping")
    .then((data)=>{
      if (data.status === "running") {
        location.reload();
      } else {
        console.info("ping > " + data.status);
        throw new Error("ping ng");
      }
    })
    .catch(()=>{
      const text = $("#ping").text();
      $("#ping").text(text + ".");
    });
  }
}

$(()=>{
  const app = new App();
  app.start();
});
