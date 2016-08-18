GrapeSwaggerRails.options.url      = "/api_docs.json"

GrapeSwaggerRails.options.before_filter_proc = proc {
  GrapeSwaggerRails.options.app_url = request.protocol + request.host_with_port
}

GrapeSwaggerRails.options.doc_expansion = 'list'
GrapeSwaggerRails.options.app_name = (ENV['BRAND_NAME'] || 'Cloud.net') + ' API documentation'

GrapeSwaggerRails.options.api_auth     = 'basic'
GrapeSwaggerRails.options.api_key_name = 'Authorization'
GrapeSwaggerRails.options.api_key_type = 'header'

GrapeSwaggerRails.options.headers['Accept-Version'] = 'v1'
