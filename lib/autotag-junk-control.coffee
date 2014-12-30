{$$, Point, Range} = require 'atom'
module.exports =
  config:
    grammars:
      type: 'array'
      description: 'Grammars that Autotag Junk Control should run on.'
      default: ['PHP', 'XML', 'HTML', 'HTML (GO)', 'HTML (Rails)', 'HTML (Moustache)', 'HTML (Ruby - ERB)']
      items:
        type: 'string'
        default: 'HTML'
    templates:
      type: 'array'
      description: 'View the readme for more info about creating a template.'
      default: ['@/>/ <@text>@cursor</@text>',
        '@/\\s/ <@text @cursor></@text>',
        '@/[%?]/ <@0@text @cursor @0>',
        '@/(img)\\s/ <@1 src="@cursor"/>',
        '@/(area|base|br|col|command|embed|img|input|keygen|hr|link|meta|param|source|track|wbr)\\s/ <@1 @cursor />',
        '@/(area|base|br|col|command|embed|img|input|keygen|hr|link|meta|param|source|track|wbr)>/ <@1 /> @cursor']
      items:
        type: 'string'
        default: '@/>/<@text>@cursor</@text>'

  activate: (state) ->
    atom.workspaceView.command "autotag-junk-control:open-tag", => @openTag()

    for item in atom.config.get 'autotag-junk-control.templates'
      hotkey = @charSubstr(item, '@/', '/')
      @templates.push
        hotkey: hotkey
        template: item.replace('@/' + hotkey + '/', '').trim()
    @templates.reverse()
    @grammars = atom.config.get 'autotag-junk-control.grammars'
    @txt = ''
    @bindCallback()

  charSubstr: (str, from, to) ->
    index = str.indexOf(from) + from.length
    char = str.charAt index
    concat = ''
    while char != to
      concat += char
      if char == '\\'
        ++index
        concat += str.charAt index
      ++index
      char = str.charAt index
    return concat

  keystrokeCallback: (e) ->
    # normalize the key being pressed into either a character or the word for the key
    if e.keyIdentifier.indexOf 'U+' == 0
      str = e.keyIdentifier.replace 'U+', '0x'
      key = String.fromCodePoint str
    else
      key = e.keyIdentifier
    # test each template's hotkey regex for the key being pressed
    txt = @txt
    template = @templates.filter (item) ->
      console.log(txt + key)
      ///#{item.hotkey}///i.test(txt + key)
    console.log(template)
    if template[0]?
      e.preventDefault()
      @stop.call(this, key, template[0])
    else
      @txt += key

  openTag: ->
    editor = atom.workspace.getActivePaneItem()
    # only allow one instance of Autotag to listen
    return editor.insertText('<') unless @listening and editor.getGrammar().name in @grammars
    # TODO: change @listening to @step to determine how many keypresses Autotag listened to. After about 16 or so, automatically close.
    @listening = false
    @txt = ''
    @start  = editor.getCursorBufferPosition().translate({row: 0, column: 1})
    @starts = editor.getCursorBufferPositions().map (position) ->
      position.translate({row: 0, column: 1})
    editor.insertText('<\u2026')
    # editor.setCursorBufferPosition(@start)
    editor.moveRight()
    # listen for the hotkey being pressed
    window.addEventListener('keypress', @bindedCallback)

  stop: (key, template) ->
    # non-alphanumeric
    window.removeEventListener('keypress', @bindedCallback)
    @listening = true
    editor = atom.workspace.getActivePaneItem()
    @end = editor.getCursorBufferPosition()
    textRange = new Range(@start, @end)
    # TODO: put all of the template generation into a new class that is pre-parsed
    wholeRange = new Range(textRange.start.translate({row: 0, column: -1}), textRange.end.translate({row: 0, column: 1}))
    text = editor.getTextInBufferRange(textRange)
    # compile output
    out = template.template.replace /@key/g, key
    out = out.replace /@text/g, text
    # get cursor positions and remove "@cursor" from output
    cursorPositions = []
    while match = /@cursor/g.exec out
      out = out[0...match.index] + out[(match.index + 7)..]
      cursorPositions.push [@start.row, @start.column + match.index - 1]
    editor.setTextInBufferRange(wholeRange, out)
    editor.setCursorBufferPosition(cursorPositions[0])
    for position in cursorPositions
      editor.addCursorAtBufferPosition(position)

  bindCallback: ->
    @bindedCallback = @keystrokeCallback.bind(this)

  listening: true
  templates: []
