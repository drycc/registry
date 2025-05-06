upstream container-registry {
    server %REGISTRY_HOST%;
}

server {
    listen 8080;
    server_name localhost;
    # disable any limits to avoid HTTP 413 for large image uploads
    client_max_body_size 0;
    # required to avoid HTTP 411: see Issue #1486 (https://github.com/moby/moby/issues/1486)
    chunked_transfer_encoding on;
    location / {
        proxy_pass                          http://container-registry;
        proxy_set_header  Host              $http_host;   # required for container client's sake
        proxy_set_header  X-Real-IP         $remote_addr; # pass on real client's IP
        proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header  X-Forwarded-Proto $scheme;
        proxy_read_timeout                  900;
        proxy_set_header  Authorization     "Basic %AUTHORIZATION%";
        limit_except      GET HEAD OPTIONS  {
            deny all;
        }
    }
}