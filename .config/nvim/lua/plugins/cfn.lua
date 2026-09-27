local server_dir = vim.fn.stdpath("data") .. "/cfn-lsp"

-- download the latest AWS CloudFormation language server (reruns on :Lazy update)
local function install_server()
  local release = vim.system({
    "curl", "-fsSL", "https://api.github.com/repos/aws-cloudformation/cloudformation-languageserver/releases/latest",
  }):wait()
  assert(release.code == 0, "cfn-lsp: failed to fetch latest release")

  local url
  for _, asset in ipairs(vim.json.decode(release.stdout).assets) do
    if asset.name:match("%-linux%-x64%-node22%.zip$") then
      url = asset.browser_download_url
    end
  end
  assert(url, "cfn-lsp: no linux-x64 release asset found")

  local zip = vim.fn.tempname() .. ".zip"
  assert(vim.system({ "curl", "-fsSL", "-o", zip, url }):wait().code == 0, "cfn-lsp: download failed")
  vim.fn.delete(server_dir, "rf")
  assert(vim.system({ "unzip", "-qo", zip, "-d", server_dir }):wait().code == 0, "cfn-lsp: unzip failed")
  vim.fn.delete(zip)
end

return {
  "mbarneyjr/cfn.nvim",
  version = "*",
  build = install_server,

  init = function()
    -- cfn.nvim expects templates to use these filetypes
    local function detect(ft)
      return function(_, bufnr)
        for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 200, false)) do
          if line:match("AWSTemplateFormatVersion") or line:match("[\"']?Type[\"']?:%s*[\"']?AWS::") then
            return ft
          end
        end
      end
    end
    vim.filetype.add({
      pattern = {
        [".*%.ya?ml"] = { detect("yaml.cloudformation"), { priority = math.huge } },
        [".*%.json"] = { detect("json.cloudformation"), { priority = math.huge } },
      },
    })

    -- new files are detected while still empty, so check again on save
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.yaml", "*.yml", "*.json" },
      callback = function()
        if vim.bo.filetype == "yaml" or vim.bo.filetype == "json" then
          vim.cmd("filetype detect")
        end
      end,
    })
  end,

  config = function()
    vim.lsp.config("cfn_lsp", {
      cmd = { "node", server_dir .. "/cfn-lsp-server-standalone.js", "--stdio" },
      filetypes = { "yaml.cloudformation", "json.cloudformation" },
      root_markers = { ".git" },
      capabilities = require("cmp_nvim_lsp").default_capabilities(),
      init_options = {
        aws = {
          clientInfo = { extension = { name = "neovim", version = tostring(vim.version()) } },
          telemetryEnabled = false,
        },
      },
    })
    vim.lsp.enable("cfn_lsp")

    local cfn = require("cfn")
    cfn.setup()

    vim.keymap.set("n", "<leader>cf", cfn.fn.toggle_status_window, { desc = "CloudFormation status" })
    -- the server doesn't implement rename, cfn.nvim updates references itself
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "yaml.cloudformation", "json.cloudformation" },
      callback = function(args)
        vim.keymap.set("n", "<leader>rn", cfn.fn.rename_resource, { buffer = args.buf, desc = "Rename resource" })
      end,
    })
  end,
}
