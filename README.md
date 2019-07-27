[![Build Status](https://travis-ci.org/ctxswitch/kafkat.png?branch=master)](https://travis-ci.org/ctxswitch/kafkat)
[![Coverage Status](https://coveralls.io/repos/github/ctxswitch/kafkat/badge.svg?branch=master)](https://coveralls.io/github/ctxswitch/kafkat?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/7fb0ef80004b68e1373c/maintainability)](https://codeclimate.com/github/ctxswitch/kafkat/maintainability)

# KafkaT

Simplified command-line administration for Kafka brokers.  This is a fork of [kafkat](https://github.com/airbnb/kafkat) originally released by the amazing developers at [Airbnb](opensource@airbnb.com).  The project was largely abandoned, but it's usefulness lives on.

## Usage

* Install the gem.

```
gem install kafkat-ctx
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

1. `.kafkat.json`
2. `~/.kafkat.json`
3. `/etc/kafkat/config.json`

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
kafkat topic create TOPIC
kafkat topic delete TOPIC
kafkat topic describe TOPIC
kafkat topic elect TOPIC
kafkat topic list
kafkat topic verify
  
```

***Note: Kafkat needs read/write access to the Kafka log directory for some operations (clean indexes).***

## How to contribute

Contributions are always welcome.  Please see the [guide for contributing](CONTRIBUTING.md) that is included in the repository.

## How to release

* update the version number in `lib/kafkat/version.rb`
* execute `bundle exec rake release`

## License & Attributions
This project is released under the Apache License Version 2.0 (APLv2).
