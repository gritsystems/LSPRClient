# Copyright 2015 GRITsystems A/S

# This file is part of LSP R Client: R package allowing access to
# LSP's data via its RESTful API.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version, along with the following terms:
#
#   1. You may convey a work based on this program in accordance with
#      section 5, provided that you retain the above notices.
#   2. You may convey verbatim copies of this program code as you receive
#      it, in any medium, provided that you retain the above notices.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

connectToLSP <- function( lsp_host, api_token ){
    lspClientEnv$host <- lsp_host
    if( !api_token ){
        cat("Please provide an authentication token from your settings page in LSP\n",
            "Go to ", lsp_host, "and paste the auth token below\n")
        api_token <- readline()
    }
    lspClientEnv$token <- api_token
    .authenicateWithLSP( lsp )
}

.authenticateWithLSP <- function( api_token ){
    TRUE
}

.lspGet <- function( lsp_host, path='/' ){
    endPoint <- paste( lsp_host, path, sep="" )
    tryCatch( response <- getURL( endPoint ),
             error = function( e ){
                 message('Unable to complete the request, \n',
                         'The message from the server was: \n',
                         e)
             })

    
    .createDataFrame( jsonlite::fromJSON( response ) )
}

.lspGetFallback <-  function( lsp_host, path='/' ){
    
    header <- NULL
    header <- c(header, paste( 'GET ', lsp_host, path, 'HTTP/1.0\r\n', sep=""))
    header <- c(header, 'Accept: application/json' )

    connection <- socketConnection( host=lsp_host, port='443', open='r', blocking=TRUE, encoding='UTF-8' )

    writeLines( header, connection )

    response <- list()

    # The HTTP request status is in the first line of the response 
    response$status <- readLines( connection, n=1 )

    # followed by the headers until a blank line
    response$headers <- character(0)
    repeat{
        ss <- readLines( connection, n=1 )
        if (ss == "") break
        key.value <- strsplit(ss, ":\\s*")
        response$headers[key.value[[1]][1]] <- key.value[[1]][2]
    }

    # and finally the response body
    resp <- readLines( connection )
    
    response$body = fromJSON( resp, asText=TRUE, nullValue=NA )
    
    .createDataFrame( response )
}

.createDataFrame <- function( resp ){
    json_file <- lapply(resp$data, function(x) {
                            x[sapply(x, is.null)] <- NA
                            unlist(x)
                        })
    as.data.frame( json_file )
}
