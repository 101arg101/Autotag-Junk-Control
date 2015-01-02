{$, Point, Range} = require 'atom'
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
      # default: ['@/>/ <@tag></@tag>',
      #   '@/\\s/ <@tag ></@tag>',
      #   '@/[%?]/ <@0@tag  @0>',
      #   '@/(img)\\s/ <@1 src="@cursor"/>',
      #   '@/(area|base|br|col|command|embed|img|input|keygen|hr|link|meta|param|source|track|wbr)\\s/ <@1  />',
      #   '@/(area|base|br|col|command|embed|img|input|keygen|hr|link|meta|param|source|track|wbr)>/ <@1 />']
      default: ['@/>/ <@tag>@cursor</@tag>',
        '@/\\s/ <@tag @cursor></@tag>',
        '@/[%?]/ <@0@tag @cursor @0>',
        '@/(img)\\s/ <@1 src="@cursor" />',
        '@/(area|base|br|col|command|embed|input|keygen|hr|link|meta|param|source|track|wbr)\\s/ <@1 @cursor />',
        '@/(area|base|br|col|command|embed|input|keygen|hr|link|meta|param|source|track|wbr)>/ <@1 />@cursor']
      items:
        type: 'string'
        default: '@/>/<@tag>@cursor</@tag>'

  activate: (state) ->
    atom.workspaceView.command "autotag-junk-control:open-tag", => @openTag()

    for item in atom.config.get 'autotag-junk-control.templates'
      hotkey = @charSubstr(item, '@/', '/')
      # @templates.push
      #   hotkey: hotkey
      #   template: item.replace('@/' + hotkey + '/', '').trim()
      @templates.push new AutotagTemplate(hotkey, item.replace('@/' + hotkey + '/', '').trim())
    @templates.reverse()
    @grammars = atom.config.get 'autotag-junk-control.grammars'
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
    editor = atom.workspace.getActivePaneItem()
    if e.charCode?
      @txt += String.fromCharCode(e.charCode)
    else
      return
    # test each template's hotkey regex for the key being pressed
    txt = @txt
    template = @templates.filter (item) ->
      item.regex.test(txt)
    if template[0]?
      e.preventDefault()

      # TODO: pass regex.exec to @stop.call instead of key for Template.render()
      end = editor.getCursorBufferPosition()
      wholeRange = new Range(@start, end.translate({row: 0, column: 1}))
      template[0].render(template[0].regex.exec(txt), wholeRange, @)

      window.removeEventListener 'keypress', @bindedCallback
      @listening = true

  openTag: ->
    editor = atom.workspace.getActivePaneItem()
    # only allow one instance of Autotag to listen
    return editor.insertText('<') unless @listening and editor.getGrammar().name in @grammars
    # TODO: change @listening to @step to determine how many keypresses Autotag listened to. After about 16 or so, automatically close.
    @listening = false
    @txt = ''
    @start  = editor.getCursorBufferPosition()
    # TODO: support multiple cursors/selections
    # @starts = editor.getCursorBufferPositions().map (position) ->
    #   position.translate({row: 0, column: 1})
    editor.insertText '<\u2026'
    editor.setCursorBufferPosition @start
    editor.moveRight()
    # listen for the hotkey being pressed
    window.addEventListener 'keypress', @bindedCallback

  bindCallback: ->
    @bindedCallback = @keystrokeCallback.bind(@)

  listening: true
  templates: []
  newTemplates: []
  txt: ''

class AutotagTemplate
  constructor: (hotkey, template) ->
    @regex = ///#{hotkey}///
    @concatable = template.split /@(?=\d+|cursor|tag)/g
    @rawTemplate = template

    @render = (match, wholeRange, autotag) ->
      # fetch editor data
      editor = atom.workspace.getActivePaneItem()
      tag = editor.getTextInBufferRange(wholeRange).replace(@regex, '')[1...-1]
      # prepare concat
      cursorPositions = []
      currPosition = 0
      concatable = @concatable.map (item) ->
        currMatch = item.match(/^\d+|cursor|tag/)
        if currMatch? then currMatch = currMatch[0]
        if currMatch == 'cursor'
          item = item.replace 'cursor', ''
          cursorPositions.push currPosition
        else if currMatch == 'tag'
          item = item.replace 'tag', tag
        else if parseInt currMatch
          item = item.replace /^\d+/, match[currMatch]
        currPosition += item.length
        item
      editor.setTextInBufferRange(wholeRange, concatable.join(''))

      editor.setCursorBufferPosition(autotag.start.add([0, cursorPositions[0]]))
      for position in cursorPositions
        editor.addCursorAtBufferPosition(autotag.start.add([0, position]))

    @renderOrig = (match, wholeRange) ->
      editor = atom.workspace.getActivePaneItem()
      tagRange = new Range(wholeRange[0].translate({row: 0, column: 1}), wholeRange[1].translate({row: 0, column: -1}))
      tag = editor.getTextInBufferRange(tagRange).replace @regex, ''
      # compile output
      out = out.replace /@tag/g, tag
      # get cursor positions and remove "@cursor" from output
      while match = /@cursor/g.exec out
        out = out[0...match.index] + out[(match.index + 7)..]
        cursorPositions.push [wholeRange[0].row, tagRange[0].column + match.index]
      editor.setTextInBufferRange(wholeRange, out)
      editor.setCursorBufferPosition(cursorPositions[0])
      for position in cursorPositions
        editor.addCursorAtBufferPosition(position)
