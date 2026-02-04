{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../lib/docker-service.nix { inherit pkgs lib; };
  serviceDir = "/etc/docker-compose/rustypaste";
in
lib.mkMerge [
  (dockerService.mkDockerComposeService {
  serviceName = "rustypaste";
  auto_update = true;
  monitoring.httpEndpoint = {
    name = "rustypaste";
    url = "http://localhost:${toString config.k.ports.rustypaste_http}/";
  };
  compose = {
    services.rustypaste = {
      image = "docker.io/orhunp/rustypaste:latest";
      container_name = "rustypaste";
      restart = "unless-stopped";
      environment = [ "RUST_LOG=info" ];
      env_file = [ "rustypaste.env" ];
      ports = [ "${toString config.k.ports.rustypaste_http}:8000" ];
      volumes = [
        "/var/lib/rustypaste/upload:/app/upload"
        "${serviceDir}/config.toml:/app/config.toml:ro"
      ];
    };
  };
  environment = {
    rustypaste = {
      AUTH_TOKEN.secret = "rustypaste/auth_token";
    };
  };
  extraFiles = {
    "docker-compose/rustypaste/config.toml".text = ''
      [config]
      refresh_rate = "1s"

      [server]
      address = "0.0.0.0:8000"
      url = "https://dump.kilko.de"
      max_content_length = "512MB"
      upload_path = "/app/upload"
      timeout = "30s"
      expose_version = false
      expose_list = false
      handle_spaces = "replace"

      [landing_page]
      content_type = "text/html; charset=utf-8"
      text = """
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>dump.kilko.de</title>
        <style>
          :root {
            color-scheme: light;
          }
          body {
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
            margin: 32px auto;
            max-width: 760px;
            padding: 0 20px;
            line-height: 1.45;
          }
          h1 {
            font-size: 20px;
            margin-bottom: 8px;
          }
          form {
            margin: 16px 0 24px;
            padding: 12px 16px;
            border: 1px solid #ddd;
            border-radius: 10px;
          }
          label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
          }
          textarea {
            width: 100%;
            min-height: 180px;
            font-family: inherit;
          }
          input[type="file"] {
            width: 100%;
          }
          button {
            margin-top: 10px;
            padding: 6px 12px;
            font-family: inherit;
          }
          .hint {
            color: #555;
            font-size: 12px;
          }
          #result {
            white-space: pre-wrap;
            word-break: break-all;
            border: 1px dashed #aaa;
            padding: 10px;
            border-radius: 8px;
          }
        </style>
      </head>
      <body>
        <h1>dump.kilko.de</h1>
        <p class="hint">Uploads require an auth token.</p>

        <form id="token-form">
          <label for="token">Auth token</label>
          <input id="token" type="password" autocomplete="off" placeholder="Required for uploads">
        </form>

        <form id="file-form" method="post" enctype="multipart/form-data">
          <label for="file">Upload file</label>
          <input id="file" name="file" type="file" required>
          <button type="submit">Upload file</button>
        </form>

        <form id="text-form">
          <label for="text">Paste text</label>
          <textarea id="text" placeholder="Paste here..."></textarea>
          <button type="submit">Upload text</button>
        </form>

        <div class="hint">Result</div>
        <pre id="result">(waiting)</pre>

        <script>
          const result = document.getElementById("result");
          const getAuthHeaders = () => {
            const token = document.getElementById("token").value.trim();
            return token ? { Authorization: token } : {};
          };
          document.getElementById("text-form").addEventListener("submit", async (event) => {
            event.preventDefault();
            const text = document.getElementById("text").value;
            if (!text.trim()) {
              result.textContent = "Nothing to upload.";
              return;
            }
            const data = new FormData();
            data.append("file", new Blob([text], { type: "text/plain" }), "paste.txt");
            const response = await fetch("/", { method: "POST", body: data, headers: getAuthHeaders() });
            result.textContent = (await response.text()).trim();
          });
          document.getElementById("file-form").addEventListener("submit", async (event) => {
            event.preventDefault();
            const form = event.target;
            const data = new FormData(form);
            const response = await fetch("/", { method: "POST", body: data, headers: getAuthHeaders() });
            result.textContent = (await response.text()).trim();
          });
        </script>
      </body>
      </html>
      """

      [paste]
      random_url = { type = "petname", words = 2, separator = "-" }
      default_extension = "txt"
      mime_override = [
        { mime = "image/jpeg", regex = "^.*\\.jpg$" },
        { mime = "image/png", regex = "^.*\\.png$" },
        { mime = "image/svg+xml", regex = "^.*\\.svg$" },
        { mime = "video/webm", regex = "^.*\\.webm$" },
        { mime = "video/x-matroska", regex = "^.*\\.mkv$" },
        { mime = "application/octet-stream", regex = "^.*\\.bin$" },
        { mime = "text/plain", regex = "^.*\\.(log|txt|diff|sh|rs|toml)$" },
      ]
      mime_blacklist = [ ]
      duplicate_files = true
      default_expiry = "7d"
      delete_expired_files = { enabled = true, interval = "1h" }
    '';
  };
  })
  {
    systemd.tmpfiles.rules = [
      "d /var/lib/rustypaste 0755 1000 1000 -"
      "d /var/lib/rustypaste/upload 0755 1000 1000 -"
    ];
  }
]
