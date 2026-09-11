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

    (pkgs.writeShellApplication {
      name = "dictate";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.curl
        pkgs.libnotify
        pkgs.pipewire
        pkgs.whisper-cpp
        pkgs.xclip
      ];
      text = ''
        set -euo pipefail

        MODEL_DIR="$HOME/.local/share/whisper/models"
        MODEL="ggml-base-q5_1.bin"
        MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$MODEL"
        PID_FILE="/tmp/dictate.pid"
        TMP_FILE="/tmp/dictate.tmpdir"
        LOG_DIR="$HOME/.local/state/dictate"
        LOG_FILE="$LOG_DIR/dictate.log"

        mkdir -p "$MODEL_DIR" "$LOG_DIR"

        log() {
          echo "$(date -Iseconds) $*" >> "$LOG_FILE"
        }

        notify() {
          notify-send -a "Dictate" "$@" 2>/dev/null || true
        }

        if [ ! -f "$MODEL_DIR/$MODEL" ]; then
          notify "Downloading model..."
          log "downloading model $MODEL"
          curl -fsSL -o "$MODEL_DIR/$MODEL" "$MODEL_URL"
        fi

        stop_recording() {
          if [ -f "$PID_FILE" ]; then
            local pid
            pid="$(cat "$PID_FILE")"
            kill "$pid" 2>/dev/null || true
            rm -f "$PID_FILE"
          fi
        }

        if [ -f "$PID_FILE" ]; then
          # Second press: stop recording and transcribe.
          stop_recording

          tmpdir="$(cat "$TMP_FILE")"
          rm -f "$TMP_FILE"

          audio="$tmpdir/dictate.wav"
          debug_audio="$LOG_DIR/last.wav"

          cp "$audio" "$debug_audio"
          file_size=$(stat -c%s "$debug_audio" 2>/dev/null || echo 0)
          log "saved recording to $debug_audio ($file_size bytes)"

          notify "Transcribing..."
          log "transcribing $audio"

          set +e
          whisper-cli \
            --model "$MODEL_DIR/$MODEL" \
            --file "$audio" \
            --output-file "$tmpdir/dictate" \
            --output-txt \
            --no-timestamps \
            --language en \
            --no-context \
            --threads 4 \
            >> "$LOG_FILE" 2>&1
          exit_code=$?
          set -e

          rm -f "$audio"

          if [ "$exit_code" -ne 0 ]; then
            notify --urgency=critical "Transcription failed" "See $LOG_FILE"
            log "transcription failed with exit code $exit_code"
            rm -rf "$tmpdir"
            exit 1
          fi

          if [ ! -f "$tmpdir/dictate.txt" ]; then
            notify "No transcript produced"
            log "no transcript file produced"
            rm -rf "$tmpdir"
            exit 1
          fi

          transcript="$(tr '\n' ' ' < "$tmpdir/dictate.txt" | sed 's/^ *//;s/ *$//')"
          rm -rf "$tmpdir"

          if [ -n "$transcript" ]; then
            printf '%s' "$transcript" | xclip -selection clipboard
            notify "Copied to clipboard" "$transcript"
            log "copied: $transcript"
          else
            notify "No speech detected"
            log "no speech detected"
          fi
        else
          # First press: start recording.
          tmpdir="$(mktemp -d)"
          echo "$tmpdir" > "$TMP_FILE"

          pw-record --rate=16000 --channels=1 --format=s16 "$tmpdir/dictate.wav" &
          echo $! > "$PID_FILE"

          notify "Recording..." "Press Super+Shift+D again to stop"
          log "recording started"
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "audio-debug";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.pipewire
        pkgs.wireplumber
      ];
      text = ''
        set -euo pipefail

        STATE_DIR="$HOME/.local/state/dictate"
        LAST_RECORDING="$STATE_DIR/last.wav"

        usage() {
          cat <<EOF
        Usage: audio-debug <command> [args]

        Commands:
          status                  Show default audio source/sink and volumes
          sources                 List input sources with IDs
          sinks                   List output sinks with IDs
          inspect [id]            Inspect default source (or given id)
          record-test [seconds]   Record a test file and play it back
          play-last               Play the last dictated recording
          set-input-volume <vol>  Set default input volume (e.g. 0.4 or 40%)
          mute-input [1|0|toggle] Mute/unmute/toggle default input
          info                    Full audio status dump

        Examples:
          audio-debug status
          audio-debug record-test 5
          audio-debug set-input-volume 0.4
        EOF
        }

        cmd_status() {
          echo "=== Audio Status ==="
          echo
          echo "--- Default Source (input) ---"
          wpctl status | sed -n '/Sources:/,/Filters:/p' | grep -E '\*' | head -1 || true
          wpctl get-volume @DEFAULT_AUDIO_SOURCE@ || true
          echo
          echo "--- Default Sink (output) ---"
          wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -E '\*' | head -1 || true
          wpctl get-volume @DEFAULT_SINK@ || true
        }

        cmd_sources() {
          echo "=== Input Sources ==="
          wpctl status | awk '/Sources:/{flag=1; next} /Filters:/{flag=0} flag' || true
        }

        cmd_sinks() {
          echo "=== Output Sinks ==="
          wpctl status | awk '/Sinks:/{flag=1; next} /Sources:/{flag=0} flag' || true
        }

        cmd_inspect() {
          local target="''${1:-@DEFAULT_AUDIO_SOURCE@}"
          echo "=== Inspecting $target ==="
          wpctl inspect "$target" || true
        }

        cmd_record_test() {
          local seconds="''${1:-5}"
          local tmpfile
          tmpfile="$(mktemp -t audio-debug-XXXXXX.wav)"

          echo "Recording for $seconds seconds..."
          pw-record --rate=16000 --channels=1 --format=s16 "$tmpfile" &
          local pid=$!
          sleep "$seconds"
          kill "$pid" 2>/dev/null || true
          wait "$pid" 2>/dev/null || true

          echo "Saved: $tmpfile"
          echo "File size: $(stat -c%s "$tmpfile") bytes"
          echo
          echo "Playing back..."
          pw-play "$tmpfile" || echo "Playback failed. Inspect the file with: pw-play $tmpfile"
        }

        cmd_play_last() {
          if [ ! -f "$LAST_RECORDING" ]; then
            echo "No last recording found at $LAST_RECORDING"
            exit 1
          fi
          echo "Playing $LAST_RECORDING ($(stat -c%s "$LAST_RECORDING") bytes)"
          pw-play "$LAST_RECORDING"
        }

        cmd_set_input_volume() {
          if [ $# -eq 0 ]; then
            echo "Usage: audio-debug set-input-volume <vol>"
            echo "Example: audio-debug set-input-volume 0.4"
            exit 1
          fi
          wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$1"
          wpctl get-volume @DEFAULT_AUDIO_SOURCE@
        }

        cmd_mute_input() {
          local state="''${1:-toggle}"
          wpctl set-mute @DEFAULT_AUDIO_SOURCE@ "$state"
          wpctl get-volume @DEFAULT_AUDIO_SOURCE@
        }

        cmd_info() {
          echo "=== WirePlumber Status ==="
          wpctl status
          echo
          echo "=== Default Source Inspect ==="
          wpctl inspect @DEFAULT_AUDIO_SOURCE@ || true
        }

        main() {
          if [ $# -eq 0 ]; then
            usage
            exit 1
          fi

          local cmd="$1"
          shift

          case "$cmd" in
            status) cmd_status "$@" ;;
            sources) cmd_sources "$@" ;;
            sinks) cmd_sinks "$@" ;;
            inspect) cmd_inspect "$@" ;;
            record-test) cmd_record_test "$@" ;;
            play-last) cmd_play_last "$@" ;;
            set-input-volume) cmd_set_input_volume "$@" ;;
            mute-input) cmd_mute_input "$@" ;;
            info) cmd_info "$@" ;;
            -h|--help|help) usage ;;
            *)
              echo "Unknown command: $cmd"
              usage
              exit 1
              ;;
          esac
        }

        main "$@"
      '';
    })
  ];
}
