local M = {}

-- Chat window state
local chat_win = nil
local chat_buf = nil
local input_buf = nil
local input_win = nil
local chat_history = {}
local current_job = nil -- Track current ollama job

-- گرفتن متن انتخابی یا خط جاری
function M.get_selection()
  -- First try to get visual selection if we were just in visual mode
  local vstart = vim.fn.getpos("'<")
  local vend = vim.fn.getpos("'>")

  -- Check if we have a valid visual selection
  if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
    local lines = vim.fn.getline(vstart[2], vend[2])
    if #lines == 1 then
      -- Single line selection
      lines[1] = string.sub(lines[1], vstart[3], vend[3])
    else
      -- Multi-line selection
      lines[1] = string.sub(lines[1], vstart[3])
      lines[#lines] = string.sub(lines[#lines], 1, vend[3])
    end
    return table.concat(lines, "\n")
  else
    -- No selection, get current line
    return vim.fn.getline(".")
  end
end

-- اجرای Ollama async (truly async using jobstart)
function M.query_ollama_async(text, callback)
  -- Stop current job if running
  if current_job and vim.fn.jobstop then
    vim.fn.jobstop(current_job)
    current_job = nil
  end

  -- Clean and prepare text
  local clean_text = text:gsub('"', '\\"'):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

  if clean_text == "" then
    callback("Error: Empty text provided")
    return
  end

  -- Create a temporary file to pass text to ollama (to avoid shell escaping issues)
  local temp_file = vim.fn.tempname()
  vim.fn.writefile({ clean_text }, temp_file)

  local cmd =
  { "sh", "-c", string.format('cat "%s" | ollama run qwen3:4b-instruct-2507-q4_K_M 2>/dev/null', temp_file) }

  local response_lines = {}
  local callback_called = false

  current_job = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            -- Clean escape codes but keep most content
            local clean_line = line
                :gsub("\27%[[%d;]*[mK]", "") -- Remove ANSI escape codes
                :gsub("%[%?25[lh]", "") -- Remove cursor visibility codes
                :gsub("\r", "")     -- Remove carriage returns

            -- Only filter out ollama stats, keep everything else
            if
                not clean_line:match("^total duration:")
                and not clean_line:match("^load duration:")
                and not clean_line:match("^prompt eval")
                and not clean_line:match("^eval count:")
                and not clean_line:match("^eval duration:")
                and not clean_line:match("^eval rate:")
            then
              table.insert(response_lines, clean_line)
            end
          end
        end
      end
    end,
    on_stderr = function(_, err)
      -- Silently handle errors
    end,
    on_exit = function(_, exit_code)
      -- Clean up temp file
      vim.fn.delete(temp_file)

      if not callback_called then
        callback_called = true

        if exit_code == 0 then
          if #response_lines > 0 then
            local final_response = table.concat(response_lines, "\n")
            -- Clean up excessive whitespace but preserve structure
            final_response = final_response:gsub("\n\n\n+", "\n\n"):gsub("^%s*", ""):gsub("%s*$", "")

            -- Limit response length if too long
            if #final_response > 2000 then
              final_response = final_response:sub(1, 2000) .. "\n\n[Response truncated - too long]"
            end

            callback(final_response)
          else
            callback("No response from Ollama")
          end
        else
          callback("Command failed with exit code: " .. exit_code)
        end
      end
    end,
  })
end

-- نمایش پاسخ در floating window
function M.show_response(response)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(response, "\n"))
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Add message to chat history and display
function M.add_to_chat(message, is_user)
  local timestamp = os.date("%H:%M")
  local prefix = is_user and "[" .. timestamp .. "] You: " or "[" .. timestamp .. "] AI: "
  local formatted_message = prefix .. message

  table.insert(chat_history, formatted_message)

  if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
    vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, vim.split(formatted_message, "\n"))
    vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, { "" })
    vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)

    -- Auto scroll to bottom
    if chat_win and vim.api.nvim_win_is_valid(chat_win) then
      local line_count = vim.api.nvim_buf_line_count(chat_buf)
      vim.api.nvim_win_set_cursor(chat_win, { line_count, 0 })
    end
  end
