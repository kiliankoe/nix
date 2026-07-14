{
  config,
  pkgs,
  lib,
  ...
}:
let
  dockerService = import ../../../../lib/docker-service.nix { inherit pkgs lib; };
in
dockerService.mkDockerComposeService {
  serviceName = "openclaw";
  auto_update = false;
  backupVolumes = [
    "openclaw-state"
    "openclaw-config"
    "openclaw-vault"
    "obsidian-sync-state"
  ];
  monitoring.httpEndpoint = {
    name = "openclaw";
    # /healthz responds without gateway auth (same endpoint the image's own
    # HEALTHCHECK uses); probing / would trip on the auth-required response.
    url = "http://127.0.0.1:${toString config.k.ports.openclaw_http}/healthz";
  };
  compose = {
    services.openclaw = {
      container_name = "openclaw";
      # renovate
      image = "ghcr.io/openclaw/openclaw:2026.6.11@sha256:3814fb1f62f9cfc5944de088c5817c68c88b5d721feebe36420b666a90a61ce7";
      restart = "unless-stopped";
      # Mirrors upstream docker-compose.yml; "lan" binds beyond loopback so
      # the published port is reachable (access control is the gateway token).
      command = [
        "node"
        "dist/index.js"
        "gateway"
        "--bind"
        "lan"
        "--port"
        "18789"
      ];
      volumes = [
        "openclaw-state:/home/node/.openclaw"
        # Auth-profile encryption keys live outside .openclaw and must survive container replacement.
        "openclaw-config:/home/node/.config/openclaw"
        # The agent workspace doubles as the Obsidian vault, shared with the obsidian-sync container.
        "openclaw-vault:/home/node/.openclaw/workspace"
      ];
      ports = [ "${toString config.k.ports.openclaw_http}:18789" ];
      env_file = [ "openclaw.env" ];
      # Lets the agent reach host-bound services (e.g. hister) without hardcoding the bridge gateway IP.
      extra_hosts = [ "host.docker.internal:host-gateway" ];
    };
    services.obsidian-sync = {
      container_name = "obsidian-sync";
      # renovate
      image = "node:24-bookworm-slim@sha256:6f7b03f7c2c8e2e784dcf9295400527b9b1270fd37b7e9a7285cf83b6951452d";
      restart = "unless-stopped";
      # obsidian-headless is version-pinned here since it's installed at
      # container start and invisible to Renovate. The retry loop keeps the
      # container alive (without npm churn) until `ob login` + `ob sync-setup`
      # have been run once, and rides out transient sync failures after that.
      command = [
        "sh"
        "-c"
        "npm install -g obsidian-headless@0.0.12 && cd /vault && until ob sync --continuous; do echo 'sync exited, retrying in 60s (first run: docker exec -it obsidian-sync ob login && ob sync-setup)'; sleep 60; done"
      ];
      volumes = [
        "openclaw-vault:/vault"
        # Home dir keeps ob credentials and the npm cache across restarts.
        "obsidian-sync-state:/root"
      ];
    };
    volumes = {
      openclaw-state = { };
      openclaw-config = { };
      openclaw-vault = { };
      obsidian-sync-state = { };
    };
    # Fixed interface name so the host firewall can allow-list this network
    # (dockerd otherwise names bridges after a hash of the network id).
    networks.default.driver_opts."com.docker.network.bridge.name" = "br-openclaw";
  };
  environment = {
    openclaw = {
      OPENCLAW_GATEWAY_TOKEN.secret = "openclaw/gateway_token";
      OPENROUTER_API_KEY.secret = "openclaw/openrouter_api_key";
      DISCORD_BOT_TOKEN.secret = "openclaw/discord_bot_token";
      MATRIX_ACCESS_TOKEN.secret = "openclaw/matrix_access_token";
    };
  };
}
