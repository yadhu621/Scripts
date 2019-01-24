var=`ls /usr/share/nano/` # get all nanorc files

arr=($var) # put it in an array

# iterate and append to ~/.nanorc file
# additional string check for only nanorc files
for i in ${arr[@]};do
  if [[ "$i" =~ nanorc ]]; then
    echo include /usr/share/nano/$i >> ~/.nanorc
  fi
done
