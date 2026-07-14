using Documenter, Mirage

makedocs(
    sitename = "Mirage.jl Documentation",
    modules = [Mirage],
    format = Documenter.HTML(repolink = "https://github.com/groverburger/Mirage.jl"),
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Core Concepts" => "concepts.md",
        "API Reference" => "api_reference.md",
        "Examples" => "examples.md"
    ],
    checkdocs = :all,
    warnonly = [:missing_docs],  # Only warn, don't fail
    remotes = nothing
)
