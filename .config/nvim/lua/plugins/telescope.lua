return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	cmd = "Telescope",

	keys = {
	      { "<leader>ff", function() require('telescope.builtin').find_files() end, desc = "Telescope find files" },
	      { "<leader>fg", function() require('telescope.builtin').live_grep() end, desc = "Telescope live grep" },
	      { "<leader>fb", function() require('telescope.builtin').buffers() end, desc = "Telescope buffers" },
	      { "<leader>fh", function() require('telescope.builtin').help_tags() end, desc = "Telescope help tags" },
	    },

	config = function()
		require("telescope").setup({
		defaults = {
		  prompt_prefix = "🔍 ",
		  selection_caret = " ",
		  layout_strategy = "horizontal",
		  layout_config = {
		    preview_cutoff = 120,
		  },
		  file_ignore_patterns = { "node_modules", ".git/" },
		},
		})
	end,
}
