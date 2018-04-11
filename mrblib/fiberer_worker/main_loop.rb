module FiberedWorker
  class MainLoop
    attr_accessor :pid
    attr_reader   :handlers, :timers

    def initialize
      @handlers = []
      @timers = []
    end

    def new_watchdog
      target = self.pid
      return Fiber.new do
        ret = nil
        quit = false
        until quit
          ret = Process.waitpid2(target, Process::WNOHANG)
          if ret
            break
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
      until watchdog.resume
        # infinite loop to wait
        after = Time.now
        if after.to_i - before.to_i >= 1
          puts "[#{Process.pid}] nonblocking run: #{after.inspect}"
          before = after
        end

        self.handlers.each do |fib|
          if fib.alive?
            fib.resume
          end
        end
      end
    end
  end
end
