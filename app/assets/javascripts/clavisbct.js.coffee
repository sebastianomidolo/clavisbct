$(document).ready ->
        $("li.active",".nav").removeClass('active')

        $("li a", ".nav").filter((index) ->
                true  if document.location.href.contains @href
        ).parent().addClass "active"
