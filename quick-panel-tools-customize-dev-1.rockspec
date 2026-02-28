package = "quick-panel-tools-customize"
version = "dev-1"
source = {
   url = "https://github.com/nenshoukei/quick-panel-tools-customize"
}
description = {
   detailed = "A Factorio mod that allows you to customize the tools tab of the Quick Panel, which is primarily used when playing on a Steam Deck or with a controller.",
   homepage = "https://github.com/nenshoukei/quick-panel-tools-customize",
   license = "MIT"
}
dependencies = {
   "lua >= 5.2"
}
build_dependencies = {
}
build = {
   type = "builtin",
   modules = {}
}
test_dependencies = {
   "busted >= 2.3"
}
