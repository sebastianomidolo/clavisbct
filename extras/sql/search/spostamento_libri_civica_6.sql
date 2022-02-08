item.home_library_id=2
AND item.item_media='F'
AND item.section='BCT'
AND NOT cl.secondo_elemento in ('LB','LC','LD','LF','LG','LM')
AND NOT cl.primo_elemento between '67' and '69'
AND NOT cl.primo_elemento between '400' and '405'
AND NOT cl.primo_elemento between '407' and '408'
AND NOT cl.primo_elemento between '410' and '413'
AND cm.edition_date between 1600 and 1969
AND NOT item.collocation ~* 'mano'
AND cl.piano = '6° piano'
