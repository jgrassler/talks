# Monasca Log API (`monasca-log-api`)

![Monasca Logging 1](img/architecture_logging1.Png)

# Monasca Log API (`monasca-log-api`)

* Repository

  * https://github.com/openstack/monasca-log-api

* Purpose

  * Receives log messages from agents

* Development Information

  * Contains logging specific documentation
    https://docs.openstack.org/monasca-log-api/latest/

  * Contributions may entail changes to `monasca-common`

# Monasca Log API (`monasca-log-api`)

![Monasca Logging 1](img/architecture_logging1.Png)

## Log Agents

![Monasca Logging 2](img/architecture_logging2.Png)

## Log Agents

* Repository: N/A

* Purpose: Send logs

* Not part of Monasca: [logstash](https://www.elastic.co/de/products/logstash)
  or [beaver](https://github.com/python-beaver) with Monasca output plugin.

## Log Agents

![Monasca Logging 2](img/architecture_logging2.Png)

## Monasca Logging

![Monasca Logging 3](img/architecture_logging3.Png)

<!--

Again, we use the message queue to pass log messages to the processing pipeline
in the background. That processing pipeline consists of Logstash configurations
for various purposes.

-->

## Log Metrics

![Monasca Logging 4](img/architecture_logging4.Png)

<!--

The first of these is the log metrics service. It processes the log messages in
the queue and counts the occurences of log levels, such as `WARN`. These
statistics are then published to Kafka as metrics for consumption on the
metrics side of Monasca.

-->

## Monasca Logging

![Monasca Logging 5](img/architecture_logging5.Png)


## Monasca Logging

![Monasca Logging 6](img/architecture_logging6.Png)


## Monasca Logging

![Monasca Logging 7](img/architecture_logging7.Png)


## Monasca Logging

![Monasca Logging 8](img/architecture_logging8.Png)


## Monasca Logging

![Monasca Logging 9](img/architecture_logging9.Png)

