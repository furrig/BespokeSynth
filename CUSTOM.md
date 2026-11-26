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

---

## Stability (macOS)

### Fixed crashes with some VST3 plugins
Some VST3 plugins made with a different version of the same audio framework Bespoke uses (for example the **gearmulator** synths) could crash Bespoke as soon as they were loaded. Bespoke and those plugins no longer interfere with each other, so these plugins load and run normally.

### Fixed a hang when quitting
Since the "all input" MIDI option was added upstream, quitting Bespoke could freeze it. The app never closed and used 100% CPU until you force-quit it. Bespoke now quits normally.
