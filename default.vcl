# return statement.
#
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the
# new 4.0 format.
vcl 4.0;

#acl upstream_proxy {
#  "127.0.0.1";
#}

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}
sub vcl_recv {
  # Set the X-Forwarded-For header so the backend can see the original
  # IP address. If one is already set by an upstream proxy, we'll just re-use that.

  #return(pass);

  if (req.method == "PURGE") {
     return (purge);
  }

  if (req.method == "XCGFULLBAN") {
     ban("req.http.host ~ .*");
     return (synth(200, "Full cache cleared"));
  }

  if (req.http.X-Requested-With == "XMLHttpRequest") {
     return(pass);
  }

  if (req.http.Authorization || req.method == "POST") {
     return (pass);
  }

  if (req.method != "GET" && req.method != "HEAD") {
     return (pass);
  }

  if (req.url ~ "(wp-admin|post\.php|edit\.php|wp-login|login|contact|wp-json)") {
     return(pass);
  }

  if (req.url ~ "/wp-cron.php" || req.url ~ "preview=true") {
     return (pass);
  }
  if (req.url ~ "/xmlrpc.php" || req.url ~ "preview=true") {
     return (pass);
  }

  if ((req.http.host ~ "sitename.com" && req.url ~ "^some_specific_filename\.(css|js)")) {
     return (pass);
  }

# Unset Cookies except for WordPress admin and WooCommerce pages
if (!(req.url ~ "(cart|my-account/*|wc-api*|checkout|addons|logout|lost-password|product/*)")) {
unset req.http.cookie;
}
# Pass through the WooCommerce dynamic pages
if (req.url ~ "^/(cart|my-account/*|checkout|wc-api/*|addons|logout|lost-password|product/*)") {
return (pass);
}
# Pass through the WooCommerce add to cart
if (req.url ~ "\?add-to-cart=" ) {
return (pass);
}
# Pass through the WooCommerce API
if (req.url ~ "\?wc-api=" ) {
return (pass);
}

  set req.http.Cookie = regsuball(req.http.Cookie, "(^|;\s*)(_[_a-z]+|has_js)=[^;]*", "");

  # Remove the wp-settings-1 cookie
  set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-1=[^;]+(; )?", "");

  # Remove the wp-settings-time-1 cookie
  set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-time-1=[^;]+(; )?", "");

  # Remove the wp test cookie
  set req.http.Cookie = regsuball(req.http.Cookie, "wordpress_test_cookie=[^;]+(; )?", "");

  # Remove the PHPSESSID in members area cookie
  set req.http.Cookie = regsuball(req.http.Cookie, "PHPSESSID=[^;]+(; )?", "");

  unset req.http.Cookie;
}
sub vcl_purge {
    set req.method = "GET";
    set req.http.X-Purger = "Purged";

    #return (synth(200, "Purged"));
    return (restart);
}

sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.

    set beresp.grace = 12h;
    set beresp.ttl = 12h;
}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
}
