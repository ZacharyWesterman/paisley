# Paisley (Plasma Build)

Note: this only applies to the Plasma build of Paisley. Most features are supported, but some are disallowed, and are specified below the FAQ.

---

**PAISLey** (Plasma Automation / Instruction Scripting Language) is a scripting language designed to allow for easy command-based behavior scripting.
The purpose of this language is NOT to be fast. Instead, Paisley is designed to be a simple, light-weight way to chain together more complex behavior (think NPC logic, device automation, etc.).
This language is meant to make complex device logic very easy to implement, while also being as easy to learn as possible.

---

## FAQ
**Q:** *Why not use Lua instead?*<br>
**A:** The biggest advantage Paisley has over Lua nodes is that the script does not require any "pausing" logic that one would have to implement in order to get the same functionality in Lua; the Paisley runtime will automatically pause execution periodically to avoid Lua timeouts or performance drops, and will always wait on results from a command before continuing execution.

**Q:** *Why not use sketch nodes instead?*<br>
**A:** Paisley was designed as a language for scripting NPC behavior, and the thing about NPCs is that their behavior needs to be able to change in response to various events. First off, when using just sketch nodes, dynamically changing an NPC's programming is downright impossible. Second, connecting all the nodes necessary for every possible event is difficult and time consuming (for example NPC chatter, a sequence of movements, events that only happen ONCE, etc). TL;DR: NPC logic is difficult to implement using just sketch nodes. Trust me, I've done it.

**Q:** *How do I connect the Paisley engine to my device?*<br>
**A:** Get the Paisley Engine device from the Steam workshop (ID **3087775427**), and attach it to your device. Then in a different controller, set the inputs (Paisley code, a list of valid commands for this device, and optional file name), and make sure the "Run Command" output will eventually flow back into the "Command Return" input. Keep in mind this MUST have a slight delay (0.02s at least) or Plasma will detect it as an infinite loop!

**Q:** Why???<br>
**A:** haha

**Q:** Isn't writing an entire compiler in Plasma a bit overkill?<br>
**A:** Your face is overkill. Compilers are fun, fight me.

---

## Differences from the main build.

Compiler Differences:
- The `require` statement is not supported when compiling code inside Plasma, as there is no arbitrary file system. However, it may be used when compiling code *outside* Plasma and copying the bytecode output into Plasma.
- Command piping (`cmd1 | cmd2 > file1 < file2`) is not supported. Any pipe operators are treated as plain text.

The following commands will not work in the Plasma build, unless the commands are defined in the target device:
- Any shell commands, `!`, `?`, `?!` or `=`.
- `clear`
- `stdin`
- `stdout`
- `stderr`

The following functions will not work in the Plasma build:
- `toepoch`
- `fromepoch`
- `epochnow`
- `file_glob`
- `file_exists`
- `file_size`
- `file_read`
- `file_write`
- `file_append`
- `file_delete`
- `dir_create`
- `dir_list`
- `dir_delete`
- `file_type`
- `file_stat`
- `file_copy`
- `file_move`

Note that all commands take a little bit of time to run (at least 0.02s), whether they're built-in or not. This is to prevent "infinite loop" errors or performance drops.
The only exception to this is the `.` no-op command. It does not actually interact with the outside world, so it will complete immediately.

### Escape sequences

All escape sequences work the same, however internally the emoji sequences are represented differently. Instead of unicode symbols, they're stored as `<sprite=XX>` tags.

- `\^-^` outputs `<sprite=0>`
- `\:relaxed:` outputs `<sprite=0>`
- `\:P` outputs `<sprite=1>`
- `\:yum:` outputs `<sprite=1>`
- `\<3` outputs `<sprite=2>`
- `\:heart_eyes:` outputs `<sprite=2>`
- `\B)` outputs `<sprite=3>`
- `\:sunglasses:` outputs `<sprite=3>`
- `\:D` outputs `<sprite=4>`
- `\:grinning:` outputs `<sprite=4>`
- `\^o^` outputs `<sprite=5>`
- `\:smile:` outputs `<sprite=5>`
- `\XD` outputs `<sprite=6>`
- `\:laughing:` outputs `<sprite=6>`
- `\:lol:` outputs `<sprite=6>`
- `\=D` outputs `<sprite=7>`
- `\:smiley:` outputs `<sprite=7>`
- `\:sweat_smile:` outputs `<sprite=9>`
- `\DX` outputs `<sprite=10>`
- `\:tired_face:` outputs `<sprite=10>`
- `\;P` outputs `<sprite=11>`
- `\:stuck_out_tongue_winking_eye:` outputs `<sprite=11>`
- `\:-*` outputs `<sprite=12>`
- `\;-*` outputs `<sprite=12>`
- `\:kissing_heart:` outputs `<sprite=12>`
- `\:kissing:` outputs `<sprite=12>`
- `\:rofl:` outputs `<sprite=13>`
- `\:)` outputs `<sprite=14>`
- `\:slight_smile:` outputs `<sprite=14>`
- `\:(` outputs `<sprite=15>`
- `\:frown:` outputs `<sprite=15>`
- `\:frowning:` outputs `<sprite=15>`
