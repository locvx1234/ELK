# stdout

Stdout là một plugin thuộc bộ output plugin của logstash, dùng để in STDOUT ra shell chạy Logstash. Điều này tiện lợi cho debug, cho phép ngay lập tức truy cập từng dữ liệu sau khi nó qua input và filter.

Dạng chung của plugin này như sau :

	output {
	  stdout {}
	}
	
Có 2 codec hữu ích :

`rubydebug` : output sử dụng thư viện  "awesome_print"

	output {
	  stdout { codec => rubydebug }
	}

`json` : output sử dụng theo định dạng JSON 

	output {
	  stdout { codec => json }
	}
	
Các option: 

|-------|-----|----|--------|-------|-----|
|Setting|Input|type|Required|Default|value|
|codec|codec|No|"line"|
|workers|number|No|1|

Chi tiết : 

https://www.elastic.co/guide/en/logstash/current/plugins-outputs-stdout.html#_details_98

