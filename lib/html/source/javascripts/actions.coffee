#= require websocket.coffee
$.extend WSClient.prototype.actions,
  append: (data) ->
    @__parent.check_target(data)
    element = $("#console-#{data.target}")
    marginSize = 16
    atBottom = element.scrollTop() >= element[0].scrollHeight - element.height() - marginSize - 2 or element[0].scrollHeight - marginSize < element.height()
    console.log "top: #{element.scrollTop()} height: #{element[0].scrollHeight - element.height() - marginSize} marginSize: #{marginSize} atBottom: #{atBottom}"
    element.append(@__parent.escape(data.text, data))
    element.scrollTop(element[0].scrollHeight - element.height() - marginSize) if atBottom

  replace: (data) ->
    @__parent.check_target(data)
    $("#console-#{data.target}").html(@__parent.escape(data.text, data))

  clear: (data) ->
    @__parent.check_target(data)
    $("#console-#{data.target}").html("") # empty() is really slow for some reason

  addpane: (data) ->
    if data.target
      target = @__parent.check_target(data)
    else
      target = $('#panes')

    target.append("<pre class='pane' id='console-#{data.name}'><pre>") if target.find("#console-#{data.name}").size() is 0
    @__parent.resize_panes(data)

  closepane: (data) ->
    target = $("#console-#{data.target}")
    unless target.size() is 0
      target.remove()
      @__parent.resize_panes(data)

  hidepane: (data) ->
    target = @__parent.check_target(data)
    target.addClass("hidden")
    target.removeClass("pane")
    @__parent.resize_panes({target_element:target.parent()})

  showpane: (data) ->
    target = @__parent.check_target(data)
    target.addClass("pane")
    target.removeClass("hidden")
    @__parent.resize_panes(data)

  reorient: (data) ->
    if data.target
      target = @__parent.check_target(data)
    else
      target = $('#panes')

    if data.orientation is "horizontal"
      target.addClass("horizontal")
    else
      target.removeClass("horizontal")
    @__parent.resize_panes(data)

  highlight: (data) ->
    target = @__parent.check_target(data)
    code = $("<code>#{ansi_up.escape_for_html(data.text)}</code>")
    code.addClass data.language if data.language
    @__parent.add(code, target, data)
    hljs.highlightBlock(code[0])

  markdown: (data) ->
    target = @__parent.check_target(data)
    newblock = $("<div class='markdown'></div>")
    newblock.html(data.text)
    @__parent.add(newblock, target, data)

  button: (data) ->
    target = @__parent.check_target(data)
    class_name = if data.inline then 'inline-button' else 'full-button'
    element = $("<a href='#' class='#{class_name}'>#{@__parent.escape(data.label, data)}</a>")
    element.click =>
      @__parent.send({
        id:data.id
        action:'callback'
        source:'button'
        original_msg:data
        })
    target.append element

  buttonbox: (data) ->
    target = @__parent.check_target(data)

    element = target.find("#console-#{data.name}")
    if element.size() is 0
      target.prepend("<pre class='button-box' id='console-#{data.name}'></pre>")
    else
      element.addClass('button-box')

  break: (data) ->
    target = @__parent.check_target(data)
    code = $("<hr>")
    @__parent.add(code, target, data)

  subpane: (data) ->
    target = @__parent.check_target(data)
    element = target.find("#console-#{data.name}")
    if element.size() is 0
      target.append("<pre id='console-#{data.name}' class='pane'></pre>")

  input: (data) ->
    target = @__parent.check_target(data)
    if data.multiline
      element = $("<textarea placeholder='#{data.label}' class='inline-text-input'></textarea>")
    else
      element = $("<input type='text' placeholder='#{data.label}' class='inline-text-input'>")
    if data.value
      element[0].value = data.value

    element.change =>
      unless element.hasClass("unclicked")
        @__parent.send({
          id:data.id
          action:'callback'
          source:'input'
          text: element[0].value
          original_msg:data
          })
        if data.once
          replaceText = @__parent.escape("#{element[0].value}\n")
          replaceText = "#{data.label}#{replaceText}" if data.keep_label
          element.replaceWith(replaceText)

    target.append(element)

    if data.focus
      element.focus()

  checkbox: (data) ->
    target = @__parent.check_target(data)
    element = $("<label class='inline-checkbox'><input type='checkbox'><span>#{@__parent.escape(data.label,data)}</span></label>'")
    if data.value
      element.find('input').attr "checked", true
      element.addClass "checked"
    element.change (e) =>
      element.toggleClass("checked",  element.find('input').prop('checked'))
      @__parent.send({
        id:data.id
        action:'callback'
        source:'input'
        checked: element.find('input').prop('checked')
        original_msg:data
        })
    element.click (e) =>
      if e.shiftKey and @__lastChecked
        all_boxes = $('.inline-checkbox')
        start = all_boxes.index(@__lastChecked)
        stop = all_boxes.index(element)
        console.log start, stop

        all_boxes.slice(Math.min(start, stop), Math.max(start, stop) + 1).find('input').prop("checked", @__lastChecked.find('input').prop("checked"))
        all_boxes.change()
      else
        @__lastChecked = element
    target.append(element)

  alert: (data) ->
    alert(data.text)

  title: (data) ->
    document.title = data.title

  status: (data) ->
    @__parent.status.show_status(data)

  layout: (data) ->
    $("body").html(data.data)

  script: (data) ->
    eval(data.data)

  style: (data) ->
    target = @__parent.check_target(data)
    target.css(data.attribute, data.value)

  table: (data) ->
    target = @__parent.check_target(data)
    html = "<table>"
    if data.headers
      html += "<tr>"
      html += "<th>#{@__parent.escape(header, data)}</th>" for header in data.headers
      html += "<tr>"
    for row in data.rows
      html += "<tr>"
      html += "<td>#{@__parent.escape(cell, data)}</td>" for cell in row
      html += "</tr>"
    html += "</table>"
    html = $(html)
    unless data.interactive is false
      html.delegate 'td', 'mouseover mouseout', ->
        pos = $(this).index()
        html.find("td:nth-child(#{(pos+1)})").toggleClass("hover")
    @__parent.add(html, target, data)

  focus: (data) ->
    window.show()

  close: (data) ->
    window.close()
