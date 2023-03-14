server {
    listen                  443 ssl http2;
    listen                  [::]:443 ssl http2;
    server_name             example.com;
    root                    /var/www/www.example.com;

    # SSL
    ssl_certificate         /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    ssl_prefer_server_ciphers on;

    # security
    include                 security.conf;

    # logging
    access_log              /var/log/nginx/access.log combined buffer=512k flush=1m;
    error_log               /var/log/nginx/error.log warn;

    # index.html fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # index.php fallback
    #location ~ ^/api/ {
    #    try_files $uri $uri/ /index.php?$query_string;
    #}

    # additional config
    include general.conf;
}

# subdomains redirect
server {
    listen                  443 ssl http2;
    listen                  [::]:443 ssl http2;
    server_name             www.example.com;
    
    include                 security.conf;

    # SSL
    ssl_certificate         /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    ssl_prefer_server_ciphers on;
    return                  301 https://example.com$request_uri;
}

# HTTP redirect
server {
    listen      80;
    listen      [::]:80;
    server_name www.example.com example.com;

    include                 security.conf;

    location / {
        return 301 https://example.com$request_uri;
    }
}

