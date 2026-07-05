#!/bin/bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y apache2

cat >/var/www/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Apache Installed Successfully</title>
</head>
<body>
  <h1>Apache Installed Successfully</h1>
</body>
</html>
HTML

systemctl enable apache2
systemctl start apache2
