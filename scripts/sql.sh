#!/bin/sh

query=$(cat)
echo "$query
"
sqlcmd -U sa -P 'ms@sql123' -Q "use qlgv; $query" | sed '/Changed database context to/d'
echo
