using Documenter, Mirage

makedocs(
    sitename = "Mirage.jl Documentation",
    modules = [Mirage],
    format = Documenter.HTML(
        repolink = "https://github.com/nasa/Mirage.jl",
        edit_link = "master",
    ),
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "Core Concepts" => "concepts.md",
        "API Reference" => "api_reference.md",
        "Examples" => "examples.md"
    ],
    checkdocs = :all,
    remotes = nothing
)
