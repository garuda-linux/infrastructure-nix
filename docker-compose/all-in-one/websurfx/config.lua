logging = false
debug = false
threads = 8

port = "8080"
binding_ip = "0.0.0.0"
production_use = true
request_timeout = 10
rate_limiter = {
	number_of_requests = 20,
	time_limit = 3,
}

safe_search = 2
colorscheme = "dracula"
theme = "simple"

redis_url = "redis://websurfx_redis:6379"

upstream_search_engines = {
	DuckDuckGo = true,
	Searx = true,
}