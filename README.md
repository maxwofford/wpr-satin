# satin

![](https://user-cdn.hackclub-assets.com/01a0f032-f1f0-754a-abee-3290ddecc891/satin-134516-2940x1912.png)

a shader for [wpr](https://github.com/maxwofford/wpr), the wallpaper manager.
diagonal bands of teal, cream and plum. all creative credit to a piece by
[strano](https://x.com/5tr4n0/status/2103247586815873535)

```sh
brew tap maxwofford/wpr && brew install wpr   # if you don't have wpr yet

wpr install maxwofford/satin
wpr gen satin                                 # a new one, set as your wallpaper
wpr enable satin                              # add it to your rotation
```

## parameters

the seed picks all of these. `--set` any of them to pin it:

```sh
wpr gen satin --set hue=0       # turn of the ramp around grey, 0..1; 0 is the reference's teal and plum
wpr gen satin --set bands=3.6   # folds across the screen's height
wpr gen satin --set warp=1      # how far the noise bends the folds
wpr gen satin --set grain=1     # per-pixel jitter of the ramp, 0 for smooth
wpr gen satin --set tilt=34     # degrees the folds fall by
wpr gen satin --set flip=0      # 1 puts the sharp edge on the other side of each fold
```

## local development

wanna clone and iterate on the design?

```sh
git clone https://github.com/maxwofford/wpr-satin
wpr install ./wpr-satin
wpr gen satin
```
