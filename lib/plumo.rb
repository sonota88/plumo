# coding: utf-8

require 'webrick'
require 'cgi'
require 'json'
require 'pp'
require 'timeout'

class Plumo

  class NullLogger
    def <<(arg)
      ;
    end
  end

  def initialize(w, h, opts={})
    @w = w
    @h = h
    @session_id = nil

    default_opts = {
      port: 9080,
      num_deq_max: 100
    }

    @opts = default_opts.merge(opts)

    @q = Thread::SizedQueue.new(100)

    @close_q = Thread::Queue.new

    @status = :starting
    @server = nil
    @server_thread = nil
  end

  def enq_reset
    @q.clear
    @q.enq({
      type: :reset,
      payload: {
        w: "#{@w}px",
        h: "#{@h}px"
      }
    })
  end

  def handle_comet(req)
    qsize = @q.size

    params = CGI.parse(req.body)
    session_id = params["sessionid"][0]

    if session_id != @session_id
      @session_id = session_id
      enq_reset
    end

    events = []
    if @q.empty?
      events << @q.deq
    end

    loop do
      break if @q.empty?
      break if @opts[:num_deq_max] <= events.size

      events << @q.deq
    end

    {
      events: events,
      qsize: qsize,
    }
  end

  def start
    @status = :running

    logger_access = NullLogger.new

    @server = WEBrick::HTTPServer.new(
      DocumentRoot: File.join(__dir__, "plumo/public"),
      BindAddress: '127.0.0.1',
      Port: @opts[:port],
      AccessLog: [
        [logger_access, WEBrick::AccessLog::COMMON_LOG_FORMAT],
        [logger_access, WEBrick::AccessLog::REFERER_LOG_FORMAT]
      ]
    )

    @server.mount_proc("/ping") do |req, res|
      res.content_type = "application/json"
      res.body = JSON.generate({ status: @status })
    end

    @server.mount_proc("/close") do |req, res|
      @close_q.enq 1

      res.content_type = "application/json"
      res.body = "{}"
    end

    @server.mount_proc("/comet") do |req, res|
      res_data = handle_comet(req)

      res.content_type = "application/json"
      res.body = JSON.generate(res_data)
    end

    Signal.trap(:INT) do
      @status = :stop

      @q.clear
      @q.enq({ type: :close })

      begin
        Timeout.timeout(1) do
          @close_q.deq
        end
      rescue Timeout::Error
        $stderr.puts "timed out"
      end

      exit
    end

    @server_thread = Thread.new do
      @server.start
    end

    sleep 0.1
  end

  def draw(*cmds)
    if @status == :running
      @q.enq({
        type: :cmds,
        cmds: cmds
      })
    end

    nil
  end

  def color(color)
    draw(
      [:strokeStyle, color],
      [:fillStyle, color]
    )
  end

  def line(x0, y0, x1, y1, style={})
    cmds = []

    if style.key?(:color)
      cmds << [:strokeStyle, style[:color]]
    end

    cmds += [
      [:beginPath],
      [:moveTo, x0, y0],
      [:lineTo, x1, y1],
      [:stroke]
    ]

    draw(*cmds)
  end

  def stroke_rect(x, y, w, h, style={})
    cmds = []

    if style.key?(:color)
      cmds << [:strokeStyle, style[:color]]
    end

    cmds += [
      [:strokeRect, x, y, w, h]
    ]

    draw(*cmds)
  end

  def fill_rect(x, y, w, h, style={})
    cmds = []

    if style.key?(:color)
      cmds << [:fillStyle, style[:color]]
    end

    cmds += [
      [:beginPath],
      [:fillRect, x, y, w, h],
    ]

    draw(*cmds)
  end

  def stroke_circle(x, y, r, style={})
    cmds = []

    if style.key?(:color)
      cmds << [:strokeStyle, style[:color]]
    end

    cmds += [
      [:beginPath],
      [:arc,
       x, y,
       r,
       0, Math::PI * 2, false
      ],
      [:stroke]
    ]

    draw(*cmds)
  end

  def fill_circle(x, y, r, style={})
    cmds = []

    if style.key?(:color)
      cmds << [:fillStyle, style[:color]]
    end

    cmds += [
      [:beginPath],
      [:arc,
       x, y,
       r,
       0, Math::PI * 2, false
      ],
      [:fill]
    ]

    draw(*cmds)
  end
end
