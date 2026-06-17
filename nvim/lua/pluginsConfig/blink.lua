return {
	"saghen/blink.cmp",
	version = "*",
	event = "InsertEnter",
	dependencies = {
		"rafamadriz/friendly-snippets",
		"onsails/lspkind.nvim",
	},
	opts = {
		keymap = {
			["<C-j>"] = { "select_next", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-o>"] = { "show", "fallback" },
			["<C-e>"] = { "hide", "fallback" },
			["<CR>"] = { "accept", "fallback" },
			["<Tab>"] = { "snippet_forward", "fallback" },
			["<S-Tab>"] = { "snippet_backward", "fallback" },
		},
		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},
		completion = {
			ghost_text = { enabled = true },
			list = {
				selection = { preselect = true, auto_insert = true },
			},
			menu = {
				auto_show = true,
			},
		},
		-- sources = {
		-- 	default = { "lsp", "path", "snippets", "buffer", "minuet" },
		-- 	providers = {
		-- 		minuet = {
		-- 			name = "minuet",
		-- 			module = "minuet.blink",
		-- 			async = true,
		-- 			timeout_ms = 15000,
		-- 		},
		-- 	},
		-- },
	},
}
