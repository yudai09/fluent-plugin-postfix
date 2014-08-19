# Fluent::Plugin::Postfix

Fluentd plugin to parse and merge postfix syslog.
This plugin is a clone of fluent-plugin-sendmail written by muddydixon.

## Configuration

```
<source>
  type postfix
  path /var/log/maillog
  pos_file /var/log/td-agent/mail.log.pos
  tag postfixlog
</source>
```

This plugin emit record like below:

```
2014-08-19T09:25:10Z    postfixlog
{
	"client":"localhost[127.0.0.1]",
	"from":"<localpart@example.com>",
	"authid":"user",
	"to":[
		{
		"recipient":"<grandeur09@gmail.com>",
		"relay":"gmail-smtp-in.l.google.com[74.125.23.27]:25",
		"status":["sent","250 2.0.0 OK 1408440312 ar2si14557666pbc.249 - gsmtp"]
		},
		{
		"recipient":"<localpart@example.com>",
		"relay":"none",
		"status":["deferred","connect to example.com[93.184.216.119]:25: Connection timed out"]
		}
	]
}
```

## TODO

Write test code
(This plugin is worked on CentOS release 6.5, fluentd 0.10.50, and Postfix 2.6.6.)

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
