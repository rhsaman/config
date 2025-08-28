-- Test file for demonstrating Ollama code editing with accept/deny functionality

-- Example 1: Function with a bug (missing return statement)
function add_numbers(a, b)
  local result = a + b
  -- Bug: missing return statement
end

-- Example 2: Inefficient code
function find_max(numbers)
  local max = numbers[1]
  for i = 1, #numbers do
    for j = 1, #numbers do  -- Inefficient nested loop
      if numbers[j] > max then
        max = numbers[j]
      end
    end
  end
  return max
end

-- Example 3: Code with style issues
function processData(data)
local result={}
for i=1,#data do
if data[i]>0 then
result[#result+1]=data[i]*2
end
end
return result
end

-- Example 4: Function that needs debugging
function calculate_average(numbers)
  local sum = 0
  for i = 1, #numbers do
    sum = sum + numbers[i]
  end
  return sum / #numbers  -- What if #numbers is 0?
end

-- Example 5: Complex function that could use debug logging
function process_user_data(user_data)
  local result = {}
  for key, value in pairs(user_data) do
    if type(value) == "string" then
      result[key] = value:upper()
    elseif type(value) == "number" then
      result[key] = value * 2
    end
  end
  return result
end

-- Example 6: Code with actual LSP errors (will definitely trigger lua_ls errors)
function buggy_function_with_real_lsp_errors()
  -- These are REAL Lua LSP errors that lua_ls will catch:
  
  -- 1. Undefined global variable (LSP Error)
  local x = undefined_global_variable
  
  -- 2. Trying to call a non-function (LSP Error)
  local num = 42
  local result = num()
  
  -- 3. Wrong number of arguments to known function (LSP Warning)
  local str = string.sub("hello")
  
  -- 4. Unused variable (LSP Warning)
  local unused_variable = "I am never used"
  
  -- 5. Unreachable code (LSP Warning)
  return result
  print("This line is unreachable")
end

-- Example 7: More LSP errors for testing
function another_function_with_errors()
  -- Typo in vim global (common LSP error)
  local buf = vin.api.nvim_get_current_buf()  -- 'vin' instead of 'vim'
  
  -- Attempting to index a nil value
  local nil_value = nil
  local bad_access = nil_value.some_field
  
  return buf, bad_access
end

-- To test the workflows:
--
-- FOR CODE EDITING:
-- 1. Select any of the functions above (Examples 1-3)
-- 2. Press <leader>oe to prepare for editing
-- 3. Review the auto-generated prompt in the input buffer
-- 4. Press Enter/Ctrl+Enter to send to Ollama
-- 5. Wait for Ollama to respond with improvements
-- 6. Press 'a' to accept or 'd' to deny the suggested changes
--
-- FOR DEBUG CODE ADDITION:
-- 1. Select any function (Examples 4-5 are good candidates)
-- 2. Press <leader>og to prepare for adding debug code
-- 3. Review the auto-generated debug prompt in the input buffer
-- 4. Press Enter/Ctrl+Enter to send to Ollama
-- 5. Wait for Ollama to respond with debug-enhanced version
-- 6. Press 'a' to accept or 'd' to deny the debug additions
