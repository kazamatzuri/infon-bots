PASS=blub
PLAYERNO=6
IP=infon.dividuum.de


predprey:
	(echo ; echo j; echo ${PLAYERNO}; echo ${PASS}; echo b; cat predprey.lua; echo ; echo .; echo r; echo q) | netcat ${IP} 1234

predprey2:
	(echo ; echo j; echo ${PLAYERNO}; echo ${PASS}; echo b; cat predprey2.lua; echo ; echo .; echo r; echo q) | netcat ${IP} 1234

cleanbot:
	(echo ; echo j; echo ${PLAYERNO}; echo ${PASS}; echo b; cat cleanbot.lua; echo ; echo .; echo r; echo q) | netcat ${IP} 1234

gravbot:
	(echo ; echo j; echo ${PLAYERNO}; echo ${PASS}; echo b; cat gravity-bot-working.lua; echo ; echo .; echo r; echo q) | netcat ${IP} 1234

ursbot:
	(echo ; echo j; echo ${PLAYERNO}; echo ${PASS}; echo b; cat ursbot.lua; echo ; echo .; echo r; echo q) | nc ${IP} 1234

devbot:
	(echo ; echo j; echo ${PLAYERNO}; echo ${PASS}; echo b; cat devbot.lua; echo ; echo .; echo r; echo q) | nc ${IP} 2323

stupi:
	(echo ; echo j; echo ${PLAYERNO}; echo ${PASS}; echo b; cat stupibot.lua; echo ; echo .; echo r; echo q) | nc ${IP} 1234


