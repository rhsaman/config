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
		{ "<leader>gb", ":G blame<cr>", desc = "Git blame", silent = true },
		{ "<leader>gl", ":G log<cr>", desc = "Git log", silent = true },
		{ "<leader>gc", "<cmd>GenerateCommit<cr>", desc = "Generate commit message", silent = true },
		{ "<leader>gB", ":G Browse<cr>", desc = "Open in browser", silent = true },
	},
	config = function()
		-- Generate commit message using LM Studio
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

			local max_diff_len = 16000
			if #diff > max_diff_len then
				diff = diff:sub(1, max_diff_len) .. "\n# ... diff truncated due to size"
			end

			vim.notify("Generating commit message from staged changes...", vim.log.levels.INFO)

			local prompt = {
				model = "oc/big-pickle", -- qwen3.5-4b gemma-4-e2b-it
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
				temperature = 0.6,
				thinking = { type = "disabled" },
				max_tokens = 1024,
			}

			-- Write JSON payload to temp file to avoid shell escaping issues
			local tmpfile = vim.fn.tempname()
			vim.fn.writefile(vim.split(vim.fn.json_encode(prompt), "\n"), tmpfile)

			local result = vim.fn.system({
				"curl",
				"-s",
				"--max-time",
				"30",
				"-X",
				"POST",
				"http://localhost:20128/v1/chat/completions",
				"-H",
				"Content-Type: application/json",
				"-d",
				"@" .. tmpfile,
			})
			local output = result

			-- Clean up temp file
			pcall(vim.fn.delete, tmpfile)

			local ok, json = pcall(vim.fn.json_decode, output)
			if not ok then
				vim.notify("Failed to parse LM Studio response: " .. output, vim.log.levels.ERROR)
				return
			end
			if not json.choices or #json.choices == 0 then
				local err = json.error
				if type(err) == "table" then
					err = vim.inspect(err)
				end
				vim.notify("LM Studio error: " .. (err or "no choices in response"), vim.log.levels.ERROR)
				return
			end

			local commit_msg = json.choices[1].message.content
			if type(commit_msg) ~= "string" or commit_msg == "" then
				vim.notify("API returned empty or null content", vim.log.levels.ERROR)
				return
			end
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
		end, { desc = "Generate commit message using LM Studio" })
	end,
}
