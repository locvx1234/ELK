
# Cài đặt Elasticsearch, Logstash, and Kibana (ELK Stack) trên Ubuntu 14.04 


<img src="http://i.imgur.com/24wToCQ.png">


## 1. Giới thiệu 

Chúng ta sẽ cấu hình và cài đặt ELK trên Ubuntu 14.04 bao gồm Elasticsearch 5.1.1, Logstash 5.1.1 và Kibana 5.1.1 sử dụng bộ cài là các gói .deb.

Logstash là một công cụ mã nguồn mở để tập hợp, phân tích và lưu trữ log dùng cho các quá trình sau đó.

Kibana là một ứng dụng với giao diện web, sử dụng để tìm kiếm và xem các log từ Logstash mà đã đánh chỉ số. 

Cả hai công cụ là cơ sở cho Elasticsearch, công cụ sử dụng cho việc lưu trữ log 

Log tập trung // TODO

Nó có thể thu thập tất cả các loại log, nhưng bài viết này thu hẹp phạm vi chỉ thu thập syslog 

## 2. Mục tiêu đạt được 

Cài đặt Logstash để thu thập syslog trên nhiều server và cài đặt Kibana để xem log.

ELK Stack của bài viết này cấu thành từ 4 thành phần chính :

	- Logstash : Các máy chủ Logstash xử lý các log đầu vào 
	- Elasticsearch : Lưu trữ tất cả các log.
	- Kibana : Giao diện web để tìm kiếm và phân tích log, chúng ta sẽ proxy qua Nginx.
	- Filebeat : Đóng vai trò shipper, đã được cài đặt trên máy khách chủ, sẽ gửi log cho Logstash.
	
<img src="https://i.imgur.com/tObw8QR.png">

Chúng ta sẽ cài đặt 3 thành phần đầu, tạo thành ELK server.

## 3. Chuẩn bị

    OS: Ubuntu 14.04
    RAM: 4GB
    CPU: 2

Ngoài ra, có thể thêm một vài máy chủ khác để làm nguồn sinh ra log.

## 4. Install Java 8

Elasticsearch và Logstash cần có Java, cho nên chúng ta sẽ cài đặt Java. Oracle Java 8 được Elasticsearch khuyên dùng.

	$ sudo add-apt-repository -y ppa:webupd8team/java
	$ sudo apt-get update
	$ sudo apt-get -y install oracle-java8-installer
	
## 5. Install Elasticsearch

Bài viết này sử dụng gói `elasticsearch-5.1.1.deb` để cài đặt. 

	$ sudo dpkg -i path_to_file.deb

Sửa file cấu hình 

	$ sudo vi /etc/elasticsearch/elasticsearch.yml
	
Bạn sẽ muốn hạn chế truy cập từ ngoài vào Elasticsearch của bạn, để người khác không thể đọc dữ liệu hoặc tắt Elasticsearch

Tìm dòng xác định `network.host` và bỏ comment đi và thay giá trị là "localhost"

	network.host: localhost
	
Lưu và thoát sau đó khởi động Elasticsearch:

	$ sudo service elasticsearch start

Sau đó chạy lệnh sau để start khi khởi động 

	$ sudo update-rc.d elasticsearch defaults 95 10
	
	
## 6. Install Kibana

Sử dụng gói `kibana-5.1.1-amd64.deb` để cài đặt. 

	$ sudo dpkg -i path_to_file.deb

Sửa file cấu hình 

	$ sudo vi /etc/kibana/kibana.yml
	
Tìm tới dòng xác định `server.host` và thay thế bởi địa chỉ IP :

	server.host: "localhost"
	
Save và exit. Cài đặt này sẽ giúp cho kibana chỉ có thể truy cập từ localhost. Điều này tốt bởi vì chúng ta sẽ sử dụng Nginx proxy để truy cập từ bên ngoài.

Bật Kibana và start:

	$ sudo update-rc.d kibana defaults 96 9
	$ sudo service kibana start
	
Trước khi sử dụng Kibana, ta phải cài đặt một reverse proxy, Nginx

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

	
## 8. Install Logstash

Sử dụng gói `logstash-5.1.1.deb` để cài đặt. 

	$ sudo dpkg -i path_to_file.deb


### 9. Generate SSL Certificates

Chúng ta sử dụng Filebeat để ship log từ Client Servers tới ELK Server. Yêu cầu cần tạo chứng nhận SSL và một cặp khóa. Chứng nhận được Filebeat sử dụng để xác minh ELK Server.

Tạo thư mục sẽ lưu chứng nhận và khóa private như sau:

	$ sudo mkdir -p /etc/pki/tls/certs
	$ sudo mkdir /etc/pki/tls/private

Có 2 cách tạo chứng nhận SSL là sử dụng IP address và sử dụng DNS.

Lab của tôi sẽ sử dụng IP address.

Mởi file cấu hình OpenSSL:

	$ sudo vi /etc/ssl/openssl.cnf
	
Tìm `[ v3_ca ]` và thêm dòng này bên dưới: 

	subjectAltName = IP: ELK_server_private_IP
	
Save và exit.

Bây giờ tạo chứng nhận SSL và private key trong địa chỉ thích hợp :

	$ cd /etc/pki/tls
	$ sudo openssl req -config /etc/ssl/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
	
File ` logstash-forwarder.crt` sẽ được copy vào tất cả các server gửi log tới Logstash.

### 10. Configure Logstash

File cấu hình Logstash theo định dạng JSON, chứa trong thư mục :  /etc/logstash/conf.d bao gồm  inputs, filters, và outputs.

Tạo một file cấu hình `02-beats-input.conf` và cài đặt đầu vào cho "filebeat"

	$ sudo vi /etc/logstash/conf.d/02-beats-input.conf

