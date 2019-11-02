" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/netrwPlugin.vim	[[[1
213
" netrwPlugin.vim: Handles file transfer and remote directory listing across a network
"            PLUGIN SECTION
" Date:		Nov 07, 2014
" Maintainer:	Charles E Campbell <NdrOchip@ScampbellPfamily.AbizM-NOSPAM>
" GetLatestVimScripts: 1075 1 :AutoInstall: netrw.vim
" Copyright:    Copyright (C) 1999-2013 Charles E. Campbell {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               netrw.vim, netrwPlugin.vim, and netrwSettings.vim are provided
"               *as is* and comes with no warranty of any kind, either
"               expressed or implied. By using this plugin, you agree that
"               in no event will the copyright holder be liable for any damages
"               resulting from the use of this software.
"
"  But be doers of the Word, and not only hearers, deluding your own selves {{{1
"  (James 1:22 RSV)
" =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
" Load Once: {{{1
if &cp || exists("g:loaded_netrwPlugin")
 finish
endif
let g:loaded_netrwPlugin = "v00"
let s:keepcpo = &cpo
set cpo&vim
"DechoRemOn

" ---------------------------------------------------------------------
" Public Interface: {{{1

" Local Browsing Autocmds: {{{2
augroup FileExplorer
 au!
 au BufLeave *  if &ft != "netrw"|let w:netrw_prvfile= expand("%:p")|endif
 au BufEnter *	sil call s:LocalBrowse(expand("<amatch>"))
 au VimEnter *	sil call s:VimEnter(expand("<amatch>"))
 if has("win32") || has("win95") || has("win64") || has("win16")
  au BufEnter .* sil call s:LocalBrowse(expand("<amatch>"))
 endif
augroup END

" Network Browsing Reading Writing: {{{2
augroup Network
 au!
 au BufReadCmd   file://*											call netrw#FileUrlRead(expand("<amatch>"))
 au BufReadCmd   ftp://*,rcp://*,scp://*,http://*,file://*,https://*,dav://*,davs://*,rsync://*,sftp://*	exe "sil doau BufReadPre ".fnameescape(expand("<amatch>"))|call netrw#Nread(2,expand("<amatch>"))|exe "sil doau BufReadPost ".fnameescape(expand("<amatch>"))
 au FileReadCmd  ftp://*,rcp://*,scp://*,http://*,file://*,https://*,dav://*,davs://*,rsync://*,sftp://*	exe "sil doau FileReadPre ".fnameescape(expand("<amatch>"))|call netrw#Nread(1,expand("<amatch>"))|exe "sil doau FileReadPost ".fnameescape(expand("<amatch>"))
 au BufWriteCmd  ftp://*,rcp://*,scp://*,http://*,file://*,dav://*,davs://*,rsync://*,sftp://*			exe "sil doau BufWritePre ".fnameescape(expand("<amatch>"))|exe 'Nwrite '.fnameescape(expand("<amatch>"))|exe "sil doau BufWritePost ".fnameescape(expand("<amatch>"))
 au FileWriteCmd ftp://*,rcp://*,scp://*,http://*,file://*,dav://*,davs://*,rsync://*,sftp://*			exe "sil doau FileWritePre ".fnameescape(expand("<amatch>"))|exe "'[,']".'Nwrite '.fnameescape(expand("<amatch>"))|exe "sil doau FileWritePost ".fnameescape(expand("<amatch>"))
 try                                                       
  au SourceCmd   ftp://*,rcp://*,scp://*,http://*,file://*,https://*,dav://*,davs://*,rsync://*,sftp://*	exe 'Nsource '.fnameescape(expand("<amatch>"))
 catch /^Vim\%((\a\+)\)\=:E216/                            
  au SourcePre   ftp://*,rcp://*,scp://*,http://*,file://*,https://*,dav://*,davs://*,rsync://*,sftp://*	exe 'Nsource '.fnameescape(expand("<amatch>"))
 endtry
augroup END

" Commands: :Nread, :Nwrite, :NetUserPass {{{2
com! -count=1 -nargs=*	Nread		call netrw#SavePosn()<bar>call netrw#NetRead(<count>,<f-args>)<bar>call netrw#RestorePosn()
com! -range=% -nargs=*	Nwrite		call netrw#SavePosn()<bar><line1>,<line2>call netrw#NetWrite(<f-args>)<bar>call netrw#RestorePosn()
com! -nargs=*		NetUserPass	call NetUserPass(<f-args>)
com! -nargs=*	        Nsource		call netrw#SavePosn()<bar>call netrw#NetSource(<f-args>)<bar>call netrw#RestorePosn()
com! -nargs=?		Ntree		call netrw#SetTreetop(<q-args>)

" Commands: :Explore, :Sexplore, Hexplore, Vexplore, Lexplore {{{2
com! -nargs=* -bar -bang -count=0 -complete=dir	Explore		call netrw#Explore(<count>,0,0+<bang>0,<q-args>)
com! -nargs=* -bar -bang -count=0 -complete=dir	Sexplore	call netrw#Explore(<count>,1,0+<bang>0,<q-args>)
com! -nargs=* -bar -bang -count=0 -complete=dir	Hexplore	call netrw#Explore(<count>,1,2+<bang>0,<q-args>)
com! -nargs=* -bar -bang -count=0 -complete=dir	Vexplore	call netrw#Explore(<count>,1,4+<bang>0,<q-args>)
com! -nargs=* -bar       -count=0 -complete=dir	Texplore	call netrw#Explore(<count>,0,6        ,<q-args>)
com! -nargs=* -bar -bang			Nexplore	call netrw#Explore(-1,0,0,<q-args>)
com! -nargs=* -bar -bang			Pexplore	call netrw#Explore(-2,0,0,<q-args>)
com! -nargs=* -bar -bang -count=0 -complete=dir Lexplore	call netrw#Lexplore(<count>,<bang>0,<q-args>)

" Commands: NetrwSettings {{{2
com! -nargs=0	NetrwSettings	call netrwSettings#NetrwSettings()
com! -bang	NetrwClean	call netrw#Clean(<bang>0)

" Maps:
if !exists("g:netrw_nogx")
 if maparg('gx','n') == ""
  if !hasmapto('<Plug>NetrwBrowseX')
   nmap <unique> gx <Plug>NetrwBrowseX
  endif
  nno <silent> <Plug>NetrwBrowseX :call netrw#BrowseX(expand((exists("g:netrw_gx")? g:netrw_gx : '<cfile>')),netrw#CheckIfRemote())<cr>
 endif
 if maparg('gx','v') == ""
  if !hasmapto('<Plug>NetrwBrowseXVis')
   vmap <unique> gx <Plug>NetrwBrowseXVis
  endif
  vno <silent> <Plug>NetrwBrowseXVis :<c-u>call netrw#BrowseXVis()<cr>
 endif
endif
if !exists("g:netrw_notab")
 if maparg('<tab>','n') == ""
  nmap <unique> <tab> <Plug>NetrwShrink
 endif
 nno <silent> <Plug>NetrwShrink :call netrw#Shrink()<cr>
endif

" ---------------------------------------------------------------------
" LocalBrowse: invokes netrw#LocalBrowseCheck() on directory buffers {{{2
fun! s:LocalBrowse(dirname)
  " Unfortunate interaction -- only DechoMsg debugging calls can be safely used here.
  " Otherwise, the BufEnter event gets triggered when attempts to write to
  " the DBG buffer are made.
  
  if !exists("s:vimentered")
   " If s:vimentered doesn't exist, then the VimEnter event hasn't fired.  It will,
   " and so s:VimEnter() will then be calling this routine, but this time with s:vimentered defined.
"   call Dfunc("s:LocalBrowse(dirname<".a:dirname.">)  (s:vimentered doesn't exist)")
"   call Dret("s:LocalBrowse")
   return
  endif

"  call Dfunc("s:LocalBrowse(dirname<".a:dirname.">)  (s:vimentered=".s:vimentered.")")

  if has("amiga")
   " The check against '' is made for the Amiga, where the empty
   " string is the current directory and not checking would break
   " things such as the help command.
"   call Decho("(LocalBrowse) dirname<".a:dirname.">  (isdirectory, amiga)")
   if a:dirname != '' && isdirectory(a:dirname)
    sil! call netrw#LocalBrowseCheck(a:dirname)
    if exists("w:netrw_bannercnt") && line('.') < w:netrw_bannercnt
     exe w:netrw_bannercnt
    endif
   endif

  elseif isdirectory(a:dirname)
"   call Decho("(LocalBrowse) dirname<".a:dirname."> ft=".&ft."  (isdirectory, not amiga)")
"   call Dredir("LocalBrowse ft last set: ","verbose set ft")
"   call Decho("(s:LocalBrowse) COMBAK#23: buf#".bufnr("%")." file<".expand("%")."> line#".line(".")." col#".col("."))
   sil! call netrw#LocalBrowseCheck(a:dirname)
"   call Decho("(s:LocalBrowse) COMBAK#24: buf#".bufnr("%")." file<".expand("%")."> line#".line(".")." col#".col("."))
   if exists("w:netrw_bannercnt") && line('.') < w:netrw_bannercnt
    exe w:netrw_bannercnt
"    call Decho("(s:LocalBrowse) COMBAK#25: buf#".bufnr("%")." file<".expand("%")."> line#".line(".")." col#".col("."))
   endif

  else
   " not a directory, ignore it
"   call Decho("(LocalBrowse) dirname<".a:dirname."> not a directory, ignoring...")
  endif
"  call Decho("(s:LocalBrowse) COMBAK#26: buf#".bufnr("%")." file<".expand("%")."> line#".line(".")." col#".col("."))

"  call Dret("s:LocalBrowse")
endfun

" ---------------------------------------------------------------------
" s:VimEnter: after all vim startup stuff is done, this function is called. {{{2
"             Its purpose: to look over all windows and run s:LocalBrowse() on
"             them, which checks if they're directories and will create a directory
"             listing when appropriate.
"             It also sets s:vimentered, letting s:LocalBrowse() know that s:VimEnter()
"             has already been called.
fun! s:VimEnter(dirname)
"  call Dfunc("s:VimEnter(dirname<".a:dirname.">) expand(%)<".expand("%").">")
  let curwin       = winnr()
  let s:vimentered = 1
  windo call s:LocalBrowse(expand("%:p"))
  exe curwin."wincmd w"
"  call Dret("s:VimEnter")
endfun

" ---------------------------------------------------------------------
" NetrwStatusLine: {{{1
fun! NetrwStatusLine()
"  let g:stlmsg= "Xbufnr=".w:netrw_explore_bufnr." bufnr=".bufnr("%")." Xline#".w:netrw_explore_line." line#".line(".")
  if !exists("w:netrw_explore_bufnr") || w:netrw_explore_bufnr != bufnr("%") || !exists("w:netrw_explore_line") || w:netrw_explore_line != line(".") || !exists("w:netrw_explore_list")
   let &stl= s:netrw_explore_stl
   if exists("w:netrw_explore_bufnr")|unlet w:netrw_explore_bufnr|endif
   if exists("w:netrw_explore_line")|unlet w:netrw_explore_line|endif
   return ""
  else
   return "Match ".w:netrw_explore_mtchcnt." of ".w:netrw_explore_listlen
  endif
endfun

" ------------------------------------------------------------------------
" NetUserPass: set username and password for subsequent ftp transfer {{{1
"   Usage:  :call NetUserPass()			-- will prompt for userid and password
"	    :call NetUserPass("uid")		-- will prompt for password
"	    :call NetUserPass("uid","password") -- sets global userid and password
fun! NetUserPass(...)

 " get/set userid
 if a:0 == 0
"  call Dfunc("NetUserPass(a:0<".a:0.">)")
  if !exists("g:netrw_uid") || g:netrw_uid == ""
   " via prompt
   let g:netrw_uid= input('Enter username: ')
  endif
 else	" from command line
"  call Dfunc("NetUserPass(a:1<".a:1.">) {")
  let g:netrw_uid= a:1
 endif

 " get password
 if a:0 <= 1 " via prompt
"  call Decho("a:0=".a:0." case <=1:")
  let g:netrw_passwd= inputsecret("Enter Password: ")
 else " from command line
"  call Decho("a:0=".a:0." case >1: a:2<".a:2.">")
  let g:netrw_passwd=a:2
 endif
"  call Dret("NetUserPass")
endfun

" ------------------------------------------------------------------------
" Modelines And Restoration: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim:ts=8 fdm=marker
autoload/netrw.vim	[[[1
11797
" netrw.vim: Handles file transfer and remote directory listing across
"            AUTOLOAD SECTION
" Date:		Aug 10, 2015
" Version:	154h	NOT RELEASED
" Maintainer:	Charles E Campbell <NdrOchip@ScampbellPfamily.AbizM-NOSPAM>
" GetLatestVimScripts: 1075 1 :AutoInstall: netrw.vim
" Copyright:    Copyright (C) 1999-2015 Charles E. Campbell {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               netrw.vim, netrwPlugin.vim, and netrwSettings.vim are provided
"               *as is* and come with no warranty of any kind, either
"               expressed or implied. By using this plugin, you agree that
"               in no event will the copyright holder be liable for any damages
"               resulting from the use of this software.
"redraw!|call DechoSep()|call inputsave()|call input("Press <cr> to continue")|call inputrestore(,'~'.expand("<slnum>"))
"
"  But be doers of the Word, and not only hearers, deluding your own selves {{{1
"  (James 1:22 RSV)
" =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
" Load Once: {{{1
if &cp || exists("g:loaded_netrw")
  finish
endif
" netrw requires vim having patch 213; netrw will benefit from vim's having patch#656, too
if v:version < 704 || !has("patch213")
 if !exists("s:needpatch213")
  unsilent echomsg "***sorry*** this version of netrw requires vim v7.4 with patch 213"
 endif
 let s:needpatch213= 1
 finish
endif
let g:loaded_netrw = "v154hNR"
if !exists("s:NOTE")
 let s:NOTE    = 0
 let s:WARNING = 1
 let s:ERROR   = 2
endif

let s:keepcpo= &cpo
setl cpo&vim
"let g:dechofuncname= 1
"DechoRemOn
"call Decho("doing autoload/netrw.vim version ".g:loaded_netrw,'~'.expand("<slnum>"))

" ======================
"  Netrw Variables: {{{1
" ======================

" ---------------------------------------------------------------------
" netrw#ErrorMsg: {{{2
"   0=note     = s:NOTE
"   1=warning  = s:WARNING
"   2=error    = s:ERROR
"   Usage: netrw#ErrorMsg(s:NOTE | s:WARNING | s:ERROR,"some message",error-number)
"          netrw#ErrorMsg(s:NOTE | s:WARNING | s:ERROR,["message1","message2",...],error-number)
"          (this function can optionally take a list of messages)
"  Jun 25, 2015 : max errnum currently is 99
fun! netrw#ErrorMsg(level,msg,errnum)
"  call Dfunc("netrw#ErrorMsg(level=".a:level." msg<".a:msg."> errnum=".a:errnum.") g:netrw_use_errorwindow=".g:netrw_use_errorwindow)

  if a:level < g:netrw_errorlvl
"   call Dret("netrw#ErrorMsg : suppressing level=".a:level." since g:netrw_errorlvl=".g:netrw_errorlvl)
   return
  endif

  if a:level == 1
   let level= "**warning** (netrw) "
  elseif a:level == 2
   let level= "**error** (netrw) "
  else
   let level= "**note** (netrw) "
  endif
"  call Decho("level=".level,'~'.expand("<slnum>"))

  if g:netrw_use_errorwindow
   " (default) netrw creates a one-line window to show error/warning
   " messages (reliably displayed)

   " record current window number for NetrwRestorePosn()'s benefit
   let s:winBeforeErr= winnr()
"   call Decho("s:winBeforeErr=".s:winBeforeErr,'~'.expand("<slnum>"))

   " getting messages out reliably is just plain difficult!
   " This attempt splits the current window, creating a one line window.
   if bufexists("NetrwMessage") && bufwinnr("NetrwMessage") > 0
"    call Decho("write to NetrwMessage buffer",'~'.expand("<slnum>"))
    exe bufwinnr("NetrwMessage")."wincmd w"
"    call Decho("setl ma noro",'~'.expand("<slnum>"))
    setl ma noro
    if type(a:msg) == 3
     for msg in a:msg
      NetrwKeepj call setline(line("$")+1,level.msg)
     endfor
    else
     NetrwKeepj call setline(line("$")+1,level.a:msg)
    endif
    NetrwKeepj $
   else
"    call Decho("create a NetrwMessage buffer window",'~'.expand("<slnum>"))
    bo 1split
    sil! call s:NetrwEnew()
    sil! NetrwKeepj call s:NetrwSafeOptions()
    setl bt=nofile
    NetrwKeepj file NetrwMessage
"    call Decho("setl ma noro",'~'.expand("<slnum>"))
    setl ma noro
    if type(a:msg) == 3
     for msg in a:msg
      NetrwKeepj call setline(line("$")+1,level.msg)
     endfor
    else
     NetrwKeepj call setline(line("$"),level.a:msg)
    endif
    NetrwKeepj $
   endif
"   call Decho("wrote msg<".level.a:msg."> to NetrwMessage win#".winnr(),'~'.expand("<slnum>"))
   if &fo !~ '[ta]'
    syn clear
    syn match netrwMesgNote	"^\*\*note\*\*"
    syn match netrwMesgWarning	"^\*\*warning\*\*"
    syn match netrwMesgError	"^\*\*error\*\*"
    hi link netrwMesgWarning WarningMsg
    hi link netrwMesgError   Error
   endif
"   call Decho("setl noma ro bh=wipe",'~'.expand("<slnum>"))
   setl ro nomod noma bh=wipe

  else
   " (optional) netrw will show messages using echomsg.  Even if the
   " message doesn't appear, at least it'll be recallable via :messages
"   redraw!
   if a:level == s:WARNING
    echohl WarningMsg
   elseif a:level == s:ERROR
    echohl Error
   endif

   if type(a:msg) == 3
     for msg in a:msg
      unsilent echomsg level.msg
     endfor
   else
    unsilent echomsg level.a:msg
   endif

"   call Decho("echomsg ***netrw*** ".a:msg,'~'.expand("<slnum>"))
   echohl None
  endif

"  call Dret("netrw#ErrorMsg")
endfun

" ---------------------------------------------------------------------
" s:NetrwInit: initializes variables if they haven't been defined {{{2
"            Loosely,  varname = value.
fun s:NetrwInit(varname,value)
" call Decho("varname<".a:varname."> value=".a:value,'~'.expand("<slnum>"))
  if !exists(a:varname)
   if type(a:value) == 0
    exe "let ".a:varname."=".a:value
   elseif type(a:value) == 1 && a:value =~ '^[{[]'
    exe "let ".a:varname."=".a:value
   elseif type(a:value) == 1
    exe "let ".a:varname."="."'".a:value."'"
   else
    exe "let ".a:varname."=".a:value
   endif
  endif
endfun

" ---------------------------------------------------------------------
"  Netrw Constants: {{{2
call s:NetrwInit("g:netrw_dirhist_cnt",0)
if !exists("s:LONGLIST")
 call s:NetrwInit("s:THINLIST",0)
 call s:NetrwInit("s:LONGLIST",1)
 call s:NetrwInit("s:WIDELIST",2)
 call s:NetrwInit("s:TREELIST",3)
 call s:NetrwInit("s:MAXLIST" ,4)
endif

" ---------------------------------------------------------------------
" Default values for netrw's global protocol variables {{{2
call s:NetrwInit("g:netrw_use_errorwindow",1)

if !exists("g:netrw_dav_cmd")
 if executable("cadaver")
  let g:netrw_dav_cmd	= "cadaver"
 elseif executable("curl")
  let g:netrw_dav_cmd	= "curl"
 else
  let g:netrw_dav_cmd   = ""
 endif
endif
if !exists("g:netrw_fetch_cmd")
 if executable("fetch")
  let g:netrw_fetch_cmd	= "fetch -o"
 else
  let g:netrw_fetch_cmd	= ""
 endif
endif
if !exists("g:netrw_file_cmd")
 if executable("elinks")
  call s:NetrwInit("g:netrw_file_cmd","elinks")
 elseif executable("links")
  call s:NetrwInit("g:netrw_file_cmd","links")
 endif
endif
if !exists("g:netrw_ftp_cmd")
  let g:netrw_ftp_cmd	= "ftp"
endif
let s:netrw_ftp_cmd= g:netrw_ftp_cmd
if !exists("g:netrw_ftp_options")
 let g:netrw_ftp_options= "-i -n"
endif
if !exists("g:netrw_http_cmd")
 if executable("elinks")
  let g:netrw_http_cmd = "elinks"
  call s:NetrwInit("g:netrw_http_xcmd","-source >")
 elseif executable("links")
  let g:netrw_http_cmd = "links"
  call s:NetrwInit("g:netrw_http_xcmd","-source >")
 elseif executable("curl")
  let g:netrw_http_cmd	= "curl"
  call s:NetrwInit("g:netrw_http_xcmd","-o")
 elseif executable("wget")
  let g:netrw_http_cmd	= "wget"
  call s:NetrwInit("g:netrw_http_xcmd","-q -O")
 elseif executable("fetch")
  let g:netrw_http_cmd	= "fetch"
  call s:NetrwInit("g:netrw_http_xcmd","-o")
 else
  let g:netrw_http_cmd	= ""
 endif
endif
call s:NetrwInit("g:netrw_http_put_cmd","curl -T")
call s:NetrwInit("g:netrw_keepj","keepj")
call s:NetrwInit("g:netrw_rcp_cmd"  , "rcp")
call s:NetrwInit("g:netrw_rsync_cmd", "rsync")
if !exists("g:netrw_scp_cmd")
 if executable("scp")
  call s:NetrwInit("g:netrw_scp_cmd" , "scp -q")
 elseif executable("pscp")
  if (has("win32") || has("win95") || has("win64") || has("win16")) && filereadable('c:\private.ppk')
   call s:NetrwInit("g:netrw_scp_cmd", 'pscp -i c:\private.ppk')
  else
   call s:NetrwInit("g:netrw_scp_cmd", 'pscp -q')
  endif
 else
  call s:NetrwInit("g:netrw_scp_cmd" , "scp -q")
 endif
endif

call s:NetrwInit("g:netrw_sftp_cmd" , "sftp")
call s:NetrwInit("g:netrw_ssh_cmd"  , "ssh")

if (has("win32") || has("win95") || has("win64") || has("win16"))
  \ && exists("g:netrw_use_nt_rcp")
  \ && g:netrw_use_nt_rcp
  \ && executable( $SystemRoot .'/system32/rcp.exe')
 let s:netrw_has_nt_rcp = 1
 let s:netrw_rcpmode    = '-b'
else
 let s:netrw_has_nt_rcp = 0
 let s:netrw_rcpmode    = ''
endif

" ---------------------------------------------------------------------
" Default values for netrw's global variables {{{2
" Cygwin Detection ------- {{{3
if !exists("g:netrw_cygwin")
 if has("win32") || has("win95") || has("win64") || has("win16")
  if  has("win32unix") && &shell =~ '\%(\<bash\>\|\<zsh\>\)\%(\.exe\)\=$'
   let g:netrw_cygwin= 1
  else
   let g:netrw_cygwin= 0
  endif
 else
  let g:netrw_cygwin= 0
 endif
endif
" Default values - a-c ---------- {{{3
call s:NetrwInit("g:netrw_alto"        , &sb)
call s:NetrwInit("g:netrw_altv"        , &spr)
call s:NetrwInit("g:netrw_banner"      , 1)
call s:NetrwInit("g:netrw_browse_split", 0)
call s:NetrwInit("g:netrw_bufsettings" , "noma nomod nonu nobl nowrap ro nornu")
call s:NetrwInit("g:netrw_chgwin"      , -1)
call s:NetrwInit("g:netrw_compress"    , "gzip")
call s:NetrwInit("g:netrw_ctags"       , "ctags")
if exists("g:netrw_cursorline") && !exists("g:netrw_cursor")
 call netrw#ErrorMsg(s:NOTE,'g:netrw_cursorline is deprecated; use g:netrw_cursor instead',77)
 let g:netrw_cursor= g:netrw_cursorline
endif
call s:NetrwInit("g:netrw_cursor"      , 2)
let s:netrw_usercul = &cursorline
let s:netrw_usercuc = &cursorcolumn
call s:NetrwInit("g:netrw_cygdrive","/cygdrive")
" Default values - d-g ---------- {{{3
call s:NetrwInit("s:didstarstar",0)
call s:NetrwInit("g:netrw_dirhist_cnt"      , 0)
call s:NetrwInit("g:netrw_decompress"       , '{ ".gz" : "gunzip", ".bz2" : "bunzip2", ".zip" : "unzip", ".tar" : "tar -xf", ".xz" : "unxz" }')
call s:NetrwInit("g:netrw_dirhistmax"       , 10)
call s:NetrwInit("g:netrw_errorlvl"  , s:NOTE)
call s:NetrwInit("g:netrw_fastbrowse"       , 1)
call s:NetrwInit("g:netrw_ftp_browse_reject", '^total\s\+\d\+$\|^Trying\s\+\d\+.*$\|^KERBEROS_V\d rejected\|^Security extensions not\|No such file\|: connect to address [0-9a-fA-F:]*: No route to host$')
if !exists("g:netrw_ftp_list_cmd")
 if has("unix") || (exists("g:netrw_cygwin") && g:netrw_cygwin)
  let g:netrw_ftp_list_cmd     = "ls -lF"
  let g:netrw_ftp_timelist_cmd = "ls -tlF"
  let g:netrw_ftp_sizelist_cmd = "ls -slF"
 else
  let g:netrw_ftp_list_cmd     = "dir"
  let g:netrw_ftp_timelist_cmd = "dir"
  let g:netrw_ftp_sizelist_cmd = "dir"
 endif
endif
call s:NetrwInit("g:netrw_ftpmode",'binary')
" Default values - h-lh ---------- {{{3
call s:NetrwInit("g:netrw_hide",1)
if !exists("g:netrw_ignorenetrc")
 if &shell =~ '\c\<\%(cmd\|4nt\)\.exe$'
  let g:netrw_ignorenetrc= 1
 else
  let g:netrw_ignorenetrc= 0
 endif
endif
call s:NetrwInit("g:netrw_keepdir",1)
if !exists("g:netrw_list_cmd")
 if g:netrw_scp_cmd =~ '^pscp' && executable("pscp")
  if (has("win32") || has("win95") || has("win64") || has("win16")) && filereadable("c:\\private.ppk")
   " provide a pscp-based listing command
   let g:netrw_scp_cmd ="pscp -i C:\\private.ppk"
  endif
  if exists("g:netrw_list_cmd_options")
   let g:netrw_list_cmd= g:netrw_scp_cmd." -ls USEPORT HOSTNAME: ".g:netrw_list_cmd_options
  else
   let g:netrw_list_cmd= g:netrw_scp_cmd." -ls USEPORT HOSTNAME:"
  endif
 elseif executable(g:netrw_ssh_cmd)
  " provide a scp-based default listing command
  if exists("g:netrw_list_cmd_options")
   let g:netrw_list_cmd= g:netrw_ssh_cmd." USEPORT HOSTNAME ls -FLa ".g:netrw_list_cmd_options
  else
   let g:netrw_list_cmd= g:netrw_ssh_cmd." USEPORT HOSTNAME ls -FLa"
  endif
 else
"  call Decho(g:netrw_ssh_cmd." is not executable",'~'.expand("<slnum>"))
  let g:netrw_list_cmd= ""
 endif
endif
call s:NetrwInit("g:netrw_list_hide","")
" Default values - lh-lz ---------- {{{3
if exists("g:netrw_local_copycmd")
 let g:netrw_localcopycmd= g:netrw_local_copycmd
 call netrw#ErrorMsg(s:NOTE,"g:netrw_local_copycmd is deprecated in favor of g:netrw_localcopycmd",84)
endif
if !exists("g:netrw_localcmdshell")
 let g:netrw_localcmdshell= ""
endif
if !exists("g:netrw_localcopycmd")
 if has("win32") || has("win95") || has("win64") || has("win16")
  if g:netrw_cygwin
   let g:netrw_localcopycmd= "cp"
  else
   let g:netrw_localcopycmd= expand("$COMSPEC")." /c copy"
  endif
 elseif has("unix") || has("macunix")
  let g:netrw_localcopycmd= "cp"
 else
  let g:netrw_localcopycmd= ""
 endif
endif
if !exists("g:netrw_localcopydircmd")
 if has("win32") || has("win95") || has("win64") || has("win16")
  if g:netrw_cygwin
   let g:netrw_localcopydircmd= "cp -R"
  else
   let g:netrw_localcopycmd= expand("$COMSPEC")." /c xcopy /e /c /h /i /k"
  endif
 elseif has("unix") || has("macunix")
  let g:netrw_localcopydircmd= "cp -R"
 else
  let g:netrw_localcopycmd= ""
 endif
endif
if exists("g:netrw_local_mkdir")
 let g:netrw_localmkdir= g:netrw_local_mkdir
 call netrw#ErrorMsg(s:NOTE,"g:netrw_local_mkdir is deprecated in favor of g:netrw_localmkdir",87)
endif
if has("win32") || has("win95") || has("win64") || has("win16")
  if g:netrw_cygwin
   call s:NetrwInit("g:netrw_localmkdir","mkdir")
  else
   let g:netrw_localmkdir= expand("$COMSPEC")." /c mkdir"
  endif
else
 call s:NetrwInit("g:netrw_localmkdir","mkdir")
endif
call s:NetrwInit("g:netrw_remote_mkdir","mkdir")
if exists("g:netrw_local_movecmd")
 let g:netrw_localmovecmd= g:netrw_local_movecmd
 call netrw#ErrorMsg(s:NOTE,"g:netrw_local_movecmd is deprecated in favor of g:netrw_localmovecmd",88)
endif
if !exists("g:netrw_localmovecmd")
 if has("win32") || has("win95") || has("win64") || has("win16")
  if g:netrw_cygwin
   let g:netrw_localmovecmd= "mv"
  else
   let g:netrw_localmovecmd= expand("$COMSPEC")." /c move"
  endif
 elseif has("unix") || has("macunix")
  let g:netrw_localmovecmd= "mv"
 else
  let g:netrw_localmovecmd= ""
 endif
endif
if exists("g:netrw_local_rmdir")
 let g:netrw_localrmdir= g:netrw_local_rmdir
 call netrw#ErrorMsg(s:NOTE,"g:netrw_local_rmdir is deprecated in favor of g:netrw_localrmdir",86)
endif
if has("win32") || has("win95") || has("win64") || has("win16")
  if g:netrw_cygwin
   call s:NetrwInit("g:netrw_localrmdir","rmdir")
  else
   let g:netrw_localrmdir= expand("$COMSPEC")." /c rmdir"
  endif
else
 call s:NetrwInit("g:netrw_localrmdir","rmdir")
endif
call s:NetrwInit("g:netrw_liststyle"  , s:THINLIST)
" sanity checks
if g:netrw_liststyle < 0 || g:netrw_liststyle >= s:MAXLIST
 let g:netrw_liststyle= s:THINLIST
endif
if g:netrw_liststyle == s:LONGLIST && g:netrw_scp_cmd !~ '^pscp'
 let g:netrw_list_cmd= g:netrw_list_cmd." -l"
endif
" Default values - m-r ---------- {{{3
call s:NetrwInit("g:netrw_markfileesc"   , '*./[\~')
call s:NetrwInit("g:netrw_maxfilenamelen", 32)
call s:NetrwInit("g:netrw_menu"          , 1)
call s:NetrwInit("g:netrw_mkdir_cmd"     , g:netrw_ssh_cmd." USEPORT HOSTNAME mkdir")
call s:NetrwInit("g:netrw_mousemaps"     , (exists("+mouse") && &mouse =~ '[anh]'))
call s:NetrwInit("g:netrw_retmap"        , 0)
if has("unix") || (exists("g:netrw_cygwin") && g:netrw_cygwin)
 call s:NetrwInit("g:netrw_chgperm"       , "chmod PERM FILENAME")
elseif has("win32") || has("win95") || has("win64") || has("win16")
 call s:NetrwInit("g:netrw_chgperm"       , "cacls FILENAME /e /p PERM")
else
 call s:NetrwInit("g:netrw_chgperm"       , "chmod PERM FILENAME")
endif
call s:NetrwInit("g:netrw_preview"       , 0)
call s:NetrwInit("g:netrw_scpport"       , "-P")
call s:NetrwInit("g:netrw_servername"    , "NETRWSERVER")
call s:NetrwInit("g:netrw_sshport"       , "-p")
call s:NetrwInit("g:netrw_rename_cmd"    , g:netrw_ssh_cmd." USEPORT HOSTNAME mv")
call s:NetrwInit("g:netrw_rm_cmd"        , g:netrw_ssh_cmd." USEPORT HOSTNAME rm")
call s:NetrwInit("g:netrw_rmdir_cmd"     , g:netrw_ssh_cmd." USEPORT HOSTNAME rmdir")
call s:NetrwInit("g:netrw_rmf_cmd"       , g:netrw_ssh_cmd." USEPORT HOSTNAME rm -f ")
" Default values - q-s ---------- {{{3
call s:NetrwInit("g:netrw_quickhelp",0)
let s:QuickHelp= ["-:go up dir  D:delete  R:rename  s:sort-by  x:special",
   \              "(create new)  %:file  d:directory",
   \              "(windows split&open) o:horz  v:vert  p:preview",
   \              "i:style  qf:file info  O:obtain  r:reverse",
   \              "(marks)  mf:mark file  mt:set target  mm:move  mc:copy",
   \              "(bookmarks)  mb:make  mB:delete  qb:list  gb:go to",
   \              "(history)  qb:list  u:go up  U:go down",
   \              "(targets)  mt:target Tb:use bookmark  Th:use history"]
" g:netrw_sepchr: picking a character that doesn't appear in filenames that can be used to separate priority from filename
call s:NetrwInit("g:netrw_sepchr"        , (&enc == "euc-jp")? "\<Char-0x01>" : "\<Char-0xff>")
if !exists("g:netrw_keepj") || g:netrw_keepj == "keepj"
 call s:NetrwInit("s:netrw_silentxfer"    , (exists("g:netrw_silent") && g:netrw_silent != 0)? "sil keepj " : "keepj ")
else
 call s:NetrwInit("s:netrw_silentxfer"    , (exists("g:netrw_silent") && g:netrw_silent != 0)? "sil " : " ")
endif
call s:NetrwInit("g:netrw_sort_by"       , "name") " alternatives: date                                      , size
call s:NetrwInit("g:netrw_sort_options"  , "")
call s:NetrwInit("g:netrw_sort_direction", "normal") " alternative: reverse  (z y x ...)
if !exists("g:netrw_sort_sequence")
 if has("unix")
  let g:netrw_sort_sequence= '[\/]$,\<core\%(\.\d\+\)\=\>,\.h$,\.c$,\.cpp$,\~\=\*$,*,\.o$,\.obj$,\.info$,\.swp$,\.bak$,\~$'
 else
  let g:netrw_sort_sequence= '[\/]$,\.h$,\.c$,\.cpp$,*,\.o$,\.obj$,\.info$,\.swp$,\.bak$,\~$'
 endif
endif
call s:NetrwInit("g:netrw_special_syntax"   , 0)
call s:NetrwInit("g:netrw_ssh_browse_reject", '^total\s\+\d\+$')
call s:NetrwInit("g:netrw_use_noswf"        , 1)
" Default values - t-w ---------- {{{3
call s:NetrwInit("g:netrw_timefmt","%c")
if !exists("g:netrw_xstrlen")
 if exists("g:Align_xstrlen")
  let g:netrw_xstrlen= g:Align_xstrlen
 elseif exists("g:drawit_xstrlen")
  let g:netrw_xstrlen= g:drawit_xstrlen
 elseif &enc == "latin1" || !has("multi_byte")
  let g:netrw_xstrlen= 0
 else
  let g:netrw_xstrlen= 1
 endif
endif
call s:NetrwInit("g:NetrwTopLvlMenu","Netrw.")
call s:NetrwInit("g:netrw_win95ftp",1)
call s:NetrwInit("g:netrw_winsize",50)
call s:NetrwInit("g:netrw_wiw",1)
if g:netrw_winsize > 100|let g:netrw_winsize= 100|endif
" ---------------------------------------------------------------------
" Default values for netrw's script variables: {{{2
call s:NetrwInit("g:netrw_fname_escape",' ?&;%')
if has("win32") || has("win95") || has("win64") || has("win16")
 call s:NetrwInit("g:netrw_glob_escape",'*?`{[]$')
else
 call s:NetrwInit("g:netrw_glob_escape",'*[]?`{~$\')
endif
call s:NetrwInit("g:netrw_menu_escape",'.&? \')
call s:NetrwInit("g:netrw_tmpfile_escape",' &;')
call s:NetrwInit("s:netrw_map_escape","<|\n\r\\\<C-V>\"")
if has("gui_running") && (&enc == 'utf-8' || &enc == 'utf-16' || &enc == 'ucs-4')
 let s:treedepthstring= "│ "
else
 let s:treedepthstring= "| "
endif

" BufEnter event ignored by decho when following variable is true
"  Has a side effect that doau BufReadPost doesn't work, so
"  files read by network transfer aren't appropriately highlighted.
"let g:decho_bufenter = 1	"Decho

" ======================
"  Netrw Initialization: {{{1
" ======================
if v:version >= 700 && has("balloon_eval") && !exists("s:initbeval") && !exists("g:netrw_nobeval") && has("syntax") && exists("g:syntax_on")
" call Decho("installed beval events",'~'.expand("<slnum>"))
 let &l:bexpr = "netrw#BalloonHelp()"
 au FileType netrw	setl beval
 au WinLeave *		if &ft == "netrw" && exists("s:initbeval")|let &beval= s:initbeval|endif
 au VimEnter * 		let s:initbeval= &beval
"else " Decho
" if v:version < 700           | call Decho("did not install beval events: v:version=".v:version." < 700","~".expand("<slnum>"))     | endif
" if !has("balloon_eval")      | call Decho("did not install beval events: does not have balloon_eval","~".expand("<slnum>"))        | endif
" if exists("s:initbeval")     | call Decho("did not install beval events: s:initbeval exists","~".expand("<slnum>"))                | endif
" if exists("g:netrw_nobeval") | call Decho("did not install beval events: g:netrw_nobeval exists","~".expand("<slnum>"))            | endif
" if !has("syntax")            | call Decho("did not install beval events: does not have syntax highlighting","~".expand("<slnum>")) | endif
" if exists("g:syntax_on")     | call Decho("did not install beval events: g:syntax_on exists","~".expand("<slnum>"))                | endif
endif
au WinEnter *	if &ft == "netrw"|call s:NetrwInsureWinVars()|endif

if g:netrw_keepj =~ "keepj"
 com! -nargs=*	NetrwKeepj	keepj <args>
else
 let g:netrw_keepj= ""
 com! -nargs=*	NetrwKeepj	<args>
endif

" ==============================
"  Netrw Utility Functions: {{{1
" ==============================

" ---------------------------------------------------------------------
" netrw#BalloonHelp: {{{2
if v:version >= 700 && has("balloon_eval") && has("syntax") && exists("g:syntax_on") && !exists("g:netrw_nobeval")
" call Decho("loading netrw#BalloonHelp()",'~'.expand("<slnum>"))
 fun! netrw#BalloonHelp()
   if &ft != "netrw"
    return ""
   endif
   if !exists("w:netrw_bannercnt") || v:beval_lnum >= w:netrw_bannercnt || (exists("g:netrw_nobeval") && g:netrw_nobeval)
    let mesg= ""
   elseif     v:beval_text == "Netrw" || v:beval_text == "Directory" || v:beval_text == "Listing"
    let mesg = "i: thin-long-wide-tree  gh: quick hide/unhide of dot-files   qf: quick file info  %:open new file"
   elseif     getline(v:beval_lnum) =~ '^"\s*/'
    let mesg = "<cr>: edit/enter   o: edit/enter in horiz window   t: edit/enter in new tab   v:edit/enter in vert window"
   elseif     v:beval_text == "Sorted" || v:beval_text == "by"
    let mesg = 's: sort by name, time, file size, extension   r: reverse sorting order   mt: mark target'
   elseif v:beval_text == "Sort"   || v:beval_text == "sequence"
    let mesg = "S: edit sorting sequence"
   elseif v:beval_text == "Hiding" || v:beval_text == "Showing"
    let mesg = "a: hiding-showing-all   ctrl-h: editing hiding list   mh: hide/show by suffix"
   elseif v:beval_text == "Quick" || v:beval_text == "Help"
    let mesg = "Help: press <F1>"
   elseif v:beval_text == "Copy/Move" || v:beval_text == "Tgt"
    let mesg = "mt: mark target   mc: copy marked file to target   mm: move marked file to target"
   else
    let mesg= ""
   endif
   return mesg
 endfun
"else " Decho
" if v:version < 700            |call Decho("did not load netrw#BalloonHelp(): vim version ".v:version." < 700 -","~".expand("<slnum>"))|endif
" if !has("balloon_eval")       |call Decho("did not load netrw#BalloonHelp(): does not have balloon eval","~".expand("<slnum>"))       |endif
" if !has("syntax")             |call Decho("did not load netrw#BalloonHelp(): syntax disabled","~".expand("<slnum>"))                  |endif
" if !exists("g:syntax_on")     |call Decho("did not load netrw#BalloonHelp(): g:syntax_on n/a","~".expand("<slnum>"))                  |endif
" if  exists("g:netrw_nobeval") |call Decho("did not load netrw#BalloonHelp(): g:netrw_nobeval exists","~".expand("<slnum>"))           |endif
endif

" ------------------------------------------------------------------------
" netrw#Explore: launch the local browser in the directory of the current file {{{2
"          indx:  == -1: Nexplore
"                 == -2: Pexplore
"                 ==  +: this is overloaded:
"                      * If Nexplore/Pexplore is in use, then this refers to the
"                        indx'th item in the w:netrw_explore_list[] of items which
"                        matched the */pattern **/pattern *//pattern **//pattern
"                      * If Hexplore or Vexplore, then this will override
"                        g:netrw_winsize to specify the qty of rows or columns the
"                        newly split window should have.
"          dosplit==0: the window will be split iff the current file has been modified and hidden not set
"          dosplit==1: the window will be split before running the local browser
"          style == 0: Explore     style == 1: Explore!
"                == 2: Hexplore    style == 3: Hexplore!
"                == 4: Vexplore    style == 5: Vexplore!
"                == 6: Texplore
fun! netrw#Explore(indx,dosplit,style,...)
"  call Dfunc("netrw#Explore(indx=".a:indx." dosplit=".a:dosplit." style=".a:style.",a:1<".a:1.">) &modified=".&modified." modifiable=".&modifiable." a:0=".a:0." win#".winnr()." buf#".bufnr("%"))
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
  if !exists("b:netrw_curdir")
   let b:netrw_curdir= getcwd()
"   call Decho("set b:netrw_curdir<".b:netrw_curdir."> (used getcwd)",'~'.expand("<slnum>"))
  endif

  " record current file for Rexplore's benefit
  if &ft != "netrw"
   let w:netrw_rexfile= expand("%:p")
  endif

  " record current directory
  let curdir     = simplify(b:netrw_curdir)
  let curfiledir = substitute(expand("%:p"),'^\(.*[/\\]\)[^/\\]*$','\1','e')
  if !exists("g:netrw_cygwin") && (has("win32") || has("win95") || has("win64") || has("win16"))
   let curdir= substitute(curdir,'\','/','g')
  endif
"  call Decho("curdir<".curdir.">  curfiledir<".curfiledir.">",'~'.expand("<slnum>"))

  " using completion, directories with spaces in their names (thanks, Bill Gates, for a truly dumb idea)
  " will end up with backslashes here.  Solution: strip off backslashes that precede white space and
  " try Explore again.
  if a:0 > 0
"   call Decho('considering retry: a:1<'.a:1.'>: '.
     \ ((a:1 =~ "\\\s")?                   'has backslash whitespace' : 'does not have backslash whitespace').', '.
     \ ((filereadable(s:NetrwFile(a:1)))?  'is readable'              : 'is not readable').', '.
     \ ((isdirectory(s:NetrwFile(a:1))))?  'is a directory'           : 'is not a directory',
     \ '~'.expand("<slnum>"))
   if a:1 =~ "\\\s" && !filereadable(s:NetrwFile(a:1)) && !isdirectory(s:NetrwFile(a:1))
"    call Decho("re-trying Explore with <".substitute(a:1,'\\\(\s\)','\1','g').">",'~'.expand("<slnum>"))
    call netrw#Explore(a:indx,a:dosplit,a:style,substitute(a:1,'\\\(\s\)','\1','g'))
"    call Dret("netrw#Explore : returning from retry")
    return
"   else " Decho
"    call Decho("retry not needed",'~'.expand("<slnum>"))
   endif
  endif

  " save registers
  if has("clipboard")
   sil! let keepregstar = @*
   sil! let keepregplus = @+
  endif
  sil! let keepregslash= @/

  " if   dosplit
  " -or- file has been modified AND file not hidden when abandoned
  " -or- Texplore used
  if a:dosplit || (&modified && &hidden == 0 && &bufhidden != "hide") || a:style == 6
"   call Decho("case dosplit=".a:dosplit." modified=".&modified." a:style=".a:style.": dosplit or file has been modified",'~'.expand("<slnum>"))
   call s:SaveWinVars()
   let winsz= g:netrw_winsize
   if a:indx > 0
    let winsz= a:indx
   endif

   if a:style == 0      " Explore, Sexplore
"    call Decho("style=0: Explore or Sexplore",'~'.expand("<slnum>"))
    let winsz= (winsz > 0)? (winsz*winheight(0))/100 : -winsz
    if winsz == 0|let winsz= ""|endif
    exe "noswapfile ".winsz."wincmd s"
"    call Decho("exe noswapfile ".winsz."wincmd s",'~'.expand("<slnum>"))

   elseif a:style == 1  "Explore!, Sexplore!
"    call Decho("style=1: Explore! or Sexplore!",'~'.expand("<slnum>"))
    let winsz= (winsz > 0)? (winsz*winwidth(0))/100 : -winsz
    if winsz == 0|let winsz= ""|endif
    exe "keepalt noswapfile ".winsz."wincmd v"
"    call Decho("exe keepalt noswapfile ".winsz."wincmd v",'~'.expand("<slnum>"))

   elseif a:style == 2  " Hexplore
"    call Decho("style=2: Hexplore",'~'.expand("<slnum>"))
    let winsz= (winsz > 0)? (winsz*winheight(0))/100 : -winsz
    if winsz == 0|let winsz= ""|endif
    exe "keepalt noswapfile bel ".winsz."wincmd s"
"    call Decho("exe keepalt noswapfile bel ".winsz."wincmd s",'~'.expand("<slnum>"))

   elseif a:style == 3  " Hexplore!
"    call Decho("style=3: Hexplore!",'~'.expand("<slnum>"))
    let winsz= (winsz > 0)? (winsz*winheight(0))/100 : -winsz
    if winsz == 0|let winsz= ""|endif
    exe "keepalt noswapfile abo ".winsz."wincmd s"
"    call Decho("exe keepalt noswapfile abo ".winsz."wincmd s",'~'.expand("<slnum>"))

   elseif a:style == 4  " Vexplore
"    call Decho("style=4: Vexplore",'~'.expand("<slnum>"))
    let winsz= (winsz > 0)? (winsz*winwidth(0))/100 : -winsz
    if winsz == 0|let winsz= ""|endif
    exe "keepalt noswapfile lefta ".winsz."wincmd v"
"    call Decho("exe keepalt noswapfile lefta ".winsz."wincmd v",'~'.expand("<slnum>"))

   elseif a:style == 5  " Vexplore!
"    call Decho("style=5: Vexplore!",'~'.expand("<slnum>"))
    let winsz= (winsz > 0)? (winsz*winwidth(0))/100 : -winsz
    if winsz == 0|let winsz= ""|endif
    exe "keepalt noswapfile rightb ".winsz."wincmd v"
"    call Decho("exe keepalt noswapfile rightb ".winsz."wincmd v",'~'.expand("<slnum>"))

   elseif a:style == 6  " Texplore
    call s:SaveBufVars()
"    call Decho("style  = 6: Texplore",'~'.expand("<slnum>"))
    exe "keepalt tabnew ".fnameescape(curdir)
"    call Decho("exe keepalt tabnew ".fnameescape(curdir),'~'.expand("<slnum>"))
    call s:RestoreBufVars()
   endif
   call s:RestoreWinVars()
"  else " Decho
"   call Decho("case a:dosplit=".a:dosplit." AND modified=".&modified." AND a:style=".a:style." is not 6",'~'.expand("<slnum>"))
  endif
  NetrwKeepj norm! 0

  if a:0 > 0
"   call Decho("case [a:0=".a:0."] > 0: a:1<".a:1.">",'~'.expand("<slnum>"))
   if a:1 =~ '^\~' && (has("unix") || (exists("g:netrw_cygwin") && g:netrw_cygwin))
"    call Decho("..case a:1<".a:1.">: starts with ~ and unix or cygwin",'~'.expand("<slnum>"))
    let dirname= simplify(substitute(a:1,'\~',expand("$HOME"),''))
"    call Decho("..using dirname<".dirname.">  (case: ~ && unix||cygwin)",'~'.expand("<slnum>"))
   elseif a:1 == '.'
"    call Decho("..case a:1<".a:1.">: matches .",'~'.expand("<slnum>"))
    let dirname= simplify(exists("b:netrw_curdir")? b:netrw_curdir : getcwd())
    if dirname !~ '/$'
     let dirname= dirname."/"
    endif
"    call Decho("..using dirname<".dirname.">  (case: ".(exists("b:netrw_curdir")? "b:netrw_curdir" : "getcwd()").")",'~'.expand("<slnum>"))
   elseif a:1 =~ '\$'
"    call Decho("..case a:1<".a:1.">: matches ending $",'~'.expand("<slnum>"))
    let dirname= simplify(expand(a:1))
"    call Decho("..using user-specified dirname<".dirname."> with $env-var",'~'.expand("<slnum>"))
   elseif a:1 !~ '^\*\{1,2}/' && a:1 !~ '^\a\{3,}://'
"    call Decho("..case a:1<".a:1.">: other, not pattern or filepattern",'~'.expand("<slnum>"))
    let dirname= simplify(a:1)
"    call Decho("..using user-specified dirname<".dirname.">",'~'.expand("<slnum>"))
   else
"    call Decho("..case a:1: pattern or filepattern",'~'.expand("<slnum>"))
    let dirname= a:1
   endif
  else
   " clear explore
"   call Decho("case a:0=".a:0.": clearing Explore list",'~'.expand("<slnum>"))
   call s:NetrwClearExplore()
"   call Dret("netrw#Explore : cleared list")
   return
  endif

"  call Decho("dirname<".dirname.">",'~'.expand("<slnum>"))
  if dirname =~ '\.\./\=$'
   let dirname= simplify(fnamemodify(dirname,':p:h'))
  elseif dirname =~ '\.\.' || dirname == '.'
   let dirname= simplify(fnamemodify(dirname,':p'))
  endif
"  call Decho("dirname<".dirname.">  (after simplify)",'~'.expand("<slnum>"))

  if dirname =~ '^\*//'
   " starpat=1: Explore *//pattern   (current directory only search for files containing pattern)
"   call Decho("case starpat=1: Explore *//pattern",'~'.expand("<slnum>"))
   let pattern= substitute(dirname,'^\*//\(.*\)$','\1','')
   let starpat= 1
"   call Decho("..Explore *//pat: (starpat=".starpat.") dirname<".dirname."> -> pattern<".pattern.">",'~'.expand("<slnum>"))
   if &hls | let keepregslash= s:ExplorePatHls(pattern) | endif

  elseif dirname =~ '^\*\*//'
   " starpat=2: Explore **//pattern  (recursive descent search for files containing pattern)
"   call Decho("case starpat=2: Explore **//pattern",'~'.expand("<slnum>"))
   let pattern= substitute(dirname,'^\*\*//','','')
   let starpat= 2
"   call Decho("..Explore **//pat: (starpat=".starpat.") dirname<".dirname."> -> pattern<".pattern.">",'~'.expand("<slnum>"))

  elseif dirname =~ '/\*\*/'
   " handle .../**/.../filepat
"   call Decho("case starpat=4: Explore .../**/.../filepat",'~'.expand("<slnum>"))
   let prefixdir= substitute(dirname,'^\(.\{-}\)\*\*.*$','\1','')
   if prefixdir =~ '^/' || (prefixdir =~ '^\a:/' && (has("win32") || has("win95") || has("win64") || has("win16")))
    let b:netrw_curdir = prefixdir
   else
    let b:netrw_curdir= getcwd().'/'.prefixdir
   endif
   let dirname= substitute(dirname,'^.\{-}\(\*\*/.*\)$','\1','')
   let starpat= 4
"   call Decho("..pwd<".getcwd()."> dirname<".dirname.">",'~'.expand("<slnum>"))
"   call Decho("..case Explore ../**/../filepat (starpat=".starpat.")",'~'.expand("<slnum>"))

  elseif dirname =~ '^\*/'
   " case starpat=3: Explore */filepat   (search in current directory for filenames matching filepat)
   let starpat= 3
"   call Decho("case starpat=3: Explore */filepat (starpat=".starpat.")",'~'.expand("<slnum>"))

  elseif dirname=~ '^\*\*/'
   " starpat=4: Explore **/filepat  (recursive descent search for filenames matching filepat)
   let starpat= 4
"   call Decho("case starpat=4: Explore **/filepat (starpat=".starpat.")",'~'.expand("<slnum>"))

  else
   let starpat= 0
"   call Decho("case starpat=0: default",'~'.expand("<slnum>"))
  endif

  if starpat == 0 && a:indx >= 0
   " [Explore Hexplore Vexplore Sexplore] [dirname]
"   call Decho("case starpat==0 && a:indx=".a:indx.": dirname<".dirname.">, handles Explore Hexplore Vexplore Sexplore",'~'.expand("<slnum>"))
   if dirname == ""
    let dirname= curfiledir
"    call Decho("..empty dirname, using current file's directory<".dirname.">",'~'.expand("<slnum>"))
   endif
   if dirname =~ '^scp://' || dirname =~ '^ftp://'
    call netrw#Nread(2,dirname)
   else
    if dirname == ""
     let dirname= getcwd()
    elseif (has("win32") || has("win95") || has("win64") || has("win16")) && !g:netrw_cygwin
     " Windows : check for a drive specifier, or else for a remote share name ('\\Foo' or '//Foo',
     " depending on whether backslashes have been converted to forward slashes by earlier code).
     if dirname !~ '^[a-zA-Z]:' && dirname !~ '^\\\\\w\+' && dirname !~ '^//\w\+'
      let dirname= b:netrw_curdir."/".dirname
     endif
    elseif dirname !~ '^/'
     let dirname= b:netrw_curdir."/".dirname
    endif
"    call Decho("..calling LocalBrowseCheck(dirname<".dirname.">)",'~'.expand("<slnum>"))
    call netrw#LocalBrowseCheck(dirname)
"    call Decho(" modified=".&modified." modifiable=".&modifiable." readonly=".&readonly,'~'.expand("<slnum>"))
"    call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
   endif
   if exists("w:netrw_bannercnt")
    " done to handle P08-Ingelrest. :Explore will _Always_ go to the line just after the banner.
    " If one wants to return the same place in the netrw window, use :Rex instead.
    exe w:netrw_bannercnt
   endif

"   call Decho("curdir<".curdir.">",'~'.expand("<slnum>"))
   " ---------------------------------------------------------------------
   " Jan 24, 2013: not sure why the following was present.  See P08-Ingelrest
"   if has("win32") || has("win95") || has("win64") || has("win16")
"    NetrwKeepj call search('\<'.substitute(curdir,'^.*[/\\]','','e').'\>','cW')
"   else
"    NetrwKeepj call search('\<'.substitute(curdir,'^.*/','','e').'\>','cW')
"   endif
   " ---------------------------------------------------------------------

  " starpat=1: Explore *//pattern  (current directory only search for files containing pattern)
  " starpat=2: Explore **//pattern (recursive descent search for files containing pattern)
  " starpat=3: Explore */filepat   (search in current directory for filenames matching filepat)
  " starpat=4: Explore **/filepat  (recursive descent search for filenames matching filepat)
  elseif a:indx <= 0
   " Nexplore, Pexplore, Explore: handle starpat
"   call Decho("case a:indx<=0: Nexplore, Pexplore, <s-down>, <s-up> starpat=".starpat." a:indx=".a:indx,'~'.expand("<slnum>"))
   if !mapcheck("<s-up>","n") && !mapcheck("<s-down>","n") && exists("b:netrw_curdir")
"    call Decho("..set up <s-up> and <s-down> maps",'~'.expand("<slnum>"))
    let s:didstarstar= 1
    nnoremap <buffer> <silent> <s-up>	:Pexplore<cr>
    nnoremap <buffer> <silent> <s-down>	:Nexplore<cr>
   endif

   if has("path_extra")
"    call Decho("..starpat=".starpat.": has +path_extra",'~'.expand("<slnum>"))
    if !exists("w:netrw_explore_indx")
     let w:netrw_explore_indx= 0
    endif

    let indx = a:indx
"    call Decho("..starpat=".starpat.": set indx= [a:indx=".indx."]",'~'.expand("<slnum>"))

    if indx == -1
     " Nexplore
"     call Decho("..case Nexplore with starpat=".starpat.": (indx=".indx.")",'~'.expand("<slnum>"))
     if !exists("w:netrw_explore_list") " sanity check
      NetrwKeepj call netrw#ErrorMsg(s:WARNING,"using Nexplore or <s-down> improperly; see help for netrw-starstar",40)
      if has("clipboard")
       sil! let @* = keepregstar
       sil! let @+ = keepregstar
      endif
      sil! let @/ = keepregslash
"      call Dret("netrw#Explore")
      return
     endif
     let indx= w:netrw_explore_indx
     if indx < 0                        | let indx= 0                           | endif
     if indx >= w:netrw_explore_listlen | let indx= w:netrw_explore_listlen - 1 | endif
     let curfile= w:netrw_explore_list[indx]
"     call Decho("....indx=".indx." curfile<".curfile.">",'~'.expand("<slnum>"))
     while indx < w:netrw_explore_listlen && curfile == w:netrw_explore_list[indx]
      let indx= indx + 1
"      call Decho("....indx=".indx." (Nexplore while loop)",'~'.expand("<slnum>"))
     endwhile
     if indx >= w:netrw_explore_listlen | let indx= w:netrw_explore_listlen - 1 | endif
"     call Decho("....Nexplore: indx= [w:netrw_explore_indx=".w:netrw_explore_indx."]=".indx,'~'.expand("<slnum>"))

    elseif indx == -2
     " Pexplore
"     call Decho("case Pexplore with starpat=".starpat.": (indx=".indx.")",'~'.expand("<slnum>"))
     if !exists("w:netrw_explore_list") " sanity check
      NetrwKeepj call netrw#ErrorMsg(s:WARNING,"using Pexplore or <s-up> improperly; see help for netrw-starstar",41)
      if has("clipboard")
       sil! let @* = keepregstar
       sil! let @+ = keepregstar
      endif
      sil! let @/ = keepregslash
"      call Dret("netrw#Explore")
      return
     endif
     let indx= w:netrw_explore_indx
     if indx < 0                        | let indx= 0                           | endif
     if indx >= w:netrw_explore_listlen | let indx= w:netrw_explore_listlen - 1 | endif
     let curfile= w:netrw_explore_list[indx]
"     call Decho("....indx=".indx." curfile<".curfile.">",'~'.expand("<slnum>"))
     while indx >= 0 && curfile == w:netrw_explore_list[indx]
      let indx= indx - 1
"      call Decho("....indx=".indx." (Pexplore while loop)",'~'.expand("<slnum>"))
     endwhile
     if indx < 0                        | let indx= 0                           | endif
"     call Decho("....Pexplore: indx= [w:netrw_explore_indx=".w:netrw_explore_indx."]=".indx,'~'.expand("<slnum>"))

    else
     " Explore -- initialize
     " build list of files to Explore with Nexplore/Pexplore
"     call Decho("..starpat=".starpat.": case Explore: initialize (indx=".indx.")",'~'.expand("<slnum>"))
     NetrwKeepj keepalt call s:NetrwClearExplore()
     let w:netrw_explore_indx= 0
     if !exists("b:netrw_curdir")
      let b:netrw_curdir= getcwd()
     endif
"     call Decho("....starpat=".starpat.": b:netrw_curdir<".b:netrw_curdir.">",'~'.expand("<slnum>"))

     " switch on starpat to build the w:netrw_explore_list of files
     if starpat == 1
      " starpat=1: Explore *//pattern  (current directory only search for files containing pattern)
"      call Decho("..case starpat=".starpat.": build *//pattern list  (curdir-only srch for files containing pattern)  &hls=".&hls,'~'.expand("<slnum>"))
"      call Decho("....pattern<".pattern.">",'~'.expand("<slnum>"))
      try
       exe "NetrwKeepj noautocmd vimgrep /".pattern."/gj ".fnameescape(b:netrw_curdir)."/*"
      catch /^Vim\%((\a\+)\)\=:E480/
       keepalt call netrw#ErrorMsg(s:WARNING,"no match with pattern<".pattern.">",76)
"       call Dret("netrw#Explore : unable to find pattern<".pattern.">")
       return
      endtry
      let w:netrw_explore_list = s:NetrwExploreListUniq(map(getqflist(),'bufname(v:val.bufnr)'))
      if &hls | let keepregslash= s:ExplorePatHls(pattern) | endif

     elseif starpat == 2
      " starpat=2: Explore **//pattern (recursive descent search for files containing pattern)
"      call Decho("..case starpat=".starpat.": build **//pattern list  (recursive descent files containing pattern)",'~'.expand("<slnum>"))
"      call Decho("....pattern<".pattern.">",'~'.expand("<slnum>"))
      try
       exe "sil NetrwKeepj noautocmd keepalt vimgrep /".pattern."/gj "."**/*"
      catch /^Vim\%((\a\+)\)\=:E480/
       keepalt call netrw#ErrorMsg(s:WARNING,'no files matched pattern<'.pattern.'>',45)
       if &hls | let keepregslash= s:ExplorePatHls(pattern) | endif
       if has("clipboard")
        sil! let @* = keepregstar
        sil! let @+ = keepregstar
       endif
       sil! let @/ = keepregslash
"       call Dret("netrw#Explore : no files matched pattern")
       return
      endtry
      let s:netrw_curdir       = b:netrw_curdir
      let w:netrw_explore_list = getqflist()
      let w:netrw_explore_list = s:NetrwExploreListUniq(map(w:netrw_explore_list,'s:netrw_curdir."/".bufname(v:val.bufnr)'))
      if &hls | let keepregslash= s:ExplorePatHls(pattern) | endif

     elseif starpat == 3
      " starpat=3: Explore */filepat   (search in current directory for filenames matching filepat)
"      call Decho("..case starpat=".starpat.": build */filepat list  (curdir-only srch filenames matching filepat)  &hls=".&hls,'~'.expand("<slnum>"))
      let filepat= substitute(dirname,'^\*/','','')
      let filepat= substitute(filepat,'^[%#<]','\\&','')
"      call Decho("....b:netrw_curdir<".b:netrw_curdir.">",'~'.expand("<slnum>"))
"      call Decho("....filepat<".filepat.">",'~'.expand("<slnum>"))
      let w:netrw_explore_list= s:NetrwExploreListUniq(split(expand(b:netrw_curdir."/".filepat),'\n'))
      if &hls | let keepregslash= s:ExplorePatHls(filepat) | endif

     elseif starpat == 4
      " starpat=4: Explore **/filepat  (recursive descent search for filenames matching filepat)
"      call Decho("..case starpat=".starpat.": build **/filepat list  (recursive descent srch filenames matching filepat)  &hls=".&hls,'~'.expand("<slnum>"))
      let w:netrw_explore_list= s:NetrwExploreListUniq(split(expand(b:netrw_curdir."/".dirname),'\n'))
      if &hls | let keepregslash= s:ExplorePatHls(dirname) | endif
     endif " switch on starpat to build w:netrw_explore_list

     let w:netrw_explore_listlen = len(w:netrw_explore_list)
"     call Decho("....w:netrw_explore_list<".string(w:netrw_explore_list).">",'~'.expand("<slnum>"))
"     call Decho("....w:netrw_explore_listlen=".w:netrw_explore_listlen,'~'.expand("<slnum>"))

     if w:netrw_explore_listlen == 0 || (w:netrw_explore_listlen == 1 && w:netrw_explore_list[0] =~ '\*\*\/')
      keepalt NetrwKeepj call netrw#ErrorMsg(s:WARNING,"no files matched",42)
      if has("clipboard")
       sil! let @* = keepregstar
       sil! let @+ = keepregstar
      endif
      sil! let @/ = keepregslash
"      call Dret("netrw#Explore : no files matched")
      return
     endif
    endif  " if indx ... endif

    " NetrwStatusLine support - for exploring support
    let w:netrw_explore_indx= indx
"    call Decho("....w:netrw_explore_list<".join(w:netrw_explore_list,',')."> len=".w:netrw_explore_listlen,'~'.expand("<slnum>"))

    " wrap the indx around, but issue a note
    if indx >= w:netrw_explore_listlen || indx < 0
"     call Decho("....wrap indx (indx=".indx." listlen=".w:netrw_explore_listlen.")",'~'.expand("<slnum>"))
     let indx                = (indx < 0)? ( w:netrw_explore_listlen - 1 ) : 0
     let w:netrw_explore_indx= indx
     keepalt NetrwKeepj call netrw#ErrorMsg(s:NOTE,"no more files match Explore pattern",43)
    endif

    exe "let dirfile= w:netrw_explore_list[".indx."]"
"    call Decho("....dirfile=w:netrw_explore_list[indx=".indx."]= <".dirfile.">",'~'.expand("<slnum>"))
    let newdir= substitute(dirfile,'/[^/]*$','','e')
"    call Decho("....newdir<".newdir.">",'~'.expand("<slnum>"))

"    call Decho("....calling LocalBrowseCheck(newdir<".newdir.">)",'~'.expand("<slnum>"))
    call netrw#LocalBrowseCheck(newdir)
    if !exists("w:netrw_liststyle")
     let w:netrw_liststyle= g:netrw_liststyle
    endif
    if w:netrw_liststyle == s:THINLIST || w:netrw_liststyle == s:LONGLIST
     keepalt NetrwKeepj call search('^'.substitute(dirfile,"^.*/","","").'\>',"W")
    else
     keepalt NetrwKeepj call search('\<'.substitute(dirfile,"^.*/","","").'\>',"w")
    endif
    let w:netrw_explore_mtchcnt = indx + 1
    let w:netrw_explore_bufnr   = bufnr("%")
    let w:netrw_explore_line    = line(".")
    keepalt NetrwKeepj call s:SetupNetrwStatusLine('%f %h%m%r%=%9*%{NetrwStatusLine()}')
"    call Decho("....explore: mtchcnt=".w:netrw_explore_mtchcnt." bufnr=".w:netrw_explore_bufnr." line#".w:netrw_explore_line,'~'.expand("<slnum>"))

   else
"    call Decho("..your vim does not have +path_extra",'~'.expand("<slnum>"))
    if !exists("g:netrw_quiet")
     keepalt NetrwKeepj call netrw#ErrorMsg(s:WARNING,"your vim needs the +path_extra feature for Exploring with **!",44)
    endif
    if has("clipboard")
     sil! let @* = keepregstar
     sil! let @+ = keepregstar
    endif
    sil! let @/ = keepregslash
"    call Dret("netrw#Explore : missing +path_extra")
    return
   endif

  else
"   call Decho("..default case: Explore newdir<".dirname.">",'~'.expand("<slnum>"))
   if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && dirname =~ '/'
    sil! unlet w:netrw_treedict
    sil! unlet w:netrw_treetop
   endif
   let newdir= dirname
   if !exists("b:netrw_curdir")
    NetrwKeepj call netrw#LocalBrowseCheck(getcwd())
   else
    NetrwKeepj call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(1,newdir))
   endif
  endif

  " visual display of **/ **// */ Exploration files
"  call Decho("w:netrw_explore_indx=".(exists("w:netrw_explore_indx")? w:netrw_explore_indx : "doesn't exist"),'~'.expand("<slnum>"))
"  call Decho("b:netrw_curdir<".(exists("b:netrw_curdir")? b:netrw_curdir : "n/a").">",'~'.expand("<slnum>"))
  if exists("w:netrw_explore_indx") && exists("b:netrw_curdir")
"   call Decho("s:explore_prvdir<".(exists("s:explore_prvdir")? s:explore_prvdir : "-doesn't exist-"),'~'.expand("<slnum>"))
   if !exists("s:explore_prvdir") || s:explore_prvdir != b:netrw_curdir
    " only update match list when current directory isn't the same as before
"    call Decho("only update match list when current directory not the same as before",'~'.expand("<slnum>"))
    let s:explore_prvdir = b:netrw_curdir
    let s:explore_match  = ""
    let dirlen           = strlen(b:netrw_curdir)
    if b:netrw_curdir !~ '/$'
     let dirlen= dirlen + 1
    endif
    let prvfname= ""
    for fname in w:netrw_explore_list
"     call Decho("fname<".fname.">",'~'.expand("<slnum>"))
     if fname =~ '^'.b:netrw_curdir
      if s:explore_match == ""
       let s:explore_match= '\<'.escape(strpart(fname,dirlen),g:netrw_markfileesc).'\>'
      else
       let s:explore_match= s:explore_match.'\|\<'.escape(strpart(fname,dirlen),g:netrw_markfileesc).'\>'
      endif
     elseif fname !~ '^/' && fname != prvfname
      if s:explore_match == ""
       let s:explore_match= '\<'.escape(fname,g:netrw_markfileesc).'\>'
      else
       let s:explore_match= s:explore_match.'\|\<'.escape(fname,g:netrw_markfileesc).'\>'
      endif
     endif
     let prvfname= fname
    endfor
"    call Decho("explore_match<".s:explore_match.">",'~'.expand("<slnum>"))
    exe "2match netrwMarkFile /".s:explore_match."/"
   endif
   echo "<s-up>==Pexplore  <s-down>==Nexplore"
  else
   2match none
   if exists("s:explore_match")  | unlet s:explore_match  | endif
   if exists("s:explore_prvdir") | unlet s:explore_prvdir | endif
   echo " "
"   call Decho("cleared explore match list",'~'.expand("<slnum>"))
  endif

  " since Explore may be used to initialize netrw's browser,
  " there's no danger of a late FocusGained event on initialization.
  " Consequently, set s:netrw_events to 2.
  let s:netrw_events= 2
  if has("clipboard")
   sil! let @* = keepregstar
   sil! let @+ = keepregstar
  endif
  sil! let @/ = keepregslash
"  call Dret("netrw#Explore : @/<".@/.">")
endfun

" ---------------------------------------------------------------------
" netrw#Lexplore: toggle Explorer window, keeping it on the left of the current tab {{{2
fun! netrw#Lexplore(count,rightside,...)
"  call Dfunc("netrw#Lexplore(count=".a:count."rightside=".a:rightside.",...) a:0=".a:0." ft=".&ft)
  let curwin= winnr()

  if a:0 > 0 && a:1 != ""
   " if a netrw window is already on the left-side of the tab
   " and a directory has been specified, explore with that
   " directory.
   let a1 = expand(a:1)
"   call Decho("a:1<".a:1.">  curwin#".curwin,'~'.expand("<slnum>"))
   exe "1wincmd w"
   if &ft == "netrw"
"    call Decho("exe Explore ".fnameescape(a:1),'~'.expand("<slnum>"))
    exe "Explore ".fnameescape(a1)
    exe curwin."wincmd w"
    if exists("t:netrw_lexposn")
"     call Decho("forgetting t:netrw_lexposn",'~'.expand("<slnum>"))
     unlet t:netrw_lexposn
    endif
"    call Dret("netrw#Lexplore")
    return
   endif
   exe curwin."wincmd w"
  else
   let a1= ""
  endif

  if exists("t:netrw_lexbufnr")
   " check if t:netrw_lexbufnr refers to a netrw window
   let lexwinnr = bufwinnr(t:netrw_lexbufnr)
  else
   let lexwinnr= 0
  endif

  if lexwinnr > 0
   " close down netrw explorer window
"  call Decho("t:netrw_lexbufnr#".t:netrw_lexbufnr.": close down netrw window",'~'.expand("<slnum>"))
   exe lexwinnr."wincmd w"
   let g:netrw_winsize = -winwidth(0)
   let t:netrw_lexposn = netrw#SavePosn()
"   call Decho("saving t:netrw_lexposn",'~'.expand("<slnum>"))
   close
   if lexwinnr < curwin
    let curwin= curwin - 1
   endif
   exe curwin."wincmd w"
   unlet t:netrw_lexbufnr

  else
   " open netrw explorer window
"   call Decho("t:netrw_lexbufnr<n/a>: open netrw explorer window",'~'.expand("<slnum>"))
   exe "1wincmd w"
   let keep_altv    = g:netrw_altv
   let g:netrw_altv = 0
   if a:count != 0
    let netrw_winsize   = g:netrw_winsize
    let g:netrw_winsize = a:count
   endif
   let curfile= expand("%")
"   call Decho("curfile<".curfile.">",'~'.expand("<slnum>"))
   exe (a:rightside? "botright" : "topleft")." vertical ".((g:netrw_winsize > 0)? (g:netrw_winsize*winwidth(0))/100 : -g:netrw_winsize) . " new"
   if a:0 > 0 && a1 != ""
"    call Decho("case 1: Explore ".a1,'~'.expand("<slnum>"))
    exe "Explore ".fnameescape(a1)
   elseif curfile =~ '^\a\{3,}://'
"    call Decho("case 2: Explore ".substitute(curfile,'[^/\\]*$','',''),'~'.expand("<slnum>"))
    exe "Explore ".substitute(curfile,'[^/\\]*$','','')
   else
"    call Decho("case 3: Explore .",'~'.expand("<slnum>"))
    Explore .
   endif
   if a:count != 0
    let g:netrw_winsize = netrw_winsize
   endif
   setlocal winfixwidth
   let g:netrw_altv     = keep_altv
   let t:netrw_lexbufnr = bufnr("%")
   if exists("t:netrw_lexposn")
"    call Decho("restoring to t:netrw_lexposn",'~'.expand("<slnum>"))
    call netrw#RestorePosn(t:netrw_lexposn)
    unlet t:netrw_lexposn
   endif
  endif

  " set up default window for editing via <cr>
  if exists("g:netrw_chgwin") && g:netrw_chgwin == -1
   if a:rightside
    let g:netrw_chgwin= 1
   else
    let g:netrw_chgwin= 2
   endif
  endif

"  call Dret("netrw#Lexplore")
endfun

" ---------------------------------------------------------------------
" netrw#Clean: remove netrw {{{2
" supports :NetrwClean  -- remove netrw from first directory on runtimepath
"          :NetrwClean! -- remove netrw from all directories on runtimepath
fun! netrw#Clean(sys)
"  call Dfunc("netrw#Clean(sys=".a:sys.")")

  if a:sys
   let choice= confirm("Remove personal and system copies of netrw?","&Yes\n&No")
  else
   let choice= confirm("Remove personal copy of netrw?","&Yes\n&No")
  endif
"  call Decho("choice=".choice,'~'.expand("<slnum>"))
  let diddel= 0
  let diddir= ""

  if choice == 1
   for dir in split(&rtp,',')
    if filereadable(dir."/plugin/netrwPlugin.vim")
"     call Decho("removing netrw-related files from ".dir,'~'.expand("<slnum>"))
     if s:NetrwDelete(dir."/plugin/netrwPlugin.vim")        |call netrw#ErrorMsg(1,"unable to remove ".dir."/plugin/netrwPlugin.vim",55)        |endif
     if s:NetrwDelete(dir."/autoload/netrwFileHandlers.vim")|call netrw#ErrorMsg(1,"unable to remove ".dir."/autoload/netrwFileHandlers.vim",55)|endif
     if s:NetrwDelete(dir."/autoload/netrwSettings.vim")    |call netrw#ErrorMsg(1,"unable to remove ".dir."/autoload/netrwSettings.vim",55)    |endif
     if s:NetrwDelete(dir."/autoload/netrw.vim")            |call netrw#ErrorMsg(1,"unable to remove ".dir."/autoload/netrw.vim",55)            |endif
     if s:NetrwDelete(dir."/syntax/netrw.vim")              |call netrw#ErrorMsg(1,"unable to remove ".dir."/syntax/netrw.vim",55)              |endif
     if s:NetrwDelete(dir."/syntax/netrwlist.vim")          |call netrw#ErrorMsg(1,"unable to remove ".dir."/syntax/netrwlist.vim",55)          |endif
     let diddir= dir
     let diddel= diddel + 1
     if !a:sys|break|endif
    endif
   endfor
  endif

   echohl WarningMsg
  if diddel == 0
   echomsg "netrw is either not installed or not removable"
  elseif diddel == 1
   echomsg "removed one copy of netrw from <".diddir.">"
  else
   echomsg "removed ".diddel." copies of netrw"
  endif
   echohl None

"  call Dret("netrw#Clean")
endfun

" ---------------------------------------------------------------------
" netrw#MakeTgt: make a target out of the directory name provided {{{2
fun! netrw#MakeTgt(dname)
"  call Dfunc("netrw#MakeTgt(dname<".a:dname.">)")
   " simplify the target (eg. /abc/def/../ghi -> /abc/ghi)
  let svpos               = netrw#SavePosn()
  let s:netrwmftgt_islocal= (a:dname !~ '^\a\{3,}://')
"  call Decho("s:netrwmftgt_islocal=".s:netrwmftgt_islocal,'~'.expand("<slnum>"))
  if s:netrwmftgt_islocal
   let netrwmftgt= simplify(a:dname)
  else
   let netrwmftgt= a:dname
  endif
  if exists("s:netrwmftgt") && netrwmftgt == s:netrwmftgt
   " re-selected target, so just clear it
   unlet s:netrwmftgt s:netrwmftgt_islocal
  else
   let s:netrwmftgt= netrwmftgt
  endif
  if g:netrw_fastbrowse <= 1
   call s:NetrwRefresh((b:netrw_curdir !~ '\a\{3,}://'),b:netrw_curdir)
  endif
  call netrw#RestorePosn(svpos)
"  call Dret("netrw#MakeTgt")
endfun

" ---------------------------------------------------------------------
" netrw#Obtain: {{{2
"   netrw#Obtain(islocal,fname[,tgtdirectory])
"     islocal=0  obtain from remote source
"            =1  obtain from local source
"     fname  :   a filename or a list of filenames
"     tgtdir :   optional place where files are to go  (not present, uses getcwd())
fun! netrw#Obtain(islocal,fname,...)
"  call Dfunc("netrw#Obtain(islocal=".a:islocal." fname<".((type(a:fname) == 1)? a:fname : string(a:fname)).">) a:0=".a:0)
  " NetrwStatusLine support - for obtaining support

  if type(a:fname) == 1
   let fnamelist= [ a:fname ]
  elseif type(a:fname) == 3
   let fnamelist= a:fname
  else
   call netrw#ErrorMsg(s:ERROR,"attempting to use NetrwObtain on something not a filename or a list",62)
"   call Dret("netrw#Obtain")
   return
  endif
"  call Decho("fnamelist<".string(fnamelist).">",'~'.expand("<slnum>"))
  if a:0 > 0
   let tgtdir= a:1
  else
   let tgtdir= getcwd()
  endif
"  call Decho("tgtdir<".tgtdir.">",'~'.expand("<slnum>"))

  if exists("b:netrw_islocal") && b:netrw_islocal
   " obtain a file from local b:netrw_curdir to (local) tgtdir
"   call Decho("obtain a file from local ".b:netrw_curdir." to ".tgtdir,'~'.expand("<slnum>"))
   if exists("b:netrw_curdir") && getcwd() != b:netrw_curdir
    let topath= s:ComposePath(tgtdir,"")
    if (has("win32") || has("win95") || has("win64") || has("win16"))
     " transfer files one at time
"     call Decho("transfer files one at a time",'~'.expand("<slnum>"))
     for fname in fnamelist
"      call Decho("system(".g:netrw_localcopycmd." ".shellescape(fname)." ".shellescape(topath).")",'~'.expand("<slnum>"))
      call system(g:netrw_localcopycmd." ".shellescape(fname)." ".shellescape(topath))
      if v:shell_error != 0
       call netrw#ErrorMsg(s:WARNING,"consider setting g:netrw_localcopycmd<".g:netrw_localcopycmd."> to something that works",80)
"       call Dret("s:NetrwObtain 0 : failed: ".g:netrw_localcopycmd." ".shellescape(fname)." ".shellescape(topath))
       return
      endif
     endfor
    else
     " transfer files with one command
"     call Decho("transfer files with one command",'~'.expand("<slnum>"))
     let filelist= join(map(deepcopy(fnamelist),"shellescape(v:val)"))
"     call Decho("system(".g:netrw_localcopycmd." ".filelist." ".shellescape(topath).")",'~'.expand("<slnum>"))
     call system(g:netrw_localcopycmd." ".filelist." ".shellescape(topath))
     if v:shell_error != 0
      call netrw#ErrorMsg(s:WARNING,"consider setting g:netrw_localcopycmd<".g:netrw_localcopycmd."> to something that works",80)
"      call Dret("s:NetrwObtain 0 : failed: ".g:netrw_localcopycmd." ".filelist." ".shellescape(topath))
      return
     endif
    endif
   elseif !exists("b:netrw_curdir")
    call netrw#ErrorMsg(s:ERROR,"local browsing directory doesn't exist!",36)
   else
    call netrw#ErrorMsg(s:WARNING,"local browsing directory and current directory are identical",37)
   endif

  else
   " obtain files from remote b:netrw_curdir to local tgtdir
"   call Decho("obtain a file from remote ".b:netrw_curdir." to ".tgtdir,'~'.expand("<slnum>"))
   if type(a:fname) == 1
    call s:SetupNetrwStatusLine('%f %h%m%r%=%9*Obtaining '.a:fname)
   endif
   call s:NetrwMethod(b:netrw_curdir)

   if b:netrw_method == 4
    " obtain file using scp
"    call Decho("obtain via scp (method#4)",'~'.expand("<slnum>"))
    if exists("g:netrw_port") && g:netrw_port != ""
     let useport= " ".g:netrw_scpport." ".g:netrw_port
    else
     let useport= ""
    endif
    if b:netrw_fname =~ '/'
     let path= substitute(b:netrw_fname,'^\(.*/\).\{-}$','\1','')
    else
     let path= ""
    endif
    let filelist= join(map(deepcopy(fnamelist),'shellescape(g:netrw_machine.":".path.v:val,1)'))
    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_scp_cmd.shellescape(useport,1)." ".filelist." ".shellescape(tgtdir,1))

   elseif b:netrw_method == 2
    " obtain file using ftp + .netrc
"     call Decho("obtain via ftp+.netrc (method #2)",'~'.expand("<slnum>"))
     call s:SaveBufVars()|sil NetrwKeepj new|call s:RestoreBufVars()
     let tmpbufnr= bufnr("%")
     setl ff=unix
     if exists("g:netrw_ftpmode") && g:netrw_ftpmode != ""
      NetrwKeepj put =g:netrw_ftpmode
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endif

     if exists("b:netrw_fname") && b:netrw_fname != ""
      call setline(line("$")+1,'cd "'.b:netrw_fname.'"')
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endif

     if exists("g:netrw_ftpextracmd")
      NetrwKeepj put =g:netrw_ftpextracmd
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endif
     for fname in fnamelist
      call setline(line("$")+1,'get "'.fname.'"')
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endfor
     if exists("g:netrw_port") && g:netrw_port != ""
      call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1)." ".shellescape(g:netrw_port,1))
     else
      call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1))
     endif
     " If the result of the ftp operation isn't blank, show an error message (tnx to Doug Claar)
     if getline(1) !~ "^$" && !exists("g:netrw_quiet") && getline(1) !~ '^Trying '
      let debugkeep= &debug
      setl debug=msg
      call netrw#ErrorMsg(s:ERROR,getline(1),4)
      let &debug= debugkeep
     endif

   elseif b:netrw_method == 3
    " obtain with ftp + machine, id, passwd, and fname (ie. no .netrc)
"    call Decho("obtain via ftp+mipf (method #3)",'~'.expand("<slnum>"))
    call s:SaveBufVars()|sil NetrwKeepj new|call s:RestoreBufVars()
    let tmpbufnr= bufnr("%")
    setl ff=unix

    if exists("g:netrw_port") && g:netrw_port != ""
     NetrwKeepj put ='open '.g:netrw_machine.' '.g:netrw_port
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
    else
     NetrwKeepj put ='open '.g:netrw_machine
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
    endif

    if exists("g:netrw_uid") && g:netrw_uid != ""
     if exists("g:netrw_ftp") && g:netrw_ftp == 1
      NetrwKeepj put =g:netrw_uid
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
      if exists("s:netrw_passwd") && s:netrw_passwd != ""
       NetrwKeepj put ='\"'.s:netrw_passwd.'\"'
      endif
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     elseif exists("s:netrw_passwd")
      NetrwKeepj put ='user \"'.g:netrw_uid.'\" \"'.s:netrw_passwd.'\"'
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endif
    endif

    if exists("g:netrw_ftpmode") && g:netrw_ftpmode != ""
     NetrwKeepj put =g:netrw_ftpmode
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
    endif

    if exists("b:netrw_fname") && b:netrw_fname != ""
     NetrwKeepj call setline(line("$")+1,'cd "'.b:netrw_fname.'"')
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
    endif

    if exists("g:netrw_ftpextracmd")
     NetrwKeepj put =g:netrw_ftpextracmd
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
    endif

    if exists("g:netrw_ftpextracmd")
     NetrwKeepj put =g:netrw_ftpextracmd
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
    endif
    for fname in fnamelist
     NetrwKeepj call setline(line("$")+1,'get "'.fname.'"')
    endfor
"    call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))

    " perform ftp:
    " -i       : turns off interactive prompting from ftp
    " -n  unix : DON'T use <.netrc>, even though it exists
    " -n  win32: quit being obnoxious about password
    NetrwKeepj norm! 1Gdd
    call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." ".g:netrw_ftp_options)
    " If the result of the ftp operation isn't blank, show an error message (tnx to Doug Claar)
    if getline(1) !~ "^$"
"     call Decho("error<".getline(1).">",'~'.expand("<slnum>"))
     if !exists("g:netrw_quiet")
      NetrwKeepj call netrw#ErrorMsg(s:ERROR,getline(1),5)
     endif
    endif

   elseif b:netrw_method == 9
    " obtain file using sftp
"    call Decho("obtain via sftp (method #9)",'~'.expand("<slnum>"))
    if a:fname =~ '/'
     let localfile= substitute(a:fname,'^.*/','','')
    else
     let localfile= a:fname
    endif
    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_sftp_cmd." ".shellescape(g:netrw_machine.":".b:netrw_fname,1).shellescape(localfile)." ".shellescape(tgtdir))

   elseif !exists("b:netrw_method") || b:netrw_method < 0
    " probably a badly formed url; protocol not recognized
"    call Dret("netrw#Obtain : unsupported method")
    return

   else
    " protocol recognized but not supported for Obtain (yet?)
    if !exists("g:netrw_quiet")
     NetrwKeepj call netrw#ErrorMsg(s:ERROR,"current protocol not supported for obtaining file",97)
    endif
"    call Dret("netrw#Obtain : current protocol not supported for obtaining file")
    return
   endif

   " restore status line
   if type(a:fname) == 1 && exists("s:netrw_users_stl")
    NetrwKeepj call s:SetupNetrwStatusLine(s:netrw_users_stl)
   endif

  endif

  " cleanup
  if exists("tmpbufnr")
   if bufnr("%") != tmpbufnr
    exe tmpbufnr."bw!"
   else
    q!
   endif
  endif

"  call Dret("netrw#Obtain")
endfun

" ---------------------------------------------------------------------
" netrw#Nread: save position, call netrw#NetRead(), and restore position {{{2
fun! netrw#Nread(mode,fname)
"  call Dfunc("netrw#Nread(mode=".a:mode." fname<".a:fname.">)")
  call netrw#SavePosn()
  call netrw#NetRead(a:mode,a:fname)
  call netrw#RestorePosn()

  if exists("w:netrw_liststyle") && w:netrw_liststyle != s:TREELIST
   if exists("w:netrw_bannercnt")
    " start with cursor just after the banner
    exe w:netrw_bannercnt
   endif
  endif
"  call Dret("netrw#Nread")
endfun

" ------------------------------------------------------------------------
" s:NetrwOptionRestore: restore options (based on prior s:NetrwOptionSave) {{{2
fun! s:NetrwOptionRestore(vt)
"  call Dfunc("s:NetrwOptionRestore(vt<".a:vt.">) win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> winnr($)=".winnr("$"))
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo." a:vt=".a:vt,'~'.expand("<slnum>"))
  if !exists("{a:vt}netrw_optionsave")
   if exists("s:nbcd_curpos_{bufnr('%')}")
"    call Decho("restoring previous position  (s:nbcd_curpos_".bufnr('%')." exists)",'~'.expand("<slnum>"))
    NetrwKeepj call netrw#RestorePosn(s:nbcd_curpos_{bufnr('%')})
"    call Decho("win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> winnr($)=".winnr("$"),'~'.expand("<slnum>"))
"    call Decho("unlet s:nbcd_curpos_".bufnr('%'),'~'.expand("<slnum>"))
    unlet s:nbcd_curpos_{bufnr('%')}
   else
"    call Decho("no previous position",'~'.expand("<slnum>"))
   endif
"   call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo." a:vt=".a:vt,'~'.expand("<slnum>"))
"   call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"   call Dret("s:NetrwOptionRestore : ".a:vt."netrw_optionsave doesn't exist")
   return
  endif
  unlet {a:vt}netrw_optionsave

  if exists("+acd")
   if exists("{a:vt}netrw_acdkeep")
"    call Decho("g:netrw_keepdir=".g:netrw_keepdir.": getcwd<".getcwd()."> acd=".&acd,'~'.expand("<slnum>"))
    let curdir = getcwd()
    let &l:acd = {a:vt}netrw_acdkeep
    unlet {a:vt}netrw_acdkeep
    if &l:acd
     call s:NetrwLcd(curdir)
    endif
   endif
  endif
  if exists("{a:vt}netrw_aikeep")   |let &l:ai     = {a:vt}netrw_aikeep      |unlet {a:vt}netrw_aikeep   |endif
  if exists("{a:vt}netrw_awkeep")   |let &l:aw     = {a:vt}netrw_awkeep      |unlet {a:vt}netrw_awkeep   |endif
  if exists("{a:vt}netrw_blkeep")   |let &l:bl     = {a:vt}netrw_blkeep      |unlet {a:vt}netrw_blkeep   |endif
  if exists("{a:vt}netrw_btkeep")   |let &l:bt     = {a:vt}netrw_btkeep      |unlet {a:vt}netrw_btkeep   |endif
  if exists("{a:vt}netrw_bombkeep") |let &l:bomb   = {a:vt}netrw_bombkeep    |unlet {a:vt}netrw_bombkeep |endif
  if exists("{a:vt}netrw_cedit")    |let &cedit    = {a:vt}netrw_cedit       |unlet {a:vt}netrw_cedit    |endif
  if exists("{a:vt}netrw_cikeep")   |let &l:ci     = {a:vt}netrw_cikeep      |unlet {a:vt}netrw_cikeep   |endif
  if exists("{a:vt}netrw_cinkeep")  |let &l:cin    = {a:vt}netrw_cinkeep     |unlet {a:vt}netrw_cinkeep  |endif
  if exists("{a:vt}netrw_cinokeep") |let &l:cino   = {a:vt}netrw_cinokeep    |unlet {a:vt}netrw_cinokeep |endif
  if exists("{a:vt}netrw_comkeep")  |let &l:com    = {a:vt}netrw_comkeep     |unlet {a:vt}netrw_comkeep  |endif
  if exists("{a:vt}netrw_cpokeep")  |let &l:cpo    = {a:vt}netrw_cpokeep     |unlet {a:vt}netrw_cpokeep  |endif
  if exists("{a:vt}netrw_diffkeep") |let &l:diff   = {a:vt}netrw_diffkeep    |unlet {a:vt}netrw_diffkeep |endif
  if exists("{a:vt}netrw_fenkeep")  |let &l:fen    = {a:vt}netrw_fenkeep     |unlet {a:vt}netrw_fenkeep  |endif
  if exists("g:netrw_ffkep") && g:netrw_ffkeep
   if exists("{a:vt}netrw_ffkeep")   |let &l:ff     = {a:vt}netrw_ffkeep      |unlet {a:vt}netrw_ffkeep   |endif
  endif
  if exists("{a:vt}netrw_fokeep")   |let &l:fo     = {a:vt}netrw_fokeep      |unlet {a:vt}netrw_fokeep   |endif
  if exists("{a:vt}netrw_gdkeep")   |let &l:gd     = {a:vt}netrw_gdkeep      |unlet {a:vt}netrw_gdkeep   |endif
  if exists("{a:vt}netrw_hidkeep")  |let &l:hidden = {a:vt}netrw_hidkeep     |unlet {a:vt}netrw_hidkeep  |endif
  if exists("{a:vt}netrw_imkeep")   |let &l:im     = {a:vt}netrw_imkeep      |unlet {a:vt}netrw_imkeep   |endif
  if exists("{a:vt}netrw_iskkeep")  |let &l:isk    = {a:vt}netrw_iskkeep     |unlet {a:vt}netrw_iskkeep  |endif
  if exists("{a:vt}netrw_lskeep")   |let &l:ls     = {a:vt}netrw_lskeep      |unlet {a:vt}netrw_lskeep   |endif
  if exists("{a:vt}netrw_makeep")   |let &l:ma     = {a:vt}netrw_makeep      |unlet {a:vt}netrw_makeep   |endif
  if exists("{a:vt}netrw_magickeep")|let &l:magic  = {a:vt}netrw_magickeep   |unlet {a:vt}netrw_magickeep|endif
  if exists("{a:vt}netrw_modkeep")  |let &l:mod    = {a:vt}netrw_modkeep     |unlet {a:vt}netrw_modkeep  |endif
  if exists("{a:vt}netrw_nukeep")   |let &l:nu     = {a:vt}netrw_nukeep      |unlet {a:vt}netrw_nukeep   |endif
  if exists("{a:vt}netrw_rnukeep")  |let &l:rnu    = {a:vt}netrw_rnukeep     |unlet {a:vt}netrw_rnukeep  |endif
  if exists("{a:vt}netrw_repkeep")  |let &l:report = {a:vt}netrw_repkeep     |unlet {a:vt}netrw_repkeep  |endif
  if exists("{a:vt}netrw_rokeep")   |let &l:ro     = {a:vt}netrw_rokeep      |unlet {a:vt}netrw_rokeep   |endif
  if exists("{a:vt}netrw_selkeep")  |let &l:sel    = {a:vt}netrw_selkeep     |unlet {a:vt}netrw_selkeep  |endif
  if exists("{a:vt}netrw_spellkeep")|let &l:spell  = {a:vt}netrw_spellkeep   |unlet {a:vt}netrw_spellkeep|endif
  if has("clipboard")
   if exists("{a:vt}netrw_starkeep") |let @*        = {a:vt}netrw_starkeep    |unlet {a:vt}netrw_starkeep |endif
  endif
  " Problem: start with liststyle=0; press <i> : result, following line resets l:ts.
"  if exists("{a:vt}netrw_tskeep")   |let &l:ts     = {a:vt}netrw_tskeep      |unlet {a:vt}netrw_tskeep   |endif
  if exists("{a:vt}netrw_twkeep")   |let &l:tw     = {a:vt}netrw_twkeep      |unlet {a:vt}netrw_twkeep   |endif
  if exists("{a:vt}netrw_wigkeep")  |let &l:wig    = {a:vt}netrw_wigkeep     |unlet {a:vt}netrw_wigkeep  |endif
  if exists("{a:vt}netrw_wrapkeep") |let &l:wrap   = {a:vt}netrw_wrapkeep    |unlet {a:vt}netrw_wrapkeep |endif
  if exists("{a:vt}netrw_writekeep")|let &l:write  = {a:vt}netrw_writekeep   |unlet {a:vt}netrw_writekeep|endif
  if exists("s:yykeep")             |let  @@       = s:yykeep                |unlet s:yykeep             |endif
  if exists("{a:vt}netrw_swfkeep")
   if &directory == ""
    " user hasn't specified a swapfile directory;
    " netrw will temporarily set the swapfile directory
    " to the current directory as returned by getcwd().
    let &l:directory= getcwd()
    sil! let &l:swf = {a:vt}netrw_swfkeep
    setl directory=
    unlet {a:vt}netrw_swfkeep
   elseif &l:swf != {a:vt}netrw_swfkeep
    " following line causes a Press ENTER in windows -- can't seem to work around it!!!
    sil! let &l:swf= {a:vt}netrw_swfkeep
    unlet {a:vt}netrw_swfkeep
   endif
  endif
  if exists("{a:vt}netrw_dirkeep") && isdirectory(s:NetrwFile({a:vt}netrw_dirkeep)) && g:netrw_keepdir
   let dirkeep = substitute({a:vt}netrw_dirkeep,'\\','/','g')
   if exists("{a:vt}netrw_dirkeep")
    call s:NetrwLcd(dirkeep)
    unlet {a:vt}netrw_dirkeep
   endif
  endif
  if has("clipboard")
   if exists("{a:vt}netrw_regstar") |sil! let @*= {a:vt}netrw_regstar |unlet {a:vt}netrw_regstar |endif
  endif
  if exists("{a:vt}netrw_regslash")|sil! let @/= {a:vt}netrw_regslash|unlet {a:vt}netrw_regslash|endif
  if exists("s:nbcd_curpos_{bufnr('%')}")
"   call Decho("restoring previous position  (s:nbcd_curpos_".bufnr('%')." exists)",'~'.expand("<slnum>"))
   NetrwKeepj call netrw#RestorePosn(s:nbcd_curpos_{bufnr('%')})
"   call Decho("unlet s:nbcd_curpos_".bufnr('%'),'~'.expand("<slnum>"))
   if exists("s:nbcd_curpos_".bufnr('%'))
    unlet s:nbcd_curpos_{bufnr('%')}
   endif
  else
"   call Decho("no previous position",'~'.expand("<slnum>"))
  endif

"  call Decho("g:netrw_keepdir=".g:netrw_keepdir.": getcwd<".getcwd()."> acd=".&acd,'~'.expand("<slnum>"))
"  call Decho("fo=".&fo.(exists("+acd")? " acd=".&acd : " acd doesn't exist"),'~'.expand("<slnum>"))
"  call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"  call Decho("diff=".&l:diff." win#".winnr()." w:netrw_diffkeep=".(exists("w:netrw_diffkeep")? w:netrw_diffkeep : "doesn't exist"),'~'.expand("<slnum>"))
"  call Decho("ts=".&l:ts,'~'.expand("<slnum>"))
  " Moved the filetype detect here from NetrwGetFile() because remote files
  " were having their filetype detect-generated settings overwritten by
  " NetrwOptionRestore.
  if &ft != "netrw"
"   call Decho("filetype detect  (ft=".&ft.")",'~'.expand("<slnum>"))
   filetype detect
  endif
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo." a:vt=".a:vt,'~'.expand("<slnum>"))
"  call Dret("s:NetrwOptionRestore : tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> modified=".&modified." modifiable=".&modifiable." readonly=".&readonly)
endfun

" ---------------------------------------------------------------------
" s:NetrwOptionSave: save options prior to setting to "netrw-buffer-standard" form {{{2
"             Options get restored by s:NetrwOptionRestore()
"  06/08/07 : removed call to NetrwSafeOptions(), either placed
"             immediately after NetrwOptionSave() calls in NetRead
"             and NetWrite, or after the s:NetrwEnew() call in
"             NetrwBrowse.
"             vt: normally its "w:" or "s:" (a variable type)
fun! s:NetrwOptionSave(vt)
"  call Dfunc("s:NetrwOptionSave(vt<".a:vt.">) win#".winnr()." buf#".bufnr("%")."<".bufname(bufnr("%")).">"." winnr($)=".winnr("$")." mod=".&mod." ma=".&ma)
"  call Decho(a:vt."netrw_optionsave".(exists("{a:vt}netrw_optionsave")? ("=".{a:vt}netrw_optionsave) : " doesn't exist"),'~'.expand("<slnum>"))
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo." a:vt=".a:vt,'~'.expand("<slnum>"))

  if !exists("{a:vt}netrw_optionsave")
   let {a:vt}netrw_optionsave= 1
  else
"   call Dret("s:NetrwOptionSave : options already saved")
   return
  endif
"  call Decho("prior to save: fo=".&fo.(exists("+acd")? " acd=".&acd : " acd doesn't exist")." diff=".&l:diff,'~'.expand("<slnum>"))

  " Save current settings and current directory
"  call Decho("saving current settings and current directory",'~'.expand("<slnum>"))
  let s:yykeep          = @@
  if exists("&l:acd")|let {a:vt}netrw_acdkeep  = &l:acd|endif
  let {a:vt}netrw_aikeep    = &l:ai
  let {a:vt}netrw_awkeep    = &l:aw
  let {a:vt}netrw_bhkeep    = &l:bh
  let {a:vt}netrw_blkeep    = &l:bl
  let {a:vt}netrw_btkeep    = &l:bt
  let {a:vt}netrw_bombkeep  = &l:bomb
  let {a:vt}netrw_cedit     = &cedit
  let {a:vt}netrw_cikeep    = &l:ci
  let {a:vt}netrw_cinkeep   = &l:cin
  let {a:vt}netrw_cinokeep  = &l:cino
  let {a:vt}netrw_comkeep   = &l:com
  let {a:vt}netrw_cpokeep   = &l:cpo
  let {a:vt}netrw_diffkeep  = &l:diff
  let {a:vt}netrw_fenkeep   = &l:fen
  if !exists("g:netrw_ffkeep") || g:netrw_ffkeep
   let {a:vt}netrw_ffkeep    = &l:ff
  endif
  let {a:vt}netrw_fokeep    = &l:fo           " formatoptions
  let {a:vt}netrw_gdkeep    = &l:gd           " gdefault
  let {a:vt}netrw_hidkeep   = &l:hidden
  let {a:vt}netrw_imkeep    = &l:im
  let {a:vt}netrw_iskkeep   = &l:isk
  let {a:vt}netrw_lskeep    = &l:ls
  let {a:vt}netrw_makeep    = &l:ma
  let {a:vt}netrw_magickeep = &l:magic
  let {a:vt}netrw_modkeep   = &l:mod
  let {a:vt}netrw_nukeep    = &l:nu
  let {a:vt}netrw_rnukeep   = &l:rnu
  let {a:vt}netrw_repkeep   = &l:report
  let {a:vt}netrw_rokeep    = &l:ro
  let {a:vt}netrw_selkeep   = &l:sel
  let {a:vt}netrw_spellkeep = &l:spell
  if g:netrw_use_noswf
   let {a:vt}netrw_swfkeep   = &l:swf
  endif
  if has("clipboard")
   let {a:vt}netrw_starkeep  = @*
  endif
  let {a:vt}netrw_tskeep    = &l:ts
  let {a:vt}netrw_twkeep    = &l:tw           " textwidth
  let {a:vt}netrw_wigkeep   = &l:wig          " wildignore
  let {a:vt}netrw_wrapkeep  = &l:wrap
  let {a:vt}netrw_writekeep = &l:write

  " save a few selected netrw-related variables
"  call Decho("saving a few selected netrw-related variables",'~'.expand("<slnum>"))
  if g:netrw_keepdir
   let {a:vt}netrw_dirkeep  = getcwd()
  endif
  if has("clipboard")
   if &go =~# 'a' | sil! let {a:vt}netrw_regstar = @* | endif
  endif
  sil! let {a:vt}netrw_regslash= @/

"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo." a:vt=".a:vt,'~'.expand("<slnum>"))
"  call Dret("s:NetrwOptionSave : tab#".tabpagenr()." win#".winnr())
endfun

" ------------------------------------------------------------------------
" s:NetrwSafeOptions: sets options to help netrw do its job {{{2
"                     Use  s:NetrwSaveOptions() to save user settings
"                     Use  s:NetrwOptionRestore() to restore user settings
fun! s:NetrwSafeOptions()
"  call Dfunc("s:NetrwSafeOptions() win#".winnr()." buf#".bufnr("%")."<".bufname(bufnr("%"))."> winnr($)=".winnr("$"))
"  call Decho("win#".winnr()."'s ft=".&ft,'~'.expand("<slnum>"))
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
  if exists("+acd") | setl noacd | endif
  setl noai
  setl noaw
  setl nobl
  setl nobomb
  setl bt=nofile
  setl noci
  setl nocin
  setl bh=hide
  setl cino=
  setl com=
  setl cpo-=a
  setl cpo-=A
  setl fo=nroql2
  setl nohid
  setl noim
  setl isk+=@ isk+=* isk+=/
  setl magic
  if g:netrw_use_noswf
   setl noswf
  endif
  setl report=10000
  setl sel=inclusive
  setl nospell
  setl tw=0
  setl wig=
  setl cedit&
  call s:NetrwCursor()

  " allow the user to override safe options
"  call Decho("ft<".&ft."> ei=".&ei,'~'.expand("<slnum>"))
  if &ft == "netrw"
"   call Decho("do any netrw FileType autocmds (doau FileType netrw)",'~'.expand("<slnum>"))
   sil! keepalt NetrwKeepj doau FileType netrw
  endif

"  call Decho("fo=".&fo.(exists("+acd")? " acd=".&acd : " acd doesn't exist")." bh=".&l:bh." bt<".&bt.">",'~'.expand("<slnum>"))
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"  call Dret("s:NetrwSafeOptions")
endfun

" ---------------------------------------------------------------------
" NetrwStatusLine: {{{2
fun! NetrwStatusLine()

" vvv NetrwStatusLine() debugging vvv
"  let g:stlmsg=""
"  if !exists("w:netrw_explore_bufnr")
"   let g:stlmsg="!X<explore_bufnr>"
"  elseif w:netrw_explore_bufnr != bufnr("%")
"   let g:stlmsg="explore_bufnr!=".bufnr("%")
"  endif
"  if !exists("w:netrw_explore_line")
"   let g:stlmsg=" !X<explore_line>"
"  elseif w:netrw_explore_line != line(".")
"   let g:stlmsg=" explore_line!={line(.)<".line(".").">"
"  endif
"  if !exists("w:netrw_explore_list")
"   let g:stlmsg=" !X<explore_list>"
"  endif
" ^^^ NetrwStatusLine() debugging ^^^

  if !exists("w:netrw_explore_bufnr") || w:netrw_explore_bufnr != bufnr("%") || !exists("w:netrw_explore_line") || w:netrw_explore_line != line(".") || !exists("w:netrw_explore_list")
   " restore user's status line
   let &stl        = s:netrw_users_stl
   let &laststatus = s:netrw_users_ls
   if exists("w:netrw_explore_bufnr")|unlet w:netrw_explore_bufnr|endif
   if exists("w:netrw_explore_line") |unlet w:netrw_explore_line |endif
   return ""
  else
   return "Match ".w:netrw_explore_mtchcnt." of ".w:netrw_explore_listlen
  endif
endfun

" ---------------------------------------------------------------------
"  Netrw Transfer Functions: {{{1
" ===============================

" ------------------------------------------------------------------------
" netrw#NetRead: responsible for reading a file over the net {{{2
"   mode: =0 read remote file and insert before current line
"         =1 read remote file and insert after current line
"         =2 replace with remote file
"         =3 obtain file, but leave in temporary format
fun! netrw#NetRead(mode,...)
"  call Dfunc("netrw#NetRead(mode=".a:mode.",...) a:0=".a:0." ".g:loaded_netrw.((a:0 > 0)? " a:1<".a:1.">" : ""))

  " NetRead: save options {{{3
  call s:NetrwOptionSave("w:")
  call s:NetrwSafeOptions()
  call s:RestoreCursorline()
  " NetrwSafeOptions sets a buffer up for a netrw listing, which includes buflisting off.
  " However, this setting is not wanted for a remote editing session.  The buffer should be "nofile", still.
  setl bl
"  call Decho("(netrw#NetRead) buf#".bufnr("%")."<".bufname("%")."> bl=".&bl." bt=".&bt." bh=".&bh,'~'.expand("<slnum>"))

  " NetRead: interpret mode into a readcmd {{{3
  if     a:mode == 0 " read remote file before current line
   let readcmd = "0r"
  elseif a:mode == 1 " read file after current line
   let readcmd = "r"
  elseif a:mode == 2 " replace with remote file
   let readcmd = "%r"
  elseif a:mode == 3 " skip read of file (leave as temporary)
   let readcmd = "t"
  else
   exe a:mode
   let readcmd = "r"
  endif
  let ichoice = (a:0 == 0)? 0 : 1
"  call Decho("readcmd<".readcmd."> ichoice=".ichoice,'~'.expand("<slnum>"))

  " NetRead: get temporary filename {{{3
  let tmpfile= s:GetTempfile("")
  if tmpfile == ""
"   call Dret("netrw#NetRead : unable to get a tempfile!")
   return
  endif

  while ichoice <= a:0

   " attempt to repeat with previous host-file-etc
   if exists("b:netrw_lastfile") && a:0 == 0
"    call Decho("using b:netrw_lastfile<" . b:netrw_lastfile . ">",'~'.expand("<slnum>"))
    let choice = b:netrw_lastfile
    let ichoice= ichoice + 1

   else
    exe "let choice= a:" . ichoice
"    call Decho("no lastfile: choice<" . choice . ">",'~'.expand("<slnum>"))

    if match(choice,"?") == 0
     " give help
     echomsg 'NetRead Usage:'
     echomsg ':Nread machine:path                         uses rcp'
     echomsg ':Nread "machine path"                       uses ftp   with <.netrc>'
     echomsg ':Nread "machine id password path"           uses ftp'
     echomsg ':Nread dav://machine[:port]/path            uses cadaver'
     echomsg ':Nread fetch://machine/path                 uses fetch'
     echomsg ':Nread ftp://[user@]machine[:port]/path     uses ftp   autodetects <.netrc>'
     echomsg ':Nread http://[user@]machine/path           uses http  wget'
     echomsg ':Nread file:///path           		  uses elinks'
     echomsg ':Nread https://[user@]machine/path          uses http  wget'
     echomsg ':Nread rcp://[user@]machine/path            uses rcp'
     echomsg ':Nread rsync://machine[:port]/path          uses rsync'
     echomsg ':Nread scp://[user@]machine[[:#]port]/path  uses scp'
     echomsg ':Nread sftp://[user@]machine[[:#]port]/path uses sftp'
     sleep 4
     break

    elseif match(choice,'^"') != -1
     " Reconstruct Choice if choice starts with '"'
"     call Decho("reconstructing choice",'~'.expand("<slnum>"))
     if match(choice,'"$') != -1
      " case "..."
      let choice= strpart(choice,1,strlen(choice)-2)
     else
       "  case "... ... ..."
      let choice      = strpart(choice,1,strlen(choice)-1)
      let wholechoice = ""

      while match(choice,'"$') == -1
       let wholechoice = wholechoice . " " . choice
       let ichoice     = ichoice + 1
       if ichoice > a:0
       	if !exists("g:netrw_quiet")
	 call netrw#ErrorMsg(s:ERROR,"Unbalanced string in filename '". wholechoice ."'",3)
	endif
"        call Dret("netrw#NetRead :2 getcwd<".getcwd().">")
        return
       endif
       let choice= a:{ichoice}
      endwhile
      let choice= strpart(wholechoice,1,strlen(wholechoice)-1) . " " . strpart(choice,0,strlen(choice)-1)
     endif
    endif
   endif

"   call Decho("choice<" . choice . ">",'~'.expand("<slnum>"))
   let ichoice= ichoice + 1

   " NetRead: Determine method of read (ftp, rcp, etc) {{{3
   call s:NetrwMethod(choice)
   if !exists("b:netrw_method") || b:netrw_method < 0
"    call Dfunc("netrw#NetRead : unsupported method")
    return
   endif
   let tmpfile= s:GetTempfile(b:netrw_fname) " apply correct suffix

   " Check whether or not NetrwBrowse() should be handling this request
"   call Decho("checking if NetrwBrowse() should handle choice<".choice."> with netrw_list_cmd<".g:netrw_list_cmd.">",'~'.expand("<slnum>"))
   if choice =~ "^.*[\/]$" && b:netrw_method != 5 && choice !~ '^https\=://'
"    call Decho("yes, choice matches '^.*[\/]$'",'~'.expand("<slnum>"))
    NetrwKeepj call s:NetrwBrowse(0,choice)
"    call Dret("netrw#NetRead :3 getcwd<".getcwd().">")
    return
   endif

   " ============
   " NetRead: Perform Protocol-Based Read {{{3
   " ===========================
   if exists("g:netrw_silent") && g:netrw_silent == 0 && &ch >= 1
    echo "(netrw) Processing your read request..."
   endif

   ".........................................
   " NetRead: (rcp)  NetRead Method #1 {{{3
   if  b:netrw_method == 1 " read with rcp
"    call Decho("read via rcp (method #1)",'~'.expand("<slnum>"))
   " ER: nothing done with g:netrw_uid yet?
   " ER: on Win2K" rcp machine[.user]:file tmpfile
   " ER: when machine contains '.' adding .user is required (use $USERNAME)
   " ER: the tmpfile is full path: rcp sees C:\... as host C
   if s:netrw_has_nt_rcp == 1
    if exists("g:netrw_uid") &&	( g:netrw_uid != "" )
     let uid_machine = g:netrw_machine .'.'. g:netrw_uid
    else
     " Any way needed it machine contains a '.'
     let uid_machine = g:netrw_machine .'.'. $USERNAME
    endif
   else
    if exists("g:netrw_uid") &&	( g:netrw_uid != "" )
     let uid_machine = g:netrw_uid .'@'. g:netrw_machine
    else
     let uid_machine = g:netrw_machine
    endif
   endif
   call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_rcp_cmd." ".s:netrw_rcpmode." ".shellescape(uid_machine.":".b:netrw_fname,1)." ".shellescape(tmpfile,1))
   let result           = s:NetrwGetFile(readcmd, tmpfile, b:netrw_method)
   let b:netrw_lastfile = choice

   ".........................................
   " NetRead: (ftp + <.netrc>)  NetRead Method #2 {{{3
   elseif b:netrw_method  == 2		" read with ftp + <.netrc>
"     call Decho("read via ftp+.netrc (method #2)",'~'.expand("<slnum>"))
     let netrw_fname= b:netrw_fname
     NetrwKeepj call s:SaveBufVars()|new|NetrwKeepj call s:RestoreBufVars()
     let filtbuf= bufnr("%")
     setl ff=unix
     NetrwKeepj put =g:netrw_ftpmode
"     call Decho("filter input: ".getline(line("$")),'~'.expand("<slnum>"))
     if exists("g:netrw_ftpextracmd")
      NetrwKeepj put =g:netrw_ftpextracmd
"      call Decho("filter input: ".getline(line("$")),'~'.expand("<slnum>"))
     endif
     call setline(line("$")+1,'get "'.netrw_fname.'" '.tmpfile)
"     call Decho("filter input: ".getline(line("$")),'~'.expand("<slnum>"))
     if exists("g:netrw_port") && g:netrw_port != ""
      call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1)." ".shellescape(g:netrw_port,1))
     else
      call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1))
     endif
     " If the result of the ftp operation isn't blank, show an error message (tnx to Doug Claar)
     if getline(1) !~ "^$" && !exists("g:netrw_quiet") && getline(1) !~ '^Trying '
      let debugkeep = &debug
      setl debug=msg
      NetrwKeepj call netrw#ErrorMsg(s:ERROR,getline(1),4)
      let &debug    = debugkeep
     endif
     call s:SaveBufVars()
     keepj bd!
     if bufname("%") == "" && getline("$") == "" && line('$') == 1
      " needed when one sources a file in a nolbl setting window via ftp
      q!
     endif
     call s:RestoreBufVars()
     let result           = s:NetrwGetFile(readcmd, tmpfile, b:netrw_method)
     let b:netrw_lastfile = choice

   ".........................................
   " NetRead: (ftp + machine,id,passwd,filename)  NetRead Method #3 {{{3
   elseif b:netrw_method == 3		" read with ftp + machine, id, passwd, and fname
    " Construct execution string (four lines) which will be passed through filter
"    call Decho("read via ftp+mipf (method #3)",'~'.expand("<slnum>"))
    let netrw_fname= escape(b:netrw_fname,g:netrw_fname_escape)
    NetrwKeepj call s:SaveBufVars()|new|NetrwKeepj call s:RestoreBufVars()
    let filtbuf= bufnr("%")
    setl ff=unix
    if exists("g:netrw_port") && g:netrw_port != ""
     NetrwKeepj put ='open '.g:netrw_machine.' '.g:netrw_port
"     call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
    else
     NetrwKeepj put ='open '.g:netrw_machine
"     call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
    endif

    if exists("g:netrw_uid") && g:netrw_uid != ""
     if exists("g:netrw_ftp") && g:netrw_ftp == 1
      NetrwKeepj put =g:netrw_uid
"       call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
      if exists("s:netrw_passwd")
       NetrwKeepj put ='\"'.s:netrw_passwd.'\"'
      endif
"      call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
     elseif exists("s:netrw_passwd")
      NetrwKeepj put ='user \"'.g:netrw_uid.'\" \"'.s:netrw_passwd.'\"'
"      call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
     endif
    endif

    if exists("g:netrw_ftpmode") && g:netrw_ftpmode != ""
     NetrwKeepj put =g:netrw_ftpmode
"     call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
    endif
    if exists("g:netrw_ftpextracmd")
     NetrwKeepj put =g:netrw_ftpextracmd
"     call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
    endif
    NetrwKeepj put ='get \"'.netrw_fname.'\" '.tmpfile
"    call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))

    " perform ftp:
    " -i       : turns off interactive prompting from ftp
    " -n  unix : DON'T use <.netrc>, even though it exists
    " -n  win32: quit being obnoxious about password
    NetrwKeepj norm! 1Gdd
    call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." ".g:netrw_ftp_options)
    " If the result of the ftp operation isn't blank, show an error message (tnx to Doug Claar)
    if getline(1) !~ "^$"
"     call Decho("error<".getline(1).">",'~'.expand("<slnum>"))
     if !exists("g:netrw_quiet")
      call netrw#ErrorMsg(s:ERROR,getline(1),5)
     endif
    endif
    call s:SaveBufVars()|keepj bd!|call s:RestoreBufVars()
    let result           = s:NetrwGetFile(readcmd, tmpfile, b:netrw_method)
    let b:netrw_lastfile = choice

   ".........................................
   " NetRead: (scp) NetRead Method #4 {{{3
   elseif     b:netrw_method  == 4	" read with scp
"    call Decho("read via scp (method #4)",'~'.expand("<slnum>"))
    if exists("g:netrw_port") && g:netrw_port != ""
     let useport= " ".g:netrw_scpport." ".g:netrw_port
    else
     let useport= ""
    endif
    " 'C' in 'C:\path\to\file' is handled as hostname on windows.
    " This is workaround to avoid mis-handle windows local-path:
    if g:netrw_scp_cmd =~ '^scp' && (has("win32") || has("win95") || has("win64") || has("win16"))
      let tmpfile_get = substitute(tr(tmpfile, '\', '/'), '^\(\a\):[/\\]\(.*\)$', '/\1/\2', '')
    else
      let tmpfile_get = tmpfile
    endif
    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_scp_cmd.useport." ".shellescape(g:netrw_machine.":".b:netrw_fname,1)." ".shellescape(tmpfile_get,1))
    let result           = s:NetrwGetFile(readcmd, tmpfile, b:netrw_method)
    let b:netrw_lastfile = choice

   ".........................................
   " NetRead: (http) NetRead Method #5 (wget) {{{3
   elseif     b:netrw_method  == 5
"    call Decho("read via http (method #5)",'~'.expand("<slnum>"))
    if g:netrw_http_cmd == ""
     if !exists("g:netrw_quiet")
      call netrw#ErrorMsg(s:ERROR,"neither the wget nor the fetch command is available",6)
     endif
"     call Dret("netrw#NetRead :4 getcwd<".getcwd().">")
     return
    endif

    if match(b:netrw_fname,"#") == -1 || exists("g:netrw_http_xcmd")
     " using g:netrw_http_cmd (usually elinks, links, curl, wget, or fetch)
"     call Decho('using '.g:netrw_http_cmd.' (# not in b:netrw_fname<'.b:netrw_fname.">)",'~'.expand("<slnum>"))
     if exists("g:netrw_http_xcmd")
      call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_http_cmd." ".shellescape(b:netrw_http."://".g:netrw_machine.b:netrw_fname,1)." ".g:netrw_http_xcmd." ".shellescape(tmpfile,1))
     else
      call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_http_cmd." ".shellescape(tmpfile,1)." ".shellescape(b:netrw_http."://".g:netrw_machine.b:netrw_fname,1))
     endif
     let result = s:NetrwGetFile(readcmd, tmpfile, b:netrw_method)

    else
     " wget/curl/fetch plus a jump to an in-page marker (ie. http://abc/def.html#aMarker)
"     call Decho("wget/curl plus jump (# in b:netrw_fname<".b:netrw_fname.">)",'~'.expand("<slnum>"))
     let netrw_html= substitute(b:netrw_fname,"#.*$","","")
     let netrw_tag = substitute(b:netrw_fname,"^.*#","","")
"     call Decho("netrw_html<".netrw_html.">",'~'.expand("<slnum>"))
"     call Decho("netrw_tag <".netrw_tag.">",'~'.expand("<slnum>"))
     call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_http_cmd." ".shellescape(tmpfile,1)." ".shellescape(b:netrw_http."://".g:netrw_machine.netrw_html,1))
     let result = s:NetrwGetFile(readcmd, tmpfile, b:netrw_method)
"     call Decho('<\s*a\s*name=\s*"'.netrw_tag.'"/','~'.expand("<slnum>"))
     exe 'NetrwKeepj norm! 1G/<\s*a\s*name=\s*"'.netrw_tag.'"/'."\<CR>"
    endif
    let b:netrw_lastfile = choice
"    call Decho("setl ro",'~'.expand("<slnum>"))
    setl ro nomod

   ".........................................
   " NetRead: (dav) NetRead Method #6 {{{3
   elseif     b:netrw_method  == 6
"    call Decho("read via cadaver (method #6)",'~'.expand("<slnum>"))

    if !executable(g:netrw_dav_cmd)
     call netrw#ErrorMsg(s:ERROR,g:netrw_dav_cmd." is not executable",73)
"     call Dret("netrw#NetRead : ".g:netrw_dav_cmd." not executable")
     return
    endif
    if g:netrw_dav_cmd =~ "curl"
     call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_dav_cmd." ".shellescape("dav://".g:netrw_machine.b:netrw_fname,1)." ".shellescape(tmpfile,1))
    else
     " Construct execution string (four lines) which will be passed through filter
     let netrw_fname= escape(b:netrw_fname,g:netrw_fname_escape)
     new
     setl ff=unix
     if exists("g:netrw_port") && g:netrw_port != ""
      NetrwKeepj put ='open '.g:netrw_machine.' '.g:netrw_port
     else
      NetrwKeepj put ='open '.g:netrw_machine
     endif
     if exists("g:netrw_uid") && exists("s:netrw_passwd") && g:netrw_uid != ""
      NetrwKeepj put ='user '.g:netrw_uid.' '.s:netrw_passwd
     endif
     NetrwKeepj put ='get '.netrw_fname.' '.tmpfile
     NetrwKeepj put ='quit'

     " perform cadaver operation:
     NetrwKeepj norm! 1Gdd
     call s:NetrwExe(s:netrw_silentxfer."%!".g:netrw_dav_cmd)
     keepj bd!
    endif
    let result           = s:NetrwGetFile(readcmd, tmpfile, b:netrw_method)
    let b:netrw_lastfile = choice

   ".........................................
   " NetRead: (rsync) NetRead Method #7 {{{3
   elseif     b:netrw_method  == 7
"    call Decho("read via rsync (method #7)",'~'.expand("<slnum>"))
    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_rsync_cmd." ".shellescape(g:netrw_machine.":".b:netrw_fname,1)." ".shellescape(tmpfile,1))
    let result		 = s:NetrwGetFile(readcmd,tmpfile, b:netrw_method)
    let b:netrw_lastfile = choice

   ".........................................
   " NetRead: (fetch) NetRead Method #8 {{{3
   "    fetch://[user@]host[:http]/path
   elseif     b:netrw_method  == 8
"    call Decho("read via fetch (method #8)",'~'.expand("<slnum>"))
    if g:netrw_fetch_cmd == ""
     if !exists("g:netrw_quiet")
      NetrwKeepj call netrw#ErrorMsg(s:ERROR,"fetch command not available",7)
     endif
"     call Dret("NetRead")
     return
    endif
    if exists("g:netrw_option") && g:netrw_option =~ ":https\="
     let netrw_option= "http"
    else
     let netrw_option= "ftp"
    endif
"    call Decho("read via fetch for ".netrw_option,'~'.expand("<slnum>"))

    if exists("g:netrw_uid") && g:netrw_uid != "" && exists("s:netrw_passwd") && s:netrw_passwd != ""
     call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_fetch_cmd." ".shellescape(tmpfile,1)." ".shellescape(netrw_option."://".g:netrw_uid.':'.s:netrw_passwd.'@'.g:netrw_machine."/".b:netrw_fname,1))
    else
     call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_fetch_cmd." ".shellescape(tmpfile,1)." ".shellescape(netrw_option."://".g:netrw_machine."/".b:netrw_fname,1))
    endif

    let result		= s:NetrwGetFile(readcmd,tmpfile, b:netrw_method)
    let b:netrw_lastfile = choice
"    call Decho("setl ro",'~'.expand("<slnum>"))
    setl ro nomod

   ".........................................
   " NetRead: (sftp) NetRead Method #9 {{{3
   elseif     b:netrw_method  == 9
"    call Decho("read via sftp (method #9)",'~'.expand("<slnum>"))
    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_sftp_cmd." ".shellescape(g:netrw_machine.":".b:netrw_fname,1)." ".tmpfile)
    let result		= s:NetrwGetFile(readcmd, tmpfile, b:netrw_method)
    let b:netrw_lastfile = choice

   ".........................................
   " NetRead: (file) NetRead Method #10 {{{3
  elseif      b:netrw_method == 10 && exists("g:netrw_file_cmd")
"   "    call Decho("read via ".b:netrw_file_cmd." (method #10)",'~'.expand("<slnum>"))
   call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_file_cmd." ".shellescape(b:netrw_fname,1)." ".tmpfile)
   let result		= s:NetrwGetFile(readcmd, tmpfile, b:netrw_method)
   let b:netrw_lastfile = choice

   ".........................................
   " NetRead: Complain {{{3
   else
    call netrw#ErrorMsg(s:WARNING,"unable to comply with your request<" . choice . ">",8)
   endif
  endwhile

  " NetRead: cleanup {{{3
  if exists("b:netrw_method")
"   call Decho("cleanup b:netrw_method and b:netrw_fname",'~'.expand("<slnum>"))
   unlet b:netrw_method
   unlet b:netrw_fname
  endif
  if s:FileReadable(tmpfile) && tmpfile !~ '.tar.bz2$' && tmpfile !~ '.tar.gz$' && tmpfile !~ '.zip' && tmpfile !~ '.tar' && readcmd != 't' && tmpfile !~ '.tar.xz$' && tmpfile !~ '.txz'
"   call Decho("cleanup by deleting tmpfile<".tmpfile.">",'~'.expand("<slnum>"))
   NetrwKeepj call s:NetrwDelete(tmpfile)
  endif
  NetrwKeepj call s:NetrwOptionRestore("w:")

"  call Dret("netrw#NetRead :5 getcwd<".getcwd().">")
endfun

" ------------------------------------------------------------------------
" netrw#NetWrite: responsible for writing a file over the net {{{2
fun! netrw#NetWrite(...) range
"  call Dfunc("netrw#NetWrite(a:0=".a:0.") ".g:loaded_netrw)

  " NetWrite: option handling {{{3
  let mod= 0
  call s:NetrwOptionSave("w:")
  call s:NetrwSafeOptions()

  " NetWrite: Get Temporary Filename {{{3
  let tmpfile= s:GetTempfile("")
  if tmpfile == ""
"   call Dret("netrw#NetWrite : unable to get a tempfile!")
   return
  endif

  if a:0 == 0
   let ichoice = 0
  else
   let ichoice = 1
  endif

  let curbufname= expand("%")
"  call Decho("curbufname<".curbufname.">",'~'.expand("<slnum>"))
  if &binary
   " For binary writes, always write entire file.
   " (line numbers don't really make sense for that).
   " Also supports the writing of tar and zip files.
"   call Decho("(write entire file) sil exe w! ".fnameescape(v:cmdarg)." ".fnameescape(tmpfile),'~'.expand("<slnum>"))
   exe "sil NetrwKeepj w! ".fnameescape(v:cmdarg)." ".fnameescape(tmpfile)
  elseif g:netrw_cygwin
   " write (selected portion of) file to temporary
   let cygtmpfile= substitute(tmpfile,g:netrw_cygdrive.'/\(.\)','\1:','')
"   call Decho("(write selected portion) sil exe ".a:firstline."," . a:lastline . "w! ".fnameescape(v:cmdarg)." ".fnameescape(cygtmpfile),'~'.expand("<slnum>"))
   exe "sil NetrwKeepj ".a:firstline."," . a:lastline . "w! ".fnameescape(v:cmdarg)." ".fnameescape(cygtmpfile)
  else
   " write (selected portion of) file to temporary
"   call Decho("(write selected portion) sil exe ".a:firstline."," . a:lastline . "w! ".fnameescape(v:cmdarg)." ".fnameescape(tmpfile),'~'.expand("<slnum>"))
   exe "sil NetrwKeepj ".a:firstline."," . a:lastline . "w! ".fnameescape(v:cmdarg)." ".fnameescape(tmpfile)
  endif

  if curbufname == ""
   " when the file is [No Name], and one attempts to Nwrite it, the buffer takes
   " on the temporary file's name.  Deletion of the temporary file during
   " cleanup then causes an error message.
   0file!
  endif

  " NetWrite: while choice loop: {{{3
  while ichoice <= a:0

   " Process arguments: {{{4
   " attempt to repeat with previous host-file-etc
   if exists("b:netrw_lastfile") && a:0 == 0
"    call Decho("using b:netrw_lastfile<" . b:netrw_lastfile . ">",'~'.expand("<slnum>"))
    let choice = b:netrw_lastfile
    let ichoice= ichoice + 1
   else
    exe "let choice= a:" . ichoice

    " Reconstruct Choice when choice starts with '"'
    if match(choice,"?") == 0
     echomsg 'NetWrite Usage:"'
     echomsg ':Nwrite machine:path                        uses rcp'
     echomsg ':Nwrite "machine path"                      uses ftp with <.netrc>'
     echomsg ':Nwrite "machine id password path"          uses ftp'
     echomsg ':Nwrite dav://[user@]machine/path           uses cadaver'
     echomsg ':Nwrite fetch://[user@]machine/path         uses fetch'
     echomsg ':Nwrite ftp://machine[#port]/path           uses ftp  (autodetects <.netrc>)'
     echomsg ':Nwrite rcp://machine/path                  uses rcp'
     echomsg ':Nwrite rsync://[user@]machine/path         uses rsync'
     echomsg ':Nwrite scp://[user@]machine[[:#]port]/path uses scp'
     echomsg ':Nwrite sftp://[user@]machine/path          uses sftp'
     sleep 4
     break

    elseif match(choice,"^\"") != -1
     if match(choice,"\"$") != -1
       " case "..."
      let choice=strpart(choice,1,strlen(choice)-2)
     else
      "  case "... ... ..."
      let choice      = strpart(choice,1,strlen(choice)-1)
      let wholechoice = ""

      while match(choice,"\"$") == -1
       let wholechoice= wholechoice . " " . choice
       let ichoice    = ichoice + 1
       if choice > a:0
       	if !exists("g:netrw_quiet")
	 call netrw#ErrorMsg(s:ERROR,"Unbalanced string in filename '". wholechoice ."'",13)
	endif
"        call Dret("netrw#NetWrite")
        return
       endif
       let choice= a:{ichoice}
      endwhile
      let choice= strpart(wholechoice,1,strlen(wholechoice)-1) . " " . strpart(choice,0,strlen(choice)-1)
     endif
    endif
   endif
   let ichoice= ichoice + 1
"   call Decho("choice<" . choice . "> ichoice=".ichoice,'~'.expand("<slnum>"))

   " Determine method of write (ftp, rcp, etc) {{{4
   NetrwKeepj call s:NetrwMethod(choice)
   if !exists("b:netrw_method") || b:netrw_method < 0
"    call Dfunc("netrw#NetWrite : unsupported method")
    return
   endif

   " =============
   " NetWrite: Perform Protocol-Based Write {{{3
   " ============================
   if exists("g:netrw_silent") && g:netrw_silent == 0 && &ch >= 1
    echo "(netrw) Processing your write request..."
"    call Decho("(netrw) Processing your write request...",'~'.expand("<slnum>"))
   endif

   ".........................................
   " NetWrite: (rcp) NetWrite Method #1 {{{3
   if  b:netrw_method == 1
"    call Decho("write via rcp (method #1)",'~'.expand("<slnum>"))
    if s:netrw_has_nt_rcp == 1
     if exists("g:netrw_uid") &&  ( g:netrw_uid != "" )
      let uid_machine = g:netrw_machine .'.'. g:netrw_uid
     else
      let uid_machine = g:netrw_machine .'.'. $USERNAME
     endif
    else
     if exists("g:netrw_uid") &&  ( g:netrw_uid != "" )
      let uid_machine = g:netrw_uid .'@'. g:netrw_machine
     else
      let uid_machine = g:netrw_machine
     endif
    endif
    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_rcp_cmd." ".s:netrw_rcpmode." ".shellescape(tmpfile,1)." ".shellescape(uid_machine.":".b:netrw_fname,1))
    let b:netrw_lastfile = choice

   ".........................................
   " NetWrite: (ftp + <.netrc>) NetWrite Method #2 {{{3
   elseif b:netrw_method == 2
"    call Decho("write via ftp+.netrc (method #2)",'~'.expand("<slnum>"))
    let netrw_fname = b:netrw_fname

    " formerly just a "new...bd!", that changed the window sizes when equalalways.  Using enew workaround instead
    let bhkeep      = &l:bh
    let curbuf      = bufnr("%")
    setl bh=hide
    keepj keepalt enew

"    call Decho("filter input window#".winnr(),'~'.expand("<slnum>"))
    setl ff=unix
    NetrwKeepj put =g:netrw_ftpmode
"    call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
    if exists("g:netrw_ftpextracmd")
     NetrwKeepj put =g:netrw_ftpextracmd
"     call Decho("filter input: ".getline("$"),'~'.expand("<slnum>"))
    endif
    NetrwKeepj call setline(line("$")+1,'put "'.tmpfile.'" "'.netrw_fname.'"')
"    call Decho("filter input: ".getline("$"),'~'.expand("<slnum>"))
    if exists("g:netrw_port") && g:netrw_port != ""
     call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1)." ".shellescape(g:netrw_port,1))
    else
"     call Decho("filter input window#".winnr(),'~'.expand("<slnum>"))
     call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1))
    endif
    " If the result of the ftp operation isn't blank, show an error message (tnx to Doug Claar)
    if getline(1) !~ "^$"
     if !exists("g:netrw_quiet")
      NetrwKeepj call netrw#ErrorMsg(s:ERROR,getline(1),14)
     endif
     let mod=1
    endif

    " remove enew buffer (quietly)
    let filtbuf= bufnr("%")
    exe curbuf."b!"
    let &l:bh            = bhkeep
    exe filtbuf."bw!"

    let b:netrw_lastfile = choice

   ".........................................
   " NetWrite: (ftp + machine, id, passwd, filename) NetWrite Method #3 {{{3
   elseif b:netrw_method == 3
    " Construct execution string (three or more lines) which will be passed through filter
"    call Decho("read via ftp+mipf (method #3)",'~'.expand("<slnum>"))
    let netrw_fname = b:netrw_fname
    let bhkeep      = &l:bh

    " formerly just a "new...bd!", that changed the window sizes when equalalways.  Using enew workaround instead
    let curbuf      = bufnr("%")
    setl bh=hide
    keepj keepalt enew
    setl ff=unix

    if exists("g:netrw_port") && g:netrw_port != ""
     NetrwKeepj put ='open '.g:netrw_machine.' '.g:netrw_port
"     call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
    else
     NetrwKeepj put ='open '.g:netrw_machine
"     call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
    endif
    if exists("g:netrw_uid") && g:netrw_uid != ""
     if exists("g:netrw_ftp") && g:netrw_ftp == 1
      NetrwKeepj put =g:netrw_uid
"      call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
      if exists("s:netrw_passwd") && s:netrw_passwd != ""
       NetrwKeepj put ='\"'.s:netrw_passwd.'\"'
      endif
"      call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
     elseif exists("s:netrw_passwd") && s:netrw_passwd != ""
      NetrwKeepj put ='user \"'.g:netrw_uid.'\" \"'.s:netrw_passwd.'\"'
"      call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
     endif
    endif
    NetrwKeepj put =g:netrw_ftpmode
"    call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
    if exists("g:netrw_ftpextracmd")
     NetrwKeepj put =g:netrw_ftpextracmd
"     call Decho("filter input: ".getline("$"),'~'.expand("<slnum>"))
    endif
    NetrwKeepj put ='put \"'.tmpfile.'\" \"'.netrw_fname.'\"'
"    call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
    " save choice/id/password for future use
    let b:netrw_lastfile = choice

    " perform ftp:
    " -i       : turns off interactive prompting from ftp
    " -n  unix : DON'T use <.netrc>, even though it exists
    " -n  win32: quit being obnoxious about password
    NetrwKeepj norm! 1Gdd
    call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." ".g:netrw_ftp_options)
    " If the result of the ftp operation isn't blank, show an error message (tnx to Doug Claar)
    if getline(1) !~ "^$"
     if  !exists("g:netrw_quiet")
      call netrw#ErrorMsg(s:ERROR,getline(1),15)
     endif
     let mod=1
    endif

    " remove enew buffer (quietly)
    let filtbuf= bufnr("%")
    exe curbuf."b!"
    let &l:bh= bhkeep
    exe filtbuf."bw!"

   ".........................................
   " NetWrite: (scp) NetWrite Method #4 {{{3
   elseif     b:netrw_method == 4
"    call Decho("write via scp (method #4)",'~'.expand("<slnum>"))
    if exists("g:netrw_port") && g:netrw_port != ""
     let useport= " ".g:netrw_scpport." ".fnameescape(g:netrw_port)
    else
     let useport= ""
    endif
    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_scp_cmd.useport." ".shellescape(tmpfile,1)." ".shellescape(g:netrw_machine.":".b:netrw_fname,1))
    let b:netrw_lastfile = choice

   ".........................................
   " NetWrite: (http) NetWrite Method #5 {{{3
   elseif     b:netrw_method == 5
"    call Decho("write via http (method #5)",'~'.expand("<slnum>"))
    let curl= substitute(g:netrw_http_put_cmd,'\s\+.*$',"","")
    if executable(curl)
     let url= g:netrw_choice
     call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_http_put_cmd." ".shellescape(tmpfile,1)." ".shellescape(url,1) )
    elseif !exists("g:netrw_quiet")
     call netrw#ErrorMsg(s:ERROR,"can't write to http using <".g:netrw_http_put_cmd".">".",16)
    endif

   ".........................................
   " NetWrite: (dav) NetWrite Method #6 (cadaver) {{{3
   elseif     b:netrw_method == 6
"    call Decho("write via cadaver (method #6)",'~'.expand("<slnum>"))

    " Construct execution string (four lines) which will be passed through filter
    let netrw_fname = escape(b:netrw_fname,g:netrw_fname_escape)
    let bhkeep      = &l:bh

    " formerly just a "new...bd!", that changed the window sizes when equalalways.  Using enew workaround instead
    let curbuf      = bufnr("%")
    setl bh=hide
    keepj keepalt enew

    setl ff=unix
    if exists("g:netrw_port") && g:netrw_port != ""
     NetrwKeepj put ='open '.g:netrw_machine.' '.g:netrw_port
    else
     NetrwKeepj put ='open '.g:netrw_machine
    endif
    if exists("g:netrw_uid") && exists("s:netrw_passwd") && g:netrw_uid != ""
     NetrwKeepj put ='user '.g:netrw_uid.' '.s:netrw_passwd
    endif
    NetrwKeepj put ='put '.tmpfile.' '.netrw_fname

    " perform cadaver operation:
    NetrwKeepj norm! 1Gdd
    call s:NetrwExe(s:netrw_silentxfer."%!".g:netrw_dav_cmd)

    " remove enew buffer (quietly)
    let filtbuf= bufnr("%")
    exe curbuf."b!"
    let &l:bh            = bhkeep
    exe filtbuf."bw!"

    let b:netrw_lastfile = choice

   ".........................................
   " NetWrite: (rsync) NetWrite Method #7 {{{3
   elseif     b:netrw_method == 7
"    call Decho("write via rsync (method #7)",'~'.expand("<slnum>"))
    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_rsync_cmd." ".shellescape(tmpfile,1)." ".shellescape(g:netrw_machine.":".b:netrw_fname,1))
    let b:netrw_lastfile = choice

   ".........................................
   " NetWrite: (sftp) NetWrite Method #9 {{{3
   elseif     b:netrw_method == 9
"    call Decho("write via sftp (method #9)",'~'.expand("<slnum>"))
    let netrw_fname= escape(b:netrw_fname,g:netrw_fname_escape)
    if exists("g:netrw_uid") &&  ( g:netrw_uid != "" )
     let uid_machine = g:netrw_uid .'@'. g:netrw_machine
    else
     let uid_machine = g:netrw_machine
    endif

    " formerly just a "new...bd!", that changed the window sizes when equalalways.  Using enew workaround instead
    let bhkeep = &l:bh
    let curbuf = bufnr("%")
    setl bh=hide
    keepj keepalt enew

    setl ff=unix
    call setline(1,'put "'.escape(tmpfile,'\').'" '.netrw_fname)
"    call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
    let sftpcmd= substitute(g:netrw_sftp_cmd,"%TEMPFILE%",escape(tmpfile,'\'),"g")
    call s:NetrwExe(s:netrw_silentxfer."%!".sftpcmd.' '.shellescape(uid_machine,1))
    let filtbuf= bufnr("%")
    exe curbuf."b!"
    let &l:bh            = bhkeep
    exe filtbuf."bw!"
    let b:netrw_lastfile = choice

   ".........................................
   " NetWrite: Complain {{{3
   else
    call netrw#ErrorMsg(s:WARNING,"unable to comply with your request<" . choice . ">",17)
    let leavemod= 1
   endif
  endwhile

  " NetWrite: Cleanup: {{{3
"  call Decho("cleanup",'~'.expand("<slnum>"))
  if s:FileReadable(tmpfile)
"   call Decho("tmpfile<".tmpfile."> readable, will now delete it",'~'.expand("<slnum>"))
   call s:NetrwDelete(tmpfile)
  endif
  call s:NetrwOptionRestore("w:")

  if a:firstline == 1 && a:lastline == line("$")
   " restore modifiability; usually equivalent to set nomod
   let &mod= mod
"   call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
  elseif !exists("leavemod")
   " indicate that the buffer has not been modified since last written
"   call Decho("set nomod",'~'.expand("<slnum>"))
   setl nomod
"   call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
  endif

"  call Dret("netrw#NetWrite")
endfun

" ---------------------------------------------------------------------
" netrw#NetSource: source a remotely hosted vim script {{{2
" uses NetRead to get a copy of the file into a temporarily file,
"              then sources that file,
"              then removes that file.
fun! netrw#NetSource(...)
"  call Dfunc("netrw#NetSource() a:0=".a:0)
  if a:0 > 0 && a:1 == '?'
   " give help
   echomsg 'NetSource Usage:'
   echomsg ':Nsource dav://machine[:port]/path            uses cadaver'
   echomsg ':Nsource fetch://machine/path                 uses fetch'
   echomsg ':Nsource ftp://[user@]machine[:port]/path     uses ftp   autodetects <.netrc>'
   echomsg ':Nsource http[s]://[user@]machine/path        uses http  wget'
   echomsg ':Nsource rcp://[user@]machine/path            uses rcp'
   echomsg ':Nsource rsync://machine[:port]/path          uses rsync'
   echomsg ':Nsource scp://[user@]machine[[:#]port]/path  uses scp'
   echomsg ':Nsource sftp://[user@]machine[[:#]port]/path uses sftp'
   sleep 4
  else
   let i= 1
   while i <= a:0
    call netrw#NetRead(3,a:{i})
"    call Decho("s:netread_tmpfile<".s:netrw_tmpfile.">",'~'.expand("<slnum>"))
    if s:FileReadable(s:netrw_tmpfile)
"     call Decho("exe so ".fnameescape(s:netrw_tmpfile),'~'.expand("<slnum>"))
     exe "so ".fnameescape(s:netrw_tmpfile)
"     call Decho("delete(".s:netrw_tmpfile.")",'~'.expand("<slnum>"))
     call delete(s:netrw_tmpfile)
     unlet s:netrw_tmpfile
    else
     call netrw#ErrorMsg(s:ERROR,"unable to source <".a:{i}.">!",48)
    endif
    let i= i + 1
   endwhile
  endif
"  call Dret("netrw#NetSource")
endfun

" ---------------------------------------------------------------------
" netrw#SetTreetop: resets the tree top to the current directory/specified directory {{{2
"                   (implements the :Ntree command)
fun! netrw#SetTreetop(...)
"  call Dfunc("netrw#SetTreetop(".((a:0 > 0)? a:1 : "").") a:0=".a:0)

  " clear out the current tree
  if exists("w:netrw_treetop")
"   call Decho("clearing out current tree",'~'.expand("<slnum>"))
   let inittreetop= w:netrw_treetop
   unlet w:netrw_treetop
  endif
  if exists("w:netrw_treedict")
"   call Decho("freeing w:netrw_treedict",'~'.expand("<slnum>"))
   unlet w:netrw_treedict
  endif

  if a:1 == "" && exists("inittreetop")
   let treedir= s:NetrwTreePath(inittreetop)
"   call Decho("treedir<".treedir.">",'~'.expand("<slnum>"))
  else
   if isdirectory(s:NetrwFile(a:1))
"    call Decho("a:1<".a:1."> is a directory",'~'.expand("<slnum>"))
    let treedir= a:1
   elseif exists("b:netrw_curdir") && (isdirectory(s:NetrwFile(b:netrw_curdir."/".a:1)) || a:1 =~ '^\a\{3,}://')
    let treedir= b:netrw_curdir."/".a:1
"    call Decho("a:1<".a:1."> is NOT a directory, trying treedir<".treedir.">",'~'.expand("<slnum>"))
   else
    " normally the cursor is left in the message window.
    " However, here this results in the directory being listed in the message window, which is not wanted.
    let netrwbuf= bufnr("%")
    call netrw#ErrorMsg(s:ERROR,"sorry, ".a:1." doesn't seem to be a directory!",95)
    exe bufwinnr(netrwbuf)."wincmd w"
    let treedir= "."
   endif
  endif
"  call Decho("treedir<".treedir.">",'~'.expand("<slnum>"))
  let islocal= expand("%") !~ '^\a\{3,}://'
"  call Decho("islocal=".islocal,'~'.expand("<slnum>"))
  if islocal
   call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(islocal,treedir))
  else
   call s:NetrwBrowse(islocal,s:NetrwBrowseChgDir(islocal,treedir))
  endif
"  call Dret("netrw#SetTreetop")
endfun

" ===========================================
" s:NetrwGetFile: Function to read temporary file "tfile" with command "readcmd". {{{2
"    readcmd == %r : replace buffer with newly read file
"            == 0r : read file at top of buffer
"            == r  : read file after current line
"            == t  : leave file in temporary form (ie. don't read into buffer)
fun! s:NetrwGetFile(readcmd, tfile, method)
"  call Dfunc("NetrwGetFile(readcmd<".a:readcmd.">,tfile<".a:tfile."> method<".a:method.">)")

  " readcmd=='t': simply do nothing
  if a:readcmd == 't'
"   call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"   call Dret("NetrwGetFile : skip read of <".a:tfile.">")
   return
  endif

  " get name of remote filename (ie. url and all)
  let rfile= bufname("%")
"  call Decho("rfile<".rfile.">",'~'.expand("<slnum>"))

  if exists("*NetReadFixup")
   " for the use of NetReadFixup (not otherwise used internally)
   let line2= line("$")
  endif

  if a:readcmd[0] == '%'
  " get file into buffer
"   call Decho("get file into buffer",'~'.expand("<slnum>"))

   " rename the current buffer to the temp file (ie. tfile)
   if g:netrw_cygwin
    let tfile= substitute(a:tfile,g:netrw_cygdrive.'/\(.\)','\1:','')
   else
    let tfile= a:tfile
   endif
"   call Decho("exe sil! keepalt file ".fnameescape(tfile),'~'.expand("<slnum>"))
   exe "sil! keepalt file ".fnameescape(tfile)

   " edit temporary file (ie. read the temporary file in)
   if     rfile =~ '\.zip$'
"    call Decho("handling remote zip file with zip#Browse(tfile<".tfile.">)",'~'.expand("<slnum>"))
    call zip#Browse(tfile)
   elseif rfile =~ '\.tar$'
"    call Decho("handling remote tar file with tar#Browse(tfile<".tfile.">)",'~'.expand("<slnum>"))
    call tar#Browse(tfile)
   elseif rfile =~ '\.tar\.gz$'
"    call Decho("handling remote gzip-compressed tar file",'~'.expand("<slnum>"))
    call tar#Browse(tfile)
   elseif rfile =~ '\.tar\.bz2$'
"    call Decho("handling remote bz2-compressed tar file",'~'.expand("<slnum>"))
    call tar#Browse(tfile)
   elseif rfile =~ '\.tar\.xz$'
"    call Decho("handling remote xz-compressed tar file",'~'.expand("<slnum>"))
    call tar#Browse(tfile)
   elseif rfile =~ '\.txz$'
"    call Decho("handling remote xz-compressed tar file (.txz)",'~'.expand("<slnum>"))
    call tar#Browse(tfile)
   else
"    call Decho("edit temporary file",'~'.expand("<slnum>"))
    NetrwKeepj e!
   endif

   " rename buffer back to remote filename
"   call Decho("exe sil! keepalt file ".fnameescape(rfile),'~'.expand("<slnum>"))
   exe "sil! NetrwKeepj keepalt file ".fnameescape(rfile)

   " Detect filetype of local version of remote file.
   " Note that isk must not include a "/" for scripts.vim
   " to process this detection correctly.
"   call Decho("detect filetype of local version of remote file",'~'.expand("<slnum>"))
   let iskkeep= &l:isk
   setl isk-=/
   let &l:isk= iskkeep
"   call Dredir("renamed buffer back to remote filename<".rfile."> : expand(%)<".expand("%").">","ls!")
   let line1 = 1
   let line2 = line("$")

  elseif !&ma
   " attempting to read a file after the current line in the file, but the buffer is not modifiable
   NetrwKeepj call netrw#ErrorMsg(s:WARNING,"attempt to read<".a:tfile."> into a non-modifiable buffer!",94)
"   call Dret("NetrwGetFile : attempt to read<".a:tfile."> into a non-modifiable buffer!")
   return

  elseif s:FileReadable(a:tfile)
   " read file after current line
"   call Decho("read file<".a:tfile."> after current line",'~'.expand("<slnum>"))
   let curline = line(".")
   let lastline= line("$")
"   call Decho("exe<".a:readcmd." ".fnameescape(v:cmdarg)." ".fnameescape(a:tfile).">  line#".curline,'~'.expand("<slnum>"))
   exe "NetrwKeepj ".a:readcmd." ".fnameescape(v:cmdarg)." ".fnameescape(a:tfile)
   let line1= curline + 1
   let line2= line("$") - lastline + 1

  else
   " not readable
"   call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"   call Decho("tfile<".a:tfile."> not readable",'~'.expand("<slnum>"))
   NetrwKeepj call netrw#ErrorMsg(s:WARNING,"file <".a:tfile."> not readable",9)
"   call Dret("NetrwGetFile : tfile<".a:tfile."> not readable")
   return
  endif

  " User-provided (ie. optional) fix-it-up command
  if exists("*NetReadFixup")
"   call Decho("calling NetReadFixup(method<".a:method."> line1=".line1." line2=".line2.")",'~'.expand("<slnum>"))
   NetrwKeepj call NetReadFixup(a:method, line1, line2)
"  else " Decho
"   call Decho("NetReadFixup() not called, doesn't exist  (line1=".line1." line2=".line2.")",'~'.expand("<slnum>"))
  endif

  if has("gui") && has("menu") && has("gui_running") && &go =~# 'm' && g:netrw_menu
   " update the Buffers menu
   NetrwKeepj call s:UpdateBuffersMenu()
  endif

"  call Decho("readcmd<".a:readcmd."> cmdarg<".v:cmdarg."> tfile<".a:tfile."> readable=".s:FileReadable(a:tfile),'~'.expand("<slnum>"))

 " make sure file is being displayed
"  redraw!

"  call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"  call Dret("NetrwGetFile")
endfun

" ------------------------------------------------------------------------
" s:NetrwMethod:  determine method of transfer {{{2
" Input:
"   choice = url   [protocol:]//[userid@]hostname[:port]/[path-to-file]
" Output:
"  b:netrw_method= 1: rcp
"                  2: ftp + <.netrc>
"	           3: ftp + machine, id, password, and [path]filename
"	           4: scp
"	           5: http[s] (wget)
"	           6: dav
"	           7: rsync
"	           8: fetch
"	           9: sftp
"	          10: file
"  g:netrw_machine= hostname
"  b:netrw_fname  = filename
"  g:netrw_port   = optional port number (for ftp)
"  g:netrw_choice = copy of input url (choice)
fun! s:NetrwMethod(choice)
"   call Dfunc("NetrwMethod(a:choice<".a:choice.">)")

   " sanity check: choice should have at least three slashes in it
   if strlen(substitute(a:choice,'[^/]','','g')) < 3
    call netrw#ErrorMsg(s:ERROR,"not a netrw-style url; netrw uses protocol://[user@]hostname[:port]/[path])",78)
    let b:netrw_method = -1
"    call Dret("NetrwMethod : incorrect url format<".a:choice.">")
    return
   endif

   " record current g:netrw_machine, if any
   " curmachine used if protocol == ftp and no .netrc
   if exists("g:netrw_machine")
    let curmachine= g:netrw_machine
"    call Decho("curmachine<".curmachine.">",'~'.expand("<slnum>"))
   else
    let curmachine= "N O T A HOST"
   endif
   if exists("g:netrw_port")
    let netrw_port= g:netrw_port
   endif

   " insure that netrw_ftp_cmd starts off every method determination
   " with the current g:netrw_ftp_cmd
   let s:netrw_ftp_cmd= g:netrw_ftp_cmd

  " initialization
  let b:netrw_method  = 0
  let g:netrw_machine = ""
  let b:netrw_fname   = ""
  let g:netrw_port    = ""
  let g:netrw_choice  = a:choice

  " Patterns:
  " mipf     : a:machine a:id password filename	     Use ftp
  " mf	    : a:machine filename		     Use ftp + <.netrc> or g:netrw_uid s:netrw_passwd
  " ftpurm   : ftp://[user@]host[[#:]port]/filename  Use ftp + <.netrc> or g:netrw_uid s:netrw_passwd
  " rcpurm   : rcp://[user@]host/filename	     Use rcp
  " rcphf    : [user@]host:filename		     Use rcp
  " scpurm   : scp://[user@]host[[#:]port]/filename  Use scp
  " httpurm  : http[s]://[user@]host/filename	     Use wget
  " davurm   : dav[s]://host[:port]/path             Use cadaver/curl
  " rsyncurm : rsync://host[:port]/path              Use rsync
  " fetchurm : fetch://[user@]host[:http]/filename   Use fetch (defaults to ftp, override for http)
  " sftpurm  : sftp://[user@]host/filename  Use scp
  " fileurm  : file://[user@]host/filename	     Use elinks or links
  let mipf     = '^\(\S\+\)\s\+\(\S\+\)\s\+\(\S\+\)\s\+\(\S\+\)$'
  let mf       = '^\(\S\+\)\s\+\(\S\+\)$'
  let ftpurm   = '^ftp://\(\([^/]*\)@\)\=\([^/#:]\{-}\)\([#:]\d\+\)\=/\(.*\)$'
  let rcpurm   = '^rcp://\%(\([^/]*\)@\)\=\([^/]\{-}\)/\(.*\)$'
  let rcphf    = '^\(\(\h\w*\)@\)\=\(\h\w*\):\([^@]\+\)$'
  let scpurm   = '^scp://\([^/#:]\+\)\%([#:]\(\d\+\)\)\=/\(.*\)$'
  let httpurm  = '^https\=://\([^/]\{-}\)\(/.*\)\=$'
  let davurm   = '^davs\=://\([^/]\+\)/\(.*/\)\([-_.~[:alnum:]]\+\)$'
  let rsyncurm = '^rsync://\([^/]\{-}\)/\(.*\)\=$'
  let fetchurm = '^fetch://\(\([^/]*\)@\)\=\([^/#:]\{-}\)\(:http\)\=/\(.*\)$'
  let sftpurm  = '^sftp://\([^/]\{-}\)/\(.*\)\=$'
  let fileurm  = '^file\=://\(.*\)$'

"  call Decho("determine method:",'~'.expand("<slnum>"))
  " Determine Method
  " Method#1: rcp://user@hostname/...path-to-file {{{3
  if match(a:choice,rcpurm) == 0
"   call Decho("rcp://...",'~'.expand("<slnum>"))
   let b:netrw_method  = 1
   let userid          = substitute(a:choice,rcpurm,'\1',"")
   let g:netrw_machine = substitute(a:choice,rcpurm,'\2',"")
   let b:netrw_fname   = substitute(a:choice,rcpurm,'\3',"")
   if userid != ""
    let g:netrw_uid= userid
   endif

  " Method#4: scp://user@hostname/...path-to-file {{{3
  elseif match(a:choice,scpurm) == 0
"   call Decho("scp://...",'~'.expand("<slnum>"))
   let b:netrw_method  = 4
   let g:netrw_machine = substitute(a:choice,scpurm,'\1',"")
   let g:netrw_port    = substitute(a:choice,scpurm,'\2',"")
   let b:netrw_fname   = substitute(a:choice,scpurm,'\3',"")

  " Method#5: http[s]://user@hostname/...path-to-file {{{3
  elseif match(a:choice,httpurm) == 0
"   call Decho("http[s]://...",'~'.expand("<slnum>"))
   let b:netrw_method = 5
   let g:netrw_machine= substitute(a:choice,httpurm,'\1',"")
   let b:netrw_fname  = substitute(a:choice,httpurm,'\2',"")
   let b:netrw_http   = (a:choice =~ '^https:')? "https" : "http"

  " Method#6: dav://hostname[:port]/..path-to-file.. {{{3
  elseif match(a:choice,davurm) == 0
"   call Decho("dav://...",'~'.expand("<slnum>"))
   let b:netrw_method= 6
   if a:choice =~ 'davs:'
    let g:netrw_machine= 'https://'.substitute(a:choice,davurm,'\1/\2',"")
   else
    let g:netrw_machine= 'http://'.substitute(a:choice,davurm,'\1/\2',"")
   endif
   let b:netrw_fname  = substitute(a:choice,davurm,'\3',"")

   " Method#7: rsync://user@hostname/...path-to-file {{{3
  elseif match(a:choice,rsyncurm) == 0
"   call Decho("rsync://...",'~'.expand("<slnum>"))
   let b:netrw_method = 7
   let g:netrw_machine= substitute(a:choice,rsyncurm,'\1',"")
   let b:netrw_fname  = substitute(a:choice,rsyncurm,'\2',"")

   " Methods 2,3: ftp://[user@]hostname[[:#]port]/...path-to-file {{{3
  elseif match(a:choice,ftpurm) == 0
"   call Decho("ftp://...",'~'.expand("<slnum>"))
   let userid	      = substitute(a:choice,ftpurm,'\2',"")
   let g:netrw_machine= substitute(a:choice,ftpurm,'\3',"")
   let g:netrw_port   = substitute(a:choice,ftpurm,'\4',"")
   let b:netrw_fname  = substitute(a:choice,ftpurm,'\5',"")
"   call Decho("g:netrw_machine<".g:netrw_machine.">",'~'.expand("<slnum>"))
   if userid != ""
    let g:netrw_uid= userid
   endif

   if curmachine != g:netrw_machine
    if exists("s:netwr_hup[".g:netrw_machine."]")
     call NetUserPass("ftp:".g:netrw_machine)
    elseif exists("s:netrw_passwd")
     " if there's a change in hostname, require password re-entry
     unlet s:netrw_passwd
    endif
    if exists("netrw_port")
     unlet netrw_port
    endif
   endif

   if exists("g:netrw_uid") && exists("s:netrw_passwd")
    let b:netrw_method = 3
   else
    let host= substitute(g:netrw_machine,'\..*$','','')
    if exists("s:netrw_hup[host]")
     call NetUserPass("ftp:".host)

    elseif (has("win32") || has("win95") || has("win64") || has("win16")) && s:netrw_ftp_cmd =~ '-[sS]:'
"     call Decho("has -s: : s:netrw_ftp_cmd<".s:netrw_ftp_cmd.">",'~'.expand("<slnum>"))
"     call Decho("          g:netrw_ftp_cmd<".g:netrw_ftp_cmd.">",'~'.expand("<slnum>"))
     if g:netrw_ftp_cmd =~ '-[sS]:\S*MACHINE\>'
      let s:netrw_ftp_cmd= substitute(g:netrw_ftp_cmd,'\<MACHINE\>',g:netrw_machine,'')
"      call Decho("s:netrw_ftp_cmd<".s:netrw_ftp_cmd.">",'~'.expand("<slnum>"))
     endif
     let b:netrw_method= 2
    elseif s:FileReadable(expand("$HOME/.netrc")) && !g:netrw_ignorenetrc
"     call Decho("using <".expand("$HOME/.netrc")."> (readable)",'~'.expand("<slnum>"))
     let b:netrw_method= 2
    else
     if !exists("g:netrw_uid") || g:netrw_uid == ""
      call NetUserPass()
     elseif !exists("s:netrw_passwd") || s:netrw_passwd == ""
      call NetUserPass(g:netrw_uid)
    " else just use current g:netrw_uid and s:netrw_passwd
     endif
     let b:netrw_method= 3
    endif
   endif

  " Method#8: fetch {{{3
  elseif match(a:choice,fetchurm) == 0
"   call Decho("fetch://...",'~'.expand("<slnum>"))
   let b:netrw_method = 8
   let g:netrw_userid = substitute(a:choice,fetchurm,'\2',"")
   let g:netrw_machine= substitute(a:choice,fetchurm,'\3',"")
   let b:netrw_option = substitute(a:choice,fetchurm,'\4',"")
   let b:netrw_fname  = substitute(a:choice,fetchurm,'\5',"")

   " Method#3: Issue an ftp : "machine id password [path/]filename" {{{3
  elseif match(a:choice,mipf) == 0
"   call Decho("(ftp) host id pass file",'~'.expand("<slnum>"))
   let b:netrw_method  = 3
   let g:netrw_machine = substitute(a:choice,mipf,'\1',"")
   let g:netrw_uid     = substitute(a:choice,mipf,'\2',"")
   let s:netrw_passwd  = substitute(a:choice,mipf,'\3',"")
   let b:netrw_fname   = substitute(a:choice,mipf,'\4',"")
   call NetUserPass(g:netrw_machine,g:netrw_uid,s:netrw_passwd)

  " Method#3: Issue an ftp: "hostname [path/]filename" {{{3
  elseif match(a:choice,mf) == 0
"   call Decho("(ftp) host file",'~'.expand("<slnum>"))
   if exists("g:netrw_uid") && exists("s:netrw_passwd")
    let b:netrw_method  = 3
    let g:netrw_machine = substitute(a:choice,mf,'\1',"")
    let b:netrw_fname   = substitute(a:choice,mf,'\2',"")

   elseif s:FileReadable(expand("$HOME/.netrc"))
    let b:netrw_method  = 2
    let g:netrw_machine = substitute(a:choice,mf,'\1',"")
    let b:netrw_fname   = substitute(a:choice,mf,'\2',"")
   endif

  " Method#9: sftp://user@hostname/...path-to-file {{{3
  elseif match(a:choice,sftpurm) == 0
"   call Decho("sftp://...",'~'.expand("<slnum>"))
   let b:netrw_method = 9
   let g:netrw_machine= substitute(a:choice,sftpurm,'\1',"")
   let b:netrw_fname  = substitute(a:choice,sftpurm,'\2',"")

  " Method#1: Issue an rcp: hostname:filename"  (this one should be last) {{{3
  elseif match(a:choice,rcphf) == 0
"   call Decho("(rcp) [user@]host:file) rcphf<".rcphf.">",'~'.expand("<slnum>"))
   let b:netrw_method  = 1
   let userid          = substitute(a:choice,rcphf,'\2',"")
   let g:netrw_machine = substitute(a:choice,rcphf,'\3',"")
   let b:netrw_fname   = substitute(a:choice,rcphf,'\4',"")
"   call Decho('\1<'.substitute(a:choice,rcphf,'\1',"").">",'~'.expand("<slnum>"))
"   call Decho('\2<'.substitute(a:choice,rcphf,'\2',"").">",'~'.expand("<slnum>"))
"   call Decho('\3<'.substitute(a:choice,rcphf,'\3',"").">",'~'.expand("<slnum>"))
"   call Decho('\4<'.substitute(a:choice,rcphf,'\4',"").">",'~'.expand("<slnum>"))
   if userid != ""
    let g:netrw_uid= userid
   endif

   " Method#10: file://user@hostname/...path-to-file {{{3
  elseif match(a:choice,fileurm) == 0 && exists("g:netrw_file_cmd")
"   call Decho("http[s]://...",'~'.expand("<slnum>"))
   let b:netrw_method = 10
   let b:netrw_fname  = substitute(a:choice,fileurm,'\1',"")
"   call Decho('\1<'.substitute(a:choice,fileurm,'\1',"").">",'~'.expand("<slnum>"))

  " Cannot Determine Method {{{3
  else
   if !exists("g:netrw_quiet")
    call netrw#ErrorMsg(s:WARNING,"cannot determine method (format: protocol://[user@]hostname[:port]/[path])",45)
   endif
   let b:netrw_method  = -1
  endif
  "}}}3

  if g:netrw_port != ""
   " remove any leading [:#] from port number
   let g:netrw_port = substitute(g:netrw_port,'[#:]\+','','')
  elseif exists("netrw_port")
   " retain port number as implicit for subsequent ftp operations
   let g:netrw_port= netrw_port
  endif

"  call Decho("a:choice       <".a:choice.">",'~'.expand("<slnum>"))
"  call Decho("b:netrw_method <".b:netrw_method.">",'~'.expand("<slnum>"))
"  call Decho("g:netrw_machine<".g:netrw_machine.">",'~'.expand("<slnum>"))
"  call Decho("g:netrw_port   <".g:netrw_port.">",'~'.expand("<slnum>"))
"  if exists("g:netrw_uid")		"Decho
"   call Decho("g:netrw_uid    <".g:netrw_uid.">",'~'.expand("<slnum>"))
"  endif					"Decho
"  if exists("s:netrw_passwd")		"Decho
"   call Decho("s:netrw_passwd <".s:netrw_passwd.">",'~'.expand("<slnum>"))
"  endif					"Decho
"  call Decho("b:netrw_fname  <".b:netrw_fname.">",'~'.expand("<slnum>"))
"  call Dret("NetrwMethod : b:netrw_method=".b:netrw_method." g:netrw_port=".g:netrw_port)
endfun

" ------------------------------------------------------------------------
" NetReadFixup: this sort of function is typically written by the user {{{2
"               to handle extra junk that their system's ftp dumps
"               into the transfer.  This function is provided as an
"               example and as a fix for a Windows 95 problem: in my
"               experience, win95's ftp always dumped four blank lines
"               at the end of the transfer.
if has("win95") && exists("g:netrw_win95ftp") && g:netrw_win95ftp
 fun! NetReadFixup(method, line1, line2)
"   call Dfunc("NetReadFixup(method<".a:method."> line1=".a:line1." line2=".a:line2.")")

   " sanity checks -- attempt to convert inputs to integers
   let method = a:method + 0
   let line1  = a:line1 + 0
   let line2  = a:line2 + 0
   if type(method) != 0 || type(line1) != 0 || type(line2) != 0 || method < 0 || line1 <= 0 || line2 <= 0
"    call Dret("NetReadFixup")
    return
   endif

   if method == 3   " ftp (no <.netrc>)
    let fourblanklines= line2 - 3
    if fourblanklines >= line1
     exe "sil NetrwKeepj ".fourblanklines.",".line2."g/^\s*$/d"
     call histdel("/",-1)
    endif
   endif

"   call Dret("NetReadFixup")
 endfun
endif

" ---------------------------------------------------------------------
" NetUserPass: set username and password for subsequent ftp transfer {{{2
"   Usage:  :call NetUserPass()		               -- will prompt for userid and password
"	    :call NetUserPass("uid")	               -- will prompt for password
"	    :call NetUserPass("uid","password")        -- sets global userid and password
"	    :call NetUserPass("ftp:host")              -- looks up userid and password using hup dictionary
"	    :call NetUserPass("host","uid","password") -- sets hup dictionary with host, userid, password
fun! NetUserPass(...)

" call Dfunc("NetUserPass() a:0=".a:0)

 if !exists('s:netrw_hup')
  let s:netrw_hup= {}
 endif

 if a:0 == 0
  " case: no input arguments

  " change host and username if not previously entered; get new password
  if !exists("g:netrw_machine")
   let g:netrw_machine= input('Enter hostname: ')
  endif
  if !exists("g:netrw_uid") || g:netrw_uid == ""
   " get username (user-id) via prompt
   let g:netrw_uid= input('Enter username: ')
  endif
  " get password via prompting
  let s:netrw_passwd= inputsecret("Enter Password: ")

  " set up hup database
  let host = substitute(g:netrw_machine,'\..*$','','')
  if !exists('s:netrw_hup[host]')
   let s:netrw_hup[host]= {}
  endif
  let s:netrw_hup[host].uid    = g:netrw_uid
  let s:netrw_hup[host].passwd = s:netrw_passwd

 elseif a:0 == 1
  " case: one input argument

  if a:1 =~ '^ftp:'
   " get host from ftp:... url
   " access userid and password from hup (host-user-passwd) dictionary
"   call Decho("case a:0=1: a:1<".a:1."> (get host from ftp:... url)",'~'.expand("<slnum>"))
   let host = substitute(a:1,'^ftp:','','')
   let host = substitute(host,'\..*','','')
   if exists("s:netrw_hup[host]")
    let g:netrw_uid    = s:netrw_hup[host].uid
    let s:netrw_passwd = s:netrw_hup[host].passwd
"    call Decho("get s:netrw_hup[".host."].uid   <".s:netrw_hup[host].uid.">",'~'.expand("<slnum>"))
"    call Decho("get s:netrw_hup[".host."].passwd<".s:netrw_hup[host].passwd.">",'~'.expand("<slnum>"))
   else
    let g:netrw_uid    = input("Enter UserId: ")
    let s:netrw_passwd = inputsecret("Enter Password: ")
   endif

  else
   " case: one input argument, not an url.  Using it as a new user-id.
"   call Decho("case a:0=1: a:1<".a:1."> (get host from input argument, not an url)",'~'.expand("<slnum>"))
   if exists("g:netrw_machine")
    if g:netrw_machine =~ '[0-9.]\+'
     let host= g:netrw_machine
    else
     let host= substitute(g:netrw_machine,'\..*$','','')
    endif
   else
    let g:netrw_machine= input('Enter hostname: ')
   endif
   let g:netrw_uid = a:1
"   call Decho("set g:netrw_uid= <".g:netrw_uid.">",'~'.expand("<slnum>"))
   if exists("g:netrw_passwd")
    " ask for password if one not previously entered
    let s:netrw_passwd= g:netrw_passwd
   else
    let s:netrw_passwd = inputsecret("Enter Password: ")
   endif
  endif

"  call Decho("host<".host.">",'~'.expand("<slnum>"))
  if exists("host")
   if !exists('s:netrw_hup[host]')
    let s:netrw_hup[host]= {}
   endif
   let s:netrw_hup[host].uid    = g:netrw_uid
   let s:netrw_hup[host].passwd = s:netrw_passwd
  endif

 elseif a:0 == 2
  let g:netrw_uid    = a:1
  let s:netrw_passwd = a:2

 elseif a:0 == 3
  " enter hostname, user-id, and password into the hup dictionary
  let host = substitute(a:1,'^\a\+:','','')
  let host = substitute(host,'\..*$','','')
  if !exists('s:netrw_hup[host]')
   let s:netrw_hup[host]= {}
  endif
  let s:netrw_hup[host].uid    = a:2
  let s:netrw_hup[host].passwd = a:3
  let g:netrw_uid              = s:netrw_hup[host].uid
  let s:netrw_passwd           = s:netrw_hup[host].passwd
"  call Decho("set s:netrw_hup[".host."].uid   <".s:netrw_hup[host].uid.">",'~'.expand("<slnum>"))
"  call Decho("set s:netrw_hup[".host."].passwd<".s:netrw_hup[host].passwd.">",'~'.expand("<slnum>"))
 endif

" call Dret("NetUserPass : uid<".g:netrw_uid."> passwd<".s:netrw_passwd.">")
endfun

" ===========================================
"  Shared Browsing Support:    {{{1
" ===========================================

" ---------------------------------------------------------------------
" s:ExplorePatHls: converts an Explore pattern into a regular expression search pattern {{{2
fun! s:ExplorePatHls(pattern)
"  call Dfunc("s:ExplorePatHls(pattern<".a:pattern.">)")
  let repat= substitute(a:pattern,'^**/\{1,2}','','')
"  call Decho("repat<".repat.">",'~'.expand("<slnum>"))
  let repat= escape(repat,'][.\')
"  call Decho("repat<".repat.">",'~'.expand("<slnum>"))
  let repat= '\<'.substitute(repat,'\*','\\(\\S\\+ \\)*\\S\\+','g').'\>'
"  call Dret("s:ExplorePatHls repat<".repat.">")
  return repat
endfun

" ---------------------------------------------------------------------
"  s:NetrwBookHistHandler: {{{2
"    0: (user: <mb>)   bookmark current directory
"    1: (user: <gb>)   change to the bookmarked directory
"    2: (user: <qb>)   list bookmarks
"    3: (browsing)     records current directory history
"    4: (user: <u>)    go up   (previous) directory, using history
"    5: (user: <U>)    go down (next)     directory, using history
"    6: (user: <mB>)   delete bookmark
fun! s:NetrwBookHistHandler(chg,curdir)
"  call Dfunc("s:NetrwBookHistHandler(chg=".a:chg." curdir<".a:curdir.">) cnt=".v:count." histcnt=".g:netrw_dirhist_cnt." histmax=".g:netrw_dirhistmax)
  if !exists("g:netrw_dirhistmax") || g:netrw_dirhistmax <= 0
"   "  call Dret("s:NetrwBookHistHandler - suppressed due to g:netrw_dirhistmax")
   return
  endif

  let ykeep    = @@
  let curbufnr = bufnr("%")

  if a:chg == 0
   " bookmark the current directory
"   call Decho("(user: <b>) bookmark the current directory",'~'.expand("<slnum>"))
   if exists("s:netrwmarkfilelist_{curbufnr}")
    call s:NetrwBookmark(0)
    echo "bookmarked marked files"
   else
    call s:MakeBookmark(a:curdir)
    echo "bookmarked the current directory"
   endif

  elseif a:chg == 1
   " change to the bookmarked directory
"   call Decho("(user: <".v:count."gb>) change to the bookmarked directory",'~'.expand("<slnum>"))
   if exists("g:netrw_bookmarklist[v:count-1]")
"    call Decho("(user: <".v:count."gb>) bookmarklist=".string(g:netrw_bookmarklist),'~'.expand("<slnum>"))
    exe "NetrwKeepj e ".fnameescape(g:netrw_bookmarklist[v:count-1])
   else
    echomsg "Sorry, bookmark#".v:count." doesn't exist!"
   endif

  elseif a:chg == 2
"   redraw!
   let didwork= 0
   " list user's bookmarks
"   call Decho("(user: <q>) list user's bookmarks",'~'.expand("<slnum>"))
   if exists("g:netrw_bookmarklist")
"    call Decho('list '.len(g:netrw_bookmarklist).' bookmarks','~'.expand("<slnum>"))
    let cnt= 1
    for bmd in g:netrw_bookmarklist
"     call Decho("Netrw Bookmark#".cnt.": ".g:netrw_bookmarklist[cnt-1],'~'.expand("<slnum>"))
     echo printf("Netrw Bookmark#%-2d: %s",cnt,g:netrw_bookmarklist[cnt-1])
     let didwork = 1
     let cnt     = cnt + 1
    endfor
   endif

   " list directory history
   let cnt     = g:netrw_dirhist_cnt
   let first   = 1
   let histcnt = 0
   if g:netrw_dirhistmax > 0
    while ( first || cnt != g:netrw_dirhist_cnt )
"    call Decho("first=".first." cnt=".cnt." dirhist_cnt=".g:netrw_dirhist_cnt,'~'.expand("<slnum>"))
     if exists("g:netrw_dirhist_{cnt}")
"     call Decho("Netrw  History#".histcnt.": ".g:netrw_dirhist_{cnt},'~'.expand("<slnum>"))
      echo printf("Netrw  History#%-2d: %s",histcnt,g:netrw_dirhist_{cnt})
      let didwork= 1
     endif
     let histcnt = histcnt + 1
     let first   = 0
     let cnt     = ( cnt - 1 ) % g:netrw_dirhistmax
     if cnt < 0
      let cnt= cnt + g:netrw_dirhistmax
     endif
    endwhile
   else
    let g:netrw_dirhist_cnt= 0
   endif
   if didwork
    call inputsave()|call input("Press <cr> to continue")|call inputrestore()
   endif

  elseif a:chg == 3
   " saves most recently visited directories (when they differ)
"   call Decho("(browsing) record curdir history",'~'.expand("<slnum>"))
   if !exists("g:netrw_dirhist_cnt") || !exists("g:netrw_dirhist_{g:netrw_dirhist_cnt}") || g:netrw_dirhist_{g:netrw_dirhist_cnt} != a:curdir
    if g:netrw_dirhistmax > 0
     let g:netrw_dirhist_cnt                   = ( g:netrw_dirhist_cnt + 1 ) % g:netrw_dirhistmax
     let g:netrw_dirhist_{g:netrw_dirhist_cnt} = a:curdir
    endif
"    call Decho("save dirhist#".g:netrw_dirhist_cnt."<".g:netrw_dirhist_{g:netrw_dirhist_cnt}.">",'~'.expand("<slnum>"))
   endif

  elseif a:chg == 4
   " u: change to the previous directory stored on the history list
"   call Decho("(user: <u>) chg to prev dir from history",'~'.expand("<slnum>"))
   if g:netrw_dirhistmax > 0
    let g:netrw_dirhist_cnt= ( g:netrw_dirhist_cnt - v:count1 ) % g:netrw_dirhistmax
    if g:netrw_dirhist_cnt < 0
     let g:netrw_dirhist_cnt= g:netrw_dirhist_cnt + g:netrw_dirhistmax
    endif
   else
    let g:netrw_dirhist_cnt= 0
   endif
   if exists("g:netrw_dirhist_{g:netrw_dirhist_cnt}")
"    call Decho("changedir u#".g:netrw_dirhist_cnt."<".g:netrw_dirhist_{g:netrw_dirhist_cnt}.">",'~'.expand("<slnum>"))
    if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && exists("b:netrw_curdir")
     setl ma noro
"     call Decho("setl ma noro",'~'.expand("<slnum>"))
     sil! NetrwKeepj %d _
     setl nomod
"     call Decho("setl nomod",'~'.expand("<slnum>"))
"     call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
    endif
"    call Decho("exe e! ".fnameescape(g:netrw_dirhist_{g:netrw_dirhist_cnt}),'~'.expand("<slnum>"))
    exe "NetrwKeepj e! ".fnameescape(g:netrw_dirhist_{g:netrw_dirhist_cnt})
   else
    if g:netrw_dirhistmax > 0
     let g:netrw_dirhist_cnt= ( g:netrw_dirhist_cnt + v:count1 ) % g:netrw_dirhistmax
    else
     let g:netrw_dirhist_cnt= 0
    endif
    echo "Sorry, no predecessor directory exists yet"
   endif

  elseif a:chg == 5
   " U: change to the subsequent directory stored on the history list
"   call Decho("(user: <U>) chg to next dir from history",'~'.expand("<slnum>"))
   if g:netrw_dirhistmax > 0
    let g:netrw_dirhist_cnt= ( g:netrw_dirhist_cnt + 1 ) % g:netrw_dirhistmax
    if exists("g:netrw_dirhist_{g:netrw_dirhist_cnt}")
"    call Decho("changedir U#".g:netrw_dirhist_cnt."<".g:netrw_dirhist_{g:netrw_dirhist_cnt}.">",'~'.expand("<slnum>"))
     if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && exists("b:netrw_curdir")
"      call Decho("setl ma noro",'~'.expand("<slnum>"))
      setl ma noro
      sil! NetrwKeepj %d _
"      call Decho("removed all lines from buffer (%d)",'~'.expand("<slnum>"))
"      call Decho("setl nomod",'~'.expand("<slnum>"))
      setl nomod
"      call Decho("(set nomod)  ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
     endif
"    call Decho("exe e! ".fnameescape(g:netrw_dirhist_{g:netrw_dirhist_cnt}),'~'.expand("<slnum>"))
     exe "NetrwKeepj e! ".fnameescape(g:netrw_dirhist_{g:netrw_dirhist_cnt})
    else
     let g:netrw_dirhist_cnt= ( g:netrw_dirhist_cnt - 1 ) % g:netrw_dirhistmax
     if g:netrw_dirhist_cnt < 0
      let g:netrw_dirhist_cnt= g:netrw_dirhist_cnt + g:netrw_dirhistmax
     endif
     echo "Sorry, no successor directory exists yet"
    endif
   else
    let g:netrw_dirhist_cnt= 0
    echo "Sorry, no successor directory exists yet (g:netrw_dirhistmax is ".g:netrw_dirhistmax.")"
   endif

  elseif a:chg == 6
"   call Decho("(user: <mB>) delete bookmark'd directory",'~'.expand("<slnum>"))
   if exists("s:netrwmarkfilelist_{curbufnr}")
    call s:NetrwBookmark(1)
    echo "removed marked files from bookmarks"
   else
    " delete the v:count'th bookmark
    let iremove = v:count
    let dremove = g:netrw_bookmarklist[iremove - 1]
"    call Decho("delete bookmark#".iremove."<".g:netrw_bookmarklist[iremove - 1].">",'~'.expand("<slnum>"))
    call s:MergeBookmarks()
"    call Decho("remove g:netrw_bookmarklist[".(iremove-1)."]<".g:netrw_bookmarklist[(iremove-1)].">",'~'.expand("<slnum>"))
    NetrwKeepj call remove(g:netrw_bookmarklist,iremove-1)
    echo "removed ".dremove." from g:netrw_bookmarklist"
"    call Decho("g:netrw_bookmarklist=".string(g:netrw_bookmarklist),'~'.expand("<slnum>"))
   endif
"   call Decho("resulting g:netrw_bookmarklist=".string(g:netrw_bookmarklist),'~'.expand("<slnum>"))
  endif
  call s:NetrwBookmarkMenu()
  call s:NetrwTgtMenu()
  let @@= ykeep
"  call Dret("s:NetrwBookHistHandler")
endfun

" ---------------------------------------------------------------------
" s:NetrwBookHistRead: this function reads bookmarks and history {{{2
"  Will source the history file (.netrwhist) only if the g:netrw_disthistmax is > 0.
"                      Sister function: s:NetrwBookHistSave()
fun! s:NetrwBookHistRead()
"  call Dfunc("s:NetrwBookHistRead()")
  if !exists("g:netrw_dirhistmax") || g:netrw_dirhistmax <= 0
"   "  call Dret("s:NetrwBookHistRead - suppressed due to g:netrw_dirhistmax")
   return
  endif
  let ykeep= @@
  if !exists("s:netrw_initbookhist")
   let home    = s:NetrwHome()
   let savefile= home."/.netrwbook"
   if filereadable(s:NetrwFile(savefile))
"    call Decho("sourcing .netrwbook",'~'.expand("<slnum>"))
    exe "keepalt NetrwKeepj so ".savefile
   endif
   if g:netrw_dirhistmax > 0
    let savefile= home."/.netrwhist"
    if filereadable(s:NetrwFile(savefile))
"    call Decho("sourcing .netrwhist",'~'.expand("<slnum>"))
     exe "keepalt NetrwKeepj so ".savefile
    endif
    let s:netrw_initbookhist= 1
    au VimLeave * call s:NetrwBookHistSave()
   endif
  endif
  let @@= ykeep
"  call Dret("s:NetrwBookHistRead")
endfun

" ---------------------------------------------------------------------
" s:NetrwBookHistSave: this function saves bookmarks and history {{{2
"                      Sister function: s:NetrwBookHistRead()
"                      I used to do this via viminfo but that appears to
"                      be unreliable for long-term storage
"                      If g:netrw_dirhistmax is <= 0, no history or bookmarks
"                      will be saved.
fun! s:NetrwBookHistSave()
"  call Dfunc("s:NetrwBookHistSave() dirhistmax=".g:netrw_dirhistmax)
  if !exists("g:netrw_dirhistmax") || g:netrw_dirhistmax <= 0
"   call Dret("s:NetrwBookHistSave : dirhistmax=".g:netrw_dirhistmax)
   return
  endif

  let savefile= s:NetrwHome()."/.netrwhist"
  1split
  call s:NetrwEnew()
  setl cino= com= cpo-=a cpo-=A fo=nroql2 tw=0 report=10000 noswf
  setl nocin noai noci magic nospell nohid wig= noaw
  setl ma noro write
  if exists("+acd") | setl noacd | endif
  sil! NetrwKeepj keepalt %d _

  " save .netrwhist -- no attempt to merge
  sil! keepalt file .netrwhist
  call setline(1,"let g:netrw_dirhistmax  =".g:netrw_dirhistmax)
  call setline(2,"let g:netrw_dirhist_cnt =".g:netrw_dirhist_cnt)
  let lastline = line("$")
  let cnt      = 1
  while cnt <= g:netrw_dirhist_cnt
   call setline((cnt+lastline),'let g:netrw_dirhist_'.cnt."='".g:netrw_dirhist_{cnt}."'")
   let cnt= cnt + 1
  endwhile
  exe "sil! w! ".savefile

  sil NetrwKeepj %d _
  if exists("g:netrw_bookmarklist") && g:netrw_bookmarklist != []
   " merge and write .netrwbook
   let savefile= s:NetrwHome()."/.netrwbook"

   if filereadable(s:NetrwFile(savefile))
    let booklist= deepcopy(g:netrw_bookmarklist)
    exe "sil NetrwKeepj keepalt so ".savefile
    for bdm in booklist
     if index(g:netrw_bookmarklist,bdm) == -1
      call add(g:netrw_bookmarklist,bdm)
     endif
    endfor
    call sort(g:netrw_bookmarklist)
   endif

   " construct and save .netrwbook
   call setline(1,"let g:netrw_bookmarklist= ".string(g:netrw_bookmarklist))
   exe "sil! w! ".savefile
  endif
  let bgone= bufnr("%")
  q!
  exe "keepalt ".bgone."bwipe!"

"  call Dret("s:NetrwBookHistSave")
endfun

" ---------------------------------------------------------------------
" s:NetrwBrowse: This function uses the command in g:netrw_list_cmd to provide a {{{2
"  list of the contents of a local or remote directory.  It is assumed that the
"  g:netrw_list_cmd has a string, USEPORT HOSTNAME, that needs to be substituted
"  with the requested remote hostname first.
"    Often called via:  Explore/e dirname/etc -> netrw#LocalBrowseCheck() -> s:NetrwBrowse()
fun! s:NetrwBrowse(islocal,dirname)
  if !exists("w:netrw_liststyle")|let w:netrw_liststyle= g:netrw_liststyle|endif
"  call Dfunc("s:NetrwBrowse(islocal=".a:islocal." dirname<".a:dirname.">) liststyle=".w:netrw_liststyle." ".g:loaded_netrw." buf#".bufnr("%")."<".bufname("%")."> win#".winnr())
"  call Decho("modified=".&modified." modifiable=".&modifiable." readonly=".&readonly,'~'.expand("<slnum>"))
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"  call Dredir("ls!")

  " save alternate-file's filename if w:netrw_rexlocal doesn't exist
  " This is useful when one edits a local file, then :e ., then :Rex
  if a:islocal && !exists("w:netrw_rexfile") && bufname("#") != ""
   let w:netrw_rexfile= bufname("#")
  endif

  " s:NetrwBrowse : initialize history {{{3
  if !exists("s:netrw_initbookhist")
   NetrwKeepj call s:NetrwBookHistRead()
  endif

  " s:NetrwBrowse : simplify the dirname (especially for ".."s in dirnames) {{{3
  if a:dirname !~ '^\a\{3,}://'
   let dirname= simplify(a:dirname)
  else
   let dirname= a:dirname
  endif

  if exists("s:netrw_skipbrowse")
   unlet s:netrw_skipbrowse
"   call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." filename<".expand("%")."> win#".winnr()." ft<".&ft.">",'~'.expand("<slnum>"))
"   call Dret("s:NetrwBrowse : s:netrw_skipbrowse existed")
   return
  endif

  " s:NetrwBrowse : sanity checks: {{{3
  if !exists("*shellescape")
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"netrw can't run -- your vim is missing shellescape()",69)
"   call Dret("s:NetrwBrowse : missing shellescape()")
   return
  endif
  if !exists("*fnameescape")
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"netrw can't run -- your vim is missing fnameescape()",70)
"   call Dret("s:NetrwBrowse : missing fnameescape()")
   return
  endif

  " s:NetrwBrowse : save options: {{{3
  call s:NetrwOptionSave("w:")

  " s:NetrwBrowse : re-instate any marked files {{{3
  if exists("s:netrwmarkfilelist_{bufnr('%')}")
"   call Decho("clearing marked files",'~'.expand("<slnum>"))
   exe "2match netrwMarkFile /".s:netrwmarkfilemtch_{bufnr("%")}."/"
  endif

  if a:islocal && exists("w:netrw_acdkeep") && w:netrw_acdkeep
   " s:NetrwBrowse : set up "safe" options for local directory/file {{{3
"   call Decho("handle w:netrw_acdkeep:",'~'.expand("<slnum>"))
"   call Decho("NetrwKeepj lcd ".fnameescape(dirname)." (due to w:netrw_acdkeep=".w:netrw_acdkeep." - acd=".&acd.")",'~'.expand("<slnum>"))
   call s:NetrwLcd(dirname)
   call s:NetrwSafeOptions()
"   call Decho("getcwd<".getcwd().">",'~'.expand("<slnum>"))

  elseif !a:islocal && dirname !~ '[\/]$' && dirname !~ '^"'
   " s:NetrwBrowse :  remote regular file handler {{{3
"   call Decho("handle remote regular file: dirname<".dirname.">",'~'.expand("<slnum>"))
   if bufname(dirname) != ""
"    call Decho("edit buf#".bufname(dirname)." in win#".winnr(),'~'.expand("<slnum>"))
    exe "NetrwKeepj b ".bufname(dirname)
   else
    " attempt transfer of remote regular file
"    call Decho("attempt transfer as regular file<".dirname.">",'~'.expand("<slnum>"))

    " remove any filetype indicator from end of dirname, except for the
    " "this is a directory" indicator (/).
    " There shouldn't be one of those here, anyway.
    let path= substitute(dirname,'[*=@|]\r\=$','','e')
"    call Decho("new path<".path.">",'~'.expand("<slnum>"))
    call s:RemotePathAnalysis(dirname)

    " s:NetrwBrowse : remote-read the requested file into current buffer {{{3
    call s:NetrwEnew(dirname)
    call s:NetrwSafeOptions()
    setl ma noro
"    call Decho("setl ma noro",'~'.expand("<slnum>"))
    let b:netrw_curdir = dirname
    let url            = s:method."://".((s:user == "")? "" : s:user."@").s:machine.(s:port ? ":".s:port : "")."/".s:path
"    call Decho("exe sil! keepalt file ".fnameescape(url)." (bt=".&bt.")",'~'.expand("<slnum>"))
    exe "sil! NetrwKeepj keepalt file ".fnameescape(url)
    exe "sil! NetrwKeepj keepalt doau BufReadPre ".fnameescape(s:fname)
    sil call netrw#NetRead(2,url)
    " netrw.vim and tar.vim have already handled decompression of the tarball; avoiding gzip.vim error
"    call Decho("url<".url.">",'~'.expand("<slnum>"))
"    call Decho("s:path<".s:path.">",'~'.expand("<slnum>"))
"    call Decho("s:fname<".s:fname.">",'~'.expand("<slnum>"))
    if s:path =~ '.bz2'
     exe "sil NetrwKeepj keepalt doau BufReadPost ".fnameescape(substitute(s:fname,'\.bz2$','',''))
    elseif s:path =~ '.gz'
     exe "sil NetrwKeepj keepalt doau BufReadPost ".fnameescape(substitute(s:fname,'\.gz$','',''))
    elseif s:path =~ '.gz'
     exe "sil NetrwKeepj keepalt doau BufReadPost ".fnameescape(substitute(s:fname,'\.txz$','',''))
    else
     exe "sil NetrwKeepj keepalt doau BufReadPost ".fnameescape(s:fname)
    endif
   endif

   " s:NetrwBrowse : save certain window-oriented variables into buffer-oriented variables {{{3
   call s:SetBufWinVars()
   call s:NetrwOptionRestore("w:")
"   call Decho("setl ma nomod",'~'.expand("<slnum>"))
   setl ma nomod noro
"   call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))

"   call Dret("s:NetrwBrowse : file<".s:fname.">")
   return
  endif

  " use buffer-oriented WinVars if buffer variables exist but associated window variables don't {{{3
  call s:UseBufWinVars()

  " set up some variables {{{3
  let b:netrw_browser_active = 1
  let dirname                = dirname
  let s:last_sort_by         = g:netrw_sort_by

  " set up menu {{{3
  NetrwKeepj call s:NetrwMenu(1)

  " get/set-up buffer {{{3
"  call Decho("saving position across a buffer refresh",'~'.expand("<slnum>"))
  let svpos  = netrw#SavePosn()
  let reusing= s:NetrwGetBuffer(a:islocal,dirname)

  " maintain markfile highlighting
  if exists("s:netrwmarkfilemtch_{bufnr('%')}") && s:netrwmarkfilemtch_{bufnr("%")} != ""
"   call Decho("bufnr(%)=".bufnr('%'),'~'.expand("<slnum>"))
"   call Decho("exe 2match netrwMarkFile /".s:netrwmarkfilemtch_{bufnr("%")}."/",'~'.expand("<slnum>"))
   exe "2match netrwMarkFile /".s:netrwmarkfilemtch_{bufnr("%")}."/"
  else
"   call Decho("2match none",'~'.expand("<slnum>"))
   2match none
  endif
  if reusing && line("$") > 1
   call s:NetrwOptionRestore("w:")
"   call Decho("setl noma nomod nowrap",'~'.expand("<slnum>"))
   setl noma nomod nowrap
"   call Decho("(set noma nomod nowrap)  ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"   call Dret("s:NetrwBrowse : re-using not-cleared buffer")
   return
  endif

  " set b:netrw_curdir to the new directory name {{{3
"  call Decho("set b:netrw_curdir to the new directory name<".dirname."> (buf#".bufnr("%").")",'~'.expand("<slnum>"))
  let b:netrw_curdir= dirname
  if b:netrw_curdir =~ '[/\\]$'
   let b:netrw_curdir= substitute(b:netrw_curdir,'[/\\]$','','e')
  endif
  if b:netrw_curdir =~ '\a:$' && (has("win32") || has("win95") || has("win64") || has("win16"))
   let b:netrw_curdir= b:netrw_curdir."/"
  endif
  if b:netrw_curdir == ''
   if has("amiga")
    " On the Amiga, the empty string connotes the current directory
    let b:netrw_curdir= getcwd()
   else
    " under unix, when the root directory is encountered, the result
    " from the preceding substitute is an empty string.
    let b:netrw_curdir= '/'
   endif
  endif
  if !a:islocal && b:netrw_curdir !~ '/$'
   let b:netrw_curdir= b:netrw_curdir.'/'
  endif
"  call Decho("b:netrw_curdir<".b:netrw_curdir.">",'~'.expand("<slnum>"))

  " ------------
  " (local only) {{{3
  " ------------
  if a:islocal
"   call Decho("local only:",'~'.expand("<slnum>"))

   " Set up ShellCmdPost handling.  Append current buffer to browselist
   call s:LocalFastBrowser()

  " handle g:netrw_keepdir: set vim's current directory to netrw's notion of the current directory {{{3
   if !g:netrw_keepdir
"    call Decho("handle g:netrw_keepdir=".g:netrw_keepdir.": getcwd<".getcwd()."> acd=".&acd,'~'.expand("<slnum>"))
"    call Decho("l:acd".(exists("&l:acd")? "=".&l:acd : " doesn't exist"),'~'.expand("<slnum>"))
    if !exists("&l:acd") || !&l:acd
     call s:NetrwLcd(b:netrw_curdir)
    endif
   endif

  " --------------------------------
  " remote handling: {{{3
  " --------------------------------
  else
"   call Decho("remote only:",'~'.expand("<slnum>"))

   " analyze dirname and g:netrw_list_cmd {{{3
"   call Decho("b:netrw_curdir<".(exists("b:netrw_curdir")? b:netrw_curdir : "doesn't exist")."> dirname<".dirname.">",'~'.expand("<slnum>"))
   if dirname =~ "^NetrwTreeListing\>"
    let dirname= b:netrw_curdir
"    call Decho("(dirname was <NetrwTreeListing>) dirname<".dirname.">",'~'.expand("<slnum>"))
   elseif exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && exists("b:netrw_curdir")
    let dirname= substitute(b:netrw_curdir,'\\','/','g')
    if dirname !~ '/$'
     let dirname= dirname.'/'
    endif
    let b:netrw_curdir = dirname
"    call Decho("(liststyle is TREELIST) dirname<".dirname.">",'~'.expand("<slnum>"))
   else
    let dirname = substitute(dirname,'\\','/','g')
"    call Decho("(normal) dirname<".dirname.">",'~'.expand("<slnum>"))
   endif

   let dirpat  = '^\(\w\{-}\)://\(\w\+@\)\=\([^/]\+\)/\(.*\)$'
   if dirname !~ dirpat
    if !exists("g:netrw_quiet")
     NetrwKeepj call netrw#ErrorMsg(s:ERROR,"netrw doesn't understand your dirname<".dirname.">",20)
    endif
    NetrwKeepj call s:NetrwOptionRestore("w:")
"    call Decho("setl noma nomod nowrap",'~'.expand("<slnum>"))
    setl noma nomod nowrap
"    call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"    call Dret("s:NetrwBrowse : badly formatted dirname<".dirname.">")
    return
   endif
   let b:netrw_curdir= dirname
"   call Decho("b:netrw_curdir<".b:netrw_curdir."> (remote)",'~'.expand("<slnum>"))
  endif  " (additional remote handling)

  " -----------------------
  " Directory Listing: {{{3
  " -----------------------
  NetrwKeepj call s:NetrwMaps(a:islocal)
  NetrwKeepj call s:NetrwCommands(a:islocal)
  NetrwKeepj call s:PerformListing(a:islocal)

  " If there is a rexposn: restore position with rexposn
  " Otherwise            : set rexposn
  if exists("s:rexposn_".bufnr("%"))
   NetrwKeepj call netrw#RestorePosn(s:rexposn_{bufnr('%')})
  else
   NetrwKeepj call s:SetRexDir(a:islocal,b:netrw_curdir)
  endif
  if v:version >= 700 && has("balloon_eval") && &beval == 0 && &l:bexpr == "" && !exists("g:netrw_nobeval")
   let &l:bexpr= "netrw#BalloonHelp()"
"   call Decho("set up balloon help: l:bexpr=".&l:bexpr,'~'.expand("<slnum>"))
   setl beval
  endif
  call s:NetrwOptionRestore("w:")
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))

  " restore position
  if reusing
"   call Decho("reusing=".reusing.": restoring position across buffer refresh",'~'.expand("<slnum>"))
   call netrw#RestorePosn(svpos)
  endif

  " The s:LocalBrowseRefresh() function is called by an autocmd
  " installed by s:LocalFastBrowser() when g:netrw_fastbrowse <= 1 (ie. slow, medium speed).
  " However, s:NetrwBrowse() causes the FocusGained event to fire the firstt time.
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"  call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"  call Dret("s:NetrwBrowse : did PerformListing  ft<".&ft.">")
  return
endfun

" ---------------------------------------------------------------------
" s:NetrwFile: because of g:netrw_keepdir, isdirectory(), type(), etc may or {{{2
" may not apply correctly; ie. netrw's idea of the current directory may
" differ from vim's.  This function insures that netrw's idea of the current
" directory is used.
fun! s:NetrwFile(fname)
"  call Dfunc("s:NetrwFile(fname<".a:fname.">)")

  if g:netrw_keepdir
   " vim's idea of the current directory possibly may differ from netrw's
   if !exists("b:netrw_curdir")
    let b:netrw_curdir= getcwd()
   endif

   if !exists("g:netrw_cygwin") && (has("win32") || has("win95") || has("win64") || has("win16"))
    if a:fname =~ '^\' || a:fname =~ '^\a:\'
     " windows, but full path given
     let ret= a:fname
"     call Decho("windows+full path: isdirectory(".a:fname.")",'~'.expand("<slnum>"))
    else
     " windows, relative path given
     let ret= s:ComposePath(b:netrw_curdir,a:fname)
"     call Decho("windows+rltv path: isdirectory(".a:fname.")",'~'.expand("<slnum>"))
    endif

   elseif a:fname =~ '^/'
    " not windows, full path given
    let ret= a:fname
"    call Decho("unix+full path: isdirectory(".a:fname.")",'~'.expand("<slnum>"))
   else
    " not windows, relative path given
    let ret= s:ComposePath(b:netrw_curdir,a:fname)
"    call Decho("unix+rltv path: isdirectory(".a:fname.")",'~'.expand("<slnum>"))
   endif
  else
   " vim and netrw agree on the current directory
   let ret= a:fname
"   call Decho("vim and netrw agree on current directory (g:netrw_keepdir=".g:netrw_keepdir.")",'~'.expand("<slnum>"))
  endif

"  call Dret("s:NetrwFile ".ret)
  return ret
endfun

" ---------------------------------------------------------------------
" s:NetrwFileInfo: supports qf (query for file information) {{{2
fun! s:NetrwFileInfo(islocal,fname)
"  call Dfunc("s:NetrwFileInfo(islocal=".a:islocal." fname<".a:fname.">) b:netrw_curdir<".b:netrw_curdir.">")
  let ykeep= @@
  if a:islocal
   if (has("unix") || has("macunix")) && executable("/bin/ls")

    if getline(".") == "../"
     echo system("/bin/ls -lsad ".shellescape(".."))
"     call Decho("#1: echo system(/bin/ls -lsad ".shellescape(..).")",'~'.expand("<slnum>"))

    elseif w:netrw_liststyle == s:TREELIST && getline(".") !~ '^'.s:treedepthstring
     echo system("/bin/ls -lsad ".shellescape(b:netrw_curdir))
"     call Decho("#2: echo system(/bin/ls -lsad ".shellescape(b:netrw_curdir).")",'~'.expand("<slnum>"))

    elseif exists("b:netrw_curdir")
      echo system("/bin/ls -lsad ".shellescape(s:ComposePath(b:netrw_curdir,a:fname)))
"      call Decho("#3: echo system(/bin/ls -lsad ".shellescape(b:netrw_curdir.a:fname).")",'~'.expand("<slnum>"))

    else
"     call Decho('using ls '.a:fname." using cwd<".getcwd().">",'~'.expand("<slnum>"))
     echo system("/bin/ls -lsad ".shellescape(s:NetrwFile(a:fname)))
"     call Decho("#5: echo system(/bin/ls -lsad ".shellescape(a:fname).")",'~'.expand("<slnum>"))
    endif
   else
    " use vim functions to return information about file below cursor
"    call Decho("using vim functions to query for file info",'~'.expand("<slnum>"))
    if !isdirectory(s:NetrwFile(a:fname)) && !filereadable(s:NetrwFile(a:fname)) && a:fname =~ '[*@/]'
     let fname= substitute(a:fname,".$","","")
    else
     let fname= a:fname
    endif
    let t  = getftime(s:NetrwFile(fname))
    let sz = getfsize(s:NetrwFile(fname))
    echo a:fname.":  ".sz."  ".strftime(g:netrw_timefmt,getftime(s:NetrwFile(fname)))
"    call Decho("fname.":  ".sz."  ".strftime(g:netrw_timefmt,getftime(fname)),'~'.expand("<slnum>"))
   endif
  else
   echo "sorry, \"qf\" not supported yet for remote files"
  endif
  let @@= ykeep
"  call Dret("s:NetrwFileInfo")
endfun

" ---------------------------------------------------------------------
" s:NetrwGetBuffer: {{{2
"   returns 0=cleared buffer
"           1=re-used buffer (buffer not cleared)
fun! s:NetrwGetBuffer(islocal,dirname)
"  call Dfunc("s:NetrwGetBuffer(islocal=".a:islocal." dirname<".a:dirname.">) liststyle=".g:netrw_liststyle)
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
  let dirname= a:dirname

  " re-use buffer if possible {{{3
"  call Decho("--re-use a buffer if possible--",'~'.expand("<slnum>"))
  if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST
   " find NetrwTreeList buffer if there is one
"   call Decho("case liststyle=treelist: find NetrwTreeList buffer if there is one",'~'.expand("<slnum>"))
   if exists("w:netrw_treebufnr") && w:netrw_treebufnr > 0
"    call Decho("  re-using w:netrw_treebufnr=".w:netrw_treebufnr,'~'.expand("<slnum>"))
    let eikeep= &ei
    setl ei=all
    exe "sil! keepj noswapfile keepalt b ".w:netrw_treebufnr
    let &ei= eikeep
    setl ma
    sil! NetrwKeepj %d _
"    call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"    call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"    call Dret("s:NetrwGetBuffer 0<buffer cleared> : bufnum#".w:netrw_treebufnr."<NetrwTreeListing>")
    return 0
   endif
   let bufnum= -1
"   call Decho("  liststyle=TREE but w:netrw_treebufnr doesn't exist",'~'.expand("<slnum>"))

  else
   " find buffer number of buffer named precisely the same as dirname {{{3
"   call Decho("case listtyle not treelist: find buffer numnber of buffer named precisely the same as dirname--",'~'.expand("<slnum>"))
"   call Dredir("(NetrwGetBuffer) ls!","ls!")

   " get dirname and associated buffer number
   let bufnum  = bufnr(escape(dirname,'\'))
"   call Decho("  find buffer<".dirname.">'s number ",'~'.expand("<slnum>"))
"   call Decho("  bufnr(dirname<".escape(dirname,'\').">)=".bufnum,'~'.expand("<slnum>"))

   if bufnum < 0 && dirname !~ '/$'
    " try appending a trailing /
"    call Decho("  try appending a trailing / to dirname<".dirname.">",'~'.expand("<slnum>"))
    let bufnum= bufnr(escape(dirname.'/','\'))
    if bufnum > 0
     let dirname= dirname.'/'
    endif
   endif

   if bufnum < 0 && dirname =~ '/$'
    " try removing a trailing /
"    call Decho("  try removing a trailing / from dirname<".dirname.">",'~'.expand("<slnum>"))
    let bufnum= bufnr(escape(substitute(dirname,'/$','',''),'\'))
    if bufnum > 0
     let dirname= substitute(dirname,'/$','','')
    endif
   endif

"   call Decho("  findbuf1: bufnum=bufnr('".dirname."')=".bufnum." bufname(".bufnum.")<".bufname(bufnum)."> (initial)",'~'.expand("<slnum>"))
   " note: !~ was used just below, but that means using ../ to go back would match (ie. abc/def/  and abc/ matches)
   if bufnum > 0 && bufname(bufnum) != dirname && bufname(bufnum) != '.'
    " handle approximate matches
"    call Decho("  handling approx match: bufnum#".bufnum.">0 AND bufname<".bufname(bufnum).">!=dirname<".dirname."> AND bufname(".bufnum.")!='.'",'~'.expand("<slnum>"))
    let ibuf    = 1
    let buflast = bufnr("$")
"    call Decho("  findbuf2: buflast=bufnr($)=".buflast,'~'.expand("<slnum>"))
    while ibuf <= buflast
     let bname= substitute(bufname(ibuf),'\\','/','g')
     let bname= substitute(bname,'.\zs/$','','')
"     call Decho("  findbuf3: while [ibuf=",ibuf."]<=[buflast=".buflast."]: dirname<".dirname."> bname=bufname(".ibuf.")<".bname.">",'~'.expand("<slnum>"))
     if bname != '' && dirname =~ '/'.bname.'/\=$' && dirname !~ '^/'
      " bname is not empty
      " dirname ends with bname,
      " dirname doesn't start with /, so its not a absolute path
"      call Decho("  findbuf3a: passes test 1 : dirname<".dirname.'> =~ /'.bname.'/\=$ && dirname !~ ^/','~'.expand("<slnum>"))
      break
     endif
     if bname =~ '^'.dirname.'/\=$'
      " bname begins with dirname
"      call Decho('  findbuf3b: passes test 2 : bname<'.bname.'>=~^'.dirname.'/\=$','~'.expand("<slnum>"))
      break
     endif
     if dirname =~ '^'.bname.'/$'
"      call Decho('  findbuf3c: passes test 3 : dirname<'.dirname.'>=~^'.bname.'/$','~'.expand("<slnum>"))
      break
     endif
     if bname != '' && dirname =~ '/'.bname.'$' && bname == bufname("%") && line("$") == 1
"      call Decho('  findbuf3d: passes test 4 : dirname<'.dirname.'>=~ /'.bname.'$','~'.expand("<slnum>"))
      break
     endif
     let ibuf= ibuf + 1
    endwhile
    if ibuf > buflast
     let bufnum= -1
    else
     let bufnum= ibuf
    endif
"    call Decho("  findbuf4: bufnum=".bufnum." (ibuf=".ibuf." buflast=".buflast.")",'~'.expand("<slnum>"))
   endif
  endif

  " get enew buffer and name it -or- re-use buffer {{{3
  if bufnum < 0 || !bufexists(bufnum)   " get enew buffer and name it
"   call Decho("--get enew buffer and name it  (bufnum#".bufnum."<0 OR bufexists(".bufnum.")=".bufexists(bufnum)."==0)",'~'.expand("<slnum>"))
   call s:NetrwEnew(dirname)
"   call Decho("  got enew buffer#".bufnr("%")." (altbuf<".expand("#").">)",'~'.expand("<slnum>"))
   " name the buffer
   if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST
    " Got enew buffer; transform into a NetrwTreeListing
"    call Decho("--transform enew buffer#".bufnr("%")." into a NetrwTreeListing --",'~'.expand("<slnum>"))
    if !exists("s:netrw_treelistnum")
     let s:netrw_treelistnum= 1
    else
     let s:netrw_treelistnum= s:netrw_treelistnum + 1
    endif
    let w:netrw_treebufnr= bufnr("%")
"    call Decho("  exe sil! keepalt file NetrwTreeListing ".fnameescape(s:netrw_treelistnum),'~'.expand("<slnum>"))
    exe 'sil! keepalt file NetrwTreeListing\ '.fnameescape(s:netrw_treelistnum)
    setl bt=nofile noswf
    nnoremap <silent> <buffer> [	:sil call <SID>TreeListMove('[')<cr>
    nnoremap <silent> <buffer> ]	:sil call <SID>TreeListMove(']')<cr>
    nnoremap <silent> <buffer> [[       :sil call <SID>TreeListMove('[')<cr>
    nnoremap <silent> <buffer> ]]       :sil call <SID>TreeListMove(']')<cr>
"    call Decho("  tree listing#".s:netrw_treelistnum." bufnr=".w:netrw_treebufnr,'~'.expand("<slnum>"))
   else
"    let v:errmsg   = "" " Decho
    let escdirname = fnameescape(dirname)
"    call Decho("  errmsg<".v:errmsg."> bufnr(escdirname<".escdirname.">)=".bufnr(escdirname)." bufname()<".bufname(bufnr(escdirname)).">",'~'.expand("<slnum>"))
"    call Decho('  exe sil! keepalt file '.escdirname,'~'.expand("<slnum>"))
"    let v:errmsg= "" " Decho
    exe 'sil! keepj keepalt file '.escdirname
"    call Decho("  errmsg<".v:errmsg."> bufnr(".escdirname.")=".bufnr(escdirname)."<".bufname(bufnr(escdirname)).">",'~'.expand("<slnum>"))
   endif
"   call Decho("  named enew buffer#".bufnr("%")."<".bufname("%").">",'~'.expand("<slnum>"))

  else " Re-use the buffer
"   call Decho("--re-use buffer#".bufnum." (bufnum#".bufnum.">=0 AND bufexists(".bufnum.")=".bufexists(bufnum)."!=0)",'~'.expand("<slnum>"))
   let eikeep= &ei
   setl ei=all
   if getline(2) =~ '^" Netrw Directory Listing'
"    call Decho("  getline(2)<".getline(2).'> matches "Netrw Directory Listing" : using keepalt b '.bufnum,'~'.expand("<slnum>"))
    exe "sil! NetrwKeepj noswapfile keepalt b ".bufnum
   else
"    call Decho("  getline(2)<".getline(2).'> does not match "Netrw Directory Listing" : using b '.bufnum,'~'.expand("<slnum>"))
    exe "sil! NetrwKeepj noswapfile keepalt b ".bufnum
   endif
"   call Decho("  line($)=".line("$"),'~'.expand("<slnum>"))
   if bufname("%") == '.'
"    call Decho("exe sil! keepalt file ".fnameescape(getcwd()),'~'.expand("<slnum>"))
    exe "sil! NetrwKeepj keepalt file ".fnameescape(getcwd())
   endif
   let &ei= eikeep

   if line("$") <= 1 && getline(1) == ""
    " empty buffer
    NetrwKeepj call s:NetrwListSettings(a:islocal)
"    call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"    call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"    call Dret("s:NetrwGetBuffer 0<buffer empty> : re-using buffer#".bufnr("%").", but its empty, so refresh it")
    return 0

   elseif g:netrw_fastbrowse == 0 || (a:islocal && g:netrw_fastbrowse == 1)
"    call Decho("g:netrw_fastbrowse=".g:netrw_fastbrowse." a:islocal=".a:islocal.": clear buffer",'~'.expand("<slnum>"))
    NetrwKeepj call s:NetrwListSettings(a:islocal)
    sil NetrwKeepj %d _
"    call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"    call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"    call Dret("s:NetrwGetBuffer 0<cleared buffer> : re-using buffer#".bufnr("%").", but refreshing due to g:netrw_fastbrowse=".g:netrw_fastbrowse)
    return 0

   elseif exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST
"    call Decho("--re-use tree listing--",'~'.expand("<slnum>"))
"    call Decho("  clear buffer<".expand("%")."> with :%d",'~'.expand("<slnum>"))
    sil NetrwKeepj %d _
    NetrwKeepj call s:NetrwListSettings(a:islocal)
"    call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"    call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"    call Dret("s:NetrwGetBuffer 0<cleared buffer> : re-using buffer#".bufnr("%").", but treelist mode always needs a refresh")
    return 0

   else
"    call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"    call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"    call Dret("s:NetrwGetBuffer 1<buffer not cleared>")
    return 1
   endif
  endif

  " do netrw settings: make this buffer not-a-file, modifiable, not line-numbered, etc {{{3
  "     fastbrowse  Local  Remote   Hiding a buffer implies it may be re-used (fast)
  "  slow   0         D      D      Deleting a buffer implies it will not be re-used (slow)
  "  med    1         D      H
  "  fast   2         H      H
"  call Decho("--do netrw settings: make this buffer#".bufnr("%")." not-a-file, modifiable, not line-numbered, etc--",'~'.expand("<slnum>"))
  let fname= expand("%")
  NetrwKeepj call s:NetrwListSettings(a:islocal)
"  call Decho("exe sil! keepalt file ".fnameescape(fname),'~'.expand("<slnum>"))
  exe "sil! NetrwKeepj keepalt file ".fnameescape(fname)

  " delete all lines from buffer {{{3
"  call Decho("--delete all lines from buffer--",'~'.expand("<slnum>"))
"  call Decho("  clear buffer<".expand("%")."> with :%d",'~'.expand("<slnum>"))
  sil! keepalt NetrwKeepj %d _

"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"  call Dret("s:NetrwGetBuffer 0<cleared buffer>")
  return 0
endfun

" ---------------------------------------------------------------------
" s:NetrwGetcwd: get the current directory. {{{2
"   Change backslashes to forward slashes, if any.
"   If doesc is true, escape certain troublesome characters
fun! s:NetrwGetcwd(doesc)
"  call Dfunc("NetrwGetcwd(doesc=".a:doesc.")")
  let curdir= substitute(getcwd(),'\\','/','ge')
  if curdir !~ '[\/]$'
   let curdir= curdir.'/'
  endif
  if a:doesc
   let curdir= fnameescape(curdir)
  endif
"  call Dret("NetrwGetcwd <".curdir.">")
  return curdir
endfun

" ---------------------------------------------------------------------
"  s:NetrwGetWord: it gets the directory/file named under the cursor {{{2
fun! s:NetrwGetWord()
"  call Dfunc("s:NetrwGetWord() liststyle=".s:ShowStyle()." virtcol=".virtcol("."))
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
  let keepsol= &l:sol
  setl nosol

  call s:UseBufWinVars()

  " insure that w:netrw_liststyle is set up
  if !exists("w:netrw_liststyle")
   if exists("g:netrw_liststyle")
    let w:netrw_liststyle= g:netrw_liststyle
   else
    let w:netrw_liststyle= s:THINLIST
   endif
"   call Decho("w:netrw_liststyle=".w:netrw_liststyle,'~'.expand("<slnum>"))
  endif

  if exists("w:netrw_bannercnt") && line(".") < w:netrw_bannercnt
   " Active Banner support
"   call Decho("active banner handling",'~'.expand("<slnum>"))
   NetrwKeepj norm! 0
   let dirname= "./"
   let curline= getline('.')

   if curline =~ '"\s*Sorted by\s'
    NetrwKeepj norm s
    let s:netrw_skipbrowse= 1
    echo 'Pressing "s" also works'

   elseif curline =~ '"\s*Sort sequence:'
    let s:netrw_skipbrowse= 1
    echo 'Press "S" to edit sorting sequence'

   elseif curline =~ '"\s*Quick Help:'
    NetrwKeepj norm ?
    let s:netrw_skipbrowse= 1

   elseif curline =~ '"\s*\%(Hiding\|Showing\):'
    NetrwKeepj norm a
    let s:netrw_skipbrowse= 1
    echo 'Pressing "a" also works'

   elseif line("$") > w:netrw_bannercnt
    exe 'sil NetrwKeepj '.w:netrw_bannercnt
   endif

  elseif w:netrw_liststyle == s:THINLIST
"   call Decho("thin column handling",'~'.expand("<slnum>"))
   NetrwKeepj norm! 0
   let dirname= substitute(getline('.'),'\t -->.*$','','')

  elseif w:netrw_liststyle == s:LONGLIST
"   call Decho("long column handling",'~'.expand("<slnum>"))
   NetrwKeepj norm! 0
   let dirname= substitute(getline('.'),'^\(\%(\S\+ \)*\S\+\).\{-}$','\1','e')

  elseif w:netrw_liststyle == s:TREELIST
"   call Decho("treelist handling",'~'.expand("<slnum>"))
   let dirname= substitute(getline('.'),'^\('.s:treedepthstring.'\)*','','e')
   let dirname= substitute(dirname,'\t -->.*$','','')

  else
"   call Decho("obtain word from wide listing",'~'.expand("<slnum>"))
   let dirname= getline('.')

   if !exists("b:netrw_cpf")
    let b:netrw_cpf= 0
    exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$g/^./if virtcol("$") > b:netrw_cpf|let b:netrw_cpf= virtcol("$")|endif'
    call histdel("/",-1)
"   "call Decho("computed cpf=".b:netrw_cpf,'~'.expand("<slnum>"))
   endif

"   call Decho("buf#".bufnr("%")."<".bufname("%").">",'~'.expand("<slnum>"))
   let filestart = (virtcol(".")/b:netrw_cpf)*b:netrw_cpf
"   call Decho("filestart= ([virtcol=".virtcol(".")."]/[b:netrw_cpf=".b:netrw_cpf."])*b:netrw_cpf=".filestart."  bannercnt=".w:netrw_bannercnt,'~'.expand("<slnum>"))
"   call Decho("1: dirname<".dirname.">",'~'.expand("<slnum>"))
   if filestart == 0
    NetrwKeepj norm! 0ma
   else
    call cursor(line("."),filestart+1)
    NetrwKeepj norm! ma
   endif
   let rega= @a
   let eofname= filestart + b:netrw_cpf + 1
   if eofname <= col("$")
    call cursor(line("."),filestart+b:netrw_cpf+1)
    NetrwKeepj norm! "ay`a
   else
    NetrwKeepj norm! "ay$
   endif
   let dirname = @a
   let @a      = rega
"   call Decho("2: dirname<".dirname.">",'~'.expand("<slnum>"))
   let dirname= substitute(dirname,'\s\+$','','e')
"   call Decho("3: dirname<".dirname.">",'~'.expand("<slnum>"))
  endif

  " symlinks are indicated by a trailing "@".  Remove it before further processing.
  let dirname= substitute(dirname,"@$","","")

  " executables are indicated by a trailing "*".  Remove it before further processing.
  let dirname= substitute(dirname,"\*$","","")

  let &l:sol= keepsol

"  call Dret("s:NetrwGetWord <".dirname.">")
  return dirname
endfun

" ---------------------------------------------------------------------
" s:NetrwListSettings: make standard settings for a netrw listing {{{2
fun! s:NetrwListSettings(islocal)
"  call Dfunc("s:NetrwListSettings(islocal=".a:islocal.")")
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
  let fname= bufname("%")
"  "  call Decho("(NetrwListSettings) setl bt=nofile nobl ma nonu nowrap noro nornu",'~'.expand("<slnum>"))
  setl bt=nofile nobl ma nonu nowrap noro nornu
"  call Decho("(NetrwListSettings) exe sil! keepalt file ".fnameescape(fname),'~'.expand("<slnum>"))
  exe "sil! keepalt file ".fnameescape(fname)
  if g:netrw_use_noswf
   setl noswf
  endif
"  call Dredir("ls!")
"  call Decho("(NetrwListSettings) exe setl ts=".(g:netrw_maxfilenamelen+1),'~'.expand("<slnum>"))
  exe "setl ts=".(g:netrw_maxfilenamelen+1)
  setl isk+=.,~,-
  if g:netrw_fastbrowse > a:islocal
   setl bh=hide
  else
   setl bh=delete
  endif
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"  call Dret("s:NetrwListSettings")
endfun

" ---------------------------------------------------------------------
"  s:NetrwListStyle: {{{2
"  islocal=0: remote browsing
"         =1: local browsing
fun! s:NetrwListStyle(islocal)
"  call Dfunc("NetrwListStyle(islocal=".a:islocal.") w:netrw_liststyle=".w:netrw_liststyle)

  let ykeep             = @@
  let fname             = s:NetrwGetWord()
  if !exists("w:netrw_liststyle")|let w:netrw_liststyle= g:netrw_liststyle|endif
  let svpos            = netrw#SavePosn()
  let w:netrw_liststyle = (w:netrw_liststyle + 1) % s:MAXLIST
"  call Decho("fname<".fname.">",'~'.expand("<slnum>"))
"  call Decho("chgd w:netrw_liststyle to ".w:netrw_liststyle,'~'.expand("<slnum>"))
"  call Decho("b:netrw_curdir<".(exists("b:netrw_curdir")? b:netrw_curdir : "doesn't exist").">",'~'.expand("<slnum>"))

  if w:netrw_liststyle == s:THINLIST
   " use one column listing
"   call Decho("use one column list",'~'.expand("<slnum>"))
   let g:netrw_list_cmd = substitute(g:netrw_list_cmd,' -l','','ge')

  elseif w:netrw_liststyle == s:LONGLIST
   " use long list
"   call Decho("use long list",'~'.expand("<slnum>"))
   let g:netrw_list_cmd = g:netrw_list_cmd." -l"

  elseif w:netrw_liststyle == s:WIDELIST
   " give wide list
"   call Decho("use wide list",'~'.expand("<slnum>"))
   let g:netrw_list_cmd = substitute(g:netrw_list_cmd,' -l','','ge')

  elseif w:netrw_liststyle == s:TREELIST
"   call Decho("use tree list",'~'.expand("<slnum>"))
   let g:netrw_list_cmd = substitute(g:netrw_list_cmd,' -l','','ge')

  else
   NetrwKeepj call netrw#ErrorMsg(s:WARNING,"bad value for g:netrw_liststyle (=".w:netrw_liststyle.")",46)
   let g:netrw_liststyle = s:THINLIST
   let w:netrw_liststyle = g:netrw_liststyle
   let g:netrw_list_cmd  = substitute(g:netrw_list_cmd,' -l','','ge')
  endif
  setl ma noro
"  call Decho("setl ma noro",'~'.expand("<slnum>"))

  " clear buffer - this will cause NetrwBrowse/LocalBrowseCheck to do a refresh
"  call Decho("clear buffer<".expand("%")."> with :%d",'~'.expand("<slnum>"))
  sil! NetrwKeepj %d _
  " following prevents tree listing buffer from being marked "modified"
"  call Decho("setl nomod",'~'.expand("<slnum>"))
  setl nomod
"  call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))

  " refresh the listing
"  call Decho("refresh the listing",'~'.expand("<slnum>"))
  NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  NetrwKeepj call s:NetrwCursor()

  " restore position; keep cursor on the filename
  NetrwKeepj call netrw#RestorePosn(svpos)
  let @@= ykeep

"  call Dret("NetrwListStyle".(exists("w:netrw_liststyle")? ' : w:netrw_liststyle='.w:netrw_liststyle : ""))
endfun

" ---------------------------------------------------------------------
" s:NetrwBannerCtrl: toggles the display of the banner {{{2
fun! s:NetrwBannerCtrl(islocal)
"  call Dfunc("s:NetrwBannerCtrl(islocal=".a:islocal.") g:netrw_banner=".g:netrw_banner)

  let ykeep= @@
  " toggle the banner (enable/suppress)
  let g:netrw_banner= !g:netrw_banner

  " refresh the listing
  let svpos= netrw#SavePosn()
  call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))

  " keep cursor on the filename
  let fname= s:NetrwGetWord()
  sil NetrwKeepj $
  let result= search('\%(^\%(|\+\s\)\=\|\s\{2,}\)\zs'.escape(fname,'.\[]*$^').'\%(\s\{2,}\|$\)','bc')
"  call Decho("search result=".result." w:netrw_bannercnt=".(exists("w:netrw_bannercnt")? w:netrw_bannercnt : 'N/A'),'~'.expand("<slnum>"))
  if result <= 0 && exists("w:netrw_bannercnt")
   exe "NetrwKeepj ".w:netrw_bannercnt
  endif
  let @@= ykeep
"  call Dret("s:NetrwBannerCtrl : g:netrw_banner=".g:netrw_banner)
endfun

" ---------------------------------------------------------------------
" s:NetrwBookmark: supports :NetrwMB[!] [file]s                 {{{2
"
"  No bang: enters files/directories into Netrw's bookmark system
"   No argument and in netrw buffer:
"     if there are marked files: bookmark marked files
"     otherwise                : bookmark file/directory under cursor
"   No argument and not in netrw buffer: bookmarks current open file
"   Has arguments: globs them individually and bookmarks them
"
"  With bang: deletes files/directories from Netrw's bookmark system
fun! s:NetrwBookmark(del,...)
"  call Dfunc("s:NetrwBookmark(del=".a:del.",...) a:0=".a:0)
  if a:0 == 0
   if &ft == "netrw"
    let curbufnr = bufnr("%")

    if exists("s:netrwmarkfilelist_{curbufnr}")
     " for every filename in the marked list
"     call Decho("bookmark every filename in marked list",'~'.expand("<slnum>"))
     let svpos  = netrw#SavePosn()
     let islocal= expand("%") !~ '^\a\{3,}://'
     for fname in s:netrwmarkfilelist_{curbufnr}
      if a:del|call s:DeleteBookmark(fname)|else|call s:MakeBookmark(fname)|endif
     endfor
     let curdir  = exists("b:netrw_curdir")? b:netrw_curdir : getcwd()
     call s:NetrwUnmarkList(curbufnr,curdir)
     NetrwKeepj call s:NetrwRefresh(islocal,s:NetrwBrowseChgDir(islocal,'./'))
     NetrwKeepj call netrw#RestorePosn(svpos)
    else
     let fname= s:NetrwGetWord()
     if a:del|call s:DeleteBookmark(fname)|else|call s:MakeBookmark(fname)|endif
    endif

   else
    " bookmark currently open file
"    call Decho("bookmark currently open file",'~'.expand("<slnum>"))
    let fname= expand("%")
    if a:del|call s:DeleteBookmark(fname)|else|call s:MakeBookmark(fname)|endif
   endif

  else
   " bookmark specified files
   "  attempts to infer if working remote or local
   "  by deciding if the current file begins with an url
   "  Globbing cannot be done remotely.
   let islocal= expand("%") !~ '^\a\{3,}://'
"   call Decho("bookmark specified file".((a:0>1)? "s" : ""),'~'.expand("<slnum>"))
   let i = 1
   while i <= a:0
    if islocal
     if v:version == 704 && has("patch656")
      let mbfiles= glob(a:{i},0,1,1)
     else
      let mbfiles= glob(a:{i},0,1)
     endif
    else
     let mbfiles= [a:{i}]
    endif
"    call Decho("mbfiles".string(mbfiles),'~'.expand("<slnum>"))
    for mbfile in mbfiles
"     call Decho("mbfile<".mbfile.">",'~'.expand("<slnum>"))
     if a:del|call s:DeleteBookmark(mbfile)|else|call s:MakeBookmark(mbfile)|endif
    endfor
    let i= i + 1
   endwhile
  endif

  " update the menu
  call s:NetrwBookmarkMenu()

"  call Dret("s:NetrwBookmark")
endfun

" ---------------------------------------------------------------------
" s:NetrwBookmarkMenu: Uses menu priorities {{{2
"                      .2.[cnt] for bookmarks, and
"                      .3.[cnt] for history
"                      (see s:NetrwMenu())
fun! s:NetrwBookmarkMenu()
  if !exists("s:netrw_menucnt")
   return
  endif
"  call Dfunc("NetrwBookmarkMenu()  histcnt=".g:netrw_dirhist_cnt." menucnt=".s:netrw_menucnt)

  " the following test assures that gvim is running, has menus available, and has menus enabled.
  if has("gui") && has("menu") && has("gui_running") && &go =~# 'm' && g:netrw_menu
   if exists("g:NetrwTopLvlMenu")
"    call Decho("removing ".g:NetrwTopLvlMenu."Bookmarks menu item(s)",'~'.expand("<slnum>"))
    exe 'sil! unmenu '.g:NetrwTopLvlMenu.'Bookmarks'
    exe 'sil! unmenu '.g:NetrwTopLvlMenu.'Bookmarks\ and\ History.Bookmark\ Delete'
   endif
   if !exists("s:netrw_initbookhist")
    call s:NetrwBookHistRead()
   endif

   " show bookmarked places
   if exists("g:netrw_bookmarklist") && g:netrw_bookmarklist != [] && g:netrw_dirhistmax > 0
    let cnt= 1
    for bmd in g:netrw_bookmarklist
"     call Decho('sil! menu '.g:NetrwMenuPriority.".2.".cnt." ".g:NetrwTopLvlMenu.'Bookmark.'.bmd.'	:e '.bmd,'~'.expand("<slnum>"))
     let bmd= escape(bmd,g:netrw_menu_escape)

     " show bookmarks for goto menu
     exe 'sil! menu '.g:NetrwMenuPriority.".2.".cnt." ".g:NetrwTopLvlMenu.'Bookmarks.'.bmd.'	:e '.bmd."\<cr>"

     " show bookmarks for deletion menu
     exe 'sil! menu '.g:NetrwMenuPriority.".8.2.".cnt." ".g:NetrwTopLvlMenu.'Bookmarks\ and\ History.Bookmark\ Delete.'.bmd.'	'.cnt."mB"
     let cnt= cnt + 1
    endfor

   endif

   " show directory browsing history
   if g:netrw_dirhistmax > 0
    let cnt     = g:netrw_dirhist_cnt
    let first   = 1
    let histcnt = 0
    while ( first || cnt != g:netrw_dirhist_cnt )
     let histcnt  = histcnt + 1
     let priority = g:netrw_dirhist_cnt + histcnt
     if exists("g:netrw_dirhist_{cnt}")
      let histdir= escape(g:netrw_dirhist_{cnt},g:netrw_menu_escape)
"     call Decho('sil! menu '.g:NetrwMenuPriority.".3.".priority." ".g:NetrwTopLvlMenu.'History.'.histdir.'	:e '.histdir,'~'.expand("<slnum>"))
      exe 'sil! menu '.g:NetrwMenuPriority.".3.".priority." ".g:NetrwTopLvlMenu.'History.'.histdir.'	:e '.histdir."\<cr>"
     endif
     let first = 0
     let cnt   = ( cnt - 1 ) % g:netrw_dirhistmax
     if cnt < 0
      let cnt= cnt + g:netrw_dirhistmax
     endif
    endwhile
   endif

  endif
"  call Dret("NetrwBookmarkMenu")
endfun

" ---------------------------------------------------------------------
"  s:NetrwBrowseChgDir: constructs a new directory based on the current {{{2
"                       directory and a new directory name.  Also, if the
"                       "new directory name" is actually a file,
"                       NetrwBrowseChgDir() edits the file.
fun! s:NetrwBrowseChgDir(islocal,newdir,...)
"  call Dfunc("s:NetrwBrowseChgDir(islocal=".a:islocal."> newdir<".a:newdir.">) a:0=".a:0." curpos<".string(getpos("."))."> b:netrw_curdir<".(exists("b:netrw_curdir")? b:netrw_curdir : "").">")
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))

  let ykeep= @@
  if !exists("b:netrw_curdir")
   " Don't try to change-directory: this can happen, for example, when netrw#ErrorMsg has been called
   " and the current window is the NetrwMessage window.
   let @@= ykeep
"   call Decho("b:netrw_curdir doesn't exist!",'~'.expand("<slnum>"))
"   call Decho("getcwd<".getcwd().">",'~'.expand("<slnum>"))
"   call Dredir("ls!")
"   call Dret("s:NetrwBrowseChgDir")
   return
  endif

  " NetrwBrowseChgDir: save options and initialize {{{3
"  call Decho("saving options",'~'.expand("<slnum>"))
  NetrwKeepj call s:NetrwOptionSave("s:")
  NetrwKeepj call s:NetrwSafeOptions()
  let nbcd_curpos                = netrw#SavePosn()
  let s:nbcd_curpos_{bufnr('%')} = nbcd_curpos
"  call Decho("setting s:nbcd_curpos_".bufnr('%')." to SavePosn",'~'.expand("<slnum>"))
  if (has("win32") || has("win95") || has("win64") || has("win16"))
   let dirname = substitute(b:netrw_curdir,'\\','/','ge')
  else
   let dirname = b:netrw_curdir
  endif
  let newdir    = a:newdir
  let dolockout = 0
  let dorestore = 1
"  call Decho("dirname<".dirname.">",'~'.expand("<slnum>"))

  " ignore <cr>s when done in the banner
"  call Decho('ignore [return]s when done in banner (g:netrw_banner='.g:netrw_banner.")",'~'.expand("<slnum>"))
  if g:netrw_banner
"   call Decho("w:netrw_bannercnt=".(exists("w:netrw_bannercnt")? w:netrw_bannercnt : 'n/a')." line(.)#".line('.')." line($)#".line("#"),'~'.expand("<slnum>"))
   if exists("w:netrw_bannercnt") && line(".") < w:netrw_bannercnt && line("$") >= w:netrw_bannercnt
    if getline(".") =~ 'Quick Help'
"     call Decho("#1: quickhelp=".g:netrw_quickhelp." ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
     let g:netrw_quickhelp= (g:netrw_quickhelp + 1)%len(s:QuickHelp)
"     call Decho("#2: quickhelp=".g:netrw_quickhelp." ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
     setl ma noro nowrap
     NetrwKeepj call setline(line('.'),'"   Quick Help: <F1>:help  '.s:QuickHelp[g:netrw_quickhelp])
     setl noma nomod nowrap
     NetrwKeepj call netrw#RestorePosn(nbcd_curpos)
     NetrwKeepj call s:NetrwOptionRestore("s:")
"     call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
    endif
   endif
"  else " Decho
"   call Decho("(s:NetrwBrowseChgdir) g:netrw_banner=".g:netrw_banner." (no banner)",'~'.expand("<slnum>"))
  endif

  " set up o/s-dependent directory recognition pattern
  if has("amiga")
   let dirpat= '[\/:]$'
  else
   let dirpat= '[\/]$'
  endif
"  call Decho("set up o/s-dependent directory recognition pattern: dirname<".dirname.">  dirpat<".dirpat.">",'~'.expand("<slnum>"))

  if dirname !~ dirpat
   " apparently vim is "recognizing" that it is in a directory and
   " is removing the trailing "/".  Bad idea, so let's put it back.
   let dirname= dirname.'/'
"   call Decho("adjusting dirname<".dirname.'>  (put trailing "/" back)','~'.expand("<slnum>"))
  endif

"  "  call Decho("[newdir<".newdir."> ".((newdir =~ dirpat)? "=~" : "!~")." dirpat<".dirpat.">] && [islocal=".a:islocal."] && [newdir is ".(isdirectory(s:NetrwFile(newdir))? "" : "not ")."a directory]",'~'.expand("<slnum>"))
  if newdir !~ dirpat && !(a:islocal && isdirectory(s:NetrwFile(s:ComposePath(dirname,newdir))))
   " ------------------------------
   " NetrwBrowseChgDir: edit a file {{{3
   " ------------------------------
"   call Decho('edit-a-file: case "handling a file": newdir<'.newdir.'> !~ dirpat<'.dirpat.">",'~'.expand("<slnum>"))

   " save position for benefit of Rexplore
   let s:rexposn_{bufnr("%")}= netrw#SavePosn()
"   call Decho("edit-a-file: setting s:rexposn_".bufnr("%")."<".bufname("%")."> to SavePosn",'~'.expand("<slnum>"))
"   call Decho("edit-a-file: win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> ft=".&ft,'~'.expand("<slnum>"))
"   call Decho("edit-a-file: w:netrw_liststyle=".(exists("w:netrw_liststyle")? w:netrw_liststyle : 'n/a')." w:netrw_treedict:".(exists("w:netrw_treedict")? "exists" : 'n/a')." newdir<".newdir.">",'~'.expand("<slnum>"))

   if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && exists("w:netrw_treedict") && newdir !~ '^\(/\|\a:\)'
"    call Decho("edit-a-file: handle tree listing: w:netrw_treedict<".(exists("w:netrw_treedict")? string(w:netrw_treedict) : 'n/a').">",'~'.expand("<slnum>"))
"    call Decho("edit-a-file: newdir<".newdir.">",'~'.expand("<slnum>"))
    let dirname= s:NetrwTreeDir(a:islocal)
    if dirname =~ '/$'
     let dirname= dirname.newdir
    else
     let dirname= dirname."/".newdir
    endif
"    call Decho("edit-a-file: dirname<".dirname.">",'~'.expand("<slnum>"))
"    call Decho("edit-a-file: tree listing",'~'.expand("<slnum>"))
   elseif newdir =~ '^\(/\|\a:\)'
    let dirname= newdir
   else
    let dirname= s:ComposePath(dirname,newdir)
   endif
"   call Decho("edit-a-file: handling a file: dirname<".dirname."> (a:0=".a:0.")",'~'.expand("<slnum>"))
   " this lets netrw#BrowseX avoid the edit
   if a:0 < 1
"    call Decho("edit-a-file: set up windows for editing<".fnameescape(dirname).">  didsplit=".(exists("s:didsplit")? s:didsplit : "doesn't exist"),'~'.expand("<slnum>"))
    NetrwKeepj call s:NetrwOptionRestore("s:")
    if !exists("s:didsplit")
"     call Decho("edit-a-file: s:didsplit does not exist; g:netrw_browse_split=".string(g:netrw_browse_split)." win#".winnr(),'~'.expand("<slnum>"))
     if type(g:netrw_browse_split) == 3
      " open file in server
      " Note that g:netrw_browse_split is a List: [servername,tabnr,winnr]
"      call Decho("edit-a-file: open file in server",'~'.expand("<slnum>"))
      call s:NetrwServerEdit(a:islocal,dirname)
"      call Dret("s:NetrwBrowseChgDir")
      return
     elseif g:netrw_browse_split == 1
      " horizontally splitting the window first
"      call Decho("edit-a-file: horizontally splitting window prior to edit",'~'.expand("<slnum>"))
      keepalt new
      if !&ea
       keepalt wincmd _
      endif
     elseif g:netrw_browse_split == 2
      " vertically splitting the window first
"      call Decho("edit-a-file: vertically splitting window prior to edit",'~'.expand("<slnum>"))
      keepalt rightb vert new
      if !&ea
       keepalt wincmd |
      endif
     elseif g:netrw_browse_split == 3
      " open file in new tab
"      call Decho("edit-a-file: opening new tab prior to edit",'~'.expand("<slnum>"))
      keepalt tabnew
     elseif g:netrw_browse_split == 4
      " act like "P" (ie. open previous window)
"      call Decho("edit-a-file: use previous window for edit",'~'.expand("<slnum>"))
      if s:NetrwPrevWinOpen(2) == 3
       let @@= ykeep
"       call Dret("s:NetrwBrowseChgDir")
       return
      endif
     else
      " handling a file, didn't split, so remove menu
"      call Decho("edit-a-file: handling a file+didn't split, so remove menu",'~'.expand("<slnum>"))
      call s:NetrwMenu(0)
      " optional change to window
      if g:netrw_chgwin >= 1
"       call Decho("edit-a-file: changing window to #".g:netrw_chgwin,'~'.expand("<slnum>"))
       if winnr("$")+1 == g:netrw_chgwin
	" if g:netrw_chgwin is set to one more than the last window, then
	" vertically split the last window to make that window available.
	let curwin= winnr()
	exe "NetrwKeepj keepalt ".winnr("$")."wincmd w"
	vs
	exe "NetrwKeepj keepalt ".g:netrw_chgwin."wincmd ".curwin
       endif
       exe "NetrwKeepj keepalt ".g:netrw_chgwin."wincmd w"
      endif
     endif
    endif

    " the point where netrw actually edits the (local) file
    " if its local only: LocalBrowseCheck() doesn't edit a file, but NetrwBrowse() will
    " no keepalt to support  :e #  to return to a directory listing
    if a:islocal
"     call Decho("edit-a-file: edit local file: exe e! ".fnameescape(dirname),'~'.expand("<slnum>"))
     " some like c-^ to return to the last edited file
     " others like c-^ to return to the netrw buffer
     if exists("g:netrw_altfile") && g:netrw_altfile
      exe "NetrwKeepj keepalt e! ".fnameescape(dirname)
     else
      exe "NetrwKeepj e! ".fnameescape(dirname)
     endif
"     call Decho("edit-a-file: after e! ".dirname.": hidden=".&hidden." bufhidden<".&bufhidden."> mod=".&mod,'~'.expand("<slnum>"))
     call s:NetrwCursor()
     if &hidden || &bufhidden == "hide"
      " file came from vim's hidden storage.  Don't "restore" options with it.
      let dorestore= 0
     endif
    else
"     call Decho("edit-a-file: remote file: NetrwBrowse will edit it",'~'.expand("<slnum>"))
    endif
    let dolockout= 1

    " handle g:Netrw_funcref -- call external-to-netrw functions
    "   This code will handle g:Netrw_funcref as an individual function reference
    "   or as a list of function references.  It will ignore anything that's not
    "   a function reference.  See  :help Funcref  for information about function references.
    if exists("g:Netrw_funcref")
"     call Decho("edit-a-file: handle optional Funcrefs",'~'.expand("<slnum>"))
     if type(g:Netrw_funcref) == 2
"      call Decho("edit-a-file: handling a g:Netrw_funcref",'~'.expand("<slnum>"))
      NetrwKeepj call g:Netrw_funcref()
     elseif type(g:Netrw_funcref) == 3
"      call Decho("edit-a-file: handling a list of g:Netrw_funcrefs",'~'.expand("<slnum>"))
      for Fncref in g:Netrw_funcref
       if type(FncRef) == 2
        NetrwKeepj call FncRef()
       endif
      endfor
     endif
    endif
   endif

  elseif newdir =~ '^/'
   " ----------------------------------------------------
   " NetrwBrowseChgDir: just go to the new directory spec {{{3
   " ----------------------------------------------------
"   call Decho('goto-newdir: case "just go to new directory spec": newdir<'.newdir.'>','~'.expand("<slnum>"))
   let dirname = newdir
   NetrwKeepj call s:SetRexDir(a:islocal,dirname)
   NetrwKeepj call s:NetrwOptionRestore("s:")
   norm! m`

  elseif newdir == './'
   " ---------------------------------------------
   " NetrwBrowseChgDir: refresh the directory list {{{3
   " ---------------------------------------------
"   call Decho('refresh-dirlist: case "refresh directory listing": newdir == "./"','~'.expand("<slnum>"))
   NetrwKeepj call s:SetRexDir(a:islocal,dirname)
   norm! m`

  elseif newdir == '../'
   " --------------------------------------
   " NetrwBrowseChgDir: go up one directory {{{3
   " --------------------------------------
"   call Decho('go-up: case "go up one directory": newdir == "../"','~'.expand("<slnum>"))

   if w:netrw_liststyle == s:TREELIST && exists("w:netrw_treedict")
    " force a refresh
"    call Decho("go-up: clear buffer<".expand("%")."> with :%d",'~'.expand("<slnum>"))
"    call Decho("go-up: setl noro ma",'~'.expand("<slnum>"))
    setl noro ma
    NetrwKeepj %d _
   endif

   if has("amiga")
    " amiga
"    call Decho('go-up: case "go up one directory": newdir == "../" and amiga','~'.expand("<slnum>"))
    if a:islocal
     let dirname= substitute(dirname,'^\(.*[/:]\)\([^/]\+$\)','\1','')
     let dirname= substitute(dirname,'/$','','')
    else
     let dirname= substitute(dirname,'^\(.*[/:]\)\([^/]\+/$\)','\1','')
    endif
"    call Decho("go-up: amiga: dirname<".dirname."> (go up one dir)",'~'.expand("<slnum>"))

   elseif !g:netrw_cygwin && (has("win32") || has("win95") || has("win64") || has("win16"))
    " windows
    if a:islocal
     let dirname= substitute(dirname,'^\(.*\)/\([^/]\+\)/$','\1','')
     if dirname == ""
      let dirname= '/'
     endif
    else
     let dirname= substitute(dirname,'^\(\a\{3,}://.\{-}/\{1,2}\)\(.\{-}\)\([^/]\+\)/$','\1\2','')
    endif
    if dirname =~ '^\a:$'
     let dirname= dirname.'/'
    endif
"    call Decho("go-up: windows: dirname<".dirname."> (go up one dir)",'~'.expand("<slnum>"))

   else
    " unix or cygwin
"    call Decho('go-up: case "go up one directory": newdir == "../" and unix or cygwin','~'.expand("<slnum>"))
    if a:islocal
     let dirname= substitute(dirname,'^\(.*\)/\([^/]\+\)/$','\1','')
     if dirname == ""
      let dirname= '/'
     endif
    else
     let dirname= substitute(dirname,'^\(\a\{3,}://.\{-}/\{1,2}\)\(.\{-}\)\([^/]\+\)/$','\1\2','')
    endif
"    call Decho("go-up: unix: dirname<".dirname."> (go up one dir)",'~'.expand("<slnum>"))
   endif
   NetrwKeepj call s:SetRexDir(a:islocal,dirname)
   norm m`

  elseif exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && exists("w:netrw_treedict")
   " --------------------------------------
   " NetrwBrowseChgDir: Handle Tree Listing {{{3
   " --------------------------------------
"   call Decho('tree-list: case liststyle is TREELIST and w:netrw_treedict exists','~'.expand("<slnum>"))
   " force a refresh (for TREELIST, NetrwTreeDir() will force the refresh)
"   call Decho("tree-list: setl noro ma",'~'.expand("<slnum>"))
   setl noro ma
   if !(exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && exists("b:netrw_curdir"))
"    call Decho("tree-list: clear buffer<".expand("%")."> with :%d  (force refresh)",'~'.expand("<slnum>"))
    NetrwKeepj %d _
   endif
   let treedir      = s:NetrwTreeDir(a:islocal)
"   call Decho("tree-list: treedir<".treedir.">",'~'.expand("<slnum>"))
   let s:treecurpos = nbcd_curpos
   let haskey       = 0
"   call Decho("tree-list: w:netrw_treedict<".string(w:netrw_treedict).">",'~'.expand("<slnum>"))

   " search treedict for tree dir as-is
"   call Decho("search treedict for tree dir as-is",'~'.expand("<slnum>"))
   if has_key(w:netrw_treedict,treedir)
"    call Decho('tree-list: ....searched for treedir<'.treedir.'> : found it!','~'.expand("<slnum>"))
    let haskey= 1
   else
"    call Decho('tree-list: ....searched for treedir<'.treedir.'> : not found','~'.expand("<slnum>"))
   endif

   " search treedict for treedir with a [/@] appended
"   call Decho("search treedict for treedir with a [/@] appended",'~'.expand("<slnum>"))
   if !haskey && treedir !~ '[/@]$'
    if has_key(w:netrw_treedict,treedir."/")
     let treedir= treedir."/"
"     call Decho('tree-list: ....searched.for treedir<'.treedir.'> found it!','~'.expand("<slnum>"))
     let haskey = 1
    else
"     call Decho('tree-list: ....searched for treedir<'.treedir.'/> : not found','~'.expand("<slnum>"))
    endif
   endif

   " search treedict for treedir with any trailing / elided
"   call Decho("search treedict for treedir with any trailing / elided",'~'.expand("<slnum>"))
   if !haskey && treedir =~ '/$'
    let treedir= substitute(treedir,'/$','','')
    if has_key(w:netrw_treedict,treedir)
"     call Decho('tree-list: ....searched.for treedir<'.treedir.'> found it!','~'.expand("<slnum>"))
     let haskey = 1
    else
"     call Decho('tree-list: ....searched for treedir<'.treedir.'> : not found','~'.expand("<slnum>"))
    endif
   endif

"   call Decho("haskey=".haskey,'~'.expand("<slnum>"))
   if haskey
    " close tree listing for selected subdirectory
"    call Decho("tree-list: closing selected subdirectory<".dirname.">",'~'.expand("<slnum>"))
    call remove(w:netrw_treedict,treedir)
"    call Decho("tree-list: removed     entry<".treedir."> from treedict",'~'.expand("<slnum>"))
"    call Decho("tree-list: yielding treedict<".string(w:netrw_treedict).">",'~'.expand("<slnum>"))
    let dirname= w:netrw_treetop
   else
    " go down one directory
    let dirname= substitute(treedir,'/*$','/','')
"    call Decho("tree-list: go down one dir: treedir<".treedir.">",'~'.expand("<slnum>"))
"    call Decho("tree-list: ...            : dirname<".dirname.">",'~'.expand("<slnum>"))
   endif
   NetrwKeepj call s:SetRexDir(a:islocal,dirname)
"   call Decho("setting s:treeforceredraw to true",'~'.expand("<slnum>"))
   let s:treeforceredraw = 1

  else
   " ----------------------------------------
   " NetrwBrowseChgDir: Go down one directory {{{3
   " ----------------------------------------
   let dirname    = s:ComposePath(dirname,newdir)
"   call Decho("go down one dir: dirname<".dirname."> newdir<".newdir.">",'~'.expand("<slnum>"))
   NetrwKeepj call s:SetRexDir(a:islocal,dirname)
   norm m`
  endif

 " --------------------------------------
 " NetrwBrowseChgDir: Restore and Cleanup {{{3
 " --------------------------------------
  if dorestore
   " dorestore is zero'd when a local file was hidden or bufhidden;
   " in such a case, we want to keep whatever settings it may have.
"   call Decho("doing option restore (dorestore=".dorestore.")",'~'.expand("<slnum>"))
   NetrwKeepj call s:NetrwOptionRestore("s:")
"  else " Decho
"   call Decho("skipping option restore (dorestore==0): hidden=".&hidden." bufhidden=".&bufhidden." mod=".&mod,'~'.expand("<slnum>"))
  endif
  if dolockout && dorestore
"   call Decho("restore: filewritable(dirname<".dirname.">)=".filewritable(dirname),'~'.expand("<slnum>"))
   if filewritable(dirname)
"    call Decho("restore: doing modification lockout settings: ma nomod noro",'~'.expand("<slnum>"))
"    call Decho("restore: setl ma nomod noro",'~'.expand("<slnum>"))
    setl ma noro nomod
"    call Decho("restore: ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
   else
"    call Decho("restore: doing modification lockout settings: ma nomod ro",'~'.expand("<slnum>"))
"    call Decho("restore: setl ma nomod noro",'~'.expand("<slnum>"))
    setl ma ro nomod
"    call Decho("restore: ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
   endif
  endif
  let @@= ykeep

"  call Dret("s:NetrwBrowseChgDir <".dirname."> : curpos<".string(getpos(".")).">")
  return dirname
endfun

" ---------------------------------------------------------------------
" s:NetrwBrowseUpDir: implements the "-" mappings {{{2
"    for thin, long, and wide: cursor placed just after banner
"    for tree, keeps cursor on current filename
fun! s:NetrwBrowseUpDir(islocal)
"  call Dfunc("s:NetrwBrowseUpDir(islocal=".a:islocal.")")
  if exists("w:netrw_bannercnt") && line(".") < w:netrw_bannercnt-1
   " this test needed because occasionally this function seems to be incorrectly called
   " when multiple leftmouse clicks are taken when atop the one line help in the banner.
   " I'm allowing the very bottom line to permit a "-" exit so that one may escape empty
   " directories.
"   call Dret("s:NetrwBrowseUpDir : cursor not in file area")
   return
  endif

  norm! 0
  if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && exists("w:netrw_treedict")
"   call Decho("case: treestyle",'~'.expand("<slnum>"))
   let curline= getline(".")
   let swwline= winline() - 1
   if exists("w:netrw_treetop")
    let b:netrw_curdir= w:netrw_treetop
   endif
   let curdir= b:netrw_curdir
   if a:islocal
    call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(1,'../'))
   else
    call s:NetrwBrowse(0,s:NetrwBrowseChgDir(0,'../'))
   endif
   if !search('\c^'.s:treedepthstring.curline,'cw')
    if !search('\c^'.curline,'cw')
     sil! NetrwKeepj 1
    endif
   endif
   exe "sil! NetrwKeepj norm! z\<cr>"
   while winline() < swwline
    let curwinline= winline()
    exe "sil! NetrwKeepj norm! \<c-y>"
    if curwinline == winline()
     break
    endif
   endwhile
  else
"   call Decho("case: not treestyle",'~'.expand("<slnum>"))
   if exists("b:netrw_curdir")
    let curdir= b:netrw_curdir
   else
    let curdir= expand(getcwd())
   endif
   if a:islocal
    call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(1,'../'))
   else
    call s:NetrwBrowse(0,s:NetrwBrowseChgDir(0,'../'))
   endif
   if exists("w:netrw_bannercnt")
"    call Decho("moving to line#".w:netrw_bannercnt,'~'.expand("<slnum>"))
    exe w:netrw_bannercnt
   else
    1
   endif
  endif
  let curdir= substitute(curdir,'^.*[\/]','','')
  call search('\<'.curdir.'\>','wc')
"  call Dret("s:NetrwBrowseUpDir")
endfun

" ---------------------------------------------------------------------
" netrw#BrowseX:  (implements "x") executes a special "viewer" script or program for the {{{2
"              given filename; typically this means given their extension.
"              0=local, 1=remote
fun! netrw#BrowseX(fname,remote)
"  call Dfunc("netrw#BrowseX(fname<".a:fname."> remote=".a:remote.")")

  " if its really just a directory, then do a "gf" instead
  if a:fname =~ '/$'
   norm! gf
"   call Dret("netrw#BrowseX : did gf instead")
  endif


  let ykeep      = @@
  let screenposn = netrw#SavePosn()

  " need to save and restore aw setting as gx can invoke this function from non-netrw buffers
  let awkeep     = &aw
  set noaw

  " special core dump handler
  if a:fname =~ '/core\(\.\d\+\)\=$'
   if exists("g:Netrw_corehandler")
    if type(g:Netrw_corehandler) == 2
     " g:Netrw_corehandler is a function reference (see :help Funcref)
"     call Decho("g:Netrw_corehandler is a funcref",'~'.expand("<slnum>"))
     call g:Netrw_corehandler(s:NetrwFile(a:fname))
    elseif type(g:Netrw_corehandler) == 3
     " g:Netrw_corehandler is a List of function references (see :help Funcref)
"     call Decho("g:Netrw_corehandler is a List",'~'.expand("<slnum>"))
     for Fncref in g:Netrw_corehandler
      if type(FncRef) == 2
       call FncRef(a:fname)
      endif
     endfor
    endif
    call netrw#RestorePosn(screenposn)
    let @@= ykeep
    let &aw= awkeep
"    call Dret("netrw#BrowseX : coredump handler invoked")
    return
   endif
  endif

  " set up the filename
  " (lower case the extension, make a local copy of a remote file)
  let exten= substitute(a:fname,'.*\.\(.\{-}\)','\1','e')
  if has("win32") || has("win95") || has("win64") || has("win16")
   let exten= substitute(exten,'^.*$','\L&\E','')
  endif
"  call Decho("exten<".exten.">",'~'.expand("<slnum>"))

  if a:remote == 1
   " create a local copy
"   call Decho("remote: a:remote=".a:remote.": create a local copy of <".a:fname.">",'~'.expand("<slnum>"))
   setl bh=delete
   call netrw#NetRead(3,a:fname)
   " attempt to rename tempfile
   let basename= substitute(a:fname,'^\(.*\)/\(.*\)\.\([^.]*\)$','\2','')
   let newname = substitute(s:netrw_tmpfile,'^\(.*\)/\(.*\)\.\([^.]*\)$','\1/'.basename.'.\3','')
"   call Decho("basename<".basename.">",'~'.expand("<slnum>"))
"   call Decho("newname <".newname.">",'~'.expand("<slnum>"))
   if rename(s:netrw_tmpfile,newname) == 0
    " renaming succeeded
    let fname= newname
   else
    " renaming failed
    let fname= s:netrw_tmpfile
   endif
  else
"   call Decho("local: a:remote=".a:remote.": handling local copy of <".a:fname.">",'~'.expand("<slnum>"))
   let fname= a:fname
   " special ~ handler for local
   if fname =~ '^\~' && expand("$HOME") != ""
"    call Decho('invoking special ~ handler','~'.expand("<slnum>"))
    let fname= s:NetrwFile(substitute(fname,'^\~',expand("$HOME"),''))
   endif
  endif
"  call Decho("fname<".fname.">",'~'.expand("<slnum>"))
"  call Decho("exten<".exten."> "."netrwFileHandlers#NFH_".exten."():exists=".exists("*netrwFileHandlers#NFH_".exten),'~'.expand("<slnum>"))

  " set up redirection
  if &srr =~ "%s"
   if (has("win32") || has("win95") || has("win64") || has("win16"))
    let redir= substitute(&srr,"%s","nul","")
   else
    let redir= substitute(&srr,"%s","/dev/null","")
   endif
  elseif (has("win32") || has("win95") || has("win64") || has("win16"))
   let redir= &srr . "nul"
  else
   let redir= &srr . "/dev/null"
  endif
"  call Decho("set up redirection: redir{".redir."} srr{".&srr."}",'~'.expand("<slnum>"))

  " extract any viewing options.  Assumes that they're set apart by quotes.
"  call Decho("extract any viewing options",'~'.expand("<slnum>"))
  if exists("g:netrw_browsex_viewer")
"   call Decho("g:netrw_browsex_viewer<".g:netrw_browsex_viewer.">",'~'.expand("<slnum>"))
   if g:netrw_browsex_viewer =~ '\s'
    let viewer  = substitute(g:netrw_browsex_viewer,'\s.*$','','')
    let viewopt = substitute(g:netrw_browsex_viewer,'^\S\+\s*','','')." "
    let oviewer = ''
    let cnt     = 1
    while !executable(viewer) && viewer != oviewer
     let viewer  = substitute(g:netrw_browsex_viewer,'^\(\(^\S\+\s\+\)\{'.cnt.'}\S\+\)\(.*\)$','\1','')
     let viewopt = substitute(g:netrw_browsex_viewer,'^\(\(^\S\+\s\+\)\{'.cnt.'}\S\+\)\(.*\)$','\3','')." "
     let cnt     = cnt + 1
     let oviewer = viewer
"     call Decho("!exe: viewer<".viewer.">  viewopt<".viewopt.">",'~'.expand("<slnum>"))
    endwhile
   else
    let viewer  = g:netrw_browsex_viewer
    let viewopt = ""
   endif
"   call Decho("viewer<".viewer.">  viewopt<".viewopt.">",'~'.expand("<slnum>"))
  endif

  " execute the file handler
"  call Decho("execute the file handler (if any)",'~'.expand("<slnum>"))
  if exists("g:netrw_browsex_viewer") && g:netrw_browsex_viewer == '-'
"   call Decho("g:netrw_browsex_viewer<".g:netrw_browsex_viewer.">",'~'.expand("<slnum>"))
   let ret= netrwFileHandlers#Invoke(exten,fname)

  elseif exists("g:netrw_browsex_viewer") && executable(viewer)
"   call Decho("g:netrw_browsex_viewer<".g:netrw_browsex_viewer.">",'~'.expand("<slnum>"))
   call s:NetrwExe("sil !".viewer." ".viewopt.shellescape(fname,1).redir)
   let ret= v:shell_error

  elseif has("win32") || has("win64")
"   call Decho("windows",'~'.expand("<slnum>"))
   if executable("start")
    call s:NetrwExe('sil! !start rundll32 url.dll,FileProtocolHandler '.shellescape(fname,1))
   elseif executable("rundll32")
    call s:NetrwExe('sil! !rundll32 url.dll,FileProtocolHandler '.shellescape(fname,1))
   else
    call netrw#ErrorMsg(s:WARNING,"rundll32 not on path",74)
   endif
   call inputsave()|call input("Press <cr> to continue")|call inputrestore()
   let ret= v:shell_error

  elseif has("win32unix")
   let winfname= 'c:\cygwin'.substitute(fname,'/','\\','g')
"   call Decho("cygwin: winfname<".shellescape(winfname,1).">",'~'.expand("<slnum>"))
   if executable("start")
    call s:NetrwExe('sil !start rundll32 url.dll,FileProtocolHandler '.shellescape(winfname,1))
   elseif executable("rundll32")
    call s:NetrwExe('sil !rundll32 url.dll,FileProtocolHandler '.shellescape(winfname,1))
   elseif executable("cygstart")
    call s:NetrwExe('sil !cygstart '.shellescape(fname,1))
   else
    call netrw#ErrorMsg(s:WARNING,"rundll32 not on path",74)
   endif
   call inputsave()|call input("Press <cr> to continue")|call inputrestore()
   let ret= v:shell_error

  elseif has("unix") && executable("kfmclient") && s:CheckIfKde()
"   call Decho("unix and kfmclient",'~'.expand("<slnum>"))
   call s:NetrwExe("sil !kfmclient exec ".shellescape(fname,1)." ".redir)
   let ret= v:shell_error

  elseif has("unix") && executable("xdg-open")
"   call Decho("unix and xdg-open",'~'.expand("<slnum>"))
   call s:NetrwExe("sil !xdg-open ".shellescape(fname,1).redir)
   let ret= v:shell_error

  elseif has("macunix") && executable("open")
"   call Decho("macunix and open",'~'.expand("<slnum>"))
   call s:NetrwExe("sil !open ".shellescape(fname,1)." ".redir)
   let ret= v:shell_error

  else
   " netrwFileHandlers#Invoke() always returns 0
   let ret= netrwFileHandlers#Invoke(exten,fname)
  endif

  " if unsuccessful, attempt netrwFileHandlers#Invoke()
  if ret
   let ret= netrwFileHandlers#Invoke(exten,fname)
  endif

  " restoring redraw! after external file handlers
  redraw!

  " cleanup: remove temporary file,
  "          delete current buffer if success with handler,
  "          return to prior buffer (directory listing)
  "          Feb 12, 2008: had to de-activiate removal of
  "          temporary file because it wasn't getting seen.
"  if a:remote == 1 && fname != a:fname
""   call Decho("deleting temporary file<".fname.">",'~'.expand("<slnum>"))
"   call s:NetrwDelete(fname)
"  endif

  if a:remote == 1
   setl bh=delete bt=nofile
   if g:netrw_use_noswf
    setl noswf
   endif
   exe "sil! NetrwKeepj norm! \<c-o>"
"   redraw!
  endif
  call netrw#RestorePosn(screenposn)
  let @@ = ykeep
  let &aw= awkeep

"  call Dret("netrw#BrowseX")
endfun

" ---------------------------------------------------------------------
" netrw#BrowseXVis: used by gx in visual mode to select a file for browsing {{{2
fun! netrw#BrowseXVis()
"  call Dfunc("netrw#BrowseXVis()")
  let atkeep = @@
  norm! gvy
"  call Decho("@@<".@@.">",'~'.expand("<slnum>"))
  call netrw#BrowseX(@@,netrw#CheckIfRemote())
  let @@     = atkeep
"  call Dret("netrw#BrowseXVis")
endfun

" ---------------------------------------------------------------------
" netrw#CheckIfRemote: returns 1 if current file looks like an url, 0 else {{{2
fun! netrw#CheckIfRemote()
"  call Dfunc("netrw#CheckIfRemote()")
  if expand("%") =~ '^\a\{3,}://'
"   call Dret("netrw#CheckIfRemote 1")
   return 1
  else
"   call Dret("netrw#CheckIfRemote 0")
   return 0
  endif
endfun

" ---------------------------------------------------------------------
" s:NetrwChgPerm: (implements "gp") change file permission {{{2
fun! s:NetrwChgPerm(islocal,curdir)
"  call Dfunc("s:NetrwChgPerm(islocal=".a:islocal." curdir<".a:curdir.">)")
  let ykeep  = @@
  call inputsave()
  let newperm= input("Enter new permission: ")
  call inputrestore()
  let chgperm= substitute(g:netrw_chgperm,'\<FILENAME\>',shellescape(expand("<cfile>")),'')
  let chgperm= substitute(chgperm,'\<PERM\>',shellescape(newperm),'')
"  call Decho("chgperm<".chgperm.">",'~'.expand("<slnum>"))
  call system(chgperm)
  if v:shell_error != 0
   NetrwKeepj call netrw#ErrorMsg(1,"changing permission on file<".expand("<cfile>")."> seems to have failed",75)
  endif
  if a:islocal
   NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  endif
  let @@= ykeep
"  call Dret("s:NetrwChgPerm")
endfun

" ---------------------------------------------------------------------
" s:CheckIfKde: checks if kdeinit is running {{{2
"    Returns 0: kdeinit not running
"            1: kdeinit is  running
fun! s:CheckIfKde()
"  call Dfunc("s:CheckIfKde()")
  " seems kde systems often have gnome-open due to dependencies, even though
  " gnome-open's subsidiary display tools are largely absent.  Kde systems
  " usually have "kdeinit" running, though...  (tnx Mikolaj Machowski)
  if !exists("s:haskdeinit")
   if has("unix") && executable("ps") && !has("win32unix")
    let s:haskdeinit= system("ps -e") =~ '\<kdeinit'
    if v:shell_error
     let s:haskdeinit = 0
    endif
   else
    let s:haskdeinit= 0
   endif
"   call Decho("setting s:haskdeinit=".s:haskdeinit,'~'.expand("<slnum>"))
  endif

"  call Dret("s:CheckIfKde ".s:haskdeinit)
  return s:haskdeinit
endfun

" ---------------------------------------------------------------------
" s:NetrwClearExplore: clear explore variables (if any) {{{2
fun! s:NetrwClearExplore()
"  call Dfunc("s:NetrwClearExplore()")
  2match none
  if exists("s:explore_match")        |unlet s:explore_match        |endif
  if exists("s:explore_indx")         |unlet s:explore_indx         |endif
  if exists("s:netrw_explore_prvdir") |unlet s:netrw_explore_prvdir |endif
  if exists("s:dirstarstar")          |unlet s:dirstarstar          |endif
  if exists("s:explore_prvdir")       |unlet s:explore_prvdir       |endif
  if exists("w:netrw_explore_indx")   |unlet w:netrw_explore_indx   |endif
  if exists("w:netrw_explore_listlen")|unlet w:netrw_explore_listlen|endif
  if exists("w:netrw_explore_list")   |unlet w:netrw_explore_list   |endif
  if exists("w:netrw_explore_bufnr")  |unlet w:netrw_explore_bufnr  |endif
"   redraw!
  echo " "
  echo " "
"  call Dret("s:NetrwClearExplore")
endfun

" ---------------------------------------------------------------------
" s:NetrwExploreListUniq: {{{2
fun! s:NetrwExploreListUniq(explist)
"  call Dfunc("s:NetrwExploreListUniq(explist<".string(a:explist).">)")

  " this assumes that the list is already sorted
  let newexplist= []
  for member in a:explist
   if !exists("uniqmember") || member != uniqmember
    let uniqmember = member
    let newexplist = newexplist + [ member ]
   endif
  endfor

"  call Dret("s:NetrwExploreListUniq newexplist<".string(newexplist).">")
  return newexplist
endfun

" ---------------------------------------------------------------------
" s:NetrwForceChgDir: (gd support) Force treatment as a directory {{{2
fun! s:NetrwForceChgDir(islocal,newdir)
"  call Dfunc("s:NetrwForceChgDir(islocal=".a:islocal." newdir<".a:newdir.">)")
  let ykeep= @@
  if a:newdir !~ '/$'
   " ok, looks like force is needed to get directory-style treatment
   if a:newdir =~ '@$'
    let newdir= substitute(a:newdir,'@$','/','')
   elseif a:newdir =~ '[*=|\\]$'
    let newdir= substitute(a:newdir,'.$','/','')
   else
    let newdir= a:newdir.'/'
   endif
"   call Decho("adjusting newdir<".newdir."> due to gd",'~'.expand("<slnum>"))
  else
   " should already be getting treatment as a directory
   let newdir= a:newdir
  endif
  let newdir= s:NetrwBrowseChgDir(a:islocal,newdir)
  call s:NetrwBrowse(a:islocal,newdir)
  let @@= ykeep
"  call Dret("s:NetrwForceChgDir")
endfun

" ---------------------------------------------------------------------
" s:NetrwForceFile: (gf support) Force treatment as a file {{{2
fun! s:NetrwForceFile(islocal,newfile)
"  call Dfunc("s:NetrwForceFile(islocal=".a:islocal." newdir<".a:newfile.">)")
  if a:newfile =~ '[/@*=|\\]$'
   let newfile= substitute(a:newfile,'.$','','')
  else
   let newfile= a:newfile
  endif
  if a:islocal
   call s:NetrwBrowseChgDir(a:islocal,newfile)
  else
   call s:NetrwBrowse(a:islocal,s:NetrwBrowseChgDir(a:islocal,newfile))
  endif
"  call Dret("s:NetrwForceFile")
endfun

" ---------------------------------------------------------------------
" s:NetrwHide: this function is invoked by the "a" map for browsing {{{2
"          and switches the hiding mode.  The actual hiding is done by
"          s:NetrwListHide().
"             g:netrw_hide= 0: show all
"                           1: show not-hidden files
"                           2: show hidden files only
fun! s:NetrwHide(islocal)
"  call Dfunc("NetrwHide(islocal=".a:islocal.") g:netrw_hide=".g:netrw_hide)
  let ykeep= @@
  let svpos= netrw#SavePosn()

  if exists("s:netrwmarkfilelist_{bufnr('%')}")
"   call Decho("((g:netrw_hide == 1)? "unhide" : "hide")." files in markfilelist<".string(s:netrwmarkfilelist_{bufnr("%")}).">",'~'.expand("<slnum>"))
"   call Decho("g:netrw_list_hide<".g:netrw_list_hide.">",'~'.expand("<slnum>"))

   " hide the files in the markfile list
   for fname in s:netrwmarkfilelist_{bufnr("%")}
"    call Decho("match(g:netrw_list_hide<".g:netrw_list_hide.'> fname<\<'.fname.'\>>)='.match(g:netrw_list_hide,'\<'.fname.'\>')." l:isk=".&l:isk,'~'.expand("<slnum>"))
    if match(g:netrw_list_hide,'\<'.fname.'\>') != -1
     " remove fname from hiding list
     let g:netrw_list_hide= substitute(g:netrw_list_hide,'..\<'.escape(fname,g:netrw_fname_escape).'\>..','','')
     let g:netrw_list_hide= substitute(g:netrw_list_hide,',,',',','g')
     let g:netrw_list_hide= substitute(g:netrw_list_hide,'^,\|,$','','')
"     call Decho("unhide: g:netrw_list_hide<".g:netrw_list_hide.">",'~'.expand("<slnum>"))
    else
     " append fname to hiding list
     if exists("g:netrw_list_hide") && g:netrw_list_hide != ""
      let g:netrw_list_hide= g:netrw_list_hide.',\<'.escape(fname,g:netrw_fname_escape).'\>'
     else
      let g:netrw_list_hide= '\<'.escape(fname,g:netrw_fname_escape).'\>'
     endif
"     call Decho("hide: g:netrw_list_hide<".g:netrw_list_hide.">",'~'.expand("<slnum>"))
    endif
   endfor
   NetrwKeepj call s:NetrwUnmarkList(bufnr("%"),b:netrw_curdir)
   let g:netrw_hide= 1

  else

   " switch between show-all/show-not-hidden/show-hidden
   let g:netrw_hide=(g:netrw_hide+1)%3
   exe "NetrwKeepj norm! 0"
   if g:netrw_hide && g:netrw_list_hide == ""
    NetrwKeepj call netrw#ErrorMsg(s:WARNING,"your hiding list is empty!",49)
    let @@= ykeep
"    call Dret("NetrwHide")
    return
   endif
  endif

  NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  NetrwKeepj call netrw#RestorePosn(svpos)
  let @@= ykeep
"  call Dret("NetrwHide")
endfun

" ---------------------------------------------------------------------
" s:NetrwHideEdit: allows user to edit the file/directory hiding list {{{2
fun! s:NetrwHideEdit(islocal)
"  call Dfunc("NetrwHideEdit(islocal=".a:islocal.")")

  let ykeep= @@
  " save current cursor position
  let svpos= netrw#SavePosn()

  " get new hiding list from user
  call inputsave()
  let newhide= input("Edit Hiding List: ",g:netrw_list_hide)
  call inputrestore()
  let g:netrw_list_hide= newhide
"  call Decho("new g:netrw_list_hide<".g:netrw_list_hide.">",'~'.expand("<slnum>"))

  " refresh the listing
  sil NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,"./"))

  " restore cursor position
  call netrw#RestorePosn(svpos)
  let @@= ykeep

"  call Dret("NetrwHideEdit")
endfun

" ---------------------------------------------------------------------
" s:NetrwHidden: invoked by "gh" {{{2
fun! s:NetrwHidden(islocal)
"  call Dfunc("s:NetrwHidden()")
  let ykeep= @@
  "  save current position
  let svpos= netrw#SavePosn()

  if g:netrw_list_hide =~ '\(^\|,\)\\(^\\|\\s\\s\\)\\zs\\.\\S\\+'
   " remove pattern from hiding list
   let g:netrw_list_hide= substitute(g:netrw_list_hide,'\(^\|,\)\\(^\\|\\s\\s\\)\\zs\\.\\S\\+','','')
  elseif s:Strlen(g:netrw_list_hide) >= 1
   let g:netrw_list_hide= g:netrw_list_hide . ',\(^\|\s\s\)\zs\.\S\+'
  else
   let g:netrw_list_hide= '\(^\|\s\s\)\zs\.\S\+'
  endif

  " refresh screen and return to saved position
  NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  NetrwKeepj call netrw#RestorePosn(svpos)
  let @@= ykeep
"  call Dret("s:NetrwHidden")
endfun

" ---------------------------------------------------------------------
"  s:NetrwHome: this function determines a "home" for saving bookmarks and history {{{2
fun! s:NetrwHome()
  if exists("g:netrw_home")
   let home= g:netrw_home
  else
   " go to vim plugin home
   for home in split(&rtp,',') + ['']
    if isdirectory(s:NetrwFile(home)) && filewritable(s:NetrwFile(home)) | break | endif
     let basehome= substitute(home,'[/\\]\.vim$','','')
     if isdirectory(s:NetrwFile(basehome)) && filewritable(s:NetrwFile(basehome))
     let home= basehome."/.vim"
     break
    endif
   endfor
   if home == ""
    " just pick the first directory
    let home= substitute(&rtp,',.*$','','')
   endif
   if (has("win32") || has("win95") || has("win64") || has("win16"))
    let home= substitute(home,'/','\\','g')
   endif
  endif
  " insure that the home directory exists
  if g:netrw_dirhistmax > 0 && !isdirectory(s:NetrwFile(home))
   if exists("g:netrw_mkdir")
    call system(g:netrw_mkdir." ".shellescape(s:NetrwFile(home)))
   else
    call mkdir(home)
   endif
  endif
  let g:netrw_home= home
  return home
endfun

" ---------------------------------------------------------------------
" s:NetrwLeftmouse: handles the <leftmouse> when in a netrw browsing window {{{2
fun! s:NetrwLeftmouse(islocal)
  if exists("s:netrwdrag")
   return
  endif
"  call Dfunc("s:NetrwLeftmouse(islocal=".a:islocal.")")

  let ykeep= @@
  " check if the status bar was clicked on instead of a file/directory name
  while getchar(0) != 0
   "clear the input stream
  endwhile
  call feedkeys("\<LeftMouse>")
  let c          = getchar()
  let mouse_lnum = v:mouse_lnum
  let wlastline  = line('w$')
  let lastline   = line('$')
"  call Decho("v:mouse_lnum=".mouse_lnum." line(w$)=".wlastline." line($)=".lastline." v:mouse_win=".v:mouse_win." winnr#".winnr(),'~'.expand("<slnum>"))
"  call Decho("v:mouse_col =".v:mouse_col."     col=".col(".")."  wincol =".wincol()." winwidth   =".winwidth(0),'~'.expand("<slnum>"))
  if mouse_lnum >= wlastline + 1 || v:mouse_win != winnr()
   " appears to be a status bar leftmouse click
   let @@= ykeep
"   call Dret("s:NetrwLeftmouse : detected a status bar leftmouse click")
   return
  endif
   " Dec 04, 2013: following test prevents leftmouse selection/deselection of directories and files in treelist mode
   " Windows are separated by vertical separator bars - but the mouse seems to be doing what it should when dragging that bar
   " without this test when its disabled.
   " May 26, 2014: edit file, :Lex, resize window -- causes refresh.  Reinstated a modified test.  See if problems develop.
"   call Decho("v:mouse_col=".v:mouse_col." col#".col('.')." virtcol#".virtcol('.')." col($)#".col("$")." virtcol($)#".virtcol("$"),'~'.expand("<slnum>"))
   if v:mouse_col > virtcol('.')
    let @@= ykeep
"    call Dret("s:NetrwLeftmouse : detected a vertical separator bar leftmouse click")
    return
   endif

  if a:islocal
   if exists("b:netrw_curdir")
    NetrwKeepj call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(1,s:NetrwGetWord()))
   endif
  else
   if exists("b:netrw_curdir")
    NetrwKeepj call s:NetrwBrowse(0,s:NetrwBrowseChgDir(0,s:NetrwGetWord()))
   endif
  endif
  let @@= ykeep
"  call Dret("s:NetrwLeftmouse")
endfun

" ---------------------------------------------------------------------
" s:NetrwCLeftmouse: used to select a file/directory for a target {{{2
fun! s:NetrwCLeftmouse(islocal)
"  call Dfunc("s:NetrwCLeftmouse(islocal=".a:islocal.")")
  call s:NetrwMarkFileTgt(a:islocal)
"  call Dret("s:NetrwCLeftmouse")
endfun

" ---------------------------------------------------------------------
" s:NetrwServerEdit: edit file in a server gvim, usually NETRWSERVER  (implements <c-r>){{{2
"   a:islocal=0 : <c-r> not used, remote
"   a:islocal=1 : <c-r> no  used, local
"   a:islocal=2 : <c-r>     used, remote
"   a:islocal=3 : <c-r>     used, local
fun! s:NetrwServerEdit(islocal,fname)
"  call Dfunc("s:NetrwServerEdit(islocal=".a:islocal.",fname<".a:fname.">)")
  let islocal = a:islocal%2      " =0: remote           =1: local
  let ctrlr   = a:islocal >= 2   " =0: <c-r> not used   =1: <c-r> used
"  call Decho("islocal=".islocal." ctrlr=".ctrlr,'~'.expand("<slnum>"))

  if (islocal && isdirectory(s:NetrwFile(a:fname))) || (!islocal && a:fname =~ '/$')
   " handle directories in the local window -- not in the remote vim server
   " user must have closed the NETRWSERVER window.  Treat as a normal editing from netrw.
"   call Decho("handling directory in client window",'~'.expand("<slnum>"))
   let g:netrw_browse_split= 0
   if exists("s:netrw_browse_split_".winnr())
    let g:netrw_browse_split= s:netrw_browse_split_{winnr()}
    unlet s:netrw_browse_split_{winnr()}
   endif
   call s:NetrwBrowse(islocal,s:NetrwBrowseChgDir(islocal,a:fname))
"   call Dret("s:NetrwServerEdit")
   return
  endif

"  call Decho("handling file in server window",'~'.expand("<slnum>"))
  if has("clientserver") && executable("gvim")
"   call Decho("has clientserver and gvim",'~'.expand("<slnum>"))

    if exists("g:netrw_browse_split") && type(g:netrw_browse_split) == 3
"     call Decho("g:netrw_browse_split=".string(g:netrw_browse_split),'~'.expand("<slnum>"))
     let srvrname = g:netrw_browse_split[0]
     let tabnum   = g:netrw_browse_split[1]
     let winnum   = g:netrw_browse_split[2]

     if serverlist() !~ '\<'.srvrname.'\>'
"      call Decho("server not available; ctrlr=".ctrlr,'~'.expand("<slnum>"))

      if !ctrlr
       " user must have closed the server window and the user did not use <c-r>, but
       " used something like <cr>.
"       call Decho("user must have closed server AND did not use ctrl-r",'~'.expand("<slnum>"))
       if exists("g:netrw_browse_split")
	unlet g:netrw_browse_split
       endif
       let g:netrw_browse_split= 0
       if exists("s:netrw_browse_split_".winnr())
        let g:netrw_browse_split= s:netrw_browse_split_{winnr()}
       endif
       call s:NetrwBrowseChgDir(islocal,a:fname)
"       call Dret("s:NetrwServerEdit")
       return

      elseif has("win32") && executable("start")
       " start up remote netrw server under windows
"       call Decho("starting up gvim server<".srvrname."> for windows",'~'.expand("<slnum>"))
       call system("start gvim --servername ".srvrname)

      else
       " start up remote netrw server under linux
"       call Decho("starting up gvim server<".srvrname.">",'~'.expand("<slnum>"))
       call system("gvim --servername ".srvrname)
      endif
     endif

"     call Decho("srvrname<".srvrname."> tabnum=".tabnum." winnum=".winnum." server-editing<".a:fname.">",'~'.expand("<slnum>"))
     call remote_send(srvrname,":tabn ".tabnum."\<cr>")
     call remote_send(srvrname,":".winnum."wincmd w\<cr>")
     call remote_send(srvrname,":e ".fnameescape(s:NetrwFile(a:fname))."\<cr>")

    else

     if serverlist() !~ '\<'.g:netrw_servername.'\>'

      if !ctrlr
"       call Decho("server<".g:netrw_servername."> not available and ctrl-r not used",'~'.expand("<slnum>"))
       if exists("g:netrw_browse_split")
	unlet g:netrw_browse_split
       endif
       let g:netrw_browse_split= 0
       call s:NetrwBrowse(islocal,s:NetrwBrowseChgDir(islocal,a:fname))
"       call Dret("s:NetrwServerEdit")
       return

      else
"       call Decho("server<".g:netrw_servername."> not available but ctrl-r used",'~'.expand("<slnum>"))
       if has("win32") && executable("start")
        " start up remote netrw server under windows
"        call Decho("starting up gvim server<".g:netrw_servername."> for windows",'~'.expand("<slnum>"))
        call system("start gvim --servername ".g:netrw_servername)
       else
        " start up remote netrw server under linux
"        call Decho("starting up gvim server<".g:netrw_servername.">",'~'.expand("<slnum>"))
        call system("gvim --servername ".g:netrw_servername)
       endif
      endif
     endif

     while 1
      try
"       call Decho("remote-send: e ".a:fname,'~'.expand("<slnum>"))
       call remote_send(g:netrw_servername,":e ".fnameescape(s:NetrwFile(a:fname))."\<cr>")
       break
      catch /^Vim\%((\a\+)\)\=:E241/
       sleep 200m
      endtry
     endwhile

     if exists("g:netrw_browse_split")
      if type(g:netrw_browse_split) != 3
        let s:netrw_browse_split_{winnr()}= g:netrw_browse_split
       endif
      unlet g:netrw_browse_split
     endif
     let g:netrw_browse_split= [g:netrw_servername,1,1]
    endif

   else
    call netrw#ErrorMsg(s:ERROR,"you need a gui-capable vim and client-server to use <ctrl-r>",98)
   endif

"  call Dret("s:NetrwServerEdit")
endfun

" ---------------------------------------------------------------------
" s:NetrwSLeftmouse: marks the file under the cursor.  May be dragged to select additional files {{{2
fun! s:NetrwSLeftmouse(islocal)
"  call Dfunc("s:NetrwSLeftmouse(islocal=".a:islocal.")")

  let s:ngw= s:NetrwGetWord()
  call s:NetrwMarkFile(a:islocal,s:ngw)

"  call Dret("s:NetrwSLeftmouse")
endfun

" ---------------------------------------------------------------------
" s:NetrwSLeftdrag: invoked via a shift-leftmouse and dragging {{{2
"                   Used to mark multiple files.
fun! s:NetrwSLeftdrag(islocal)
"  call Dfunc("s:NetrwSLeftdrag(islocal=".a:islocal.")")
  if !exists("s:netrwdrag")
   let s:netrwdrag = winnr()
   if a:islocal
    nno <silent> <s-leftrelease> <leftmouse>:<c-u>call <SID>NetrwSLeftrelease(1)<cr>
   else
    nno <silent> <s-leftrelease> <leftmouse>:<c-u>call <SID>NetrwSLeftrelease(0)<cr>
   endif
  endif
  let ngw = s:NetrwGetWord()
  if !exists("s:ngw") || s:ngw != ngw
   call s:NetrwMarkFile(a:islocal,ngw)
  endif
  let s:ngw= ngw
"  call Dret("s:NetrwSLeftdrag : s:netrwdrag=".s:netrwdrag." buf#".bufnr("%"))
endfun

" ---------------------------------------------------------------------
" s:NetrwSLeftrelease: terminates shift-leftmouse dragging {{{2
fun! s:NetrwSLeftrelease(islocal)
"  call Dfunc("s:NetrwSLeftrelease(islocal=".a:islocal.") s:netrwdrag=".s:netrwdrag." buf#".bufnr("%"))
  if exists("s:netrwdrag")
   nunmap <s-leftrelease>
   let ngw = s:NetrwGetWord()
   if !exists("s:ngw") || s:ngw != ngw
    call s:NetrwMarkFile(a:islocal,ngw)
   endif
   if exists("s:ngw")
    unlet s:ngw
   endif
   unlet s:netrwdrag
  endif
"  call Dret("s:NetrwSLeftrelease")
endfun

" ---------------------------------------------------------------------
" s:NetrwListHide: uses [range]g~...~d to delete files that match comma {{{2
" separated patterns given in g:netrw_list_hide
fun! s:NetrwListHide()
"  call Dfunc("s:NetrwListHide() g:netrw_hide=".g:netrw_hide." g:netrw_list_hide<".g:netrw_list_hide.">")
  let ykeep= @@

  " find a character not in the "hide" string to use as a separator for :g and :v commands
  " How-it-works: take the hiding command, convert it into a range.  Duplicate
  " characters don't matter.  Remove all such characters from the '/~...90'
  " string.  Use the first character left as a separator character.
  let listhide= g:netrw_list_hide
  let sep     = strpart(substitute('/~@#$%^&*{};:,<.>?|1234567890','['.escape(listhide,'-]^\').']','','ge'),1,1)
"  call Decho("sep=".sep,'~'.expand("<slnum>"))

  while listhide != ""
   if listhide =~ ','
    let hide     = substitute(listhide,',.*$','','e')
    let listhide = substitute(listhide,'^.\{-},\(.*\)$','\1','e')
   else
    let hide     = listhide
    let listhide = ""
   endif

   " Prune the list by hiding any files which match
   if g:netrw_hide == 1
"    call Decho("hiding<".hide."> listhide<".listhide.">",'~'.expand("<slnum>"))
    exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$g'.sep.hide.sep.'d'
   elseif g:netrw_hide == 2
"    call Decho("showing<".hide."> listhide<".listhide.">",'~'.expand("<slnum>"))
    exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$g'.sep.hide.sep.'s@^@ /-KEEP-/ @'
   endif
  endwhile
  if g:netrw_hide == 2
   exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$v@^ /-KEEP-/ @d'
   exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$s@^\%( /-KEEP-/ \)\+@@e'
  endif

  " remove any blank lines that have somehow remained.
  " This seems to happen under Windows.
  exe 'sil! NetrwKeepj 1,$g@^\s*$@d'

  let @@= ykeep
"  call Dret("s:NetrwListHide")
endfun

" ---------------------------------------------------------------------
" s:NetrwMakeDir: this function makes a directory (both local and remote) {{{2
"                 implements the "d" mapping.
fun! s:NetrwMakeDir(usrhost)
"  call Dfunc("s:NetrwMakeDir(usrhost<".a:usrhost.">)")

  let ykeep= @@
  " get name of new directory from user.  A bare <CR> will skip.
  " if its currently a directory, also request will be skipped, but with
  " a message.
  call inputsave()
  let newdirname= input("Please give directory name: ")
  call inputrestore()
"  call Decho("newdirname<".newdirname.">",'~'.expand("<slnum>"))

  if newdirname == ""
   let @@= ykeep
"   call Dret("s:NetrwMakeDir : user aborted with bare <cr>")
   return
  endif

  if a:usrhost == ""
"   call Decho("local mkdir",'~'.expand("<slnum>"))

   " Local mkdir:
   " sanity checks
   let fullnewdir= b:netrw_curdir.'/'.newdirname
"   call Decho("fullnewdir<".fullnewdir.">",'~'.expand("<slnum>"))
   if isdirectory(s:NetrwFile(fullnewdir))
    if !exists("g:netrw_quiet")
     NetrwKeepj call netrw#ErrorMsg(s:WARNING,"<".newdirname."> is already a directory!",24)
    endif
    let @@= ykeep
"    call Dret("s:NetrwMakeDir : directory<".newdirname."> exists previously")
    return
   endif
   if s:FileReadable(fullnewdir)
    if !exists("g:netrw_quiet")
     NetrwKeepj call netrw#ErrorMsg(s:WARNING,"<".newdirname."> is already a file!",25)
    endif
    let @@= ykeep
"    call Dret("s:NetrwMakeDir : file<".newdirname."> exists previously")
    return
   endif

   " requested new local directory is neither a pre-existing file or
   " directory, so make it!
   if exists("*mkdir")
    if has("unix")
     call mkdir(fullnewdir,"p",xor(0777, system("umask")))
    else
     call mkdir(fullnewdir,"p")
    endif
   else
    let netrw_origdir= s:NetrwGetcwd(1)
    call s:NetrwLcd(b:netrw_curdir)
"    call Decho("netrw_origdir<".netrw_origdir.">: lcd b:netrw_curdir<".fnameescape(b:netrw_curdir).">",'~'.expand("<slnum>"))
    call s:NetrwExe("sil! !".g:netrw_localmkdir.' '.shellescape(newdirname,1))
    if v:shell_error != 0
     let @@= ykeep
     call netrw#ErrorMsg(s:ERROR,"consider setting g:netrw_localmkdir<".g:netrw_localmkdir."> to something that works",80)
"     call Dret("s:NetrwMakeDir : failed: sil! !".g:netrw_localmkdir.' '.shellescape(newdirname,1))
     return
    endif
    if !g:netrw_keepdir
"     call Decho("restoring netrw_origdir since g:netrw_keepdir=".g:netrw_keepdir,'~'.expand("<slnum>"))
     call s:NetrwLcd(netrw_origdir)
    endif
   endif

   if v:shell_error == 0
    " refresh listing
"    call Decho("refresh listing",'~'.expand("<slnum>"))
    let svpos= netrw#SavePosn()
    call s:NetrwRefresh(1,s:NetrwBrowseChgDir(1,'./'))
    call netrw#RestorePosn(svpos)
   elseif !exists("g:netrw_quiet")
    call netrw#ErrorMsg(s:ERROR,"unable to make directory<".newdirname.">",26)
   endif
"   redraw!

  elseif !exists("b:netrw_method") || b:netrw_method == 4
   " Remote mkdir:  using ssh
"   call Decho("remote mkdir",'~'.expand("<slnum>"))
   let mkdircmd  = s:MakeSshCmd(g:netrw_mkdir_cmd)
   let newdirname= substitute(b:netrw_curdir,'^\%(.\{-}/\)\{3}\(.*\)$','\1','').newdirname
   call s:NetrwExe("sil! !".mkdircmd." ".shellescape(newdirname,1))
   if v:shell_error == 0
    " refresh listing
    let svpos= netrw#SavePosn()
    NetrwKeepj call s:NetrwRefresh(0,s:NetrwBrowseChgDir(0,'./'))
    NetrwKeepj call netrw#RestorePosn(svpos)
   elseif !exists("g:netrw_quiet")
    NetrwKeepj call netrw#ErrorMsg(s:ERROR,"unable to make directory<".newdirname.">",27)
   endif
"   redraw!

  elseif b:netrw_method == 2
   " Remote mkdir:  using ftp+.netrc
   let svpos= netrw#SavePosn()
"   call Decho("b:netrw_curdir<".b:netrw_curdir.">",'~'.expand("<slnum>"))
   if exists("b:netrw_fname")
"    call Decho("b:netrw_fname<".b:netrw_fname.">",'~'.expand("<slnum>"))
    let remotepath= b:netrw_fname
   else
    let remotepath= ""
   endif
   call s:NetrwRemoteFtpCmd(remotepath,g:netrw_remote_mkdir.' "'.newdirname.'"')
   NetrwKeepj call s:NetrwRefresh(0,s:NetrwBrowseChgDir(0,'./'))
   NetrwKeepj call netrw#RestorePosn(svpos)

  elseif b:netrw_method == 3
   " Remote mkdir: using ftp + machine, id, passwd, and fname (ie. no .netrc)
   let svpos= netrw#SavePosn()
"   call Decho("b:netrw_curdir<".b:netrw_curdir.">",'~'.expand("<slnum>"))
   if exists("b:netrw_fname")
"    call Decho("b:netrw_fname<".b:netrw_fname.">",'~'.expand("<slnum>"))
    let remotepath= b:netrw_fname
   else
    let remotepath= ""
   endif
   call s:NetrwRemoteFtpCmd(remotepath,g:netrw_remote_mkdir.' "'.newdirname.'"')
   NetrwKeepj call s:NetrwRefresh(0,s:NetrwBrowseChgDir(0,'./'))
   NetrwKeepj call netrw#RestorePosn(svpos)
  endif

  let @@= ykeep
"  call Dret("s:NetrwMakeDir")
endfun

" ---------------------------------------------------------------------
" s:TreeSqueezeDir: allows a shift-cr (gvim only) to squeeze the current tree-listing directory {{{2
fun! s:TreeSqueezeDir(islocal)
"  call Dfunc("s:TreeSqueezeDir(islocal=".a:islocal.")")
  if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && exists("w:netrw_treedict")
   " its a tree-listing style
   let curdepth = substitute(getline('.'),'^\(\%('.s:treedepthstring.'\)*\)[^'.s:treedepthstring.'].\{-}$','\1','e')
   let iline    = line(".") - 1
   let stopline = (exists("w:netrw_bannercnt")? (w:netrw_bannercnt + 1) : 1)
"   call Decho("curdepth=".curdepth,'~'.expand("<slnum>"))
"   call Decho("stopline#".stopline,'~'.expand("<slnum>"))
"   call Decho("starting with line#".line(".").": ".getline('.'),'~'.expand("<slnum>"))
   while iline > stopline
    " find a line that has less depth
    let depth = substitute(getline('.'),'^\(\%('.s:treedepthstring.'\)*\)[^'.s:treedepthstring.'].\{-}$','\1','e')
"    call Decho("considering  line#".line(".").": ".getline('.'),'~'.expand("<slnum>"))
    if depth < curdepth
     break
    endif
    norm! k
   endwhile
"   call Decho("squeezing at line#".line(".").": ".getline('.'),'~'.expand("<slnum>"))
   call s:NetrwBrowse(a:islocal,s:NetrwBrowseChgDir(a:islocal,s:NetrwGetWord()))
  endif
"  call Dret("s:TreeSqueezeDir")
endfun

" ---------------------------------------------------------------------
" s:NetrwMaps: {{{2
fun! s:NetrwMaps(islocal)
"  call Dfunc("s:NetrwMaps(islocal=".a:islocal.") b:netrw_curdir<".b:netrw_curdir.">")

  if g:netrw_mousemaps && g:netrw_retmap
"   call Decho("set up Rexplore 2-leftmouse",'~'.expand("<slnum>"))
   if !hasmapto("<Plug>NetrwReturn")
    if maparg("<2-leftmouse>","n") == "" || maparg("<2-leftmouse>","n") =~ '^-$'
"     call Decho("making map for 2-leftmouse",'~'.expand("<slnum>"))
     nmap <unique> <silent> <2-leftmouse>	<Plug>NetrwReturn
    elseif maparg("<c-leftmouse>","n") == ""
"     call Decho("making map for c-leftmouse",'~'.expand("<slnum>"))
     nmap <unique> <silent> <c-leftmouse>	<Plug>NetrwReturn
    endif
   endif
   nno <silent> <Plug>NetrwReturn	:Rexplore<cr>
"   call Decho("made <Plug>NetrwReturn map",'~'.expand("<slnum>"))
  endif

  if a:islocal
"   call Decho("make local maps",'~'.expand("<slnum>"))
   " local normal-mode maps
   nnoremap <buffer> <silent> <nowait> a	:call <SID>NetrwHide(1)<cr>
   nnoremap <buffer> <silent> <nowait> %	:call <SID>NetrwOpenFile(1)<cr>
   nnoremap <buffer> <silent> <nowait> c	:call <SID>NetrwLcd(b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> C	:<c-u>call <SID>NetrwSetChgwin()<cr>
   nnoremap <buffer> <silent> <nowait> <cr>	:call netrw#LocalBrowseCheck(<SID>NetrwBrowseChgDir(1,<SID>NetrwGetWord()))<cr>
   nnoremap <buffer> <silent> <nowait> <s-cr>	:call <SID>TreeSqueezeDir(1)<cr>
   nnoremap <buffer> <silent> <nowait> <c-r>	:call <SID>NetrwServerEdit(3,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> d	:call <SID>NetrwMakeDir("")<cr>
   nnoremap <buffer> <silent> <nowait> -	:call <SID>NetrwBrowseUpDir(1)<cr>
   nnoremap <buffer> <silent> <nowait> gb	:<c-u>call <SID>NetrwBookHistHandler(1,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> gd	:<c-u>call <SID>NetrwForceChgDir(1,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> gf	:<c-u>call <SID>NetrwForceFile(1,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> gh	:<c-u>call <SID>NetrwHidden(1)<cr>
   nnoremap <buffer> <silent> <nowait> gn	:<c-u>call netrw#SetTreetop(<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> gp	:<c-u>call <SID>NetrwChgPerm(1,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> I	:call <SID>NetrwBannerCtrl(1)<cr>
   nnoremap <buffer> <silent> <nowait> i	:call <SID>NetrwListStyle(1)<cr>
   nnoremap <buffer> <silent> <nowait> mb	:<c-u>call <SID>NetrwBookHistHandler(0,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> mB	:<c-u>call <SID>NetrwBookHistHandler(6,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> mc	:<c-u>call <SID>NetrwMarkFileCopy(1)<cr>
   nnoremap <buffer> <silent> <nowait> md	:<c-u>call <SID>NetrwMarkFileDiff(1)<cr>
   nnoremap <buffer> <silent> <nowait> me	:<c-u>call <SID>NetrwMarkFileEdit(1)<cr>
   nnoremap <buffer> <silent> <nowait> mf	:<c-u>call <SID>NetrwMarkFile(1,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> mF	:<c-u>call <SID>NetrwUnmarkList(bufnr("%"),b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> mg	:<c-u>call <SID>NetrwMarkFileGrep(1)<cr>
   nnoremap <buffer> <silent> <nowait> mh	:<c-u>call <SID>NetrwMarkHideSfx(1)<cr>
   nnoremap <buffer> <silent> <nowait> mm	:<c-u>call <SID>NetrwMarkFileMove(1)<cr>
   nnoremap <buffer> <silent> <nowait> mp	:<c-u>call <SID>NetrwMarkFilePrint(1)<cr>
   nnoremap <buffer> <silent> <nowait> mr	:<c-u>call <SID>NetrwMarkFileRegexp(1)<cr>
   nnoremap <buffer> <silent> <nowait> ms	:<c-u>call <SID>NetrwMarkFileSource(1)<cr>
   nnoremap <buffer> <silent> <nowait> mt	:<c-u>call <SID>NetrwMarkFileTgt(1)<cr>
   nnoremap <buffer> <silent> <nowait> mT	:<c-u>call <SID>NetrwMarkFileTag(1)<cr>
   nnoremap <buffer> <silent> <nowait> mu	:<c-u>call <SID>NetrwUnMarkFile(1)<cr>
   nnoremap <buffer> <silent> <nowait> mv	:<c-u>call <SID>NetrwMarkFileVimCmd(1)<cr>
   nnoremap <buffer> <silent> <nowait> mx	:<c-u>call <SID>NetrwMarkFileExe(1,0)<cr>
   nnoremap <buffer> <silent> <nowait> mX	:<c-u>call <SID>NetrwMarkFileExe(1,1)<cr>
   nnoremap <buffer> <silent> <nowait> mz	:<c-u>call <SID>NetrwMarkFileCompress(1)<cr>
   nnoremap <buffer> <silent> <nowait> O	:call <SID>NetrwObtain(1)<cr>
   nnoremap <buffer> <silent> <nowait> o	:call <SID>NetrwSplit(3)<cr>
   nnoremap <buffer> <silent> <nowait> p	:call <SID>NetrwPreview(<SID>NetrwBrowseChgDir(1,<SID>NetrwGetWord(),1))<cr>
   nnoremap <buffer> <silent> <nowait> P	:call <SID>NetrwPrevWinOpen(1)<cr>
   nnoremap <buffer> <silent> <nowait> qb	:<c-u>call <SID>NetrwBookHistHandler(2,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> qf	:<c-u>call <SID>NetrwFileInfo(1,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> qF	:<c-u>call <SID>NetrwMarkFileQFEL(1,getqflist())<cr>
   nnoremap <buffer> <silent> <nowait> r	:let g:netrw_sort_direction= (g:netrw_sort_direction =~ 'n')? 'r' : 'n'<bar>exe "norm! 0"<bar>call <SID>NetrwRefresh(1,<SID>NetrwBrowseChgDir(1,'./'))<cr>
   nnoremap <buffer> <silent> <nowait> s	:call <SID>NetrwSortStyle(1)<cr>
   nnoremap <buffer> <silent> <nowait> S	:call <SID>NetSortSequence(1)<cr>
   nnoremap <buffer> <silent> <nowait> t	:call <SID>NetrwSplit(4)<cr>
   nnoremap <buffer> <silent> <nowait> Tb	:<c-u>call <SID>NetrwSetTgt('b',v:count1)<cr>
   nnoremap <buffer> <silent> <nowait> Th	:<c-u>call <SID>NetrwSetTgt('h',v:count)<cr>
   nnoremap <buffer> <silent> <nowait> u	:<c-u>call <SID>NetrwBookHistHandler(4,expand("%"))<cr>
   nnoremap <buffer> <silent> <nowait> U	:<c-u>call <SID>NetrwBookHistHandler(5,expand("%"))<cr>
   nnoremap <buffer> <silent> <nowait> v	:call <SID>NetrwSplit(5)<cr>
   nnoremap <buffer> <silent> <nowait> x	:call netrw#BrowseX(<SID>NetrwBrowseChgDir(1,<SID>NetrwGetWord(),0),0)"<cr>
   nnoremap <buffer> <silent> <nowait> X	:call <SID>NetrwLocalExecute(expand("<cword>"))"<cr>
   " local insert-mode maps
   inoremap <buffer> <silent> <nowait> a	<c-o>:call <SID>NetrwHide(1)<cr>
   inoremap <buffer> <silent> <nowait> c	<c-o>:exe "NetrwKeepj lcd ".fnameescape(b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> c	<c-o>:call <SID>NetrwLcd(b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> C	<c-o>:call <SID>NetrwSetChgwin()<cr>
   inoremap <buffer> <silent> <nowait> %	<c-o>:call <SID>NetrwOpenFile(1)<cr>
   inoremap <buffer> <silent> <nowait> -	<c-o>:call <SID>NetrwBrowseUpDir(1)<cr>
   inoremap <buffer> <silent> <nowait> <cr>	<c-o>:call netrw#LocalBrowseCheck(<SID>NetrwBrowseChgDir(1,<SID>NetrwGetWord()))<cr>
   inoremap <buffer> <silent> <nowait> <s-cr>	<c-o>:call <SID>TreeSqueezeDir(1)<cr>
   inoremap <buffer> <silent> <nowait> d	<c-o>:call <SID>NetrwMakeDir("")<cr>
   inoremap <buffer> <silent> <nowait> gb	<c-o>:<c-u>call <SID>NetrwBookHistHandler(1,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> gh	<c-o>:<c-u>call <SID>NetrwHidden(1)<cr>
   nnoremap <buffer> <silent> <nowait> gn	:<c-u>call netrw#SetTreetop(<SID>NetrwGetWord())<cr>
   inoremap <buffer> <silent> <nowait> gp	<c-o>:<c-u>call <SID>NetrwChgPerm(1,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> I	<c-o>:call <SID>NetrwBannerCtrl(1)<cr>
   inoremap <buffer> <silent> <nowait> i	<c-o>:call <SID>NetrwListStyle(1)<cr>
   inoremap <buffer> <silent> <nowait> mb	<c-o>:<c-u>call <SID>NetrwBookHistHandler(0,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> mB	<c-o>:<c-u>call <SID>NetrwBookHistHandler(6,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> mc	<c-o>:<c-u>call <SID>NetrwMarkFileCopy(1)<cr>
   inoremap <buffer> <silent> <nowait> md	<c-o>:<c-u>call <SID>NetrwMarkFileDiff(1)<cr>
   inoremap <buffer> <silent> <nowait> me	<c-o>:<c-u>call <SID>NetrwMarkFileEdit(1)<cr>
   inoremap <buffer> <silent> <nowait> mf	<c-o>:<c-u>call <SID>NetrwMarkFile(1,<SID>NetrwGetWord())<cr>
   inoremap <buffer> <silent> <nowait> mg	<c-o>:<c-u>call <SID>NetrwMarkFileGrep(1)<cr>
   inoremap <buffer> <silent> <nowait> mh	<c-o>:<c-u>call <SID>NetrwMarkHideSfx(1)<cr>
   inoremap <buffer> <silent> <nowait> mm	<c-o>:<c-u>call <SID>NetrwMarkFileMove(1)<cr>
   inoremap <buffer> <silent> <nowait> mp	<c-o>:<c-u>call <SID>NetrwMarkFilePrint(1)<cr>
   inoremap <buffer> <silent> <nowait> mr	<c-o>:<c-u>call <SID>NetrwMarkFileRegexp(1)<cr>
   inoremap <buffer> <silent> <nowait> ms	<c-o>:<c-u>call <SID>NetrwMarkFileSource(1)<cr>
   inoremap <buffer> <silent> <nowait> mT	<c-o>:<c-u>call <SID>NetrwMarkFileTag(1)<cr>
   inoremap <buffer> <silent> <nowait> mt	<c-o>:<c-u>call <SID>NetrwMarkFileTgt(1)<cr>
   inoremap <buffer> <silent> <nowait> mu	<c-o>:<c-u>call <SID>NetrwUnMarkFile(1)<cr>
   inoremap <buffer> <silent> <nowait> mv	<c-o>:<c-u>call <SID>NetrwMarkFileVimCmd(1)<cr>
   inoremap <buffer> <silent> <nowait> mx	<c-o>:<c-u>call <SID>NetrwMarkFileExe(1,0)<cr>
   inoremap <buffer> <silent> <nowait> mX	<c-o>:<c-u>call <SID>NetrwMarkFileExe(1,1)<cr>
   inoremap <buffer> <silent> <nowait> mz	<c-o>:<c-u>call <SID>NetrwMarkFileCompress(1)<cr>
   inoremap <buffer> <silent> <nowait> O	<c-o>:call <SID>NetrwObtain(1)<cr>
   inoremap <buffer> <silent> <nowait> o	<c-o>:call <SID>NetrwSplit(3)<cr>
   inoremap <buffer> <silent> <nowait> p	<c-o>:call <SID>NetrwPreview(<SID>NetrwBrowseChgDir(1,<SID>NetrwGetWord(),1))<cr>
   inoremap <buffer> <silent> <nowait> P	<c-o>:call <SID>NetrwPrevWinOpen(1)<cr>
   inoremap <buffer> <silent> <nowait> qb	<c-o>:<c-u>call <SID>NetrwBookHistHandler(2,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> qf	<c-o>:<c-u>call <SID>NetrwFileInfo(1,<SID>NetrwGetWord())<cr>
   inoremap <buffer> <silent> <nowait> qF	:<c-u>call <SID>NetrwMarkFileQFEL(1,getqflist())<cr>
   inoremap <buffer> <silent> <nowait> r	<c-o>:let g:netrw_sort_direction= (g:netrw_sort_direction =~ 'n')? 'r' : 'n'<bar>exe "norm! 0"<bar>call <SID>NetrwRefresh(1,<SID>NetrwBrowseChgDir(1,'./'))<cr>
   inoremap <buffer> <silent> <nowait> s	<c-o>:call <SID>NetrwSortStyle(1)<cr>
   inoremap <buffer> <silent> <nowait> S	<c-o>:call <SID>NetSortSequence(1)<cr>
   inoremap <buffer> <silent> <nowait> t	<c-o>:call <SID>NetrwSplit(4)<cr>
   inoremap <buffer> <silent> <nowait> Tb	<c-o>:<c-u>call <SID>NetrwSetTgt('b',v:count1)<cr>
   inoremap <buffer> <silent> <nowait> Th	<c-o>:<c-u>call <SID>NetrwSetTgt('h',v:count)<cr>
   inoremap <buffer> <silent> <nowait> u	<c-o>:<c-u>call <SID>NetrwBookHistHandler(4,expand("%"))<cr>
   inoremap <buffer> <silent> <nowait> U	<c-o>:<c-u>call <SID>NetrwBookHistHandler(5,expand("%"))<cr>
   inoremap <buffer> <silent> <nowait> v	<c-o>:call <SID>NetrwSplit(5)<cr>
   inoremap <buffer> <silent> <nowait> x	<c-o>:call netrw#BrowseX(<SID>NetrwBrowseChgDir(1,<SID>NetrwGetWord(),0),0)"<cr>
   if !hasmapto('<Plug>NetrwHideEdit')
    nmap <buffer> <unique> <c-h> <Plug>NetrwHideEdit
    imap <buffer> <unique> <c-h> <Plug>NetrwHideEdit
   endif
   nnoremap <buffer> <silent> <Plug>NetrwHideEdit	:call <SID>NetrwHideEdit(1)<cr>
   if !hasmapto('<Plug>NetrwRefresh')
    nmap <buffer> <unique> <c-l> <Plug>NetrwRefresh
    imap <buffer> <unique> <c-l> <Plug>NetrwRefresh
   endif
   nnoremap <buffer> <silent> <Plug>NetrwRefresh		:call <SID>NetrwRefresh(1,<SID>NetrwBrowseChgDir(1,(w:netrw_liststyle == 3)? w:netrw_treetop : './'))<cr>
   if s:didstarstar || !mapcheck("<s-down>","n")
    nnoremap <buffer> <silent> <s-down>	:Nexplore<cr>
    inoremap <buffer> <silent> <s-down>	:Nexplore<cr>
   endif
   if s:didstarstar || !mapcheck("<s-up>","n")
    nnoremap <buffer> <silent> <s-up>	:Pexplore<cr>
    inoremap <buffer> <silent> <s-up>	:Pexplore<cr>
   endif
   let mapsafecurdir = escape(b:netrw_curdir, s:netrw_map_escape)
   if g:netrw_mousemaps == 1
    nmap <buffer> <leftmouse>   	<Plug>NetrwLeftmouse
    nno  <buffer> <silent>		<Plug>NetrwLeftmouse	<leftmouse>:call <SID>NetrwLeftmouse(1)<cr>
    nmap <buffer> <c-leftmouse>		<Plug>NetrwCLeftmouse
    nno  <buffer> <silent>		<Plug>NetrwCLeftmouse	<leftmouse>:call <SID>NetrwCLeftmouse(1)<cr>
    nmap <buffer> <middlemouse>		<Plug>NetrwMiddlemouse
    nno  <buffer> <silent>		<Plug>NetrwMiddlemouse	<leftmouse>:call <SID>NetrwPrevWinOpen(1)<cr>
    nmap <buffer> <s-leftmouse>		<Plug>NetrwSLeftmouse
    nno  <buffer> <silent>		<Plug>NetrwSLeftmouse 	<leftmouse>:call <SID>NetrwSLeftmouse(1)<cr>
    nmap <buffer> <s-leftdrag>		<Plug>NetrwSLeftdrag
    nno  <buffer> <silent>		<Plug>NetrwSLeftdrag	<leftmouse>:call <SID>NetrwSLeftdrag(1)<cr>
    nmap <buffer> <2-leftmouse>		<Plug>Netrw2Leftmouse
    nmap <buffer> <silent>		<Plug>Netrw2Leftmouse	-
    imap <buffer> <leftmouse>		<Plug>ILeftmouse
    ino  <buffer> <silent>		<Plug>ILeftmouse	<c-o><leftmouse><c-o>:call <SID>NetrwLeftmouse(1)<cr>
    imap <buffer> <middlemouse>		<Plug>IMiddlemouse
    ino  <buffer> <silent>		<Plug>IMiddlemouse	<c-o><leftmouse><c-o>:call <SID>NetrwPrevWinOpen(1)<cr>
    imap <buffer> <s-leftmouse>		<Plug>ISLeftmouse
    ino  <buffer> <silent>		<Plug>ISLeftmouse	<c-o><leftmouse><c-o>:call <SID>NetrwMarkFile(1,<SID>NetrwGetWord())<cr>
    exe 'nnoremap <buffer> <silent> <rightmouse>  <leftmouse>:call <SID>NetrwLocalRm("'.mapsafecurdir.'")<cr>'
    exe 'vnoremap <buffer> <silent> <rightmouse>  <leftmouse>:call <SID>NetrwLocalRm("'.mapsafecurdir.'")<cr>'
    exe 'inoremap <buffer> <silent> <rightmouse>  <c-o><leftmouse><c-o>:call <SID>NetrwLocalRm("'.mapsafecurdir.'")<cr>'
   endif
   exe 'nnoremap <buffer> <silent> <nowait> <del>	:call <SID>NetrwLocalRm("'.mapsafecurdir.'")<cr>'
   exe 'nnoremap <buffer> <silent> <nowait> D		:call <SID>NetrwLocalRm("'.mapsafecurdir.'")<cr>'
   exe 'nnoremap <buffer> <silent> <nowait> R		:call <SID>NetrwLocalRename("'.mapsafecurdir.'")<cr>'
   exe 'nnoremap <buffer> <silent> <nowait> d		:call <SID>NetrwMakeDir("")<cr>'
   exe 'vnoremap <buffer> <silent> <nowait> <del>	:call <SID>NetrwLocalRm("'.mapsafecurdir.'")<cr>'
   exe 'vnoremap <buffer> <silent> <nowait> D		:call <SID>NetrwLocalRm("'.mapsafecurdir.'")<cr>'
   exe 'vnoremap <buffer> <silent> <nowait> R		:call <SID>NetrwLocalRename("'.mapsafecurdir.'")<cr>'
   exe 'inoremap <buffer> <silent> <nowait> <del>	<c-o>:call <SID>NetrwLocalRm("'.mapsafecurdir.'")<cr>'
   exe 'inoremap <buffer> <silent> <nowait> D		<c-o>:call <SID>NetrwLocalRm("'.mapsafecurdir.'")<cr>'
   exe 'inoremap <buffer> <silent> <nowait> R		<c-o>:call <SID>NetrwLocalRename("'.mapsafecurdir.'")<cr>'
   exe 'inoremap <buffer> <silent> <nowait> d		<c-o>:call <SID>NetrwMakeDir("")<cr>'
   nnoremap <buffer> <F1>			:he netrw-quickhelp<cr>

   " support user-specified maps
   call netrw#UserMaps(1)

  else " remote
"   call Decho("make remote maps",'~'.expand("<slnum>"))
   call s:RemotePathAnalysis(b:netrw_curdir)
   " remote normal-mode maps
   nnoremap <buffer> <silent> <nowait> <cr>	:call <SID>NetrwBrowse(0,<SID>NetrwBrowseChgDir(0,<SID>NetrwGetWord()))<cr>
   nnoremap <buffer> <silent> <nowait> <s-cr>	:call <SID>TreeSqueezeDir(0)<cr>
   nnoremap <buffer> <silent> <nowait> <c-l>	:call <SID>NetrwRefresh(0,<SID>NetrwBrowseChgDir(0,'./'))<cr>
   nnoremap <buffer> <silent> <nowait> <c-r>	:call <SID>NetrwServerEdit(2,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> -	:call <SID>NetrwBrowseUpDir(0)<cr>
   nnoremap <buffer> <silent> <nowait> a	:call <SID>NetrwHide(0)<cr>
   nnoremap <buffer> <silent> <nowait> mb	:<c-u>call <SID>NetrwBookHistHandler(0,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> mc	:<c-u>call <SID>NetrwMarkFileCopy(0)<cr>
   nnoremap <buffer> <silent> <nowait> md	:<c-u>call <SID>NetrwMarkFileDiff(0)<cr>
   nnoremap <buffer> <silent> <nowait> me	:<c-u>call <SID>NetrwMarkFileEdit(0)<cr>
   nnoremap <buffer> <silent> <nowait> mf	:<c-u>call <SID>NetrwMarkFile(0,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> mF	:<c-u>call <SID>NetrwUnmarkList(bufnr("%"),b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> mg	:<c-u>call <SID>NetrwMarkFileGrep(0)<cr>
   nnoremap <buffer> <silent> <nowait> mh	:<c-u>call <SID>NetrwMarkHideSfx(0)<cr>
   nnoremap <buffer> <silent> <nowait> mm	:<c-u>call <SID>NetrwMarkFileMove(0)<cr>
   nnoremap <buffer> <silent> <nowait> mp	:<c-u>call <SID>NetrwMarkFilePrint(0)<cr>
   nnoremap <buffer> <silent> <nowait> mr	:<c-u>call <SID>NetrwMarkFileRegexp(0)<cr>
   nnoremap <buffer> <silent> <nowait> ms	:<c-u>call <SID>NetrwMarkFileSource(0)<cr>
   nnoremap <buffer> <silent> <nowait> mt	:<c-u>call <SID>NetrwMarkFileTgt(0)<cr>
   nnoremap <buffer> <silent> <nowait> mT	:<c-u>call <SID>NetrwMarkFileTag(0)<cr>
   nnoremap <buffer> <silent> <nowait> mu	:<c-u>call <SID>NetrwUnMarkFile(0)<cr>
   nnoremap <buffer> <silent> <nowait> mv	:<c-u>call <SID>NetrwMarkFileVimCmd(0)<cr>
   nnoremap <buffer> <silent> <nowait> mx	:<c-u>call <SID>NetrwMarkFileExe(0,0)<cr>
   nnoremap <buffer> <silent> <nowait> mX	:<c-u>call <SID>NetrwMarkFileExe(0,1)<cr>
   nnoremap <buffer> <silent> <nowait> mz	:<c-u>call <SID>NetrwMarkFileCompress(0)<cr>
   nnoremap <buffer> <silent> <nowait> gb	:<c-u>call <SID>NetrwBookHistHandler(1,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> gd	:<c-u>call <SID>NetrwForceChgDir(0,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> gf	:<c-u>call <SID>NetrwForceFile(0,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> gh	:<c-u>call <SID>NetrwHidden(0)<cr>
   nnoremap <buffer> <silent> <nowait> gp	:<c-u>call <SID>NetrwChgPerm(0,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> C		:<c-u>call <SID>NetrwSetChgwin()<cr>
   nnoremap <buffer> <silent> <nowait> i		:call <SID>NetrwListStyle(0)<cr>
   nnoremap <buffer> <silent> <nowait> I		:call <SID>NetrwBannerCtrl(1)<cr>
   nnoremap <buffer> <silent> <nowait> o		:call <SID>NetrwSplit(0)<cr>
   nnoremap <buffer> <silent> <nowait> O		:call <SID>NetrwObtain(0)<cr>
   nnoremap <buffer> <silent> <nowait> p		:call <SID>NetrwPreview(<SID>NetrwBrowseChgDir(1,<SID>NetrwGetWord(),1))<cr>
   nnoremap <buffer> <silent> <nowait> P		:call <SID>NetrwPrevWinOpen(0)<cr>
   nnoremap <buffer> <silent> <nowait> qb	:<c-u>call <SID>NetrwBookHistHandler(2,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> mB	:<c-u>call <SID>NetrwBookHistHandler(6,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> qf	:<c-u>call <SID>NetrwFileInfo(0,<SID>NetrwGetWord())<cr>
   nnoremap <buffer> <silent> <nowait> qF	:<c-u>call <SID>NetrwMarkFileQFEL(0,getqflist())<cr>
   nnoremap <buffer> <silent> <nowait> r		:let g:netrw_sort_direction= (g:netrw_sort_direction =~ 'n')? 'r' : 'n'<bar>exe "norm! 0"<bar>call <SID>NetrwBrowse(0,<SID>NetrwBrowseChgDir(0,'./'))<cr>
   nnoremap <buffer> <silent> <nowait> s		:call <SID>NetrwSortStyle(0)<cr>
   nnoremap <buffer> <silent> <nowait> S		:call <SID>NetSortSequence(0)<cr>
   nnoremap <buffer> <silent> <nowait> t		:call <SID>NetrwSplit(1)<cr>
   nnoremap <buffer> <silent> <nowait> Tb	:<c-u>call <SID>NetrwSetTgt('b',v:count1)<cr>
   nnoremap <buffer> <silent> <nowait> Th	:<c-u>call <SID>NetrwSetTgt('h',v:count)<cr>
   nnoremap <buffer> <silent> <nowait> u		:<c-u>call <SID>NetrwBookHistHandler(4,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> U		:<c-u>call <SID>NetrwBookHistHandler(5,b:netrw_curdir)<cr>
   nnoremap <buffer> <silent> <nowait> v		:call <SID>NetrwSplit(2)<cr>
   nnoremap <buffer> <silent> <nowait> x		:call netrw#BrowseX(<SID>NetrwBrowseChgDir(0,<SID>NetrwGetWord()),1)<cr>
   nnoremap <buffer> <silent> <nowait> %		:call <SID>NetrwOpenFile(0)<cr>
   " remote insert-mode maps
   inoremap <buffer> <silent> <nowait> <cr>	<c-o>:call <SID>NetrwBrowse(0,<SID>NetrwBrowseChgDir(0,<SID>NetrwGetWord()))<cr>
   inoremap <buffer> <silent> <nowait> <c-l>	<c-o>:call <SID>NetrwRefresh(0,<SID>NetrwBrowseChgDir(0,'./'))<cr>
   inoremap <buffer> <silent> <nowait> <s-cr>	<c-o>:call <SID>TreeSqueezeDir(0)<cr>
   inoremap <buffer> <silent> <nowait> -		<c-o>:call <SID>NetrwBrowseUpDir(0)<cr>
   inoremap <buffer> <silent> <nowait> a		<c-o>:call <SID>NetrwHide(0)<cr>
   inoremap <buffer> <silent> <nowait> mb	<c-o>:<c-u>call <SID>NetrwBookHistHandler(0,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> mc	<c-o>:<c-u>call <SID>NetrwMarkFileCopy(0)<cr>
   inoremap <buffer> <silent> <nowait> md	<c-o>:<c-u>call <SID>NetrwMarkFileDiff(0)<cr>
   inoremap <buffer> <silent> <nowait> me	<c-o>:<c-u>call <SID>NetrwMarkFileEdit(0)<cr>
   inoremap <buffer> <silent> <nowait> mf	<c-o>:<c-u>call <SID>NetrwMarkFile(0,<SID>NetrwGetWord())<cr>
   inoremap <buffer> <silent> <nowait> mg	<c-o>:<c-u>call <SID>NetrwMarkFileGrep(0)<cr>
   inoremap <buffer> <silent> <nowait> mh	<c-o>:<c-u>call <SID>NetrwMarkHideSfx(0)<cr>
   inoremap <buffer> <silent> <nowait> mm	<c-o>:<c-u>call <SID>NetrwMarkFileMove(0)<cr>
   inoremap <buffer> <silent> <nowait> mp	<c-o>:<c-u>call <SID>NetrwMarkFilePrint(0)<cr>
   inoremap <buffer> <silent> <nowait> mr	<c-o>:<c-u>call <SID>NetrwMarkFileRegexp(0)<cr>
   inoremap <buffer> <silent> <nowait> ms	<c-o>:<c-u>call <SID>NetrwMarkFileSource(0)<cr>
   inoremap <buffer> <silent> <nowait> mt	<c-o>:<c-u>call <SID>NetrwMarkFileTgt(0)<cr>
   inoremap <buffer> <silent> <nowait> mT	<c-o>:<c-u>call <SID>NetrwMarkFileTag(0)<cr>
   inoremap <buffer> <silent> <nowait> mu	<c-o>:<c-u>call <SID>NetrwUnMarkFile(0)<cr>
   nnoremap <buffer> <silent> <nowait> mv	:<c-u>call <SID>NetrwMarkFileVimCmd(1)<cr>
   inoremap <buffer> <silent> <nowait> mx	<c-o>:<c-u>call <SID>NetrwMarkFileExe(0,0)<cr>
   inoremap <buffer> <silent> <nowait> mX	<c-o>:<c-u>call <SID>NetrwMarkFileExe(0,1)<cr>
   inoremap <buffer> <silent> <nowait> mv	<c-o>:<c-u>call <SID>NetrwMarkFileVimCmd(0)<cr>
   inoremap <buffer> <silent> <nowait> mz	<c-o>:<c-u>call <SID>NetrwMarkFileCompress(0)<cr>
   inoremap <buffer> <silent> <nowait> gb	<c-o>:<c-u>call <SID>NetrwBookHistHandler(1,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> gh	<c-o>:<c-u>call <SID>NetrwHidden(0)<cr>
   inoremap <buffer> <silent> <nowait> gp	<c-o>:<c-u>call <SID>NetrwChgPerm(0,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> C		<c-o>:call <SID>NetrwSetChgwin()<cr>
   inoremap <buffer> <silent> <nowait> i		<c-o>:call <SID>NetrwListStyle(0)<cr>
   inoremap <buffer> <silent> <nowait> I		<c-o>:call <SID>NetrwBannerCtrl(1)<cr>
   inoremap <buffer> <silent> <nowait> o		<c-o>:call <SID>NetrwSplit(0)<cr>
   inoremap <buffer> <silent> <nowait> O		<c-o>:call <SID>NetrwObtain(0)<cr>
   inoremap <buffer> <silent> <nowait> p		<c-o>:call <SID>NetrwPreview(<SID>NetrwBrowseChgDir(1,<SID>NetrwGetWord(),1))<cr>
   inoremap <buffer> <silent> <nowait> P		<c-o>:call <SID>NetrwPrevWinOpen(0)<cr>
   inoremap <buffer> <silent> <nowait> qb	<c-o>:<c-u>call <SID>NetrwBookHistHandler(2,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> mB	<c-o>:<c-u>call <SID>NetrwBookHistHandler(6,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> qf	<c-o>:<c-u>call <SID>NetrwFileInfo(0,<SID>NetrwGetWord())<cr>
   inoremap <buffer> <silent> <nowait> qF	:<c-u>call <SID>NetrwMarkFileQFEL(0,getqflist())<cr>
   inoremap <buffer> <silent> <nowait> r		<c-o>:let g:netrw_sort_direction= (g:netrw_sort_direction =~ 'n')? 'r' : 'n'<bar>exe "norm! 0"<bar>call <SID>NetrwBrowse(0,<SID>NetrwBrowseChgDir(0,'./'))<cr>
   inoremap <buffer> <silent> <nowait> s		<c-o>:call <SID>NetrwSortStyle(0)<cr>
   inoremap <buffer> <silent> <nowait> S		<c-o>:call <SID>NetSortSequence(0)<cr>
   inoremap <buffer> <silent> <nowait> t		<c-o>:call <SID>NetrwSplit(1)<cr>
   inoremap <buffer> <silent> <nowait> Tb	<c-o>:<c-u>call <SID>NetrwSetTgt('b',v:count1)<cr>
   inoremap <buffer> <silent> <nowait> Th	<c-o>:<c-u>call <SID>NetrwSetTgt('h',v:count)<cr>
   inoremap <buffer> <silent> <nowait> u		<c-o>:<c-u>call <SID>NetrwBookHistHandler(4,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> U		<c-o>:<c-u>call <SID>NetrwBookHistHandler(5,b:netrw_curdir)<cr>
   inoremap <buffer> <silent> <nowait> v		<c-o>:call <SID>NetrwSplit(2)<cr>
   inoremap <buffer> <silent> <nowait> x		<c-o>:call netrw#BrowseX(<SID>NetrwBrowseChgDir(0,<SID>NetrwGetWord()),1)<cr>
   inoremap <buffer> <silent> <nowait> %		<c-o>:call <SID>NetrwOpenFile(0)<cr>
   if !hasmapto('<Plug>NetrwHideEdit')
    nmap <buffer> <c-h> <Plug>NetrwHideEdit
    imap <buffer> <c-h> <Plug>NetrwHideEdit
   endif
   nnoremap <buffer> <silent> <Plug>NetrwHideEdit	:call <SID>NetrwHideEdit(0)<cr>
   if !hasmapto('<Plug>NetrwRefresh')
    nmap <buffer> <c-l> <Plug>NetrwRefresh
    imap <buffer> <c-l> <Plug>NetrwRefresh
   endif

   let mapsafepath     = escape(s:path, s:netrw_map_escape)
   let mapsafeusermach = escape(((s:user == "")? "" : s:user."@").s:machine, s:netrw_map_escape)

   nnoremap <buffer> <silent> <Plug>NetrwRefresh	:call <SID>NetrwRefresh(0,<SID>NetrwBrowseChgDir(0,'./'))<cr>
   if g:netrw_mousemaps == 1
    nmap <buffer> <leftmouse>		<Plug>NetrwLeftmouse
    nno  <buffer> <silent>		<Plug>NetrwLeftmouse	<leftmouse>:call <SID>NetrwLeftmouse(0)<cr>
    nmap <buffer> <c-leftmouse>		<Plug>NetrwCLeftmouse
    nno  <buffer> <silent>		<Plug>NetrwCLeftmouse	<leftmouse>:call <SID>NetrwCLeftmouse(0)<cr>
    nmap <buffer> <s-leftmouse>		<Plug>NetrwSLeftmouse
    nno  <buffer> <silent>		<Plug>NetrwSLeftmouse 	<leftmouse>:call <SID>NetrwSLeftmouse(0)<cr>
    nmap <buffer> <s-leftdrag>		<Plug>NetrwSLeftdrag
    nno  <buffer> <silent>		<Plug>NetrwSLeftdrag	<leftmouse>:call <SID>NetrwSLeftdrag(0)<cr>
    nmap <middlemouse>			<Plug>NetrwMiddlemouse
    nno  <buffer> <silent>		<middlemouse>		<Plug>NetrwMiddlemouse <leftmouse>:call <SID>NetrwPrevWinOpen(0)<cr>
    nmap <buffer> <2-leftmouse>		<Plug>Netrw2Leftmouse
    nmap <buffer> <silent>		<Plug>Netrw2Leftmouse	-
    imap <buffer> <leftmouse>		<Plug>ILeftmouse
    ino  <buffer> <silent>		<Plug>ILeftmouse	<c-o><leftmouse><c-o>:call <SID>NetrwLeftmouse(0)<cr>
    imap <buffer> <middlemouse>		<Plug>IMiddlemouse
    ino  <buffer> <silent>		<Plug>IMiddlemouse	<c-o><leftmouse><c-o>:call <SID>NetrwPrevWinOpen(0)<cr>
    imap <buffer> <s-leftmouse>		<Plug>ISLeftmouse
    ino  <buffer> <silent>		<Plug>ISLeftmouse	<c-o><leftmouse><c-o>:call <SID>NetrwMarkFile(0,<SID>NetrwGetWord())<cr>
    exe 'nnoremap <buffer> <silent> <rightmouse> <leftmouse>:call <SID>NetrwRemoteRm("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
    exe 'vnoremap <buffer> <silent> <rightmouse> <leftmouse>:call <SID>NetrwRemoteRm("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
    exe 'inoremap <buffer> <silent> <rightmouse> <c-o><leftmouse><c-o>:call <SID>NetrwRemoteRm("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   endif
   exe 'nnoremap <buffer> <silent> <nowait> <del>	:call <SID>NetrwRemoteRm("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   exe 'nnoremap <buffer> <silent> <nowait> d		:call <SID>NetrwMakeDir("'.mapsafeusermach.'")<cr>'
   exe 'nnoremap <buffer> <silent> <nowait> D		:call <SID>NetrwRemoteRm("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   exe 'nnoremap <buffer> <silent> <nowait> R		:call <SID>NetrwRemoteRename("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   exe 'vnoremap <buffer> <silent> <nowait> <del>	:call <SID>NetrwRemoteRm("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   exe 'vnoremap <buffer> <silent> <nowait> D		:call <SID>NetrwRemoteRm("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   exe 'vnoremap <buffer> <silent> <nowait> R		:call <SID>NetrwRemoteRename("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   exe 'inoremap <buffer> <silent> <nowait> <del>	<c-o>:call <SID>NetrwRemoteRm("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   exe 'inoremap <buffer> <silent> <nowait> d		<c-o>:call <SID>NetrwMakeDir("'.mapsafeusermach.'")<cr>'
   exe 'inoremap <buffer> <silent> <nowait> D		<c-o>:call <SID>NetrwRemoteRm("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   exe 'inoremap <buffer> <silent> <nowait> R		<c-o>:call <SID>NetrwRemoteRename("'.mapsafeusermach.'","'.mapsafepath.'")<cr>'
   nnoremap <buffer> <F1>			:he netrw-quickhelp<cr>
   inoremap <buffer> <F1>			<c-o>:he netrw-quickhelp<cr>

   " support user-specified maps
   call netrw#UserMaps(0)
  endif

"  call Dret("s:NetrwMaps")
endfun

" ---------------------------------------------------------------------
" s:NetrwCommands: sets up commands 				{{{2
"  If -buffer, the command is only available from within netrw buffers
"  Otherwise, the command is available from any window, so long as netrw
"  has been used at least once in the session.
fun! s:NetrwCommands(islocal)
"  call Dfunc("s:NetrwCommands(islocal=".a:islocal.")")

  com! -nargs=* -complete=file -bang	NetrwMB	call s:NetrwBookmark(<bang>0,<f-args>)
  com! -nargs=*			    	NetrwC	call s:NetrwSetChgwin(<q-args>)
  com! Rexplore if exists("w:netrw_rexlocal")|call s:NetrwRexplore(w:netrw_rexlocal,exists("w:netrw_rexdir")? w:netrw_rexdir : ".")|else|call netrw#ErrorMsg(s:WARNING,"not a former netrw window",79)|endif
  if a:islocal
   com! -buffer -nargs=+ -complete=file	MF	call s:NetrwMarkFiles(1,<f-args>)
  else
   com! -buffer -nargs=+ -complete=file	MF	call s:NetrwMarkFiles(0,<f-args>)
  endif
  com! -buffer -nargs=? -complete=file	MT	call s:NetrwMarkTarget(<q-args>)

"  call Dret("s:NetrwCommands")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFiles: apply s:NetrwMarkFile() to named file(s) {{{2
"                   glob()ing only works with local files
fun! s:NetrwMarkFiles(islocal,...)
"  call Dfunc("s:NetrwMarkFiles(islocal=".a:islocal."...) a:0=".a:0)
  let curdir = s:NetrwGetCurdir(a:islocal)
  let i      = 1
  while i <= a:0
   if a:islocal
    if v:version == 704 && has("patch656")
     let mffiles= glob(a:{i},0,1,1)
    else
     let mffiles= glob(a:{i},0,1)
    endif
   else
    let mffiles= [a:{i}]
   endif
"   call Decho("mffiles".string(mffiles),'~'.expand("<slnum>"))
   for mffile in mffiles
"    call Decho("mffile<".mffile.">",'~'.expand("<slnum>"))
    call s:NetrwMarkFile(a:islocal,mffile)
   endfor
   let i= i + 1
  endwhile
"  call Dret("s:NetrwMarkFiles")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkTarget: implements :MT (mark target) {{{2
fun! s:NetrwMarkTarget(...)
"  call Dfunc("s:NetrwMarkTarget() a:0=".a:0)
  if a:0 == 0 || (a:0 == 1 && a:1 == "")
   let curdir = s:NetrwGetCurdir(1)
   let tgt    = b:netrw_curdir
  else
   let curdir = s:NetrwGetCurdir((a:1 =~ '^\a\{3,}://')? 0 : 1)
   let tgt    = a:1
  endif
"  call Decho("tgt<".tgt.">",'~'.expand("<slnum>"))
  let s:netrwmftgt         = tgt
  let s:netrwmftgt_islocal = tgt !~ '^\a\{3,}://'
  let curislocal           = b:netrw_curdir !~ '^\a\{3,}://'
  let svpos                = netrw#SavePosn()
  call s:NetrwRefresh(curislocal,s:NetrwBrowseChgDir(curislocal,'./'))
  call netrw#RestorePosn(svpos)
"  call Dret("s:NetrwMarkTarget")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFile: (invoked by mf) This function is used to both {{{2
"                  mark and unmark files.  If a markfile list exists,
"                  then the rename and delete functions will use it instead
"                  of whatever may happen to be under the cursor at that
"                  moment.  When the mouse and gui are available,
"                  shift-leftmouse may also be used to mark files.
"
"  Creates two lists
"    s:netrwmarkfilelist    -- holds complete paths to all marked files
"    s:netrwmarkfilelist_#  -- holds list of marked files in current-buffer's directory (#==bufnr())
"
"  Creates a marked file match string
"    s:netrwmarfilemtch_#   -- used with 2match to display marked files
"
"  Creates a buffer version of islocal
"    b:netrw_islocal
fun! s:NetrwMarkFile(islocal,fname)
"  call Dfunc("s:NetrwMarkFile(islocal=".a:islocal." fname<".a:fname.">)")
"  call Decho("bufnr(%)=".bufnr("%").": ".bufname("%"),'~'.expand("<slnum>"))

  " sanity check
  if empty(a:fname)
"   call Dret("s:NetrwMarkFile : emtpy fname")
   return
  endif
  let curdir = s:NetrwGetCurdir(a:islocal)

  let ykeep   = @@
  let curbufnr= bufnr("%")
  if a:fname =~ '^\a'
   let leader= '\<'
  else
   let leader= ''
  endif
  if a:fname =~ '\a$'
   let trailer = '\>[@=|\/\*]\=\ze\%(  \|\t\|$\)'
  else
   let trailer = '[@=|\/\*]\=\ze\%(  \|\t\|$\)'
  endif

  if exists("s:netrwmarkfilelist_".curbufnr)
   " markfile list pre-exists
"   call Decho("case s:netrwmarkfilelist_".curbufnr." already exists",'~'.expand("<slnum>"))
"   call Decho("starting s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}).">",'~'.expand("<slnum>"))
"   call Decho("starting s:netrwmarkfilemtch_".curbufnr."<".s:netrwmarkfilemtch_{curbufnr}.">",'~'.expand("<slnum>"))
   let b:netrw_islocal= a:islocal

   if index(s:netrwmarkfilelist_{curbufnr},a:fname) == -1
    " append filename to buffer's markfilelist
"    call Decho("append filename<".a:fname."> to local markfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}).">",'~'.expand("<slnum>"))
    call add(s:netrwmarkfilelist_{curbufnr},a:fname)
    let s:netrwmarkfilemtch_{curbufnr}= s:netrwmarkfilemtch_{curbufnr}.'\|'.leader.escape(a:fname,g:netrw_markfileesc).trailer

   else
    " remove filename from buffer's markfilelist
"    call Decho("remove filename<".a:fname."> from local markfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}).">",'~'.expand("<slnum>"))
    call filter(s:netrwmarkfilelist_{curbufnr},'v:val != a:fname')
    if s:netrwmarkfilelist_{curbufnr} == []
     " local markfilelist is empty; remove it entirely
"     call Decho("markfile list now empty",'~'.expand("<slnum>"))
     call s:NetrwUnmarkList(curbufnr,curdir)
    else
     " rebuild match list to display markings correctly
"     call Decho("rebuild s:netrwmarkfilemtch_".curbufnr,'~'.expand("<slnum>"))
     let s:netrwmarkfilemtch_{curbufnr}= ""
     let first                         = 1
     for fname in s:netrwmarkfilelist_{curbufnr}
      if first
       let s:netrwmarkfilemtch_{curbufnr}= s:netrwmarkfilemtch_{curbufnr}.leader.escape(fname,g:netrw_markfileesc).trailer
      else
       let s:netrwmarkfilemtch_{curbufnr}= s:netrwmarkfilemtch_{curbufnr}.'\|'.leader.escape(fname,g:netrw_markfileesc).trailer
      endif
      let first= 0
     endfor
"     call Decho("ending s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}).">",'~'.expand("<slnum>"))
    endif
   endif

  else
   " initialize new markfilelist
"   call Decho("case: initialize new markfilelist",'~'.expand("<slnum>"))

"   call Decho("add fname<".a:fname."> to new markfilelist_".curbufnr,'~'.expand("<slnum>"))
   let s:netrwmarkfilelist_{curbufnr}= []
   call add(s:netrwmarkfilelist_{curbufnr},substitute(a:fname,'[|@]$','',''))
"   call Decho("ending s:netrwmarkfilelist_{curbufnr}<".string(s:netrwmarkfilelist_{curbufnr}).">",'~'.expand("<slnum>"))

   " build initial markfile matching pattern
   if a:fname =~ '/$'
    let s:netrwmarkfilemtch_{curbufnr}= leader.escape(a:fname,g:netrw_markfileesc)
   else
    let s:netrwmarkfilemtch_{curbufnr}= leader.escape(a:fname,g:netrw_markfileesc).trailer
   endif
"   call Decho("ending s:netrwmarkfilemtch_".curbufnr."<".s:netrwmarkfilemtch_{curbufnr}.">",'~'.expand("<slnum>"))
  endif

  " handle global markfilelist
  if exists("s:netrwmarkfilelist")
   let dname= s:ComposePath(b:netrw_curdir,a:fname)
   if index(s:netrwmarkfilelist,dname) == -1
    " append new filename to global markfilelist
    call add(s:netrwmarkfilelist,s:ComposePath(b:netrw_curdir,a:fname))
"    call Decho("append filename<".a:fname."> to global markfilelist<".string(s:netrwmarkfilelist).">",'~'.expand("<slnum>"))
   else
    " remove new filename from global markfilelist
"    call Decho("filter(".string(s:netrwmarkfilelist).",'v:val != '.".dname.")",'~'.expand("<slnum>"))
    call filter(s:netrwmarkfilelist,'v:val != "'.dname.'"')
"    call Decho("ending s:netrwmarkfilelist  <".string(s:netrwmarkfilelist).">",'~'.expand("<slnum>"))
    if s:netrwmarkfilelist == []
     unlet s:netrwmarkfilelist
    endif
   endif
  else
   " initialize new global-directory markfilelist
   let s:netrwmarkfilelist= []
   call add(s:netrwmarkfilelist,s:ComposePath(b:netrw_curdir,a:fname))
"   call Decho("init s:netrwmarkfilelist<".string(s:netrwmarkfilelist).">",'~'.expand("<slnum>"))
  endif

  " set up 2match'ing to netrwmarkfilemtch_# list
  if exists("s:netrwmarkfilemtch_{curbufnr}") && s:netrwmarkfilemtch_{curbufnr} != ""
"   call Decho("exe 2match netrwMarkFile /".s:netrwmarkfilemtch_{curbufnr}."/",'~'.expand("<slnum>"))
   if exists("g:did_drchip_netrwlist_syntax")
    exe "2match netrwMarkFile /".s:netrwmarkfilemtch_{curbufnr}."/"
   endif
  else
"   call Decho("2match none",'~'.expand("<slnum>"))
   2match none
  endif
  let @@= ykeep
"  call Dret("s:NetrwMarkFile : s:netrwmarkfilelist_".curbufnr."<".(exists("s:netrwmarkfilelist_{curbufnr}")? string(s:netrwmarkfilelist_{curbufnr}) : " doesn't exist").">")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileCompress: (invoked by mz) This function is used to {{{2
"                          compress/decompress files using the programs
"                          in g:netrw_compress and g:netrw_uncompress,
"                          using g:netrw_compress_suffix to know which to
"                          do.  By default:
"                            g:netrw_compress        = "gzip"
"                            g:netrw_decompress      = { ".gz" : "gunzip" , ".bz2" : "bunzip2" , ".zip" : "unzip" , ".tar" : "tar -xf", ".xz" : "unxz"}
fun! s:NetrwMarkFileCompress(islocal)
"  call Dfunc("s:NetrwMarkFileCompress(islocal=".a:islocal.")")
  let svpos    = netrw#SavePosn()
  let curdir   = s:NetrwGetCurdir(a:islocal)
  let curbufnr = bufnr("%")

  " sanity check
  if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
   NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"   call Dret("s:NetrwMarkFileCompress")
   return
  endif
"  call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))

  if exists("s:netrwmarkfilelist_{curbufnr}") && exists("g:netrw_compress") && exists("g:netrw_decompress")

   " for every filename in the marked list
   for fname in s:netrwmarkfilelist_{curbufnr}
    let sfx= substitute(fname,'^.\{-}\(\.\a\+\)$','\1','')
"    call Decho("extracted sfx<".sfx.">",'~'.expand("<slnum>"))
    if exists("g:netrw_decompress['".sfx."']")
     " fname has a suffix indicating that its compressed; apply associated decompression routine
     let exe= g:netrw_decompress[sfx]
"     call Decho("fname<".fname."> is compressed so decompress with <".exe.">",'~'.expand("<slnum>"))
     let exe= netrw#WinPath(exe)
     if a:islocal
      if g:netrw_keepdir
       let fname= shellescape(s:ComposePath(curdir,fname))
      endif
     else
      let fname= shellescape(b:netrw_curdir.fname,1)
     endif
     if executable(exe)
      if a:islocal
       call system(exe." ".fname)
      else
       NetrwKeepj call s:RemoteSystem(exe." ".fname)
      endif
     else
      NetrwKeepj call netrw#ErrorMsg(s:WARNING,"unable to apply<".exe."> to file<".fname.">",50)
     endif
    endif
    unlet sfx

    if exists("exe")
     unlet exe
    elseif a:islocal
     " fname not a compressed file, so compress it
     call system(netrw#WinPath(g:netrw_compress)." ".shellescape(s:ComposePath(b:netrw_curdir,fname)))
    else
     " fname not a compressed file, so compress it
     NetrwKeepj call s:RemoteSystem(netrw#WinPath(g:netrw_compress)." ".shellescape(fname))
    endif
   endfor	" for every file in the marked list

   call s:NetrwUnmarkList(curbufnr,curdir)
   NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
   NetrwKeepj call netrw#RestorePosn(svpos)
  endif
"  call Dret("s:NetrwMarkFileCompress")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileCopy: (invoked by mc) copy marked files to target {{{2
"                      If no marked files, then set up directory as the
"                      target.  Currently does not support copying entire
"                      directories.  Uses the local-buffer marked file list.
"                      Returns 1=success  (used by NetrwMarkFileMove())
"                              0=failure
fun! s:NetrwMarkFileCopy(islocal,...)
"  call Dfunc("s:NetrwMarkFileCopy(islocal=".a:islocal.") target<".(exists("s:netrwmftgt")? s:netrwmftgt : '---')."> a:0=".a:0)

  let curdir   = s:NetrwGetCurdir(a:islocal)
  let curbufnr = bufnr("%")

  " sanity check
  if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
   NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"   call Dret("s:NetrwMarkFileCopy")
   return
  endif
"  call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))

  if !exists("s:netrwmftgt")
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"your marked file target is empty! (:help netrw-mt)",67)
"   call Dret("s:NetrwMarkFileCopy 0")
   return 0
  endif
"  call Decho("sanity chk passed: s:netrwmftgt<".s:netrwmftgt.">",'~'.expand("<slnum>"))

  if      a:islocal &&  s:netrwmftgt_islocal
   " Copy marked files, local directory to local directory
"   call Decho("copy from local to local",'~'.expand("<slnum>"))
   if !executable(g:netrw_localcopycmd) && g:netrw_localcopycmd !~ '^'.expand("$COMSPEC").'\s'
    call netrw#ErrorMsg(s:ERROR,"g:netrw_localcopycmd<".g:netrw_localcopycmd."> not executable on your system, aborting",91)
"    call Dfunc("s:NetrwMarkFileMove : g:netrw_localcopycmd<".g:netrw_localcopycmd."> n/a!")
    return
   endif

   " copy marked files while within the same directory (ie. allow renaming)
   if simplify(s:netrwmftgt) == simplify(b:netrw_curdir)
    if len(s:netrwmarkfilelist_{bufnr('%')}) == 1
     " only one marked file
"     call Decho("case: only one marked file",'~'.expand("<slnum>"))
     let args    = shellescape(b:netrw_curdir."/".s:netrwmarkfilelist_{bufnr('%')}[0])
     let oldname = s:netrwmarkfilelist_{bufnr('%')}[0]
    elseif a:0 == 1
"     call Decho("case: handling one input argument",'~'.expand("<slnum>"))
     " this happens when the next case was used to recursively call s:NetrwMarkFileCopy()
     let args    = shellescape(b:netrw_curdir."/".a:1)
     let oldname = a:1
    else
     " copy multiple marked files inside the same directory
"     call Decho("case: handling a multiple marked files",'~'.expand("<slnum>"))
     let s:recursive= 1
     for oldname in s:netrwmarkfilelist_{bufnr("%")}
      let ret= s:NetrwMarkFileCopy(a:islocal,oldname)
      if ret == 0
       break
      endif
     endfor
     unlet s:recursive
     call s:NetrwUnmarkList(curbufnr,curdir)
"     call Dret("s:NetrwMarkFileCopy ".ret)
     return ret
    endif

    call inputsave()
    let newname= input("Copy ".oldname." to : ",oldname,"file")
    call inputrestore()
    if newname == ""
"     call Dret("s:NetrwMarkFileCopy 0")
     return 0
    endif
    let args= shellescape(oldname)
    let tgt = shellescape(s:netrwmftgt.'/'.newname)
   else
    let args= join(map(deepcopy(s:netrwmarkfilelist_{bufnr('%')}),"shellescape(b:netrw_curdir.\"/\".v:val)"))
    let tgt = shellescape(s:netrwmftgt)
   endif
   if !g:netrw_cygwin && (has("win32") || has("win95") || has("win64") || has("win16"))
    let args= substitute(args,'/','\\','g')
    let tgt = substitute(tgt, '/','\\','g')
   endif
   if args =~ "'"|let args= substitute(args,"'\\(.*\\)'",'\1','')|endif
   if tgt  =~ "'"|let tgt = substitute(tgt,"'\\(.*\\)'",'\1','') |endif
   if args =~ '//$'|let args= substitute(args,'//$','/','')|endif
   if isdirectory(s:NetrwFile(args))
"    call Decho("args<".args."> is a directory",'~'.expand("<slnum>"))
    let copycmd= g:netrw_localcopydircmd
"    call Decho("using copydircmd<".copycmd.">",'~'.expand("<slnum>"))
    if !g:netrw_cygwin && (has("win32") || has("win95") || has("win64") || has("win16"))
     " window's xcopy doesn't copy a directory to a target properly.  Instead, it copies a directory's
     " contents to a target.  One must append the source directory name to the target to get xcopy to
     " do the right thing.
     let tgt= tgt.'\'.substitute(a:1,'^.*[\\/]','','')
"     call Decho("modified tgt for xcopy",'~'.expand("<slnum>"))
    endif
   else
    let copycmd= g:netrw_localcopycmd
   endif
   if g:netrw_localcopycmd =~ '\s'
    let copycmd     = substitute(copycmd,'\s.*$','','')
    let copycmdargs = substitute(copycmd,'^.\{-}\(\s.*\)$','\1','')
    let copycmd     = netrw#WinPath(copycmd).copycmdargs
   else
    let copycmd = netrw#WinPath(copycmd)
   endif
"   call Decho("args   <".args.">",'~'.expand("<slnum>"))
"   call Decho("tgt    <".tgt.">",'~'.expand("<slnum>"))
"   call Decho("copycmd<".copycmd.">",'~'.expand("<slnum>"))
"   call Decho("system(".copycmd." '".args."' '".tgt."')",'~'.expand("<slnum>"))
   call system(copycmd." '".args."' '".tgt."'")
   if v:shell_error != 0
    call netrw#ErrorMsg(s:ERROR,"tried using g:netrw_localcopycmd<".g:netrw_localcopycmd.">; it doesn't work!",80)
"    call Dret("s:NetrwMarkFileCopy 0 : failed: system(".g:netrw_localcopycmd." ".args." ".shellescape(s:netrwmftgt))
    return 0
   endif

  elseif  a:islocal && !s:netrwmftgt_islocal
   " Copy marked files, local directory to remote directory
"   call Decho("copy from local to remote",'~'.expand("<slnum>"))
   NetrwKeepj call s:NetrwUpload(s:netrwmarkfilelist_{bufnr('%')},s:netrwmftgt)

  elseif !a:islocal &&  s:netrwmftgt_islocal
   " Copy marked files, remote directory to local directory
"   call Decho("copy from remote to local",'~'.expand("<slnum>"))
   NetrwKeepj call netrw#Obtain(a:islocal,s:netrwmarkfilelist_{bufnr('%')},s:netrwmftgt)

  elseif !a:islocal && !s:netrwmftgt_islocal
   " Copy marked files, remote directory to remote directory
"   call Decho("copy from remote to remote",'~'.expand("<slnum>"))
   let curdir = getcwd()
   let tmpdir = s:GetTempfile("")
   if tmpdir !~ '/'
    let tmpdir= curdir."/".tmpdir
   endif
   if exists("*mkdir")
    call mkdir(tmpdir)
   else
    call s:NetrwExe("sil! !".g:netrw_localmkdir.' '.shellescape(tmpdir,1))
    if v:shell_error != 0
     call netrw#ErrorMsg(s:WARNING,"consider setting g:netrw_localmkdir<".g:netrw_localmkdir."> to something that works",80)
"     call Dret("s:NetrwMarkFileCopy : failed: sil! !".g:netrw_localmkdir.' '.shellescape(tmpdir,1) )
     return
    endif
   endif
   if isdirectory(s:NetrwFile(tmpdir))
    call s:NetrwLcd(tmpdir)
    NetrwKeepj call netrw#Obtain(a:islocal,s:netrwmarkfilelist_{bufnr('%')},tmpdir)
    let localfiles= map(deepcopy(s:netrwmarkfilelist_{bufnr('%')}),'substitute(v:val,"^.*/","","")')
    NetrwKeepj call s:NetrwUpload(localfiles,s:netrwmftgt)
    if getcwd() == tmpdir
     for fname in s:netrwmarkfilelist_{bufnr('%')}
      NetrwKeepj call s:NetrwDelete(fname)
     endfor
     call s:NetrwLcd(curdir)
     call s:NetrwExe("sil !".g:netrw_localrmdir." ".shellescape(tmpdir,1))
     if v:shell_error != 0
      call netrw#ErrorMsg(s:WARNING,"consider setting g:netrw_localrmdir<".g:netrw_localrmdir."> to something that works",80)
"      call Dret("s:NetrwMarkFileCopy : failed: sil !".g:netrw_localrmdir." ".shellescape(tmpdir,1) )
      return
     endif
    else
     call s:NetrwLcd(curdir)
    endif
   endif
  endif

  " -------
  " cleanup
  " -------
"   call Decho("cleanup",'~'.expand("<slnum>"))
  if !exists("s:recursive")
   " remove markings from local buffer
   call s:NetrwUnmarkList(curbufnr,curdir)
  endif

  " refresh buffers
  if !s:netrwmftgt_islocal
   call s:NetrwRefreshDir(s:netrwmftgt_islocal,s:netrwmftgt)
  endif
  if a:islocal
   NetrwKeepj call s:NetrwRefreshDir(a:islocal,curdir)
  endif
  if g:netrw_fastbrowse <= 1
   NetrwKeepj call s:LocalBrowseRefresh()
  endif

"  call Dret("s:NetrwMarkFileCopy 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileDiff: (invoked by md) This function is used to {{{2
"                      invoke vim's diff mode on the marked files.
"                      Either two or three files can be so handled.
"                      Uses the global marked file list.
fun! s:NetrwMarkFileDiff(islocal)
"  call Dfunc("s:NetrwMarkFileDiff(islocal=".a:islocal.") b:netrw_curdir<".b:netrw_curdir.">")
  let curbufnr= bufnr("%")

  " sanity check
  if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
   NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"   call Dret("s:NetrwMarkFileDiff")
   return
  endif
  let curdir= s:NetrwGetCurdir(a:islocal)
"  call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))

  if exists("s:netrwmarkfilelist_{".curbufnr."}")
   let cnt    = 0
   for fname in s:netrwmarkfilelist
    let cnt= cnt + 1
    if cnt == 1
"     call Decho("diffthis: fname<".fname.">",'~'.expand("<slnum>"))
     exe "NetrwKeepj e ".fnameescape(fname)
     diffthis
    elseif cnt == 2 || cnt == 3
     vsplit
     wincmd l
"     call Decho("diffthis: ".fname,'~'.expand("<slnum>"))
     exe "NetrwKeepj e ".fnameescape(fname)
     diffthis
    else
     break
    endif
   endfor
   call s:NetrwUnmarkList(curbufnr,curdir)
  endif

"  call Dret("s:NetrwMarkFileDiff")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileEdit: (invoked by me) put marked files on arg list and start editing them {{{2
"                       Uses global markfilelist
fun! s:NetrwMarkFileEdit(islocal)
"  call Dfunc("s:NetrwMarkFileEdit(islocal=".a:islocal.")")

  let curdir   = s:NetrwGetCurdir(a:islocal)
  let curbufnr = bufnr("%")

  " sanity check
  if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
   NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"   call Dret("s:NetrwMarkFileEdit")
   return
  endif
"  call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))

  if exists("s:netrwmarkfilelist_{curbufnr}")
   call s:SetRexDir(a:islocal,curdir)
   let flist= join(map(deepcopy(s:netrwmarkfilelist), "fnameescape(v:val)"))
   " unmark markedfile list
"   call s:NetrwUnmarkList(curbufnr,curdir)
   call s:NetrwUnmarkAll()
"   call Decho("exe sil args ".flist,'~'.expand("<slnum>"))
   exe "sil args ".flist
  endif
  echo "(use :bn, :bp to navigate files; :Rex to return)"

"  call Dret("s:NetrwMarkFileEdit")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileQFEL: convert a quickfix-error list into a marked file list {{{2
fun! s:NetrwMarkFileQFEL(islocal,qfel)
"  call Dfunc("s:NetrwMarkFileQFEL(islocal=".a:islocal.",qfel)")
  call s:NetrwUnmarkAll()
  let curbufnr= bufnr("%")

  if !empty(a:qfel)
   for entry in a:qfel
    let bufnmbr= entry["bufnr"]
"    call Decho("bufname(".bufnmbr.")<".bufname(bufnmbr)."> line#".entry["lnum"]." text=".entry["text"],'~'.expand("<slnum>"))
    if !exists("s:netrwmarkfilelist_{curbufnr}")
"     call Decho("case: no marked file list",'~'.expand("<slnum>"))
     call s:NetrwMarkFile(a:islocal,bufname(bufnmbr))
    elseif index(s:netrwmarkfilelist_{curbufnr},bufname(bufnmbr)) == -1
     " s:NetrwMarkFile will remove duplicate entries from the marked file list.
     " So, this test lets two or more hits on the same pattern to be ignored.
"     call Decho("case: ".bufname(bufnmbr)." not currently in marked file list",'~'.expand("<slnum>"))
     call s:NetrwMarkFile(a:islocal,bufname(bufnmbr))
    else
"     call Decho("case: ".bufname(bufnmbr)." already in marked file list",'~'.expand("<slnum>"))
    endif
   endfor
   echo "(use me to edit marked files)"
  else
   call netrw#ErrorMsg(s:WARNING,"can't convert quickfix error list; its empty!",92)
  endif

"  call Dret("s:NetrwMarkFileQFEL")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileExe: (invoked by mx and mX) execute arbitrary system command on marked files {{{2
"                     mx enbloc=0: Uses the local marked-file list, applies command to each file individually
"                     mX enbloc=1: Uses the global marked-file list, applies command to entire list
fun! s:NetrwMarkFileExe(islocal,enbloc)
"  call Dfunc("s:NetrwMarkFileExe(islocal=".a:islocal.",enbloc=".a:enbloc.")")
  let svpos    = netrw#SavePosn()
  let curdir   = s:NetrwGetCurdir(a:islocal)
  let curbufnr = bufnr("%")

  if a:enbloc == 0
   " individually apply command to files, one at a time
    " sanity check
    if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
     NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"     call Dret("s:NetrwMarkFileExe")
     return
    endif
"    call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))

    if exists("s:netrwmarkfilelist_{curbufnr}")
     " get the command
     call inputsave()
     let cmd= input("Enter command: ","","file")
     call inputrestore()
"     call Decho("cmd<".cmd.">",'~'.expand("<slnum>"))
     if cmd == ""
"      call Dret("s:NetrwMarkFileExe : early exit, empty command")
      return
     endif

     " apply command to marked files, individually.  Substitute: filename -> %
     " If no %, then append a space and the filename to the command
     for fname in s:netrwmarkfilelist_{curbufnr}
      if a:islocal
       if g:netrw_keepdir
	let fname= shellescape(netrw#WinPath(s:ComposePath(curdir,fname)))
       endif
      else
       let fname= shellescape(netrw#WinPath(b:netrw_curdir.fname))
      endif
      if cmd =~ '%'
       let xcmd= substitute(cmd,'%',fname,'g')
      else
       let xcmd= cmd.' '.fname
      endif
      if a:islocal
"       call Decho("local: xcmd<".xcmd.">",'~'.expand("<slnum>"))
       let ret= system(xcmd)
      else
"       call Decho("remote: xcmd<".xcmd.">",'~'.expand("<slnum>"))
       let ret= s:RemoteSystem(xcmd)
      endif
      if v:shell_error < 0
       NetrwKeepj call netrw#ErrorMsg(s:ERROR,"command<".xcmd."> failed, aborting",54)
       break
      else
       echo ret
      endif
     endfor

   " unmark marked file list
   call s:NetrwUnmarkList(curbufnr,curdir)

   " refresh the listing
   NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
   NetrwKeepj call netrw#RestorePosn(svpos)
  else
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"no files marked!",59)
  endif

 else " apply command to global list of files, en bloc

  call inputsave()
  let cmd= input("Enter command: ","","file")
  call inputrestore()
"  call Decho("cmd<".cmd.">",'~'.expand("<slnum>"))
  if cmd == ""
"   call Dret("s:NetrwMarkFileExe : early exit, empty command")
   return
  endif
  if cmd =~ '%'
   let cmd= substitute(cmd,'%',join(map(s:netrwmarkfilelist,'shellescape(v:val)'),' '),'g')
  else
   let cmd= cmd.' '.join(map(s:netrwmarkfilelist,'shellescape(v:val)'),' ')
  endif
  if a:islocal
   call system(cmd)
   if v:shell_error < 0
    NetrwKeepj call netrw#ErrorMsg(s:ERROR,"command<".xcmd."> failed, aborting",54)
   endif
  else
   let ret= s:RemoteSystem(cmd)
  endif
  call s:NetrwUnmarkAll()

  " refresh the listing
  NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  NetrwKeepj call netrw#RestorePosn(svpos)

 endif

"  call Dret("s:NetrwMarkFileExe")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkHideSfx: (invoked by mh) (un)hide files having same suffix
"                  as the marked file(s) (toggles suffix presence)
"                  Uses the local marked file list.
fun! s:NetrwMarkHideSfx(islocal)
"  call Dfunc("s:NetrwMarkHideSfx(islocal=".a:islocal.")")
  let svpos    = netrw#SavePosn()
  let curbufnr = bufnr("%")

  " s:netrwmarkfilelist_{curbufnr}: the List of marked files
  if exists("s:netrwmarkfilelist_{curbufnr}")

   for fname in s:netrwmarkfilelist_{curbufnr}
"     call Decho("s:NetrwMarkFileCopy: fname<".fname.">",'~'.expand("<slnum>"))
     " construct suffix pattern
     if fname =~ '\.'
      let sfxpat= "^.*".substitute(fname,'^.*\(\.[^. ]\+\)$','\1','')
     else
      let sfxpat= '^\%(\%(\.\)\@!.\)*$'
     endif
     " determine if its in the hiding list or not
     let inhidelist= 0
     if g:netrw_list_hide != ""
      let itemnum = 0
      let hidelist= split(g:netrw_list_hide,',')
      for hidepat in hidelist
       if sfxpat == hidepat
        let inhidelist= 1
        break
       endif
       let itemnum= itemnum + 1
      endfor
     endif
"     call Decho("fname<".fname."> inhidelist=".inhidelist." sfxpat<".sfxpat.">",'~'.expand("<slnum>"))
     if inhidelist
      " remove sfxpat from list
      call remove(hidelist,itemnum)
      let g:netrw_list_hide= join(hidelist,",")
     elseif g:netrw_list_hide != ""
      " append sfxpat to non-empty list
      let g:netrw_list_hide= g:netrw_list_hide.",".sfxpat
     else
      " set hiding list to sfxpat
      let g:netrw_list_hide= sfxpat
     endif
    endfor

   " refresh the listing
   NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
   NetrwKeepj call netrw#RestorePosn(svpos)
  else
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"no files marked!",59)
  endif

"  call Dret("s:NetrwMarkHideSfx")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileVimCmd: (invoked by mv) execute arbitrary vim command on marked files, one at a time {{{2
"                     Uses the local marked-file list.
fun! s:NetrwMarkFileVimCmd(islocal)
"  call Dfunc("s:NetrwMarkFileVimCmd(islocal=".a:islocal.")")
  let svpos    = netrw#SavePosn()
  let curdir   = s:NetrwGetCurdir(a:islocal)
  let curbufnr = bufnr("%")

  " sanity check
  if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
   NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"   call Dret("s:NetrwMarkFileVimCmd")
   return
  endif
"  call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))

  if exists("s:netrwmarkfilelist_{curbufnr}")
   " get the command
   call inputsave()
   let cmd= input("Enter vim command: ","","file")
   call inputrestore()
"   call Decho("cmd<".cmd.">",'~'.expand("<slnum>"))
   if cmd == ""
"    "   call Dret("s:NetrwMarkFileVimCmd : early exit, empty command")
    return
   endif

   " apply command to marked files.  Substitute: filename -> %
   " If no %, then append a space and the filename to the command
   for fname in s:netrwmarkfilelist_{curbufnr}
"    call Decho("fname<".fname.">",'~'.expand("<slnum>"))
    if a:islocal
     1split
     exe "sil! NetrwKeepj keepalt e ".fnameescape(fname)
"     call Decho("local<".fname.">: exe ".cmd,'~'.expand("<slnum>"))
     exe cmd
     exe "sil! keepalt wq!"
    else
"     call Decho("remote<".fname.">: exe ".cmd." : NOT SUPPORTED YET",'~'.expand("<slnum>"))
     echo "sorry, \"mv\" not supported yet for remote files"
    endif
   endfor

   " unmark marked file list
   call s:NetrwUnmarkList(curbufnr,curdir)

   " refresh the listing
   NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
   NetrwKeepj call netrw#RestorePosn(svpos)
  else
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"no files marked!",59)
  endif

"  call Dret("s:NetrwMarkFileVimCmd")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkHideSfx: (invoked by mh) (un)hide files having same suffix
"                  as the marked file(s) (toggles suffix presence)
"                  Uses the local marked file list.
fun! s:NetrwMarkHideSfx(islocal)
"  call Dfunc("s:NetrwMarkHideSfx(islocal=".a:islocal.")")
  let svpos    = netrw#SavePosn()
  let curbufnr = bufnr("%")

  " s:netrwmarkfilelist_{curbufnr}: the List of marked files
  if exists("s:netrwmarkfilelist_{curbufnr}")

   for fname in s:netrwmarkfilelist_{curbufnr}
"     call Decho("s:NetrwMarkFileCopy: fname<".fname.">",'~'.expand("<slnum>"))
     " construct suffix pattern
     if fname =~ '\.'
      let sfxpat= "^.*".substitute(fname,'^.*\(\.[^. ]\+\)$','\1','')
     else
      let sfxpat= '^\%(\%(\.\)\@!.\)*$'
     endif
     " determine if its in the hiding list or not
     let inhidelist= 0
     if g:netrw_list_hide != ""
      let itemnum = 0
      let hidelist= split(g:netrw_list_hide,',')
      for hidepat in hidelist
       if sfxpat == hidepat
        let inhidelist= 1
        break
       endif
       let itemnum= itemnum + 1
      endfor
     endif
"     call Decho("fname<".fname."> inhidelist=".inhidelist." sfxpat<".sfxpat.">",'~'.expand("<slnum>"))
     if inhidelist
      " remove sfxpat from list
      call remove(hidelist,itemnum)
      let g:netrw_list_hide= join(hidelist,",")
     elseif g:netrw_list_hide != ""
      " append sfxpat to non-empty list
      let g:netrw_list_hide= g:netrw_list_hide.",".sfxpat
     else
      " set hiding list to sfxpat
      let g:netrw_list_hide= sfxpat
     endif
    endfor

   " refresh the listing
   NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
   NetrwKeepj call netrw#RestorePosn(svpos)
  else
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"no files marked!",59)
  endif

"  call Dret("s:NetrwMarkHideSfx")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileGrep: (invoked by mg) This function applies vimgrep to marked files {{{2
"                     Uses the global markfilelist
fun! s:NetrwMarkFileGrep(islocal)
"  call Dfunc("s:NetrwMarkFileGrep(islocal=".a:islocal.")")
  let svpos    = netrw#SavePosn()
  let curbufnr = bufnr("%")
  let curdir   = s:NetrwGetCurdir(a:islocal)

  if exists("s:netrwmarkfilelist")
"  call Decho("s:netrwmarkfilelist".string(s:netrwmarkfilelist).">",'~'.expand("<slnum>"))
   let netrwmarkfilelist= join(map(deepcopy(s:netrwmarkfilelist), "fnameescape(v:val)"))
   call s:NetrwUnmarkAll()
  else
"   call Decho('no marked files, using "*"','~'.expand("<slnum>"))
   let netrwmarkfilelist= "*"
  endif

  " ask user for pattern
  call inputsave()
  let pat= input("Enter pattern: ","")
  call inputrestore()
  let patbang = ""
  if pat =~ '^!'
   let patbang = "!"
   let pat     = strpart(pat,2)
  endif
  if pat =~ '^\i'
   let pat    = escape(pat,'/')
   let pat    = '/'.pat.'/'
  else
   let nonisi = pat[0]
  endif

  " use vimgrep for both local and remote
"  call Decho("exe vimgrep".patbang." ".pat." ".netrwmarkfilelist,'~'.expand("<slnum>"))
  try
   exe "NetrwKeepj noautocmd vimgrep".patbang." ".pat." ".netrwmarkfilelist
  catch /^Vim\%((\a\+)\)\=:E480/
   NetrwKeepj call netrw#ErrorMsg(s:WARNING,"no match with pattern<".pat.">",76)
"   call Dret("s:NetrwMarkFileGrep : unable to find pattern<".pat.">")
   return
  endtry
  echo "(use :cn, :cp to navigate, :Rex to return)"

  2match none
  NetrwKeepj call netrw#RestorePosn(svpos)

  if exists("nonisi")
   " original, user-supplied pattern did not begin with a character from isident
"   call Decho("looking for trailing nonisi<".nonisi."> followed by a j, gj, or jg",'~'.expand("<slnum>"))
   if pat =~ nonisi.'j$\|'.nonisi.'gj$\|'.nonisi.'jg$'
    call s:NetrwMarkFileQFEL(a:islocal,getqflist())
   endif
  endif

"  call Dret("s:NetrwMarkFileGrep")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileMove: (invoked by mm) execute arbitrary command on marked files, one at a time {{{2
"                      uses the global marked file list
"                      s:netrwmfloc= 0: target directory is remote
"                                  = 1: target directory is local
fun! s:NetrwMarkFileMove(islocal)
"  call Dfunc("s:NetrwMarkFileMove(islocal=".a:islocal.")")
  let curdir   = s:NetrwGetCurdir(a:islocal)
  let curbufnr = bufnr("%")

  " sanity check
  if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
   NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"   call Dret("s:NetrwMarkFileMove")
   return
  endif
"  call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))

  if !exists("s:netrwmftgt")
   NetrwKeepj call netrw#ErrorMsg(2,"your marked file target is empty! (:help netrw-mt)",67)
"   call Dret("s:NetrwMarkFileCopy 0")
   return 0
  endif
"  call Decho("sanity chk passed: s:netrwmftgt<".s:netrwmftgt.">",'~'.expand("<slnum>"))

  if      a:islocal &&  s:netrwmftgt_islocal
   " move: local -> local
"   call Decho("move from local to local",'~'.expand("<slnum>"))
"   call Decho("local to local move",'~'.expand("<slnum>"))
   if !executable(g:netrw_localmovecmd) && g:netrw_localmovecmd !~ '^'.expand("$COMSPEC").'\s'
    call netrw#ErrorMsg(s:ERROR,"g:netrw_localmovecmd<".g:netrw_localmovecmd."> not executable on your system, aborting",90)
"    call Dfunc("s:NetrwMarkFileMove : g:netrw_localmovecmd<".g:netrw_localmovecmd."> n/a!")
    return
   endif
   let tgt         = shellescape(s:netrwmftgt)
"   call Decho("tgt<".tgt.">",'~'.expand("<slnum>"))
   if !g:netrw_cygwin && (has("win32") || has("win95") || has("win64") || has("win16"))
    let tgt         = substitute(tgt, '/','\\','g')
"    call Decho("windows exception: tgt<".tgt.">",'~'.expand("<slnum>"))
    if g:netrw_localmovecmd =~ '\s'
     let movecmd     = substitute(g:netrw_localmovecmd,'\s.*$','','')
     let movecmdargs = substitute(g:netrw_localmovecmd,'^.\{-}\(\s.*\)$','\1','')
     let movecmd     = netrw#WinPath(movecmd).movecmdargs
"     call Decho("windows exception: movecmd<".movecmd."> (#1: had a space)",'~'.expand("<slnum>"))
    else
     let movecmd = netrw#WinPath(movecmd)
"     call Decho("windows exception: movecmd<".movecmd."> (#2: no space)",'~'.expand("<slnum>"))
    endif
   else
    let movecmd = netrw#WinPath(g:netrw_localmovecmd)
"    call Decho("movecmd<".movecmd."> (#3 linux or cygwin)",'~'.expand("<slnum>"))
   endif
   for fname in s:netrwmarkfilelist_{bufnr("%")}
    if !g:netrw_cygwin && (has("win32") || has("win95") || has("win64") || has("win16"))
     let fname= substitute(fname,'/','\\','g')
    endif
"    call Decho("system(".movecmd." ".shellescape(fname)." ".tgt.")",'~'.expand("<slnum>"))
    let ret= system(movecmd." ".shellescape(fname)." ".tgt)
    "    let ret= system(g:netrw_localmovecmd." ".shellescape(fname)." ".tgt)   " COMBAK -- trying movecmd out...
    if v:shell_error != 0
     call netrw#ErrorMsg(s:ERROR,"tried using g:netrw_localmovecmd<".g:netrw_localmovecmd.">; it doesn't work!",54)
     break
    endif
   endfor

  elseif  a:islocal && !s:netrwmftgt_islocal
   " move: local -> remote
"   call Decho("move from local to remote",'~'.expand("<slnum>"))
"   call Decho("copy",'~'.expand("<slnum>"))
   let mflist= s:netrwmarkfilelist_{bufnr("%")}
   NetrwKeepj call s:NetrwMarkFileCopy(a:islocal)
"   call Decho("remove",'~'.expand("<slnum>"))
   for fname in mflist
    let barefname = substitute(fname,'^\(.*/\)\(.\{-}\)$','\2','')
    let ok        = s:NetrwLocalRmFile(b:netrw_curdir,barefname,1)
   endfor
   unlet mflist

  elseif !a:islocal &&  s:netrwmftgt_islocal
   " move: remote -> local
"   call Decho("move from remote to local",'~'.expand("<slnum>"))
"   call Decho("copy",'~'.expand("<slnum>"))
   let mflist= s:netrwmarkfilelist_{bufnr("%")}
   NetrwKeepj call s:NetrwMarkFileCopy(a:islocal)
"   call Decho("remove",'~'.expand("<slnum>"))
   for fname in mflist
    let barefname = substitute(fname,'^\(.*/\)\(.\{-}\)$','\2','')
    let ok        = s:NetrwRemoteRmFile(b:netrw_curdir,barefname,1)
   endfor
   unlet mflist

  elseif !a:islocal && !s:netrwmftgt_islocal
   " move: remote -> remote
"   call Decho("move from remote to remote",'~'.expand("<slnum>"))
"   call Decho("copy",'~'.expand("<slnum>"))
   let mflist= s:netrwmarkfilelist_{bufnr("%")}
   NetrwKeepj call s:NetrwMarkFileCopy(a:islocal)
"   call Decho("remove",'~'.expand("<slnum>"))
   for fname in mflist
    let barefname = substitute(fname,'^\(.*/\)\(.\{-}\)$','\2','')
    let ok        = s:NetrwRemoteRmFile(b:netrw_curdir,barefname,1)
   endfor
   unlet mflist
  endif

  " -------
  " cleanup
  " -------
"  call Decho("cleanup",'~'.expand("<slnum>"))

  " remove markings from local buffer
  call s:NetrwUnmarkList(curbufnr,curdir)                   " remove markings from local buffer

  " refresh buffers
  if !s:netrwmftgt_islocal
"   call Decho("refresh netrwmftgt<".s:netrwmftgt.">",'~'.expand("<slnum>"))
   NetrwKeepj call s:NetrwRefreshDir(s:netrwmftgt_islocal,s:netrwmftgt)
  endif
  if a:islocal
"   call Decho("refresh b:netrw_curdir<".b:netrw_curdir.">",'~'.expand("<slnum>"))
   NetrwKeepj call s:NetrwRefreshDir(a:islocal,b:netrw_curdir)
  endif
  if g:netrw_fastbrowse <= 1
"   call Decho("since g:netrw_fastbrowse=".g:netrw_fastbrowse.", perform shell cmd refresh",'~'.expand("<slnum>"))
   NetrwKeepj call s:LocalBrowseRefresh()
  endif

"  call Dret("s:NetrwMarkFileMove")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFilePrint: (invoked by mp) This function prints marked files {{{2
"                       using the hardcopy command.  Local marked-file list only.
fun! s:NetrwMarkFilePrint(islocal)
"  call Dfunc("s:NetrwMarkFilePrint(islocal=".a:islocal.")")
  let curbufnr= bufnr("%")

  " sanity check
  if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
   NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"   call Dret("s:NetrwMarkFilePrint")
   return
  endif
"  call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))
  let curdir= s:NetrwGetCurdir(a:islocal)

  if exists("s:netrwmarkfilelist_{curbufnr}")
   let netrwmarkfilelist = s:netrwmarkfilelist_{curbufnr}
   call s:NetrwUnmarkList(curbufnr,curdir)
   for fname in netrwmarkfilelist
    if a:islocal
     if g:netrw_keepdir
      let fname= s:ComposePath(curdir,fname)
     endif
    else
     let fname= curdir.fname
    endif
    1split
    " the autocmds will handle both local and remote files
"    call Decho("exe sil e ".escape(fname,' '),'~'.expand("<slnum>"))
    exe "sil NetrwKeepj e ".fnameescape(fname)
"    call Decho("hardcopy",'~'.expand("<slnum>"))
    hardcopy
    q
   endfor
   2match none
  endif
"  call Dret("s:NetrwMarkFilePrint")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileRegexp: (invoked by mr) This function is used to mark {{{2
"                        files when given a regexp (for which a prompt is
"                        issued) (matches to name of files).
fun! s:NetrwMarkFileRegexp(islocal)
"  call Dfunc("s:NetrwMarkFileRegexp(islocal=".a:islocal.")")

  " get the regular expression
  call inputsave()
  let regexp= input("Enter regexp: ","","file")
  call inputrestore()

  if a:islocal
   let curdir= s:NetrwGetCurdir(a:islocal)
   " get the matching list of files using local glob()
"   call Decho("handle local regexp",'~'.expand("<slnum>"))
   let dirname = escape(b:netrw_curdir,g:netrw_glob_escape)
   if v:version == 704 && has("patch656")
    let files   = glob(s:ComposePath(dirname,regexp),0,0,1)
   else
    let files   = glob(s:ComposePath(dirname,regexp),0,0)
   endif
"   call Decho("files<".files.">",'~'.expand("<slnum>"))
   let filelist= split(files,"\n")

  " mark the list of files
  for fname in filelist
"   call Decho("fname<".fname.">",'~'.expand("<slnum>"))
   NetrwKeepj call s:NetrwMarkFile(a:islocal,substitute(fname,'^.*/','',''))
  endfor

  else
"   call Decho("handle remote regexp",'~'.expand("<slnum>"))

   " convert displayed listing into a filelist
   let eikeep = &ei
   let areg   = @a
   sil NetrwKeepj %y a
   setl ei=all ma
"   call Decho("setl ei=all ma",'~'.expand("<slnum>"))
   1split
   NetrwKeepj call s:NetrwEnew()
   NetrwKeepj call s:NetrwSafeOptions()
   sil NetrwKeepj norm! "ap
   NetrwKeepj 2
   let bannercnt= search('^" =====','W')
   exe "sil NetrwKeepj 1,".bannercnt."d"
   setl bt=nofile
   if     g:netrw_liststyle == s:LONGLIST
    sil NetrwKeepj %s/\s\{2,}\S.*$//e
    call histdel("/",-1)
   elseif g:netrw_liststyle == s:WIDELIST
    sil NetrwKeepj %s/\s\{2,}/\r/ge
    call histdel("/",-1)
   elseif g:netrw_liststyle == s:TREELIST
    exe 'sil NetrwKeepj %s/^'.s:treedepthstring.' //e'
    sil! NetrwKeepj g/^ .*$/d
    call histdel("/",-1)
    call histdel("/",-1)
   endif
   " convert regexp into the more usual glob-style format
   let regexp= substitute(regexp,'\*','.*','g')
"   call Decho("regexp<".regexp.">",'~'.expand("<slnum>"))
   exe "sil! NetrwKeepj v/".escape(regexp,'/')."/d"
   call histdel("/",-1)
   let filelist= getline(1,line("$"))
   q!
   for filename in filelist
    NetrwKeepj call s:NetrwMarkFile(a:islocal,substitute(filename,'^.*/','',''))
   endfor
   unlet filelist
   let @a  = areg
   let &ei = eikeep
  endif
  echo "  (use me to edit marked files)"

"  call Dret("s:NetrwMarkFileRegexp")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileSource: (invoked by ms) This function sources marked files {{{2
"                        Uses the local marked file list.
fun! s:NetrwMarkFileSource(islocal)
"  call Dfunc("s:NetrwMarkFileSource(islocal=".a:islocal.")")
  let curbufnr= bufnr("%")

  " sanity check
  if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
   NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"   call Dret("s:NetrwMarkFileSource")
   return
  endif
"  call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))
  let curdir= s:NetrwGetCurdir(a:islocal)

  if exists("s:netrwmarkfilelist_{curbufnr}")
   let netrwmarkfilelist = s:netrwmarkfilelist_{bufnr("%")}
   call s:NetrwUnmarkList(curbufnr,curdir)
   for fname in netrwmarkfilelist
    if a:islocal
     if g:netrw_keepdir
      let fname= s:ComposePath(curdir,fname)
     endif
    else
     let fname= curdir.fname
    endif
    " the autocmds will handle sourcing both local and remote files
"    call Decho("exe so ".fnameescape(fname),'~'.expand("<slnum>"))
    exe "so ".fnameescape(fname)
   endfor
   2match none
  endif
"  call Dret("s:NetrwMarkFileSource")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileTag: (invoked by mT) This function applies g:netrw_ctags to marked files {{{2
"                     Uses the global markfilelist
fun! s:NetrwMarkFileTag(islocal)
"  call Dfunc("s:NetrwMarkFileTag(islocal=".a:islocal.")")
  let svpos    = netrw#SavePosn()
  let curdir   = s:NetrwGetCurdir(a:islocal)
  let curbufnr = bufnr("%")

  " sanity check
  if !exists("s:netrwmarkfilelist_{curbufnr}") || empty(s:netrwmarkfilelist_{curbufnr})
   NetrwKeepj call netrw#ErrorMsg(2,"there are no marked files in this window (:help netrw-mf)",66)
"   call Dret("s:NetrwMarkFileTag")
   return
  endif
"  call Decho("sanity chk passed: s:netrwmarkfilelist_".curbufnr."<".string(s:netrwmarkfilelist_{curbufnr}),'~'.expand("<slnum>"))

  if exists("s:netrwmarkfilelist")
"   call Decho("s:netrwmarkfilelist".string(s:netrwmarkfilelist).">",'~'.expand("<slnum>"))
   let netrwmarkfilelist= join(map(deepcopy(s:netrwmarkfilelist), "shellescape(v:val,".!a:islocal.")"))
   call s:NetrwUnmarkAll()

   if a:islocal
    if executable(g:netrw_ctags)
"     call Decho("call system(".g:netrw_ctags." ".netrwmarkfilelist.")",'~'.expand("<slnum>"))
     call system(g:netrw_ctags." ".netrwmarkfilelist)
    else
     call netrw#ErrorMsg(s:ERROR,"g:netrw_ctags<".g:netrw_ctags."> is not executable!",51)
    endif
   else
    let cmd   = s:RemoteSystem(g:netrw_ctags." ".netrwmarkfilelist)
    call netrw#Obtain(a:islocal,"tags")
    let curdir= b:netrw_curdir
    1split
    NetrwKeepj e tags
    let path= substitute(curdir,'^\(.*\)/[^/]*$','\1/','')
"    call Decho("curdir<".curdir."> path<".path.">",'~'.expand("<slnum>"))
    exe 'NetrwKeepj %s/\t\(\S\+\)\t/\t'.escape(path,"/\n\r\\").'\1\t/e'
    call histdel("/",-1)
    wq!
   endif
   2match none
   call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
   call netrw#RestorePosn(svpos)
  endif

"  call Dret("s:NetrwMarkFileTag")
endfun

" ---------------------------------------------------------------------
" s:NetrwMarkFileTgt:  (invoked by mt) This function sets up a marked file target {{{2
"   Sets up two variables,
"     s:netrwmftgt         : holds the target directory
"     s:netrwmftgt_islocal : 0=target directory is remote
"                            1=target directory is local
fun! s:NetrwMarkFileTgt(islocal)
"  call Dfunc("s:NetrwMarkFileTgt(islocal=".a:islocal.")")
  let svpos  = netrw#SavePosn()
  let curdir = s:NetrwGetCurdir(a:islocal)
  let hadtgt = exists("s:netrwmftgt")
  if !exists("w:netrw_bannercnt")
   let w:netrw_bannercnt= b:netrw_bannercnt
  endif

  " set up target
  if line(".") < w:netrw_bannercnt
"   call Decho("set up target: line(.) < w:netrw_bannercnt=".w:netrw_bannercnt,'~'.expand("<slnum>"))
   " if cursor in banner region, use b:netrw_curdir for the target unless its already the target
   if exists("s:netrwmftgt") && exists("s:netrwmftgt_islocal") && s:netrwmftgt == b:netrw_curdir
"    call Decho("cursor in banner region, and target already is <".b:netrw_curdir.">: removing target",'~'.expand("<slnum>"))
    unlet s:netrwmftgt s:netrwmftgt_islocal
    if g:netrw_fastbrowse <= 1
     call s:LocalBrowseRefresh()
    endif
    call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
    call netrw#RestorePosn(svpos)
"    call Dret("s:NetrwMarkFileTgt : removed target")
    return
   else
    let s:netrwmftgt= b:netrw_curdir
"    call Decho("inbanner: s:netrwmftgt<".s:netrwmftgt.">",'~'.expand("<slnum>"))
   endif

  else
   " get word under cursor.
   "  * If directory, use it for the target.
   "  * If file, use b:netrw_curdir for the target
"   call Decho("get word under cursor",'~'.expand("<slnum>"))
   let curword= s:NetrwGetWord()
   let tgtdir = s:ComposePath(curdir,curword)
   if a:islocal && isdirectory(s:NetrwFile(tgtdir))
    let s:netrwmftgt = tgtdir
"    call Decho("local isdir: s:netrwmftgt<".s:netrwmftgt.">",'~'.expand("<slnum>"))
   elseif !a:islocal && tgtdir =~ '/$'
    let s:netrwmftgt = tgtdir
"    call Decho("remote isdir: s:netrwmftgt<".s:netrwmftgt.">",'~'.expand("<slnum>"))
   else
    let s:netrwmftgt = curdir
"    call Decho("isfile: s:netrwmftgt<".s:netrwmftgt.">",'~'.expand("<slnum>"))
   endif
  endif
  if a:islocal
   " simplify the target (eg. /abc/def/../ghi -> /abc/ghi)
   let s:netrwmftgt= simplify(s:netrwmftgt)
"   call Decho("simplify: s:netrwmftgt<".s:netrwmftgt.">",'~'.expand("<slnum>"))
  endif
  if g:netrw_cygwin
   let s:netrwmftgt= substitute(system("cygpath ".shellescape(s:netrwmftgt)),'\n$','','')
   let s:netrwmftgt= substitute(s:netrwmftgt,'\n$','','')
  endif
  let s:netrwmftgt_islocal= a:islocal

  " need to do refresh so that the banner will be updated
  "  s:LocalBrowseRefresh handles all local-browsing buffers when not fast browsing
  if g:netrw_fastbrowse <= 1
"   call Decho("g:netrw_fastbrowse=".g:netrw_fastbrowse.", so refreshing all local netrw buffers")
   call s:LocalBrowseRefresh()
  endif
"  call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  if w:netrw_liststyle == s:TREELIST
   call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,w:netrw_treetop))
  else
   call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  endif
  call netrw#RestorePosn(svpos)
  if !hadtgt
   sil! NetrwKeepj norm! j
  endif

"  call Decho("getmatches=".string(getmatches()),'~'.expand("<slnum>"))
"  call Decho("s:netrwmarkfilelist=".(exists("s:netrwmarkfilelist")? string(s:netrwmarkfilelist) : 'n/a'),'~'.expand("<slnum>"))
"  call Dret("s:NetrwMarkFileTgt : netrwmftgt<".(exists("s:netrwmftgt")? s:netrwmftgt : "").">")
endfun

" ---------------------------------------------------------------------
" s:NetrwGetCurdir: gets current directory and sets up b:netrw_curdir if necessary {{{2
fun! s:NetrwGetCurdir(islocal)
"  call Dfunc("s:NetrwGetCurdir(islocal=".a:islocal.")")

  if w:netrw_liststyle == s:TREELIST
   let b:netrw_curdir = s:NetrwTreePath(w:netrw_treetop)
"   call Decho("set b:netrw_curdir<".b:netrw_curdir."> (used s:NetrwTreeDir)",'~'.expand("<slnum>"))
  elseif !exists("b:netrw_curdir")
   let b:netrw_curdir= getcwd()
"   call Decho("set b:netrw_curdir<".b:netrw_curdir."> (used getcwd)",'~'.expand("<slnum>"))
  endif

"  call Decho("b:netrw_curdir<".b:netrw_curdir."> ".((b:netrw_curdir !~ '\<\a\{3,}://')? "does not match" : "matches")." url pattern")
  if b:netrw_curdir !~ '\<\a\{3,}://'
   let curdir= b:netrw_curdir
"   call Decho("g:netrw_keepdir=".g:netrw_keepdir)
   if g:netrw_keepdir == 0
    call s:NetrwLcd(curdir)
   endif
  endif

"  call Dret("s:NetrwGetCurdir <".curdir.">")
  return b:netrw_curdir
endfun

" ---------------------------------------------------------------------
" s:NetrwOpenFile: query user for a filename and open it {{{2
fun! s:NetrwOpenFile(islocal)
"  call Dfunc("s:NetrwOpenFile(islocal=".a:islocal.")")
  let ykeep= @@
  call inputsave()
  let fname= input("Enter filename: ")
  call inputrestore()
  if fname !~ '[/\\]'
   if exists("b:netrw_curdir")
    if exists("g:netrw_quiet")
     let netrw_quiet_keep = g:netrw_quiet
    endif
    let g:netrw_quiet = 1
    " save position for benefit of Rexplore
    let s:rexposn_{bufnr("%")}= netrw#SavePosn()
"    call Decho("setting s:rexposn_".bufnr("%")."<".bufname("%")."> to SavePosn",'~'.expand("<slnum>"))
    if b:netrw_curdir =~ '/$'
     exe "NetrwKeepj e ".fnameescape(b:netrw_curdir.fname)
    else
     exe "e ".fnameescape(b:netrw_curdir."/".fname)
    endif
    if exists("netrw_quiet_keep")
     let g:netrw_quiet= netrw_quiet_keep
    else
     unlet g:netrw_quiet
    endif
   endif
  else
   exe "NetrwKeepj e ".fnameescape(fname)
  endif
  let @@= ykeep
"  call Dret("s:NetrwOpenFile")
endfun

" ---------------------------------------------------------------------
" netrw#Shrink: shrinks/expands a netrw or Lexplorer window {{{2
fun! netrw#Shrink()
"  call Dfunc("netrw#Shrink() ft<".&ft."> winwidth=".winwidth(0)." lexbuf#".((exists("t:netrw_lexbufnr"))? t:netrw_lexbufnr : 'n/a'))
  let curwin  = winnr()
  let wiwkeep = &wiw
  set wiw=1

  if &ft == "netrw"
   if winwidth(0) > g:netrw_wiw
    let t:netrw_winwidth= winwidth(0)
    exe "vert resize ".g:netrw_wiw
    wincmd l
    if winnr() == curwin
     wincmd h
    endif
"    call Decho("vert resize 0",'~'.expand("<slnum>"))
   else
    exe "vert resize ".t:netrw_winwidth
"    call Decho("vert resize ".t:netrw_winwidth,'~'.expand("<slnum>"))
   endif

  elseif exists("t:netrw_lexbufnr")
   exe bufwinnr(t:netrw_lexbufnr)."wincmd w"
   if     winwidth(bufwinnr(t:netrw_lexbufnr)) >  g:netrw_wiw
    let t:netrw_winwidth= winwidth(0)
    exe "vert resize ".g:netrw_wiw
    wincmd l
    if winnr() == curwin
     wincmd h
    endif
"    call Decho("vert resize 0",'~'.expand("<slnum>"))
   elseif winwidth(bufwinnr(t:netrw_lexbufnr)) >= 0
    exe "vert resize ".t:netrw_winwidth
"    call Decho("vert resize ".t:netrw_winwidth,'~'.expand("<slnum>"))
   else 
    call netrw#Lexplore(0,0)
   endif

  else
   call netrw#Lexplore(0,0)
  endif
  let wiw= wiwkeep

"  call Dret("netrw#Shrink")
endfun

" ---------------------------------------------------------------------
" s:NetSortSequence: allows user to edit the sorting sequence {{{2
fun! s:NetSortSequence(islocal)
"  call Dfunc("NetSortSequence(islocal=".a:islocal.")")

  let ykeep= @@
  let svpos= netrw#SavePosn()
  call inputsave()
  let newsortseq= input("Edit Sorting Sequence: ",g:netrw_sort_sequence)
  call inputrestore()

  " refresh the listing
  let g:netrw_sort_sequence= newsortseq
  NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  NetrwKeepj call netrw#RestorePosn(svpos)
  let @@= ykeep

"  call Dret("NetSortSequence")
endfun

" ---------------------------------------------------------------------
" s:NetrwUnmarkList: delete local marked file list and remove their contents from the global marked-file list {{{2
"   User access provided by the <mF> mapping. (see :help netrw-mF)
"   Used by many MarkFile functions.
fun! s:NetrwUnmarkList(curbufnr,curdir)
"  call Dfunc("s:NetrwUnmarkList(curbufnr=".a:curbufnr." curdir<".a:curdir.">)")

  "  remove all files in local marked-file list from global list
  if exists("s:netrwmarkfilelist")
   for mfile in s:netrwmarkfilelist_{a:curbufnr}
    let dfile = s:ComposePath(a:curdir,mfile)       " prepend directory to mfile
    let idx   = index(s:netrwmarkfilelist,dfile)    " get index in list of dfile
    call remove(s:netrwmarkfilelist,idx)            " remove from global list
   endfor
   if s:netrwmarkfilelist == []
    unlet s:netrwmarkfilelist
   endif

   " getting rid of the local marked-file lists is easy
   unlet s:netrwmarkfilelist_{a:curbufnr}
  endif
  if exists("s:netrwmarkfilemtch_{a:curbufnr}")
   unlet s:netrwmarkfilemtch_{a:curbufnr}
  endif
  2match none
"  call Dret("s:NetrwUnmarkList")
endfun

" ---------------------------------------------------------------------
" s:NetrwUnmarkAll: remove the global marked file list and all local ones {{{2
fun! s:NetrwUnmarkAll()
"  call Dfunc("s:NetrwUnmarkAll()")
  if exists("s:netrwmarkfilelist")
   unlet s:netrwmarkfilelist
  endif
  sil call s:NetrwUnmarkAll2()
  2match none
"  call Dret("s:NetrwUnmarkAll")
endfun

" ---------------------------------------------------------------------
" s:NetrwUnmarkAll2: unmark all files from all buffers {{{2
fun! s:NetrwUnmarkAll2()
"  call Dfunc("s:NetrwUnmarkAll2()")
  redir => netrwmarkfilelist_let
  let
  redir END
  let netrwmarkfilelist_list= split(netrwmarkfilelist_let,'\n')          " convert let string into a let list
  call filter(netrwmarkfilelist_list,"v:val =~ '^s:netrwmarkfilelist_'") " retain only those vars that start as s:netrwmarkfilelist_
  call map(netrwmarkfilelist_list,"substitute(v:val,'\\s.*$','','')")    " remove what the entries are equal to
  for flist in netrwmarkfilelist_list
   let curbufnr= substitute(flist,'s:netrwmarkfilelist_','','')
   unlet s:netrwmarkfilelist_{curbufnr}
   unlet s:netrwmarkfilemtch_{curbufnr}
  endfor
"  call Dret("s:NetrwUnmarkAll2")
endfun

" ---------------------------------------------------------------------
" s:NetrwUnMarkFile: called via mu map; unmarks *all* marked files, both global and buffer-local {{{2
"
" Marked files are in two types of lists:
"    s:netrwmarkfilelist    -- holds complete paths to all marked files
"    s:netrwmarkfilelist_#  -- holds list of marked files in current-buffer's directory (#==bufnr())
"
" Marked files suitable for use with 2match are in:
"    s:netrwmarkfilemtch_#   -- used with 2match to display marked files
fun! s:NetrwUnMarkFile(islocal)
"  call Dfunc("s:NetrwUnMarkFile(islocal=".a:islocal.")")
  let svpos    = netrw#SavePosn()
  let curbufnr = bufnr("%")

  " unmark marked file list
  " (although I expect s:NetrwUpload() to do it, I'm just making sure)
  if exists("s:netrwmarkfilelist")
"   "   call Decho("unlet'ing: s:netrwmarkfilelist",'~'.expand("<slnum>"))
   unlet s:netrwmarkfilelist
  endif

  let ibuf= 1
  while ibuf < bufnr("$")
   if exists("s:netrwmarkfilelist_".ibuf)
    unlet s:netrwmarkfilelist_{ibuf}
    unlet s:netrwmarkfilemtch_{ibuf}
   endif
   let ibuf = ibuf + 1
  endwhile
  2match none

"  call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  call netrw#RestorePosn(svpos)
"  call Dret("s:NetrwUnMarkFile")
endfun

" ---------------------------------------------------------------------
" s:NetrwMenu: generates the menu for gvim and netrw {{{2
fun! s:NetrwMenu(domenu)

  if !exists("g:NetrwMenuPriority")
   let g:NetrwMenuPriority= 80
  endif

  if has("menu") && has("gui_running") && &go =~# 'm' && g:netrw_menu
"   call Dfunc("NetrwMenu(domenu=".a:domenu.")")

   if !exists("s:netrw_menu_enabled") && a:domenu
"    call Decho("initialize menu",'~'.expand("<slnum>"))
    let s:netrw_menu_enabled= 1
    exe 'sil! menu '.g:NetrwMenuPriority.'.1      '.g:NetrwTopLvlMenu.'Help<tab><F1>	<F1>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.5      '.g:NetrwTopLvlMenu.'-Sep1-	:'
    exe 'sil! menu '.g:NetrwMenuPriority.'.6      '.g:NetrwTopLvlMenu.'Go\ Up\ Directory<tab>-	-'
    exe 'sil! menu '.g:NetrwMenuPriority.'.7      '.g:NetrwTopLvlMenu.'Apply\ Special\ Viewer<tab>x	x'
    if g:netrw_dirhistmax > 0
     exe 'sil! menu '.g:NetrwMenuPriority.'.8.1   '.g:NetrwTopLvlMenu.'Bookmarks\ and\ History.Bookmark\ Current\ Directory<tab>mb	mb'
     exe 'sil! menu '.g:NetrwMenuPriority.'.8.4   '.g:NetrwTopLvlMenu.'Bookmarks\ and\ History.Goto\ Prev\ Dir\ (History)<tab>u	u'
     exe 'sil! menu '.g:NetrwMenuPriority.'.8.5   '.g:NetrwTopLvlMenu.'Bookmarks\ and\ History.Goto\ Next\ Dir\ (History)<tab>U	U'
     exe 'sil! menu '.g:NetrwMenuPriority.'.8.6   '.g:NetrwTopLvlMenu.'Bookmarks\ and\ History.List<tab>qb	qb'
    else
     exe 'sil! menu '.g:NetrwMenuPriority.'.8     '.g:NetrwTopLvlMenu.'Bookmarks\ and\ History	:echo "(disabled)"'."\<cr>"
    endif
    exe 'sil! menu '.g:NetrwMenuPriority.'.9.1    '.g:NetrwTopLvlMenu.'Browsing\ Control.Horizontal\ Split<tab>o	o'
    exe 'sil! menu '.g:NetrwMenuPriority.'.9.2    '.g:NetrwTopLvlMenu.'Browsing\ Control.Vertical\ Split<tab>v	v'
    exe 'sil! menu '.g:NetrwMenuPriority.'.9.3    '.g:NetrwTopLvlMenu.'Browsing\ Control.New\ Tab<tab>t	t'
    exe 'sil! menu '.g:NetrwMenuPriority.'.9.4    '.g:NetrwTopLvlMenu.'Browsing\ Control.Preview<tab>p	p'
    exe 'sil! menu '.g:NetrwMenuPriority.'.9.5    '.g:NetrwTopLvlMenu.'Browsing\ Control.Edit\ File\ Hiding\ List<tab><ctrl-h>'."	\<c-h>'"
    exe 'sil! menu '.g:NetrwMenuPriority.'.9.6    '.g:NetrwTopLvlMenu.'Browsing\ Control.Edit\ Sorting\ Sequence<tab>S	S'
    exe 'sil! menu '.g:NetrwMenuPriority.'.9.7    '.g:NetrwTopLvlMenu.'Browsing\ Control.Quick\ Hide/Unhide\ Dot\ Files<tab>'."gh	gh"
    exe 'sil! menu '.g:NetrwMenuPriority.'.9.8    '.g:NetrwTopLvlMenu.'Browsing\ Control.Refresh\ Listing<tab>'."<ctrl-l>	\<c-l>"
    exe 'sil! menu '.g:NetrwMenuPriority.'.9.9    '.g:NetrwTopLvlMenu.'Browsing\ Control.Settings/Options<tab>:NetrwSettings	'.":NetrwSettings\<cr>"
    exe 'sil! menu '.g:NetrwMenuPriority.'.10     '.g:NetrwTopLvlMenu.'Delete\ File/Directory<tab>D	D'
    exe 'sil! menu '.g:NetrwMenuPriority.'.11.1   '.g:NetrwTopLvlMenu.'Edit\ File/Dir.Create\ New\ File<tab>%	%'
    exe 'sil! menu '.g:NetrwMenuPriority.'.11.1   '.g:NetrwTopLvlMenu.'Edit\ File/Dir.In\ Current\ Window<tab><cr>	'."\<cr>"
    exe 'sil! menu '.g:NetrwMenuPriority.'.11.2   '.g:NetrwTopLvlMenu.'Edit\ File/Dir.Preview\ File/Directory<tab>p	p'
    exe 'sil! menu '.g:NetrwMenuPriority.'.11.3   '.g:NetrwTopLvlMenu.'Edit\ File/Dir.In\ Previous\ Window<tab>P	P'
    exe 'sil! menu '.g:NetrwMenuPriority.'.11.4   '.g:NetrwTopLvlMenu.'Edit\ File/Dir.In\ New\ Window<tab>o	o'
    exe 'sil! menu '.g:NetrwMenuPriority.'.11.5   '.g:NetrwTopLvlMenu.'Edit\ File/Dir.In\ New\ Tab<tab>t	t'
    exe 'sil! menu '.g:NetrwMenuPriority.'.11.5   '.g:NetrwTopLvlMenu.'Edit\ File/Dir.In\ New\ Vertical\ Window<tab>v	v'
    exe 'sil! menu '.g:NetrwMenuPriority.'.12.1   '.g:NetrwTopLvlMenu.'Explore.Directory\ Name	:Explore '
    exe 'sil! menu '.g:NetrwMenuPriority.'.12.2   '.g:NetrwTopLvlMenu.'Explore.Filenames\ Matching\ Pattern\ (curdir\ only)<tab>:Explore\ */	:Explore */'
    exe 'sil! menu '.g:NetrwMenuPriority.'.12.2   '.g:NetrwTopLvlMenu.'Explore.Filenames\ Matching\ Pattern\ (+subdirs)<tab>:Explore\ **/	:Explore **/'
    exe 'sil! menu '.g:NetrwMenuPriority.'.12.3   '.g:NetrwTopLvlMenu.'Explore.Files\ Containing\ String\ Pattern\ (curdir\ only)<tab>:Explore\ *//	:Explore *//'
    exe 'sil! menu '.g:NetrwMenuPriority.'.12.4   '.g:NetrwTopLvlMenu.'Explore.Files\ Containing\ String\ Pattern\ (+subdirs)<tab>:Explore\ **//	:Explore **//'
    exe 'sil! menu '.g:NetrwMenuPriority.'.12.4   '.g:NetrwTopLvlMenu.'Explore.Next\ Match<tab>:Nexplore	:Nexplore<cr>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.12.4   '.g:NetrwTopLvlMenu.'Explore.Prev\ Match<tab>:Pexplore	:Pexplore<cr>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.13     '.g:NetrwTopLvlMenu.'Make\ Subdirectory<tab>d	d'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.1   '.g:NetrwTopLvlMenu.'Marked\ Files.Mark\ File<tab>mf	mf'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.2   '.g:NetrwTopLvlMenu.'Marked\ Files.Mark\ Files\ by\ Regexp<tab>mr	mr'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.3   '.g:NetrwTopLvlMenu.'Marked\ Files.Hide-Show-List\ Control<tab>a	a'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.4   '.g:NetrwTopLvlMenu.'Marked\ Files.Copy\ To\ Target<tab>mc	mc'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.5   '.g:NetrwTopLvlMenu.'Marked\ Files.Delete<tab>D	D'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.6   '.g:NetrwTopLvlMenu.'Marked\ Files.Diff<tab>md	md'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.7   '.g:NetrwTopLvlMenu.'Marked\ Files.Edit<tab>me	me'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.8   '.g:NetrwTopLvlMenu.'Marked\ Files.Exe\ Cmd<tab>mx	mx'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.9   '.g:NetrwTopLvlMenu.'Marked\ Files.Move\ To\ Target<tab>mm	mm'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.10  '.g:NetrwTopLvlMenu.'Marked\ Files.Obtain<tab>O	O'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.11  '.g:NetrwTopLvlMenu.'Marked\ Files.Print<tab>mp	mp'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.12  '.g:NetrwTopLvlMenu.'Marked\ Files.Replace<tab>R	R'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.13  '.g:NetrwTopLvlMenu.'Marked\ Files.Set\ Target<tab>mt	mt'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.14  '.g:NetrwTopLvlMenu.'Marked\ Files.Tag<tab>mT	mT'
    exe 'sil! menu '.g:NetrwMenuPriority.'.14.15  '.g:NetrwTopLvlMenu.'Marked\ Files.Zip/Unzip/Compress/Uncompress<tab>mz	mz'
    exe 'sil! menu '.g:NetrwMenuPriority.'.15     '.g:NetrwTopLvlMenu.'Obtain\ File<tab>O	O'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.1.1 '.g:NetrwTopLvlMenu.'Style.Listing.thin<tab>i	:let w:netrw_liststyle=0<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.1.1 '.g:NetrwTopLvlMenu.'Style.Listing.long<tab>i	:let w:netrw_liststyle=1<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.1.1 '.g:NetrwTopLvlMenu.'Style.Listing.wide<tab>i	:let w:netrw_liststyle=2<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.1.1 '.g:NetrwTopLvlMenu.'Style.Listing.tree<tab>i	:let w:netrw_liststyle=3<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.2.1 '.g:NetrwTopLvlMenu.'Style.Normal-Hide-Show.Show\ All<tab>a	:let g:netrw_hide=0<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.2.3 '.g:NetrwTopLvlMenu.'Style.Normal-Hide-Show.Normal<tab>a	:let g:netrw_hide=1<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.2.2 '.g:NetrwTopLvlMenu.'Style.Normal-Hide-Show.Hidden\ Only<tab>a	:let g:netrw_hide=2<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.3   '.g:NetrwTopLvlMenu.'Style.Reverse\ Sorting\ Order<tab>'."r	r"
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.4.1 '.g:NetrwTopLvlMenu.'Style.Sorting\ Method.Name<tab>s       :let g:netrw_sort_by="name"<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.4.2 '.g:NetrwTopLvlMenu.'Style.Sorting\ Method.Time<tab>s       :let g:netrw_sort_by="time"<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.4.3 '.g:NetrwTopLvlMenu.'Style.Sorting\ Method.Size<tab>s       :let g:netrw_sort_by="size"<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.16.4.3 '.g:NetrwTopLvlMenu.'Style.Sorting\ Method.Exten<tab>s      :let g:netrw_sort_by="exten"<cr><c-L>'
    exe 'sil! menu '.g:NetrwMenuPriority.'.17     '.g:NetrwTopLvlMenu.'Rename\ File/Directory<tab>R	R'
    exe 'sil! menu '.g:NetrwMenuPriority.'.18     '.g:NetrwTopLvlMenu.'Set\ Current\ Directory<tab>c	c'
    let s:netrw_menucnt= 28
    call s:NetrwBookmarkMenu() " provide some history!  uses priorities 2,3, reserves 4, 8.2.x
    call s:NetrwTgtMenu()      " let bookmarks and history be easy targets

   elseif !a:domenu
    let s:netrwcnt = 0
    let curwin     = winnr()
    windo if getline(2) =~ "Netrw" | let s:netrwcnt= s:netrwcnt + 1 | endif
    exe curwin."wincmd w"

    if s:netrwcnt <= 1
"     call Decho("clear menus",'~'.expand("<slnum>"))
     exe 'sil! unmenu '.g:NetrwTopLvlMenu
"     call Decho('exe sil! unmenu '.g:NetrwTopLvlMenu.'*','~'.expand("<slnum>"))
     sil! unlet s:netrw_menu_enabled
    endif
   endif
"   call Dret("NetrwMenu")
   return
  endif

endfun

" ---------------------------------------------------------------------
" s:NetrwObtain: obtain file under cursor or from markfile list {{{2
"                Used by the O maps (as <SID>NetrwObtain())
fun! s:NetrwObtain(islocal)
"  call Dfunc("NetrwObtain(islocal=".a:islocal.")")

  let ykeep= @@
  if exists("s:netrwmarkfilelist_{bufnr('%')}")
   let islocal= s:netrwmarkfilelist_{bufnr('%')}[1] !~ '^\a\{3,}://'
   call netrw#Obtain(islocal,s:netrwmarkfilelist_{bufnr('%')})
   call s:NetrwUnmarkList(bufnr('%'),b:netrw_curdir)
  else
   call netrw#Obtain(a:islocal,expand("<cWORD>"))
  endif
  let @@= ykeep

"  call Dret("NetrwObtain")
endfun

" ---------------------------------------------------------------------
" s:NetrwPrevWinOpen: open file/directory in previous window.  {{{2
"   If there's only one window, then the window will first be split.
"   Returns:
"     choice = 0 : didn't have to choose
"     choice = 1 : saved modified file in window first
"     choice = 2 : didn't save modified file, opened window
"     choice = 3 : cancel open
fun! s:NetrwPrevWinOpen(islocal)
"  call Dfunc("s:NetrwPrevWinOpen(islocal=".a:islocal.")")

  let ykeep= @@
  " grab a copy of the b:netrw_curdir to pass it along to newly split windows
  let curdir = b:netrw_curdir

  " get last window number and the word currently under the cursor
  let origwin   = winnr()
  let lastwinnr = winnr("$")
  let curword   = s:NetrwGetWord()
  let choice    = 0
  let s:treedir = s:NetrwTreeDir(a:islocal)
  let curdir    = s:treedir
"  call Decho("winnr($)#".lastwinnr." curword<".curword.">",'~'.expand("<slnum>"))

  let didsplit = 0
  if lastwinnr == 1
   " if only one window, open a new one first
"   call Decho("only one window, so open a new one (g:netrw_alto=".g:netrw_alto.")",'~'.expand("<slnum>"))
   if g:netrw_preview
    " vertically split preview window
    let winsz= (g:netrw_winsize > 0)? (g:netrw_winsize*winheight(0))/100 : -g:netrw_winsize
"    call Decho("exe ".(g:netrw_alto? "top " : "bot ")."vert ".winsz."wincmd s",'~'.expand("<slnum>"))
    exe (g:netrw_alto? "top " : "bot ")."vert ".winsz."wincmd s"
   else
    " horizontally split preview window
    let winsz= (g:netrw_winsize > 0)? (g:netrw_winsize*winwidth(0))/100 : -g:netrw_winsize
"    call Decho("exe ".(g:netrw_alto? "bel " : "abo ").winsz."wincmd s",'~'.expand("<slnum>"))
    exe (g:netrw_alto? "bel " : "abo ").winsz."wincmd s"
   endif
   let didsplit = 1
"   call Decho("did split",'~'.expand("<slnum>"))

  else
   NetrwKeepj call s:SaveBufVars()
   let eikeep= &ei
   setl ei=all
   wincmd p
"   call Decho("wincmd p  (now in win#".winnr().") curdir<".curdir.">",'~'.expand("<slnum>"))

   " prevwinnr: the window number of the "prev" window
   " prevbufnr: the buffer number of the buffer in the "prev" window
   " bnrcnt   : the qty of windows open on the "prev" buffer
   let prevwinnr   = winnr()
   let prevbufnr   = bufnr("%")
   let prevbufname = bufname("%")
   let prevmod     = &mod
   let bnrcnt      = 0
   NetrwKeepj call s:RestoreBufVars()
"   call Decho("after wincmd p: win#".winnr()." win($)#".winnr("$")." origwin#".origwin." &mod=".&mod." bufname(%)<".bufname("%")."> prevbufnr=".prevbufnr,'~'.expand("<slnum>"))

   " if the previous window's buffer has been changed (ie. its modified flag is set),
   " and it doesn't appear in any other extant window, then ask the
   " user if s/he wants to abandon modifications therein.
   if prevmod
"    call Decho("detected that prev window's buffer has been modified: prevbufnr=".prevbufnr." winnr()#".winnr(),'~'.expand("<slnum>"))
    windo if winbufnr(0) == prevbufnr | let bnrcnt=bnrcnt+1 | endif
"    call Decho("prevbufnr=".prevbufnr." bnrcnt=".bnrcnt." buftype=".&bt." winnr()=".winnr()." prevwinnr#".prevwinnr,'~'.expand("<slnum>"))
    exe prevwinnr."wincmd w"

    if bnrcnt == 1 && &hidden == 0
     " only one copy of the modified buffer in a window, and
     " hidden not set, so overwriting will lose the modified file.  Ask first...
     let choice = confirm("Save modified buffer<".prevbufname."> first?","&Yes\n&No\n&Cancel")
"     call Decho("(NetrwPrevWinOpen) prevbufname<".prevbufname."> choice=".choice." current-winnr#".winnr(),'~'.expand("<slnum>"))
     let &ei= eikeep

     if choice == 1
      " Yes -- write file & then browse
      let v:errmsg= ""
      sil w
      if v:errmsg != ""
       call netrw#ErrorMsg(s:ERROR,"unable to write <".(exists("prevbufname")? prevbufname : 'n/a').">!",30)
       exe origwin."wincmd w"
       let &ei = eikeep
       let @@  = ykeep
"       call Dret("s:NetrwPrevWinOpen ".choice." : unable to write <".prevbufname.">")
       return choice
      endif

     elseif choice == 2
      " No -- don't worry about changed file, just browse anyway
"      call Decho("don't worry about chgd file, just browse anyway (winnr($)#".winnr("$").")",'~'.expand("<slnum>"))
      echomsg "**note** changes to ".prevbufname." abandoned"

     else
      " Cancel -- don't do this
"      call Decho("cancel, don't browse, switch to win#".origwin,'~'.expand("<slnum>"))
      exe origwin."wincmd w"
      let &ei= eikeep
      let @@ = ykeep
"      call Dret("s:NetrwPrevWinOpen ".choice." : cancelled")
      return choice
     endif
    endif
   endif
   let &ei= eikeep
  endif

  " restore b:netrw_curdir (window split/enew may have lost it)
  let b:netrw_curdir= curdir
  if a:islocal < 2
   if a:islocal
    call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(a:islocal,curword))
   else
    call s:NetrwBrowse(a:islocal,s:NetrwBrowseChgDir(a:islocal,curword))
   endif
  endif
  let @@= ykeep
"  call Dret("s:NetrwPrevWinOpen ".choice)
  return choice
endfun

" ---------------------------------------------------------------------
" s:NetrwUpload: load fname to tgt (used by NetrwMarkFileCopy()) {{{2
"                Always assumed to be local -> remote
"                call s:NetrwUpload(filename, target)
"                call s:NetrwUpload(filename, target, fromdirectory)
fun! s:NetrwUpload(fname,tgt,...)
"  call Dfunc("s:NetrwUpload(fname<".((type(a:fname) == 1)? a:fname : string(a:fname))."> tgt<".a:tgt.">) a:0=".a:0)

  if a:tgt =~ '^\a\{3,}://'
   let tgtdir= substitute(a:tgt,'^\a\{3,}://[^/]\+/\(.\{-}\)$','\1','')
  else
   let tgtdir= substitute(a:tgt,'^\(.*\)/[^/]*$','\1','')
  endif
"  call Decho("tgtdir<".tgtdir.">",'~'.expand("<slnum>"))

  if a:0 > 0
   let fromdir= a:1
  else
   let fromdir= getcwd()
  endif
"  call Decho("fromdir<".fromdir.">",'~'.expand("<slnum>"))

  if type(a:fname) == 1
   " handle uploading a single file using NetWrite
"   call Decho("handle uploading a single file via NetWrite",'~'.expand("<slnum>"))
   1split
"   call Decho("exe e ".fnameescape(s:NetrwFile(a:fname)),'~'.expand("<slnum>"))
   exe "NetrwKeepj e ".fnameescape(s:NetrwFile(a:fname))
"   call Decho("now locally editing<".expand("%").">, has ".line("$")." lines",'~'.expand("<slnum>"))
   if a:tgt =~ '/$'
    let wfname= substitute(a:fname,'^.*/','','')
"    call Decho("exe w! ".fnameescape(wfname),'~'.expand("<slnum>"))
    exe "w! ".fnameescape(a:tgt.wfname)
   else
"    call Decho("writing local->remote: exe w ".fnameescape(a:tgt),'~'.expand("<slnum>"))
    exe "w ".fnameescape(a:tgt)
"    call Decho("done writing local->remote",'~'.expand("<slnum>"))
   endif
   q!

  elseif type(a:fname) == 3
   " handle uploading a list of files via scp
"   call Decho("handle uploading a list of files via scp",'~'.expand("<slnum>"))
   let curdir= getcwd()
   if a:tgt =~ '^scp:'
    call s:NetrwLcd(fromdir)
    let filelist= deepcopy(s:netrwmarkfilelist_{bufnr('%')})
    let args    = join(map(filelist,"shellescape(v:val, 1)"))
    if exists("g:netrw_port") && g:netrw_port != ""
     let useport= " ".g:netrw_scpport." ".g:netrw_port
    else
     let useport= ""
    endif
    let machine = substitute(a:tgt,'^scp://\([^/:]\+\).*$','\1','')
    let tgt     = substitute(a:tgt,'^scp://[^/]\+/\(.*\)$','\1','')
    call s:NetrwExe(s:netrw_silentxfer."!".g:netrw_scp_cmd.shellescape(useport,1)." ".args." ".shellescape(machine.":".tgt,1))
    call s:NetrwLcd(curdir)

   elseif a:tgt =~ '^ftp:'
    call s:NetrwMethod(a:tgt)

    if b:netrw_method == 2
     " handle uploading a list of files via ftp+.netrc
     let netrw_fname = b:netrw_fname
     sil NetrwKeepj new
"     call Decho("filter input window#".winnr(),'~'.expand("<slnum>"))

     NetrwKeepj put =g:netrw_ftpmode
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))

     if exists("g:netrw_ftpextracmd")
      NetrwKeepj put =g:netrw_ftpextracmd
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endif

     NetrwKeepj call setline(line("$")+1,'lcd "'.fromdir.'"')
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))

     if tgtdir == ""
      let tgtdir= '/'
     endif
     NetrwKeepj call setline(line("$")+1,'cd "'.tgtdir.'"')
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))

     for fname in a:fname
      NetrwKeepj call setline(line("$")+1,'put "'.s:NetrwFile(fname).'"')
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endfor

     if exists("g:netrw_port") && g:netrw_port != ""
      call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1)." ".shellescape(g:netrw_port,1))
     else
"      call Decho("filter input window#".winnr(),'~'.expand("<slnum>"))
      call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1))
     endif
     " If the result of the ftp operation isn't blank, show an error message (tnx to Doug Claar)
     sil NetrwKeepj g/Local directory now/d
     call histdel("/",-1)
     if getline(1) !~ "^$" && !exists("g:netrw_quiet") && getline(1) !~ '^Trying '
      call netrw#ErrorMsg(s:ERROR,getline(1),14)
     else
      bw!|q
     endif

    elseif b:netrw_method == 3
     " upload with ftp + machine, id, passwd, and fname (ie. no .netrc)
     let netrw_fname= b:netrw_fname
     NetrwKeepj call s:SaveBufVars()|sil NetrwKeepj new|NetrwKeepj call s:RestoreBufVars()
     let tmpbufnr= bufnr("%")
     setl ff=unix

     if exists("g:netrw_port") && g:netrw_port != ""
      NetrwKeepj put ='open '.g:netrw_machine.' '.g:netrw_port
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     else
      NetrwKeepj put ='open '.g:netrw_machine
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endif

     if exists("g:netrw_uid") && g:netrw_uid != ""
      if exists("g:netrw_ftp") && g:netrw_ftp == 1
       NetrwKeepj put =g:netrw_uid
"       call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
       if exists("s:netrw_passwd")
        NetrwKeepj call setline(line("$")+1,'"'.s:netrw_passwd.'"')
       endif
"       call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
      elseif exists("s:netrw_passwd")
       NetrwKeepj put ='user \"'.g:netrw_uid.'\" \"'.s:netrw_passwd.'\"'
"       call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
      endif
     endif

     NetrwKeepj call setline(line("$")+1,'lcd "'.fromdir.'"')
"     call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))

     if exists("b:netrw_fname") && b:netrw_fname != ""
      NetrwKeepj call setline(line("$")+1,'cd "'.b:netrw_fname.'"')
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endif

     if exists("g:netrw_ftpextracmd")
      NetrwKeepj put =g:netrw_ftpextracmd
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endif

     for fname in a:fname
      NetrwKeepj call setline(line("$")+1,'put "'.fname.'"')
"      call Decho("filter input: ".getline('$'),'~'.expand("<slnum>"))
     endfor

     " perform ftp:
     " -i       : turns off interactive prompting from ftp
     " -n  unix : DON'T use <.netrc>, even though it exists
     " -n  win32: quit being obnoxious about password
     NetrwKeepj norm! 1Gdd
     call s:NetrwExe(s:netrw_silentxfer."%!".s:netrw_ftp_cmd." ".g:netrw_ftp_options)
     " If the result of the ftp operation isn't blank, show an error message (tnx to Doug Claar)
     sil NetrwKeepj g/Local directory now/d
     call histdel("/",-1)
     if getline(1) !~ "^$" && !exists("g:netrw_quiet") && getline(1) !~ '^Trying '
      let debugkeep= &debug
      setl debug=msg
      call netrw#ErrorMsg(s:ERROR,getline(1),15)
      let &debug = debugkeep
      let mod    = 1
     else
      bw!|q
     endif
    elseif !exists("b:netrw_method") || b:netrw_method < 0
"     call Dfunc("netrw#NetrwUpload : unsupported method")
     return
    endif
   else
    call netrw#ErrorMsg(s:ERROR,"can't obtain files with protocol from<".a:tgt.">",63)
   endif
  endif

"  call Dret("s:NetrwUpload")
endfun

" ---------------------------------------------------------------------
" s:NetrwPreview: {{{2
fun! s:NetrwPreview(path) range
"  call Dfunc("NetrwPreview(path<".a:path.">)")
  let ykeep= @@
  NetrwKeepj call s:NetrwOptionSave("s:")
  NetrwKeepj call s:NetrwSafeOptions()
  if has("quickfix")
   if !isdirectory(s:NetrwFile(a:path))
    if g:netrw_preview && !g:netrw_alto
     let pvhkeep = &pvh
     let winsz   = (g:netrw_winsize > 0)? (g:netrw_winsize*winwidth(0))/100 : -g:netrw_winsize
     let &pvh    = winwidth(0) - winsz
    endif
    exe (g:netrw_alto? "top " : "bot ").(g:netrw_preview? "vert " : "")."pedit ".fnameescape(a:path)
    if exists("pvhkeep")
     let &pvh= pvhkeep
    endif
   elseif !exists("g:netrw_quiet")
    NetrwKeepj call netrw#ErrorMsg(s:WARNING,"sorry, cannot preview a directory such as <".a:path.">",38)
   endif
  elseif !exists("g:netrw_quiet")
   NetrwKeepj call netrw#ErrorMsg(s:WARNING,"sorry, to preview your vim needs the quickfix feature compiled in",39)
  endif
  NetrwKeepj call s:NetrwOptionRestore("s:")
  let @@= ykeep
"  call Dret("NetrwPreview")
endfun

" ---------------------------------------------------------------------
" s:NetrwRefresh: {{{2
fun! s:NetrwRefresh(islocal,dirname)
"  call Dfunc("s:NetrwRefresh(islocal<".a:islocal.">,dirname=".a:dirname.") hide=".g:netrw_hide." sortdir=".g:netrw_sort_direction)
  " at the current time (Mar 19, 2007) all calls to NetrwRefresh() call NetrwBrowseChgDir() first.
  setl ma noro
"  call Decho("setl ma noro",'~'.expand("<slnum>"))
"  call Decho("clear buffer<".expand("%")."> with :%d",'~'.expand("<slnum>"))
  let ykeep      = @@

  " save the cursor position before refresh.
  let screenposn = netrw#SavePosn()

"  call Decho("win#".winnr().": ".winheight(0)."x".winwidth(0)." curfile<".expand("%").">",'~'.expand("<slnum>"))
"  call Decho("clearing buffer prior to refresh",'~'.expand("<slnum>"))
  sil! NetrwKeepj %d _
  if a:islocal
   NetrwKeepj call netrw#LocalBrowseCheck(a:dirname)
  else
   NetrwKeepj call s:NetrwBrowse(a:islocal,a:dirname)
  endif

  " restore position
  NetrwKeepj call netrw#RestorePosn(screenposn)

  " restore file marks
  if exists("s:netrwmarkfilemtch_{bufnr('%')}") && s:netrwmarkfilemtch_{bufnr("%")} != ""
"   call Decho("exe 2match netrwMarkFile /".s:netrwmarkfilemtch_{bufnr("%")}."/",'~'.expand("<slnum>"))
   exe "2match netrwMarkFile /".s:netrwmarkfilemtch_{bufnr("%")}."/"
  else
"   call Decho("2match none  (bufnr(%)=".bufnr("%")."<".bufname("%").">)",'~'.expand("<slnum>"))
   2match none
  endif

"  restore
  let @@= ykeep
"  call Dret("s:NetrwRefresh")
endfun

" ---------------------------------------------------------------------
" s:NetrwRefreshDir: refreshes a directory by name {{{2
"                    Called by NetrwMarkFileCopy()
"                    Interfaces to s:NetrwRefresh() and s:LocalBrowseRefresh()
fun! s:NetrwRefreshDir(islocal,dirname)
"  call Dfunc("s:NetrwRefreshDir(islocal=".a:islocal." dirname<".a:dirname.">) g:netrw_fastbrowse=".g:netrw_fastbrowse)
  if g:netrw_fastbrowse == 0
   " slowest mode (keep buffers refreshed, local or remote)
"   call Decho("slowest mode: keep buffers refreshed, local or remote",'~'.expand("<slnum>"))
   let tgtwin= bufwinnr(a:dirname)
"   call Decho("tgtwin= bufwinnr(".a:dirname.")=".tgtwin,'~'.expand("<slnum>"))

   if tgtwin > 0
    " tgtwin is being displayed, so refresh it
    let curwin= winnr()
"    call Decho("refresh tgtwin#".tgtwin." (curwin#".curwin.")",'~'.expand("<slnum>"))
    exe tgtwin."wincmd w"
    NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
    exe curwin."wincmd w"

   elseif bufnr(a:dirname) > 0
    let bn= bufnr(a:dirname)
"    call Decho("bd bufnr(".a:dirname.")=".bn,'~'.expand("<slnum>"))
    exe "sil keepj bd ".bn
   endif

  elseif g:netrw_fastbrowse <= 1
"   call Decho("medium-speed mode: refresh local buffers only",'~'.expand("<slnum>"))
   NetrwKeepj call s:LocalBrowseRefresh()
  endif
"  call Dret("s:NetrwRefreshDir")
endfun

" ---------------------------------------------------------------------
" s:NetrwSetChgwin: set g:netrw_chgwin; a <cr> will use the specified
" window number to do its editing in.
" Supports   [count]C  where the count, if present, is used to specify
" a window to use for editing via the <cr> mapping.
fun! s:NetrwSetChgwin(...)
"  call Dfunc("s:NetrwSetChgwin() v:count=".v:count)
  if a:0 > 0
"   call Decho("a:1<".a:1.">",'~'.expand("<slnum>"))
   if a:1 == ""    " :NetrwC win#
    let g:netrw_chgwin= winnr()
   else              " :NetrwC
    let g:netrw_chgwin= a:1
   endif
  elseif v:count > 0 " [count]C
   let g:netrw_chgwin= v:count
  else               " C
   let g:netrw_chgwin= winnr()
  endif
  echo "editing window now set to window#".g:netrw_chgwin
"  call Dret("s:NetrwSetChgwin : g:netrw_chgwin=".g:netrw_chgwin)
endfun

" ---------------------------------------------------------------------
" s:NetrwSetSort: sets up the sort based on the g:netrw_sort_sequence {{{2
"          What this function does is to compute a priority for the patterns
"          in the g:netrw_sort_sequence.  It applies a substitute to any
"          "files" that satisfy each pattern, putting the priority / in
"          front.  An "*" pattern handles the default priority.
fun! s:NetrwSetSort()
"  call Dfunc("SetSort() bannercnt=".w:netrw_bannercnt)
  let ykeep= @@
  if w:netrw_liststyle == s:LONGLIST
   let seqlist  = substitute(g:netrw_sort_sequence,'\$','\\%(\t\\|\$\\)','ge')
  else
   let seqlist  = g:netrw_sort_sequence
  endif
  " sanity check -- insure that * appears somewhere
  if seqlist == ""
   let seqlist= '*'
  elseif seqlist !~ '\*'
   let seqlist= seqlist.',*'
  endif
  let priority = 1
  while seqlist != ""
   if seqlist =~ ','
    let seq     = substitute(seqlist,',.*$','','e')
    let seqlist = substitute(seqlist,'^.\{-},\(.*\)$','\1','e')
   else
    let seq     = seqlist
    let seqlist = ""
   endif
   if priority < 10
    let spriority= "00".priority.g:netrw_sepchr
   elseif priority < 100
    let spriority= "0".priority.g:netrw_sepchr
   else
    let spriority= priority.g:netrw_sepchr
   endif
"   call Decho("priority=".priority." spriority<".spriority."> seq<".seq."> seqlist<".seqlist.">",'~'.expand("<slnum>"))

   " sanity check
   if w:netrw_bannercnt > line("$")
    " apparently no files were left after a Hiding pattern was used
"    call Dret("SetSort : no files left after hiding")
    return
   endif
   if seq == '*'
    let starpriority= spriority
   else
    exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$g/'.seq.'/s/^/'.spriority.'/'
    call histdel("/",-1)
    " sometimes multiple sorting patterns will match the same file or directory.
    " The following substitute is intended to remove the excess matches.
    exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$g/^\d\{3}'.g:netrw_sepchr.'\d\{3}\//s/^\d\{3}'.g:netrw_sepchr.'\(\d\{3}\/\).\@=/\1/e'
    NetrwKeepj call histdel("/",-1)
   endif
   let priority = priority + 1
  endwhile
  if exists("starpriority")
   exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$v/^\d\{3}'.g:netrw_sepchr.'/s/^/'.starpriority.'/e'
   NetrwKeepj call histdel("/",-1)
  endif

  " Following line associated with priority -- items that satisfy a priority
  " pattern get prefixed by ###/ which permits easy sorting by priority.
  " Sometimes files can satisfy multiple priority patterns -- only the latest
  " priority pattern needs to be retained.  So, at this point, these excess
  " priority prefixes need to be removed, but not directories that happen to
  " be just digits themselves.
  exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$s/^\(\d\{3}'.g:netrw_sepchr.'\)\%(\d\{3}'.g:netrw_sepchr.'\)\+\ze./\1/e'
  NetrwKeepj call histdel("/",-1)
  let @@= ykeep

"  call Dret("SetSort")
endfun

" ---------------------------------------------------------------------
" s:NetrwSetTgt: sets the target to the specified choice index {{{2
"    Implements [count]Tb  (bookhist<b>)
"               [count]Th  (bookhist<h>)
"               See :help netrw-qb for how to make the choice.
fun! s:NetrwSetTgt(bookhist,choice)
"  call Dfunc("s:NetrwSetTgt(bookhist<".a:bookhist."> choice#".a:choice.")")

  if     a:bookhist == 'b'
   " supports choosing a bookmark as a target using a qb-generated list
   let choice= a:choice - 1
   if exists("g:netrw_bookmarklist[".choice."]")
    call netrw#MakeTgt(g:netrw_bookmarklist[choice])
   else
    echomsg "Sorry, bookmark#".a:choice." doesn't exist!"
   endif

  elseif a:bookhist == 'h'
   " supports choosing a history stack entry as a target using a qb-generated list
   let choice= (a:choice % g:netrw_dirhistmax) + 1
   if exists("g:netrw_dirhist_".choice)
    let histentry = g:netrw_dirhist_{choice}
    call netrw#MakeTgt(histentry)
   else
    echomsg "Sorry, history#".a:choice." not available!"
   endif
  endif

"  call Dret("s:NetrwSetTgt")
endfun

" =====================================================================
" s:NetrwSortStyle: change sorting style (name - time - size) and refresh display {{{2
fun! s:NetrwSortStyle(islocal)
"  call Dfunc("s:NetrwSortStyle(islocal=".a:islocal.") netrw_sort_by<".g:netrw_sort_by.">")
  NetrwKeepj call s:NetrwSaveWordPosn()
  let svpos= netrw#SavePosn()

  let g:netrw_sort_by= (g:netrw_sort_by =~ '^n')? 'time' : (g:netrw_sort_by =~ '^t')? 'size' : (g:netrw_sort_by =~ '^siz')? 'exten' : 'name'
  NetrwKeepj norm! 0
  NetrwKeepj call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
  NetrwKeepj call netrw#RestorePosn(svpos)

"  call Dret("s:NetrwSortStyle : netrw_sort_by<".g:netrw_sort_by.">")
endfun

" ---------------------------------------------------------------------
" s:NetrwSplit: mode {{{2
"           =0 : net   and o
"           =1 : net   and t
"           =2 : net   and v
"           =3 : local and o
"           =4 : local and t
"           =5 : local and v
fun! s:NetrwSplit(mode)
"  call Dfunc("s:NetrwSplit(mode=".a:mode.") alto=".g:netrw_alto." altv=".g:netrw_altv)

  let ykeep= @@
  call s:SaveWinVars()

  if a:mode == 0
   " remote and o
   let winsz= (g:netrw_winsize > 0)? (g:netrw_winsize*winheight(0))/100 : -g:netrw_winsize
   if winsz == 0|let winsz= ""|endif
"   call Decho("exe ".(g:netrw_alto? "bel " : "abo ").winsz."wincmd s",'~'.expand("<slnum>"))
   exe (g:netrw_alto? "bel " : "abo ").winsz."wincmd s"
   let s:didsplit= 1
   NetrwKeepj call s:RestoreWinVars()
   NetrwKeepj call s:NetrwBrowse(0,s:NetrwBrowseChgDir(0,s:NetrwGetWord()))
   unlet s:didsplit

  elseif a:mode == 1
   " remote and t
   let newdir  = s:NetrwBrowseChgDir(0,s:NetrwGetWord())
"   call Decho("tabnew",'~'.expand("<slnum>"))
   tabnew
   let s:didsplit= 1
   NetrwKeepj call s:RestoreWinVars()
   NetrwKeepj call s:NetrwBrowse(0,newdir)
   unlet s:didsplit

  elseif a:mode == 2
   " remote and v
   let winsz= (g:netrw_winsize > 0)? (g:netrw_winsize*winwidth(0))/100 : -g:netrw_winsize
   if winsz == 0|let winsz= ""|endif
"   call Decho("exe ".(g:netrw_altv? "rightb " : "lefta ").winsz."wincmd v",'~'.expand("<slnum>"))
   exe (g:netrw_altv? "rightb " : "lefta ").winsz."wincmd v"
   let s:didsplit= 1
   NetrwKeepj call s:RestoreWinVars()
   NetrwKeepj call s:NetrwBrowse(0,s:NetrwBrowseChgDir(0,s:NetrwGetWord()))
   unlet s:didsplit

  elseif a:mode == 3
   " local and o
   let winsz= (g:netrw_winsize > 0)? (g:netrw_winsize*winheight(0))/100 : -g:netrw_winsize
   if winsz == 0|let winsz= ""|endif
"   call Decho("exe ".(g:netrw_alto? "bel " : "abo ").winsz."wincmd s",'~'.expand("<slnum>"))
   exe (g:netrw_alto? "bel " : "abo ").winsz."wincmd s"
   let s:didsplit= 1
   NetrwKeepj call s:RestoreWinVars()
   NetrwKeepj call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(1,s:NetrwGetWord()))
   unlet s:didsplit

  elseif a:mode == 4
   " local and t
   let cursorword  = s:NetrwGetWord()
   let eikeep      = &ei
   let netrw_winnr = winnr()
   let netrw_line  = line(".")
   let netrw_col   = virtcol(".")
   NetrwKeepj norm! H0
   let netrw_hline = line(".")
   setl ei=all
   exe "NetrwKeepj norm! ".netrw_hline."G0z\<CR>"
   exe "NetrwKeepj norm! ".netrw_line."G0".netrw_col."\<bar>"
   let &ei          = eikeep
   let netrw_curdir = s:NetrwTreeDir(0)
"   call Decho("tabnew",'~'.expand("<slnum>"))
   tabnew
   let b:netrw_curdir = netrw_curdir
   let s:didsplit     = 1
   NetrwKeepj call s:RestoreWinVars()
   NetrwKeepj call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(1,cursorword))
   if &ft == "netrw"
    setl ei=all
    exe "NetrwKeepj norm! ".netrw_hline."G0z\<CR>"
    exe "NetrwKeepj norm! ".netrw_line."G0".netrw_col."\<bar>"
    let &ei= eikeep
   endif
   unlet s:didsplit

  elseif a:mode == 5
   " local and v
   let winsz= (g:netrw_winsize > 0)? (g:netrw_winsize*winwidth(0))/100 : -g:netrw_winsize
   if winsz == 0|let winsz= ""|endif
"   call Decho("exe ".(g:netrw_altv? "rightb " : "lefta ").winsz."wincmd v",'~'.expand("<slnum>"))
   exe (g:netrw_altv? "rightb " : "lefta ").winsz."wincmd v"
   let s:didsplit= 1
   NetrwKeepj call s:RestoreWinVars()
   NetrwKeepj call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(1,s:NetrwGetWord()))
   "call netrw#LocalBrowseCheck(s:NetrwBrowseChgDir(1,s:NetrwGetWord()))
   unlet s:didsplit

  else
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"(NetrwSplit) unsupported mode=".a:mode,45)
  endif

  let @@= ykeep
"  call Dret("s:NetrwSplit")
endfun

" ---------------------------------------------------------------------
" s:NetrwTgtMenu: {{{2
fun! s:NetrwTgtMenu()
  if !exists("s:netrw_menucnt")
   return
  endif
"  call Dfunc("s:NetrwTgtMenu()")

  " the following test assures that gvim is running, has menus available, and has menus enabled.
  if has("gui") && has("menu") && has("gui_running") && &go =~# 'm' && g:netrw_menu
   if exists("g:NetrwTopLvlMenu")
"    call Decho("removing ".g:NetrwTopLvlMenu."Bookmarks menu item(s)",'~'.expand("<slnum>"))
    exe 'sil! unmenu '.g:NetrwTopLvlMenu.'Targets'
   endif
   if !exists("s:netrw_initbookhist")
    call s:NetrwBookHistRead()
   endif

   " try to cull duplicate entries
   let tgtdict={}

   " target bookmarked places
   if exists("g:netrw_bookmarklist") && g:netrw_bookmarklist != [] && g:netrw_dirhistmax > 0
"    call Decho("installing bookmarks as easy targets",'~'.expand("<slnum>"))
    let cnt= 1
    for bmd in g:netrw_bookmarklist
     if has_key(tgtdict,bmd)
      let cnt= cnt + 1
      continue
     endif
     let tgtdict[bmd]= cnt
     let ebmd= escape(bmd,g:netrw_menu_escape)
     " show bookmarks for goto menu
"     call Decho("menu: Targets: ".bmd,'~'.expand("<slnum>"))
     exe 'sil! menu <silent> '.g:NetrwMenuPriority.".19.1.".cnt." ".g:NetrwTopLvlMenu.'Targets.'.ebmd."	:call netrw#MakeTgt('".bmd."')\<cr>"
     let cnt= cnt + 1
    endfor
   endif

   " target directory browsing history
   if exists("g:netrw_dirhistmax") && g:netrw_dirhistmax > 0
"    call Decho("installing history as easy targets (histmax=".g:netrw_dirhistmax.")",'~'.expand("<slnum>"))
    let histcnt = 1
    while histcnt <= g:netrw_dirhistmax
     let priority = g:netrw_dirhist_cnt + histcnt
     if exists("g:netrw_dirhist_{histcnt}")
      let histentry  = g:netrw_dirhist_{histcnt}
      if has_key(tgtdict,histentry)
       let histcnt = histcnt + 1
       continue
      endif
      let tgtdict[histentry] = histcnt
      let ehistentry         = escape(histentry,g:netrw_menu_escape)
"      call Decho("menu: Targets: ".histentry,'~'.expand("<slnum>"))
      exe 'sil! menu <silent> '.g:NetrwMenuPriority.".19.2.".priority." ".g:NetrwTopLvlMenu.'Targets.'.ehistentry."	:call netrw#MakeTgt('".histentry."')\<cr>"
     endif
     let histcnt = histcnt + 1
    endwhile
   endif
  endif
"  call Dret("s:NetrwTgtMenu")
endfun

" ---------------------------------------------------------------------
" s:NetrwTreeDir: determine tree directory given current cursor position {{{2
" (full path directory with trailing slash returned)
fun! s:NetrwTreeDir(islocal)
"  call Dfunc("s:NetrwTreeDir(islocal=".a:islocal.") getline(".line(".").")"."<".getline('.')."> b:netrw_curdir<".b:netrw_curdir."> tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> ft=".&ft)

  if exists("s:treedir")
   " s:NetrwPrevWinOpen opens a "previous" window -- and thus needs to and does call s:NetrwTreeDir early
   let treedir= s:treedir
   unlet s:treedir
"   call Dret("s:NetrwTreeDir ".treedir)
   return treedir
  endif

  if !exists("b:netrw_curdir") || b:netrw_curdir == ""
   let b:netrw_curdir= getcwd()
  endif

  let treedir = b:netrw_curdir
"  call Decho("set initial treedir<".treedir.">",'~'.expand("<slnum>"))
  let s:treecurpos= netrw#SavePosn()

  if w:netrw_liststyle == s:TREELIST
"   call Decho("w:netrw_liststyle is TREELIST:",'~'.expand("<slnum>"))
"   call Decho("line#".line(".")." getline(.)<".getline('.')."> treecurpos<".string(s:treecurpos).">",'~'.expand("<slnum>"))

   " extract tree directory if on a line specifying a subdirectory (ie. ends with "/")
   let curline= substitute(getline('.'),"\t -->.*$",'','')
   if curline =~ '/$'
"    call Decho("extract tree subdirectory from current line",'~'.expand("<slnum>"))
    let treedir= substitute(getline('.'),'^\%('.s:treedepthstring.'\)*\([^'.s:treedepthstring.'].\{-}\)$','\1','e')
"    call Decho("treedir<".treedir.">",'~'.expand("<slnum>"))
   elseif curline =~ '@$'
"    call Decho("handle symbolic link from current line",'~'.expand("<slnum>"))
    let treedir= resolve(substitute(substitute(getline('.'),'@.*$','','e'),'^|*\s*','','e'))
"    call Decho("treedir<".treedir.">",'~'.expand("<slnum>"))
   else
"    call Decho("do not extract tree subdirectory from current line and set treedir to empty",'~'.expand("<slnum>"))
    let treedir= ""
   endif

   " detect user attempting to close treeroot
"   call Decho("check if user is attempting to close treeroot",'~'.expand("<slnum>"))
"   call Decho(".win#".winnr()." buf#".bufnr("%")."<".bufname("%").">",'~'.expand("<slnum>"))
"   call Decho(".getline(".line(".").")<".getline('.').'> '.((getline('.') =~ '^'.s:treedepthstring)? '=~' : '!~').' ^'.s:treedepthstring,'~'.expand("<slnum>"))
   if curline !~ '^'.s:treedepthstring && getline('.') != '..'
"    call Decho(".user may have attempted to close treeroot",'~'.expand("<slnum>"))
    " now force a refresh
"    call Decho(".force refresh: clear buffer<".expand("%")."> with :%d",'~'.expand("<slnum>"))
    sil! NetrwKeepj %d _
"    call Dret("s:NetrwTreeDir <".treedir."> : (side effect) s:treecurpos<".(exists("s:treecurpos")? string(s:treecurpos) : 'n/a').">")
    return b:netrw_curdir
"   else " Decho
"    call Decho(".user did not attempt to close treeroot",'~'.expand("<slnum>"))
   endif

"   call Decho("islocal=".a:islocal." curline<".curline.">",'~'.expand("<slnum>"))
"   call Decho("after subst<".substitute(curline,'^'.s:treedepthstring.'\+ \(.*\)$','\1','').">",'~'.expand("<slnum>"))
   let potentialdir= substitute(curline,'^'.s:treedepthstring.'* \(.*\)@$','\1','')
"   call Decho("potentialdir<".potentialdir."> isdir=".isdirectory(s:NetrwFile(potentialdir)),'~'.expand("<slnum>"))

   " COMBAK: a symbolic link may point anywhere -- so it will be used to start a new treetop
"   if a:islocal && curline =~ '@$' && isdirectory(s:NetrwFile(potentialdir))
"    let newdir          = w:netrw_treetop.'/'.potentialdir
" "   call Decho("apply NetrwTreePath to newdir<".newdir.">",'~'.expand("<slnum>"))
"    let treedir         = s:NetrwTreePath(newdir)
"    let w:netrw_treetop = newdir
" "   call Decho("newdir <".newdir.">",'~'.expand("<slnum>"))
"   else
"    call Decho("apply NetrwTreePath to treetop<".w:netrw_treetop.">",'~'.expand("<slnum>"))
    let treedir = s:NetrwTreePath(w:netrw_treetop)
"   endif
  endif

  " sanity maintenance: keep those //s away...
  let treedir= substitute(treedir,'//$','/','')
"  call Decho("treedir<".treedir.">",'~'.expand("<slnum>"))

"  call Dret("s:NetrwTreeDir <".treedir."> : (side effect) s:treecurpos<".(exists("s:treecurpos")? string(s:treecurpos) : 'n/a').">")
  return treedir
endfun

" ---------------------------------------------------------------------
" s:NetrwTreeDisplay: recursive tree display {{{2
fun! s:NetrwTreeDisplay(dir,depth)
"  call Dfunc("NetrwTreeDisplay(dir<".a:dir."> depth<".a:depth.">)")

  " insure that there are no folds
  setl nofen

  " install ../ and shortdir
  if a:depth == ""
   call setline(line("$")+1,'../')
"   call Decho("setline#".line("$")." ../ (depth is zero)",'~'.expand("<slnum>"))
  endif
  if a:dir =~ '^\a\{3,}://'
   if a:dir == w:netrw_treetop
    let shortdir= a:dir
   else
    let shortdir= substitute(a:dir,'^.*/\([^/]\+\)/$','\1/','e')
   endif
   call setline(line("$")+1,a:depth.shortdir)
  else
   let shortdir= substitute(a:dir,'^.*/','','e')
   call setline(line("$")+1,a:depth.shortdir.'/')
  endif
"  call Decho("setline#".line("$")." shortdir<".a:depth.shortdir.">",'~'.expand("<slnum>"))

  " append a / to dir if its missing one
  let dir= a:dir

  " display subtrees (if any)
  let depth= s:treedepthstring.a:depth
"  call Decho("display subtrees with depth<".depth."> and current leaves",'~'.expand("<slnum>"))

"  call Decho("w:netrw_treedict[".dir."]=".string(w:netrw_treedict[dir]),'~'.expand("<slnum>"))
  for entry in w:netrw_treedict[dir]
   let direntry= substitute(dir.'/'.entry,'[@/]$','','e')
"   call Decho("dir<".dir."> entry<".entry."> direntry<".direntry.">",'~'.expand("<slnum>"))
   if entry =~ '/$' && has_key(w:netrw_treedict,direntry)
"    call Decho("<".direntry."> is a key in treedict - display subtree for it",'~'.expand("<slnum>"))
    NetrwKeepj call s:NetrwTreeDisplay(direntry,depth)
   elseif entry =~ '/$' && has_key(w:netrw_treedict,direntry.'/')
"    call Decho("<".direntry."/> is a key in treedict - display subtree for it",'~'.expand("<slnum>"))
    NetrwKeepj call s:NetrwTreeDisplay(direntry.'/',depth)
   elseif entry =~ '@$' && has_key(w:netrw_treedict,direntry.'@')
"    call Decho("<".direntry."/> is a key in treedict - display subtree for it",'~'.expand("<slnum>"))
    NetrwKeepj call s:NetrwTreeDisplay(direntry.'/',depth)
   else
"    call Decho("<".entry."> is not a key in treedict (no subtree)",'~'.expand("<slnum>"))
    sil! NetrwKeepj call setline(line("$")+1,depth.entry)
   endif
  endfor

"  call Dret("NetrwTreeDisplay")
endfun

" ---------------------------------------------------------------------
" s:NetrwTreeListing: displays tree listing from treetop on down, using NetrwTreeDisplay() {{{2
"                     Called by s:PerformListing()
fun! s:NetrwTreeListing(dirname)
  if w:netrw_liststyle == s:TREELIST
"   call Dfunc("NetrwTreeListing() bufname<".expand("%").">")
"   call Decho("curdir<".a:dirname.">",'~'.expand("<slnum>"))
"   call Decho("win#".winnr().": w:netrw_treetop ".(exists("w:netrw_treetop")? "exists" : "doesn't exist")." w:netrw_treedict ".(exists("w:netrw_treedict")? "exists" : "doesn't exit"),'~'.expand("<slnum>"))
"   call Decho("g:netrw_banner=".g:netrw_banner.": banner ".(g:netrw_banner? "enabled" : "suppressed").": (line($)=".line("$")." byte2line(1)=".byte2line(1)." bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))

   " update the treetop
"   call Decho("update the treetop",'~'.expand("<slnum>"))
   if !exists("w:netrw_treetop")
    let w:netrw_treetop= a:dirname
"    call Decho("w:netrw_treetop<".w:netrw_treetop."> (reusing)",'~'.expand("<slnum>"))
   elseif (w:netrw_treetop =~ ('^'.a:dirname) && s:Strlen(a:dirname) < s:Strlen(w:netrw_treetop)) || a:dirname !~ ('^'.w:netrw_treetop)
    let w:netrw_treetop= a:dirname
"    call Decho("w:netrw_treetop<".w:netrw_treetop."> (went up)",'~'.expand("<slnum>"))
   endif

   if !exists("w:netrw_treedict")
    " insure that we have a treedict, albeit empty
"    call Decho("initializing w:netrw_treedict to empty",'~'.expand("<slnum>"))
    let w:netrw_treedict= {}
   endif

   " update the directory listing for the current directory
"   call Decho("updating dictionary with ".a:dirname.":[..directory listing..]",'~'.expand("<slnum>"))
"   call Decho("w:netrw_bannercnt=".w:netrw_bannercnt." line($)=".line("$"),'~'.expand("<slnum>"))
   exe "sil! NetrwKeepj ".w:netrw_bannercnt.',$g@^\.\.\=/$@d'
   let w:netrw_treedict[a:dirname]= getline(w:netrw_bannercnt,line("$"))
"   call Decho("w:treedict[".a:dirname."]= ".string(w:netrw_treedict[a:dirname]),'~'.expand("<slnum>"))
   exe "sil! NetrwKeepj ".w:netrw_bannercnt.",$d"

   " if past banner, record word
   if exists("w:netrw_bannercnt") && line(".") > w:netrw_bannercnt
    let fname= expand("<cword>")
   else
    let fname= ""
   endif
"   call Decho("fname<".fname.">",'~'.expand("<slnum>"))
"   call Decho("g:netrw_banner=".g:netrw_banner.": banner ".(g:netrw_banner? "enabled" : "suppressed").": (line($)=".line("$")." byte2line(1)=".byte2line(1)." bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))

   " display from treetop on down
   NetrwKeepj call s:NetrwTreeDisplay(w:netrw_treetop,"")
"   call Decho("s:NetrwTreeDisplay) setl noma nomod ro",'~'.expand("<slnum>"))

   " remove any blank line remaining as line#1 (happens in treelisting mode with banner suppressed)
   while getline(1) =~ '^\s*$' && byte2line(1) > 0
"    call Decho("deleting blank line",'~'.expand("<slnum>"))
    1d
   endwhile

   exe "setl ".g:netrw_bufsettings

"   call Dret("NetrwTreeListing : bufname<".expand("%").">")
   return
  endif
endfun

" ---------------------------------------------------------------------
" s:NetrwTreePath: returns path to current file in tree listing {{{2
"                  Normally, treetop is w:netrw_treetop, but a
"                  user of the function ( netrw#SetTreetop() )
"                  wipes that out prior to calling this function
fun! s:NetrwTreePath(treetop)
"  call Dfunc("s:NetrwTreePath() line#".line(".")."<".getline(".").">")
  let depth = substitute(getline('.'),'^\(\%('.s:treedepthstring.'\)*\)[^'.s:treedepthstring.'].\{-}$','\1','e')
"  call Decho("depth<".depth."> 1st subst",'~'.expand("<slnum>"))
  let depth = substitute(depth,'^'.s:treedepthstring,'','')
"  call Decho("depth<".depth."> 2nd subst (first depth removed)",'~'.expand("<slnum>"))
  let curline= getline('.')
"  call Decho("curline<".curline.'>','~'.expand("<slnum>"))
  if curline =~ '/$'
"   call Decho("extract tree directory from current line",'~'.expand("<slnum>"))
   let treedir= substitute(curline,'^\%('.s:treedepthstring.'\)*\([^'.s:treedepthstring.'].\{-}\)$','\1','e')
"   call Decho("treedir<".treedir.">",'~'.expand("<slnum>"))
  elseif curline =~ '@\s\+-->'
"   call Decho("extract tree directory using symbolic link",'~'.expand("<slnum>"))
   let treedir= substitute(curline,'^\%('.s:treedepthstring.'\)*\([^'.s:treedepthstring.'].\{-}\)$','\1','e')
   let treedir= substitute(treedir,'@\s\+-->.*$','','e')
"   call Decho("treedir<".treedir.">",'~'.expand("<slnum>"))
  else
"   call Decho("do not extract tree directory from current line and set treedir to empty",'~'.expand("<slnum>"))
   let treedir= ""
  endif
  " construct treedir by searching backwards at correct depth
"  call Decho("construct treedir by searching backwards for correct depth",'~'.expand("<slnum>"))
"  call Decho("initial      treedir<".treedir."> depth<".depth.">",'~'.expand("<slnum>"))
  while depth != "" && search('^'.depth.'[^'.s:treedepthstring.'].\{-}/$','bW')
   let dirname= substitute(getline('.'),'^\('.s:treedepthstring.'\)*','','e')
   let treedir= dirname.treedir
   let depth  = substitute(depth,'^'.s:treedepthstring,'','')
"   call Decho("constructing treedir<".treedir.">: dirname<".dirname."> while depth<".depth.">",'~'.expand("<slnum>"))
  endwhile
  if a:treetop =~ '/$'
   let treedir= a:treetop.treedir
  else
   let treedir= a:treetop.'/'.treedir
  endif
  let treedir= substitute(treedir,'//$','/','')
"  call Dret("s:NetrwTreePath <".treedir.">")
  return treedir
endfun

" ---------------------------------------------------------------------
" s:NetrwWideListing: {{{2
fun! s:NetrwWideListing()

  if w:netrw_liststyle == s:WIDELIST
"   call Dfunc("NetrwWideListing() w:netrw_liststyle=".w:netrw_liststyle.' fo='.&fo.' l:fo='.&l:fo)
   " look for longest filename (cpf=characters per filename)
   " cpf: characters per filename
   " fpl: filenames per line
   " fpc: filenames per column
   setl ma noro
"   call Decho("setl ma noro",'~'.expand("<slnum>"))
   let b:netrw_cpf= 0
   if line("$") >= w:netrw_bannercnt
    exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$g/^./if virtcol("$") > b:netrw_cpf|let b:netrw_cpf= virtcol("$")|endif'
    NetrwKeepj call histdel("/",-1)
   else
"    call Dret("NetrwWideListing")
    return
   endif
   let b:netrw_cpf= b:netrw_cpf + 2
"   call Decho("b:netrw_cpf=max_filename_length+2=".b:netrw_cpf,'~'.expand("<slnum>"))

   " determine qty files per line (fpl)
   let w:netrw_fpl= winwidth(0)/b:netrw_cpf
   if w:netrw_fpl <= 0
    let w:netrw_fpl= 1
   endif
"   call Decho("fpl= [winwidth=".winwidth(0)."]/[b:netrw_cpf=".b:netrw_cpf.']='.w:netrw_fpl,'~'.expand("<slnum>"))

   " make wide display
   "   fpc: files per column of wide listing
   exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$s/^.*$/\=escape(printf("%-'.b:netrw_cpf.'S",submatch(0)),"\\")/'
   NetrwKeepj call histdel("/",-1)
   let fpc         = (line("$") - w:netrw_bannercnt + w:netrw_fpl)/w:netrw_fpl
   let newcolstart = w:netrw_bannercnt + fpc
   let newcolend   = newcolstart + fpc - 1
"   call Decho("bannercnt=".w:netrw_bannercnt." fpl=".w:netrw_fpl." fpc=".fpc." newcol[".newcolstart.",".newcolend."]",'~'.expand("<slnum>"))
   if has("clipboard")
    sil! let keepregstar = @*
   endif
   while line("$") >= newcolstart
    if newcolend > line("$") | let newcolend= line("$") | endif
    let newcolqty= newcolend - newcolstart
    exe newcolstart
    if newcolqty == 0
     exe "sil! NetrwKeepj norm! 0\<c-v>$hx".w:netrw_bannercnt."G$p"
    else
     exe "sil! NetrwKeepj norm! 0\<c-v>".newcolqty.'j$hx'.w:netrw_bannercnt.'G$p'
    endif
    exe "sil! NetrwKeepj ".newcolstart.','.newcolend.'d'
    exe 'sil! NetrwKeepj '.w:netrw_bannercnt
   endwhile
   if has("clipboard")
    sil! let @*= keepregstar
   endif
   exe "sil! NetrwKeepj ".w:netrw_bannercnt.',$s/\s\+$//e'
   NetrwKeepj call histdel("/",-1)
   exe 'nno <buffer> <silent> w	:call search(''^.\\|\s\s\zs\S'',''W'')'."\<cr>"
   exe 'nno <buffer> <silent> b	:call search(''^.\\|\s\s\zs\S'',''bW'')'."\<cr>"
"   call Decho("NetrwWideListing) setl noma nomod ro",'~'.expand("<slnum>"))
   exe "setl ".g:netrw_bufsettings
"   call Decho("(NetrwWideListing) ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"   call Dret("NetrwWideListing")
   return
  else
   if hasmapto("w","n")
    sil! nunmap <buffer> w
   endif
   if hasmapto("b","n")
    sil! nunmap <buffer> b
   endif
  endif

endfun

" ---------------------------------------------------------------------
" s:PerformListing: {{{2
fun! s:PerformListing(islocal)
"  call Dfunc("s:PerformListing(islocal=".a:islocal.")")
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol()." line($)=".line("$"),'~'.expand("<slnum>"))
"  call Decho("settings: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (enter)",'~'.expand("<slnum>"))

  " set up syntax highlighting {{{3
"  call Decho("--set up syntax highlighting (ie. setl ft=netrw)",'~'.expand("<slnum>"))
  sil! setl ft=netrw

  NetrwKeepj call s:NetrwSafeOptions()
  setl noro ma
"  call Decho("setl noro ma bh=".&bh,'~'.expand("<slnum>"))

"  if exists("g:netrw_silent") && g:netrw_silent == 0 && &ch >= 1	" Decho
"   call Decho("(netrw) Processing your browsing request...",'~'.expand("<slnum>"))
"  endif								" Decho

"  call Decho('w:netrw_liststyle='.(exists("w:netrw_liststyle")? w:netrw_liststyle : 'n/a'),'~'.expand("<slnum>"))
  if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST && exists("w:netrw_treedict")
   " force a refresh for tree listings
"   call Decho("force refresh for treelisting: clear buffer<".expand("%")."> with :%d",'~'.expand("<slnum>"))
   sil! NetrwKeepj %d _
  endif

  " save current directory on directory history list
  NetrwKeepj call s:NetrwBookHistHandler(3,b:netrw_curdir)

  " Set up the banner {{{3
  if g:netrw_banner
"   call Decho("--set up banner",'~'.expand("<slnum>"))
   NetrwKeepj call setline(1,'" ============================================================================')
   if exists("g:netrw_pchk")
    " this undocumented option allows pchk to run with different versions of netrw without causing spurious
    " failure detections.
    NetrwKeepj call setline(2,'" Netrw Directory Listing')
   else
    NetrwKeepj call setline(2,'" Netrw Directory Listing                                        (netrw '.g:loaded_netrw.')')
   endif
   if exists("g:netrw_pchk")
    let curdir= substitute(b:netrw_curdir,expand("$HOME"),'~','')
   else
    let curdir= b:netrw_curdir
   endif
   if exists("g:netrw_bannerbackslash") && g:netrw_bannerbackslash
    NetrwKeepj call setline(3,'"   '.substitute(curdir,'/','\\','g'))
   else
    NetrwKeepj call setline(3,'"   '.curdir)
   endif
   let w:netrw_bannercnt= 3
   NetrwKeepj exe "sil! NetrwKeepj ".w:netrw_bannercnt
  else
"   call Decho("--no banner",'~'.expand("<slnum>"))
   NetrwKeepj 1
   let w:netrw_bannercnt= 1
  endif
"  call Decho("w:netrw_bannercnt=".w:netrw_bannercnt." win#".winnr(),'~'.expand("<slnum>"))
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol()." line($)=".line("$"),'~'.expand("<slnum>"))

  let sortby= g:netrw_sort_by
  if g:netrw_sort_direction =~ "^r"
   let sortby= sortby." reversed"
  endif

  " Sorted by... {{{3
  if g:netrw_banner
"   call Decho("--handle specified sorting: g:netrw_sort_by<".g:netrw_sort_by.">",'~'.expand("<slnum>"))
   if g:netrw_sort_by =~ "^n"
"   call Decho("directories will be sorted by name",'~'.expand("<slnum>"))
    " sorted by name
    NetrwKeepj put ='\"   Sorted by      '.sortby
    NetrwKeepj put ='\"   Sort sequence: '.g:netrw_sort_sequence
    let w:netrw_bannercnt= w:netrw_bannercnt + 2
   else
"   call Decho("directories will be sorted by size or time",'~'.expand("<slnum>"))
    " sorted by size or date
    NetrwKeepj put ='\"   Sorted by '.sortby
    let w:netrw_bannercnt= w:netrw_bannercnt + 1
   endif
   exe "sil! NetrwKeepj ".w:netrw_bannercnt
"  else " Decho
"   call Decho("g:netrw_banner=".g:netrw_banner.": banner ".(g:netrw_banner? "enabled" : "suppressed").": (line($)=".line("$")." byte2line(1)=".byte2line(1)." bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))
  endif

  " show copy/move target, if any
  if g:netrw_banner
   if exists("s:netrwmftgt") && exists("s:netrwmftgt_islocal")
"    call Decho("--show copy/move target<".s:netrwmftgt.">",'~'.expand("<slnum>"))
    NetrwKeepj put =''
    if s:netrwmftgt_islocal
     sil! NetrwKeepj call setline(line("."),'"   Copy/Move Tgt: '.s:netrwmftgt.' (local)')
    else
     sil! NetrwKeepj call setline(line("."),'"   Copy/Move Tgt: '.s:netrwmftgt.' (remote)')
    endif
    let w:netrw_bannercnt= w:netrw_bannercnt + 1
   else
"    call Decho("s:netrwmftgt does not exist, don't make Copy/Move Tgt",'~'.expand("<slnum>"))
   endif
   exe "sil! NetrwKeepj ".w:netrw_bannercnt
  endif

  " Hiding...  -or-  Showing... {{{3
  if g:netrw_banner
"   call Decho("--handle hiding/showing (g:netrw_hide=".g:netrw_list_hide." g:netrw_list_hide<".g:netrw_list_hide.">)",'~'.expand("<slnum>"))
   if g:netrw_list_hide != "" && g:netrw_hide
    if g:netrw_hide == 1
     NetrwKeepj put ='\"   Hiding:        '.g:netrw_list_hide
    else
     NetrwKeepj put ='\"   Showing:       '.g:netrw_list_hide
    endif
    let w:netrw_bannercnt= w:netrw_bannercnt + 1
   endif
   exe "NetrwKeepj ".w:netrw_bannercnt

"   call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
   let quickhelp   = g:netrw_quickhelp%len(s:QuickHelp)
"   call Decho("quickhelp   =".quickhelp,'~'.expand("<slnum>"))
   NetrwKeepj put ='\"   Quick Help: <F1>:help  '.s:QuickHelp[quickhelp]
"   call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
   NetrwKeepj put ='\" =============================================================================='
   let w:netrw_bannercnt= w:netrw_bannercnt + 2
"  else " Decho
"   call Decho("g:netrw_banner=".g:netrw_banner.": banner ".(g:netrw_banner? "enabled" : "suppressed").": (line($)=".line("$")." byte2line(1)=".byte2line(1)." bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))
  endif

  " bannercnt should index the line just after the banner
  if g:netrw_banner
   let w:netrw_bannercnt= w:netrw_bannercnt + 1
   exe "sil! NetrwKeepj ".w:netrw_bannercnt
"   call Decho("--w:netrw_bannercnt=".w:netrw_bannercnt." (should index line just after banner) line($)=".line("$"),'~'.expand("<slnum>"))
"  else " Decho
"   call Decho("g:netrw_banner=".g:netrw_banner.": banner ".(g:netrw_banner? "enabled" : "suppressed").": (line($)=".line("$")." byte2line(1)=".byte2line(1)." bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))
  endif

  " get list of files
"  call Decho("--Get list of files - islocal=".a:islocal,'~'.expand("<slnum>"))
  if a:islocal
   NetrwKeepj call s:LocalListing()
  else " remote
   NetrwKeepj let badresult= s:NetrwRemoteListing()
   if badresult
"    call Decho("w:netrw_bannercnt=".(exists("w:netrw_bannercnt")? w:netrw_bannercnt : 'n/a')." win#".winnr()." buf#".bufnr("%")."<".bufname("%").">",'~'.expand("<slnum>"))
"    call Dret("s:PerformListing : error detected by NetrwRemoteListing")
    return
   endif
  endif

  " manipulate the directory listing (hide, sort) {{{3
  if !exists("w:netrw_bannercnt")
   let w:netrw_bannercnt= 0
  endif
"  call Decho("--manipulate directory listing (hide, sort)",'~'.expand("<slnum>"))
"  call Decho("g:netrw_banner=".g:netrw_banner." w:netrw_bannercnt=".w:netrw_bannercnt." (banner complete)",'~'.expand("<slnum>"))
"  call Decho("g:netrw_banner=".g:netrw_banner.": banner ".(g:netrw_banner? "enabled" : "suppressed").": (line($)=".line("$")." byte2line(1)=".byte2line(1)." bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))

  if !g:netrw_banner || line("$") >= w:netrw_bannercnt
"   call Decho("manipulate directory listing (hide)",'~'.expand("<slnum>"))
"   call Decho("g:netrw_hide=".g:netrw_hide." g:netrw_list_hide<".g:netrw_list_hide.">",'~'.expand("<slnum>"))
   if g:netrw_hide && g:netrw_list_hide != ""
    NetrwKeepj call s:NetrwListHide()
   endif
   if !g:netrw_banner || line("$") >= w:netrw_bannercnt
"    call Decho("manipulate directory listing (sort) : g:netrw_sort_by<".g:netrw_sort_by.">",'~'.expand("<slnum>"))

    if g:netrw_sort_by =~ "^n"
     " sort by name
     NetrwKeepj call s:NetrwSetSort()

     if !g:netrw_banner || w:netrw_bannercnt < line("$")
"      call Decho("g:netrw_sort_direction=".g:netrw_sort_direction." (bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))
      if g:netrw_sort_direction =~ 'n'
       " normal direction sorting
       exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$sort'.' '.g:netrw_sort_options
      else
       " reverse direction sorting
       exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$sort!'.' '.g:netrw_sort_options
      endif
     endif
     " remove priority pattern prefix
"     call Decho("remove priority pattern prefix",'~'.expand("<slnum>"))
     exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$s/^\d\{3}'.g:netrw_sepchr.'//e'
     NetrwKeepj call histdel("/",-1)

    elseif g:netrw_sort_by =~ "^ext"
     " sort by extension
     exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$g+/+s/^/001'.g:netrw_sepchr.'/'
     NetrwKeepj call histdel("/",-1)
     exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$v+[./]+s/^/002'.g:netrw_sepchr.'/'
     NetrwKeepj call histdel("/",-1)
     exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$v+['.g:netrw_sepchr.'/]+s/^\(.*\.\)\(.\{-\}\)$/\2'.g:netrw_sepchr.'&/e'
     NetrwKeepj call histdel("/",-1)
     if !g:netrw_banner || w:netrw_bannercnt < line("$")
"      call Decho("g:netrw_sort_direction=".g:netrw_sort_direction." (bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))
      if g:netrw_sort_direction =~ 'n'
       " normal direction sorting
       exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$sort'.' '.g:netrw_sort_options
      else
       " reverse direction sorting
       exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$sort!'.' '.g:netrw_sort_options
      endif
     endif
     exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$s/^.\{-}'.g:netrw_sepchr.'//e'
     NetrwKeepj call histdel("/",-1)

    elseif a:islocal
     if !g:netrw_banner || w:netrw_bannercnt < line("$")
"      call Decho("g:netrw_sort_direction=".g:netrw_sort_direction,'~'.expand("<slnum>"))
      if g:netrw_sort_direction =~ 'n'
"       call Decho('exe sil NetrwKeepj '.w:netrw_bannercnt.',$sort','~'.expand("<slnum>"))
       exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$sort'.' '.g:netrw_sort_options
      else
"       call Decho('exe sil NetrwKeepj '.w:netrw_bannercnt.',$sort!','~'.expand("<slnum>"))
       exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$sort!'.' '.g:netrw_sort_options
      endif
     exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$s/^\d\{-}\///e'
     NetrwKeepj call histdel("/",-1)
     endif
    endif

   elseif g:netrw_sort_direction =~ 'r'
"    call Decho('(s:PerformListing) reverse the sorted listing','~'.expand("<slnum>"))
    if !g:netrw_banner || w:netrw_bannercnt < line('$')
     exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$g/^/m '.w:netrw_bannercnt
     call histdel("/",-1)
    endif
   endif
  endif
"  call Decho("g:netrw_banner=".g:netrw_banner.": banner ".(g:netrw_banner? "enabled" : "suppressed").": (line($)=".line("$")." byte2line(1)=".byte2line(1)." bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))

  " convert to wide/tree listing {{{3
"  call Decho("--modify display if wide/tree listing style",'~'.expand("<slnum>"))
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (internal#1)",'~'.expand("<slnum>"))
  NetrwKeepj call s:NetrwWideListing()
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (internal#2)",'~'.expand("<slnum>"))
  NetrwKeepj call s:NetrwTreeListing(b:netrw_curdir)
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (internal#3)",'~'.expand("<slnum>"))

  " resolve symbolic links if local and (thin or tree)
  if a:islocal && (w:netrw_liststyle == s:THINLIST || w:netrw_liststyle == s:TREELIST)
"   call Decho("--resolve symbolic links if local and thin|tree",'~'.expand("<slnum>"))
   g/@$/call s:ShowLink()
  endif

  if exists("w:netrw_bannercnt") && (line("$") >= w:netrw_bannercnt || !g:netrw_banner)
   " place cursor on the top-left corner of the file listing
"   call Decho("--place cursor on top-left corner of file listing",'~'.expand("<slnum>"))
   exe 'sil! '.w:netrw_bannercnt
   sil! NetrwKeepj norm! 0
"   call Decho("  tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol()." line($)=".line("$"),'~'.expand("<slnum>"))
  else
"   call Decho("--did NOT place cursor on top-left corner",'~'.expand("<slnum>"))
"   call Decho("  w:netrw_bannercnt=".(exists("w:netrw_bannercnt")? w:netrw_bannercnt : 'n/a'),'~'.expand("<slnum>"))
"   call Decho("  line($)=".line("$"),'~'.expand("<slnum>"))
"   call Decho("  g:netrw_banner=".(exists("g:netrw_banner")? g:netrw_banner : 'n/a'),'~'.expand("<slnum>"))
  endif

  " record previous current directory
  let w:netrw_prvdir= b:netrw_curdir
"  call Decho("--record netrw_prvdir<".w:netrw_prvdir.">",'~'.expand("<slnum>"))

  " save certain window-oriented variables into buffer-oriented variables {{{3
"  call Decho("--save some window-oriented variables into buffer oriented variables",'~'.expand("<slnum>"))
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (internal#4)",'~'.expand("<slnum>"))
  NetrwKeepj call s:SetBufWinVars()
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (internal#5)",'~'.expand("<slnum>"))
  NetrwKeepj call s:NetrwOptionRestore("w:")
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (internal#6)",'~'.expand("<slnum>"))

  " set display to netrw display settings
"  call Decho("--set display to netrw display settings (".g:netrw_bufsettings.")",'~'.expand("<slnum>"))
  exe "setl ".g:netrw_bufsettings
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (internal#7)",'~'.expand("<slnum>"))
  if g:netrw_liststyle == s:LONGLIST
"   call Decho("exe setl ts=".(g:netrw_maxfilenamelen+1),'~'.expand("<slnum>"))
   exe "setl ts=".(g:netrw_maxfilenamelen+1)
  endif

  if exists("s:treecurpos")
"   call Decho("s:treecurpos exists; restore posn",'~'.expand("<slnum>"))
"   call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (internal#8)",'~'.expand("<slnum>"))
   NetrwKeepj call netrw#RestorePosn(s:treecurpos)
   unlet s:treecurpos
  endif

"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo. " (return)",'~'.expand("<slnum>"))
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol()." line($)=".line("$"),'~'.expand("<slnum>"))
"  call Dret("s:PerformListing : curpos<".string(getpos(".")).">")
endfun

" ---------------------------------------------------------------------
" s:SetupNetrwStatusLine: {{{2
fun! s:SetupNetrwStatusLine(statline)
"  call Dfunc("SetupNetrwStatusLine(statline<".a:statline.">)")

  if !exists("s:netrw_setup_statline")
   let s:netrw_setup_statline= 1
"   call Decho("do first-time status line setup",'~'.expand("<slnum>"))

   if !exists("s:netrw_users_stl")
    let s:netrw_users_stl= &stl
   endif
   if !exists("s:netrw_users_ls")
    let s:netrw_users_ls= &laststatus
   endif

   " set up User9 highlighting as needed
   let keepa= @a
   redir @a
   try
    hi User9
   catch /^Vim\%((\a\{3,})\)\=:E411/
    if &bg == "dark"
     hi User9 ctermfg=yellow ctermbg=blue guifg=yellow guibg=blue
    else
     hi User9 ctermbg=yellow ctermfg=blue guibg=yellow guifg=blue
    endif
   endtry
   redir END
   let @a= keepa
  endif

  " set up status line (may use User9 highlighting)
  " insure that windows have a statusline
  " make sure statusline is displayed
  let &stl=a:statline
  setl laststatus=2
"  call Decho("stl=".&stl,'~'.expand("<slnum>"))
  redraw

"  call Dret("SetupNetrwStatusLine : stl=".&stl)
endfun

" ---------------------------------------------------------------------
"  Remote Directory Browsing Support:    {{{1
" ===========================================

" ---------------------------------------------------------------------
" s:NetrwRemoteFtpCmd: unfortunately, not all ftp servers honor options for ls {{{2
"  This function assumes that a long listing will be received.  Size, time,
"  and reverse sorts will be requested of the server but not otherwise
"  enforced here.
fun! s:NetrwRemoteFtpCmd(path,listcmd)
"  call Dfunc("NetrwRemoteFtpCmd(path<".a:path."> listcmd<".a:listcmd.">) w:netrw_method=".(exists("w:netrw_method")? w:netrw_method : (exists("b:netrw_method")? b:netrw_method : "???")))
"  call Decho("line($)=".line("$")." w:netrw_bannercnt=".w:netrw_bannercnt,'~'.expand("<slnum>"))
  " sanity check: {{{3
  if !exists("w:netrw_method")
   if exists("b:netrw_method")
    let w:netrw_method= b:netrw_method
   else
    call netrw#ErrorMsg(2,"(s:NetrwRemoteFtpCmd) internal netrw error",93)
"    call Dret("NetrwRemoteFtpCmd")
    return
   endif
  endif

  " WinXX ftp uses unix style input, so set ff to unix	" {{{3
  let ffkeep= &ff
  setl ma ff=unix noro
"  call Decho("setl ma ff=unix noro",'~'.expand("<slnum>"))

  " clear off any older non-banner lines	" {{{3
  " note that w:netrw_bannercnt indexes the line after the banner
"  call Decho('exe sil! NetrwKeepj '.w:netrw_bannercnt.",$d  (clear off old non-banner lines)",'~'.expand("<slnum>"))
  exe "sil! NetrwKeepj ".w:netrw_bannercnt.",$d"

  ".........................................
  if w:netrw_method == 2 || w:netrw_method == 5	" {{{3
   " ftp + <.netrc>:  Method #2
   if a:path != ""
    NetrwKeepj put ='cd \"'.a:path.'\"'
   endif
   if exists("g:netrw_ftpextracmd")
    NetrwKeepj put =g:netrw_ftpextracmd
"    call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
   endif
   NetrwKeepj call setline(line("$")+1,a:listcmd)
"   exe "NetrwKeepj ".w:netrw_bannercnt.',$g/^./call Decho("ftp#".line(".").": ".getline("."),''~''.expand("<slnum>"))'
   if exists("g:netrw_port") && g:netrw_port != ""
"    call Decho("exe ".s:netrw_silentxfer.w:netrw_bannercnt.",$!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1)." ".shellescape(g:netrw_port,1),'~'.expand("<slnum>"))
    exe s:netrw_silentxfer." NetrwKeepj ".w:netrw_bannercnt.",$!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1)." ".shellescape(g:netrw_port,1)
   else
"    call Decho("exe ".s:netrw_silentxfer.w:netrw_bannercnt.",$!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1),'~'.expand("<slnum>"))
    exe s:netrw_silentxfer." NetrwKeepj ".w:netrw_bannercnt.",$!".s:netrw_ftp_cmd." -i ".shellescape(g:netrw_machine,1)
   endif

  ".........................................
  elseif w:netrw_method == 3	" {{{3
   " ftp + machine,id,passwd,filename:  Method #3
    setl ff=unix
    if exists("g:netrw_port") && g:netrw_port != ""
     NetrwKeepj put ='open '.g:netrw_machine.' '.g:netrw_port
    else
     NetrwKeepj put ='open '.g:netrw_machine
    endif

    " handle userid and password
    let host= substitute(g:netrw_machine,'\..*$','','')
"    call Decho("host<".host.">",'~'.expand("<slnum>"))
    if exists("s:netrw_hup") && exists("s:netrw_hup[host]")
     call NetUserPass("ftp:".host)
    endif
    if exists("g:netrw_uid") && g:netrw_uid != ""
     if exists("g:netrw_ftp") && g:netrw_ftp == 1
      NetrwKeepj put =g:netrw_uid
      if exists("s:netrw_passwd") && s:netrw_passwd != ""
       NetrwKeepj put ='\"'.s:netrw_passwd.'\"'
      endif
     elseif exists("s:netrw_passwd")
      NetrwKeepj put ='user \"'.g:netrw_uid.'\" \"'.s:netrw_passwd.'\"'
     endif
    endif

   if a:path != ""
    NetrwKeepj put ='cd \"'.a:path.'\"'
   endif
   if exists("g:netrw_ftpextracmd")
    NetrwKeepj put =g:netrw_ftpextracmd
"    call Decho("filter input: ".getline('.'),'~'.expand("<slnum>"))
   endif
   NetrwKeepj call setline(line("$")+1,a:listcmd)

   " perform ftp:
   " -i       : turns off interactive prompting from ftp
   " -n  unix : DON'T use <.netrc>, even though it exists
   " -n  win32: quit being obnoxious about password
   if exists("w:netrw_bannercnt")
"    exe w:netrw_bannercnt.',$g/^./call Decho("ftp#".line(".").": ".getline("."),''~''.expand("<slnum>"))'
    call s:NetrwExe(s:netrw_silentxfer.w:netrw_bannercnt.",$!".s:netrw_ftp_cmd." ".g:netrw_ftp_options)
"   else " Decho
"    call Decho("WARNING: w:netrw_bannercnt doesn't exist!",'~'.expand("<slnum>"))
"    g/^./call Decho("SKIPPING ftp#".line(".").": ".getline("."),'~'.expand("<slnum>"))
   endif

  ".........................................
  elseif w:netrw_method == 9	" {{{3
   " sftp username@machine: Method #9
   " s:netrw_sftp_cmd
   setl ff=unix

   " restore settings
   let &ff= ffkeep
"   call Dret("NetrwRemoteFtpCmd")
   return

  ".........................................
  else	" {{{3
   NetrwKeepj call netrw#ErrorMsg(s:WARNING,"unable to comply with your request<" . bufname("%") . ">",23)
  endif

  " cleanup for Windows " {{{3
  if has("win32") || has("win95") || has("win64") || has("win16")
   sil! NetrwKeepj %s/\r$//e
   NetrwKeepj call histdel("/",-1)
  endif
  if a:listcmd == "dir"
   " infer directory/link based on the file permission string
   sil! NetrwKeepj g/d\%([-r][-w][-x]\)\{3}/NetrwKeepj s@$@/@e
   sil! NetrwKeepj g/l\%([-r][-w][-x]\)\{3}/NetrwKeepj s/$/@/e
   NetrwKeepj call histdel("/",-1)
   NetrwKeepj call histdel("/",-1)
   if w:netrw_liststyle == s:THINLIST || w:netrw_liststyle == s:WIDELIST || w:netrw_liststyle == s:TREELIST
    exe "sil! NetrwKeepj ".w:netrw_bannercnt.',$s/^\%(\S\+\s\+\)\{8}//e'
    NetrwKeepj call histdel("/",-1)
   endif
  endif

  " ftp's listing doesn't seem to include ./ or ../ " {{{3
  if !search('^\.\/$\|\s\.\/$','wn')
   exe 'NetrwKeepj '.w:netrw_bannercnt
   NetrwKeepj put ='./'
  endif
  if !search('^\.\.\/$\|\s\.\.\/$','wn')
   exe 'NetrwKeepj '.w:netrw_bannercnt
   NetrwKeepj put ='../'
  endif

  " restore settings " {{{3
  let &ff= ffkeep
"  call Dret("NetrwRemoteFtpCmd")
endfun

" ---------------------------------------------------------------------
" s:NetrwRemoteListing: {{{2
fun! s:NetrwRemoteListing()
"  call Dfunc("s:NetrwRemoteListing() b:netrw_curdir<".b:netrw_curdir.">)")

  if !exists("w:netrw_bannercnt") && exists("s:bannercnt")
   let w:netrw_bannercnt= s:bannercnt
  endif
  if !exists("w:netrw_bannercnt") && exists("b:bannercnt")
   let w:netrw_bannercnt= s:bannercnt
  endif

  call s:RemotePathAnalysis(b:netrw_curdir)

  " sanity check:
  if exists("b:netrw_method") && b:netrw_method =~ '[235]'
"   call Decho("b:netrw_method=".b:netrw_method,'~'.expand("<slnum>"))
   if !executable("ftp")
"    call Decho("ftp is not executable",'~'.expand("<slnum>"))
    if !exists("g:netrw_quiet")
     call netrw#ErrorMsg(s:ERROR,"this system doesn't support remote directory listing via ftp",18)
    endif
    call s:NetrwOptionRestore("w:")
"    call Dret("s:NetrwRemoteListing -1")
    return -1
   endif

  elseif !exists("g:netrw_list_cmd") || g:netrw_list_cmd == ''
"   call Decho("g:netrw_list_cmd<",(exists("g:netrw_list_cmd")? 'n/a' : "-empty-").">",'~'.expand("<slnum>"))
   if !exists("g:netrw_quiet")
    if g:netrw_list_cmd == ""
     NetrwKeepj call netrw#ErrorMsg(s:ERROR,"your g:netrw_list_cmd is empty; perhaps ".g:netrw_ssh_cmd." is not executable on your system",47)
    else
     NetrwKeepj call netrw#ErrorMsg(s:ERROR,"this system doesn't support remote directory listing via ".g:netrw_list_cmd,19)
    endif
   endif

   NetrwKeepj call s:NetrwOptionRestore("w:")
"   call Dret("s:NetrwRemoteListing -1")
   return -1
  endif  " (remote handling sanity check)
"  call Decho("passed remote listing sanity checks",'~'.expand("<slnum>"))

  if exists("b:netrw_method")
"   call Decho("setting w:netrw_method to b:netrw_method<".b:netrw_method.">",'~'.expand("<slnum>"))
   let w:netrw_method= b:netrw_method
  endif

  if s:method == "ftp"
   " use ftp to get remote file listing {{{3
"   call Decho("use ftp to get remote file listing",'~'.expand("<slnum>"))
   let s:method  = "ftp"
   let listcmd = g:netrw_ftp_list_cmd
   if g:netrw_sort_by =~ '^t'
    let listcmd= g:netrw_ftp_timelist_cmd
   elseif g:netrw_sort_by =~ '^s'
    let listcmd= g:netrw_ftp_sizelist_cmd
   endif
"   call Decho("listcmd<".listcmd."> (using g:netrw_ftp_list_cmd)",'~'.expand("<slnum>"))
   call s:NetrwRemoteFtpCmd(s:path,listcmd)
"   exe "sil! keepalt NetrwKeepj ".w:netrw_bannercnt.',$g/^./call Decho("raw listing: ".getline("."),''~''.expand("<slnum>"))'

   " report on missing file or directory messages
   if search('[Nn]o such file or directory\|Failed to change directory')
    let mesg= getline(".")
    if exists("w:netrw_bannercnt")
     setl ma
     exe w:netrw_bannercnt.",$d"
     setl noma
    endif
    NetrwKeepj call s:NetrwOptionRestore("w:")
    call netrw#ErrorMsg(s:WARNING,mesg,96)
"    call Dret("s:NetrwRemoteListing : -1")
    return -1
   endif

   if w:netrw_liststyle == s:THINLIST || w:netrw_liststyle == s:WIDELIST || w:netrw_liststyle == s:TREELIST
    " shorten the listing
"    call Decho("generate short listing",'~'.expand("<slnum>"))
    exe "sil! keepalt NetrwKeepj ".w:netrw_bannercnt

    " cleanup
    if g:netrw_ftp_browse_reject != ""
     exe "sil! keepalt NetrwKeepj g/".g:netrw_ftp_browse_reject."/NetrwKeepj d"
     NetrwKeepj call histdel("/",-1)
    endif
    sil! NetrwKeepj %s/\r$//e
    NetrwKeepj call histdel("/",-1)

    " if there's no ../ listed, then put ../ in
    let line1= line(".")
    exe "sil! NetrwKeepj ".w:netrw_bannercnt
    let line2= search('\.\.\/\%(\s\|$\)','cnW')
"    call Decho("search(".'\.\.\/\%(\s\|$\)'."','cnW')=".line2."  w:netrw_bannercnt=".w:netrw_bannercnt,'~'.expand("<slnum>"))
    if line2 == 0
"     call Decho("netrw is putting ../ into listing",'~'.expand("<slnum>"))
     sil! NetrwKeepj put='../'
    endif
    exe "sil! NetrwKeepj ".line1
    sil! NetrwKeepj norm! 0

"    call Decho("line1=".line1." line2=".line2." line(.)=".line("."),'~'.expand("<slnum>"))
    if search('^\d\{2}-\d\{2}-\d\{2}\s','n') " M$ ftp site cleanup
"     call Decho("M$ ftp cleanup",'~'.expand("<slnum>"))
     exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$s/^\d\{2}-\d\{2}-\d\{2}\s\+\d\+:\d\+[AaPp][Mm]\s\+\%(<DIR>\|\d\+\)\s\+//'
     NetrwKeepj call histdel("/",-1)
    else " normal ftp cleanup
"     call Decho("normal ftp cleanup",'~'.expand("<slnum>"))
     exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$s/^\(\%(\S\+\s\+\)\{7}\S\+\)\s\+\(\S.*\)$/\2/e'
     exe "sil! NetrwKeepj ".w:netrw_bannercnt.',$g/ -> /s# -> .*/$#/#e'
     exe "sil! NetrwKeepj ".w:netrw_bannercnt.',$g/ -> /s# -> .*$#/#e'
     NetrwKeepj call histdel("/",-1)
     NetrwKeepj call histdel("/",-1)
     NetrwKeepj call histdel("/",-1)
    endif
   endif

   else
   " use ssh to get remote file listing {{{3
"   call Decho("use ssh to get remote file listing: s:path<".s:path.">",'~'.expand("<slnum>"))
   let listcmd= s:MakeSshCmd(g:netrw_list_cmd)
"   call Decho("listcmd<".listcmd."> (using g:netrw_list_cmd)",'~'.expand("<slnum>"))
   if g:netrw_scp_cmd =~ '^pscp'
"    call Decho("1: exe r! ".shellescape(listcmd.s:path, 1),'~'.expand("<slnum>"))
    exe "NetrwKeepj r! ".listcmd.shellescape(s:path, 1)
    " remove rubbish and adjust listing format of 'pscp' to 'ssh ls -FLa' like
    sil! NetrwKeepj g/^Listing directory/NetrwKeepj d
    sil! NetrwKeepj g/^d[-rwx][-rwx][-rwx]/NetrwKeepj s+$+/+e
    sil! NetrwKeepj g/^l[-rwx][-rwx][-rwx]/NetrwKeepj s+$+@+e
    NetrwKeepj call histdel("/",-1)
    NetrwKeepj call histdel("/",-1)
    NetrwKeepj call histdel("/",-1)
    if g:netrw_liststyle != s:LONGLIST
     sil! NetrwKeepj g/^[dlsp-][-rwx][-rwx][-rwx]/NetrwKeepj s/^.*\s\(\S\+\)$/\1/e
     NetrwKeepj call histdel("/",-1)
    endif
   else
    if s:path == ""
"     call Decho("2: exe r! ".listcmd,'~'.expand("<slnum>"))
     exe "NetrwKeepj keepalt r! ".listcmd
    else
"     call Decho("3: exe r! ".listcmd.' '.shellescape(fnameescape(s:path),1),'~'.expand("<slnum>"))
     exe "NetrwKeepj keepalt r! ".listcmd.' '.shellescape(fnameescape(s:path),1)
"     call Decho("listcmd<".listcmd."> path<".s:path.">",'~'.expand("<slnum>"))
    endif
   endif

   " cleanup
   if g:netrw_ssh_browse_reject != ""
"    call Decho("cleanup: exe sil! g/".g:netrw_ssh_browse_reject."/NetrwKeepj d",'~'.expand("<slnum>"))
    exe "sil! g/".g:netrw_ssh_browse_reject."/NetrwKeepj d"
    NetrwKeepj call histdel("/",-1)
   endif
  endif

  if w:netrw_liststyle == s:LONGLIST
   " do a long listing; these substitutions need to be done prior to sorting {{{3
"   call Decho("fix long listing:",'~'.expand("<slnum>"))

   if s:method == "ftp"
    " cleanup
    exe "sil! NetrwKeepj ".w:netrw_bannercnt
    while getline('.') =~ g:netrw_ftp_browse_reject
     sil! NetrwKeepj d
    endwhile
    " if there's no ../ listed, then put ../ in
    let line1= line(".")
    sil! NetrwKeepj 1
    sil! NetrwKeepj call search('^\.\.\/\%(\s\|$\)','W')
    let line2= line(".")
    if line2 == 0
     if b:netrw_curdir != '/'
      exe 'sil! NetrwKeepj '.w:netrw_bannercnt."put='../'"
     endif
    endif
    exe "sil! NetrwKeepj ".line1
    sil! NetrwKeepj norm! 0
   endif

   if search('^\d\{2}-\d\{2}-\d\{2}\s','n') " M$ ftp site cleanup
"    call Decho("M$ ftp site listing cleanup",'~'.expand("<slnum>"))
    exe 'sil! NetrwKeepj '.w:netrw_bannercnt.',$s/^\(\d\{2}-\d\{2}-\d\{2}\s\+\d\+:\d\+[AaPp][Mm]\s\+\%(<DIR>\|\d\+\)\s\+\)\(\w.*\)$/\2\t\1/'
   elseif exists("w:netrw_bannercnt") && w:netrw_bannercnt <= line("$")
"    call Decho("normal ftp site listing cleanup: bannercnt=".w:netrw_bannercnt." line($)=".line("$"),'~'.expand("<slnum>"))
    exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$s/ -> .*$//e'
    exe 'sil NetrwKeepj '.w:netrw_bannercnt.',$s/^\(\%(\S\+\s\+\)\{7}\S\+\)\s\+\(\S.*\)$/\2 \t\1/e'
    exe 'sil NetrwKeepj '.w:netrw_bannercnt
    NetrwKeepj call histdel("/",-1)
    NetrwKeepj call histdel("/",-1)
    NetrwKeepj call histdel("/",-1)
   endif
  endif

"  if exists("w:netrw_bannercnt") && w:netrw_bannercnt <= line("$") " Decho
"   exe "NetrwKeepj ".w:netrw_bannercnt.',$g/^./call Decho("listing: ".getline("."),''~''.expand("<slnum>"))'
"  endif " Decho

"  call Dret("s:NetrwRemoteListing 0")
  return 0
endfun

" ---------------------------------------------------------------------
" s:NetrwRemoteRm: remove/delete a remote file or directory {{{2
fun! s:NetrwRemoteRm(usrhost,path) range
"  call Dfunc("s:NetrwRemoteRm(usrhost<".a:usrhost."> path<".a:path.">) virtcol=".virtcol("."))
"  call Decho("firstline=".a:firstline." lastline=".a:lastline,'~'.expand("<slnum>"))
  let svpos= netrw#SavePosn()

  let all= 0
  if exists("s:netrwmarkfilelist_{bufnr('%')}")
   " remove all marked files
"   call Decho("remove all marked files with bufnr#".bufnr("%"),'~'.expand("<slnum>"))
   for fname in s:netrwmarkfilelist_{bufnr("%")}
    let ok= s:NetrwRemoteRmFile(a:path,fname,all)
    if ok =~ 'q\%[uit]'
     break
    elseif ok =~ 'a\%[ll]'
     let all= 1
    endif
   endfor
   call s:NetrwUnmarkList(bufnr("%"),b:netrw_curdir)

  else
   " remove files specified by range
"   call Decho("remove files specified by range",'~'.expand("<slnum>"))

   " preparation for removing multiple files/directories
   let keepsol = &l:sol
   setl nosol
   let ctr    = a:firstline

   " remove multiple files and directories
   while ctr <= a:lastline
    exe "NetrwKeepj ".ctr
    let ok= s:NetrwRemoteRmFile(a:path,s:NetrwGetWord(),all)
    if ok =~ 'q\%[uit]'
     break
    elseif ok =~ 'a\%[ll]'
     let all= 1
    endif
    let ctr= ctr + 1
   endwhile
   let &l:sol = keepsol
  endif

  " refresh the (remote) directory listing
"  call Decho("refresh remote directory listing",'~'.expand("<slnum>"))
  NetrwKeepj call s:NetrwRefresh(0,s:NetrwBrowseChgDir(0,'./'))
  NetrwKeepj call netrw#RestorePosn(svpos)

"  call Dret("s:NetrwRemoteRm")
endfun

" ---------------------------------------------------------------------
" s:NetrwRemoteRmFile: {{{2
fun! s:NetrwRemoteRmFile(path,rmfile,all)
"  call Dfunc("s:NetrwRemoteRmFile(path<".a:path."> rmfile<".a:rmfile.">) all=".a:all)

  let all= a:all
  let ok = ""

  if a:rmfile !~ '^"' && (a:rmfile =~ '@$' || a:rmfile !~ '[\/]$')
   " attempt to remove file
"    call Decho("attempt to remove file (all=".all.")",'~'.expand("<slnum>"))
   if !all
    echohl Statement
"    call Decho("case all=0:",'~'.expand("<slnum>"))
    call inputsave()
    let ok= input("Confirm deletion of file<".a:rmfile."> ","[{y(es)},n(o),a(ll),q(uit)] ")
    call inputrestore()
    echohl NONE
    if ok == ""
     let ok="no"
    endif
    let ok= substitute(ok,'\[{y(es)},n(o),a(ll),q(uit)]\s*','','e')
    if ok =~ 'a\%[ll]'
     let all= 1
    endif
   endif

   if all || ok =~ 'y\%[es]' || ok == ""
"    call Decho("case all=".all." or ok<".ok.">".(exists("w:netrw_method")? ': netrw_method='.w:netrw_method : ""),'~'.expand("<slnum>"))
    if exists("w:netrw_method") && (w:netrw_method == 2 || w:netrw_method == 3)
"     call Decho("case ftp:",'~'.expand("<slnum>"))
     let path= a:path
     if path =~ '^\a\{3,}://'
      let path= substitute(path,'^\a\{3,}://[^/]\+/','','')
     endif
     sil! NetrwKeepj .,$d
     call s:NetrwRemoteFtpCmd(path,"delete ".'"'.a:rmfile.'"')
    else
"     call Decho("case ssh: g:netrw_rm_cmd<".g:netrw_rm_cmd.">",'~'.expand("<slnum>"))
     let netrw_rm_cmd= s:MakeSshCmd(g:netrw_rm_cmd)
"     call Decho("netrw_rm_cmd<".netrw_rm_cmd.">",'~'.expand("<slnum>"))
     if !exists("b:netrw_curdir")
      NetrwKeepj call netrw#ErrorMsg(s:ERROR,"for some reason b:netrw_curdir doesn't exist!",53)
      let ok="q"
     else
      let remotedir= substitute(b:netrw_curdir,'^.*//[^/]\+/\(.*\)$','\1','')
"      call Decho("netrw_rm_cmd<".netrw_rm_cmd.">",'~'.expand("<slnum>"))
"      call Decho("remotedir<".remotedir.">",'~'.expand("<slnum>"))
"      call Decho("rmfile<".a:rmfile.">",'~'.expand("<slnum>"))
      if remotedir != ""
       let netrw_rm_cmd= netrw_rm_cmd." ".shellescape(fnameescape(remotedir.a:rmfile))
      else
       let netrw_rm_cmd= netrw_rm_cmd." ".shellescape(fnameescape(a:rmfile))
      endif
"      call Decho("call system(".netrw_rm_cmd.")",'~'.expand("<slnum>"))
      let ret= system(netrw_rm_cmd)
      if ret != 0
       NetrwKeepj call netrw#ErrorMsg(s:WARNING,"cmd<".netrw_rm_cmd."> failed",60)
      endif
"      call Decho("returned=".ret." errcode=".v:shell_error,'~'.expand("<slnum>"))
     endif
    endif
   elseif ok =~ 'q\%[uit]'
"    call Decho("ok==".ok,'~'.expand("<slnum>"))
   endif

  else
   " attempt to remove directory
"    call Decho("attempt to remove directory",'~'.expand("<slnum>"))
   if !all
    call inputsave()
    let ok= input("Confirm deletion of directory<".a:rmfile."> ","[{y(es)},n(o),a(ll),q(uit)] ")
    call inputrestore()
    if ok == ""
     let ok="no"
    endif
    let ok= substitute(ok,'\[{y(es)},n(o),a(ll),q(uit)]\s*','','e')
    if ok =~ 'a\%[ll]'
     let all= 1
    endif
   endif

   if all || ok =~ 'y\%[es]' || ok == ""
    if exists("w:netrw_method") && (w:netrw_method == 2 || w:netrw_method == 3)
     NetrwKeepj call s:NetrwRemoteFtpCmd(a:path,"rmdir ".a:rmfile)
    else
     let rmfile          = substitute(a:path.a:rmfile,'/$','','')
     let netrw_rmdir_cmd = s:MakeSshCmd(netrw#WinPath(g:netrw_rmdir_cmd)).' '.shellescape(netrw#WinPath(rmfile))
"      call Decho("attempt to remove dir: system(".netrw_rmdir_cmd.")",'~'.expand("<slnum>"))
     let ret= system(netrw_rmdir_cmd)
"      call Decho("returned=".ret." errcode=".v:shell_error,'~'.expand("<slnum>"))

     if v:shell_error != 0
"      call Decho("v:shell_error not 0",'~'.expand("<slnum>"))
      let netrw_rmf_cmd= s:MakeSshCmd(netrw#WinPath(g:netrw_rmf_cmd)).' '.shellescape(netrw#WinPath(substitute(rmfile,'[\/]$','','e')))
"      call Decho("2nd attempt to remove dir: system(".netrw_rmf_cmd.")",'~'.expand("<slnum>"))
      let ret= system(netrw_rmf_cmd)
"      call Decho("returned=".ret." errcode=".v:shell_error,'~'.expand("<slnum>"))

      if v:shell_error != 0 && !exists("g:netrw_quiet")
      	NetrwKeepj call netrw#ErrorMsg(s:ERROR,"unable to remove directory<".rmfile."> -- is it empty?",22)
      endif
     endif
    endif

   elseif ok =~ 'q\%[uit]'
"    call Decho("ok==".ok,'~'.expand("<slnum>"))
   endif
  endif

"  call Dret("s:NetrwRemoteRmFile ".ok)
  return ok
endfun

" ---------------------------------------------------------------------
" s:NetrwRemoteRename: rename a remote file or directory {{{2
fun! s:NetrwRemoteRename(usrhost,path) range
"  call Dfunc("NetrwRemoteRename(usrhost<".a:usrhost."> path<".a:path.">)")

  " preparation for removing multiple files/directories
  let svpos      = netrw#SavePosn()
  let ctr        = a:firstline
  let rename_cmd = s:MakeSshCmd(g:netrw_rename_cmd)

  " rename files given by the markfilelist
  if exists("s:netrwmarkfilelist_{bufnr('%')}")
   for oldname in s:netrwmarkfilelist_{bufnr("%")}
"    call Decho("oldname<".oldname.">",'~'.expand("<slnum>"))
    if exists("subfrom")
     let newname= substitute(oldname,subfrom,subto,'')
"     call Decho("subfrom<".subfrom."> subto<".subto."> newname<".newname.">",'~'.expand("<slnum>"))
    else
     call inputsave()
     let newname= input("Moving ".oldname." to : ",oldname)
     call inputrestore()
     if newname =~ '^s/'
      let subfrom = substitute(newname,'^s/\([^/]*\)/.*/$','\1','')
      let subto   = substitute(newname,'^s/[^/]*/\(.*\)/$','\1','')
      let newname = substitute(oldname,subfrom,subto,'')
"      call Decho("subfrom<".subfrom."> subto<".subto."> newname<".newname.">",'~'.expand("<slnum>"))
     endif
    endif

    if exists("w:netrw_method") && (w:netrw_method == 2 || w:netrw_method == 3)
     NetrwKeepj call s:NetrwRemoteFtpCmd(a:path,"rename ".oldname." ".newname)
    else
     let oldname= shellescape(a:path.oldname)
     let newname= shellescape(a:path.newname)
"     call Decho("system(netrw#WinPath(".rename_cmd.") ".oldname.' '.newname.")",'~'.expand("<slnum>"))
     let ret    = system(netrw#WinPath(rename_cmd).' '.oldname.' '.newname)
    endif

   endfor
   call s:NetrwUnMarkFile(1)

  else

  " attempt to rename files/directories
   let keepsol= &l:sol
   setl nosol
   while ctr <= a:lastline
    exe "NetrwKeepj ".ctr

    let oldname= s:NetrwGetWord()
"   call Decho("oldname<".oldname.">",'~'.expand("<slnum>"))

    call inputsave()
    let newname= input("Moving ".oldname." to : ",oldname)
    call inputrestore()

    if exists("w:netrw_method") && (w:netrw_method == 2 || w:netrw_method == 3)
     call s:NetrwRemoteFtpCmd(a:path,"rename ".oldname." ".newname)
    else
     let oldname= shellescape(a:path.oldname)
     let newname= shellescape(a:path.newname)
"     call Decho("system(netrw#WinPath(".rename_cmd.") ".oldname.' '.newname.")",'~'.expand("<slnum>"))
     let ret    = system(netrw#WinPath(rename_cmd).' '.oldname.' '.newname)
    endif

    let ctr= ctr + 1
   endwhile
   let &l:sol= keepsol
  endif

  " refresh the directory
  NetrwKeepj call s:NetrwRefresh(0,s:NetrwBrowseChgDir(0,'./'))
  NetrwKeepj call netrw#RestorePosn(svpos)

"  call Dret("NetrwRemoteRename")
endfun

" ---------------------------------------------------------------------
"  Local Directory Browsing Support:    {{{1
" ==========================================

" ---------------------------------------------------------------------
" netrw#FileUrlRead: handles reading file://* files {{{2
"   Should accept:   file://localhost/etc/fstab
"                    file:///etc/fstab
"                    file:///c:/WINDOWS/clock.avi
"                    file:///c|/WINDOWS/clock.avi
"                    file://localhost/c:/WINDOWS/clock.avi
"                    file://localhost/c|/WINDOWS/clock.avi
"                    file://c:/foo.txt
"                    file:///c:/foo.txt
" and %XX (where X is [0-9a-fA-F] is converted into a character with the given hexadecimal value
fun! netrw#FileUrlRead(fname)
"  call Dfunc("netrw#FileUrlRead(fname<".a:fname.">)")
  let fname = a:fname
  if fname =~ '^file://localhost/'
"   call Decho('converting file://localhost/   -to-  file:///','~'.expand("<slnum>"))
   let fname= substitute(fname,'^file://localhost/','file:///','')
"   call Decho("fname<".fname.">",'~'.expand("<slnum>"))
  endif
  if (has("win32") || has("win95") || has("win64") || has("win16"))
   if fname  =~ '^file:///\=\a[|:]/'
"    call Decho('converting file:///\a|/   -to-  file://\a:/','~'.expand("<slnum>"))
    let fname = substitute(fname,'^file:///\=\(\a\)[|:]/','file://\1:/','')
"    call Decho("fname<".fname.">",'~'.expand("<slnum>"))
   endif
  endif
  let fname2396 = netrw#RFC2396(fname)
  let fname2396e= fnameescape(fname2396)
  let plainfname= substitute(fname2396,'file://\(.*\)','\1',"")
  if (has("win32") || has("win95") || has("win64") || has("win16"))
"   call Decho("windows exception for plainfname",'~'.expand("<slnum>"))
   if plainfname =~ '^/\+\a:'
"    call Decho('removing leading "/"s','~'.expand("<slnum>"))
    let plainfname= substitute(plainfname,'^/\+\(\a:\)','\1','')
   endif
  endif
"  call Decho("fname2396<".fname2396.">",'~'.expand("<slnum>"))
"  call Decho("plainfname<".plainfname.">",'~'.expand("<slnum>"))
  exe "sil doau BufReadPre ".fname2396e
  exe 'NetrwKeepj r '.plainfname
  exe 'sil! bdelete '.plainfname
  exe 'keepalt file! '.plainfname
  NetrwKeepj 1d
"  call Decho("setl nomod",'~'.expand("<slnum>"))
  setl nomod
"  call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"  call Dret("netrw#FileUrlRead")
  exe "sil doau BufReadPost ".fname2396e
endfun

" ---------------------------------------------------------------------
" netrw#LocalBrowseCheck: {{{2
fun! netrw#LocalBrowseCheck(dirname)
  " This function is called by netrwPlugin.vim's s:LocalBrowse() and by s:NetrwRexplore()
  " unfortunate interaction -- split window debugging can't be
  " used here, must use D-echoRemOn or D-echoTabOn -- the BufEnter
  " event triggers another call to LocalBrowseCheck() when attempts
  " to write to the DBG buffer are made.
  " The &ft == "netrw" test was installed because the BufEnter event
  " would hit when re-entering netrw windows, creating unexpected
  " refreshes (and would do so in the middle of NetrwSaveOptions(), too)
"  call Dfunc("netrw#LocalBrowseCheck(dirname<".a:dirname.">")
"  call Decho("isdir<".a:dirname.">=".isdirectory(s:NetrwFile(a:dirname)).((exists("s:treeforceredraw")? " treeforceredraw" : "")).expand("<slnum>"))
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"  call Dredir("ls!","ls!")
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"  call Decho("current buffer#".bufnr("%")."<".bufname("%")."> ft=".&ft,'~'.expand("<slnum>"))

  let ykeep= @@
  if isdirectory(s:NetrwFile(a:dirname))
"   call Decho("is-directory ft<".&ft."> b:netrw_curdir<".(exists("b:netrw_curdir")? b:netrw_curdir : " doesn't exist")."> dirname<".a:dirname.">"." line($)=".line("$")." ft<".&ft."> g:netrw_fastbrowse=".g:netrw_fastbrowse,'~'.expand("<slnum>"))

   if &ft != "netrw" || (exists("b:netrw_curdir") && b:netrw_curdir != a:dirname) || g:netrw_fastbrowse <= 1
"    call Decho("case 1 : ft=".&ft,'~'.expand("<slnum>"))
"    call Decho("s:rexposn_".bufnr("%")."<".bufname("%")."> ".(exists("s:rexposn_".bufnr("%"))? "exists" : "does not exist"),'~'.expand("<slnum>"))
    sil! NetrwKeepj keepalt call s:NetrwBrowse(1,a:dirname)

   elseif &ft == "netrw" && line("$") == 1
"    call Decho("case 2 (ft≡netrw && line($)≡1)",'~'.expand("<slnum>"))
    sil! NetrwKeepj keepalt call s:NetrwBrowse(1,a:dirname)

   elseif exists("s:treeforceredraw")
"    call Decho("case 3 (treeforceredraw)",'~'.expand("<slnum>"))
    unlet s:treeforceredraw
    sil! NetrwKeepj keepalt call s:NetrwBrowse(1,a:dirname)
   endif

"   call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
"   call Dret("netrw#LocalBrowseCheck")
   return
  endif

  " following code wipes out currently unused netrw buffers
  "       IF g:netrw_fastbrowse is zero (ie. slow browsing selected)
  "   AND IF the listing style is not a tree listing
  if exists("g:netrw_fastbrowse") && g:netrw_fastbrowse == 0 && g:netrw_liststyle != s:TREELIST
"   call Decho("wiping out currently unused netrw buffers",'~'.expand("<slnum>"))
   let ibuf    = 1
   let buflast = bufnr("$")
   while ibuf <= buflast
    if bufwinnr(ibuf) == -1 && isdirectory(s:NetrwFile(bufname(ibuf)))
     exe "sil! keepj keepalt ".ibuf."bw!"
    endif
    let ibuf= ibuf + 1
   endwhile
  endif
  let @@= ykeep
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))
  " not a directory, ignore it
"  call Dret("netrw#LocalBrowseCheck : not a directory, ignoring it; dirname<".a:dirname.">")
endfun

" ---------------------------------------------------------------------
" s:LocalBrowseRefresh: this function is called after a user has {{{2
" performed any shell command.  The idea is to cause all local-browsing
" buffers to be refreshed after a user has executed some shell command,
" on the chance that s/he removed/created a file/directory with it.
fun! s:LocalBrowseRefresh()
"  call Dfunc("s:LocalBrowseRefresh() tabpagenr($)=".tabpagenr("$"))
"  call Decho("s:netrw_browselist =".(exists("s:netrw_browselist")?  string(s:netrw_browselist)  : '<n/a>'),'~'.expand("<slnum>"))
"  call Decho("w:netrw_bannercnt  =".(exists("w:netrw_bannercnt")?   string(w:netrw_bannercnt)   : '<n/a>'),'~'.expand("<slnum>"))

  " determine which buffers currently reside in a tab
  if !exists("s:netrw_browselist")
"   call Dret("s:LocalBrowseRefresh : browselist is empty")
   return
  endif
  if !exists("w:netrw_bannercnt")
"   call Dret("s:LocalBrowseRefresh : don't refresh when focus not on netrw window")
   return
  endif
  if exists("s:netrw_events") && s:netrw_events == 1
   " s:LocalFastBrowser gets called (indirectly) from a
   let s:netrw_events= 2
"   call Dret("s:LocalBrowseRefresh : avoid initial double refresh")
   return
  endif
  let itab       = 1
  let buftablist = []
  let ykeep      = @@
  while itab <= tabpagenr("$")
   let buftablist = buftablist + tabpagebuflist()
   let itab       = itab + 1
   tabn
  endwhile
"  call Decho("buftablist".string(buftablist),'~'.expand("<slnum>"))
"  call Decho("s:netrw_browselist<".(exists("s:netrw_browselist")? string(s:netrw_browselist) : "").">",'~'.expand("<slnum>"))
  "  GO through all buffers on netrw_browselist (ie. just local-netrw buffers):
  "   | refresh any netrw window
  "   | wipe out any non-displaying netrw buffer
  let curwin = winnr()
  let ibl    = 0
  for ibuf in s:netrw_browselist
"   call Decho("bufwinnr(".ibuf.") index(buftablist,".ibuf.")=".index(buftablist,ibuf),'~'.expand("<slnum>"))
   if bufwinnr(ibuf) == -1 && index(buftablist,ibuf) == -1
    " wipe out any non-displaying netrw buffer
"    call Decho("wiping  buf#".ibuf,"<".bufname(ibuf).">",'~'.expand("<slnum>"))
    exe "sil! keepj bd ".fnameescape(ibuf)
    call remove(s:netrw_browselist,ibl)
"    call Decho("browselist=".string(s:netrw_browselist),'~'.expand("<slnum>"))
    continue
   elseif index(tabpagebuflist(),ibuf) != -1
    " refresh any netrw buffer
"    call Decho("refresh buf#".ibuf.'-> win#'.bufwinnr(ibuf),'~'.expand("<slnum>"))
    exe bufwinnr(ibuf)."wincmd w"
    if getline(".") =~ 'Quick Help'
     " decrement g:netrw_quickhelp to prevent refresh from changing g:netrw_quickhelp
     " (counteracts s:NetrwBrowseChgDir()'s incrementing)
     let g:netrw_quickhelp= g:netrw_quickhelp - 1
    endif
"    call Decho("#3: quickhelp=".g:netrw_quickhelp,'~'.expand("<slnum>"))
    NetrwKeepj call s:NetrwRefresh(1,s:NetrwBrowseChgDir(1,'./'))
   endif
   let ibl= ibl + 1
"   call Decho("bottom of s:netrw_browselist for loop: ibl=".ibl,'~'.expand("<slnum>"))
  endfor
"  call Decho("restore window: exe ".curwin."wincmd w",'~'.expand("<slnum>"))
  exe curwin."wincmd w"
  let @@= ykeep

"  call Dret("s:LocalBrowseRefresh")
endfun

" ---------------------------------------------------------------------
" s:LocalFastBrowser: handles setting up/taking down fast browsing for the local browser {{{2
"
"     g:netrw_    Directory Is
"     fastbrowse  Local  Remote
"  slow   0         D      D      D=Deleting a buffer implies it will not be re-used (slow)
"  med    1         D      H      H=Hiding a buffer implies it may be re-used        (fast)
"  fast   2         H      H
"
"  Deleting a buffer means that it will be re-loaded when examined, hence "slow".
"  Hiding   a buffer means that it will be re-used   when examined, hence "fast".
"                       (re-using a buffer may not be as accurate)
"
"  s:netrw_events : doesn't exist, s:LocalFastBrowser() will install autocmds whena med or fast browsing
"                   =1: autocmds installed, but ignore next FocusGained event to avoid initial double-refresh of listing.
"                       BufEnter may be first event, then a FocusGained event.  Ignore the first FocusGained event.
"                       If :Explore used: it sets s:netrw_events to 2, so no FocusGained events are ignored.
"                   =2: autocmds installed (doesn't ignore any FocusGained events)
fun! s:LocalFastBrowser()
"  call Dfunc("LocalFastBrowser() g:netrw_fastbrowse=".g:netrw_fastbrowse)
"  call Decho("s:netrw_events        ".(exists("s:netrw_events")? "exists"    : 'n/a'),'~'.expand("<slnum>"))
"  call Decho("autocmd: ShellCmdPost ".(exists("#ShellCmdPost")?  "installed" : "not installed"),'~'.expand("<slnum>"))
"  call Decho("autocmd: FocusGained  ".(exists("#FocusGained")?   "installed" : "not installed"),'~'.expand("<slnum>"))

  " initialize browselist, a list of buffer numbers that the local browser has used
  if !exists("s:netrw_browselist")
"   call Decho("initialize s:netrw_browselist",'~'.expand("<slnum>"))
   let s:netrw_browselist= []
  endif

  " append current buffer to fastbrowse list
  if empty(s:netrw_browselist) || bufnr("%") > s:netrw_browselist[-1]
"   call Decho("appendng current buffer to browselist",'~'.expand("<slnum>"))
   call add(s:netrw_browselist,bufnr("%"))
"   call Decho("browselist=".string(s:netrw_browselist),'~'.expand("<slnum>"))
  endif

  " enable autocmd events to handle refreshing/removing local browser buffers
  "    If local browse buffer is currently showing: refresh it
  "    If local browse buffer is currently hidden : wipe it
  "    g:netrw_fastbrowse=0 : slow   speed, never re-use directory listing
  "                      =1 : medium speed, re-use directory listing for remote only
  "                      =2 : fast   speed, always re-use directory listing when possible
  if g:netrw_fastbrowse <= 1 && !exists("#ShellCmdPost") && !exists("s:netrw_events")
   let s:netrw_events= 1
   augroup AuNetrwEvent
    au!
    if (has("win32") || has("win95") || has("win64") || has("win16"))
"     call Decho("installing autocmd: ShellCmdPost",'~'.expand("<slnum>"))
     au ShellCmdPost			*	call s:LocalBrowseRefresh()
    else
"     call Decho("installing autocmds: ShellCmdPost FocusGained",'~'.expand("<slnum>"))
     au ShellCmdPost,FocusGained	*	call s:LocalBrowseRefresh()
    endif
   augroup END

  " user must have changed fastbrowse to its fast setting, so remove
  " the associated autocmd events
  elseif g:netrw_fastbrowse > 1 && exists("#ShellCmdPost") && exists("s:netrw_events")
"   call Decho("remove AuNetrwEvent autcmd group",'~'.expand("<slnum>"))
   unlet s:netrw_events
   augroup AuNetrwEvent
    au!
   augroup END
   augroup! AuNetrwEvent
  endif

"  call Dret("LocalFastBrowser : browselist<".string(s:netrw_browselist).">")
endfun

" ---------------------------------------------------------------------
"  s:LocalListing: does the job of "ls" for local directories {{{2
fun! s:LocalListing()
"  call Dfunc("s:LocalListing()")
"  call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"  call Decho("modified=".&modified." modifiable=".&modifiable." readonly=".&readonly,'~'.expand("<slnum>"))
"  call Decho("tab#".tabpagenr()." win#".winnr()." buf#".bufnr("%")."<".bufname("%")."> line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol(),'~'.expand("<slnum>"))

"  if exists("b:netrw_curdir") |call Decho('b:netrw_curdir<'.b:netrw_curdir.">")  |else|call Decho("b:netrw_curdir doesn't exist",'~'.expand("<slnum>")) |endif
"  if exists("g:netrw_sort_by")|call Decho('g:netrw_sort_by<'.g:netrw_sort_by.">")|else|call Decho("g:netrw_sort_by doesn't exist",'~'.expand("<slnum>"))|endif
"  call Decho("g:netrw_banner=".g:netrw_banner.": banner ".(g:netrw_banner? "enabled" : "suppressed").": (line($)=".line("$")." byte2line(1)=".byte2line(1)." bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))

  " get the list of files contained in the current directory
  let dirname    = b:netrw_curdir
  let dirnamelen = strlen(b:netrw_curdir)
  if v:version == 704 && has("patch656")
"   call Decho("using glob with patch656",'~'.expand("<slnum>"))
   let filelist   = glob(s:ComposePath(dirname,"*"),0,1,1)
   let filelist   = filelist + glob(s:ComposePath(dirname,".*"),0,1,1)
  else
"   call Decho("using glob without patch656",'~'.expand("<slnum>"))
   let filelist   = glob(s:ComposePath(dirname,"*"),0,1)
   let filelist   = filelist + glob(s:ComposePath(dirname,".*"),0,1)
  endif
"  call Decho("filelist=".string(filelist),'~'.expand("<slnum>"))

  if g:netrw_cygwin == 0 && (has("win32") || has("win95") || has("win64") || has("win16"))
"   call Decho("filelist=".string(filelist),'~'.expand("<slnum>"))
  elseif index(filelist,'..') == -1 && b:netrw_curdir !~ '/'
    " include ../ in the glob() entry if its missing
"   call Decho("forcibly including on \"..\"",'~'.expand("<slnum>"))
   let filelist= filelist+[s:ComposePath(b:netrw_curdir,"../")]
"   call Decho("filelist=".string(filelist),'~'.expand("<slnum>"))
  endif

"  call Decho("before while: dirname<".dirname.">",'~'.expand("<slnum>"))
"  call Decho("before while: dirnamelen<".dirnamelen.">",'~'.expand("<slnum>"))
"  call Decho("before while: filelist=".string(filelist),'~'.expand("<slnum>"))

  if get(g:, 'netrw_dynamic_maxfilenamelen', 0)
   let filelistcopy           = map(deepcopy(filelist),'fnamemodify(v:val, ":t")')
   let g:netrw_maxfilenamelen = max(map(filelistcopy,'len(v:val)')) + 1
"   call Decho("dynamic_maxfilenamelen: filenames             =".string(filelistcopy),'~'.expand("<slnum>"))
"   call Decho("dynamic_maxfilenamelen: g:netrw_maxfilenamelen=".g:netrw_maxfilenamelen,'~'.expand("<slnum>"))
  endif
"  call Decho("g:netrw_banner=".g:netrw_banner.": banner ".(g:netrw_banner? "enabled" : "suppressed").": (line($)=".line("$")." byte2line(1)=".byte2line(1)." bannercnt=".w:netrw_bannercnt.")",'~'.expand("<slnum>"))

  for filename in filelist
"   call Decho(" ",'~'.expand("<slnum>"))
"   call Decho("for filename in filelist: filename<".filename.">",'~'.expand("<slnum>"))

   if getftype(filename) == "link"
    " indicate a symbolic link
"    call Decho("indicate <".filename."> is a symbolic link with trailing @",'~'.expand("<slnum>"))
    let pfile= filename."@"

   elseif getftype(filename) == "socket"
    " indicate a socket
"    call Decho("indicate <".filename."> is a socket with trailing =",'~'.expand("<slnum>"))
    let pfile= filename."="

   elseif getftype(filename) == "fifo"
    " indicate a fifo
"    call Decho("indicate <".filename."> is a fifo with trailing |",'~'.expand("<slnum>"))
    let pfile= filename."|"

   elseif isdirectory(s:NetrwFile(filename))
    " indicate a directory
"    call Decho("indicate <".filename."> is a directory with trailing /",'~'.expand("<slnum>"))
    let pfile= filename."/"

   elseif exists("b:netrw_curdir") && b:netrw_curdir !~ '^.*://' && !isdirectory(s:NetrwFile(filename))
    if (has("win32") || has("win95") || has("win64") || has("win16"))
     if filename =~ '\.[eE][xX][eE]$' || filename =~ '\.[cC][oO][mM]$' || filename =~ '\.[bB][aA][tT]$'
      " indicate an executable
"      call Decho("indicate <".filename."> is executable with trailing *",'~'.expand("<slnum>"))
      let pfile= filename."*"
     else
      " normal file
      let pfile= filename
     endif
    elseif executable(filename)
     " indicate an executable
"     call Decho("indicate <".filename."> is executable with trailing *",'~'.expand("<slnum>"))
     let pfile= filename."*"
    else
     " normal file
     let pfile= filename
    endif

   else
    " normal file
    let pfile= filename
   endif
"   call Decho("pfile<".pfile."> (after *@/ appending)",'~'.expand("<slnum>"))

   if pfile =~ '//$'
    let pfile= substitute(pfile,'//$','/','e')
"    call Decho("change // to /: pfile<".pfile.">",'~'.expand("<slnum>"))
   endif
   let pfile= strpart(pfile,dirnamelen)
   let pfile= substitute(pfile,'^[/\\]','','e')
"   call Decho("filename<".filename.">",'~'.expand("<slnum>"))
"   call Decho("pfile   <".pfile.">",'~'.expand("<slnum>"))

   if w:netrw_liststyle == s:LONGLIST
    let sz   = getfsize(filename)
    let fsz  = strpart("               ",1,15-strlen(sz)).sz
    let pfile= pfile."\t".fsz." ".strftime(g:netrw_timefmt,getftime(filename))
"    call Decho("sz=".sz." fsz=".fsz,'~'.expand("<slnum>"))
   endif

   if     g:netrw_sort_by =~ "^t"
    " sort by time (handles time up to 1 quintillion seconds, US)
"    call Decho("getftime(".filename.")=".getftime(filename),'~'.expand("<slnum>"))
    let t  = getftime(filename)
    let ft = strpart("000000000000000000",1,18-strlen(t)).t
"    call Decho("exe NetrwKeepj put ='".ft.'/'.filename."'",'~'.expand("<slnum>"))
    let ftpfile= ft.'/'.pfile
    sil! NetrwKeepj put=ftpfile

   elseif g:netrw_sort_by =~ "^s"
    " sort by size (handles file sizes up to 1 quintillion bytes, US)
"    call Decho("getfsize(".filename.")=".getfsize(filename),'~'.expand("<slnum>"))
    let sz   = getfsize(filename)
    let fsz  = strpart("000000000000000000",1,18-strlen(sz)).sz
"    call Decho("exe NetrwKeepj put ='".fsz.'/'.filename."'",'~'.expand("<slnum>"))
    let fszpfile= fsz.'/'.pfile
    sil! NetrwKeepj put =fszpfile

   else
    " sort by name
"    call Decho("exe NetrwKeepj put ='".pfile."'",'~'.expand("<slnum>"))
    sil! NetrwKeepj put=pfile
   endif
  endfor

  " cleanup any windows mess at end-of-line
  sil! NetrwKeepj g/^$/d
  sil! NetrwKeepj %s/\r$//e
  call histdel("/",-1)
"  call Decho("exe setl ts=".(g:netrw_maxfilenamelen+1),'~'.expand("<slnum>"))
  exe "setl ts=".(g:netrw_maxfilenamelen+1)

"  call Dret("s:LocalListing")
endfun

" ---------------------------------------------------------------------
" s:NetrwLocalExecute: uses system() to execute command under cursor ("X" command support) {{{2
fun! s:NetrwLocalExecute(cmd)
"  call Dfunc("s:NetrwLocalExecute(cmd<".a:cmd.">)")
  let ykeep= @@
  " sanity check
  if !executable(a:cmd)
   call netrw#ErrorMsg(s:ERROR,"the file<".a:cmd."> is not executable!",89)
   let @@= ykeep
"   call Dret("s:NetrwLocalExecute")
   return
  endif

  let optargs= input(":!".a:cmd,"","file")
"  call Decho("optargs<".optargs.">",'~'.expand("<slnum>"))
  let result= system(a:cmd.optargs)
"  call Decho("result,'~'.expand("<slnum>"))

  " strip any ansi escape sequences off
  let result = substitute(result,"\e\\[[0-9;]*m","","g")

  " show user the result(s)
  echomsg result
  let @@= ykeep

"  call Dret("s:NetrwLocalExecute")
endfun

" ---------------------------------------------------------------------
" s:NetrwLocalRename: rename a local file or directory {{{2
fun! s:NetrwLocalRename(path) range
"  call Dfunc("NetrwLocalRename(path<".a:path.">)")

  " preparation for removing multiple files/directories
  let ykeep    = @@
  let ctr      = a:firstline
  let svpos    = netrw#SavePosn()

  " rename files given by the markfilelist
  if exists("s:netrwmarkfilelist_{bufnr('%')}")
   for oldname in s:netrwmarkfilelist_{bufnr("%")}
"    call Decho("oldname<".oldname.">",'~'.expand("<slnum>"))
    if exists("subfrom")
     let newname= substitute(oldname,subfrom,subto,'')
"     call Decho("subfrom<".subfrom."> subto<".subto."> newname<".newname.">",'~'.expand("<slnum>"))
    else
     call inputsave()
     let newname= input("Moving ".oldname." to : ",oldname,"file")
     call inputrestore()
     if newname =~ ''
      " two ctrl-x's : ignore all of string preceding the ctrl-x's
      let newname = substitute(newname,'^.*','','')
     elseif newname =~ ''
      " one ctrl-x : ignore portion of string preceding ctrl-x but after last /
      let newname = substitute(newname,'[^/]*','','')
     endif
     if newname =~ '^s/'
      let subfrom = substitute(newname,'^s/\([^/]*\)/.*/$','\1','')
      let subto   = substitute(newname,'^s/[^/]*/\(.*\)/$','\1','')
"      call Decho("subfrom<".subfrom."> subto<".subto."> newname<".newname.">",'~'.expand("<slnum>"))
      let newname = substitute(oldname,subfrom,subto,'')
     endif
    endif
    call rename(oldname,newname)
   endfor
   call s:NetrwUnmarkList(bufnr("%"),b:netrw_curdir)

  else

   " attempt to rename files/directories
   while ctr <= a:lastline
    exe "NetrwKeepj ".ctr

    " sanity checks
    if line(".") < w:netrw_bannercnt
     let ctr= ctr + 1
     continue
    endif
    let curword= s:NetrwGetWord()
    if curword == "./" || curword == "../"
     let ctr= ctr + 1
     continue
    endif

    NetrwKeepj norm! 0
    let oldname= s:ComposePath(a:path,curword)
"   call Decho("oldname<".oldname.">",'~'.expand("<slnum>"))

    call inputsave()
    let newname= input("Moving ".oldname." to : ",substitute(oldname,'/*$','','e'))
    call inputrestore()

    call rename(oldname,newname)
"   call Decho("renaming <".oldname."> to <".newname.">",'~'.expand("<slnum>"))

    let ctr= ctr + 1
   endwhile
  endif

  " refresh the directory
"  call Decho("refresh the directory listing",'~'.expand("<slnum>"))
  NetrwKeepj call s:NetrwRefresh(1,s:NetrwBrowseChgDir(1,'./'))
  NetrwKeepj call netrw#RestorePosn(svpos)
  let @@= ykeep

"  call Dret("NetrwLocalRename")
endfun

" ---------------------------------------------------------------------
" s:NetrwLocalRm: {{{2
fun! s:NetrwLocalRm(path) range
"  call Dfunc("s:NetrwLocalRm(path<".a:path.">)")
"  call Decho("firstline=".a:firstline." lastline=".a:lastline,'~'.expand("<slnum>"))

  " preparation for removing multiple files/directories
  let ykeep = @@
  let ret   = 0
  let all   = 0
  let svpos = netrw#SavePosn()

  if exists("s:netrwmarkfilelist_{bufnr('%')}")
   " remove all marked files
"   call Decho("remove all marked files",'~'.expand("<slnum>"))
   for fname in s:netrwmarkfilelist_{bufnr("%")}
    let ok= s:NetrwLocalRmFile(a:path,fname,all)
    if ok =~ 'q\%[uit]' || ok == "no"
     break
    elseif ok =~ 'a\%[ll]'
     let all= 1
    endif
   endfor
   call s:NetrwUnMarkFile(1)

  else
  " remove (multiple) files and directories
"   call Decho("remove files in range [".a:firstline.",".a:lastline."]",'~'.expand("<slnum>"))

   let keepsol= &l:sol
   setl nosol
   let ctr = a:firstline
   while ctr <= a:lastline
    exe "NetrwKeepj ".ctr

    " sanity checks
    if line(".") < w:netrw_bannercnt
     let ctr= ctr + 1
     continue
    endif
    let curword= s:NetrwGetWord()
    if curword == "./" || curword == "../"
     let ctr= ctr + 1
     continue
    endif
    let ok= s:NetrwLocalRmFile(a:path,curword,all)
    if ok =~ 'q\%[uit]' || ok == "no"
     break
    elseif ok =~ 'a\%[ll]'
     let all= 1
    endif
    let ctr= ctr + 1
   endwhile
   let &l:sol= keepsol
  endif

  " refresh the directory
"  call Decho("bufname<".bufname("%").">",'~'.expand("<slnum>"))
  if bufname("%") != "NetrwMessage"
   NetrwKeepj call s:NetrwRefresh(1,s:NetrwBrowseChgDir(1,'./'))
   NetrwKeepj call netrw#RestorePosn(svpos)
  endif
  let @@= ykeep

"  call Dret("s:NetrwLocalRm")
endfun

" ---------------------------------------------------------------------
" s:NetrwLocalRmFile: remove file fname given the path {{{2
"                     Give confirmation prompt unless all==1
fun! s:NetrwLocalRmFile(path,fname,all)
"  call Dfunc("s:NetrwLocalRmFile(path<".a:path."> fname<".a:fname."> all=".a:all)

  let all= a:all
  let ok = ""
  NetrwKeepj norm! 0
  let rmfile= s:NetrwFile(s:ComposePath(a:path,a:fname))
"  call Decho("rmfile<".rmfile.">",'~'.expand("<slnum>"))

  if rmfile !~ '^"' && (rmfile =~ '@$' || rmfile !~ '[\/]$')
   " attempt to remove file
"   call Decho("attempt to remove file<".rmfile.">",'~'.expand("<slnum>"))
   if !all
    echohl Statement
    call inputsave()
    let ok= input("Confirm deletion of file<".rmfile."> ","[{y(es)},n(o),a(ll),q(uit)] ")
    call inputrestore()
    echohl NONE
    if ok == ""
     let ok="no"
    endif
"    call Decho("response: ok<".ok.">",'~'.expand("<slnum>"))
    let ok= substitute(ok,'\[{y(es)},n(o),a(ll),q(uit)]\s*','','e')
"    call Decho("response: ok<".ok."> (after sub)",'~'.expand("<slnum>"))
    if ok =~ 'a\%[ll]'
     let all= 1
    endif
   endif

   if all || ok =~ 'y\%[es]' || ok == ""
    let ret= s:NetrwDelete(rmfile)
"    call Decho("errcode=".v:shell_error." ret=".ret,'~'.expand("<slnum>"))
   endif

  else
   " attempt to remove directory
   if !all
    echohl Statement
    call inputsave()
    let ok= input("Confirm deletion of directory<".rmfile."> ","[{y(es)},n(o),a(ll),q(uit)] ")
    call inputrestore()
    let ok= substitute(ok,'\[{y(es)},n(o),a(ll),q(uit)]\s*','','e')
    if ok == ""
     let ok="no"
    endif
    if ok =~ 'a\%[ll]'
     let all= 1
    endif
   endif
   let rmfile= substitute(rmfile,'[\/]$','','e')

   if all || ok =~ 'y\%[es]' || ok == ""
"    call Decho("1st attempt: system(netrw#WinPath(".g:netrw_localrmdir.') '.shellescape(rmfile).')','~'.expand("<slnum>"))
    call system(netrw#WinPath(g:netrw_localrmdir).' '.shellescape(rmfile))
"    call Decho("v:shell_error=".v:shell_error,'~'.expand("<slnum>"))

    if v:shell_error != 0
"     call Decho("2nd attempt to remove directory<".rmfile.">",'~'.expand("<slnum>"))
     let errcode= s:NetrwDelete(rmfile)
"     call Decho("errcode=".errcode,'~'.expand("<slnum>"))

     if errcode != 0
      if has("unix")
"       call Decho("3rd attempt to remove directory<".rmfile.">",'~'.expand("<slnum>"))
       call system("rm ".shellescape(rmfile))
       if v:shell_error != 0 && !exists("g:netrw_quiet")
        call netrw#ErrorMsg(s:ERROR,"unable to remove directory<".rmfile."> -- is it empty?",34)
	let ok="no"
       endif
      elseif !exists("g:netrw_quiet")
       call netrw#ErrorMsg(s:ERROR,"unable to remove directory<".rmfile."> -- is it empty?",35)
       let ok="no"
      endif
     endif
    endif
   endif
  endif

"  call Dret("s:NetrwLocalRmFile ".ok)
  return ok
endfun

" ---------------------------------------------------------------------
" Support Functions: {{{1

" ---------------------------------------------------------------------
" netrw#Access: intended to provide access to variable values for netrw's test suite {{{2
"   0: marked file list of current buffer
"   1: marked file target
fun! netrw#Access(ilist)
  if     a:ilist == 0
   if exists("s:netrwmarkfilelist_".bufnr('%'))
    return s:netrwmarkfilelist_{bufnr('%')}
   else
    return "no-list-buf#".bufnr('%')
   endif
  elseif a:ilist == 1
   return s:netrwmftgt
endfun

" ---------------------------------------------------------------------
" netrw#Call: allows user-specified mappings to call internal netrw functions {{{2
fun! netrw#Call(funcname,...)
"  call Dfunc("netrw#Call(funcname<".a:funcname.">,".string(a:000).")")
  if a:0 > 0
   exe "call s:".a:funcname."(".string(a:000).")"
  else
   exe "call s:".a:funcname."()"
  endif
"  call Dret("netrw#Call")
endfun

" ------------------------------------------------------------------------
" netrw#RestorePosn: restores the cursor and file position as saved by netrw#SavePosn() {{{2
fun! netrw#RestorePosn(...)
"  call Dfunc("netrw#RestorePosn() a:0=".a:0." winnr=".(exists("w:netrw_winnr")? w:netrw_winnr : -1)." line=".(exists("w:netrw_line")? w:netrw_line : -1)." col=".(exists("w:netrw_col")? w:netrw_col : -1)." hline=".(exists("w:netrw_hline")? w:netrw_hline : -1))
  let eikeep= &ei
  setl ei=all
  if expand("%") == "NetrwMessage"
   if exists("s:winBeforeErr")
    exe s:winBeforeErr."wincmd w"
   endif
  endif

  if a:0 > 0
   exe "keepj ".a:1
  endif
"  "call Decho("a:1             = ".((a:0 > 0)?              a:1       : 'n/a'),'~'.expand("<slnum>"))
"  "call Decho("liststyle       = ".(exists("liststyle")?    liststyle : 'n/a'). " w:netrw_liststyle=".(exists("w:netrw_liststyle")? w:netrw_liststyle : 'n/a'),'~'.expand("<slnum>"))
  if exists("liststyle") && exists("w:netrw_liststyle") && liststyle != w:netrw_liststyle
   let usesrch= 1
  else
   let usesrch= 0
  endif

"  "call Decho("winh            = ".(exists("w:netrw_winh")?    w:netrw_winh    : -1),'~'.expand("<slnum>"))
"  "call Decho("winw            = ".(exists("w:netrw_winw")?    w:netrw_winw    : -1),'~'.expand("<slnum>"))
"  "call Decho("cur    winheight=".winheight(0)." winwidth=".winwidth(0),'~'.expand("<slnum>"))
"  "call Decho("w:netrw_winfile = ".(exists("w:netrw_winfile")? w:netrw_winfile : 'n/a'),'~'.expand("<slnum>"))

  " restore window
  if exists("w:netrw_winnr")
"   "call Decho("restore window: exe sil! ".w:netrw_winnr."wincmd w",'~'.expand("<slnum>"))
   exe "sil! ".w:netrw_winnr."wincmd w"
  endif
"  if v:shell_error == 0
   " as suggested by Bram M: redraw on no error
   " allows protocol error messages to remain visible
"   redraw!
"  endif

  " restore top-of-screen line
  if exists("w:netrw_hline")
"   "call Decho("restore topofscreen: exe keepj norm! ".w:netrw_hline."G0z",'~'.expand("<slnum>"))
   exe "keepj norm! ".w:netrw_hline."G0z\<CR>"
  endif

  " restore position
  " when the window's height x width has changed, the line,col is no longer useful
  if w:netrw_winh == winheight(0) && w:netrw_winw == winwidth(0) && exists("w:netrw_line") && exists("w:netrw_col") && !usesrch
"   "call Decho("using posn: exe keepj norm! ".w:netrw_line."G0".w:netrw_col."|",'~'.expand("<slnum>"))
   exe "keepj norm! ".w:netrw_line."G0".w:netrw_col."\<bar>"

  elseif exists("w:netrw_winfile")
   if !search('\<'.escape(w:netrw_winfile,g:netrw_fname_escape),'cw')
    if exists("w:netrw_bannercnt")
"     "call Decho("using bannercnt: win#".winnr()." ".winheight(0)."x".winwidth(0)." w:netrw_winfile<".w:netrw_winfile.">",'~'.expand("<slnum>"))
     exe "keepj ".w:netrw_bannercnt
     norm! 0
    else
     " go to upper left corner
"     "call Decho("goto ulc: win#".winnr()." ".winheight(0)."x".winwidth(0)." w:netrw_winfile<".w:netrw_winfile.">",'~'.expand("<slnum>"))
     keepj 1
     norm! 0
    endif
   else
"    "call Decho("used search: w:netrw_winfile<".w:netrw_winfile.">",'~'.expand("<slnum>"))
   endif

  else
"   "call Decho("goto ulc: win#".winnr()." ".winheight(0)."x".winwidth(0),'~'.expand("<slnum>"))
   keepj 1
   norm! 0
  endif

  let &ei= eikeep
"  call Dret("netrw#RestorePosn : line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol())
endfun

" ---------------------------------------------------------------------
" netrw#Expose: allows UserMaps and pchk to look at otherwise script-local variables {{{2
"               I expect this function to be used in
"                 :PChkAssert netrw#Expose("netrwmarkfilelist")
"               for example.
fun! netrw#Expose(varname)
"   call Dfunc("netrw#Expose(varname<".a:varname.">)")
  exe "let retval= s:".a:varname
  if exists("g:netrw_pchk")
   if type(retval) == 3
    let retval = copy(retval)
    let i      = 0
    while i < len(retval)
     let retval[i]= substitute(retval[i],expand("$HOME"),'~','')
     let i        = i + 1
    endwhile
   endif
"    call Dret("netrw#Expose ".string(retval))
   return string(retval)
  endif

"  call Dret("netrw#Expose ".string(retval))
  return retval
endfun

" ---------------------------------------------------------------------
" netrw#Modify: allows UserMaps to set (modify) script-local variables {{{2
fun! netrw#Modify(varname,newvalue)
"  call Dfunc("netrw#Modify(varname<".a:varname.">,newvalue<".string(a:newvalue).">)")
  exe "let s:".a:varname."= ".string(a:newvalue)
"  call Dret("netrw#Modify")
endfun

" ---------------------------------------------------------------------
"  netrw#RFC2396: converts %xx into characters {{{2
fun! netrw#RFC2396(fname)
"  call Dfunc("netrw#RFC2396(fname<".a:fname.">)")
  let fname = escape(substitute(a:fname,'%\(\x\x\)','\=nr2char("0x".submatch(1))','ge')," \t")
"  call Dret("netrw#RFC2396 ".fname)
  return fname
endfun

" ---------------------------------------------------------------------
" netrw#SavePosn: saves position of cursor on screen {{{2
fun! netrw#SavePosn()
"  call Dfunc("netrw#SavePosn() win#".winnr()." line#".line(".")." col#".col(".")." winline#".winline()." wincol#".wincol())
  " Save current line and column
  let w:netrw_winnr= winnr()
  let w:netrw_line = line(".")
  let w:netrw_col  = virtcol(".")
"  "call Decho("currently, win#".w:netrw_winnr." line#".w:netrw_line." col#".w:netrw_col,'~'.expand("<slnum>"))

  " save filename under cursor
"  "call Decho("line#".line(".")." w:netrw_bannercnt=".(exists("w:netrw_bannercnt")? w:netrw_bannercnt : 'n/a'),'~'.expand("<slnum>"))
  if exists("w:netrw_bannercnt") && line(".") >= w:netrw_bannercnt && &ft == "netrw"
   let winfile = "|let w:netrw_winfile=\"".fnameescape(s:NetrwGetWord())."\""
  else
   let winfile= ""
  endif
"  "call Decho("winfile<".winfile.">",'~'.expand("<slnum>"))
  if exists("w:netrw_liststyle")
   let liststyle = "|let liststyle=".w:netrw_liststyle
  else
   let liststyle= ""
  endif
"  "call Decho("liststyle=".liststyle,'~'.expand("<slnum>"))

  " Save top-of-screen line
  keepj norm! H0
  let w:netrw_hline= line(".")

  " save up alternate position information
  " use this when window height x width has changed
  let w:netrw_winh = winheight(0)
  let w:netrw_winw = winwidth(0)

  " set up string holding position parameters
  let ret          = "let w:netrw_winnr=".w:netrw_winnr."|let w:netrw_line=".w:netrw_line."|let w:netrw_col=".w:netrw_col."|let w:netrw_hline=".w:netrw_hline."|let w:netrw_winh=".w:netrw_winh."|let w:netrw_winw=".w:netrw_winw.liststyle.winfile

  keepj call netrw#RestorePosn()
"  call Dret("netrw#SavePosn : win#=".(exists("w:netrw_winnr")? w:netrw_winnr : "n/a")." line=".(exists("w:netrw_line")? w:netrw_line : "n/a")." col=".(exists("w:netrw_col")? w:netrw_col : "n/a")." hline=".(exists("w:netrw_hline")? w:netrw_hline : "n/a"))
  return ret
endfun

" ---------------------------------------------------------------------
" netrw#UserMaps: supports user-specified maps {{{2
"                 see :help function()
"
"                 g:Netrw_UserMaps is a List with members such as:
"                       [[keymap sequence, function reference],...]
"
"                 The referenced function may return a string,
"                 	refresh : refresh the display
"                 	-other- : this string will be executed
"                 or it may return a List of strings.
"
"                 Each keymap-sequence will be set up with a nnoremap
"                 to invoke netrw#UserMaps(islocal).
"                 Related functions:
"                   netrw#Expose(varname)          -- see s:varname variables
"                   netrw#Modify(varname,newvalue) -- modify value of s:varname variable
"                   netrw#Call(funcname,...)       -- call internal netrw function with optional arguments
fun! netrw#UserMaps(islocal)
"  call Dfunc("netrw#UserMaps(islocal=".a:islocal.")")
"  call Decho("g:Netrw_UserMaps ".(exists("g:Netrw_UserMaps")? "exists" : "does NOT exist"),'~'.expand("<slnum>"))

   " set up usermaplist
   if exists("g:Netrw_UserMaps") && type(g:Netrw_UserMaps) == 3
"    call Decho("g:Netrw_UserMaps has type 3<List>",'~'.expand("<slnum>"))
    for umap in g:Netrw_UserMaps
"     call Decho("type(umap[0]<".string(umap[0]).">)=".type(umap[0])." (should be 1=string)",'~'.expand("<slnum>"))
"     call Decho("type(umap[1])=".type(umap[1])." (should be 1=string)",'~'.expand("<slnum>"))
     " if umap[0] is a string and umap[1] is a string holding a function name
     if type(umap[0]) == 1 && type(umap[1]) == 1
"      call Decho("nno <buffer> <silent> ".umap[0]." :call s:UserMaps(".a:islocal.",".string(umap[1]).")<cr>",'~'.expand("<slnum>"))
      exe "nno <buffer> <silent> ".umap[0]." :call <SID>UserMaps(".a:islocal.",'".umap[1]."')<cr>"
      else
       call netrw#ErrorMsg(s:WARNING,"ignoring usermap <".string(umap[0])."> -- not a [string,funcref] entry",99)
     endif
    endfor
   endif
"  call Dret("netrw#UserMaps")
endfun

" ---------------------------------------------------------------------
" netrw#WinPath: tries to insure that the path is windows-acceptable, whether cygwin is used or not {{{2
fun! netrw#WinPath(path)
"  call Dfunc("netrw#WinPath(path<".a:path.">)")
  if (!g:netrw_cygwin || &shell !~ '\%(\<bash\>\|\<zsh\>\)\%(\.exe\)\=$') && (has("win32") || has("win95") || has("win64") || has("win16"))
   " remove cygdrive prefix, if present
   let path = substitute(a:path,g:netrw_cygdrive.'/\(.\)','\1:','')
   " remove trailing slash (Win95)
   let path = substitute(path, '\(\\\|/\)$', '', 'g')
   " remove escaped spaces
   let path = substitute(path, '\ ', ' ', 'g')
   " convert slashes to backslashes
   let path = substitute(path, '/', '\', 'g')
  else
   let path= a:path
  endif
"  call Dret("netrw#WinPath <".path.">")
  return path
endfun

" ---------------------------------------------------------------------
"  s:ComposePath: Appends a new part to a path taking different systems into consideration {{{2
fun! s:ComposePath(base,subdir)
"  call Dfunc("s:ComposePath(base<".a:base."> subdir<".a:subdir.">)")

  if has("amiga")
"   call Decho("amiga",'~'.expand("<slnum>"))
   let ec = a:base[s:Strlen(a:base)-1]
   if ec != '/' && ec != ':'
    let ret = a:base . "/" . a:subdir
   else
    let ret = a:base . a:subdir
   endif

  elseif a:subdir =~ '^\a:[/\\][^/\\]' && (has("win32") || has("win95") || has("win64") || has("win16"))
"   call Decho("windows",'~'.expand("<slnum>"))
   let ret= a:subdir

  elseif a:base =~ '^\a:[/\\][^/\\]' && (has("win32") || has("win95") || has("win64") || has("win16"))
"   call Decho("windows",'~'.expand("<slnum>"))
   if a:base =~ '[/\\]$'
    let ret= a:base.a:subdir
   else
    let ret= a:base.'/'.a:subdir
   endif

  elseif a:base =~ '^\a\{3,}://'
"   call Decho("remote linux/macos",'~'.expand("<slnum>"))
   let urlbase = substitute(a:base,'^\(\a\+://.\{-}/\)\(.*\)$','\1','')
   let curpath = substitute(a:base,'^\(\a\+://.\{-}/\)\(.*\)$','\2','')
   if a:subdir == '../'
    if curpath =~ '[^/]/[^/]\+/$'
     let curpath= substitute(curpath,'[^/]\+/$','','')
    else
     let curpath=""
    endif
    let ret= urlbase.curpath
   else
    let ret= urlbase.curpath.a:subdir
   endif
"   call Decho("urlbase<".urlbase.">",'~'.expand("<slnum>"))
"   call Decho("curpath<".curpath.">",'~'.expand("<slnum>"))
"   call Decho("ret<".ret.">",'~'.expand("<slnum>"))

  else
"   call Decho("local linux/macos",'~'.expand("<slnum>"))
   let ret = substitute(a:base."/".a:subdir,"//","/","g")
   if a:base =~ '^//'
    " keeping initial '//' for the benefit of network share listing support
    let ret= '/'.ret
   endif
   let ret= simplify(ret)
  endif

"  call Dret("s:ComposePath ".ret)
  return ret
endfun

" ---------------------------------------------------------------------
" s:DeleteBookmark: deletes a file/directory from Netrw's bookmark system {{{2
"   Related Functions: s:MakeBookmark() s:NetrwBookHistHandler() s:NetrwBookmark()
fun! s:DeleteBookmark(fname)
"  call Dfunc("s:DeleteBookmark(fname<".a:fname.">)")
  call s:MergeBookmarks()

  if exists("g:netrw_bookmarklist")
   let indx= index(g:netrw_bookmarklist,a:fname)
   if indx == -1
    let indx= 0
    while indx < len(g:netrw_bookmarklist)
     if g:netrw_bookmarklist[indx] =~ a:fname
      call remove(g:netrw_bookmarklist,indx)
      let indx= indx - 1
     endif
     let indx= indx + 1
    endwhile
   else
    " remove exact match
    call remove(g:netrw_bookmarklist,indx)
   endif
  endif

"  call Dret("s:DeleteBookmark")
endfun

" ---------------------------------------------------------------------
" s:FileReadable: o/s independent filereadable {{{2
fun! s:FileReadable(fname)
"  call Dfunc("s:FileReadable(fname<".a:fname.">)")

  if g:netrw_cygwin
   let ret= filereadable(s:NetrwFile(substitute(a:fname,g:netrw_cygdrive.'/\(.\)','\1:/','')))
  else
   let ret= filereadable(s:NetrwFile(a:fname))
  endif

"  call Dret("s:FileReadable ".ret)
  return ret
endfun

" ---------------------------------------------------------------------
"  s:GetTempfile: gets a tempname that'll work for various o/s's {{{2
"                 Places correct suffix on end of temporary filename,
"                 using the suffix provided with fname
fun! s:GetTempfile(fname)
"  call Dfunc("s:GetTempfile(fname<".a:fname.">)")

  if !exists("b:netrw_tmpfile")
   " get a brand new temporary filename
   let tmpfile= tempname()
"   call Decho("tmpfile<".tmpfile."> : from tempname()",'~'.expand("<slnum>"))

   let tmpfile= substitute(tmpfile,'\','/','ge')
"   call Decho("tmpfile<".tmpfile."> : chgd any \\ -> /",'~'.expand("<slnum>"))

   " sanity check -- does the temporary file's directory exist?
   if !isdirectory(s:NetrwFile(substitute(tmpfile,'[^/]\+$','','e')))
"    call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
    NetrwKeepj call netrw#ErrorMsg(s:ERROR,"your <".substitute(tmpfile,'[^/]\+$','','e')."> directory is missing!",2)
"    call Dret("s:GetTempfile getcwd<".getcwd().">")
    return ""
   endif

   " let netrw#NetSource() know about the tmpfile
   let s:netrw_tmpfile= tmpfile " used by netrw#NetSource() and netrw#BrowseX()
"   call Decho("tmpfile<".tmpfile."> s:netrw_tmpfile<".s:netrw_tmpfile.">",'~'.expand("<slnum>"))

   " o/s dependencies
   if g:netrw_cygwin != 0
    let tmpfile = substitute(tmpfile,'^\(\a\):',g:netrw_cygdrive.'/\1','e')
   elseif has("win32") || has("win95") || has("win64") || has("win16")
    if !exists("+shellslash") || !&ssl
     let tmpfile = substitute(tmpfile,'/','\','g')
    endif
   else
    let tmpfile = tmpfile
   endif
   let b:netrw_tmpfile= tmpfile
"   call Decho("o/s dependent fixed tempname<".tmpfile.">",'~'.expand("<slnum>"))
  else
   " re-use temporary filename
   let tmpfile= b:netrw_tmpfile
"   call Decho("tmpfile<".tmpfile."> re-using",'~'.expand("<slnum>"))
  endif

  " use fname's suffix for the temporary file
  if a:fname != ""
   if a:fname =~ '\.[^./]\+$'
"    call Decho("using fname<".a:fname.">'s suffix",'~'.expand("<slnum>"))
    if a:fname =~ '\.tar\.gz$' || a:fname =~ '\.tar\.bz2$' || a:fname =~ '\.tar\.xz$'
     let suffix = ".tar".substitute(a:fname,'^.*\(\.[^./]\+\)$','\1','e')
    elseif a:fname =~ '.txz$'
     let suffix = ".txz".substitute(a:fname,'^.*\(\.[^./]\+\)$','\1','e')
    else
     let suffix = substitute(a:fname,'^.*\(\.[^./]\+\)$','\1','e')
    endif
"    call Decho("suffix<".suffix.">",'~'.expand("<slnum>"))
    let tmpfile= substitute(tmpfile,'\.tmp$','','e')
"    call Decho("chgd tmpfile<".tmpfile."> (removed any .tmp suffix)",'~'.expand("<slnum>"))
    let tmpfile .= suffix
"    call Decho("chgd tmpfile<".tmpfile."> (added ".suffix." suffix) netrw_fname<".b:netrw_fname.">",'~'.expand("<slnum>"))
    let s:netrw_tmpfile= tmpfile " supports netrw#NetSource()
   endif
  endif

"  call Decho("ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
"  call Dret("s:GetTempfile <".tmpfile.">")
  return tmpfile
endfun

" ---------------------------------------------------------------------
" s:MakeSshCmd: transforms input command using USEPORT HOSTNAME into {{{2
"               a correct command for use with a system() call
fun! s:MakeSshCmd(sshcmd)
"  call Dfunc("s:MakeSshCmd(sshcmd<".a:sshcmd.">) user<".s:user."> machine<".s:machine.">")
  if s:user == ""
   let sshcmd = substitute(a:sshcmd,'\<HOSTNAME\>',s:machine,'')
  else
   let sshcmd = substitute(a:sshcmd,'\<HOSTNAME\>',s:user."@".s:machine,'')
  endif
  if exists("g:netrw_port") && g:netrw_port != ""
   let sshcmd= substitute(sshcmd,"USEPORT",g:netrw_sshport.' '.g:netrw_port,'')
  elseif exists("s:port") && s:port != ""
   let sshcmd= substitute(sshcmd,"USEPORT",g:netrw_sshport.' '.s:port,'')
  else
   let sshcmd= substitute(sshcmd,"USEPORT ",'','')
  endif
"  call Dret("s:MakeSshCmd <".sshcmd.">")
  return sshcmd
endfun

" ---------------------------------------------------------------------
" s:MakeBookmark: enters a bookmark into Netrw's bookmark system   {{{2
fun! s:MakeBookmark(fname)
"  call Dfunc("s:MakeBookmark(fname<".a:fname.">)")

  if !exists("g:netrw_bookmarklist")
   let g:netrw_bookmarklist= []
  endif

  if index(g:netrw_bookmarklist,a:fname) == -1
   " curdir not currently in g:netrw_bookmarklist, so include it
   if isdirectory(s:NetrwFile(a:fname)) && a:fname !~ '/$'
    call add(g:netrw_bookmarklist,a:fname.'/')
   elseif a:fname !~ '/'
    call add(g:netrw_bookmarklist,getcwd()."/".a:fname)
   else
    call add(g:netrw_bookmarklist,a:fname)
   endif
   call sort(g:netrw_bookmarklist)
  endif

"  call Dret("s:MakeBookmark")
endfun

" ---------------------------------------------------------------------
" s:MergeBookmarks: merge current bookmarks with saved bookmarks {{{2
fun! s:MergeBookmarks()
"  call Dfunc("s:MergeBookmarks() : merge current bookmarks into .netrwbook")
  " get bookmarks from .netrwbook file
  let savefile= s:NetrwHome()."/.netrwbook"
  if filereadable(s:NetrwFile(savefile))
"   call Decho("merge bookmarks (active and file)",'~'.expand("<slnum>"))
   NetrwKeepj call s:NetrwBookHistSave()
"   call Decho("bookmark delete savefile<".savefile.">",'~'.expand("<slnum>"))
   NetrwKeepj call delete(savefile)
  endif
"  call Dret("s:MergeBookmarks")
endfun

" ---------------------------------------------------------------------
" s:NetrwBMShow: {{{2
fun! s:NetrwBMShow()
"  call Dfunc("s:NetrwBMShow()")
  redir => bmshowraw
   menu
  redir END
  let bmshowlist = split(bmshowraw,'\n')
  if bmshowlist != []
   let bmshowfuncs= filter(bmshowlist,'v:val =~ "<SNR>\\d\\+_BMShow()"')
   if bmshowfuncs != []
    let bmshowfunc = substitute(bmshowfuncs[0],'^.*:\(call.*BMShow()\).*$','\1','')
    if bmshowfunc =~ '^call.*BMShow()'
     exe "sil! NetrwKeepj ".bmshowfunc
    endif
   endif
  endif
"  call Dret("s:NetrwBMShow : bmshowfunc<".(exists("bmshowfunc")? bmshowfunc : 'n/a').">")
endfun

" ---------------------------------------------------------------------
" s:NetrwCursor: responsible for setting cursorline/cursorcolumn based upon g:netrw_cursor {{{2
fun! s:NetrwCursor()
  if !exists("w:netrw_liststyle")
   let w:netrw_liststyle= g:netrw_liststyle
  endif
"  call Dfunc("s:NetrwCursor() ft<".&ft."> liststyle=".w:netrw_liststyle." g:netrw_cursor=".g:netrw_cursor." s:netrw_usercuc=".s:netrw_usercuc." s:netrw_usercul=".s:netrw_usercul)

  if &ft != "netrw"
   " if the current window isn't a netrw directory listing window, then use user cursorline/column
   " settings.  Affects when netrw is used to read/write a file using scp/ftp/etc.
"   call Decho("case ft!=netrw: use user cul,cuc",'~'.expand("<slnum>"))
   let &l:cursorline   = s:netrw_usercul
   let &l:cursorcolumn = s:netrw_usercuc

  elseif g:netrw_cursor == 4
   " all styles: cursorline, cursorcolumn
"   call Decho("case g:netrw_cursor==4: setl cul cuc",'~'.expand("<slnum>"))
   setl cursorline
   setl cursorcolumn

  elseif g:netrw_cursor == 3
   " thin-long-tree: cursorline, user's cursorcolumn
   " wide          : cursorline, cursorcolumn
   if w:netrw_liststyle == s:WIDELIST
"    call Decho("case g:netrw_cursor==3 and wide: setl cul cuc",'~'.expand("<slnum>"))
    setl cursorline
    setl cursorcolumn
   else
"    call Decho("case g:netrw_cursor==3 and not wide: setl cul (use user's cuc)",'~'.expand("<slnum>"))
    setl cursorline
    let &l:cursorcolumn   = s:netrw_usercuc
   endif

  elseif g:netrw_cursor == 2
   " thin-long-tree: cursorline, user's cursorcolumn
   " wide          : cursorline, user's cursorcolumn
"   call Decho("case g:netrw_cursor==2: setl cuc (use user's cul)",'~'.expand("<slnum>"))
   let &l:cursorcolumn = s:netrw_usercuc
   setl cursorline

  elseif g:netrw_cursor == 1
   " thin-long-tree: user's cursorline, user's cursorcolumn
   " wide          : cursorline,        user's cursorcolumn
   let &l:cursorcolumn = s:netrw_usercuc
   if w:netrw_liststyle == s:WIDELIST
"    call Decho("case g:netrw_cursor==2 and wide: setl cul (use user's cuc)",'~'.expand("<slnum>"))
    setl cursorline
   else
"    call Decho("case g:netrw_cursor==2 and not wide: (use user's cul,cuc)",'~'.expand("<slnum>"))
    let &l:cursorline   = s:netrw_usercul
   endif

  else
   " all styles: user's cursorline, user's cursorcolumn
"   call Decho("default: (use user's cul,cuc)",'~'.expand("<slnum>"))
   let &l:cursorline   = s:netrw_usercul
   let &l:cursorcolumn = s:netrw_usercuc
  endif

"  call Dret("s:NetrwCursor : l:cursorline=".&l:cursorline." l:cursorcolumn=".&l:cursorcolumn)
endfun

" ---------------------------------------------------------------------
" s:RestoreCursorline: restores cursorline/cursorcolumn to original user settings {{{2
fun! s:RestoreCursorline()
"  call Dfunc("s:RestoreCursorline() currently, cul=".&l:cursorline." cuc=".&l:cursorcolumn." win#".winnr()." buf#".bufnr("%"))
  if exists("s:netrw_usercul")
   let &l:cursorline   = s:netrw_usercul
  endif
  if exists("s:netrw_usercuc")
   let &l:cursorcolumn = s:netrw_usercuc
  endif
"  call Dret("s:RestoreCursorline : restored cul=".&l:cursorline." cuc=".&l:cursorcolumn)
endfun

" ---------------------------------------------------------------------
" s:NetrwDelete: Deletes a file. {{{2
"           Uses Steve Hall's idea to insure that Windows paths stay
"           acceptable.  No effect on Unix paths.
"  Examples of use:  let result= s:NetrwDelete(path)
fun! s:NetrwDelete(path)
"  call Dfunc("s:NetrwDelete(path<".a:path.">)")

  let path = netrw#WinPath(a:path)
  if !g:netrw_cygwin && (has("win32") || has("win95") || has("win64") || has("win16"))
   if exists("+shellslash")
    let sskeep= &shellslash
    setl noshellslash
    let result      = delete(path)
    let &shellslash = sskeep
   else
"    call Decho("exe let result= ".a:cmd."('".path."')",'~'.expand("<slnum>"))
    let result= delete(path)
   endif
  else
"   call Decho("let result= delete(".path.")",'~'.expand("<slnum>"))
   let result= delete(path)
  endif
  if result < 0
   NetrwKeepj call netrw#ErrorMsg(s:WARNING,"delete(".path.") failed!",71)
  endif

"  call Dret("s:NetrwDelete ".result)
  return result
endfun

" ---------------------------------------------------------------------
" s:NetrwEnew: opens a new buffer, passes netrw buffer variables through {{{2
fun! s:NetrwEnew(...)
"  call Dfunc("s:NetrwEnew() a:0=".a:0." bufnr($)=".bufnr("$"))
"  call Decho("curdir<".((a:0>0)? a:1 : "")."> buf#".bufnr("%")."<".bufname("%").">",'~'.expand("<slnum>"))

  " grab a function-local-variable copy of buffer variables
"  call Decho("make function-local copy of netrw variables",'~'.expand("<slnum>"))
  if exists("b:netrw_bannercnt")      |let netrw_bannercnt       = b:netrw_bannercnt      |endif
  if exists("b:netrw_browser_active") |let netrw_browser_active  = b:netrw_browser_active |endif
  if exists("b:netrw_cpf")            |let netrw_cpf             = b:netrw_cpf            |endif
  if exists("b:netrw_curdir")         |let netrw_curdir          = b:netrw_curdir         |endif
  if exists("b:netrw_explore_bufnr")  |let netrw_explore_bufnr   = b:netrw_explore_bufnr  |endif
  if exists("b:netrw_explore_indx")   |let netrw_explore_indx    = b:netrw_explore_indx   |endif
  if exists("b:netrw_explore_line")   |let netrw_explore_line    = b:netrw_explore_line   |endif
  if exists("b:netrw_explore_list")   |let netrw_explore_list    = b:netrw_explore_list   |endif
  if exists("b:netrw_explore_listlen")|let netrw_explore_listlen = b:netrw_explore_listlen|endif
  if exists("b:netrw_explore_mtchcnt")|let netrw_explore_mtchcnt = b:netrw_explore_mtchcnt|endif
  if exists("b:netrw_fname")          |let netrw_fname           = b:netrw_fname          |endif
  if exists("b:netrw_lastfile")       |let netrw_lastfile        = b:netrw_lastfile       |endif
  if exists("b:netrw_liststyle")      |let netrw_liststyle       = b:netrw_liststyle      |endif
  if exists("b:netrw_method")         |let netrw_method          = b:netrw_method         |endif
  if exists("b:netrw_option")         |let netrw_option          = b:netrw_option         |endif
  if exists("b:netrw_prvdir")         |let netrw_prvdir          = b:netrw_prvdir         |endif

  NetrwKeepj call s:NetrwOptionRestore("w:")
"  call Decho("generate a buffer with NetrwKeepj keepalt enew!",'~'.expand("<slnum>"))
  let netrw_keepdiff= &l:diff
  noswapfile NetrwKeepj keepalt enew!
  let &l:diff= netrw_keepdiff
"  call Decho("bufnr($)=".bufnr("$")." winnr($)=".winnr("$"),'~'.expand("<slnum>"))
  NetrwKeepj call s:NetrwOptionSave("w:")

  " copy function-local-variables to buffer variable equivalents
"  call Decho("copy function-local variables back to buffer netrw variables",'~'.expand("<slnum>"))
  if exists("netrw_bannercnt")      |let b:netrw_bannercnt       = netrw_bannercnt      |endif
  if exists("netrw_browser_active") |let b:netrw_browser_active  = netrw_browser_active |endif
  if exists("netrw_cpf")            |let b:netrw_cpf             = netrw_cpf            |endif
  if exists("netrw_curdir")         |let b:netrw_curdir          = netrw_curdir         |endif
  if exists("netrw_explore_bufnr")  |let b:netrw_explore_bufnr   = netrw_explore_bufnr  |endif
  if exists("netrw_explore_indx")   |let b:netrw_explore_indx    = netrw_explore_indx   |endif
  if exists("netrw_explore_line")   |let b:netrw_explore_line    = netrw_explore_line   |endif
  if exists("netrw_explore_list")   |let b:netrw_explore_list    = netrw_explore_list   |endif
  if exists("netrw_explore_listlen")|let b:netrw_explore_listlen = netrw_explore_listlen|endif
  if exists("netrw_explore_mtchcnt")|let b:netrw_explore_mtchcnt = netrw_explore_mtchcnt|endif
  if exists("netrw_fname")          |let b:netrw_fname           = netrw_fname          |endif
  if exists("netrw_lastfile")       |let b:netrw_lastfile        = netrw_lastfile       |endif
  if exists("netrw_liststyle")      |let b:netrw_liststyle       = netrw_liststyle      |endif
  if exists("netrw_method")         |let b:netrw_method          = netrw_method         |endif
  if exists("netrw_option")         |let b:netrw_option          = netrw_option         |endif
  if exists("netrw_prvdir")         |let b:netrw_prvdir          = netrw_prvdir         |endif

  if a:0 > 0
   let b:netrw_curdir= a:1
   if b:netrw_curdir =~ '/$'
    if exists("w:netrw_liststyle") && w:netrw_liststyle == s:TREELIST
     file NetrwTreeListing
     setl bt=nowrite noswf bh=hide
     nno <silent> <buffer> [	:sil call <SID>TreeListMove('[')<cr>
     nno <silent> <buffer> ]	:sil call <SID>TreeListMove(']')<cr>
    else
     exe "sil! keepalt file ".fnameescape(b:netrw_curdir)
    endif
   endif
  endif

"  call Dret("s:NetrwEnew : buf#".bufnr("%")."<".bufname("%")."> expand(%)<".expand("%")."> expand(#)<".expand("#")."> bh=".&bh." win#".winnr()." winnr($)#".winnr("$"))
endfun

" ---------------------------------------------------------------------
" s:NetrwExe: executes a string using "!" {{{2
fun! s:NetrwExe(cmd)
"  call Dfunc("s:NetrwExe(a:cmd)")
  if has("win32") && &shell !~? 'cmd' && !g:netrw_cygwin
    let savedShell=[&shell,&shellcmdflag,&shellxquote,&shellxescape,&shellquote,&shellpipe,&shellredir,&shellslash]
    set shell& shellcmdflag& shellxquote& shellxescape&
    set shellquote& shellpipe& shellredir& shellslash&
    exe a:cmd
    let [&shell,&shellcmdflag,&shellxquote,&shellxescape,&shellquote,&shellpipe,&shellredir,&shellslash] = savedShell
  else
   exe a:cmd
  endif
"  call Dret("s:NetrwExe")
endfun

" ---------------------------------------------------------------------
" s:NetrwInsureWinVars: insure that a netrw buffer has its w: variables in spite of a wincmd v or s {{{2
fun! s:NetrwInsureWinVars()
"  call Dfunc("s:NetrwInsureWinVars() win#".winnr())
  if !exists("w:netrw_liststyle")
   let curbuf = bufnr("%")
   let curwin = winnr()
   let iwin   = 1
   while iwin <= winnr("$")
    exe iwin."wincmd w"
    if winnr() != curwin && bufnr("%") == curbuf && exists("w:netrw_liststyle")
     " looks like ctrl-w_s or ctrl-w_v was used to split a netrw buffer
     let winvars= w:
     break
    endif
    let iwin= iwin + 1
   endwhile
   exe "keepalt ".curwin."wincmd w"
   if exists("winvars")
"    call Decho("copying w#".iwin." window variables to w#".curwin,'~'.expand("<slnum>"))
    for k in keys(winvars)
     let w:{k}= winvars[k]
    endfor
   endif
  endif
"  call Dret("s:NetrwInsureWinVars win#".winnr())
endfun

" ---------------------------------------------------------------------
" s:NetrwLcd: handles changing the (local) directory {{{2
fun! s:NetrwLcd(newdir)
"  call Dfunc("s:NetrwLcd(newdir<".a:newdir.">)")

  try
   exe 'NetrwKeepj sil lcd '.fnameescape(a:newdir)
  catch /^Vim\%((\a\+)\)\=:E344/
     " Vim's lcd fails with E344 when attempting to go above the 'root' of a Windows share.
     " Therefore, detect if a Windows share is present, and if E344 occurs, just settle at
     " 'root' (ie. '\').  The share name may start with either backslashes ('\\Foo') or
     " forward slashes ('//Foo'), depending on whether backslashes have been converted to
     " forward slashes by earlier code; so check for both.
     if (has("win32") || has("win95") || has("win64") || has("win16")) && !g:netrw_cygwin
       if a:newdir =~ '^\\\\\w\+' || a:newdir =~ '^//\w\+'
         let dirname = '\'
	 exe 'NetrwKeepj sil lcd '.fnameescape(dirname)
       endif
     endif
  catch /^Vim\%((\a\+)\)\=:E472/
   call netrw#ErrorMsg(s:ERROR,"unable to change directory to <".a:newdir."> (permissions?)",61)
   if exists("w:netrw_prvdir")
    let a:newdir= w:netrw_prvdir
   else
    call s:NetrwOptionRestore("w:")
"    call Decho("setl noma nomod nowrap",'~'.expand("<slnum>"))
    exe "setl ".g:netrw_bufsettings
"    call Decho(" ro=".&l:ro." ma=".&l:ma." mod=".&l:mod." wrap=".&l:wrap." (filename<".expand("%")."> win#".winnr()." ft<".&ft.">)",'~'.expand("<slnum>"))
    let a:newdir= dirname
"    call Dret("s:NetrwBrowse : reusing buffer#".(exists("bufnum")? bufnum : 'N/A')."<".dirname."> getcwd<".getcwd().">")
    return
   endif
  endtry

"  call Dret("s:NetrwLcd")
endfun

" ------------------------------------------------------------------------
" s:NetrwSaveWordPosn: used to keep cursor on same word after refresh, {{{2
" changed sorting, etc.  Also see s:NetrwRestoreWordPosn().
fun! s:NetrwSaveWordPosn()
"  call Dfunc("NetrwSaveWordPosn()")
  let s:netrw_saveword= '^'.fnameescape(getline('.')).'$'
"  call Dret("NetrwSaveWordPosn : saveword<".s:netrw_saveword.">")
endfun

" ---------------------------------------------------------------------
" s:NetrwRestoreWordPosn: used to keep cursor on same word after refresh, {{{2
"  changed sorting, etc.  Also see s:NetrwSaveWordPosn().
fun! s:NetrwRestoreWordPosn()
"  call Dfunc("NetrwRestoreWordPosn()")
  sil! call search(s:netrw_saveword,'w')
"  call Dret("NetrwRestoreWordPosn")
endfun

" ---------------------------------------------------------------------
" s:RestoreBufVars: {{{2
fun! s:RestoreBufVars()
"  call Dfunc("s:RestoreBufVars()")

  if exists("s:netrw_curdir")        |let b:netrw_curdir         = s:netrw_curdir        |endif
  if exists("s:netrw_lastfile")      |let b:netrw_lastfile       = s:netrw_lastfile      |endif
  if exists("s:netrw_method")        |let b:netrw_method         = s:netrw_method        |endif
  if exists("s:netrw_fname")         |let b:netrw_fname          = s:netrw_fname         |endif
  if exists("s:netrw_machine")       |let b:netrw_machine        = s:netrw_machine       |endif
  if exists("s:netrw_browser_active")|let b:netrw_browser_active = s:netrw_browser_active|endif

"  call Dret("s:RestoreBufVars")
endfun

" ---------------------------------------------------------------------
" s:RemotePathAnalysis: {{{2
fun! s:RemotePathAnalysis(dirname)
"  call Dfunc("s:RemotePathAnalysis(a:dirname<".a:dirname.">)")

  "                method   ://    user  @      machine      :port            /path
  let dirpat  = '^\(\w\{-}\)://\(\(\w\+\)@\)\=\([^/:#]\+\)\%([:#]\(\d\+\)\)\=/\(.*\)$'
  let s:method  = substitute(a:dirname,dirpat,'\1','')
  let s:user    = substitute(a:dirname,dirpat,'\3','')
  let s:machine = substitute(a:dirname,dirpat,'\4','')
  let s:port    = substitute(a:dirname,dirpat,'\5','')
  let s:path    = substitute(a:dirname,dirpat,'\6','')
  let s:fname   = substitute(s:path,'^.*/\ze.','','')
  if s:machine =~ '@'
   let dirpat    = '^\(.*\)@\(.\{-}\)$'
   let s:user    = s:user.'@'.substitute(s:machine,dirpat,'\1','')
   let s:machine = substitute(s:machine,dirpat,'\2','')
  endif

"  call Decho("set up s:method <".s:method .">",'~'.expand("<slnum>"))
"  call Decho("set up s:user   <".s:user   .">",'~'.expand("<slnum>"))
"  call Decho("set up s:machine<".s:machine.">",'~'.expand("<slnum>"))
"  call Decho("set up s:port   <".s:port.">",'~'.expand("<slnum>"))
"  call Decho("set up s:path   <".s:path   .">",'~'.expand("<slnum>"))
"  call Decho("set up s:fname  <".s:fname  .">",'~'.expand("<slnum>"))

"  call Dret("s:RemotePathAnalysis")
endfun

" ---------------------------------------------------------------------
" s:RemoteSystem: runs a command on a remote host using ssh {{{2
"                 Returns status
" Runs system() on
"    [cd REMOTEDIRPATH;] a:cmd
" Note that it doesn't do shellescape(a:cmd)!
fun! s:RemoteSystem(cmd)
"  call Dfunc("s:RemoteSystem(cmd<".a:cmd.">)")
  if !executable(g:netrw_ssh_cmd)
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"g:netrw_ssh_cmd<".g:netrw_ssh_cmd."> is not executable!",52)
  elseif !exists("b:netrw_curdir")
   NetrwKeepj call netrw#ErrorMsg(s:ERROR,"for some reason b:netrw_curdir doesn't exist!",53)
  else
   let cmd      = s:MakeSshCmd(g:netrw_ssh_cmd." USEPORT HOSTNAME")
   let remotedir= substitute(b:netrw_curdir,'^.*//[^/]\+/\(.*\)$','\1','')
   if remotedir != ""
    let cmd= cmd.' cd '.shellescape(remotedir).";"
   else
    let cmd= cmd.' '
   endif
   let cmd= cmd.a:cmd
"   call Decho("call system(".cmd.")",'~'.expand("<slnum>"))
   let ret= system(cmd)
  endif
"  call Dret("s:RemoteSystem ".ret)
  return ret
endfun

" ---------------------------------------------------------------------
" s:RestoreWinVars: (used by Explore() and NetrwSplit()) {{{2
fun! s:RestoreWinVars()
"  call Dfunc("s:RestoreWinVars()")
  if exists("s:bannercnt")      |let w:netrw_bannercnt       = s:bannercnt      |unlet s:bannercnt      |endif
  if exists("s:col")            |let w:netrw_col             = s:col            |unlet s:col            |endif
  if exists("s:curdir")         |let w:netrw_curdir          = s:curdir         |unlet s:curdir         |endif
  if exists("s:explore_bufnr")  |let w:netrw_explore_bufnr   = s:explore_bufnr  |unlet s:explore_bufnr  |endif
  if exists("s:explore_indx")   |let w:netrw_explore_indx    = s:explore_indx   |unlet s:explore_indx   |endif
  if exists("s:explore_line")   |let w:netrw_explore_line    = s:explore_line   |unlet s:explore_line   |endif
  if exists("s:explore_listlen")|let w:netrw_explore_listlen = s:explore_listlen|unlet s:explore_listlen|endif
  if exists("s:explore_list")   |let w:netrw_explore_list    = s:explore_list   |unlet s:explore_list   |endif
  if exists("s:explore_mtchcnt")|let w:netrw_explore_mtchcnt = s:explore_mtchcnt|unlet s:explore_mtchcnt|endif
  if exists("s:fpl")            |let w:netrw_fpl             = s:fpl            |unlet s:fpl            |endif
  if exists("s:hline")          |let w:netrw_hline           = s:hline          |unlet s:hline          |endif
  if exists("s:line")           |let w:netrw_line            = s:line           |unlet s:line           |endif
  if exists("s:liststyle")      |let w:netrw_liststyle       = s:liststyle      |unlet s:liststyle      |endif
  if exists("s:method")         |let w:netrw_method          = s:method         |unlet s:method         |endif
  if exists("s:prvdir")         |let w:netrw_prvdir          = s:prvdir         |unlet s:prvdir         |endif
  if exists("s:treedict")       |let w:netrw_treedict        = s:treedict       |unlet s:treedict       |endif
  if exists("s:treetop")        |let w:netrw_treetop         = s:treetop        |unlet s:treetop        |endif
  if exists("s:winnr")          |let w:netrw_winnr           = s:winnr          |unlet s:winnr          |endif
"  call Dret("s:RestoreWinVars")
endfun

" ---------------------------------------------------------------------
" s:Rexplore: implements returning from a buffer to a netrw directory {{{2
"
"             s:SetRexDir() sets up <2-leftmouse> maps (if g:netrw_retmap
"             is true) and a command, :Rexplore, which call this function.
"
"             s:nbcd_curpos_{bufnr('%')} is set up by s:NetrwBrowseChgDir()
"
"             s:rexposn_BUFNR used to save/restore cursor position
fun! s:NetrwRexplore(islocal,dirname)
  if exists("s:netrwdrag")
   return
  endif
"  call Dfunc("s:NetrwRexplore() w:netrw_rexlocal=".w:netrw_rexlocal." w:netrw_rexdir<".w:netrw_rexdir.">")
"  call Decho("currently in bufname<".bufname("%").">",'~'.expand("<slnum>"))
"  call Decho("ft=".&ft." win#".winnr()." w:netrw_rexfile<".(exists("w:netrw_rexfile")? w:netrw_rexfile : 'n/a').">",'~'.expand("<slnum>"))

  if &ft == "netrw" && exists("w:netrw_rexfile") && w:netrw_rexfile != ""
   " a :Rex while in a netrw buffer means: edit the file in w:netrw_rexfile
"   call Decho("in netrw buffer, will edit file<".w:netrw_rexfile.">",'~'.expand("<slnum>"))
   exe "NetrwKeepj e ".w:netrw_rexfile
   unlet w:netrw_rexfile
"   call Dret("s:NetrwRexplore returning from netrw to buf#".bufnr("%")."<".bufname("%").">  (ft=".&ft.")")
   return
"  else " Decho
"   call Decho("treating as not-netrw-buffer: ft=".&ft.((&ft == "netrw")? " == netrw" : "!= netrw"),'~'.expand("<slnum>"))
"   call Decho("treating as not-netrw-buffer: w:netrw_rexfile<".((exists("w:netrw_rexfile"))? w:netrw_rexfile : 'n/a').">",'~'.expand("<slnum>"))
  endif

  " ---------------------------
  " :Rex issued while in a file
  " ---------------------------

  " record current file so :Rex can return to it from netrw
  let w:netrw_rexfile= expand("%")
"  call Decho("set w:netrw_rexfile<".w:netrw_rexfile.">  (win#".winnr().")",'~'.expand("<slnum>"))

  if !exists("w:netrw_rexlocal")
"   call Dret("s:NetrwRexplore w:netrw_rexlocal doesn't exist (".&ft.")")
   return
  endif
"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
  if w:netrw_rexlocal
   NetrwKeepj call netrw#LocalBrowseCheck(w:netrw_rexdir)
  else
   NetrwKeepj call s:NetrwBrowse(0,w:netrw_rexdir)
  endif
  if exists("s:initbeval")
   setl beval
  endif
  if exists("s:rexposn_".bufnr("%"))
"   call Decho("restore posn, then unlet s:rexposn_".bufnr('%')."<".bufname("%").">",'~'.expand("<slnum>"))
   " restore position in directory listing
   NetrwKeepj call netrw#RestorePosn(s:rexposn_{bufnr('%')})
   if exists("s:rexposn_".bufnr('%'))
    unlet s:rexposn_{bufnr('%')}
   endif
  else
"   call Decho("s:rexposn_".bufnr('%')."<".bufname("%")."> doesn't exist",'~'.expand("<slnum>"))
  endif

  if exists("s:explore_match")
   exe "2match netrwMarkFile /".s:explore_match."/"
  endif

"  call Decho("settings buf#".bufnr("%")."<".bufname("%").">: ".((&l:ma == 0)? "no" : "")."ma ".((&l:mod == 0)? "no" : "")."mod ".((&l:bl == 0)? "no" : "")."bl ".((&l:ro == 0)? "no" : "")."ro fo=".&l:fo,'~'.expand("<slnum>"))
"  call Dret("s:NetrwRexplore : ft=".&ft)
endfun

" ---------------------------------------------------------------------
" s:SaveBufVars: save selected b: variables to s: variables {{{2
"                use s:RestoreBufVars() to restore b: variables from s: variables
fun! s:SaveBufVars()
"  call Dfunc("s:SaveBufVars() buf#".bufnr("%"))

  if exists("b:netrw_curdir")        |let s:netrw_curdir         = b:netrw_curdir        |endif
  if exists("b:netrw_lastfile")      |let s:netrw_lastfile       = b:netrw_lastfile      |endif
  if exists("b:netrw_method")        |let s:netrw_method         = b:netrw_method        |endif
  if exists("b:netrw_fname")         |let s:netrw_fname          = b:netrw_fname         |endif
  if exists("b:netrw_machine")       |let s:netrw_machine        = b:netrw_machine       |endif
  if exists("b:netrw_browser_active")|let s:netrw_browser_active = b:netrw_browser_active|endif

"  call Dret("s:SaveBufVars")
endfun

" ---------------------------------------------------------------------
" s:SaveWinVars: (used by Explore() and NetrwSplit()) {{{2
fun! s:SaveWinVars()
"  call Dfunc("s:SaveWinVars() win#".winnr())
  if exists("w:netrw_bannercnt")      |let s:bannercnt       = w:netrw_bannercnt      |endif
  if exists("w:netrw_col")            |let s:col             = w:netrw_col            |endif
  if exists("w:netrw_curdir")         |let s:curdir          = w:netrw_curdir         |endif
  if exists("w:netrw_explore_bufnr")  |let s:explore_bufnr   = w:netrw_explore_bufnr  |endif
  if exists("w:netrw_explore_indx")   |let s:explore_indx    = w:netrw_explore_indx   |endif
  if exists("w:netrw_explore_line")   |let s:explore_line    = w:netrw_explore_line   |endif
  if exists("w:netrw_explore_listlen")|let s:explore_listlen = w:netrw_explore_listlen|endif
  if exists("w:netrw_explore_list")   |let s:explore_list    = w:netrw_explore_list   |endif
  if exists("w:netrw_explore_mtchcnt")|let s:explore_mtchcnt = w:netrw_explore_mtchcnt|endif
  if exists("w:netrw_fpl")            |let s:fpl             = w:netrw_fpl            |endif
  if exists("w:netrw_hline")          |let s:hline           = w:netrw_hline          |endif
  if exists("w:netrw_line")           |let s:line            = w:netrw_line           |endif
  if exists("w:netrw_liststyle")      |let s:liststyle       = w:netrw_liststyle      |endif
  if exists("w:netrw_method")         |let s:method          = w:netrw_method         |endif
  if exists("w:netrw_prvdir")         |let s:prvdir          = w:netrw_prvdir         |endif
  if exists("w:netrw_treedict")       |let s:treedict        = w:netrw_treedict       |endif
  if exists("w:netrw_treetop")        |let s:treetop         = w:netrw_treetop        |endif
  if exists("w:netrw_winnr")          |let s:winnr           = w:netrw_winnr          |endif
"  call Dret("s:SaveWinVars")
endfun

" ---------------------------------------------------------------------
" s:SetBufWinVars: (used by NetrwBrowse() and LocalBrowseCheck()) {{{2
"   To allow separate windows to have their own activities, such as
"   Explore **/pattern, several variables have been made window-oriented.
"   However, when the user splits a browser window (ex: ctrl-w s), these
"   variables are not inherited by the new window.  SetBufWinVars() and
"   UseBufWinVars() get around that.
fun! s:SetBufWinVars()
"  call Dfunc("s:SetBufWinVars() win#".winnr())
  if exists("w:netrw_liststyle")      |let b:netrw_liststyle      = w:netrw_liststyle      |endif
  if exists("w:netrw_bannercnt")      |let b:netrw_bannercnt      = w:netrw_bannercnt      |endif
  if exists("w:netrw_method")         |let b:netrw_method         = w:netrw_method         |endif
  if exists("w:netrw_prvdir")         |let b:netrw_prvdir         = w:netrw_prvdir         |endif
  if exists("w:netrw_explore_indx")   |let b:netrw_explore_indx   = w:netrw_explore_indx   |endif
  if exists("w:netrw_explore_listlen")|let b:netrw_explore_listlen= w:netrw_explore_listlen|endif
  if exists("w:netrw_explore_mtchcnt")|let b:netrw_explore_mtchcnt= w:netrw_explore_mtchcnt|endif
  if exists("w:netrw_explore_bufnr")  |let b:netrw_explore_bufnr  = w:netrw_explore_bufnr  |endif
  if exists("w:netrw_explore_line")   |let b:netrw_explore_line   = w:netrw_explore_line   |endif
  if exists("w:netrw_explore_list")   |let b:netrw_explore_list   = w:netrw_explore_list   |endif
"  call Dret("s:SetBufWinVars")
endfun

" ---------------------------------------------------------------------
" s:SetRexDir: set directory for :Rexplore {{{2
fun! s:SetRexDir(islocal,dirname)
"  call Dfunc("s:SetRexDir(islocal=".a:islocal." dirname<".a:dirname.">)")
  let w:netrw_rexdir         = a:dirname
  let w:netrw_rexlocal       = a:islocal
  let s:rexposn_{bufnr("%")} = netrw#SavePosn()
"  call Decho("setting s:rexposn_".bufnr("%")."<".bufname("%")."> to SavePosn",'~'.expand("<slnum>"))
"  call Dret("s:SetRexDir : win#".winnr()." ".(a:islocal? "local" : "remote")." dir: ".a:dirname)
endfun

" ---------------------------------------------------------------------
" s:ShowLink: used to modify thin and tree listings to show links {{{2
fun! s:ShowLink()
" "  call Dfunc("s:ShowLink()")
" "  call Decho("b:netrw_curdir<".(exists("b:netrw_curdir")? b:netrw_curdir : "doesn't exist").">",'~'.expand("<slnum>"))
" "  call Decho(printf("line#%4d: %s",line("."),getline(".")),'~'.expand("<slnum>"))
  if exists("b:netrw_curdir")
   norm! $?\a
   let fname   = b:netrw_curdir.'/'.s:NetrwGetWord()
   let resname = resolve(fname)
" "   call Decho("fname         <".fname.">",'~'.expand("<slnum>"))
" "   call Decho("resname       <".resname.">",'~'.expand("<slnum>"))
" "   call Decho("b:netrw_curdir<".b:netrw_curdir.">",'~'.expand("<slnum>"))
   if resname =~ '^\M'.b:netrw_curdir.'/'
    let dirlen  = strlen(b:netrw_curdir)
    let resname = strpart(resname,dirlen+1)
" "    call Decho("resname<".resname.">  (b:netrw_curdir elided)",'~'.expand("<slnum>"))
   endif
   let modline = getline(".")."\t --> ".resname
" "   call Decho("fname  <".fname.">",'~'.expand("<slnum>"))
" "   call Decho("modline<".modline.">",'~'.expand("<slnum>"))
   setl noro ma
   call setline(".",modline)
   setl ro noma nomod
  endif
" "  call Dret("s:ShowLink".((exists("fname")? ' : '.fname : 'n/a')))
endfun

" ---------------------------------------------------------------------
" s:ShowStyle: {{{2
fun! s:ShowStyle()
  if !exists("w:netrw_liststyle")
   let liststyle= g:netrw_liststyle
  else
   let liststyle= w:netrw_liststyle
  endif
  if     liststyle == s:THINLIST
   return s:THINLIST.":thin"
  elseif liststyle == s:LONGLIST
   return s:LONGLIST.":long"
  elseif liststyle == s:WIDELIST
   return s:WIDELIST.":wide"
  elseif liststyle == s:TREELIST
   return s:TREELIST.":tree"
  else
   return 'n/a'
  endif
endfun

" ---------------------------------------------------------------------
" s:Strlen: this function returns the length of a string, even if its using multi-byte characters. {{{2
"           Solution from Nicolai Weibull, vim docs (:help strlen()),
"           Tony Mechelynck, and my own invention.
fun! s:Strlen(x)
"  "" call Dfunc("s:Strlen(x<".a:x."> g:Align_xstrlen=".g:Align_xstrlen.")")

  if v:version >= 703 && exists("*strdisplaywidth")
   let ret= strdisplaywidth(a:x)

  elseif type(g:Align_xstrlen) == 1
   " allow user to specify a function to compute the string length  (ie. let g:Align_xstrlen="mystrlenfunc")
   exe "let ret= ".g:Align_xstrlen."('".substitute(a:x,"'","''","g")."')"

  elseif g:Align_xstrlen == 1
   " number of codepoints (Latin a + combining circumflex is two codepoints)
   " (comment from TM, solution from NW)
   let ret= strlen(substitute(a:x,'.','c','g'))

  elseif g:Align_xstrlen == 2
   " number of spacing codepoints (Latin a + combining circumflex is one spacing
   " codepoint; a hard tab is one; wide and narrow CJK are one each; etc.)
   " (comment from TM, solution from TM)
   let ret=strlen(substitute(a:x, '.\Z', 'x', 'g'))

  elseif g:Align_xstrlen == 3
   " virtual length (counting, for instance, tabs as anything between 1 and
   " 'tabstop', wide CJK as 2 rather than 1, Arabic alif as zero when immediately
   " preceded by lam, one otherwise, etc.)
   " (comment from TM, solution from me)
   let modkeep= &l:mod
   exe "norm! o\<esc>"
   call setline(line("."),a:x)
   let ret= virtcol("$") - 1
   d
   NetrwKeepj norm! k
   let &l:mod= modkeep

  else
   " at least give a decent default
    let ret= strlen(a:x)
  endif
"  "" call Dret("s:Strlen ".ret)
  return ret
endfun

" ---------------------------------------------------------------------
" s:TreeListMove: {{{2
fun! s:TreeListMove(dir)
"  call Dfunc("s:TreeListMove(dir<".a:dir.">)")
  let curline  = getline('.')
  let prvline  = (line(".") > 1)?         getline(line(".")-1) : ''
  let nxtline  = (line(".") < line("$"))? getline(line(".")+1) : ''
  let curindent= substitute(curline,'^\([| ]*\).\{-}$','\1','')
  let indentm1 = substitute(curindent,'^'.s:treedepthstring.' ','','')
"  call Decho("prvline  <".prvline."> #".line(".")-1,'~'.expand("<slnum>"))
"  call Decho("curline  <".curline."> #".line("."),'~'.expand("<slnum>"))
"  call Decho("nxtline  <".nxtline."> #".line(".")+1,'~'.expand("<slnum>"))
"  call Decho("curindent<".curindent.">",'~'.expand("<slnum>"))
"  call Decho("indentm1 <".indentm1.">",'~'.expand("<slnum>"))

  if curline !~ '/$'
"   call Decho('regfile','~'.expand("<slnum>"))
   if     a:dir == '[' && prvline != ''
    NetrwKeepj norm! 0
    let nl = search('^'.indentm1.'[^'.s:treedepthstring.']','bWe')    " search backwards from regular file
"    call Decho("regfile srch back: ".nl,'~'.expand("<slnum>"))
   elseif a:dir == ']' && nxtline != ''
    NetrwKeepj norm! $
    let nl = search('^'.indentm1.'[^'.s:treedepthstring.']','We')     " search forwards from regular file
"    call Decho("regfile srch fwd: ".nl,'~'.expand("<slnum>"))
   endif

  elseif a:dir == '[' && prvline != ''
   NetrwKeepj norm! 0
   let curline= line(".")
   let nl     = search('^'.curindent.'[^'.s:treedepthstring.']','bWe') " search backwards From directory, same indentation
"   call Decho("dir srch back ind: ".nl,'~'.expand("<slnum>"))
   if nl != 0
    if line(".") == curline-1
     let nl= search('^'.indentm1.'[^'.s:treedepthstring.']','bWe')     " search backwards from directory, indentation - 1
"     call Decho("dir srch back ind-1: ".nl,'~'.expand("<slnum>"))
    endif
   endif

  elseif a:dir == ']' && nxtline != ''
   NetrwKeepj norm! $
   let curline = line(".")
   let nl      = search('^'.curindent.'[^'.s:treedepthstring.']','We') " search forwards from directory, same indentation
"   call Decho("dir srch fwd ind: ".nl,'~'.expand("<slnum>"))
   if nl != 0
    if line(".") == curline+1
     let nl= search('^'.indentm1.'[^'.s:treedepthstring.']','We')         " search forwards from directory, indentation - 1
"     call Decho("dir srch fwd ind-1: ".nl,'~'.expand("<slnum>"))
    endif
   endif

  endif

"  call Dret("s:TreeListMove")
endfun

" ---------------------------------------------------------------------
" s:UpdateBuffersMenu: does emenu Buffers.Refresh (but due to locale, the menu item may not be called that) {{{2
"                      The Buffers.Refresh menu calls s:BMShow(); unfortunately, that means that that function
"                      can't be called except via emenu.  But due to locale, that menu line may not be called
"                      Buffers.Refresh; hence, s:NetrwBMShow() utilizes a "cheat" to call that function anyway.
fun! s:UpdateBuffersMenu()
"  call Dfunc("s:UpdateBuffersMenu()")
  if has("gui") && has("menu") && has("gui_running") && &go =~# 'm' && g:netrw_menu
   try
    sil emenu Buffers.Refresh\ menu
   catch /^Vim\%((\a\+)\)\=:E/
    let v:errmsg= ""
    sil NetrwKeepj call s:NetrwBMShow()
   endtry
  endif
"  call Dret("s:UpdateBuffersMenu")
endfun

" ---------------------------------------------------------------------
" s:UseBufWinVars: (used by NetrwBrowse() and LocalBrowseCheck() {{{2
"              Matching function to s:SetBufWinVars()
fun! s:UseBufWinVars()
"  call Dfunc("s:UseBufWinVars()")
  if exists("b:netrw_liststyle")       && !exists("w:netrw_liststyle")      |let w:netrw_liststyle       = b:netrw_liststyle      |endif
  if exists("b:netrw_bannercnt")       && !exists("w:netrw_bannercnt")      |let w:netrw_bannercnt       = b:netrw_bannercnt      |endif
  if exists("b:netrw_method")          && !exists("w:netrw_method")         |let w:netrw_method          = b:netrw_method         |endif
  if exists("b:netrw_prvdir")          && !exists("w:netrw_prvdir")         |let w:netrw_prvdir          = b:netrw_prvdir         |endif
  if exists("b:netrw_explore_indx")    && !exists("w:netrw_explore_indx")   |let w:netrw_explore_indx    = b:netrw_explore_indx   |endif
  if exists("b:netrw_explore_listlen") && !exists("w:netrw_explore_listlen")|let w:netrw_explore_listlen = b:netrw_explore_listlen|endif
  if exists("b:netrw_explore_mtchcnt") && !exists("w:netrw_explore_mtchcnt")|let w:netrw_explore_mtchcnt = b:netrw_explore_mtchcnt|endif
  if exists("b:netrw_explore_bufnr")   && !exists("w:netrw_explore_bufnr")  |let w:netrw_explore_bufnr   = b:netrw_explore_bufnr  |endif
  if exists("b:netrw_explore_line")    && !exists("w:netrw_explore_line")   |let w:netrw_explore_line    = b:netrw_explore_line   |endif
  if exists("b:netrw_explore_list")    && !exists("w:netrw_explore_list")   |let w:netrw_explore_list    = b:netrw_explore_list   |endif
"  call Dret("s:UseBufWinVars")
endfun

" ---------------------------------------------------------------------
" s:UserMaps: supports user-defined UserMaps {{{2
"               * calls a user-supplied funcref(islocal,curdir)
"               * interprets result
"             See netrw#UserMaps()
fun! s:UserMaps(islocal,funcname)
"  call Dfunc("s:UserMaps(islocal=".a:islocal.",funcname<".a:funcname.">)")

  if !exists("b:netrw_curdir")
   let b:netrw_curdir= getcwd()
  endif
  let Funcref = function(a:funcname)
  let result  = Funcref(a:islocal)

  if     type(result) == 1
   " if result from user's funcref is a string...
"   call Decho("result string from user funcref<".result.">",'~'.expand("<slnum>"))
   if result == "refresh"
"    call Decho("refreshing display",'~'.expand("<slnum>"))
    call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
   elseif result != ""
"    call Decho("executing result<".result.">",'~'.expand("<slnum>"))
    exe result
   endif

  elseif type(result) == 3
   " if result from user's funcref is a List...
"   call Decho("result List from user funcref<".string(result).">",'~'.expand("<slnum>"))
   for action in result
    if action == "refresh"
"     call Decho("refreshing display",'~'.expand("<slnum>"))
     call s:NetrwRefresh(a:islocal,s:NetrwBrowseChgDir(a:islocal,'./'))
    elseif action != ""
"     call Decho("executing action<".action.">",'~'.expand("<slnum>"))
     exe action
    endif
   endfor
  endif

"  call Dret("s:UserMaps")
endfun

" ---------------------------------------------------------------------
" Settings Restoration: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo

" ------------------------------------------------------------------------
" Modelines: {{{1
" vim:ts=8 fdm=marker
autoload/netrwFileHandlers.vim	[[[1
362
" netrwFileHandlers: contains various extension-based file handlers for
"                    netrw's browsers' x command ("eXecute launcher")
" Author:	Charles E. Campbell
" Date:		May 03, 2013
" Version:	11b	ASTRO-ONLY
" Copyright:    Copyright (C) 1999-2012 Charles E. Campbell {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               netrwFileHandlers.vim is provided *as is* and comes with no
"               warranty of any kind, either expressed or implied. In no
"               event will the copyright holder be liable for any damages
"               resulting from the use of this software.
"
" Rom 6:23 (WEB) For the wages of sin is death, but the free gift of God {{{1
"                is eternal life in Christ Jesus our Lord.

" ---------------------------------------------------------------------
" Load Once: {{{1
if exists("g:loaded_netrwFileHandlers") || &cp
 finish
endif
let g:loaded_netrwFileHandlers= "v11b"
if v:version < 702
 echohl WarningMsg
 echo "***warning*** this version of netrwFileHandlers needs vim 7.2"
 echohl Normal
 finish
endif
let s:keepcpo= &cpo
set cpo&vim

" ---------------------------------------------------------------------
" netrwFileHandlers#Invoke: {{{1
fun! netrwFileHandlers#Invoke(exten,fname)
"  call Dfunc("netrwFileHandlers#Invoke(exten<".a:exten."> fname<".a:fname.">)")
  let exten= a:exten
  " list of supported special characters.  Consider rcs,v --- that can be
  " supported with a NFH_rcsCOMMAv() handler
  if exten =~ '[@:,$!=\-+%?;~]'
   let specials= {
\   '@' : 'AT',
\   ':' : 'COLON',
\   ',' : 'COMMA',
\   '$' : 'DOLLAR',
\   '!' : 'EXCLAMATION',
\   '=' : 'EQUAL',
\   '-' : 'MINUS',
\   '+' : 'PLUS',
\   '%' : 'PERCENT',
\   '?' : 'QUESTION',
\   ';' : 'SEMICOLON',
\   '~' : 'TILDE'}
   let exten= substitute(a:exten,'[@:,$!=\-+%?;~]','\=specials[submatch(0)]','ge')
"   call Decho('fname<'.fname.'> done with dictionary')
  endif

  if a:exten != "" && exists("*NFH_".exten)
   " support user NFH_*() functions
"   call Decho("let ret= netrwFileHandlers#NFH_".a:exten.'("'.fname.'")')
   exe "let ret= NFH_".exten.'("'.a:fname.'")'
  elseif a:exten != "" && exists("*s:NFH_".exten)
   " use builtin-NFH_*() functions
"   call Decho("let ret= netrwFileHandlers#NFH_".a:exten.'("'.fname.'")')
   exe "let ret= s:NFH_".a:exten.'("'.a:fname.'")'
  endif

"  call Dret("netrwFileHandlers#Invoke 0 : ret=".ret)
  return 0
endfun

" ---------------------------------------------------------------------
" s:NFH_html: handles html when the user hits "x" when the {{{1
"                        cursor is atop a *.html file
fun! s:NFH_html(pagefile)
"  call Dfunc("s:NFH_html(".a:pagefile.")")

  let page= substitute(a:pagefile,'^','file://','')

  if executable("mozilla")
"   call Decho("executing !mozilla ".page)
   exe "!mozilla ".shellescape(page,1)
  elseif executable("netscape")
"   call Decho("executing !netscape ".page)
   exe "!netscape ".shellescape(page,1)
  else
"   call Dret("s:NFH_html 0")
   return 0
  endif

"  call Dret("s:NFH_html 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_htm: handles html when the user hits "x" when the {{{1
"                        cursor is atop a *.htm file
fun! s:NFH_htm(pagefile)
"  call Dfunc("s:NFH_htm(".a:pagefile.")")

  let page= substitute(a:pagefile,'^','file://','')

  if executable("mozilla")
"   call Decho("executing !mozilla ".page)
   exe "!mozilla ".shellescape(page,1)
  elseif executable("netscape")
"   call Decho("executing !netscape ".page)
   exe "!netscape ".shellescape(page,1)
  else
"   call Dret("s:NFH_htm 0")
   return 0
  endif

"  call Dret("s:NFH_htm 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_jpg: {{{1
fun! s:NFH_jpg(jpgfile)
"  call Dfunc("s:NFH_jpg(jpgfile<".a:jpgfile.">)")

  if executable("gimp")
   exe "silent! !gimp -s ".shellescape(a:jpgfile,1)
  elseif executable(expand("$SystemRoot")."/SYSTEM32/MSPAINT.EXE")
"   call Decho("silent! !".expand("$SystemRoot")."/SYSTEM32/MSPAINT ".escape(a:jpgfile," []|'"))
   exe "!".expand("$SystemRoot")."/SYSTEM32/MSPAINT ".shellescape(a:jpgfile,1)
  else
"   call Dret("s:NFH_jpg 0")
   return 0
  endif

"  call Dret("s:NFH_jpg 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_gif: {{{1
fun! s:NFH_gif(giffile)
"  call Dfunc("s:NFH_gif(giffile<".a:giffile.">)")

  if executable("gimp")
   exe "silent! !gimp -s ".shellescape(a:giffile,1)
  elseif executable(expand("$SystemRoot")."/SYSTEM32/MSPAINT.EXE")
   exe "silent! !".expand("$SystemRoot")."/SYSTEM32/MSPAINT ".shellescape(a:giffile,1)
  else
"   call Dret("s:NFH_gif 0")
   return 0
  endif

"  call Dret("s:NFH_gif 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_png: {{{1
fun! s:NFH_png(pngfile)
"  call Dfunc("s:NFH_png(pngfile<".a:pngfile.">)")

  if executable("gimp")
   exe "silent! !gimp -s ".shellescape(a:pngfile,1)
  elseif executable(expand("$SystemRoot")."/SYSTEM32/MSPAINT.EXE")
   exe "silent! !".expand("$SystemRoot")."/SYSTEM32/MSPAINT ".shellescape(a:pngfile,1)
  else
"   call Dret("s:NFH_png 0")
   return 0
  endif

"  call Dret("s:NFH_png 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_pnm: {{{1
fun! s:NFH_pnm(pnmfile)
"  call Dfunc("s:NFH_pnm(pnmfile<".a:pnmfile.">)")

  if executable("gimp")
   exe "silent! !gimp -s ".shellescape(a:pnmfile,1)
  elseif executable(expand("$SystemRoot")."/SYSTEM32/MSPAINT.EXE")
   exe "silent! !".expand("$SystemRoot")."/SYSTEM32/MSPAINT ".shellescape(a:pnmfile,1)
  else
"   call Dret("s:NFH_pnm 0")
   return 0
  endif

"  call Dret("s:NFH_pnm 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_bmp: visualize bmp files {{{1
fun! s:NFH_bmp(bmpfile)
"  call Dfunc("s:NFH_bmp(bmpfile<".a:bmpfile.">)")

  if executable("gimp")
   exe "silent! !gimp -s ".a:bmpfile
  elseif executable(expand("$SystemRoot")."/SYSTEM32/MSPAINT.EXE")
   exe "silent! !".expand("$SystemRoot")."/SYSTEM32/MSPAINT ".shellescape(a:bmpfile,1)
  else
"   call Dret("s:NFH_bmp 0")
   return 0
  endif

"  call Dret("s:NFH_bmp 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_pdf: visualize pdf files {{{1
fun! s:NFH_pdf(pdf)
"  call Dfunc("s:NFH_pdf(pdf<".a:pdf.">)")
  if executable("gs")
   exe 'silent! !gs '.shellescape(a:pdf,1)
  elseif executable("pdftotext")
   exe 'silent! pdftotext -nopgbrk '.shellescape(a:pdf,1)
  else
"  call Dret("s:NFH_pdf 0")
   return 0
  endif

"  call Dret("s:NFH_pdf 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_doc: visualize doc files {{{1
fun! s:NFH_doc(doc)
"  call Dfunc("s:NFH_doc(doc<".a:doc.">)")

  if executable("oowriter")
   exe 'silent! !oowriter '.shellescape(a:doc,1)
   redraw!
  else
"  call Dret("s:NFH_doc 0")
   return 0
  endif

"  call Dret("s:NFH_doc 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_sxw: visualize sxw files {{{1
fun! s:NFH_sxw(sxw)
"  call Dfunc("s:NFH_sxw(sxw<".a:sxw.">)")

  if executable("oowriter")
   exe 'silent! !oowriter '.shellescape(a:sxw,1)
   redraw!
  else
"   call Dret("s:NFH_sxw 0")
   return 0
  endif

"  call Dret("s:NFH_sxw 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_xls: visualize xls files {{{1
fun! s:NFH_xls(xls)
"  call Dfunc("s:NFH_xls(xls<".a:xls.">)")

  if executable("oocalc")
   exe 'silent! !oocalc '.shellescape(a:xls,1)
   redraw!
  else
"  call Dret("s:NFH_xls 0")
   return 0
  endif

"  call Dret("s:NFH_xls 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_ps: handles PostScript files {{{1
fun! s:NFH_ps(ps)
"  call Dfunc("s:NFH_ps(ps<".a:ps.">)")
  if executable("gs")
"   call Decho("exe silent! !gs ".a:ps)
   exe "silent! !gs ".shellescape(a:ps,1)
   redraw!
  elseif executable("ghostscript")
"   call Decho("exe silent! !ghostscript ".a:ps)
   exe "silent! !ghostscript ".shellescape(a:ps,1)
   redraw!
  elseif executable("gswin32")
"   call Decho("exe silent! !gswin32 ".shellescape(a:ps,1))
   exe "silent! !gswin32 ".shellescape(a:ps,1)
   redraw!
  else
"   call Dret("s:NFH_ps 0")
   return 0
  endif

"  call Dret("s:NFH_ps 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_eps: handles encapsulated PostScript files {{{1
fun! s:NFH_eps(eps)
"  call Dfunc("s:NFH_eps()")
  if executable("gs")
   exe "silent! !gs ".shellescape(a:eps,1)
   redraw!
  elseif executable("ghostscript")
   exe "silent! !ghostscript ".shellescape(a:eps,1)
   redraw!
  elseif executable("ghostscript")
   exe "silent! !ghostscript ".shellescape(a:eps,1)
   redraw!
  elseif executable("gswin32")
   exe "silent! !gswin32 ".shellescape(a:eps,1)
   redraw!
  else
"   call Dret("s:NFH_eps 0")
   return 0
  endif
"  call Dret("s:NFH_eps 0")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_fig: handles xfig files {{{1
fun! s:NFH_fig(fig)
"  call Dfunc("s:NFH_fig()")
  if executable("xfig")
   exe "silent! !xfig ".a:fig
   redraw!
  else
"   call Dret("s:NFH_fig 0")
   return 0
  endif

"  call Dret("s:NFH_fig 1")
  return 1
endfun

" ---------------------------------------------------------------------
" s:NFH_obj: handles tgif's obj files {{{1
fun! s:NFH_obj(obj)
"  call Dfunc("s:NFH_obj()")
  if has("unix") && executable("tgif")
   exe "silent! !tgif ".a:obj
   redraw!
  else
"   call Dret("s:NFH_obj 0")
   return 0
  endif

"  call Dret("s:NFH_obj 1")
  return 1
endfun

let &cpo= s:keepcpo
unlet s:keepcpo
" ---------------------------------------------------------------------
"  Modelines: {{{1
"  vim: fdm=marker
autoload/netrwSettings.vim	[[[1
245
" netrwSettings.vim: makes netrw settings simpler
" Date:		Dec 30, 2014
" Maintainer:	Charles E Campbell <drchipNOSPAM at campbellfamily dot biz>
" Version:	15
" Copyright:    Copyright (C) 1999-2007 Charles E. Campbell {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               netrwSettings.vim is provided *as is* and comes with no
"               warranty of any kind, either expressed or implied. By using
"               this plugin, you agree that in no event will the copyright
"               holder be liable for any damages resulting from the use
"               of this software.
"
" Mat 4:23 (WEB) Jesus went about in all Galilee, teaching in their {{{1
"                synagogues, preaching the gospel of the kingdom, and healing
"                every disease and every sickness among the people.
" Load Once: {{{1
if exists("g:loaded_netrwSettings") || &cp
  finish
endif
let g:loaded_netrwSettings = "v15"
if v:version < 700
 echohl WarningMsg
 echo "***warning*** this version of netrwSettings needs vim 7.0"
 echohl Normal
 finish
endif

" ---------------------------------------------------------------------
" NetrwSettings: {{{1
fun! netrwSettings#NetrwSettings()
  " this call is here largely just to insure that netrw has been loaded
  call netrw#SavePosn()
  if !exists("g:loaded_netrw")
   echohl WarningMsg | echomsg "***sorry*** netrw needs to be loaded prior to using NetrwSettings" | echohl None
   return
  endif

  above wincmd s
  enew
  setlocal noswapfile bh=wipe
  set ft=vim
  file Netrw\ Settings

  " these variables have the following default effects when they don't
  " exist (ie. have not been set by the user in his/her .vimrc)
  if !exists("g:netrw_liststyle")
   let g:netrw_liststyle= 0
   let g:netrw_list_cmd= "ssh HOSTNAME ls -FLa"
  endif
  if !exists("g:netrw_silent")
   let g:netrw_silent= 0
  endif
  if !exists("g:netrw_use_nt_rcp")
   let g:netrw_use_nt_rcp= 0
  endif
  if !exists("g:netrw_ftp")
   let g:netrw_ftp= 0
  endif
  if !exists("g:netrw_ignorenetrc")
   let g:netrw_ignorenetrc= 0
  endif

  put ='+ ---------------------------------------------'
  put ='+  NetrwSettings:  by Charles E. Campbell'
  put ='+ Press <F1> with cursor atop any line for help'
  put ='+ ---------------------------------------------'
  let s:netrw_settings_stop= line(".")

  put =''
  put ='+ Netrw Protocol Commands'
  put = 'let g:netrw_dav_cmd           = '.g:netrw_dav_cmd
  put = 'let g:netrw_fetch_cmd         = '.g:netrw_fetch_cmd
  put = 'let g:netrw_ftp_cmd           = '.g:netrw_ftp_cmd
  put = 'let g:netrw_http_cmd          = '.g:netrw_http_cmd
  put = 'let g:netrw_rcp_cmd           = '.g:netrw_rcp_cmd
  put = 'let g:netrw_rsync_cmd         = '.g:netrw_rsync_cmd
  put = 'let g:netrw_scp_cmd           = '.g:netrw_scp_cmd
  put = 'let g:netrw_sftp_cmd          = '.g:netrw_sftp_cmd
  put = 'let g:netrw_ssh_cmd           = '.g:netrw_ssh_cmd
  let s:netrw_protocol_stop= line(".")
  put = ''

  put ='+Netrw Transfer Control'
  put = 'let g:netrw_cygwin            = '.g:netrw_cygwin
  put = 'let g:netrw_ftp               = '.g:netrw_ftp
  put = 'let g:netrw_ftpmode           = '.g:netrw_ftpmode
  put = 'let g:netrw_ignorenetrc       = '.g:netrw_ignorenetrc
  put = 'let g:netrw_sshport           = '.g:netrw_sshport
  put = 'let g:netrw_silent            = '.g:netrw_silent
  put = 'let g:netrw_use_nt_rcp        = '.g:netrw_use_nt_rcp
  put = 'let g:netrw_win95ftp          = '.g:netrw_win95ftp
  let s:netrw_xfer_stop= line(".")
  put =''
  put ='+ Netrw Messages'
  put ='let g:netrw_use_errorwindow    = '.g:netrw_use_errorwindow

  put = ''
  put ='+ Netrw Browser Control'
  if exists("g:netrw_altfile")
   put = 'let g:netrw_altfile   = '.g:netrw_altfile
  else
   put = 'let g:netrw_altfile   = 0'
  endif
  put = 'let g:netrw_alto              = '.g:netrw_alto
  put = 'let g:netrw_altv              = '.g:netrw_altv
  put = 'let g:netrw_banner            = '.g:netrw_banner
  if exists("g:netrw_bannerbackslash")
   put = 'let g:netrw_bannerbackslash   = '.g:netrw_bannerbackslash
  else
   put = '\" let g:netrw_bannerbackslash   = (not defined)'
  endif
  put = 'let g:netrw_browse_split      = '.g:netrw_browse_split
  if exists("g:netrw_browsex_viewer")
   put = 'let g:netrw_browsex_viewer   = '.g:netrw_browsex_viewer
  else
   put = '\" let g:netrw_browsex_viewer   = (not defined)'
  endif
  put = 'let g:netrw_compress          = '.g:netrw_compress
  if exists("g:Netrw_corehandler")
   put = 'let g:Netrw_corehandler      = '.g:Netrw_corehandler
  else
   put = '\" let g:Netrw_corehandler      = (not defined)'
  endif
  put = 'let g:netrw_ctags             = '.g:netrw_ctags
  put = 'let g:netrw_cursor            = '.g:netrw_cursor
  let decompressline= line("$")
  put = 'let g:netrw_decompress        = '.string(g:netrw_decompress)
  if exists("g:netrw_dynamic_maxfilenamelen")
   put = 'let g:netrw_dynamic_maxfilenamelen='.g:netrw_dynamic_maxfilenamelen
  else
   put = '\" let g:netrw_dynamic_maxfilenamelen= (not defined)'
  endif
  put = 'let g:netrw_dirhistmax        = '.g:netrw_dirhistmax
  put = 'let g:netrw_errorlvl          = '.g:netrw_errorlvl
  put = 'let g:netrw_fastbrowse        = '.g:netrw_fastbrowse
  let fnameescline= line("$")
  put = 'let g:netrw_fname_escape      = '.string(g:netrw_fname_escape)
  put = 'let g:netrw_ftp_browse_reject = '.g:netrw_ftp_browse_reject
  put = 'let g:netrw_ftp_list_cmd      = '.g:netrw_ftp_list_cmd
  put = 'let g:netrw_ftp_sizelist_cmd  = '.g:netrw_ftp_sizelist_cmd
  put = 'let g:netrw_ftp_timelist_cmd  = '.g:netrw_ftp_timelist_cmd
  let globescline= line("$")
  put = 'let g:netrw_glob_escape       = '.string(g:netrw_glob_escape)
  put = 'let g:netrw_hide              = '.g:netrw_hide
  if exists("g:netrw_home")
   put = 'let g:netrw_home              = '.g:netrw_home
  else
   put = '\" let g:netrw_home              = (not defined)'
  endif
  put = 'let g:netrw_keepdir           = '.g:netrw_keepdir
  put = 'let g:netrw_list_cmd          = '.g:netrw_list_cmd
  put = 'let g:netrw_list_hide         = '.g:netrw_list_hide
  put = 'let g:netrw_liststyle         = '.g:netrw_liststyle
  put = 'let g:netrw_localcopycmd      = '.g:netrw_localcopycmd
  put = 'let g:netrw_localmkdir        = '.g:netrw_localmkdir
  put = 'let g:netrw_localmovecmd      = '.g:netrw_localmovecmd
  put = 'let g:netrw_localrmdir        = '.g:netrw_localrmdir
  put = 'let g:netrw_maxfilenamelen    = '.g:netrw_maxfilenamelen
  put = 'let g:netrw_menu              = '.g:netrw_menu
  put = 'let g:netrw_mousemaps         = '.g:netrw_mousemaps
  put = 'let g:netrw_mkdir_cmd         = '.g:netrw_mkdir_cmd
  if exists("g:netrw_nobeval")
   put = 'let g:netrw_nobeval           = '.g:netrw_nobeval
  else
   put = '\" let g:netrw_nobeval           = (not defined)'
  endif
  put = 'let g:netrw_remote_mkdir      = '.g:netrw_remote_mkdir
  put = 'let g:netrw_preview           = '.g:netrw_preview
  put = 'let g:netrw_rename_cmd        = '.g:netrw_rename_cmd
  put = 'let g:netrw_retmap            = '.g:netrw_retmap
  put = 'let g:netrw_rm_cmd            = '.g:netrw_rm_cmd
  put = 'let g:netrw_rmdir_cmd         = '.g:netrw_rmdir_cmd
  put = 'let g:netrw_rmf_cmd           = '.g:netrw_rmf_cmd
  put = 'let g:netrw_sort_by           = '.g:netrw_sort_by
  put = 'let g:netrw_sort_direction    = '.g:netrw_sort_direction
  put = 'let g:netrw_sort_options      = '.g:netrw_sort_options
  put = 'let g:netrw_sort_sequence     = '.g:netrw_sort_sequence
  put = 'let g:netrw_servername        = '.g:netrw_servername
  put = 'let g:netrw_special_syntax    = '.g:netrw_special_syntax
  put = 'let g:netrw_ssh_browse_reject = '.g:netrw_ssh_browse_reject
  put = 'let g:netrw_ssh_cmd           = '.g:netrw_ssh_cmd
  put = 'let g:netrw_scpport           = '.g:netrw_scpport
  put = 'let g:netrw_sepchr            = '.g:netrw_sepchr
  put = 'let g:netrw_sshport           = '.g:netrw_sshport
  put = 'let g:netrw_timefmt           = '.g:netrw_timefmt
  let tmpfileescline= line("$")
  put ='let g:netrw_tmpfile_escape...'
  put = 'let g:netrw_use_noswf         = '.g:netrw_use_noswf
  put = 'let g:netrw_xstrlen           = '.g:netrw_xstrlen
  put = 'let g:netrw_winsize           = '.g:netrw_winsize

  put =''
  put ='+ For help, place cursor on line and press <F1>'

  1d
  silent %s/^+/"/e
  res 99
  silent %s/= \([^0-9].*\)$/= '\1'/e
  silent %s/= $/= ''/e
  1

  call setline(decompressline,"let g:netrw_decompress        = ".substitute(string(g:netrw_decompress),"^'\\(.*\\)'$",'\1',''))
  call setline(fnameescline,  "let g:netrw_fname_escape      = '".escape(g:netrw_fname_escape,"'")."'")
  call setline(globescline,   "let g:netrw_glob_escape       = '".escape(g:netrw_glob_escape,"'")."'")
  call setline(tmpfileescline,"let g:netrw_tmpfile_escape    = '".escape(g:netrw_tmpfile_escape,"'")."'")

  set nomod

  nmap <buffer> <silent> <F1>                       :call NetrwSettingHelp()<cr>
  nnoremap <buffer> <silent> <leftmouse> <leftmouse>:call NetrwSettingHelp()<cr>
  let tmpfile= tempname()
  exe 'au BufWriteCmd	Netrw\ Settings	silent w! '.tmpfile.'|so '.tmpfile.'|call delete("'.tmpfile.'")|set nomod'
endfun

" ---------------------------------------------------------------------
" NetrwSettingHelp: {{{2
fun! NetrwSettingHelp()
"  call Dfunc("NetrwSettingHelp()")
  let curline = getline(".")
  if curline =~ '='
   let varhelp = substitute(curline,'^\s*let ','','e')
   let varhelp = substitute(varhelp,'\s*=.*$','','e')
"   call Decho("trying help ".varhelp)
   try
    exe "he ".varhelp
   catch /^Vim\%((\a\+)\)\=:E149/
   	echo "***sorry*** no help available for <".varhelp.">"
   endtry
  elseif line(".") < s:netrw_settings_stop
   he netrw-settings
  elseif line(".") < s:netrw_protocol_stop
   he netrw-externapp
  elseif line(".") < s:netrw_xfer_stop
   he netrw-variables
  else
   he netrw-browse-var
  endif
"  call Dret("NetrwSettingHelp")
endfun

" ---------------------------------------------------------------------
" Modelines: {{{1
" vim:ts=8 fdm=marker
doc/pi_netrw.txt	[[[1
3955
*pi_netrw.txt*  For Vim version 7.4.  Last change: 2015 Aug 10

	    ------------------------------------------------
	    NETRW REFERENCE MANUAL    by Charles E. Campbell
	    ------------------------------------------------
Author:  Charles E. Campbell  <NdrOchip@ScampbellPfamily.AbizM>
	  (remove NOSPAM from Campbell's email first)

Copyright: Copyright (C) 1999-2015 Charles E Campbell    *netrw-copyright*
	The VIM LICENSE applies to the files in this package, including
	netrw.vim, pi_netrw.txt, netrwFileHandlers.vim, netrwSettings.vim, and
	syntax/netrw.vim.  Like anything else that's free, netrw.vim and its
	associated files are provided *as is* and comes with no warranty of
	any kind, either expressed or implied.  No guarantees of
	merchantability.  No guarantees of suitability for any purpose.  By
	using this plugin, you agree that in no event will the copyright
	holder be liable for any damages resulting from the use of this
	software. Use at your own risk!


		*netrw*
		*dav*    *ftp*    *netrw-file*  *rcp*    *scp*
		*davs*   *http*   *netrw.vim*   *rsync*  *sftp*
		*fetch*  *network*

==============================================================================
1. Contents						*netrw-contents* {{{1

1.  Contents..............................................|netrw-contents|
2.  Starting With Netrw...................................|netrw-start|
3.  Netrw Reference.......................................|netrw-ref|
      EXTERNAL APPLICATIONS AND PROTOCOLS.................|netrw-externapp|
      READING.............................................|netrw-read|
      WRITING.............................................|netrw-write|
      SOURCING............................................|netrw-source|
      DIRECTORY LISTING...................................|netrw-dirlist|
      CHANGING THE USERID AND PASSWORD....................|netrw-chgup|
      VARIABLES AND SETTINGS..............................|netrw-variables|
      PATHS...............................................|netrw-path|
4.  Network-Oriented File Transfer........................|netrw-xfer|
      NETRC...............................................|netrw-netrc|
      PASSWORD............................................|netrw-passwd|
5.  Activation............................................|netrw-activate|
6.  Transparent Remote File Editing.......................|netrw-transparent|
7.  Ex Commands...........................................|netrw-ex|
8.  Variables and Options.................................|netrw-variables|
9.  Browsing..............................................|netrw-browse|
      Introduction To Browsing............................|netrw-intro-browse|
      Quick Reference: Maps...............................|netrw-browse-maps|
      Quick Reference: Commands...........................|netrw-browse-cmds|
      Bookmarking A Directory.............................|netrw-mb|
      Browsing............................................|netrw-cr|
        Squeezing the Current Tree-Listing Directory......|:netrw-s-cr|
      Browsing With A Horizontally Split Window...........|netrw-o|
      Browsing With A New Tab.............................|netrw-t|
      Browsing With A Vertically Split Window.............|netrw-v|
      Change Listing Style.(thin wide long tree)..........|netrw-i|
      Changing To A Bookmarked Directory..................|netrw-gb|
      Changing To A Predecessor Directory.................|netrw-u|
      Changing To A Successor Directory...................|netrw-U|
      Customizing Browsing With A Special Handler.........|netrw-x|
      Deleting Bookmarks..................................|netrw-mB|
      Deleting Files Or Directories.......................|netrw-D|
      Directory Exploring Commands........................|netrw-explore|
      Exploring With Stars and Patterns...................|netrw-star|
      Displaying Information About File...................|netrw-qf|
      Edit File Or Directory Hiding List..................|netrw-ctrl-h|
      Editing The Sorting Sequence........................|netrw-S|
      Forcing treatment as a file or directory............|netrw-gd| |netrw-gf|
      Going Up............................................|netrw--|
      Hiding Files Or Directories.........................|netrw-a|
      Improving Browsing..................................|netrw-ssh-hack|
      Listing Bookmarks And History.......................|netrw-qb|
      Making A New Directory..............................|netrw-d|
      Making The Browsing Directory The Current Directory.|netrw-c|
      Marking Files.......................................|netrw-mf|
      Unmarking Files.....................................|netrw-mF|
      Marking Files By QuickFix List......................|netrw-qF|
      Marking Files By Regular Expression.................|netrw-mr|
      Marked Files: Arbitrary Shell Command...............|netrw-mx|
      Marked Files: Arbitrary Shell Command, En Bloc......|netrw-mX|
      Marked Files: Arbitrary Vim Command.................|netrw-mv|
      Marked Files: Compression And Decompression.........|netrw-mz|
      Marked Files: Copying...............................|netrw-mc|
      Marked Files: Diff..................................|netrw-md|
      Marked Files: Editing...............................|netrw-me|
      Marked Files: Grep..................................|netrw-mg|
      Marked Files: Hiding and Unhiding by Suffix.........|netrw-mh|
      Marked Files: Moving................................|netrw-mm|
      Marked Files: Printing..............................|netrw-mp|
      Marked Files: Sourcing..............................|netrw-ms|
      Marked Files: Setting the Target Directory..........|netrw-mt|
      Marked Files: Tagging...............................|netrw-mT|
      Marked Files: Target Directory Using Bookmarks......|netrw-Tb|
      Marked Files: Target Directory Using History........|netrw-Th|
      Marked Files: Unmarking.............................|netrw-mu|
      Netrw Browser Variables.............................|netrw-browser-var|
      Netrw Browsing And Option Incompatibilities.........|netrw-incompatible|
      Netrw Settings Window...............................|netrw-settings-window|
      Obtaining A File....................................|netrw-O|
      Preview Window......................................|netrw-p|
      Previous Window.....................................|netrw-P|
      Refreshing The Listing..............................|netrw-ctrl-l|
      Reversing Sorting Order.............................|netrw-r|
      Renaming Files Or Directories.......................|netrw-R|
      Selecting Sorting Style.............................|netrw-s|
      Setting Editing Window..............................|netrw-C|
10. Problems and Fixes....................................|netrw-problems|
11. Debugging Netrw Itself................................|netrw-debug|
12. History...............................................|netrw-history|
13. Todo..................................................|netrw-todo|
14. Credits...............................................|netrw-credits|

{Vi does not have any of this}

==============================================================================
2. Starting With Netrw					*netrw-start* {{{1

Netrw makes reading files, writing files, browsing over a network, and
local browsing easy!  First, make sure that you have plugins enabled, so
you'll need to have at least the following in your <.vimrc>:
(or see |netrw-activate|) >

	set nocp                    " 'compatible' is not set
	filetype plugin on          " plugins are enabled
<
(see |'cp'| and |:filetype-plugin-on|)

Netrw supports "transparent" editing of files on other machines using urls
(see |netrw-transparent|). As an example of this, let's assume you have an
account on some other machine; if you can use scp, try: >

	vim scp://hostname/path/to/file
<
Want to make ssh/scp easier to use? Check out |netrw-ssh-hack|!

So, what if you have ftp, not ssh/scp?  That's easy, too; try >

	vim ftp://hostname/path/to/file
<
Want to make ftp simpler to use?  See if your ftp supports a file called
<.netrc> -- typically it goes in your home directory, has read/write
permissions for only the user to read (ie. not group, world, other, etc),
and has lines resembling >

	machine HOSTNAME login USERID password "PASSWORD"
	machine HOSTNAME login USERID password "PASSWORD"
	...
	default          login USERID password "PASSWORD"
<
Windows' ftp doesn't support .netrc; however, one may have in one's .vimrc:  >

   let g:netrw_ftp_cmd= 'c:\Windows\System32\ftp -s:C:\Users\MyUserName\MACHINE'
<
Netrw will substitute the host's machine name for "MACHINE" from the url it is
attempting to open, and so one may specify >
	userid
	password
for each site in a separate file: c:\Users\MyUserName\MachineName.

Now about browsing -- when you just want to look around before editing a
file.  For browsing on your current host, just "edit" a directory: >

	vim .
	vim /home/userid/path
<
For browsing on a remote host, "edit" a directory (but make sure that
the directory name is followed by a "/"): >

	vim scp://hostname/
	vim ftp://hostname/path/to/dir/
<
See |netrw-browse| for more!

There are more protocols supported by netrw than just scp and ftp, too: see the
next section, |netrw-externapp|, on how to use these external applications with
netrw and vim.

PREVENTING LOADING					*netrw-noload*

If you want to use plugins, but for some reason don't wish to use netrw, then
you need to avoid loading both the plugin and the autoload portions of netrw.
You may do so by placing the following two lines in your <.vimrc>: >

	:let g:loaded_netrw       = 1
	:let g:loaded_netrwPlugin = 1
<

==============================================================================
3. Netrw Reference					*netrw-ref* {{{1

   Netrw supports several protocols in addition to scp and ftp as mentioned
   in |netrw-start|.  These include dav, fetch, http,... well, just look
   at the list in |netrw-externapp|.  Each protocol is associated with a
   variable which holds the default command supporting that protocol.

EXTERNAL APPLICATIONS AND PROTOCOLS			*netrw-externapp* {{{2

	Protocol  Variable	       Default Value
	--------  ----------------     -------------
	   dav:   *g:netrw_dav_cmd*      = "cadaver"    if cadaver is executable
	   dav:   g:netrw_dav_cmd      = "curl -o"    elseif curl is available
	 fetch:   *g:netrw_fetch_cmd*    = "fetch -o"   if fetch is available
	   ftp:   *g:netrw_ftp_cmd*      = "ftp"
	  http:   *g:netrw_http_cmd*     = "elinks"     if   elinks  is available
	  http:   g:netrw_http_cmd     = "links"      elseif links is available
	  http:   g:netrw_http_cmd     = "curl"       elseif curl  is available
	  http:   g:netrw_http_cmd     = "wget"       elseif wget  is available
          http:   g:netrw_http_cmd     = "fetch"      elseif fetch is available
	  http:   *g:netrw_http_put_cmd* = "curl -T"
	   rcp:   *g:netrw_rcp_cmd*      = "rcp"
	 rsync:   *g:netrw_rsync_cmd*    = "rsync -a"
	   scp:   *g:netrw_scp_cmd*      = "scp -q"
	  sftp:   *g:netrw_sftp_cmd*     = "sftp"
	  file:   *g:netrw_file_cmd*     = "elinks" or "links"

	*g:netrw_http_xcmd* : the option string for http://... protocols are
	specified via this variable and may be independently overridden.  By
	default, the option arguments for the http-handling commands are: >

		    elinks : "-source >"
		    links  : "-dump >"
		    curl   : "-o"
		    wget   : "-q -O"
		    fetch  : "-o"
<
	For example, if your system has elinks, and you'd rather see the
	page using an attempt at rendering the text, you may wish to have >
		let g:netrw_http_xcmd= "-dump >"
<	in your .vimrc.

	g:netrw_http_put_cmd: this option specifies both the executable and
	any needed options.  This command does a PUT operation to the url.


READING						*netrw-read* *netrw-nread* {{{2

	Generally, one may just use the url notation with a normal editing
	command, such as >

		:e ftp://[user@]machine/path
<
	Netrw also provides the Nread command:

	:Nread ?					give help
	:Nread "machine:path"				uses rcp
	:Nread "machine path"				uses ftp w/ <.netrc>
	:Nread "machine id password path"		uses ftp
	:Nread "dav://machine[:port]/path"		uses cadaver
	:Nread "fetch://[user@]machine/path"		uses fetch
	:Nread "ftp://[user@]machine[[:#]port]/path"	uses ftp w/ <.netrc>
	:Nread "http://[user@]machine/path"		uses http  uses wget
	:Nread "rcp://[user@]machine/path"		uses rcp
	:Nread "rsync://[user@]machine[:port]/path"	uses rsync
	:Nread "scp://[user@]machine[[:#]port]/path"	uses scp
	:Nread "sftp://[user@]machine/path"		uses sftp

WRITING					*netrw-write* *netrw-nwrite* {{{2

	One may just use the url notation with a normal file writing
	command, such as >

		:w ftp://[user@]machine/path
<
	Netrw also provides the Nwrite command:

	:Nwrite ?					give help
	:Nwrite "machine:path"				uses rcp
	:Nwrite "machine path"				uses ftp w/ <.netrc>
	:Nwrite "machine id password path"		uses ftp
	:Nwrite "dav://machine[:port]/path"		uses cadaver
	:Nwrite "ftp://[user@]machine[[:#]port]/path"	uses ftp w/ <.netrc>
	:Nwrite "rcp://[user@]machine/path"		uses rcp
	:Nwrite "rsync://[user@]machine[:port]/path"	uses rsync
	:Nwrite "scp://[user@]machine[[:#]port]/path"	uses scp
	:Nwrite "sftp://[user@]machine/path"		uses sftp
	http: not supported!

SOURCING					*netrw-source* {{{2

	One may just use the url notation with the normal file sourcing
	command, such as >

		:so ftp://[user@]machine/path
<
	Netrw also provides the Nsource command:

	:Nsource ?					give help
	:Nsource "dav://machine[:port]/path"		uses cadaver
	:Nsource "fetch://[user@]machine/path"		uses fetch
	:Nsource "ftp://[user@]machine[[:#]port]/path"	uses ftp w/ <.netrc>
	:Nsource "http://[user@]machine/path"		uses http  uses wget
	:Nsource "rcp://[user@]machine/path"		uses rcp
	:Nsource "rsync://[user@]machine[:port]/path"	uses rsync
	:Nsource "scp://[user@]machine[[:#]port]/path"	uses scp
	:Nsource "sftp://[user@]machine/path"		uses sftp

DIRECTORY LISTING		*netrw-trailingslash* *netrw-dirlist* {{{2

	One may browse a directory to get a listing by simply attempting to
	edit the directory: >

		:e scp://[user]@hostname/path/
		:e ftp://[user]@hostname/path/
<
	For remote directory listings (ie. those using scp or ftp), that
	trailing "/" is necessary (the slash tells netrw to treat the argument
	as a directory to browse instead of as a file to download).

	The Nread command may also be used to accomplish this (again, that
	trailing slash is necessary): >

		:Nread [protocol]://[user]@hostname/path/
<
					*netrw-login* *netrw-password*
CHANGING USERID AND PASSWORD		*netrw-chgup* *netrw-userpass* {{{2

	Attempts to use ftp will prompt you for a user-id and a password.
	These will be saved in global variables |g:netrw_uid| and
	|s:netrw_passwd|; subsequent use of ftp will re-use those two strings,
	thereby simplifying use of ftp.  However, if you need to use a
	different user id and/or password, you'll want to call |NetUserPass()|
	first.  To work around the need to enter passwords, check if your ftp
	supports a <.netrc> file in your home directory.  Also see
	|netrw-passwd| (and if you're using ssh/scp hoping to figure out how
	to not need to use passwords for scp, look at |netrw-ssh-hack|).

	:NetUserPass [uid [password]]		-- prompts as needed
	:call NetUserPass()			-- prompts for uid and password
	:call NetUserPass("uid")		-- prompts for password
	:call NetUserPass("uid","password")	-- sets global uid and password

(Related topics: |ftp| |netrw-userpass| |netrw-start|)

NETRW VARIABLES AND SETTINGS				*netrw-variables* {{{2
    (Also see:
    |netrw-browser-var|     : netrw browser option variables
    |netrw-protocol|        : file transfer protocol option variables
    |netrw-settings|        : additional file transfer options
    |netrw-browser-options| : these options affect browsing directories
    )

Netrw provides a lot of variables which allow you to customize netrw to your
preferences.  One way to look at them is via the command :NetrwSettings (see
|netrw-settings|) which will display your current netrw settings.  Most such
settings are described below, in |netrw-browser-options|, and in
|netrw-externapp|:

 *b:netrw_lastfile*	last file Network-read/written retained on a
			per-buffer basis (supports plain :Nw )

 *g:netrw_bufsettings*	the settings that netrw buffers have
			(default) noma nomod nonu nowrap ro nobl

 *g:netrw_chgwin*	specifies a window number where subsequent file edits
			will take place.  (also see |netrw-C|)
			(default) -1

 *g:Netrw_funcref*	specifies a function (or functions) to be called when
			netrw edits a file.  The file is first edited, and
			then the function reference (|Funcref|) is called.
			This variable may also hold a |List| of Funcrefs.
			(default) not defined.  (the capital in g:Netrw...
			is required by its holding a function reference)
>
			    Example: place in .vimrc; affects all file opening
			    fun! MyFuncRef()
			    endfun
			    let g:Netrw_funcref= function("MyFuncRef")

<
 *g:Netrw_UserMaps*	specifies a function or |List| of functions which can
			be used to set up user-specified maps and functionality.
			See |netrw-usermaps|

 *g:netrw_ftp*		   if it doesn't exist, use default ftp
			=0 use default ftp		       (uid password)
			=1 use alternate ftp method	  (user uid password)
			   If you're having trouble with ftp, try changing the
			   value of this variable to see if the alternate ftp
			   method works for your setup.

 *g:netrw_ftp_options*     Chosen by default, these options are supposed to
			 turn interactive prompting off and to restrain ftp
			 from attempting auto-login upon initial connection.
			 However, it appears that not all ftp implementations
			 support this (ex. ncftp).
		        ="-i -n"

 *g:netrw_ftpextracmd*	default: doesn't exist
			If this variable exists, then any string it contains
			will be placed into the commands set to your ftp
			client.  As an example:
			   ="passive"

 *g:netrw_ftpmode*	="binary"				    (default)
			="ascii"

 *g:netrw_ignorenetrc*	=0 (default for linux, cygwin)
			=1 If you have a <.netrc> file but it doesn't work and
			   you want it ignored, then set this variable as
			   shown. (default for Windows + cmd.exe)

 *g:netrw_menu*		=0 disable netrw's menu
			=1 (default) netrw's menu enabled

 *g:netrw_nogx*		if this variable exists, then the "gx" map will not
			be available (see |netrw-gx|)

 *g:netrw_uid*		(ftp) user-id,      retained on a per-vim-session basis
 *s:netrw_passwd*	(ftp) password,     retained on a per-vim-session basis

 *g:netrw_preview*	=0 (default) preview window shown in a horizontally
			   split window
			=1 preview window shown in a vertically split window.
			   Also affects the "previous window" (see |netrw-P|)
			   in the same way.
			The |g:netrw_alto| variable may be used to provide
			additional splitting control:
				g:netrw_preview g:netrw_alto result
				         0             0     |:aboveleft|
				         0             1     |:belowright|
				         1             0     |:topleft|
				         1             1     |:botright|
			To control sizing, see |g:netrw_winsize|

 *g:netrw_scpport*	= "-P" : option to use to set port for scp
 *g:netrw_sshport*	= "-p" : option to use to set port for ssh

 *g:netrw_sepchr*	=\0xff
			=\0x01 for enc == euc-jp (and perhaps it should be for
			   others, too, please let me know)
			   Separates priority codes from filenames internally.
			   See |netrw-p12|.

  *g:netrw_silent*	=0 : transfers done normally
			=1 : transfers done silently

 *g:netrw_use_errorwindow* =1 : messages from netrw will use a separate one
			      line window.  This window provides reliable
			      delivery of messages. (default)
			 =0 : messages from netrw will use echoerr ;
			      messages don't always seem to show up this
			      way, but one doesn't have to quit the window.

 *g:netrw_win95ftp*	=1 if using Win95, will remove four trailing blank
			   lines that o/s's ftp "provides" on transfers
			=0 force normal ftp behavior (no trailing line removal)

 *g:netrw_cygwin*	=1 assume scp under windows is from cygwin. Also
			   permits network browsing to use ls with time and
			   size sorting (default if windows)
			=0 assume Windows' scp accepts windows-style paths
			   Network browsing uses dir instead of ls
			   This option is ignored if you're using unix

 *g:netrw_use_nt_rcp*	=0 don't use the rcp of WinNT, Win2000 and WinXP
			=1 use WinNT's rcp in binary mode         (default)

PATHS							*netrw-path* {{{2

Paths to files are generally user-directory relative for most protocols.
It is possible that some protocol will make paths relative to some
associated directory, however.
>
	example:  vim scp://user@host/somefile
	example:  vim scp://user@host/subdir1/subdir2/somefile
<
where "somefile" is in the "user"'s home directory.  If you wish to get a
file using root-relative paths, use the full path:
>
	example:  vim scp://user@host//somefile
	example:  vim scp://user@host//subdir1/subdir2/somefile
<

==============================================================================
4. Network-Oriented File Transfer			*netrw-xfer* {{{1

Network-oriented file transfer under Vim is implemented by a VimL-based script
(<netrw.vim>) using plugin techniques.  It currently supports both reading and
writing across networks using rcp, scp, ftp or ftp+<.netrc>, scp, fetch,
dav/cadaver, rsync, or sftp.

http is currently supported read-only via use of wget or fetch.

<netrw.vim> is a standard plugin which acts as glue between Vim and the
various file transfer programs.  It uses autocommand events (BufReadCmd,
FileReadCmd, BufWriteCmd) to intercept reads/writes with url-like filenames. >

	ex. vim ftp://hostname/path/to/file
<
The characters preceding the colon specify the protocol to use; in the
example, it's ftp.  The <netrw.vim> script then formulates a command or a
series of commands (typically ftp) which it issues to an external program
(ftp, scp, etc) which does the actual file transfer/protocol.  Files are read
from/written to a temporary file (under Unix/Linux, /tmp/...) which the
<netrw.vim> script will clean up.

Now, a word about Jan Minář's "FTP User Name and Password Disclosure"; first,
ftp is not a secure protocol.  User names and passwords are transmitted "in
the clear" over the internet; any snooper tool can pick these up; this is not
a netrw thing, this is a ftp thing.  If you're concerned about this, please
try to use scp or sftp instead.

Netrw re-uses the user id and password during the same vim session and so long
as the remote hostname remains the same.

Jan seems to be a bit confused about how netrw handles ftp; normally multiple
commands are performed in a "ftp session", and he seems to feel that the
uid/password should only be retained over one ftp session.  However, netrw
does every ftp operation in a separate "ftp session"; so remembering the
uid/password for just one "ftp session" would be the same as not remembering
the uid/password at all.  IMHO this would rapidly grow tiresome as one
browsed remote directories, for example.

On the other hand, thanks go to Jan M. for pointing out the many
vulnerabilities that netrw (and vim itself) had had in handling "crafted"
filenames.  The |shellescape()| and |fnameescape()| functions were written in
response by Bram Moolenaar to handle these sort of problems, and netrw has
been modified to use them.  Still, my advice is, if the "filename" looks like
a vim command that you aren't comfortable with having executed, don't open it.

				*netrw-putty* *netrw-pscp* *netrw-psftp*
One may modify any protocol's implementing external application by setting a
variable (ex. scp uses the variable g:netrw_scp_cmd, which is defaulted to
"scp -q").  As an example, consider using PuTTY: >

	let g:netrw_scp_cmd = '"c:\Program Files\PuTTY\pscp.exe" -q -batch'
	let g:netrw_sftp_cmd= '"c:\Program Files\PuTTY\psftp.exe"'
<
(note: it has been reported that windows 7 with putty v0.6's "-batch" option
       doesn't work, so its best to leave it off for that system)

See |netrw-p8| for more about putty, pscp, psftp, etc.

Ftp, an old protocol, seems to be blessed by numerous implementations.
Unfortunately, some implementations are noisy (ie., add junk to the end of the
file).  Thus, concerned users may decide to write a NetReadFixup() function
that will clean up after reading with their ftp.  Some Unix systems (ie.,
FreeBSD) provide a utility called "fetch" which uses the ftp protocol but is
not noisy and more convenient, actually, for <netrw.vim> to use.
Consequently, if "fetch" is available (ie. executable), it may be preferable
to use it for ftp://... based transfers.

For rcp, scp, sftp, and http, one may use network-oriented file transfers
transparently; ie.
>
	vim rcp://[user@]machine/path
	vim scp://[user@]machine/path
<
If your ftp supports <.netrc>, then it too can be transparently used
if the needed triad of machine name, user id, and password are present in
that file.  Your ftp must be able to use the <.netrc> file on its own, however.
>
	vim ftp://[user@]machine[[:#]portnumber]/path
<
Windows provides an ftp (typically c:\Windows\System32\ftp.exe) which uses
an option, -s:filename (filename can and probably should be a full path)
which contains ftp commands which will be automatically run whenever ftp
starts.  You may use this feature to enter a user and password for one site: >
	userid
	password
<				*netrw-windows-netrc*  *netrw-windows-s*
If |g:netrw_ftp_cmd| contains -s:[path/]MACHINE, then (on Windows machines
only) netrw will substitute the current machine name requested for ftp
connections for MACHINE.  Hence one can have multiple machine.ftp files
containing login and password for ftp.  Example: >

    let g:netrw_ftp_cmd= 'c:\Windows\System32\ftp -s:C:\Users\Myself\MACHINE'
    vim ftp://myhost.somewhere.net/

will use a file >

	C:\Users\Myself\myhost.ftp
<
Often, ftp will need to query the user for the userid and password.
The latter will be done "silently"; ie. asterisks will show up instead of
the actually-typed-in password.  Netrw will retain the userid and password
for subsequent read/writes from the most recent transfer so subsequent
transfers (read/write) to or from that machine will take place without
additional prompting.

								*netrw-urls*
  +=================================+============================+============+
  |  Reading                        | Writing                    |  Uses      |
  +=================================+============================+============+
  | DAV:                            |                            |            |
  |  dav://host/path                |                            | cadaver    |
  |  :Nread dav://host/path         | :Nwrite dav://host/path    | cadaver    |
  +---------------------------------+----------------------------+------------+
  | DAV + SSL:                      |                            |            |
  |  davs://host/path               |                            | cadaver    |
  |  :Nread davs://host/path        | :Nwrite davs://host/path   | cadaver    |
  +---------------------------------+----------------------------+------------+
  | FETCH:                          |                            |            |
  |  fetch://[user@]host/path       |                            |            |
  |  fetch://[user@]host:http/path  |  Not Available             | fetch      |
  |  :Nread fetch://[user@]host/path|                            |            |
  +---------------------------------+----------------------------+------------+
  | FILE:                           |                            |            |
  |  file:///*                      | file:///*                  |            |
  |  file://localhost/*             | file://localhost/*         |            |
  +---------------------------------+----------------------------+------------+
  | FTP:          (*3)              |              (*3)          |            |
  |  ftp://[user@]host/path         | ftp://[user@]host/path     | ftp  (*2)  |
  |  :Nread ftp://host/path         | :Nwrite ftp://host/path    | ftp+.netrc |
  |  :Nread host path               | :Nwrite host path          | ftp+.netrc |
  |  :Nread host uid pass path      | :Nwrite host uid pass path | ftp        |
  +---------------------------------+----------------------------+------------+
  | HTTP: wget is executable: (*4)  |                            |            |
  |  http://[user@]host/path        |        Not Available       | wget       |
  +---------------------------------+----------------------------+------------+
  | HTTP: fetch is executable (*4)  |                            |            |
  |  http://[user@]host/path        |        Not Available       | fetch      |
  +---------------------------------+----------------------------+------------+
  | RCP:                            |                            |            |
  |  rcp://[user@]host/path         | rcp://[user@]host/path     | rcp        |
  +---------------------------------+----------------------------+------------+
  | RSYNC:                          |                            |            |
  |  rsync://[user@]host/path       | rsync://[user@]host/path   | rsync      |
  |  :Nread rsync://host/path       | :Nwrite rsync://host/path  | rsync      |
  |  :Nread rcp://host/path         | :Nwrite rcp://host/path    | rcp        |
  +---------------------------------+----------------------------+------------+
  | SCP:                            |                            |            |
  |  scp://[user@]host/path         | scp://[user@]host/path     | scp        |
  |  :Nread scp://host/path         | :Nwrite scp://host/path    | scp  (*1)  |
  +---------------------------------+----------------------------+------------+
  | SFTP:                           |                            |            |
  |  sftp://[user@]host/path        | sftp://[user@]host/path    | sftp       |
  |  :Nread sftp://host/path        | :Nwrite sftp://host/path   | sftp  (*1) |
  +=================================+============================+============+

	(*1) For an absolute path use scp://machine//path.

	(*2) if <.netrc> is present, it is assumed that it will
	work with your ftp client.  Otherwise the script will
	prompt for user-id and password.

        (*3) for ftp, "machine" may be machine#port or machine:port
	if a different port is needed than the standard ftp port

	(*4) for http:..., if wget is available it will be used.  Otherwise,
	if fetch is available it will be used.

Both the :Nread and the :Nwrite ex-commands can accept multiple filenames.


NETRC							*netrw-netrc*

The <.netrc> file, typically located in your home directory, contains lines
therein which map a hostname (machine name) to the user id and password you
prefer to use with it.

The typical syntax for lines in a <.netrc> file is given as shown below.
Ftp under Unix usually supports <.netrc>; ftp under Windows usually doesn't.
>
	machine {full machine name} login {user-id} password "{password}"
	default login {user-id} password "{password}"

Your ftp client must handle the use of <.netrc> on its own, but if the
<.netrc> file exists, an ftp transfer will not ask for the user-id or
password.

	Note:
	Since this file contains passwords, make very sure nobody else can
	read this file!  Most programs will refuse to use a .netrc that is
	readable for others.  Don't forget that the system administrator can
	still read the file!  Ie. for Linux/Unix: chmod 600 .netrc

Even though Windows' ftp clients typically do not support .netrc, netrw has
a work-around: see |netrw-windows-s|.


PASSWORD						*netrw-passwd*

The script attempts to get passwords for ftp invisibly using |inputsecret()|,
a built-in Vim function.  See |netrw-userpass| for how to change the password
after one has set it.

Unfortunately there doesn't appear to be a way for netrw to feed a password to
scp.  Thus every transfer via scp will require re-entry of the password.
However, |netrw-ssh-hack| can help with this problem.


==============================================================================
5. Activation						*netrw-activate* {{{1

Network-oriented file transfers are available by default whenever Vim's
|'nocompatible'| mode is enabled.  Netrw's script files reside in your
system's plugin, autoload, and syntax directories; just the
plugin/netrwPlugin.vim script is sourced automatically whenever you bring up
vim.  The main script in autoload/netrw.vim is only loaded when you actually
use netrw.  I suggest that, at a minimum, you have at least the following in
your <.vimrc> customization file: >

	set nocp
	if version >= 600
	  filetype plugin indent on
	endif
<
By also including the following lines in your .vimrc, one may have netrw
immediately activate when using [g]vim without any filenames, showing the
current directory: >

	" Augroup VimStartup:
	augroup VimStartup
	  au!
	  au VimEnter * if expand("%") == "" | e . | endif
	augroup END
<

==============================================================================
6. Transparent Remote File Editing		*netrw-transparent* {{{1

Transparent file transfers occur whenever a regular file read or write
(invoked via an |:autocmd| for |BufReadCmd|, |BufWriteCmd|, or |SourceCmd|
events) is made.  Thus one may read, write, or source  files across networks
just as easily as if they were local files! >

	vim ftp://[user@]machine/path
	...
	:wq

See |netrw-activate| for more on how to encourage your vim to use plugins
such as netrw.


==============================================================================
7. Ex Commands						*netrw-ex* {{{1

The usual read/write commands are supported.  There are also a few
additional commands available.  Often you won't need to use Nwrite or
Nread as shown in |netrw-transparent| (ie. simply use >
  :e url
  :r url
  :w url
instead, as appropriate) -- see |netrw-urls|.  In the explanations
below, a {netfile} is an url to a remote file.

						*:Nwrite*  *:Nw*
:[range]Nw[rite]	Write the specified lines to the current
		file as specified in b:netrw_lastfile.
		(related: |netrw-nwrite|)

:[range]Nw[rite] {netfile} [{netfile}]...
		Write the specified lines to the {netfile}.

						*:Nread*   *:Nr*
:Nr[ead]	Read the lines from the file specified in b:netrw_lastfile
		into the current buffer.  (related: |netrw-nread|)

:Nr[ead] {netfile} {netfile}...
		Read the {netfile} after the current line.

						*:Nsource* *:Ns*
:Ns[ource] {netfile}
		Source the {netfile}.
		To start up vim using a remote .vimrc, one may use
		the following (all on one line) (tnx to Antoine Mechelynck) >
		vim -u NORC -N
		 --cmd "runtime plugin/netrwPlugin.vim"
		 --cmd "source scp://HOSTNAME/.vimrc"
<		 (related: |netrw-source|)

:call NetUserPass()				*NetUserPass()*
		If g:netrw_uid and s:netrw_passwd don't exist,
		this function will query the user for them.
		(related: |netrw-userpass|)

:call NetUserPass("userid")
		This call will set the g:netrw_uid and, if
		the password doesn't exist, will query the user for it.
		(related: |netrw-userpass|)

:call NetUserPass("userid","passwd")
		This call will set both the g:netrw_uid and s:netrw_passwd.
		The user-id and password are used by ftp transfers.  One may
		effectively remove the user-id and password by using empty
		strings (ie. "").
		(related: |netrw-userpass|)

:NetrwSettings  This command is described in |netrw-settings| -- used to
                display netrw settings and change netrw behavior.


==============================================================================
8. Variables and Options		*netrw-var* *netrw-settings* {{{1

(also see: |netrw-options| |netrw-variables| |netrw-protocol|
           |netrw-browser-settings| |netrw-browser-options| )

The <netrw.vim> script provides several variables which act as options to
affect <netrw.vim>'s file transfer behavior.  These variables typically may be
set in the user's <.vimrc> file: (see also |netrw-settings| |netrw-protocol|)
						*netrw-options*
>
                        -------------
                        Netrw Options
                        -------------
	Option			Meaning
	--------------		-----------------------------------------------
<
        b:netrw_col             Holds current cursor position (during NetWrite)
        g:netrw_cygwin          =1 assume scp under windows is from cygwin
                                                              (default/windows)
                                =0 assume scp under windows accepts windows
                                   style paths                (default/else)
        g:netrw_ftp             =0 use default ftp            (uid password)
        g:netrw_ftpmode         ="binary"                     (default)
                                ="ascii"                      (your choice)
	g:netrw_ignorenetrc     =1                            (default)
	                           if you have a <.netrc> file but you don't
				   want it used, then set this variable.  Its
				   mere existence is enough to cause <.netrc>
				   to be ignored.
        b:netrw_lastfile        Holds latest method/machine/path.
        b:netrw_line            Holds current line number     (during NetWrite)
	g:netrw_silent          =0 transfers done normally
	                        =1 transfers done silently
        g:netrw_uid             Holds current user-id for ftp.
        g:netrw_use_nt_rcp      =0 don't use WinNT/2K/XP's rcp (default)
                                =1 use WinNT/2K/XP's rcp, binary mode
        g:netrw_win95ftp        =0 use unix-style ftp even if win95/98/ME/etc
                                =1 use default method to do ftp >
	-----------------------------------------------------------------------
<
						*netrw-internal-variables*
The script will also make use of the following variables internally, albeit
temporarily.
>
			     -------------------
			     Temporary Variables
			     -------------------
	Variable		Meaning
	--------		------------------------------------
<
	b:netrw_method		Index indicating rcp/ftp+.netrc/ftp
	w:netrw_method		(same as b:netrw_method)
	g:netrw_machine		Holds machine name parsed from input
	b:netrw_fname		Holds filename being accessed >
	------------------------------------------------------------
<
							*netrw-protocol*

Netrw supports a number of protocols.  These protocols are invoked using the
variables listed below, and may be modified by the user.
>
			   ------------------------
                           Protocol Control Options
			   ------------------------
    Option            Type        Setting         Meaning
    ---------         --------    --------------  ---------------------------
<    netrw_ftp         variable    =doesn't exist  userid set by "user userid"
                                  =0              userid set by "user userid"
                                  =1              userid set by "userid"
    NetReadFixup      function    =doesn't exist  no change
                                  =exists         Allows user to have files
                                                  read via ftp automatically
                                                  transformed however they wish
                                                  by NetReadFixup()
    g:netrw_dav_cmd      var   ="cadaver"      if cadaver  is executable
    g:netrw_dav_cmd      var   ="curl -o"      elseif curl is executable
    g:netrw_fetch_cmd    var   ="fetch -o"     if fetch is available
    g:netrw_ftp_cmd      var   ="ftp"
    g:netrw_http_cmd     var   ="fetch -o"     if      fetch is available
    g:netrw_http_cmd     var   ="wget -O"      else if wget  is available
    g:netrw_http_put_cmd var   ="curl -T"
    |g:netrw_list_cmd|    var   ="ssh USEPORT HOSTNAME ls -Fa"
    g:netrw_rcp_cmd      var   ="rcp"
    g:netrw_rsync_cmd    var   ="rsync -a"
    g:netrw_scp_cmd      var   ="scp -q"
    g:netrw_sftp_cmd     var   ="sftp" >
    -------------------------------------------------------------------------
<
								*netrw-ftp*

The g:netrw_..._cmd options (|g:netrw_ftp_cmd| and |g:netrw_sftp_cmd|)
specify the external program to use handle the ftp protocol.  They may
include command line options (such as -p for passive mode). Example: >

	let g:netrw_ftp_cmd= "ftp -p"
<
Browsing is supported by using the |g:netrw_list_cmd|; the substring
"HOSTNAME" will be changed via substitution with whatever the current request
is for a hostname.

Two options (|g:netrw_ftp| and |netrw-fixup|) both help with certain ftp's
that give trouble .  In order to best understand how to use these options if
ftp is giving you troubles, a bit of discussion is provided on how netrw does
ftp reads.

For ftp, netrw typically builds up lines of one of the following formats in a
temporary file:
>
  IF g:netrw_ftp !exists or is not 1     IF g:netrw_ftp exists and is 1
  ----------------------------------     ------------------------------
<
       open machine [port]                    open machine [port]
       user userid password                   userid password
       [g:netrw_ftpmode]                      password
       [g:netrw_ftpextracmd]                  [g:netrw_ftpmode]
       get filename tempfile                  [g:netrw_extracmd]
                                              get filename tempfile >
  ---------------------------------------------------------------------
<
The |g:netrw_ftpmode| and |g:netrw_ftpextracmd| are optional.

Netrw then executes the lines above by use of a filter:
>
	:%! {g:netrw_ftp_cmd} -i [-n]
<
where
	g:netrw_ftp_cmd is usually "ftp",
	-i tells ftp not to be interactive
	-n means don't use netrc and is used for Method #3 (ftp w/o <.netrc>)

If <.netrc> exists it will be used to avoid having to query the user for
userid and password.  The transferred file is put into a temporary file.
The temporary file is then read into the main editing session window that
requested it and the temporary file deleted.

If your ftp doesn't accept the "user" command and immediately just demands a
userid, then try putting "let netrw_ftp=1" in your <.vimrc>.

								*netrw-cadaver*
To handle the SSL certificate dialog for untrusted servers, one may pull
down the certificate and place it into /usr/ssl/cert.pem.  This operation
renders the server treatment as "trusted".

						*netrw-fixup* *netreadfixup*
If your ftp for whatever reason generates unwanted lines (such as AUTH
messages) you may write a NetReadFixup() function:
>
    function! NetReadFixup(method,line1,line2)
      " a:line1: first new line in current file
      " a:line2: last  new line in current file
      if     a:method == 1 "rcp
      elseif a:method == 2 "ftp + <.netrc>
      elseif a:method == 3 "ftp + machine,uid,password,filename
      elseif a:method == 4 "scp
      elseif a:method == 5 "http/wget
      elseif a:method == 6 "dav/cadaver
      elseif a:method == 7 "rsync
      elseif a:method == 8 "fetch
      elseif a:method == 9 "sftp
      else               " complain
      endif
    endfunction
>
The NetReadFixup() function will be called if it exists and thus allows you to
customize your reading process.  As a further example, <netrw.vim> contains
just such a function to handle Windows 95 ftp.  For whatever reason, Windows
95's ftp dumps four blank lines at the end of a transfer, and so it is
desirable to automate their removal.  Here's some code taken from <netrw.vim>
itself:
>
    if has("win95") && g:netrw_win95ftp
     fun! NetReadFixup(method, line1, line2)
       if method == 3   " ftp (no <.netrc>)
        let fourblanklines= line2 - 3
        silent fourblanklines.",".line2."g/^\s*/d"
       endif
     endfunction
    endif
>
(Related topics: |ftp| |netrw-userpass| |netrw-start|)

==============================================================================
9. Browsing		*netrw-browsing* *netrw-browse* *netrw-help* {{{1
			*netrw-browser*  *netrw-dir*    *netrw-list*

INTRODUCTION TO BROWSING			*netrw-intro-browse* {{{2
	(Quick References: |netrw-quickmaps| |netrw-quickcoms|)

Netrw supports the browsing of directories on your local system and on remote
hosts; browsing includes listing files and directories, entering directories,
editing files therein, deleting files/directories, making new directories,
moving (renaming) files and directories, copying files and directories, etc.
One may mark files and execute any system command on them!  The Netrw browser
generally implements the previous explorer's maps and commands for remote
directories, although details (such as pertinent global variable names)
necessarily differ.  To browse a directory, simply "edit" it! >

	vim /your/directory/
	vim .
	vim c:\your\directory\
<
(Related topics: |netrw-cr|  |netrw-o|  |netrw-p| |netrw-P| |netrw-t|
                 |netrw-mf|  |netrw-mx| |netrw-D| |netrw-R| |netrw-v| )

The Netrw remote file and directory browser handles two protocols: ssh and
ftp.  The protocol in the url, if it is ftp, will cause netrw also to use ftp
in its remote browsing.  Specifying any other protocol will cause it to be
used for file transfers; but the ssh protocol will be used to do remote
browsing.

To use Netrw's remote directory browser, simply attempt to read a "file" with
a trailing slash and it will be interpreted as a request to list a directory:
>
	vim [protocol]://[user@]hostname/path/
<
where [protocol] is typically scp or ftp.  As an example, try: >

	vim ftp://ftp.home.vim.org/pub/vim/
<
For local directories, the trailing slash is not required.  Again, because it's
easy to miss: to browse remote directories, the url must terminate with a
slash!

If you'd like to avoid entering the password repeatedly for remote directory
listings with ssh or scp, see |netrw-ssh-hack|.  To avoid password entry with
ftp, see |netrw-netrc| (if your ftp supports it).

There are several things you can do to affect the browser's display of files:

	* To change the listing style, press the "i" key (|netrw-i|).
	  Currently there are four styles: thin, long, wide, and tree.
	  To make that change "permanent", see |g:netrw_liststyle|.

	* To hide files (don't want to see those xyz~ files anymore?) see
	  |netrw-ctrl-h|.

	* Press s to sort files by name, time, or size.

See |netrw-browse-cmds| for all the things you can do with netrw!

			*netrw-getftype* *netrw-filigree* *netrw-ftype*
The |getftype()| function is used to append a bit of filigree to indicate
filetype to locally listed files:

	directory  : /
	executable : *
	fifo       : |
	links      : @
	sockets    : =

The filigree also affects the |g:netrw_sort_sequence|.


QUICK HELP						*netrw-quickhelp* {{{2
                       (Use ctrl-] to select a topic)~
	Intro to Browsing...............................|netrw-intro-browse|
	  Quick Reference: Maps.........................|netrw-quickmap|
	  Quick Reference: Commands.....................|netrw-browse-cmds|
	Hiding
	  Edit hiding list..............................|netrw-ctrl-h|
	  Hiding Files or Directories...................|netrw-a|
	  Hiding/Unhiding by suffix.....................|netrw-mh|
	  Hiding  dot-files.............................|netrw-gh|
	Listing Style
	  Select listing style (thin/long/wide/tree)....|netrw-i|
	  Associated setting variable...................|g:netrw_liststyle|
	  Shell command used to perform listing.........|g:netrw_list_cmd|
	  Quick file info...............................|netrw-qf|
	Sorted by
	  Select sorting style (name/time/size).........|netrw-s|
	  Editing the sorting sequence..................|netrw-S|
	  Sorting options...............................|g:netrw_sort_options|
	  Associated setting variable...................|g:netrw_sort_sequence|
	  Reverse sorting order.........................|netrw-r|


				*netrw-quickmap* *netrw-quickmaps*
QUICK REFERENCE: MAPS				*netrw-browse-maps* {{{2
>
	  ---			-----------------			----
	  Map			Quick Explanation			Link
	  ---			-----------------			----
<	 <F1>	Causes Netrw to issue help
	 <cr>	Netrw will enter the directory or read the file      |netrw-cr|
	 <del>	Netrw will attempt to remove the file/directory      |netrw-del|
	 <c-h>	Edit file hiding list                                |netrw-ctrl-h|
	 <c-l>	Causes Netrw to refresh the directory listing        |netrw-ctrl-l|
	 <c-r>	Browse using a gvim server                           |netrw-ctrl-r|
	 <tab>	Shrink/expand a netrw/explore window                 |netrw-tab|
	   -	Makes Netrw go up one directory                      |netrw--|
	   a	Toggles between normal display,                      |netrw-a|
	    	hiding (suppress display of files matching g:netrw_list_hide)
	    	showing (display only files which match g:netrw_list_hide)
	   c	Make browsing directory the current directory        |netrw-c|
	   C	Setting the editing window                           |netrw-C|
	   d	Make a directory                                     |netrw-d|
	   D	Attempt to remove the file(s)/directory(ies)         |netrw-D|
	   gb	Go to previous bookmarked directory                  |netrw-gb|
	   gd	Force treatment as directory                         |netrw-gd|
	   gf	Force treatment as file                              |netrw-gf|
	   gh	Quick hide/unhide of dot-files                       |netrw-gh|
	   gn	Make top of tree the directory below the cursor      |netrw-gn|
	   i	Cycle between thin, long, wide, and tree listings    |netrw-i|
	   mb	Bookmark current directory                           |netrw-mb|
	   mc	Copy marked files to marked-file target directory    |netrw-mc|
	   md	Apply diff to marked files (up to 3)                 |netrw-md|
	   me	Place marked files on arg list and edit them         |netrw-me|
	   mf	Mark a file                                          |netrw-mf|
	   mF	Unmark files                                         |netrw-mF|
	   mg	Apply vimgrep to marked files                        |netrw-mg|
	   mh	Toggle marked file suffices' presence on hiding list |netrw-mh|
	   mm	Move marked files to marked-file target directory    |netrw-mm|
	   mp	Print marked files                                   |netrw-mp|
	   mr	Mark files using a shell-style |regexp|                |netrw-mr|
	   mt	Current browsing directory becomes markfile target   |netrw-mt|
	   mT	Apply ctags to marked files                          |netrw-mT|
	   mu	Unmark all marked files                              |netrw-mu|
	   mv	Apply arbitrary vim   command to marked files        |netrw-mv|
	   mx	Apply arbitrary shell command to marked files        |netrw-mx|
	   mX	Apply arbitrary shell command to marked files en bloc|netrw-mX|
	   mz	Compress/decompress marked files                     |netrw-mz|
	   o	Enter the file/directory under the cursor in a new   |netrw-o|
	    	browser window.  A horizontal split is used.
	   O	Obtain a file specified by cursor                    |netrw-O|
	   p	Preview the file                                     |netrw-p|
	   P	Browse in the previously used window                 |netrw-P|
	   qb	List bookmarked directories and history              |netrw-qb|
	   qf	Display information on file                          |netrw-qf|
	   qF	Mark files using a quickfix list                     |netrw-qF|
	   r	Reverse sorting order                                |netrw-r|
	   R	Rename the designated file(s)/directory(ies)         |netrw-R|
	   s	Select sorting style: by name, time, or file size    |netrw-s|
	   S	Specify suffix priority for name-sorting             |netrw-S|
	   t	Enter the file/directory under the cursor in a new tab|netrw-t|
	   u	Change to recently-visited directory                 |netrw-u|
	   U	Change to subsequently-visited directory             |netrw-U|
	   v	Enter the file/directory under the cursor in a new   |netrw-v|
	    	browser window.  A vertical split is used.
	   x	View file with an associated program                 |netrw-x|
	   X	Execute filename under cursor via |system()|           |netrw-X|

	   %	Open a new file in netrw's current directory         |netrw-%|

	*netrw-mouse* *netrw-leftmouse* *netrw-middlemouse* *netrw-rightmouse*
	<leftmouse>	(gvim only) selects word under mouse as if a <cr>
			had been pressed (ie. edit file, change directory)
	<middlemouse>	(gvim only) same as P selecting word under mouse;
			see |netrw-P|
	<rightmouse>	(gvim only) delete file/directory using word under
			mouse
	<2-leftmouse>	(gvim only) when:
			 * in a netrw-selected file, AND
			 * |g:netrw_retmap| == 1       AND
			 * the user doesn't already have a <2-leftmouse>
			   mapping defined before netrw is autoloaded,
			then a double clicked leftmouse button will return
			to the netrw browser window.  See |g:netrw_retmap|.
	<s-leftmouse>	(gvim only) like mf, will mark files.  Dragging
			the shifted leftmouse will mark multiple files.
			(see |netrw-mf|)

	(to disable mouse buttons while browsing: |g:netrw_mousemaps|)

				*netrw-quickcom* *netrw-quickcoms*
QUICK REFERENCE: COMMANDS	*netrw-explore-cmds* *netrw-browse-cmds* {{{2
     :NetrwClean[!]............................................|netrw-clean|
     :NetrwSettings............................................|netrw-settings|
     :Ntree....................................................|netrw-ntree|
     :Explore[!]  [dir] Explore directory of current file......|netrw-explore|
     :Hexplore[!] [dir] Horizontal Split & Explore.............|netrw-explore|
     :Lexplore[!] [dir] Left Explorer Toggle...................|netrw-explore|
     :Nexplore[!] [dir] Vertical Split & Explore...............|netrw-explore|
     :Pexplore[!] [dir] Vertical Split & Explore...............|netrw-explore|
     :Rexplore          Return to Explorer.....................|netrw-explore|
     :Sexplore[!] [dir] Split & Explore directory .............|netrw-explore|
     :Texplore[!] [dir] Tab & Explore..........................|netrw-explore|
     :Vexplore[!] [dir] Vertical Split & Explore...............|netrw-explore|

BOOKMARKING A DIRECTORY *netrw-mb* *netrw-bookmark* *netrw-bookmarks* {{{2

One may easily "bookmark" the currently browsed directory by using >

	mb
<
								*.netrwbook*
Bookmarks are retained in between sessions in a $HOME/.netrwbook file, and are
kept in sorted order.

If there are marked files and/or directories, mb will add them to the bookmark
list.

*netrw-:NetrwMB*
Addtionally, one may use :NetrwMB to bookmark files or directories. >

	:NetrwMB[!] [files/directories]

< No bang: enters files/directories into Netrw's bookmark system

   No argument and in netrw buffer:
     if there are marked files: bookmark marked files
     otherwise                : bookmark file/directory under cursor
   No argument and not in netrw buffer: bookmarks current open file
   Has arguments: globs them individually and bookmarks them

 With bang: deletes files/directories from Netrw's bookmark system

The :NetrwMB command is available outside of netrw buffers (once netrw has been
invoked in the session).

The file ".netrwbook" holds bookmarks when netrw (and vim) is not active.  By
default, its stored on the first directory on the user's |'runtimepath'|.

Related Topics:
	|netrw-gb| how to return (go) to a bookmark
	|netrw-mB| how to delete bookmarks
	|netrw-qb| how to list bookmarks
	|g:netrw_home| controls where .netrwbook is kept


BROWSING						*netrw-cr* {{{2

Browsing is simple: move the cursor onto a file or directory of interest.
Hitting the <cr> (the return key) will select the file or directory.
Directories will themselves be listed, and files will be opened using the
protocol given in the original read request.

  CAVEAT: There are four forms of listing (see |netrw-i|).  Netrw assumes that
  two or more spaces delimit filenames and directory names for the long and
  wide listing formats.  Thus, if your filename or directory name has two or
  more sequential spaces embedded in it, or any trailing spaces, then you'll
  need to use the "thin" format to select it.

The |g:netrw_browse_split| option, which is zero by default, may be used to
cause the opening of files to be done in a new window or tab instead of the
default.  When the option is one or two, the splitting will be taken
horizontally or vertically, respectively.  When the option is set to three, a
<cr> will cause the file to appear in a new tab.


When using the gui (gvim), one may select a file by pressing the <leftmouse>
button.  In addition, if

 * |g:netrw_retmap| == 1       AND   (its default value is 0)
 * in a netrw-selected file, AND
 * the user doesn't already have a <2-leftmouse> mapping defined before
   netrw is loaded

then a doubly-clicked leftmouse button will return to the netrw browser
window.

Netrw attempts to speed up browsing, especially for remote browsing where one
may have to enter passwords, by keeping and re-using previously obtained
directory listing buffers.  The |g:netrw_fastbrowse| variable is used to
control this behavior; one may have slow browsing (no buffer re-use), medium
speed browsing (re-use directory buffer listings only for remote directories),
and fast browsing (re-use directory buffer listings as often as possible).
The price for such re-use is that when changes are made (such as new files
are introduced into a directory), the listing may become out-of-date.  One may
always refresh directory listing buffers by pressing ctrl-L (see
|netrw-ctrl-l|).
								*:netrw-s-cr*
    Squeezing the Current Tree-Listing Directory~
    When the tree listing style is enabled (see |netrw-i|) and one is using
    gvim, then the <s-cr> mapping may be used to squeeze (close) the
    directory currently containing the cursor.

Related topics:
	|netrw-ctrl-r|	|netrw-o|	|netrw-p|
	|netrw-P|	|netrw-t|	|netrw-v|
Associated setting variables:
   |g:netrw_browse_split|	|g:netrw_fastbrowse|
   |g:netrw_ftp_list_cmd|	|g:netrw_ftp_sizelist_cmd|
   |g:netrw_ftp_timelist_cmd|	|g:netrw_ssh_browse_reject|
   |g:netrw_ssh_cmd|		|g:netrw_use_noswf|


BROWSING WITH A HORIZONTALLY SPLIT WINDOW	*netrw-o* *netrw-horiz* {{{2

Normally one enters a file or directory using the <cr>.  However, the "o" map
allows one to open a new window to hold the new directory listing or file.  A
horizontal split is used.  (for vertical splitting, see |netrw-v|)

Normally, the o key splits the window horizontally with the new window and
cursor at the top.

Associated setting variables: |g:netrw_alto| |g:netrw_winsize|

Related topics:
	|netrw-ctrl-r|	|netrw-o|	|netrw-p|
	|netrw-P|	|netrw-t|	|netrw-v|
Associated setting variables:
   |g:netrw_alto|    control above/below splitting
   |g:netrw_winsize| control initial sizing

BROWSING WITH A NEW TAB				*netrw-t* {{{2

Normally one enters a file or directory using the <cr>.  The "t" map
allows one to open a new window holding the new directory listing or file in
a new tab.

If you'd like to have the new listing in a background tab, use |gT|.

Related topics:
	|netrw-ctrl-r|	|netrw-o|	|netrw-p|
	|netrw-P|	|netrw-t|	|netrw-v|
Associated setting variables:
   |g:netrw_winsize| control initial sizing

BROWSING WITH A VERTICALLY SPLIT WINDOW			*netrw-v* {{{2

Normally one enters a file or directory using the <cr>.  However, the "v" map
allows one to open a new window to hold the new directory listing or file.  A
vertical split is used.  (for horizontal splitting, see |netrw-o|)

Normally, the v key splits the window vertically with the new window and
cursor at the left.

There is only one tree listing buffer; using "v" on a displayed subdirectory
will split the screen, but the same buffer will be shown twice.

Related topics:
	|netrw-ctrl-r|	|netrw-o|	|netrw-p|
	|netrw-P|	|netrw-t|	|netrw-v|
Associated setting variables:
   |g:netrw_altv|    control right/left splitting
   |g:netrw_winsize| control initial sizing


BROWSING USING A GVIM SERVER			*netrw-ctrl-r* {{{2

One may keep a browsing gvim separate from the gvim being used to edit.
Use the <c-r> map on a file (not a directory) in the netrw browser, and it
will use a gvim server (see |g:netrw_servername|).  Subsequent use of <cr>
(see |netrw-cr|) will re-use that server for editing files.

Related topics:
	|netrw-ctrl-r|	|netrw-o|	|netrw-p|
	|netrw-P|	|netrw-t|	|netrw-v|
Associated setting variables:
	|g:netrw_servername|   : sets name of server
	|g:netrw_browse_split| : controls how <cr> will open files


CHANGE LISTING STYLE  (THIN LONG WIDE TREE)			*netrw-i* {{{2

The "i" map cycles between the thin, long, wide, and tree listing formats.

The thin listing format gives just the files' and directories' names.

The long listing is either based on the "ls" command via ssh for remote
directories or displays the filename, file size (in bytes), and the time and
date of last modification for local directories.  With the long listing
format, netrw is not able to recognize filenames which have trailing spaces.
Use the thin listing format for such files.

The wide listing format uses two or more contiguous spaces to delineate
filenames; when using that format, netrw won't be able to recognize or use
filenames which have two or more contiguous spaces embedded in the name or any
trailing spaces.  The thin listing format will, however, work with such files.
The wide listing format is the most compact.

The tree listing format has a top directory followed by files and directories
preceded by one or more "|"s, which indicate the directory depth.  One may
open and close directories by pressing the <cr> key while atop the directory
name.

One may make a preferred listing style your default; see |g:netrw_liststyle|.
As an example, by putting the following line in your .vimrc, >
	let g:netrw_liststyle= 3
the tree style will become your default listing style.

One typical way to use the netrw tree display is to: >

	vim .
	(use i until a tree display shows)
	navigate to a file
	v  (edit as desired in vertically split window)
	ctrl-w h  (to return to the netrw listing)
	P (edit newly selected file in the previous window)
	ctrl-w h  (to return to the netrw listing)
	P (edit newly selected file in the previous window)
	...etc...
<
Associated setting variables: |g:netrw_liststyle| |g:netrw_maxfilenamelen|
                              |g:netrw_timefmt|   |g:netrw_list_cmd|

CHANGE FILE PERMISSION						*netrw-gp* {{{2

"gp" will ask you for a new permission for the file named under the cursor.
Currently, this only works for local files.

Associated setting variables: |g:netrw_chgperm|


CHANGING TO A BOOKMARKED DIRECTORY			*netrw-gb*  {{{2

To change directory back to a bookmarked directory, use

	{cnt}gb

Any count may be used to reference any of the bookmarks.
Note that |netrw-qb| shows both bookmarks and history; to go
to a location stored in the history see |netrw-u| and |netrw-U|.

Related Topics:
	|netrw-mB| how to delete bookmarks
	|netrw-mb| how to make a bookmark
	|netrw-qb| how to list bookmarks


CHANGING TO A PREDECESSOR DIRECTORY		*netrw-u* *netrw-updir* {{{2

Every time you change to a new directory (new for the current session),
netrw will save the directory in a recently-visited directory history
list (unless |g:netrw_dirhistmax| is zero; by default, it's ten).  With the
"u" map, one can change to an earlier directory (predecessor).  To do
the opposite, see |netrw-U|.

The "u" map also accepts counts to go back in the history several slots.
For your convenience, qb (see |netrw-qb|) lists the history number which may
be used in that count.

						*.netrwhist*
See |g:netrw_dirhistmax| for how to control the quantity of history stack
slots.  The file ".netrwhist" holds history when netrw (and vim) is not
active.  By default, its stored on the first directory on the user's
|'runtimepath'|.

Related Topics:
	|netrw-U| changing to a successor directory
	|g:netrw_home| controls where .netrwhist is kept


CHANGING TO A SUCCESSOR DIRECTORY		*netrw-U* *netrw-downdir* {{{2

With the "U" map, one can change to a later directory (successor).
This map is the opposite of the "u" map. (see |netrw-u|)  Use the
qb map to list both the bookmarks and history. (see |netrw-qb|)

The "U" map also accepts counts to go forward in the history several slots.

See |g:netrw_dirhistmax| for how to control the quantity of history stack
slots.


CHANGING TREE TOP			*netrw-ntree*  *:Ntree*  *netrw-gn* {{{2

One may specify a new tree top for tree listings using >

	:Ntree [dirname]

Without a "dirname", the current line is used (and any leading depth
information is elided).
With a "dirname", the specified directory name is used.

The "gn" map will take the word below the cursor and use that for
changing the top of the tree listing.


NETRW CLEAN					*netrw-clean* *:NetrwClean* {{{2

With NetrwClean one may easily remove netrw from one's home directory;
more precisely, from the first directory on your |'runtimepath'|.

With NetrwClean!, netrw will attempt to remove netrw from all directories on
your |'runtimepath'|.  Of course, you have to have write/delete permissions
correct to do this.

With either form of the command, netrw will first ask for confirmation
that the removal is in fact what you want to do.  If netrw doesn't have
permission to remove a file, it will issue an error message.

						*netrw-gx*
CUSTOMIZING BROWSING WITH A SPECIAL HANDLER	*netrw-x* *netrw-handler* {{{2
						(also see |netrw_filehandler|)

Certain files, such as html, gif, jpeg, (word/office) doc, etc, files, are
best seen with a special handler (ie. a tool provided with your computer's
operating system).  Netrw allows one to invoke such special handlers by: >

	* when Exploring, hit the "x" key
	* when editing, hit gx with the cursor atop the special filename
<	  (latter not available if the |g:netrw_nogx| variable exists)

Netrw determines which special handler by the following method:

  * if |g:netrw_browsex_viewer| exists, then it will be used to attempt to
    view files.  Examples of useful settings (place into your <.vimrc>): >

	:let g:netrw_browsex_viewer= "kfmclient exec"
<   or >
	:let g:netrw_browsex_viewer= "xdg-open"
<
    If g:netrw_browsex_viewer == '-', then netrwFileHandlers#Invoke() will be
    used instead (see |netrw_filehandler|).

  * for Windows 32 or 64, the url and FileProtocolHandler dlls are used.
  * for Gnome (with gnome-open): gnome-open is used.
  * for KDE (with kfmclient)   : kfmclient is used
  * for Mac OS X               : open is used.
  * otherwise the netrwFileHandler plugin is used.

The file's suffix is used by these various approaches to determine an
appropriate application to use to "handle" these files.  Such things as
OpenOffice (*.sfx), visualization (*.jpg, *.gif, etc), and PostScript (*.ps,
*.eps) can be handled.

The gx mapping extends to all buffers; apply "gx" while atop a word and netrw
will apply a special handler to it (like "x" works when in a netrw buffer).
One may also use visual mode (see |visual-start|) to select the text that the
special handler will use.  Normally gx uses expand("<cfile>") to pick up the
text under the cursor; one may change what |expand()| uses via the
|g:netrw_gx| variable.  Alternatively, one may select the text to be used by
gx via first making a visual selection (see |visual-block|).

Associated setting variables:
	|g:netrw_gx|	control how gx picks up the text under the cursor
	|g:netrw_nogx|	prevent gx map while editing

							*netrw_filehandler*

When |g:netrw_browsex_viewer| exists and is "-", then netrw will attempt to
handle the special file with a vim function.  The "x" map applies a function
to a file, based on its extension.  Of course, the handler function must exist
for it to be called!
>
 Ex. mypgm.html   x -> NFH_html("scp://user@host/some/path/mypgm.html")

<	Users may write their own netrw File Handler functions to
	support more suffixes with special handling.  See
	<autoload/netrwFileHandlers.vim> for examples on how to make
	file handler functions.   As an example: >

	" NFH_suffix(filename)
	fun! NFH_suffix(filename)
	..do something special with filename..
	endfun
<
These functions need to be defined in some file in your .vim/plugin
(vimfiles\plugin) directory.  Vim's function names may not have punctuation
characters (except for the underscore) in them.  To support suffices that
contain such characters, netrw will first convert the suffix using the
following table: >

    @ -> AT       ! -> EXCLAMATION    % -> PERCENT
    : -> COLON    = -> EQUAL          ? -> QUESTION
    , -> COMMA    - -> MINUS          ; -> SEMICOLON
    $ -> DOLLAR   + -> PLUS           ~ -> TILDE
<
So, for example: >

	file.rcs,v  ->  NFH_rcsCOMMAv()
<
If more such translations are necessary, please send me email: >
		NdrOchip at ScampbellPfamily.AbizM - NOSPAM
with a request.

Associated setting variable: |g:netrw_browsex_viewer|

							*netrw-curdir*
DELETING BOOKMARKS					*netrw-mB* {{{2

To delete a bookmark, use >

	{cnt}mB

If there are marked files, then mB will remove them from the
bookmark list.

Alternatively, one may use :NetrwMB! (see |netrw-:NetrwMB|). >

	:NetrwMB! [files/directories]

Related Topics:
	|netrw-gb| how to return (go) to a bookmark
	|netrw-mb| how to make a bookmark
	|netrw-qb| how to list bookmarks


DELETING FILES OR DIRECTORIES	*netrw-delete* *netrw-D* *netrw-del* {{{2

If files have not been marked with |netrw-mf|:   (local marked file list)

    Deleting/removing files and directories involves moving the cursor to the
    file/directory to be deleted and pressing "D".  Directories must be empty
    first before they can be successfully removed.  If the directory is a
    softlink to a directory, then netrw will make two requests to remove the
    directory before succeeding.  Netrw will ask for confirmation before doing
    the removal(s).  You may select a range of lines with the "V" command
    (visual selection), and then pressing "D".

If files have been marked with |netrw-mf|:   (local marked file list)

    Marked files (and empty directories) will be deleted; again, you'll be
    asked to confirm the deletion before it actually takes place.

A further approach is to delete files which match a pattern.

    * use  :MF pattern  (see |netrw-:MF|); then press "D".

    * use mr (see |netrw-mr|) which will prompt you for pattern.
      This will cause the matching files to be marked.  Then,
      press "D".

The |g:netrw_rm_cmd|, |g:netrw_rmf_cmd|, and |g:netrw_rmdir_cmd| variables are
used to control the attempts to remove remote files and directories.  The
g:netrw_rm_cmd is used with files, and its default value is:

	g:netrw_rm_cmd: ssh HOSTNAME rm

The g:netrw_rmdir_cmd variable is used to support the removal of directories.
Its default value is:

	|g:netrw_rmdir_cmd|: ssh HOSTNAME rmdir

If removing a directory fails with g:netrw_rmdir_cmd, netrw then will attempt
to remove it again using the g:netrw_rmf_cmd variable.  Its default value is:

	|g:netrw_rmf_cmd|: ssh HOSTNAME rm -f

Related topics: |netrw-d|
Associated setting variable: |g:netrw_localrmdir| |g:netrw_rm_cmd|
                             |g:netrw_rmdir_cmd|   |g:netrw_ssh_cmd|


*netrw-explore*  *netrw-hexplore* *netrw-nexplore* *netrw-pexplore*
*netrw-rexplore* *netrw-sexplore* *netrw-texplore* *netrw-vexplore* *netrw-lexplore*
DIRECTORY EXPLORATION COMMANDS  {{{2

     :[N]Explore[!]  [dir]... Explore directory of current file      *:Explore*
     :[N]Hexplore[!] [dir]... Horizontal Split & Explore             *:Hexplore*
     :[N]Lexplore[!] [dir]... Left Explorer Toggle                   *:Lexplore*
     :[N]Sexplore[!] [dir]... Split&Explore current file's directory *:Sexplore*
     :[N]Vexplore[!] [dir]... Vertical   Split & Explore             *:Vexplore*
     :Texplore       [dir]... Tab & Explore                          *:Texplore*
     :Rexplore            ... Return to/from Explorer                *:Rexplore*

     Used with :Explore **/pattern : (also see |netrw-starstar|)
     :Nexplore............. go to next matching file                *:Nexplore*
     :Pexplore............. go to previous matching file            *:Pexplore*

						*netrw-:Explore*
:Explore  will open the local-directory browser on the current file's
          directory (or on directory [dir] if specified).  The window will be
	  split only if the file has been modified and |'hidden'| is not set,
	  otherwise the browsing window will take over that window.  Normally
	  the splitting is taken horizontally.
	  Also see: |netrw-:Rexplore|
:Explore! is like :Explore, but will use vertical splitting.

						*netrw-:Hexplore*
:Hexplore  [dir] does an :Explore with |:belowright| horizontal splitting.
:Hexplore! [dir] does an :Explore with |:aboveleft|  horizontal splitting.

						*netrw-:Lexplore*
:[N]Lexplore [dir] toggles a full height Explorer window on the left hand side
	  of the current tab.  It will open a netrw window on the current
	  directory if [dir] is omitted; a :Lexplore [dir] will show the
	  specified directory in the left-hand side browser display no matter
	  from which window the command is issued.

	  By default, :Lexplore will change an uninitialized |g:netrw_chgwin|
	  to 2; edits will thus preferentially be made in window#2.

	  The [N] specifies a |g:netrw_winsize| just for the new :Lexplore
	  window.

	  Those who like this method often also often like tree style displays;
	  see |g:netrw_liststyle|.

	  Also see: |netrw-C|           |g:netrw_browse_split|   |g:netrw_wiw|
		    |netrw-p| |netrw-P|   |g:netrw_chgwin|
		    |netrw-tab|         |g:netrw_winsize|

:[N]Lexplore! is like :Lexplore, except that the full-height Explorer window
	  will open on the right hand side and an uninitialized |g:netrw_chgwin|
	  will be set to 1.

						*netrw-:Sexplore*
:[N]Sexplore will always split the window before invoking the local-directory
	  browser.  As with Explore, the splitting is normally done
	  horizontally.
:[N]Sexplore! [dir] is like :Sexplore, but the splitting will be done vertically.

						*netrw-:Texplore*
:Texplore  [dir] does a |:tabnew| before generating the browser window

						*netrw-:Vexplore*
:[N]Vexplore  [dir] does an :Explore with |:leftabove|  vertical splitting.
:[N]Vexplore! [dir] does an :Explore with |:rightbelow| vertical splitting.

The optional parameters are:

 [N]: This parameter will override |g:netrw_winsize| to specify the quantity of
      rows and/or columns the new explorer window should have.
      Otherwise, the |g:netrw_winsize| variable, if it has been specified by the
      user, is used to control the quantity of rows and/or columns new
      explorer windows should have.

 [dir]: By default, these explorer commands use the current file's directory.
        However, one may explicitly provide a directory (path) to use instead;
	ie. >

	:Explore /some/path
<
						*netrw-:Rexplore*
:Rexplore  This command is a little different from the other Explore commands
	   as it doesn't necessarily open an Explorer window.

	   Return to Explorer~
	   When one edits a file using netrw which can occur, for example,
	   when pressing <cr> while the cursor is atop a filename in a netrw
	   browser window, a :Rexplore issued while editing that file will
	   return the display to that of the last netrw browser display in
	   that window.

	   Return from Explorer~
	   Conversely, when one is editing a directory, issuing a :Rexplore
	   will return to editing the file that was last edited in that
	   window.

	   The <2-leftmouse> map (which is only available under gvim and
	   cooperative terms) does the same as :Rexplore.

Also see: |g:netrw_alto| |g:netrw_altv| |g:netrw_winsize|


*netrw-star* *netrw-starpat* *netrw-starstar* *netrw-starstarpat* *netrw-grep*
EXPLORING WITH STARS AND PATTERNS {{{2

When Explore, Sexplore, Hexplore, or Vexplore are used with one of the
following four patterns Explore generates a list of files which satisfy
the request. >

    */filepat	files in current directory which satisfy filepat
    **/filepat	files in current directory or below which satisfy the
		file pattern
    *//pattern	files in the current directory which contain the
		pattern (vimgrep is used)
    **//pattern	files in the current directory or below which contain
		the pattern (vimgrep is used)
<
The cursor will be placed on the first file in the list.  One may then
continue to go to subsequent files on that list via |:Nexplore| or to
preceding files on that list with |:Pexplore|.  Explore will update the
directory and place the cursor appropriately.

A plain >
	:Explore
will clear the explore list.

If your console or gui produces recognizable shift-up or shift-down sequences,
then you'll likely find using shift-downarrow and shift-uparrow convenient.
They're mapped by netrw as follows:

	<s-down>  == Nexplore, and
	<s-up>    == Pexplore.

As an example, consider
>
	:Explore */*.c
	:Nexplore
	:Nexplore
	:Pexplore
<
The status line will show, on the right hand side of the status line, a
message like "Match 3 of 20".

Associated setting variables:
	|g:netrw_keepdir|          |g:netrw_browse_split|
	|g:netrw_fastbrowse|       |g:netrw_ftp_browse_reject|
	|g:netrw_ftp_list_cmd|     |g:netrw_ftp_sizelist_cmd|
	|g:netrw_ftp_timelist_cmd| |g:netrw_list_cmd|
	|g:netrw_liststyle|


DISPLAYING INFORMATION ABOUT FILE				*netrw-qf* {{{2

With the cursor atop a filename, pressing "qf" will reveal the file's size
and last modification timestamp.  Currently this capability is only available
for local files.


EDIT FILE OR DIRECTORY HIDING LIST	*netrw-ctrl-h* *netrw-edithide* {{{2

The "<ctrl-h>" map brings up a requestor allowing the user to change the
file/directory hiding list contained in |g:netrw_list_hide|.  The hiding list
consists of one or more patterns delimited by commas.  Files and/or
directories satisfying these patterns will either be hidden (ie. not shown) or
be the only ones displayed (see |netrw-a|).

The "gh" mapping (see |netrw-gh|) quickly alternates between the usual
hiding list and the hiding of files or directories that begin with ".".

As an example, >
	let g:netrw_list_hide= '\(^\|\s\s\)\zs\.\S\+'
Effectively, this makes the effect of a |netrw-gh| command the initial setting.
What it means:

	\(^\|\s\s\)   : if the line begins with the following, -or-
	                two consecutive spaces are encountered
	\zs           : start the hiding match now
	\.            : if it now begins with a dot
	\S\+          : and is followed by one or more non-whitespace
	                characters

Associated setting variables: |g:netrw_hide| |g:netrw_list_hide|
Associated topics: |netrw-a| |netrw-gh| |netrw-mh|

					*netrw-sort-sequence*
EDITING THE SORTING SEQUENCE		*netrw-S* *netrw-sortsequence* {{{2

When "Sorted by" is name, one may specify priority via the sorting sequence
(g:netrw_sort_sequence).  The sorting sequence typically prioritizes the
name-listing by suffix, although any pattern will do.  Patterns are delimited
by commas.  The default sorting sequence is (all one line):

For Unix: >
	'[\/]$,\<core\%(\.\d\+\)\=,\.[a-np-z]$,\.h$,\.c$,\.cpp$,*,\.o$,\.obj$,
	\.info$,\.swp$,\.bak$,\~$'
<
Otherwise: >
	'[\/]$,\.[a-np-z]$,\.h$,\.c$,\.cpp$,*,\.o$,\.obj$,\.info$,
	\.swp$,\.bak$,\~$'
<
The lone * is where all filenames not covered by one of the other patterns
will end up.  One may change the sorting sequence by modifying the
g:netrw_sort_sequence variable (either manually or in your <.vimrc>) or by
using the "S" map.

Related topics:               |netrw-s|               |netrw-S|
Associated setting variables: |g:netrw_sort_sequence| |g:netrw_sort_options|


EXECUTING FILE UNDER CURSOR VIA SYSTEM()			*netrw-X* {{{2

Pressing X while the cursor is atop an executable file will yield a prompt
using the filename asking for any arguments.  Upon pressing a [return], netrw
will then call |system()| with that command and arguments.  The result will
be displayed by |:echomsg|, and so |:messages| will repeat display of the
result.  Ansi escape sequences will be stripped out.


FORCING TREATMENT AS A FILE OR DIRECTORY	*netrw-gd* *netrw-gf* {{{2

Remote symbolic links (ie. those listed via ssh or ftp) are problematic
in that it is difficult to tell whether they link to a file or to a
directory.

To force treatment as a file: use >
	gf
<
To force treatment as a directory: use >
	gd
<

GOING UP							*netrw--* {{{2

To go up a directory, press "-" or press the <cr> when atop the ../ directory
entry in the listing.

Netrw will use the command in |g:netrw_list_cmd| to perform the directory
listing operation after changing HOSTNAME to the host specified by the
user-prpvided url.  By default netrw provides the command as: >

	ssh HOSTNAME ls -FLa
<
where the HOSTNAME becomes the [user@]hostname as requested by the attempt to
read.  Naturally, the user may override this command with whatever is
preferred.  The NetList function which implements remote browsing
expects that directories will be flagged by a trailing slash.


HIDING FILES OR DIRECTORIES			*netrw-a* *netrw-hiding* {{{2

Netrw's browsing facility allows one to use the hiding list in one of three
ways: ignore it, hide files which match, and show only those files which
match.

If no files have been marked via |netrw-mf|:

The "a" map allows the user to cycle through the three hiding modes.

The |g:netrw_list_hide| variable holds a comma delimited list of patterns
based on regular expressions (ex. ^.*\.obj$,^\.) which specify the hiding list.
(also see |netrw-ctrl-h|)  To set the hiding list, use the <c-h> map.  As an
example, to hide files which begin with a ".", one may use the <c-h> map to
set the hiding list to '^\..*' (or one may put let g:netrw_list_hide= '^\..*'
in one's <.vimrc>).  One may then use the "a" key to show all files, hide
matching files, or to show only the matching files.

	Example: \.[ch]$
		This hiding list command will hide/show all *.c and *.h files.

	Example: \.c$,\.h$
		This hiding list command will also hide/show all *.c and *.h
		files.

Don't forget to use the "a" map to select the mode (normal/hiding/show) you
want!

If files have been marked using |netrw-mf|, then this command will:

  if showing all files or non-hidden files:
   modify the g:netrw_list_hide list by appending the marked files to it
   and showing only non-hidden files.

  else if showing hidden files only:
   modify the g:netrw_list_hide list by removing the marked files from it
   and showing only non-hidden files.
  endif

					*netrw-gh* *netrw-hide*
As a quick shortcut, one may press >
	gh
to toggle between hiding files which begin with a period (dot) and not hiding
them.

Associated setting variables: |g:netrw_list_hide|  |g:netrw_hide|
Associated topics: |netrw-a| |netrw-ctrl-h| |netrw-mh|

					*netrw-gitignore*
Netrw provides a helper function 'netrw_gitignore#Hide()' that, when used with
|g:netrw_list_hide| automatically hides all git-ignored files.

'netrw_gitignore#Hide' searches for patterns in the following files: >

	'./.gitignore'
	'./.git/info/exclude'
	global gitignore file: `git config --global core.excludesfile`
	system gitignore file: `git config --system core.excludesfile`
<
Files that do not exist, are ignored.
Git-ignore patterns are taken from existing files, and converted to patterns for
hiding files. For example, if you had '*.log' in your '.gitignore' file, it
would be converted to '.*\.log'.

To use this function, simply assign its output to |g:netrw_list_hide| option.  >

	Example: let g:netrw_list_hide= netrw_gitignore#Hide()
		Git-ignored files are hidden in Netrw.

	Example: let g:netrw_list_hide= netrw_gitignore#Hide('my_gitignore_file')
		Function can take additional files with git-ignore patterns.

	Example: g:netrw_list_hide= netrw_gitignore#Hide() . '.*\.swp$'
		Combining 'netrw_gitignore#Hide' with custom patterns.
<

IMPROVING BROWSING			*netrw-listhack* *netrw-ssh-hack* {{{2

Especially with the remote directory browser, constantly entering the password
is tedious.

For Linux/Unix systems, the book "Linux Server Hacks - 100 industrial strength
tips & tools" by Rob Flickenger (O'Reilly, ISBN 0-596-00461-3) gives a tip
for setting up no-password ssh and scp and discusses associated security
issues.  It used to be available at http://hacks.oreilly.com/pub/h/66 ,
but apparently that address is now being redirected to some "hackzine".
I'll attempt a summary based on that article and on a communication from
Ben Schmidt:

	1. Generate a public/private key pair on the local machine
	   (ssh client): >
		ssh-keygen -t rsa
		(saving the file in ~/.ssh/id_rsa as prompted)
<
	2. Just hit the <CR> when asked for passphrase (twice) for no
	   passphrase.  If you do use a passphrase, you will also need to use
	   ssh-agent so you only have to type the passphrase once per session.
	   If you don't use a passphrase, simply logging onto your local
	   computer or getting access to the keyfile in any way will suffice
	   to access any ssh servers which have that key authorized for login.

	3. This creates two files: >
		~/.ssh/id_rsa
		~/.ssh/id_rsa.pub
<
	4. On the target machine (ssh server): >
		cd
		mkdir -p .ssh
		chmod 0700 .ssh
<
	5. On your local machine (ssh client): (one line) >
		ssh {serverhostname}
		  cat '>>' '~/.ssh/authorized_keys2' < ~/.ssh/id_rsa.pub
<
	   or, for OpenSSH, (one line) >
		ssh {serverhostname}
		  cat '>>' '~/.ssh/authorized_keys' < ~/.ssh/id_rsa.pub
<
You can test it out with >
	ssh {serverhostname}
and you should be log onto the server machine without further need to type
anything.

If you decided to use a passphrase, do: >
	ssh-agent $SHELL
	ssh-add
	ssh {serverhostname}
You will be prompted for your key passphrase when you use ssh-add, but not
subsequently when you use ssh.  For use with vim, you can use >
	ssh-agent vim
and, when next within vim, use >
	:!ssh-add
Alternatively, you can apply ssh-agent to the terminal you're planning on
running vim in: >
	ssh-agent xterm &
and do ssh-add whenever you need.

For Windows, folks on the vim mailing list have mentioned that Pageant helps
with avoiding the constant need to enter the password.

Kingston Fung wrote about another way to avoid constantly needing to enter
passwords:

    In order to avoid the need to type in the password for scp each time, you
    provide a hack in the docs to set up a non password ssh account. I found a
    better way to do that: I can use a regular ssh account which uses a
    password to access the material without the need to key-in the password
    each time. It's good for security and convenience. I tried ssh public key
    authorization + ssh-agent, implementing this, and it works! Here are two
    links with instructions:

    http://www.ibm.com/developerworks/library/l-keyc2/
    http://sial.org/howto/openssh/publickey-auth/


    Ssh hints:

	Thomer Gil has provided a hint on how to speed up netrw+ssh:
	    http://thomer.com/howtos/netrw_ssh.html

	Alex Young has several hints on speeding ssh up:
	    http://usevim.com/2012/03/16/editing-remote-files/


LISTING BOOKMARKS AND HISTORY		*netrw-qb* *netrw-listbookmark* {{{2

Pressing "qb" (query bookmarks) will list both the bookmarked directories and
directory traversal history.

Related Topics:
	|netrw-gb| how to return (go) to a bookmark
	|netrw-mb| how to make a bookmark
	|netrw-mB| how to delete bookmarks
	|netrw-u|  change to a predecessor directory via the history stack
	|netrw-U|  change to a successor   directory via the history stack

MAKING A NEW DIRECTORY					*netrw-d* {{{2

With the "d" map one may make a new directory either remotely (which depends
on the global variable g:netrw_mkdir_cmd) or locally (which depends on the
global variable g:netrw_localmkdir).  Netrw will issue a request for the new
directory's name.  A bare <CR> at that point will abort the making of the
directory.  Attempts to make a local directory that already exists (as either
a file or a directory) will be detected, reported on, and ignored.

Related topics: |netrw-D|
Associated setting variables:	|g:netrw_localmkdir|   |g:netrw_mkdir_cmd|
				|g:netrw_remote_mkdir| |netrw-%|


MAKING THE BROWSING DIRECTORY THE CURRENT DIRECTORY	*netrw-c* {{{2

By default, |g:netrw_keepdir| is 1.  This setting means that the current
directory will not track the browsing directory. (done for backwards
compatibility with v6's file explorer).

Setting g:netrw_keepdir to 0 tells netrw to make vim's current directory
track netrw's browsing directory.

However, given the default setting for g:netrw_keepdir of 1 where netrw
maintains its own separate notion of the current directory, in order to make
the two directories the same, use the "c" map (just type c).  That map will
set Vim's notion of the current directory to netrw's current browsing
directory.

Associated setting variable: |g:netrw_keepdir|

MARKING FILES					*netrw-:MF*	*netrw-mf* {{{2
	(also see |netrw-mr|)

Netrw provides several ways to mark files:

	* One may mark files with the cursor atop a filename and
	  then pressing "mf".

	* With gvim, in addition one may mark files with
	  <s-leftmouse>. (see |netrw-mouse|)

	* One may use the :MF command, which takes a list of
	  files (for local directories, the list may include
	  wildcards -- see |glob()|) >

		:MF *.c
<
	* Note that :MF uses |<f-args>| to break the line
	  at spaces.

	* Mark files based upon the quickfix list (|netrw-qF|)

The following netrw maps make use of marked files:

    |netrw-a|	Hide marked files/directories
    |netrw-D|	Delete marked files/directories
    |netrw-mb|	Append marked files to bookmarks
    |netrw-mB|	Delete marked files from bookmarks
    |netrw-mc|	Copy marked files to target
    |netrw-md|	Apply vimdiff to marked files
    |netrw-me|	Edit marked files
    |netrw-mF|	Unmark marked files
    |netrw-mg|	Apply vimgrep to marked files
    |netrw-mm|	Move marked files to target
    |netrw-mp|	Print marked files
    |netrw-mt|	Set target for |netrw-mm| and |netrw-mc|
    |netrw-mT|	Generate tags using marked files
    |netrw-mv|	Apply vim command to marked files
    |netrw-mx|	Apply shell command to marked files
    |netrw-mX|	Apply shell command to marked files, en bloc
    |netrw-mz|	Compress/Decompress marked files
    |netrw-O|	Obtain marked files
    |netrw-R|	Rename marked files

One may unmark files one at a time the same way one marks them; ie. place
the cursor atop a marked file and press "mf".  This process also works
with <s-leftmouse> using gvim.  One may unmark all files by pressing
"mu" (see |netrw-mu|).

Marked files are highlighted using the "netrwMarkFile" highlighting group,
which by default is linked to "Identifier" (see Identifier under
|group-name|).  You may change the highlighting group by putting something
like >

	highlight clear netrwMarkFile
	hi link netrwMarkFile ..whatever..
<
into $HOME/.vim/after/syntax/netrw.vim .

If the mouse is enabled and works with your vim, you may use <s-leftmouse> to
mark one or more files.  You may mark multiple files by dragging the shifted
leftmouse.  (see |netrw-mouse|)

			*markfilelist* *global_markfilelist* *local_markfilelist*
All marked files are entered onto the global marked file list; there is only
one such list.  In addition, every netrw buffer also has its own buffer-local
marked file list; since netrw buffers are associated with specific
directories, this means that each directory has its own local marked file
list.  The various commands which operate on marked files use one or the other
of the marked file lists.

Known Problem: if one is using tree mode (|g:netrw_liststyle|) and several
directories have files with the same name,  then marking such a file will
result in all such files being highlighted as if they were all marked.  The
|markfilelist|, however, will only have the selected file in it.  This problem
is unlikely to be fixed.


UNMARKING FILES							*netrw-mF* {{{2
	(also see |netrw-mf|, |netrw-mu|)

The "mF" command will unmark all files in the current buffer.  One may also use
mf (|netrw-mf|) on a specific, already marked, file to unmark just that file.


MARKING FILES BY QUICKFIX LIST				*netrw-qF* {{{2
	(also see |netrw-mf|)

One may convert |quickfix-error-lists| into a marked file list using "qF".
You may then proceed with commands such as me (|netrw-me|) to edit them.
Quickfix error lists are generated, for example, by calls to |:vimgrep|.


MARKING FILES BY REGULAR EXPRESSION				*netrw-mr* {{{2
	(also see |netrw-mf|)

One may also mark files by pressing "mr"; netrw will then issue a prompt,
"Enter regexp: ".  You may then enter a shell-style regular expression such
as *.c$ (see |glob()|).  For remote systems, glob() doesn't work -- so netrw
converts "*" into ".*" (see |regexp|) and marks files based on that.  In the
future I may make it possible to use |regexp|s instead of glob()-style
expressions (yet-another-option).


MARKED FILES, ARBITRARY VIM COMMAND				*netrw-mv*  {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the local marked-file list)

The "mv" map causes netrw to execute an arbitrary vim command on each file on
the local marked file list, individually:

	* 1split
	* sil! keepalt e file
	* run vim command
	* sil! keepalt wq!

A prompt, "Enter vim command: ", will be issued to elicit the vim command
you wish used.


MARKED FILES, ARBITRARY SHELL COMMAND				*netrw-mx* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the local marked-file list)

Upon activation of the "mx" map, netrw will query the user for some (external)
command to be applied to all marked files.  All "%"s in the command will be
substituted with the name of each marked file in turn.  If no "%"s are in the
command, then the command will be followed by a space and a marked filename.

Example:
	(mark files)
	mx
	Enter command: cat

	The result is a series of shell commands:
	cat 'file1'
	cat 'file2'
	...


MARKED FILES, ARBITRARY SHELL COMMAND, EN BLOC 			*netrw-mX* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the global marked-file list)

Upon activation of the 'mX' map, netrw will query the user for some (external)
command to be applied to all marked files on the global marked file list.  The
"en bloc" means that one command will be executed on all the files at once: >

	command files

This approach is useful, for example, to select files and make a tarball: >

	(mark files)
	mX
	Enter command: tar cf mynewtarball.tar
<
The command that will be run with this example:

	tar cf mynewtarball.tar 'file1' 'file2' ...


MARKED FILES: COMPRESSION AND DECOMPRESSION		*netrw-mz* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the local marked file list)

If any marked files are compressed,   then "mz" will decompress them.
If any marked files are decompressed, then "mz" will compress them
using the command specified by |g:netrw_compress|; by default,
that's "gzip".

For decompression, netrw provides a |Dictionary| of suffices and their
associated decompressing utilities; see |g:netrw_decompress|.

Remember that one can mark multiple files by regular expression
(see |netrw-mr|); this is particularly useful to facilitate compressing and
decompressing a large number of files.

Associated setting variables: |g:netrw_compress| |g:netrw_decompress|

MARKED FILES: COPYING						*netrw-mc* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (Uses the global marked file list)

Select a target directory with mt (|netrw-mt|).  Then change directory,
select file(s) (see |netrw-mf|), and press "mc".  The copy is done
from the current window (where one does the mf) to the target.

If one does not have a target directory set with |netrw-mt|, then netrw
will query you for a directory to copy to.

One may also copy directories and their contents (local only) to a target
directory.

Associated setting variables:
	|g:netrw_localcopycmd|
	|g:netrw_localcopydircmd|
	|g:netrw_ssh_cmd|

MARKED FILES: DIFF						*netrw-md* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the global marked file list)

Use |vimdiff| to visualize difference between selected files (two or
three may be selected for this).  Uses the global marked file list.

MARKED FILES: EDITING						*netrw-me* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the global marked file list)

The "me" command will place the marked files on the |arglist| and commence
editing them.  One may return the to explorer window with |:Rexplore|.
(use |:n| and |:p| to edit next and previous files in the arglist)

MARKED FILES: GREP						*netrw-mg* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the global marked file list)

The "mg" command will apply |:vimgrep| to the marked files.
The command will ask for the requested pattern; one may then enter: >

	/pattern/[g][j]
	! /pattern/[g][j]
	pattern
<
With /pattern/, editing will start with the first item on the |quickfix| list
that vimgrep sets up (see |copen|, |cnext|, |cprevious|).  The |vimgrep|
command is in use, so without 'g' each line is added to quickfix list only
once; with 'g' every match is included.

With /pattern/j, "mg" will winnow the current marked file list to just those
marked files also possessing the specified pattern.  Thus, one may use >

	mr ...file-pattern...
	mg /pattern/j
<
to have a marked file list satisfying the file-pattern but also restricted to
files containing some desired pattern.


MARKED FILES: HIDING AND UNHIDING BY SUFFIX			*netrw-mh* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the local marked file list)

The "mh" command extracts the suffices of the marked files and toggles their
presence on the hiding list.  Please note that marking the same suffix
this way multiple times will result in the suffix's presence being toggled
for each file (so an even quantity of marked files having the same suffix
is the same as not having bothered to select them at all).

Related topics: |netrw-a| |g:netrw_list_hide|

MARKED FILES: MOVING						*netrw-mm* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the global marked file list)

	WARNING: moving files is more dangerous than copying them.
	A file being moved is first copied and then deleted; if the
	copy operation fails and the delete succeeds, you will lose
	the file.  Either try things out with unimportant files
	first or do the copy and then delete yourself using mc and D.
	Use at your own risk!

Select a target directory with mt (|netrw-mt|).  Then change directory,
select file(s) (see |netrw-mf|), and press "mm".  The move is done
from the current window (where one does the mf) to the target.

Associated setting variable: |g:netrw_localmovecmd| |g:netrw_ssh_cmd|

MARKED FILES: PRINTING						*netrw-mp* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the local marked file list)

When "mp" is used, netrw will apply the |:hardcopy| command to marked files.
What netrw does is open each file in a one-line window, execute hardcopy, then
close the one-line window.


MARKED FILES: SOURCING						*netrw-ms* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the local marked file list)

With "ms", netrw will source the marked files (using vim's |:source| command)


MARKED FILES: SETTING THE TARGET DIRECTORY			*netrw-mt* {{{2
     (See |netrw-mf| and |netrw-mr| for how to mark files)

Set the marked file copy/move-to target (see |netrw-mc| and |netrw-mm|):

  * If the cursor is atop a file name, then the netrw window's currently
    displayed directory is used for the copy/move-to target.

  * Also, if the cursor is in the banner, then the netrw window's currently
    displayed directory is used for the copy/move-to target.
    Unless the target already is the current directory.  In which case,
    typing "mf" clears the target.

  * However, if the cursor is atop a directory name, then that directory is
    used for the copy/move-to target

  * One may use the :MT [directory] command to set the target	*netrw-:MT*
    This command uses |<q-args>|, so spaces in the directory name are
    permitted without escaping.

  * With mouse-enabled vim or with gvim, one may select a target by using
    <c-leftmouse>

There is only one copy/move-to target at a time in a vim session; ie. the
target is a script variable (see |s:var|) and is shared between all netrw
windows (in an instance of vim).

When using menus and gvim, netrw provides a "Targets" entry which allows one
to pick a target from the list of bookmarks and history.

Related topics:
      Marking Files......................................|netrw-mf|
      Marking Files by Regular Expression................|netrw-mr|
      Marked Files: Target Directory Using Bookmarks.....|netrw-Tb|
      Marked Files: Target Directory Using History.......|netrw-Th|


MARKED FILES: TAGGING						*netrw-mT* {{{2
	    (See |netrw-mf| and |netrw-mr| for how to mark files)
		      (uses the global marked file list)

The "mT" mapping will apply the command in |g:netrw_ctags| (by default, it is
"ctags") to marked files.  For remote browsing, in order to create a tags file
netrw will use ssh (see |g:netrw_ssh_cmd|), and so ssh must be available for
this to work on remote systems.  For your local system, see |ctags| on how to
get a version.  I myself use hdrtags, currently available at
http://www.drchip.org/astronaut/src/index.html , and have >

	let g:netrw_ctags= "hdrtag"
<
in my <.vimrc>.

When a remote set of files are tagged, the resulting tags file is "obtained";
ie. a copy is transferred to the local system's directory.  The now local tags
file is then modified so that one may use it through the network.  The
modification made concerns the names of the files in the tags; each filename is
preceded by the netrw-compatible url used to obtain it.  When one subsequently
uses one of the go to tag actions (|tags|), the url will be used by netrw to
edit the desired file and go to the tag.

Associated setting variables: |g:netrw_ctags| |g:netrw_ssh_cmd|

MARKED FILES: TARGET DIRECTORY USING BOOKMARKS		*netrw-Tb* {{{2

Sets the marked file copy/move-to target.

The |netrw-qb| map will give you a list of bookmarks (and history).
One may choose one of the bookmarks to become your marked file
target by using [count]Tb (default count: 1).

Related topics:
      Copying files to target............................|netrw-mc|
      Listing Bookmarks and History......................|netrw-qb|
      Marked Files: Setting The Target Directory.........|netrw-mt|
      Marked Files: Target Directory Using History.......|netrw-Th|
      Marking Files......................................|netrw-mf|
      Marking Files by Regular Expression................|netrw-mr|
      Moving files to target.............................|netrw-mm|


MARKED FILES: TARGET DIRECTORY USING HISTORY			*netrw-Th* {{{2

Sets the marked file copy/move-to target.

The |netrw-qb| map will give you a list of history (and bookmarks).
One may choose one of the history entries to become your marked file
target by using [count]Th (default count: 0; ie. the current directory).

Related topics:
      Copying files to target............................|netrw-mc|
      Listing Bookmarks and History......................|netrw-qb|
      Marked Files: Setting The Target Directory.........|netrw-mt|
      Marked Files: Target Directory Using Bookmarks.....|netrw-Tb|
      Marking Files......................................|netrw-mf|
      Marking Files by Regular Expression................|netrw-mr|
      Moving files to target.............................|netrw-mm|


MARKED FILES: UNMARKING						*netrw-mu* {{{2
     (See |netrw-mf|, |netrw-mF|)

The "mu" mapping will unmark all currently marked files.  This command differs
from "mF" as the latter only unmarks files in the current directory whereas
"mu" will unmark global and all buffer-local marked files.
(see |netrw-mF|)


				*netrw-browser-settings*
NETRW BROWSER VARIABLES		*netrw-browser-options* *netrw-browser-var* {{{2

(if you're interested in the netrw file transfer settings, see |netrw-options|
 and |netrw-protocol|)

The <netrw.vim> browser provides settings in the form of variables which
you may modify; by placing these settings in your <.vimrc>, you may customize
your browsing preferences.  (see also: |netrw-settings|)
>
   ---				-----------
   Var				Explanation
   ---				-----------
<  *g:netrw_altfile*		some like |CTRL-^| to return to the last
				edited file.  Choose that by setting this
				parameter to 1.
				Others like |CTRL-^| to return to the
				netrw browsing buffer.  Choose that by setting
				this parameter to 0.
				 default: =0

  *g:netrw_alto*		change from above splitting to below splitting
				by setting this variable (see |netrw-o|)
				 default: =&sb           (see |'sb'|)

  *g:netrw_altv*		change from left splitting to right splitting
				by setting this variable (see |netrw-v|)
				 default: =&spr          (see |'spr'|)

  *g:netrw_banner*		enable/suppress the banner
				=0: suppress the banner
				=1: banner is enabled (default)

  *g:netrw_bannerbackslash*	if this variable exists and is not zero, the
				banner will be displayed with backslashes
				rather than forward slashes.

  *g:netrw_browse_split*	when browsing, <cr> will open the file by:
				=0: re-using the same window  (default)
				=1: horizontally splitting the window first
				=2: vertically   splitting the window first
				=3: open file in new tab
				=4: act like "P" (ie. open previous window)
				    Note that |g:netrw_preview| may be used
				    to get vertical splitting instead of
				    horizontal splitting.
				=[servername,tab-number,window-number]
				    Given a |List| such as this, a remote server
				    named by the "servername" will be used for
				    editing.  It will also use the specified tab
				    and window numbers to perform editing
				    (see |clientserver|, |netrw-ctrl-r|)
				This option does not affect |:Lexplore|
				windows.

				Related topics:
				    |g:netrw_alto|	|g:netrw_altv|
				    |netrw-C|		|netrw-cr|
				    |netrw-ctrl-r|

  *g:netrw_browsex_viewer*	specify user's preference for a viewer: >
					"kfmclient exec"
					"gnome-open"
<				If >
					"-"
<				is used, then netrwFileHandler() will look for
				a script/function to handle the given
				extension.  (see |netrw_filehandler|).

  *g:netrw_chgperm*		Unix/Linux: "chmod PERM FILENAME"
				Windows:    "cacls FILENAME /e /p PERM"
				Used to change access permission for a file.

  *g:netrw_compress*		="gzip"
				    Will compress marked files with this
				    command

  *g:Netrw_corehandler*		Allows one to specify something additional
				to do when handling <core> files via netrw's
				browser's "x" command (see |netrw-x|).  If
				present, g:Netrw_corehandler specifies
				either one or more function references
				(see |Funcref|).  (the capital g:Netrw...
				is required its holding a function reference)


  *g:netrw_ctags*		="ctags"
				The default external program used to create
				tags

  *g:netrw_cursor*		= 2 (default)
				This option controls the use of the
				|'cursorline'| (cul) and |'cursorcolumn'|
				(cuc) settings by netrw:

				Value   Thin-Long-Tree      Wide
				 =0      u-cul u-cuc      u-cul u-cuc
				 =1      u-cul u-cuc        cul u-cuc
				 =2        cul u-cuc        cul u-cuc
				 =3        cul u-cuc        cul   cuc
				 =4        cul   cuc        cul   cuc

				Where
				  u-cul : user's |'cursorline'|   setting used
				  u-cuc : user's |'cursorcolumn'| setting used
				  cul   : |'cursorline'|  locally set
				  cuc   : |'cursorcolumn'| locally set

  *g:netrw_decompress*		= { ".gz"  : "gunzip" ,
				    ".bz2" : "bunzip2" ,
				    ".zip" : "unzip" ,
				    ".tar" : "tar -xf"}
				  A dictionary mapping suffices to
				  decompression programs.

  *g:netrw_dirhistmax*            =10: controls maximum quantity of past
                                     history.  May be zero to supppress
				     history.
				     (related: |netrw-qb| |netrw-u| |netrw-U|)

  *g:netrw_dynamic_maxfilenamelen* =32: enables dynamic determination of
				    |g:netrw_maxfilenamelen|, which affects
				    local file long listing.

  *g:netrw_errorlvl*		=0: error levels greater than or equal to
				    this are permitted to be displayed
				    0: notes
				    1: warnings
				    2: errors

  *g:netrw_fastbrowse*		=0: slow speed directory browsing;
				    never re-uses directory listings;
				    always obtains directory listings.
				=1: medium speed directory browsing;
				    re-use directory listings only
				    when remote directory browsing.
				    (default value)
				=2: fast directory browsing;
				    only obtains directory listings when the
				    directory hasn't been seen before
				    (or |netrw-ctrl-l| is used).

				Fast browsing retains old directory listing
				buffers so that they don't need to be
				re-acquired.  This feature is especially
				important for remote browsing.  However, if
				a file is introduced or deleted into or from
				such directories, the old directory buffer
				becomes out-of-date.  One may always refresh
				such a directory listing with |netrw-ctrl-l|.
				This option gives the user the choice of
				trading off accuracy (ie. up-to-date listing)
				versus speed.

  *g:netrw_ffkeep*		(default: doesn't exist)
				If this variable exists and is zero, then
				netrw will not do a save and restore for
				|'fileformat'|.

  *g:netrw_fname_escape*	=' ?&;%'
				Used on filenames before remote reading/writing

  *g:netrw_ftp_browse_reject*	ftp can produce a number of errors and warnings
				that can show up as "directories" and "files"
				in the listing.  This pattern is used to
				remove such embedded messages.  By default its
				value is:
				 '^total\s\+\d\+$\|
				 ^Trying\s\+\d\+.*$\|
				 ^KERBEROS_V\d rejected\|
				 ^Security extensions not\|
				 No such file\|
				 : connect to address [0-9a-fA-F:]*
				 : No route to host$'

  *g:netrw_ftp_list_cmd*	options for passing along to ftp for directory
				listing.  Defaults:
				 unix or g:netrw_cygwin set: : "ls -lF"
				 otherwise                     "dir"


  *g:netrw_ftp_sizelist_cmd*	options for passing along to ftp for directory
				listing, sorted by size of file.
				Defaults:
				 unix or g:netrw_cygwin set: : "ls -slF"
				 otherwise                     "dir"

  *g:netrw_ftp_timelist_cmd*	options for passing along to ftp for directory
				listing, sorted by time of last modification.
				Defaults:
				 unix or g:netrw_cygwin set: : "ls -tlF"
				 otherwise                     "dir"

  *g:netrw_glob_escape*		='[]*?`{~$'  (unix)
				='[]*?`{$'  (windows
				These characters in directory names are
				escaped before applying glob()

  *g:netrw_gx*			="<cfile>"
 				This option controls how gx (|netrw-gx|) picks
				up the text under the cursor.  See |expand()|
				for possibilities.

  *g:netrw_hide*		Controlled by the "a" map (see |netrw-a|)
				=0 : show all
				=1 : show not-hidden files
				=2 : show hidden files only
				 default: =0

  *g:netrw_home*		The home directory for where bookmarks and
				history are saved (as .netrwbook and
				.netrwhist).
				 default: the first directory on the
				         |'runtimepath'|

  *g:netrw_keepdir*		=1 (default) keep current directory immune from
				   the browsing directory.
				=0 keep the current directory the same as the
				   browsing directory.
				The current browsing directory is contained in
				b:netrw_curdir (also see |netrw-c|)

  *g:netrw_keepj*		="keepj" (default) netrw attempts to keep the
				         |:jumps| table unaffected.
				=""      netrw will not use |:keepjumps| with
					 exceptions only for the
					 saving/restoration of position.

  *g:netrw_list_cmd*		command for listing remote directories
				 default: (if ssh is executable)
				          "ssh HOSTNAME ls -FLa"

 *g:netrw_list_cmd_options*	If this variable exists, then its contents are
				appended to the g:netrw_list_cmd.  For
				example, use "2>/dev/null" to get rid of banner
				messages on unix systems.


  *g:netrw_liststyle*		Set the default listing style:
                                = 0: thin listing (one file per line)
                                = 1: long listing (one file per line with time
				     stamp information and file size)
				= 2: wide listing (multiple files in columns)
				= 3: tree style listing

  *g:netrw_list_hide*		comma separated pattern list for hiding files
				Patterns are regular expressions (see |regexp|)
				There's some special support for git-ignore
				files: you may add the output from the helper
				function 'netrw_gitignore#Hide() automatically
				hiding all gitignored files.
				For more details see |netrw-gitignore|.

				Examples:
				 let g:netrw_list_hide= '.*\.swp$'
				 let g:netrw_list_hide= netrw_gitignore#Hide().'.*\.swp$'
				default: ""

  *g:netrw_localcopycmd*	="cp" Linux/Unix/MacOS/Cygwin
				="copy" Windows
				Copies marked files (|netrw-mf|) to target
				directory (|netrw-mt|, |netrw-mc|)

 *g:netrw_localcopydircmd*	="cp -R"	Linux/Unix/MacOS/Cygwin
				="xcopy /e /c /h/ /i /k"	Windows
				Copies directories to target directory.
				(|netrw-mc|, |netrw-mt|)

  *g:netrw_localmkdir*		command for making a local directory
				 default: "mkdir"

  *g:netrw_localmovecmd*	="mv" Linux/Unix/MacOS/Cygwin
				="move" Windows
				Moves marked files (|netrw-mf|) to target
				directory (|netrw-mt|, |netrw-mm|)

  *g:netrw_localrmdir*		remove directory command (rmdir)
				 default: "rmdir"

  *g:netrw_maxfilenamelen*	=32 by default, selected so as to make long
				    listings fit on 80 column displays.
				If your screen is wider, and you have file
				or directory names longer than 32 bytes,
				you may set this option to keep listings
				columnar.

  *g:netrw_mkdir_cmd*		command for making a remote directory
				via ssh  (also see |g:netrw_remote_mkdir|)
				 default: "ssh USEPORT HOSTNAME mkdir"

  *g:netrw_mousemaps*		  =1 (default) enables mouse buttons while
				   browsing to:
				     leftmouse       : open file/directory
				     shift-leftmouse : mark file
				     middlemouse     : same as P
				     rightmouse      : remove file/directory
				=0: disables mouse maps

  *g:netrw_nobeval*		doesn't exist (default)
				If this variable exists, then balloon
				evaluation will be suppressed
				(see |'ballooneval'|)

  *g:netrw_notab*		if this variable exists, then the <tab>
				map supporting shrinking/expanding a
				Lexplore or netrw window will be disabled.
				(see |netrw-tab|)

  *g:netrw_remote_mkdir*	command for making a remote directory
				via ftp  (also see |g:netrw_mkdir_cmd|)
				 default: "mkdir"

  *g:netrw_retmap*		if it exists and is set to one, then:
				 * if in a netrw-selected file, AND
				 * no normal-mode <2-leftmouse> mapping exists,
				then the <2-leftmouse> will be mapped for easy
				return to the netrw browser window.
				 example: click once to select and open a file,
				          double-click to return.

				Note that one may instead choose to:
				 * let g:netrw_retmap= 1, AND
				 * nmap <silent> YourChoice <Plug>NetrwReturn
				and have another mapping instead of
				<2-leftmouse> to invoke the return.

				You may also use the |:Rexplore| command to do
				the same thing.

				  default: =0

  *g:netrw_rm_cmd*		command for removing remote files
				 default: "ssh USEPORT HOSTNAME rm"

  *g:netrw_rmdir_cmd*		command for removing remote directories
				 default: "ssh USEPORT HOSTNAME rmdir"

  *g:netrw_rmf_cmd*		command for removing remote softlinks
				 default: "ssh USEPORT HOSTNAME rm -f"

  *g:netrw_servername*		use this variable to provide a name for
				|netrw-ctrl-r| to use for its server.
				 default: "NETRWSERVER"

  *g:netrw_sort_by*		sort by "name", "time", "size", or
  				"exten".
				 default: "name"

  *g:netrw_sort_direction*	sorting direction: "normal" or "reverse"
				 default: "normal"

  *g:netrw_sort_options*	sorting is done using |:sort|; this
				variable's value is appended to the
				sort command.  Thus one may ignore case,
				for example, with the following in your
				.vimrc: >
					let g:netrw_sort_options="i"
<				 default: ""

  *g:netrw_sort_sequence*	when sorting by name, first sort by the
				comma-separated pattern sequence.  Note that
				any filigree added to indicate filetypes
				should be accounted for in your pattern.
				 default: '[\/]$,*,\.bak$,\.o$,\.h$,
				           \.info$,\.swp$,\.obj$'

  *g:netrw_special_syntax*	If true, then certain files will be shown
				using special syntax in the browser:

					netrwBak     : *.bak
					netrwCompress: *.gz *.bz2 *.Z *.zip
					netrwData    : *.dat
					netrwHdr     : *.h
					netrwLib     : *.a *.so *.lib *.dll
					netrwMakefile: [mM]akefile *.mak
					netrwObj     : *.o *.obj
					netrwTags    : tags ANmenu ANtags
					netrwTilde   : *
					netrwTmp     : tmp* *tmp

				These syntax highlighting groups are linked
				to Folded or DiffChange by default
				(see |hl-Folded| and |hl-DiffChange|), but
				one may put lines like >
					hi link netrwCompress Visual
<				into one's <.vimrc> to use one's own
				preferences.  Alternatively, one may
				put such specifications into
				.vim/after/syntax/netrw.vim.

				As an example, I myself use a dark-background
				colorscheme with the following in
				.vim/after/syntax/netrw.vim: >

 hi netrwCompress term=NONE cterm=NONE gui=NONE ctermfg=10 guifg=green  ctermbg=0 guibg=black
 hi netrwData	  term=NONE cterm=NONE gui=NONE ctermfg=9 guifg=blue ctermbg=0 guibg=black
 hi netrwHdr	  term=NONE cterm=NONE,italic gui=NONE guifg=SeaGreen1
 hi netrwLex	  term=NONE cterm=NONE,italic gui=NONE guifg=SeaGreen1
 hi netrwYacc	  term=NONE cterm=NONE,italic gui=NONE guifg=SeaGreen1
 hi netrwLib	  term=NONE cterm=NONE gui=NONE ctermfg=14 guifg=yellow
 hi netrwObj	  term=NONE cterm=NONE gui=NONE ctermfg=12 guifg=red
 hi netrwTilde	  term=NONE cterm=NONE gui=NONE ctermfg=12 guifg=red
 hi netrwTmp	  term=NONE cterm=NONE gui=NONE ctermfg=12 guifg=red
 hi netrwTags	  term=NONE cterm=NONE gui=NONE ctermfg=12 guifg=red
 hi netrwDoc	  term=NONE cterm=NONE gui=NONE ctermfg=220 ctermbg=27 guifg=yellow2 guibg=Blue3
 hi netrwSymLink  term=NONE cterm=NONE gui=NONE ctermfg=220 ctermbg=27 guifg=grey60
<
  *g:netrw_ssh_browse_reject*	ssh can sometimes produce unwanted lines,
				messages, banners, and whatnot that one doesn't
				want masquerading as "directories" and "files".
				Use this pattern to remove such embedded
				messages.  By default its value is:
					 '^total\s\+\d\+$'

  *g:netrw_ssh_cmd*		One may specify an executable command
				to use instead of ssh for remote actions
				such as listing, file removal, etc.
				 default: ssh


  *g:netrw_tmpfile_escape*	=' &;'
				escape() is applied to all temporary files
				to escape these characters.

  *g:netrw_timefmt*		specify format string to vim's strftime().
				The default, "%c", is "the preferred date
				and time representation for the current
				locale" according to my manpage entry for
				strftime(); however, not all are satisfied
				with it.  Some alternatives:
				 "%a %d %b %Y %T",
				 " %a %Y-%m-%d  %I-%M-%S %p"
				 default: "%c"

  *g:netrw_use_noswf*		netrw normally avoids writing swapfiles
				for browser buffers.  However, under some
				systems this apparently is causing nasty
				ml_get errors to appear; if you're getting
				ml_get errors, try putting
				  let g:netrw_use_noswf= 0
				in your .vimrc.
				  default: 1

  *g:netrw_winsize*		specify initial size of new windows made with
				"o" (see |netrw-o|), "v" (see |netrw-v|),
				|:Hexplore| or |:Vexplore|.  The g:netrw_winsize
				is an integer describing the percentage of the
				current netrw buffer's window to be used for
				the new window.
				 If g:netrw_winsize is less than zero, then
				the absolute value of g:netrw_winsize lines
				or columns will be used for the new window.
				 If g:netrw_winsize is zero, then a normal
				split will be made (ie. |'equalalways'| will
				take effect, for example).
				 default: 50  (for 50%)

  *g:netrw_wiw*			=1 specifies the minimum window width to use
				when shrinking a netrw/Lexplore window
				(see |netrw-tab|).

  *g:netrw_xstrlen*		Controls how netrw computes string lengths,
				including multi-byte characters' string
				length. (thanks to N Weibull, T Mechelynck)
				=0: uses Vim's built-in strlen()
				=1: number of codepoints (Latin a + combining
				    circumflex is two codepoints)  (DEFAULT)
				=2: number of spacing codepoints (Latin a +
				    combining circumflex is one spacing
				    codepoint; a hard tab is one; wide and
				    narrow CJK are one each; etc.)
				=3: virtual length (counting tabs as anything
				    between 1 and |'tabstop'|, wide CJK as 2
				    rather than 1, Arabic alif as zero when
				    immediately preceded by lam, one
				    otherwise, etc)

  *g:NetrwTopLvlMenu*		This variable specifies the top level
				menu name; by default, it's "Netrw.".  If
				you wish to change this, do so in your
				.vimrc.

NETRW BROWSING AND OPTION INCOMPATIBILITIES	*netrw-incompatible* {{{2

Netrw has been designed to handle user options by saving them, setting the
options to something that's compatible with netrw's needs, and then restoring
them.  However, the autochdir option: >
	:set acd
is problematic.  Autochdir sets the current directory to that containing the
file you edit; this apparently also applies to directories.  In other words,
autochdir sets the current directory to that containing the "file" (even if
that "file" is itself a directory).

NETRW SETTINGS WINDOW				*netrw-settings-window* {{{2

With the NetrwSettings.vim plugin, >
	:NetrwSettings
will bring up a window with the many variables that netrw uses for its
settings.  You may change any of their values; when you save the file, the
settings therein will be used.  One may also press "?" on any of the lines for
help on what each of the variables do.

(also see: |netrw-browser-var| |netrw-protocol| |netrw-variables|)


==============================================================================
OBTAINING A FILE					*netrw-obtain* *netrw-O* {{{2

If there are no marked files:

    When browsing a remote directory, one may obtain a file under the cursor
    (ie.  get a copy on your local machine, but not edit it) by pressing the O
    key.

If there are marked files:

    The marked files will be obtained (ie. a copy will be transferred to your
    local machine, but not set up for editing).

Only ftp and scp are supported for this operation (but since these two are
available for browsing, that shouldn't be a problem).  The status bar will
then show, on its right hand side, a message like "Obtaining filename".  The
statusline will be restored after the transfer is complete.

Netrw can also "obtain" a file using the local browser.  Netrw's display
of a directory is not necessarily the same as Vim's "current directory",
unless |g:netrw_keepdir| is set to 0 in the user's <.vimrc>.  One may select
a file using the local browser (by putting the cursor on it) and pressing
"O" will then "obtain" the file; ie. copy it to Vim's current directory.

Related topics:
 * To see what the current directory is, use |:pwd|
 * To make the currently browsed directory the current directory, see |netrw-c|
 * To automatically make the currently browsed directory the current
   directory, see |g:netrw_keepdir|.

					*netrw-newfile* *netrw-createfile*
OPEN A NEW FILE IN NETRW'S CURRENT DIRECTORY		*netrw-%* {{{2

To open a new file in netrw's current directory, press "%".  This map
will query the user for a new filename; an empty file by that name will
be placed in the netrw's current directory (ie. b:netrw_curdir).

Related topics:               |netrw-d|


PREVIEW WINDOW				*netrw-p* *netrw-preview* {{{2

One may use a preview window by using the "p" key when the cursor is atop the
desired filename to be previewed.  The display will then split to show both
the browser (where the cursor will remain) and the file (see |:pedit|).  By
default, the split will be taken horizontally; one may use vertical splitting
if one has set |g:netrw_preview| first.

An interesting set of netrw settings is: >

	let g:netrw_preview   = 1
	let g:netrw_liststyle = 3
	let g:netrw_winsize   = 30

These will:

	1. Make vertical splitting the default for previewing files
	2. Make the default listing style "tree"
	3. When a vertical preview window is opened, the directory listing
	   will use only 30% of the columns available; the rest of the window
	   is used for the preview window.

	Related: if you like this idea, you may also find :Lexplore
	         (|netrw-:Lexplore|) or |g:netrw_chgwin| of interest

Also see: |g:netrw_chgwin| |netrw-P| |'previewwindow'|


PREVIOUS WINDOW					*netrw-P* *netrw-prvwin* {{{2

To edit a file or directory in the previously used (last accessed) window (see
:he |CTRL-W_p|), press a "P".  If there's only one window, then the one window
will be horizontally split (by default).

If there's more than one window, the previous window will be re-used on
the selected file/directory.  If the previous window's associated buffer
has been modified, and there's only one window with that buffer, then
the user will be asked if s/he wishes to save the buffer first (yes,
no, or cancel).

Related Actions |netrw-cr| |netrw-o| |netrw-t| |netrw-v|
Associated setting variables:
   |g:netrw_alto|    control above/below splitting
   |g:netrw_altv|    control right/left splitting
   |g:netrw_preview| control horizontal vs vertical splitting
   |g:netrw_winsize| control initial sizing

Also see: |g:netrw_chgwin| |netrw-p|


REFRESHING THE LISTING		*netrw-refresh* *netrw-ctrl-l* *netrw-ctrl_l* {{{2

To refresh either a local or remote directory listing, press ctrl-l (<c-l>) or
hit the <cr> when atop the ./ directory entry in the listing.  One may also
refresh a local directory by using ":e .".


REVERSING SORTING ORDER		*netrw-r* *netrw-reverse* {{{2

One may toggle between normal and reverse sorting order by pressing the
"r" key.

Related topics:              |netrw-s|
Associated setting variable: |g:netrw_sort_direction|


RENAMING FILES OR DIRECTORIES	*netrw-move* *netrw-rename* *netrw-R* {{{2

If there are no marked files: (see |netrw-mf|)

    Renaming files and directories involves moving the cursor to the
    file/directory to be moved (renamed) and pressing "R".  You will then be
    queried for what you want the file/directory to be renamed to  You may select
    a range of lines with the "V" command (visual selection), and then
    press "R"; you will be queried for each file as to what you want it
    renamed to.

If there are marked files:  (see |netrw-mf|)

    Marked files will be renamed (moved).  You will be queried as above in
    order to specify where you want the file/directory to be moved.

    If you answer a renaming query with a "s/frompattern/topattern/", then
    subsequent files on the marked file list will be renamed by taking each
    name, applying that substitute, and renaming each file to the result.
    As an example : >

    	mr  [query: reply with *.c]
	R   [query: reply with s/^\(.*\)\.c$/\1.cpp/]
<
    This example will mark all *.c files and then rename them to *.cpp
    files.

    The ctrl-X character has special meaning for renaming files: >

    	<c-x>      : a single ctrl-x tells netrw to ignore the portion of the response
	             lying between the last '/' and the ctrl-x.

	<c-x><c-x> : a pair of contiguous ctrl-x's tells netrw to ignore any
		     portion of the string preceding the double ctrl-x's.
<
    WARNING:~

    Note that moving files is a dangerous operation; copies are safer.  That's
    because a "move" for remote files is actually a copy + delete -- and if
    the copy fails and the delete does not, you may lose the file.
    Use at your own risk.

The g:netrw_rename_cmd variable is used to implement remote renaming.  By
default its value is:

	ssh HOSTNAME mv

One may rename a block of files and directories by selecting them with
V (|linewise-visual|) when using thin style


SELECTING SORTING STYLE			*netrw-s* *netrw-sort* {{{2

One may select the sorting style by name, time, or (file) size.  The "s" map
allows one to circulate amongst the three choices; the directory listing will
automatically be refreshed to reflect the selected style.

Related topics:               |netrw-r| |netrw-S|
Associated setting variables: |g:netrw_sort_by| |g:netrw_sort_sequence|


SETTING EDITING WINDOW		*netrw-editwindow* *netrw-C* *netrw-:NetrwC* {{{2

One may select a netrw window for editing with the "C" mapping, using the
:NetrwC [win#] command, or by setting |g:netrw_chgwin| to the selected window
number.  Subsequent selection of a file to edit (|netrw-cr|) will use that
window.

	* C : by itself, will select the current window holding a netrw buffer
	  for editing via |netrw-cr|.  The C mapping is only available while in
	  netrw buffers.

	* [count]C : the count will be used as the window number to be used
	  for subsequent editing via |netrw-cr|.

	* :NetrwC will set |g:netrw_chgwin| to the current window

	* :NetrwC win#  will set |g:netrw_chgwin| to the specified window
	  number

Using >
	let g:netrw_chgwin= -1
will restore the default editing behavior
(ie. editing will use the current window).

Related topics:			|netrw-cr| |g:netrw_browse_split|
Associated setting variables:	|g:netrw_chgwin|


SHRINKING OR EXPANDING A NETRW OR LEXPLORE WINDOW	*netrw-tab* {{{2

The <tab> key will toggle a netrw or |:Lexplore| window's width.

  * If the current window is a netrw window, toggle its width
    (between |g:netrw_wiw| and its original width)

  * Else if there is a |:Lexplore| window in the current tab, toggle
    its width

  * Else bring up a |:Lexplore| window

If |g:netrw_notab| exists or there is a pre-existing mapping for
<tab>, then the <tab> will not be mapped.  One may map something
else: >
	nmap <unique> (whatever)	<Plug>NetrwShrink
<
Related topics:			|:Lexplore|
Associated setting variable:	|g:netrw_notab|


USER SPECIFIED MAPS					*netrw-usermaps* {{{1

One may make customized user maps.  Specify a variable, |g:Netrw_UserMaps|,
to hold a |List| of lists of keymap strings and function names: >

	[["keymap-sequence","ExampleUserMapFunc"],...]
<
When netrw is setting up maps for a netrw buffer, if |g:Netrw_UserMaps|
exists, then the internal function netrw#UserMaps(islocal) is called.
This function goes through all the entries in the |g:Netrw_UserMaps| list:

	* sets up maps: >
		nno <buffer> <silent> KEYMAP-SEQUENCE
		:call s:UserMaps(islocal,"ExampleUserMapFunc")
<	* refreshes if result from that function call is the string
	  "refresh"
	* if the result string is not "", then that string will be
	  executed (:exe result)
	* if the result is a List, then the above two actions on results
	  will be taken for every string in the result List

The user function is passed one argument; it resembles >

	fun! ExampleUserMapFunc(islocal)
<
where a:islocal is 1 if its a local-directory system call or 0 when
remote-directory system call.

Use netrw#Expose("varname")          to access netrw-internal (script-local)
				     variables.
Use netrw#Modify("varname",newvalue) to change netrw-internal variables.
Use netrw#Call("funcname"[,args])    to call a netrw-internal function with
				     specified arguments.

Example: Get a copy of netrw's marked file list: >

	let netrwmarkfilelist= netrw#Expose("netrwmarkfilelist")
<
Example: Modify the value of netrw's marked file list: >

	call netrw#Modify("netrwmarkfilelist",[])
<
Example: Clear netrw's marked file list via a mapping on gu >
    " ExampleUserMap: {{{2
    fun! ExampleUserMap(islocal)
      call netrw#Modify("netrwmarkfilelist",[])
      call netrw#Modify('netrwmarkfilemtch_{bufnr("%")}',"")
      let retval= ["refresh"]
      return retval
    endfun
    let g:Netrw_UserMaps= [["gu","ExampleUserMap"]]
<

10. Problems and Fixes					*netrw-problems* {{{1

	(This section is likely to grow as I get feedback)
	(also see |netrw-debug|)
								*netrw-p1*
	P1. I use windows 95, and my ftp dumps four blank lines at the
	    end of every read.

		See |netrw-fixup|, and put the following into your
		<.vimrc> file:

			let g:netrw_win95ftp= 1

								*netrw-p2*
	P2. I use Windows, and my network browsing with ftp doesn't sort by
	    time or size!  -or-  The remote system is a Windows server; why
	    don't I get sorts by time or size?

		Windows' ftp has a minimal support for ls (ie. it doesn't
		accept sorting options).  It doesn't support the -F which
		gives an explanatory character (ABC/ for "ABC is a directory").
		Netrw then uses "dir" to get both its thin and long listings.
		If you think your ftp does support a full-up ls, put the
		following into your <.vimrc>: >

			let g:netrw_ftp_list_cmd    = "ls -lF"
			let g:netrw_ftp_timelist_cmd= "ls -tlF"
			let g:netrw_ftp_sizelist_cmd= "ls -slF"
<
		Alternatively, if you have cygwin on your Windows box, put
		into your <.vimrc>: >

			let g:netrw_cygwin= 1
<
		This problem also occurs when the remote system is Windows.
		In this situation, the various g:netrw_ftp_[time|size]list_cmds
		are as shown above, but the remote system will not correctly
		modify its listing behavior.


								*netrw-p3*
	P3. I tried rcp://user@host/ (or protocol other than ftp) and netrw
	    used ssh!  That wasn't what I asked for...

		Netrw has two methods for browsing remote directories: ssh
		and ftp.  Unless you specify ftp specifically, ssh is used.
		When it comes time to do download a file (not just a directory
		listing), netrw will use the given protocol to do so.

								*netrw-p4*
	P4. I would like long listings to be the default.

		Put the following statement into your |.vimrc|: >

			let g:netrw_liststyle= 1
<
		Check out |netrw-browser-var| for more customizations that
		you can set.

								*netrw-p5*
	P5. My times come up oddly in local browsing

		Does your system's strftime() accept the "%c" to yield dates
		such as "Sun Apr 27 11:49:23 1997"?  If not, do a
		"man strftime" and find out what option should be used.  Then
		put it into your |.vimrc|: >

			let g:netrw_timefmt= "%X"  (where X is the option)
<
								*netrw-p6*
	P6. I want my current directory to track my browsing.
	    How do I do that?

	    Put the following line in your |.vimrc|:
>
		let g:netrw_keepdir= 0
<
								*netrw-p7*
	P7. I use Chinese (or other non-ascii) characters in my filenames, and
	    netrw (Explore, Sexplore, Hexplore, etc) doesn't display them!

		(taken from an answer provided by Wu Yongwei on the vim
		mailing list)
		I now see the problem. Your code page is not 936, right? Vim
		seems only able to open files with names that are valid in the
		current code page, as are many other applications that do not
		use the Unicode version of Windows APIs. This is an OS-related
		issue. You should not have such problems when the system
		locale uses UTF-8, such as modern Linux distros.

		(...it is one more reason to recommend that people use utf-8!)

								*netrw-p8*
	P8. I'm getting "ssh is not executable on your system" -- what do I
	    do?

		(Dudley Fox) Most people I know use putty for windows ssh.  It
		is a free ssh/telnet application. You can read more about it
		here:

		http://www.chiark.greenend.org.uk/~sgtatham/putty/ Also:

		(Marlin Unruh) This program also works for me. It's a single
		executable, so he/she can copy it into the Windows\System32
		folder and create a shortcut to it.

		(Dudley Fox) You might also wish to consider plink, as it
		sounds most similar to what you are looking for. plink is an
		application in the putty suite.

           http://the.earth.li/~sgtatham/putty/0.58/htmldoc/Chapter7.html#plink

		(Vissale Neang) Maybe you can try OpenSSH for windows, which
		can be obtained from:

		http://sshwindows.sourceforge.net/

		It doesn't need the full Cygwin package.

		(Antoine Mechelynck) For individual Unix-like programs needed
		for work in a native-Windows environment, I recommend getting
		them from the GnuWin32 project on sourceforge if it has them:

		    http://gnuwin32.sourceforge.net/

		Unlike Cygwin, which sets up a Unix-like virtual machine on
		top of Windows, GnuWin32 is a rewrite of Unix utilities with
		Windows system calls, and its programs works quite well in the
		cmd.exe "Dos box".

		(dave) Download WinSCP and use that to connect to the server.
		In Preferences > Editors, set gvim as your editor:

			- Click "Add..."
			- Set External Editor (adjust path as needed, include
			  the quotes and !.! at the end):
			    "c:\Program Files\Vim\vim70\gvim.exe" !.!
			- Check that the filetype in the box below is
			  {asterisk}.{asterisk} (all files), or whatever types
			  you want (cec: change {asterisk} to * ; I had to
			  write it that way because otherwise the helptags
			  system thinks it's a tag)
			- Make sure it's at the top of the listbox (click it,
			  then click "Up" if it's not)
		If using the Norton Commander style, you just have to hit <F4>
		to edit a file in a local copy of gvim.

		(Vit Gottwald) How to generate public/private key and save
		public key it on server: >
  http://www.chiark.greenend.org.uk/~sgtatham/putty/0.60/htmldoc/Chapter8.html#pubkey-gettingready
			(8.3 Getting ready for public key authentication)
<
		How to use a private key with 'pscp': >

  http://www.chiark.greenend.org.uk/~sgtatham/putty/0.60/htmldoc/Chapter5.html
			(5.2.4 Using public key authentication with PSCP)
<
		(Ben Schmidt) I find the ssh included with cwRsync is
		brilliant, and install cwRsync or cwRsyncServer on most
		Windows systems I come across these days. I guess COPSSH,
		packed by the same person, is probably even better for use as
		just ssh on Windows, and probably includes sftp, etc. which I
		suspect the cwRsync doesn't, though it might

		(cec) To make proper use of these suggestions above, you will
		need to modify the following user-settable variables in your
		.vimrc:

		|g:netrw_ssh_cmd| |g:netrw_list_cmd|  |g:netrw_mkdir_cmd|
		|g:netrw_rm_cmd|  |g:netrw_rmdir_cmd| |g:netrw_rmf_cmd|

		The first one (|g:netrw_ssh_cmd|) is the most important; most
		of the others will use the string in g:netrw_ssh_cmd by
		default.
						*netrw-p9* *netrw-ml_get*
	P9. I'm browsing, changing directory, and bang!  ml_get errors
	    appear and I have to kill vim.  Any way around this?

		Normally netrw attempts to avoid writing swapfiles for
		its temporary directory buffers.  However, on some systems
		this attempt appears to be causing ml_get errors to
		appear.  Please try setting |g:netrw_use_noswf| to 0
		in your <.vimrc>: >
			let g:netrw_use_noswf= 0
<
								*netrw-p10*
	P10. I'm being pestered with "[something] is a directory" and
	     "Press ENTER or type command to continue" prompts...

		The "[something] is a directory" prompt is issued by Vim,
		not by netrw, and there appears to be no way to work around
		it.  Coupled with the default cmdheight of 1, this message
		causes the "Press ENTER..." prompt.  So:  read |hit-enter|;
		I also suggest that you set your |'cmdheight'| to 2 (or more) in
		your <.vimrc> file.

								*netrw-p11*
	P11. I want to have two windows; a thin one on the left and my editing
	     window on the right.  How may I accomplish this?

		* Put the following line in your <.vimrc>:
			let g:netrw_altv = 1
		* Edit the current directory:  :e .
		* Select some file, press v
		* Resize the windows as you wish (see |CTRL-W_<| and
		  |CTRL-W_>|).  If you're using gvim, you can drag
		  the separating bar with your mouse.
		* When you want a new file, use  ctrl-w h  to go back to the
		  netrw browser, select a file, then press P  (see |CTRL-W_h|
		  and |netrw-P|).  If you're using gvim, you can press
		  <leftmouse> in the browser window and then press the
		  <middlemouse> to select the file.

								*netrw-p12*
	P12. My directory isn't sorting correctly, or unwanted letters are
	     appearing in the listed filenames, or things aren't lining
	     up properly in the wide listing, ...

	     This may be due to an encoding problem.  I myself usually use
	     utf-8, but really only use ascii (ie. bytes from 32-126).
	     Multibyte encodings use two (or more) bytes per character.
	     You may need to change |g:netrw_sepchr| and/or |g:netrw_xstrlen|.

								*netrw-p13*
	P13. I'm a Windows + putty + ssh user, and when I attempt to browse,
	     the directories are missing trailing "/"s so netrw treats them
	     as file transfers instead of as attempts to browse
	     subdirectories.  How may I fix this?

	     (mikeyao) If you want to use vim via ssh and putty under Windows,
	     try combining the use of pscp/psftp with plink.  pscp/psftp will
	     be used to connect and plink will be used to execute commands on
	     the server, for example: list files and directory using 'ls'.

	     These are the settings I use to do this:
>
	    " list files, it's the key setting, if you haven't set,
	    " you will get a blank buffer
	    let g:netrw_list_cmd = "plink HOSTNAME ls -Fa"
	    " if you haven't add putty directory in system path, you should
	    " specify scp/sftp command.  For examples:
	    "let g:netrw_sftp_cmd = "d:\\dev\\putty\\PSFTP.exe"
	    "let g:netrw_scp_cmd = "d:\\dev\\putty\\PSCP.exe"
<
								*netrw-p14*
	P14. I would like to speed up writes using Nwrite and scp/ssh
	     style connections.  How?  (Thomer M. Gil)

	     Try using ssh's ControlMaster and ControlPath (see the ssh_config
	     man page) to share multiple ssh connections over a single network
	     connection. That cuts out the cryptographic handshake on each
	     file write, sometimes speeding it up by an order of magnitude.
	     (see  http://thomer.com/howtos/netrw_ssh.html)
	     (included by permission)

	     Add the following to your ~/.ssh/config: >

		 # you change "*" to the hostname you care about
		 Host *
		   ControlMaster auto
		   ControlPath /tmp/%r@%h:%p

<	     Then create an ssh connection to the host and leave it running: >

		 ssh -N host.domain.com

<	     Now remotely open a file with Vim's Netrw and enjoy the
	     zippiness: >

		vim scp://host.domain.com//home/user/.bashrc
<
								*netrw-p15*
	P15. How may I use a double-click instead of netrw's usual single click
	     to open a file or directory?  (Ben Fritz)

	     First, disable netrw's mapping with >
		    let g:netrw_mousemaps= 0
<	     and then create a netrw buffer only mapping in
	     $HOME/.vim/after/ftplugin/netrw.vim: >
		    nmap <buffer> <2-leftmouse> <CR>
<	     Note that setting g:netrw_mousemaps to zero will turn off
	     all netrw's mouse mappings, not just the <leftmouse> one.
	     (see |g:netrw_mousemaps|)

								*netrw-p16*
	P16. When editing remote files (ex. :e ftp://hostname/path/file),
	     under Windows I get an |E303| message complaining that its unable
	     to open a swap file.

	     (romainl) It looks like you are starting Vim from a protected
	     directory.  Start netrw from your $HOME or other writable
	     directory.

								*netrw-p17*
	P17. Netrw is closing buffers on its own.
	     What steps will reproduce the problem?
		1. :Explore, navigate directories, open a file
		2. :Explore, open another file
		3. Buffer opened in step 1 will be closed. o
	    What is the expected output? What do you see instead?
		I expect both buffers to exist, but only the last one does.

	   (Lance) Problem is caused by "set autochdir" in .vimrc.
	   (drchip) I am able to duplicate this problem with |'acd'| set.
	            It appears that the buffers are not exactly closed;
		    a ":ls!" will show them (although ":ls" does not).

								*netrw-P18*
	P18. How to locally edit a file that's only available via
	     another server accessible via ssh?
	     See http://stackoverflow.com/questions/12469645/
	     "Using Vim to Remotely Edit A File on ServerB Only
	      Accessible From ServerA"

								*netrw-P19*
	P19. How do I get numbering on in directory listings?
		With |g:netrw_bufsettings|, you can control netrw's buffer
		settings; try putting >
		  let g:netrw_bufsettings="noma nomod nu nobl nowrap ro nornu"
<		in your .vimrc.  If you'd like to have relative numbering
		instead, try >
		  let g:netrw_bufsettings="noma nomod nonu nobl nowrap ro rnu"
<
								*netrw-P20*
	P20. How may I have gvim start up showing a directory listing?
		Try putting the following code snippet into your .vimrc: >
		    augroup VimStartup
		      au!
		      au VimEnter * if expand("%") == "" && argc() == 0 &&
		      \ (v:servername =~ 'GVIM\d*' || v:servername == "")
		      \ | e . | endif
		    augroup END
<		You may use Lexplore instead of "e" if you're so inclined.
		This snippet assumes that you have client-server enabled
		(ie. a "huge" vim version).

								*netrw-P21*
	P21. I've made a directory (or file) with an accented character, but
		netrw isn't letting me enter that directory/read that file:

		Its likely that the shell or o/s is using a different encoding
		than you have vim (netrw) using.  A patch to vim supporting
		"systemencoding" may address this issue in the future; for
		now, just have netrw use the proper encoding.  For example: >

			au FileType netrw set enc=latin1
<

==============================================================================
11. Debugging Netrw Itself				*netrw-debug* {{{1

Step 1: check that the problem you've encountered hasn't already been resolved
by obtaining a copy of the latest (often developmental) netrw at:

	http://www.drchip.org/astronaut/vim/index.html#NETRW

The <netrw.vim> script is typically installed on systems as something like:
>
	/usr/local/share/vim/vim7x/plugin/netrwPlugin.vim
	/usr/local/share/vim/vim7x/autoload/netrw.vim
		(see output of :echo &rtp)
<
which is loaded automatically at startup (assuming :set nocp).  If you
installed a new netrw, then it will be located at >

	$HOME/.vim/plugin/netrwPlugin.vim
	$HOME/.vim/autoload/netrw.vim
<
Step 2: assuming that you've installed the latest version of netrw,
check that your problem is really due to netrw.  Create a file
called netrw.vimrc with the following contents: >

	set nocp
	so $HOME/.vim/plugin/netrwPlugin.vim
<
Then run netrw as follows: >

	vim -u netrw.vimrc --noplugins [some path here]
<
Perform whatever netrw commands you need to, and check that the problem is
still present.  This procedure sidesteps any issues due to personal .vimrc
settings and other plugins.  If the problem does not appear, then you need
to determine what setting in your .vimrc is causing the conflict with netrw
or which plugin.

Step 3: If the problem still is present, then get a debugging trace from
netrw:

	1. Get the <Decho.vim> script, available as:

	     http://www.drchip.org/astronaut/vim/index.html#DECHO
	   or
	     http://vim.sourceforge.net/scripts/script.php?script_id=120

	  Decho.vim is provided as a "vimball"; see |vimball-intro|.

	2. Edit the <netrw.vim> file by typing: >

		vim netrw.vim
		:DechoOn
		:wq
<
	   To restore to normal non-debugging behavior, re-edit <netrw.vim>
	   and type >

		vim netrw.vim
		:DechoOff
		:wq
<
	   This command, provided by <Decho.vim>, will comment out all
	   Decho-debugging statements (Dfunc(), Dret(), Decho(), Dredir()).

	3. Then bring up vim and attempt to evoke the problem by doing a
	   transfer or doing some browsing.  A set of messages should appear
	   concerning the steps that <netrw.vim> took in attempting to
	   read/write your file over the network in a separate tab or
	   server vim window.

	   To save the file, use >

		:tabnext
		:set bt=
		:w! DBG

<	   Furthermore, it'd be helpful if you would type >
		:Dsep <command>
<	   where <command> is the command you're about to type next,
	   thereby making it easier to associate which part of the
	   debugging trace is due to which command.

	   Please send that information to <netrw.vim>'s maintainer along
	   with the o/s you're using and the vim version that you're using
	   (see |:version|) >
		NdrOchip at ScampbellPfamily.AbizM - NOSPAM
<
==============================================================================
12. History						*netrw-history* {{{1

	v154:	Feb 26, 2015	* (Yuri Kanivetsky) reported a situation where
				  a file was not treated properly as a file
				  due to g:netrw_keepdir == 1
		Mar 25, 2015	* (requested by Ben Friz) one may now sort by
				  extension
		Mar 28, 2015	* (requested by Matt Brooks) netrw has a lot
				  of buffer-local mappings; however, some
				  plugins (such as vim-surround) set up
				  conflicting mappings that cause vim to wait.
				  The |<nowait>| modifier has been included
				  with most of netrw's mappings to avoid that
				  delay.
		Jun 26, 2015	* |netrw-gn| mapping implemted
				* :Ntree NotADir resulted in having
				  the tree listing expand in the error messages
				  window.  Fixed.
		Jun 29, 2015	* Attempting to delete a file remotely caused
				  an error with "keepsol" mentioned; fixed.
		Jul 08, 2015	* Several changes to keep the |:jumps| table
				  correct when working with
				  |g:netrw_fastbrowse| set to 2
				* wide listing with accented characters fixed
				  (using %-S instead of %-s with a |printf()|
		Jul 13, 2015	* (Daniel Hahler) CheckIfKde() could be true
				  but kfmclient not installed.  Changed order
				  in netrw#BrowseX(): checks if kde and
				  kfmclient, then will use xdg-open on a unix
				  system (if xdg-open is executable)
		Aug 11, 2015	* (McDonnell) tree listing mode wouldn't
				  select a file in a open subdirectory.
				* (McDonnell) when multiple subdirectories
				  were concurrently open in tree listing
				  mode, a ctrl-L wouldn't refresh properly.
				* The netrw:target menu showed duplicate
				  entries
	v153:	May 13, 2014	* added another |g:netrw_ffkeep| usage {{{2
		May 14, 2014	* changed s:PerformListing() so that it
				  always sets ft=netrw for netrw buffers
				  (ie. even when syntax highlighting is
				  off, not available, etc)
		May 16, 2014	* introduced the |netrw-ctrl-r| functionality
		May 17, 2014	* introduced the |netrw-:NetrwMB| functionality
				* mb and mB (|netrw-mb|, |netrw-mB|) will
				  add/remove marked files from bookmark list
		May 20, 2014	* (Enno Nagel) reported that :Lex <dirname>
				  wasn't working.  Fixed.
		May 26, 2014	* restored test to prevent leftmouse window
				  resizing from causing refresh.
				  (see s:NetrwLeftmouse())
				* fixed problem where a refresh caused cursor
				  to go just under the banner instead of
				  staying put
		May 28, 2014	* (László Bimba) provided a patch for opening
				  the |:Lexplore| window 100% high, optionally
				  on the right, and will work with remote
				  files.
		May 29, 2014	* implemented :NetrwC  (see |netrw-:NetrwC|)
		Jun 01, 2014	* Removed some "silent"s from commands used
				  to implemented scp://... and pscp://...
				  directory listing.  Permits request for
				  password to appear.
		Jun 05, 2014	* (Enno Nagel) reported that user maps "/"
				  caused problems with "b" and "w", which
				  are mapped (for wide listings only) to
				  skip over files rather than just words.
		Jun 10, 2014	* |g:netrw_gx| introduced to allow users to
				  override default "<cfile>" with the gx
				  (|netrw-gx|) map
		Jun 11, 2014	* gx (|netrw-gx|), with |'autowrite'| set,
				  will write modified files.  s:NetrwBrowseX()
				  will now save, turn off, and restore the
				  |'autowrite'| setting.
		Jun 13, 2014	* added visual map for gx use
		Jun 15, 2014	* (Enno Nagel) reported that with having hls
				  set and wide listing style in use, that the
				  b and w maps caused unwanted highlighting.
		Jul 05, 2014	* |netrw-mv| and |netrw-mX| commands included
		Jul 09, 2014	* |g:netrw_keepj| included, allowing optional
				  keepj
		Jul 09, 2014	* fixing bugs due to previous update
		Jul 21, 2014	* (Bruno Sutic) provided an updated
				  netrw_gitignore.vim
		Jul 30, 2014	* (Yavuz Yetim) reported that editing two
				  remote files of the same name caused the
				  second instance to have a "temporary"
				  name.  Fixed: now they use the same buffer.
		Sep 18, 2014	* (Yasuhiro Matsumoto) provided a patch which
				  allows scp and windows local paths to work.
		Oct 07, 2014	* gx (see |netrw-gx|) when atop a directory,
				  will now do |gf| instead
		Nov 06, 2014	* For cygwin: cygstart will be available for
				  netrw#BrowseX() to use if its executable.
		Nov 07, 2014	* Began support for file://... urls.  Will use
				  |g:netrw_file_cmd| (typically elinks or links)
		Dec 02, 2014	* began work on having mc (|netrw-mc|) copy
				  directories.  Works for linux machines,
				  cygwin+vim, but not for windows+gvim.
		Dec 02, 2014	* in tree mode, netrw was not opening
				  directories via symbolic links.
		Dec 02, 2014	* added resolved link information to
				  thin and tree modes
		Dec 30, 2014	* (issue#231) |:ls| was not showing
				  remote-file buffers reliably.  Fixed.
	v152:	Apr 08, 2014	* uses the |'noswapfile'| option (requires {{{2
				  vim 7.4 with patch 213)
				* (Enno Nagel) turn |'rnu'| off in netrw
				  buffers.
				* (Quinn Strahl) suggested that netrw
				  allow regular window splitting to occur,
				  thereby allowing |'equalalways'| to take
				  effect.
				* (qingtian zhao) normally, netrw will
				  save and restore the |'fileformat'|;
				  however, sometimes that isn't wanted
		Apr 14, 2014	* whenever netrw marks a buffer as ro,
				  it will also mark it as nomod.
		Apr 16, 2014	* sftp protocol now supported by
				  netrw#Obtain(); this means that one
				  may use "mc" to copy a remote file
				  to a local file using sftp, and that
				  the |netrw-O| command can obtain remote
				  files via sftp.
				* added [count]C support (see |netrw-C|)
		Apr 18, 2014	* when |g:netrw_chgwin| is one more than
				  the last window, then vertically split
				  the last window and use it as the
				  chgwin window.
		May 09, 2014	* SavePosn was "saving filename under cursor"
				  from a non-netrw window when using :Rex.
	v151:	Jan 22, 2014	* extended :Rexplore to return to buffer {{{2
				  prior to Explore or editing a directory
				* (Ken Takata) netrw gave error when
				  clipboard was disabled.  Sol'n: Placed
				  several if has("clipboard") tests in.
				* Fixed ftp://X@Y@Z// problem; X@Y now
				  part of user id, and only Z is part of
				  hostname.
				* (A Loumiotis) reported that completion
				  using a directory name containing spaces
				  did not work.  Fixed with a retry in
				  netrw#Explore() which removes the
				  backslashes vim inserted.
		Feb 26, 2014	* :Rexplore now records the current file
				   using w:netrw_rexfile when returning via
				  |:Rexplore|
		Mar 08, 2014	* (David Kotchan) provided some patches
				  allowing netrw to work properly with
				  windows shares.
				* Multiple one-liner help messages available
				  by pressing <cr> while atop the "Quick
				  Help" line
				* worked on ShellCmdPost, FocusGained event
				  handling.
				* |:Lexplore| path: will be used to update
				  a left-side netrw browsing directory.
		Mar 12, 2014	* |:netrw-s-cr|: use <s-cr>  to close
				  tree directory implemented
		Mar 13, 2014	* (Tony Mechylynck) reported that using
				  the browser with ftp on a directory,
				  and selecting a gzipped txt file, that
				  an E19 occurred (which was issued by
				  gzip.vim).  Fixed.
		Mar 14, 2014	* Implemented :MF and :MT (see |netrw-:MF|
				  and |netrw-:MT|, respectively)
		Mar 17, 2014	* |:Ntree| [dir] wasn't working properly; fixed
		Mar 18, 2014	* Changed all uses of set to setl
		Mar 18, 2014	* Commented the netrw_btkeep line in
				  s:NetrwOptionSave(); the effect is that
				  netrw buffers will remain as |'bt'|=nofile.
				  This should prevent swapfiles being created
				  for netrw buffers.
		Mar 20, 2014	* Changed all uses of lcd to use s:NetrwLcd()
				  instead.  Consistent error handling results
				  and it also handles Window's shares
				* Fixed |netrw-d| command when applied with ftp
				* https: support included for netrw#NetRead()
	v150:	Jul 12, 2013	* removed a "keepalt" to allow ":e #" to {{{2
				  return to the netrw directory listing
		Jul 13, 2013	* (Jonas Diemer) suggested changing
				  a <cWORD> to <cfile>.
		Jul 21, 2013	* (Yuri Kanivetsky) reported that netrw's
				  use of mkdir did not produce directories
				  following the user's umask.
		Aug 27, 2013	* introduced |g:netrw_altfile| option
		Sep 05, 2013	* s:Strlen() now uses |strdisplaywidth()|
				  when available, by default
		Sep 12, 2013	* (Selyano Baldo) reported that netrw wasn't
				  opening some directories properly from the
				  command line.
		Nov 09, 2013	* |:Lexplore| introduced
				* (Ondrej Platek) reported an issue with
				  netrw's trees (P15).  Fixed.
				* (Jorge Solis) reported that "t" in
				  tree mode caused netrw to forget its
				  line position.
		Dec 05, 2013	* Added <s-leftmouse> file marking
				  (see |netrw-mf|)
		Dec 05, 2013	* (Yasuhiro Matsumoto) Explore should use
				  strlen() instead s:Strlen() when handling
				  multibyte chars with strpart()
				  (ie. strpart() is byte oriented, not
				  display-width oriented).
		Dec 09, 2013	* (Ken Takata) Provided a patch; File sizes
				  and a portion of timestamps were wrongly
				  highlighted with the directory color when
				  setting `:let g:netrw_liststyle=1` on Windows.
				* (Paul Domaskis) noted that sometimes
				  cursorline was activating in non-netrw
				  windows.  All but one setting of cursorline
				  was done via setl; there was one that was
				  overlooked.  Fixed.
		Dec 24, 2013	* (esquifit) asked that netrw allow the
				  /cygdrive prefix be a user-alterable
				  parameter.
		Jan 02, 2014	* Fixed a problem with netrw-based ballon
				  evaluation (ie. netrw#NetrwBaloonHelp()
				  not having been loaded error messages)
		Jan 03, 2014	* Fixed a problem with tree listings
				* New command installed: |:Ntree|
		Jan 06, 2014	* (Ivan Brennan) reported a problem with
				  |netrw-P|.  Fixed.
		Jan 06, 2014	* Fixed a problem with |netrw-P| when the
				  modified file was to be abandoned.
		Jan 15, 2014	* (Matteo Cavalleri) reported that when the
				  banner is suppressed and tree listing is
				  used, a blank line was left at the top of
				  the display.  Fixed.
		Jan 20, 2014	* (Gideon Go) reported that, in tree listing
				  style, with a previous window open, that
				  the wrong directory was being used to open
				  a file.  Fixed. (P21)
	v149:	Apr 18, 2013	* in wide listing format, now have maps for {{{2
				  w and b to move to next/previous file
		Apr 26, 2013	* one may now copy files in the same
				  directory; netrw will issue requests for
				  what names the files should be copied under
		Apr 29, 2013	* Trying Benzinger's problem again.  Seems
				  that commenting out the BufEnter and
				  installing VimEnter (only) works.  Weird
				  problem!  (tree listing, vim -O Dir1 Dir2)
		May 01, 2013	* :Explore ftp://... wasn't working.  Fixed.
		May 02, 2013	* introduced |g:netrw_bannerbackslash| as
				  requested by Paul Domaskis.
		Jul 03, 2013	* Explore now avoids splitting when a buffer
				  will be hidden.
	v148:	Apr 16, 2013	* changed Netrw's Style menu to allow direct {{{2
				  choice of listing style, hiding style, and
				  sorting style

==============================================================================
13. Todo						*netrw-todo* {{{1

07/29/09 : banner	:|g:netrw_banner| can be used to suppress the
	   suppression	  banner.  This feature is new and experimental,
			  so its in the process of being debugged.
09/04/09 : "gp"		: See if it can be made to work for remote systems.
			: See if it can be made to work with marked files.

==============================================================================
14. Credits						*netrw-credits* {{{1

	Vim editor	by Bram Moolenaar (Thanks, Bram!)
	dav		support by C Campbell
	fetch		support by Bram Moolenaar and C Campbell
	ftp		support by C Campbell <NdrOchip@ScampbellPfamily.AbizM>
	http		support by Bram Moolenaar <bram@moolenaar.net>
	rcp
	rsync		support by C Campbell (suggested by Erik Warendorph)
	scp		support by raf <raf@comdyn.com.au>
	sftp		support by C Campbell

	inputsecret(), BufReadCmd, BufWriteCmd contributed by C Campbell

	Jérôme Augé		-- also using new buffer method with ftp+.netrc
	Bram Moolenaar		-- obviously vim itself, :e and v:cmdarg use,
	                           fetch,...
	Yasuhiro Matsumoto	-- pointing out undo+0r problem and a solution
	Erik Warendorph		-- for several suggestions (g:netrw_..._cmd
				   variables, rsync etc)
	Doug Claar		-- modifications to test for success with ftp
	                           operation

==============================================================================
Modelines: {{{1
 vim:tw=78:ts=8:ft=help:norl:fdm=marker
syntax/netrw.vim	[[[1
123
" Language   : Netrw Remote-Directory Listing Syntax
" Maintainer : Charles E. Campbell
" Last change: Oct 06, 2014
" Version    : 19
" ---------------------------------------------------------------------

" Syntax Clearing: {{{1
if version < 600
 syntax clear
elseif exists("b:current_syntax")
 finish
endif

" ---------------------------------------------------------------------
" Directory List Syntax Highlighting: {{{1
syn cluster NetrwGroup		contains=netrwHide,netrwSortBy,netrwSortSeq,netrwQuickHelp,netrwVersion,netrwCopyTgt
syn cluster NetrwTreeGroup	contains=netrwDir,netrwSymLink,netrwExe

syn match  netrwPlain		"\(\S\+ \)*\S\+"					contains=netrwLink,@NoSpell
syn match  netrwSpecial		"\%(\S\+ \)*\S\+[*|=]\ze\%(\s\{2,}\|$\)"		contains=netrwClassify,@NoSpell
syn match  netrwDir		"\.\{1,2}/"						contains=netrwClassify,@NoSpell
syn match  netrwDir		"\%(\S\+ \)*\S\+/\ze\%(\s\{2,}\|$\)"			contains=netrwClassify,@NoSpell
syn match  netrwSizeDate	"\<\d\+\s\d\{1,2}/\d\{1,2}/\d\{4}\s"	skipwhite	contains=netrwDateSep,@NoSpell	nextgroup=netrwTime
syn match  netrwSymLink		"\%(\S\+ \)*\S\+@\ze\%(\s\{2,}\|$\)"  			contains=netrwClassify,@NoSpell
syn match  netrwExe		"\%(\S\+ \)*\S*[^~]\*\ze\%(\s\{2,}\|$\)" 		contains=netrwClassify,@NoSpell
if has("gui_running") && (&enc == 'utf-8' || &enc == 'utf-16' || &enc == 'ucs-4')
syn match  netrwTreeBar		"^\%([-+|│] \)\+"					contains=netrwTreeBarSpace	nextgroup=@netrwTreeGroup
else
syn match  netrwTreeBar		"^\%([-+|] \)\+"					contains=netrwTreeBarSpace	nextgroup=@netrwTreeGroup
endif
syn match  netrwTreeBarSpace	" "					contained

syn match  netrwClassify	"[*=|@/]\ze\%(\s\{2,}\|$\)"		contained
syn match  netrwDateSep		"/"					contained
syn match  netrwTime		"\d\{1,2}:\d\{2}:\d\{2}"		contained	contains=netrwTimeSep
syn match  netrwTimeSep		":"

syn match  netrwComment		'".*\%(\t\|$\)'						contains=@NetrwGroup,@NoSpell
syn match  netrwHide		'^"\s*\(Hid\|Show\)ing:'	skipwhite		contains=@NoSpell		nextgroup=netrwHidePat
syn match  netrwSlash		"/"				contained
syn match  netrwHidePat		"[^,]\+"			contained skipwhite	contains=@NoSpell		nextgroup=netrwHideSep
syn match  netrwHideSep		","				contained skipwhite					nextgroup=netrwHidePat
syn match  netrwSortBy		"Sorted by"			contained transparent skipwhite				nextgroup=netrwList
syn match  netrwSortSeq		"Sort sequence:"		contained transparent skipwhite			 	nextgroup=netrwList
syn match  netrwCopyTgt		"Copy/Move Tgt:"		contained transparent skipwhite				nextgroup=netrwList
syn match  netrwList		".*$"				contained		contains=netrwComma,@NoSpell
syn match  netrwComma		","				contained
syn region netrwQuickHelp	matchgroup=Comment start="Quick Help:\s\+" end="$"	contains=netrwHelpCmd,netrwQHTopic,@NoSpell	keepend contained
syn match  netrwHelpCmd		"\S\+\ze:"			contained skipwhite	contains=@NoSpell		nextgroup=netrwCmdSep
syn match  netrwQHTopic		"([a-zA-Z &]\+)"		contained skipwhite
syn match  netrwCmdSep		":"				contained nextgroup=netrwCmdNote
syn match  netrwCmdNote		".\{-}\ze  "			contained		contains=@NoSpell
syn match  netrwVersion		"(netrw.*)"			contained		contains=@NoSpell
syn match  netrwLink		"-->"				contained skipwhite

" -----------------------------
" Special filetype highlighting {{{1
" -----------------------------
if exists("g:netrw_special_syntax") && netrw_special_syntax
 syn match netrwBak		"\(\S\+ \)*\S\+\.bak\>"				contains=netrwTreeBar,@NoSpell
 syn match netrwCompress	"\(\S\+ \)*\S\+\.\%(gz\|bz2\|Z\|zip\)\>"	contains=netrwTreeBar,@NoSpell
 if has("unix")
  syn match netrwCoreDump	"\<core\%(\.\d\+\)\=\>"				contains=netrwTreeBar,@NoSpell
 endif
 syn match netrwLex		"\(\S\+ \)*\S\+\.\%(l\|lex\)\>"			contains=netrwTreeBar,@NoSpell
 syn match netrwYacc		"\(\S\+ \)*\S\+\.y\>"				contains=netrwTreeBar,@NoSpell
 syn match netrwData		"\(\S\+ \)*\S\+\.dat\>"				contains=netrwTreeBar,@NoSpell
 syn match netrwDoc		"\(\S\+ \)*\S\+\.\%(doc\|txt\|pdf\|ps\)"	contains=netrwTreeBar,@NoSpell
 syn match netrwHdr		"\(\S\+ \)*\S\+\.\%(h\|hpp\)\>"			contains=netrwTreeBar,@NoSpell
 syn match netrwLib		"\(\S\+ \)*\S*\.\%(a\|so\|lib\|dll\)\>"		contains=netrwTreeBar,@NoSpell
 syn match netrwMakeFile	"\<[mM]akefile\>\|\(\S\+ \)*\S\+\.mak\>"	contains=netrwTreeBar,@NoSpell
 syn match netrwObj		"\(\S\+ \)*\S*\.\%(o\|obj\)\>"			contains=netrwTreeBar,@NoSpell
 syn match netrwTags		"\<\(ANmenu\|ANtags\)\>"			contains=netrwTreeBar,@NoSpell
 syn match netrwTags    	"\<tags\>"					contains=netrwTreeBar,@NoSpell
 syn match netrwTilde		"\(\S\+ \)*\S\+\~\*\=\>"			contains=netrwTreeBar,@NoSpell
 syn match netrwTmp		"\<tmp\(\S\+ \)*\S\+\>\|\(\S\+ \)*\S*tmp\>"	contains=netrwTreeBar,@NoSpell
endif

" ---------------------------------------------------------------------
" Highlighting Links: {{{1
if !exists("did_drchip_netrwlist_syntax")
 let did_drchip_netrwlist_syntax= 1
 hi default link netrwClassify	Function
 hi default link netrwCmdSep	Delimiter
 hi default link netrwComment	Comment
 hi default link netrwDir	Directory
 hi default link netrwHelpCmd	Function
 hi default link netrwQHTopic	Number
 hi default link netrwHidePat	Statement
 hi default link netrwHideSep	netrwComment
 hi default link netrwList	Statement
 hi default link netrwVersion	Identifier
 hi default link netrwSymLink	Question
 hi default link netrwExe	PreProc
 hi default link netrwDateSep	Delimiter

 hi default link netrwTreeBar	Special
 hi default link netrwTimeSep	netrwDateSep
 hi default link netrwComma	netrwComment
 hi default link netrwHide	netrwComment
 hi default link netrwMarkFile	TabLineSel
 hi default link netrwLink	Special

 " special syntax highlighting (see :he g:netrw_special_syntax)
 hi default link netrwBak	NonText
 hi default link netrwCompress	Folded
 hi default link netrwCoreDump	WarningMsg
 hi default link netrwData	DiffChange
 hi default link netrwHdr	netrwPlain
 hi default link netrwLex	netrwPlain
 hi default link netrwLib	DiffChange
 hi default link netrwMakefile	DiffChange
 hi default link netrwObj	Folded
 hi default link netrwTilde	Folded
 hi default link netrwTmp	Folded
 hi default link netrwTags	Folded
 hi default link netrwYacc	netrwPlain
endif

" Current Syntax: {{{1
let   b:current_syntax = "netrwlist"
" ---------------------------------------------------------------------
" vim: ts=8 fdm=marker
autoload/netrw_gitignore.vim	[[[1
78
" netrw_gitignore#Hide: gitignore-based hiding
"  Function returns a string of comma separated patterns convenient for
"  assignment to `g:netrw_list_hide` option.
"  Function can take additional filenames as arguments, example:
"  netrw_gitignore#Hide('custom_gitignore1', 'custom_gitignore2')
"
" Usage examples:
"  let g:netrw_list_hide = netrw_gitignore#Hide()
"  let g:netrw_list_hide = netrw_gitignore#Hide() . 'more,hide,patterns'
"
" Copyright:    Copyright (C) 2013 Bruno Sutic {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               netrw_gitignore.vim is provided *as is* and comes with no
"               warranty of any kind, either expressed or implied. By using
"               this plugin, you agree that in no event will the copyright
"               holder be liable for any damages resulting from the use
"               of this software.
function! netrw_gitignore#Hide(...)
  let additional_files = a:000

  let default_files = ['.gitignore', '.git/info/exclude']

  " get existing global/system gitignore files
  let global_gitignore = expand(substitute(system("git config --global core.excludesfile"), '\n', '', 'g'))
  if global_gitignore !=# ''
    let default_files = add(default_files, global_gitignore)
  endif
  let system_gitignore = expand(substitute(system("git config --system core.excludesfile"), '\n', '', 'g'))
  if system_gitignore !=# ''
    let default_files = add(default_files, system_gitignore)
  endif

  " append additional files if given as function arguments
  if additional_files !=# []
    let files = extend(default_files, additional_files)
  else
    let files = default_files
  endif

  " keep only existing/readable files
  let gitignore_files = []
  for file in files
    if filereadable(file)
      let gitignore_files = add(gitignore_files, file)
    endif
  endfor

  " get contents of gitignore patterns from those files
  let gitignore_lines = []
  for file in gitignore_files
    for line in readfile(file)
      " filter empty lines and comments
      if line !~# '^#' && line !~# '^$'
        let gitignore_lines = add(gitignore_lines, line)
      endif
    endfor
  endfor

  " convert gitignore patterns to Netrw/Vim regex patterns
  let escaped_lines = []
  for line in gitignore_lines
    let escaped = line
    let escaped = substitute(escaped, '\*\*', '*', 'g')
    let escaped = substitute(escaped, '\.', '\\.', 'g')
    let escaped = substitute(escaped, '\$', '\\$', 'g')
    let escaped = substitute(escaped, '*', '.*', 'g')
    " correction: dot, dollar and asterisks chars shouldn't be escaped when
    " within regex matching groups.
    let escaped = substitute(escaped, '\(\[[^]]*\)\zs\\\.', '\.', 'g')
    let escaped = substitute(escaped, '\(\[[^]]*\)\zs\\\$', '\$', 'g')
    let escaped = substitute(escaped, '\(\[[^]]*\)\zs\.\*', '*', 'g')
    let escaped_lines = add(escaped_lines, escaped)
  endfor

  return join(escaped_lines, ',')
endfunction
