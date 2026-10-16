{ config, pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "ytmp3";
      runtimeInputs = [
        pkgs.yt-dlp
        pkgs.ffmpeg
      ];
      text = ''
        if [ $# -eq 0 ]; then
          echo "Usage: ytmp3 <youtube-url> [yt-dlp options...]"
          echo "Tip: quote the URL, e.g. ytmp3 \"https://www.youtube.com/watch?v=...\""
          exit 1
        fi

        url="$1"
        shift

        mkdir -p "$HOME/Desktop"
        yt-dlp \
          --extract-audio \
          --audio-format mp3 \
          --audio-quality 0 \
          --embed-metadata \
          --embed-thumbnail \
          --cookies-from-browser firefox \
          --extractor-args "youtube:player_client=web" \
          --user-agent "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0" \
          -o "$HOME/Desktop/%(title)s.%(ext)s" \
          "$@" \
          "$url"
      '';
    })
  ];
}
