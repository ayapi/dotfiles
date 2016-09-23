local color = require('color');

function ayapi_prompt_filter()
  local cwd = clink.get_cwd()
  local name = clink.get_env('USERNAME') .. '@' .. clink.get_env('COMPUTERNAME')
  local datetime = os.date("%y-%m-%d %H:%M:%S")
  local home = clink.get_env('USERPROFILE')
  local root = clink.get_env('HOMEDRIVE') .. "\\"
  
  cwd = string.gsub(cwd, home, '~', 1)
  cwd = string.gsub(cwd, root, '/', 1)
  cwd = string.gsub(cwd, '\\', '/')
  
  local branch = ""
  for line in io.popen("git branch 2>nul"):lines() do
    branch = line:match("%* (.+)$")
    if branch then
      break
    end
  end
  
  local cols = clink.get_screen_info().window_width
  local used_cols = 2 + string.len(name) + 2 + string.len(datetime) + 2
  if (branch ~= '') then
    used_cols = used_cols + string.len(branch) + 2
  end
  local remain_cols = cols - used_cols
  if (remain_cols > 2) then
    local cwd_len = string.len(cwd)
    if (cwd_len > remain_cols) then
      cwd = '..' .. string.sub(cwd, (remain_cols - 2) * -1)
    else
      cwd = cwd .. string.rep(' ', remain_cols - cwd_len)
    end
  end
  
  local cells = {
    color.color_text(' ' .. name .. ' ', color.WHITE ,color.MAGENTA),
    color.color_text(' ' .. cwd .. ' ', color.WHITE, color.BLACK),
    color.color_text(' ' .. datetime .. ' ', color.BLACK ,color.WHITE),
    "\n > "
  }
  
  if (branch ~= '') then
    table.insert(cells, 2,
      color.color_text(' ' .. branch .. ' ', color.BLACK, color.CYAN)
    )
  end
  
  clink.prompt.value = table.concat(cells, '')
  return false
end

clink.prompt.register_filter(ayapi_prompt_filter, 0)