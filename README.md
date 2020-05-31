## MPV slicing reencode for windows platform

Lua script for mpv player on windows, to cut single slices of video and reencode to lightweight mp4.

If you want a direct copy AV-stream of the slice, Check this script other script : [Pullusb/mpv-video-splice](https://github.com/Pullusb/mpv-video-splice)  
You can load both scripts (no keymap overlap)

**Requires: ffmpeg**

/!\ This fork is a windows port of the original code from [robsalasco](https://github.com/robsalasco/mpv_slicing) itself forked from [Kagami](https://github.com/Kagami/mpv_slicing)

Go there if you are Unix users.

Difference with forked source script :

- Slice video is exported in the same directory as the original video
- Reencode to lightweight mp4 intead of uncompressed RGB (to revert back to original behevior check the big commented template block at the beginning)
<!-- original was set in uncompressed RGB format which might be useful for video editing. -->

#### Usage

Put the srcipt in mpv scripts directory to autoload the script or load it manually with `--script=<path>`
Folder located in `C:\Users\USERNAME\AppData\Roaming\mpv\scripts`, create `scripts` folder if not exists.

Press `c` first time to mark the start of the fragment. Press it again to mark the end of the fragment and write it to the disk.

Press `a` to toggle uncompressed audio capturing (default on). By default output videos will be placed in the home directory.

You could change key bindings and all parameters of the output video by editing your `input.conf` and `lua-settings/slicing.conf`, see [slicing.lua](https://github.com/Kagami/mpv_slicing/blob/master/slicing.lua) for details.

#### License

mpv_slicing - Cut video fragments with mpv

Written in 2015 by Kagami Hiiragi <kagami@genshiken.org>

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.

You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
