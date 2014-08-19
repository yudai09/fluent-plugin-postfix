class PostfixParser
  
  def initialize(conf)
    @base_regexp = /^(?<time>\w+ \w+ \d+:\d+:\d+) (?<host>\w+) (?<daemon>[^ ]+): (?<queueid>\w+): (?<entry>(?<type>[^=]+).*)$/
    @to_status_regexp = /^(?<code>\w+) \((?<detail>.+)\)$/
  end

  def gen_key_value_pair(entry)
    record = {}
    entry.split(", ").each {|param|
      key, val = param.split("=")
      record[key] = val
    }
    return record
  end

  def to_status_parser(status)
    m = @to_status_regexp.match(status)
    unless m
      $log.warn "postfix: status code parse error: #{status}"
      return nil, nil
    end
    return m["code"], m["detail"]
  end
    
  def to_parser(entry)
    record = gen_key_value_pair(entry)
    if record["status"]
      record["status"] = to_status_parser(record["status"])
    end
    if entry.include?("status=sent")
      return :sent, record
    end
    if entry.include?("status=deferred")
      return :deferred, record
    end
    return nil, nil
  end

  def from_parser(entry)
    record = gen_key_value_pair(entry)
    return :from, record
  end

  def auth_parser(entry)
    record = gen_key_value_pair(entry)
    if ! entry.include?("sasl_username=")
      return :no_auth, record
    end
    return :auth, record
  end

  def parse(value)
    m = @base_regexp.match(value)
    unless m
      # $log.warn "postfix: pattern not match: #{value.inspect}"
      return nil, nil, nil, nil
    end
    type = nil
    logtype = m["type"]
    entry = m["entry"]
    qid = m["queueid"]
    time = Time.parse(m["time"]) || Fluent::Engine.now
    time = time.tv_sec 
    case logtype
    when "from"
      type, record = from_parser(entry)
    when "to"
      type, record = to_parser(entry)
      if type == nil
        return nil, nil, nil, nil
      end
    when "removed"
      type = :ready
      return qid, type, time, ""
    when "client"
      type, record = auth_parser(entry)
    else      
      # not match
      return nil, nil, nil, nil      
    end
    return qid, type, time, record
  end
end
