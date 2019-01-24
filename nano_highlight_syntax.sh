var=`ls /usr/share/nano/`

arr=($var)

for i in ${arr[@]};do
  if [[ "$i" =~ nanorc ]]; then
    echo include /usr/share/nano/$i >> ~/.nanorc
  fi
done
