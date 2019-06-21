[![Build Status](https://travis-ci.org/ctxswitch/kafkat.png?branch=master)](https://travis-ci.org/ctxswitch/kafkat)
[![Coverage Status](https://coveralls.io/repos/github/ctxswitch/kafkat/badge.svg?branch=master)](https://coveralls.io/github/ctxswitch/kafkat?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/7fb0ef80004b68e1373c/maintainability)](https://codeclimate.com/github/ctxswitch/kafkat/maintainability)

kafkat
======

Simplified command-line administration for Kafka brokers.

## Contact 
**Let us know!** If you fork this, or if you use it, or if it helps in anyway, we'd love to hear from you! opensource@airbnb.com

## License & Attributions
This project is released under the Apache License Version 2.0 (APLv2).

## How to release

- update the version number in `lib/kafkat/version.rb`
- execute `bundle exec rake release`


## Usage

* Install the gem.

```
gem install kafkat
```

* Create a new configuration file to match your deployment.

```
{
  "kafka_path": "/srv/kafka/kafka_2.10-0.8.1.1",
  "log_path": "/mnt/kafka-logs",
  "zk_path": "zk0.foo.ca:2181,zk1.foo.ca:2181,zk2.foo.ca:2181/kafka"
}
```

Kafkat searches for this file in multiple places in the following order:

1. .kafkat.json
2. ~/.kafkat.json
3. /etc/kafkat/config.json

* At any time, you can run `kafkat` to get a list of available commands and their arguments.

```
$ kafkat
kafkat: Simplified command-line administration for Kafka brokers

kafkat SUB-COMMAND (options)
    -c, --config CONFIG              Configuration file to use.
    -k, --kafka-path PATH            Where kafka has been installed.
    -l, --log-path PATH              Where topic data is stored.
    -z, --zookeeper PATH             The zookeeper path string in the form <host>:<port>,...
    -h, --help                       Show this message

Available subcommands: (for details, kafkat SUB-COMMAND --help)

-- BROKER COMMANDS --
kafkat broker clean
kafkat broker drain BROKER
kafkat broker list
kafkat broker resign BROKER

-- CLUSTER COMMANDS --
kafkat cluster restart

-- TOPIC COMMANDS --
kafkat topic alter reassign TOPIC
kafkat topic alter replication-factor TOPIC
kafkat topic describe TOPIC
kafkat topic elect TOPIC
kafkat topic list
kafkat topic verify
  
```

## Important Note

The gem needs read/write access to the Kafka log directory for some operations (clean indexes).


