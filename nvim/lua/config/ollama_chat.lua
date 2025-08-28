-- AI Chat Plugin with Multi-Provider Support
-- Features:
-- - Ollama (local AI)
-- - OpenAI GPT-4
-- - Anthropic Claude
-- - Grok (xAI) - Free API
-- - Provider selection popup: <leader>op
-- - Code editing with AI suggestions
-- - LSP diagnostics integration

local M = {}

-- Configuration variables
local config = {
	ollama = {
		models = {
			"qwen3:4b-instruct-2507-q4_K_M", -- Default model
			"llama2:7b",
			"codellama:7b",
			"mistral:7b",
			"qwen:7b",
		},
		current_model = "qwen3:4b-instruct-2507-q4_K_M",
		url = nil, -- nil means local
		custom_models = {}, -- User-added models
	},
}

-- Helper function to set keymaps with descriptions
local function set_keymap(buf, mode, lhs, rhs, opts, description)
	local final_opts = vim.tbl_extend("force", opts or {}, { desc = description })
	vim.api.nvim_buf_set_keymap(buf, mode, lhs, rhs, final_opts)
end

-- Setup function to configure Ollama
function M.setup(opts)
	opts = opts or {}
	if opts.ollama then
		-- Support both old single model and new multi-model format
		if opts.ollama.model then
			config.ollama.current_model = opts.ollama.model
		end
		if opts.ollama.models then
			config.ollama.models = opts.ollama.models
		end
		if opts.ollama.current_model then
			config.ollama.current_model = opts.ollama.current_model
		end
		config.ollama.url = opts.ollama.url or config.ollama.url
		if opts.ollama.custom_models then
			config.ollama.custom_models = opts.ollama.custom_models
		end
	end

	-- Initialize model on setup
	M._model_initialized = false -- Reset flag to ensure re-initialization
	M.initialize_model()
	M._model_initialized = true
end

-- Model management functions
function M.get_available_models()
	local all_models = {}

	-- Add default models
	for _, model in ipairs(config.ollama.models) do
		table.insert(all_models, { name = model, type = "default" })
	end

	-- Add custom models
	for _, model in ipairs(config.ollama.custom_models) do
		table.insert(all_models, { name = model, type = "custom" })
	end

	return all_models
end

function M.get_current_model()
	return config.ollama.current_model
end

function M.set_current_model(model)
	if M.is_model_available(model) then
		config.ollama.current_model = model
		M.save_model_config()
		print("Switched to Ollama model: " .. model)
		return true
	else
		print("Error: Model '" .. model .. "' is not available")
		return false
	end
end

function M.is_model_available(model)
	local models = M.get_available_models()
	for _, m in ipairs(models) do
		if m.name == model then
			return true
		end
	end
	return false
end

function M.add_custom_model(model)
	if not M.is_model_available(model) then
		table.insert(config.ollama.custom_models, model)
		print("Added custom model: " .. model)
		-- Save the updated configuration
		M.save_model_config()
		return true
	else
		print("Model '" .. model .. "' already exists")
		return false
	end
end

function M.remove_model(model)
	-- First try to remove from custom models
	for i, m in ipairs(config.ollama.custom_models) do
		if m == model then
			table.remove(config.ollama.custom_models, i)
			print("Removed custom model: " .. model)

			-- If this was the current model, switch to another available model
			if config.ollama.current_model == model then
				M.switch_to_available_model()
			end

			-- Save the updated configuration
			M.save_model_config()
			return true
		end
	end

	-- Then try to remove from default models
	for i, m in ipairs(config.ollama.models) do
		if m == model then
			table.remove(config.ollama.models, i)
			print("Removed default model: " .. model)

			-- If this was the current model, switch to another available model
			if config.ollama.current_model == model then
				M.switch_to_available_model()
			end

			-- Save the updated configuration
			M.save_model_config()
			return true
		end
	end

	print("Model '" .. model .. "' not found")
	return false
end

-- Legacy function for backward compatibility
function M.remove_custom_model(model)
	return M.remove_model(model)
end

-- Switch to an available model when current model is removed
function M.switch_to_available_model()
	local available_models = M.get_available_models()
	if #available_models > 0 then
		local new_model = available_models[1].name
		config.ollama.current_model = new_model
		M.save_model_config()
		print("Switched to available model: " .. new_model)
	else
		print("Warning: No models available. Please add a model using :OllamaAddModel")
		config.ollama.current_model = nil
		M.save_model_config()
	end
end

-- Model persistence
local model_config_file = vim.fn.stdpath("data") .. "/ollama_chat_model.json"

function M.save_model_config()
	local data = {
		current_model = config.ollama.current_model,
		models = config.ollama.models, -- Save default models
		custom_models = config.ollama.custom_models, -- Save custom models
		timestamp = os.time(),
		version = "1.1", -- Updated version for new format
	}

	local success, encoded = pcall(vim.json.encode, data)
	if success then
		local file = io.open(model_config_file, "w")
		if file then
			file:write(encoded)
			file:close()
			return true
		end
	end
	return false
end

-- Legacy function for backward compatibility
function M.save_current_model()
	return M.save_model_config()
end

function M.load_model_config()
	local file = io.open(model_config_file, "r")
	if file then
		local content = file:read("*all")
		file:close()

		local success, data = pcall(vim.json.decode, content)
		if success and data then
			-- Load models if available (new format)
			if data.models then
				config.ollama.models = data.models
			end
			if data.custom_models then
				config.ollama.custom_models = data.custom_models
			end

			-- Load current model if available
			if data.current_model then
				-- Check if the saved model is still available
				if M.is_model_available(data.current_model) then
					config.ollama.current_model = data.current_model
					return true
				else
					print("Warning: Saved model '" .. data.current_model .. "' is no longer available")
					-- Try to use first available model
					local available_models = M.get_available_models()
					if #available_models > 0 then
						config.ollama.current_model = available_models[1].name
						print("Using available model: " .. config.ollama.current_model)
						return true
					end
				end
			end
		end
	end
	return false
end

-- Legacy function for backward compatibility
function M.load_saved_model()
	return M.load_model_config()
end

function M.initialize_model()
	-- Try to load saved model configuration first
	if M.load_model_config() then
		print("Loaded saved Ollama model configuration")
		if config.ollama.current_model then
			print("Current model: " .. config.ollama.current_model)
		end
		return true
	end

	-- If no saved configuration, check if we have any models available
	local available_models = M.get_available_models()
	if #available_models > 0 then
		-- Use the first available model as default
		config.ollama.current_model = available_models[1].name
		M.save_model_config()
		print("Using default Ollama model: " .. config.ollama.current_model)
		return true
	end

	-- If no models available, prompt user to add one
	print("No Ollama models configured. Please add a model to get started.")
	vim.defer_fn(function()
		M.add_model_interactive()
	end, 1000)

	return false
end

function M.reset_model_config()
	-- Clear saved model configuration and reset to defaults
	os.remove(model_config_file)

	-- Reset to original default models
	config.ollama.models = {
		"qwen3:4b-instruct-2507-q4_K_M", -- Default model
		"llama2:7b",
		"codellama:7b",
		"mistral:7b",
		"qwen:7b",
	}
	config.ollama.custom_models = {}
	config.ollama.current_model = config.ollama.models[1]

	M.save_model_config()
	print("Model configuration reset. Current model: " .. config.ollama.current_model)
end

-- Focus back to input window manually
function M.focus_input_window()
	if input_win and vim.api.nvim_win_is_valid(input_win) then
		vim.api.nvim_set_current_win(input_win)
		if vim.api.nvim_get_mode().mode ~= "i" then
			vim.cmd("startinsert")
		end
		print("Focused back to input window")
	else
		print("Input window not available")
	end
end

-- Manual model initialization (for external calls)
function M.ensure_model_initialized()
	if not M._model_initialized then
		M.initialize_model()
		M._model_initialized = true
	end
end

function M.list_models()
	local models = M.get_available_models()
	print("=== Available Ollama Models ===")
	print("Current: " .. config.ollama.current_model)
	print("")

	for i, model in ipairs(models) do
		local marker = (model.name == config.ollama.current_model) and " ← current" or ""
		local type_marker = (model.type == "custom") and " (custom)" or ""
		print(string.format("%d. %s%s%s", i, model.name, type_marker, marker))
	end

	local available_models = M.get_available_models()
	if #available_models > 0 then
		print("")
		print("💡 Tips:")
		print("  - Use :OllamaRemoveModel <model> to remove any model")
		print("  - Use :OllamaRemoveModel (no args) for interactive removal")
		print("  - Use <leader>oa to add a new model")
		print("  - Use <leader>or to remove a model")
		print("  - Current model will automatically switch when removed")
	end
end

-- Interactive model addition
function M.add_model_interactive()
	vim.ui.input({
		prompt = "Enter model name to add: ",
	}, function(input)
		if input and input ~= "" then
			if M.add_custom_model(input) then
				-- Automatically switch to the newly added model
				M.set_current_model(input)
			end
		end
	end)
end

-- Interactive model removal
function M.remove_model_interactive()
	local all_models = M.get_available_models()
	if #all_models == 0 then
		print("No models available to remove")
		return
	end

	local options = {}
	for i, model in ipairs(all_models) do
		local type_label = (model.type == "custom") and " (custom)" or " (default)"
		local current_label = (model.name == config.ollama.current_model) and " ← CURRENT" or ""
		table.insert(options, string.format("%d. %s%s%s", i, model.name, type_label, current_label))
	end

	vim.ui.select(options, {
		prompt = "Select model to remove:",
		format_item = function(item)
			return item
		end,
	}, function(choice, idx)
		if choice and idx then
			local model_to_remove = all_models[idx].name

			-- Prevent removing the current model without confirmation
			if model_to_remove == config.ollama.current_model then
				vim.ui.select({ "Yes, remove it", "No, keep it" }, {
					prompt = "This is your current model. Remove it anyway?",
				}, function(confirm_choice)
					if confirm_choice == "Yes, remove it" then
						M.remove_model(model_to_remove)
					end
				end)
			else
				M.remove_model(model_to_remove)
			end
		end
	end)
end

-- Set Ollama model interactively (legacy function, use set_current_model instead)
function M.set_ollama_model(model)
	if model and model ~= "" then
		return M.set_current_model(model)
	else
		print("Error: Model name cannot be empty")
		return false
	end
end

-- Set Ollama URL interactively
function M.set_ollama_url(url)
	if url and url ~= "" then
		config.ollama.url = url
		print("Ollama URL set to: " .. url)
	else
		config.ollama.url = nil
		print("Ollama URL reset to local (nil)")
	end
end

