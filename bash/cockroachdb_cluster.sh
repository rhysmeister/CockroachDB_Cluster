# Download and set PATH
wget https://binaries.cockroachdb.com/cockroach-latest.darwin-10.9-amd64.tgz
tar xvzf cockroach-latest.darwin-10.9-amd64.tgz
PATH="$PATH:/Users/rhys1/cockroach-latest.darwin-10.9-amd64";
export PATH;

# Setup the cluster nodes
mkdir -p cockroach_cluster_tmp/node1;
mkdir -p cockroach_cluster_tmp/node2;
mkdir -p cockroach_cluster_tmp/node3;
mkdir -p cockroach_cluster_tmp/node4;
mkdir -p cockroach_cluster_tmp/node5;
cd cockroach_cluster_tmp
cockroach start --background --cache=50M --store=./node1;
cockroach start --background --cache=50M --store=./node2 --port=26258 --http-port=8081 --join=localhost:26257;
cockroach start --background --cache=50M --store=./node3 --port=26259 --http-port=8082 --join=localhost:26257;
cockroach start --background --cache=50M --store=./node4 --port=26260 --http-port=8083 --join=localhost:26257;
cockroach start --background --cache=50M --store=./node5 --port=26261 --http-port=8084 --join=localhost:26257;

# Access web console at http://localhost:8084

# Command-line access
# cockroach sql;
# root@:26257/> CREATE DATABASE rhys;
# root@:26257/> SHOW DATABASES;
# root@:26257/> CREATE TABLE rhys.test (id SERIAL PRIMARY KEY, text VARCHAR(100) NOT NULL);
# root@:26257/> INSERT INTO rhys.test(text) VALUES ('Hello World');
# root@:26257/> SELECT * FROM rhys.test;
# Looks like CockroachDB does some type translation...
# CREATE TABLE test (
# 	id INT NOT NULL DEFAULT unique_rowid(),
# 	text STRING(100) NOT NULL,
# 	CONSTRAINT "primary" PRIMARY KEY (id ASC),
# 	FAMILY "primary" (id, text)
# )



