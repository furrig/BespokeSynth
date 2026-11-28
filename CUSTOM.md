# What's new in this build (main-custom)

This build is Bespoke Synth from the official `main` branch, up to commit `3278a2e9` "improve performance when drawing long zoomed-out samples (#2168)" from November 26, 2026. It adds the fixes and small improvements below.

---

## Sequencing & sync

### Snapshots now recall the circle sequencer's steps
**Module:** `circlesequencer`

Before, snapshots of a circle sequencer recalled only its knobs and settings. The steps you had placed on each ring weren't saved, so going back to a snapshot didn't bring your pattern back.

Snapshots now store the steps on every ring. Saving and recalling snapshots works for this module the same way as for the other sequencers.

### MIDI clock out stays in sync with external gear
**Module:** `clockout`

Two fixes for sending tempo to drum machines, hardware sequencers or other apps:

- **Correct tempo in every time signature.** MIDI clock is always 24 pulses per quarter note. Before, in time signatures like 6/8 or 7/8, the clock ran at the wrong speed. It now matches Bespoke's tempo in any time signature. The multiplier setting (½×, 2×, …) still works as before.
- **Devices start exactly on the downbeat.** When you start the clock, the "start" message is now sent just before the first pulse of the bar. External devices start on beat 1 instead of one pulse late.

---

## Scripting (`script` module)

### Notes received by a script now include pan
The `on_note` function can now receive the pan of each incoming note:

```python
def on_note(pitch, velocity, pan):
    me.output(f"{pitch} {velocity} {pan}")
```

Existing scripts that use `on_note(pitch, velocity)` keep working unchanged. Add `pan` only if you need it.

### The loaded script file is remembered when you reopen a patch
Before, if a script was loaded from a file with **hotload** turned on, reopening the `.bsk` patch made Bespoke forget which file it came from. Hotload (editing the script in an external editor and having Bespoke reload it on save) stopped working until you loaded the file again by hand.

The patch now remembers the script file, so hotload keeps working after you reopen it. The script dropdown also still points to the right file when you've added or removed files in your scripts folder since saving.

### Scripts can find out more about modules and controls
New Python functions tell a script what it's working with:

- **`module.get(name).get_type()`** returns a module's type (`oscillator`, `notesequencer`, …), even after the module was renamed. **`get_category()`** returns the category shown in the spawn menu (`synths`, `audio effects`, …).
- **`module.get(name).get_control_info("volume")`** describes a control: what kind it is (slider, checkbox, dropdown, button, text, grid), its current value, its range and the text Bespoke shows for it. For a dropdown or radio button it lists every option with the value it sets. Before, a script only got a number and had to guess the rest.
- **`bespoke.get_controls(name, include_hidden=True)`** also lists controls that exist but aren't on screen right now, such as an oscillator's envelope sliders when the envelope view is closed. Without `include_hidden`, it works as before.

### Scripts can load plugins
Before, a script could only create an empty plugin module; picking the plugin had to be done by hand from the menu.

- **`bespoke.get_plugins()`** lists the plugins Bespoke has scanned, as the plugin menu shows them: name, maker, format, category, and whether it's an instrument or an effect.
- **`module.create_plugin("ValhallaSupermassive", x, y)`** creates a plugin module with that plugin in it. Give the plugin's name (or part of it) or its identifier from `get_plugins()`. If the name matches several plugins, the error lists them so you can pick one.
- Plugins take a moment to load. **`vstplugin.get(name).get_plugin_status()`** tells a script whether the plugin is still loading, ready, or failed (and why).

### Fixed crashes when scripts used plugin, sampler and drum modules
Once a script had used the Python functions for plugin modules (`vstplugin`), `sampleplayer`, `midicontroller`, `drumplayer` or `beats`, the general module functions on those modules could read the wrong data and crash Bespoke, for example right after creating a plugin. They now work correctly.

