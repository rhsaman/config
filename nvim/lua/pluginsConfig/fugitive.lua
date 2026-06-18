return {
	"tpope/vim-fugitive",
	dependencies = {
		"tpope/vim-rhubarb",
	},
	cmd = { "Git", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GRename", "GBrowse" },
	keys = {
		{ "<leader>ga", ":Git add .<cr>", desc = "Git add", silent = true },
		{ "<leader>gi", "<cmd>:Git<cr>", desc = "Git status", silent = true },
		{ "<leader>gd", ":Git diff<cr>", desc = "Git diff", silent = true },
		{ "<leader>gb", ":Gblame<cr>", desc = "Git blame", silent = true },
		{ "<leader>gl", ":Glog<cr>", desc = "Git log", silent = true },
		{ "<leader>gp", ":Gpush<cr>", desc = "Git push", silent = true },
		{ "<leader>gP", ":Gpull<cr>", desc = "Git pull", silent = true },
		{ "<leader>gc", "<cmd>GenerateCommit<cr>", desc = "Generate commit message (OpenRouter)", silent = true },
		{ "<leader>gB", ":GBrowse<cr>", desc = "Open in browser", silent = true },
	},
	config = function()
		-- Generate commit message using OpenRouter
		vim.api.nvim_create_user_command("GenerateCommit", function()
			-- Get staged diff
			local diff = vim.fn.system("git diff --cached")
			if vim.v.shell_error ~= 0 then
				vim.notify("No staged changes found. Stage your files first with :Git add .", vim.log.levels.ERROR)
				return
			end
			if diff == "" then
				vim.notify("No staged changes found. Stage your files first.", vim.log.levels.ERROR)
				return
			end

			vim.notify("Generating commit message from staged changes...", vim.log.levels.INFO)

			local api_key = vim.fn.getenv("OPENROUTER_API_KEY")
			if not api_key or api_key == "" then
				vim.notify("OPENROUTER_API_KEY not set", vim.log.levels.ERROR)
				return
			end

			local prompt = {
				model = "openrouter/free",
				messages = {
					{
						role = "system",
						content = "You are a commit message generator. Generate a concise, conventional commit message for the given diff. Output ONLY the commit message, no explanation, no markdown formatting.",
					},
					{
						role = "user",
						content = "Generate a commit message for this diff:\n\n" .. diff,
					},
				},
				temperature = 0.1,
				max_tokens = 128,
			}

			-- Write JSON payload to temp file to avoid shell escaping issues
			local tmpfile = vim.fn.tempname()
			vim.fn.writefile(vim.split(vim.fn.json_encode(prompt), "\n"), tmpfile)

			local result = vim.fn.system({
				"curl",
				"-s",
				"-X",
				"POST",
				"https://openrouter.ai/api/v1/chat/completions",
				"-H",
				"Content-Type: application/json",
				"-H",
				"Authorization: Bearer " .. api_key,
				"-H",
				"HTTP-Referer: https://github.com",
				"-d",
				"@" .. tmpfile,
			})
			local output = result

			-- Clean up temp file
			pcall(vim.fn.delete, tmpfile)

			local ok, json = pcall(vim.fn.json_decode, output)
			if not ok or not json.choices or #json.choices == 0 then
				vim.notify(
					"Failed to get response from OpenRouter. Error: " .. (json.error or output),
					vim.log.levels.ERROR
				)
				return
			end

			local commit_msg = json.choices[1].message.content
			-- Clean up the message
			commit_msg = vim.trim(commit_msg)
			commit_msg = commit_msg:gsub("^```", ""):gsub("```$", "")
			commit_msg = vim.trim(commit_msg)

			-- Write commit message to temp file and commit
			local msgfile = vim.fn.tempname()
			vim.fn.writefile(vim.split(commit_msg, "\n"), msgfile)
			local ret = vim.fn.system({ "git", "commit", "-F", msgfile })
			pcall(vim.fn.delete, msgfile)

			if vim.v.shell_error == 0 then
				vim.notify("Committed successfully!", vim.log.levels.INFO)
				-- Refresh fugitive if it's open

				pcall(function()
					vim.cmd("Git")
				end)
			else
				vim.notify("Commit failed: " .. vim.trim(ret), vim.log.levels.ERROR)
			end
		end, { desc = "Generate commit message using OpenRouter" })
	end,
}
