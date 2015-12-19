if exists('did_load_filetypes')
    finish
endif

augroup filetypedetect
autocmd BufNewFile,BufRead * if getline(1) =~# '^#!.*/usr/bin/env\s\+node\>' | setfiletype javascript | endif
augroup END
