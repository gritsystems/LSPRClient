# LSP R Client

The LSP R client package allows R users to extract data from an LSP installation using the LSP REST API.

The prerequisites for connecting to LSP is an API token, which is obtainable from the "User Settings" page in LSP.


# Dependencies

## RCurl
Windows users may need to download the binary package from http://cran.r-project.org/web/packages/RCurl/index.html

# Installation

    require(devtools)
    install_github( 'gritsystems/lsprclient', ref='$CURRENT_VERSION' )

where $CURRENT_VERSION is a tag, e.g. `1.0.0`

# Contributing

Contributions are most welcome!

Fork the repository, create a branch named something relating to the feature/bug you're developing and send us a pull request



