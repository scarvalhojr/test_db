# Demo 1

## Create a 3-node cluster

* Show list of 3 VMs in Devprod1: `db01`, `db02`, `db03`.

* On db01, show how to install CockroachDB and start first node:

```
$ tar xzvf cockroach-v1.1.0.linux-amd64.tgz

$ sudo mv cockroach-v1.1.0.linux-amd64 /usr/local/bin

$ rm -rf cockroach-v1.1.0.linux-amd64*

$ cockroach version

$ cockroach start --insecure --port 9696 --http-port 8082 --locality=cloud=devprod1 --background
```

* Start other 2 nodes and let them join the cluster:

```
$ cockroach start --insecure --port 9696 --http-port 8082 --locality=cloud=devprod1 --join 10.140.65.70:9696 --background
```

* Show status of nodes:

```
$ cockroach node status --insecure --port 9696
```

## Upload data

* From laptop, configure client, connect to cluster and create `employees`
database:

```
$ ssh -nNT -L 9696:localhost:9696 10.140.65.70 &

$ export COCKROACH_HOST=localhost

$ export COCKROACH_PORT=9696

$ export COCKROACH_INSECURE=true

$ cockroach sql

> create database employees;

> show databases;
```

* From the laptop show import script and run it:

```
$ vi employees_import.sql

$ cockroach sql < employees_import.sql
```

* While data is loading, open admin web UI and show nodes joined, and the new
database:

http://10.140.65.70:8082

# Demo 2

## Create 3 nodes in another locality and join the cluster

* Before starting, creating index on `salaries` table:

```
CREATE INDEX ON salaries (to_date);
```

* Show list of 4 VMs in Devprod2: `db04`, `db05`, `db06`, `haproxy`.

* Start CockroachDB on new nodes and show data replication:

```
$ cockroach start --insecure --port 9696 --http-port 8082 --locality=cloud=devprod2 --join 10.140.65.70:9696 --background
```

## Add a load balancer and simulate client jobs

* Configure HAproxy to load balance across all CockroachDB nodes:

```
$ cockroach gen haproxy --insecure --host=10.140.65.70 --port=9696

# change bind port to 9696
$ vi haproxy.cfg

$ sudo haproxy -f haproxy.cfg
```

* Configure local client to talk to HAProxy instead and run simple query:

```
$ ssh -nNT -L 9696:localhost:9696 10.140.67.215 &

$ cockroach sql -e "SELECT count(*) FROM salaries WHERE to_date = '9999-01-01';"
```

* Start a script that runs SQL queries indefinetely:

```
$ ./raise_salary.sh
```

## Kill nodes and show client jobs are unaffected

* Kill a random node in Devprod1 and one in Devprod2:

```
$ ps -fC cockroach

$ kill -9 xyz
```
* Show HAProxy marked nodes as down.

* Show client job still running.

* Show number of under-replicated ranges going up and down.

* Bring node back up in Devprod2:

```
$ cockroach start --insecure --port 9696 --http-port 8082 --locality=cloud=devprod2 --join 10.140.65.70:9696 --background
```

## Move data across while keeping active jobs alive

* Check replication settings for the default zone:

```
$ cockroach zone get .default --insecure --port 9696
```

* Force all data to move to Devprod2:

```
echo 'constraints: [+cloud=devprod2]' | cockroach zone set .default --insecure --port 9696 -f -
```

* Check new replication settings for the default zone:

```
$ cockroach zone get .default --insecure --port 9696
```

* Show replication of ranges moving to nodes in Devprod2:

http://10.140.67.212:8082

* Decommission dead node in Devprod1:

```
$ cockroach node decommission 3 --insecure --port 9696 --wait=live
```

* Decommission other surviving nodes in Devprod1:

```
$ cockroach quit --insecure --port 9696 --decommission
```

* Show running jobs unaffected.
