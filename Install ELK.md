<a name="head"></a>
# Cài đặt Elasticsearch, Logstash, and Kibana (ELK Stack) và Rsyslog trên Ubuntu 14.04 


<img src="http://i.imgur.com/24wToCQ.png">


## Mục lục

[1. Giới thiệu](#gioithieu)

[2. Mục tiêu ](#muctieu)

[3. Chuẩn bị ](#chuanbi)

[4. Install Java 8 ](#java8)

[5. Install Elasticsearch ](#Elasticsearch)

[6. Install Kibana ](#Kibana)

[7. Install Nginx ](#Nginx)

[8. Cấu hình server tập trung nhận dữ liệu ](#ReceiveData)

[9. Cấu hình rsyslog để gửi dữ liệu từ xa ](#rsyslogSendData)

[10. Định dạng JSON cho Log Data ](#JSON)

[11. Cấu hình server tập trung để gửi tới Logstash ](#sendToLogstash)

[12. Install Logstash ](#Logstash)

<a name="gioithieu"></a>
## 1. Giới thiệu 

Chúng ta sẽ cấu hình và cài đặt ELK trên Ubuntu 14.04 bao gồm Elasticsearch 5.1.1, Logstash 5.1.1 và Kibana 5.1.1 sử dụng bộ cài là các gói .deb. 

Rsyslog đóng vai trò là các shipper để chuyển log về Logstash.

Logstash là một công cụ mã nguồn mở để tập hợp, phân tích và lưu trữ log dùng cho các quá trình sau đó.

Kibana là một ứng dụng với giao diện web, sử dụng để tìm kiếm và xem các log từ Logstash mà đã đánh chỉ số. 

Cả hai công cụ là cơ sở cho Elasticsearch, công cụ sử dụng cho việc lưu trữ log 

Log tập trung // TODO

<a name="muctieu"></a>
## 2. Mục tiêu  

Cài đặt Logstash để thu thập log trên nhiều server và cài đặt Kibana để xem log.

ELK Stack của bài viết này cấu thành từ 4 thành phần chính :

	- Logstash : Các máy chủ Logstash xử lý các log đầu vào 
	- Elasticsearch : Lưu trữ tất cả các log.
	- Kibana : Giao diện web để tìm kiếm và phân tích log, chúng ta sẽ proxy qua Nginx.
	- Rsyslog : Đóng vai trò shipper, đã được cài đặt trên máy khách chủ, sẽ gửi log cho Logstash.
	

Chúng ta sẽ cài đặt 3 thành phần đầu, tạo thành ELK server.

<a name="chuanbi"></a>
## 3. Chuẩn bị

    OS: Ubuntu 14.04
    RAM: 4GB
    CPU: 2

Ngoài ra, có thể thêm một vài máy chủ khác để làm nguồn sinh ra log.

<a name="java8"></a>
## 4. Install Java 8

Elasticsearch và Logstash cần có Java, cho nên chúng ta sẽ cài đặt Java. Oracle Java 8 được Elasticsearch khuyên dùng.

	$ sudo add-apt-repository -y ppa:webupd8team/java
	$ sudo apt-get update
	$ sudo apt-get -y install oracle-java8-installer

<a name="Elasticsearch"></a>	
## 5. Install Elasticsearch

Bài viết này sử dụng gói `elasticsearch-5.1.1.deb` để cài đặt. 

	$ sudo dpkg -i path/to/file/elasticsearch-5.1.1.deb

Sửa file cấu hình 

	$ sudo vi /etc/elasticsearch/elasticsearch.yml
	
Bạn sẽ muốn hạn chế truy cập từ ngoài vào Elasticsearch của bạn, để người khác không thể đọc dữ liệu hoặc tắt Elasticsearch

Tìm dòng xác định `network.host` , `cluster.name`, `node.name`, `http.port`  và bỏ comment đi và thay giá trị là ip Elasticsearch server

	...
	network.host: ip_elasticsearch_server
	...
	cluster.name: my-application
	...
	node.name: node-1
	...
	http.port: 9200
	...
	
Lưu và thoát sau đó khởi động Elasticsearch:

	$ sudo service elasticsearch start

Sau đó chạy lệnh sau để start khi khởi động 

	$ sudo update-rc.d elasticsearch defaults 95 10
	
<a name="Kibana"></a>
## 6. Install Kibana

Sử dụng gói `kibana-5.1.1-amd64.deb` để cài đặt. 

	$ sudo dpkg -i path/to/file/kibana-5.1.1-amd64.deb

Sửa file cấu hình 

	$ sudo vi /etc/kibana/kibana.yml
	
Tìm tới dòng xác định `server.host` và thay thế bởi địa chỉ IP :

	server.host: "localhost"
	
Save và exit. Cài đặt này sẽ giúp cho kibana chỉ có thể truy cập từ localhost. Điều này tốt bởi vì chúng ta sẽ sử dụng Nginx proxy để truy cập từ bên ngoài.

Bật Kibana và start:

	$ sudo update-rc.d kibana defaults 96 9
	$ sudo service kibana start
	
Trước khi sử dụng Kibana, ta phải cài đặt một reverse proxy, Nginx


<a name="Nginx"></a>
## 7. Install Nginx

Bởi vì chúng ta cài đặt Kibana lắng nghe trên `localhost` nên ta phải cài đặt reverse proxy cho phép truy cập từ ngoài vào.

Cài đặt Nginx và Apache2-utils

	$ sudo apt-get install nginx apache2-utils
	
Sử dụng htpasswd  để tạo admin user, trong trường hợp này là "lockibana"

	$ sudo htpasswd -c /etc/nginx/htpasswd.users lockibana

Tài khoản này để đăng nhập trên giao diện web của Kibana

Cấu hình Nginx default server block

	$ sudo vi /etc/nginx/sites-available/default
	
Xóa nội dung file và thay thế bởi


	server {
        listen 80;

        server_name example.com;

        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/htpasswd.users;

        location / {
            proxy_pass http://localhost:5601;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;        
        }
    }

`server_name` phải đúng servername của bạn

Save và exit.

Với cấu hình này, Nginx sẽ kết nối trực tiếp tới Kibana, lắng nghe trên `localhost:5601`. Ngoài ra Nginx sử dụng file `htpasswd.users` mà chúng ta tạo ra trước đó để xác thực cơ bản.

Restart Nginx:

	$ sudo service nginx restart

<a name="ReceiveData"></a>
## 8. Cấu hình server tập trung nhận dữ liệu

Trên *rsyslog-server* , ta sửa đổi file cấu hình : 

	$ sudo vi /etc/rsyslog.conf
	
Bỏ comment ở dòng `$ModLoad imudp`, `$UDPServerRun 514` nếu muốn nhận log bằng UDP

Bỏ comment ở dòng `$ModLoad imtcp`, `$InputTCPServerRun 514` nếu muốn nhận log bằng TCP

File rsyslog.conf sau khi cấu hình:

	# provides UDP syslog reception
	$ModLoad imudp
	$UDPServerRun 514

	# provides TCP syslog reception
	$ModLoad imtcp
	$InputTCPServerRun 514
	
Restart rsyslog

	$ sudo service rsyslog restart
	
<a name="rsyslogSendData"></a>	
## 9. Cấu hình rsyslog để gửi dữ liệu từ xa 

Mặc định có 2 file trong `/etc/rsyslog.d`:

- 20-ufw.conf
- 50-default.conf

Trên `rsyslog-client`, edit file cấu hình default: 

	$ sudo vi /etc/rsyslog.d/50-default.conf
	
Chèn dòng yêu cầu gửi tất cả về ip_rsyslog_server sau section `log by facility`:

	*.*                         @private_ip_of_ryslog_server:514
	
Save và exit.

Dùng @ trước ip nếu sử dụng UDP

Dùng @@ trước ip nếu sử dụng TCP

Restart rsyslog

	$ sudo service rsyslog restart
	
<a name="JSON"></a>	
## 10. Định dạng JSON cho Log Data 

Elasticsearch yêu cầu tất cả các tài liệu nó nhận ở dạng JSON và rsyslog cung cấp điều này bằng template.

Trên *rsyslog-server*  tạo file cấu hình để định dạng thông điệp sang JSON trước khi gửi cho Logstash.

	$ sudo vi /etc/rsyslog.d/01-json-template.conf
	
Copy nội dung sau vào file :

	template(name="json-template"
	  type="list") {
		constant(value="{")
		  constant(value="\"@timestamp\":\"")     property(name="timereported" dateFormat="rfc3339")
		  constant(value="\",\"@version\":\"1")
		  constant(value="\",\"message\":\"")     property(name="msg" format="json")
		  constant(value="\",\"sysloghost\":\"")  property(name="hostname")
		  constant(value="\",\"severity\":\"")    property(name="syslogseverity-text")
		  constant(value="\",\"facility\":\"")    property(name="syslogfacility-text")
		  constant(value="\",\"programname\":\"") property(name="programname")
		  constant(value="\",\"procid\":\"")      property(name="procid")
		constant(value="\"}\n")
	}

Một JSON message sẽ có dạng :

	{
	  "@timestamp" : "2015-11-18T18:45:00Z",
	  "@version" : "1",
	  "message" : "Your syslog message here",
	  "sysloghost" : "hostname.example.com",
	  "severity" : "info",
	  "facility" : "daemon",
	  "programname" : "my_program",
	  "procid" : "1234"
	}

<a name="sendToLogstash"></a>	
## 11. Cấu hình server tập trung để gửi tới Logstash

Trên `rsyslog-server`, tạo file `/etc/rsyslog.d/60-output.conf` với nội dung:

	# This line sends all lines to defined IP address at port 10514,
	# using the "json-template" format template

	*.*                         @private_ip_logstash:10514;json-template
	
Save và exit.

<a name="Logstash"></a>
## 12. Install Logstash

Sử dụng gói `logstash-5.1.1.deb` để cài đặt. 

	$ sudo dpkg -i path/to/file/logstash-5.1.1.deb

File cấu hình Logstash theo định dạng JSON, chứa trong thư mục :  /etc/logstash/conf.d thông thường gồm 3 phần input, filter và output

Edit file cấu hình : 

	$ sudo vi /etc/logstash/conf.d/logstash.conf
	
Thêm các dòng sau 

	# This input block will listen on port 10514 for logs to come in.
	# host should be an IP on the Logstash server.
	# codec => "json" indicates that we expect the lines we're receiving to be in JSON format
	# type => "rsyslog" is an optional identifier to help identify messaging streams in the pipeline.

	input {
	  udp {
		host => "logstash_private_ip"
		port => 10514
		codec => "json"
		type => "rsyslog"
	  }
	}

	# This is an empty filter block.  You can later add other filters here to further process
	# your log lines

	filter { }

	# This output block will send all events of type "rsyslog" to Elasticsearch at the configured
	# host and port into daily indices of the pattern, "rsyslog-YYYY.MM.DD"

	output {
	  if [type] == "rsyslog" {
		elasticsearch {
		  hosts => [ "elasticsearch_private_ip:9200" ]
		}
	  }
	}

Save and exit.

Sau đó khởi động Logstash

	$ sudo service logstash start
	
Restart lại rsyslog

	$ sudo service rsyslog restart
	
Kiểm tra Logstash lắng nghe ở cổng 10514

	$ netstat -na | grep 10514
	
Nếu tiến trình hoạt động, ta sẽ nhận được như sau

	udp6       0      0 10.128.33.68:10514     :::*  
	

Khởi động Logstash bằng lệnh: 

	/usr/share/logstash/bin/logstash -f /etc/logstash/conf.d
	


	
	
** Tham khảo **

https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-ubuntu-14-04

https://www.digitalocean.com/community/tutorials/how-to-centralize-logs-with-rsyslog-logstash-and-elasticsearch-on-ubuntu-14-04
	
[Head](#head)