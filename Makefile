# TODO: APP_HOMEとAPP_DIRECTORYなど、埋める
APP_HOME:=/home/isucon/webapp
APP_DIRECTORY:=$(APP_HOME)/go
APP_BUILD_COMMAND:=make
SYSTEMCTL_APP:=isuports.service

# TODO: nginxのファイルの場所を指定する
NGINX_CONF:=$(APP_HOME)/nginx/nginx.conf
NGINX_APP_CONF:=$(APP_HOME)/nginx/isuports.conf
NGINX_LOG:=/var/log/nginx/access.log
NGINX_ERR_LOG:=/var/log/nginx/error.log
ALP_FORMAT:=/image/\w+,/posts/\d+,/@\w+

# TODO: mysqlのコンフィグファイルの場所を指定する
MYSQL_CONF:=$(APP_HOME)/mysql/mysqld.cnf $(APP_HOME)/mysql/mysql.cnf
MYSQL_LOG:=/var/log/mysql/mysql-slow.log

# TODO: IPを埋める
BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
SERVER1_IP:=52.199.19.177
SERVER2_IP:=18.179.190.28
SERVER3_IP:=35.79.252.177
SERVER1:=isucon@$(SERVER1_IP)
SERVER2:=isucon@$(SERVER2_IP)
SERVER3:=isucon@$(SERVER3_IP)

SLACK_CHANNEL=isucon11-log
SLACKCAT_RAW_CMD=slackcat -c $(SLACK_CHANNEL)

SSH_COMMAND=ssh -t

all: build

.PHONY: build build-server1 build-server2 build-server3 build-app build-nginx build-mysql
build:
	$(SSH_COMMAND) $(SERVER1) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make build-server1 BRANCH:=$(BRANCH)'
	$(SSH_COMMAND) $(SERVER2) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make build-server2 BRANCH:=$(BRANCH)'
	$(SSH_COMMAND) $(SERVER3) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make build-server3 BRANCH:=$(BRANCH)'

# Set app, mysql and nginx.
build-server1: build-app build-nginx build-mysql
build-server2: build-app
build-server3: build-app

DATE=$(shell date '+%T')

build-app:
	sudo systemctl stop $(SYSTEMCTL_APP)
	cd $(APP_DIRECTORY) && $(APP_BUILD_COMMAND)
	sudo systemctl restart $(SYSTEMCTL_APP)

build-nginx:
	-sudo cp -f $(NGINX_LOG) /tmp/nginx_access_$(shell echo $(BRANCH) | sed -e "s@/@-@g")_latest.log
	-sudo mv $(NGINX_LOG) /tmp/nginx_access_$(DATE).log
	-sudo mv $(NGINX_ERR_LOG) /tmp/nginx_error_$(DATE).log
	sudo cp $(NGINX_CONF) /etc/nginx/
	sudo cp $(NGINX_APP_CONF) /etc/nginx/sites-enabled/
	sudo systemctl restart nginx.service

build-mysql:
	-sudo mv $(MYSQL_LOG) /tmp/mysql_log_$(DATE).log
	sudo cp $(MYSQL_CONF) /etc/mysql/mysql.conf.d/
	sudo systemctl restart mysql.service


.PHONY: log log-server1 log-server2 log-server3 log-nginx log-nginx-diff log-mysql log-app echo-branch
log:
	$(SSH_COMMAND) $(SERVER1) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make log-server1'
	$(SSH_COMMAND) $(SERVER2) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make log-server2'
	$(SSH_COMMAND) $(SERVER3) 'cd $(APP_HOME) && source ~/.profile && git fetch -p && git checkout $(BRANCH) && git pull origin $(BRANCH) && make log-server3'

# Send log to slack
# Set log-nginx or log-mysql.
log-server1: echo-branch log-app log-mysql log-nginx log-nginx-diff
log-server2:
log-server3:

echo-branch:
	git rev-parse --abbrev-ref HEAD | $(SLACKCAT_RAW_CMD) -tee --stream

log-app:
	sudo systemctl status $(SYSTEMCTL_APP) | $(SLACKCAT_RAW_CMD)

log-nginx:
	sudo cat $(NGINX_LOG) | alp ltsv -m "$(ALP_FORMAT)" --sort=sum -r | $(SLACKCAT_RAW_CMD)
	-[ -s $(NGINX_ERR_LOG) ] && sudo cat $(NGINX_ERR_LOG) | $(SLACKCAT_RAW_CMD)

DEFAULT_BRANCH=$(shell git remote show origin | sed -n '/HEAD branch/s/.*: //p')
LAST_MERGED_BRANCH=$(shell git log --first-parent $(DEFAULT_BRANCH) --oneline --merges --pretty=format:"%s" -1 | sed -e "s;Merge pull request \\\#[0-9]\{1,\} from kyncon/;;g" -e "s;/;-;g")
log-nginx-diff:
	sudo alpdiff -m "$(ALP_FORMAT)" /tmp/nginx_access_$(LAST_MERGED_BRANCH)_latest.log $(NGINX_LOG) | $(SLACKCAT_RAW_CMD)

log-mysql:
	sudo mysqldumpslow -s t $(MYSQL_LOG) | $(SLACKCAT_RAW_CMD)


.PHONY: check
check:
	$(SSH_COMMAND) $(SERVER1) journalctl -u $(SYSTEMCTL_APP)
