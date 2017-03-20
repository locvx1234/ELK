# Schedule report for Kibana

### Install tools :

##### Git : 

	# apt-get update
	# apt-get install git 
	
##### Docker : 

	# curl -sSL https://get.docker.com/ | sh


Clone git Snapshot

	# git clone https://github.com/locvx1234/snapshot.git
	
Config : 
	
	# cd snapshot
	# vi app/config/server.json 
 
 
- os_type - For selection of phantomjs binary - linux / mac
- type - Supports Kibana & Grafana
- kibana: true / false
- grafana: true / false
- request_headers: false / JSON object
- "request_headers": { "Accept": "application/json", "Authorization": "Bearer " }
- dashboard_url - Should be like this:
- http://{YOUR_KIBANA_HOST}:{YOUR_KIBANA_PORT}/app/kibana#/dashboard/
- http://{YOUR_GRAFANA_HOST}:{YOUR_GRAFANA_PORT}/dashboard/
- dashboards_list_url - Should be like this:
- http://{YOUR_KIBANA_HOST}:{YOUR_KIBANA_PORT}/elasticsearch/.kibana/dashboard/_search?size=100
- http://{YOUR_GRAFANA_HOST}:{YOUR_GRAFANA_PORT}/api/search
- basic_auth_users - Basic authentication list of users

Examplpe : 

	{
	  "app_port": 8080,
	  "app_dir": "/deploy",
	  "os_type": "linux",
	  "phantomjs": {
		"wait_seconds": "30"
	  },
	  "type": {
		"kibana": true,
		"grafana": false
	  },
	  "request_headers": false,
	  "dashboard_url": "http://192.168.169.161:5601/app/kibana#/dashboard/",  
	  "dashboards_list_url": "http://192.168.169.161:5601/elasticsearch/.kibana/dashboard/_search?size=100",
	  "basic_auth_users": [
		{"user": "locvu", "password": "admin"},
		{"user": "u2", "password": "p2"}
	  ]
	}

Save and quit 

### Start Docker Instance

	docker build -t parvez/snapshot .
	docker run -p 49160:8080 -d parvez/snapshot
	
### Access with username and password in config file

<img src="https://raw.githubusercontent.com/locvx1234/ELK/master/images/Snapshot_login.png">


### New snapshot 

<img src="https://raw.githubusercontent.com/locvx1234/ELK/master/images/Snapshot_new.png">

### Result

<img src="https://raw.githubusercontent.com/locvx1234/ELK/master/images/Snapshot_result.png">
 
