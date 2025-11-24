{ pkgs, ... }:
# For information on how to configure Zed, see the Zed
# documentation: https://zed.dev/docs/configuring-zed
#
# To see all of Zed's default settings without changing your
# custom settings, run `zed: open default settings` from the
# command palette (cmd-shift-p / ctrl-shift-p)

{
  programs.zed-editor = {
    enable = true;
    userSettings = {
      agent = {
        default_model = {
          provider = "copilot_chat";
          model = "claude-sonnet-4.5";
        };
      };
      features = {
        edit_prediction_provider = "copilot";
      };
      telemetry = {
        metrics = false;
      };
      ui_font_size = 12;
      buffer_font_size = 12;
      theme = {
        mode = "system";
        light = "One Light";
        dark = "One Dark";
      };
      autosave = "on_window_change";
      format_on_save = "on";
      ensure_final_newline_on_save = true;
      remove_trailing_whitespace_on_save = true;
      code_actions_on_format = {
        "source.organizeImports" = true;
        "source.removeUnusedImports" = true;
      };
    };
  };
}
