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
  <title>Terraform EC2 Apache</title>
  <style>
    :root {
      color-scheme: light;
      --ink: #172026;
      --paper: #fff9ef;
      --coral: #ff5a5f;
      --gold: #ffc145;
      --mint: #2ec4b6;
      --sky: #247ba0;
    }

    * {
      box-sizing: border-box;
    }

    body {
      min-height: 100vh;
      margin: 0;
      display: grid;
      place-items: center;
      overflow: hidden;
      color: var(--ink);
      font-family: Georgia, "Times New Roman", serif;
      background:
        radial-gradient(circle at 18% 20%, rgba(255, 193, 69, 0.95) 0 13%, transparent 14%),
        radial-gradient(circle at 82% 18%, rgba(46, 196, 182, 0.82) 0 15%, transparent 16%),
        radial-gradient(circle at 78% 82%, rgba(255, 90, 95, 0.78) 0 18%, transparent 19%),
        linear-gradient(135deg, #fff9ef 0%, #f8ead6 45%, #d8f3f0 100%);
    }

    main {
      width: min(92vw, 760px);
      padding: clamp(32px, 7vw, 72px);
      border: 3px solid rgba(23, 32, 38, 0.9);
      border-radius: 8px;
      background: rgba(255, 249, 239, 0.84);
      box-shadow: 18px 18px 0 rgba(36, 123, 160, 0.28);
    }

    .eyebrow {
      margin: 0 0 18px;
      color: var(--sky);
      font: 700 0.85rem/1.2 Verdana, sans-serif;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }

    h1 {
      max-width: 11ch;
      margin: 0;
      font-size: clamp(3rem, 12vw, 7rem);
      line-height: 0.88;
      letter-spacing: 0;
    }

    p {
      max-width: 56ch;
      margin: 28px 0 0;
      font: 1.08rem/1.7 Verdana, sans-serif;
    }

    .status {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 32px;
      font: 700 0.9rem/1 Verdana, sans-serif;
    }

    .status span {
      padding: 12px 14px;
      border: 2px solid currentColor;
      border-radius: 999px;
      background: white;
    }

    .status span:nth-child(1) { color: var(--coral); }
    .status span:nth-child(2) { color: var(--mint); }
    .status span:nth-child(3) { color: var(--sky); }
  </style>
</head>
<body>
  <main>
    <p class="eyebrow">Terraform EC2 Prod</p>
    <h1>Apache is live.</h1>
    <p>This colorful landing page was installed by user data on an Ubuntu EC2 instance. If you can see it, Apache is running and serving traffic.</p>
    <div class="status" aria-label="Deployment status">
      <span>Apache ready</span>
      <span>EC2 online</span>
      <span>Managed by Terraform</span>
    </div>
  </main>
</body>
</html>
HTML

systemctl enable apache2
systemctl start apache2
