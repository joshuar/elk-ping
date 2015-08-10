# Introduction

This repo contains an example ELK stack used for ping (ICMP echo
request/reply) monitoring.  The concept was presented at a
[DevOps Brisbane Meetup](http://www.meetup.com/Devops-Brisbane/events/224090775/)
about ELK.  See also the slides on
[Speaker Deck](https://speakerdeck.com/elastic/you-know-for-pings).

It sets up an ELK stack in a single Docker container that then
monitors ping times to a specified list of hosts.  It defaults to
monitoring a bunch of public Google services (hopefully Google doesn't
mind a few extra pings).

# Requirements

- docker and docker-compose
- approx. 850MB for docker image

# Installation

In the top-level directory, run `docker-compose up`.  This should
first build an image called *elkping_elk* and then start a container
using this image called *elkping_elk_1*.  The Elasticsearch service
should be directly accessible on TCP ports 9200 and 9300 while a
Kibana instance should be running on TCP port 5601.

# Configuration

## FPing

For FPing targets, the list of hosts to ping can be found in
`logstash/fping.conf`.  Add hosts one per line to that file, Logstash
should pick the new hosts up automatically, no restart needed.  The
Logstash configuration for FPing can be found in
`logstash/conf.d/10-input-fping.conf` (input section) and
`logstash/conf.d/20-filter-fping.conf` (filter section).  Feel free to
adjust/change as necessary.

## EchoPing

No EchoPing targets (for faking ping via TCP) are configured by
default. To add a new EchoPing target, create a file
`logstash/config/conf.d/10-input-echoping.conf` with the contents:

```
input {
  exec {
         command   => "/usr/bin/echoping -v -h / -R <TARGET> | /usr/bin/grep -E '^TCP-Estimated RTT'"
         interval  => 60
         type      => "echoping"
         tags      => [ "echopinghttp" ]
         add_field => { "target_host" => "<TARGET>" }
  }
}
```

Where `<TARGET>` is the host to ping.  If the host only supports
HTTPS, add `-C` to the options. You'll need to add a full `exec` input
for each target you want to monitor with echoping.

You can adjust the Logstash filter for EchoPing targets in the
`logstash/config/conf.d/20-filter-echoping.conf` file.

## Kibana

Once you've configured your pings, you should open
[Kibana](http://localhost:5601), go to
[Settings->Objects](http://localhost:5601/#/settings/objects?_g=%28%29)
and *Import* the pre-configured search/visualisations/dashboard from
`kibana/export.json`.  Then, you should be able to go to the
[Pings Dashboard](http://localhost:5601/#/dashboard/Pings?_g=%28%29)
and watch the pretty graphs.

# Internals

## Docker Volumes

### Elasticsearch

- `elasticsearch/`
  - `config/`: Elasticsearch configuration directory
  containing `elasticsearch.vml` and `logging.yml`. Mounted as
  `/opt/elasticsearch/config` in the container.
  - `data/`: Elasticsearch data directory. Mounted as
  `/opt/elasticsearch/data` in the container.
  - `logs/`: Elasticsearch log directory. Mounted as
  `/opt/elasticsearch/logs` in the container
  - `plugins/`: Elasticsearch plugin directory.  Mounted as
  `/opt/elasticsearch/plugins` in the container.

## Logstash

- `logstash/`:
  - `config/`: Logstash configuration directory.  Mounted as
  `/etc/logstash` in the container.
  - `logs/`: Logstash log directory. Mounted as
  `/var/log/logstash` in the container.

## ELK Advanced Configuration

## Elasticsearch

Edit `elasticsearch/{elasticsearch,logging}.yml` and restart the
container.  Alternatively, you can issue API calls directly as per
usual via TCP port 9200.

Elasticsearch log files are viewable under `elasticsearch/logs/`.

## Logstash

All files under `logstash/config/conf.d/` will be read as Logstash
config snippets. Restart the container for Logstash to pick up the changes.

Logstash log files are viewable under `logstash/logs/`.
