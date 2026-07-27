_: {
  # No home-manager module for tig, so the config is written verbatim. tig reads
  # ~/.config/tig/config after the system tigrc.
  xdg.configFile."tig/config".text = ''
    # Cursor/selected line: invert whatever it sits on. tig's default is
    # white-on-green, which is hard to read.
    color cursor default default reverse

    # Title bars, legible instead of the dim default.
    color title-focus default blue    bold
    color title-blur  default default

    set line-graphics = utf-8
  '';
}