-- Show current Ollama configuration
function M.show_ollama_config()
	print("=== Ollama Configuration ===")
	print("Current Model: " .. config.ollama.current_model)
	print("Server URL: " .. (config.ollama.url or "Local (default)"))
	print("")

	local models = M.get_available_models()
	print("Available Models (" .. #models .. " total):")
	for i, model in ipairs(models) do
		local marker = (model.name == config.ollama.current_model) and " ← current" or ""
		local type_marker = (model.type == "custom") and " (custom)" or ""
		print(string.format("  %d. %s%s%s", i, model.name, type_marker, marker))
	end

	if #config.ollama.custom_models > 0 then
		print("")
		print("💡 Tip: Use :OllamaRemoveModel <model> to manage custom models")
	end
end

-- Show help for all available keymaps
function M.show_keymap_help()
	local help_text = {
		"==========================================",
		"    OLLAMA CHAT KEYMAP REFERENCE",
		"==========================================",
		"",
		"INPUT WINDOW KEYMAPS:",
		"  <leader>oo         - Toggle chat window",
		"  <F12>             - Toggle chat window (backup)",
		"  <C-Enter> (insert) - Send message",
		"  <CR> (normal)      - Send message",
		"  <Enter> (insert)   - New line (normal behavior)",
		"  a                  - Accept AI code suggestion",
		"  d                  - Deny AI code suggestion",
		"  <leader>of         - Focus back to input window",
		"",
		"OLLAMA CONFIGURATION:",
		"  <leader>om         - Select Ollama model",
		"  <leader>ol         - List all available models",
		"  <leader>oa         - Add custom model",
		"  <leader>or         - Remove any model",
		"  <leader>oinfo      - Show detailed model info",
		"  <leader>ou         - Configure Ollama server URL",
		"  <leader>oc         - Show Ollama configuration",
		"",
		"CHAT MANAGEMENT:",
		"  <leader>och        - Clear chat history",
		"  <leader>occ        - Clear chat context",
		"  <leader>osc        - Show chat context",
		"",
		"DEBUGGING:",
		"  <leader>od         - Show cursor position and selection",
		"  <leader>oe         - Show pending edit state",
		"",
		"PROVIDER MANAGEMENT:",
		"  Use :OllamaModel, :OllamaURL, :OllamaConfig commands",
		"  Or configure in your init.lua with setup() function",
		"",
		"COMMANDS:",
		"  :OllamaToggle      - Toggle chat window",
		"  :OllamaModel       - Set/switch model (with completion)",
		"  :OllamaListModels  - List all available models",
		"  :OllamaModelInfo   - Show detailed model information",
		"  :OllamaAddModel    - Add custom model",
		"  :OllamaRemoveModel - Remove any model (interactive if no arg)",
		"  :OllamaResetModel  - Reset model configuration",
		"  :OllamaSaveConfig  - Manually save configuration",
		"  :OllamaInitModel   - Manually initialize model",
		"  :OllamaClearHistory - Clear chat history",
		"  :OllamaClearContext - Clear chat context",
		"  :OllamaShowContext  - Show chat context",
		"  :OllamaTestFocus   - Test cursor focus functionality",
		"  :OllamaReadFile    - Read and analyze current file (debug)",
		"  :OllamaURL         - Set/change URL",
		"  :OllamaConfig      - Show configuration",
		"  :OllamaDebugSelection - Show cursor/selection info",
		"  :OllamaDebugEdit   - Show pending edit state",
		"  :OllamaHelp        - Show this help",
		"",
		"PROGRAMMATIC CONFIGURATION:",
		"  require('config.ollama_chat').setup({",
		"    ollama = {",
		"      models = {'llama2:7b', 'codellama:7b', 'mistral:7b'},",
		"      current_model = 'codellama:7b',",
		"      custom_models = {'my-experimental-model:1b'},",
		"      url = 'your-url'",
		"    }",
		"  })",
		"",
		"MODEL MANAGEMENT:",
		"  - Add models: :OllamaAddModel <model>",
		"  - Remove models: :OllamaRemoveModel <model>",
		"  - List models: :OllamaListModels",
		"",
		"PERSISTENCE:",
		"  - Model configuration is automatically saved and restored",
		"  - Removed models stay removed across sessions",
		"  - Added models are preserved",
		"  - Use :OllamaResetModel to restore defaults",
		"  - Use :OllamaSaveConfig to manually save",
		"",
		"TIP: Use <leader>op for interactive provider selection!",
		"==========================================",
	}

	-- Create a floating window to show the help
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_text)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
	vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })

	local width = 60
	local height = #help_text
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	-- Set keymap to close the help window
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })

	-- Add title and instructions
	vim.api.nvim_buf_set_lines(buf, 0, 1, false, {
		"==========================================",
		"    OLLAMA CHAT KEYMAP REFERENCE",
		"==========================================",
		"Press 'q' or <Esc> to close this help",
		"",
	})
end

-- Interactive model selection
function M.select_ollama_model()
	local models = M.get_available_models()
	local options = {}

	for _, model in ipairs(models) do
		local display_name = model.name
		if model.type == "custom" then
			display_name = display_name .. " (custom)"
		end
		if model.name == config.ollama.current_model then
			display_name = display_name .. " ← current"
		end
		table.insert(options, display_name)
	end

	vim.ui.select(options, {
		prompt = "Select Ollama Model:",
		format_item = function(item)
			return item
		end,
	}, function(choice, idx)
		if choice and idx then
			local selected_model = models[idx].name
			M.set_current_model(selected_model)
		end
	end)
end

-- Interactive URL selection
function M.select_ollama_url()
	vim.ui.input({
		prompt = "Enter Ollama server URL (leave empty for local): ",
		default = config.ollama.url or "",
	}, function(input)
		if input and input ~= "" then
			M.set_ollama_url(input)
		else
			M.set_ollama_url(nil)
		end
	end)
end

local clean_code_prompt = [[
You are an expert programmer. Rewrite the code I provide in a clean and concise way,
optimizing structure and formatting, and adding comments if necessary.
Do not write any explanations, analysis, or anything I didn't ask for.
Only return the improved, cleaned-up version of the code.
]]

-- API Provider Configuration
local function get_providers()
	return {
		ollama = {
			name = "Ollama",
			model = config.ollama.current_model,
			endpoint = config.ollama.url, -- Local or custom URL
			api_key = nil, -- Not needed for local
		},
		openai = {
			name = "OpenAI",
			model = "gpt-4",
			endpoint = "https://api.openai.com/v1/chat/completions",
			api_key = os.getenv("OPENAI_API_KEY"),
		},
		cloud = {
			name = "Anthropic Claude",
			model = "claude-3-sonnet-20240229",
			endpoint = "https://api.anthropic.com/v1/messages",
			api_key = os.getenv("ANTHROPIC_API_KEY"),
		},
		grok = {
			name = "Grok (xAI)",
			model = "grok-beta",
			endpoint = "https://api.x.ai/v1/chat/completions",
			api_key = os.getenv("GROK_API_KEY"),
		},
	}
end

-- For backward compatibility, keep providers as a table but make it dynamic
local providers = get_providers()

-- Current active provider
local current_provider = "ollama"

-- Provider persistence
local provider_config_file = vim.fn.stdpath("data") .. "/ollama_chat_provider.json"

-- Load saved provider from file
function M.load_saved_provider()
	-- Ensure model is initialized before validating provider
	if not M._model_initialized then
		M.initialize_model()
		M._model_initialized = true
	end

	local file = io.open(provider_config_file, "r")
	if file then
		local content = file:read("*all")
		file:close()

		local success, data = pcall(vim.json.decode, content)
		if success and data and data.provider and get_providers()[data.provider] then
			-- Validate that the provider's API key is still available
			local valid, error_msg = M.validate_api_key(data.provider)
			if valid then
				current_provider = data.provider
				return true
			else
				print("Warning: Saved provider '" .. data.provider .. "' is no longer available: " .. error_msg)
				print("Falling back to Ollama")
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

-- Save current provider to file
function M.save_current_provider()
	local data = {
		provider = current_provider,
		timestamp = os.time(),
		version = "1.0",
	}

	local success, encoded = pcall(vim.json.encode, data)
	if success then
		local file = io.open(provider_config_file, "w")
		if file then
			file:write(encoded)
			file:close()
			return true
		end
	end
	return false
end

-- Chat window state
local chat_win = nil
local chat_buf = nil
local input_buf = nil
local input_win = nil
local chat_history = {} -- Store last 10 conversations for context
local current_job = nil -- Track current API job
local MAX_CHAT_HISTORY = 10 -- Maximum conversations to remember for context

-- Code edit state
local pending_edit = {
	original_buf = nil,
	original_start_line = nil,
	original_end_line = nil,
	original_start_col = nil,
	original_end_col = nil,
	suggested_code = nil,
	response_id = nil,
}

-- Module state
M._provider_initialized = false
M._model_initialized = false
M.provider_popup = nil

-- Validate API key for a provider
function M.validate_api_key(provider)
	if provider == "ollama" then
		-- Validate Ollama configuration
		local model = config.ollama.current_model
		if not model or model == "" then
			return false,
				"Ollama model not configured. Use :OllamaModel to select a model or :OllamaAddModel to add one"
		end
		return true
	elseif provider == "openai" then
		if not get_providers().openai.api_key or get_providers().openai.api_key == "" then
			return false, "OpenAI API key not found. Set OPENAI_API_KEY environment variable."
		end
	elseif provider == "cloud" then
		if not get_providers().cloud.api_key or get_providers().cloud.api_key == "" then
			return false, "Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable."
		end
	elseif provider == "grok" then
		if not get_providers().grok.api_key or get_providers().grok.api_key == "" then
			return false, "Grok API key not found. Set GROK_API_KEY environment variable."
		end
	end
	return true
end

-- Extract code from response (supports code blocks and inline code)
function M.extract_code_from_response(response)
	if not response or response == "" then
		return nil
	end

	-- First try to find code blocks (```code```)
	local code_block = response:match("```[^\n]*\n(.-)```")
	if code_block then
		return code_block:gsub("^%s*", ""):gsub("%s*$", "")
	end

	-- Try to find inline code (`code`)
	local inline_code = response:match("`([^`]+)`")
	if inline_code then
		return inline_code
	end

	-- If it looks like pure code (contains common programming patterns)
	if
		response:match("function")
		or response:match("class")
		or response:match("{.-}")
		or response:match("import")
		or response:match("require")
		or response:match("local.*=")
		or response:match("def ")
		or response:match("var ")
		or response:match("const ")
		or response:match("let ")
	then
		return response:gsub("^%s*", ""):gsub("%s*$", "")
	end

	return nil
end

-- Check if response contains code that could be applied as an edit
function M.is_code_edit_response(response)
	return M.extract_code_from_response(response) ~= nil
end

-- Get selected text or current line
function M.get_selection()
	-- First try to get visual selection if we were just in visual mode
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")

	-- Check if we have a valid visual selection
	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		local lines = vim.fn.getline(vstart[2], vend[2])

		-- If only one line, vim.fn.getline returns a string, convert to table
		if type(lines) == "string" then
			lines = { lines }
		end

		if #lines == 1 then
			-- Single line selection
			local line = lines[1]
			-- Handle the case where vend[3] might be beyond the line length
			local end_col = math.min(vend[3], #line)
			lines[1] = string.sub(line, vstart[3], end_col)
		else
			-- Multi-line selection
			lines[1] = string.sub(lines[1], vstart[3])
			-- For the last line, vend[3] is inclusive
			local last_line = lines[#lines]
			local end_col = math.min(vend[3], #last_line)
			lines[#lines] = string.sub(last_line, 1, end_col)
		end

		return table.concat(lines, "\n")
	else
		-- No selection, get current line
		return vim.fn.getline(".")
	end
end

-- Store the current selection context for later editing
function M.store_selection_context()
	local buf = vim.api.nvim_get_current_buf()
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")

	-- Check if we have a valid visual selection
	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		-- We have a valid visual selection
		pending_edit.original_buf = buf
		pending_edit.original_start_line = vstart[2]
		pending_edit.original_end_line = vend[2]
		pending_edit.original_start_col = vstart[3]
		-- For visual selection, vend[3] is inclusive, so we need to make it exclusive
		-- But we also need to handle the case where vend[3] might be at line end
		local end_line_text = vim.api.nvim_buf_get_lines(buf, vend[2] - 1, vend[2], false)[1] or ""
		pending_edit.original_end_col = math.min(vend[3] + 1, #end_line_text + 1)
	else
		-- No visual selection, use current line
		local current_line = vim.api.nvim_win_get_cursor(0)[1]
		local line_text = vim.api.nvim_get_current_line()

		pending_edit.original_buf = buf
		pending_edit.original_start_line = current_line
		pending_edit.original_end_line = current_line
		pending_edit.original_start_col = 1
		-- For full line replacement, we want to replace up to but not including the newline
		pending_edit.original_end_col = #line_text + 1
	end

	return buf, vstart, vend
end

-- اجرای Ollama API async (truly async using jobstart)
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

	local model = get_providers().ollama.model
	local cmd = {
		"sh",
		"-c",
		string.format('timeout 15s cat "%s" | ollama run %s 2>/dev/null | head -10', temp_file, model),
	}

	local response_lines = {}
	local callback_called = false

	-- Add timeout to prevent hanging
	vim.defer_fn(function()
		if current_job and not callback_called then
			vim.fn.jobstop(current_job)
			current_job = nil
			if not callback_called then
				callback_called = true
				print("Ollama job timed out, trying fallback...")
				local fallback_response = M.try_sync_ollama(clean_text)
				if fallback_response then
					callback(fallback_response .. " (timed out, via fallback)")
				else
					callback("Ollama request timed out")
				end
			end
		end
	end, 10000) -- 10 second timeout

	current_job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line and line ~= "" then
						-- Clean escape codes but keep most content
						local clean_line = line
							:gsub("\27%[%d*;*%d*[mK]", "") -- Remove ANSI escape codes
							:gsub("%[%?25[lh]", "") -- Remove cursor visibility codes
							:gsub("\r", "") -- Remove carriage returns

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
		on_stderr = function(_, _)
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

						callback(final_response)
					else
						-- Try synchronous fallback
						print("Ollama async failed, trying synchronous fallback...")
						local fallback_response = M.try_sync_ollama(clean_text)
						if fallback_response then
							callback(fallback_response .. " (via fallback)")
						else
							callback("No response from Ollama (empty response)")
						end
					end
				else
					-- Try synchronous fallback on failure
					print("Ollama command failed (exit code: " .. exit_code .. "), trying synchronous fallback...")
					local fallback_response = M.try_sync_ollama(clean_text)
					if fallback_response then
						callback(fallback_response .. " (via fallback)")
					else
						callback("Ollama command failed with exit code: " .. exit_code)
					end
				end
			end
		end,
	})
end

-- اجرای OpenAI API async
function M.query_openai_async(text, callback)
	-- Check if API key is available
	if not get_providers().openai.api_key then
		callback("Error: OpenAI API key not found. Set OPENAI_API_KEY environment variable.")
		return
	end

	-- Clean and prepare text
	local clean_text = text:gsub('"', '\\"'):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

	if clean_text == "" then
		callback("Error: Empty text provided")
		return
	end

	-- Create request payload
	local payload = {
		model = get_providers().openai.model,
		messages = {
			{ role = "user", content = clean_text },
		},
		max_tokens = 4096,
		temperature = 0.7,
	}

	local json_payload = vim.json.encode(payload)

	-- Create temporary file for payload
	local temp_file = vim.fn.tempname()
	vim.fn.writefile({ json_payload }, temp_file)

	local cmd = {
		"curl",
		"-s",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-H",
		"Authorization: Bearer " .. get_providers().openai.api_key,
		"-d",
		"@" .. temp_file,
		get_providers().openai.endpoint,
	}

	local response_lines = {}
	local callback_called = false

	current_job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line and line ~= "" then
						table.insert(response_lines, line)
					end
				end
			end
		end,
		on_stderr = function(_, _)
			-- Silently handle errors
		end,
		on_exit = function(_, exit_code)
			-- Clean up temp file
			vim.fn.delete(temp_file)

			if not callback_called then
				callback_called = true

				if exit_code == 0 then
					if #response_lines > 0 then
						local response_json = table.concat(response_lines, "")
						local success, response_data = pcall(vim.json.decode, response_json)

						if success and response_data.choices and response_data.choices[1] then
							local content = response_data.choices[1].message.content
							if content then
								callback(content)
							else
								callback("No content in OpenAI response")
							end
						else
							callback("Failed to parse OpenAI response: " .. response_json)
						end
					else
						callback("No response from OpenAI")
					end
				else
					callback("OpenAI API request failed with exit code: " .. exit_code)
				end
			end
		end,
	})
end

-- اجرای Cloud API (Anthropic Claude) async
function M.query_cloud_async(text, callback)
	-- Check if API key is available
	if not get_providers().cloud.api_key then
		callback("Error: Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable.")
		return
	end

	-- Clean and prepare text
	local clean_text = text:gsub('"', '\\"'):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

	if clean_text == "" then
		callback("Error: Empty text provided")
		return
	end

	-- Create request payload for Anthropic
	local payload = {
		model = get_providers().cloud.model,
		max_tokens = 4096,
		messages = {
			{ role = "user", content = clean_text },
		},
	}

	local json_payload = vim.json.encode(payload)

	-- Create temporary file for payload
	local temp_file = vim.fn.tempname()
	vim.fn.writefile({ json_payload }, temp_file)

	local cmd = {
		"curl",
		"-s",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-H",
		"x-api-key: " .. get_providers().cloud.api_key,
		"-H",
		"anthropic-version: 2023-06-01",
		"-d",
		"@" .. temp_file,
		get_providers().cloud.endpoint,
	}

	local response_lines = {}
	local callback_called = false

	current_job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line and line ~= "" then
						table.insert(response_lines, line)
					end
				end
			end
		end,
		on_stderr = function(_, _)
			-- Silently handle errors
		end,
		on_exit = function(_, exit_code)
			-- Clean up temp file
			vim.fn.delete(temp_file)

			if not callback_called then
				callback_called = true

				if exit_code == 0 then
					if #response_lines > 0 then
						local response_json = table.concat(response_lines, "")
						local success, response_data = pcall(vim.json.decode, response_json)

						if success and response_data.content and response_data.content[1] then
							local content = response_data.content[1].text
							if content then
								callback(content)
							else
								callback("No content in Claude response")
							end
						else
							callback("Failed to parse Claude response: " .. response_json)
						end
					else
						callback("No response from Claude")
					end
				else
					callback("Claude API request failed with exit code: " .. exit_code)
				end
			end
		end,
	})
end

-- اجرای Grok API async (xAI)
function M.query_grok_async(text, callback)
	-- Check if API key is available
	if not get_providers().grok.api_key then
		callback("Error: Grok API key not found. Set GROK_API_KEY environment variable.")
		return
	end

	-- Clean and prepare text
	local clean_text = text:gsub('"', '\\"'):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

	if clean_text == "" then
		callback("Error: Empty text provided")
		return
	end

	-- Create request payload (similar to OpenAI format)
	local payload = {
		model = get_providers().grok.model,
		messages = {
			{ role = "user", content = clean_text },
		},
		max_tokens = 4096,
		temperature = 0.7,
	}

	local json_payload = vim.json.encode(payload)

	-- Create temporary file for payload
	local temp_file = vim.fn.tempname()
	vim.fn.writefile({ json_payload }, temp_file)

	local cmd = {
		"curl",
		"-s",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-H",
		"Authorization: Bearer " .. get_providers().grok.api_key,
		"-d",
		"@" .. temp_file,
		get_providers().grok.endpoint,
	}

	local response_lines = {}
	local callback_called = false

	current_job = vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line and line ~= "" then
						table.insert(response_lines, line)
					end
				end
			end
		end,
		on_stderr = function(_, _)
			-- Silently handle errors
		end,
		on_exit = function(_, exit_code)
			-- Clean up temp file
			vim.fn.delete(temp_file)

			if not callback_called then
				callback_called = true

				if exit_code == 0 then
					if #response_lines > 0 then
						local response_json = table.concat(response_lines, "")
						local success, response_data = pcall(vim.json.decode, response_json)

						if success and response_data.choices and response_data.choices[1] then
							local content = response_data.choices[1].message.content
							if content then
								callback(content)
							else
								callback("No content in Grok response")
							end
						else
							callback("Failed to parse Grok response: " .. response_json)
						end
					else
						callback("No response from Grok")
					end
				else
					callback("Grok API request failed with exit code: " .. exit_code)
				end
			end
		end,
	})
end

-- Synchronous fallback for Ollama queries
function M.try_sync_ollama(text)
	local temp_file = vim.fn.tempname()
	vim.fn.writefile({ text }, temp_file)

	local model = get_providers().ollama.model
	local cmd = string.format('timeout 10s cat "%s" | ollama run %s 2>/dev/null | head -5', temp_file, model)
	local handle = io.popen(cmd)

	if handle then
		local result = handle:read("*a")
		handle:close()
		vim.fn.delete(temp_file)

		if result and result ~= "" then
			-- Clean up the response
			result = result:gsub("\n+", " "):gsub("^%s*", ""):gsub("%s*$", "")
			if #result > 500 then
				result = result:sub(1, 500) .. "..."
			end
			return result
		end
	end

	vim.fn.delete(temp_file)
	return nil
end

-- Get current provider (for testing/debugging)
function M.get_current_provider()
	return current_provider
end

-- Unified query function that routes to the current provider
function M.query_ai_async(text, callback)
	local valid, error_msg = M.validate_api_key(current_provider)
	if not valid then
		callback("Error: " .. error_msg)
		return
	end

	if current_provider == "ollama" then
		M.query_ollama_async(text, callback)
	elseif current_provider == "openai" then
		M.query_openai_async(text, callback)
	elseif current_provider == "cloud" then
		M.query_cloud_async(text, callback)
	elseif current_provider == "grok" then
		M.query_grok_async(text, callback)
	else
		callback("Error: Unknown provider '" .. current_provider .. "'")
	end
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
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

-- Apply code edit to original buffer (without switching to it)
function M.accept_code_edit()
	if
		not pending_edit.original_buf
		or not pending_edit.suggested_code
		or not vim.api.nvim_buf_is_valid(pending_edit.original_buf)
	then
		print("Error: Invalid pending edit state")
		return
	end

	-- Remember current window to return to it later
	local current_win = vim.api.nvim_get_current_win()

	-- Get buffer info for validation
	local buf_line_count = vim.api.nvim_buf_line_count(pending_edit.original_buf)

	-- Apply the edit to the original buffer (without switching view)
	local code_lines = vim.split(pending_edit.suggested_code, "\n")

	-- Ensure we have valid line numbers and validate them
	local start_line = pending_edit.original_start_line or 1
	local end_line = pending_edit.original_end_line or start_line
	local start_col = pending_edit.original_start_col or 1
	local end_col = pending_edit.original_end_col or 1

	-- Clamp values to valid ranges
	start_line = math.max(1, math.min(start_line, buf_line_count))
	end_line = math.max(1, math.min(end_line, buf_line_count))

	-- Ensure start <= end
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end

	-- Convert to 0-based indices for nvim_buf_set_text
	local start_row = start_line - 1
	local start_col_0 = start_col - 1
	local end_row = end_line - 1
	local end_col_0 = end_col - 1

	-- Validate buffer is modifiable
	if not vim.bo[pending_edit.original_buf].modifiable then
		print("Error: Buffer is not modifiable")
		return
	end

	-- Validate positions are within bounds
	if start_row < 0 or start_row >= buf_line_count or end_row < 0 or end_row >= buf_line_count then
		print("Error: Invalid line range for replacement")
		return
	end

	-- Get the line lengths to validate column positions
	local start_line_text = vim.api.nvim_buf_get_lines(pending_edit.original_buf, start_row, start_row + 1, false)[1]
		or ""
	local end_line_text = vim.api.nvim_buf_get_lines(pending_edit.original_buf, end_row, end_row + 1, false)[1] or ""

	-- Validate and clamp column positions
	if start_col_0 < 0 then
		start_col_0 = 0
	elseif start_col_0 > #start_line_text then
		start_col_0 = #start_line_text
	end

	-- For end_col, since it's exclusive, it can be equal to line length + 1 (for newline)
	if end_col_0 < 0 then
		end_col_0 = 0
	elseif end_col_0 > #end_line_text + 1 then
		end_col_0 = #end_line_text + 1
	end

	-- Additional validation: ensure start <= end for same line
	if start_row == end_row and start_col_0 > end_col_0 then
		print("Error: Start column is greater than end column on same line")
		return
	end

	-- Debug logging
	print(
		string.format(
			"Replacing lines %d-%d, cols %d-%d with %d lines of code",
			start_line,
			end_line,
			start_col,
			end_col - 1,
			#code_lines
		)
	)

	-- Replace the selection with the new code
	local success, err = pcall(function()
		vim.api.nvim_buf_set_text(pending_edit.original_buf, start_row, start_col_0, end_row, end_col_0, code_lines)
	end)

	if not success then
		print("Error applying code edit: " .. (err or "Unknown error"))
		return
	end

	print("Code edit applied successfully!")

	-- Clear pending edit
	pending_edit = {
		original_buf = nil,
		original_start_line = nil,
		original_end_line = nil,
		original_start_col = nil,
		original_end_col = nil,
		suggested_code = nil,
		response_id = nil,
	}

	-- Keep the AI response in chat, just remove accept/deny options
	M.clear_edit_options()

	-- Stay in current window (don't switch to original buffer)
	if vim.api.nvim_win_is_valid(current_win) then
		vim.api.nvim_set_current_win(current_win)
	end

	-- Focus back to input window if we're in chat mode
	if input_win and vim.api.nvim_win_is_valid(input_win) then
		vim.api.nvim_set_current_win(input_win)
		vim.cmd("startinsert")
	end
end

-- Deny code edit
function M.deny_code_edit()
	-- Clear pending edit
	pending_edit = {
		original_buf = nil,
		original_start_line = nil,
		original_end_line = nil,
		original_start_col = nil,
		original_end_col = nil,
		suggested_code = nil,
		response_id = nil,
	}

	-- Remove accept/deny options from chat
	M.clear_edit_options()
end

-- Clear edit options from chat window (keeps AI response, removes only options)
function M.clear_edit_options()
	if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
		vim.api.nvim_set_option_value("modifiable", true, { buf = chat_buf })
		local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

		-- Remove only the accept/deny option lines, keep everything else
		local new_lines = {}
		for _, line in ipairs(lines) do
			if not line:match("^%[ACCEPT%]") and not line:match("^%[DENY%]") and not line:match("^>>> Press") then
				table.insert(new_lines, line)
			end
		end

		vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, new_lines)
		vim.api.nvim_set_option_value("modifiable", false, { buf = chat_buf })
	end
end

-- Add accept/deny options to chat
function M.add_edit_options()
	if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
		vim.api.nvim_set_option_value("modifiable", true, { buf = chat_buf })
		local options = {
			"",
			">>> Press 'a' to ACCEPT this code edit or 'd' to DENY it <<<",
			"[ACCEPT] - Apply the suggested code to your original selection",
			"[DENY] - Reject the code edit",
			"",
		}
		vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, options)
		vim.api.nvim_set_option_value("modifiable", false, { buf = chat_buf })

		-- Auto scroll to bottom
		if chat_win and vim.api.nvim_win_is_valid(chat_win) then
			local line_count = vim.api.nvim_buf_line_count(chat_buf)
			vim.api.nvim_win_set_cursor(chat_win, { line_count, 0 })
		end
	end
end

-- Add message to chat display and store in history for context
function M.add_to_chat(message, is_user)
	local timestamp = os.date("%H:%M")
	local prefix = is_user and "[" .. timestamp .. "] You: " or "[" .. timestamp .. "] AI: "
	local formatted_message = prefix .. message

	-- Store in history for context (last 10 conversations)
	local conversation_entry = {
		message = formatted_message,
		timestamp = timestamp,
		is_user = is_user,
		raw_message = message,
	}

	table.insert(chat_history, conversation_entry)

	-- Keep only last MAX_CHAT_HISTORY conversations
	if #chat_history > MAX_CHAT_HISTORY then
		table.remove(chat_history, 1)
	end

	if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
		vim.api.nvim_set_option_value("modifiable", true, { buf = chat_buf })

		vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, vim.split(formatted_message, "\n"))
		vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, { "" })
		vim.api.nvim_set_option_value("modifiable", false, { buf = chat_buf })

		-- Auto scroll to bottom (only if chat window is currently focused)
		if chat_win and vim.api.nvim_win_is_valid(chat_win) then
			local current_win = vim.api.nvim_get_current_win()
			if current_win == chat_win then
				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				vim.api.nvim_win_set_cursor(chat_win, { line_count, 0 })
			end
		end
	end
end

-- Initialize provider (load saved or use default)
function M.initialize_provider()
	if not M.load_saved_provider() then
		-- If no saved provider or invalid, use default
		current_provider = "ollama"
	end
end

-- Create or show chat window as resizable panes
function M.toggle_chat_window()
	-- Initialize provider on first use
	if not M._provider_initialized then
		M.initialize_provider()
		M._provider_initialized = true
	end

	-- Check if chat windows exist and are valid
	local chat_exists = chat_win and vim.api.nvim_win_is_valid(chat_win)
	local input_exists = input_win and vim.api.nvim_win_is_valid(input_win)

	if chat_exists or input_exists then
		-- Close chat windows
		if chat_exists and chat_win then
			vim.api.nvim_win_close(chat_win, true)
		end
		if input_exists and input_win then
			vim.api.nvim_win_close(input_win, true)
		end
		chat_win = nil
		input_win = nil
		return
	end

	-- Create chat buffer if it doesn't exist
	if not chat_buf or not vim.api.nvim_buf_is_valid(chat_buf) then
		chat_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[chat_buf].buftype = "nofile"
		vim.bo[chat_buf].swapfile = false
		vim.bo[chat_buf].filetype = "markdown"
		vim.api.nvim_buf_set_name(chat_buf, "[" .. get_providers()[current_provider].name .. " Chat]")

		-- Add welcome message
		local welcome = "=== " .. get_providers()[current_provider].name .. " Chat ==="
		local help_text = {
			"Model: " .. config.ollama.current_model .. " (auto-saved)",
			"Ollama: <leader>om (switch), <leader>ol (list), <leader>oa (add), <leader>or (remove), <leader>ou (URL), <leader>oc (config)",
			"Toggle: <leader>oo or <F12>",
			"Send message: <C-Enter> (insert), <CR> (normal) | Accept/Deny: 'a' / 'd'",
			"Chat: <leader>och (clear history), <leader>occ (clear context), <leader>osc (show context) | Debug: <leader>od (selection), <leader>oe (edit state), <leader>orf (read file), <leader>oh (help), <leader>of (focus), <leader>oft (test focus)",
			"💾 Provider preference is automatically saved",
			"",
		}
		local lines = { welcome, "" }
		for _, line in ipairs(help_text) do
			table.insert(lines, line)
		end
		vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, lines)
		vim.bo[chat_buf].modifiable = false
	end

	-- Create input buffer if it doesn't exist
	if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
		input_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[input_buf].buftype = "nofile"
		vim.bo[input_buf].swapfile = false
		vim.bo[input_buf].filetype = "text"
		vim.api.nvim_buf_set_name(input_buf, "[Ollama Input]")
	end

	-- Create vertical split on the right (40% width)
	vim.cmd("rightbelow 50vnew")
	chat_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(chat_win, chat_buf)

	-- Create horizontal split in chat pane for input (larger height)
	vim.cmd("rightbelow 8split")
	input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(input_win, input_buf)

	-- ===========================================
	-- INPUT BUFFER KEYMAPS
	-- ===========================================

	-- Visual mode - Send selection to chat window with Ctrl+S
	vim.api.nvim_set_keymap(
		"v",
		"<C-s>",
		':<C-U>lua require("config.ollama_chat").send_selection_to_chat()<CR>',
		{ noremap = true, silent = true, desc = "Send selection to Ollama chat" }
	)

	-- Normal mode - Send current line to chat window with Ctrl+S
	vim.api.nvim_set_keymap(
		"n",
		"<C-s>",
		':lua require("config.ollama_chat").send_selection_to_chat()<CR>',
		{ noremap = true, silent = true, desc = "Send current line to Ollama chat" }
	)
	vim.api.nvim_set_keymap(
		"v",
		"<leader>oe",
		':<C-U>lua require("config.ollama_chat").send_selection_to_chat_for_editing()<CR>',
		{ noremap = true, silent = true, desc = "Send selection to Ollama for editing with accept/deny" }
	)
	vim.api.nvim_set_keymap(
		"n",
		"<leader>oe",
		':lua require("config.ollama_chat").send_selection_to_chat_for_editing()<CR>',
		{ noremap = true, silent = true, desc = "Send current line to Ollama for editing with accept/deny" }
	)

	-- Send selection for adding debug code
	vim.api.nvim_set_keymap(
		"v",
		"<leader>og",
		':<C-U>lua require("config.ollama_chat").send_selection_to_chat_for_debug()<CR>',
		{ noremap = true, silent = true, desc = "Send selection to Ollama for adding debug code" }
	)
	vim.api.nvim_set_keymap(
		"n",
		"<leader>og",
		':lua require("config.ollama_chat").send_selection_to_chat_for_debug()<CR>',
		{ noremap = true, silent = true, desc = "Send current line to Ollama for adding debug code" }
	)

	-- Basic Input/Output Operations
	set_keymap(
		input_buf,
		"n",
		"<leader>oo",
		":lua require('config.ollama_chat').toggle_chat_window()<CR>",
		{ noremap = true, silent = true },
		"Toggle chat window"
	)
	-- Backup keymap
	set_keymap(
		input_buf,
		"n",
		"<F12>",
		":lua require('config.ollama_chat').toggle_chat_window()<CR>",
		{ noremap = true, silent = true },
		"Toggle chat window (backup)"
	)
	-- Send message mappings (use Ctrl+Enter in insert mode)
	set_keymap(
		input_buf,
		"i",
		"<C-Enter>",
		"<Esc>:lua require('config.ollama_chat').send_chat_message()<CR>",
		{ noremap = true, silent = true },
		"Send message (insert mode)"
	)
	set_keymap(
		input_buf,
		"i",
		"<C-M>",
		"<Esc>:lua require('config.ollama_chat').send_chat_message()<CR>",
		{ noremap = true, silent = true },
		"Send message (insert mode)"
	)

	-- Code Edit Actions (accessible from input window)
	set_keymap(
		input_buf,
		"n",
		"a",
		":lua require('config.ollama_chat').accept_code_edit()<CR>",
		{ noremap = true, silent = true },
		"Accept AI code suggestion"
	)
	set_keymap(
		input_buf,
		"n",
		"d",
		":lua require('config.ollama_chat').deny_code_edit()<CR>",
		{ noremap = true, silent = true },
		"Deny AI code suggestion"
	)

	-- Provider Management (removed <leader>p* keymaps as requested)

	-- Ollama Configuration
	set_keymap(
		input_buf,
		"n",
		"<leader>om",
		":lua require('config.ollama_chat').select_ollama_model()<CR>",
		{ noremap = true, silent = true },
		"Select Ollama model"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>ol",
		":lua require('config.ollama_chat').list_models()<CR>",
		{ noremap = true, silent = true },
		"List available Ollama models"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>oa",
		":lua require('config.ollama_chat').add_model_interactive()<CR>",
		{ noremap = true, silent = true },
		"Add custom Ollama model"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>or",
		":lua require('config.ollama_chat').remove_model_interactive()<CR>",
		{ noremap = true, silent = true },
		"Remove custom Ollama model"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>oreset",
		":OllamaResetModel<CR>",
		{ noremap = true, silent = true },
		"Reset model configuration"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>oinit",
		":OllamaInitModel<CR>",
		{ noremap = true, silent = true },
		"Initialize model configuration"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>oinfo",
		":OllamaModelInfo<CR>",
		{ noremap = true, silent = true },
		"Show detailed model information"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>of",
		":lua require('config.ollama_chat').focus_input_window()<CR>",
		{ noremap = true, silent = true },
		"Focus back to input window"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>oft",
		":OllamaTestFocus<CR>",
		{ noremap = true, silent = true },
		"Test cursor focus functionality"
	)

	set_keymap(
		input_buf,
		"n",
		"<leader>ou",
		":lua require('config.ollama_chat').select_ollama_url()<CR>",
		{ noremap = true, silent = true },
		"Configure Ollama server URL"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>oc",
		":lua require('config.ollama_chat').show_ollama_config()<CR>",
		{ noremap = true, silent = true },
		"Show Ollama configuration"
	)

	set_keymap(
		input_buf,
		"n",
		"<leader>oh",
		":lua require('config.ollama_chat').show_keymap_help()<CR>",
		{ noremap = true, silent = true },
		"Show keymap help"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>och",
		":OllamaClearHistory<CR>",
		{ noremap = true, silent = true },
		"Clear chat history"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>occ",
		":OllamaClearContext<CR>",
		{ noremap = true, silent = true },
		"Clear chat context"
	)
	set_keymap(
		input_buf,
		"n",
		"<leader>osc",
		":OllamaShowContext<CR>",
		{ noremap = true, silent = true },
		"Show chat context"
	)

	-- Legacy Provider Switching (removed <leader>p* keymaps as requested)

	-- ===========================================
	-- CHAT BUFFER KEYMAPS
	-- ===========================================

	-- Window Management
	set_keymap(
		chat_buf,
		"n",
		"<leader>oo",
		":lua require('config.ollama_chat').toggle_chat_window()<CR>",
		{ noremap = true, silent = true },
		"Toggle chat window"
	)
	-- Backup keymap
	set_keymap(
		chat_buf,
		"n",
		"<F12>",
		":lua require('config.ollama_chat').toggle_chat_window()<CR>",
		{ noremap = true, silent = true },
		"Toggle chat window (backup)"
	)

	-- Code Edit Actions (when AI suggests code changes)
	set_keymap(
		chat_buf,
		"n",
		"a",
		":lua require('config.ollama_chat').accept_code_edit()<CR>",
		{ noremap = true, silent = true },
		"Accept AI code suggestion"
	)
	set_keymap(
		chat_buf,
		"n",
		"d",
		":lua require('config.ollama_chat').deny_code_edit()<CR>",
		{ noremap = true, silent = true },
		"Deny AI code suggestion"
	)

	-- Provider Management (removed <leader>p* keymaps as requested)

	-- Ollama Configuration
	set_keymap(
		chat_buf,
		"n",
		"<leader>om",
		":lua require('config.ollama_chat').select_ollama_model()<CR>",
		{ noremap = true, silent = true },
		"Select Ollama model"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>ol",
		":lua require('config.ollama_chat').list_models()<CR>",
		{ noremap = true, silent = true },
		"List available Ollama models"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>oa",
		":lua require('config.ollama_chat').add_model_interactive()<CR>",
		{ noremap = true, silent = true },
		"Add custom Ollama model"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>or",
		":lua require('config.ollama_chat').remove_model_interactive()<CR>",
		{ noremap = true, silent = true },
		"Remove custom Ollama model"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>oreset",
		":OllamaResetModel<CR>",
		{ noremap = true, silent = true },
		"Reset model configuration"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>oinit",
		":OllamaInitModel<CR>",
		{ noremap = true, silent = true },
		"Initialize model configuration"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>oinfo",
		":OllamaModelInfo<CR>",
		{ noremap = true, silent = true },
		"Show detailed model information"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>of",
		":lua require('config.ollama_chat').focus_input_window()<CR>",
		{ noremap = true, silent = true },
		"Focus back to input window"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>oft",
		":OllamaTestFocus<CR>",
		{ noremap = true, silent = true },
		"Test cursor focus functionality"
	)

	set_keymap(
		chat_buf,
		"n",
		"<leader>ou",
		":lua require('config.ollama_chat').select_ollama_url()<CR>",
		{ noremap = true, silent = true },
		"Configure Ollama server URL"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>oc",
		":lua require('config.ollama_chat').show_ollama_config()<CR>",
		{ noremap = true, silent = true },
		"Show Ollama configuration"
	)

	-- Debugging
	set_keymap(
		chat_buf,
		"n",
		"<leader>od",
		":lua require('config.ollama_chat').debug_selection()<CR>",
		{ noremap = true, silent = true },
		"Debug current selection"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>oh",
		":lua require('config.ollama_chat').show_keymap_help()<CR>",
		{ noremap = true, silent = true },
		"Show keymap help"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>och",
		":OllamaClearHistory<CR>",
		{ noremap = true, silent = true },
		"Clear chat history"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>occ",
		":OllamaClearContext<CR>",
		{ noremap = true, silent = true },
		"Clear chat context"
	)
	set_keymap(
		chat_buf,
		"n",
		"<leader>osc",
		":OllamaShowContext<CR>",
		{ noremap = true, silent = true },
		"Show chat context"
	)

	-- Legacy Provider Switching (removed <leader>p* keymaps as requested)

	-- Enter insert mode in input window
	vim.cmd("startinsert")
end

-- Switch to a different provider
function M.switch_provider(provider)
	-- Initialize provider if not already done
	if not M._provider_initialized then
		M.initialize_provider()
		M._provider_initialized = true
	end

	if get_providers()[provider] then
		local valid, error_msg = M.validate_api_key(provider)
		if not valid then
			print("Error: " .. error_msg)
			return
		end

		local old_provider = current_provider
		current_provider = provider

		-- Save the new provider setting
		local saved = M.save_current_provider()
		if not saved then
			print("Warning: Could not save provider preference")
		end

		if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
			-- Update chat header to show current provider
			local header = "=== " .. get_providers()[provider].name .. " Chat ==="
			vim.api.nvim_set_option_value("modifiable", true, { buf = chat_buf })
			vim.api.nvim_buf_set_lines(chat_buf, 0, 1, false, { header, "" })
			vim.api.nvim_set_option_value("modifiable", false, { buf = chat_buf })
		end

		if old_provider ~= provider then
			local save_status = saved and " (saved)" or " (not saved)"
			print("Switched to " .. get_providers()[provider].name .. save_status)
		end
	else
		print("Error: Unknown provider '" .. provider .. "'")
	end
end

-- Show current provider status
function M.show_provider_status()
	-- Initialize provider if not already done
	if not M._provider_initialized then
		M.initialize_provider()
		M._provider_initialized = true
	end

	local status = "Current provider: " .. get_providers()[current_provider].name
	if current_provider ~= "ollama" then
		local valid, error_msg = M.validate_api_key(current_provider)
		if not valid then
			status = status .. " (API key missing: " .. error_msg .. ")"
		else
			status = status .. " (API key configured)"
		end
	end

	-- Show persistence info
	local file_exists = vim.fn.filereadable(provider_config_file) == 1
	if file_exists then
		status = status .. " (saved)"
	else
		status = status .. " (not saved)"
	end

	print(status)
end

-- Show detailed provider configuration info
function M.show_provider_config_info()
	print("=== AI Chat Provider Configuration ===")
	print("Config file: " .. provider_config_file)
	print("Current provider: " .. get_providers()[current_provider].name)

	local file_exists = vim.fn.filereadable(provider_config_file) == 1
	if file_exists then
		local file = io.open(provider_config_file, "r")
		if file then
			local content = file:read("*all")
			file:close()
			local success, data = pcall(vim.json.decode, content)
			if success and data then
				print("Saved provider: " .. (data.provider or "none"))
				if data.timestamp then
					print("Last saved: " .. os.date("%Y-%m-%d %H:%M:%S", data.timestamp))
				end
			end
		end
	else
		print("No saved configuration found")
	end

	print("\nAvailable providers:")
	for key, provider in pairs(get_providers()) do
		local status = ""
		if key ~= "ollama" then
			local valid, error_msg = M.validate_api_key(key)
			if not valid then
				status = " (API key missing)"
			else
				status = " (configured)"
			end
		else
			status = " (local)"
		end
		local current_marker = (key == current_provider) and " ← current" or ""
		print("  " .. provider.name .. status .. current_marker)
	end
end

-- Show provider selection popup
function M.show_provider_popup()
	-- Initialize provider if not already done
	if not M._provider_initialized then
		M.initialize_provider()
		M._provider_initialized = true
	end

	local options = {}
	local option_keys = {}

	for key, provider in pairs(get_providers()) do
		local status = ""
		if key ~= "ollama" then
			local valid, error_msg = M.validate_api_key(key)
			if not valid then
				status = " (⚠️  API key missing)"
			else
				status = " (✅ configured)"
			end
		else
			status = " (🏠 local)"
		end

		local display_name = provider.name .. status
		if key == current_provider then
			display_name = "● " .. display_name .. " (current)"
		else
			display_name = "○ " .. display_name
		end

		table.insert(options, display_name)
		table.insert(option_keys, key)
	end

	-- Try vim.ui.select first, fallback to custom popup
	if vim.ui and vim.ui.select then
		vim.ui.select(options, {
			prompt = "Select AI Provider:",
			format_item = function(item)
				return item
			end,
		}, function(choice, idx)
			if choice and idx then
				local selected_provider = option_keys[idx]
				M.switch_provider(selected_provider)
			end
		end)
	else
		-- Fallback: create a simple floating window popup
		M.show_custom_provider_popup(options, option_keys)
	end
end

-- Custom floating window popup for provider selection
function M.show_custom_provider_popup(options, option_keys)
	local width = 50
	local height = #options + 2
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
	vim.api.nvim_set_option_value("swapfile", false, { buf = buf })

	-- Create window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	-- Set content
	local lines = { "Select AI Provider:", "" }
	for i, option in ipairs(options) do
		table.insert(lines, string.format("%d. %s", i, option))
	end
	table.insert(lines, "")
	table.insert(lines, "Press number key to select, Esc to cancel")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Set keymaps for selection
	for i = 1, #options do
		vim.api.nvim_buf_set_keymap(
			buf,
			"n",
			tostring(i),
			string.format(':lua require("config.ollama_chat").select_provider_from_popup(%d)<CR>', i),
			{ noremap = true, silent = true }
		)
	end

	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<Esc>",
		':lua require("config.ollama_chat").close_provider_popup()<CR>',
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"q",
		':lua require("config.ollama_chat").close_provider_popup()<CR>',
		{ noremap = true, silent = true }
	)

	-- Store popup state
	M.provider_popup = {
		win = win,
		buf = buf,
		options = option_keys,
	}

	-- Enter insert mode to make it more obvious it's interactive
	vim.cmd("startinsert")
end

-- Select provider from popup
function M.select_provider_from_popup(index)
	if M.provider_popup and M.provider_popup.options[index] then
		local selected_provider = M.provider_popup.options[index]
		M.close_provider_popup()
		M.switch_provider(selected_provider)
	end
end

-- Close provider popup
function M.close_provider_popup()
	if M.provider_popup then
		if vim.api.nvim_win_is_valid(M.provider_popup.win) then
			vim.api.nvim_win_close(M.provider_popup.win, true)
		end
		if vim.api.nvim_buf_is_valid(M.provider_popup.buf) then
			vim.api.nvim_buf_delete(M.provider_popup.buf, { force = true })
		end
		M.provider_popup = nil
	end
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

	-- Ensure cursor stays in input window
	if input_win and vim.api.nvim_win_is_valid(input_win) then
		vim.api.nvim_set_current_win(input_win)
	end

	-- Add user message to chat
	M.add_to_chat(message, true)

	-- Show "thinking" indicator
	M.add_to_chat("Thinking...", false)

	-- Build message with context
	local context = M.build_chat_context()
	local message_with_context = message

	if context ~= "" then
		message_with_context = context .. "Current user message: " .. message
	end

	-- Send to AI provider with context
	M.query_ai_async(message_with_context, function(response)
		vim.schedule(function()
			-- Remove "thinking" indicator
			if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
				vim.bo[chat_buf].modifiable = true
				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				-- Remove last 2 lines ("Thinking..." and empty line)
				if line_count >= 2 then
					vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
				end
				vim.bo[chat_buf].modifiable = false
			end

			-- Add AI response
			if response and response ~= "" then
				M.add_to_chat(response, false)

				-- Check if we have a pending edit context and if response contains code
				if pending_edit.original_buf and vim.api.nvim_buf_is_valid(pending_edit.original_buf) then
					local suggested_code = M.extract_code_from_response(response)
					if suggested_code then
						-- Store the suggested code for potential application
						pending_edit.suggested_code = suggested_code
						pending_edit.response_id = os.time() .. "_" .. math.random(1000)

						-- Show accept/deny options
						M.add_edit_options()

						-- Keep focus in input window even with code suggestions
						-- User can press 'a'/'d' from input window or switch to chat window
					end
				end
			else
				M.add_to_chat("No response received from Ollama", false)
			end

			-- Always focus back to input window after processing response
			vim.defer_fn(function()
				if input_win and vim.api.nvim_win_is_valid(input_win) then
					-- Force focus to input window
					vim.api.nvim_set_current_win(input_win)

					-- Ensure we're in normal mode
					vim.schedule(function()
						local current_mode = vim.api.nvim_get_mode().mode
						if current_mode == "i" then
							vim.cmd("stopinsert")
						end
					end)
				end
			end, 300) -- Delay for proper execution
		end)
	end)
end

-- Get LSP diagnostics for current buffer and selection range
function M.get_lsp_diagnostics_for_selection()
	local buf = vim.api.nvim_get_current_buf()

	-- For current line selection (when no visual selection)
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local start_line = current_line
	local end_line = current_line

	-- Try to get visual selection marks
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos(">")

	-- If we have a valid visual selection, use it
	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		start_line = vstart[2]
		end_line = vend[2]
	end

	-- Get all diagnostics for the current buffer
	local diagnostics = vim.diagnostic.get(buf)

	local relevant_diagnostics = {}
	local similar_diagnostics = {} -- Track similar issues throughout the file

	-- Filter diagnostics that are within the selection range
	for _, diag in ipairs(diagnostics) do
		local diag_line = diag.lnum + 1 -- LSP uses 0-based, Vim uses 1-based

		if diag_line >= start_line and diag_line <= end_line then
			table.insert(relevant_diagnostics, diag)
		end

		-- Also collect similar diagnostics (same message pattern) from the whole file
		if diag.message:match("Deprecated") or diag.message:match("nvim_buf_set_option") then
			table.insert(similar_diagnostics, diag)
		end
	end

	-- If we only found a few diagnostics in the selection, but there are many similar ones,
	-- include some of the similar ones to give better context
	if #relevant_diagnostics < 3 and #similar_diagnostics > #relevant_diagnostics then
		for _, diag in ipairs(similar_diagnostics) do
			local already_included = false
			for _, existing in ipairs(relevant_diagnostics) do
				if diag.lnum == existing.lnum then
					already_included = true
					break
				end
			end
			if not already_included then
				table.insert(relevant_diagnostics, diag)
				-- Limit to avoid too much output
				if #relevant_diagnostics >= 10 then
					break
				end
			end
		end
	end

	return relevant_diagnostics
end

-- Format LSP diagnostics into readable text
function M.format_lsp_diagnostics(diagnostics)
	if #diagnostics == 0 then
		return nil
	end

	local formatted = { "\n\nLSP ERRORS/WARNINGS in this code:" }

	for _, diag in ipairs(diagnostics) do
		local severity = ""
		if diag.severity == 1 then
			severity = "ERROR"
		elseif diag.severity == 2 then
			severity = "WARNING"
		elseif diag.severity == 3 then
			severity = "INFO"
		elseif diag.severity == 4 then
			severity = "HINT"
		end

		local line_info = string.format("Line %d: [%s] %s", diag.lnum + 1, severity, diag.message)
		if diag.source then
			line_info = line_info .. " (" .. diag.source .. ")"
		end

		table.insert(formatted, line_info)
	end

	return table.concat(formatted, "\n")
end

