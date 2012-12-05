function! s:ShowFavStar(bang, user)
  let user = len(a:user) > 0 ? a:user : exists('g:favstar_user') ? g:favstar_user : ''
  if len(user) == 0
    echohl WarningMsg
    echo 'Usage:'
    echo '  :FavStar [user]'
    echo '  you can set g:favstar_user to specify default user'
    echohl None
    return
  endif
  let url = 'http://favstar.fm/users/'.user.'/recent'
  if len(a:bang) > 0
    try
      call OpenBrowser(url)
    catch
    endtry
    return
  endif
  echohl WarningMsg
  redraw | echo 'fetching data...'
  let res = webapi#http#get(url, '', {
  \ 'User-Agent': 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_3_2 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8H7 Safari/6533.18.5'
  \})
  if empty(res.header)
    redraw | echomsg 'server error'
    return
  endif
  if res.header[0] !~ '200'
    redraw | echomsg res.header[0]
    return
  endif
 
  let res.content = iconv(res.content, 'utf-8', &encoding)
  let res.content = substitute(res.content, '<\(br\|meta\|link\|hr\)\s*>', '<\1/>', 'g')
  redraw | echo 'parsing data...'
  let dom = webapi#xml#parse(res.content)

  let nodes = dom.findAll({'class': 'fs-tweet'})
  try
    let pb = vim#widgets#progressbar#NewSimpleProgressBar('Processing:', len(nodes)) 
  catch /.*/
    let pb = {}
    function! pb.incr()
    endfunction
    function! pb.restore()
    endfunction
  endtry

  redraw | echo ''
  let favinfos = []
  for item in nodes
    let info = webapi#json#decode(item.attr['data-model'])
    let id = info['tweet_id']
    let text = item.find('p', {'class': 'fs-tweet-text'}).value()
    let text = substitute(text, "\n", ' ', 'g')
    let text = substitute(text, '^ *', '', '')
    let favinfo = {'text': webapi#html#decodeEntityReference(text), 'favs': [], 'rts': [], 'favcount': 0, 'rtcount': 0}

    let favs = item.find('div', {'data-type': 'favs'})
    if !empty(favs)
      let favinfo.favcount = 0 + favs.find('li', {'class': 'fs-total'}).value()
      for f in favs.findAll('a')
        call add(favinfo.favs, f.attr['title'])
      endfor
    endif
    let rts = item.find('div', {'data-type': 'retweets'})
    if !empty(rts)
      let favinfo.rtcount = 0 + rts.find('li', {'class': 'fs-total'}).value()
      for f in rts.findAll('a')
        call add(favinfo.rts, f.attr['title'])
      endfor
    endif
    call add(favinfos, favinfo)
    call pb.incr()
  endfor
  call pb.restore()
  redraw!
  for favinfo in favinfos
    echohl Function
    echo favinfo.text."\n"
    echohl None
    if len(favinfo.favs)
      echon 'FAV('.favinfo.favcount.'):'
      for fav in favinfo.favs
        echohl Statement
        echon ' ' . fav
        echohl None
      endfor
      if favinfo.favcount > len(favinfo.favs)
        echon ' ...'
      endif
      echo ''
    endif
    if len(favinfo.rts)
      echon 'RT('.favinfo.rtcount.'):'
      for rt in favinfo.rts
        echohl Statement
        echon ' ' . rt
        echohl None
      endfor
      if favinfo.rtcount > len(favinfo.rts)
        echon ' ...'
      endif
      echo ''
    endif
    echo "\n"
  endfor
endfunction

command! -nargs=? -bang FavStar call <SID>ShowFavStar('<bang>', <q-args>)

" vim:set et:
