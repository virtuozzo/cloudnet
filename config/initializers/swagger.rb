GrapeSwaggerRails.options.url      = "/api_docs.json"

GrapeSwaggerRails.options.before_filter_proc = proc {
  GrapeSwaggerRails.options.app_url = request.protocol + request.host_with_port
}

GrapeSwaggerRails.options.doc_expansion = 'list'
GrapeSwaggerRails.options.app_name = ENV['BRAND_NAME'] + ' API documentation'