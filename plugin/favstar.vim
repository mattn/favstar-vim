function! s:ShowFavStar(...)
  let user = a:0 > 0 ? a:1 : exists('g:favstar_user') ? g:favstar_user : ''
  if len(user) == 0
    echohl WarningMsg
    echo "Usage:"
    echo "  :FavStar [user]"
    echo "  you can set g:favstar_user to specify default user"
    echohl None
    return
  endif
  let res = http#get("http://favstar.fm/users/".user."/recent")
  let res.content = iconv(res.content, 'utf-8', &encoding)
  let res.content = substitute(res.content, '<\(br\|meta\|link\)\s*>', '<\1/>', 'g')
  let dom = xml#parse(res.content)

  let nodes = dom.findAll({'class': 'tweetWithStats'})
  try
    let pb = vim#widgets#progressbar#NewSimpleProgressBar("Processing:", len(nodes)) 
  catch /.*/
    let pb = {}
  endtry

  let favinfos = []
  for item in nodes
    let tweet = item.find('div', {"class": "theTweet"})
    let text = substitute(tweet.value(), "\n", " ", "g")
    let text = substitute(text, "^ *", "", "")
	let favinfo = {"text": text, "favs": [], "rts": []}
    let actions = item.findAll('div', {"class": "avatarList"})
    for action in actions
      let line = ''
      if action.attr['id'] =~ "^faved_by_"
        for a in action.findAll('img')
          call add(favinfo.favs, a.attr['alt'])
        endfor
      elseif action.attr['id'] =~ "^rt_by_"
        for a in action.findAll('img')
          call add(favinfo.rts, a.attr['alt'])
        endfor
      endif
    endfor
	call add(favinfos, favinfo)
    if !empty(pb) | call pb.incr() | endif
  endfor
  if !empty(pb) | call pb.restore() | endif
  if len(favinfos) == 0
    let node = dom.find({'class': 'content'})
	let text = node.value()
	let text = substitute(text, "[\t ]*\n[\t ]*", " ", "g")
	let text = substitute(text, "^[\t ]*", "", "g")
	echomsg text
    return
  endif
  for favinfo in favinfos
    echohl Function
    echo favinfo.text
    echohl None
	if len(favinfo.favs)
	  echon "\nFAV:"
      for fav in favinfo.favs
        echohl Statement
        echon " " . fav
        echohl None
	  endfor
    endif
	if len(favinfo.rts)
	  echon "\nRT:"
      for rt in favinfo.rts
        echohl Statement
        echon " " . rt
        echohl None
	  endfor
    endif
    echo "\n"
  endfor
endfunction

command! -nargs=? FavStar call <SID>ShowFavStar(<f-args>)
