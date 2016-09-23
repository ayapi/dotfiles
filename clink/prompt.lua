local color = require('color');

function ayapi_prompt_filter()
  local name = os.getenv("USERNAME") .. '@' .. os.getenv("COMPUTERNAME")
  local datetime = os.date("%Y-%m-%d %H:%M:%S")
  local pwd = io.popen("cd"):read('*l')
  local branch = ""
  
  for line in io.popen("git branch 2>nul"):lines() do
    branch = line:match("%* (.+)$")
    if branch then
      break
    end
  end
  
  local cols = io.popen("tput cols"):read('*l') - 1
  local used_cols = 2 + string.len(name) + 2 + string.len(datetime) + 2
  if (branch ~= '') then
    used_cols = used_cols + string.len(branch) + 2
  end
  local remain_cols = cols - used_cols
  if (remain_cols > 2) then
    local pwd_len = string.len(pwd)
    if (pwd_len > remain_cols) then
      pwd = '..' .. string.sub(pwd, (remain_cols - 2) * -1)
    else
      pwd = pwd .. string.rep(' ', remain_cols - pwd_len)
    end
  end
  
  local cells = {
    color.color_text(' ' .. name .. ' ', color.WHITE ,color.MAGENTA),
    color.color_text(' ' .. pwd .. ' ', color.WHITE, color.BLACK),
    color.color_text(' ' .. datetime .. ' ', color.BLACK ,color.WHITE),
    "\n "
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