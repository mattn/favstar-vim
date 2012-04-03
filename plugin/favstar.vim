function! s:ShowFavStar(bang, user)
  let user = len(a:user) > 0 ? a:user : exists('g:favstar_user') ? g:favstar_user : ''
  if len(user) == 0
    echohl WarningMsg
    echo "Usage:"
    echo "  :FavStar [user]"
    echo "  you can set g:favstar_user to specify default user"
    echohl None
    return
  endif
  let url = "http://favstar.fm/users/".user."/recent"
  if len(a:bang) > 0
    try
      call OpenBrowser(url)
    catch
    endtry
    return
  endif
  let res = webapi#http#get(url)
  let res.content = iconv(res.content, 'utf-8', &encoding)
  let res.content = substitute(res.content, '<\(br\|meta\|link\|hr\)\s*>', '<\1/>', 'g')
  let dom = webapi#xml#parse(res.content)

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
        let other = action.find('a', {'class': 'otherCount'})
        if !empty(other)
           let ll = matchstr(other.attr['onclick'], '\(\[.*\]\)')
           if len(ll)
             for o in webapi#json#decode(ll)
               call add(favinfo.favs, o[0])
             endfor
           endif
        endif
        let favinfo.favcount = action.find('span', {"class": "count"}).value()
      elseif action.attr['id'] =~ "^rt_by_"
        for a in action.findAll('img')
          call add(favinfo.rts, a.attr['alt'])
        endfor
        let other = action.find('a', {'class': 'otherCount'})
        if !empty(other)
           let ll = matchstr(other.attr['onclick'], '\(\[.*\]\)')
           if len(ll)
             for o in webapi#json#decode(ll)
               call add(favinfo.rts, o[0])
             endfor
           endif
        endif
        let favinfo.rtcount = action.find('span', {"class": "count"}).value()
      endif
    endfor
    call add(favinfos, favinfo)
    if !empty(pb) | call pb.incr() | endif
  endfor
  if !empty(pb) | call pb.restore() | endif
  if len(favinfos) == 0
    let node = dom.find('div', {'class': 'content'})
    if empty(node)
      let node = dom.find('div', {'id': 'streamTitle'})
    endif
    if !empty(node)
      let text = node.value()
      let text = substitute(text, '[\t\r\n ]\+', ' ', 'g')
      let text = matchstr(text, '^\s*\zs.*\ze\s*$')
      echomsg text
    endif
    return
  endif
  for favinfo in favinfos
    echohl Function
    echo favinfo.text."\n"
    echohl None
    if len(favinfo.favs)
      echon "FAV(".(0+favinfo.favcount)."):"
      for fav in favinfo.favs
        echohl Statement
        echon " " . fav
        echohl None
      endfor
      echo ""
    endif
    if len(favinfo.rts)
      echon "RT(".(0+favinfo.rtcount)."):"
      for rt in favinfo.rts
        echohl Statement
        echon " " . rt
        echohl None
      endfor
      echo ""
    endif
    echo "\n"
  endfor
endfunction

command! -nargs=? -bang FavStar call <SID>ShowFavStar("<bang>", <q-args>)

" vim:set et:
