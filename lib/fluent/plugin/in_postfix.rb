# -*- coding: utf-8 -*-

require 'fluent/plugin/in_tail'

class Fluent::PostfixInput < Fluent::TailInput
  Fluent::Plugin.register_input('postfix', self)
  require_relative 'postfixparser'
  require 'pathname'
  config_param :types, :string, :default => 'from,sent,queued'
  
  def initialize
    super
    @transactions = {}
  end

  def configure_parser(conf)
    @parser = PostfixParser.new(conf)
  end

  def receive_lines(lines)
    es = Fluent::MultiEventStream.new
    lines.each {|line|
      begin
        line.chomp!  # remove \n
        qid, type, time, record = parse_line(line)
        if qid && type && time && record
          if @transactions.has_key?(qid)
            # last line.
            if type == :ready
              @status = :ready
              log = @transactions[qid]
              es.add(log.time, log.record)
              @transactions.delete(qid)
            else
              @transactions[qid].merge(type, time, record)
            end
          # new
          elsif qid && type && time && record
            @transactions[qid] = PostfixLog.new(time)
            @transactions[qid].merge(type, time, record)
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

class PostfixLog
  attr_reader :status
  attr_reader :time
  
  def initialize(time)
    @client = ""
    @status = :init
    @time = time
    @tos  = {}
    @from = ""
    @authid = ""
  end

  def record
    return {
      "client" => @client,
      "from" => @from,
      "authid" => @authid,
      "to" => @tos.map {|name, to|
        {
          "recipient" => to["to"],
          "relay" => to["relay"],
          "status" => to["status"]
        }
      }
    }
  end

  def merge(type, time, record)
    case type
    when :sent, :deferred
      @tos[record["to"]] = record
    when :from
      @from = record["from"];
    when :auth
      @authid = record["sasl_username"];
      @client = record["client"];
    when :no_auth
      @client = record["client"];
    end
  end
end
