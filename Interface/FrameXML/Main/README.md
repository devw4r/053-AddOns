# Main

`Main` is the clean rewrite branch for the legacy custom addon suite in this repository.

Current scaffold:

- adds an `Addons` button to the escape menu
- adds an in-game manager frame
- includes first-pass modules for buff durations, instant quest text, a movable clock, and an open-all-bags button

Notes:

- the legacy addons are intentionally left untouched
- the TOC entry for `Main` is added commented out so you can enable it only when you want to test it
- this first scaffold keeps settings in-session only; `Main.autoexec.wtf.sample` is included as a starting point for later custom CVar bootstrap work
- 0.5.3 UI scale is not scriptable from Lua; the client applies it through the internal `scaleui` console command, so use an external helper or `WTF/autoexec.wtf` for launch-time scale changes

Attribution:

- this rewrite is based on the ideas from the original custom UI work already present in this repository, while keeping the new runtime identifiers under the `Main` name only
