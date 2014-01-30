# Fluent::Plugin::Sendmail

Fluentd plugin to parse and merge sendmail syslog.

## Configuration

```
<source>
  type sendmail
  path ./syslog.log
  pos_file ./syslog.log.pos
  tag sendmail
</source>
```

This plugin emit record like below:

```
2014-01-10 01:00:01 +0900 sendmail: {
  "from":"<sample@nifty.com>",
  "relay":{"ip":"111.111.111.111","host":null},
  "count":"6",
  "msgid":"<201401091559.ajcwij92gj4sdf@example.com>",
  "popid":null,
  "authid":"1004093333",
  "to":[
    {"to":["<sample1@example1.com>"],"relay":{"ip":"111.111.110.111","host":"example1.com."}},
    {"to":["<sample2@example2.com>","<sample3@example2.com>"],"relay":{"ip":"111.111.110.112","host":null}},
    {"to":["<sample4@example3.com>"],"relay":{"ip":"111.111.110.113","host":"example3.com."}}
  ]
}
```

## ChangeLog

See [CHANGELOG.md](CHANGELOG.md) for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2014 muddydixon. See [LICENSE](LICENSE) for details.
