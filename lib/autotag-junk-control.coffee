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
      default: ['@[>] <@text>@cursor</@text>','@[\\s] <@text @cursor></@text>','@[/] <@text @cursor />','@[%?] <@key@text @cursor @key>']
      items:
        type: 'string'
        default: '@[>]<@text>@cursor</@text>'

  activate: (state) ->
    atom.workspaceView.command "autotag-junk-control:open-tag", => @openTag()
    # TODO: fix the hotkeyReg to enable full regex and allow for multiple chars to be matched
    hotkeyReg = /@\[.+?\]/
    @bindCallback()
    for item in atom.config.get('autotag-junk-control.templates')
      @templates.push(
        hotkey: item.match(hotkeyReg)[0][1..]
        template: item.replace(hotkeyReg, '').trim()
      )
    @grammars = atom.config.get('autotag-junk-control.grammars')

  keystrokeCallback: (e) ->
    # normalize the key being pressed into either a character or the word for the key
    if e.keyIdentifier.indexOf('U+') == 0
      str = e.keyIdentifier.replace('U+','0x')
      key = String.fromCodePoint(str)
    else
      key = e.keyIdentifier
    # test each template's hotkey regex for the key being pressed
    template = @templates.filter (item) ->
      ///#{item.hotkey}///.test(key)
    if template[0]?
      e.preventDefault()
      @stop.call(this, key, template[0])

  openTag: ->
    editor = atom.workspace.getActivePaneItem()
    # only allow one instance of Autotag to listen
    return editor.insertText('<') unless @listening and editor.getGrammar().name in @grammars
    @listening = false
    @start = editor.getCursorBufferPosition().translate({row:0,column:1})
    editor.insertText('<\u2026')
    editor.setCursorBufferPosition(@start)
    # listen for the hotkey being pressed
    window.addEventListener('keypress', @bindedCallback)

  stop: (key, template) ->
    # non-alphanumeric
    window.removeEventListener('keypress', @bindedCallback)
    @listening = true
    editor = atom.workspace.getActivePaneItem()
    @end = editor.getCursorBufferPosition()
    textRange = new Range(@start, @end)
    # TODO: make this not look like crap
    wholeRange = new Range(textRange.start.translate({row:0,column:-1}),textRange.end.translate({row:0,column:1}))
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
