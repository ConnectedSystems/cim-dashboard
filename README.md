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

## Dev notes

There is a bug in Agtor.jl caused by the assumption that files can be asynchronously
read in with multiple threads. For the majority of cases this is not an issue, however,
when running the dashboard (with asynchronous threads), a race condition can be met leading
to files not being read, which in turns causes the model run to file.

An "UndefRefError: access to undefined reference" warning will be raised.

In the majority of cases the model can simply be re-run without issue. In the rare case, it can lead to the Julia session crashing.

Potential fix is simple:

Delete `Threads.@threads` from this line:
https://github.com/ConnectedSystems/Agtor.jl/blob/4670fd904fec4a1e83392a1e93092e965bf3808e/src/AgBase/io.jl#L30
