# Steam-Workshop-Downloader
<img alt="Visitors" src="https://visitor-badge.laobi.icu/badge?page_id=Be1zebub.Steam-Workshop-Downloader"/> 

console tool for batch downloading workshop items from your terminal!
![Preview GIF](https://github.com/Be1zebub/Steam-Workshop-Downloader/blob/main/preview.gif?raw=true)
![Preview JPG](https://github.com/Be1zebub/Steam-Workshop-Downloader/blob/main/preview.jpg?raw=true)

## Installation:

1. Install luvit: https://luvit.io/install.html
2. Install dependencies:
```shell
lit install creationix/coro-http@3.1.0
lit install creationix/coro-websocket@3.1.0
lit install luvit/secure-socket@1.2.2
```
3. Grab your workshop `.json` items list with: https://gist.github.com/BrynM/c1b49804e53d7c406143a9ae40ed65ad

## Usage:
Make shure you have `swd.lua` and `addons.json` & then just run downloader with: `luvit swd.lua`   
If the game whose workshop items you are downloading is not a gmod, use `luvit swd.lua raw`
