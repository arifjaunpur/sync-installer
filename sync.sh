#!/bin/bash
export REACT_APP_API_URL=http://$DOMAIN_NAME
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install redis-server nginx nodejs git -y
npm i -g pm2
cd /opt && git clone https://github.com/ubclaunchpad/sync && cd sync
cd frontend
npm install
cd ../backend
npm install
export NODE_ENV=production
npm run build
pm2 start build/index.js --name sync-backend
cd ../frontend
npm run build
rm -rf /var/www/html/ && cp -r build/ /var/www/html/
rm -rf /etc/nginx/sites-enabled/$DOMAIN_NAME && cat >/etc/nginx/sites-enabled/$DOMAIN_NAME <<EOL
server {
  listen 80;
  server_name $DOMAIN_NAME;
  root /var/www/html;
  index index.html;
  location /api {
    proxy_pass http://localhost:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_cache_bypass \$http_upgrade;
  }
  location / {
    try_files \$uri /index.html =404;
  }
}
EOL
sudo systemctl restart nginx
