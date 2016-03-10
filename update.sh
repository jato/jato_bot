#!/bin/bash  
. ~/.profile
ebooks archive kevinrose corpus/kevinrose.json  
ebooks archive jato corpus/jato.json  
ebooks consume-all corpus/kevinrose.json corpus/jato.json
