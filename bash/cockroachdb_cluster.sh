# Create array containing ports of cockroachdb instances
function cc_port_list()
{
	PORT_LIST[0]=26257;
	PORT_LIST[1]=26258;
	PORT_LIST[2]=26259;
	PORT_LIST[3]=26260;
	PORT_LIST[4]=26261;
}

# Download and set PATH if needed
cc_dl_set_path()
{
	command -v cockroach >/dev/null 2>&1 || {
		cd;
		[ -d "$HOME/cockroach-latest.darwin-10.9-amd64/" ] && PATH="$PATH:$HOME/cockroach-latest.darwin-10.9-amd64" && export PATH || {
			wget https://binaries.cockroachdb.com/cockroach-latest.darwin-10.9-amd64.tgz
			tar xvzf cockroach-latest.darwin-10.9-amd64.tgz;
			PATH="$PATH:/$HOME/cockroach-latest.darwin-10.9-amd64" && export PATH;
		}
		
	}
}

# Setup the cluster nodes
function cc_mkdirs()
{
	cd
	mkdir -p cockroach_cluster_tmp/node1;
	mkdir -p cockroach_cluster_tmp/node2;
	mkdir -p cockroach_cluster_tmp/node3;
	mkdir -p cockroach_cluster_tmp/node4;
	mkdir -p cockroach_cluster_tmp/node5;
}

function cc_start_cluster_nodes()
{
	cd "$HOME/cockroach_cluster_tmp"
	cockroach start --background --cache=50M --store=./node1;
	cockroach start --background --cache=50M --store=./node2 --port=26258 --http-port=8081 --join=localhost:26257;
	cockroach start --background --cache=50M --store=./node3 --port=26259 --http-port=8082 --join=localhost:26257;
	cockroach start --background --cache=50M --store=./node4 --port=26260 --http-port=8083 --join=localhost:26257;
	cockroach start --background --cache=50M --store=./node5 --port=26261 --http-port=8084 --join=localhost:26257;
}

# Needs xdg-utils install, OS X - sudo port install xdg-utils
# Access web console at http://localhost:8084
function cc_web_console()
{
	command -v xdg-open >/dev/null 2>&1 xdg-open && xdg-open http://localhost:8084 || echo "Problem laucnhing browser. Is xdg-open installed?";
}

# clean up (gets rid of all processes and data!)
function cc_murder_cluster()
{
	pgrep -x cockroach && {
		cockroach quit --port=26257;
		cockroach quit --port=26258;
		cockroach quit --port=26259;
		cockroach quit --port=26260;
		cockroach quit --port=26261;
	}
	cd;
	rm -Rf cockroach_cluster_tmp;
}

# create a db
function cc_create_db()
{
	cockroach sql --port 26257 --execute "CREATE DATABASE rhys";
	cockroach sql --port 26257 --execute "CREATE TABLE rhys.test (id SERIAL PRIMARY KEY, text VARCHAR(100) NOT NULL)";
}

# Inserts a random values into the rhys.test table
function cc_random_inserts()
{
	X=$[$RANDOM % 5];
	SELECTED_PORT=${PORT_LIST[$rand]}
	MD5=$(echo $RANDOM | md5);
	for i in {1..10000}; do 
		cockroach sql --port $SELECTED_PORT --execute "INSERT INTO rhys.test (text) VALUES ('"$MD5"')";
	done;
}

function cc_setup_cluster()
{
	cc_port_list;
	cc_dl_set_path;
	cc_mkdirs;
	cc_start_cluster_nodes;
	cc_web_console;
	cc_create_db;
	cc_random_inserts;
}

# TODO
# Authentication & Encryption https://www.cockroachlabs.com/docs/secure-a-cluster.html	

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

# Now let's see if all the nodes have correct data
# cockroach sql --port 26257 --execute "SELECT COUNT(*) FROM rhys.test";
# cockroach sql --port 26258 --execute "SELECT COUNT(*) FROM rhys.test";
# cockroach sql --port 26259 --execute "SELECT COUNT(*) FROM rhys.test";
# cockroach sql --port 26260 --execute "SELECT COUNT(*) FROM rhys.test";
# cockroach sql --port 26261 --execute "SELECT COUNT(*) FROM rhys.test";

# Insert into different nodes
# cockroach sql --port 26257 --execute "INSERT INTO rhys.test (text) VALUES ('Node 1')";
# cockroach sql --port 26258 --execute "INSERT INTO rhys.test (text) VALUES ('Node 2')";
# cockroach sql --port 26259 --execute "INSERT INTO rhys.test (text) VALUES ('Node 3')";
# cockroach sql --port 26260 --execute "INSERT INTO rhys.test (text) VALUES ('Node 4')";
# cockroach sql --port 26261 --execute "INSERT INTO rhys.test (text) VALUES ('Node 5')";

# Check counts again
# cockroach sql --port 26257 --execute "SELECT COUNT(*) FROM rhys.test";
# cockroach sql --port 26258 --execute "SELECT COUNT(*) FROM rhys.test";
# cockroach sql --port 26259 --execute "SELECT COUNT(*) FROM rhys.test";
# cockroach sql --port 26260 --execute "SELECT COUNT(*) FROM rhys.test";
# cockroach sql --port 26261 --execute "SELECT COUNT(*) FROM rhys.test";

# Check data on a couple of nodes
# rhysmacbook:cockroach_cluster_tmp rhys1$ cockroach sql --port 26261 --execute "SELECT * FROM rhys.test";
#+--------------------+-------------+
#|         id         |    text     |
#+--------------------+-------------+
#| 226950927534555137 | Hello World |
#| 226951064182259713 | Hello World |
#| 226951080098856961 | Hello World |
#| 226952456016003073 | Node 1      |
#| 226952456149368834 | Node 2      |
#| 226952456292663299 | Node 3      |
#| 226952456455684100 | Node 4      |
#| 226952456591376389 | Node 5      |
#+--------------------+-------------+
#(8 rows)
#rhysmacbook:cockroach_cluster_tmp rhys1$ cockroach sql --port 26260 --execute "SELECT * FROM rhys.test";
#+--------------------+-------------+
#|         id         |    text     |
#+--------------------+-------------+
#| 226950927534555137 | Hello World |
#| 226951064182259713 | Hello World |
#| 226951080098856961 | Hello World |
#| 226952456016003073 | Node 1      |
#| 226952456149368834 | Node 2      |
#| 226952456292663299 | Node 3      |
#| 226952456455684100 | Node 4      |
#| 226952456591376389 | Node 5      |
#+--------------------+-------------+
#(8 rows)





