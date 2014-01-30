class SendmailParser
  def initialize(conf)
    @base_regexp   = /^(?<time>\w{3} \d+ \d+:\d+:\d+) (?<host>[^ ]+) (?<procowner>[^\[]+)\[(?<procid>\d+)\]: (?<mid>[^ ]+): (?<entry>(?<type>[^=]+).+)$/
  end

  def to_parser(entry)
    unless entry.include?("stat=Sent")
      return :queued, nil
    end
    record = {}
    entry.split(", ").each {|param|
      key, val = param.split("=")
      record[key] = val
    }
    record["to"] = record["to"].split(",")

    if record.has_key?("relay")
      record["relay"] = relay_parser(record["relay"])
    end
    return :sent, record
  end

  def from_parser(entry)
    record = {}
    entry.split(", ").each {|param|
      key, val = param.split("=")
      record[key] = val
    }
    if record.has_key?("relay")
      record["relay"] = relay_parser(record["relay"])
    end
    return :from, record
  end

  def trim_bracket(val)
    val[1..-2]
  end
  def relay_parser(relays)
    relay_host = nil
    relay_ip   = nil
    relays.split(" ").each {|relay|
      if relay.index("[") == 0
        return {"ip" => trim_bracket(relay), "host" => relay_host}
      else
        relay_host = relay
      end
    }
    return {"ip" => relay_ip, "host" => relay_host}
  end

  def parse(value)
    m = @base_regexp.match(value)
    unless m
      # $log.warn "sendmail: pattern not match: #{value.inspect}"
      return nil, nil, nil, nil
    end

    type = nil
    logtype = m["type"]
    entry = m["entry"]

    case logtype
    when "from"
      type, record = from_parser(entry)
    when "to"
      type, record = to_parser(entry)
      if type == :queued
        return nil, nil, nil, nil
      end
    else
      # not match
      return nil, nil, nil, nil
    end

    mid = m["mid"]
    time = Time.parse(m["time"]) || Fluent::Engine.now

    return mid, type, time, record
  end
end
