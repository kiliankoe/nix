{
  config,
  pkgs,
  ...
}:
let
  yaml = pkgs.formats.yaml { };
in
{
  # k9s only ever reads skins from its own config dir. The 35 skins nixpkgs
  # ships in $out/share/k9s/skins are invisible to it, and a `skin` naming one
  # of them silently falls back to the built-in default. recursive so
  # hand-written skins can live alongside them.
  home.file."Library/Application Support/k9s/skins" = {
    source = "${pkgs.k9s}/share/k9s/skins";
    recursive = true;
  };

  home.file."Library/Application Support/k9s/config.yaml".source = yaml.generate "k9s-config" {
    k9s = {
      liveViewAutoRefresh = false;
      gpuVendors = { };
      screenDumpDir = "${config.home.homeDirectory}/Library/Application Support/k9s/screen-dumps";
      refreshRate = 2;
      apiServerTimeout = "15s";
      maxConnRetry = 5;
      readOnly = false;
      noExitOnCtrlC = false;
      portForwardAddress = "localhost";
      ui = {
        enableMouse = true;
        headless = false;
        logoless = true;
        crumbsless = false;
        splashless = true;
        reactive = false;
        noIcons = false;
        defaultsToFullScreen = false;
        useFullGVRTitle = false;
        skin = "transparent";
      };
      skipLatestRevCheck = false;
      disablePodCounting = false;
      shellPod = {
        image = "busybox:1.35.0";
        namespace = "default";
        limits = {
          cpu = "100m";
          memory = "100Mi";
        };
      };
      imageScans = {
        enable = false;
        exclusions = {
          namespaces = [ ];
          labels = { };
        };
      };
      logger = {
        tail = 100;
        buffer = 5000;
        sinceSeconds = -1;
        textWrap = false;
        disableAutoscroll = false;
        showTime = false;
      };
      thresholds = {
        cpu = {
          critical = 90;
          warn = 70;
        };
        memory = {
          critical = 90;
          warn = 70;
        };
      };
      defaultView = "";
    };
  };
}
