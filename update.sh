#!/bin/bash  
. ~/.profile
ebooks archive jato corpus/jato.json  
ebooks archive kevinrose corpus/kevinrose.json  
ebooks consume-all combined corpus/jato.json corpus/kevinrose.json