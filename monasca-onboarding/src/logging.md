## Monasca Log API (`monasca-log-api`)

![Monasca Logging 1](img/architecture_logging1.Png)

<!--

Just like with metrics we have an API service as the center piece.

-->

## Monasca Log API (`monasca-log-api`)

* Repository

  * https://github.com/openstack/monasca-log-api

* Purpose

  * Receives log messages from agents

* Development Information

  * Repository contains logging specific parts of documentation

  * Contributions may entail changes to `monasca-common`

<!--

You will find its sources in the [monasca-log-api](https://github.com/openstack/monasca-log-api)
repository.

The Log API receives log messages from agents and forwards them for further processing.

The `monasca-log-api` repository holds the sources for all logging specific documentation.

If you modify `monasca-log-api`, you may have to use `monasca-common` as well.

-->

## Monasca Log API (`monasca-log-api`)

![Monasca Logging 1](img/architecture_logging1.Png)

## Log Agents

![Monasca Logging 2](img/architecture_logging2.Png)

## Log Agents

* Repository: N/A

* Purpose: Send logs

* Not part of Monasca: [logstash](https://www.elastic.co/de/products/logstash),
  [beaver](https://github.com/python-beaver) or
  [fluentd](https://www.fluentd.org/) with Monasca output plugin.

<!--

On the input side we have agents again, which send the log messages to the API.

Unlike the metric agent, these are not part of Monasca, though. You can use
either [logstash](https://www.elastic.co/de/products/logstash) or
[beaver](https://github.com/python-beaver) with a Monasca output plugin.

We currently recommend logstash because the Monasca plugin for Beaver has not
been merged upstream and Beaver appears to be unmaintained.

-->

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
the message queue and counts the occurences of log levels, such as `INFO`,
`WARN` or `DEBUG`. These statistics are then published to Kafka as metrics for
consumption on the metrics side of Monasca.

-->

## Log Transformer

![Monasca Logging 5](img/architecture_logging5.Png)


<!--

The next one is monasca-log-transformer. This service parses log messages and
turns various metadata such as the time stamp or log level into proper JSON
attributes. The parsed log message is then republished on the Kafka message
queue.

-->

## Log Persister

![Monasca Logging 6](img/architecture_logging6.Png)

<!--

The final step in the log processing pipeline is the log persister which writes
the transformed log messages to Elasticsearch.

-->

## Elasticsearch

![Monasca Logging 7](img/architecture_logging7.Png)

<!--

Not much to be said about elasticsearch. This is where we store our logs. We
index them by tenant to support multi tenancy. Since Elasticsearch does not
support Keystone authentication we also need some sort of Keystone enabled
frontend.

-->


## Kibana

![Monasca Logging 8](img/architecture_logging8.Png)

<!--

That's what we've got Kibana with `monasca-kibana-plugin` for. That one does
support Keystone authentication (it uses the Keystone auth token header).

-->

## `monasca-kibana-plugin`

* Repository

  * https://github.com/openstack/monasca-kibana-plugin

## Monasca Logging

![Monasca Logging 9](img/architecture_logging9.Png)


<!--

For the future we are planning on allowing the retrieval of logs through
`monasca-log-api` as well. That way any third party application that supports
Keystone authentication will then be able to retrieve log data.

-->
