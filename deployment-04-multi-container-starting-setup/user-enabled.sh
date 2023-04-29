isAuth=`mongo --eval "db.runCommand('ping')" "mongodb://max:secret@localhost:27017/course-goals?authSource=admin" $1 | grep "Authenticated"`

if [ -z "$isAuth" ] ;
then
  0
else
  1
fi