Chèn vào file nội dung như sau :

	input {
      beats {
        port => 5044
        ssl => true
        ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
        ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
      }
    }

Save và quit. Các beats input sẽ lắng nghe ở cổng 5044 và sử dụng SSL certificate  và  private key vừa tạo.


Tạo một file cấu hình `02-beats-input.conf` và chúng ta sẽ thêm bộ lọc cho các syslog message:

	$ sudo vi /etc/logstash/conf.d/10-syslog-filter.conf
	
Chèn vào file nội dung như sau :

	filter {
      if [type] == "syslog" {
        grok {
          match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
          add_field => [ "received_at", "%{@timestamp}" ]
          add_field => [ "received_from", "%{host}" ]
        }
        syslog_pri { }
        date {
          match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
        }
      }
    }


Save và quit. Bộ lọc này sẽ nhận các syslog. Và nó sử dụng `grok` để phân tích các syslog để nó có cấu trúc và có thể truy vấn.

Cuối cùng, tạo file `30-elasticsearch-output.conf`

	$ sudo vi /etc/logstash/conf.d/30-elasticsearch-output.conf
	
Chèn vào file nội dung như sau :

	output {
      elasticsearch {
        hosts => ["localhost:9200"]
        sniffing => true
        manage_template => false
        index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
        document_type => "%{[@metadata][type]}"
      }
    }

Save và quit.Cấu hình cơ bản để Logstash lưu trữ dữ liệu của các beats trong Elasticsearch chạy ở `localhost:9200`, trong một chỉ mục sau khi beat sử dụng.

Test cấu hình Logstash

	$ sudo service logstash configtest
	
Restart Logstash và enable nó :

	$ sudo service logstash restart
	$ sudo update-rc.d logstash defaults 96 9
	
## 11. Load Kibana Dashboards

Elastic cung cấp một vài dashboard và các Beat index mẫu giúp bạn bắt đầu với Kibana.

Chúng ta sử dụng mẫu Filebeat index:

Đầu tiên, download dashboard mẫu 

	$ cd ~
    $ curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.1.0.zip
	$ sudo apt-get -y install unzip
	$ unzip beats-dashboards-*.zip
	$ cd beats-dashboards-*
	$ ./load.sh
	
Có các mẫu index :

	
    [packetbeat-]YYYY.MM.DD
    [topbeat-]YYYY.MM.DD
    [filebeat-]YYYY.MM.DD
    [winlogbeat-]YYYY.MM.DD

Khi sử dụng Kibana, chúng ta sẽ cần chọn Filebeat index mặc định.

## 12. Load Filebeat Index Template in Elasticsearch

Chúng ta sử dụng Filebeat để ship log tới Elasticsearch nên cần  load Filebeat index template.

	$ cd ~
    $ curl -O https://gist.githubusercontent.com/thisismitch/3429023e8438cc25b86c/raw/d8c479e2a1adcea8b1fe86570e42abab0f10f364/filebeat-index-template.json
	$ curl -XPUT 'http://localhost:9200/_template/filebeat?pretty' -d@filebeat-index-template.json
	
Chúng ta sẽ thấy như thế này :

	{
		"acknowledged" : true
	}
	
Bây giờ, ELK server của chúng ta đã sẵn sàng để nhận Filebeat data. 

	
## 13. Set Up Filebeat (Add Client Servers)

### 13.1 Copy SSL Certificate

Trên ELK server, copy  SSL certificate vừa tạo sang Client Servers.

	elk$ scp /etc/pki/tls/certs/logstash-forwarder.crt user@client_server_private_address:/tmp
	
Trên Client Server, copy ELK Server's SSL certificate vào vị trí thích hợp

	client$ sudo mkdir -p /etc/pki/tls/certs
	client$ sudo cp /tmp/logstash-forwarder.crt /etc/pki/tls/certs/

### 13.2 Install Filebeat Package

Trên Client Server, tạo danh sách nguồn Beat

	$ echo "deb https://packages.elastic.co/beats/apt stable main" |  sudo tee -a /etc/apt/sources.list.d/beats.list
	$ wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

Cài đặt gói Filebeat

	$ sudo apt-get update
	$ sudo apt-get install filebeat
	
### 13.3 Configure Filebeat

Trên Client Server, sửa file cấu hình Filebeat:

	$ sudo vi /etc/filebeat/filebeat.yml
	
Tại `prospectors` section định nghĩa các file log được ship, mỗi prospector  chỉ ra bởi dấu -

Chúng ta cho nhận syslog và auth.log
	
	...
      paths:
        - /var/log/auth.log
        - /var/log/syslog
	#        - /var/log/*.log
	...
	
Sau đó tìm dòng `document_type:` và thêm giá trị syslog

	...
      document_type: syslog
	...

Tiếp theo, dưới `output` section, tìm `elasticsearch:` và comment phần đó

Bỏ comment `#logstash:` và `hosts:` bên dưới, thay đổi localhost thành IP của ELK server.

	### Logstash as output
	logstash:
		# The Logstash hosts
		hosts: ["ELK_server_private_IP:5044"]
		
Với cấu hình này , Filebeat kết nối với Logstash trên ELK Server qua port 5044

Cấu hình thêm : 

	bulk_max_size: 1024
	
Tiếp theo tìm `tls` và uncomment và thay đổi giá trị của `certificate_authorities` thành `["/etc/pki/tls/certs/logstash-forwarder.crt"]`

	...
    tls:
      # List of root certificates for HTTPS server verifications
      certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
	  
	  
Save and quit. 

Restart Filebeat để chấp nhận thay đổi : 

	$ sudo service filebeat restart
	$ sudo update-rc.d filebeat defaults 95 10
	
	

	
