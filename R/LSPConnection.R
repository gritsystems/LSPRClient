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

#' The LSPRClient will check the LSP API for an expected version number to make
#' sure that the entities and formats are conformant to the client
lspClientEnv <- new.env() 
assign( 'api_version', '0.1.0', envir = lspClientEnv )

options(stringsAsFactors = FALSE)

#' This function is the entrypoint for interaction with the LSP API through the 
#' R Client.
#' The prerequisites for using this function is an endpoint URL pointing to a
#' running instance of LSP, e.g 'https://lsp.gritsystems.dk'. It is possible to 
#' specify a port-number to the endpoint, e.g. 'https://lsp.gritsystems.dk:443'.
#' The second prerequisite is an api-token, which is obtainable from the
#' LSP installation. See the README.md file for more information on how to do
#' this.
#' Once successfully authenticated (in this case against the 0.1.0 version of the 
#' api), you will see the message
#' \code{Successfully authenticated with LSP API (v0.1.0), ready to continue}
#'
connectToLSP <- function( lsp_host, api_token ){
  
    if( substring(lsp_host, nchar(lsp_host)) != '/' )
    {
      lsp_host = paste( lsp_host, '/', sep="" )
    }

    assign( 'host', lsp_host, envir = lspClientEnv )
        
    if(  nchar(api_token, type="chars") < 1 ){
        cat("Please provide an authentication token from your settings page in LSP\n",
            "Go to ", lsp_host, "and paste the auth token below\n")
        api_token <- readline()
    }   
    assign( 'api_token', api_token, envir = lspClientEnv )
    
    .authenticateWithLSP()
}

.authenticateWithLSP <- function(){
  version <- .lspGet(get('host', envir = lspClientEnv ), 'api/version', get( 'api_token', envir = lspClientEnv ))
  if( version$api_version != get( 'api_version', envir = lspClientEnv ) )
  {
    warning( sprintf( 'Server is version %s but this client expects %s\nThings might not work as expected', version$api_version, get( 'api_version', envir = lspClientEnv) ) )
  }else
  {
    message( sprintf( 'Successfully authenticated with LSP API (v%s), ready to continue', version$api_version ) )
  }
}

.lspGet <- function( lsp_host, path='/', api_token ){
    endPoint <- paste( lsp_host, path, '?token=', api_token, sep="" )

    # use the ssl.verifyhost=FALSE option to bypass certificate check
    tryCatch( response <- getURL( endPoint, ssl.verifyhost=FALSE ),
             error = function( e ){
                 stop('Unable to complete the request, \n',
                         'The message from the server was: \n',
                         e$message)
             })
    
    tryCatch( jsonResp <- jsonlite::fromJSON( gsub( "[\n\r]", "", response ), flatten = TRUE),
              error = function( e ){
                stop( 'Could not parse JSON response, \n',
                         'The error message from the server was: \n',
                         e$message)
              })
    .createDataFrame( jsonResp )
}

.lspGetFallback <-  function( lsp_host, path='/', api_token ){
    port_no <- gsub( '.*([^0-9]+)', '\\1',  lsp_host, perl=TRUE )

    if( nchar(port_no) < 1 )
    {
      port_no <- '443'
    }else
    {
      port_no <- gsub( ':([0-9]+)', '\\1', port_no )
    }
    
    lsp_host <- gsub( ':[0-9]+', '', lsp_host ) #remove ports, as we are defining them below
    lsp_host <- gsub( '/$', '', lsp_host ) #remove trailing slashes, if any
    scheme <- gsub( '(^.+):/(.+)$', '\\1', lsp_host )
    
    if( grepl(scheme, 'https' ))
    {
      stop( 'https scheme is not supported by the fallback function')      
    }
    
    lsp_host <- substring( lsp_host, regexpr( '://', lsp_host )+3, nchar(lsp_host) )

    header <- NULL
    header <- c(header, paste( 'GET', path, 'HTTP/1.1\r\n', sep=" "))

    connection <- socketConnection( host=lsp_host, port=port_no, open='r', blocking=TRUE, encoding='UTF-8', server = FALSE )

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
                            x
                        })
    as.data.frame( json_file )
}
