# ZeroTV

ZeroTV is an IPTV application for tvOS. It relies on [TVVLCKit](https://code.videolan.org/videolan/VLCKit) and has borrowed some code from the [VLC AppleTV application](https://www.videolan.org/vlc/download-appletv.html).

## Features include:

* Quick access to your list of favorite shows
* Subtitle support for VOD episodes (powered by OpenSubtitles.org, API key required)
* Subtitle selection for Live channels with subtitle tracks
* Subtitle offset adjustment
* Episodes that have been watched will be marked with a checkmark
* Manually marking an episode as watched or unwatched
* Resuming a partially watched episode
* Jumping forward/backward 10 seconds
* Scrubbing (for non-linear content)
* Search
* Manifest will be cached and is easily updated within app

## Setup

* Create `Config.plist` at `ZeroTV/Config.plist`
* Add your IPTV manifest URL to `ManifestURL` in `Config.plist`
* Add your OpenSubtitles.org API Key to `OpenSubtitlesAPIKey` in `Config.plist`
* Configure the `FavoriteShows` array in `Config.plist` with the titles of your favorite shows.

## Possible Future Features

* Bookmarking specific episodes

## License

ZeroTV is under the [LGPLv2.1](https://opensource.org/licenses/LGPL-2.1) license.
