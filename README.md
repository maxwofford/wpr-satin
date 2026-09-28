# <name>

<!-- probably add an image here once you have one! -->

a shader for [wpr](https://github.com/maxwofford/wpr), the wallpaper manager.

```sh
brew tap maxwofford/wpr && brew install wpr   # if you don't have wpr yet

wpr install <you>/<name>
wpr gen <name>                                # a new one, set as your wallpaper
wpr enable <name>                             # add it to your rotation
```

## local development

wanna clone and iterate on the design?

```sh
git clone https://github.com/username/wpr-myshader
wpr install ./myshader
wpr gen myshader
```

