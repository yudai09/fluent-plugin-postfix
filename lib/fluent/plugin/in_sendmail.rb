class Fluent::SendmailInput < Fluent::TailInput
  Fluent::Plugin.register_input('sendmail', self)

  require_relative 'sendmailparser'
  require 'pathname'

  config_param :types, :string, :default => 'from,sent'

  def initialize
    super
    @transactions = {}
  end

  def configure_parser(conf)
    @parser = SendmailParser.new(conf)
  end

  def receive_lines(lines)
    es = Fluent::MultiEventStream.new
    lines.each {|line|
      begin
        line.chomp!  # remove \n
        mid, type, time, record = parse_line(line)

        if mid && type && time && record
          if @transactions.has_key?(mid)
            @transactions[mid].merge(type, time, record)
          elsif mid && type == :from && time && record
            @transactions[mid] = SendmailLog.new(time, record)
          end

          if @transactions[mid].status == :ready
            log = @transactions[mid]
            es.add(log.time, log.record)
            @transactions.delete(mid)
            log.destroy
          end
        end
      rescue
        $log.warn line.dump, :error=>$!.to_s
        $log.debug_backtrace
      end
    }

    unless es.empty?
      begin
        Fluent::Engine.emit_stream(@tag, es)
      rescue
        # ignore errors. Engine shows logs and backtraces.
      end
    end
  end
end

class SendmailLog
  attr_reader :status
  attr_reader :time
  def initialize(time, record)
    @status = :init
    @time = time
    @tos  = {}
    @from = record
    @count = record["nrcpts"].to_i
  end

  def record
    return {
      "from" => @from["from"],
      "relay" => @from["relay"],
      "count" => @from["nrcpts"],
      "msgid" => @from["msgid"],
      "popid" => @from["popid"],
      "authid" => @from["authid"],
      "to" => @tos.map {|name, to|
        {
          "to" => to["to"],
          "relay" => to["relay"]
        }
      }
    }
  end

  def merge(type, time, record)
    if type == :sent
      @count = @count - record["to"].size
      @tos[record["relay"]["ip"]] = record
      if @count == 0
        @status = :ready
      end
    end
  end
end
