#!/bin/bash  
. ~/.profile
ebooks archive jato corpus/jato.json  
ebooks archive kevinrose corpus/kevinrose.json  
ebooks archive damienfahey corpus/damienfahey.json  
ebooks archive summertomato corpus/summertomato.json  
ebooks consume-all combined corpus/jato.json corpus/kevinrose.json corpus/summertomato.json corpus/damienfahey.json

# type "./update.sh" in Terminal to run the update script and grab new tweets 
