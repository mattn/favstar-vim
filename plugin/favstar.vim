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
  let yql = "select * from html where url = 'http://favstar.fm/users/".user."/recent' and xpath = '//div[@class=\"tweetContainer\"]'"
  let res = http#get("http://query.yahooapis.com/v1/public/yql", {'q': yql})
  let dom = xml#parse(res.content)
  for item in dom.childNode('results').childNodes('div')
    let tweet = item.find('div', {"class": "theTweet"})
  	let text = substitute(tweet.childNode('p').value(), "\n", " ", "g")
 	let text = substitute(text, "^ *", "", "")
	echohl Function
	echo text
	echohl None
    let actions = item.findAll('div', {"class": "avatarList"})
	for action in actions
      let line = ''
	  if actions[0].attr['id'] =~ "^faved_by_"
        let line .= "FAV:"
	  elseif actions[0].attr['id'] =~ "^rt_by_"
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