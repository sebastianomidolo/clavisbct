$(document).ready ->
        $("li.active",".nav").removeClass('active')

        $("li a", ".nav").filter((index) ->
                true  if document.location.href is @href
        ).parent().addClass "active"
