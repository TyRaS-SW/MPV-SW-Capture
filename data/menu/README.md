# Saved menu settings

Runtime preferences live here and are excluded from Git:

- `audio_mode.txt`: `plugin`, `mpv`, or `ffplay`. New installations default to
  **WASAPI Audio Plugin**; the release must include `scripts/msc_audio.dll`.
- `boost.txt`: audio boost percentage, shared by all audio backends.
- `hover_volume.txt`: `yes` or `no` for the hover volume sidebar.

Existing settings are copied from `data/` when the corresponding file here
does not exist. Existing files here take precedence. Old files remain as
backups and are no longer updated. Release packages should leave this folder's
runtime `.txt` files out so upgrades preserve users' selections.

To switch back manually, close the app and write `ffplay` to
`data/menu/audio_mode.txt`. Settings changes to the audio mode apply on the next
launch; volume and boost still control the currently running backend.
