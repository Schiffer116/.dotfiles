return {
    'norcalli/nvim-colorizer.lua',
    config = function ()
        require'colorizer'.setup({'*'}, {
            RRGGBBAA = true;
            rgb_fn   = true;
            hsl_fn   = true;
            css      = true;
            css_fn   = true;
            mode = 'foreground';
        })
    end
}
