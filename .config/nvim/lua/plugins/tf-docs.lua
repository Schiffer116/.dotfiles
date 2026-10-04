return {
  "cablecreek/tf-docs.nvim",
  cmd = { "TFDocs", "TFDocsSearch", "TFDocsUnderCursor" },
  keys = {
    { "<leader>gt", "<cmd>TFDocs aws<cr>", desc = "Terraform AWS docs" },
  },
  opts = {
    providers = { "aws" },
    picker = "telescope",
  },
}
