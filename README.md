## Setup

First, copy data files into a `data` directory.

```shell
this_project_directory
├── assets
│   └── db_display.css
├── *data* <- CREATE AND COPY FILES INTO THIS DIRECTORY
├── dashboard.jl
├── Manifest.toml
├── Project.toml
└── README.md
```

Second, instantiate the project and `dev` local copy of the Campaspe Integrated Model.

```shell
$ julia --project=.
] instantiate
] dev <path to local campaspe integrated model>
```

## Usage

To launch from a Julia REPL and to allow changes to be hot reloaded:

```julia
using Revise, Infiltrator

includet("dashboard.jl")  # Note the `t` in `includet`!
```

Otherwise, `include` the file as normal:

```julia
include("dashboard.jl")
```

The dashboard should be served at http://localhost:9384
