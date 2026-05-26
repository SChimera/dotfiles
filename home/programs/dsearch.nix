{ inputs, ... }:
{
  imports = [
    inputs.danksearch.homeModules.dsearch
  ];

  programs.dsearch = {
    enable = true;

    config.index_paths = [
      {
        path = "~";
        max_depth = 4;
        exclude_hidden = true;
        extract_exif = false;
        merge_default_exclude_dirs = true;
      }
      {
        path = "~/code";
        max_depth = 0;
        exclude_hidden = true;
        extract_exif = false;
        merge_default_exclude_dirs = true;
        exclude_dirs = [ ".git" ".direnv" "result" "target" ];
      }
      {
        path = "~/Downloads";
        max_depth = 2;
        exclude_hidden = true;
        extract_exif = true;
        merge_default_exclude_dirs = true;
      }
    ];
  };
}