### Script editor improvements
- **Select text with the mouse.** Click and drag to select code, just like in any text editor. If you drag past the top or bottom edge, the code keeps scrolling, faster the further away the mouse is. **Double-click** selects a word, and **triple-click** selects the whole line. Keep the mouse button held after a double- or triple-click to extend the selection word by word or line by line. **Shift-click** extends the current selection.
- **Page Up / Page Down** move through the code one screen at a time. Hold **Shift** to select text while doing so.
- **The scrollbars can be dragged.** Grab a scrollbar to scroll through long or wide scripts, or click anywhere along it to jump there. Scrollbars are twice as thick as before, so they're easier to see and grab, and they light up when the mouse is over them. Clicking a scrollbar keeps your text selection.
- **Fixed syntax colouring with special characters.** A non-English character, an accent, an emoji or a long dash (—) in a script used to scramble the colours for the rest of the script, and some characters were missing from the screen. All text now shows correctly with the right colours.

---

## Interface

### Prefab title bars show their own name
**Module:** `prefab`

Every prefab's title bar used to say "prefab", even after you renamed it, so you couldn't tell several prefabs apart. The title bar now shows the prefab's actual name (for example `drums: mykit` or `prefab2`).

### New shortcut to open the console: Cmd-K
On many non-US keyboards (French, German, …) the **`** key used to open the console is hard to reach. **Cmd-K** now opens the console too.

Also, keyboard shortcuts that use **Cmd** no longer:
- start typing a value into the slider or text field under the mouse
- play notes on a keyboard module under the mouse.

### Copy the path of what's under the mouse: Cmd-Shift-C
Hover over a control or a module and press **Cmd-Shift-C** to copy its path to the clipboard, for example `oscillator~volume` for a control or `oscillator` for a module. You can then paste it anywhere, including other apps. This also works while you're typing in the script editor.

**Cmd-C** over a control still copies its value, as before. In the script editor, **Cmd-Shift-V** still types the hovered path straight into the code.

---

## Stability (macOS)

### Fixed crashes with some VST3 plugins
Some VST3 plugins made with a different version of the same audio framework Bespoke uses (for example the **gearmulator** synths) could crash Bespoke as soon as they were loaded. Bespoke and those plugins no longer interfere with each other, so these plugins load and run normally.

### Fixed a hang when quitting
Since the "all input" MIDI option was added upstream, quitting Bespoke could freeze it. The app never closed and used 100% CPU until you force-quit it. Bespoke now quits normally.

---

## Installing this build (macOS)

The install script builds the app from source and installs it as **BespokeSynth Custom** in `/Applications`, alongside the official **BespokeSynth**. The official app isn't modified. Both can be installed together, and Spotlight and the Dock show them under their own names.

The script installs nothing system-wide. The Python it needs is the same python.org Python 3.10 the official app uses. It's downloaded and unpacked inside the repository, under `ignore/`, then copied into the app.

### What you need first
- **Xcode Command Line Tools**: `xcode-select --install`, or the full Xcode
- **CMake**: `brew install cmake` with [Homebrew](https://brew.sh), or the installer from cmake.org
- An internet connection the first time, to download Python 3.10 and the script autocomplete package (jedi)

### First install
```sh
git clone --recurse-submodules -b main-custom https://github.com/furrig/BespokeSynth.git
cd BespokeSynth
scripts/install_custom_mac.sh
```

If you already have a clone, switch it to this branch and fetch the libraries first:
```sh
git checkout main-custom
git pull
git submodule update --init --recursive
scripts/install_custom_mac.sh
```

The first build takes a while. Later runs only rebuild what changed.

### Updating
Quit BespokeSynth Custom, then run:
```sh
git pull
git submodule update --init --recursive
scripts/install_custom_mac.sh
```

### Good to know
- If BespokeSynth Custom is running, the script stops without changing the installed app. Quit the app and run the script again.
- The build uses 10 parallel jobs. On a machine with less memory or fewer cores, use fewer jobs, for example `JOBS=4 scripts/install_custom_mac.sh`.
- Your settings, layouts and saved patches are shared with the official app: both use the `Documents/BespokeSynth` folder.
- To uninstall, delete `/Applications/BespokeSynth Custom.app`. The build files are in `ignore/` inside the repository, and you can delete them too.
