#!/bin/bash  
. ~/.profile
ebooks archive jato corpus/jato.json  
ebooks archive kevinrose corpus/kevinrose.json  
ebooks archive summertomato corpus/summertomato.json  
ebooks consume-all combined corpus/jato.json corpus/kevinrose.json corpus/summertomato.json