#!/bin/bash
if [[ $1 == "cluster list" ]] ; then
  CMD="/opt/1C/v8.3/x86_64/rac $1"
  if [[ -z $2 ]] ; then
    ${CMD} | awk -F':' '{\
    printf "{\"data\":[", "%s"; \
    do{
      printf "{", "%s"; \
      do{
        gsub(/[\t ]*/,"",$1)
        gsub("-","",$1)
        gsub(/[\t ]*/,"",$2)
        gsub("\"","",$2)
        printf "\"{#"toupper($1)"}\":\""$2"\"", "%s"; \
        getline;\
        if($0 != "") printf ",", "%s";\
      }while($0 != "")
      getline;\
      printf "}", "%s"; \
      if($0) printf ",", "%s";\
    }while($0)
    print "]}"; \
    }'
  else
    ${CMD} | awk -F':' -v PROP=$2 '{\
      gsub(/[\t ]*/,"",$1)
      gsub(/[\t ]*/,"",$2)
      if($1 == PROP) printf $2, "%s"; \
  }'
  fi
  exit;
fi
CMD="/opt/1C/v8.3/x86_64/rac $1 --cluster $2"
KEY=""
if [[ -n $3 ]] ; then
  KEY=$3;
fi
${CMD} | awk -F':' -v mykey=$KEY '\
BEGIN{\
  arr["total_count"] = 0;\
  arr["total_bgjobs_count"]=0;\
  arr["total_sleep_count"]=0;\
}{\
  do{\
    arr["total_count"]++;\
    do{\
      gsub(/[\t ]*/,"",$1);\
      gsub(/[\t ]*/,"",$2);\
      if(match($1, "app-id") && match($2, "BackgroundJob"))arr["total_bgjobs_count"]++;\
      if(match($1, "hibernate") && match($2, "yes"))arr["total_sleep_count"]++;\
      if(match($2, /^[0-9.]+$/)){\
        key = $1;
        gsub("-","_",key);\
        arr["sum_"key]=arr["sum_"key] + $2;\
        arr["avg_"key]=arr["sum_"key]/arr["total_count"];\
        if($2 > arr["max_"key]) arr["max_"key] = $2;\
        if($2 < arr["min_"key] || arr["min_"key] == "") arr["min_"key] = $2;\
      }\
      getline;\
    }while($0 != "");\
    getline;\
  }while($0);\
}
END{\
if(mykey == ""){
  printf "{\"data\":[", "%s"; \
  printf "{", "%s"; \
  for(a in arr){\
    print a":"arr[a]",";\
  }\
  printf "total_count:"arr["total_count"];
  printf "}", "%s"; \
  printf "]}", "%s"; \
}else{\
  for(a in arr){\
    if(match(a, mykey)){printf arr[a], "%s";}\
  }\
}\
}'
