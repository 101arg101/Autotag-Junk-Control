# Autotag Junk Control

The grammars list in the settings defines which languages Autotag should run on. When running `autotag-junk-control:open-tag` outside of a specified grammar or running it while you have an open tag, it will insert `<`.

Templates are rendered when you type a character
You don't need to escape `@` in your templates.

* `@[regex]` defines regex that closes the tag when you press a key that matches it. It does not accept flags and only accepts POSIX expressions.
* `@text` outputs to the text you type in between the opening and closing characters.
* `@cursor` dictates where the cursor(s) will be placed in the template.
* `@key` is the character pressed to close the tag.

If you want to add a template, keep the originals, and don't wanna dig through the source code to find them (they're at the top), then copy & paste `@[>] <@text>@cursor</@text>, @[\s] <@text @cursor></@text>, @[/] <@text @cursor />, @[%?] <@key@text @cursor @key>`

![A screenshot of your spankin' package](https://f.cloud.github.com/assets/69169/2290250/c35d867a-a017-11e3-86be-cd7c5bf3ff9b.gif)

TODO:

  1. Add support for enclosing selections with Autotag
  2. Add more robust regex handling to support patterns more than 1 character in length. e.g. being able to match `img>` and treat it differently than matching `>`.
  3.
