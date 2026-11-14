# DocsCheck rules for RunicPlatform (passed with -DRULES): a code change under a C++ module (cpp/<Module>/) needs
# cpp/<Module>/ARCHITECTURE.md; a code change under a Go area (go/sdk/, go/services/, go/blocks/) needs that
# area's ARCHITECTURE.md (its contract and package status, written by the area's first package). The Go bootstrap
# placeholder (go/platform/), go/cmd/ (executables) and generated code have no contract.
function(runic_docs_rule path out_module out_contracts)
    set(module "")
    set(contracts "")
    if(path MATCHES "^(cpp|go)/([A-Za-z0-9_]+)/")
        set(root "${CMAKE_MATCH_1}")
        set(name "${CMAKE_MATCH_2}")
        if(NOT name MATCHES "^(platform|cmd|generated)$")
            set(module "${name}")
            list(APPEND contracts "${root}/${name}/ARCHITECTURE.md")
        endif()
    endif()
    set(${out_module} "${module}" PARENT_SCOPE)
    set(${out_contracts} "${contracts}" PARENT_SCOPE)
endfunction()
