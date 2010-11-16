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
  for item in dom.findAll({'class': 'tweetContainer'})
    let tweet = item.find('div', {"class": "theTweet"})
    let text = substitute(tweet.value(), "\n", " ", "g")
    let text = substitute(text, "^ *", "", "")
    echohl Function
    echo text
    echohl None
    let actions = item.findAll('div', {"class": "avatarList"})
    for action in actions
      let line = ''
      if action.attr['id'] =~ "^faved_by_"
        let line .= "FAV:"
      elseif action.attr['id'] =~ "^rt_by_"
        let line .= "RT:"
      endif
      for a in action.findAll('img')
        let line .= " " . a.attr['alt']
      endfor
      echohl Statement
      echo line
      echohl None
    endfor
    echo "\n"
  endfor
endfunction

command! -nargs=? FavStar call <SID>ShowFavStar(<f-args>)