end

-- Create or show chat window as resizable panes
function M.toggle_chat_window()
  -- Check if chat windows exist and are valid
  local chat_exists = chat_win and vim.api.nvim_win_is_valid(chat_win)
  local input_exists = input_win and vim.api.nvim_win_is_valid(input_win)

  if chat_exists or input_exists then
    -- Close chat windows
    if chat_exists then
      vim.api.nvim_win_close(chat_win, true)
    end
    if input_exists then
      vim.api.nvim_win_close(input_win, true)
    end
    chat_win = nil
    input_win = nil
    return
  end

  -- Create chat buffer if it doesn't exist
  if not chat_buf or not vim.api.nvim_buf_is_valid(chat_buf) then
    chat_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(chat_buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(chat_buf, "swapfile", false)
    vim.api.nvim_buf_set_option(chat_buf, "filetype", "markdown")
    vim.api.nvim_buf_set_name(chat_buf, "[Ollama Chat]")

    -- Add welcome message
    local welcome = "=== Ollama Chat ==="
    vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, { welcome, "" })
    vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)
  end

  -- Create input buffer if it doesn't exist
  if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
    input_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(input_buf, "buftype", "nofile")
    vim.api.nvim_buf_set_option(input_buf, "swapfile", false)
    vim.api.nvim_buf_set_option(input_buf, "filetype", "text")
    vim.api.nvim_buf_set_name(input_buf, "[Ollama Input]")
  end

  -- Create vertical split on the right (40% width)
  vim.cmd("rightbelow 40vnew")
  chat_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(chat_win, chat_buf)

  -- Create horizontal split in chat pane for input (larger height)
  vim.cmd('rightbelow 8split')
  input_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(input_win, input_buf)

  -- Set up input buffer keymaps
  vim.api.nvim_buf_set_keymap(
    input_buf,
    "n",
    "<Esc>",
    ":lua require('config.ollama_chat').toggle_chat_window()<CR>",
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    input_buf,
    "i",
    "<C-CR>",
    "<Esc>:lua require('config.ollama_chat').send_chat_message()<CR>",
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(
    input_buf,
    "n",
    "<CR>",
    ":lua require('config.ollama_chat').send_chat_message()<CR>",
    { noremap = true, silent = true }
  )

  -- Set up chat buffer keymaps
  vim.api.nvim_buf_set_keymap(
    chat_buf,
    "n",
    "<Esc>",
    ":lua require('config.ollama_chat').toggle_chat_window()<CR>",
    { noremap = true, silent = true }
  )

  -- Enter insert mode in input window
  vim.cmd("startinsert")
end

-- Send message from input buffer
function M.send_chat_message()
  if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
    print("Error: Input buffer not valid")
    return
  end

  local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  local message = table.concat(lines, "\n"):gsub("^%s*", ""):gsub("%s*$", "")

  if message == "" then
    return
  end

  -- Clear input buffer
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })

  -- Add user message to chat
  M.add_to_chat(message, true)

  -- Show "thinking" indicator
  M.add_to_chat("Thinking...", false)

  -- Send to Ollama
  M.query_ollama_async(message, function(response)
    vim.schedule(function()
      -- Remove "thinking" indicator
      if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
        vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
        local line_count = vim.api.nvim_buf_line_count(chat_buf)
        -- Remove last 2 lines ("Thinking..." and empty line)
        if line_count >= 2 then
          vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
        end
        vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)
      end

      -- Add AI response
      if response and response ~= "" then
        M.add_to_chat(response, false)
      else
        M.add_to_chat("No response received from Ollama", false)
      end

      -- Focus back to input window
      if input_win and vim.api.nvim_win_is_valid(input_win) then
        vim.api.nvim_set_current_win(input_win)
        vim.cmd("startinsert")
      end
    end)
  end)
