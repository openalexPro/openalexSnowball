library("vcr")

vcr_dir <- vcr::vcr_test_path("fixtures", "vcr")
vcr::vcr_configure_log(file = file.path(vcr_dir, "vcr.log"))

# "none" replays only: a request missing from a cassette fails, instead of
# being passed through to the live API -- which, on r-universe (network
# access), silently compared today's OpenAlex data with an old recording.
# OPENALEXSNOWBALL_RECORD_CASSETTES=true re-records every cassette ("all").
# Re-record oa_snowball and pro_snowball together, so the openalexR
# reference and pro_snowball() see the same data.
vcr_record_mode <- if (nzchar(Sys.getenv("OPENALEXSNOWBALL_RECORD_CASSETTES"))) {
  "all"
} else {
  "none"
}

# openalexPro (>= 0.13.0) sends the API key as an `Authorization: Bearer`
# header, never in the URL; requests are matched on method, URI and (POST)
# body, not headers, so the key does not affect matching. vcr masks it when
# writing cassettes. `api_key` in a URL (openalexR with a key set) is masked
# the same way.
invisible(vcr::vcr_configure(
  dir = vcr_dir,
  record = vcr_record_mode,
  filter_request_headers = list(Authorization = "<api-key>"),
  filter_query_parameters = list(api_key = "<api-key>")
))
