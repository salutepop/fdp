pushd $1
find -name '*.c' -o -name '*.cc' -o -name '*.h' -o -name '*.cpp' > cscope.files
cscope -b -q -k
ctags -R
popd
