package provide darksky 0.1

package require http
package require json
package require tls

namespace eval ::darksky {
	variable url https://api.darksky.net
	variable useragent https://github.com/horgh/darksky-tcl
	variable timeout [expr 30*1000]
}

# Parameters:
#
# key: The secret key to use in API requests.
proc ::darksky::new {key} {
	return [dict create key $key]
}

# Look up the forecast for the given latitude and longitude
#
# Parameters:
#
# darksky: Create this with ::darksky::new
proc ::darksky::forecast {darksky latitude longitude} {
	::http::config -useragent $::darksky::useragent
	::http::register https 443 [list ::tls::socket -ssl2 0 -ssl3 0 -tls1 1]

	set query [::http::formatQuery units ca]
	set url $::darksky::url/forecast/[dict get $darksky key]/$latitude,$longitude?$query
	set token [::http::geturl $url -timeout $::darksky::timeout -binary 1]

	set status [::http::status $token]
	if {$status != "ok"} {
		::http::cleanup $token
		return [dict create error "status is $status"]
	}

	set ncode [::http::ncode $token]

	if {$ncode != 200} {
		::http::cleanup $token
		return [dict create error "HTTP status $ncode"]
	}

	set data [::http::data $token]
	set data [encoding convertfrom "utf-8" $data]
	::http::cleanup $token

	set decoded [::json::json2dict $data]

	if {[catch {::darksky::parse_forecast $decoded} response]} {
		return [dict create error "Error parsing response: $response"]
	}

	return $response
}

proc ::darksky::parse_forecast {response} {
	# There's more than this in the response, but this is what I'm interested in.

	# With units = ca:
	# - temperature is in celsius
	# - pressure is in hectopascals
	# - windSpeed is in meters per second.

	set resp [dict create \
		latitude    [dict get $response latitude] \
		longitude   [dict get $response longitude] \
		summary     [dict get $response currently summary] \
		temperature [dict get $response currently temperature] \
		humidity    [dict get $response currently humidity] \
		pressure    [dict get $response currently pressure] \
		windSpeed   [dict get $response currently windSpeed] \
		cloudCover  [dict get $response currently cloudCover] \
	]

	return $resp
}