end

-- Send selection to chat input for editing
function M.send_selection_to_chat()
  local text = M.get_selection()
  if not text or text == "" then
    print("No text selected!")
    return
  end

  -- Open chat window if not open
  if not chat_win or not vim.api.nvim_win_is_valid(chat_win) then
    M.toggle_chat_window()
    -- Wait a moment for the window to be created, then populate input
    vim.defer_fn(function()
      if input_buf and vim.api.nvim_buf_is_valid(input_buf) then
        local lines = vim.split(text, "\n")
        -- Add an empty line at the end for cursor positioning
        table.insert(lines, "")
        vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, lines)
        -- Focus the input window and position cursor on the empty line
        if input_win and vim.api.nvim_win_is_valid(input_win) then
          vim.api.nvim_set_current_win(input_win)
          -- Move cursor to the last (empty) line
          vim.api.nvim_win_set_cursor(input_win, { #lines, 0 })
          vim.cmd("startinsert")
        end
      end
    end, 100)
  else
    -- Chat window is already open, just populate the input
    if input_buf and vim.api.nvim_buf_is_valid(input_buf) then
      local lines = vim.split(text, "\n")
      -- Add an empty line at the end for cursor positioning
      table.insert(lines, "")
      vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, lines)
      -- Focus the input window and position cursor on the empty line
      if input_win and vim.api.nvim_win_is_valid(input_win) then
        vim.api.nvim_set_current_win(input_win)
        -- Move cursor to the last (empty) line
        vim.api.nvim_win_set_cursor(input_win, { #lines, 0 })
        vim.cmd("startinsert")
      end
    end
  end
end

-- Process message in chat window
function M.process_chat_message(message)
  -- Add user message to chat
  M.add_to_chat(message, true)

  -- Show "thinking" indicator
  M.add_to_chat("Thinking...", false)

  -- Send to Ollama
  M.query_ollama_async(message, function(response)
    vim.schedule(function()
      -- Remove "thinking" indicator
      if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
        vim.api.nvim_buf_set_option(chat_buf, "modifiable", true)
        local line_count = vim.api.nvim_buf_line_count(chat_buf)
        -- Remove last 2 lines ("Thinking..." and empty line)
        if line_count >= 2 then
          vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
        end
        vim.api.nvim_buf_set_option(chat_buf, "modifiable", false)
      end

      -- Add AI response
      if response and response ~= "" then
        M.add_to_chat(response, false)
      else
        M.add_to_chat("No response received from Ollama", false)
      end
    end)
  end)
end

-- Focus chat input window
function M.focus_chat_input()
  if input_win and vim.api.nvim_win_is_valid(input_win) then
    vim.api.nvim_set_current_win(input_win)
    vim.cmd("startinsert")
  else
    print("Chat window is not open. Use <Space>oc to open it.")
  end
end

-- Focus chat history window
function M.focus_chat_history()
  if chat_win and vim.api.nvim_win_is_valid(chat_win) then
    vim.api.nvim_set_current_win(chat_win)
  else
    print("Chat window is not open. Use <Space>oc to open it.")
  end
end

-- Test function for debugging
function M.test_ollama()
  local test_text = "Hello, can you respond with just 'Hi there!'?"
  M.query_ollama_async(test_text, function(response)
    vim.schedule(function()
      M.show_response(response)
    end)
  end)
end

-- Debug function to test selection capture
function M.debug_selection()
  local text = M.get_selection()
  print("Selected text: '" .. (text or "[NIL]") .. "'")
  print("Length: " .. (text and #text or 0))
end

-- تابع اصلی (برای quick queries)
function M.send_to_ollama()
  local text = M.get_selection()
  if not text or text == "" then
    return
  end

  M.query_ollama_async(text, function(response)
    vim.schedule(function()
      M.show_response(response)
    end)
  end)
end

return M
