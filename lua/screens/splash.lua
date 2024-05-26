local starstyle = require('starstyle')

local screen_content_file = 'splash.txt'
local banner_start_line = 3
local banner_line_count = 10

local gradient_start = { r = 248, g = 172, b = 97 }
local gradient_end = { r = 138, g = 49, b = 141 }
-- local gradient_start = { r = 255, g = 114, b = 82 }
-- local gradient_end = { r = 132, g = 111, b = 92 }
local screen_splash_gradient = starstyle.gradient(gradient_start, gradient_end, banner_line_count)
local screen_splash_color_group = starstyle.style_group_from_seqs('screen_splash', { fg = screen_splash_gradient })

vim.cmd(':54vsplit '..vim.fn.stdpath('config')..'/'..screen_content_file)
local screen_buffer = vim.fn.bufnr()

starstyle.color_lines_seq(screen_splash_color_group, screen_buffer, banner_start_line, banner_line_count)
