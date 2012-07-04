
Hogan = require 'lib/hogan'
window.Hogan = Hogan
T = require 'templates'

require 'lib/spin'

$ ->
    if !Trello.authorized()
        Trello.authorize type: "popup", success: render, scope: {
            read: true
            write: true
        }
    else
        render()

render = ->
    boardId = null
    
    $('body').append($(T.layout.render()))
    
    opts = {
        lines: 9
        length: 2
        width: 8
        radius: 5
        rotate: 0
        color: '#eee'
        speed: 1
        trail: 32
        shadow: true
        hwaccel: false
        className: 'spinner'
        zIndex: 2e9
        top: 'auto'
        left: 'auto'
    }

    spinner = new Spinner(opts)
      
    $('#spinner').ajaxStart ->
        spinner.spin(this)
    
    $('#spinner').ajaxStop ->
        spinner.stop()
    
    
    eventSource = {
        events: []
    }
    
    $('#calendar').fullCalendar({
        weekends: false
        editable: true
        header:
            left: "title"
            center: ""
            right: "today prev,next"
        eventSources: [
            eventSource
        ]
        eventDrop: (event, dayDelta, minuteDelta, allDay, revertFunc) ->
            newDueDate = event.start.toISOString()
            # Trello's PUT CORS stuff is broked, so we do a workaround
            # Trello.put("cards/#{event.id}/due", {value: newDue}, (o) ->
            #    console.log(o)
            # )
            Trello.rest('GET',
                        "cards/#{event.id}/due",
                        {value: newDueDate, _method: 'PUT'},
                        () ->
                            console.log 'win'
                        () ->
                            console.log 'fail'
                            revertFunc()
            )
    })
    
    $('#refreshButton').click((e) ->
        e.preventDefault()
        loadEvents(boardId)
    )
    
    Trello.members.get('me/boards', (boards) ->
        $('#boards').html(T.boardOptions.render boards: boards)
    )
    
    $('#boards').change((e) ->
        if e.target.value
            boardId = e.target.value
            loadEvents(boardId)
    )
    
    loadEvents = (boardId) ->
        Trello.boards.get("#{boardId}/cards",
                (cards) ->
                    eventSource.events = []
                    for c in cards
                        eventSource.events.push {
                            id: c.id
                            title: c.name
                            start: c.badges.due.replace(".000", "")
                            allDay: true
                            className: [l.color for l in c.labels]
                        } if c.badges.due?
                    
                    console.log(eventSource.events)
                    $('#calendar').fullCalendar('refetchEvents')
            )