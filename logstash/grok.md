# Grok
Grok là một plugin trong bộ filter plugin của logstash.

Grok hiện tại là cách tốt nhất trong logstash dùng để phân tích, cấu trúc lại log data.

Công cụ này hoàn hảo cho syslog, mysql log, apache và các webserver log khác.

Grok làm việc bằng sự phối hợp giữa các mẫu text và match với log của bạn.

## Grok basic

Cú pháp cho grok pattern là `%{SYNTAX:SEMANTIC}`

`SYNTAX` là tên của pattern sẽ match với text của bạn. Ví dụ `3.14` match bởi pattern `NUMBER`, `192.168.169.137` match với pattern `IP`

`SEMANTIC` là mã nhận dạng của text được match.

Ví dụ cho grok filter ở trên :

	%{NUMBER:duration} %{IP:client}
	
Từ một bản ghi request log:

	55.3.244.1 GET /index.html 15824 0.043
	
Pattern nên là : 

	%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}
	
Và đặt chúng vào tập tin config : 


	input {
	  file {
		path => "/var/log/http.log"
	  }
	}
	filter {
	  grok {
		match => { "message" => "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}" }
	  }
	}
	
Sau khi qua grok filter, các sự kiện sẽ có các trường mở rộng :

	client: 55.3.244.1
    method: GET
    request: /index.html
    bytes: 15824
    duration: 0.043 
	
## Regular Expressions 

Grok luôn đứng top của regular expression (regex).

Thư viện dùng cho regex là Oniguruma	

Cú pháp regex được hỗ trợ đầy đủ tại [Oniguruma site](https://github.com/kkos/oniguruma/blob/master/doc/RE)

## Custom Pattern

Thi thoảng, logstash không có pattern bạn cần, vì thế cần định nghĩa chúng trong file.

Ví dụ postfix log có `queue id` gồm 10 hoặc 11 kí tự thập lục phân, bạn có thể định nghĩa như sau:

	(?<queue_id>[0-9A-F]{10,11})

Bạn tạo một custom patterns file:
	
- Tạo một thư mục `patterns` với file `postfix` bên trong nó (tên file không phải là vấn đề)
- Trong file đó, viết pattern mà bạn cần, như là tên pattern, khoảng trắng, regex pattern.

	# contents of ./patterns/postfix:
	POSTFIX_QUEUEID [0-9A-F]{10,11}
	
Sau đó sử dụng `patterns_dir` trong plugin này để thông báo cho logstash biết thư mục của custom patterns.

Ví dụ đầy đủ với một log mẫu:

	Jan  1 06:25:43 mailserver14 postfix/cleanup[21403]: BEF25A72965: message-id=<20130101142543.5828399CCAF@mailserver14.example.com>

	
	filter {
	  grok {
		patterns_dir => ["./patterns"]
		match => { "message" => "%{SYSLOGBASE} %{POSTFIX_QUEUEID:queue_id}: %{GREEDYDATA:syslog_message}" }
	  }
	}

Kết quả của ví dụ trên sẽ là :

	timestamp: Jan 1 06:25:43
    logsource: mailserver14
    program: postfix/cleanup
    pid: 21403
    queue_id: BEF25A72965
    syslog_message: message-id=<20130101142543.5828399CCAF@mailserver14.example.com> 
	
Trong đó `timestamp`, `logsource`, `program`, `pid` là các trường từ SYSLOGBASE pattern được định nghĩa bởi các pattern khác.

## Tóm tắt

Cấu trúc chính của grok 

	grok {
	
	}
	
Các option 

|-------|----------|--------|-------------|
|Setting|Input type|Required|Default value|
|-------|----------|--------|-------------|
|add_field|hash|No|{}|
|add_tag|array|No|[]|
|break_on_match|boolean|No|true|
|keep_empty_captures|boolean|No|false|
|match|hash|No|{}|
|named_captures_only|boolean|No|true|
|overwrite|array|No|[]|
|patterns_dir|array|No|[]|
|patterns_files_glob|string|No|"*"|
|periodic_flush|boolean|No|false|
|remove_field|array|No|[]|
|remove_tag|array|No|[]|
|tag_on_failure|array|No|["_grokparsefailure"]|
|tag_on_timeout|string|No|"_groktimeout"|
|timeout_millis|number|No|2000|

## Chi tiết

https://www.elastic.co/guide/en/logstash/5.0/plugins-filters-grok.html#_details_127