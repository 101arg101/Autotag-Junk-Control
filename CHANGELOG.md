## 0.2.0 - Enter the regex
Full regex support for tags and changed the template variables. Instead of listening to single key presses using `@[regex]`, you can now express full JS regex with `@/regex/` in your template. However, it still won't accept flags.

### New Variables
* `@0`, `@1`, `@2`, etc. These tags get regex groups. `@0` always gets the entire match while the following numbers get the following groups.
* `@tag` is what `@text` used to be. It gets everything typed that isn't matched and isn't the opening bracket.
* `@text` is removed to lessen what might be confusing for an intended future release.
* `@key` is removed since you can now get the last key pressed with a regex group, and then access it with `@X`.

## 0.1.2
* Fixified more bugs
* Speedified some badly written code

## 0.1.1
* Fixified a bug

## 0.1.0 - First Release
* In a usable state
