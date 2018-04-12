module FiberedWorker
  class MainLoop
    attr_accessor :pid, :interval
    attr_reader   :handlers, :timers

    def initialize(opt={})
      @interval = opt[:interval] || nil # by msec
      @pid = opt[:pid] || nil
      @handlers = []
      @timers = []
    end

    def new_watchdog
      target = self.pid
      unless target
        raise "Target pid must be set"
      end

      return Fiber.new do
        keep = true
        while keep
          ret = Process.waitpid2(target, Process::WNOHANG)
          if ret
            keep = false
          end
          Fiber.yield ret
        end
      end
    end

    def register_handler(signo, once=true, &blk)
      FiberedWorker.register_internal_handler(signo)
      self.handlers << Fiber.new do
        keep = true
        while keep
          ret = nil
          if FiberedWorker.signaled_nonblock?(signo)
            ret = blk.call(signo)
            if once
              keep = false
            end
          end
          Fiber.yield ret
        end
      end
    end

    def register_timer(signo, start, interval=0, &blk)
      register_handler(signo, (interval == 0), &blk)
      self.timers << [
        FiberedWorker::Timer.new(signo),
        [start, interval]
      ]
    end

    def run
      watchdog = new_watchdog
      self.timers.each do |data|
        timer = data[0]
        args = data[1]
        timer.start(args[0], args[1])
      end

      before = Time.now
      until ret = watchdog.resume
        self.handlers.each do |fib|
          if fib.alive?
            fib.resume
          end
        end

        if @interval
          # use mruby-sleep's usleep
          Sleep.usleep @interval * 1000
        end
      end

      return ret
    end
  end
end