-- Send selection to chat for adding debug code (shows in input, doesn't send automatically)
function M.send_selection_to_chat_for_debug()
	local text = M.get_selection()
	if not text or text == "" then
		print("No text selected!")
		return
	end

	-- Store selection context for later editing
	M.store_selection_context()

	-- Get LSP diagnostics for the selected code
	local diagnostics = M.get_lsp_diagnostics_for_selection()
	local lsp_info = M.format_lsp_diagnostics(diagnostics)

	-- Create the debug prompt with the selected code and LSP errors
	local debug_prompt = clean_code_prompt .. "\n\n" .. text
	-- Add LSP diagnostics if available
	if lsp_info then
		debug_prompt = debug_prompt .. lsp_info .. "\n\n fix it"
	else
		debug_prompt = debug_prompt .. "\n\nfix it"
	end

	-- Open chat window if not open
	if not chat_win or not vim.api.nvim_win_is_valid(chat_win) then
		M.toggle_chat_window()
		-- Wait a moment for the window to be created, then populate input
		vim.defer_fn(function()
			M.populate_input_for_editing(debug_prompt)
		end, 100)
	else
		-- Chat window is already open, populate input immediately
		M.populate_input_for_editing(debug_prompt)
	end
end

-- Send selection to chat input for code editing (shows in input, doesn't send automatically)
function M.send_selection_to_chat_for_editing()
	local text = M.get_selection()
	if not text or text == "" then
		print("No text selected!")
		return
	end

	-- Store selection context for later editing
	M.store_selection_context()

	-- Just send the selected code without extra prompt text
	local editing_prompt = clean_code_prompt .. "\n\n" .. text

	-- Open chat window if not open
	if not chat_win or not vim.api.nvim_win_is_valid(chat_win) then
		M.toggle_chat_window()
		-- Wait a moment for the window to be created, then populate input
		vim.defer_fn(function()
			M.populate_input_for_editing(editing_prompt)
		end, 100)
	else
		-- Chat window is already open, populate input immediately
		M.populate_input_for_editing(editing_prompt)
	end
end

-- Populate input buffer with editing prompt (user can review before sending)
function M.populate_input_for_editing(prompt)
	if input_buf and vim.api.nvim_buf_is_valid(input_buf) then
		local lines = vim.split(prompt, "\n")
		vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, lines)
		-- Focus the input window
		if input_win and vim.api.nvim_win_is_valid(input_win) then
			vim.api.nvim_set_current_win(input_win)
			-- Position cursor at the end
			vim.api.nvim_win_set_cursor(input_win, { #lines, 0 })
			vim.cmd("startinsert!")
		end
	end
end

-- Process code edit request
function M.process_code_edit_request(text)
	-- Add user message to chat (show the code they want to edit)
	M.add_to_chat(text .. "\n```", true)

	-- Show "thinking" indicator
	M.add_to_chat("Thinking...", false)

	-- Send to AI provider
	M.query_ai_async(text, function(response)
		vim.schedule(function()
			-- Remove "thinking" indicator
			if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
				vim.bo[chat_buf].modifiable = false
				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				-- Remove last 2 lines ("Thinking..." and empty line)
				if line_count >= 2 then
					vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
				end
				vim.bo[chat_buf].modifiable = false
			end

			-- Add AI response
			if response and response ~= "" then
				M.add_to_chat(response, false)

				-- Check if response contains code that can be applied as edit
				local suggested_code = M.extract_code_from_response(response)
				if suggested_code then
					-- Store the suggested code for potential application
					pending_edit.suggested_code = suggested_code
					pending_edit.response_id = os.time() .. "_" .. math.random(1000)

					-- Show accept/deny options
					M.add_edit_options()
				end
			else
				M.add_to_chat("No response received from Ollama", false)
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

	-- Send to AI provider
	M.query_ai_async(message, function(response)
		vim.schedule(function()
			-- Remove "thinking" indicator
			if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
				vim.bo[chat_buf].modifiable = true

				local line_count = vim.api.nvim_buf_line_count(chat_buf)
				-- Remove last 2 lines ("Thinking..." and empty line)
				if line_count >= 2 then
					vim.api.nvim_buf_set_lines(chat_buf, line_count - 2, line_count, false, {})
				end
				vim.bo[chat_buf].modifiable = false
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

-- Test function for debugging
function M.test_ai()
	local test_text = "Hello, can you respond with just 'Hi there!'?"
	M.query_ai_async(test_text, function(response)
		vim.schedule(function()
			M.show_response(response)
		end)
	end)
end

-- Simple debug function showing cursor position and selection
function M.debug_selection()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local current_line = cursor_pos[1]
	local current_col = cursor_pos[2] + 1 -- Convert to 1-based

	-- Check for visual selection
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")

	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		-- Has visual selection
		local selected_text = M.get_selection()
		local lines_selected = vend[2] - vstart[2] + 1
		local chars_selected = selected_text and #selected_text or 0

		print(
			string.format(
				"Selection: %d lines, %d chars (lines %d-%d, cols %d-%d)",
				lines_selected,
				chars_selected,
				vstart[2],
				vend[2],
				vstart[3],
				vend[3]
			)
		)

		if selected_text and #selected_text <= 150 then
			print("Selected: '" .. selected_text .. "'")
		end
	else
		-- No selection, show cursor info
		local line_content = vim.api.nvim_get_current_line()
		print(string.format("Cursor: Line %d, Col %d | Line: '%s'", current_line, current_col, line_content))
	end
end

-- Debug function to show pending edit state
function M.debug_pending_edit()
	if not pending_edit.original_buf then
		print("No pending edit - no code has been sent for editing yet")
		return
	end

	print("=== Pending Edit State ===")
	print("Buffer valid: " .. (vim.api.nvim_buf_is_valid(pending_edit.original_buf) and "Yes" or "No"))
	print(
		"Selection: Lines "
			.. (pending_edit.original_start_line or "?")
			.. "-"
			.. (pending_edit.original_end_line or "?")
	)
	print("Columns: " .. (pending_edit.original_start_col or "?") .. "-" .. (pending_edit.original_end_col or "?"))

	if pending_edit.suggested_code then
		local code_lines = vim.split(pending_edit.suggested_code, "\n")
		print("AI suggested " .. #code_lines .. " lines of code")
		if #pending_edit.suggested_code <= 200 then
			print("Suggested code: " .. pending_edit.suggested_code)
		else
			print("Suggested code preview: " .. pending_edit.suggested_code:sub(1, 200) .. "...")
		end
	else
		print("No AI suggestion available yet")
	end

	-- Show current cursor position for context
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	print("Current cursor: Line " .. cursor_pos[1] .. ", Column " .. (cursor_pos[2] + 1))
end

-- Read and analyze current file for debugging
function M.read_current_file()
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local filename = vim.api.nvim_buf_get_name(buf)
	local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })

	print("=== Current File Analysis ===")
	print("File: " .. (filename ~= "" and filename or "Untitled"))
	print("Type: " .. filetype)
	print("Lines: " .. #lines)
	print("Size: " .. string.len(table.concat(lines, "\n")) .. " characters")
	print("")

	-- Show file structure overview
	if #lines > 0 then
		print("File Content Preview:")
		print("--- First 10 lines ---")
		for i = 1, math.min(10, #lines) do
			print(string.format("%4d: %s", i, lines[i]))
		end

		if #lines > 10 then
			print("...")
			print("--- Last 5 lines ---")
			for i = math.max(1, #lines - 4), #lines do
				print(string.format("%4d: %s", i, lines[i]))
			end
		end
	end

	-- Analyze code structure
	M.analyze_file_structure(lines, filetype)

	return {
		filename = filename,
		filetype = filetype,
		lines = lines,
		content = table.concat(lines, "\n"),
	}
end

-- Analyze file structure based on filetype
function M.analyze_file_structure(lines, filetype)
	print("")
	print("=== Code Structure Analysis ===")

	if filetype == "lua" then
		M.analyze_lua_structure(lines)
	elseif filetype == "python" then
		M.analyze_python_structure(lines)
	elseif filetype == "javascript" or filetype == "typescript" then
		M.analyze_js_structure(lines)
	else
		print("Structure analysis not available for filetype: " .. filetype)
	end
end

-- Analyze Lua file structure
function M.analyze_lua_structure(lines)
	local functions = {}
	local modules = {}
	local classes = {}

	for i, line in ipairs(lines) do
		-- Find functions
		local func_name = line:match("function%s+([%w_.:]+)")
		if func_name then
			table.insert(functions, { name = func_name, line = i })
		end

		-- Find local modules
		local mod_name = line:match("local%s+([%w_]+)%s*=")
		if mod_name and line:match("require") then
			table.insert(modules, { name = mod_name, line = i })
		end
	end

	if #functions > 0 then
		print("Functions found (" .. #functions .. "):")
		for _, func in ipairs(functions) do
			print(string.format("  Line %d: %s", func.line, func.name))
		end
	end

	if #modules > 0 then
		print("Modules found (" .. #modules .. "):")
		for _, mod in ipairs(modules) do
			print(string.format("  Line %d: %s", mod.line, mod.name))
		end
	end
end

-- Analyze Python file structure
function M.analyze_python_structure(lines)
	local functions = {}
	local classes = {}
	local imports = {}

	for i, line in ipairs(lines) do
		-- Find functions
		local func_name = line:match("def%s+([%w_]+)")
		if func_name then
			table.insert(functions, { name = func_name, line = i })
		end

		-- Find classes
		local class_name = line:match("class%s+([%w_]+)")
		if class_name then
			table.insert(classes, { name = class_name, line = i })
		end

		-- Find imports
		if line:match("^import") or line:match("^from") then
			table.insert(imports, { name = line:gsub("^%s*", ""), line = i })
		end
	end

	if #classes > 0 then
		print("Classes found (" .. #classes .. "):")
		for _, class in ipairs(classes) do
			print(string.format("  Line %d: %s", class.line, class.name))
		end
	end

	if #functions > 0 then
		print("Functions found (" .. #functions .. "):")
		for _, func in ipairs(functions) do
			print(string.format("  Line %d: %s", func.line, func.name))
		end
	end

	if #imports > 0 then
		print("Imports found (" .. #imports .. "):")
		for _, imp in ipairs(imports) do
			print(string.format("  Line %d: %s", imp.line, imp.name))
		end
	end
end

-- Analyze JavaScript/TypeScript file structure
function M.analyze_js_structure(lines)
	local functions = {}
	local classes = {}
	local imports = {}

	for i, line in ipairs(lines) do
		-- Find functions
		local func_name = line:match("function%s+([%w_]+)")
			or line:match("([%w_]+)%s*=>")
			or line:match("([%w_]+)%s*:\\s*function")
		if func_name then
			table.insert(functions, { name = func_name, line = i })
		end

		-- Find classes
		local class_name = line:match("class%s+([%w_]+)")
		if class_name then
			table.insert(classes, { name = class_name, line = i })
		end

		-- Find imports
		if line:match("^import") or line:match("^export") then
			table.insert(imports, { name = line:gsub("^%s*", ""), line = i })
		end
	end

	if #classes > 0 then
		print("Classes found (" .. #classes .. "):")
		for _, class in ipairs(classes) do
			print(string.format("  Line %d: %s", class.line, class.name))
		end
	end

	if #functions > 0 then
		print("Functions found (" .. #functions .. "):")
		for _, func in ipairs(functions) do
			print(string.format("  Line %d: %s", func.line, func.name))
		end
	end

	if #imports > 0 then
		print("Imports/Exports found (" .. #imports .. "):")
		for _, imp in ipairs(imports) do
			print(string.format("  Line %d: %s", imp.line, imp.name))
		end
	end
end

-- Build context from recent chat history
function M.build_chat_context()
	if #chat_history == 0 then
		return ""
	end

	local context_parts = {}
	local recent_history = {}

	-- Get last 5 conversations for context (don't include the current message being sent)
	local start_idx = math.max(1, #chat_history - 4)
	for i = start_idx, #chat_history do
		table.insert(recent_history, chat_history[i])
	end

	-- Build context string
	for _, entry in ipairs(recent_history) do
		local role = entry.is_user and "User" or "Assistant"
		table.insert(context_parts, role .. ": " .. entry.raw_message)
	end

	if #context_parts > 0 then
		return "\n\nRecent conversation context:\n" .. table.concat(context_parts, "\n") .. "\n\n"
	end

	return ""
end

function M.clear_chat_history()
	chat_history = {}
	print("Chat history cleared")
end

function M.clear_chat_context()
	chat_history = {}
	print("Chat context cleared")
end

function M.remove_last_conversations(count)
	count = count or 1
	if count > #chat_history then
		count = #chat_history
	end

	for i = 1, count do
		table.remove(chat_history)
	end

	print("Removed last " .. count .. " conversations")
	print("Remaining conversations: " .. #chat_history)
end

-- Debug function to test LSP diagnostics
function M.debug_lsp_diagnostics()
	local buf = vim.api.nvim_get_current_buf()
	local diagnostics = vim.diagnostic.get(buf)

	print("=== LSP Diagnostics Debug ===")
	print("Buffer: " .. buf)
	print("Total diagnostics in buffer: " .. #diagnostics)

	for i, diag in ipairs(diagnostics) do
		print(
			string.format(
				"[%d] Line %d (0-based: %d): [%s] %s",
				i,
				diag.lnum + 1,
				diag.lnum,
				(diag.severity == 1 and "ERROR")
					or (diag.severity == 2 and "WARNING")
					or (diag.severity == 3 and "INFO")
					or (diag.severity == 4 and "HINT")
					or "UNKNOWN",
				diag.message
			)
		)
		if diag.source then
			print("    Source: " .. diag.source)
		end
	end

	-- Test the selection range detection
	local current_line = vim.api.nvim_win_get_cursor(0)[1]
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")

	print("\n=== Selection Range Debug ===")
	print("Current cursor line: " .. current_line)
	print("Visual start: " .. vim.inspect(vstart))
	print("Visual end: " .. vim.inspect(vend))

	if vstart[2] > 0 and vend[2] > 0 and (vstart[2] ~= vend[2] or vstart[3] ~= vend[3]) then
		print("Selection range: " .. vstart[2] .. " to " .. vend[2])
	else
		print("No visual selection, using current line: " .. current_line)
	end
end

-- تابع اصلی (برای quick queries)
function M.send_to_ai()
	local text = M.get_selection()
	if not text or text == "" then
		return
	end

	M.query_ai_async(text, function(response)
		vim.schedule(function()
			M.show_response(response)
		end)
	end)
end

-- Global function to show provider popup from anywhere
function M.select_provider_global()
	M.show_provider_popup()
end

-- Test Ollama connection
function M.test_ollama_connection()
	print("Testing Ollama connection...")

	local test_text = "Hello, respond with just 'OK' if you can hear me."

	M.query_ollama_async(test_text, function(response)
		vim.schedule(function()
			print("Ollama test response: " .. (response or "nil"))
		end)
	end)
end

-- Simple synchronous Ollama test
function M.test_ollama_simple()
	print("Testing simple Ollama command...")

	local model = get_providers().ollama.model
	local handle = io.popen(string.format('echo "Hi" | timeout 10s ollama run %s 2>/dev/null | head -5', model))
	if handle then
		local result = handle:read("*a")
		handle:close()
		print("Simple test result:")
		print(result)
	else
		print("Failed to run simple test")
	end
end

-- Test provider persistence (for debugging)
function M.test_provider_persistence()
	print("=== Testing Provider Persistence ===")

	-- Test saving
	local original_provider = current_provider
	current_provider = "openai"
	local saved = M.save_current_provider()
	print("Save test: " .. (saved and "SUCCESS" or "FAILED"))

	-- Test loading
	current_provider = "ollama" -- Reset to different value
	local loaded = M.load_saved_provider()
	print("Load test: " .. (loaded and "SUCCESS" or "FAILED"))
	print("Loaded provider: " .. current_provider)

	-- Restore original
	current_provider = original_provider
	M.save_current_provider()
	print("Restored original provider: " .. current_provider)
end

-- Create Neovim commands for easy access
vim.api.nvim_create_user_command("OllamaModel", function(opts)
	local model = opts.args
	if model ~= "" then
		M.set_current_model(model)
	else
		M.select_ollama_model()
	end
end, {
	nargs = "?",
	desc = "Set/switch Ollama model (interactive if no argument)",
	complete = function()
		local models = M.get_available_models()
		local completions = {}
		for _, model in ipairs(models) do
			table.insert(completions, model.name)
		end
		return completions
	end,
})

vim.api.nvim_create_user_command("OllamaListModels", function()
	M.list_models()
end, {
	desc = "List all available Ollama models",
})

vim.api.nvim_create_user_command("OllamaAddModel", function(opts)
	local model = opts.args
	if model ~= "" then
		M.add_custom_model(model)
	else
		print("Usage: :OllamaAddModel <model-name>")
	end
end, {
	nargs = 1,
	desc = "Add a custom Ollama model",
})

vim.api.nvim_create_user_command("OllamaRemoveModel", function(opts)
	local model = opts.args
	if model ~= "" then
		M.remove_model(model)
	else
		M.remove_model_interactive()
	end
end, {
	nargs = "?",
	desc = "Remove an Ollama model (interactive if no argument)",
	complete = function()
		local models = M.get_available_models()
		local completions = {}
		for _, model in ipairs(models) do
			table.insert(completions, model.name)
		end
		return completions
	end,
})

vim.api.nvim_create_user_command("OllamaResetModel", function()
	M.reset_model_config()
end, {
	desc = "Reset model configuration and clear saved preferences",
})

vim.api.nvim_create_user_command("OllamaSaveConfig", function()
	if M.save_model_config() then
		print("Model configuration saved successfully")
	else
		print("Failed to save model configuration")
	end
end, {
	desc = "Manually save current model configuration",
})

vim.api.nvim_create_user_command("OllamaInitModel", function()
	M.ensure_model_initialized()
	print("Model initialized. Current model: " .. config.ollama.current_model)
end, {
	desc = "Manually initialize model configuration",
})

vim.api.nvim_create_user_command("OllamaTestFocus", function()
	print("=== Focus Test ===")
	print("Current window: " .. vim.api.nvim_get_current_win())
	print("Input window: " .. (input_win or "nil"))
	print("Chat window: " .. (chat_win or "nil"))
	print("Current mode: " .. vim.api.nvim_get_mode().mode)

	if input_win and vim.api.nvim_win_is_valid(input_win) then
		vim.api.nvim_set_current_win(input_win)
		vim.cmd("startinsert")
		print("Focused to input window and entered insert mode")
	else
		print("Input window not available")
	end
end, {
	desc = "Test cursor focus functionality",
})

vim.api.nvim_create_user_command("OllamaModelInfo", function()
	print("=== Ollama Model Information ===")
	print("Current Model: " .. (config.ollama.current_model or "None"))
	print("")

	local available_models = M.get_available_models()
	print("Available Models (" .. #available_models .. " total):")

	local default_count = 0
	local custom_count = 0

	for _, model in ipairs(available_models) do
		local marker = (model.name == config.ollama.current_model) and " ← CURRENT" or ""
		local type_info = (model.type == "custom") and " (Custom)" or " (Default)"
		print(string.format("  %s%s%s", model.name, type_info, marker))

		if model.type == "default" then
			default_count = default_count + 1
		else
			custom_count = custom_count + 1
		end
	end

	print("")
	print("Summary:")
	print("  Default models: " .. default_count)
	print("  Custom models: " .. custom_count)
	print("")
	print("💡 Management Commands:")
	print("  Add model:    :OllamaAddModel <name>")
	print("  Remove model: :OllamaRemoveModel <name>")
	print("  Switch model: :OllamaModel <name>")
	print("  List models:  :OllamaListModels")
end, {
	desc = "Show detailed model information and management options",
})

vim.api.nvim_create_user_command("OllamaURL", function(opts)
	local url = opts.args
	if url ~= "" then
		M.set_ollama_url(url)
	else
		M.select_ollama_url()
	end
end, {
	nargs = "?",
	desc = "Set Ollama server URL (interactive if no argument)",
})

vim.api.nvim_create_user_command("OllamaConfig", function()
	M.show_ollama_config()
end, {
	desc = "Show current Ollama configuration",
})

vim.api.nvim_create_user_command("OllamaDebugSelection", function()
	M.debug_selection()
end, {
	desc = "Show cursor position and selection info",
})

vim.api.nvim_create_user_command("OllamaDebugEdit", function()
	M.debug_pending_edit()
end, {
	desc = "Show pending edit state",
})

vim.api.nvim_create_user_command("OllamaHelp", function()
	M.show_keymap_help()
end, {
	desc = "Show Ollama Chat keymap help",
})

vim.api.nvim_create_user_command("OllamaToggle", function()
	M.toggle_chat_window()
end, {
	desc = "Toggle Ollama chat window",
})

-- Global keymaps (work from any buffer)
vim.keymap.set("n", "<leader>oo", ':lua require("config.ollama_chat").toggle_chat_window()<CR>', {
	noremap = true,
	silent = true,
	desc = "Toggle Ollama chat window",
})

vim.keymap.set("n", "<F12>", ':lua require("config.ollama_chat").toggle_chat_window()<CR>', {
	noremap = true,
	silent = true,
	desc = "Toggle Ollama chat window (backup)",
})

vim.api.nvim_create_user_command("OllamaReadFile", function()
	M.read_current_file()
end, {
	desc = "Read and analyze current file for debugging",
})

vim.api.nvim_create_user_command("OllamaClearContext", function()
	M.clear_chat_context()
end, {
	desc = "Clear chat context (for fresh conversation)",
})

vim.api.nvim_create_user_command("OllamaShowContext", function()
	if #chat_history == 0 then
		print("No chat context available")
		return
	end

	print("=== Chat Context (" .. #chat_history .. " messages) ===")
	for i, entry in ipairs(chat_history) do
		local role = entry.is_user and "User" or "Assistant"
		print(
			string.format(
				"[%d] %s: %s",
				i,
				role,
				entry.raw_message:sub(1, 60) .. (entry.raw_message:len() > 60 and "..." or "")
			)
		)
	end
end, {
	desc = "Show current chat context",
})

return M
